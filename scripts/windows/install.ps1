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

# ==================================
# 
# その他ツール
# 
# ==================================

winget install googlechrome
winget install -i vscode # TODO： -i 必要？
winget install Python.Python

# WSL
wsl --install
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl.exe --install Ubuntu

# Docker
# WSL backend のため、WSLより後にインストールする
winget install Docker.DockerDesktop

# OBS Studio + virtual cam plugin
# 起動後に「ツール」>「obs virtual cam」で起動する必要あり
winget install OBSProject.OBSStudio

# obs-virtual-cam プラグインの Installer.exe をダウンロードして実行
$vcam_url = "https://api.github.com/repos/miaulightouch/obs-virtual-cam/releases/latest"
$vcam_asset = Invoke-RestMethod -Method Get -Uri $vcam_url | % assets | where name -like "*Installer.exe"
$vcam_installer = "$env:temp\$($vcam_asset.name)"
Write-Host "Downloading obs-virtual-cam installer: $($vcam_asset.browser_download_url)"
Invoke-WebRequest -Uri $vcam_asset.browser_download_url -OutFile $vcam_installer

# サイレントインストール（/S オプションが使える場合）
Start-Process -FilePath $vcam_installer -ArgumentList "/S" -Wait


winget install Microsoft.WindowsTerminal
winget install obsidian
winget install ollama
winget install Amazon.AWSCLI
winget install Google.CloudSDK
winget install jqlang.jq
winget install Starship.Starship
winget install Neovim.Neovim
winget install GitHub.cli

# nvm-windows (Node.js バージョン管理)
winget install CoreyButler.NVMforWindows

# fzf (ファジーファインダー)
winget install fzf

# Unity
winget install Unity.Unity

# Epic Games Launcher
winget install EpicGames.EpicGamesLauncher

# Claude code
winget install Anthropic.ClaudeCode

# ==================================
# 
# フォント ※ダウンロードのみ
# 
# ==================================

# PlemolJP NF
$plemoljp_url = "https://api.github.com/repos/yuru7/PlemolJP/releases/latest"
$plemoljp_asset = Invoke-RestMethod -Method Get -Uri $plemoljp_url | % assets | where name -like "*NF*.zip"
Write-Host "git_url: $plemoljp_url"
Write-Host "asset: $($plemoljp_asset.name)"

# ダウンロード
$plemoljp_installer = "$env:temp\$($plemoljp_asset.name)"
Write-Host "plemoljp_installer: $plemoljp_installer"
Invoke-WebRequest -Uri $plemoljp_asset.browser_download_url -OutFile $plemoljp_installer

# JKゴシックL
$jk_font_url = "https://font.cutegirl.jp/wp-content/uploads/2015/08/jk-go-l-1.zip"
$download_folder = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$jk_font_zip = Join-Path $download_folder "jk-go-l-1.zip"
Write-Host "Downloading JKゴシックLフォント: $jk_font_url"
Invoke-WebRequest -Uri $jk_font_url -OutFile $jk_font_zip

# JKゴシックM
$jk_font_m_url = "https://font.cutegirl.jp/wp-content/uploads/2015/08/jk-go-m-1.zip"
$jk_font_m_zip = Join-Path $download_folder "jk-go-m-1.zip"
Write-Host "Downloading JKゴシックMフォント: $jk_font_m_url"
Invoke-WebRequest -Uri $jk_font_m_url -OutFile $jk_font_m_zip

# Nerd Fonts
Install-PSResource -Name NerdFonts # プロンプトで確認が必要、-Confirm:$false でも回避できないかも
Import-Module -Name NerdFonts

# インストール確認
bash -c 'winget.exe list | grep winget'
