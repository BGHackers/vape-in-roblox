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