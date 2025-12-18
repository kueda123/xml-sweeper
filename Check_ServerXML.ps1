<#
.SYNOPSIS
    Server XML Integrity Checker & Sweeper
    - スマートクォート: 検証NG (手動修正)
    - NBSP: 自動置換 (Space)
    - BOM: 自動除去 (UTF-8 NoBOM化)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFilePath
)

# ========================================================
# 設定エリア
# ========================================================
$FatalPattern = "[\u201C\u201D\u2018\u2019]" 
$FixPattern   = "\u00A0"
$MaxGenerations = 5

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
# 1. BOM (Byte Order Mark) チェック
# ========================================================
$hasBOM = $false
try {
    # .NETメソッドでバイナリとして先頭3バイトを確認 (確実)
    $bytes = [System.IO.File]::ReadAllBytes($TargetFilePath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $hasBOM = $true
    }
}
catch {
    $hasBOM = $false
}

# ========================================================
# 2. テキスト読み込み & スマートクォート検査
# ========================================================
try {
    # テキストとして全読み込み
    $rawContent = [System.IO.File]::ReadAllText($TargetFilePath, [System.Text.Encoding]::UTF8)
}
catch {
    Write-Host "[ERROR] テキスト読み込み失敗: $_" -ForegroundColor Red
    exit 1
}

# スマートクォート (Validation Error)
if ($rawContent -match $FatalPattern) {
    # 行番号特定のため再スキャン
    $lines = [System.IO.File]::ReadAllLines($TargetFilePath, [System.Text.Encoding]::UTF8)
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match $FatalPattern) {
            Write-Host ""
            # ★修正箇所: VALIDATION ERROR (要修正)
            Write-Host "× [VALIDATION ERROR] (要修正) 不正な文字を検出しました (行: $lineNum)" -ForegroundColor Red
            Write-Host "--------------------------------------------------" -ForegroundColor Red
            Write-Host "該当行: $($line.Trim())" -ForegroundColor Yellow
            Write-Host "理由  : スマートクォート（“ ” ‘ ’）が含まれています。" -ForegroundColor Red
            Write-Host "--------------------------------------------------" -ForegroundColor Red
            Write-Host "処置  : 処理を中断しました。ファイルは変更されていません。" -ForegroundColor Red
            Write-Host "        エディタで正しい引用符に修正してください。" -ForegroundColor Gray
            exit 1
        }
    }
}

# ========================================================
# 3. NBSP 除去処理
# ========================================================
$fixedContent = $rawContent -replace $FixPattern, " "
$hasNBSP = ($rawContent -ne $fixedContent)

# ========================================================
# 4. 判定と更新アクション
# ========================================================
if ((-not $hasNBSP) -and (-not $hasBOM)) {
    Write-Host ""
    Write-Host "○ 判定: OK (変更なし)" -ForegroundColor Green
    Write-Host "  不正な文字やBOMは検出されませんでした。"
    exit 0
}

Write-Host ""
if ($hasNBSP) {
    Write-Host "！ NBSP (ノーブレークスペース) を検出しました。" -ForegroundColor Yellow
    Write-Host "   -> 半角スペースに置換します。" -ForegroundColor Gray
}
if ($hasBOM) {
    Write-Host "！ BOM (Byte Order Mark) を検出しました。" -ForegroundColor Yellow
    Write-Host "   -> BOMを除去します。" -ForegroundColor Gray
}
Write-Host "   ファイルを更新します..." -ForegroundColor Cyan

# ========================================================
# 5. 更新 & ローテーション
# ========================================================
$fileItem = Get-Item $TargetFilePath
$dir = $fileItem.DirectoryName
$baseName = $fileItem.Name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "$baseName.$timestamp.bak"

try {
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

# 世代管理
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