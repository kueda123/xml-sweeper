# テストケース出力用ディレクトリ作成
$TestDir = Join-Path $PWD "test_cases"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir | Out-Null }
Write-Host "テストデータを生成しています..." -ForegroundColor Cyan


# ---------------------------------------------------------
# CASE 1: 標準的な汚れファイル (正常に削除されるべき)
# ---------------------------------------------------------
$Content1 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
<featureManager>
<feature>servlet-4.0</feature>
</featureManager>
</server>
"@
$Path1 = Join-Path $TestDir "01_normal_dirty.xml"
[System.IO.File]::WriteAllText($Path1, $Content1, [System.Text.Encoding]::UTF8)


# ---------------------------------------------------------
# CASE 2: すでに綺麗なファイル (変更なし・スキップされるべき)
# ---------------------------------------------------------
$Content2 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
<featureManager>
<feature>servlet-4.0</feature>
</featureManager>
</server>
"@
$Path2 = Join-Path $TestDir "02_already_clean.xml"
[System.IO.File]::WriteAllText($Path2, $Content2, [System.Text.Encoding]::UTF8)


# ---------------------------------------------------------
# CASE 3: 不正なスマートクォート (エラーで停止すべき)
# ---------------------------------------------------------
$Content3 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description=“MyServer”>
<featureManager>
<feature>servlet-4.0</feature>
</featureManager>
</server>
"@
$Path3 = Join-Path $TestDir "03_error_smartquote.xml"
[System.IO.File]::WriteAllText($Path3, $Content3, [System.Text.Encoding]::UTF8)


# ---------------------------------------------------------
# CASE 4: CDATAセクション (削除されてはいけない)
# ---------------------------------------------------------
$Content4 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>
<data><![CDATA[ ここは重要なデータです ]]></data>
</server>
"@
$Path4 = Join-Path $TestDir "04_cdata_preserve.xml"
[System.IO.File]::WriteAllText($Path4, $Content4, [System.Text.Encoding]::UTF8)


# ---------------------------------------------------------
# CASE 5: 大量の改行とコメント (整形能力のテスト)
# ---------------------------------------------------------
$Content5 = @"
<?xml version="1.0" encoding="UTF-8"?>
<server>


&lt;featureManager&gt;
    &lt;feature&gt;servlet-4.0&lt;/feature&gt;
&lt;/featureManager&gt;


&lt;/server&gt;

    
  

"@
$Path5 = Join-Path $TestDir "05_multiline_spaces.xml"
[System.IO.File]::WriteAllText($Path5, $Content5, [System.Text.Encoding]::UTF8)


Write-Host "生成完了: $TestDir に5つのファイルを保存しました。" -ForegroundColor Green