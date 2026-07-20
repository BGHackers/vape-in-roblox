local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local ColorPicker = {}
ColorPicker.__index = ColorPicker
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
function ColorPicker.new(parent, nameOrSettings, defaultValue, callback, assets, api)
    local self = setmetatable({}, ColorPicker)
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
    self.Type = "ColorSlider"
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.Callback = callback or function() end
    self.Hue = optionsettings.DefaultHue or (type(defaultValue) == "table" and defaultValue.Hue) or 0.44
    self.Sat = optionsettings.DefaultSat or (type(defaultValue) == "table" and defaultValue.Sat) or 1
    self.Value = optionsettings.DefaultValue or (type(defaultValue) == "table" and defaultValue.Value) or 1
    self.Opacity = optionsettings.DefaultOpacity or (type(defaultValue) == "table" and defaultValue.Opacity) or 1
    self.Rainbow = false
    local function createSubSlider(sliderName, gradientColor)
        local sub = Instance.new("TextButton")
        sub.Name = name .. "Slider" .. sliderName
        sub.Size = UDim2.new(1, 0, 0, 50)
        local parentCol = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
        sub.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentCol, 0.02) or parentCol
        sub.BorderSizePixel = 0
        sub.AutoButtonColor = false
        sub.Visible = false
        sub.Text = ""
        sub.Parent = parent
        local subTitle = Instance.new("TextLabel")
        subTitle.Name = "Title"
        subTitle.Size = UDim2.fromOffset(100, 30)
        subTitle.Position = UDim2.fromOffset(12, 2)
        subTitle.BackgroundTransparency = 1
        subTitle.Text = sliderName
        subTitle.TextXAlignment = Enum.TextXAlignment.Left
        subTitle.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
        subTitle.TextSize = 13 
        applyFont(subTitle, active_uipallet.Font)
        subTitle.Parent = sub
        local subBkg = Instance.new("Frame")
        subBkg.Name = "Slider"
        subBkg.Size = UDim2.new(1, -24, 0, 2) 
        subBkg.Position = UDim2.fromOffset(12, 37)
        subBkg.BackgroundColor3 = Color3.new(1, 1, 1)
        subBkg.BorderSizePixel = 0
        subBkg.Parent = sub
        local subGrad = Instance.new("UIGradient")
        subGrad.Color = gradientColor
        subGrad.Parent = subBkg
        local subFill = Instance.new("Frame")
        subFill.Name = "Fill"
        local initialVal = (sliderName == "Saturation" and self.Sat) or (sliderName == "Vibrance" and self.Value) or self.Opacity
        subFill.Size = UDim2.fromScale(math.clamp(initialVal, 0.01, 0.99), 1)
        subFill.Position = UDim2.new()
        subFill.BackgroundTransparency = 1
        subFill.Parent = subBkg
        local knobHolder = Instance.new("Frame")
        knobHolder.Name = "Knob"
        knobHolder.Size = UDim2.fromOffset(24, 4)
        knobHolder.Position = UDim2.fromScale(1, 0.5)
        knobHolder.AnchorPoint = Vector2.new(0.5, 0.5)
        knobHolder.BackgroundColor3 = sub.BackgroundColor3
        knobHolder.BorderSizePixel = 0
        knobHolder.Parent = subFill
        local subKnob = Instance.new("Frame")
        subKnob.Name = "KnobCircle"
        subKnob.Size = UDim2.fromOffset(14, 14)
        subKnob.Position = UDim2.fromScale(0.5, 0.5)
        subKnob.AnchorPoint = Vector2.new(0.5, 0.5)
        subKnob.BackgroundColor3 = active_uipallet.Text
        subKnob.Parent = knobHolder
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = subKnob
        local subDragging = false
        local dragConn = nil
        local function updateSubDrag(input)
            local ratio = math.clamp((input.Position.X - subBkg.AbsolutePosition.X) / subBkg.AbsoluteSize.X, 0, 1)
            if sliderName == "Saturation" then
                self:SetValue(nil, ratio, nil, nil)
            elseif sliderName == "Vibrance" then
                self:SetValue(nil, nil, ratio, nil)
            elseif sliderName == "Opacity" then
                self:SetValue(nil, nil, nil, ratio)
            end
        end
        sub.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                subDragging = true
                if dragConn then dragConn:Disconnect() end
                updateSubDrag(input)
                dragConn = UserInputService.InputChanged:Connect(function(changedInput)
                    if subDragging and (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) then
                        updateSubDrag(changedInput)
                    end
                end)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if subDragging then
                    subDragging = false
                    if dragConn then
                        dragConn:Disconnect()
                        dragConn = nil
                    end
                end
            end
        end)
        sub.MouseEnter:Connect(function()
            TweenService:Create(subKnob, active_uipallet.Tween, {Size = UDim2.fromOffset(16, 16)}):Play()
        end)
        sub.MouseLeave:Connect(function()
            if not subDragging then
                TweenService:Create(subKnob, active_uipallet.Tween, {Size = UDim2.fromOffset(14, 14)}):Play()
            end
        end)
        return sub
    end
    local slider = Instance.new("TextButton")
    slider.Name = name .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 50)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    slider.BackgroundColor3 = optionsettings.Darker and colorDark(parentColor, 0.02) or parentColor
    slider.BorderSizePixel = 0
    slider.AutoButtonColor = false
    slider.Visible = optionsettings.Visible == nil or optionsettings.Visible
    slider.Text = ""
    slider.Parent = parent
    if addTooltip and optionsettings.Tooltip then
        addTooltip(slider, optionsettings.Tooltip)
    end
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromOffset(150, 30)
    title.Position = UDim2.fromOffset(12, 2)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = colorDark(active_uipallet.Text, 0.16)
    title.TextSize = 17 
    applyFont(title, active_uipallet.Font)
    title.Parent = slider
    local valuebox = Instance.new("TextBox")
    valuebox.Name = "Box"
    valuebox.Size = UDim2.fromOffset(90, 20)
    valuebox.Position = UDim2.new(1, -102, 0, 7)
    valuebox.BackgroundTransparency = 1
    valuebox.Visible = false
    valuebox.Text = ""
    valuebox.TextXAlignment = Enum.TextXAlignment.Right
    valuebox.TextColor3 = colorDark(active_uipallet.Text, 0.16)
    valuebox.TextSize = 15
    applyFont(valuebox, active_uipallet.Font)
    valuebox.ClearTextOnFocus = true
    valuebox.Parent = slider
    local bkg = Instance.new("Frame")
    bkg.Name = "Slider"
    bkg.Size = UDim2.new(1, -24, 0, 2)
    bkg.Position = UDim2.fromOffset(12, 39)
    bkg.BackgroundColor3 = Color3.new(1, 1, 1)
    bkg.BorderSizePixel = 0
    bkg.Parent = slider
    local rainbowTable = {}
    for i = 0, 1, 0.1 do
        table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
    end
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(rainbowTable)
    gradient.Parent = bkg
    local fill = bkg:Clone()
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.01, 0.99), 1)
    fill.Position = UDim2.new()
    fill.BackgroundTransparency = 1
    fill.Parent = bkg
    local preview = Instance.new("TextButton")
    preview.Name = "Preview"
    preview.Size = UDim2.fromOffset(14, 14)
    preview.Position = UDim2.new(1, -26, 0, 10) 
    preview.BackgroundColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
    preview.BackgroundTransparency = 1 - self.Opacity
    preview.BorderSizePixel = 0
    preview.Text = ""
    preview.Parent = slider
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(1, 0)
    previewCorner.Parent = preview
    local previewStroke = Instance.new("UIStroke")
    previewStroke.Thickness = 1
    previewStroke.Color = Color3.fromRGB(80, 80, 80)
    previewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    previewStroke.Parent = preview
    local expandbutton = Instance.new("TextButton")
    expandbutton.Name = "Expand"
    expandbutton.Size = UDim2.fromOffset(17, 13)
    local textWidth = TextService:GetTextSize(title.Text, title.TextSize, title.Font, Vector2.new(1000, 1000)).X
    expandbutton.Position = UDim2.new(0, textWidth + 15, 0, 7)
    expandbutton.BackgroundTransparency = 1
    expandbutton.Text = ""
    expandbutton.Parent = slider
    local expand = Instance.new("ImageLabel")
    expand.Name = "Expand"
    expand.Size = UDim2.fromOffset(9, 5)
    expand.Position = UDim2.fromOffset(4, 4)
    expand.BackgroundTransparency = 1
    expand.Image = "rbxassetid://10709790948" 
    expand.ImageColor3 = active_color.Dark(active_uipallet.Text, 0.43)
    expand.Parent = expandbutton
    local rainbow = Instance.new("TextButton")
    rainbow.Name = "Rainbow"
    rainbow.Size = UDim2.fromOffset(14, 14)
    rainbow.Position = UDim2.new(1, -48, 0, 10)
    rainbow.BackgroundTransparency = 1
    rainbow.Text = ""
    rainbow.Parent = slider
    local rainbowCircle = Instance.new("Frame")
    rainbowCircle.Size = UDim2.fromScale(1, 1)
    rainbowCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    rainbowCircle.BorderSizePixel = 0
    rainbowCircle.Parent = rainbow
    local rcCorner = Instance.new("UICorner")
    rcCorner.CornerRadius = UDim.new(1, 0)
    rcCorner.Parent = rainbowCircle
    local rcGrad = Instance.new("UIGradient")
    rcGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 46, 52)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5, 127, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(228, 125, 43))
    })
    rcGrad.Parent = rainbowCircle
    local rainbowStroke = Instance.new("UIStroke")
    rainbowStroke.Thickness = 1.5
    rainbowStroke.Color = Color3.fromRGB(255, 255, 255)
    rainbowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rainbowStroke.Enabled = false
    rainbowStroke.Parent = rainbowCircle
    local knobholder = Instance.new("Frame")
    knobholder.Name = "Knob"
    knobholder.Size = UDim2.fromOffset(24, 4)
    knobholder.Position = UDim2.fromScale(1, 0.5)
    knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
    knobholder.BackgroundColor3 = slider.BackgroundColor3
    knobholder.BorderSizePixel = 0
    knobholder.Parent = fill
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.fromScale(0.5, 0.5)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = active_uipallet.Text
    knob.Parent = knobholder
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    local satSlider = createSubSlider("Saturation", ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
    }))
    local vibSlider = createSubSlider("Vibrance", ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
    }))
    local opSlider = createSubSlider("Opacity", ColorSequence.new({
        ColorSequenceKeypoint.new(0, active_color.Dark(active_uipallet.Main, 0.02)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, self.Value))
    }))
    self.Object     = slider
    self.Track      = bkg
    self.Fill       = fill
    self.Preview    = preview
    self.ValueBox   = valuebox
    self.RainbowStroke = rainbowStroke
    self.SatSlider  = satSlider
    self.VibSlider  = vibSlider
    self.OpSlider   = opSlider
    self.ExpandIcon = expand
    local mainDragging = false
    local mainDragConn = nil
    local function updateMainDrag(input)
        local ratio = math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
        self:SetValue(ratio, nil, nil, nil)
    end
    slider.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and (input.Position.Y - slider.AbsolutePosition.Y) > 20 then
            mainDragging = true
            if mainDragConn then mainDragConn:Disconnect() end
            updateMainDrag(input)
            mainDragConn = UserInputService.InputChanged:Connect(function(changedInput)
                if mainDragging and (changedInput.UserInputType == Enum.UserInputType.MouseMovement or changedInput.UserInputType == Enum.UserInputType.Touch) then
                    updateMainDrag(changedInput)
                end
            end)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if mainDragging then
                mainDragging = false
                if mainDragConn then
                    mainDragConn:Disconnect()
                    mainDragConn = nil
                end
            end
        end
    end)
    slider.MouseEnter:Connect(function()
        TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(16, 16)}):Play()
    end)
    slider.MouseLeave:Connect(function()
        if not mainDragging then
            TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(14, 14)}):Play()
        end
    end)
    preview.MouseButton1Click:Connect(function()
        preview.Visible = false
        rainbow.Visible = false
        valuebox.Visible = true
        valuebox:CaptureFocus()
        local c = Color3.fromHSV(self.Hue, self.Sat, self.Value)
        valuebox.Text = math.round(c.R * 255) .. ", " .. math.round(c.G * 255) .. ", " .. math.round(c.B * 255)
    end)
    valuebox.FocusLost:Connect(function(enter)
        preview.Visible = true
        rainbow.Visible = true
        valuebox.Visible = false
        if enter then
            local commas = valuebox.Text:split(",")
            local suc, res = pcall(function()
                return tonumber(commas[1]) and Color3.fromRGB(tonumber(commas[1]), tonumber(commas[2]), tonumber(commas[3])) or Color3.fromHex(valuebox.Text)
            end)
            if suc then
                if self.Rainbow then
                    self:Toggle()
                end
                self:SetValue(res:ToHSV())
            end
        end
    end)
    slider:GetPropertyChangedSignal("Visible"):Connect(function()
        local state = expand.Rotation == 180 and slider.Visible
        satSlider.Visible = state
        vibSlider.Visible = state
        opSlider.Visible = state
    end)
    expandbutton.MouseEnter:Connect(function()
        expand.ImageColor3 = active_color.Dark(active_uipallet.Text, 0.43)
    end)
    expandbutton.MouseLeave:Connect(function()
        expand.ImageColor3 = active_color.Dark(active_uipallet.Text, 0.43)
    end)
    expandbutton.MouseButton1Click:Connect(function()
        local state = not satSlider.Visible
        satSlider.Visible = state
        vibSlider.Visible = state
        opSlider.Visible = state
        expand.Rotation = state and 180 or 0
    end)
    rainbow.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    slider.MouseButton1Click:Connect(function()
        self.Window.Visible = not self.Window.Visible
        local guiCol = active_mainapi and active_mainapi.GUIColor or {Hue = 0, Sat = 1, Value = 1}
        local activeColor = self.Window.Visible and Color3.fromHSV(guiCol.Hue, guiCol.Sat, guiCol.Value) or active_color.Light(active_uipallet.Main, 0.034)
        TweenService:Create(bkg, TweenInfo.new(0.12), {BackgroundColor3 = activeColor}):Play()
    end)
    if self.api and self.api.Options then
        self.api.Options[name] = self
    end
    self:SetValue(self.Hue, self.Sat, self.Value, self.Opacity)
    return self
end
function ColorPicker:Save(tab)
    tab[self.Name] = {
        Hue = self.Hue,
        Sat = self.Sat,
        Value = self.Value,
        Opacity = self.Opacity,
        Rainbow = self.Rainbow
    }
end
function ColorPicker:Load(tab)
    if tab.Rainbow ~= self.Rainbow then
        self:Toggle()
    end
    if self.Hue ~= tab.Hue or self.Sat ~= tab.Sat or self.Value ~= tab.Value or self.Opacity ~= tab.Opacity then
        self:SetValue(tab.Hue, tab.Sat, tab.Value, tab.Opacity)
    end
end
function ColorPicker:SetValue(h, s, v, o)
    self.Hue = h or self.Hue
    self.Sat = s or self.Sat
    self.Value = v or self.Value
    self.Opacity = o or self.Opacity
    self.Preview.BackgroundColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
    self.Preview.BackgroundTransparency = 1 - self.Opacity
    self.SatSlider.Slider.UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
    })
    self.VibSlider.Slider.UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
    })
    self.OpSlider.Slider.UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorDark(self.uipallet.Main, 0.02)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, self.Value))
    })
    if self.Rainbow then
        self.Fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.01, 0.99), 1)
    else
        TweenService:Create(self.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Hue, 0.01, 0.99), 1)
        }):Play()
    end
    if s then
        TweenService:Create(self.SatSlider.Slider.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Sat, 0.01, 0.99), 1)
        }):Play()
    end
    if v then
        TweenService:Create(self.VibSlider.Slider.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Value, 0.01, 0.99), 1)
        }):Play()
    end
    if o then
        TweenService:Create(self.OpSlider.Slider.Fill, self.uipallet.Tween, {
            Size = UDim2.fromScale(math.clamp(self.Opacity, 0.01, 0.99), 1)
        }):Play()
    end
    if self.Callback then
        self.Callback(self.Hue, self.Sat, self.Value, self.Opacity)
    end
end
function ColorPicker:Toggle()
    self.Rainbow = not self.Rainbow
    self.RainbowStroke.Enabled = self.Rainbow
    if self.Rainbow then
        if self.mainapi and self.mainapi.RainbowTable then
            table.insert(self.mainapi.RainbowTable, self)
        end
    else
        if self.mainapi and self.mainapi.RainbowTable then
            local ind = table.find(self.mainapi.RainbowTable, self)
            if ind then
                table.remove(self.mainapi.RainbowTable, ind)
            end
        end
    end
end
return ColorPicker