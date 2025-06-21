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

mklink /H %HOMEPATH%\.bashrc %~dp0\..\HOME\.bashrc
mklink /H %HOMEPATH%\.gitconfig %~dp0\..\HOME\.gitconfig

:: ?o?b?N?A?b?v?f?B???N?g????
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

echo Finish copy dotfiles successfully.

pause > nul
@REM exit
