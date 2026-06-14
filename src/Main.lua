local assets = require("utils.AssetLoader")
local WindowFactory = require("gui.WindowFactory")
local Tooltip = require("gui.Tooltip")
local Sidebar = require("gui.Sidebar")
local SessionInfo = require("hud.SessionInfo")
local Tutorial = require("hud.Tutorial")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 2重起動対策: 既存のGUIを削除して作り直す
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

    local success = pcall(function()
        gui.Parent = coreGui
    end)
    if not success then
        gui.Parent = playerGui
    end

    return gui
end

local ScreenGui = getOrCreateScreenGui()

-- 【修正】すべてのウィンドウ（Container）の定義を最上部に移動（未定義エラーを防止）
local MainContainer, MainFrame, SidebarHeader = WindowFactory.createBaseWindow(ScreenGui, "Main", UDim2.new(0, 220, 0, 470), UDim2.new(0, 15, 0.2, 0))
local SessionContainer, SessionFrame, SessionHeader = WindowFactory.createBaseWindow(ScreenGui, "Session", UDim2.new(0, 220, 0, 120), UDim2.new(0, 15, 0.75, 0))
local TutorialContainer, TutorialFrame, TutorialHeader = WindowFactory.createBaseWindow(ScreenGui, "Tutorial", UDim2.new(0, 260, 0, 220), UDim2.new(0.5, -130, 0.4, -110))

-- ツールチップとサイドバーの初期化
local VapeTooltip, tLabel = Tooltip.create(ScreenGui)
local SettingsBtn, SessionToggleBtn = Sidebar.init(MainFrame, assets, VapeTooltip, tLabel)

-- 各種モジュールのセットアップ
SessionInfo.init(SessionFrame, SettingsBtn)
Tutorial.init(TutorialFrame, TutorialHeader)

-- ドラッグ機能の有効化
WindowFactory.setupDraggable(MainContainer, MainFrame)
WindowFactory.setupDraggable(SessionContainer, SessionFrame)
WindowFactory.setupDraggable(TutorialContainer, TutorialFrame)

-- 変数とアニメーションの設定
local visible = true
local sessionVisible = true
local TWEEN_INFO = TweenInfo.new(1 / 240 * 12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function animateContainer(container, show)
    local targetTransparency = show and 0 or 1
    local targetOffsetX = show and container.Position.X.Offset or container.Position.X.Offset - 10

    -- ※注意: WindowFactoryが生成する各Containerは「CanvasGroup」である必要があります。
    -- もし通常の「Frame」である場合は、GroupTransparency を BackgroundTransparency に変更してください。
    TweenService:Create(container, TWEEN_INFO, {
        GroupTransparency = targetTransparency,
        Position = UDim2.new(
            container.Position.X.Scale,
            targetOffsetX,
            container.Position.Y.Scale,
            container.Position.Y.Offset
        )
    }):Play()

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

-- 【修正】重複していたトグル処理を一本化
SessionToggleBtn.MouseButton1Click:Connect(function()
    SessionContainer.Visible = not SessionContainer.Visible
    sessionVisible = SessionContainer.Visible
end)

-- キー入力によるUI全体の開閉イベント
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        visible = not visible

        animateContainer(MainContainer, visible)

        if visible then
            if sessionVisible then
                animateContainer(SessionContainer, true)
            end
        else
            sessionVisible = SessionContainer.Visible
            if sessionVisible then
                animateContainer(SessionContainer, false)
            end
        end

        if TutorialContainer.Parent then
            animateContainer(TutorialContainer, visible)
        end

        local blurEffect = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
        if blurEffect then
            blurEffect.Enabled = visible
        end
    end
end)

print("Vape V4 Sidebar: Done setting up UI with Tutorial Window.")