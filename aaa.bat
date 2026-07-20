<# :
@echo off
title Lua/Txt Overwrite Comment Remover

set "BAT_DIR=%~dp0"
set "TARGET_FILE=%~1"

powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Encoding UTF8 | Out-String))"
goto :EOF
#>

# PowerShell出力の文字コードをUTF-8に固定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$target = $env:TARGET_FILE
$batDir = $env:BAT_DIR
$filesToProcess = @()

# 1. 処理対象ファイルを自動検索して集める
if ($target) {
    if (Test-Path -Path $target -PathType Container) {
        # フォルダがドラッグ＆ドロップされた場合：そのフォルダ内を検索
        Write-Host "ドラッグされたフォルダ内を検索中..." -ForegroundColor Yellow
        $filesToProcess = Get-ChildItem -Path $target -File | Where-Object { $_.Extension -match '^\.(lua|txt)$' }
    } else {
        # 単一ファイルがドラッグ＆ドロップされた場合
        $filesToProcess = Get-Item -LiteralPath $target
    }
} else {
    # ダブルクリックされた場合：BATファイルと同じフォルダ内を自動検索
    Write-Host "BATファイルと同じフォルダ内から対象ファイルを自動検索中..." -ForegroundColor Yellow
    $filesToProcess = Get-ChildItem -Path $batDir -File | Where-Object { $_.Extension -match '^\.(lua|txt)$' }
}

# 対象ファイルが見つからなかった場合の処理
if ($filesToProcess.Count -eq 0) {
    Write-Host "対象となる .lua または .txt ファイルが見つかりませんでした。" -ForegroundColor Red
    Read-Host "Enterキーを押して終了してください..."
    exit
}

Write-Host ("{0} 個の対象ファイルが見つかりました。直接上書きを開始します..." -f $filesToProcess.Count) -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

# 2. 集めたファイルを順次上書きクリーンアップ
foreach ($file in $filesToProcess) {
    $filePath = $file.FullName
    $content = Get-Content -LiteralPath $filePath -Raw

    # コメント削除用の正規表現
    $pattern = '("[^"\\]*(?:\\.[^"\\]*)*"|''[^''\\]*(?:\\.[^''\\]*)*'')|--.*'
    $cleaned = [regex]::Replace($content, $pattern, {
        param($match)
        if ($match.Groups[1].Success) {
            return $match.Groups[1].Value # 文字列は残す
        }
        return "" # コメントは消去
    })

    # フォーマットをきれいに整える
    $cleaned = $cleaned -replace '(?m)[ \t]+$', '' # 行末スペース削除
    $cleaned = $cleaned -replace '(?m)^\s*\r?\n', '' # 不要な空行の圧縮

    # 元のファイル名（同じファイルパス）へ直接上書き保存
    [System.IO.File]::WriteAllText($filePath, $cleaned, [System.Text.Encoding]::UTF8)
    Write-Host "【上書き完了】 $($file.Name)" -ForegroundColor Green
}

Write-Host "--------------------------------------------------"
Write-Host "すべてのファイルを元の名前で直接上書きしました！" -ForegroundColor Green
Start-Sleep -Seconds 3