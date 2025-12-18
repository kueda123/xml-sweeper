@echo off
setlocal enabledelayedexpansion

REM ========================================================
REM  Server XML Integrity Checker Launcher
REM ========================================================

REM --- 1. スクリプトの絶対パスを確定 ---
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Check_ServerXML.ps1"

REM --- 2. 安全装置 ---
if not exist "%PS_SCRIPT%" (
    echo.
    echo [ERROR] PowerShell script not found!
    echo Looked in: "%PS_SCRIPT%"
    echo.
    echo Please ensure .bat and .ps1 are in the SAME folder.
    echo.
    pause
    exit /b 1
)

REM --- カウンター初期化 ---
set /a count_total=0
set /a count_processed=0
set /a count_skipped=0
set /a count_error=0

:LOOP
if "%~1"=="" goto FINISH

REM 総数カウントアップ
set /a count_total+=1

REM --- 3. 区切り線 ---
echo ===============================================================================
echo Target: %~1
echo -------------------------------------------------------------------------------

REM --- 4. PowerShell呼び出し ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -TargetFilePath "%~1"

REM --- 5. 結果判定と集計 ---
REM  Exit Code 2 = Skipped
REM  Exit Code 1 = Error
REM  Exit Code 0 = OK/Fixed

set RET=!ERRORLEVEL!

if !RET! equ 2 (
    set /a count_skipped+=1
) else if !RET! equ 1 (
    set /a count_error+=1
) else (
    set /a count_processed+=1
)

REM 次のファイルへ
shift
goto LOOP

:FINISH
echo ===============================================================================
echo.
echo  [Summary]
echo  Total Scanned : %count_total%
echo  -----------------------
echo   o Processed  : %count_processed%  (Checked / Fixed)
echo   - Skipped    : %count_skipped%  (Excluded extensions)
echo   x Errors     : %count_error%  (Validation failed or Read error)
echo.
echo ===============================================================================
pause
