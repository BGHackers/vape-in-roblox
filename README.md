
A lightweight utility and runtime framework for Luau (Roblox Lua) environments, powered by an asynchronous, dynamic module loading (Lazy Loading) architecture.

This framework is built to bypass compiler limitations (such as the local register limits) and prevent thread-blocking engine crashes or freezes that commonly occur when executing monolithic scripts exceeding thousands of lines.

## Motivation / Inspiration

This project was heavily inspired by the original VapeV4ForRoblox project developed by 7GrandDadPGN (https://github.com/7GrandDadPGN/VapeV4ForRoblox). Seeing their incredible work and the historical impact of the original repository motivated me to rebuild, revive, and modernize the Vape framework for current Luau environments. 

By restructuring the system, this repository aims to keep the legacy alive while shifting the focus toward modularity, runtime efficiency, and execution stability.

## Features

- **Asynchronous Lazy Loading**
  Instead of compiling everything into a single massive file, modules are split into individual files of a few dozen to a hundred lines and fetched dynamically over HTTP only when needed.
- **VM Crash Prevention**
  Bypasses Luau's strict limits, such as the maximum of 200 local variables per scope, and prevents watchdog timer timeouts that freeze or crash the game client.
- **Automated Developer Workflow**
  Monitors local source files and automatically syncs saved changes to your GitHub repository. You no longer need to wait for local bundlers (like luabundler) to compile before testing.

## Repository Structure

The project is modularly structured as follows:
```text
├── .github/
│   └── workflows/          # Optional CI/CD configurations for automated builds
├── src/
│   ├── games/              # Game-specific script definitions
│   │   └── game1/          # Targeted game directory
│   │       ├── base.lua    # Auto-generated: Module list and index registry
│   │       └── modules/    # Categorized functional modules
│   │           ├── combat/
│   │           ├── Render/
│   │           └── Utility/
│   └── Main.lua            # Main entry point (Loader Bootstrap)
├── auto-push.js            # Auto-sync tool: Developer sync utility (Pushes to Git on save)
└── package.json            # Node.js project settings
```

## How to Run (Loader Bootstrap)

Execute the following loader bootstrap script inside your execution environment.
Important: Please change YOUR_USERNAME and YOUR_REPO_NAME to your actual GitHub account and repository names before running.

```lua
local HttpService = game:GetService("HttpService")
local BaseUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main/src/"

local moduleCache = {}

local function httpRequire(path)
    if moduleCache[path] then return moduleCache[path] end
    local fileUrl = BaseUrl .. path
    if not string.match(fileUrl, "%.lua$") then fileUrl = fileUrl .. ".lua" end

    local success, response = pcall(function() return game:HttpGet(fileUrl) end)
    if not success or not response then error("Failed to load: " .. path) end

    local chunk, err = loadstring(response)
    if not chunk then error("Compile error (" .. path .. "): " .. tostring(err)) end

    local result = chunk()
    moduleCache[path] = result
    return result
end

-- Fetch the module index for "game1"
local base = httpRequire("games/game1/base")

-- Dynamically load and initiate modules for each category
for category, modules in pairs(base) do
    for _, modulePath in ipairs(modules) do
        task.spawn(function()
            pcall(function() httpRequire(modulePath) end)
        end)
    end
end
```

## Developer Setup & Workflow
Follow these steps to set up the local file watcher that automatically pushes your code changes to GitHub.

## 1. Install Dependencies
Run the following command in your project's root directory:
```bash
npm install
```

## 3. Run the Auto-Sync Watcher
Start the file watcher. It will monitor your ./src folder and automatically run git push if no modifications are detected for 5 seconds after your last save.

```bash
npm run watch-push
```

## License
This project is licensed under the MIT License.


### 日本語版 (README.md - Japanese Version)


Luau (Roblox Lua) 環境向けの、非同期・動的モジュールロード (Lazy Loading) を採用した軽量なユーティリティ・ランタイムフレームワークです。

数千行を超える巨大なスクリプトを実行した際に発生する、VM（仮想マシン）のコンパイル制限（ローカル変数登録制限）や、メインスレッド占有によるクラッシュ・フリーズ問題を根本から解決するために設計されています。

## 開発のきっかけ (Motivation / Inspiration)

このプロジェクトは、7GrandDadPGN氏によるオリジナルの VapeV4ForRoblox プロジェクト (https://github.com/7GrandDadPGN/VapeV4ForRoblox) から強い影響を受けて作成されました。彼の素晴らしい開発成果や、そのリポジトリがコミュニティにもたらしたインパクトを目にしたことで、現在のLuau環境に向けてVapeフレームワークを再構築・復活させ、近代化させたいと考えたことが開発のきっかけです。

システム構造を根本から刷新することで、オリジナルのレガシー（遺産）を維持しつつ、コードのモジュール化、動作の効率化、そして実行時における圧倒的な安定性の確保を追求しています。

## 特徴 (Features)

- **非同期・動的ロード (Lazy Loading / Asynchronous Loading)**
  すべてのコードを1つの大きなファイルに結合するのではなく、機能ごとに数十〜数百行単位のモジュールに分割し、必要に応じてGitHubから個別に取得・実行します。
- **VM制限の回避**
  Luauの「1スコープ内のローカル変数上限（200個）」や、処理の過密によるコンパイルタイムアウト（ゲームエンジンの強制終了やハングアップ）を防ぎます。
- **自動同期デベロッパーワークフロー**
  ローカルのソースファイルを監視し、保存された変更を自動的にGitHubに同期します。bundlerによるビルド完了を待つ必要がありません。

---

## フォルダ構成 (Repository Structure)

リポジトリは以下のようにモジュール化されて管理されます。
```text
├── .github/
│   └── workflows/          # 自動ビルドや管理用のCI/CD設定（オプション）
├── src/
│   ├── games/              # 各ゲーム専用のスクリプト定義
│   │   └── game1/          # ゲームごとの識別フォルダ
│   │       ├── base.lua    # 自動生成：カテゴリと所属モジュールの一覧
│   │       └── modules/    # 機能別のモジュール群
│   │           ├── combat/
│   │           ├── Render/
│   │           └── Utility/
│   └── Main.lua            # ローダー（エントリポイント）
├── auto-push.js            # 自動同期ツール（保存時にGitHubへ自動送信）
└── package.json            # 開発パッケージ設定
```

## 実行方法 (How to Run / Loader Bootstrap)
ゲーム内またはエグゼキューター等から、以下のローダースクリプトを実行してロードします。
重要: 実行前に、スクリプト内の YOUR_USERNAME と YOUR_REPO_NAME をご自身のGitHubのアカウント名およびリポジトリ名に書き換えてください。

```lua
local HttpService = game:GetService("HttpService")
local BaseUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main/src/"

local moduleCache = {}

local function httpRequire(path)
    if moduleCache[path] then return moduleCache[path] end
    local fileUrl = BaseUrl .. path
    if not string.match(fileUrl, "%.lua$") then fileUrl = fileUrl .. ".lua" end

    local success, response = pcall(function() return game:HttpGet(fileUrl) end)
    if not success or not response then error("Failed to load: " .. path) end

    local chunk, err = loadstring(response)
    if not chunk then error("Compile error (" .. path .. "): " .. tostring(err)) end

    local result = chunk()
    moduleCache[path] = result
    return result
end

-- ゲーム1用のモジュールを読み込み
local base = httpRequire("games/game1/base")

-- 各カテゴリごとに登録されているモジュールを1つずつ安全にロード
for category, modules in pairs(base) do
    for _, modulePath in ipairs(modules) do
        task.spawn(function()
            pcall(function() httpRequire(modulePath) end)
        end)
    end
end
```

## 開発環境セットアップ (Developer Setup & Workflow)
コードを編集してGitHubに自動的に反映させるためのローカル開発手順です。
1. ## 依存関係のインストール
プロジェクトのルートディレクトリで以下を実行します。

```bash
npm install
```

## 2. 自動同期の起動
ファイル変更を検知して自動的にGitHubへプッシュする監視スクリプトを起動します（保存してから5秒間次の変更がなければ、自動的に git push が実行されます）。
```bash
npm run watch-push
```
# ライセンス (License)
 このプロジェクトは MIT License のもとで公開されています。
