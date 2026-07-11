-- src/gui/components/Dropdown.lua
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Dropdown = {}
Dropdown.__index = Dropdown

local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = Color3.fromRGB(200, 200, 200),
    Font  = Enum.Font.SourceSans,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- 🌟 修正：正しいEnum指定に修正
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
    self.ModuleInstance = moduleInstance

    -- 接続イベント安全管理用
    self.OutsideClickConnection = nil

    -- 汎用アニメーション（Tween）ラッパー
    local function tweenProperty(instance, properties)
        if active_tween then
            active_tween:Tween(instance, active_uipallet.Tween, properties)
        else
            TweenService:Create(instance, active_uipallet.Tween, properties):Play()
        end
    end

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
    dropdown.ClipsDescendants = true -- スライド時に中身がはみ出ないようにクリップ
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
    bkg.ClipsDescendants = true
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
    button.ClipsDescendants = true
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

    -- 領域外イベント用クリーンアップ関数
    local function disconnectOutsideClick()
        if self.OutsideClickConnection then
            self.OutsideClickConnection:Disconnect()
            self.OutsideClickConnection = nil
        end
    end

    -- 展開・閉縮ロジック
    button.MouseButton1Click:Connect(function()
        if not self.DropdownChildren then
            tweenProperty(arrow, { Rotation = 270 })
            
            -- アイテム数に応じたスクロール切り替えロジック
            local listSize = #self.List
            local maxVisibleItems = 6 -- 一度に表示する最大オプション数
            local optionHeight = 26
            local useScroll = listSize > maxVisibleItems
            
            local childrenHeight = useScroll and (maxVisibleItems * optionHeight) or (listSize * optionHeight)
            local expandedHeight = 40 + childrenHeight

            -- コンテナ生成 (Frame または ScrollingFrame)
            local childrenFrame
            if useScroll then
                childrenFrame = Instance.new("ScrollingFrame")
                childrenFrame.Size = UDim2.new(1, 0, 0, childrenHeight)
                childrenFrame.CanvasSize = UDim2.new(0, 0, 0, listSize * optionHeight)
                childrenFrame.ScrollBarThickness = 3
                childrenFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
                childrenFrame.BorderSizePixel = 0
                childrenFrame.Active = true
            else
                childrenFrame = Instance.new("Frame")
                childrenFrame.Size = UDim2.new(1, 0, 0, childrenHeight)
            end
            
            childrenFrame.Name = "Children"
            childrenFrame.Position = UDim2.fromOffset(0, 27)
            childrenFrame.BackgroundTransparency = 1
            childrenFrame.Parent = button
            self.DropdownChildren = childrenFrame

            -- UIListLayout による整列
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = childrenFrame

            local ind = 0
            for _, v in ipairs(self.List) do
                local option = Instance.new("TextButton")
                option.Name = v .. "Option"
                option.Size = UDim2.new(1, 0, 0, optionHeight)
                option.LayoutOrder = ind
                option.BackgroundColor3 = active_uipallet.Main
                option.BorderSizePixel = 0
                option.AutoButtonColor = false
                option.Text = v
                option.TextXAlignment = Enum.TextXAlignment.Left
                
                -- アクティブアイテムの色強調
                if v == self.Value then
                    option.TextColor3 = active_uipallet.Text
                else
                    option.TextColor3 = active_color.Dark(active_uipallet.Text, 0.16)
                end
                
                option.TextSize = 15 
                option.TextTruncate = Enum.TextTruncate.AtEnd
                applyFont(option, active_uipallet.Font)
                option.Parent = childrenFrame

                local optionPadding = Instance.new("UIPadding")
                optionPadding.PaddingLeft = UDim.new(0, 12)
                optionPadding.PaddingRight = UDim.new(0, 12)
                optionPadding.Parent = option

                -- オプションのホバー処理
                local hoverCol = active_color.Light(active_uipallet.Main, 0.02)
                option.MouseEnter:Connect(function()
                    tweenProperty(option, { BackgroundColor3 = hoverCol })
                end)
                option.MouseLeave:Connect(function()
                    tweenProperty(option, { BackgroundColor3 = active_uipallet.Main })
                end)

                -- 選択クリック時
                option.MouseButton1Click:Connect(function()
                    self:SetValue(v, true)
                end)

                ind = ind + 1
            end

            -- サイズの展開アニメーション
            tweenProperty(dropdown, { Size = UDim2.new(1, 0, 0, expandedHeight) })

            -- 外側クリック時の閉じ処理バインド
            disconnectOutsideClick()
            self.OutsideClickConnection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mousePos = UserInputService:GetMouseLocation()
                    local absPos = dropdown.AbsolutePosition
                    
                    local x1, y1 = absPos.X, absPos.Y
                    local x2, y2 = x1 + dropdown.AbsoluteSize.X, y1 + dropdown.AbsoluteSize.Y
                    
                    local isInside = mousePos.X >= x1 and mousePos.X <= x2 and mousePos.Y >= y1 and mousePos.Y <= y2
                    if not isInside then
                        self:SetValue(self.Value, false)
                    end
                end
            end)
        else
            self:SetValue(self.Value, true)
        end

        -- 親メニュー全体のレイアウト高さを追従更新
        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end)

    -- 外側の枠ホバー
    local hoverBkgCol = active_color.Light(active_uipallet.Main, 0.0875)
    local normalBkgCol = active_color.Light(active_uipallet.Main, 0.034)
    dropdown.MouseEnter:Connect(function()
        tweenProperty(bkg, { BackgroundColor3 = hoverBkgCol })
    end)
    dropdown.MouseLeave:Connect(function()
        tweenProperty(bkg, { BackgroundColor3 = normalBkgCol })
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

    -- 展開されていた場合はスムーズに閉じる
    if self.DropdownChildren then
        -- 外側クリック検知イベントの安全解除
        if self.OutsideClickConnection then
            self.OutsideClickConnection:Disconnect()
            self.OutsideClickConnection = nil
        end

        tweenProperty(self.Arrow, { Rotation = 90 })
        self.DropdownChildren:Destroy()
        self.DropdownChildren = nil
        
        -- クローズアニメーションの再生
        tweenProperty(self.Object, { Size = UDim2.new(1, 0, 0, 40) })

        -- 閉じたことを即座に親ウィンドウに通知してリサイズ
        if self.ModuleInstance and self.ModuleInstance._refreshOptionsHeight then
            self.ModuleInstance:_refreshOptionsHeight()
        end
    end

    if self.Callback then
        self.Callback(self.Value, mouse)
    end
end

-- デストラクター（メモリ解放用）
function Dropdown:Destroy()
    if self.OutsideClickConnection then
        self.OutsideClickConnection:Disconnect()
        self.OutsideClickConnection = nil
    end
    if self.Object then
        self.Object:Destroy()
    end
    self.Object = nil
    self.Bkg = nil
    self.Button = nil
    self.Title = nil
    self.Arrow = nil
    self.DropdownChildren = nil
end

return Dropdown