local TweenService = game:GetService("TweenService")
local TextBox = {}
TextBox.__index = TextBox
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
function TextBox.new(parent, nameOrSettings, defaultValue, placeholder, callback, api)
    local self = setmetatable({}, TextBox)
    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        defaultValue = optionsettings.Default
        placeholder = optionsettings.Placeholder
        callback = optionsettings.Function
    end
    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    self.Name = name
    self.Type = "TextBox"
    self.Value = defaultValue or ""
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.Callback = callback or function() end
    local textbox = Instance.new("TextButton")
    textbox.Name = name .. "TextBoxSetting"
    textbox.Size = UDim2.new(1, 0, 0, 58)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    textbox.BackgroundColor3 = optionsettings.Darker and colorDark(parentColor, 0.02) or parentColor
    textbox.BorderSizePixel = 0
    textbox.AutoButtonColor = false
    textbox.Visible = optionsettings.Visible == nil or optionsettings.Visible
    textbox.Text = ""
    textbox.Parent = parent
    if addTooltip and optionsettings.Tooltip then
        addTooltip(textbox, optionsettings.Tooltip)
    end
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -24, 0, 20)
    title.Position = UDim2.fromOffset(12, 3)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = colorDark(active_uipallet.Text, 0.16)
    title.TextSize = 17
    applyFont(title, active_uipallet.Font)
    title.Parent = textbox
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    bkg.Size = UDim2.new(1, -24, 0, 29)
    bkg.Position = UDim2.fromOffset(12, 23)
    bkg.BackgroundColor3 = colorLight(active_uipallet.Main, 0.02)
    bkg.BorderSizePixel = 0
    bkg.Parent = textbox
    if addCorner then
        addCorner(bkg, UDim.new(0, 4))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = bkg
    end
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.fromOffset(8, 0)
    box.BackgroundTransparency = 1
    box.Text = self.Value
    box.PlaceholderText = placeholder or "Click to set"
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextColor3 = colorDark(active_uipallet.Text, 0.16)
    box.PlaceholderColor3 = colorDark(active_uipallet.Text, 0.31)
    box.TextSize = 17
    applyFont(box, active_uipallet.Font)
    box.ClearTextOnFocus = false
    box.Parent = bkg
    self.Object = textbox
    self.Bkg = bkg
    self.Box = box
    textbox.MouseButton1Click:Connect(function()
        box:CaptureFocus()
    end)
    box.FocusLost:Connect(function(enter)
        self:SetValue(box.Text, enter)
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        self:SetValue(box.Text, false)
    end)
    if self.api and self.api.Options then
        self.api.Options[name] = self
    end
    return self
end
function TextBox:Save(tab)
    tab[self.Name] = {Value = self.Value}
end
function TextBox:Load(tab)
    if tab and self.Value ~= tab.Value then
        self:SetValue(tab.Value, true)
    end
end
function TextBox:SetValue(val, enter)
    if self.Value == val then return end
    self.Value = val
    if self.Box.Text ~= val then
        self.Box.Text = val
    end
    if self.Callback then
        task.spawn(self.Callback, val, enter)
    end
end
return TextBox