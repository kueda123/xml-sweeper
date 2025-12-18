# テストケース出力用ディレクトリ作成
$TestDir = Join-Path $PWD "test_cases"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir | Force | Out-Null }
Write-Host "テストデータを生成しています..." -ForegroundColor Cyan

# [01] 正常
$Content1 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="Normal Server">
    <featureManager>
        <feature>servlet-4.0</feature>
    </featureManager>
</server>
"@
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
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
$NBSP = [char]0x00A0
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
# BOM付きで書き込み
$Utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText((Join-Path $TestDir "04_fix_bom.xml"), $Content4, $Utf8WithBom)

# [05] Messy Format (OK) - スマートクォートを排除
$Content5 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
    <data><![CDATA[ ここはCDATAセクションです。通常の引用符 " " はOKです。 ]]></data>


    </server>
"@
[System.IO.File]::WriteAllText((Join-Path $TestDir "05_messy_format.xml"), $Content5, $Utf8NoBom)

Write-Host "生成完了: 5つのファイルを保存しました。" -ForegroundColor Green