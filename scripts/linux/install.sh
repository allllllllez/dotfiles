#!/usr/bin/env bash
set -x

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
ROOT_DIR=${SCRIPT_DIR}/../..


# ==================================
# 
# install
#
# ==================================

sudo apt install -y \
    ninja-build \
    gettext \
    gcc \
    cmake \
    unzip \
    curl \
    neovim \
    tmux \
    python3 python3-venv \
    npm \
    fzf

## Nerd-fonts
git clone https://github.com/ryanoasis/nerd-fonts.git && cd nerd-fonts && ./install.sh

## starship
curl -sS https://starship.rs/install.sh | sh

## AWS CLI
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

## GitHub CLI
## cf. https://github.com/cli/cli/blob/trunk/docs/install_linux.md
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

## nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

## Claude code
nvm install --lts
nvm use --lts

npm install -g @anthropic-ai/claude-code

## vde-layout (requires Node.js 22+)
npm install -g vde-layout


# ==================================
# 
# SimLink dotfiles
#
# ==================================

echo "Start copy dotfiles..."

# Variables
HOMEDIR=$HOME
BAKDIR=$HOMEDIR/.dotfiles.bak
SRCDIR=$SCRIPT_DIR/../../HOME

# Create backup directory
if [ ! -d "$BAKDIR" ]; then
    mkdir -p "$BAKDIR"
fi

# . から開始されるファイルを対象にする
shopt -s dotglob
for item in "$SRCDIR"/*; do
    filename=$(basename "$item")

    # Skip AppData directory
    if [ "$filename" = "AppData" ]; then
        echo "Skipping: $filename"
        continue
    fi

    source=$(realpath "$item")
    target="$HOMEDIR/$filename"
    
    # Backup existing file/directory
    if [ -e "$target" ]; then
        echo "Backing up: $filename"
        mv "$target" "$BAKDIR/"
    fi
    
    # Create symbolic link
    echo "Creating symbolic link: $filename"
    ln -s "$source" "$target"
done

# Restore the original dotglob setting
shopt -u dotglob

echo "Finish copy dotfiles successfully."

# ==================================
# 
# dotfiles 配置後の処理
#
# ==================================

# Install Neovim plugins
nvim --headless -c 'Lazy! sync' -c 'qall'
