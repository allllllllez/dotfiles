---
name: continuous-learning
description: Automatically extract reusable patterns from Claude Code sessions and save them as learned skills for future use.
---

# Continuous Learning Skill

セッション終了時にトランスクリプトを走査し、再利用できるパターンの候補を検出する。
検出結果は候補ファイルに書き出すだけで、skill 化は人が `/learn` または
`/retrospective` を実行したときに行う。

## 動作

`evaluate-session.py` が Stop hook として走る。セッション終了はブロックしない。

1. stdin の JSON から `transcript_path` を受け取る
2. トランスクリプトを1回走査し、4つの信号を数える
3. 閾値を超えたら `~/.claude/learning_candidates.md` を書き、systemMessage で知らせる
4. 超えなければ古い候補ファイルを削除して静かに終わる
5. 判定にかかわらず `runs.jsonl` へ1行追記する

## 検出する信号

| 信号 | 何を数えるか |
|------|--------------|
| `human_turns` | tool_result と自動挿入を除いた、人の実発話数。承認だけの「y」は数えない |
| `error_recoveries` | `is_error` の tool_result の後、同一操作が成功した回数 |
| `corrections` | 発話冒頭400文字に訂正表現を含む発話の数 |
| `repeated_failures` | 同一操作が2回以上失敗した回数 |

`human_turns` が閾値以上で、かつ残り3つのいずれかが閾値以上のときに候補を書く。

## 設定

`config.json` の `signals` で閾値を変える。

```json
{
  "signals": {
    "min_human_turns": 4,
    "min_error_recoveries": 1,
    "min_corrections": 1,
    "min_repeated_failures": 2
  }
}
```

## 計測

```bash
python3 ~/.claude/skills/continuous-learning/evaluate-session.py --status
```

実行回数、候補が出た割合、`learned/` 配下のファイル数を表示する。

わかるのは発火と候補の産出まで。抽出した skill が後のセッションを改善したかは
測っていない。それを測るには `learned/` の読み取りを記録する別の hook が必要になる。

## Hook 設定

`~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/skills/continuous-learning/evaluate-session.py",
        "timeout": 15
      }]
    }]
  }
}
```

Stop hook はトランスクリプトのパスを stdin の JSON で渡す。環境変数では渡らない。

## 出力先

- `~/.claude/learning_candidates.md` — 候補。毎回上書きされ、信号がなければ削除される
- `runs.jsonl` — 実行記録

どちらもセッション由来の内容を含むため `.gitignore` で除外している。

## 関連

- `/learn` — セッション途中での手動抽出
- `/retrospective` — KPT による振り返りと rules / skills への反映
