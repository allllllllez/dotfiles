@echo off

echo Start installation...
@REM �ꎞ�I�Ɏ��s�|���V�[��ύX
powershell -NoProfile -ExecutionPolicy Unrestricted %~dp0\install.ps1 %~dp0\install.ps1
echo Finish installation successfully.
pause > nul
@REM exit
