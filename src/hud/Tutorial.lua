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