# dotfiles

## Overview
俺の俺による俺のための設定ファイルセットです

## Supported OS（WIP）
- Windows
- Ubuntu
    - WSL2 Ubuntu 含む
- ChromeOS Linux([Debian](https://support.google.com/chromebook/answer/9145439))

## Installation（WIP）

1. Install
    - Windows のみ

       ```command
       windows/install.bat
       ```

    - 共通 

       ```bash session
       ./install.sh
       ```

1. neovim plugin install

   ```bash
   vi --headless -c 'Lazy! sync' -c 'qall'
   ```

1. Enjoy👍

