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
  -- src/Main.lua inside LoadingScreen.show
    local Notification = require("gui.Notification")
    _G.mainapi = {
        CreateNotification = function(self, title, text, duration, notifType)
            Notification.create(ScreenGui, title, text, duration, notifType)
        end,
        UpdateTextGUI = function(self, ...)
            -- Empty method to prevent missing method crashes
        end,
        RainbowTable = {},
        -- Option A: Classic Vape Teal Green applied
-- Exact color representation matched from the Scaffold screenshot
-- Exact color representation matched from the Parkour screenshot (Deep Emerald Teal)
    GUIColor = { Hue = 0.45, Sat = 1.00, Value = 0.50 }
    }
    shared.vape = _G.mainapi -- For compatibility



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

-- Create Minigames window
    local MinigamesWindow = ModuleWindow.new(
        ScreenGui, "Minigames",
        UDim2.new(0, sidebarWidth, 0, 300),
        UDim2.new(0, minigamesX, 0.2, 0),
        assets.minigames or assets.Minigames, assets
    )

    -- [Ported directly from Sidebar.lua without any coordinate modifications]
    local name = "Minigames"
    local iconSizeX = 15
    local iconSizeY = 15
    if name == "Minigames" then
        iconSizeX, iconSizeY = 19, 19
    end

    local minigamesIcon = MinigamesWindow.Header:FindFirstChildOfClass("ImageLabel")
    if minigamesIcon then
        minigamesIcon.Size = UDim2.new(0, iconSizeX, 0, iconSizeY)
        minigamesIcon.Position = UDim2.new(0, 15 - (iconSizeX - 15) / 2, 0.5, -iconSizeY / 2)
    end

    -- モジュールのロード
   -- Load modules dynamically by requiring the file paths
    local function loadModules(window, list)
        if not list then return end
        for _, modPath in ipairs(list) do
            -- Dynamically load the module table via our custom require
            local success, mod = pcall(require, modPath)
            
            if success and type(mod) == "table" then
                -- Safely create the module UI using loaded properties
                local moduleObj = window:CreateModule(mod.Name, mod.Description, mod.Callback)
                if type(mod.Init) == "function" then
                    mod.Init(moduleObj)
                end
            else
                -- Output a warning if the module failed to load or compile
                warn("Failed to load module at path: " .. tostring(modPath) .. " | Error: " .. tostring(mod))
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