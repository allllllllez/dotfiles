# ==================================
# Setup
# 
# Usage:
#     powershell -NoProfile -ExecutionPolicy Unrestricted ./install.ps1 install.ps1
# ==================================

# ==================================
# 
# Git for windows
# ※設定（.gitconfig）は別途
# winget install git ではオプション指定ができないのでインストーラからインストール
#
# ==================================

# git-for-windows 64-bit の最新リリースを取得
$git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
$asset = Invoke-RestMethod -Method Get -Uri $git_url | % assets | where name -like "*64-bit.exe"
Write-Host "git_url: $git_url"
Write-Host "asset: $asset"

# インストーラーをダウンロード
$git_installer = "$env:temp\$($asset.name)"
Write-Host "installer: $git_installer"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $git_installer

# inf file
# https://github.com/git-for-windows/git/wiki/Silent-or-Unattended-Installation
$git_install_inf = "$env:temp\setup.inf"
Set-Content -Path "$git_install_inf" -Force -Value @'
[Setup]
Lang=default
Dir=C:\Git
Group=Git
NoIcons=0
SetupType=default
Components=
Tasks=
PathOption=Cmd
SSHOption=OpenSSH
CRLFOption=CRLFCommitAsIs
'@

# run installer
$git_install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
Start-Process -FilePath $git_installer -ArgumentList $git_install_args -Wait

# 最新化
# git update-git-for-windows

Write-Host "git-for-windows のインストールが完了しました。"

# ==================================
# 
# その他ツール
# 
# ==================================

winget install googlechrome
winget install -i vscode # TODO： -i 必要？
winget install Python.Python

# WSL

Start-Process wsl --install

# Docker
# WSL backend のため、WSLより後にインストールする

winget install docker
winget install obs
winget install obsidian
winget install ollama
winget install Amazon.AWSCLI
winget install Google.CloudSDK
winget install jqlang.jq

# nvm-windows (Node.js バージョン管理)
winget install CoreyButler.NVMforWindows

# fzf (ファジーファインダー)
winget install fzf

# Unity
winget install Unity.Unity.6000

# Epic Games Launcher
winget install EpicGames.EpicGamesLauncher

# インストール確認
winget list
