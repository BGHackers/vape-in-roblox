local TweenService = game:GetService("TweenService")
local LoadingScreen = {}
function LoadingScreen.show(parentScreenGui, assets, onComplete)
    local blur = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
    if blur then
        blur.Enabled = true
    end
    local LoadingContainer = Instance.new("CanvasGroup")
    LoadingContainer.Name = "VapeLoadingScreen"
    LoadingContainer.Size = UDim2.new(1, 0, 1, 0)
    LoadingContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10) 
    LoadingContainer.BackgroundTransparency = 0.15
    LoadingContainer.BorderSizePixel = 0
    LoadingContainer.ZIndex = 10000
    LoadingContainer.Parent = parentScreenGui
    local CenterFrame = Instance.new("Frame")
    CenterFrame.Size = UDim2.new(0, 320, 0, 120)
    CenterFrame.Position = UDim2.new(0.5, -160, 0.5, -60)
    CenterFrame.BackgroundTransparency = 1
    CenterFrame.Parent = LoadingContainer
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
    LogoLayout.Padding = UDim.new(0, 0) 
    LogoLayout.Parent = LogoContainer
    local VapeLogoImg = Instance.new("ImageLabel")
    VapeLogoImg.Name = "ApeLogoImg"
    VapeLogoImg.Size = UDim2.new(0, 76, 0, 28) 
    VapeLogoImg.BackgroundTransparency = 1
    VapeLogoImg.ImageTransparency = 1
    VapeLogoImg.ScaleType = Enum.ScaleType.Fit
    VapeLogoImg.Parent = LogoContainer
    local V4LogoImg = Instance.new("ImageLabel")
    V4LogoImg.Size = UDim2.new(0, 44, 0, 28) 
    V4LogoImg.BackgroundTransparency = 1
    V4LogoImg.ImageTransparency = 1
    V4LogoImg.ScaleType = Enum.ScaleType.Fit
    V4LogoImg.Parent = LogoContainer
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 0, 52)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Connecting..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.SourceSansSemibold
    StatusLabel.Parent = CenterFrame
    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, 0, 0, 2)
    BarBg.Position = UDim2.new(0, 0, 0, 85)
    BarBg.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    BarBg.BorderSizePixel = 0
    BarBg.Parent = CenterFrame
    local BarBgCorner = Instance.new("UICorner")
    BarBgCorner.CornerRadius = UDim.new(0, 1)
    BarBgCorner.Parent = BarBg
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(45, 186, 120)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBg
    local BarFillCorner = Instance.new("UICorner")
    BarFillCorner.CornerRadius = UDim.new(0, 1)
    BarFillCorner.Parent = BarFill
    local connection
    local logoLoaded = false
    connection = assets.OnProgress:Connect(function(progress, text)
        StatusLabel.Text = text
        TweenService:Create(BarFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
        if not logoLoaded and assets.vapeLogo and assets.v4Logo then
            logoLoaded = true
            VapeLogoImg.Image = assets.vapeLogo
            V4LogoImg.Image = assets.v4Logo
            TweenService:Create(VapeLogoImg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
            TweenService:Create(V4LogoImg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
        end
        if progress >= 1.0 then
            if connection then
                connection:Disconnect()
                connection = nil
            end
            task.wait(0.2)
            local fadeTween = TweenService:Create(LoadingContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                GroupTransparency = 1
            })
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                LoadingContainer:Destroy()
                if onComplete then
                    onComplete()
                end
            end)
        end
    end)
    task.spawn(function()
        assets.loadAll()
    end)
end
return LoadingScreen