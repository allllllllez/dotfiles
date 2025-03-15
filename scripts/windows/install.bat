@echo off

echo Start installation...
@REM 一時的に実行ポリシーを変更
powershell -NoProfile -ExecutionPolicy Unrestricted %~dp0\install.ps1 %~dp0\install.ps1
echo Finish installation successfully.
pause > nul
@REM exit
