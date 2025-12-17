@echo off
cd /d %~dp0

rem 引数がない場合は終了
if "%~1"=="" goto :eof


:loop
rem ファイルが存在するかチェック
if not exist "%~1" goto :next


echo -------------------------------------------------------
echo Target: %~nx1
echo -------------------------------------------------------


rem PowerShell呼び出し (ファイルごとに実行)
powershell -NoProfile -ExecutionPolicy Bypass -File ".\xml-sweeper.ps1" -TargetFilePath "%~1"


rem 次の引数（ファイル）へシフト
:next
shift
if not "%~1"=="" goto :loop


echo.
echo =======================================================
echo All tasks finished.
pause