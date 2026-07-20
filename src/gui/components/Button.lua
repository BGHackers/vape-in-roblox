local TweenService = game:GetService("TweenService")
local Button = {}
Button.__index = Button
local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}
local function getTableSize(t)
    local count = 0
    if typeof(t) == "table" then
        for _ in pairs(t) do count = count + 1 end
    end
    return count
end
local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end
local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end
local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end
function Button.new(parent, nameOrSettings, callback, api)
    local self = setmetatable({}, Button)
    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        callback = optionsettings.Function
    end
    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    local active_color = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween = (tween and tween.Tween) and tween or nil
    self.Name = name
    self.Type = "Button"
    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    local button = Instance.new("TextButton")
    button.Name = name .. "ButtonSetting"
    button.Size = UDim2.new(1, 0, 0, 31)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    button.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentColor, 0.02) or parentColor
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Visible = optionsettings.Visible == nil or optionsettings.Visible
    button.Text = ""
    button.Parent = parent
    if addTooltip and optionsettings.Tooltip then
        addTooltip(button, optionsettings.Tooltip)
    end
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    bkg.Size = UDim2.new(1, -24, 0, 27)
    bkg.Position = UDim2.fromOffset(12, 2)
    bkg.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.05)
    bkg.BorderSizePixel = 0
    bkg.Parent = button
    if addCorner then
        addCorner(bkg, UDim.new(0, 4))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = bkg
    end
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -4, 1, -4)
    label.Position = UDim2.fromOffset(2, 2)
    label.BackgroundColor3 = active_uipallet.Main
    label.Text = name
    label.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
    label.TextSize = 14
    applyFont(label, active_uipallet.Font)
    label.Parent = bkg
    if addCorner then
        addCorner(label, UDim.new(0, 4))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = label
    end
    self.Object = button
    self.Bkg = bkg
    self.Label = label
    local hoverCol = active_color.Light(active_uipallet.Main, 0.0875)
    local normalCol = active_color.Light(active_uipallet.Main, 0.05)
    button.MouseEnter:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverCol }):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = normalCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = normalCol }):Play()
        end
    end)
    button.MouseButton1Click:Connect(function()
        if self.Callback then
            task.spawn(self.Callback)
        end
    end)
    if self.api and self.api.Options then
        self.api.Options[name] = self
    end
    return self
end
function Button:Save(tab)
end
function Button:Load(tab)
end
return Button