# 井戸端会議 (Idobata-Kaigi)

複数のAIエージェントが独立してコードレビューを実行し、多角的な視点でコード品質を評価するシステム。
cf. https://zenn.dev/genda_jp/articles/2025-12-04-magi-system-ai-review

## コンセプト

「井戸端会議」は、異なる専門性を持つ複数のAIエージェントが独立してコードレビューを行い、その結果を統合することで、より包括的で偏りの少ないコードレビューを実現します。

### なぜ複数のAIなのか？

- **専門性の分離**: セキュリティ、パフォーマンス、コード品質の各専門家が独立して分析
- **バイアスの軽減**: 単一のAIによる偏った判断を避ける
- **多角的な視点**: 異なる観点からの指摘により、見落としを減少
- **合意度の可視化**: 複数のエージェントが同じ問題を指摘すると、重要度が高いと判断

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│                     Vim (Editor)                        │
│  - コード編集                                            │
│  - レビュー結果の閲覧                                     │
│  - AIへのテキスト送信 (vim-tmux-send-to-ai-cli)         │
└─────────────────────────────────────────────────────────┘
                            │
                            │ tmux integration
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐  ┌──────────────┐  ┌───────▼────────┐
│ Claude Code #1 │  │ Claude Code  │  │ Claude Code #3 │
│ (セキュリティ)  │  │      #2      │  │  (コード品質)  │
│                │  │ (パフォーマンス)│  │                │
└───────┬────────┘  └──────┬───────┘  └────────┬───────┘
        │                   │                   │
        │  /idobata-kaigi:review               │
        │                   │                   │
        ▼                   ▼                   ▼
┌────────────────────────────────────────────────────────┐
│           .idobata-kaigi/ (レビュー結果)               │
│  - YYYYMMDD-p0-review.md                              │
│  - YYYYMMDD-p1-review.md                              │
│  - YYYYMMDD-p2-review.md                              │
└────────────────────────────────────────────────────────┘
                            │
                            │ /idobata-kaigi:summarize-reviews
                            ▼
┌────────────────────────────────────────────────────────┐
│        .idobata-kaigi/YYYYMMDD-all-reviews.md         │
│  - 統合レビューレポート                                 │
│  - 優先度順の推奨事項                                   │
│  - カテゴリ別サマリー                                   │
└────────────────────────────────────────────────────────┘
```

## 前提条件

### 必須

- **tmux**: ペイン管理
- **Claude Code CLI**: AIエージェント実行
- **Neovim**: エディタ（Vim互換エディタでも可）
- **Git**: バージョン管理とdiff取得

### オプション

- **gh (GitHub CLI)**: PR diffの取得に便利
- **vde**: tmuxレイアウトの自動構築ツール

## セットアップ

### 1. dotfilesの配置

このリポジトリをもとに環境構築すればOKなのですが、この機能だけを利用する場合について記載します

```bash
# このdotfilesリポジトリをクローン
git clone https://github.com/allllllllez/dotfiles.git ~/dotfiles
cd ~/dotfiles

# シンボリックリンクを作成（または直接コピー）
ln -s ~/dotfiles/HOME/.claude ~/.claude
ln -s ~/dotfiles/HOME/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/HOME/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/HOME/.bash_aliases ~/.bash_aliases
```

### 2. Neovimプラグインのインストール

このリポジトリをもとに環境構築すればOKなのですが、この機能だけを利用する場合について記載します

```bash
# Neovimを起動（初回起動時に自動的にプラグインがインストールされる）
nvim

# または手動でプラグインをインストール
nvim --headless "Lazy! sync" +qa
```

### 3. tmux設定の反映

```bash
# tmuxが起動中の場合は設定をリロード
tmux source-file ~/.tmux.conf

# または新規セッションを開始
tmux new -s default
```

## 使い方

### 基本的なワークフロー

#### Step 1: 開発環境の起動

```bash
# tmuxセッションを起動
tm  # alias for: tmux attach -t default || tmux new -s default

# tmux内でNeovimを起動
nvim
```

#### Step 2: 井戸端会議用レイアウトの構築

**方法A: 手動でペインを分割**

```bash
# 水平分割（C-a |）
# 垂直分割（C-a -）
# 各ペインでClaude Codeを起動
claude --model sonnet
```

**方法B: vdeを使用（推奨）**

```bash
# vdeがインストールされている場合
vde review  # ~/.config/vde/layout.yml の review プリセットを使用
```

最終的に以下のレイアウトになる：

```
┌─────────────────────┬──────────┐
│                     │          │
│   Vim (Editor)      │ Claude#1 │
│                     │          │
├─────────┬─────────┬─┴──────────┤
│Claude#2 │Claude#3 │  Claude#4  │
└─────────┴─────────┴────────────┘
```

#### Step 3: レビューの実行

各Claude Codeペイン（#1, #2, #3, #4）で以下のコマンドを実行：

```
/idobata-kaigi:review
```

各エージェントは以下のように動作します：

- **ペイン番号 % 3 == 0** → セキュリティ専門家
  - XSS, SQLインジェクション, 認証/認可の問題
  - OWASP Top 10に基づいた分析

- **ペイン番号 % 3 == 1** → パフォーマンス専門家
  - アルゴリズムの計算量
  - メモリリーク、リソース管理
  - データベースクエリの最適化

- **ペイン番号 % 3 == 2** → コード品質専門家
  - 可読性と保守性
  - SOLID原則、DRY原則
  - テストカバレッジ

レビュー結果は `.idobata-kaigi/YYYYMMDD-pN-review.md` に保存されます。

#### Step 4: レビュー結果の統合

いずれか1つのClaude Codeペインで以下を実行：

```
/idobata-kaigi:summarize-reviews
```

統合レポートが `.idobata-kaigi/YYYYMMDD-all-reviews.md` に生成されます。

#### Step 5: 結果の確認

```bash
# Vimで統合レポートを開く
:e .idobata-kaigi/YYYYMMDD-all-reviews.md

# または直接ファイルを開く
nvim .idobata-kaigi/$(date +%Y%m%d)-all-reviews.md
```

### Vimからのテキスト送信

Neovimプラグイン `vim-tmux-send-to-ai-cli` を使用して、エディタから直接AIにテキストを送信できます。

#### 単一ペインへの送信

| キーマッピング | 動作 |
|--------------|------|
| `<leader>al` | 現在行を送信 |
| `<leader>ap` | 現在のパラグラフを送信 |
| `<leader>as` | ビジュアル選択を送信 |
| `<leader>ab` | バッファ全体を送信 |

#### 全ペインへの送信

| キーマッピング | 動作 |
|--------------|------|
| `<leader>aL` | 現在行を全AIペインに送信 |
| `<leader>aP` | パラグラフを全AIペインに送信 |
| `<leader>aS` | ビジュアル選択を全AIペインに送信 |
| `<leader>aB` | バッファ全体を全AIペインに送信 |

**使用例**:

1. コードの一部をビジュアルモードで選択
2. `<leader>aS` で全AIペインに送信
3. 各AIが独立して分析を開始

## ファイル構成

```
HOME/.claude/commands/idobata-kaigi/
├── README.md                    # このファイル
├── review.md                    # AIエージェント用レビューコマンド
└── summarize-reviews.md         # レビュー統合コマンド

HOME/.config/nvim/lua/plugins/
├── idobata-kaigi.lua            # vim-slime設定
└── vim-tmux-send-to-ai-cli.lua  # tmux連携プラグイン

HOME/.config/vde/
└── layout.yml                   # tmuxレイアウト定義

.idobata-kaigi/                  # レビュー結果（gitignore推奨）
├── YYYYMMDD-p0-review.md
├── YYYYMMDD-p1-review.md
├── YYYYMMDD-p2-review.md
├── YYYYMMDD-p3-review.md
└── YYYYMMDD-all-reviews.md
```

## トラブルシューティング

### Q: レビューコマンドが見つからない

```bash
# Claude Codeがコマンドを認識しているか確認
ls -la ~/.claude/commands/idobata-kaigi/

# パーミッションを確認
chmod 644 ~/.claude/commands/idobata-kaigi/*.md
```

### Q: tmuxペイン番号がわからない

```bash
# 現在のペイン番号を表示
tmux display-message -p '#{pane_index}'

# または、tmuxのステータスバーで確認（C-a qで一時表示）
```

### Q: Vimからのテキスト送信が動作しない

```bash
# vim-tmux-send-to-ai-cliプラグインがインストールされているか確認
:Lazy

# tmuxセッション内でNeovimを起動しているか確認
echo $TMUX  # 空でない場合はtmux内で実行中
```

### Q: AIが正しい専門分野で動作していない

```bash
# ペイン番号を確認し、期待される専門分野と一致するか確認
# ペイン0, 3 → セキュリティ
# ペイン1, 4 → パフォーマンス
# ペイン2, 5 → コード品質
```

### Q: レビュー結果が保存されない

```bash
# .idobata-kaigi ディレクトリが存在するか確認
ls -la .idobata-kaigi/

# 存在しない場合は作成
mkdir -p .idobata-kaigi
```

## ベストプラクティス

### 1. レビュー前の準備

- 変更内容を明確にするため、コミットメッセージを整理
- PRの場合は、diffが取得できる状態にする

### 2. 効率的なレビュー

- 大規模な変更は、機能単位で分割してレビュー
- レビュー結果は日付別に保存されるため、定期的に古いファイルを整理

### 3. 統合レポートの活用

- Critical/High優先度の項目から対応
- 複数のAIが一致した指摘は特に重要

### 4. コスト管理

- 4つのSonnetインスタンスを同時実行するため、API使用量に注意
- 実験的な使用や重要なレビューに限定することを推奨

## 今後の拡張案

### 機能拡張

- [ ] レビュー結果のdiff表示機能
- [ ] 自動修正サジェスション
- [ ] レビュー履歴の可視化（グラフ化）
- [ ] CI/CDパイプラインとの統合

### プロセス改善

- [ ] レビュー結果のスコアリングシステム
- [ ] カスタムペルソナの追加（例：アクセシビリティ専門家）
- [ ] レビュー結果のJSON出力

### パフォーマンス

- [ ] 並行実行の最適化
- [ ] キャッシュ機構の導入
- [ ] 差分レビュー（変更部分のみ）

## 参考資料

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [tmux Documentation](https://github.com/tmux/tmux/wiki)
- [vim-slime](https://github.com/jpalardy/vim-slime)
- [vim-tmux-send-to-ai-cli](https://github.com/i9wa4/vim-tmux-send-to-ai-cli)

## ライセンス

このプロジェクトは、親リポジトリのライセンスに従います。

## フィードバック

改善案やバグレポートは、GitHubのIssueまたはPull Requestでお願いします。
