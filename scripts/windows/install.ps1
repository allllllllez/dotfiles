# ==================================
# Setup
# 
# Usage:
#     powershell -NoProfile -ExecutionPolicy Unrestricted ./install.ps1 install.ps1
# ==================================

# 
# Git for windows
# ※設定（.gitconfig）は別途
#

# get latest download url for git-for-windows 64-bit exe
$git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
$asset = Invoke-RestMethod -Method Get -Uri $git_url | % assets | where name -like "*64-bit.exe"
echo "git_url: "$git_url
echo "asset: "$asset

# download installer
$installer = "$env:temp\$($asset.name)"
echo "installer: "$installer 
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer

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
$install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
Start-Process -FilePath $installer -ArgumentList $install_args -Wait

# 最新化
# git update-git-for-windows

# 
# AWS CLI v2
# ※credentialは手動で設定する
# 

# /quiet は効かない
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# 
# Cloud SDK
# 

(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe")
& $env:Temp\GoogleCloudSDKInstaller.exe

# 
# nvm-windows (Node.js バージョン管理)
# 

# nvm-windows の最新リリースを取得
$nvm_git_url = "https://api.github.com/repos/coreybutler/nvm-windows/releases/latest"
$nvm_asset = Invoke-RestMethod -Method Get -Uri $nvm_git_url | % assets | where name -like "*nvm-setup.exe"
Write-Host "git_url: $nvm_git_url"
Write-Host "nvm-windows の最新バージョンを取得しました: $($nvm_asset.name)"

# インストーラーをダウンロード
$nvm_installer = "$env:temp\$($nvm_asset.name)"
Write-Host "インストーラーをダウンロードしています: $nvm_installer"
Invoke-WebRequest -Uri $nvm_asset.browser_download_url -OutFile $nvm_installer

# サイレントインストールを実行
Write-Host "nvm-windows をインストールしています..."
Start-Process -FilePath $nvm_installer -ArgumentList "/SILENT /NORESTART" -Wait

# 環境変数を更新するためにPowerShellセッションを更新
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$nvm_exe = "$($env:LOCALAPPDATA)\nvm\nvm.exe"
# cf. https://github.com/coreybutler/nvm-windows/issues/22
$env:NVM_HOME = "$($env:LOCALAPPDATA)\nvm"
$env:NVM_SYMLINK = ""

# Node.js LTS バージョンをインストール
Write-Host "Node.js LTS バージョンをインストールしています..."
try {
    # 最新のLTSバージョンをインストール
    Invoke-Expression "$nvm_exe install lts"
    
    # インストールしたバージョンを使用するように設定
    Invoke-Expression "$nvm_exe use lts"
    
    # # インストールの確認
    # $node_version = node -v
    $npm_version = Invoke-Expression "$nvm_exe -v"
    # Write-Host "Node.js $node_version と npm $npm_version がインストールされました"
} catch {
    Write-Warning "Node.js のインストールに問題がありました。手動でインストールを確認してください。"
}

Write-Host "nvm-windows と Node.js のインストールが完了しました。"
