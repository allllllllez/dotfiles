#!/usr/bin/env python3
"""Stop hook: セッションから再利用可能なパターンの候補を検出する。

warn-only — セッション終了をブロックしない。信号が閾値を超えたときだけ
CANDIDATE_FILE を書き、systemMessage で知らせる。パターンの抽出と
skill 化そのものは、人が /learn または /retrospective を実行したときに行う
(config の auto_approve: false に対応する)。

計測: 実行ごとに RUNS_LOG へ1行追記する。`--status` で集計を表示。

Stop hook はトランスクリプトのパスを stdin の JSON で渡す。
環境変数では渡らない。
"""
import json
import re
import sys
from collections import OrderedDict
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SCRIPT_DIR / "config.json"
RUNS_LOG = SCRIPT_DIR / "runs.jsonl"
CANDIDATE_FILE = Path.home() / ".claude" / "learning_candidates.md"
LEARNED_DIR = Path.home() / ".claude" / "skills" / "learned"

DEFAULTS = {
    "min_human_turns": 4,
    "min_error_recoveries": 1,
    "min_corrections": 1,
    "min_repeated_failures": 2,
}

# 人の発話に見えるが実体は自動挿入である行の目印
NOISE_PREFIXES = (
    "<task-notification>",
    "<bash-stdout>",
    "<bash-stderr>",
    "<local-command-stdout>",
    "<local-command-stderr>",
    "<command-name>",
    "<command-message>",
    "<command-args>",
    "<system-reminder>",
    "[Request interrupted by user",
    "Another Claude session sent",
)
# 5原則に基づく承認だけの発話 — 学習の信号を持たない
APPROVAL_RE = re.compile(r"^(?:[yn]|[ｙｎ]|yes|no|ok|ｏｋ)[。.!！]?$", re.IGNORECASE)
# 訂正の表明
CORRECTION_RE = re.compile(
    r"違う|ちがう|ではなく|じゃなく|そうじゃな|そうではな|間違|まちが"
    r"|直して|修正して|やり直|戻して|逆です|勘違"
    r"|that'?s wrong|not what i|incorrect|revert that|undo that",
    re.IGNORECASE,
)
MAX_EXCERPT = 120  # 候補ファイルに残す抜粋の上限文字数
# 訂正は発話の冒頭で述べられる。長い貼り付けの奥での誤マッチを避けるため
# 走査範囲を先頭に限る。
CORRECTION_SCAN = 400


def load_config():
    cfg = dict(DEFAULTS)
    try:
        raw = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return cfg
    for key, val in (raw.get("signals") or {}).items():
        if key in cfg and isinstance(val, int):
            cfg[key] = val
    return cfg


def human_text(rec):
    """user レコードから人の発話本文を取り出す。人の発話でなければ None."""
    if rec.get("isMeta") or rec.get("isSidechain") or rec.get("isCompactSummary"):
        return None
    content = (rec.get("message") or {}).get("content")
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        parts = [
            c.get("text", "")
            for c in content
            if isinstance(c, dict) and c.get("type") == "text"
        ]
        if not parts:
            return None  # tool_result のみ
        text = "\n".join(parts)
    else:
        return None
    text = text.strip()
    if not text or text.startswith(NOISE_PREFIXES) or APPROVAL_RE.match(text):
        return None
    return text


def tool_signature(name, inp):
    """同一操作の再試行を突き合わせるための鍵。"""
    if not isinstance(inp, dict):
        return name
    for key in ("command", "file_path", "pattern", "url"):
        val = inp.get(key)
        if isinstance(val, str) and val:
            return f"{name}:{re.sub(r'\s+', ' ', val).strip()[:60]}"
    return name


def match_excerpt(text, match):
    """一致箇所を中心に抜粋する。先頭を出すと一致理由が見えないため。"""
    start = max(0, match.start() - MAX_EXCERPT // 3)
    excerpt = re.sub(r"\s+", " ", text[start:start + MAX_EXCERPT]).strip()
    return ("…" if start else "") + excerpt


def scan(tpath):
    """transcript を1回走査し、信号を集める。"""
    human_turns = 0
    corrections = []
    id_to_sig = {}
    # sig -> {"errors": int, "recovered": bool}
    attempts = OrderedDict()

    with open(tpath, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            rtype = rec.get("type")

            if rtype == "assistant":
                for c in (rec.get("message") or {}).get("content") or []:
                    if isinstance(c, dict) and c.get("type") == "tool_use":
                        id_to_sig[c.get("id")] = tool_signature(
                            c.get("name", ""), c.get("input")
                        )
                continue

            if rtype != "user":
                continue

            text = human_text(rec)
            if text is not None:
                human_turns += 1
                hit = CORRECTION_RE.search(text[:CORRECTION_SCAN])
                if hit:
                    corrections.append(match_excerpt(text, hit))
                continue

            content = (rec.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for c in content:
                if not isinstance(c, dict) or c.get("type") != "tool_result":
                    continue
                sig = id_to_sig.get(c.get("tool_use_id"))
                if sig is None:
                    continue
                state = attempts.setdefault(sig, {"errors": 0, "recovered": False})
                if c.get("is_error"):
                    state["errors"] += 1
                elif state["errors"]:
                    state["recovered"] = True

    recovered = [s for s, v in attempts.items() if v["recovered"]]
    repeated = [s for s, v in attempts.items() if v["errors"] >= 2]
    return {
        "human_turns": human_turns,
        "error_recoveries": len(recovered),
        "corrections": len(corrections),
        "repeated_failures": len(repeated),
        "_recovered": recovered,
        "_repeated": repeated,
        "_correction_texts": corrections,
    }


def write_candidates(sig, cwd):
    lines = [
        "# 学習候補",
        "",
        f"検出: {datetime.now().isoformat(timespec='seconds')}",
        f"作業ディレクトリ: {cwd or '不明'}",
        "",
        "`/learn` または `/retrospective` を実行すると、この候補をもとに抽出する。",
        "抽出しない場合はこのファイルを削除してよい。次のセッション終了時に上書きされる。",
        "",
        "## 検出した信号",
        "",
        f"- 人の発話数: {sig['human_turns']}",
        f"- エラーからの復帰: {sig['error_recoveries']}",
        f"- 訂正の発話: {sig['corrections']}",
        f"- 同一操作の反復失敗: {sig['repeated_failures']}",
        "",
    ]
    if sig["_recovered"]:
        lines += ["## 失敗して成功した操作", ""]
        lines += [f"- `{s}`" for s in sig["_recovered"][:10]]
        lines += [""]
    if sig["_repeated"]:
        lines += ["## 2回以上失敗した操作", ""]
        lines += [f"- `{s}`" for s in sig["_repeated"][:10]]
        lines += [""]
    if sig["_correction_texts"]:
        lines += ["## 訂正を含む発話（一致箇所の周辺）", ""]
        lines += [f"- {t}" for t in sig["_correction_texts"][:10]]
        lines += [""]
    CANDIDATE_FILE.write_text("\n".join(lines), encoding="utf-8")


def log_run(record):
    try:
        with open(RUNS_LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except OSError:
        pass


def show_status():
    if not RUNS_LOG.exists():
        print("実行記録なし。まだ一度も走っていない。")
        return 0
    runs = []
    for line in RUNS_LOG.read_text(encoding="utf-8").splitlines():
        try:
            runs.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    if not runs:
        print("実行記録なし。")
        return 0
    by_decision = {}
    for r in runs:
        by_decision[r.get("decision", "?")] = by_decision.get(r.get("decision", "?"), 0) + 1
    learned = len(list(LEARNED_DIR.glob("*"))) if LEARNED_DIR.exists() else 0
    print(f"実行回数: {len(runs)}")
    print(f"初回: {runs[0].get('at')}")
    print(f"直近: {runs[-1].get('at')}")
    for decision, count in sorted(by_decision.items(), key=lambda kv: -kv[1]):
        print(f"  {decision}: {count}")
    triggered = by_decision.get("candidate_written", 0)
    print(f"候補が出た割合: {triggered}/{len(runs)}")
    print(f"learned/ 配下のファイル数: {learned}")
    print()
    print("この集計でわかるのは発火と候補の産出まで。")
    print("学習内容が後のセッションを改善したかは測っていない。")
    return 0


def main():
    if "--status" in sys.argv:
        return show_status()

    at = datetime.now().isoformat(timespec="seconds")
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        log_run({"at": at, "decision": "skipped", "reason": "stdin が JSON でない"})
        return 0

    tpath = str(data.get("transcript_path") or "")
    session_id = data.get("session_id")
    if not tpath or not Path(tpath).exists():
        log_run({
            "at": at,
            "session_id": session_id,
            "decision": "skipped",
            "reason": "transcript_path が無い",
        })
        return 0

    cfg = load_config()
    try:
        sig = scan(tpath)
    except OSError as exc:
        log_run({
            "at": at,
            "session_id": session_id,
            "decision": "skipped",
            "reason": f"走査に失敗: {exc}",
        })
        return 0

    hit = [
        name
        for name in ("error_recoveries", "corrections", "repeated_failures")
        if sig[name] >= cfg["min_" + name]
    ]
    triggered = sig["human_turns"] >= cfg["min_human_turns"] and bool(hit)

    record = {
        "at": at,
        "session_id": session_id,
        "stop_hook_active": bool(data.get("stop_hook_active")),
        "human_turns": sig["human_turns"],
        "error_recoveries": sig["error_recoveries"],
        "corrections": sig["corrections"],
        "repeated_failures": sig["repeated_failures"],
        "decision": "candidate_written" if triggered else "no_signal",
        "hit_signals": hit,
    }

    if not triggered:
        if CANDIDATE_FILE.exists():
            try:
                CANDIDATE_FILE.unlink()  # 古い候補を残さない
            except OSError:
                pass
        log_run(record)
        return 0

    try:
        write_candidates(sig, data.get("cwd"))
    except OSError as exc:
        record["decision"] = "skipped"
        record["reason"] = f"候補の書き込みに失敗: {exc}"
        log_run(record)
        return 0

    log_run(record)
    print(json.dumps({
        "systemMessage": (
            f"学習候補あり（{', '.join(hit)}）: {CANDIDATE_FILE} "
            "— /learn または /retrospective で抽出できる"
        )
    }, ensure_ascii=False))
    return 0  # 常に 0 = ブロックしない


if __name__ == "__main__":
    sys.exit(main())
