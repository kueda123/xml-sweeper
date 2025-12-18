@echo off
setlocal enabledelayedexpansion

REM ========================================================
REM  Server XML Integrity Checker Launcher
REM ========================================================

REM --- 1. スクリプトの絶対パスを確定 (%~dp0 はこのbatの場所) ---
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Check_ServerXML.ps1"

REM 念のため確認（万が一見つからない場合は停止）
if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] PowerShell script not found!
    echo Looked in: "%PS_SCRIPT%"
    echo.
    echo Please ensure .bat and .ps1 are in the SAME folder.
    pause
    exit /b 1
)

REM カウンター初期化
set /a count=0

:LOOP
if "%~1"=="" goto FINISH

REM カウントアップ
set /a count+=1

REM --- 2. 区切り線を太線(====)に変更 ---
echo ===============================================================================
echo Target: %~1
echo -------------------------------------------------------------------------------

REM --- 3. 確定させた絶対パスで呼び出し ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -TargetFilePath "%~1"

REM 次のファイルへ
shift
goto LOOP

:FINISH
echo ===============================================================================
echo.
echo  [Summary]
echo  Total files processed: %count%
echo.
echo ===============================================================================
pause

