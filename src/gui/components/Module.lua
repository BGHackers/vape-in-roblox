-- src/gui/components/Module.lua
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ── 🌟【自動登録用コンポーネントリスト】 ──
-- 新しいコンポーネント（TextBoxなど）を追加したい場合は、ここに1行 require を
-- 追加するだけで、自動的に Module:Create[コンポーネント名](...) が使用可能になります。
-- src/gui/components/Module.lua

-- src/gui/components/Module.lua

-- src/gui/components/Module.lua

-- src/gui/components/Module.lua
-- src/gui/components/Module.lua
-- src/gui/components/Module.lua

-- src/gui/components/Module.lua

local components = {
    Toggle        = require("gui.components.Toggle"),
    Slider        = require("gui.components.Slider"),
    TextBox       = require("gui.components.TextBox"),
    Button        = require("gui.components.Button"),
    ColorPicker   = require("gui.components.ColorPicker"),
    Dropdown      = require("gui.components.Dropdown"),
    MultiDropdown = require("gui.components.MultiDropdown"),
    Section       = require("gui.components.Section"),
}
local Module = {}

-- src/gui/components/Module.lua の 15行目付近（一括生成ループ箇所）

-- ── 🌟 【動的バインディング】components内のコンポーネントからCreateメソッドを自動一括生成 ──
for compName, compClass in pairs(components) do
    local methodName = "Create" .. compName
    Module[methodName] = function(self, ...)
        -- 🌟 引数リストの末尾に、親モジュールである self を安全に挿入して渡します
        local args = {...}
        table.insert(args, self)
        
        -- parent（self.OptionsFrame）を第1引数にしてコンポーネントを生成
        local res = compClass.new(self.OptionsFrame, unpack(args))
        
        -- 生成されたオブジェクトをOptionsテーブルに自動で登録
        local optionName = (res.Name) or (res.Object and res.Object.Name) or compName
        self.Options[optionName] = res
        
        -- 高さの自動更新
        self:_refreshOptionsHeight()
        return res
    end
end

-- クラス定義のメタテーブルを紐付け
Module.__index = Module

local DEBUG_ENABLED = true
local function debugPrint(...)
    if DEBUG_ENABLED then print("[Module]", ...) end
end

-- ── Visual constants ────────────────────────────────────────────────────────
local TWEEN_INFO   = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FONT_SEMI    = Enum.Font.SourceSansSemibold
local FONT_BOLD    = Enum.Font.SourceSansBold

-- Text
local COL_TEXT_OFF    = Color3.fromRGB(130, 130, 130)
local COL_TEXT_HOVER  = Color3.fromRGB(210, 210, 210)
local COL_TEXT_ON     = Color3.fromRGB(255, 255, 255)

-- Icon
local COL_ICON_OFF    = Color3.fromRGB(95,  95,  95)
local COL_ICON_HOVER  = Color3.fromRGB(170, 170, 170)
local COL_ICON_ON     = Color3.fromRGB(200, 200, 200)

-- Backgrounds
local COL_HOVER_BG    = Color3.fromRGB(255, 255, 255)
local COL_ACTIVE_BG   = Color3.fromRGB(16,  133, 96)

-- Fallback palette
local default_uipallet = {
    Main  = Color3.fromRGB(26, 25, 26),
    Text  = COL_TEXT_OFF,
    Font  = FONT_SEMI,
    Tween = TWEEN_INFO,
}

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function addMaid(obj)
    obj.Connections = {}
    function obj:Clean(cb)
        if typeof(cb) == "Instance" then
            table.insert(self.Connections, { Disconnect = function()
                cb:ClearAllChildren(); cb:Destroy()
            end })
        elseif type(cb) == "function" then
            table.insert(self.Connections, { Disconnect = cb })
        else
            table.insert(self.Connections, cb)
        end
    end
end

local function getTableSize(t)
    local n = 0
    if type(t) == "table" then for _ in pairs(t) do n = n + 1 end end
    return n
end

local function getAsset(self, path, default)
    if self.getcustomasset then
        local ok, res = pcall(self.getcustomasset, path)
        if ok and res and res ~= "" then return res end
    end
    return default
end

local function colorLight(c, n) local h,s,v = c:ToHSV(); return Color3.fromHSV(h,s,math.clamp(v+n,0,1)) end
local function colorDark (c, n) local h,s,v = c:ToHSV(); return Color3.fromHSV(h,s,math.clamp(v-n,0,1)) end

-- アコーディオンの展開高さをコンテンツぴったりに合わせるため、不要な余白 (+ 24) を削除
local function calcOptionsHeight(frame, layout)
    local h = layout.AbsoluteContentSize.Y
    if h > 0 then return h end
    local total, cnt = 0, 0
    for _, ch in ipairs(frame:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextButton") then
            total = total + ch.AbsoluteSize.Y; cnt = cnt + 1
        end
    end
    return total + math.max(cnt-1,0)*4
end

-- Toggle専用：文字サイズを16に拡大し、Y座標のズレを防ぐために自動で中央揃えに矯正するヘルパー
local function adjustComponentTextSize(s)
    local function traverse(instance)
        if instance:IsA("TextLabel") or instance:IsA("TextButton") then
            if instance.TextSize < 16 then
                instance.TextSize = 16
            end
        end
        -- 小さなボタンや画像フレームを親コンテナに対して垂直中央揃え（AnchorPoint.Y=0.5, Position.Y=0.5）にする
        if instance:IsA("Frame") or instance:IsA("TextButton") or instance:IsA("ImageLabel") then
            if instance.Size.Y.Offset > 0 and instance.Size.Y.Offset < 30 then
                instance.AnchorPoint = Vector2.new(instance.AnchorPoint.X, 0.5)
                instance.Position = UDim2.new(instance.Position.X.Scale, instance.Position.X.Offset, 0.5, 0)
            end
        end
        for _, child in ipairs(instance:GetChildren()) do
            traverse(child)
        end
    end

    if s then
        if typeof(s) == "table" then
            if s.Object then traverse(s.Object) end
            if s.Label then traverse(s.Label) end
            if s.Frame then traverse(s.Frame) end
        elseif typeof(s) == "Instance" then
            traverse(s)
        end
    end
end

-- ── Constructor ─────────────────────────────────────────────────────────────
function Module.new(parent, nameOrSettings, callback, assets, api)
    local self = setmetatable({}, Module)

    local name, modulesettings = nameOrSettings, {}
    if type(nameOrSettings) == "table" then
        modulesettings = nameOrSettings
        name     = modulesettings.Name
        callback = modulesettings.Function
    end
    debugPrint("new:", name)

    -- Resolve globals
    local mapi   = api or mainapi or (shared.vape) or (shared.VapeMenu)
    local libs   = mapi and mapi.Libraries
    local pal    = (libs and libs.uipallet) or (uipallet and uipallet.Main and uipallet) or default_uipallet
    local col    = (libs and libs.color) or { Light = colorLight, Dark = colorDark }
    local tw     = (libs and libs.tween) or nil
    local gfs    = (libs and libs.getfontsize) or getfontsize
    local gca    = (libs and libs.getcustomasset) or getcustomasset

    self.api            = mapi
    self.mainapi        = mapi
    self.uipallet       = pal
    self.color          = col
    self.tween          = tw
    self.getfontsize    = gfs
    self.getcustomasset = gca
    self.Assets         = type(assets) == "table" and assets or {}
    self.Type           = "Module"
    self.Enabled        = false
    self.Options        = {}
    self.Bind           = {}
    self.Connections    = {}
    self.Index          = (mapi and mapi.Modules) and getTableSize(mapi.Modules) or 0
    self.ExtraText      = modulesettings.ExtraText
    self.Name           = name
    self.Category       = (parent and parent.Parent) and parent.Parent.Name:gsub("Category$","") or ""
    self.Starred        = false
    self.Callback       = callback or function() end
    self.IsBinding      = false
    self.OptionsExpanded = false

    -- ── 親コンテナ強制密着ロジック ──
    -- リスト親フレームおよびスクロール親フレームをウィンドウのフチに完全に密着させ、1pxの切り取り余白を排除します。
    task.spawn(function()
        if parent then
            -- 直接の親（モジュールを格納しているFrame）の余白をリセットして左右に伸ばす
            if parent:IsA("Frame") or parent:IsA("ScrollingFrame") then
                parent.Size = UDim2.new(1, 0, parent.Size.Y.Scale, parent.Size.Y.Offset)
                parent.Position = UDim2.new(0, 0, parent.Position.Y.Scale, parent.Position.Y.Offset)
            end
            -- スクロール機能を提供するScrollingFrame先祖を探し、その横幅と位置を強制フラッシュする
            local scrollParent = parent:IsA("ScrollingFrame") and parent or parent:FindFirstAncestorWhichIsA("ScrollingFrame")
            if scrollParent then
                scrollParent.Size = UDim2.new(1, 0, scrollParent.Size.Y.Scale, scrollParent.Size.Y.Offset)
                scrollParent.Position = UDim2.new(0, 0, scrollParent.Position.Y.Scale, scrollParent.Position.Y.Offset)
            end
        end
    end)

    -- Outer wrapper (親コンテナ自体がフチに密着したため、Scale = 1 で完全にフチに揃います)
    local moduleFrame = Instance.new("Frame")
    moduleFrame.Name              = name .. "Frame"
    moduleFrame.Size              = UDim2.new(1, 0, 0, 44)
    moduleFrame.BackgroundTransparency = 1
    moduleFrame.BorderSizePixel   = 0
    moduleFrame.Parent            = parent

    -- Root button
    local button = Instance.new("TextButton")
    button.Name               = name
    button.Size               = UDim2.new(1, 0, 0, 44)
    button.BackgroundTransparency = 1
    button.BorderSizePixel    = 0
    button.Text               = ""
    button.AutoButtonColor    = false
    button.ZIndex             = 4
    button.Parent             = moduleFrame

    -- Hover background
    local hoverBg = Instance.new("Frame")
    hoverBg.Name                  = "HoverBg"
    hoverBg.Position              = UDim2.new(0, 0, 0, 0)
    hoverBg.Size                  = UDim2.new(1, 0, 1, -1)
    hoverBg.BackgroundColor3      = COL_HOVER_BG
    hoverBg.BackgroundTransparency = 1
    hoverBg.BorderSizePixel       = 0
    hoverBg.ZIndex                = 2
    hoverBg.Parent                = button

    -- Active background
    local activeBg = Instance.new("Frame")
    activeBg.Name                  = "ActiveBg"
    activeBg.Position              = UDim2.new(0, 0, 0, 0)
    activeBg.Size                  = UDim2.new(1, 0, 1, -1)
    activeBg.BackgroundColor3      = COL_ACTIVE_BG
    activeBg.BackgroundTransparency = 1
    activeBg.BorderSizePixel       = 0
    activeBg.ZIndex                = 3
    activeBg.Parent                = button

    -- Gradient
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Enabled  = false
    gradient.Parent   = activeBg

    -- Divider line (モジュール間の境界線。ON/OFF問わず常に表示)
    local divider = Instance.new("Frame")
    divider.Name             = "Divider"
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.Position         = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    divider.BorderSizePixel  = 0
    divider.Visible          = true -- 常に表示
    divider.ZIndex           = 4
    divider.Parent             = button

    -- Module name label (位置12px)
    local label = Instance.new("TextLabel")
    label.Name               = "Label"
    label.Size               = UDim2.new(1, -90, 1, 0)
    label.Position           = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text               = name
    label.TextColor3         = COL_TEXT_OFF
    label.TextSize           = 16
    label.TextXAlignment     = Enum.TextXAlignment.Left
    label.ZIndex             = 5
    local ok = pcall(function() label.FontFace = pal.Font end)
    if not ok then label.Font = FONT_SEMI end
    label.Parent = button

    -- Small dot (Safe hide to match original layout)
    local colorDotFrame = Instance.new("Frame")
    colorDotFrame.Name               = "ColorDot"
    colorDotFrame.Size               = UDim2.fromOffset(0, 0)
    colorDotFrame.Visible            = false
    colorDotFrame.BackgroundColor3   = Color3.fromRGB(16, 133, 96)
    colorDotFrame.BackgroundTransparency = 1
    colorDotFrame.BorderSizePixel    = 0
    colorDotFrame.ZIndex             = 5
    colorDotFrame.Parent             = button

    -- ⋮ option expand button (垂直中央 0.5,0 / 高さ 18px / 右端 -8px)
    local optionBtn = Instance.new("TextButton")
    optionBtn.Name               = "Dots"
    optionBtn.Size               = UDim2.fromOffset(12, 18)
    optionBtn.AnchorPoint        = Vector2.new(1, 0.5)
    optionBtn.Position           = UDim2.new(1, -8, 0.5, 0)
    optionBtn.BackgroundTransparency = 1
    optionBtn.Text               = ""
    optionBtn.ZIndex             = 5
    optionBtn.Parent             = button

    local optionIcon = Instance.new("ImageLabel")
    optionIcon.Name              = "DotsIcon"
    optionIcon.Size              = UDim2.fromOffset(14, 14)
    optionIcon.AnchorPoint       = Vector2.new(0.5, 0.5)
    optionIcon.Position          = UDim2.new(0.5, 0, 0.5, -1) -- アセットの余白を考慮し、1px上に補正
    optionIcon.BackgroundTransparency = 1
    optionIcon.Image             = getAsset(self, "newvape/assets/new/dots.png", "rbxassetid://10734897387")
    optionIcon.ImageColor3       = COL_ICON_OFF
    optionIcon.ScaleType         = Enum.ScaleType.Fit
    optionIcon.ZIndex            = 6
    optionIcon.Parent            = optionBtn

    -- Bind button (垂直中央 0.5,0 / 高さ 18px / 右端 -26px / 隙間6px)
    local bindBtn = Instance.new("TextButton")
    bindBtn.Name               = "Bind"
    bindBtn.Size               = UDim2.fromOffset(18, 18)
    bindBtn.AnchorPoint        = Vector2.new(1, 0.5)
    bindBtn.Position           = UDim2.new(1, -26, 0.5, 0)
    bindBtn.BackgroundTransparency = 1
    bindBtn.Text               = ""
    bindBtn.ZIndex             = 5
    bindBtn.Parent             = button

    -- BindFrame (18x18pxのサイズを完全に維持)
    local bindFrame = Instance.new("Frame")
    bindFrame.Name               = "BindFrame"
    bindFrame.Size               = UDim2.new(1, 0, 1, 0)
    bindFrame.BackgroundColor3   = Color3.new(0, 0, 0)
    bindFrame.BackgroundTransparency = 0.65
    bindFrame.BorderSizePixel    = 0
    bindFrame.ZIndex             = 5
    bindFrame.Parent             = bindBtn

    local bfc = Instance.new("UICorner")
    bfc.CornerRadius = UDim.new(0, 4)
    bfc.Parent = bindFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bindFrame

    -- Bind icon (完全に中央揃え)
    local bindIcon = Instance.new("ImageLabel")
    bindIcon.Name              = "Icon"
    bindIcon.Size              = UDim2.fromOffset(12, 12)
    bindIcon.AnchorPoint       = Vector2.new(0.5, 0.5)
    bindIcon.Position          = UDim2.new(0.5, 0, 0.5, 0)
    bindIcon.BackgroundTransparency = 1
    bindIcon.ImageColor3       = COL_TEXT_OFF
    bindIcon.ScaleType         = Enum.ScaleType.Fit
    bindIcon.ZIndex            = 6
    bindIcon.Image             = (type(assets) == "table" and assets.bind) or getAsset(self, "newvape/assets/new/bind.png", "rbxassetid://14368304734")
    bindIcon.Parent            = bindFrame

    -- BindText
    local bindText = Instance.new("TextLabel")
    bindText.Name              = "BindText"
    bindText.Size              = UDim2.new(1, 0, 1, 0)
    bindText.BackgroundTransparency = 1
    bindText.Text              = ""
    bindText.Visible           = false
    bindText.TextColor3        = COL_TEXT_OFF
    bindText.TextSize          = 10
    bindText.ZIndex            = 6
    local bfok = pcall(function() bindText.FontFace = pal.Font end)
    if not bfok then bindText.Font = FONT_BOLD end
    bindText.Parent = bindFrame

    -- ★ Star button (垂直中央 0.5,0 / 高さ 24px / 右端 -50px / ONのときのみ表示)
    local starBtn = Instance.new("TextButton")
    starBtn.Name               = "StarBtn"
    starBtn.Size               = UDim2.fromOffset(24, 24)
    starBtn.AnchorPoint        = Vector2.new(1, 0.5)
    starBtn.Position           = UDim2.new(1, -50, 0.5, 0)
    starBtn.BackgroundTransparency = 1
    starBtn.Text               = ""
    starBtn.ZIndex             = 5
    starBtn.Visible            = false
    starBtn.Parent             = button

    -- ★ Star TextLabel
    local starIcon = Instance.new("TextLabel")
    starIcon.Name              = "Icon"
    starIcon.Size              = UDim2.new(1, 0, 1, 0)
    starIcon.AnchorPoint       = Vector2.new(0.5, 0.5)
    starIcon.Position          = UDim2.new(0.5, 0, 0.5, -1)
    starIcon.BackgroundTransparency = 1
    starIcon.Text              = "★"
    starIcon.TextSize          = 22
    starIcon.Font              = FONT_BOLD
    starIcon.TextXAlignment    = Enum.TextXAlignment.Center
    starIcon.TextYAlignment    = Enum.TextYAlignment.Center
    starIcon.TextColor3        = Color3.fromRGB(70, 70, 70)
    starIcon.ZIndex            = 6
    starIcon.Parent            = starBtn

    -- Options accordion frame (親コンテナに100%追従)
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name              = "OptionsFrame"
    optionsFrame.Size              = UDim2.new(1, 0, 0, 0)
    optionsFrame.Position          = UDim2.fromOffset(0, 44)
    optionsFrame.BackgroundColor3  = col.Dark(pal.Main, 0.02)
    optionsFrame.BorderSizePixel   = 0
    optionsFrame.ClipsDescendants  = true
    optionsFrame.Visible           = false
    optionsFrame.ZIndex            = 2
    optionsFrame.Parent            = moduleFrame

    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.FillDirection        = Enum.FillDirection.Vertical
    optionsLayout.SortOrder            = Enum.SortOrder.LayoutOrder
    optionsLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    optionsLayout.Parent               = optionsFrame

    -- Hover / click events
    local hoverTime = 0.15
    local ease, dir = Enum.EasingStyle.Quart, Enum.EasingDirection.Out

    button.MouseEnter:Connect(function()
        if self.Enabled then return end
        TweenService:Create(hoverBg,    TweenInfo.new(hoverTime,ease,dir), {BackgroundTransparency = 0.94}):Play()
        TweenService:Create(label,      TweenInfo.new(hoverTime,ease,dir), {TextColor3 = COL_TEXT_HOVER}):Play()
        TweenService:Create(optionIcon, TweenInfo.new(hoverTime,ease,dir), {ImageColor3 = COL_ICON_HOVER}):Play()
    end)

    button.MouseLeave:Connect(function()
        if self.Enabled then return end
        TweenService:Create(hoverBg,    TweenInfo.new(hoverTime,ease,dir), {BackgroundTransparency = 1}):Play()
        TweenService:Create(label,      TweenInfo.new(hoverTime,ease,dir), {TextColor3 = COL_TEXT_OFF}):Play()
        TweenService:Create(optionIcon, TweenInfo.new(hoverTime,ease,dir), {ImageColor3 = COL_ICON_OFF}):Play()
    end)

    -- Bindホバー時の微弱なハイライト
    bindBtn.MouseEnter:Connect(function()
        TweenService:Create(bindFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.45
        }):Play()
    end)

    bindBtn.MouseLeave:Connect(function()
        TweenService:Create(bindFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.65
        }):Play()
    end)

    button.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    optionBtn.MouseButton1Click:Connect(function()
        self:ToggleOptions()
    end)

    starBtn.MouseButton1Click:Connect(function()
        self.Starred = not self.Starred
        starIcon.TextColor3 = self.Starred and Color3.fromRGB(255, 255, 255) or (self.Enabled and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(70, 70, 70))
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if self.IsBinding then return end
        self.IsBinding = true
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local keyName = input.KeyCode ~= Enum.KeyCode.Unknown
                and input.KeyCode.Name
                or (input.UserInputType == Enum.UserInputType.MouseButton1 and "MouseButton1")
                or nil
            if keyName then
                conn:Disconnect()
                self:SetBind({keyName}, true)
            end
        end)
    end)

    -- Assign to self
    self.Frame         = moduleFrame
    self.Object        = button
    self.HoverBg       = hoverBg
    self.ActiveBg      = activeBg
    self.Gradient      = gradient
    self.Divider       = divider
    self.Label         = label
    self.ColorDot      = colorDotFrame
    self.OptionButton  = optionBtn
    self.OptionIcon    = optionIcon
    self.StarButton    = starBtn
    self.StarIcon      = starIcon
    self.BindButton    = bindBtn
    self.BindFrame     = bindFrame
    self.BindIcon      = bindIcon
    self.BindText      = bindText

    self.OptionsFrame  = optionsFrame
    self.OptionsLayout = optionsLayout
    self.Children      = optionsFrame

    -- Dynamic component injection
    local comps = (mapi and mapi.Components) or (shared.vape and shared.vape.Components)
    if type(comps) == "table" then
        for k, v in pairs(comps) do
            if not Module["Create"..k] then
                self["Create"..k] = function(_, settings)
                    local res = v(settings, optionsFrame, self)
                    self:_refreshOptionsHeight()
                    return res
                end
            end
        end
    end

    addMaid(self)
    return self
end

-- ── Methods ──────────────────────────────────────────────────────────────────

function Module:SetBind(tab, mouse)
    debugPrint("SetBind:", self.Name, table.concat(tab, "+"))
    if tab.Mobile then
        createMobileButton(self, Vector2.new(tab.X, tab.Y))
        return
    end
    self.Bind = table.clone(tab)
    self.IsBinding = false
    self:UpdateBindState()
end

function Module:UpdateBindState()
    local hasBind = #self.Bind > 0
    self.BindIcon.Visible = not hasBind
    self.BindText.Visible = hasBind
    if hasBind then
        self.BindText.Text = table.concat(self.Bind, "+")
    end
end

-- src/gui/components/Module.lua の 190行目付近

function Module:SetState(state, multiple)
    debugPrint("SetState:", self.Name, state)
    self.Enabled = state

    if self.Gradient then self.Gradient.Enabled  = state end

    TweenService:Create(self.Label, TWEEN_INFO, {
        TextColor3 = state and COL_TEXT_ON or COL_TEXT_OFF
    }):Play()

    -- Color dot visibility
    TweenService:Create(self.ColorDot, TWEEN_INFO, {
        BackgroundTransparency = state and 0 or 1
    }):Play()

    -- Active background color
    local mapi = self.mainapi or (shared.vape and shared.vape.mainapi)
    local activeCol = COL_ACTIVE_BG
    local rainbow = mapi and mapi.GUIColor and mapi.GUIColor.Rainbow and mapi.RainbowMode and mapi.RainbowMode.Value ~= "Retro"
    if mapi and mapi.GUIColor then
        if rainbow and mapi.Color then
            activeCol = Color3.fromHSV(mapi:Color((self.Index * 0.025) % 1))
        else
            activeCol = Color3.fromHSV(mapi.GUIColor.Hue, mapi.GUIColor.Sat, mapi.GUIColor.Value)
        end
    end

    if self.tween and self.tween.Tween then
        self.tween:Tween(self.ActiveBg, self.uipallet.Tween, {
            BackgroundTransparency = state and 0 or 1,
            BackgroundColor3       = activeCol, -- 🌟 【修正】色を白に切り替えず、そのままの色のまま透明度だけを下げます
        })
    else
        TweenService:Create(self.ActiveBg, TWEEN_INFO, {
            BackgroundTransparency = state and 0 or 1,
            BackgroundColor3       = activeCol, -- 🌟 【修正】同上
        }):Play()
    end

    TweenService:Create(self.OptionIcon, TWEEN_INFO, {
        ImageColor3 = state and COL_TEXT_ON or COL_ICON_OFF
    }):Play()

    TweenService:Create(self.BindIcon, TWEEN_INFO, {
        ImageColor3 = state and COL_TEXT_ON or COL_TEXT_OFF
    }):Play()

    -- ホバー背景の透明度をリセット
    TweenService:Create(self.HoverBg, TWEEN_INFO, {BackgroundTransparency = 1}):Play()

    -- 星ボタンの表示切り替え（ONのときのみ表示）と色変更（Starredのときは白色に）
    self.StarButton.Visible = state
    TweenService:Create(self.StarIcon, TWEEN_INFO, {
        TextColor3 = self.Starred and Color3.fromRGB(255, 255, 255) or (state and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(70, 70, 70))
    }):Play()

    if not state then
        for _, v in ipairs(self.Connections) do pcall(function() v:Disconnect() end) end
        table.clear(self.Connections)
    end

    if not multiple and mapi then mapi:UpdateTextGUI() end
    self:UpdateBindState()
    if self.Callback then task.spawn(self.Callback, self.Enabled) end
end

function Module:Toggle(multiple)
    self:SetState(not self.Enabled, multiple)
end

-- アコーディオンプランの横幅を100%追従に変更
function Module:ToggleOptions()
    self.OptionsExpanded = not self.OptionsExpanded
    self.OptionsFrame.Visible = true
    local h = self.OptionsExpanded and calcOptionsHeight(self.OptionsFrame, self.OptionsLayout) or 0
    TweenService:Create(self.Frame,        TWEEN_INFO, {Size = UDim2.new(1, 0, 0, 44 + h)}):Play()
    TweenService:Create(self.OptionsFrame, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, h)}):Play()
    TweenService:Create(self.OptionIcon,   TWEEN_INFO, {Rotation = self.OptionsExpanded and 90 or 0}):Play()
    if not self.OptionsExpanded then
        task.delay(TWEEN_INFO.Time, function()
            if not self.OptionsExpanded then self.OptionsFrame.Visible = false end
        end)
    end
end

-- アコーディオンプランの横幅を100%追従に変更
function Module:_refreshOptionsHeight()
    if self.OptionsExpanded then
        task.defer(function()
            local h = calcOptionsHeight(self.OptionsFrame, self.OptionsLayout)
            TweenService:Create(self.OptionsFrame, TWEEN_INFO, {Size = UDim2.new(1, 0, 0, h)}):Play()
            TweenService:Create(self.Frame,        TWEEN_INFO, {Size = UDim2.new(1, 0, 0, 44 + h)}):Play()
        end)
    end
end

function Module:SetColorDot(color3)
    if self.ColorDot then
        self.ColorDot.BackgroundColor3 = color3
    end
end

function Module:Color(hue, sat, val, rainbowcheck)
    local mapi    = self.mainapi or (shared.vape and shared.vape.mainapi)
    local rainbow = rainbowcheck and mapi and mapi.GUIColor and mapi.GUIColor.Rainbow and mapi.RainbowMode and mapi.RainbowMode.Value ~= "Retro"
    if self.Enabled then
        local c
        if rainbow and mapi and mapi.Color then
            c = Color3.fromHSV(mapi:Color((hue - self.Index * 0.025) % 1))
        else
            c = Color3.fromHSV(hue, sat, val)
        end
        local mode = (mapi and mapi.RainbowMode) and mapi.RainbowMode.Value or "Normal"
        if rainbow and mode == "Gradient" then
            self.Gradient.Enabled = true
            if mapi and mapi.Color then
                self.Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, c),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(mapi:Color((hue - (self.Index+1)*0.025) % 1)))
                })
            end
            self.ActiveBg.BackgroundColor3 = Color3.fromRGB(255,255,255)
        else
            self.Gradient.Enabled = false
            self.ActiveBg.BackgroundColor3 = c
        end
        local tc = (mapi and mapi.TextColor) and mapi:TextColor(hue,sat,val) or COL_TEXT_ON
        self.Label.TextColor3    = tc
        self.BindText.TextColor3 = tc
        self.BindIcon.ImageColor3 = tc
        self.OptionIcon.ImageColor3 = tc
    else
        self.Label.TextColor3    = COL_TEXT_OFF
        self.OptionIcon.ImageColor3 = COL_ICON_OFF
        self.BindIcon.ImageColor3   = self.color.Dark(self.uipallet.Text, 0.43)
        self.BindText.TextColor3    = self.color.Dark(self.uipallet.Text, 0.43)
    end
    for _, opt in pairs(self.Options) do
        if opt.Color then opt:Color(hue, sat, val, rainbowcheck) end
    end
end

-- Late-bind global components (non-overwriting)
task.spawn(function()
    local comps = components or (shared.vape and shared.vape.Components)
    if comps then
        for k, v in pairs(comps) do
            if not Module["Create"..k] then
                Module["Create"..k] = function(self, settings)
                    local res = v(settings, self.OptionsFrame, self)
                    self:_refreshOptionsHeight()
                    return res
                end
            end
        end
    end
end)

return Module