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
    python3 python3-venv \
    npm

## Nerd-fonts
git clone https://github.com/ryanoasis/nerd-fonts.git && cd nerd-fonts && ./install.sh

## Starshiip
curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir ~/bin

## nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

## Claude code
nvm install --lts
nvm use --lts

npm install -g @anthropic-ai/claude-code

## NeoVim
git clone https://github.com/neovim/neovim.git ~/neovim
pushd .
cd ~/neovim
make CMAKE_BUILD_TYPE=Release
sudo make install
popd


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

# HOME/bin and NeoVim PATH
cat << 'EOF' >> ~/.bashrc 
export PATH="~/neovim/build/bin/nvim:$PATH"
EOF

