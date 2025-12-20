#!/bin/bash

# ==============================================================================
# 井戸端会議 セットアップスクリプト
# ==============================================================================

set -e

echo "======================================"
echo "井戸端会議 セットアップ"
echo "======================================"
echo

# ------------------------------------------------------------------------------
# カラー定義
# ------------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# ヘルパー関数
# ------------------------------------------------------------------------------

check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name がインストールされています"
        return 0
    else
        echo -e "${RED}✗${NC} $name がインストールされていません"
        if [ -n "$install_hint" ]; then
            echo -e "  ${YELLOW}インストール方法:${NC} $install_hint"
        fi
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 依存関係チェック
# ------------------------------------------------------------------------------

echo "依存関係をチェックしています..."
echo

all_ok=true

# tmux
if ! check_command "tmux" "tmux" "apt install tmux"; then
    all_ok=false
fi

# Node.js (vde-layout用)
if ! check_command "node" "Node.js" "https://nodejs.org/ からインストール"; then
    all_ok=false
else
    node_version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_version" -lt 22 ]; then
        echo -e "${YELLOW}⚠${NC} Node.js のバージョンが古いです（v22以上が推奨）"
        echo "  現在のバージョン: $(node --version)"
        all_ok=false
    fi
fi

# vde-layout
if ! check_command "vde-layout" "vde-layout" "npm install -g vde-layout"; then
    all_ok=false
fi

# GitHub CLI
if ! check_command "gh" "GitHub CLI" "https://cli.github.com/ からインストール"; then
    all_ok=false
fi

# Claude Code
if ! check_command "claude" "Claude Code" "https://claude.com/claude-code からインストール"; then
    all_ok=false
fi

# Codex CLI
if ! check_command "codex" "Codex CLI" "適切なインストール手順を確認してください"; then
    all_ok=false
fi

# NeoVim
if ! check_command "nvim" "NeoVim" "apt install neovim または brew install neovim"; then
    all_ok=false
fi

echo

# ------------------------------------------------------------------------------
# 必須ディレクトリの作成
# ------------------------------------------------------------------------------

echo "必須ディレクトリを作成しています..."
echo

mkdir -p ~/.config/vde
mkdir -p ~/.config/nvim/lua/plugins
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/scripts
mkdir -p .i9wa4

echo -e "${GREEN}✓${NC} ディレクトリを作成しました"
echo

# ------------------------------------------------------------------------------
# 設定ファイルのシンボリックリンク確認
# ------------------------------------------------------------------------------

echo "設定ファイルを確認しています..."
echo

config_files=(
    "$HOME/.tmux.conf"
    "$HOME/.config/vde/layout.yml"
    "$HOME/.config/nvim/lua/plugins/magi-system.lua"
    "$HOME/.claude/commands/my-review.md"
    "$HOME/.claude/commands/summarize-reviews.md"
)

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file が存在します"
    else
        echo -e "${RED}✗${NC} $file が存在しません"
        all_ok=false
    fi
done

echo

# ------------------------------------------------------------------------------
# 結果サマリー
# ------------------------------------------------------------------------------

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}======================================"
    echo "セットアップ完了！"
    echo "======================================${NC}"
    echo
    echo "井戸端会議を起動するには："
    echo "  $ vde-layout review"
    echo
    echo "NeoVimから全AIペインにコマンドを送信するには："
    echo "  :SendToAllAI /my-review"
    echo
else
    echo -e "${RED}======================================"
    echo "セットアップに問題があります"
    echo "======================================${NC}"
    echo
    echo "上記のエラーを解決してから、再度このスクリプトを実行してください。"
    exit 1
fi
