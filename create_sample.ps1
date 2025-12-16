# 作成するファイル名
$FileName = "sample-server.xml"

# テスト用のXMLコンテンツ
# 日本語、複数行コメント、タグの間のコメントなどを含めています
$XmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<server description="Debug Server">

    <featureManager>
        <feature>jsp-2.3</feature>
        <feature>servlet-4.0</feature> </featureManager>

    <application id="TestApp" location="test.war" type="war"/>

</server>
"@

# カレントディレクトリに保存
$FilePath = Join-Path $PWD $FileName

# UTF-8でファイルを書き出し
# (Set-ContentはデフォルトでUTF-8 BOM付きになることが多いですが、テストには十分です)
Set-Content -Path $FilePath -Value $XmlContent -Encoding UTF8

Write-Host "--------------------------------------------------"
Write-Host "サンプルファイルを作成しました: $FilePath" -ForegroundColor Green
Write-Host "このファイルを xml-sweeper.bat にドラッグ＆ドロップして動作確認してください。"
Write-Host "--------------------------------------------------"

Start-Sleep -Seconds 3