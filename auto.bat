<# :
@echo off
title Lua/Txt Recursive Overwrite Comment Remover

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

# 1. サブフォルダも含めて、処理対象ファイルを自動で再帰検索
if ($target) {
    if (Test-Path -Path $target -PathType Container) {
        # フォルダがドラッグされた場合：そのフォルダ内（サブフォルダ含む）を再帰探索
        Write-Host "ドラッグされたフォルダ内（サブフォルダ含む）を再帰検索中..." -ForegroundColor Yellow
        $filesToProcess = Get-ChildItem -Path $target -File -Recurse | Where-Object {
            $_.Extension -match '^\.(lua|txt)$' -and
            $_.FullName -notmatch '[/\\].git([/\\]|$)' -and
            $_.FullName -notmatch '[/\\]node_modules([/\\]|$)'
        }
    } else {
        # 単一ファイルがドラッグされた場合
        $filesToProcess = Get-Item -LiteralPath $target
    }
} else {
    # ダブルクリックされた場合：BATがあるフォルダ内（サブフォルダ含む）を自動で再帰探索
    Write-Host "BATがあるフォルダ内（サブフォルダ含む）から自動再帰検索中..." -ForegroundColor Yellow
    $filesToProcess = Get-ChildItem -Path $batDir -File -Recurse | Where-Object {
        $_.Extension -match '^\.(lua|txt)$' -and
        $_.FullName -notmatch '[/\\].git([/\\]|$)' -and
        $_.FullName -notmatch '[/\\]node_modules([/\\]|$)'
    }
}

# 対象ファイルが見つからなかった場合の処理
if ($filesToProcess.Count -eq 0) {
    Write-Host "対象となる .lua または .txt ファイルが見つかりませんでした。" -ForegroundColor Red
    Read-Host "Enterキーを押して終了してください..."
    exit
}

Write-Host ("{0} 個の対象ファイルが見つかりました（サブフォルダ含む）。直接上書きを開始します..." -f $filesToProcess.Count) -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

# 2. 集めたすべてのファイルを順次上書きクリーンアップ
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

    # 元のファイルへ直接上書き保存
    [System.IO.File]::WriteAllText($filePath, $cleaned, [System.Text.Encoding]::UTF8)
    
    # どの階層のファイルが処理されたか分かりやすいよう相対パスで表示します
    $relativePath = $filePath
    if ($filePath.StartsWith($batDir)) {
        $relativePath = $filePath.Substring($batDir.Length).TrimStart('[/\]')
    }
    Write-Host "【上書き完了】 $relativePath" -ForegroundColor Green
}

Write-Host "--------------------------------------------------"
Write-Host "サブフォルダを含むすべてのファイルを直接上書きしました！" -ForegroundColor Green
Start-Sleep -Seconds 3