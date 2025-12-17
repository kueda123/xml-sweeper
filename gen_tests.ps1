# テストケース出力用ディレクトリ作成
$TestDir = Join-Path $PWD "test_cases"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir | Force | Out-Null }
Write-Host "テストデータを生成しています..." -ForegroundColor Cyan

# =========================================================
# CASE 1: 正常なファイル
# [期待値] ○ OK (変更なし)
# =========================================================
$Content1 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="Normal Server">
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
$Path1 = Join-Path $TestDir "01_clean.xml"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($Path1, $Content1, $Utf8NoBom)


# =========================================================
# CASE 2: スマートクォート混入
# [期待値] × FATAL ERROR (処理中断)
# =========================================================
$Content2 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description=“MyServer”>
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
$Path2 = Join-Path $TestDir "02_error_smartquote.xml"
[System.IO.File]::WriteAllText($Path2, $Content2, $Utf8NoBom)


# =========================================================
# CASE 3: NBSP (No-Break Space) 混入
# [期待値] ！ 自動修正 (NBSP除去 & 更新)
# =========================================================
$NBSP = [char]0x00A0
$Content3 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <httpEndpoint id="defaultHttpEndpoint"${NBSP}host="*" />
</server>
"@
$Path3 = Join-Path $TestDir "03_fix_nbsp.xml"
[System.IO.File]::WriteAllText($Path3, $Content3, $Utf8NoBom)


# =========================================================
# CASE 4: BOM (Byte Order Mark) 付き
# [期待値] ！ 自動修正 (BOM除去 & 更新)
# =========================================================
$Content4 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="BOM_TEST">
    </server>
"@
$Path4 = Join-Path $TestDir "04_fix_bom.xml"
# BOM付きUTF-8で書き込む
$Utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($Path4, $Content4, $Utf8WithBom)


# =========================================================
# CASE 5: CDATAや大量の空行 (誤検知チェック)
# [期待値] ○ OK (変更なし)
# ※整形機能は廃止されたため、空行もそのまま残るのが正解
# =========================================================
$Content5 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <data><![CDATA[ スマートクォートっぽい記号 “ ” もCDATA内なら無視されるべき？ 
       (※現在の仕様では単純文字列マッチなのでCDATA内でもエラーになる可能性がありますが、
        今回は「誤って消えないか」を確認します) ]]></data>


    </server>
"@
$Path5 = Join-Path $TestDir "05_messy_format.xml"
[System.IO.File]::WriteAllText($Path5, $Content5, $Utf8NoBom)


Write-Host "生成完了: $TestDir に5つのファイルを保存しました。" -ForegroundColor Green
Write-Host "--------------------------------------------------"
Write-Host " [01] 正常 -> OK"
Write-Host " [02] SmartQuote -> FATAL ERROR"
Write-Host " [03] NBSP -> 自動修正"
Write-Host " [04] BOM  -> 自動修正"
Write-Host " [05] Messy -> OK (変更なし)"
Write-Host "--------------------------------------------------"
