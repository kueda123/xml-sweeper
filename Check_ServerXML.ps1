param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFilePath
)

# .NETクラスのロード
Add-Type -AssemblyName System.Text.RegularExpressions

# ========================================================
# 設定エリア
# ========================================================
$InvalidPattern = "[\u201C\u201D\u2018\u2019]" 
$MaxGenerations = 5

# ========================================================
# メイン処理
# ========================================================

Write-Host "処理開始: $TargetFilePath" -ForegroundColor Cyan

if (-not (Test-Path $TargetFilePath)) {
    Write-Error "指定されたファイルが見つかりません。"
    exit 1
}

# --- 1. ファイル読み込み & 構文チェック ---
try {
    $rawContent = [System.IO.File]::ReadAllText($TargetFilePath, [System.Text.Encoding]::UTF8)
}
catch {
    Write-Error "ファイルの読み込みに失敗しました: $_"
    exit 1
}

# スマートクォートのチェック
if ($rawContent -match $InvalidPattern) {
    # 行番号特定のため再度読み込み
    $lines = [System.IO.File]::ReadAllLines($TargetFilePath, [System.Text.Encoding]::UTF8)
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match $InvalidPattern) {
            Write-Host ""
            Write-Host "[FATAL ERROR] 構文エラーを検出しました。" -ForegroundColor Red
            Write-Host "  行番号: $lineNum" -ForegroundColor Yellow
            Write-Host "  該当行: $($line.Trim())" -ForegroundColor Yellow
            Write-Host "  理由  : Word等のオートフォーマットによる不正な引用符（“ ” ‘ ’）が含まれています。" -ForegroundColor Red
            break
        }
    }
    Write-Host ""
    Write-Host "処理を中断しました。ファイルは変更されていません。" -ForegroundColor Red
    exit 1
}

Write-Host "構文チェックOK。" -ForegroundColor Green

# --- 2. コメント検出 & 削除 ---
Write-Host "コメント削除処理を実行中..." -NoNewline

# ★修正: シングルクォートを使用し、RegexOptions.Singleline (s) を明示的に指定
# これにより「.」が改行を含むようになります
$regexPattern = ''
$regexOptions = [System.Text.RegularExpressions.RegexOptions]::Singleline
$regex = [System.Text.RegularExpressions.Regex]::new($regexPattern, $regexOptions)

# マッチング実行
$foundMatches = $regex.Matches($rawContent)
$matchCount = $foundMatches.Count

if ($matchCount -gt 0) {
    Write-Host " [検出: $matchCount 箇所]" -ForegroundColor Yellow
    
    # ★デバッグ: 何がマッチしたのか最初の3件を表示（これで原因がわかります）
    Write-Host "  DEBUG: 検出内容サンプル:" -ForegroundColor DarkGray
    for ($i = 0; $i -lt [Math]::Min($matchCount, 3); $i++) {
        $val = $foundMatches[$i].Value
        # 改行を含むと見づらいので1行に縮める
        $displayVal = $val -replace "\r\n|\n", " " 
        if ($displayVal.Length -gt 60) { $displayVal = $displayVal.Substring(0, 60) + "..." }
        Write-Host "  [$i] '$displayVal'" -ForegroundColor DarkGray
    }
} else {
    Write-Host " [検出なし]" -ForegroundColor Gray
}

# 置換実行
$cleanedContent = $regex.Replace($rawContent, "")

# --- 3. 空行の整理 ---
# 3つ以上の改行を2つに
$regexSpace = [System.Text.RegularExpressions.Regex]::new("(\r\n){3,}")
$cleanedContent = $regexSpace.Replace($cleanedContent, "`r`n`r`n")

# --- 4. 変更有無の確認 ---
if ($rawContent -eq $cleanedContent) {
    Write-Host "変更なし" -ForegroundColor Yellow
    Write-Host "削除対象のコメントや不要な空行はありませんでした。"
    Write-Host "ファイルの更新をスキップします。" -ForegroundColor Cyan
    exit 0
}

Write-Host "ファイル内容に変更があります。更新プロセスへ進みます。" -ForegroundColor Cyan

# ========================================================
# バックアップ & 更新処理
# ========================================================

$fileItem = Get-Item $TargetFilePath
$dir = $fileItem.DirectoryName
$baseName = $fileItem.Name

# バックアップ作成
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupName = "$baseName.$timestamp.bak"
$backupPath = Join-Path $dir $backupName

try {
    Rename-Item -Path $TargetFilePath -NewName $backupName -ErrorAction Stop
    Write-Host "バックアップ作成: $backupName" -ForegroundColor Gray
}
catch {
    Write-Error "バックアップ作成に失敗しました。処理を中止します。"
    exit 1
}

# 新ファイル書き出し
try {
    $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($TargetFilePath, $cleanedContent, $Utf8NoBom)
    Write-Host "更新完了: コメントを除去したファイルを生成しました。" -ForegroundColor Green
}
catch {
    Write-Error "ファイルの書き込みに失敗しました。"
    exit 1
}

# ========================================================
# 世代管理
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