<# :
@echo off
title Lua Comment Remover

if "%~1" == "" goto :NoArgs

set "TARGET_FILE=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Encoding UTF8 | Out-String))"
goto :EOF

:NoArgs
echo ====================================================
echo  Please drag and drop your Lua file onto this BAT.
echo ====================================================
echo.
pause
goto :EOF
#>

$filePath = $env:TARGET_FILE
if (-not $filePath -or -not (Test-Path -LiteralPath $filePath)) {
    # 念のためPowerShellの文字出力をUTF-8に固定
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host "ファイルが見つかりません。" -ForegroundColor Red
    Read-Host "Enterキーを押して終了してください..."
    exit
}

# ファイルを読み込み
$content = Get-Content -LiteralPath $filePath -Raw

# 文字列内の "--" を保護しつつ、コメントとしての "--" 以降を除去する正規表現
$pattern = '("[^"\\]*(?:\\.[^"\\]*)*"|''[^''\\]*(?:\\.[^''\\]*)*'')|--.*'
$cleaned = [regex]::Replace($content, $pattern, {
    param($match)
    if ($match.Groups[1].Success) {
        return $match.Groups[1].Value # 文字列はそのまま残す
    }
    return "" # コメントは消去
})

# 行末に残った余分なスペースを削除
$cleaned = $cleaned -replace '(?m)[ \t]+$', ''

# コメントのみが消えて「完全に空行」になった行を詰めてスッキリさせる
$cleaned = $cleaned -replace '(?m)^\s*\r?\n', ''

# 保存先パスの生成
$directory = [System.IO.Path]::GetDirectoryName($filePath)
$filename = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
$extension = [System.IO.Path]::GetExtension($filePath)
$outputPath = Join-Path $directory "$filename`_no_comments$extension"

# UTF-8（BOMなし）で新規ファイルとして保存
[System.IO.File]::WriteAllText($outputPath, $cleaned, [System.Text.Encoding]::UTF8)

# 出力文字コードをUTF-8に設定してメッセージを表示
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "クリーンアップが完了しました！" -ForegroundColor Green
Write-Host "作成されたファイル: $outputPath"
Start-Sleep -Seconds 2