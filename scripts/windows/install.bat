@echo off
:: ?x??????????W?J?i!)???g?????????
setlocal enabledelayedexpansion

::
:: Installation
::

echo Start installation...
:: ???I????s?|???V?[???X
powershell -NoProfile -ExecutionPolicy Unrestricted %~dp0\install.ps1 %~dp0\install.ps1
echo Finish installation successfully.

::
:: Settings
::

echo Start copy dotfiles...
:: ???t?@?C????????N?i?n?[?h?????N?j????
:: ???[?U?[?z?[???f?B???N?g??
set HOMEDIR=%HOMEPATH%
set BAKDIR=%HOMEDIR%\.dotfiles.bak
set SRCDIR=%~dp0\..\..\HOME

:: ?o?b?N?A?b?v?f?B???N?g????
if not exist !BAKDIR! (
    mkdir !BAKDIR!
)

:: HOME?f?B???N?g??????t?@?C????????
:: ?t?@?C??
for %%F in (%SRCDIR%\*) do (
    set FILE=%%~nxF
    if exist %HOMEDIR%\!FILE! (
        echo Backing up: !FILE!
        move /Y "%HOMEDIR%\!FILE!" "!BAKDIR!\"
    )
    echo Creating symbolic link: !FILE!
    mklink "%HOMEDIR%\!FILE!" "%SRCDIR%\!FILE!"
)

:: ?f?B???N?g??
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

:: dotfiles ?z?u??????
nvim --headless -c "Lazy! sync" -c "qall"

pause > nul
@REM exit
