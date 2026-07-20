local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local WindowFactory = require("gui.WindowFactory")
local Module = require("gui.components.Module")
local ModuleWindow = {}
ModuleWindow.__index = ModuleWindow
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
function ModuleWindow.new(ScreenGui, name, size, position, iconAssetId, assets)
    local self = setmetatable({}, ModuleWindow)
    local container, mainFrame, header = WindowFactory.createBaseWindow(ScreenGui, name, size, position, iconAssetId)
    self.Container = container
    self.MainFrame = mainFrame
    self.Header = header
    self.Visible = false
    self.Modules = {}
    self.Collapsed = false
    self.Assets = assets
    WindowFactory.setupDraggable(container, mainFrame)
    header.BackgroundTransparency = 1
    local title = header:FindFirstChild("Title")
    if title then
        title.Font = Enum.Font.SourceSansSemibold
        title.TextSize = 18
    end
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
    local HEADER_HEIGHT = 38
    local MAX_WINDOW_HEIGHT = size.Y.Offset
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "ListFrame"
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
    listLayout.Padding = UDim.new(0, 1)
    listLayout.Parent = listFrame
    local function updateWindowSize()
        local contentHeight = listLayout.AbsoluteContentSize.Y
        listFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
        if not self.Collapsed then
            local maxAllowedContentHeight = MAX_WINDOW_HEIGHT - HEADER_HEIGHT
            local targetContentHeight = math.min(contentHeight, maxAllowedContentHeight)
            local targetHeight = HEADER_HEIGHT + targetContentHeight
            local needsScrolling = contentHeight > maxAllowedContentHeight
            listFrame.ScrollingEnabled = needsScrolling
            listFrame.ScrollBarImageTransparency = needsScrolling and 0 or 1
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
function ModuleWindow:CreateModule(name, desc, callback)
    local moduleObj = Module.new(self.ListFrame, name, callback, self.Assets)
    table.insert(self.Modules, moduleObj)
    return moduleObj
end
return ModuleWindow