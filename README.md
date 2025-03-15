# dotfiles

## Overview
俺の俺による俺のための設定ファイルセットです。インストールもするやつ

## Supported OS（WIP）
- Windows
- Ubuntu
    - WSL2 Ubuntu 含む
- ChromeOS Linux([Debian](https://support.google.com/chromebook/answer/9145439))

## Installation（WIP）

### Windows
1. Download

   ```bash
   git clone https://github.com/allllllllez/dotfiles.git
   cd dotfiles
   ```

1. Install
   コマンドプロンプト（**管理者として実行**で起動すること[^1]）で次を実行：

   ```command
   scripts/windows/install.bat
   ```

[^1]: mklink を実行するために必要。

### Linux（WSL）
1. Download
   [Windows](#windows) の手順と同様 [^2]

1. Install

   ```bash session
   ./install.sh
   ```

2. neovim plugin install

   ```bash
   vi --headless -c 'Lazy! sync' -c 'qall'
   ```

[^2]: Win・Linux 共通でもいいっちゃいいけど。。。

1. Enjoy👍

