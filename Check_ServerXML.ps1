param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFilePath
)

# ========================================================
# 設定エリア
# ========================================================
# 検知対象の不正文字（スマートクォート等）
# \uXXXX 形式の正規表現で指定（誤検知を防ぐため厳密に記述）
$InvalidPattern = "[\u201C\u201D\u2018\u2019]" 

# バックアップ保持世代数
$MaxGenerations = 5

# ========================================================
# メイン処理
# ========================================================

Write-Host "処理開始: $TargetFilePath" -ForegroundColor Cyan

if (-not (Test-Path $TargetFilePath)) {
    Write-Error "指定されたファイルが見つかりません。"
    exit 1
}

# --- 1. 構文チェック (Fail Fast) ---
# 行ごとに読み込んで不正文字がないか確認する
$lineCount = 0
$hasError = $false

foreach ($line in Get-Content $TargetFilePath -Encoding UTF8) {
    $lineCount++

    if ($line -match $InvalidPattern) {
        Write-Host ""
        Write-Host "[FATAL ERROR] 構文エラーを検出しました。" -ForegroundColor Red
        Write-Host "  行番号: $lineCount" -ForegroundColor Yellow
        Write-Host "  該当行: $line" -ForegroundColor Yellow
        Write-Host "  理由  : Word等のオートフォーマットによる不正な引用符（“ ” ‘ ’）が含まれています。" -ForegroundColor Red
        $hasError = $true
        break
    }
}

# エラーがあれば即終了（ファイルは一切触らない）
if ($hasError) {
    Write-Host ""
    Write-Host "処理を中断しました。ファイルは変更されていません。" -ForegroundColor Red
    exit 1
}

# --- 2. 整形処理 (コメント削除) ---
# ※XMLコメントは複数行にまたがることが多いため、ファイル全体を一括で読み込んで処理します
$rawContent = Get-Content -Path $TargetFilePath -Raw -Encoding UTF8

# 正規表現で を削除
# (?s) は改行を含んでマッチさせるオプション
$newContent = $rawContent -replace '(?s)', ''

# 連続する空行を整理（3行以上の空行を2行に縮める）
$newContent = $newContent -replace '(\r\n){3,}', "`r`n`r`n"


# ========================================================
# バックアップ & 更新処理
# ========================================================

Write-Host "チェックOK。更新処理を開始します..." -ForegroundColor Green

# 1. ファイル情報の取得
$fileItem = Get-Item $TargetFilePath
$dir = $fileItem.DirectoryName
$baseName = $fileItem.Name

# 2. バックアップ作成 (server.xml -> server.xml.yyyyMMdd_HHmmss.bak)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "$baseName.$timestamp.bak"
$backupPath = Join-Path $dir $backupName

try {
    Rename-Item -Path $TargetFilePath -NewName $backupName -ErrorAction Stop
    Write-Host "バックアップ作成: $backupName" -ForegroundColor Gray
}
catch {
    Write-Error "バックアップ作成（リネーム）に失敗しました。処理を中止します。"
    exit 1
}

# 3. 新ファイル書き出し
try {
    # BOMなしUTF-8で保存
    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($TargetFilePath, $newContent, $Utf8NoBom)
    
    Write-Host "更新完了: $baseName を再生成しました。" -ForegroundColor Green
}
catch {
    Write-Error "ファイルの書き込みに失敗しました。"
    exit 1
}

# ========================================================
# 世代管理 (ローテーション)
# ========================================================

# 対象ファイルのバックアップのみを抽出 (例: server.xml.*.bak)
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