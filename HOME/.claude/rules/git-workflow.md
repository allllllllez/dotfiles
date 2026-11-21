# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

Note: Attribution disabled globally via ~/.claude/settings.json.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch
6. Reference related issues as "Related to #N" by default — do not use auto-close keywords (Closes/Fixes/Resolves #N) unless the user explicitly asks for auto-close semantics.
7. 実装中に気づいた関連する欠落や不整合は、スコープ外と判断する前に選択肢として提示する。含めるかどうかは Cru が決める。
8. レビュー指摘への対応では、計画を「指摘が求める層（項目、手順、ファイル名など）」と「波及先（変更しないが影響する層）」に分ける。指摘が複数の直し方を許すときは、編集の前に選択肢で聞く。指摘が前提にしている事実（環境の制約、製品の提供状況、日程）は、定例や Slack で PR の外から更新されていることがある。計画を出す前に、更新の有無を Cru に 1 行で聞き、選択肢の質問はその回答の後に出す。
9. commit の計画では、stage 済みのファイルごとに「今回のセッションで触ったか」を書き、触っていないものは含めるか確認する。
10. 別の目的の未コミット変更がある作業ツリーや、そこから複製したファイルの上で編集するときは、コミットを案内する前に、`git diff --stat` のファイルを「今回の目的」「無関係」「同じファイルに両方」の3つに仕分けて示す。「同じファイルに両方」があるときは、`git add -u` と `git add -A` を案内せず、そのファイルの扱い（origin の版から目的の編集だけをやり直す、など）を先に決める。
11. 依頼が「〇〇さんのコメント」「レビューの指摘」のように PR 上の資料を指すときは、リポジトリ内の grep より先に、PR のレビューコメント、通常コメント、レビュー本体を gh で取得する計画を、最初の計画に入れる。アカウント切り替えの y/n も、その計画で取る。リポジトリ内に無いことを理由に、資料の所在を Cru に尋ねない。

## PR レビューの判断を求めるとき

Cru にレビュースレッドの扱い（resolve / 追加指摘）を決めてもらうときは、論点ごとに
スレッドの URL（`#discussion_r...`）と、PR head の該当行を開く blob URL（`/blob/<sha>/<path>?plain=1#L<n>`）を付ける。
Cru は要約ではなく原文を読んで判断する。

スレッドの件数を報告するときは、API の結果を jq で数えた値を書く。
一覧は1スレッド1行にし、複数のスレッドを1行にまとめない。

## GitHub Multi-Account Safety

Before creating or editing issues, PRs, or comments via `gh`, verify the active account matches the intended identity:
- Run `gh auth status` and compare the active account against the target identity (git remote owner, commit author config, or the account the user has been referring to).
- If multiple accounts are logged in and it's ambiguous which one should be used, ask the user before proceeding — do not rely on whichever account happens to be active by default.
- The active account is shared across concurrent sessions and can change mid-session. Do not rely on a check made earlier in the session.
- Every command that writes to GitHub (issue / PR / comment / review / resolve) must verify `gh api graphql -f query='{viewer{login}}'` equals the intended account inside the same command, and abort without writing if it does not.

ユーザーが「ユーザーは X です」のようにアカウントを指定したときは、アカウント切り替えの依頼として扱う。
最初の `gh` 呼び出しの前に `gh api graphql -f query='{viewer{login}}'` を実行し、X と違えば後続の `gh` を流さない。
違うときは、`GH_TOKEN` の差し替えなど別の手段に回らず、`gh auth switch --user X` の計画を出して y/n を取る。
読み取りだけの呼び出しも対象とする。

セッションの最初の `gh` 呼び出しの前に、「viewer が X でなければ `gh auth switch --user X` を実行してから続行してよいか」を 1 回だけ聞く。
承認を得たら、そのセッションの中で viewer の不一致を検出したときは、計画を出し直さず、切り替えて同じコマンドを再実行し、結果に「切り替えた」と書く。
書き込みを伴うコマンドは、再実行の前にも viewer を同じコマンドの中で確かめる。
承認がないときは、上の手順のとおり、計画を出して y/n を取る。

リポジトリのオーナーごとの既定のアカウントは次のとおり。
最初の `gh` 呼び出しの前の計画に、「viewer が X でなければ `gh auth switch --user X` を実行する」を含める。

- ds-products：m-kajiya-datum
- fg-wizbase：miho-kajiya_mdevbase
- 上にないオーナー：Cru に聞く

## GitHub への書き込みの計画

レビュー、コメント、Approve、Resolved を GitHub に書き込む計画には、次の 3 点を書く。

- 投稿の種類：インライン行コメント、レビュー本文、通常コメントのどれか
- イベント：APPROVE、COMMENT、REQUEST_CHANGES、返信、Resolved のどれか
- 本文：投稿する文面を逐語で

指摘をレビューに載せるときの既定は、指摘ごとのインライン行コメントとする。
Approve には本文を付ける。
承認、Resolved、了承の返信の本文は、Cru が指定しない限り 1 文の案を出す。
提出済みのレビュー本体は削除できないため、投稿の種類とイベントは、y を取る前に確定させる。

PR のレビューコメントは、作成者に頼む口調で書く（「〜してもらえますか」「〜と思います」）。
事実の記述は断定のまま残し、提案と影響の推測だけを和らげる。

## 共有ブランチへのコミットと push

他の人も push するブランチでコミットや push を計画するときは、計画を出す前に
`git fetch` を実行し、リモートとの差（`HEAD..origin/<branch>` の件数）を計画に書く。
セッション開始時の git status は過去のスナップショットであり、リモートの現状を表さない。

## Git Staging Preference

If the user states during a session that they will handle `git add` themselves, treat it as a standing preference for the rest of that session:
- Do not attempt `git add` again, even for a different/new set of files later in the same session.
- When new changes need staging, ask the user to stage them rather than re-attempting the command.

## Feature Implementation Workflow

1. **Plan First**
   - Use **planner** agent to create implementation plan
   - Identify dependencies and risks
   - Break down into phases

2. **TDD Approach**
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

3. **Code Review**
   - Use **code-reviewer** agent immediately after writing code
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format
