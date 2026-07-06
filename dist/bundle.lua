-- Bundled by luabundle {"version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/Main.lua
local assets = require("utils.AssetLoader") -- 🌟 アセットローダー（ロード関数を内包）
local WindowFactory = require("gui.WindowFactory")
local Tooltip = require("gui.Tooltip")
local Sidebar = require("gui.Sidebar")
local LoadingScreen = require("gui.LoadingScreen") -- 🌟 連動型ローディング画面

-- 🌟 実際のファイルシステム（src/hud/）に合わせた正しいインポートパスに戻しました
local SessionInfo = require("hud.SessionInfo")
local SettingsInfo = require("hud.SettingsInfo")
local Tutorial = require("hud.Tutorial")

local ModuleWindow = require("gui.ModuleWindow")
local moduleRegistry = require("games.GameRegistry").getModules()
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ==========================================
-- 🌟 グローバル設定テーブルと変更イベントの初期化
-- ==========================================
shared.VapeSettings = shared.VapeSettings or {
    BlurBackground = true,     -- 背景ブラーをかけるか
    ShowTooltips = true,       -- ツールチップを表示するか
    GPUBindIndicator = true,   -- GUIバインドインジケーターを表示するか
    ShowLegitMode = false      -- レジットモード（ONの時はBlatantタブを隠す）
}
shared.VapeSettingsChanged = shared.VapeSettingsChanged or Instance.new("BindableEvent")

local function getOrCreateScreenGui()
    local coreGui = game:GetService("CoreGui")
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui

    local existing = coreGui:FindFirstChild("VapeV4SidebarContainer")
        or playerGui:FindFirstChild("VapeV4SidebarContainer")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VapeV4SidebarContainer"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true -- 🌟 これを追記して、上部の隙間を無くし完全に画面全体を覆います！

    local success = pcall(function()
        gui.Parent = coreGui
    end)
    if not success then
        gui.Parent = playerGui
    end

    return gui
end

local ScreenGui = getOrCreateScreenGui()

-- 各ウィンドウの初期X座標の定義
local spacing = 15
local sidebarWidth = 220
local sidebarX = 15

-- 指定された並び順に配置座標を計算 (Combat, Blatant, Render, Utility, World, Inventory, Minigames)
local combatX = sidebarX + sidebarWidth + spacing      -- 250
local blatantX = combatX + sidebarWidth + spacing     -- 485
local renderX = blatantX + sidebarWidth + spacing       -- 720
local utilityX = renderX + sidebarWidth + spacing     -- 955
local worldX = utilityX + sidebarWidth + spacing       -- 1190
local inventoryX = worldX + sidebarWidth + spacing     -- 1425
local minigamesX = inventoryX + sidebarWidth + spacing   -- 1660

-- 開閉状態の初期変数
local visible = false
local sessionVisible = true
local settingsVisible = false
local TWEEN_INFO = TweenInfo.new(1 / 240 * 12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ==========================================
-- 🌟 ブラー（ぼかし）効果の自動生成
-- ==========================================
local function setupBlurEffect()
    local lighting = game:GetService("Lighting")
    local blur = lighting:FindFirstChild("VapeBlurEffect")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "VapeBlurEffect"
        blur.Size = 15
        blur.Enabled = false
        blur.Parent = lighting
    end
end
setupBlurEffect()

-- ==========================================
-- 🌟 アセットダウンロード開始と、完了後のUI生成処理
-- ==========================================
LoadingScreen.show(ScreenGui, assets, function()
-- src/Main.lua の LoadingScreen.show 内

    -- 🌟 【修正】空のモック関数「UpdateTextGUI」を追加し、
    -- モジュール切り替え時に発生していた missing method クラッシュを解決します。
    local Notification = require("gui.Notification")
    _G.mainapi = {
        CreateNotification = function(self, title, text, duration, notifType)
            Notification.create(ScreenGui, title, text, duration, notifType)
        end,
        UpdateTextGUI = function(self, ...)
            -- 🌟 【追加】クラッシュを完全に防止するための空の関数
        end,
        -- 各パーツ（ColorPickerなど）のエラーを防ぐための共通テーブルを定義
        RainbowTable = {},
        GUIColor = { Hue = 0.44, Sat = 1, Value = 1 }
    }
    shared.vape = _G.mainapi -- 互換性確保用



    -- すべてのベースウィンドウ（Container）の定義
    local MainContainer, MainFrame, SidebarHeader = WindowFactory.createBaseWindow(ScreenGui, "Main", UDim2.new(0, sidebarWidth, 0, 470), UDim2.new(0, sidebarX, 0.2, 0))
    local SessionContainer, SessionFrame, SessionHeader = WindowFactory.createBaseWindow(ScreenGui, "Session", UDim2.new(0, sidebarWidth, 0, 120), UDim2.new(0, sidebarX, 0, 500))
    local SettingsContainer, SettingsFrame, SettingsHeader = WindowFactory.createBaseWindow(ScreenGui, "Settings", UDim2.new(0, sidebarWidth, 0, 160), UDim2.new(0, 240, 0, 10))
    SettingsContainer.Visible = false
    local TutorialContainer, TutorialFrame, TutorialHeader = WindowFactory.createBaseWindow(ScreenGui, "Tutorial", UDim2.new(0, 260, 0, 220), UDim2.new(0.5, -130, 0.4, -110))

    -- 各ウィンドウ（Container）の生成（ダウンロードされたアイコンアセットが確実に渡されます）
    local CombatWindow = ModuleWindow.new(
        ScreenGui, "Combat", 
        UDim2.new(0, sidebarWidth, 0, 470), 
        UDim2.new(0, combatX, 0.2, 0),
        assets.combat, assets
    )

    local BlatantWindow = ModuleWindow.new(
        ScreenGui, "Blatant", 
        UDim2.new(0, sidebarWidth, 0, 470), 
        UDim2.new(0, blatantX, 0.2, 0),
        assets.blatant, assets
    )

    local RenderWindow = ModuleWindow.new(
        ScreenGui, "Render", 
        UDim2.new(0, sidebarWidth, 0, 300), 
        UDim2.new(0, renderX, 0.2, 0),
        assets.render, assets
    )

    local UtilityWindow = ModuleWindow.new(
        ScreenGui, "Utility", 
        UDim2.new(0, sidebarWidth, 0, 300), 
        UDim2.new(0, utilityX, 0.2, 0),
        assets.utility, assets
    )

    local WorldWindow = ModuleWindow.new(
        ScreenGui, "World",
        UDim2.new(0, sidebarWidth, 0, 300),
        UDim2.new(0, worldX, 0.2, 0),
        assets.world or assets.World, assets
    )

    local InventoryWindow = ModuleWindow.new(
        ScreenGui, "Inventory",
        UDim2.new(0, sidebarWidth, 0, 300),
        UDim2.new(0, inventoryX, 0.2, 0),
        assets.inventory or assets.Inventory or assets.inventry or assets.Inventry, assets
    )

    local MinigamesWindow = ModuleWindow.new(
        ScreenGui, "Minigames",
        UDim2.new(0, sidebarWidth, 0, 300),
        UDim2.new(0, minigamesX, 0.2, 0),
        assets.minigames or assets.Minigames, assets
    )

    -- モジュールのロード
    local function loadModules(window, list)
        if not list then return end
        for _, mod in ipairs(list) do
            local moduleObj = window:CreateModule(mod.Name, mod.Description, mod.Callback)
            if type(mod.Init) == "function" then
                mod.Init(moduleObj)
            end
        end
    end

    loadModules(CombatWindow, moduleRegistry.combat)
    loadModules(BlatantWindow, moduleRegistry.blatant)
    loadModules(RenderWindow, moduleRegistry.Render)
    loadModules(UtilityWindow, moduleRegistry.Utility)
    loadModules(WorldWindow, moduleRegistry.World)
    loadModules(InventoryWindow, moduleRegistry.Inventory or moduleRegistry.inventry)
    loadModules(MinigamesWindow, moduleRegistry.Minigames)

    -- ツールチップとサイドバー初期化
    local VapeTooltip, tLabel = Tooltip.create(ScreenGui)
    local SettingsBtn, SessionToggleBtn, tabs = Sidebar.init(MainFrame, assets, VapeTooltip, tLabel)

    SessionInfo.init(SessionFrame)
    SettingsInfo.init(SettingsFrame)
    Tutorial.init(TutorialFrame, TutorialHeader)

    -- ドラッグのセットアップ
    WindowFactory.setupDraggable(MainContainer, MainFrame)
    WindowFactory.setupDraggable(SessionContainer, SessionFrame)
    WindowFactory.setupDraggable(SettingsContainer, SettingsFrame)
    WindowFactory.setupDraggable(TutorialContainer, TutorialFrame)

    local mainTitle = SidebarHeader:FindFirstChild("Title")
    if mainTitle then mainTitle.Visible = false end

    -- コンテナのアニメーション関数
    local function animateContainer(container, show)
        local targetTransparency = show and 0 or 1
        local mainFrame = container:FindFirstChild("MainFrame")
        local shadow = container:FindFirstChild("Shadow")

        if mainFrame and mainFrame:IsA("CanvasGroup") then
            TweenService:Create(mainFrame, TWEEN_INFO, {GroupTransparency = targetTransparency}):Play()
            local stroke = mainFrame:FindFirstChildOfClass("UIStroke")
            if stroke then
                TweenService:Create(stroke, TWEEN_INFO, {Transparency = targetTransparency}):Play()
            end
        end

        if shadow and shadow:IsA("ImageLabel") then
            local targetShadowTransparency = show and 0.2 or 1
            TweenService:Create(shadow, TWEEN_INFO, {ImageTransparency = targetShadowTransparency}):Play()
        end

        if show then
            container.Visible = true
        else
            task.delay(TWEEN_INFO.Time, function()
                if not show then
                    container.Visible = false
                end
            end)
        end
    end

    -- タブのバインド
    if tabs then
        if tabs.Combat then tabs.Combat.MouseButton1Click:Connect(function() CombatWindow:Toggle() end) end
        if tabs.Blatant then tabs.Blatant.MouseButton1Click:Connect(function() BlatantWindow:Toggle() end) end
        if tabs.Render then tabs.Render.MouseButton1Click:Connect(function() RenderWindow:Toggle() end) end
        if tabs.Utility or tabs.utility then
            local utilTab = tabs.Utility or tabs.utility
            utilTab.MouseButton1Click:Connect(function() UtilityWindow:Toggle() end)
        end
        if tabs.World or tabs.world then
            local worldTab = tabs.World or tabs.world
            worldTab.MouseButton1Click:Connect(function() WorldWindow:Toggle() end)
        end
        if tabs.Inventory or tabs.inventry or tabs.Inventry then
            local invTab = tabs.Inventory or tabs.inventry or tabs.Inventry
            invTab.MouseButton1Click:Connect(function() InventoryWindow:Toggle() end)
        end
        if tabs.Minigames or tabs.minigames then
            local miniTab = tabs.Minigames or tabs.minigames
            miniTab.MouseButton1Click:Connect(function() MinigamesWindow:Toggle() end)
        end
    end

    -- セッションボタンバインド
    SessionToggleBtn.MouseButton1Click:Connect(function()
        sessionVisible = not SessionContainer.Visible
        animateContainer(SessionContainer, sessionVisible)
    end)

    -- 設定ボタンバインド
    SettingsBtn.MouseButton1Click:Connect(function()
        settingsVisible = not SettingsContainer.Visible
        animateContainer(SettingsContainer, settingsVisible)
    end)

    -- ウィンドウの状態記憶
    local savedWindowStates = {
        Combat = false,
        Blatant = false,
        Render = false,
        Utility = false,
        World = false,
        Inventory = false,
        Minigames = false
    }

    -- 設定連動ハンドラー
    local connection
    connection = shared.VapeSettingsChanged.Event:Connect(function(settingName, value)
        if settingName == "BlurBackground" then
            local blurEffect = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
            if blurEffect then
                blurEffect.Enabled = visible and value
            end
        elseif settingName == "GPUBindIndicator" then
            for _, desc in ipairs(ScreenGui:GetDescendants()) do
                if desc:IsA("TextLabel") and (desc.Name == "BindText" or desc.Name == "BindLabel" or desc.Name == "Keybind" or desc.Text:match("^%[.+%]$")) then
                    desc.Visible = value
                end
            end
        elseif settingName == "ShowLegitMode" then
            if tabs and tabs.Blatant then
                tabs.Blatant.Visible = not value
            end
            if value and BlatantWindow.Visible then
                BlatantWindow:Animate(false)
            end
        end
    end)

    -- キー入力によるUI全体の開閉イベント
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            visible = not visible

            animateContainer(MainContainer, visible)

            if not visible then
                savedWindowStates.Combat = CombatWindow.Visible
                savedWindowStates.Blatant = BlatantWindow.Visible
                savedWindowStates.Render = RenderWindow.Visible
                savedWindowStates.Utility = UtilityWindow.Visible
                savedWindowStates.World = WorldWindow.Visible
                savedWindowStates.Inventory = InventoryWindow.Visible
                savedWindowStates.Minigames = MinigamesWindow.Visible

                if CombatWindow.Visible then CombatWindow:Animate(false) end
                if BlatantWindow.Visible then BlatantWindow:Animate(false) end
                if RenderWindow.Visible then RenderWindow:Animate(false) end
                if UtilityWindow.Visible then UtilityWindow:Animate(false) end
                if WorldWindow.Visible then WorldWindow:Animate(false) end
                if InventoryWindow.Visible then InventoryWindow:Animate(false) end
                if MinigamesWindow.Visible then MinigamesWindow:Animate(false) end
            end

            if visible then
                if sessionVisible then animateContainer(SessionContainer, true) end
                if settingsVisible then animateContainer(SettingsContainer, true) end

                if savedWindowStates.Combat then CombatWindow:Animate(true) end
                if savedWindowStates.Blatant and not shared.VapeSettings.ShowLegitMode then 
                    BlatantWindow:Animate(true) 
                end
                if savedWindowStates.Render then RenderWindow:Animate(true) end
                if savedWindowStates.Utility then UtilityWindow:Animate(true) end
                if savedWindowStates.World then WorldWindow:Animate(true) end
                if savedWindowStates.Inventory then InventoryWindow:Animate(true) end
                if savedWindowStates.Minigames then MinigamesWindow:Animate(true) end
            else
                sessionVisible = SessionContainer.Visible
                if sessionVisible then animateContainer(SessionContainer, false) end

                settingsVisible = SettingsContainer.Visible
                if settingsVisible then animateContainer(SettingsContainer, false) end
            end

            if TutorialContainer.Parent then
                animateContainer(TutorialContainer, visible)
            end

            local blurEffect = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
            if blurEffect then
                blurEffect.Enabled = visible and shared.VapeSettings.BlurBackground
            end
        end
    end)

    -- 🌟 100%ロード完了したため、メインUIを画面にふわっとフェードイン表示します
    visible = true
    sessionVisible = true
    animateContainer(MainContainer, true)
    animateContainer(SessionContainer, true)
    if TutorialContainer.Parent then
        animateContainer(TutorialContainer, true)
    end

    -- 初期ブラーの状態反映
    local blurEffect = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
    if blurEffect then
        blurEffect.Enabled = shared.VapeSettings.BlurBackground
    end
end)

print("Vape V4 Sidebar: Fully Loaded with 연동 Loading Screen & Assets!")
end)
__bundle_register("gui.Notification", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/Notification.lua
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local Notification = {}

-- 🌟 フォルダ名（vape / vape_GameName）を AssetLoader.lua と完全に同じロジックで自動解決
local function getAsset(fileName)
    local isfolder = isfolder or function(path)
        local success, _ = pcall(listfiles, path)
        return success
    end
    local gameName = "Game"
    if game.PlaceId == 6872274481 or game.PlaceId == 6872265039 or game.PlaceId == 14247545801 then
        gameName = "BedWars"
    else
        local success, productInfo = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if success and productInfo and productInfo.Name then
            gameName = productInfo.Name
        end
    end
    gameName = gameName:gsub("%s+", "_"):gsub("[^%w_]", "")
    if gameName == "" then
        gameName = tostring(game.PlaceId)
    end
    
    local folderName = "vape"
    if isfolder and isfolder("vape") then
        folderName = "vape_" .. gameName
    end
    
    local getasset = getcustomasset or getgenv().getcustomasset
    if getasset then
        local path = folderName .. "/assets/" .. fileName
        local success, asset = pcall(getasset, path)
        if success and asset then return asset end
    end
    return ""
end

-- リッチテキストタグを除去するヘルパー
local function removeTags(str)
    str = str:gsub('<br%s*/>', '\n')
    return str:gsub('<[^<>]->', '')
end

-- ボカシ背景の適用
local function addBlur(parent)
    local blur = Instance.new("ImageLabel")
    blur.Name = "Blur"
    blur.Size = UDim2.new(1, 89, 1, 52)
    blur.Position = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    blur.Image = getAsset("blurnotif.png")
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.Parent = parent
    return blur
end

-- 通知フォルダ
local notificationsFolder = nil

-- 🌟 通知生成のメイン関数
function Notification.create(parentScreenGui, title, text, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"

    -- スクリーンGUI直下に通知格納用のフォルダを作成
    if not notificationsFolder or not notificationsFolder.Parent then
        notificationsFolder = parentScreenGui:FindFirstChild("Notifications")
        if not notificationsFolder then
            notificationsFolder = Instance.new("Folder")
            notificationsFolder.Name = "Notifications"
            notificationsFolder.Parent = parentScreenGui

            -- 子要素が消えたら、残った通知を上部へスライドさせる接続イベント
            notificationsFolder.ChildRemoved:Connect(function()
                local list = notificationsFolder:GetChildren()
                for idx, item in ipairs(list) do
                    TweenService:Create(item, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                        Position = UDim2.new(1, 0, 1, -(29 + (78 * idx)))
                    }):Play()
                end
            end)
        end
    end

    local textBounds = TextService:GetTextSize(removeTags(text), 14, Enum.Font.SourceSans, Vector2.new(1000, 1000))
    local i = #notificationsFolder:GetChildren() + 1

    local card = Instance.new("ImageLabel")
    card.Name = "Notification"
    card.Size = UDim2.fromOffset(math.max(textBounds.X + 80, 266), 75)
    card.Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
    card.ZIndex = 5
    card.BackgroundTransparency = 1
    card.Image = getAsset("notification.png")
    card.ScaleType = Enum.ScaleType.Slice
    card.SliceCenter = Rect.new(7, 7, 9, 9)
    card.Parent = notificationsFolder
    addBlur(card)

    -- アイコン
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromOffset(50, 50)
    icon.Position = UDim2.fromOffset(10, 12)
    icon.ZIndex = 5
    icon.BackgroundTransparency = 1
    icon.Image = getAsset((notifType or "info") .. ".png")
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card

    -- タイトル
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -76, 0, 20)
    titleLabel.Position = UDim2.fromOffset(66, 14)
    titleLabel.ZIndex = 5
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = card

    -- 本文
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -76, 0, 30)
    textLabel.Position = UDim2.fromOffset(66, 31)
    textLabel.ZIndex = 5
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    textLabel.TextSize = 13
    textLabel.TextWrapped = true
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Parent = card

    -- 下部のタイマー進行ゲージ (Progress)
    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.new(1, -14, 0, 2)
    progress.Position = UDim2.new(0, 7, 1, -5)
    progress.ZIndex = 5
    progress.BackgroundColor3 = (notifType == "alert" and Color3.fromRGB(250, 50, 56)) 
                            or (notifType == "warning" and Color3.fromRGB(236, 129, 43)) 
                            or Color3.fromRGB(16, 133, 96) -- 緑
    progress.BorderSizePixel = 0
    progress.Parent = card

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = progress

    -- スライドイン ＆ ゲージ縮小のアニメーション
    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        AnchorPoint = Vector2.new(1, 0)
    }):Play()

    TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.fromOffset(0, 2)
    }):Play()

    -- 完了後のスライドアウトと消滅処理
    task.delay(duration, function()
        TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            AnchorPoint = Vector2.new(0, 0)
        }):Play()

        task.wait(0.4) -- 🌟 スライドアウトが終わるのを待ってからデストロイ
        if card and card.Parent then
            card:ClearAllChildren()
            card:Destroy()
        end
    end)
end

return Notification
end)
__bundle_register("games.GameRegistry", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/games/GameRegistry.lua
local GameRegistry = {}

local places = {
    -- 🌟 フォルダ名が正確に一致しているか確認し、無いものは行頭に -- を書いてコメントアウトしてください。
    ["77790193039862"] = require("games.1_8arena.base"), -- 1_8arena
    ["109668355806967"] = require("games.hoplex.base"),    -- hoplex
    ["81463261330977"] = require("games.pillars_of_fortune.base"), -- pillars_of_fortune
    -- ["13956616152"] = require("games.bridge_duel.base"), -- 🌟 まだフォルダが無い場合はコメントアウト
}

-- 🌟 universal フォルダも作成していない場合は、一旦コメントアウトしてください
local universal = require("games.universal.base") 

-- 現在のプレイスIDに合致する「マージ済みの」モジュールリストを返す関数
function GameRegistry.getModules()
    local placeIdStr = tostring(game.PlaceId)
    local placeSpecific = places[placeIdStr] or {
        ["combat"] = {},
        ["blatant"] = {},
        ["Render"] = {},
        ["Utility"] = {},
        ["World"] = {},
        ["Inventory"] = {},
        ["Minigames"] = {}
    }

    local merged = {}
    local categories = {"combat", "blatant", "Render", "Utility", "World", "Inventory", "Minigames"}

    for _, category in ipairs(categories) do
        merged[category] = {}
        
        -- ユニバーサルモジュールを合流
        if universal and universal[category] then
            for _, mod in ipairs(universal[category]) do
                table.insert(merged[category], mod)
            end
        end
        
        -- プレイス固有モジュールを合流
        if placeSpecific[category] then
            for _, mod in ipairs(placeSpecific[category]) do
                table.insert(merged[category], mod)
            end
        end
    end

    return merged
end

return GameRegistry
end)
__bundle_register("games.universal.base", function(require, _LOADED, __bundle_register, __bundle_modules)
-- !! AUTO GENERATED BY WATCH.JS - DO NOT MODIFY MANUALLY !!
return {
    ["combat"] = {
        require("games.universal.modules.combat.AimAssist"),
    },
    ["blatant"] = {
        require("games.universal.modules.blatant.HitBoxes"),
    },
    ["Render"] = {
    },
    ["Utility"] = {
    },
    ["World"] = {
    },
    ["Inventory"] = {
    },
    ["Minigames"] = {
    },
}

end)
__bundle_register("games.universal.modules.blatant.HitBoxes", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/features/modules/impl/blatant/HitBoxes.lua

local HitBoxes = {
    Name = "HitBoxes",
    Description = "Expand player hitboxes."
}

function HitBoxes.Callback(enabled)
    if enabled then
        print("HitBoxes Enabled")
    else
        print("HitBoxes Disabled")
    end
end

return HitBoxes
end)
__bundle_register("games.universal.modules.combat.AimAssist", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/features/modules/impl/combat/AimAssist.lua
local AimAssist = {
    Name = "AimAssist",
    Description = "Smoothly guides your aim to opponents."
}

-- 使用する設定値の一括管理
AimAssist.Settings = {
    ResetAngle = false,
    ResetDelay = 0.5,
    TargetName = "",
    AimColor = { Hue = 0.44, Sat = 1, Value = 1, Opacity = 1 },
    TargetMode = "Distance", 
    Targets = { Players = true, NPCs = true, Friends = false }
}

function AimAssist.Init(moduleObj)
    
    -- ── 🌟 セクション1: ANGLE SETTINGS ──
    moduleObj:CreateSection("Angle Settings")

    -- 1. トグル設定（ON / OFF）
    moduleObj:CreateToggle("Reset angle", AimAssist.Settings.ResetAngle, function(state)
        AimAssist.Settings.ResetAngle = state
    end)

    -- 2. スライダー設定（数値調整）
    moduleObj:CreateSlider("Reset angle delay", 0.1, 5, AimAssist.Settings.ResetDelay, 0.1, " s", function(val)
        AimAssist.Settings.ResetDelay = val
    end)


    -- ── 🌟 セクション2: TARGET SETTINGS ──
    moduleObj:CreateSection("Target Settings")

    -- 3. テキストボックス設定（文字列入力）
    local targetBox = moduleObj:CreateTextBox("Target Name", AimAssist.Settings.TargetName, "Enter name...", function(val, enter)
        AimAssist.Settings.TargetName = val
    end)

    -- 4. ボタン設定（クリック実行）
    moduleObj:CreateButton("Reset Target", function()
        AimAssist.Settings.TargetName = ""
        if targetBox and targetBox.SetValue then
            targetBox:SetValue("")
        end
        print("Target Name has been reset via Button!")
    end, "rbxassetid://10734897387") -- ごみ箱アイコン

    -- 5. カラーピッカー設定（HSVカラー・不透明度・レインボー調整）
    moduleObj:CreateColorPicker("Target Color", AimAssist.Settings.AimColor, function(h, s, v, opacity)
        AimAssist.Settings.AimColor.Hue = h
        AimAssist.Settings.AimColor.Sat = s
        AimAssist.Settings.AimColor.Value = v
        AimAssist.Settings.AimColor.Opacity = opacity
    end)

    -- 6. ドロップダウン設定（単一選択リスト）
    moduleObj:CreateDropdown(
        "Target Mode", 
        {"Distance", "FOV", "Health"}, 
        AimAssist.Settings.TargetMode, 
        function(val, mouse)
            AimAssist.Settings.TargetMode = val
        end
    )

    -- 7. マルチドロップダウン設定（複数選択リスト）
    moduleObj:CreateMultiDropdown(
        "Aim Targets",
        {"Players", "NPCs", "Friends"},
        AimAssist.Settings.Targets,
        function(updatedTable, mouse)
            AimAssist.Settings.Targets = updatedTable
        end
    )

end

function AimAssist.Callback(enabled)
    if enabled then
        local targetColor = Color3.fromHSV(
            AimAssist.Settings.AimColor.Hue,
            AimAssist.Settings.AimColor.Sat,
            AimAssist.Settings.AimColor.Value
        )
        
        -- 現在の設定状態をコンソールに出力してデバッグ確認
        print("====== AimAssist Enabled ======")
        print("Reset Angle:", AimAssist.Settings.ResetAngle)
        print("Reset Delay:", AimAssist.Settings.ResetDelay, "seconds")
        print("Specific Target:", AimAssist.Settings.TargetName ~= "" and AimAssist.Settings.TargetName or "None")
        print("Target Prioritization:", AimAssist.Settings.TargetMode)
        print("Aim Target Filters:")
        print("  - Players:", AimAssist.Settings.Targets.Players)
        print("  - NPCs:", AimAssist.Settings.Targets.NPCs)
        print("  - Friends:", AimAssist.Settings.Targets.Friends)
        print("Color RGB:", math.round(targetColor.R * 255) .. ", " .. math.round(targetColor.G * 255) .. ", " .. math.round(targetColor.B * 255))
        print("Color Opacity:", AimAssist.Settings.AimColor.Opacity)
        print("===============================")
    else
        print("AimAssist Disabled")
    end
end

return AimAssist
end)
__bundle_register("games.pillars_of_fortune.base", function(require, _LOADED, __bundle_register, __bundle_modules)
-- !! AUTO GENERATED BY WATCH.JS - DO NOT MODIFY MANUALLY !!
return {
    ["combat"] = {
    },
    ["blatant"] = {
    },
    ["Render"] = {
    },
    ["Utility"] = {
    },
    ["World"] = {
    },
    ["Inventory"] = {
    },
    ["Minigames"] = {
    },
}

end)
__bundle_register("games.hoplex.base", function(require, _LOADED, __bundle_register, __bundle_modules)
-- !! AUTO GENERATED BY WATCH.JS - DO NOT MODIFY MANUALLY !!
return {
    ["combat"] = {
    },
    ["blatant"] = {
    },
    ["Render"] = {
    },
    ["Utility"] = {
    },
    ["World"] = {
    },
    ["Inventory"] = {
    },
    ["Minigames"] = {
    },
}

end)
__bundle_register("games.1_8arena.base", function(require, _LOADED, __bundle_register, __bundle_modules)
-- !! AUTO GENERATED BY WATCH.JS - DO NOT MODIFY MANUALLY !!
return {
    ["combat"] = {
    },
    ["blatant"] = {
    },
    ["Render"] = {
    },
    ["Utility"] = {
    },
    ["World"] = {
    },
    ["Inventory"] = {
    },
    ["Minigames"] = {
    },
}

end)
__bundle_register("gui.ModuleWindow", function(require, _LOADED, __bundle_register, __bundle_modules)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local WindowFactory = require("gui.WindowFactory")
local Module = require("gui.components.Module") -- 🌟 ToggleからModuleに変更

local ModuleWindow = {}
ModuleWindow.__index = ModuleWindow

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- 【コンストラクタ】assets を追加受け取り
function ModuleWindow.new(ScreenGui, name, size, position, iconAssetId, assets)
    local self = setmetatable({}, ModuleWindow)

    local container, mainFrame, header = WindowFactory.createBaseWindow(ScreenGui, name, size, position, iconAssetId)
    
    self.Container = container
    self.MainFrame = mainFrame
    self.Header = header
    self.Visible = false
    self.Modules = {}
    self.Collapsed = false
    self.Assets = assets -- アセットリストを保持

    WindowFactory.setupDraggable(container, mainFrame)

    header.BackgroundTransparency = 1

    -- ヘッダータイトルサイズを18pxに拡大
    local title = header:FindFirstChild("Title")
    if title then
        title.Font = Enum.Font.SourceSansSemibold
        title.TextSize = 18
    end

    -- 右上折りたたみボタン（Lucide chevron-down）
    local collapseBtn = Instance.new("ImageButton")
    collapseBtn.Name = "CollapseBtn"
    collapseBtn.Size = UDim2.fromOffset(12, 12)
    collapseBtn.Position = UDim2.new(1, -27, 0.5, -6)
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.Image = "rbxassetid://10709790948"
    collapseBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    collapseBtn.Rotation = 180
    collapseBtn.ZIndex = 4
    collapseBtn.Parent = header

    -- レイアウト用の定数
    local HEADER_HEIGHT = 38
    local MAX_WINDOW_HEIGHT = size.Y.Offset -- コンストラクタで指定された高さを最大サイズとして使用

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "ListFrame"
    -- 初期サイズは最大高さからヘッダー分を引いたサイズに設定
    listFrame.Size = UDim2.new(1, 0, 0, MAX_WINDOW_HEIGHT - HEADER_HEIGHT)
    listFrame.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 2
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ZIndex = 2
    listFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 1) -- 🌟 1pxのすきまに設定
    listLayout.Parent = listFrame

    -- ウィンドウ全体の高さとスクロールバーを動的に自動調整する関数
    local function updateWindowSize()
        local contentHeight = listLayout.AbsoluteContentSize.Y
        -- 無駄な隙間をなくすため +10 の余白を削除（必要に応じて調整してください）
        listFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)

        if not self.Collapsed then
            local maxAllowedContentHeight = MAX_WINDOW_HEIGHT - HEADER_HEIGHT
            -- 実コンテンツ高、または最大可能高のどちらか小さい方に合わせる
            local targetContentHeight = math.min(contentHeight, maxAllowedContentHeight)
            local targetHeight = HEADER_HEIGHT + targetContentHeight

            -- 中身が最大高さを超える場合のみスクロールを有効にし、スクロールバーを表示
            local needsScrolling = contentHeight > maxAllowedContentHeight
            listFrame.ScrollingEnabled = needsScrolling
            listFrame.ScrollBarImageTransparency = needsScrolling and 0 or 1

            -- リストとウィンドウのサイズをフィットさせる
            listFrame.Size = UDim2.new(1, 0, 0, targetContentHeight)
            TweenService:Create(container, TWEEN_INFO, {
                Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, targetHeight)
            }):Play()
        end
    end

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWindowSize)

    self.ListFrame = listFrame

    collapseBtn.MouseButton1Click:Connect(function()
        self.Collapsed = not self.Collapsed
        
        local contentHeight = listLayout.AbsoluteContentSize.Y
        local maxAllowedContentHeight = MAX_WINDOW_HEIGHT - HEADER_HEIGHT
        local targetContentHeight = math.min(contentHeight, maxAllowedContentHeight)
        
        -- 折りたたむ時はヘッダーの高さのみ、開く時はコンテンツに合わせた高さに設定
        local targetHeight = self.Collapsed and HEADER_HEIGHT or (HEADER_HEIGHT + targetContentHeight)
        local targetRotation = self.Collapsed and 0 or 180
        
        listFrame.Visible = not self.Collapsed
        
        TweenService:Create(collapseBtn, TWEEN_INFO, {
            Rotation = targetRotation
        }):Play()
        
        TweenService:Create(container, TWEEN_INFO, {
            Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, targetHeight)
        }):Play()
    end)

    self.Container.Visible = false
    self.MainFrame.GroupTransparency = 1
    
    local stroke = self.MainFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Transparency = 1
    end
    
    local shadow = self.Container:FindFirstChild("Shadow")
    if shadow then
        shadow.ImageTransparency = 1
    end

    return self
end

function ModuleWindow:Toggle()
    self:Animate(not self.Visible)
end

function ModuleWindow:Animate(show)
    self.Visible = show
    local targetTransparency = show and 0 or 1

    TweenService:Create(self.MainFrame, TWEEN_INFO, {GroupTransparency = targetTransparency}):Play()
    
    local stroke = self.MainFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        TweenService:Create(stroke, TWEEN_INFO, {Transparency = targetTransparency}):Play()
    end

    local shadow = self.Container:FindFirstChild("Shadow")
    if shadow then
        local targetShadowTransparency = show and 0.2 or 1
        TweenService:Create(shadow, TWEEN_INFO, {ImageTransparency = targetShadowTransparency}):Play()
    end

    if show then
        self.Container.Visible = true
    else
        task.delay(TWEEN_INFO.Time, function()
            if not self.Visible then
                self.Container.Visible = false
            end
        end)
    end
end

-- Moduleコンポーネントを生成・バインド（Module.new を呼び出すように変更）
function ModuleWindow:CreateModule(name, desc, callback)
    local moduleObj = Module.new(self.ListFrame, name, callback, self.Assets)
    
    table.insert(self.Modules, moduleObj)
    
    return moduleObj -- 🌟 インスタンス自体をそのまま返します
end

return ModuleWindow
end)
__bundle_register("gui.components.Module", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/Module.lua
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ── 🌟【自動登録用コンポーネントリスト】 ──
-- 新しいコンポーネント（TextBoxなど）を追加したい場合は、ここに1行 require を
-- 追加するだけで、自動的に Module:Create[コンポーネント名](...) が使用可能になります。
-- src/gui/components/Module.lua

-- src/gui/components/Module.lua

-- src/gui/components/Module.lua

-- src/gui/components/Module.lua
-- src/gui/components/Module.lua
-- src/gui/components/Module.lua

-- src/gui/components/Module.lua

local components = {
    Toggle        = require("gui.components.Toggle"),
    Slider        = require("gui.components.Slider"),
    TextBox       = require("gui.components.TextBox"),
    Button        = require("gui.components.Button"),
    ColorPicker   = require("gui.components.ColorPicker"),
    Dropdown      = require("gui.components.Dropdown"),
    MultiDropdown = require("gui.components.MultiDropdown"),
    Section       = require("gui.components.Section"),
}
local Module = {}

-- src/gui/components/Module.lua の 15行目付近（一括生成ループ箇所）

-- ── 🌟 【動的バインディング】components内のコンポーネントからCreateメソッドを自動一括生成 ──
for compName, compClass in pairs(components) do
    local methodName = "Create" .. compName
    Module[methodName] = function(self, ...)
        -- 🌟 引数リストの末尾に、親モジュールである self を安全に挿入して渡します
        local args = {...}
        table.insert(args, self)
        
        -- parent（self.OptionsFrame）を第1引数にしてコンポーネントを生成
        local res = compClass.new(self.OptionsFrame, unpack(args))
        
        -- 生成されたオブジェクトをOptionsテーブルに自動で登録
        local optionName = (res.Name) or (res.Object and res.Object.Name) or compName
        self.Options[optionName] = res
        
        -- 高さの自動更新
        self:_refreshOptionsHeight()
        return res
    end
end

-- クラス定義のメタテーブルを紐付け
Module.__index = Module

local DEBUG_ENABLED = true
local function debugPrint(...)
    if DEBUG_ENABLED then print("[Module]", ...) end
end

-- ── Visual constants ────────────────────────────────────────────────────────
local TWEEN_INFO   = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FONT_SEMI    = Enum.Font.SourceSansSemibold
local FONT_BOLD    = Enum.Font.SourceSansBold

-- Text
local COL_TEXT_OFF    = Color3.fromRGB(130, 130, 130)
local COL_TEXT_HOVER  = Color3.fromRGB(210, 210, 210)
local COL_TEXT_ON     = Color3.fromRGB(255, 255, 255)

-- Icon
local COL_ICON_OFF    = Color3.fromRGB(95,  95,  95)
local COL_ICON_HOVER  = Color3.fromRGB(170, 170, 170)
local COL_ICON_ON     = Color3.fromRGB(200, 200, 200)

-- Backgrounds
local COL_HOVER_BG    = Color3.fromRGB(255, 255, 255)
local COL_ACTIVE_BG   = Color3.fromRGB(16,  133, 96)

-- Fallback palette
local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = COL_TEXT_OFF,
    Font  = FONT_SEMI,
    Tween = TWEEN_INFO,
}

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function addMaid(obj)
    obj.Connections = {}
    function obj:Clean(cb)
        if typeof(cb) == "Instance" then
            table.insert(self.Connections, { Disconnect = function()
                cb:ClearAllChildren(); cb:Destroy()
            end })
        elseif type(cb) == "function" then
            table.insert(self.Connections, { Disconnect = cb })
        else
            table.insert(self.Connections, cb)
        end
    end
end

local function getTableSize(t)
    local n = 0
    if type(t) == "table" then for _ in pairs(t) do n = n + 1 end end
    return n
end

local function getAsset(self, path, default)
    if self.getcustomasset then
        local ok, res = pcall(self.getcustomasset, path)
        if ok and res and res ~= "" then return res end
    end
    return default
end

local function colorLight(c, n) local h,s,v = c:ToHSV(); return Color3.fromHSV(h,s,math.clamp(v+n,0,1)) end
local function colorDark (c, n) local h,s,v = c:ToHSV(); return Color3.fromHSV(h,s,math.clamp(v-n,0,1)) end

-- アコーディオンの展開高さをコンテンツぴったりに合わせるため、不要な余白 (+ 24) を削除
local function calcOptionsHeight(frame, layout)
    local h = layout.AbsoluteContentSize.Y
    if h > 0 then return h end
    local total, cnt = 0, 0
    for _, ch in ipairs(frame:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextButton") then
            total = total + ch.AbsoluteSize.Y; cnt = cnt + 1
        end
    end
    return total + math.max(cnt-1,0)*4
end

-- Toggle専用：文字サイズを16に拡大し、Y座標のズレを防ぐために自動で中央揃えに矯正するヘルパー
local function adjustComponentTextSize(s)
    local function traverse(instance)
        if instance:IsA("TextLabel") or instance:IsA("TextButton") then
            if instance.TextSize < 16 then
                instance.TextSize = 16
            end
        end
        -- 小さなボタンや画像フレームを親コンテナに対して垂直中央揃え（AnchorPoint.Y=0.5, Position.Y=0.5）にする
        if instance:IsA("Frame") or instance:IsA("TextButton") or instance:IsA("ImageLabel") then
            if instance.Size.Y.Offset > 0 and instance.Size.Y.Offset < 30 then
                instance.AnchorPoint = Vector2.new(instance.AnchorPoint.X, 0.5)
                instance.Position = UDim2.new(instance.Position.X.Scale, instance.Position.X.Offset, 0.5, 0)
            end
        end
        for _, child in ipairs(instance:GetChildren()) do
            traverse(child)
        end
    end

    if s then
        if typeof(s) == "table" then
            if s.Object then traverse(s.Object) end
            if s.Label then traverse(s.Label) end
            if s.Frame then traverse(s.Frame) end
        elseif typeof(s) == "Instance" then
            traverse(s)
        end
    end
end

-- ── Constructor ─────────────────────────────────────────────────────────────
function Module.new(parent, nameOrSettings, callback, assets, api)
    local self = setmetatable({}, Module)

    local name, modulesettings = nameOrSettings, {}
    if type(nameOrSettings) == "table" then
        modulesettings = nameOrSettings
        name     = modulesettings.Name
        callback = modulesettings.Function
    end
    debugPrint("new:", name)

    -- Resolve globals
    local mapi   = api or mainapi or (shared.vape) or (shared.VapeMenu)
    local libs   = mapi and mapi.Libraries
    local pal    = (libs and libs.uipallet) or (uipallet and uipallet.Main and uipallet) or default_uipallet
    local col    = (libs and libs.color) or { Light = colorLight, Dark = colorDark }
    local tw     = (libs and libs.tween) or nil
    local gfs    = (libs and libs.getfontsize) or getfontsize
    local gca    = (libs and libs.getcustomasset) or getcustomasset

    self.api            = mapi
    self.mainapi        = mapi
    self.uipallet       = pal
    self.color          = col
    self.tween          = tw
    self.getfontsize    = gfs
    self.getcustomasset = gca
    self.Assets         = type(assets) == "table" and assets or {}
    self.Type           = "Module"
    self.Enabled        = false
    self.Options        = {}
    self.Bind           = {}
    self.Connections    = {}
    self.Index          = (mapi and mapi.Modules) and getTableSize(mapi.Modules) or 0
    self.ExtraText      = modulesettings.ExtraText
    self.Name           = name
    self.Category       = (parent and parent.Parent) and parent.Parent.Name:gsub("Category$","") or ""
    self.Starred        = false
    self.Callback       = callback or function() end
    self.IsBinding      = false
    self.OptionsExpanded = false

    -- ── 親コンテナ強制密着ロジック ──
    -- リスト親フレームおよびスクロール親フレームをウィンドウのフチに完全に密着させ、1pxの切り取り余白を排除します。
    task.spawn(function()
        if parent then
            -- 直接の親（モジュールを格納しているFrame）の余白をリセットして左右に伸ばす
            if parent:IsA("Frame") or parent:IsA("ScrollingFrame") then
                parent.Size = UDim2.new(1, 0, parent.Size.Y.Scale, parent.Size.Y.Offset)
                parent.Position = UDim2.new(0, 0, parent.Position.Y.Scale, parent.Position.Y.Offset)
            end
            -- スクロール機能を提供するScrollingFrame先祖を探し、その横幅と位置を強制フラッシュする
            local scrollParent = parent:IsA("ScrollingFrame") and parent or parent:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scrollParent then
                scrollParent.Size = UDim2.new(1, 0, scrollParent.Size.Y.Scale, scrollParent.Size.Y.Offset)
                scrollParent.Position = UDim2.new(0, 0, scrollParent.Position.Y.Scale, scrollParent.Position.Y.Offset)
            end
        end
    end)

    -- Outer wrapper (親コンテナ自体がフチに密着したため、Scale = 1 で完全にフチに揃います)
    local moduleFrame = Instance.new("Frame")
    moduleFrame.Name              = name .. "Frame"
    moduleFrame.Size              = UDim2.new(1, 0, 0, 44)
    moduleFrame.BackgroundTransparency = 1
    moduleFrame.BorderSizePixel   = 0
    moduleFrame.Parent            = parent

    -- Root button
    local button = Instance.new("TextButton")
    button.Name               = name
    button.Size               = UDim2.new(1, 0, 0, 44)
    button.BackgroundTransparency = 1
    button.BorderSizePixel    = 0
    button.Text               = ""
    button.AutoButtonColor    = false
    button.ZIndex             = 4
    button.Parent             = moduleFrame

    -- Hover background
    local hoverBg = Instance.new("Frame")
    hoverBg.Name                  = "HoverBg"
    hoverBg.Position              = UDim2.new(0, 0, 0, 0)
    hoverBg.Size                  = UDim2.new(1, 0, 1, -1)
    hoverBg.BackgroundColor3      = COL_HOVER_BG
    hoverBg.BackgroundTransparency = 1
    hoverBg.BorderSizePixel       = 0
    hoverBg.ZIndex                = 2
    hoverBg.Parent                = button

    -- Active background
    local activeBg = Instance.new("Frame")
    activeBg.Name                  = "ActiveBg"
    activeBg.Position              = UDim2.new(0, 0, 0, 0)
    activeBg.Size                  = UDim2.new(1, 0, 1, -1)
    activeBg.BackgroundColor3      = COL_ACTIVE_BG
    activeBg.BackgroundTransparency = 1
    activeBg.BorderSizePixel       = 0
    activeBg.ZIndex                = 3
    activeBg.Parent                = button

    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Enabled  = false
    gradient.Parent   = activeBg

    -- Divider line (モジュール間の境界線。ON/OFF問わず常に表示)
    local divider = Instance.new("Frame")
    divider.Name             = "Divider"
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.Position         = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    divider.BorderSizePixel  = 0
    divider.Visible          = true -- 常に表示
    divider.ZIndex           = 4
    divider.Parent             = button

    -- Module name label (位置12px)
    local label = Instance.new("TextLabel")
    label.Name               = "Label"
    label.Size               = UDim2.new(1, -90, 1, 0)
    label.Position           = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text               = name
    label.TextColor3         = COL_TEXT_OFF
    label.TextSize           = 16
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.ZIndex             = 5
    local ok = pcall(function() label.FontFace = pal.Font end)
    if not ok then label.Font = FONT_SEMI end
    label.Parent = button

    -- Small dot (Safe hide to match original layout)
    local colorDotFrame = Instance.new("Frame")
    colorDotFrame.Name               = "ColorDot"
    colorDotFrame.Size               = UDim2.fromOffset(0, 0)
    colorDotFrame.Visible            = false
    colorDotFrame.BackgroundColor3   = Color3.fromRGB(16, 133, 96)
    colorDotFrame.BackgroundTransparency = 1
    colorDotFrame.BorderSizePixel    = 0
    colorDotFrame.ZIndex             = 5
    colorDotFrame.Parent             = button

    -- ⋮ option expand button (垂直中央 0.5,0 / 高さ 18px / 右端 -8px)
    local optionBtn = Instance.new("TextButton")
    optionBtn.Name               = "Dots"
    optionBtn.Size               = UDim2.fromOffset(12, 18)
    optionBtn.AnchorPoint        = Vector2.new(1, 0.5)
    optionBtn.Position           = UDim2.new(1, -8, 0.5, 0)
    optionBtn.BackgroundTransparency = 1
    optionBtn.Text               = ""
    optionBtn.ZIndex             = 5
    optionBtn.Parent             = button

    local optionIcon = Instance.new("ImageLabel")
    optionIcon.Name              = "DotsIcon"
    optionIcon.Size              = UDim2.fromOffset(14, 14)
    optionIcon.AnchorPoint       = Vector2.new(0.5, 0.5)
    optionIcon.Position          = UDim2.new(0.5, 0, 0.5, -1) -- アセットの余白を考慮し、1px上に補正
    optionIcon.BackgroundTransparency = 1
    optionIcon.Image             = getAsset(self, "newvape/assets/new/dots.png", "rbxassetid://10734897387")
    optionIcon.ImageColor3       = COL_ICON_OFF
    optionIcon.ScaleType         = Enum.ScaleType.Fit
    optionIcon.ZIndex            = 6
    optionIcon.Parent            = optionBtn

    -- Bind button (垂直中央 0.5,0 / 高さ 18px / 右端 -26px / 隙間6px)
    local bindBtn = Instance.new("TextButton")
    bindBtn.Name               = "Bind"
    bindBtn.Size               = UDim2.fromOffset(18, 18)
    bindBtn.AnchorPoint        = Vector2.new(1, 0.5)
    bindBtn.Position           = UDim2.new(1, -26, 0.5, 0)
    bindBtn.BackgroundTransparency = 1
    bindBtn.Text               = ""
    bindBtn.ZIndex             = 5
    bindBtn.Parent             = button

    -- BindFrame (18x18pxのサイズを完全に維持)
    local bindFrame = Instance.new("Frame")
    bindFrame.Name               = "BindFrame"
    bindFrame.Size               = UDim2.new(1, 0, 1, 0)
    bindFrame.BackgroundColor3   = Color3.new(0, 0, 0)
    bindFrame.BackgroundTransparency = 0.65
    bindFrame.BorderSizePixel    = 0
    bindFrame.ZIndex             = 5
    bindFrame.Parent             = bindBtn

    local bfc = Instance.new("UICorner")
    bfc.CornerRadius = UDim.new(0, 4)
    bfc.Parent = bindFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bindFrame

    -- Bind icon (完全に中央揃え)
    local bindIcon = Instance.new("ImageLabel")
    bindIcon.Name              = "Icon"
    bindIcon.Size              = UDim2.fromOffset(12, 12)
    bindIcon.AnchorPoint       = Vector2.new(0.5, 0.5)
    bindIcon.Position          = UDim2.new(0.5, 0, 0.5, 0)
    bindIcon.BackgroundTransparency = 1
    bindIcon.ImageColor3       = COL_TEXT_OFF
    bindIcon.ScaleType         = Enum.ScaleType.Fit
    bindIcon.ZIndex            = 6
    bindIcon.Image             = (type(assets) == "table" and assets.bind) or getAsset(self, "newvape/assets/new/bind.png", "rbxassetid://14368304734")
    bindIcon.Parent            = bindFrame

    -- BindText
    local bindText = Instance.new("TextLabel")
    bindText.Name              = "BindText"
    bindText.Size              = UDim2.new(1, 0, 1, 0)
    bindText.BackgroundTransparency = 1
    bindText.Text              = ""
    bindText.Visible           = false
    bindText.TextColor3        = COL_TEXT_OFF
    bindText.TextSize          = 10
    bindText.ZIndex            = 6
    local bfok = pcall(function() bindText.FontFace = pal.Font end)
    if not bfok then bindText.Font = FONT_BOLD end
    bindText.Parent = bindFrame

    -- ★ Star button (垂直中央 0.5,0 / 高さ 24px / 右端 -50px / ONのときのみ表示)
    local starBtn = Instance.new("TextButton")
    starBtn.Name               = "StarBtn"
    starBtn.Size               = UDim2.fromOffset(24, 24)
    starBtn.AnchorPoint        = Vector2.new(1, 0.5)
    starBtn.Position           = UDim2.new(1, -50, 0.5, 0)
    starBtn.BackgroundTransparency = 1
    starBtn.Text               = ""
    starBtn.ZIndex             = 5
    starBtn.Visible            = false
    starBtn.Parent             = button

    -- ★ Star TextLabel
    local starIcon = Instance.new("TextLabel")
    starIcon.Name              = "Icon"
    starIcon.Size              = UDim2.new(1, 0, 1, 0)
    starIcon.AnchorPoint       = Vector2.new(0.5, 0.5)
    starIcon.Position          = UDim2.new(0.5, 0, 0.5, -1)
    starIcon.BackgroundTransparency = 1
    starIcon.Text              = "★"
    starIcon.TextSize          = 22
    starIcon.Font              = FONT_BOLD
    starIcon.TextXAlignment    = Enum.TextXAlignment.Center
    starIcon.TextYAlignment    = Enum.TextYAlignment.Center
    starIcon.TextColor3        = Color3.fromRGB(70, 70, 70)
    starIcon.ZIndex            = 6
    starIcon.Parent            = starBtn

    -- Options accordion frame (親コンテナに100%追従)
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name              = "OptionsFrame"
    optionsFrame.Size              = UDim2.new(1, 0, 0, 0)
    optionsFrame.Position          = UDim2.fromOffset(0, 44)
    optionsFrame.BackgroundColor3  = col.Dark(pal.Main, 0.02)
    optionsFrame.BorderSizePixel   = 0
    optionsFrame.ClipsDescendants  = true
    optionsFrame.Visible           = false
    optionsFrame.ZIndex            = 2
    optionsFrame.Parent            = moduleFrame

    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.FillDirection        = Enum.FillDirection.Vertical
    optionsLayout.SortOrder            = Enum.SortOrder.LayoutOrder
    optionsLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    optionsLayout.Parent               = optionsFrame

    -- Hover / click events
    local hoverTime = 0.15
    local ease, dir = Enum.EasingStyle.Quart, Enum.EasingDirection.Out

    button.MouseEnter:Connect(function()
        if self.Enabled then return end
        TweenService:Create(hoverBg,    TweenInfo.new(hoverTime,ease,dir), {BackgroundTransparency = 0.94}):Play()
        TweenService:Create(label,      TweenInfo.new(hoverTime,ease,dir), {TextColor3 = COL_TEXT_HOVER}):Play()
        TweenService:Create(optionIcon, TweenInfo.new(hoverTime,ease,dir), {ImageColor3 = COL_ICON_HOVER}):Play()
    end)

    button.MouseLeave:Connect(function()
        if self.Enabled then return end
        TweenService:Create(hoverBg,    TweenInfo.new(hoverTime,ease,dir), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label,      TweenInfo.new(hoverTime,ease,dir), {TextColor3 = COL_TEXT_OFF}):Play()
        TweenService:Create(optionIcon, TweenInfo.new(hoverTime,ease,dir), {ImageColor3 = COL_ICON_OFF}):Play()
    end)

    -- Bindホバー時の微弱なハイライト
    bindBtn.MouseEnter:Connect(function()
        TweenService:Create(bindFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.45
        }):Play()
    end)

    bindBtn.MouseLeave:Connect(function()
        TweenService:Create(bindFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.65
        }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    optionBtn.MouseButton1Click:Connect(function()
        self:ToggleOptions()
    end)

    starBtn.MouseButton1Click:Connect(function()
        self.Starred = not self.Starred
        starIcon.TextColor3 = self.Starred and Color3.fromRGB(255, 255, 255) or (self.Enabled and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(70, 70, 70))
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if self.IsBinding then return end
        self.IsBinding = true
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local keyName = input.KeyCode ~= Enum.KeyCode.Unknown
                and input.KeyCode.Name
                or (input.UserInputType == Enum.UserInputType.MouseButton1 and "MouseButton1")
                or nil
            if keyName then
                conn:Disconnect()
                self:SetBind({keyName}, true)
            end
        end)
    end)

    -- Assign to self
    self.Frame         = moduleFrame
    self.Object        = button
    self.HoverBg       = hoverBg
    self.ActiveBg      = activeBg
    self.Gradient      = gradient
    self.Divider       = divider
    self.Label         = label
    self.ColorDot      = colorDotFrame
    self.OptionButton  = optionBtn
    self.OptionIcon    = optionIcon
    self.StarButton    = starBtn
    self.StarIcon      = starIcon
    self.BindButton    = bindBtn
    self.BindFrame     = bindFrame
    self.BindIcon      = bindIcon
    self.BindText      = bindText

    self.OptionsFrame  = optionsFrame
    self.OptionsLayout = optionsLayout
    self.Children      = optionsFrame

    -- Dynamic component injection
    local comps = (mapi and mapi.Components) or (shared.vape and shared.vape.Components)
    if type(comps) == "table" then
        for k, v in pairs(comps) do
            if not Module["Create"..k] then
                self["Create"..k] = function(_, settings)
                    local res = v(settings, optionsFrame, self)
                    self:_refreshOptionsHeight()
                    return res
                end
            end
        end
    end

    addMaid(self)
    return self
end

-- ── Methods ──────────────────────────────────────────────────────────────────

function Module:SetBind(tab, mouse)
    debugPrint("SetBind:", self.Name, table.concat(tab, "+"))
    if tab.Mobile then
        createMobileButton(self, Vector2.new(tab.X, tab.Y))
        return
    end
    self.Bind = table.clone(tab)
    self.IsBinding = false
    self:UpdateBindState()
end

function Module:UpdateBindState()
    local hasBind = #self.Bind > 0
    self.BindIcon.Visible = not hasBind
    self.BindText.Visible = hasBind
    if hasBind then
        self.BindText.Text = table.concat(self.Bind, "+")
    end
end

-- src/gui/components/Module.lua の 190行目付近

function Module:SetState(state, multiple)
    debugPrint("SetState:", self.Name, state)
    self.Enabled = state

    if self.Gradient then self.Gradient.Enabled  = state end

    TweenService:Create(self.Label, TWEEN_INFO, {
        TextColor3 = state and COL_TEXT_ON or COL_TEXT_OFF
    }):Play()

    -- Color dot visibility
    TweenService:Create(self.ColorDot, TWEEN_INFO, {
        BackgroundTransparency = state and 0 or 1
    }):Play()

    -- Active background color
    local mapi = self.mainapi or (shared.vape and shared.vape.mainapi)
    local activeCol = COL_ACTIVE_BG
    local rainbow = mapi and mapi.GUIColor and mapi.GUIColor.Rainbow and mapi.RainbowMode and mapi.RainbowMode.Value ~= "Retro"
    if mapi and mapi.GUIColor then
        if rainbow and mapi.Color then
            activeCol = Color3.fromHSV(mapi:Color((self.Index * 0.025) % 1))
        else
            activeCol = Color3.fromHSV(mapi.GUIColor.Hue, mapi.GUIColor.Sat, mapi.GUIColor.Value)
        end
    end

    if self.tween and self.tween.Tween then
        self.tween:Tween(self.ActiveBg, self.uipallet.Tween, {
            BackgroundTransparency = state and 0 or 1,
            BackgroundColor3       = activeCol, -- 🌟 【修正】色を白に切り替えず、そのままの色のまま透明度だけを下げます
        })
    else
        TweenService:Create(self.ActiveBg, TWEEN_INFO, {
            BackgroundTransparency = state and 0 or 1,
            BackgroundColor3       = activeCol, -- 🌟 【修正】同上
        }):Play()
    end

    TweenService:Create(self.OptionIcon, TWEEN_INFO, {
        ImageColor3 = state and COL_TEXT_ON or COL_ICON_OFF
    }):Play()

    TweenService:Create(self.BindIcon, TWEEN_INFO, {
        ImageColor3 = state and COL_TEXT_ON or COL_TEXT_OFF
    }):Play()

    -- ホバー背景の透明度をリセット
    TweenService:Create(self.HoverBg, TWEEN_INFO, {BackgroundTransparency = 1}):Play()

    -- 星ボタンの表示切り替え（ONのときのみ表示）と色変更（Starredのときは白色に）
    self.StarButton.Visible = state
    TweenService:Create(self.StarIcon, TWEEN_INFO, {
        TextColor3 = self.Starred and Color3.fromRGB(255, 255, 255) or (state and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(70, 70, 70))
    }):Play()

    if not state then
        for _, v in ipairs(self.Connections) do pcall(function() v:Disconnect() end) end
        table.clear(self.Connections)
    end

    if not multiple and mapi then mapi:UpdateTextGUI() end
    self:UpdateBindState()
    if self.Callback then task.spawn(self.Callback, self.Enabled) end
end

function Module:Toggle(multiple)
    self:SetState(not self.Enabled, multiple)
end

-- アコーディオンプランの横幅を100%追従に変更
function Module:ToggleOptions()
    self.OptionsExpanded = not self.OptionsExpanded
    self.OptionsFrame.Visible = true
    local h = self.OptionsExpanded and calcOptionsHeight(self.OptionsFrame, self.OptionsLayout) or 0
    TweenService:Create(self.Frame,        TWEEN_INFO, {Size = UDim2.new(1, 0, 0, 44 + h)}):Play()
    TweenService:Create(self.OptionsFrame, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, h)}):Play()
    TweenService:Create(self.OptionIcon,   TWEEN_INFO, {Rotation = self.OptionsExpanded and 90 or 0}):Play()
    if not self.OptionsExpanded then
        task.delay(TWEEN_INFO.Time, function()
            if not self.OptionsExpanded then self.OptionsFrame.Visible = false end
        end)
    end
end

-- アコーディオンプランの横幅を100%追従に変更
function Module:_refreshOptionsHeight()
    if self.OptionsExpanded then
        task.defer(function()
            local h = calcOptionsHeight(self.OptionsFrame, self.OptionsLayout)
            TweenService:Create(self.OptionsFrame, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, h)}):Play()
            TweenService:Create(self.Frame,        TWEEN_INFO, {Size = UDim2.new(1, 0, 0, 44 + h)}):Play()
        end)
    end
end

function Module:SetColorDot(color3)
    if self.ColorDot then
        self.ColorDot.BackgroundColor3 = color3
    end
end

function Module:Color(hue, sat, val, rainbowcheck)
    local mapi    = self.mainapi or (shared.vape and shared.vape.mainapi)
    local rainbow = rainbowcheck and mapi and mapi.GUIColor and mapi.GUIColor.Rainbow and mapi.RainbowMode and mapi.RainbowMode.Value ~= "Retro"
    if self.Enabled then
        local c
        if rainbow and mapi and mapi.Color then
            c = Color3.fromHSV(mapi:Color((hue - self.Index * 0.025) % 1))
        else
            c = Color3.fromHSV(hue, sat, val)
        end
        local mode = (mapi and mapi.RainbowMode) and mapi.RainbowMode.Value or "Normal"
        if rainbow and mode == "Gradient" then
            self.Gradient.Enabled = true
            if mapi and mapi.Color then
                self.Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, c),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(mapi:Color((hue - (self.Index+1)*0.025) % 1)))
                })
            end
            self.ActiveBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
        else
            self.Gradient.Enabled = false
            self.ActiveBg.BackgroundColor3 = c
        end
        local tc = (mapi and mapi.TextColor) and mapi:TextColor(hue,sat,val) or COL_TEXT_ON
        self.Label.TextColor3    = tc
        self.BindText.TextColor3 = tc
        self.BindIcon.ImageColor3 = tc
        self.OptionIcon.ImageColor3 = tc
    else
        self.Label.TextColor3    = COL_TEXT_OFF
        self.OptionIcon.ImageColor3 = COL_ICON_OFF
        self.BindIcon.ImageColor3   = self.color.Dark(self.uipallet.Text, 0.43)
        self.BindText.TextColor3    = self.color.Dark(self.uipallet.Text, 0.43)
    end
    for _, opt in pairs(self.Options) do
        if opt.Color then opt:Color(hue, sat, val, rainbowcheck) end
    end
end

-- Late-bind global components (non-overwriting)
task.spawn(function()
    local comps = components or (shared.vape and shared.vape.Components)
    if comps then
        for k, v in pairs(comps) do
            if not Module["Create"..k] then
                Module["Create"..k] = function(self, settings)
                    local res = v(settings, self.OptionsFrame, self)
                    self:_refreshOptionsHeight()
                    return res
                end
            end
        end
    end
end)

return Module
end)
__bundle_register("gui.components.Section", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/Section.lua
local TweenService = game:GetService("TweenService")

local Section = {}
Section.__index = Section

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSansBold,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function Section.new(parent, nameOrSettings, callback, moduleInstance)
    local self = setmetatable({}, Section)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
    end

    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet

    self.Name = name
    self.Type = "Section"

    -- セクション用コンテナ（縦幅 28px）
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Name = name .. "Section"
    sectionFrame.Size = UDim2.new(1, 0, 0, 28)
    sectionFrame.BackgroundTransparency = 1
    sectionFrame.BorderSizePixel = 0
    sectionFrame.Parent = parent

    -- セクション名表示ラベル
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.fromOffset(12, 6) -- 🌟 12pxの左余白に完璧に整列
    label.BackgroundTransparency = 1
    label.Text = name:upper() -- 大文字にしてヘッダーらしさを演出
    label.TextColor3 = Color3.fromRGB(110, 110, 110) -- 視覚的な邪魔をしない控えめなグレー色
    label.TextSize = 11 -- 小さくスタイリッシュに
    applyFont(label, active_uipallet.Font or Enum.Font.SourceSansBold)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sectionFrame

    self.Object = sectionFrame
    self.Label = label

    return self
end

function Section:Save(tab)
    -- 静的表示要素なので保存・ロードは不要
end

function Section:Load(tab)
end

return Section
end)
__bundle_register("gui.components.MultiDropdown", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/MultiDropdown.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function MultiDropdown.new(parent, nameOrSettings, list, defaultValues, callback, moduleInstance)
    local self = setmetatable({}, MultiDropdown)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        list = optionsettings.List
        defaultValues = optionsettings.Default
        callback = optionsettings.Function
    end

    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = moduleInstance or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    local active_color = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween = (tween and tween.Tween) and tween or nil

    self.Name = name
    self.Type = "MultiDropdown"
    self.List = list or {}
    
    -- 複数選択値の初期化
    self.Value = {}
    for _, opt in ipairs(self.List) do
        self.Value[opt] = false
    end
    
    -- デフォルト選択（配列または辞書テーブルに対応）
    if type(defaultValues) == "table" then
        for k, v in pairs(defaultValues) do
            if type(k) == "number" then
                if table.find(self.List, v) then
                    self.Value[v] = true
                end
            else
                if table.find(self.List, k) then
                    self.Value[k] = v == true
                end
            end
        end
    end

    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.ModuleInstance = moduleInstance

    -- ベースボタン枠（初期の閉じている高さ: 40）
    local dropdown = Instance.new("TextButton")
    dropdown.Name = name .. "MultiDropdownSetting"
    dropdown.Size = UDim2.new(1, 0, 0, 40)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    dropdown.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentColor, 0.02) or parentColor
    dropdown.BorderSizePixel = 0
    dropdown.AutoButtonColor = false
    dropdown.Visible = optionsettings.Visible == nil or optionsettings.Visible
    dropdown.Text = ""
    dropdown.Parent = parent

    if addTooltip and (optionsettings.Tooltip or name) then
        addTooltip(dropdown, optionsettings.Tooltip or name)
    end

    -- 背景枠 (BKG) - 余白を 12px に統一
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    bkg.Size = UDim2.new(1, -24, 1, -9)
    bkg.Position = UDim2.fromOffset(12, 4)
    bkg.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.034)
    bkg.BorderSizePixel = 0
    bkg.Parent = dropdown

    if addCorner then
        addCorner(bkg, UDim.new(0, 6))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = bkg
    end

    -- メイン選択ボタン
    local button = Instance.new("TextButton")
    button.Name = "Dropdown"
    button.Size = UDim2.new(1, -2, 1, -2)
    button.Position = UDim2.fromOffset(1, 1)
    button.BackgroundColor3 = active_uipallet.Main
    button.AutoButtonColor = false
    button.Text = ""
    button.Parent = bkg

    if addCorner then
        addCorner(button, UDim.new(0, 6))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = button
    end

    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 12)
    buttonPadding.PaddingRight = UDim.new(0, 12)
    buttonPadding.Parent = button

    -- タイトルテキスト
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -30, 0, 29)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
    title.TextSize = 17 
    title.TextTruncate = Enum.TextTruncate.AtEnd
    applyFont(title, active_uipallet.Font)
    title.Parent = button

    -- 開閉矢印アイコン
    local arrow = Instance.new("ImageLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.fromOffset(12, 12)
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, 0, 0, 14)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://10709791437"
    arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
    arrow.ScaleType = Enum.ScaleType.Fit
    arrow.Rotation = 90
    arrow.Parent = button

    self.Object = dropdown
    self.Bkg = bkg
    self.Button = button
    self.Title = title
    self.Arrow = arrow
    self.DropdownChildren = nil

    -- メニュー展開処理
    button.MouseButton1Click:Connect(function()
        if not self.DropdownChildren then
            arrow.Rotation = 270
            local listSize = #self.List
            local expandedHeight = 40 + listSize * 26
            dropdown.Size = UDim2.new(1, 0, 0, expandedHeight)

            local childrenFrame = Instance.new("Frame")
            childrenFrame.Name = "Children"
            childrenFrame.Size = UDim2.new(1, 0, 0, listSize * 26)
            childrenFrame.Position = UDim2.fromOffset(0, 27)
            childrenFrame.BackgroundTransparency = 1
            childrenFrame.Parent = button
            self.DropdownChildren = childrenFrame

            -- 選択肢をすべて生成
            for ind, v in ipairs(self.List) do
                local option = Instance.new("TextButton")
                option.Name = v .. "Option"
                option.Size = UDim2.new(1, 0, 0, 26)
                option.Position = UDim2.fromOffset(0, (ind - 1) * 26)
                option.BackgroundColor3 = active_uipallet.Main
                option.BorderSizePixel = 0
                option.AutoButtonColor = false
                option.Text = "" -- 🌟 ボタン自体のTextは空に
                option.Parent = childrenFrame

                -- 🌟 【変更】UIPaddingの不具合を完全に回避するため、テキストは独立したTextLabelとして内部に配置
                local optionLabel = Instance.new("TextLabel")
                optionLabel.Name = "Label"
                -- 左右にパディング空間（左: 26px, 右: 12px）を空けたサイズに指定
                optionLabel.Size = UDim2.new(1, -38, 1, 0)
                optionLabel.Position = UDim2.fromOffset(26, 0) -- 🌟 確実に26px右へずらして配置
                optionLabel.BackgroundTransparency = 1
                optionLabel.Text = v
                optionLabel.TextXAlignment = Enum.TextXAlignment.Left
                optionLabel.TextSize = 15
                optionLabel.TextTruncate = Enum.TextTruncate.AtEnd
                applyFont(optionLabel, active_uipallet.Font)
                optionLabel.Parent = option

                -- 🌟 【変更】Lucide の正式なチェックマークアイコンを追加
                local checkIcon = Instance.new("ImageLabel")
                checkIcon.Name = "CheckIcon"
                checkIcon.Size = UDim2.fromOffset(12, 12)
                checkIcon.Position = UDim2.new(0, 8, 0.5, 0) -- 左から8px
                checkIcon.AnchorPoint = Vector2.new(0, 0.5)
                checkIcon.BackgroundTransparency = 1
                checkIcon.Image = "rbxassetid://10709790644" -- 🌟 Lucide check icon
                checkIcon.ImageColor3 = active_uipallet.Text
                checkIcon.ScaleType = Enum.ScaleType.Fit
                checkIcon.ZIndex = 6
                checkIcon.Parent = option

                -- 現在選択されているか（チェック状態）のビュー更新関数
                local function updateOptionView()
                    if self.Value[v] then
                        optionLabel.TextColor3 = active_uipallet.Text
                        checkIcon.Visible = true
                    else
                        optionLabel.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
                        checkIcon.Visible = false
                    end
                end
                updateOptionView()

                -- ホバー処理
                local hoverCol = active_color.Light(active_uipallet.Main, 0.02)
                option.MouseEnter:Connect(function()
                    if active_tween then
                        active_tween:Tween(option, active_uipallet.Tween, { BackgroundColor3 = hoverCol })
                    else
                        TweenService:Create(option, active_uipallet.Tween, { BackgroundColor3 = hoverCol }):Play()
                    end
                end)
                option.MouseLeave:Connect(function()
                    if active_tween then
                        active_tween:Tween(option, active_uipallet.Tween, { BackgroundColor3 = active_uipallet.Main })
                    else
                        TweenService:Create(option, active_uipallet.Tween, { BackgroundColor3 = active_uipallet.Main }):Play()
                    end
                end)

                -- 選択トグル動作
                option.MouseButton1Click:Connect(function()
                    self:ToggleValue(v, true)
                    updateOptionView()
                end)
            end
        else
            self:Collapse()
        end

        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end)

    -- 外側の枠ホバー
    local hoverBkgCol = active_color.Light(active_uipallet.Main, 0.0875)
    local normalBkgCol = active_color.Light(active_uipallet.Main, 0.034)
    dropdown.MouseEnter:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverBkgCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverBkgCol }):Play()
        end
    end)
    dropdown.MouseLeave:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = normalBkgCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = normalBkgCol }):Play()
        end
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    self:UpdateTitleText()

    return self
end

function MultiDropdown:UpdateTitleText()
    local selectedNames = {}
    for _, optName in ipairs(self.List) do
        if self.Value[optName] then
            table.insert(selectedNames, optName)
        end
    end
    local titleText = #selectedNames > 0 and table.concat(selectedNames, ", ") or "None"
    self.Title.Text = self.Name .. " - [" .. titleText .. "]"
end

function MultiDropdown:ToggleValue(val, mouse)
    if self.Value[val] ~= nil then
        self.Value[val] = not self.Value[val]
        self:UpdateTitleText()
        if self.Callback then
            self.Callback(self.Value, mouse)
        end
    end
end

function MultiDropdown:Collapse()
    if self.DropdownChildren then
        self.Arrow.Rotation = 90
        self.DropdownChildren:Destroy()
        self.DropdownChildren = nil
        self.Object.Size = UDim2.new(1, 0, 0, 40)

        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end
end

function MultiDropdown:Save(tab)
    tab[self.Name] = {Value = self.Value}
end

function MultiDropdown:Load(tab)
    if tab and self.Value ~= tab.Value then
        self.Value = tab.Value
        self:UpdateTitleText()
    end
end

return MultiDropdown
end)
__bundle_register("gui.components.Dropdown", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/Dropdown.lua
local TweenService = game:GetService("TweenService")

local Dropdown = {}
Dropdown.__index = Dropdown

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function Dropdown.new(parent, nameOrSettings, list, defaultValue, callback, moduleInstance)
    local self = setmetatable({}, Dropdown)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        list = optionsettings.List
        defaultValue = optionsettings.Default
        callback = optionsettings.Function
    end

    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = moduleInstance or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    local active_color = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween = (tween and tween.Tween) and tween or nil

    self.Name = name
    self.Type = "Dropdown"
    self.List = list or {}
    self.Value = table.find(self.List, defaultValue) and defaultValue or self.List[1] or "None"
    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.ModuleInstance = moduleInstance -- 親のモジュールオブジェクト

    -- ベースボタン枠（初期の閉じている高さ: 40）
    local dropdown = Instance.new("TextButton")
    dropdown.Name = name .. "DropdownSetting"
    dropdown.Size = UDim2.new(1, 0, 0, 40)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    dropdown.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentColor, 0.02) or parentColor
    dropdown.BorderSizePixel = 0
    dropdown.AutoButtonColor = false
    dropdown.Visible = optionsettings.Visible == nil or optionsettings.Visible
    dropdown.Text = ""
    dropdown.Parent = parent

    if addTooltip and (optionsettings.Tooltip or name) then
        addTooltip(dropdown, optionsettings.Tooltip or name)
    end

    -- 背景枠 (BKG) - 余白を 12px に統一
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    -- 縦サイズを固定（31）から、親フレームの伸縮（1, -9）に自動追従するようレスポンシブ化
    bkg.Size = UDim2.new(1, -24, 1, -9)
    bkg.Position = UDim2.fromOffset(12, 4)
    bkg.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.034)
    bkg.BorderSizePixel = 0
    bkg.Parent = dropdown

    if addCorner then
        addCorner(bkg, UDim.new(0, 6))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = bkg
    end

    -- メイン選択ボタン
    local button = Instance.new("TextButton")
    button.Name = "Dropdown"
    button.Size = UDim2.new(1, -2, 1, -2)
    button.Position = UDim2.fromOffset(1, 1)
    button.BackgroundColor3 = active_uipallet.Main
    button.AutoButtonColor = false
    button.Text = ""
    button.Parent = bkg

    if addCorner then
        addCorner(button, UDim.new(0, 6))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = button
    end

    -- 【内側パディングの自動解決】
    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 12)
    buttonPadding.PaddingRight = UDim.new(0, 12)
    buttonPadding.Parent = button

    -- タイトルテキスト
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -30, 0, 29) -- 縦幅はタイトル行の29pxに固定
    title.BackgroundTransparency = 1
    title.Text = name .. " - " .. self.Value
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
    title.TextSize = 17 
    title.TextTruncate = Enum.TextTruncate.AtEnd
    applyFont(title, active_uipallet.Font)
    title.Parent = button

    -- 開閉矢印アイコン
    local arrow = Instance.new("ImageLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.fromOffset(12, 12)
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, 0, 0, 14)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://10709791437"
    arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
    arrow.ScaleType = Enum.ScaleType.Fit
    arrow.Rotation = 90
    arrow.Parent = button

    self.Object = dropdown
    self.Bkg = bkg
    self.Button = button
    self.Title = title
    self.Arrow = arrow
    self.DropdownChildren = nil

    -- 展開・閉縮ロジック
    button.MouseButton1Click:Connect(function()
        if not self.DropdownChildren then
            arrow.Rotation = 270
            
            -- 🌟 【修正】選択肢をリストから除外せずすべて表示するため、高さのマイナス1補正を削除
            local listSize = #self.List
            local expandedHeight = 40 + listSize * 26
            dropdown.Size = UDim2.new(1, 0, 0, expandedHeight)

            local childrenFrame = Instance.new("Frame")
            childrenFrame.Name = "Children"
            childrenFrame.Size = UDim2.new(1, 0, 0, listSize * 26)
            childrenFrame.Position = UDim2.fromOffset(0, 27)
            childrenFrame.BackgroundTransparency = 1
            childrenFrame.Parent = button
            self.DropdownChildren = childrenFrame

            local ind = 0
            for _, v in ipairs(self.List) do
                -- 🌟 【修正】v ~= self.Value による除外を無くし、すべてのボタンを生成します
                local option = Instance.new("TextButton")
                option.Name = v .. "Option"
                option.Size = UDim2.new(1, 0, 0, 26)
                option.Position = UDim2.fromOffset(0, ind * 26)
                option.BackgroundColor3 = active_uipallet.Main
                option.BorderSizePixel = 0
                option.AutoButtonColor = false
                option.Text = v
                option.TextXAlignment = Enum.TextXAlignment.Left
                
                -- 🌟 現在選ばれている項目は文字色を明るく（アクティブ化）し、それ以外は元の暗い色にします
                if v == self.Value then
                    option.TextColor3 = active_uipallet.Text
                else
                    option.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
                end
                
                option.TextSize = 15 
                option.TextTruncate = Enum.TextTruncate.AtEnd
                applyFont(option, active_uipallet.Font)
                option.Parent = childrenFrame

                -- 各オプションの左インデントをシステム統一
                local optionPadding = Instance.new("UIPadding")
                optionPadding.PaddingLeft = UDim.new(0, 12)
                optionPadding.PaddingRight = UDim.new(0, 12)
                optionPadding.Parent = option

                -- ホバー処理
                local hoverCol = active_color.Light(active_uipallet.Main, 0.02)
                option.MouseEnter:Connect(function()
                    if active_tween then
                        active_tween:Tween(option, active_uipallet.Tween, { BackgroundColor3 = hoverCol })
                    else
                        TweenService:Create(option, active_uipallet.Tween, { BackgroundColor3 = hoverCol }):Play()
                    end
                end)
                option.MouseLeave:Connect(function()
                    if active_tween then
                        active_tween:Tween(option, active_uipallet.Tween, { BackgroundColor3 = active_uipallet.Main })
                    else
                        TweenService:Create(option, active_uipallet.Tween, { BackgroundColor3 = active_uipallet.Main }):Play()
                    end
                end)

                -- 選択クリック時
                option.MouseButton1Click:Connect(function()
                    self:SetValue(v, true)
                end)

                ind = ind + 1
            end
        else
            self:SetValue(self.Value, true)
        end

        -- 親メニュー全体の高さを連動して再更新
        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end)

    -- 外側の枠ホバー
    local hoverBkgCol = active_color.Light(active_uipallet.Main, 0.0875)
    local normalBkgCol = active_color.Light(active_uipallet.Main, 0.034)
    dropdown.MouseEnter:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverBkgCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverBkgCol }):Play()
        end
    end)
    dropdown.MouseLeave:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = normalBkgCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = normalBkgCol }):Play()
        end
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    return self
end

function Dropdown:Save(tab)
    tab[self.Name] = {Value = self.Value}
end

function Dropdown:Load(tab)
    if self.Value ~= tab.Value then
        self:SetValue(tab.Value)
    end
end

function Dropdown:Change(list)
    self.List = list or {}
    if not table.find(self.List, self.Value) then
        self:SetValue(self.Value)
    end
end

function Dropdown:SetValue(val, mouse)
    self.Value = table.find(self.List, val) and val or self.List[1] or "None"
    self.Title.Text = self.Name .. " - " .. self.Value

    -- 展開されていた場合は閉じる
    if self.DropdownChildren then
        self.Arrow.Rotation = 90
        self.DropdownChildren:Destroy()
        self.DropdownChildren = nil
        self.Object.Size = UDim2.new(1, 0, 0, 40)

        -- 閉じたことを親ウィンドウに通知してリサイズ
        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end

    if self.Callback then
        self.Callback(self.Value, mouse)
    end
end

return Dropdown
end)
__bundle_register("gui.components.ColorPicker", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/ColorPicker.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local ColorPicker = {}
ColorPicker.__index = ColorPicker

-- パレット
local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function ColorPicker.new(parent, nameOrSettings, defaultValue, callback, assets, api)
    local self = setmetatable({}, ColorPicker)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        callback = optionsettings.Function
    end

    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    local active_color = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween = (tween and tween.Tween) and tween or nil

    self.Name = name
    self.Type = "ColorSlider"
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.Callback = callback or function() end

    -- 値の初期化 (HSV + 不透明度)
    self.Hue = optionsettings.DefaultHue or (type(defaultValue) == "table" and defaultValue.Hue) or 0.44
    self.Sat = optionsettings.DefaultSat or (type(defaultValue) == "table" and defaultValue.Sat) or 1
    self.Value = optionsettings.DefaultValue or (type(defaultValue) == "table" and defaultValue.Value) or 1
    self.Opacity = optionsettings.DefaultOpacity or (type(defaultValue) == "table" and defaultValue.Opacity) or 1
    self.Rainbow = false

    -- ── サブスライダー (Saturation / Vibrance / Opacity) の生成用ヘルパー ──
    local function createSubSlider(sliderName, gradientColor)
        local sub = Instance.new("TextButton")
        sub.Name = name .. "Slider" .. sliderName
        sub.Size = UDim2.new(1, 0, 0, 50)
        local parentCol = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
        sub.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentCol, 0.02) or parentCol
        sub.BorderSizePixel = 0
        sub.AutoButtonColor = false
        sub.Visible = false
        sub.Text = ""
        sub.Parent = parent

        local subTitle = Instance.new("TextLabel")
        subTitle.Name = "Title"
        subTitle.Size = UDim2.fromOffset(100, 30)
        subTitle.Position = UDim2.fromOffset(12, 2)
        subTitle.BackgroundTransparency = 1
        subTitle.Text = sliderName
        subTitle.TextXAlignment = Enum.TextXAlignment.Left
        subTitle.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
        subTitle.TextSize = 13 
        applyFont(subTitle, active_uipallet.Font)
        subTitle.Parent = sub

        local subBkg = Instance.new("Frame")
        subBkg.Name = "Slider"
        subBkg.Size = UDim2.new(1, -24, 0, 2) 
        subBkg.Position = UDim2.fromOffset(12, 37)
        subBkg.BackgroundColor3 = Color3.new(1, 1, 1)
        subBkg.BorderSizePixel = 0
        subBkg.Parent = sub

        local subGrad = Instance.new("UIGradient")
        subGrad.Color = gradientColor
        subGrad.Parent = subBkg

        local subFill = Instance.new("Frame")
        subFill.Name = "Fill"
        local initialVal = (sliderName == "Saturation" and self.Sat) or (sliderName == "Vibrance" and self.Value) or self.Opacity
        subFill.Size = UDim2.fromScale(math.clamp(initialVal, 0.01, 0.99), 1)
        subFill.Position = UDim2.new()
        subFill.BackgroundTransparency = 1
        subFill.Parent = subBkg

        local knobHolder = Instance.new("Frame")
        knobHolder.Name = "Knob"
        knobHolder.Size = UDim2.fromOffset(24, 4)
        knobHolder.Position = UDim2.fromScale(1, 0.5)
        knobHolder.AnchorPoint = Vector2.new(0.5, 0.5)
        knobHolder.BackgroundColor3 = sub.BackgroundColor3
        knobHolder.BorderSizePixel = 0
        knobHolder.Parent = subFill

        local subKnob = Instance.new("Frame")
        subKnob.Name = "KnobCircle"
        subKnob.Size = UDim2.fromOffset(14, 14)
        subKnob.Position = UDim2.fromScale(0.5, 0.5)
        subKnob.AnchorPoint = Vector2.new(0.5, 0.5)
        subKnob.BackgroundColor3 = active_uipallet.Text
        subKnob.Parent = knobHolder

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = subKnob

        -- 入力ドラッグ処理
        local subDragging = false
        local dragConn = nil

        local function updateSubDrag(input)
            local ratio = math.clamp((input.Position.X - subBkg.AbsolutePosition.X) / subBkg.AbsoluteSize.X, 0, 1)
            if sliderName == "Saturation" then
                self:SetValue(nil, ratio, nil, nil)
            elseif sliderName == "Vibrance" then
                self:SetValue(nil, nil, ratio, nil)
            elseif sliderName == "Opacity" then
                self:SetValue(nil, nil, nil, ratio)
            end
        end

        sub.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                subDragging = true
                if dragConn then dragConn:Disconnect() end
                updateSubDrag(input)

                dragConn = UserInputService.InputChanged:Connect(function(changedInput)
                    if subDragging and (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) then
                        updateSubDrag(changedInput)
                    end
                end)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if subDragging then
                    subDragging = false
                    if dragConn then
                        dragConn:Disconnect()
                        dragConn = nil
                    end
                end
            end
        end)

        sub.MouseEnter:Connect(function()
            TweenService:Create(subKnob, active_uipallet.Tween, {Size = UDim2.fromOffset(16, 16)}):Play()
        end)
        sub.MouseLeave:Connect(function()
            if not subDragging then
                TweenService:Create(subKnob, active_uipallet.Tween, {Size = UDim2.fromOffset(14, 14)}):Play()
            end
        end)

        return sub
    end

    -- ── メインスライダー (Hue) ──
    local slider = Instance.new("TextButton")
    slider.Name = name .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 50)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    slider.BackgroundColor3 = optionsettings.Darker and colorDark(parentColor, 0.02) or parentColor
    slider.BorderSizePixel = 0
    slider.AutoButtonColor = false
    slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
    slider.Text = ""
    slider.Parent = parent

    if addTooltip and optionsettings.Tooltip then
        addTooltip(slider, optionsettings.Tooltip)
    end

    -- タイトル
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromOffset(150, 30)
    title.Position = UDim2.fromOffset(12, 2)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = colorDark(active_uipallet.Text, 0.16)
    title.TextSize = 17 
    applyFont(title, active_uipallet.Font)
    title.Parent = slider

    -- RGB・Hex入力用のvaluebox (隠し直接入力枠)
    local valuebox = Instance.new("TextBox")
    valuebox.Name = "Box"
    valuebox.Size = UDim2.fromOffset(90, 20)
    valuebox.Position = UDim2.new(1, -102, 0, 7)
    valuebox.BackgroundTransparency = 1
    valuebox.Visible = false
    valuebox.Text = ""
    valuebox.TextXAlignment = Enum.TextXAlignment.Right
    valuebox.TextColor3 = colorDark(active_uipallet.Text, 0.16)
    valuebox.TextSize = 15
    applyFont(valuebox, active_uipallet.Font)
    valuebox.ClearTextOnFocus = true
    valuebox.Parent = slider

    -- 虹色グラデーション用のトラック
    local bkg = Instance.new("Frame")
    bkg.Name = "Slider"
    bkg.Size = UDim2.new(1, -24, 0, 2)
    bkg.Position = UDim2.fromOffset(12, 39)
    bkg.BackgroundColor3 = Color3.new(1, 1, 1)
    bkg.BorderSizePixel = 0
    bkg.Parent = slider

    local rainbowTable = {}
    for i = 0, 1, 0.1 do
        table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
    end

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(rainbowTable)
    gradient.Parent = bkg

    local fill = bkg:Clone()
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.01, 0.99), 1)
    fill.Position = UDim2.new()
    fill.BackgroundTransparency = 1
    fill.Parent = bkg

    -- Color Preview
    local preview = Instance.new("TextButton")
    preview.Name = "Preview"
    preview.Size = UDim2.fromOffset(14, 14)
    preview.Position = UDim2.new(1, -26, 0, 10) 
    preview.BackgroundColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
    preview.BackgroundTransparency = 1 - self.Opacity
    preview.BorderSizePixel = 0
    preview.Text = ""
    preview.Parent = slider

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(1, 0)
    previewCorner.Parent = preview

    local previewStroke = Instance.new("UIStroke")
    previewStroke.Thickness = 1
    previewStroke.Color = Color3.fromRGB(80, 80, 80)
    previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    previewStroke.Parent = preview

    -- アコーディオン展開ボタン
    local expandbutton = Instance.new("TextButton")
    expandbutton.Name = "Expand"
    expandbutton.Size = UDim2.fromOffset(17, 13)
    
    local textWidth = TextService:GetTextSize(title.Text, title.TextSize, title.Font, Vector2.new(1000, 1000)).X
    expandbutton.Position = UDim2.new(0, textWidth + 15, 0, 7)
    expandbutton.BackgroundTransparency = 1
    expandbutton.Text = ""
    expandbutton.Parent = slider

    local expand = Instance.new("ImageLabel")
    expand.Name = "Expand"
    expand.Size = UDim2.fromOffset(9, 5)
    expand.Position = UDim2.fromOffset(4, 4)
    expand.BackgroundTransparency = 1
    expand.Image = "rbxassetid://10709790948" 
    expand.ImageColor3 = active_color.Dark(active_uipallet.Text, 0.43)
    expand.Parent = expandbutton

    -- レインボー切り替えボタン
    local rainbow = Instance.new("TextButton")
    rainbow.Name = "Rainbow"
    rainbow.Size = UDim2.fromOffset(14, 14)
    rainbow.Position = UDim2.new(1, -48, 0, 10)
    rainbow.BackgroundTransparency = 1
    rainbow.Text = ""
    rainbow.Parent = slider

    local rainbowCircle = Instance.new("Frame")
    rainbowCircle.Size = UDim2.fromScale(1, 1)
    rainbowCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    rainbowCircle.BorderSizePixel = 0
    rainbowCircle.Parent = rainbow

    local rcCorner = Instance.new("UICorner")
    rcCorner.CornerRadius = UDim.new(1, 0)
    rcCorner.Parent = rainbowCircle

    local rcGrad = Instance.new("UIGradient")
    rcGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 46, 52)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5, 127, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(228, 125, 43))
    })
    rcGrad.Parent = rainbowCircle

    local rainbowStroke = Instance.new("UIStroke")
    rainbowStroke.Thickness = 1.5
    rainbowStroke.Color = Color3.fromRGB(255, 255, 255)
    rainbowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rainbowStroke.Enabled = false
    rainbowStroke.Parent = rainbowCircle

    local knobholder = Instance.new("Frame")
    knobholder.Name = "Knob"
    knobholder.Size = UDim2.fromOffset(24, 4)
    knobholder.Position = UDim2.fromScale(1, 0.5)
    knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
    knobholder.BackgroundColor3 = slider.BackgroundColor3
    knobholder.BorderSizePixel = 0
    knobholder.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.fromScale(0.5, 0.5)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = active_uipallet.Text
    knob.Parent = knobholder

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    -- 3つの各種サブスライダーの構築
    local satSlider = createSubSlider("Saturation", ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
    }))
    local vibSlider = createSubSlider("Vibrance", ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
    }))
    local opSlider = createSubSlider("Opacity", ColorSequence.new({
        ColorSequenceKeypoint.new(0, active_color.Dark(active_uipallet.Main, 0.02)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, self.Value))
    }))

    self.Object     = slider
    self.Track      = bkg
    self.Fill       = fill
    self.Preview    = preview
    self.ValueBox   = valuebox
    self.RainbowStroke = rainbowStroke
    
    self.SatSlider  = satSlider
    self.VibSlider  = vibSlider
    self.OpSlider   = opSlider
    self.ExpandIcon = expand

    -- メインスライダー（Hue）ドラッグ処理
    local mainDragging = false
    local mainDragConn = nil

    local function updateMainDrag(input)
        local ratio = math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
        self:SetValue(ratio, nil, nil, nil)
    end

    slider.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and (input.Position.Y - slider.AbsolutePosition.Y) > 20 then
            mainDragging = true
            if mainDragConn then mainDragConn:Disconnect() end
            updateMainDrag(input)

            mainDragConn = UserInputService.InputChanged:Connect(function(changedInput)
                if mainDragging and (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) then
                    updateMainDrag(changedInput)
                end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if mainDragging then
                mainDragging = false
                if mainDragConn then
                    mainDragConn:Disconnect()
                    mainDragConn = nil
                end
            end
        end
    end)

    slider.MouseEnter:Connect(function()
        TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(16, 16)}):Play()
    end)
    slider.MouseLeave:Connect(function()
        if not mainDragging then
            TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(14, 14)}):Play()
        end
    end)

    -- 各種ボタン・テキスト入力接続
    preview.MouseButton1Click:Connect(function()
        preview.Visible = false
        rainbow.Visible = false -- 入力窓展開時、重なりを防ぐため一時的にレインボーボタンを隠す
        valuebox.Visible = true
        valuebox:CaptureFocus()
        local c = Color3.fromHSV(self.Hue, self.Sat, self.Value)
        valuebox.Text = math.round(c.R * 255) .. ", " .. math.round(c.G * 255) .. ", " .. math.round(c.B * 255)
    end)

    valuebox.FocusLost:Connect(function(enter)
        preview.Visible = true
        rainbow.Visible = true -- 入力窓が閉じられた際、レインボーボタンを再表示する
        valuebox.Visible = false
        if enter then
            local commas = valuebox.Text:split(",")
            local suc, res = pcall(function()
                return tonumber(commas[1]) and Color3.fromRGB(tonumber(commas[1]), tonumber(commas[2]), tonumber(commas[3])) or Color3.fromHex(valuebox.Text)
            end)
            if suc then
                if self.Rainbow then
                    self:Toggle()
                end
                self:SetValue(res:ToHSV())
            end
        end
    end)

    slider:GetPropertyChangedSignal("Visible"):Connect(function()
        local state = expand.Rotation == 180 and slider.Visible
        satSlider.Visible = state
        vibSlider.Visible = state
        opSlider.Visible = state
    end)

    expandbutton.MouseEnter:Connect(function()
        expand.ImageColor3 = active_color.Dark(active_uipallet.Text, 0.43)
    end)
    expandbutton.MouseLeave:Connect(function()
        expand.ImageColor3 = active_color.Dark(active_uipallet.Text, 0.43)
    end)

    expandbutton.MouseButton1Click:Connect(function()
        local state = not satSlider.Visible
        satSlider.Visible = state
        vibSlider.Visible = state
        opSlider.Visible = state
        expand.Rotation = state and 180 or 0
    end)

    rainbow.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- 🌟 【重要バグ修正】変数名「button」を「slider」に変更して nil インデックスエラーを完全に解決
    slider.MouseButton1Click:Connect(function()
        self.Window.Visible = not self.Window.Visible
        
        local guiCol = active_mainapi and active_mainapi.GUIColor or {Hue = 0, Sat = 1, Value = 1}
        local activeColor = self.Window.Visible and Color3.fromHSV(guiCol.Hue, guiCol.Sat, guiCol.Value) or active_color.Light(active_uipallet.Main, 0.034)
        
        TweenService:Create(bkg, TweenInfo.new(0.12), {BackgroundColor3 = activeColor}):Play()
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    -- 初期表示の同期
    self:SetValue(self.Hue, self.Sat, self.Value, self.Opacity)

    return self
end

-- ── Methods ──────────────────────────────────────────────────────────────────

function ColorPicker:Save(tab)
    tab[self.Name] = {
        Hue = self.Hue,
        Sat = self.Sat,
        Value = self.Value,
        Opacity = self.Opacity,
        Rainbow = self.Rainbow
    }
end

function ColorPicker:Load(tab)
    if tab.Rainbow ~= self.Rainbow then
        self:Toggle()
    end
    if self.Hue ~= tab.Hue or self.Sat ~= tab.Sat or self.Value ~= tab.Value or self.Opacity ~= tab.Opacity then
        self:SetValue(tab.Hue, tab.Sat, tab.Value, tab.Opacity)
    end
end

function ColorPicker:SetValue(h, s, v, o)
    self.Hue = h or self.Hue
    self.Sat = s or self.Sat
    self.Value = v or self.Value
    self.Opacity = o or self.Opacity

    self.Preview.BackgroundColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
    self.Preview.BackgroundTransparency = 1 - self.Opacity

    self.SatSlider.Slider.UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
    })
    self.VibSlider.Slider.UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
    })
    self.OpSlider.Slider.UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorDark(self.uipallet.Main, 0.02)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, self.Value))
    })

    if self.Rainbow then
        self.Fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.01, 0.99), 1)
    else
        TweenService:Create(self.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Hue, 0.01, 0.99), 1)
        }):Play()
    end

    if s then
        TweenService:Create(self.SatSlider.Slider.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Sat, 0.01, 0.99), 1)
        }):Play()
    end
    if v then
        TweenService:Create(self.VibSlider.Slider.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Value, 0.01, 0.99), 1)
        }):Play()
    end
    if o then
        TweenService:Create(self.OpSlider.Slider.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Opacity, 0.01, 0.99), 1)
        }):Play()
    end

    if self.Callback then
        self.Callback(self.Hue, self.Sat, self.Value, self.Opacity)
    end
end

function ColorPicker:Toggle()
    self.Rainbow = not self.Rainbow
    self.RainbowStroke.Enabled = self.Rainbow

    if self.Rainbow then
        if self.mainapi and self.mainapi.RainbowTable then
            table.insert(self.mainapi.RainbowTable, self)
        end
    else
        if self.mainapi and self.mainapi.RainbowTable then
            local ind = table.find(self.mainapi.RainbowTable, self)
            if ind then
                table.remove(self.mainapi.RainbowTable, ind)
            end
        end
    end
end

return ColorPicker
end)
__bundle_register("gui.components.Button", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/Button.lua
local TweenService = game:GetService("TweenService")

local Button = {}
Button.__index = Button

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function Button.new(parent, nameOrSettings, callback, api)
    local self = setmetatable({}, Button)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        callback = optionsettings.Function
    end

    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    local active_color = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween = (tween and tween.Tween) and tween or nil

    self.Name = name
    self.Type = "Button"
    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0

    -- ベース枠
    local button = Instance.new("TextButton")
    button.Name = name .. "ButtonSetting"
    button.Size = UDim2.new(1, 0, 0, 31)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    button.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentColor, 0.02) or parentColor
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Visible = optionsettings.Visible == nil or optionsettings.Visible
    button.Text = ""
    button.Parent = parent

    if addTooltip and optionsettings.Tooltip then
        addTooltip(button, optionsettings.Tooltip)
    end

    -- ボタン背景枠 (BKG)
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    -- 🌟 【整列調整】左右フチに12pxずつのゆとりを持たせ、ToggleやTextBoxの横幅とぴったり揃うようにレスポンシブ化
    bkg.Size = UDim2.new(1, -24, 0, 27)
    bkg.Position = UDim2.fromOffset(12, 2)
    bkg.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.05)
    bkg.BorderSizePixel = 0
    bkg.Parent = button

    if addCorner then
        addCorner(bkg, UDim.new(0, 4))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = bkg
    end

    -- ラベル (Label)
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -4, 1, -4)
    label.Position = UDim2.fromOffset(2, 2)
    label.BackgroundColor3 = active_uipallet.Main
    label.Text = name
    label.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
    label.TextSize = 14
    applyFont(label, active_uipallet.Font)
    label.Parent = bkg

    if addCorner then
        addCorner(label, UDim.new(0, 4))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = label
    end

    self.Object = button
    self.Bkg = bkg
    self.Label = label

    -- ホバーアニメーションのカラー設定
    local hoverCol = active_color.Light(active_uipallet.Main, 0.0875)
    local normalCol = active_color.Light(active_uipallet.Main, 0.05)

    button.MouseEnter:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverCol }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = normalCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = normalCol }):Play()
        end
    end)

    button.MouseButton1Click:Connect(function()
        if self.Callback then
            task.spawn(self.Callback)
        end
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    return self
end

function Button:Save(tab)
    -- ボタンは値を保存しないため空処理
end

function Button:Load(tab)
    -- 互換性確保のため空処理
end

return Button
end)
__bundle_register("gui.components.TextBox", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/TextBox.lua
local TweenService = game:GetService("TweenService")

local TextBox = {}
TextBox.__index = TextBox

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function TextBox.new(parent, nameOrSettings, defaultValue, placeholder, callback, api)
    local self = setmetatable({}, TextBox)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        defaultValue = optionsettings.Default
        placeholder = optionsettings.Placeholder
        callback = optionsettings.Function
    end

    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet

    self.Name = name
    self.Type = "TextBox"
    self.Value = defaultValue or ""
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.Callback = callback or function() end

    -- ベース枠
    local textbox = Instance.new("TextButton")
    textbox.Name = name .. "TextBoxSetting"
    textbox.Size = UDim2.new(1, 0, 0, 58)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    textbox.BackgroundColor3 = optionsettings.Darker and colorDark(parentColor, 0.02) or parentColor
    textbox.BorderSizePixel = 0
    textbox.AutoButtonColor = false
    textbox.Visible = optionsettings.Visible == nil or optionsettings.Visible
    textbox.Text = ""
    textbox.Parent = parent

    if addTooltip and optionsettings.Tooltip then
        addTooltip(textbox, optionsettings.Tooltip)
    end

    -- タイトル
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -24, 0, 20)
    title.Position = UDim2.fromOffset(12, 3) -- 12pxの左端整列
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 🌟 【スライダーに統一】常に落ち着いた暗い色
    title.TextSize = 17 -- 🌟 【スライダーに統一】17pxに拡大
    applyFont(title, active_uipallet.Font)
    title.Parent = textbox

    -- 入力背景枠 (BKG)
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    bkg.Size = UDim2.new(1, -24, 0, 29) -- 左右12pxずつ（横幅-24）
    bkg.Position = UDim2.fromOffset(12, 23)
    bkg.BackgroundColor3 = colorLight(active_uipallet.Main, 0.02)
    bkg.BorderSizePixel = 0
    bkg.Parent = textbox

    if addCorner then
        addCorner(bkg, UDim.new(0, 4))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = bkg
    end

    -- テキスト入力ボックス (Box)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.fromOffset(8, 0)
    box.BackgroundTransparency = 1
    box.Text = self.Value
    box.PlaceholderText = placeholder or "Click to set"
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 🌟 【スライダーに統一】
    box.PlaceholderColor3 = colorDark(active_uipallet.Text, 0.31) -- 🌟 【スライダーに統一】
    box.TextSize = 17 -- 🌟 【スライダーに統一】入力中の文字も17pxに拡大
    applyFont(box, active_uipallet.Font)
    box.ClearTextOnFocus = false
    box.Parent = bkg

    self.Object = textbox
    self.Bkg = bkg
    self.Box = box

    -- 接続イベント
    textbox.MouseButton1Click:Connect(function()
        box:CaptureFocus()
    end)

    box.FocusLost:Connect(function(enter)
        self:SetValue(box.Text, enter)
    end)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        self:SetValue(box.Text, false)
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    return self
end

function TextBox:Save(tab)
    tab[self.Name] = {Value = self.Value}
end

function TextBox:Load(tab)
    if tab and self.Value ~= tab.Value then
        self:SetValue(tab.Value, true)
    end
end

function TextBox:SetValue(val, enter)
    if self.Value == val then return end -- 無限ループ防止
    self.Value = val
    if self.Box.Text ~= val then
        self.Box.Text = val
    end
    if self.Callback then
        task.spawn(self.Callback, val, enter)
    end
end

return TextBox
end)
__bundle_register("gui.components.Slider", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/Slider.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Slider = {}
Slider.__index = Slider

-- 🌟 パレットを 200 の落ち着いたグレーに戻しました
local default_uipallet = {
    Main = Color3.fromRGB(26, 25, 26),
    Text = Color3.fromRGB(200, 200, 200), 
    Font = Enum.Font.SourceSans, 
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

-- フォントの型（Font / EnumItem）を判別して安全に適用するヘルパー関数
local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function Slider.new(parent, nameOrSettings, minLimit, maxLimit, defaultValue, step, suffix, callback, assets, api)
    local self = setmetatable({}, Slider)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        minLimit = optionsettings.Min
        maxLimit = optionsettings.Max
        defaultValue = optionsettings.Default
        step = optionsettings.Step
        suffix = optionsettings.Suffix
        callback = optionsettings.Function
    end

    -- グローバルおよびAPI解決
    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet

    self.Name = name
    self.Type = "Slider"
    self.MinLimit = minLimit or 0
    self.MaxLimit = maxLimit or 10
    self.Step = step or 1
    self.Decimal = optionsettings.Decimal or (self.Step < 1 and 10 or 1)
    self.Suffix = suffix or ""
    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0

    self.Value = math.clamp(defaultValue or minLimit or 0, self.MinLimit, self.MaxLimit)

    -- ────────────── GUI要素構築 ──────────────
    local slider = Instance.new("Frame")
    slider.Name = name .. "SliderSetting"
    slider.Size = UDim2.new(1, 0, 0, 50) 
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    slider.BackgroundColor3 = optionsettings.Darker and colorDark(parentColor, 0.02) or parentColor
    slider.BorderSizePixel = 0
    slider.Parent = parent

    -- ツールチップの追加
    if addTooltip and optionsettings.Tooltip then
        addTooltip(slider, optionsettings.Tooltip)
    end

    -- タイトルラベル
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromOffset(150, 30)
    title.Position = UDim2.fromOffset(12, 2)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 常に落ち着いた暗い色
    title.TextSize = 17 
    applyFont(title, active_uipallet.Font) 
    title.Parent = slider

    -- 値表示ボタン
    local valuebutton = Instance.new("TextButton")
    valuebutton.Name = "Value"
    valuebutton.Size = UDim2.fromOffset(80, 20)
    valuebutton.Position = UDim2.new(1, -92, 0, 7)
    valuebutton.BackgroundTransparency = 1
    valuebutton.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 常に落ち着いた暗い色
    valuebutton.TextSize = 17 
    applyFont(valuebutton, active_uipallet.Font) 
    valuebutton.TextXAlignment = Enum.TextXAlignment.Right
    valuebutton.Parent = slider

    -- 直接入力用 TextBox
    local valuebox = Instance.new("TextBox")
    valuebox.Name = "Box"
    valuebox.Size = valuebutton.Size
    valuebox.Position = valuebutton.Position
    valuebox.BackgroundTransparency = 1
    valuebox.Visible = false
    valuebox.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 常に落ち着いた暗い色
    valuebox.TextSize = 17 
    applyFont(valuebox, active_uipallet.Font) 
    valuebox.TextXAlignment = Enum.TextXAlignment.Right
    valuebox.ClearTextOnFocus = false
    valuebox.Parent = slider

    -- ────────────── TRACK ──────────────
    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.Size = UDim2.new(1, -24, 0, 20)
    track.Position = UDim2.new(0.5, 0, 0, 37) 
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.BackgroundTransparency = 1
    track.Text = ""
    track.ZIndex = 4
    track.Parent = slider

    -- トラック背景線（極細 2px）
    local bkg = Instance.new("Frame")
    bkg.Name = "Slider"
    bkg.Size = UDim2.new(1, 0, 0, 2)
    bkg.Position = UDim2.new(0, 0, 0.5, -1)
    bkg.BackgroundColor3 = colorLight(active_uipallet.Main, 0.034)
    bkg.BorderSizePixel = 0
    bkg.ZIndex = 5
    bkg.Parent = track

    -- 選択範囲の緑塗り
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 0, 2)
    fill.Position = UDim2.new(0, 0, 0.5, -1)
    
    local guiCol = active_mainapi and active_mainapi.GUIColor
    local initCol = guiCol and Color3.fromHSV(guiCol.Hue, guiCol.Sat, guiCol.Value) or Color3.fromRGB(0, 204, 136)
    fill.BackgroundColor3 = initCol
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = track

    -- ハンドル
    local handle = Instance.new("TextButton")
    handle.Name = "Handle"
    handle.Size = UDim2.fromOffset(30, 30)
    handle.Position = UDim2.new(0, 0, 0.5, 0)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.BackgroundTransparency = 1
    handle.Text = ""
    handle.ZIndex = 7
    handle.Parent = track

    -- 丸型ノブ (14x14)
    local knob = Instance.new("Frame")
    knob.Name = "KnobCircle"
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.new(0.5, 0, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = initCol
    knob.BorderSizePixel = 0
    knob.ZIndex = 8
    knob.Parent = handle

    if addCorner then
        addCorner(knob, UDim.new(1, 0))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = knob
    end

    self.Object = slider
    self.Track = track
    self.Bkg = bkg
    self.Fill = fill
    self.Handle = handle
    self.Knob = knob
    self.ValueButton = valuebutton
    self.ValueBox = valuebox

    -- 内部処理ヘルパー
    local function formatValue(val)
        local decimals = 0
        local stepStr = tostring(self.Step)
        local dotIdx = stepStr:find("%.")
        if dotIdx then
            decimals = #stepStr - dotIdx
        end
        return string.format("%." .. decimals .. "f", val)
    end

    local function getPercentFromValue(val)
        return (val - self.MinLimit) / (self.MaxLimit - self.MinLimit)
    end

    local function getValueFromPercent(pct)
        local val = self.MinLimit + (self.MaxLimit - self.MinLimit) * pct
        return math.clamp(math.round(val / self.Step) * self.Step, self.MinLimit, self.MaxLimit)
    end

    local currentPct = getPercentFromValue(self.Value)

    -- ドラッグ用のスムーズTween設定（吸いつくような操作感にするための短めの時間）
    local dragTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- UI同期
    local function updateUI(animate)
        local handlePos = UDim2.new(currentPct, 0, 0.5, 0)
        local fillSize = UDim2.new(currentPct, 0, 0, 2)

        if animate then
            TweenService:Create(handle, active_uipallet.Tween, {Position = handlePos}):Play()
            TweenService:Create(fill,   active_uipallet.Tween, {Size     = fillSize}):Play()
            TweenService:Create(knob,   active_uipallet.Tween, {Size     = UDim2.fromOffset(14, 14)}):Play()
        else
            -- ドラッグ中も滑らかに移動させるため、短いTweenを適用します
            TweenService:Create(handle, dragTweenInfo, {Position = handlePos}):Play()
            TweenService:Create(fill,   dragTweenInfo, {Size     = fillSize}):Play()
        end

        local suffixText = ""
        if self.Suffix ~= "" then
            if type(self.Suffix) == "function" then
                suffixText = " " .. self.Suffix(self.Value)
            else
                suffixText = " " .. self.Suffix
            end
        end
        valuebutton.Text = formatValue(self.Value) .. suffixText
    end

    updateUI(false)

    -- ドラッグ処理
    local connection = nil
    local dragging = false

    local function startDrag()
        dragging = true
        if connection then connection:Disconnect() end

        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local mouseX = input.Position.X
                local trackPos = track.AbsolutePosition
                local trackSz = track.AbsoluteSize

                local pct = math.clamp((mouseX - trackPos.X) / trackSz.X, 0, 1)
                self.Value = getValueFromPercent(pct)
                currentPct = getPercentFromValue(self.Value)
                updateUI(false)
                
                if self.Callback then
                    task.spawn(self.Callback, self.Value, false)
                end
            end
        end)
    end

    local function stopDrag()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if dragging then
            dragging = false
            updateUI(true)
            if self.Callback then
                task.spawn(self.Callback, self.Value, true)
            end
        end
    end

    -- ホバー時に丸ノブを微拡大 (14x14 → 16x16)
    handle.MouseEnter:Connect(function()
        TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(16, 16)}):Play()
    end)
    handle.MouseLeave:Connect(function()
        if not dragging then
            TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(14, 14)}):Play()
        end
    end)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            startDrag()
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local mouseX = input.Position.X
            local trackPos = track.AbsolutePosition
            local trackSz = track.AbsoluteSize

            local pct = math.clamp((mouseX - trackPos.X) / trackSz.X, 0, 1)
            self.Value = getValueFromPercent(pct)
            currentPct = getPercentFromValue(self.Value)
            updateUI(true) -- トラッククリック時は滑らかに位置移動させるため true に変更
            startDrag()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            stopDrag()
        end
    end)

    valuebutton.MouseButton1Click:Connect(function()
        valuebutton.Visible = false
        valuebox.Visible = true
        valuebox.Text = tostring(self.Value)
        valuebox:CaptureFocus()
    end)

    -- 🌟 【アップグレード①】入力中のテキスト変更を検知して、リアルタイムにメーターとツマミを追従して動かす
    valuebox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(valuebox.Text)
        if num then
            local clamped = math.clamp(num, self.MinLimit, self.MaxLimit)
            currentPct = getPercentFromValue(clamped)
            -- プレビューとしてメーター位置を動的に更新（第3引数を false にして確定フラグはまだ送らない）
            updateUI(false)
            if self.Callback then
                task.spawn(self.Callback, clamped, false)
            end
        end
    end)

    -- 🌟 【アップグレード②】入力窓が閉じられた時（Enterキー、または別の場所をクリックして閉じた時どちらでも）に確定して保存
    valuebox.FocusLost:Connect(function(enter)
        valuebutton.Visible = true
        valuebox.Visible = false
        
        local num = tonumber(valuebox.Text)
        if num then
            self:SetValue(num, nil, true) -- 第3引数を true にして確定処理
        else
            -- 無効なテキストが入力された場合は、元の数値表示へ戻す
            updateUI(false)
        end
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    return self
end

-- ────────────── 公開メソッド（本家必須 of API） ──────────────

function Slider:SetValue(value, pos, final)
    if tonumber(value) == math.huge or value ~= value then return end

    local check = self.Value ~= value
    self.Value = math.clamp(
        math.round(value / self.Step) * self.Step,
        self.MinLimit,
        self.MaxLimit
    )

    local pct = pos or (self.Value - self.MinLimit) / (self.MaxLimit - self.MinLimit)
    currentPct = pct

    TweenService:Create(self.Handle, self.uipallet.Tween, {
        Position = UDim2.new(math.clamp(pct, 0, 1), 0, 0.5, 0)
    }):Play()
    TweenService:Create(self.Fill, self.uipallet.Tween, {
        Size = UDim2.new(math.clamp(pct, 0, 1), 0, 0, 2)
    }):Play()

    local decimals = 0
    local stepStr = tostring(self.Step)
    local dotIdx = stepStr:find("%.")
    if dotIdx then
        decimals = #stepStr - dotIdx
    end
    local formattedVal = string.format("%." .. decimals .. "f", self.Value)

    local suffixText = ""
    if self.Suffix ~= "" then
        if type(self.Suffix) == "function" then
            suffixText = " " .. self.Suffix(self.Value)
        else
            suffixText = " " .. self.Suffix
        end
    end
    self.ValueButton.Text = formattedVal .. suffixText

    if check or final then
        self.Callback(self.Value, final)
    end
end

function Slider:Save(tab)
    tab[self.Name] = {
        Value = self.Value,
        Max = self.MaxLimit
    }
end

function Slider:Load(tab)
    local newval = (tab.Value == tab.Max and tab.Max ~= self.MaxLimit) and self.MaxLimit or tab.Value
    if self.Value ~= newval then
        self:SetValue(newval, nil, true)
    end
end

function Slider:Color(hue, sat, val, rainbowcheck)
    local col
    if rainbowcheck and self.mainapi and self.mainapi.Color then
        col = Color3.fromHSV(self.mainapi:Color((hue - (self.Index * 0.075)) % 1))
    else
        col = Color3.fromHSV(hue, sat, val)
    end
    -- 🌟 色の変更時も瞬時ではなく、パレットの Tween に従い滑らかに色が補間されます
    TweenService:Create(self.Fill, self.uipallet.Tween, {BackgroundColor3 = col}):Play()
    TweenService:Create(self.Knob, self.uipallet.Tween, {BackgroundColor3 = col}):Play()
end

return Slider
end)
__bundle_register("gui.components.Toggle", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/components/Toggle.lua
local TweenService = game:GetService("TweenService")

local Toggle = {}
Toggle.__index = Toggle

local DEBUG_ENABLED = true
local function debugPrint(...)
    if DEBUG_ENABLED then print("[Toggle]", ...) end
end

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans, -- 🌟 Arial から本家の SourceSans に変更
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}
local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end

local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

local function playTween(obj, tweeninfo, goal)
    if obj and obj.Parent then
        TweenService:Create(obj, tweeninfo, goal):Play()
    else
        for i, v in pairs(goal) do obj[i] = v end
    end
end

function Toggle.new(parent, nameOrSettings, defaultValue, callback, options, api)
    local self = setmetatable({}, Toggle)

    local name = nameOrSettings
    if type(nameOrSettings) == "table" then
        local s    = nameOrSettings
        local savedApi = defaultValue  -- 🌟 3rd引数(api参照)を上書き前に保存
        name         = s.Name
        defaultValue = s.Default
        callback     = s.Function
        options      = s
        api          = savedApi        -- 正しいapi参照を復元（旧コードのバグ修正）
        debugPrint("table mode:", name)
    else
        debugPrint("param mode:", name)
    end

    local active_uipallet = (uipallet and uipallet.Main and uipallet.Tween) and uipallet or default_uipallet
    local active_color    = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween    = (tween and tween.Tween and tween.Cancel) and tween or nil
    local active_mainapi  = mainapi

    self.api      = api or active_mainapi
    self.mainapi  = active_mainapi
    self.uipallet = active_uipallet
    self.color    = active_color
    self.tween    = active_tween
    self.Name     = name
    self.Type     = "Toggle"
    self.Enabled  = false
    self.Hovered  = false
    self.Index    = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.Callback = callback or function() end

    -- options ガード
    local isDarker    = type(options) == "table" and options.Darker
    local isVisible   = not (type(options) == "table" and options.Visible == false)
    local tooltipText = type(options) == "table" and options.Tooltip

    local toggle = Instance.new("TextButton")
    toggle.Name             = name .. "Toggle"
    toggle.Size             = UDim2.new(1, 0, 0, 30)
    toggle.BorderSizePixel  = 0
    toggle.AutoButtonColor  = false
    toggle.Visible          = isVisible
toggle.Text             = name
    toggle.TextXAlignment   = Enum.TextXAlignment.Left
    toggle.TextSize         = 18  -- 🌟 13から14に大きくする（または15や16に変更）
    toggle.TextColor3       = active_color.Dark(active_uipallet.Text, 0.16)

    -- 🌟 システム的な左余白（12px）を追加して、左端にピタッと整列させる
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingLeft = UDim.new(0, 12)
    uiPadding.Parent = toggle

    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    toggle.BackgroundColor3 = isDarker and active_color.Dark(parentColor, 0.02) or parentColor

    local fontOk = pcall(function() toggle.FontFace = active_uipallet.Font end)
    if not fontOk then
        pcall(function() toggle.Font = active_uipallet.Font end)
    end

    toggle.Parent = parent

    if addTooltip and tooltipText then
        addTooltip(toggle, tooltipText)
    end

    -- スイッチトラック (22×12)
    local knobholder = Instance.new("Frame")
    knobholder.Name            = "Knob"
    knobholder.Size            = UDim2.fromOffset(22, 12)
    knobholder.Position        = UDim2.new(1, -30, 0, 9)
    knobholder.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.14)
    knobholder.Parent          = toggle

    if addCorner then
        addCorner(knobholder, UDim.new(1, 0))
    else
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = knobholder
    end

    -- ノブ (8×8)
    local knob = knobholder:Clone()
    knob.Name            = "KnobCircle"
    knob.Size            = UDim2.fromOffset(8, 8)
    knob.Position        = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = active_uipallet.Main
    knob.Parent          = knobholder

    self.Object     = toggle
    self.KnobHolder = knobholder
    self.Knob       = knob

    toggle.MouseEnter:Connect(function()
        self.Hovered = true
        if not self.Enabled then
            playTween(knobholder, self.uipallet.Tween, {
                BackgroundColor3 = self.color.Light(self.uipallet.Main, 0.37)
            })
        end
    end)

    toggle.MouseLeave:Connect(function()
        self.Hovered = false
        if not self.Enabled then
            playTween(knobholder, self.uipallet.Tween, {
                BackgroundColor3 = self.color.Light(self.uipallet.Main, 0.14)
            })
        end
    end)

    toggle.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    if defaultValue == true then
        self:Toggle()
    end

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    return self
end

function Toggle:Toggle()
    self.Enabled = not self.Enabled
    debugPrint("Toggle:", self.Name, self.Enabled)

    local mapi = self.mainapi
    local rainbow = mapi and mapi.GUIColor and mapi.RainbowMode
        and mapi.GUIColor.Rainbow and mapi.RainbowMode.Value ~= "Retro"

    local targetBg
    if self.Enabled then
        if rainbow and mapi.Color then
            targetBg = Color3.fromHSV(mapi:Color((mapi.GUIColor.Hue - self.Index * 0.075) % 1))
        elseif mapi and mapi.GUIColor then
            targetBg = Color3.fromHSV(mapi.GUIColor.Hue, mapi.GUIColor.Sat, mapi.GUIColor.Value)
        else
            targetBg = Color3.fromRGB(0, 204, 136)
        end
    else
        targetBg = self.Hovered
            and self.color.Light(self.uipallet.Main, 0.37)
            or  self.color.Light(self.uipallet.Main, 0.14)
    end

    local targetPos = self.Enabled and UDim2.fromOffset(12, 2) or UDim2.fromOffset(2, 2)

    playTween(self.KnobHolder, self.uipallet.Tween, {BackgroundColor3 = targetBg})
    playTween(self.Knob,       self.uipallet.Tween, {Position = targetPos})

    if self.Callback then task.spawn(self.Callback, self.Enabled) end
end

function Toggle:Save(tab)
    tab[self.Name] = {Enabled = self.Enabled}
end

function Toggle:Load(tab)
    if tab and self.Enabled ~= tab.Enabled then self:Toggle() end
end

function Toggle:Color(hue, sat, val, rainbowcheck)
    if not self.Enabled then return end
    local mapi = self.mainapi
    local c = (rainbowcheck and mapi and mapi.Color)
        and Color3.fromHSV(mapi:Color((hue - self.Index * 0.075) % 1))
        or  Color3.fromHSV(hue, sat, val)
    if self.tween and self.tween.Cancel then
        self.tween:Cancel(self.KnobHolder)
    end
    self.KnobHolder.BackgroundColor3 = c
end

return Toggle
end)
__bundle_register("gui.WindowFactory", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/WindowFactory.lua

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local WindowFactory = {}

-- ドラッグ機能をセットアップする関数
function WindowFactory.setupDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        frame:SetAttribute("BasePosition", targetPos)
        TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ベースとなるウィンドウを生成する関数
function WindowFactory.createBaseWindow(ScreenGui, name, size, position, iconAssetId)
    -- 外枠
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Size = size
    container.Position = position
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.Active = true
    container.ZIndex = 2
    container.Parent = ScreenGui

    container:SetAttribute("BasePosition", position)

    -- 影
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 89, 1, 52)
    shadow.Position = UDim2.fromOffset(-48, -31)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://14898786664"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(52, 31, 261, 502)
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.2
    shadow.ZIndex = 1
    shadow.Parent = container

    -- メインの枠
    local mainFrame = Instance.new("CanvasGroup")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Parent = container

    -- 🌟 【新規追加】すべてのウィンドウ背景に背景ブラー（addBlur）を安全に適用
    local addBlurFunc = addBlur or addblur or (shared.vape and shared.vape.addBlur) or (shared.vape and shared.vape.addblur)
    if addBlurFunc then
        pcall(addBlurFunc, mainFrame)
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(35, 35, 35)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = mainFrame

    -- ヘッダー
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    header.BorderSizePixel = 0
    header.ZIndex = 3
    header.Parent = mainFrame

    -- タイトルと任意アイコン
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 4
    titleLabel.Parent = header

    if iconAssetId then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(16, 16)
        icon.Position = UDim2.new(0, 15, 0.5, -8)
        icon.BackgroundTransparency = 1
        icon.Image = iconAssetId
        icon.ZIndex = 4
        icon.Parent = header

        titleLabel.Position = UDim2.new(0, 38, 0, 0)
        titleLabel.Size = UDim2.new(1, -53, 1, 0)
        titleLabel.Text = name
    else
        titleLabel.Position = UDim2.new(0, 15, 0, 0)
        titleLabel.Size = UDim2.new(1, -30, 1, 0)
        titleLabel.Text = name
    end

    return container, mainFrame, header
end

-- ウィンドウのリストフレーム内にモジュールを追加する関数
function WindowFactory.addModule(listFrame, name, desc)
    local ModuleBtn = Instance.new("TextButton")
    ModuleBtn.Name = name .. "Module"
    ModuleBtn.Size = UDim2.new(1, 0, 0, 34)
    ModuleBtn.BackgroundTransparency = 1
    ModuleBtn.Text = ""
    ModuleBtn.AutoButtonColor = false
    ModuleBtn.ZIndex = 3
    ModuleBtn.Parent = listFrame

    local HoverBg = Instance.new("Frame")
    HoverBg.Name = "HoverBg"
    HoverBg.Size = UDim2.new(1, -10, 1, 0)
    HoverBg.Position = UDim2.new(0, 5, 0, 0)
    HoverBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HoverBg.BackgroundTransparency = 1
    HoverBg.BorderSizePixel = 0
    HoverBg.ZIndex = 2
    HoverBg.Parent = ModuleBtn
    
    local HoverCorner = Instance.new("UICorner")
    HoverCorner.CornerRadius = UDim.new(0, 4)
    HoverCorner.Parent = HoverBg

    -- モジュール名
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(150, 150, 150)
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamMedium
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 3
    Label.Parent = ModuleBtn

    -- 右端の「...」設定ボタン
    local OptionBtn = Instance.new("TextButton")
    OptionBtn.Name = "OptionBtn"
    OptionBtn.Size = UDim2.new(0, 30, 0, 30)
    OptionBtn.Position = UDim2.new(1, -35, 0.5, -15)
    OptionBtn.BackgroundTransparency = 1
    OptionBtn.Text = "..."
    OptionBtn.TextColor3 = Color3.fromRGB(110, 110, 110)
    OptionBtn.TextSize = 14
    OptionBtn.Font = Enum.Font.GothamBold
    OptionBtn.ZIndex = 4
    OptionBtn.Parent = ModuleBtn

    local enabled = false

    -- 有効・無効を切り替えるトグルアニメーション
    local function toggle(state)
        enabled = state
        local targetColor = enabled and Color3.fromRGB(30, 180, 130) or Color3.fromRGB(150, 150, 150)
        TweenService:Create(Label, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = targetColor}):Play()
    end

    ModuleBtn.MouseEnter:Connect(function()
        TweenService:Create(HoverBg, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.95}):Play()
        if not enabled then
            TweenService:Create(Label, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        end
    end)

    ModuleBtn.MouseLeave:Connect(function()
        TweenService:Create(HoverBg, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        if not enabled then
            TweenService:Create(Label, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        end
    end)

    ModuleBtn.MouseButton1Click:Connect(function()
        toggle(not enabled)
    end)

    OptionBtn.MouseEnter:Connect(function()
        TweenService:Create(OptionBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end)
    OptionBtn.MouseLeave:Connect(function()
        TweenService:Create(OptionBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(110, 110, 110)}):Play()
    end)

    return ModuleBtn, OptionBtn
end

return WindowFactory
end)
__bundle_register("hud.Tutorial", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/hud/Tutorial.lua

local TweenService = game:GetService("TweenService")
local Tutorial = {}

function Tutorial.init(TutorialFrame, TutorialHeader)
    task.defer(function()
        if TutorialFrame and TutorialFrame.Parent then
            TutorialFrame.Parent.AnchorPoint = Vector2.new(1, 0.5)
            TutorialFrame.Parent.Position = UDim2.new(1, -10, 0.5, 0)
        end
    end)

    -- デフォルトヘッダーの非表示化
    if TutorialHeader then
        TutorialHeader.BackgroundTransparency = 1
        local defaultTitle = TutorialHeader:FindFirstChild("Title")
        if defaultTitle then
            defaultTitle.Visible = false
        end
    end

    -- チュートリアルアイコンの追加
    local TutorialIcon = Instance.new("ImageLabel")
    TutorialIcon.Size = UDim2.fromOffset(13, 13)
    TutorialIcon.Position = UDim2.new(0, 15, 0.5, -6)
    TutorialIcon.BackgroundTransparency = 1
    TutorialIcon.Image = "rbxassetid://10734950309" -- Lucide HelpCircle
    TutorialIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    TutorialIcon.ScaleType = Enum.ScaleType.Fit
    TutorialIcon.ZIndex = 5
    TutorialIcon.Parent = TutorialHeader

    local TutorialTitle = Instance.new("TextLabel")
    TutorialTitle.Size = UDim2.new(1, -85, 1, 0)
    TutorialTitle.Position = UDim2.new(0, 35, 0, 0)
    TutorialTitle.BackgroundTransparency = 1
    TutorialTitle.Text = "Tutorial"
    TutorialTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    TutorialTitle.TextSize = 14
    TutorialTitle.Font = Enum.Font.SourceSansBold
    TutorialTitle.TextXAlignment = Enum.TextXAlignment.Left
    TutorialTitle.ZIndex = 5
    TutorialTitle.Parent = TutorialHeader

    local TutorialBody = Instance.new("Frame")
    TutorialBody.Size = UDim2.new(1, 0, 1, -38)
    TutorialBody.Position = UDim2.new(0, 0, 0, 38)
    TutorialBody.BackgroundTransparency = 1
    TutorialBody.ZIndex = 4
    TutorialBody.Parent = TutorialFrame

    local tPadding = Instance.new("UIPadding")
    tPadding.PaddingLeft, tPadding.PaddingRight, tPadding.PaddingTop = UDim.new(0, 15), UDim.new(0, 15), UDim.new(0, 10)
    tPadding.Parent = TutorialBody

    local tLayout = Instance.new("UIListLayout")
    tLayout.FillDirection, tLayout.SortOrder, tLayout.Padding = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, UDim.new(0, 10)
    tLayout.Parent = TutorialBody

    local function createTutorialStep(parent, icon, text, order)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order
        row.ZIndex = 5
        row.Parent = parent

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromOffset(16, 16)
        img.Position = UDim2.new(0, 5, 0.5, -8)
        img.BackgroundTransparency = 1
        img.Image = icon
        img.ImageColor3 = Color3.fromRGB(180, 180, 180)
        img.ScaleType = Enum.ScaleType.Fit
        img.ZIndex = 6
        img.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -32, 1, 0)
        lbl.Position = UDim2.new(0, 32, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.SourceSans
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.ZIndex = 6
        lbl.Parent = row
    end

    createTutorialStep(TutorialBody, "rbxassetid://10734900011", "Drag anywhere on any window to move it around.", 1)
    createTutorialStep(TutorialBody, "rbxassetid://10734950309", "Click the Settings gear (top right) to toggle Session Info.", 2)
    createTutorialStep(TutorialBody, "rbxassetid://10709811365", "Press the [RightControl] key to hide or show all windows.", 3)

    local GotItBtn = Instance.new("TextButton")
    GotItBtn.Size = UDim2.new(1, 0, 0, 26)
    GotItBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    GotItBtn.BorderSizePixel = 0
    GotItBtn.Text = "Got It"
    GotItBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    GotItBtn.TextSize = 13
    GotItBtn.Font = Enum.Font.SourceSansBold
    GotItBtn.LayoutOrder = 4
    GotItBtn.ZIndex = 5
    GotItBtn.Parent = TutorialBody

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = GotItBtn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(50, 50, 50)
    btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    btnStroke.Parent = GotItBtn

    GotItBtn.MouseEnter:Connect(function()
        TweenService:Create(GotItBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    GotItBtn.MouseLeave:Connect(function()
        TweenService:Create(GotItBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
    end)
    
    GotItBtn.MouseButton1Click:Connect(function()
        local anim = TweenService:Create(TutorialFrame.Parent, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, -300, TutorialFrame.Parent.Position.Y.Scale, TutorialFrame.Parent.Position.Y.Offset)})
        anim:Play()
        anim.Completed:Once(function()
            TutorialFrame.Parent:Destroy()
        end)
    end)
end

return Tutorial
end)
__bundle_register("hud.SettingsInfo", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/hud/SettingsInfo.lua
local TweenService = game:GetService("TweenService")

-- Toggleコンポーネントをインポート
local Toggle = require("gui.components.Toggle")

local SettingsInfo = {}

function SettingsInfo.init(SettingsFrame)
    -- 🌟 設定ウィンドウの位置調整（画面左下の Session Info の右隣にきれいに並ぶよう設定）
    task.defer(function()
        if SettingsFrame and SettingsFrame.Parent then
            SettingsFrame.Parent.AnchorPoint = Vector2.new(0, 1) -- 基準点を左下に
            SettingsFrame.Parent.Position = UDim2.new(0, 240, 1, -10) -- X=240 (Session Infoのすぐ横)、Y=下から10px
        end
    end)

    -- デフォルトヘッダーの非表示化
    local defaultHeader = SettingsFrame:FindFirstChild("Header")
    if defaultHeader then
        defaultHeader.BackgroundTransparency = 1
        local defaultTitle = defaultHeader:FindFirstChild("Title")
        if defaultTitle then
            defaultTitle.Visible = false
        end
    end

    local SettingsContent = Instance.new("Frame")
    SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.BorderSizePixel = 0
    SettingsContent.ZIndex = 4
    SettingsContent.Parent = SettingsFrame

    local SettingsHeaderPlaceholder = Instance.new("Frame")
    SettingsHeaderPlaceholder.Size = UDim2.new(1, 0, 0, 38)
    SettingsHeaderPlaceholder.BackgroundTransparency = 1
    SettingsHeaderPlaceholder.ZIndex = 4
    SettingsHeaderPlaceholder.Parent = SettingsContent

    local SettingsIcon = Instance.new("ImageLabel")
    SettingsIcon.Size = UDim2.fromOffset(18, 18)
    SettingsIcon.Position = UDim2.new(0, 15, 0.5, -9)
    SettingsIcon.BackgroundTransparency = 1
    SettingsIcon.Image = "rbxassetid://10734950309" -- Lucide settings ⚙️
    SettingsIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    SettingsIcon.ScaleType = Enum.ScaleType.Fit
    SettingsIcon.ZIndex = 5
    SettingsIcon.Parent = SettingsHeaderPlaceholder

    local SettingsTitle = Instance.new("TextLabel")
    SettingsTitle.Size = UDim2.new(1, -85, 1, 0)
    SettingsTitle.Position = UDim2.new(0, 40, 0, 0)
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Text = "GUI Settings"
    SettingsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    SettingsTitle.TextSize = 14
    SettingsTitle.Font = Enum.Font.SourceSansBold
    SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    SettingsTitle.ZIndex = 5
    SettingsTitle.Parent = SettingsHeaderPlaceholder

    local PinBtn = Instance.new("ImageButton")
    PinBtn.Size = UDim2.fromOffset(13, 13)
    PinBtn.Position = UDim2.new(1, -35, 0.5, 0)
    PinBtn.AnchorPoint = Vector2.new(1, 0.5)
    PinBtn.BackgroundTransparency = 1
    PinBtn.Image = "rbxassetid://14368342301"
    PinBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    PinBtn.ZIndex = 5
    PinBtn.Parent = SettingsHeaderPlaceholder

    local DotsBtn = Instance.new("ImageButton")
    DotsBtn.Size = UDim2.fromOffset(3, 13)
    DotsBtn.Position = UDim2.new(1, -15, 0.5, 0)
    DotsBtn.AnchorPoint = Vector2.new(1, 0.5)
    DotsBtn.BackgroundTransparency = 1
    DotsBtn.Image = "rbxassetid://14368314459"
    DotsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    DotsBtn.ZIndex = 5
    DotsBtn.Parent = SettingsHeaderPlaceholder

    local SettingsDivider = Instance.new("Frame")
    SettingsDivider.Size = UDim2.new(1, 0, 0, 1)
    SettingsDivider.Position = UDim2.new(0, 0, 0, 37)
    SettingsDivider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SettingsDivider.BorderSizePixel = 0
    SettingsDivider.ZIndex = 4
    SettingsDivider.Parent = SettingsContent

    local SettingsBody = Instance.new("Frame")
    SettingsBody.Size = UDim2.new(1, 0, 1, -38)
    SettingsBody.Position = UDim2.new(0, 0, 0, 38)
    SettingsBody.BackgroundTransparency = 1
    SettingsBody.ZIndex = 4
    SettingsBody.Parent = SettingsContent

    local BodyPadding = Instance.new("UIPadding")
    BodyPadding.PaddingLeft = UDim.new(0, 15)
    BodyPadding.PaddingRight = UDim.new(0, 15)
    BodyPadding.PaddingTop = UDim.new(0, 10)
    BodyPadding.Parent = SettingsBody

    local BodyLayout = Instance.new("UIListLayout")
    BodyLayout.FillDirection = Enum.FillDirection.Vertical
    BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BodyLayout.Padding = UDim.new(0, 4)
    BodyLayout.Parent = SettingsBody

    local function createToggle(text, enabled, layoutOrder, iconAssetId, callback)
        local toggleInst = Toggle.new(SettingsBody, text, enabled, callback)

        if toggleInst and toggleInst.Object then
            toggleInst.Object.LayoutOrder = layoutOrder
            toggleInst.Object.ZIndex = 5
            toggleInst.Object.BackgroundTransparency = 1

            if iconAssetId then
                toggleInst.Object.Text = "      " .. text

                local toggleIcon = Instance.new("ImageLabel")
                toggleIcon.Name = "ToggleIcon"
                toggleIcon.Size = UDim2.fromOffset(13, 13)
                toggleIcon.Position = UDim2.new(0, 0, 0.5, -6)
                toggleIcon.BackgroundTransparency = 1
                toggleIcon.Image = iconAssetId
                toggleIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
                toggleIcon.ScaleType = Enum.ScaleType.Fit
                toggleIcon.ZIndex = 6
                toggleIcon.Parent = toggleInst.Object
            else
                toggleInst.Object.Text = text
            end

            toggleInst.Object.Size = UDim2.new(1, 0, 0, 24)

            if toggleInst.KnobHolder then
                toggleInst.KnobHolder.Position = UDim2.new(1, -30, 0, 6)
            end
        end

        return toggleInst
    end

    -- ==========================================
    -- 🌟 共有設定テーブルの値と連動したトグル作成
    -- ==========================================
    
    createToggle("Blur Background", shared.VapeSettings.BlurBackground, 1, "rbxassetid://7733774602", function(state)
        shared.VapeSettings.BlurBackground = state
        shared.VapeSettingsChanged:Fire("BlurBackground", state)
    end)

    createToggle("Show Tooltips", shared.VapeSettings.ShowTooltips, 2, "rbxassetid://7733964719", function(state)
        shared.VapeSettings.ShowTooltips = state
        shared.VapeSettingsChanged:Fire("ShowTooltips", state)
    end)

    createToggle("GUI Bind Indicator", shared.VapeSettings.GPUBindIndicator, 3, "rbxassetid://7733965118", function(state)
        shared.VapeSettings.GPUBindIndicator = state
        shared.VapeSettingsChanged:Fire("GPUBindIndicator", state)
    end)

    createToggle("Show Legit Mode", shared.VapeSettings.ShowLegitMode, 4, "rbxassetid://7734056608", function(state)
        shared.VapeSettings.ShowLegitMode = state
        shared.VapeSettingsChanged:Fire("ShowLegitMode", state)
    end)

    DotsBtn.MouseButton1Click:Connect(function()
        SettingsFrame.Parent.Visible = false
    end)
end

return SettingsInfo
end)
__bundle_register("hud.SessionInfo", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/hud/SessionInfo.lua

local SessionInfo = {}

function SessionInfo.init(SessionFrame)
    task.defer(function()
        if SessionFrame and SessionFrame.Parent then
            SessionFrame.Parent.AnchorPoint = Vector2.new(0, 1)
            SessionFrame.Parent.Position = UDim2.new(0, 10, 1, -10)
            
            -- 🌟 各行をコンパクトにしたため、ウィンドウ全体の高さも 130px -> 108px に微調整
            local currentSize = SessionFrame.Parent.Size
            SessionFrame.Parent.Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 0, 108)
        end
    end)

    -- デフォルトヘッダーの非表示化
    local defaultHeader = SessionFrame:FindFirstChild("Header")
    if defaultHeader then
        defaultHeader.BackgroundTransparency = 1
        local defaultTitle = defaultHeader:FindFirstChild("Title")
        if defaultTitle then
            defaultTitle.Visible = false
        end
    end

    local SessionContent = Instance.new("Frame")
    SessionContent.Size = UDim2.new(1, 0, 1, 0)
    SessionContent.BackgroundTransparency = 1
    SessionContent.BorderSizePixel = 0
    SessionContent.ZIndex = 4
    SessionContent.Parent = SessionFrame

    local SessionHeaderPlaceholder = Instance.new("Frame")
    SessionHeaderPlaceholder.Size = UDim2.new(1, 0, 0, 38)
    SessionHeaderPlaceholder.BackgroundTransparency = 1
    SessionHeaderPlaceholder.ZIndex = 4
    SessionHeaderPlaceholder.Parent = SessionContent

    -- ヘッダーアイコン (18x18サイズ、上下中央)
    local SessionIcon = Instance.new("ImageLabel")
    SessionIcon.Size = UDim2.fromOffset(18, 18)
    SessionIcon.Position = UDim2.new(0, 15, 0.5, -9)
    SessionIcon.BackgroundTransparency = 1
    SessionIcon.Image = "rbxassetid://14397380433" -- 統計アイコン 📊
    SessionIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    SessionIcon.ScaleType = Enum.ScaleType.Fit
    SessionIcon.ZIndex = 5
    SessionIcon.Parent = SessionHeaderPlaceholder

    -- ヘッダータイトル
    local SessionTitle = Instance.new("TextLabel")
    SessionTitle.Size = UDim2.new(1, -85, 1, 0)
    SessionTitle.Position = UDim2.new(0, 40, 0, 0)
    SessionTitle.BackgroundTransparency = 1
    SessionTitle.Text = "Session Info"
    SessionTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    SessionTitle.TextSize = 14
    SessionTitle.Font = Enum.Font.SourceSansBold
    SessionTitle.TextXAlignment = Enum.TextXAlignment.Left
    SessionTitle.ZIndex = 5
    SessionTitle.Parent = SessionHeaderPlaceholder

    local PinBtn = Instance.new("ImageButton")
    PinBtn.Size = UDim2.fromOffset(13, 13)
    PinBtn.Position = UDim2.new(1, -35, 0.5, 0)
    PinBtn.AnchorPoint = Vector2.new(1, 0.5)
    PinBtn.BackgroundTransparency = 1
    PinBtn.Image = "rbxassetid://14368342301"
    PinBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    PinBtn.ZIndex = 5
    PinBtn.Parent = SessionHeaderPlaceholder

    local DotsBtn = Instance.new("ImageButton")
    DotsBtn.Size = UDim2.fromOffset(3, 13)
    DotsBtn.Position = UDim2.new(1, -15, 0.5, 0)
    DotsBtn.AnchorPoint = Vector2.new(1, 0.5)
    DotsBtn.BackgroundTransparency = 1
    DotsBtn.Image = "rbxassetid://14368314459"
    DotsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    DotsBtn.ZIndex = 5
    DotsBtn.Parent = SessionHeaderPlaceholder

    local SessionDivider = Instance.new("Frame")
    SessionDivider.Size = UDim2.new(1, 0, 0, 1)
    SessionDivider.Position = UDim2.new(0, 0, 0, 37)
    SessionDivider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SessionDivider.BorderSizePixel = 0
    SessionDivider.ZIndex = 4
    SessionDivider.Parent = SessionContent

    local SessionBody = Instance.new("Frame")
    SessionBody.Size = UDim2.new(1, 0, 1, -38)
    SessionBody.Position = UDim2.new(0, 0, 0, 38)
    SessionBody.BackgroundTransparency = 1
    SessionBody.ZIndex = 4
    SessionBody.Parent = SessionContent

    local BodyPadding = Instance.new("UIPadding")
    BodyPadding.PaddingLeft, BodyPadding.PaddingRight, BodyPadding.PaddingTop = UDim.new(0, 15), UDim.new(0, 15), UDim.new(0, 10)
    BodyPadding.Parent = SessionBody

    local BodyLayout = Instance.new("UIListLayout")
    BodyLayout.FillDirection, BodyLayout.SortOrder, BodyLayout.Padding = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, UDim.new(0, 2) -- 🌟 行同士のパディングを 2px に変更
    BodyLayout.Parent = SessionBody

    -- 重なりを防ぐ statsLabel 構築関数（コンパクトサイズ版）
    local function createStatsLabel(text, layoutOrder, iconAssetId)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 16) -- 🌟 各行の高さを 24px から 16px に圧縮
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.LayoutOrder = layoutOrder
        Row.ZIndex = 5
        Row.Parent = SessionBody

        if iconAssetId then
            local LabelIcon = Instance.new("ImageLabel")
            LabelIcon.Name = "LabelIcon"
            LabelIcon.Size = UDim2.fromOffset(13, 13)
            LabelIcon.Position = UDim2.new(0, 0, 0.5, -6) -- 16pxの高さでもきれいに中央揃え
            LabelIcon.BackgroundTransparency = 1
            LabelIcon.Image = iconAssetId
            LabelIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
            LabelIcon.ScaleType = Enum.ScaleType.Fit
            LabelIcon.ZIndex = 6
            LabelIcon.Parent = Row
        end

        local Label = Instance.new("TextLabel")
        local textOffset = iconAssetId and 20 or 0
        Label.Size = UDim2.new(1, -textOffset, 1, 0)
        Label.Position = UDim2.new(0, textOffset, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(150, 150, 150)
        Label.TextSize = 14
        Label.Font = Enum.Font.SourceSans
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.ZIndex = 5
        Label.Parent = Row

        return Label
    end

    -- 統計項目の構築
    local elapsedTimer = createStatsLabel("Time Elapsed: 0h 0m 0s", 1, "rbxassetid://7733734848") -- clock 🕒
    createStatsLabel("Kills: 0", 2, "rbxassetid://7734058599")                                  -- skull 💀
    createStatsLabel("Wins: 0", 3, "rbxassetid://7733765398")                                   -- crown 👑

    local startTime = os.time()
    task.spawn(function()
        while task.wait(1) do
            if not SessionFrame.Parent then break end
            local elapsed = os.time() - startTime
            elapsedTimer.Text = string.format("Time Elapsed: %dh %dm %ds", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), elapsed % 60)
        end
    end)

    DotsBtn.MouseButton1Click:Connect(function()
        SessionFrame.Parent.Visible = false
    end)
end

return SessionInfo
end)
__bundle_register("gui.LoadingScreen", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/LoadingScreen.lua
local TweenService = game:GetService("TweenService")
local LoadingScreen = {}

function LoadingScreen.show(parentScreenGui, assets, onComplete)
    -- 🌟 本物同様に起動した瞬間から背景を美しくボケさせます
    local blur = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
    if blur then
        blur.Enabled = true
    end

    -- 🌟 背景を完全な黒ではなく、ゲーム画面が少し透ける「透過ダークグレー」に変更
    local LoadingContainer = Instance.new("CanvasGroup")
    LoadingContainer.Name = "VapeLoadingScreen"
    LoadingContainer.Size = UDim2.new(1, 0, 1, 0)
    LoadingContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10) 
    LoadingContainer.BackgroundTransparency = 0.15 -- 🌟 ほぼ真っ暗（15%だけ透明、85%黒い）
    LoadingContainer.BorderSizePixel = 0
    LoadingContainer.ZIndex = 10000 -- 常に全ウィンドウの最前面
    LoadingContainer.Parent = parentScreenGui

    -- 中央のコンテンツ配置枠
    local CenterFrame = Instance.new("Frame")
    CenterFrame.Size = UDim2.new(0, 320, 0, 120)
    CenterFrame.Position = UDim2.new(0.5, -160, 0.5, -60)
    CenterFrame.BackgroundTransparency = 1
    CenterFrame.Parent = LoadingContainer

    -- ==========================================
    -- 🌟 ロゴ画像を表示するためのコンテナ
    -- ==========================================
    local LogoContainer = Instance.new("Frame")
    LogoContainer.Name = "LogoContainer"
    LogoContainer.Size = UDim2.new(1, 0, 0, 30)
    LogoContainer.Position = UDim2.new(0, 0, 0, 0)
    LogoContainer.BackgroundTransparency = 1
    LogoContainer.Parent = CenterFrame

    local LogoLayout = Instance.new("UIListLayout")
    LogoLayout.FillDirection = Enum.FillDirection.Horizontal
    LogoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LogoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    -- 🌟 【修正】ロゴとV4バッジの間の隙間を「6」から「0」に縮小して左に寄せます。
    -- もしこれでも離れて見える場合は UDim.new(0, -3) などのマイナス値に調整してみてください。
    LogoLayout.Padding = UDim.new(0, 0) 
    LogoLayout.Parent = LogoContainer

    -- 🌟 【修正】APE用にアスペクト比を計算し、横幅を「90」から「76」に拡大・調整しました
    local VapeLogoImg = Instance.new("ImageLabel")
    VapeLogoImg.Name = "ApeLogoImg"
    VapeLogoImg.Size = UDim2.new(0, 76, 0, 28) 
    VapeLogoImg.BackgroundTransparency = 1
    VapeLogoImg.ImageTransparency = 1
    VapeLogoImg.ScaleType = Enum.ScaleType.Fit
    VapeLogoImg.Parent = LogoContainer

    -- V4 Badge Logo (ちょうど良い中間の 28px 高さ / 初期状態は透明)
    local V4LogoImg = Instance.new("ImageLabel")
    V4LogoImg.Size = UDim2.new(0, 44, 0, 28) 
    V4LogoImg.BackgroundTransparency = 1
    V4LogoImg.ImageTransparency = 1
    V4LogoImg.ScaleType = Enum.ScaleType.Fit
    V4LogoImg.Parent = LogoContainer

    -- 進捗ステータス表記（フォントサイズをやや小さくし、本家の控えめな雰囲気に）
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 0, 52)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Connecting..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100) -- やや暗めのグレー
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.SourceSansSemibold
    StatusLabel.Parent = CenterFrame

    -- プログレスバー背景（本家Vapeに合わせ、太さを2pxに極細化してスタイリッシュに）
    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, 0, 0, 2) -- 🌟 2pxに極細化
    BarBg.Position = UDim2.new(0, 0, 0, 85)
    BarBg.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    BarBg.BorderSizePixel = 0
    BarBg.Parent = CenterFrame

    local BarBgCorner = Instance.new("UICorner")
    BarBgCorner.CornerRadius = UDim.new(0, 1)
    BarBgCorner.Parent = BarBg

    -- プログレスバー進行
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(45, 186, 120) -- 🌟 本家Vapeの鮮やかな黄緑色（ミントグリーン）
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBg

    local BarFillCorner = Instance.new("UICorner")
    BarFillCorner.CornerRadius = UDim.new(0, 1)
    BarFillCorner.Parent = BarFill

    -- 実際のアセットのダウンロード進捗イベントを監視
    local connection
    local logoLoaded = false -- ロゴのフェードインが完了したか追跡するフラグ

    connection = assets.OnProgress:Connect(function(progress, text)
        StatusLabel.Text = text
        
        -- ダウンロード進捗に合わせてバーをなめらかに伸長
        TweenService:Create(BarFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()

        -- 🌟 ロゴアセットのダウンロードが完了した瞬間、画像をセットしてフェードイン
        if not logoLoaded and assets.vapeLogo and assets.v4Logo then
            logoLoaded = true
            VapeLogoImg.Image = assets.vapeLogo
            V4LogoImg.Image = assets.v4Logo
            
            -- 不透明度を 1 から 0 へ（ふわっと出現）
            TweenService:Create(VapeLogoImg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
            TweenService:Create(V4LogoImg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
        end

        -- 100%読み込みが完了した時の処理
        if progress >= 1.0 then
            if connection then
                connection:Disconnect()
                connection = nil
            end

            task.wait(0.2) -- 完了状態を見せるための僅かな余韻

            -- 画面全体を滑らかにフェードアウト
            local fadeTween = TweenService:Create(LoadingContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                GroupTransparency = 1
            })
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                LoadingContainer:Destroy()
                if onComplete then
                    onComplete() -- ロード完了をMain.luaに通知
                end
            end)
        end
    end)

    -- 非同期で実際のアセットのダウンロードロード処理を開始
    task.spawn(function()
        assets.loadAll()
    end)
end

return LoadingScreen
end)
__bundle_register("gui.Sidebar", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/Sidebar.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Sidebar = {}

function Sidebar.init(MainFrame, assets, VapeTooltip, tLabel)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ZIndex = 4
    ContentFrame.Parent = MainFrame

    local TabScrollingFrame = Instance.new("ScrollingFrame")
    TabScrollingFrame.Name = "TabScrollingFrame"
    TabScrollingFrame.Position = UDim2.new(0, 0, 0, 38)
    TabScrollingFrame.Size = UDim2.new(1, 0, 1, -76)
    TabScrollingFrame.BackgroundTransparency = 1
    TabScrollingFrame.BorderSizePixel = 0
    TabScrollingFrame.ZIndex = 4
    TabScrollingFrame.ScrollBarThickness = 0
    TabScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    TabScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScrollingFrame.Parent = ContentFrame

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.Parent = TabScrollingFrame

    local tabs = {}

    -- 共通のツールチップ表示関数
    local function bindTooltip(uiObject, desc)
        local hoverActive = false
        local hoverThread = nil

        uiObject.MouseEnter:Connect(function()
            -- 🌟 設定がOFFの場合はツールチップを一切表示しない
            if shared.VapeSettings and not shared.VapeSettings.ShowTooltips then
                return
            end

            hoverActive = true
            hoverThread = task.delay(1, function()
                if hoverActive and desc then
                    tLabel.Font = Enum.Font.SourceSansSemibold
                    tLabel.TextSize = 13
                    tLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                    tLabel.TextWrapped = true
                    tLabel.TextXAlignment = Enum.TextXAlignment.Left
                    tLabel.TextYAlignment = Enum.TextYAlignment.Center
                    tLabel.Text = desc

                    local maxWidth = 200
                    local textBounds = TextService:GetTextSize(
                        desc,
                        tLabel.TextSize,
                        tLabel.Font,
                        Vector2.new(maxWidth, math.huge)
                    )

                    local paddingX = 16
                    local paddingY = 12

                    tLabel.Position = UDim2.fromOffset(paddingX / 2, paddingY / 2)
                    tLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)

                    VapeTooltip.Size = UDim2.fromOffset(textBounds.X + paddingX, textBounds.Y + paddingY)
                    VapeTooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    VapeTooltip.BackgroundTransparency = 0.15
                    VapeTooltip.BorderSizePixel = 0

                    local vtCorner = VapeTooltip:FindFirstChildOfClass("UICorner")
                    if not vtCorner then
                        vtCorner = Instance.new("UICorner")
                        vtCorner.CornerRadius = UDim.new(0, 4)
                        vtCorner.Parent = VapeTooltip
                    end

                    local vtStroke = VapeTooltip:FindFirstChildOfClass("UIStroke")
                    if not vtStroke then
                        vtStroke = Instance.new("UIStroke")
                        vtStroke.Thickness = 1
                        vtStroke.Color = Color3.fromRGB(35, 35, 35)
                        vtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        vtStroke.Parent = VapeTooltip
                    end

                    VapeTooltip.Position = UDim2.fromOffset(UserInputService:GetMouseLocation().X + 15, UserInputService:GetMouseLocation().Y - 5)
                    VapeTooltip.Visible = true
                end
            end)
        end)

        uiObject.MouseLeave:Connect(function()
            hoverActive = false
            if hoverThread then
                task.cancel(hoverThread)
                hoverThread = nil
            end
            VapeTooltip.Visible = false
        end)
    end

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 0)
    ListLayout.Parent = TabScrollingFrame

    -- ヘッダープレースホルダー
    local HeaderPlaceholder = Instance.new("Frame")
    HeaderPlaceholder.Name = "HeaderPlaceholder"
    HeaderPlaceholder.Size = UDim2.new(1, 0, 0, 38)
    HeaderPlaceholder.BackgroundTransparency = 1
    HeaderPlaceholder.ZIndex = 4
    HeaderPlaceholder.Parent = ContentFrame

    local LogoContainer = Instance.new("Frame")
    LogoContainer.Name = "LogoContainer"
    LogoContainer.Size = UDim2.new(1, -50, 1, 0)
    LogoContainer.Position = UDim2.new(0, 15, 0, 0)
    LogoContainer.BackgroundTransparency = 1
    LogoContainer.ZIndex = 5
    LogoContainer.Parent = HeaderPlaceholder

local LogoLayout = Instance.new("UIListLayout")
    LogoLayout.FillDirection = Enum.FillDirection.Horizontal
    LogoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    LogoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    -- 🌟 隙間（Padding）を 3 から 0 に変更します。
    -- もしこれでもまだ離れている場合は、UDim.new(0, -2) や UDim.new(0, -4) などのマイナス値に調整してみてください。
    LogoLayout.Padding = UDim.new(0, 0)
    LogoLayout.Parent = LogoContainer

local VapeLogo = Instance.new("ImageLabel")
    VapeLogo.Name = "ApeLogo"
    VapeLogo.LayoutOrder = 1
    VapeLogo.BackgroundTransparency = 1
    -- 🌟 文字が小さくならないよう、横幅を 54、縦幅を 20 に拡大調整しました
    -- もしこれでも小さい、または大きすぎる場合は、ここの数値を調整してみてください
    VapeLogo.Size = UDim2.new(0, 58, 0, 22) 
    VapeLogo.ScaleType = Enum.ScaleType.Fit
    VapeLogo.ZIndex = 6
    if assets and assets.vapeLogo and assets.vapeLogo ~= "" then
        VapeLogo.Image = assets.vapeLogo
    else
        local TempText = Instance.new("TextLabel")
        TempText.Size = UDim2.new(1, 0, 1, 0)
        TempText.BackgroundTransparency = 1
        TempText.Text = "APE"
        TempText.TextColor3 = Color3.fromRGB(255, 255, 255)
        TempText.Font = Enum.Font.SourceSansBold
        TempText.TextSize = 18 -- 🌟 プレースホルダー文字も少し大きく
        TempText.Parent = VapeLogo
    end
    VapeLogo.Parent = LogoContainer

    local V4Logo = Instance.new("ImageLabel")
    V4Logo.Name = "V4Logo"
    V4Logo.LayoutOrder = 2
    V4Logo.BackgroundTransparency = 1
    V4Logo.Size = UDim2.new(0, 28, 0, 18)
    V4Logo.ScaleType = Enum.ScaleType.Fit
    V4Logo.ZIndex = 6
    if assets and assets.v4Logo then
        V4Logo.Image = assets.v4Logo
    else
        local TempText = Instance.new("TextLabel")
        TempText.Size = UDim2.new(1, 0, 1, 0)
        TempText.BackgroundTransparency = 1
        TempText.Text = "V4"
        TempText.TextColor3 = Color3.fromRGB(30, 180, 130)
        TempText.Font = Enum.Font.SourceSansBold
        TempText.TextSize = 10
        TempText.Parent = V4Logo
    end
    V4Logo.Parent = LogoContainer

    local SettingsBtn = Instance.new("ImageButton")
    SettingsBtn.Name = "SettingsBtn"
    SettingsBtn.Size = UDim2.new(0, 16, 0, 16)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    SettingsBtn.Position = UDim2.new(1, -15, 0.5, 0)
    SettingsBtn.ZIndex = 5
    if assets and assets.guiSettings then
        SettingsBtn.Image = assets.guiSettings
        SettingsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    else
        SettingsBtn.Image = "rbxassetid://10734950309"
        SettingsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    end
    SettingsBtn.Parent = HeaderPlaceholder

    SettingsBtn.MouseEnter:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(180, 180, 180), Rotation = 45}):Play()
    end)
    SettingsBtn.MouseLeave:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(110, 110, 110), Rotation = 0}):Play()
    end)

    bindTooltip(SettingsBtn, "Configure GUI settings, keybinds, and window options.")

    local function createTab(name, iconAssetId, fallbackAssetId, layoutOrder, hasBadge, desc)
        local Tab = Instance.new("TextButton")
        Tab.Name = name .. "Tab"
        Tab.Size = UDim2.new(1, 0, 0, 38)
        Tab.BackgroundTransparency = 1
        Tab.Text = ""
        Tab.AutoButtonColor = false
        Tab.LayoutOrder = layoutOrder
        Tab.ZIndex = 4
        Tab.Parent = TabScrollingFrame

        local TabHoverBg = Instance.new("Frame")
        TabHoverBg.Name = "TabHoverBg"
        TabHoverBg.Size = UDim2.new(1, 0, 1, 0)
        TabHoverBg.Position = UDim2.new(0, 0, 0, 0)
        TabHoverBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabHoverBg.BackgroundTransparency = 1
        TabHoverBg.BorderSizePixel = 0
        TabHoverBg.ZIndex = 2
        TabHoverBg.Parent = Tab

        local HoverCorner = Instance.new("UICorner")
        HoverCorner.CornerRadius = UDim.new(0, 5)
        HoverCorner.Parent = TabHoverBg

        local iconSizeX = 15
        local iconSizeY = 15
        if name == "Minigames" then
            iconSizeX, iconSizeY = 19, 19
        end

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "TabIcon"
        TabIcon.Size = UDim2.new(0, iconSizeX, 0, iconSizeY)
        TabIcon.Position = UDim2.new(0, 15 - (iconSizeX - 15) / 2, 0.5, -iconSizeY / 2)
        TabIcon.BackgroundTransparency = 1
        TabIcon.ScaleType = Enum.ScaleType.Fit
        TabIcon.ZIndex = 5
        if iconAssetId then
            TabIcon.Image = iconAssetId
        else
            TabIcon.Image = fallbackAssetId or ""
        end
        TabIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
        TabIcon.Parent = Tab

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "TabLabel"
        TabLabel.Size = UDim2.new(1, -60, 1, 0)
        TabLabel.Position = UDim2.new(0, 40, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = name
        TabLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        TabLabel.TextSize = 15
        TabLabel.Font = Enum.Font.SourceSansSemibold
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.ZIndex = 5
        TabLabel.Parent = Tab

        local Arrow = Instance.new("ImageLabel")
        Arrow.Name = "Arrow"
        Arrow.Size = UDim2.fromOffset(12, 12)
        Arrow.BackgroundTransparency = 1
        -- 🌟 【重要修正】assets.arrow が nil の場合でも、キャストエラーにならず標準の矢印が表示されるようにフォールバックを追加
        Arrow.Image = (assets and assets.arrow) or "rbxassetid://10709791437"
        Arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
        Arrow.ScaleType = Enum.ScaleType.Fit
        Arrow.AnchorPoint = Vector2.new(1, 0.5)
        Arrow.Position = UDim2.new(1, -15, 0.5, 0)
        Arrow.ZIndex = 5
        Arrow.Parent = Tab

        if hasBadge then
            local Badge = Instance.new("TextLabel")
            Badge.Name = "Badge"
            Badge.Size = UDim2.new(0, 50, 0, 16)
            Badge.AnchorPoint = Vector2.new(1, 0.5)
            Badge.Position = UDim2.new(1, -35, 0.5, 0)
            Badge.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
            Badge.BorderSizePixel = 0
            Badge.Text = hasBadge
            Badge.TextColor3 = Color3.fromRGB(110, 110, 110)
            Badge.TextSize = 11
            Badge.Font = Enum.Font.SourceSans
            Badge.ZIndex = 5
            Badge.Parent = Tab

            local BadgeCorner = Instance.new("UICorner")
            BadgeCorner.CornerRadius = UDim.new(0, 3)
            BadgeCorner.Parent = Badge
        end

        local hoverTime = 0.15
        local easingStyle = Enum.EasingStyle.Quart
        local easingDirection = Enum.EasingDirection.Out

        Tab.MouseEnter:Connect(function()
            TweenService:Create(TabHoverBg, TweenInfo.new(hoverTime, easingStyle, easingDirection), {BackgroundTransparency = 0.94}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(220, 220, 220), Position = UDim2.new(0, 17 - (iconSizeX - 15) / 2, 0.5, -iconSizeY / 2)}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(hoverTime, easingStyle, easingDirection), {TextColor3 = Color3.fromRGB(220, 220, 220), Position = UDim2.new(0, 42, 0, 0)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(240, 240, 240)}):Play()
        end)

        Tab.MouseLeave:Connect(function()
            TweenService:Create(TabHoverBg, TweenInfo.new(hoverTime, easingStyle, easingDirection), {BackgroundTransparency = 1}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(150, 150, 150), Position = UDim2.new(0, 15 - (iconSizeX - 15) / 2, 0.5, -iconSizeY / 2)}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(hoverTime, easingStyle, easingDirection), {TextColor3 = Color3.fromRGB(150, 150, 150), Position = UDim2.new(0, 40, 0, 0)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(140, 140, 140)}):Play()
        end)

        bindTooltip(Tab, desc)

        tabs[name] = Tab
    end

    createTab("Combat", assets.combat, "rbxassetid://10723414920", 2, nil, "Combat modules for player vs player fights.")
    createTab("Blatant", assets.blatant, "rbxassetid://10723414920", 3, nil, "Blatant hacks that are easily detectable but powerful.")
    createTab("Render", assets.render, "rbxassetid://10709765275", 4, nil, "Visual modifications like ESP, Chams, and Tracers.")
    createTab("Utility", assets.utility, "rbxassetid://10747385202", 5, nil, "Useful utilities and automation scripts.")
    createTab("World", assets.world, "rbxassetid://10723351909", 6, nil, "World-related helpers and environment tweaks.")
    createTab("Inventory", assets.inventory, "rbxassetid://10723415392", 7, nil, "Auto buy, consume, and armor-switching modules.")
    createTab("Minigames", assets.minigames, "rbxassetid://10723381488", 8, nil, "Mini-game specific modules and automations.")

    local MiscDivider = Instance.new("Frame")
    MiscDivider.Size = UDim2.new(1, 0, 0, 24)
    MiscDivider.BackgroundTransparency = 1
    MiscDivider.LayoutOrder = 9
    MiscDivider.ZIndex = 4
    MiscDivider.Parent = TabScrollingFrame

    local MiscText = Instance.new("TextLabel")
    MiscText.Size = UDim2.new(1, -30, 1, 0)
    MiscText.Position = UDim2.new(0, 15, 0, 0)
    MiscText.BackgroundTransparency = 1
    MiscText.Text = "MISC"
    MiscText.TextColor3 = Color3.fromRGB(75, 75, 75)
    MiscText.TextSize = 10
    MiscText.Font = Enum.Font.SourceSansBold
    MiscText.TextXAlignment = Enum.TextXAlignment.Left
    MiscText.ZIndex = 5
    MiscText.Parent = MiscDivider

    createTab("Friends", assets.friends, "rbxassetid://10747373426", 10, nil, "Configure your friend and whitelisted player settings.")
    createTab("Profiles", assets.profiles, "rbxassetid://10734898122", 11, "default", "Switch and customize your config profiles.")
    createTab("Macros", nil, "rbxassetid://10709811365", 12, nil, "Set up and bind custom macros to keys.")

    local SessionToggleBtn = Instance.new("TextButton")
    SessionToggleBtn.Name = "SessionToggleBtn"
    SessionToggleBtn.Size = UDim2.new(1, 0, 0, 38)
    SessionToggleBtn.Position = UDim2.new(0, 0, 1, -38)
    SessionToggleBtn.BackgroundTransparency = 1
    SessionToggleBtn.Text = ""
    SessionToggleBtn.AutoButtonColor = false
    SessionToggleBtn.ZIndex = 4
    SessionToggleBtn.Parent = ContentFrame

    local STHoverBg = Instance.new("Frame")
    STHoverBg.Size = UDim2.new(1, 0, 1, 0)
    STHoverBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    STHoverBg.BackgroundTransparency = 1
    STHoverBg.BorderSizePixel = 0
    STHoverBg.ZIndex = 2
    STHoverBg.Parent = SessionToggleBtn
    local STCorner = Instance.new("UICorner")
    STCorner.CornerRadius = UDim.new(0, 5)
    STCorner.Parent = STHoverBg

    local STIcon = Instance.new("ImageLabel")
    STIcon.Size = UDim2.new(0, 15, 0, 15)
    STIcon.Position = UDim2.new(0, 15, 0.5, -7)
    STIcon.BackgroundTransparency = 1
    STIcon.Image = "rbxassetid://14397380433"
    STIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
    STIcon.ScaleType = Enum.ScaleType.Fit
    STIcon.ZIndex = 5
    STIcon.Parent = SessionToggleBtn

    local STLabel = Instance.new("TextLabel")
    STLabel.Size = UDim2.new(1, -60, 1, 0)
    STLabel.Position = UDim2.new(0, 40, 0, 0)
    STLabel.BackgroundTransparency = 1
    STLabel.Text = "Session Info"
    STLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    STLabel.TextSize = 15
    STLabel.Font = Enum.Font.SourceSansSemibold
    STLabel.TextXAlignment = Enum.TextXAlignment.Left
    STLabel.ZIndex = 5
    STLabel.Parent = SessionToggleBtn

    SessionToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(STHoverBg, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.94}):Play()
        TweenService:Create(STIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(220, 220, 220)}):Play()
        TweenService:Create(STLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
    end)
    SessionToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(STHoverBg, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(STIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        TweenService:Create(STLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end)

    bindTooltip(SessionToggleBtn, "Toggle the visibility of the Session Info overlay.")

    return SettingsBtn, SessionToggleBtn, tabs
end

return Sidebar
end)
__bundle_register("gui.Tooltip", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/gui/Tooltip.lua

local UserInputService = game:GetService("UserInputService")
local Tooltip = {}
function Tooltip.create(ScreenGui)
    local VapeTooltip = Instance.new("Frame")
    VapeTooltip.Name = "VapeTooltip"
    VapeTooltip.Size = UDim2.fromOffset(180, 30)
    VapeTooltip.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    VapeTooltip.BorderSizePixel = 0
    VapeTooltip.Visible = false
    VapeTooltip.ZIndex = 10
    VapeTooltip.Parent = ScreenGui
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 4)
    tCorner.Parent = VapeTooltip
    local tStroke = Instance.new("UIStroke")
    tStroke.Thickness = 1
    tStroke.Color = Color3.fromRGB(35, 35, 35)
    tStroke.Parent = VapeTooltip
    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(1, -12, 1, -8)
    tLabel.Position = UDim2.fromOffset(6, 4)
    tLabel.BackgroundTransparency = 1
    tLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    tLabel.TextSize = 10
    tLabel.Font = Enum.Font.Gotham
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.TextWrapped = true
    tLabel.ZIndex = 10
    tLabel.Parent = VapeTooltip
    return VapeTooltip, tLabel
end
return Tooltip
end)
__bundle_register("utils.AssetLoader", function(require, _LOADED, __bundle_register, __bundle_modules)
-- src/utils/AssetLoader.lua

local Players = game:GetService("Players")
local isfolder = isfolder or function(path)
    local success, _ = pcall(listfiles, path)
    return success
end
local gameName = "Game"
if game.PlaceId == 6872274481 or game.PlaceId == 6872265039 or game.PlaceId == 14247545801 then
    gameName = "BedWars"
else
    local success, productInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and productInfo and productInfo.Name then
        gameName = productInfo.Name
    end
end
gameName = gameName:gsub("%s+", "_"):gsub("[^%w_]", "")
if gameName == "" then
    gameName = tostring(game.PlaceId)
end
local folderName = "vape"
if isfolder and isfolder("vape") then
    folderName = "vape_" .. gameName
end
if makefolder then
    pcall(makefolder, folderName)
    pcall(makefolder, folderName .. "/assets")
end
if delfile then
    local oldRootFiles = {
        "vape_logo_main.png", "vape_v4_badge.png", "vape_gui_settings.png",
        "vape_combat_icon.png", "vape_blatant_icon.png", "vape_render_icon.png",
        "vape_utility_icon.png", "vape_world_icon.png", "vape_inventory_icon.png",
        "vape_minigames_icon.png", "vape_friends_icon.png", "vape_profiles_icon.png", 
        "vape_blur_shadow.png", "vape_bind_icon.png"
    }
    for _, file in ipairs(oldRootFiles) do
        pcall(delfile, file)
    end
end
local getasset = getcustomasset or getgenv().getcustomasset
local request = request or http_request or (syn and syn.request)
local function loadOnlineImage(url, localName)
    if request and getasset then
        local success, response = pcall(function()
            return request({Url = url, Method = "GET"})
        end)
        if success and response and response.Success then
            local writeSuccess = pcall(writefile, localName, response.Body)
            if not writeSuccess then return nil end
            local assetSuccess, asset = pcall(getasset, localName)
            if assetSuccess and asset then return asset end
        end
    end
    return nil
end

local assets = {}

-- 🌟 進捗をローディング画面に伝えるための BindableEvent を定義
local progressEvent = Instance.new("BindableEvent")
assets.OnProgress = progressEvent.Event

-- ダウンロード対象のURLとファイル名、および表示用のラベル
local downloadList = {
    -- 保存するファイル名「ape_logo_main.png」と、進捗ラベル「Ape Main Logo」
    {key = "vapeLogo", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/aa.png", file = "ape_logo_main.png", label = "Ape Main Logo"},
    {key = "v4Logo", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/textv4.png", file = "vape_v4_badge.png", label = "V4 Badge"},
    {key = "guiSettings", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guisettings.png", file = "vape_gui_settings.png", label = "Settings Gear"},
    {key = "combat", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/combaticon.png", file = "vape_combat_icon.png", label = "Combat Icon"},
    {key = "blatant", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blatanticon.png", file = "vape_blatant_icon.png", label = "Blatant Icon"},
    {key = "render", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/rendertab.png", file = "vape_render_icon.png", label = "Render Icon"},
    {key = "utility", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/utilityicon.png", file = "vape_utility_icon.png", label = "Utility Icon"},
    {key = "world", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/worldicon.png", file = "vape_world_icon.png", label = "World Icon"},
    {key = "inventory", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/inventoryicon.png", file = "vape_inventory_icon.png", label = "Inventory Icon"},
    {key = "minigames", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/miniicon.png", file = "vape_minigames_icon.png", label = "Minigames Icon"},
    {key = "friends", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/friendstab.png", file = "vape_friends_icon.png", label = "Friends Icon"},
    {key = "profiles", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/profilesicon.png", file = "vape_profiles_icon.png", label = "Profiles Icon"},
    {key = "blurShadow", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blur.png", file = "vape_blur_shadow.png", label = "Blur Shadow Layer"},
    {key = "bind", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/bind.png", file = "vape_bind_icon.png", label = "Keybind Icon"},
    {key = "guislider", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guislider.png", file = "vape_guislider.png", label = "GUI Slider"},
    {key = "guisliderrain", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guisliderrain.png", file = "vape_guisliderrain.png", label = "Rainbow Slider"},
    {key = "warning", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/warning.png", file = "warning.png", label = "Warning Icon"},
    {key = "blurnotif", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blurnotif.png", file = "blurnotif.png", label = "Notification Blur"},
    -- 🌟 【追加】新規通知関連アセット 3点
    {key = "alert", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/alert.png", file = "alert.png", label = "Alert Icon"},
    {key = "info", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/info.png", file = "info.png", label = "Info Icon"},
    {key = "notification", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/notification.png", file = "notification.png", label = "Notification Background"}
}

-- 🌟 この関数を呼び出すことで、実際のアセット読み込み（ダウンロード）を開始します
-- 🌟 アセットのロード処理（遅延時間を調整）
function assets.loadAll()
    local total = #downloadList
    for i, item in ipairs(downloadList) do
        -- 進捗イベントを発火
        progressEvent:Fire(i / total, "Loading " .. item.label .. "...")
        
        -- アセットをダウンロード＆登録
        assets[item.key] = loadOnlineImage(item.url, folderName .. "/assets/" .. item.file)
        
        -- 🌟 演出を綺麗に見せるため、あえて 0.08 秒の遅延を追加
        -- これにより、ゲージがカクつかずスムーズになめらかに伸びていきます
        task.wait(0.08) 
    end
    
    -- 固定アセットの追加
    assets.arrow = "rbxassetid://10709791437"
    
    -- ロード完了を通知
    progressEvent:Fire(1.0, "Assets successfully loaded!")
end

return assets
end)
return __bundle_require("__root")