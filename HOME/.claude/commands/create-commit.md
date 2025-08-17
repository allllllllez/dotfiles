## commitを作成

### commitの前にコードを確認
- コードのガイドラインに従っているか
- 不要なコメント（console.logなど）が残っていないか
- 必要なエラーハンドリングが実装されているか

### コミットメッセージのフォーマット
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)に従う:
- feat: 新機能
- fix: バグ修正
- docs: ドキュメントのみの変更
- style: コードの意味に影響を与えない変更（空白、フォーマット、セミコロンの欠落など）
- refactor: バグを修正せず、機能も追加しないコード変更
- perf: パフォーマンスを向上させるコード変更
- test: 不足しているテストの追加や既存のテストの修正
- ci : CI 構成ファイルとスクリプトの変更 (例: GitHub Actions、Circle)
- chore: ビルドプロセスや補助ツール、ライブラリなどの変更

例: feat: add user authentication
