@echo off
setlocal

REM ========================================================
REM server.xml 整合性チェック＆整形ツール 起動バッチ
REM ========================================================

REM 引数チェック（ドラッグ＆ドロップされたか）
if "%~1"=="" (
    echo [ERROR] ファイルが指定されていません。
    echo 処理対象の server.xml をこのバッチファイルにドロップしてください。
    pause
    exit /b
)

REM PowerShellスクリプトのパス設定（バッチと同じ階層）
set "PS_SCRIPT=%~dp0Check_ServerXML.ps1"

REM PowerShell実行
REM -NoProfile: プロファイル読み込みなし（高速化・環境依存排除）
REM -ExecutionPolicy Bypass: 実行ポリシーの一時的な回避
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "%~1"

REM 処理結果確認のため一時停止
echo.
pause