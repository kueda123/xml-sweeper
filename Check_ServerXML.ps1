<#
.SYNOPSIS
    Server XML Integrity Checker & Sweeper
    - スマートクォート: 検知したらエラー終了 (手動修正待ち)
    - NBSP: 検知したら自動置換して保存 (バックアップ作成)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFilePath
)

# ========================================================
# 設定エリア
# ========================================================
# エラー停止対象: スマートクォート
$FatalPattern = "[\u201C\u201D\u2018\u2019]" 
# 自動修正対象: NBSP (No-Break Space) -> 半角スペース(0x20)へ置換
$FixPattern   = "\u00A0"
$MaxGenerations = 5

# コンソール表示設定
$Host.UI.RawUI.ForegroundColor = "Gray"
Write-Host "--------------------------------------------------"
Write-Host " Server XML Integrity Checker & Sweeper"
Write-Host "--------------------------------------------------"
Write-Host "対象: $TargetFilePath" -ForegroundColor Cyan

if (-not (Test-Path $TargetFilePath)) {
    Write-Host "[ERROR] ファイルが見つかりません。" -ForegroundColor Red
    exit 1
}

# ========================================================
# 1. ファイル読み込み & 構文チェック (Smart Quote)
# ========================================================
try {
    # 全文読み込み
    $rawContent = [System.IO.File]::ReadAllText($TargetFilePath, [System.Text.Encoding]::UTF8)
}
catch {
    Write-Host "[ERROR] 読み込み失敗: $_" -ForegroundColor Red
    exit 1
}

# スマートクォートチェック (これは自動修正せず、ユーザーに直させる)
if ($rawContent -match $FatalPattern) {
    # 行番号を特定するために行ごとに再スキャン
    $lines = [System.IO.File]::ReadAllLines($TargetFilePath, [System.Text.Encoding]::UTF8)
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match $FatalPattern) {
            Write-Host ""
            Write-Host "[FATAL ERROR] 修復不可能な不正文字を検出しました (行: $lineNum)" -ForegroundColor Red
            Write-Host "--------------------------------------------------" -ForegroundColor Red
            Write-Host "該当行: $($line.Trim())" -ForegroundColor Yellow
            Write-Host "理由  : スマートクォート（“ ” ‘ ’）が含まれています。" -ForegroundColor Red
            Write-Host "        引用符の誤りは論理的な問題の可能性があるため、自動修正しません。" -ForegroundColor Gray
            Write-Host "--------------------------------------------------" -ForegroundColor Red
            Write-Host "処理を中断しました。エディタで修正してください。" -ForegroundColor Red
            exit 1
        }
    }
}

# ========================================================
# 2. 自動修正処理 (NBSP -> Space)
# ========================================================
$fixedContent = $rawContent -replace $FixPattern, " "

# 変更有無の確認
if ($rawContent -eq $fixedContent) {
    Write-Host ""
    Write-Host "○ 判定: OK (変更なし)" -ForegroundColor Green
    Write-Host "  不正な文字（スマートクォート, NBSP）はありませんでした。"
    exit 0
}

# ========================================================
# 3. 更新 & ローテーション処理
# ========================================================
Write-Host ""
Write-Host "！ NBSP(ノーブレークスペース) を検出しました。" -ForegroundColor Yellow
Write-Host "   -> 半角スペースに自動置換して保存します。" -ForegroundColor Cyan

$fileItem = Get-Item $TargetFilePath
$dir = $fileItem.DirectoryName
$baseName = $fileItem.Name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "$baseName.$timestamp.bak"

try {
    # バックアップ作成
    Rename-Item -Path $TargetFilePath -NewName $backupName -ErrorAction Stop
    Write-Host "バックアップ作成: $backupName" -ForegroundColor Gray
    
    # 新ファイル書き出し (BOMなしUTF-8)
    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($TargetFilePath, $fixedContent, $Utf8NoBom)
    Write-Host "更新完了: クリーニング済みのファイルを生成しました。" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] ファイル更新失敗: $_" -ForegroundColor Red
    exit 1
}

# ========================================================
# 4. 世代管理 (ローテーション)
# ========================================================
$backupPattern = "$baseName.*.bak"
$backupList = Get-ChildItem -Path $dir -Filter $backupPattern | Sort-Object Name -Descending

if ($backupList.Count -gt $MaxGenerations) {
    $filesToDelete = $backupList | Select-Object -Skip $MaxGenerations
    foreach ($file in $filesToDelete) {
        Remove-Item $file.FullName -Force
        Write-Host "世代管理: 古いバックアップを削除しました - $($file.Name)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "全処理が正常に終了しました。" -ForegroundColor Cyan
exit 0