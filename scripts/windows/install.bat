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

mklink /H %HOMEPATH%\.bashrc %~dp0\..\HOME\.bashrc
mklink /H %HOMEPATH%\.gitconfig %~dp0\..\HOME\.gitconfig

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

echo Finish copy dotfiles successfully.

pause > nul
@REM exit
