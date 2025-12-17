@echo off
setlocal

rem -------------------------------------------------------
rem プログラム（ps1）のパスを絶対パスで確定させる
rem %~dp0 はこのバッチファイルが存在するドライブとフォルダのパスです
rem -------------------------------------------------------
rem ★修正: 実際のファイル名 "Check_ServerXML.ps1" に合わせました
set "SCRIPT_PATH=%~dp0Check_ServerXML.ps1"

rem ps1ファイルがバッチと同じ場所にあるか確認
if not exist "%SCRIPT_PATH%" (
    echo [ERROR] PowerShell script not found at:
    echo "%SCRIPT_PATH%"
    echo.
    echo Please ensure Check_ServerXML.ps1 is in the same folder as this batch file.
    pause
    exit /b 1
)

rem 引数がない場合は終了
if "%~1"=="" goto :eof

:loop
rem ドラッグされたファイルが存在するかチェック
if not exist "%~1" goto :next

echo -------------------------------------------------------
echo Target: %~1
echo -------------------------------------------------------

rem PowerShell呼び出し
rem -File には先ほど確定させた絶対パス(%SCRIPT_PATH%)を渡す
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -TargetFilePath "%~1"

rem 次の引数（ファイル）へシフト
:next
shift
if not "%~1"=="" goto :loop

echo.
echo =======================================================
echo All tasks finished.
pause