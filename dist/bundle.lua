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
end)
__bundle_register("hud.Tutorial", function(require, _LOADED, __bundle_register, __bundle_modules)
local TweenService = game:GetService("TweenService")
local Tutorial = {}
function Tutorial.init(TutorialFrame, TutorialHeader)
    local TutorialTitle = Instance.new("TextLabel")
    TutorialTitle.Size = UDim2.new(1, -30, 1, 0)
    TutorialTitle.Position = UDim2.new(0, 15, 0, 0)
    TutorialTitle.BackgroundTransparency = 1
    TutorialTitle.Text = "Tutorial"
    TutorialTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    TutorialTitle.TextSize = 13
    TutorialTitle.Font = Enum.Font.GothamMedium
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
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
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
    GotItBtn.TextSize = 11
    GotItBtn.Font = Enum.Font.GothamBold
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
__bundle_register("hud.SessionInfo", function(require, _LOADED, __bundle_register, __bundle_modules)
local SessionInfo = {}
function SessionInfo.init(SessionFrame)
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
    local SessionIcon = Instance.new("ImageLabel")
    SessionIcon.Size = UDim2.fromOffset(14, 12)
    SessionIcon.Position = UDim2.new(0, 15, 0.5, -6)
    SessionIcon.BackgroundTransparency = 1
    SessionIcon.Image = "rbxassetid://14397380433"
    SessionIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    SessionIcon.ScaleType = Enum.ScaleType.Fit
    SessionIcon.ZIndex = 5
    SessionIcon.Parent = SessionHeaderPlaceholder
    local SessionTitle = Instance.new("TextLabel")
    SessionTitle.Size = UDim2.new(1, -85, 1, 0)
    SessionTitle.Position = UDim2.new(0, 35, 0, 0)
    SessionTitle.BackgroundTransparency = 1
    SessionTitle.Text = "Session Info"
    SessionTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    SessionTitle.TextSize = 13
    SessionTitle.Font = Enum.Font.GothamMedium
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
    BodyLayout.FillDirection, BodyLayout.SortOrder, BodyLayout.Padding = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, UDim.new(0, 6)
    BodyLayout.Parent = SessionBody
    local function createStatsLabel(text, layoutOrder)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 16)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(150, 150, 150)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.LayoutOrder = layoutOrder
        Label.ZIndex = 5
        Label.Parent = SessionBody
        return Label
    end
    local elapsedTimer = createStatsLabel("Time Elapsed: 0h 0m 0s", 1)
    createStatsLabel("Kills: 0", 2)
    createStatsLabel("Wins: 0", 3)
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
__bundle_register("gui.Sidebar", function(require, _LOADED, __bundle_register, __bundle_modules)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Sidebar = {}

function Sidebar.init(MainFrame, assets, VapeTooltip, tLabel)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ZIndex = 4
    ContentFrame.Parent = MainFrame

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 0)
    ListLayout.Parent = ContentFrame

    local HeaderPlaceholder = Instance.new("Frame")
    HeaderPlaceholder.Name = "HeaderPlaceholder"
    HeaderPlaceholder.Size = UDim2.new(1, 0, 0, 38)
    HeaderPlaceholder.BackgroundTransparency = 1
    HeaderPlaceholder.LayoutOrder = 1
    HeaderPlaceholder.ZIndex = 4
    HeaderPlaceholder.Parent = ContentFrame

    local LogoContainer = Instance.new("Frame")
    LogoContainer.Name = "LogoContainer"
    LogoContainer.Size = UDim2.new(0, 130, 1, 0)
    LogoContainer.Position = UDim2.new(0, 15, 0, 0)
    LogoContainer.BackgroundTransparency = 1
    LogoContainer.ZIndex = 5
    LogoContainer.Parent = HeaderPlaceholder

    local LogoLayout = Instance.new("UIListLayout")
    LogoLayout.FillDirection = Enum.FillDirection.Horizontal
    LogoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    LogoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogoLayout.Padding = UDim.new(0, 3)
    LogoLayout.Parent = LogoContainer

    local VapeLogo = Instance.new("ImageLabel")
    VapeLogo.Name = "VapeLogo"
    VapeLogo.LayoutOrder = 1
    VapeLogo.BackgroundTransparency = 1
    VapeLogo.Size = UDim2.new(0, 58, 0, 17)
    VapeLogo.ScaleType = Enum.ScaleType.Fit
    VapeLogo.ZIndex = 6
    if assets.vapeLogo then
        VapeLogo.Image = assets.vapeLogo
    else
        VapeLogo.Size = UDim2.new(0, 50, 1, 0)
        local TempText = Instance.new("TextLabel")
        TempText.Size = UDim2.new(1, 0, 1, 0)
        TempText.BackgroundTransparency = 1
        TempText.Text = "VAPE"
        TempText.TextColor3 = Color3.fromRGB(255, 255, 255)
        TempText.Font = Enum.Font.GothamBold
        TempText.TextSize = 14
        TempText.Parent = VapeLogo
    end
    VapeLogo.Parent = LogoContainer

    local V4Logo = Instance.new("ImageLabel")
    V4Logo.Name = "V4Logo"
    V4Logo.LayoutOrder = 2
    V4Logo.BackgroundTransparency = 1
    V4Logo.Size = UDim2.new(0, 28, 0, 14)
    V4Logo.ScaleType = Enum.ScaleType.Fit
    V4Logo.ZIndex = 6
    if assets.v4Logo then
        V4Logo.Image = assets.v4Logo
    else
        V4Logo.Size = UDim2.new(0, 18, 0, 12)
        local TempText = Instance.new("TextLabel")
        TempText.Size = UDim2.new(1, 0, 1, 0)
        TempText.BackgroundTransparency = 1
        TempText.Text = "V4"
        TempText.TextColor3 = Color3.fromRGB(30, 180, 130)
        TempText.Font = Enum.Font.GothamBold
        TempText.TextSize = 8
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
    if assets.guiSettings then
        SettingsBtn.Image = assets.guiSettings
        SettingsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    else
        SettingsBtn.Image = "rbxassetid://6031280224"
        SettingsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    end
    SettingsBtn.Parent = HeaderPlaceholder

    SettingsBtn.MouseEnter:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(180, 180, 180), Rotation = 45}):Play()
    end)
    SettingsBtn.MouseLeave:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(110, 110, 110), Rotation = 0}):Play()
    end)

    local function createTab(name, iconAssetId, fallbackAssetId, layoutOrder, hasBadge, desc)
        local Tab = Instance.new("TextButton")
        Tab.Name = name .. "Tab"
        Tab.Size = UDim2.new(1, 0, 0, 38)
        Tab.BackgroundTransparency = 1
        Tab.Text = ""
        Tab.AutoButtonColor = false
        Tab.LayoutOrder = layoutOrder
        Tab.ZIndex = 4
        Tab.Parent = ContentFrame

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
            TabIcon.Image = fallbackAssetId
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
        TabLabel.TextSize = 13
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.ZIndex = 5
        TabLabel.Parent = Tab

        local Arrow = Instance.new("ImageLabel")
        Arrow.Name = "Arrow"
        Arrow.Size = UDim2.fromOffset(12, 12)
        Arrow.BackgroundTransparency = 1
        Arrow.Image = assets.arrow
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
            Badge.TextSize = 9
            Badge.Font = Enum.Font.Gotham
            Badge.ZIndex = 5
            Badge.Parent = Tab

            local BadgeCorner = Instance.new("UICorner")
            BadgeCorner.CornerRadius = UDim.new(0, 3)
            BadgeCorner.Parent = Badge
        end

        local hoverTime = 0.15
        local easingStyle = Enum.EasingStyle.Quart
        local easingDirection = Enum.EasingDirection.Out
        local hoverActive = false
        local hoverThread = nil

        Tab.MouseEnter:Connect(function()
            TweenService:Create(TabHoverBg, TweenInfo.new(hoverTime, easingStyle, easingDirection), {BackgroundTransparency = 0.94}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(220, 220, 220), Position = UDim2.new(0, 17 - (iconSizeX - 15) / 2, 0.5, -iconSizeY / 2)}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(hoverTime, easingStyle, easingDirection), {TextColor3 = Color3.fromRGB(220, 220, 220), Position = UDim2.new(0, 42, 0, 0)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(240, 240, 240)}):Play()
            hoverActive = true
            hoverThread = task.delay(1, function()
                if hoverActive and desc then
                    tLabel.Text = desc
                    VapeTooltip.Position = UDim2.fromOffset(UserInputService:GetMouseLocation().X + 15, UserInputService:GetMouseLocation().Y - 5)
                    VapeTooltip.Visible = true
                end
            end)
        end)

        Tab.MouseLeave:Connect(function()
            TweenService:Create(TabHoverBg, TweenInfo.new(hoverTime, easingStyle, easingDirection), {BackgroundTransparency = 1}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(150, 150, 150), Position = UDim2.new(0, 15 - (iconSizeX - 15) / 2, 0.5, -iconSizeY / 2)}):Play()
            TweenService:Create(TabLabel, TweenInfo.new(hoverTime, easingStyle, easingDirection), {TextColor3 = Color3.fromRGB(150, 150, 150), Position = UDim2.new(0, 40, 0, 0)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(hoverTime, easingStyle, easingDirection), {ImageColor3 = Color3.fromRGB(140, 140, 140)}):Play()
            hoverActive = false
            if hoverThread then
                task.cancel(hoverThread)
                hoverThread = nil
            end
            VapeTooltip.Visible = false
        end)
    end

    createTab("Combat", assets.combat, "rbxassetid://10723414920", 2, nil, "Combat modules for player vs player fights.")
    createTab("Render", assets.render, "rbxassetid://10709765275", 3, nil, "Visual modifications like ESP, Chams, and Tracers.")
    createTab("Utility", assets.utility, "rbxassetid://10747385202", 4, nil, "Useful utilities and automation scripts.")
    createTab("World", assets.world, "rbxassetid://10723351909", 5, nil, "World-related helpers and environment tweaks.")
    createTab("Inventory", assets.inventory, "rbxassetid://10723415392", 6, nil, "Auto buy, consume, and armor-switching modules.")
    createTab("Minigames", assets.minigames, "rbxassetid://10723381488", 7, nil, "Mini-game specific modules and automations.")
    createTab("Blatant", assets.blatant, "rbxassetid://10723343281", 8, nil, "Blatant modules like Fly, Speed, and Killaura.")

    local MiscDivider = Instance.new("Frame")
    MiscDivider.Size = UDim2.new(1, 0, 0, 24)
    MiscDivider.BackgroundTransparency = 1
    MiscDivider.LayoutOrder = 9
    MiscDivider.ZIndex = 4
    MiscDivider.Parent = ContentFrame

    local MiscText = Instance.new("TextLabel")
    MiscText.Size = UDim2.new(1, -30, 1, 0)
    MiscText.Position = UDim2.new(0, 15, 0, 0)
    MiscText.BackgroundTransparency = 1
    MiscText.Text = "MISC"
    MiscText.TextColor3 = Color3.fromRGB(75, 75, 75)
    MiscText.TextSize = 9
    MiscText.Font = Enum.Font.GothamBold
    MiscText.TextXAlignment = Enum.TextXAlignment.Left
    MiscText.ZIndex = 5
    MiscText.Parent = MiscDivider

    createTab("Friends", assets.friends, "rbxassetid://10747373426", 10, nil, "Configure your friend and whitelisted player settings.")
    createTab("Profiles", assets.profiles, "rbxassetid://10734898122", 11, "default", "Switch and customize your config profiles.")
    createTab("Macros", nil, "rbxassetid://10709811365", 12, nil, "Set up and bind custom macros to keys.")

    local SessionDivider2 = Instance.new("Frame")
    SessionDivider2.Size = UDim2.new(1, 0, 0, 24)
    SessionDivider2.BackgroundTransparency = 1
    SessionDivider2.LayoutOrder = 13
    SessionDivider2.ZIndex = 4
    SessionDivider2.Parent = ContentFrame

    local SessionToggleBtn = Instance.new("TextButton")
    SessionToggleBtn.Name = "SessionToggleBtn"
    SessionToggleBtn.Size = UDim2.new(1, 0, 0, 38)
    SessionToggleBtn.BackgroundTransparency = 1
    SessionToggleBtn.Text = ""
    SessionToggleBtn.AutoButtonColor = false
    SessionToggleBtn.LayoutOrder = 14
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
    STLabel.TextSize = 13
    STLabel.Font = Enum.Font.GothamMedium
    STLabel.TextXAlignment = Enum.TextXAlignment.Left
    STLabel.ZIndex = 5
    STLabel.Parent = SessionToggleBtn -- ここを正しく修正しました

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

    return SettingsBtn, SessionToggleBtn
end

return Sidebar
end)
__bundle_register("gui.Tooltip", function(require, _LOADED, __bundle_register, __bundle_modules)
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
__bundle_register("gui.WindowFactory", function(require, _LOADED, __bundle_register, __bundle_modules)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local WindowFactory = {}
function WindowFactory.setupDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
function WindowFactory.createBaseWindow(ScreenGui, name, size, position)
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Size = size
    container.Position = position
    container.BackgroundTransparency = 1
    container.Active = true
    container.ZIndex = 2
    container.Parent = ScreenGui
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
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 2
    mainFrame.Parent = container
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = mainFrame
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(35, 35, 35)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = mainFrame
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    header.BorderSizePixel = 0
    header.ZIndex = 3
    header.Parent = mainFrame
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 5)
    headerCorner.Parent = header
    local headerCover = Instance.new("Frame")
    headerCover.Name = "HeaderCover"
    headerCover.Size = UDim2.new(1, 0, 0, 5)
    headerCover.Position = UDim2.new(0, 0, 1, -5)
    headerCover.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    headerCover.BorderSizePixel = 0
    headerCover.ZIndex = 3
    headerCover.Parent = header
    return container, mainFrame, header
end
return WindowFactory
end)
__bundle_register("utils.AssetLoader", function(require, _LOADED, __bundle_register, __bundle_modules)
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
        "vape_combat_icon.png", "vape_render_icon.png", "vape_utility_icon.png",
        "vape_world_icon.png", "vape_inventory_icon.png", "vape_minigames_icon.png",
        "vape_friends_icon.png", "vape_profiles_icon.png", "vape_blur_shadow.png"
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
assets.vapeLogo = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/textvape.png", folderName .. "/assets/vape_logo_main.png")
assets.v4Logo = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/textv4.png", folderName .. "/assets/vape_v4_badge.png")
assets.guiSettings = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guisettings.png", folderName .. "/assets/vape_gui_settings.png")
assets.combat = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/combaticon.png", folderName .. "/assets/vape_combat_icon.png")
assets.render = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/rendertab.png", folderName .. "/assets/vape_render_icon.png")
assets.utility = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/utilityicon.png", folderName .. "/assets/vape_utility_icon.png")
assets.world = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/worldicon.png", folderName .. "/assets/vape_world_icon.png")
assets.inventory = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/inventoryicon.png", folderName .. "/assets/vape_inventory_icon.png")
assets.minigames = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/miniicon.png", folderName .. "/assets/vape_minigames_icon.png")
assets.friends = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/friendstab.png", folderName .. "/assets/vape_friends_icon.png")
assets.profiles = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/profilesicon.png", folderName .. "/assets/vape_profiles_icon.png")
assets.blurShadow = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blur.png", folderName .. "/assets/vape_blur_shadow.png")
assets.arrow = "rbxassetid://10709791437"
return assets
end)
return __bundle_require("__root")