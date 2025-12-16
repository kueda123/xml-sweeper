param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFilePath
)

# ========================================================
# 設定エリア
# ========================================================
# 検知対象の不正文字（スマートクォート等）
$InvalidPattern = "[`u201C`u201D`u2018`u2019]" 

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

# ファイル読み込み & 行単位チェック
$newContent = new-object System.Collections.Generic.List[string]
$lineCount = 0
$hasError = $false

# 行ごとにストリーム処理
foreach ($line in Get-Content $TargetFilePath) {
    $lineCount++

    # 1. 不正文字チェック (Fail Fast)
    if ($line -match $InvalidPattern) {
        Write-Host "`n[FATAL ERROR] 構文エラーを検出しました。" -ForegroundColor Red
        Write-Host "  行番号: $lineCount" -ForegroundColor Yellow
        Write-Host "  該当行: $line" -ForegroundColor Yellow
        Write-Host "  理由  : Word等のオートフォーマットによる不正な引用符が含まれています。" -ForegroundColor Red
        $hasError = $true
        break
    }

    # 2. 整形処理 (必要に応じてコメント削除ロジックなどをここに記述)
    # 現在はそのまま通過
    $processedLine = $line

    # バッファに追加
    $newContent.Add($processedLine)
}

# エラーがあれば即終了（ファイルは一切触らない）
if ($hasError) {
    Write-Host "`n処理を中断しました。ファイルは変更されていません。" -ForegroundColor Red
    exit 1
}

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
    $newContent | Set-Content -Path $TargetFilePath -Encoding UTF8 -ErrorAction Stop
    Write-Host "更新完了: $baseName を再生成しました。" -ForegroundColor Green
}
catch {
    Write-Error "ファイルの書き込みに失敗しました。"
    # 失敗時はバックアップから戻すリカバリが必要であればここに記述
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

Write-Host "`n全処理が正常に終了しました。" -ForegroundColor Cyan
exit 0