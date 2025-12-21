@echo off
:: 遅延環境変数の展開（!)を使うための設定
setlocal enabledelayedexpansion

::
:: Installation
::

echo Start installation...
:: 一時的に実行ポリシーを変更
powershell -NoProfile -ExecutionPolicy Unrestricted %~dp0\install.ps1 %~dp0\install.ps1
echo Finish installation successfully.

::
:: Settings
::

echo Start copy dotfiles...
:: 設定ファイルのリンク（ハードリンク）を作成
:: ユーザーホームディレクトリ
set HOMEDIR=%HOMEPATH%
set BAKDIR=%HOMEDIR%\.dotfiles.bak
set SRCDIR=%~dp0\..\..\HOME

:: バックアップディレクトリ作成
if not exist !BAKDIR! (
    mkdir !BAKDIR!
)

:: HOMEディレクトリ内のファイルを処理
:: ファイル
for %%F in (%SRCDIR%\*) do (
    set FILE=%%~nxF
    if exist %HOMEDIR%\!FILE! (
        echo Backing up: !FILE!
        move /Y "%HOMEDIR%\!FILE!" "!BAKDIR!\"
    )
    echo Creating symbolic link: !FILE!
    mklink "%HOMEDIR%\!FILE!" "%SRCDIR%\!FILE!"
)

:: ディレクトリ
for /D %%F in (%SRCDIR%\*) do (
    set FILE=%%~nxF
    if exist %HOMEDIR%\!FILE! (
        echo Backing up: !FILE!
        move /Y "%HOMEDIR%\!FILE!" "!BAKDIR!\"
    )
    echo Creating symbolic link: !FILE!
    mklink /D "%HOMEDIR%\!FILE!" "%SRCDIR%\!FILE!"
)

:: nvim の設定ディレクトリ作成
if not exist %HOMEDIR%\nvim (
    mklink /D "%LOCALAPPDATA%\nvim" "%SRCDIR%\.config\nvim"
)

echo Finish copy dotfiles successfully.

:: dotfiles 配置後の処理
nvim --headless -c "Lazy! sync" -c "qall"

pause > nul
@REM exit
