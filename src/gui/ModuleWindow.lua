local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local WindowFactory = require("gui.WindowFactory")
local Module = require("gui.components.Module") -- 🌟 ToggleからModuleに変更

local ModuleWindow = {}
ModuleWindow.__index = ModuleWindow

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- 【コンストラクタ】assets を追加受け取り
function ModuleWindow.new(ScreenGui, name, size, position, iconAssetId, assets)
    local self = setmetatable({}, ModuleWindow)

    local container, mainFrame, header = WindowFactory.createBaseWindow(ScreenGui, name, size, position, iconAssetId)
    
    self.Container = container
    self.MainFrame = mainFrame
    self.Header = header
    self.Visible = false
    self.Modules = {}
    self.Collapsed = false
    self.Assets = assets -- アセットリストを保持

    WindowFactory.setupDraggable(container, mainFrame)

    header.BackgroundTransparency = 1

    -- ヘッダータイトルサイズを18pxに拡大
    local title = header:FindFirstChild("Title")
    if title then
        title.Font = Enum.Font.SourceSansSemibold
        title.TextSize = 18
    end

    -- 右上折りたたみボタン（Lucide chevron-down）
    local collapseBtn = Instance.new("ImageButton")
    collapseBtn.Name = "CollapseBtn"
    collapseBtn.Size = UDim2.fromOffset(12, 12)
    collapseBtn.Position = UDim2.new(1, -27, 0.5, -6)
    collapseBtn.BackgroundTransparency = 1
    collapseBtn.Image = "rbxassetid://10709790948"
    collapseBtn.ImageColor3 = Color3.fromRGB(110, 110, 110)
    collapseBtn.Rotation = 180
    collapseBtn.ZIndex = 4
    collapseBtn.Parent = header

    -- レイアウト用の定数
    local HEADER_HEIGHT = 38
    local MAX_WINDOW_HEIGHT = size.Y.Offset -- コンストラクタで指定された高さを最大サイズとして使用

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Name = "ListFrame"
    -- 初期サイズは最大高さからヘッダー分を引いたサイズに設定
    listFrame.Size = UDim2.new(1, 0, 0, MAX_WINDOW_HEIGHT - HEADER_HEIGHT)
    listFrame.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 2
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ZIndex = 2
    listFrame.Parent = mainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 1) -- 🌟 1pxのすきまに設定
    listLayout.Parent = listFrame

    -- ウィンドウ全体の高さとスクロールバーを動的に自動調整する関数
    local function updateWindowSize()
        local contentHeight = listLayout.AbsoluteContentSize.Y
        -- 無駄な隙間をなくすため +10 の余白を削除（必要に応じて調整してください）
        listFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)

        if not self.Collapsed then
            local maxAllowedContentHeight = MAX_WINDOW_HEIGHT - HEADER_HEIGHT
            -- 実コンテンツ高、または最大可能高のどちらか小さい方に合わせる
            local targetContentHeight = math.min(contentHeight, maxAllowedContentHeight)
            local targetHeight = HEADER_HEIGHT + targetContentHeight

            -- 中身が最大高さを超える場合のみスクロールを有効にし、スクロールバーを表示
            local needsScrolling = contentHeight > maxAllowedContentHeight
            listFrame.ScrollingEnabled = needsScrolling
            listFrame.ScrollBarImageTransparency = needsScrolling and 0 or 1

            -- リストとウィンドウのサイズをフィットさせる
            listFrame.Size = UDim2.new(1, 0, 0, targetContentHeight)
            TweenService:Create(container, TWEEN_INFO, {
                Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, targetHeight)
            }):Play()
        end
    end

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWindowSize)

    self.ListFrame = listFrame

    collapseBtn.MouseButton1Click:Connect(function()
        self.Collapsed = not self.Collapsed
        
        local contentHeight = listLayout.AbsoluteContentSize.Y
        local maxAllowedContentHeight = MAX_WINDOW_HEIGHT - HEADER_HEIGHT
        local targetContentHeight = math.min(contentHeight, maxAllowedContentHeight)
        
        -- 折りたたむ時はヘッダーの高さのみ、開く時はコンテンツに合わせた高さに設定
        local targetHeight = self.Collapsed and HEADER_HEIGHT or (HEADER_HEIGHT + targetContentHeight)
        local targetRotation = self.Collapsed and 0 or 180
        
        listFrame.Visible = not self.Collapsed
        
        TweenService:Create(collapseBtn, TWEEN_INFO, {
            Rotation = targetRotation
        }):Play()
        
        TweenService:Create(container, TWEEN_INFO, {
            Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale, targetHeight)
        }):Play()
    end)

    self.Container.Visible = false
    self.MainFrame.GroupTransparency = 1
    
    local stroke = self.MainFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Transparency = 1
    end
    
    local shadow = self.Container:FindFirstChild("Shadow")
    if shadow then
        shadow.ImageTransparency = 1
    end

    return self
end

function ModuleWindow:Toggle()
    self:Animate(not self.Visible)
end

function ModuleWindow:Animate(show)
    self.Visible = show
    local targetTransparency = show and 0 or 1

    TweenService:Create(self.MainFrame, TWEEN_INFO, {GroupTransparency = targetTransparency}):Play()
    
    local stroke = self.MainFrame:FindFirstChildOfClass("UIStroke")
    if stroke then
        TweenService:Create(stroke, TWEEN_INFO, {Transparency = targetTransparency}):Play()
    end

    local shadow = self.Container:FindFirstChild("Shadow")
    if shadow then
        local targetShadowTransparency = show and 0.2 or 1
        TweenService:Create(shadow, TWEEN_INFO, {ImageTransparency = targetShadowTransparency}):Play()
    end

    if show then
        self.Container.Visible = true
    else
        task.delay(TWEEN_INFO.Time, function()
            if not self.Visible then
                self.Container.Visible = false
            end
        end)
    end
end

-- Moduleコンポーネントを生成・バインド（Module.new を呼び出すように変更）
function ModuleWindow:CreateModule(name, desc, callback)
    local moduleObj = Module.new(self.ListFrame, name, callback, self.Assets)
    
    table.insert(self.Modules, moduleObj)
    
    return moduleObj -- 🌟 インスタンス自体をそのまま返します
end

return ModuleWindow