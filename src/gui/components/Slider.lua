-- src/gui/components/Slider.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Slider = {}
Slider.__index = Slider

-- 🌟 パレットを 200 の落ち着いたグレーに戻しました
local default_uipallet = {
    Main = Color3.fromRGB(26, 25, 26),
    Text = Color3.fromRGB(200, 200, 200), 
    Font = Enum.Font.SourceSans, 
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

-- フォントの型（Font / EnumItem）を判別して安全に適用するヘルパー関数
local function applyFont(instance, font)
    if typeof(font) == "Font" then
        instance.FontFace = font
    elseif typeof(font) == "EnumItem" then
        instance.Font = font
    else
        pcall(function() instance.FontFace = font end)
    end
end

-- 【コンストラクタ】
function Slider.new(parent, nameOrSettings, minLimit, maxLimit, defaultValue, step, suffix, callback, assets, api)
    local self = setmetatable({}, Slider)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        minLimit = optionsettings.Min
        maxLimit = optionsettings.Max
        defaultValue = optionsettings.Default
        step = optionsettings.Step
        suffix = optionsettings.Suffix
        callback = optionsettings.Function
    end

    -- グローバルおよびAPI解決
    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = api or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet

    self.Name = name
    self.Type = "Slider"
    self.MinLimit = minLimit or 0
    self.MaxLimit = maxLimit or 10
    self.Step = step or 1
    self.Decimal = optionsettings.Decimal or (self.Step < 1 and 10 or 1)
    self.Suffix = suffix or ""
    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0

    self.Value = math.clamp(defaultValue or minLimit or 0, self.MinLimit, self.MaxLimit)

    -- ────────────── GUI要素構築 ──────────────
    local slider = Instance.new("Frame")
    slider.Name = name .. "SliderSetting"
    slider.Size = UDim2.new(1, 0, 0, 50) 
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    slider.BackgroundColor3 = optionsettings.Darker and colorDark(parentColor, 0.02) or parentColor
    slider.BorderSizePixel = 0
    slider.Parent = parent

    -- ツールチップの追加
    if addTooltip and optionsettings.Tooltip then
        addTooltip(slider, optionsettings.Tooltip)
    end

    -- タイトルラベル
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromOffset(150, 30)
    title.Position = UDim2.fromOffset(12, 2)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 常に落ち着いた暗い色
    title.TextSize = 17 
    applyFont(title, active_uipallet.Font) 
    title.Parent = slider

    -- 値表示ボタン
    local valuebutton = Instance.new("TextButton")
    valuebutton.Name = "Value"
    valuebutton.Size = UDim2.fromOffset(80, 20)
    valuebutton.Position = UDim2.new(1, -92, 0, 7)
    valuebutton.BackgroundTransparency = 1
    valuebutton.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 常に落ち着いた暗い色
    valuebutton.TextSize = 17 
    applyFont(valuebutton, active_uipallet.Font) 
    valuebutton.TextXAlignment = Enum.TextXAlignment.Right
    valuebutton.Parent = slider

    -- 直接入力用 TextBox
    local valuebox = Instance.new("TextBox")
    valuebox.Name = "Box"
    valuebox.Size = valuebutton.Size
    valuebox.Position = valuebutton.Position
    valuebox.BackgroundTransparency = 1
    valuebox.Visible = false
    valuebox.TextColor3 = colorDark(active_uipallet.Text, 0.16) -- 常に落ち着いた暗い色
    valuebox.TextSize = 17 
    applyFont(valuebox, active_uipallet.Font) 
    valuebox.TextXAlignment = Enum.TextXAlignment.Right
    valuebox.ClearTextOnFocus = false
    valuebox.Parent = slider

    -- ────────────── TRACK ──────────────
    local track = Instance.new("TextButton")
    track.Name = "Track"
    track.Size = UDim2.new(1, -24, 0, 20)
    track.Position = UDim2.new(0.5, 0, 0, 37) 
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.BackgroundTransparency = 1
    track.Text = ""
    track.ZIndex = 4
    track.Parent = slider

    -- トラック背景線（極細 2px）
    local bkg = Instance.new("Frame")
    bkg.Name = "Slider"
    bkg.Size = UDim2.new(1, 0, 0, 2)
    bkg.Position = UDim2.new(0, 0, 0.5, -1)
    bkg.BackgroundColor3 = colorLight(active_uipallet.Main, 0.034)
    bkg.BorderSizePixel = 0
    bkg.ZIndex = 5
    bkg.Parent = track

    -- 選択範囲の緑塗り
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 0, 2)
    fill.Position = UDim2.new(0, 0, 0.5, -1)
    
    local guiCol = active_mainapi and active_mainapi.GUIColor
    local initCol = guiCol and Color3.fromHSV(guiCol.Hue, guiCol.Sat, guiCol.Value) or Color3.fromRGB(0, 204, 136)
    fill.BackgroundColor3 = initCol
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = track

    -- ハンドル
    local handle = Instance.new("TextButton")
    handle.Name = "Handle"
    handle.Size = UDim2.fromOffset(30, 30)
    handle.Position = UDim2.new(0, 0, 0.5, 0)
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.BackgroundTransparency = 1
    handle.Text = ""
    handle.ZIndex = 7
    handle.Parent = track

    -- 丸型ノブ (14x14)
    local knob = Instance.new("Frame")
    knob.Name = "KnobCircle"
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.new(0.5, 0, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = initCol
    knob.BorderSizePixel = 0
    knob.ZIndex = 8
    knob.Parent = handle

    if addCorner then
        addCorner(knob, UDim.new(1, 0))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = knob
    end

    self.Object = slider
    self.Track = track
    self.Bkg = bkg
    self.Fill = fill
    self.Handle = handle
    self.Knob = knob
    self.ValueButton = valuebutton
    self.ValueBox = valuebox

    -- 内部処理ヘルパー
    local function formatValue(val)
        local decimals = 0
        local stepStr = tostring(self.Step)
        local dotIdx = stepStr:find("%.")
        if dotIdx then
            decimals = #stepStr - dotIdx
        end
        return string.format("%." .. decimals .. "f", val)
    end

    local function getPercentFromValue(val)
        return (val - self.MinLimit) / (self.MaxLimit - self.MinLimit)
    end

    local function getValueFromPercent(pct)
        local val = self.MinLimit + (self.MaxLimit - self.MinLimit) * pct
        return math.clamp(math.round(val / self.Step) * self.Step, self.MinLimit, self.MaxLimit)
    end

    local currentPct = getPercentFromValue(self.Value)

    -- ドラッグ用のスムーズTween設定（吸いつくような操作感にするための短めの時間）
    local dragTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    -- UI同期
    local function updateUI(animate)
        local handlePos = UDim2.new(currentPct, 0, 0.5, 0)
        local fillSize = UDim2.new(currentPct, 0, 0, 2)

        if animate then
            TweenService:Create(handle, active_uipallet.Tween, {Position = handlePos}):Play()
            TweenService:Create(fill,   active_uipallet.Tween, {Size     = fillSize}):Play()
            TweenService:Create(knob,   active_uipallet.Tween, {Size     = UDim2.fromOffset(14, 14)}):Play()
        else
            -- ドラッグ中も滑らかに移動させるため、短いTweenを適用します
            TweenService:Create(handle, dragTweenInfo, {Position = handlePos}):Play()
            TweenService:Create(fill,   dragTweenInfo, {Size     = fillSize}):Play()
        end

        local suffixText = ""
        if self.Suffix ~= "" then
            if type(self.Suffix) == "function" then
                suffixText = " " .. self.Suffix(self.Value)
            else
                suffixText = " " .. self.Suffix
            end
        end
        valuebutton.Text = formatValue(self.Value) .. suffixText
    end

    updateUI(false)

    -- ドラッグ処理
    local connection = nil
    local dragging = false

    local function startDrag()
        dragging = true
        if connection then connection:Disconnect() end

        connection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local mouseX = input.Position.X
                local trackPos = track.AbsolutePosition
                local trackSz = track.AbsoluteSize

                local pct = math.clamp((mouseX - trackPos.X) / trackSz.X, 0, 1)
                self.Value = getValueFromPercent(pct)
                currentPct = getPercentFromValue(self.Value)
                updateUI(false)
                
                if self.Callback then
                    task.spawn(self.Callback, self.Value, false)
                end
            end
        end)
    end

    local function stopDrag()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if dragging then
            dragging = false
            updateUI(true)
            if self.Callback then
                task.spawn(self.Callback, self.Value, true)
            end
        end
    end

    -- ホバー時に丸ノブを微拡大 (14x14 → 16x16)
    handle.MouseEnter:Connect(function()
        TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(16, 16)}):Play()
    end)
    handle.MouseLeave:Connect(function()
        if not dragging then
            TweenService:Create(knob, active_uipallet.Tween, {Size = UDim2.fromOffset(14, 14)}):Play()
        end
    end)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            startDrag()
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local mouseX = input.Position.X
            local trackPos = track.AbsolutePosition
            local trackSz = track.AbsoluteSize

            local pct = math.clamp((mouseX - trackPos.X) / trackSz.X, 0, 1)
            self.Value = getValueFromPercent(pct)
            currentPct = getPercentFromValue(self.Value)
            updateUI(true) -- トラッククリック時は滑らかに位置移動させるため true に変更
            startDrag()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            stopDrag()
        end
    end)

    valuebutton.MouseButton1Click:Connect(function()
        valuebutton.Visible = false
        valuebox.Visible = true
        valuebox.Text = tostring(self.Value)
        valuebox:CaptureFocus()
    end)

    -- 🌟 【アップグレード①】入力中のテキスト変更を検知して、リアルタイムにメーターとツマミを追従して動かす
    valuebox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(valuebox.Text)
        if num then
            local clamped = math.clamp(num, self.MinLimit, self.MaxLimit)
            currentPct = getPercentFromValue(clamped)
            -- プレビューとしてメーター位置を動的に更新（第3引数を false にして確定フラグはまだ送らない）
            updateUI(false)
            if self.Callback then
                task.spawn(self.Callback, clamped, false)
            end
        end
    end)

    -- 🌟 【アップグレード②】入力窓が閉じられた時（Enterキー、または別の場所をクリックして閉じた時どちらでも）に確定して保存
    valuebox.FocusLost:Connect(function(enter)
        valuebutton.Visible = true
        valuebox.Visible = false
        
        local num = tonumber(valuebox.Text)
        if num then
            self:SetValue(num, nil, true) -- 第3引数を true にして確定処理
        else
            -- 無効なテキストが入力された場合は、元の数値表示へ戻す
            updateUI(false)
        end
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    return self
end

-- ────────────── 公開メソッド（本家必須 of API） ──────────────

function Slider:SetValue(value, pos, final)
    if tonumber(value) == math.huge or value ~= value then return end

    local check = self.Value ~= value
    self.Value = math.clamp(
        math.round(value / self.Step) * self.Step,
        self.MinLimit,
        self.MaxLimit
    )

    local pct = pos or (self.Value - self.MinLimit) / (self.MaxLimit - self.MinLimit)
    currentPct = pct

    TweenService:Create(self.Handle, self.uipallet.Tween, {
        Position = UDim2.new(math.clamp(pct, 0, 1), 0, 0.5, 0)
    }):Play()
    TweenService:Create(self.Fill, self.uipallet.Tween, {
        Size = UDim2.new(math.clamp(pct, 0, 1), 0, 0, 2)
    }):Play()

    local decimals = 0
    local stepStr = tostring(self.Step)
    local dotIdx = stepStr:find("%.")
    if dotIdx then
        decimals = #stepStr - dotIdx
    end
    local formattedVal = string.format("%." .. decimals .. "f", self.Value)

    local suffixText = ""
    if self.Suffix ~= "" then
        if type(self.Suffix) == "function" then
            suffixText = " " .. self.Suffix(self.Value)
        else
            suffixText = " " .. self.Suffix
        end
    end
    self.ValueButton.Text = formattedVal .. suffixText

    if check or final then
        self.Callback(self.Value, final)
    end
end

function Slider:Save(tab)
    tab[self.Name] = {
        Value = self.Value,
        Max = self.MaxLimit
    }
end

function Slider:Load(tab)
    local newval = (tab.Value == tab.Max and tab.Max ~= self.MaxLimit) and self.MaxLimit or tab.Value
    if self.Value ~= newval then
        self:SetValue(newval, nil, true)
    end
end

function Slider:Color(hue, sat, val, rainbowcheck)
    local col
    if rainbowcheck and self.mainapi and self.mainapi.Color then
        col = Color3.fromHSV(self.mainapi:Color((hue - (self.Index * 0.075)) % 1))
    else
        col = Color3.fromHSV(hue, sat, val)
    end
    -- 🌟 色の変更時も瞬時ではなく、パレットの Tween に従い滑らかに色が補間されます
    TweenService:Create(self.Fill, self.uipallet.Tween, {BackgroundColor3 = col}):Play()
    TweenService:Create(self.Knob, self.uipallet.Tween, {BackgroundColor3 = col}):Play()
end

return Slider