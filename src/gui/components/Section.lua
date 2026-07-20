local TweenService = game:GetService("TweenService")
local Section = {}
Section.__index = Section
local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSansBold,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}
local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end
function Section.new(parent, nameOrSettings, callback, moduleInstance)
    local self = setmetatable({}, Section)
    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
    end
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.Name = name
    self.Type = "Section"
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Name = name .. "Section"
    sectionFrame.Size = UDim2.new(1, 0, 0, 28)
    sectionFrame.BackgroundTransparency = 1
    sectionFrame.BorderSizePixel = 0
    sectionFrame.Parent = parent
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.fromOffset(12, 6)
    label.BackgroundTransparency = 1
    label.Text = name:upper()
    label.TextColor3 = Color3.fromRGB(110, 110, 110)
    label.TextSize = 11
    applyFont(label, active_uipallet.Font or Enum.Font.SourceSansBold)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sectionFrame
    self.Object = sectionFrame
    self.Label = label
    return self
end
function Section:Save(tab)
end
function Section:Load(tab)
end
return Section