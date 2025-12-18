# テストケース出力用ディレクトリ作成
$TestDir = Join-Path $PWD "test_cases"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir | Force | Out-Null }
Write-Host "テストデータを生成しています..." -ForegroundColor Cyan

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$Utf8WithBom = New-Object System.Text.UTF8Encoding $true
$NBSP = [char]0x00A0

# =========================================================
# [01] 正常 (LF改行のみ)
# =========================================================
$Content1 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="Normal Server">
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
# ヒア文字列はファイルの改行コードに依存するため、念のためLFに統一
$Content1 = $Content1 -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "01_clean.xml"), $Content1, $Utf8NoBom)


# =========================================================
# [02] スマートクォート (Fail)
# =========================================================
# ヒア文字列を使うことで、中の " や “ ” が競合しなくなります
$Content2 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description=“MyServer”>
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
$Content2 = $Content2 -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "02_error_smartquote.xml"), $Content2, $Utf8NoBom)


# =========================================================
# [03] NBSP (Auto-Fix)
# =========================================================
$Content3 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <httpEndpoint id="defaultHttpEndpoint"${NBSP}host="*" />
</server>
"@
$Content3 = $Content3 -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "03_fix_nbsp.xml"), $Content3, $Utf8NoBom)


# =========================================================
# [04] BOM (Auto-Fix)
# =========================================================
$Content4 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="BOM_TEST">
    </server>
"@
$Content4 = $Content4 -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "04_fix_bom.xml"), $Content4, $Utf8WithBom)


# =========================================================
# [05] CRLF混入 (Windows Style) -> Auto-Fix to LF
# =========================================================
# 明示的に CRLF (`r`n) を混入させます
$Content5 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    </server>
"@
# LFがあれば CRLF に強制変換して、Windows形式の状態を作る
$Content5 = $Content5 -replace "`r`n", "`n" -replace "`n", "`r`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "05_fix_crlf.xml"), $Content5, $Utf8NoBom)


# =========================================================
# [06] 複合汚染 (BOM + NBSP + CRLF)
# =========================================================
$Content6 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <variable name="Path1" value="C:\Program${NBSP}Files" />
</server>
"@
# CRLF化
$Content6 = $Content6 -replace "`r`n", "`n" -replace "`n", "`r`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "06_mixed_mess.xml"), $Content6, $Utf8WithBom)


# =========================================================
# [07] CSVファイル (検査対象だがCRLF維持) + BOM
# =========================================================
# CSVは CRLF のまま出力されるべき（BOMのみ除去される）
$Content7 = @"
id,value
1,test
2,hello
"@
# CRLF化
$Content7 = $Content7 -replace "`r`n", "`n" -replace "`n", "`r`n"
[System.IO.File]::WriteAllText((Join-Path $TestDir "07_config.csv"), $Content7, $Utf8WithBom)


# =========================================================
# [08] バックアップファイル (.bak) -> SKIPされるべき
# =========================================================
$Content8 = "This is backup file content."
[System.IO.File]::WriteAllText((Join-Path $TestDir "08_ignore_me.bak"), $Content8, $Utf8NoBom)


Write-Host "生成完了: 8つのファイルを保存しました。" -ForegroundColor Green
