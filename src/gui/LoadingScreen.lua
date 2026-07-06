-- src/gui/LoadingScreen.lua
local TweenService = game:GetService("TweenService")
local LoadingScreen = {}

function LoadingScreen.show(parentScreenGui, assets, onComplete)
    -- 🌟 本物同様に起動した瞬間から背景を美しくボケさせます
    local blur = game:GetService("Lighting"):FindFirstChild("VapeBlurEffect")
    if blur then
        blur.Enabled = true
    end

    -- 🌟 背景を完全な黒ではなく、ゲーム画面が少し透ける「透過ダークグレー」に変更
    local LoadingContainer = Instance.new("CanvasGroup")
    LoadingContainer.Name = "VapeLoadingScreen"
    LoadingContainer.Size = UDim2.new(1, 0, 1, 0)
    LoadingContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 10) 
    LoadingContainer.BackgroundTransparency = 0.15 -- 🌟 ほぼ真っ暗（15%だけ透明、85%黒い）
    LoadingContainer.BorderSizePixel = 0
    LoadingContainer.ZIndex = 10000 -- 常に全ウィンドウの最前面
    LoadingContainer.Parent = parentScreenGui

    -- 中央のコンテンツ配置枠
    local CenterFrame = Instance.new("Frame")
    CenterFrame.Size = UDim2.new(0, 320, 0, 120)
    CenterFrame.Position = UDim2.new(0.5, -160, 0.5, -60)
    CenterFrame.BackgroundTransparency = 1
    CenterFrame.Parent = LoadingContainer

    -- ==========================================
    -- 🌟 ロゴ画像を表示するためのコンテナ
    -- ==========================================
    local LogoContainer = Instance.new("Frame")
    LogoContainer.Name = "LogoContainer"
    LogoContainer.Size = UDim2.new(1, 0, 0, 30)
    LogoContainer.Position = UDim2.new(0, 0, 0, 0)
    LogoContainer.BackgroundTransparency = 1
    LogoContainer.Parent = CenterFrame

    local LogoLayout = Instance.new("UIListLayout")
    LogoLayout.FillDirection = Enum.FillDirection.Horizontal
    LogoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LogoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    -- 🌟 【修正】ロゴとV4バッジの間の隙間を「6」から「0」に縮小して左に寄せます。
    -- もしこれでも離れて見える場合は UDim.new(0, -3) などのマイナス値に調整してみてください。
    LogoLayout.Padding = UDim.new(0, 0) 
    LogoLayout.Parent = LogoContainer

    -- 🌟 【修正】APE用にアスペクト比を計算し、横幅を「90」から「76」に拡大・調整しました
    local VapeLogoImg = Instance.new("ImageLabel")
    VapeLogoImg.Name = "ApeLogoImg"
    VapeLogoImg.Size = UDim2.new(0, 76, 0, 28) 
    VapeLogoImg.BackgroundTransparency = 1
    VapeLogoImg.ImageTransparency = 1
    VapeLogoImg.ScaleType = Enum.ScaleType.Fit
    VapeLogoImg.Parent = LogoContainer

    -- V4 Badge Logo (ちょうど良い中間の 28px 高さ / 初期状態は透明)
    local V4LogoImg = Instance.new("ImageLabel")
    V4LogoImg.Size = UDim2.new(0, 44, 0, 28) 
    V4LogoImg.BackgroundTransparency = 1
    V4LogoImg.ImageTransparency = 1
    V4LogoImg.ScaleType = Enum.ScaleType.Fit
    V4LogoImg.Parent = LogoContainer

    -- 進捗ステータス表記（フォントサイズをやや小さくし、本家の控えめな雰囲気に）
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0, 0, 0, 52)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Connecting..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100) -- やや暗めのグレー
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.SourceSansSemibold
    StatusLabel.Parent = CenterFrame

    -- プログレスバー背景（本家Vapeに合わせ、太さを2pxに極細化してスタイリッシュに）
    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, 0, 0, 2) -- 🌟 2pxに極細化
    BarBg.Position = UDim2.new(0, 0, 0, 85)
    BarBg.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    BarBg.BorderSizePixel = 0
    BarBg.Parent = CenterFrame

    local BarBgCorner = Instance.new("UICorner")
    BarBgCorner.CornerRadius = UDim.new(0, 1)
    BarBgCorner.Parent = BarBg

    -- プログレスバー進行
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(45, 186, 120) -- 🌟 本家Vapeの鮮やかな黄緑色（ミントグリーン）
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBg

    local BarFillCorner = Instance.new("UICorner")
    BarFillCorner.CornerRadius = UDim.new(0, 1)
    BarFillCorner.Parent = BarFill

    -- 実際のアセットのダウンロード進捗イベントを監視
    local connection
    local logoLoaded = false -- ロゴのフェードインが完了したか追跡するフラグ

    connection = assets.OnProgress:Connect(function(progress, text)
        StatusLabel.Text = text
        
        -- ダウンロード進捗に合わせてバーをなめらかに伸長
        TweenService:Create(BarFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()

        -- 🌟 ロゴアセットのダウンロードが完了した瞬間、画像をセットしてフェードイン
        if not logoLoaded and assets.vapeLogo and assets.v4Logo then
            logoLoaded = true
            VapeLogoImg.Image = assets.vapeLogo
            V4LogoImg.Image = assets.v4Logo
            
            -- 不透明度を 1 から 0 へ（ふわっと出現）
            TweenService:Create(VapeLogoImg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
            TweenService:Create(V4LogoImg, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
        end

        -- 100%読み込みが完了した時の処理
        if progress >= 1.0 then
            if connection then
                connection:Disconnect()
                connection = nil
            end

            task.wait(0.2) -- 完了状態を見せるための僅かな余韻

            -- 画面全体を滑らかにフェードアウト
            local fadeTween = TweenService:Create(LoadingContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                GroupTransparency = 1
            })
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                LoadingContainer:Destroy()
                if onComplete then
                    onComplete() -- ロード完了をMain.luaに通知
                end
            end)
        end
    end)

    -- 非同期で実際のアセットのダウンロードロード処理を開始
    task.spawn(function()
        assets.loadAll()
    end)
end

return LoadingScreen