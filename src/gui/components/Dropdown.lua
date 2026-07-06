-- src/gui/components/Dropdown.lua
local TweenService = game:GetService("TweenService")

local Dropdown = {}
Dropdown.__index = Dropdown

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
function Dropdown.new(parent, nameOrSettings, list, defaultValue, callback, moduleInstance)
    local self = setmetatable({}, Dropdown)

    local name = nameOrSettings
    local optionsettings = {}
    if type(nameOrSettings) == "table" then
        optionsettings = nameOrSettings
        name = optionsettings.Name
        list = optionsettings.List
        defaultValue = optionsettings.Default
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
    self.Type = "Dropdown"
    self.List = list or {}
    self.Value = table.find(self.List, defaultValue) and defaultValue or self.List[1] or "None"
    self.Callback = callback or function() end
    self.Index = (self.api and self.api.Options) and getTableSize(self.api.Options) or 0
    self.ModuleInstance = moduleInstance -- 親のモジュールオブジェクト

    -- ベースボタン枠（初期の閉じている高さ: 40）
    local dropdown = Instance.new("TextButton")
    dropdown.Name = name .. "DropdownSetting"
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
    -- 縦サイズを固定（31）から、親フレームの伸縮（1, -9）に自動追従するようレスポンシブ化
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

    -- 【内側パディングの自動解決】
    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 12)
    buttonPadding.PaddingRight = UDim.new(0, 12)
    buttonPadding.Parent = button

    -- タイトルテキスト
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -30, 0, 29) -- 縦幅はタイトル行の29pxに固定
    title.BackgroundTransparency = 1
    title.Text = name .. " - " .. self.Value
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

    -- 展開・閉縮ロジック
    button.MouseButton1Click:Connect(function()
        if not self.DropdownChildren then
            arrow.Rotation = 270
            
            -- 🌟 【修正】選択肢をリストから除外せずすべて表示するため、高さのマイナス1補正を削除
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

            local ind = 0
            for _, v in ipairs(self.List) do
                -- 🌟 【修正】v ~= self.Value による除外を無くし、すべてのボタンを生成します
                local option = Instance.new("TextButton")
                option.Name = v .. "Option"
                option.Size = UDim2.new(1, 0, 0, 26)
                option.Position = UDim2.fromOffset(0, ind * 26)
                option.BackgroundColor3 = active_uipallet.Main
                option.BorderSizePixel = 0
                option.AutoButtonColor = false
                option.Text = v
                option.TextXAlignment = Enum.TextXAlignment.Left
                
                -- 🌟 現在選ばれている項目は文字色を明るく（アクティブ化）し、それ以外は元の暗い色にします
                if v == self.Value then
                    option.TextColor3 = active_uipallet.Text
                else
                    option.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
                end
                
                option.TextSize = 15 
                option.TextTruncate = Enum.TextTruncate.AtEnd
                applyFont(option, active_uipallet.Font)
                option.Parent = childrenFrame

                -- 各オプションの左インデントをシステム統一
                local optionPadding = Instance.new("UIPadding")
                optionPadding.PaddingLeft = UDim.new(0, 12)
                optionPadding.PaddingRight = UDim.new(0, 12)
                optionPadding.Parent = option

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

                -- 選択クリック時
                option.MouseButton1Click:Connect(function()
                    self:SetValue(v, true)
                end)

                ind = ind + 1
            end
        else
            self:SetValue(self.Value, true)
        end

        -- 親メニュー全体の高さを連動して再更新
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

    return self
end

function Dropdown:Save(tab)
    tab[self.Name] = {Value = self.Value}
end

function Dropdown:Load(tab)
    if self.Value ~= tab.Value then
        self:SetValue(tab.Value)
    end
end

function Dropdown:Change(list)
    self.List = list or {}
    if not table.find(self.List, self.Value) then
        self:SetValue(self.Value)
    end
end

function Dropdown:SetValue(val, mouse)
    self.Value = table.find(self.List, val) and val or self.List[1] or "None"
    self.Title.Text = self.Name .. " - " .. self.Value

    -- 展開されていた場合は閉じる
    if self.DropdownChildren then
        self.Arrow.Rotation = 90
        self.DropdownChildren:Destroy()
        self.DropdownChildren = nil
        self.Object.Size = UDim2.new(1, 0, 0, 40)

        -- 閉じたことを親ウィンドウに通知してリサイズ
        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end

    if self.Callback then
        self.Callback(self.Value, mouse)
    end
end

return Dropdown