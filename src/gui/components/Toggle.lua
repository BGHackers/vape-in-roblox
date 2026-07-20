local TweenService = game:GetService("TweenService")
local Toggle = {}
Toggle.__index = Toggle
local DEBUG_ENABLED = true
local function debugPrint(...)
    if DEBUG_ENABLED then print("[Toggle]", ...) end
end
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
local function colorLight(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end
local function colorDark(col, num)
    local h, s, v = col:ToHSV()
    return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end
local function playTween(obj, tweeninfo, goal)
    if obj and obj.Parent then
        TweenService:Create(obj, tweeninfo, goal):Play()
    else
        for i, v in pairs(goal) do obj[i] = v end
    end
end
function Toggle.new(parent, nameOrSettings, defaultValue, callback, options, api)
    local self = setmetatable({}, Toggle)
    local name = nameOrSettings
    if type(nameOrSettings) == "table" then
        local s    = nameOrSettings
        local savedApi = defaultValue
        name         = s.Name
        defaultValue = s.Default
        callback     = s.Function
        options      = s
        api          = savedApi
        debugPrint("table mode:", name)
    else
        debugPrint("param mode:", name)
    end
    local active_uipallet = (uipallet and uipallet.Main and uipallet.Tween) and uipallet or default_uipallet
    local active_color    = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween    = (tween and tween.Tween and tween.Cancel) and tween or nil
    local active_mainapi  = mainapi
    self.api      = api or active_mainapi
    self.mainapi  = active_mainapi
    self.uipallet = active_uipallet
    self.color    = active_color
    self.tween    = active_tween
    self.Name     = name
    self.Type     = "Toggle"
    self.Enabled  = false
    self.Hovered  = false
    self.Index    = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.Callback = callback or function() end
    local isDarker    = type(options) == "table" and options.Darker
    local isVisible   = not (type(options) == "table" and options.Visible == false)
    local tooltipText = type(options) == "table" and options.Tooltip
    local toggle = Instance.new("TextButton")
    toggle.Name             = name .. "Toggle"
    toggle.Size             = UDim2.new(1, 0, 0, 30)
    toggle.BorderSizePixel  = 0
    toggle.AutoButtonColor  = false
    toggle.Visible          = isVisible
toggle.Text             = name
    toggle.TextXAlignment   = Enum.TextXAlignment.Left
    toggle.TextSize         = 18
    toggle.TextColor3       = active_color.Dark(active_uipallet.Text, 0.16)
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingLeft = UDim.new(0, 12)
    uiPadding.Parent = toggle
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    toggle.BackgroundColor3 = isDarker and active_color.Dark(parentColor, 0.02) or parentColor
    local fontOk = pcall(function() toggle.FontFace = active_uipallet.Font end)
    if not fontOk then
        pcall(function() toggle.Font = active_uipallet.Font end)
    end
    toggle.Parent = parent
    if addTooltip and tooltipText then
        addTooltip(toggle, tooltipText)
    end
    local knobholder = Instance.new("Frame")
    knobholder.Name            = "Knob"
    knobholder.Size            = UDim2.fromOffset(22, 12)
    knobholder.Position        = UDim2.new(1, -30, 0, 9)
    knobholder.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.14)
    knobholder.Parent          = toggle
    if addCorner then
        addCorner(knobholder, UDim.new(1, 0))
    else
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = knobholder
    end
    local knob = knobholder:Clone()
    knob.Name            = "KnobCircle"
    knob.Size            = UDim2.fromOffset(8, 8)
    knob.Position        = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = active_uipallet.Main
    knob.Parent          = knobholder
    self.Object     = toggle
    self.KnobHolder = knobholder
    self.Knob       = knob
    toggle.MouseEnter:Connect(function()
        self.Hovered = true
        if not self.Enabled then
            playTween(knobholder, self.uipallet.Tween, {
                BackgroundColor3 = self.color.Light(self.uipallet.Main, 0.37)
            })
        end
    end)
    toggle.MouseLeave:Connect(function()
        self.Hovered = false
        if not self.Enabled then
            playTween(knobholder, self.uipallet.Tween, {
                BackgroundColor3 = self.color.Light(self.uipallet.Main, 0.14)
            })
        end
    end)
    toggle.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    if defaultValue == true then
        self:Toggle()
    end
    if self.api and self.api.Options then
        self.api.Options[name] = self
    end
    return self
end
function Toggle:Toggle()
    self.Enabled = not self.Enabled
    debugPrint("Toggle:", self.Name, self.Enabled)
    local mapi = self.mainapi
    local rainbow = mapi and mapi.GUIColor and mapi.RainbowMode
        and mapi.GUIColor.Rainbow and mapi.RainbowMode.Value ~= "Retro"
    local targetBg
    if self.Enabled then
        if rainbow and mapi.Color then
            targetBg = Color3.fromHSV(mapi:Color((mapi.GUIColor.Hue - self.Index * 0.075) % 1))
        elseif mapi and mapi.GUIColor then
            targetBg = Color3.fromHSV(mapi.GUIColor.Hue, mapi.GUIColor.Sat, mapi.GUIColor.Value)
        else
            targetBg = Color3.fromRGB(0, 204, 136)
        end
    else
        targetBg = self.Hovered
            and self.color.Light(self.uipallet.Main, 0.37)
            or  self.color.Light(self.uipallet.Main, 0.14)
    end
    local targetPos = self.Enabled and UDim2.fromOffset(12, 2) or UDim2.fromOffset(2, 2)
    playTween(self.KnobHolder, self.uipallet.Tween, {BackgroundColor3 = targetBg})
    playTween(self.Knob,       self.uipallet.Tween, {Position = targetPos})
    if self.Callback then task.spawn(self.Callback, self.Enabled) end
end
function Toggle:Save(tab)
    tab[self.Name] = {Enabled = self.Enabled}
end
function Toggle:Load(tab)
    if tab and self.Enabled ~= tab.Enabled then self:Toggle() end
end
function Toggle:Color(hue, sat, val, rainbowcheck)
    if not self.Enabled then return end
    local mapi = self.mainapi
    local c = (rainbowcheck and mapi and mapi.Color)
        and Color3.fromHSV(mapi:Color((hue - self.Index * 0.075) % 1))
        or  Color3.fromHSV(hue, sat, val)
    if self.tween and self.tween.Cancel then
        self.tween:Cancel(self.KnobHolder)
    end
    self.KnobHolder.BackgroundColor3 = c
end
return Toggle