-- src/gui/components/MultiDropdown.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown

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

-- 【コンストラクタ】
function MultiDropdown.new(parent, nameOrSettings, list, defaultValues, callback, moduleInstance)
    local self = setmetatable({}, MultiDropdown)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        list = optionsettings.List
        defaultValues = optionsettings.Default
        callback = optionsettings.Function
    end

    local active_mainapi = mainapi or (shared.vape and shared.vape.mainapi)
    self.api = moduleInstance or active_mainapi or shared.vape or (shared.VapeMenu)
    self.mainapi = active_mainapi
    local active_uipallet = (uipallet and uipallet.Main) and uipallet or default_uipallet
    self.uipallet = active_uipallet
    local active_color = (color and color.Light and color.Dark) and color or { Light = colorLight, Dark = colorDark }
    local active_tween = (tween and tween.Tween) and tween or nil

    self.Name = name
    self.Type = "MultiDropdown"
    self.List = list or {}
    
    -- 複数選択値の初期化
    self.Value = {}
    for _, opt in ipairs(self.List) do
        self.Value[opt] = false
    end
    
    -- デフォルト選択（配列または辞書テーブルに対応）
    if type(defaultValues) == "table" then
        for k, v in pairs(defaultValues) do
            if type(k) == "number" then
                if table.find(self.List, v) then
                    self.Value[v] = true
                end
            else
                if table.find(self.List, k) then
                    self.Value[k] = v == true
                end
            end
        end
    end

    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.ModuleInstance = moduleInstance

    -- ベースボタン枠（初期の閉じている高さ: 40）
    local dropdown = Instance.new("TextButton")
    dropdown.Name = name .. "MultiDropdownSetting"
    dropdown.Size = UDim2.new(1, 0, 0, 40)
    local parentColor = (parent and parent:IsA("GuiObject")) and parent.BackgroundColor3 or active_uipallet.Main
    dropdown.BackgroundColor3 = optionsettings.Darker and active_color.Dark(parentColor, 0.02) or parentColor
    dropdown.BorderSizePixel = 0
    dropdown.AutoButtonColor = false
    dropdown.Visible = optionsettings.Visible == nil or optionsettings.Visible
    dropdown.Text = ""
    dropdown.Parent = parent

    if addTooltip and (optionsettings.Tooltip or name) then
        addTooltip(dropdown, optionsettings.Tooltip or name)
    end

    -- 背景枠 (BKG) - 余白を 12px に統一
    local bkg = Instance.new("Frame")
    bkg.Name = "BKG"
    bkg.Size = UDim2.new(1, -24, 1, -9)
    bkg.Position = UDim2.fromOffset(12, 4)
    bkg.BackgroundColor3 = active_color.Light(active_uipallet.Main, 0.034)
    bkg.BorderSizePixel = 0
    bkg.Parent = dropdown

    if addCorner then
        addCorner(bkg, UDim.new(0, 6))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = bkg
    end

    -- メイン選択ボタン
    local button = Instance.new("TextButton")
    button.Name = "Dropdown"
    button.Size = UDim2.new(1, -2, 1, -2)
    button.Position = UDim2.fromOffset(1, 1)
    button.BackgroundColor3 = active_uipallet.Main
    button.AutoButtonColor = false
    button.Text = ""
    button.Parent = bkg

    if addCorner then
        addCorner(button, UDim.new(0, 6))
    else
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = button
    end

    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 12)
    buttonPadding.PaddingRight = UDim.new(0, 12)
    buttonPadding.Parent = button

    -- タイトルテキスト
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -30, 0, 29)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
    title.TextSize = 17 
    title.TextTruncate = Enum.TextTruncate.AtEnd
    applyFont(title, active_uipallet.Font)
    title.Parent = button

    -- 開閉矢印アイコン
    local arrow = Instance.new("ImageLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.fromOffset(12, 12)
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, 0, 0, 14)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://10709791437"
    arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
    arrow.ScaleType = Enum.ScaleType.Fit
    arrow.Rotation = 90
    arrow.Parent = button

    self.Object = dropdown
    self.Bkg = bkg
    self.Button = button
    self.Title = title
    self.Arrow = arrow
    self.DropdownChildren = nil

    -- メニュー展開処理
    button.MouseButton1Click:Connect(function()
        if not self.DropdownChildren then
            arrow.Rotation = 270
            local listSize = #self.List
            local expandedHeight = 40 + listSize * 26
            dropdown.Size = UDim2.new(1, 0, 0, expandedHeight)

            local childrenFrame = Instance.new("Frame")
            childrenFrame.Name = "Children"
            childrenFrame.Size = UDim2.new(1, 0, 0, listSize * 26)
            childrenFrame.Position = UDim2.fromOffset(0, 27)
            childrenFrame.BackgroundTransparency = 1
            childrenFrame.Parent = button
            self.DropdownChildren = childrenFrame

            -- 選択肢をすべて生成
            for ind, v in ipairs(self.List) do
                local option = Instance.new("TextButton")
                option.Name = v .. "Option"
                option.Size = UDim2.new(1, 0, 0, 26)
                option.Position = UDim2.fromOffset(0, (ind - 1) * 26)
                option.BackgroundColor3 = active_uipallet.Main
                option.BorderSizePixel = 0
                option.AutoButtonColor = false
                option.Text = "" -- 🌟 ボタン自体のTextは空に
                option.Parent = childrenFrame

                -- 🌟 【変更】UIPaddingの不具合を完全に回避するため、テキストは独立したTextLabelとして内部に配置
                local optionLabel = Instance.new("TextLabel")
                optionLabel.Name = "Label"
                -- 左右にパディング空間（左: 26px, 右: 12px）を空けたサイズに指定
                optionLabel.Size = UDim2.new(1, -38, 1, 0)
                optionLabel.Position = UDim2.fromOffset(26, 0) -- 🌟 確実に26px右へずらして配置
                optionLabel.BackgroundTransparency = 1
                optionLabel.Text = v
                optionLabel.TextXAlignment = Enum.TextXAlignment.Left
                optionLabel.TextSize = 15
                optionLabel.TextTruncate = Enum.TextTruncate.AtEnd
                applyFont(optionLabel, active_uipallet.Font)
                optionLabel.Parent = option

                -- 🌟 【変更】Lucide の正式なチェックマークアイコンを追加
                local checkIcon = Instance.new("ImageLabel")
                checkIcon.Name = "CheckIcon"
                checkIcon.Size = UDim2.fromOffset(12, 12)
                checkIcon.Position = UDim2.new(0, 8, 0.5, 0) -- 左から8px
                checkIcon.AnchorPoint = Vector2.new(0, 0.5)
                checkIcon.BackgroundTransparency = 1
                checkIcon.Image = "rbxassetid://10709790644" -- 🌟 Lucide check icon
                checkIcon.ImageColor3 = active_uipallet.Text
                checkIcon.ScaleType = Enum.ScaleType.Fit
                checkIcon.ZIndex = 6
                checkIcon.Parent = option

                -- 現在選択されているか（チェック状態）のビュー更新関数
                local function updateOptionView()
                    if self.Value[v] then
                        optionLabel.TextColor3 = active_uipallet.Text
                        checkIcon.Visible = true
                    else
                        optionLabel.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
                        checkIcon.Visible = false
                    end
                end
                updateOptionView()

                -- ホバー処理
                local hoverCol = active_color.Light(active_uipallet.Main, 0.02)
                option.MouseEnter:Connect(function()
                    if active_tween then
                        active_tween:Tween(option, active_uipallet.Tween, { BackgroundColor3 = hoverCol })
                    else
                        TweenService:Create(option, active_uipallet.Tween, { BackgroundColor3 = hoverCol }):Play()
                    end
                end)
                option.MouseLeave:Connect(function()
                    if active_tween then
                        active_tween:Tween(option, active_uipallet.Tween, { BackgroundColor3 = active_uipallet.Main })
                    else
                        TweenService:Create(option, active_uipallet.Tween, { BackgroundColor3 = active_uipallet.Main }):Play()
                    end
                end)

                -- 選択トグル動作
                option.MouseButton1Click:Connect(function()
                    self:ToggleValue(v, true)
                    updateOptionView()
                end)
            end
        else
            self:Collapse()
        end

        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end)

    -- 外側の枠ホバー
    local hoverBkgCol = active_color.Light(active_uipallet.Main, 0.0875)
    local normalBkgCol = active_color.Light(active_uipallet.Main, 0.034)
    dropdown.MouseEnter:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverBkgCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = hoverBkgCol }):Play()
        end
    end)
    dropdown.MouseLeave:Connect(function()
        if active_tween then
            active_tween:Tween(bkg, active_uipallet.Tween, { BackgroundColor3 = normalBkgCol })
        else
            TweenService:Create(bkg, active_uipallet.Tween, { BackgroundColor3 = normalBkgCol }):Play()
        end
    end)

    if self.api and self.api.Options then
        self.api.Options[name] = self
    end

    self:UpdateTitleText()

    return self
end

function MultiDropdown:UpdateTitleText()
    local selectedNames = {}
    for _, optName in ipairs(self.List) do
        if self.Value[optName] then
            table.insert(selectedNames, optName)
        end
    end
    local titleText = #selectedNames > 0 and table.concat(selectedNames, ", ") or "None"
    self.Title.Text = self.Name .. " - [" .. titleText .. "]"
end

function MultiDropdown:ToggleValue(val, mouse)
    if self.Value[val] ~= nil then
        self.Value[val] = not self.Value[val]
        self:UpdateTitleText()
        if self.Callback then
            self.Callback(self.Value, mouse)
        end
    end
end

function MultiDropdown:Collapse()
    if self.DropdownChildren then
        self.Arrow.Rotation = 90
        self.DropdownChildren:Destroy()
        self.DropdownChildren = nil
        self.Object.Size = UDim2.new(1, 0, 0, 40)

        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end
end

function MultiDropdown:Save(tab)
    tab[self.Name] = {Value = self.Value}
end

function MultiDropdown:Load(tab)
    if tab and self.Value ~= tab.Value then
        self.Value = tab.Value
        self:UpdateTitleText()
    end
end

return MultiDropdown