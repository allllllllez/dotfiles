#!/usr/bin/env python3
"""Stop hook: 探索委譲の検査 — read-only ツールが委譲なしに
連続 N 回続いた形跡があれば警告ファイルを書く(warn のみ、block しない)."""
import json
import os
import re
import sys
from pathlib import Path

READONLY_TOOLS = {"Read", "Grep", "Glob", "Bash"}            # 探索系
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}  # 編集系
DELEGATION_TOOLS = {"Agent", "TaskCreate"}                   # 委譲成立
# Bash のうち変更系コマンドは連続数を切る(正規表現の近似で十分 — warn 用途)
BASH_MUTATE_RE = re.compile(
    r"(?:^|[;&|]\s*)(?:rm|mv|cp|mkdir|touch|sed\s+-i"
    r"|git\s+(?:commit|push|add|reset|checkout))\b|>>?\s*\S"
)
WARN_FILE = Path.home() / ".claude" / "delegation_warn.md"


def scan_max_streak(tpath: str) -> int:
    """transcript を走査し、read-only 連続数の最大値を返す."""
    max_streak = streak = 0
    with open(tpath, encoding="utf-8", errors="replace") as f:
        for line in f:
            if '"assistant"' not in line:  # 前段フィルタで json.loads を節約
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if rec.get("type") != "assistant":
                continue
            for c in rec.get("message", {}).get("content", []):
                if not isinstance(c, dict) or c.get("type") != "tool_use":
                    continue
                name, inp = c.get("name", ""), c.get("input") or {}
                if name in DELEGATION_TOOLS or name in EDIT_TOOLS:
                    streak = 0  # 委譲成立 or 編集フェーズ移行でリセット
                elif name in READONLY_TOOLS:
                    if name == "Bash" and BASH_MUTATE_RE.search(
                        str(inp.get("command") or "")
                    ):
                        streak = 0
                    else:
                        streak += 1
                        max_streak = max(max_streak, streak)
    return max_streak


def main() -> int:
    if os.environ.get("CLAUDE_DELEGATION_CHECK", "0") != "1":
        return 0
    try:
        data = json.load(sys.stdin)  # Stop hook は stdin で JSON を受け取る
    except (json.JSONDecodeError, ValueError):
        return 0  # 不正入力なら静かに何もしない
    tpath = str(data.get("transcript_path") or "")
    if not os.path.exists(tpath):
        return 0
    try:
        threshold = int(os.environ.get("CLAUDE_DELEGATION_STREAK_N", "8"))
    except ValueError:
        threshold = 8
    if scan_max_streak(tpath) >= threshold:
        WARN_FILE.write_text(
            "探索の subagent 委譲忘れ: read-only ツールが委譲なしに"
            f"{threshold} 回以上連続。explorer / scanner への委譲を検討。\n"
        )
    elif WARN_FILE.exists():
        WARN_FILE.unlink()  # 健全なセッションなら古い警告を消す
    return 0  # 常に exit 0 = warn のみで block しない


if __name__ == "__main__":
    sys.exit(main())

