-- src/gui/Tooltip.lua

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