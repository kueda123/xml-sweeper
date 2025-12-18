# テストケース出力用ディレクトリ作成
$TestDir = Join-Path $PWD "test_cases"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir | Force | Out-Null }
Write-Host "テストデータを生成しています..." -ForegroundColor Cyan

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$Utf8WithBom = New-Object System.Text.UTF8Encoding $true
$NBSP = [char]0x00A0

# [01] 正常
$Content1 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="Normal Server">
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "01_clean.xml"), $Content1, $Utf8NoBom)

# [02] スマートクォート (Fail)
$Content2 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description=“MyServer”>
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "02_error_smartquote.xml"), $Content2, $Utf8NoBom)

# [03] NBSP (Auto-Fix)
$Content3 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <httpEndpoint id="defaultHttpEndpoint"${NBSP}host="*" />
</server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "03_fix_nbsp.xml"), $Content3, $Utf8NoBom)

# [04] BOM (Auto-Fix)
$Content4 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="BOM_TEST">
    </server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "04_fix_bom.xml"), $Content4, $Utf8WithBom)

# [05] Messy Format (OK)
$Content5 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <data><![CDATA[ スマートクォートっぽい記号 " " はOK ]]></data>


    </server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "05_messy_format.xml"), $Content5, $Utf8NoBom)

# ---------------------------------------------------------
# [06] BOM + Multiple NBSP (複合汚染)
# ---------------------------------------------------------
# BOM付きで保存し、かつ複数のNBSPを混入させる
$Content6 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <variable name="Path1" value="C:\Program${NBSP}Files" />
    <variable name="Path2" value="D:\Data${NBSP}Center" />
</server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "06_bom_multi_nbsp.xml"), $Content6, $Utf8WithBom)


Write-Host "生成完了: 6つのファイルを保存しました。" -ForegroundColor Green