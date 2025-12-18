<#
.SYNOPSIS
    Server XML Integrity Checker & Sweeper
    EXIT CODES:
      0 : OK / Fixed (正常終了)
      1 : Error (ファイルなし, 読込失敗, Validation Error)
      2 : Skipped (除外拡張子)
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

# LF変換対象拡張子
$ExtensionsToForceLF = @(".xml", ".properties", ".jvm.options", ".env", ".sh")

# 除外拡張子
$ExcludeExtensions = @(".bak", ".tmp", ".zip", ".jar", ".class", ".exe", ".dll", ".png", ".jpg", ".ico")


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
# 0. 拡張子チェック (Skip判定)
# ========================================================
$ext = [System.IO.Path]::GetExtension($TargetFilePath).ToLower()

if ($ExcludeExtensions -contains $ext) {
    Write-Host ""
    Write-Host "- [SKIP] 除外対象の拡張子のためスキップ ($ext)" -ForegroundColor DarkGray
    # ★変更点: バッチが集計できるように Exit Code 2 を返す
    exit 2
}

# LF変換対象か
$shouldConvertToLF = ($ExtensionsToForceLF -contains $ext)

# ========================================================
# 1. BOM チェック
# ========================================================
$hasBOM = $false
try {
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
    $rawContent = [System.IO.File]::ReadAllText($TargetFilePath, [System.Text.Encoding]::UTF8)
}
catch {
    Write-Host "[ERROR] ファイル読み込み失敗: $_" -ForegroundColor Red
    exit 1
}

# スマートクォート (Validation Error)
if ($rawContent -match $FatalPattern) {
    $lines = [System.IO.File]::ReadAllLines($TargetFilePath, [System.Text.Encoding]::UTF8)
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match $FatalPattern) {
            Write-Host ""
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
# 3. 自動修正処理
# ========================================================
$tempContent = $rawContent -replace $FixPattern, " "
$hasNBSP = ($rawContent -ne $tempContent)

$hasCRLF = $false
$fixedContent = $tempContent

if ($shouldConvertToLF) {
    $fixedContent = $tempContent -replace "`r`n", "`n"
    if ($tempContent -ne $fixedContent) {
        $hasCRLF = $true
    }
}

# ========================================================
# 4. 判定と更新アクション
# ========================================================
if ((-not $hasNBSP) -and (-not $hasBOM) -and (-not $hasCRLF)) {
    Write-Host ""
    Write-Host "○ 判定: OK (変更なし)" -ForegroundColor Green
    Write-Host "  不正文字・BOM・改行コードの不整合は検出されませんでした。"
    if (-not $shouldConvertToLF) {
        Write-Host "  (※ この拡張子は改行コード変換の対象外です: $ext)" -ForegroundColor DarkGray
    }
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
if ($hasCRLF) {
    Write-Host "！ Windows改行コード (CRLF) を検出しました。" -ForegroundColor Yellow
    Write-Host "   -> Linux形式 (LF) に変換します。" -ForegroundColor Gray
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
Write-Host "ファイル処理完了。" -ForegroundColor Cyan
exit 0
