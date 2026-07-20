local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Notification = {}
local function getAsset(fileName)
    local isfolder = isfolder or function(path)
        local success, _ = pcall(listfiles, path)
        return success
    end
    local gameName = "Game"
    if game.PlaceId == 6872274481 or game.PlaceId == 6872265039 or game.PlaceId == 14247545801 then
        gameName = "BedWars"
    else
        local success, productInfo = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if success and productInfo and productInfo.Name then
            gameName = productInfo.Name
        end
    end
    gameName = gameName:gsub("%s+", "_"):gsub("[^%w_]", "")
    if gameName == "" then
        gameName = tostring(game.PlaceId)
    end
    local folderName = "vape"
    if isfolder and isfolder("vape") then
        folderName = "vape_" .. gameName
    end
    local getasset = getcustomasset or getgenv().getcustomasset
    if getasset then
        local path = folderName .. "/assets/" .. fileName
        local success, asset = pcall(getasset, path)
        if success and asset then return asset end
    end
    return ""
end
local function removeTags(str)
    str = str:gsub('<br%s*/>', '\n')
    return str:gsub('<[^<>]->', '')
end
local function addBlur(parent)
    local blur = Instance.new("ImageLabel")
    blur.Name = "Blur"
    blur.Size = UDim2.new(1, 89, 1, 52)
    blur.Position = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    blur.Image = getAsset("blurnotif.png")
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.Parent = parent
    return blur
end
local notificationsFolder = nil
function Notification.create(parentScreenGui, title, text, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"
    if not notificationsFolder or not notificationsFolder.Parent then
        notificationsFolder = parentScreenGui:FindFirstChild("Notifications")
        if not notificationsFolder then
            notificationsFolder = Instance.new("Folder")
            notificationsFolder.Name = "Notifications"
            notificationsFolder.Parent = parentScreenGui
            notificationsFolder.ChildRemoved:Connect(function()
                local list = notificationsFolder:GetChildren()
                for idx, item in ipairs(list) do
                    TweenService:Create(item, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
                        Position = UDim2.new(1, 0, 1, -(29 + (78 * idx)))
                    }):Play()
                end
            end)
        end
    end
    local textBounds = TextService:GetTextSize(removeTags(text), 14, Enum.Font.SourceSans, Vector2.new(1000, 1000))
    local i = #notificationsFolder:GetChildren() + 1
    local card = Instance.new("ImageLabel")
    card.Name = "Notification"
    card.Size = UDim2.fromOffset(math.max(textBounds.X + 80, 266), 75)
    card.Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
    card.ZIndex = 5
    local customAssetExists = (getcustomasset or (getgenv and getgenv().getcustomasset)) ~= nil
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    card.BackgroundTransparency = customAssetExists and 1 or 0.15
    card.Image = getAsset("notification.png")
    card.ScaleType = Enum.ScaleType.Slice
    card.SliceCenter = Rect.new(7, 7, 9, 9)
    card.Parent = notificationsFolder
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 5)
    cCorner.Parent = card
    addBlur(card)
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromOffset(50, 50)
    icon.Position = UDim2.fromOffset(10, 12)
    icon.ZIndex = 5
    icon.BackgroundTransparency = 1
    icon.Image = getAsset((notifType or "info") .. ".png")
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = card
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -76, 0, 20)
    titleLabel.Position = UDim2.fromOffset(66, 14)
    titleLabel.ZIndex = 5
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = card
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -76, 0, 30)
    textLabel.Position = UDim2.fromOffset(66, 31)
    textLabel.ZIndex = 5
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    textLabel.TextSize = 13
    textLabel.TextWrapped = true
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Parent = card
    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.new(1, -14, 0, 2)
    progress.Position = UDim2.new(0, 7, 1, -5)
    progress.ZIndex = 5
    progress.BackgroundColor3 = (notifType == "alert" and Color3.fromRGB(250, 50, 56)) 
                            or (notifType == "warning" and Color3.fromRGB(236, 129, 43)) 
                            or Color3.fromRGB(16, 133, 96)
    progress.BorderSizePixel = 0
    progress.Parent = card
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = progress
    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        AnchorPoint = Vector2.new(1, 0)
    }):Play()
    TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.fromOffset(0, 2)
    }):Play()
    task.delay(duration, function()
        TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            AnchorPoint = Vector2.new(0, 0)
        }):Play()
        task.wait(0.4)
        if card and card.Parent then
            card:ClearAllChildren()
            card:Destroy()
        end
    end)
end
return Notification