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