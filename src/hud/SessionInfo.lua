local SessionInfo = {}
function SessionInfo.init(SessionFrame)
    task.defer(function()
        if SessionFrame and SessionFrame.Parent then
            SessionFrame.Parent.AnchorPoint = Vector2.new(0, 1)
            SessionFrame.Parent.Position = UDim2.new(0, 10, 1, -10)
            local currentSize = SessionFrame.Parent.Size
            SessionFrame.Parent.Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 0, 108)
        end
    end)
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
    local SessionIcon = Instance.new("ImageLabel")
    SessionIcon.Size = UDim2.fromOffset(18, 18)
    SessionIcon.Position = UDim2.new(0, 15, 0.5, -9)
    SessionIcon.BackgroundTransparency = 1
    SessionIcon.Image = "rbxassetid://14397380433"
    SessionIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    SessionIcon.ScaleType = Enum.ScaleType.Fit
    SessionIcon.ZIndex = 5
    SessionIcon.Parent = SessionHeaderPlaceholder
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
    BodyLayout.FillDirection, BodyLayout.SortOrder, BodyLayout.Padding = Enum.FillDirection.Vertical, Enum.SortOrder.LayoutOrder, UDim.new(0, 2)
    BodyLayout.Parent = SessionBody
    local function createStatsLabel(text, layoutOrder, iconAssetId)
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, 0, 0, 16)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.LayoutOrder = layoutOrder
        Row.ZIndex = 5
        Row.Parent = SessionBody
        if iconAssetId then
            local LabelIcon = Instance.new("ImageLabel")
            LabelIcon.Name = "LabelIcon"
            LabelIcon.Size = UDim2.fromOffset(13, 13)
            LabelIcon.Position = UDim2.new(0, 0, 0.5, -6)
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
    local elapsedTimer = createStatsLabel("Time Elapsed: 0h 0m 0s", 1, "rbxassetid://7733734848")
    createStatsLabel("Kills: 0", 2, "rbxassetid://7734058599")
    createStatsLabel("Wins: 0", 3, "rbxassetid://7733765398")
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