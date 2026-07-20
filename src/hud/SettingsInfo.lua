local TweenService = game:GetService("TweenService")
local Toggle = require("gui.components.Toggle")
local SettingsInfo = {}
function SettingsInfo.init(SettingsFrame)
    task.defer(function()
        if SettingsFrame and SettingsFrame.Parent then
            SettingsFrame.Parent.AnchorPoint = Vector2.new(0, 1)
            SettingsFrame.Parent.Position = UDim2.new(0, 240, 1, -10)
        end
    end)
    local defaultHeader = SettingsFrame:FindFirstChild("Header")
    if defaultHeader then
        defaultHeader.BackgroundTransparency = 1
        local defaultTitle = defaultHeader:FindFirstChild("Title")
        if defaultTitle then
            defaultTitle.Visible = false
        end
    end
    local SettingsContent = Instance.new("Frame")
    SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.BorderSizePixel = 0
    SettingsContent.ZIndex = 4
    SettingsContent.Parent = SettingsFrame
    local SettingsHeaderPlaceholder = Instance.new("Frame")
    SettingsHeaderPlaceholder.Size = UDim2.new(1, 0, 0, 38)
    SettingsHeaderPlaceholder.BackgroundTransparency = 1
    SettingsHeaderPlaceholder.ZIndex = 4
    SettingsHeaderPlaceholder.Parent = SettingsContent
    local SettingsIcon = Instance.new("ImageLabel")
    SettingsIcon.Size = UDim2.fromOffset(18, 18)
    SettingsIcon.Position = UDim2.new(0, 15, 0.5, -9)
    SettingsIcon.BackgroundTransparency = 1
    SettingsIcon.Image = "rbxassetid://10734950309"
    SettingsIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    SettingsIcon.ScaleType = Enum.ScaleType.Fit
    SettingsIcon.ZIndex = 5
    SettingsIcon.Parent = SettingsHeaderPlaceholder
    local SettingsTitle = Instance.new("TextLabel")
    SettingsTitle.Size = UDim2.new(1, -85, 1, 0)
    SettingsTitle.Position = UDim2.new(0, 40, 0, 0)
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Text = "GUI Settings"
    SettingsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    SettingsTitle.TextSize = 14
    SettingsTitle.Font = Enum.Font.SourceSansBold
    SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    SettingsTitle.ZIndex = 5
    SettingsTitle.Parent = SettingsHeaderPlaceholder
    local PinBtn = Instance.new("ImageButton")
    PinBtn.Size = UDim2.fromOffset(13, 13)
    PinBtn.Position = UDim2.new(1, -35, 0.5, 0)
    PinBtn.AnchorPoint = Vector2.new(1, 0.5)
    PinBtn.BackgroundTransparency = 1
    PinBtn.Image = "rbxassetid://14368342301"
    PinBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    PinBtn.ZIndex = 5
    PinBtn.Parent = SettingsHeaderPlaceholder
    local DotsBtn = Instance.new("ImageButton")
    DotsBtn.Size = UDim2.fromOffset(3, 13)
    DotsBtn.Position = UDim2.new(1, -15, 0.5, 0)
    DotsBtn.AnchorPoint = Vector2.new(1, 0.5)
    DotsBtn.BackgroundTransparency = 1
    DotsBtn.Image = "rbxassetid://14368314459"
    DotsBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    DotsBtn.ZIndex = 5
    DotsBtn.Parent = SettingsHeaderPlaceholder
    local SettingsDivider = Instance.new("Frame")
    SettingsDivider.Size = UDim2.new(1, 0, 0, 1)
    SettingsDivider.Position = UDim2.new(0, 0, 0, 37)
    SettingsDivider.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SettingsDivider.BorderSizePixel = 0
    SettingsDivider.ZIndex = 4
    SettingsDivider.Parent = SettingsContent
    local SettingsBody = Instance.new("Frame")
    SettingsBody.Size = UDim2.new(1, 0, 1, -38)
    SettingsBody.Position = UDim2.new(0, 0, 0, 38)
    SettingsBody.BackgroundTransparency = 1
    SettingsBody.ZIndex = 4
    SettingsBody.Parent = SettingsContent
    local BodyPadding = Instance.new("UIPadding")
    BodyPadding.PaddingLeft = UDim.new(0, 15)
    BodyPadding.PaddingRight = UDim.new(0, 15)
    BodyPadding.PaddingTop = UDim.new(0, 10)
    BodyPadding.Parent = SettingsBody
    local BodyLayout = Instance.new("UIListLayout")
    BodyLayout.FillDirection = Enum.FillDirection.Vertical
    BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BodyLayout.Padding = UDim.new(0, 4)
    BodyLayout.Parent = SettingsBody
    local function createToggle(text, enabled, layoutOrder, iconAssetId, callback)
        local toggleInst = Toggle.new(SettingsBody, text, enabled, callback)
        if toggleInst and toggleInst.Object then
            toggleInst.Object.LayoutOrder = layoutOrder
            toggleInst.Object.ZIndex = 5
            toggleInst.Object.BackgroundTransparency = 1
            if iconAssetId then
                toggleInst.Object.Text = "      " .. text
                local toggleIcon = Instance.new("ImageLabel")
                toggleIcon.Name = "ToggleIcon"
                toggleIcon.Size = UDim2.fromOffset(13, 13)
                toggleIcon.Position = UDim2.new(0, 0, 0.5, -6)
                toggleIcon.BackgroundTransparency = 1
                toggleIcon.Image = iconAssetId
                toggleIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
                toggleIcon.ScaleType = Enum.ScaleType.Fit
                toggleIcon.ZIndex = 6
                toggleIcon.Parent = toggleInst.Object
            else
                toggleInst.Object.Text = text
            end
            toggleInst.Object.Size = UDim2.new(1, 0, 0, 24)
            if toggleInst.KnobHolder then
                toggleInst.KnobHolder.Position = UDim2.new(1, -30, 0, 6)
            end
        end
        return toggleInst
    end
    createToggle("Blur Background", shared.VapeSettings.BlurBackground, 1, "rbxassetid://7733774602", function(state)
        shared.VapeSettings.BlurBackground = state
        shared.VapeSettingsChanged:Fire("BlurBackground", state)
    end)
    createToggle("Show Tooltips", shared.VapeSettings.ShowTooltips, 2, "rbxassetid://7733964719", function(state)
        shared.VapeSettings.ShowTooltips = state
        shared.VapeSettingsChanged:Fire("ShowTooltips", state)
    end)
    createToggle("GUI Bind Indicator", shared.VapeSettings.GPUBindIndicator, 3, "rbxassetid://7733965118", function(state)
        shared.VapeSettings.GPUBindIndicator = state
        shared.VapeSettingsChanged:Fire("GPUBindIndicator", state)
    end)
    createToggle("Show Legit Mode", shared.VapeSettings.ShowLegitMode, 4, "rbxassetid://7734056608", function(state)
        shared.VapeSettings.ShowLegitMode = state
        shared.VapeSettingsChanged:Fire("ShowLegitMode", state)
    end)
    DotsBtn.MouseButton1Click:Connect(function()
        SettingsFrame.Parent.Visible = false
    end)
end
return SettingsInfo