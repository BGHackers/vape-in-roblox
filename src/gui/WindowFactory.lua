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