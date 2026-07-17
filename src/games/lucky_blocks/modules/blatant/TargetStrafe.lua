-- サービスの取得
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ローカルプレイヤー
local lplr = Players.LocalPlayer

-- モジュールの基本情報
local TargetStrafe = {
    Name = "TargetStrafe",
    Description = "Automatically circles around your target opponent with void and wall prevention.",
    TargetGame = "lucky_blocks"
}

-- 設定のデフォルト値
TargetStrafe.Settings = {
    DistanceValue = 6,
    SpeedValue = 12,
    SearchRangeValue = 80,
    AutoJump = true,
    DrawCircle = true,       
    TargetHighlight = true,  
    TargetTracer = true,
    DrawBillboard = true,    -- 3D頭上HUDのデフォルト
    Rainbow = true,          -- レインボーモードのデフォルト
    Color = Color3.fromRGB(0, 255, 150) -- デフォルトカラー
}

-- 変数の初期化
local connection = nil 
local currentTarget = nil
local theta = 0 -- 旋回の角度
local direction = 1 -- 1 = 時計回り, -1 = 反時計回り
local lastDirectionSwitchTime = 0

-- デバッグ用変数
local lastPeriodicLog = 0
local lastTargetName = nil
local firstHeartbeatFired = false

-- ビジュアル管理用インスタンス
local currentHighlight = nil
local circlePart = nil
local tracerBeam = nil
local localAttachment = nil
local targetAttachment = nil
local targetBillboard = nil 

-- UIコンポーネントを保持するテーブル
local UI = {}

-- アバターの高さ取得 (R6/R15対応)
local function getPivotOffset(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 2.0 end

    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        return 2.5
    else
        return humanoid.HipHeight + (model.PrimaryPart.Size.Y / 2)
    end
end

-- クリーンアップ関数
local function cleanupVisuals()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
    if circlePart then
        circlePart:Destroy()
        circlePart = nil
    end
    if tracerBeam then
        tracerBeam:Destroy()
        tracerBeam = nil
    end
    if localAttachment then
        localAttachment:Destroy()
        localAttachment = nil
    end
    if targetAttachment then
        targetAttachment:Destroy()
        targetAttachment = nil
    end
    if targetBillboard then
        targetBillboard:Destroy()
        targetBillboard = nil
    end
end

-- ターゲット取得
local function findClosestTarget(rangeLimit)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter.PrimaryPart
    if not myRoot then return nil end

    local closestTarget = nil
    local minDistance = rangeLimit

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character.PrimaryPart then
            local targetRoot = player.Character.PrimaryPart
            local distance = (myRoot.Position - targetRoot.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closestTarget = player.Character
            end
        end
    end
    return closestTarget
end

-- モジュールの初期化（UI作成）
function TargetStrafe.Init(moduleObj)
    print("[TargetStrafe Debug] Init関数が呼び出されました。UIを作成します。")
    
    UI.Distance = moduleObj:CreateSlider({
        Name = "Strafe Distance",
        Min = 2, Max = 20,
        Default = TargetStrafe.Settings.DistanceValue,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.DistanceValue = val end
    })

    UI.Speed = moduleObj:CreateSlider({
        Name = "Strafe Speed",
        Min = 1, Max = 30,
        Default = TargetStrafe.Settings.SpeedValue,
        Function = function(val) TargetStrafe.Settings.SpeedValue = val end
    })

    UI.SearchRange = moduleObj:CreateSlider({
        Name = "Search Range",
        Min = 10, Max = 150,
        Default = TargetStrafe.Settings.SearchRangeValue,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.SearchRangeValue = val end
    })

    UI.AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump (BHop)",
        Default = TargetStrafe.Settings.AutoJump,
        Function = function(state) TargetStrafe.Settings.AutoJump = state end
    })

    UI.DrawCircle = moduleObj:CreateToggle({
        Name = "Draw Strafe Circle",
        Default = TargetStrafe.Settings.DrawCircle,
        Function = function(state) TargetStrafe.Settings.DrawCircle = state end
    })

    UI.TargetHighlight = moduleObj:CreateToggle({
        Name = "Highlight Target",
        Default = TargetStrafe.Settings.TargetHighlight,
        Function = function(state) TargetStrafe.Settings.TargetHighlight = state end
    })

    UI.TargetTracer = moduleObj:CreateToggle({
        Name = "Target Tracer",
        Default = TargetStrafe.Settings.TargetTracer,
        Function = function(state) TargetStrafe.Settings.TargetTracer = state end
    })

    UI.DrawBillboard = moduleObj:CreateToggle({
        Name = "3D Floating HUD",
        Default = TargetStrafe.Settings.DrawBillboard,
        Function = function(state) TargetStrafe.Settings.DrawBillboard = state end
    })

    UI.Rainbow = moduleObj:CreateToggle({
        Name = "Rainbow RGB Mode",
        Default = TargetStrafe.Settings.Rainbow,
        Function = function(state) TargetStrafe.Settings.Rainbow = state end
    })

    UI.Color = moduleObj:CreateColorPicker({
        Name = "Theme Color (Non-RGB)",
        Color = TargetStrafe.Settings.Color,
        Function = function(val) TargetStrafe.Settings.Color = val end
    })
    
    print("[TargetStrafe Debug] すべてのUIの作成が完了しました。")
end

-- Strafe処理の本体
local function onHeartbeat(dt)
    if not firstHeartbeatFired then
        print("[TargetStrafe Debug] Heartbeatループが正常に開始されました。")
        firstHeartbeatFired = true
    end

    if os.clock() - lastPeriodicLog > 2 then
        lastPeriodicLog = os.clock()
        local myCharacter = lplr.Character
        local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
        
        local status = "正常動作中"
        if not myCharacter then status = "エラー: キャラクターが存在しません"
        elseif not myRoot then status = "エラー: HumanoidRootPartがありません"
        elseif not humanoid then status = "エラー: Humanoidがありません"
        elseif humanoid:GetState() == Enum.HumanoidStateType.Dead then status = "エラー: プレイヤーが死亡しています"
        end
        
        local targetName = currentTarget and currentTarget.Name or "なし"
        print(string.format("[TargetStrafe Debug] ステータス: %s | ターゲット: %s", status, targetName))
    end

    local myCharacter = lplr.Character
    if not myCharacter then return end
    
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end

    currentTarget = findClosestTarget(TargetStrafe.Settings.SearchRangeValue)
    
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos = myRoot.Position
        local targetPos = targetRoot.Position

        local targetName = currentTarget.Name
        if lastTargetName ~= targetName then
            print("[TargetStrafe Debug] ターゲットを新たに捕捉しました: " .. targetName)
            cleanupVisuals()
            lastTargetName = targetName
        end

        local currentVisualColor = TargetStrafe.Settings.Color
        if TargetStrafe.Settings.Rainbow then
            local hue = (os.clock() * 0.15) % 1
            currentVisualColor = Color3.fromHSV(hue, 0.85, 1)
        end

        -- 1. ターゲットハイライト
        if TargetStrafe.Settings.TargetHighlight then
            if not currentHighlight or currentHighlight.Parent ~= currentTarget then
                if currentHighlight then currentHighlight:Destroy() end
                currentHighlight = Instance.new("Highlight")
                currentHighlight.OutlineColor = Color3.fromRGB(255, 255, 255) 
                currentHighlight.FillTransparency = 0.65
                currentHighlight.OutlineTransparency = 0.1
                currentHighlight.Adornee = currentTarget
                currentHighlight.Parent = currentTarget
            end
            currentHighlight.FillColor = currentVisualColor
        else
            if currentHighlight then
                currentHighlight:Destroy()
                currentHighlight = nil
            end
        end

        -- 2. 旋回サークル
        if TargetStrafe.Settings.DrawCircle then
            if not circlePart then
                circlePart = Instance.new("Part")
                circlePart.Name = "StrafeCircleVisual"
                circlePart.Shape = Enum.PartType.Cylinder
                circlePart.Material = Enum.Material.Neon
                circlePart.Anchored = true
                circlePart.CanCollide = false
                circlePart.CanQuery = false
                circlePart.CanTouch = false
                circlePart.Parent = workspace.Terrain
            end
            
            local pulse = math.sin(os.clock() * 4.5) * 0.08
            local sizeDiameter = (TargetStrafe.Settings.DistanceValue * 2) + (pulse * 2)
            
            circlePart.Color = currentVisualColor
            circlePart.Transparency = 0.82 + (pulse * 0.4)
            circlePart.Size = Vector3.new(0.04 + (math.abs(pulse) * 0.1), sizeDiameter, sizeDiameter)
            
            local floorOffset = getPivotOffset(currentTarget)
            local floorPos = targetPos - Vector3.new(0, floorOffset, 0)
            circlePart.CFrame = CFrame.new(floorPos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(os.clock() * 1.5, 0, 0)
        else
            if circlePart then
                circlePart:Destroy()
                circlePart = nil
            end
        end

        -- 3. トレーサー
        if TargetStrafe.Settings.TargetTracer then
            if not tracerBeam then
                localAttachment = Instance.new("Attachment")
                localAttachment.Parent = myRoot
                
                targetAttachment = Instance.new("Attachment")
                targetAttachment.Parent = targetRoot
                
                tracerBeam = Instance.new("Beam")
                tracerBeam.Attachment0 = localAttachment
                tracerBeam.Attachment1 = targetAttachment
                tracerBeam.Width0 = 0.15
                tracerBeam.Width1 = 0.15
                tracerBeam.FaceCamera = true
                tracerBeam.Transparency = NumberSequence.new(0.3)
                tracerBeam.Parent = workspace.Terrain
            else
                if localAttachment.Parent ~= myRoot then localAttachment.Parent = myRoot end
                if targetAttachment.Parent ~= targetRoot then targetAttachment.Parent = targetRoot end
            end
            tracerBeam.Color = ColorSequence.new(currentVisualColor)
        else
            if tracerBeam then
                tracerBeam:Destroy()
                tracerBeam = nil
            end
            if localAttachment then
                localAttachment:Destroy()
                localAttachment = nil
            end
            if targetAttachment then
                targetAttachment:Destroy()
                targetAttachment = nil
            end
        end

        -- 4. Vape V4 風 3DフローティングHUD
        if TargetStrafe.Settings.DrawBillboard then
            if not targetBillboard then
                targetBillboard = Instance.new("BillboardGui")
                targetBillboard.Size = UDim2.new(0, 150, 0, 48)
                targetBillboard.AlwaysOnTop = true
                targetBillboard.StudsOffset = Vector3.new(0, 3.2, 0)
                
                -- メインフレーム (Vape風半透明ダーク)
                local frame = Instance.new("Frame")
                frame.Name = "MainFrame"
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                frame.BackgroundTransparency = 0.5
                frame.BorderSizePixel = 0
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 6)
                corner.Parent = frame
                
                -- 枠線
                local stroke = Instance.new("UIStroke")
                stroke.Name = "BorderStroke"
                stroke.Thickness = 1
                stroke.Transparency = 0.6
                stroke.Color = Color3.fromRGB(255, 255, 255)
                stroke.Parent = frame
                
                -- プレイヤー名
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, -12, 0.4, 0)
                nameLabel.Position = UDim2.new(0, 6, 0.1, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 10
                nameLabel.Font = Enum.Font.GothamSemibold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = frame
                
                -- 距離
                local distLabel = Instance.new("TextLabel")
                distLabel.Name = "DistLabel"
                distLabel.Size = UDim2.new(1, -12, 0.3, 0)
                distLabel.Position = UDim2.new(0, 6, 0.45, 0)
                distLabel.BackgroundTransparency = 1
                distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
                distLabel.TextSize = 8
                distLabel.Font = Enum.Font.Gotham
                distLabel.TextXAlignment = Enum.TextXAlignment.Left
                distLabel.Parent = frame

                -- ヘルスバー背景
                local hpBg = Instance.new("Frame")
                hpBg.Name = "HPBackground"
                hpBg.Size = UDim2.new(1, -12, 0.12, 0)
                hpBg.Position = UDim2.new(0, 6, 0.78, 0)
                hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                hpBg.BorderSizePixel = 0
                hpBg.Parent = frame

                local hpCorner = Instance.new("UICorner")
                hpCorner.CornerRadius = UDim.new(0, 2)
                hpCorner.Parent = hpBg

                -- ヘルスバー本体
                local hpBar = Instance.new("Frame")
                hpBar.Name = "HPBar"
                hpBar.Size = UDim2.new(1, 0, 1, 0)
                hpBar.BorderSizePixel = 0
                hpBar.Parent = hpBg

                local barCorner = Instance.new("UICorner")
                barCorner.CornerRadius = UDim.new(0, 2)
                barCorner.Parent = hpBar
                
                frame.Parent = targetBillboard
                targetBillboard.Adornee = targetRoot
                targetBillboard.Parent = workspace.Terrain
            else
                if targetBillboard.Adornee ~= targetRoot then
                    targetBillboard.Adornee = targetRoot
                end
                
                local frame = targetBillboard:FindFirstChild("MainFrame")
                if frame then
                    local targetHumanoid = currentTarget:FindFirstChildOfClass("Humanoid")
                    local hp = targetHumanoid and targetHumanoid.Health or 0
                    local maxHp = targetHumanoid and targetHumanoid.MaxHealth or 100
                    local hpPercent = math.clamp(hp / maxHp, 0, 1)
                    
                    local nameLabel = frame:FindFirstChild("NameLabel")
                    if nameLabel then
                        nameLabel.Text = string.format("%s (%d HP)", targetName, math.round(hp))
                    end

                    local distLabel = frame:FindFirstChild("DistLabel")
                    if distLabel then
                        local distance = math.round((myPos - targetPos).Magnitude)
                        distLabel.Text = string.format("Distance: %d studs", distance)
                    end

                    local hpBg = frame:FindFirstChild("HPBackground")
                    local hpBar = hpBg and hpBg:FindFirstChild("HPBar")
                    if hpBar then
                        hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                        hpBar.BackgroundColor3 = currentVisualColor
                    end
                end
            end
        else
            if targetBillboard then
                targetBillboard:Destroy()
                targetBillboard = nil
            end
        end

        -- ========================================================
        -- 【旋回・移動処理】
        -- ========================================================
        theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt) % (math.pi * 2)
        
        local desiredDistance = TargetStrafe.Settings.DistanceValue
        local nextX = targetPos.X + math.cos(theta) * desiredDistance
        local nextZ = targetPos.Z + math.sin(theta) * desiredDistance
        local nextPos = Vector3.new(nextX, myPos.Y, nextZ)
        
        local moveDirection = (nextPos - myPos).Unit

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {myCharacter}

        local groundCheckOrigin = myPos + moveDirection * 2
        local groundRay = workspace:Raycast(groundCheckOrigin, Vector3.new(0, -50, 0), raycastParams)
        local isVoid = not groundRay

        local wallRay = workspace:Raycast(myPos, moveDirection * 2, raycastParams)
        local isWall = wallRay and wallRay.Instance and wallRay.Instance.CanCollide

        if (isVoid or isWall) and (os.clock() - lastDirectionSwitchTime > 0.5) then
            print(string.format("[TargetStrafe Debug] 壁または奈落を検知。反転します。 (Void: %s, Wall: %s)", tostring(isVoid), tostring(isWall)))
            direction = -direction 
            lastDirectionSwitchTime = os.clock()
            theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt * 3) % (math.pi * 2) 
            return 
        end

        humanoid:Move(moveDirection, false)
        myRoot.CFrame = CFrame.lookAt(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
        
        if TargetStrafe.Settings.AutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
        end
    else
        if lastTargetName ~= nil then
            print("[TargetStrafe Debug] ターゲットを見失いました。描画を消去します。")
            cleanupVisuals()
            lastTargetName = nil
        end

        if humanoid.MoveDirection ~= Vector3.zero then
            humanoid:Move(Vector3.zero, false)
        end
    end
end

-- モジュールの有効/無効を切り替える関数
function TargetStrafe.Callback(enabled)
    print("[TargetStrafe Debug] Callbackが呼び出されました。設定値(Enabled): " .. tostring(enabled))
    
    if enabled then
        theta = 0
        direction = 1
        lastDirectionSwitchTime = 0
        currentTarget = nil
        lastTargetName = nil
        firstHeartbeatFired = false
        lastPeriodicLog = 0
        
        connection = RunService.Heartbeat:Connect(onHeartbeat)
        print("[TargetStrafe Debug] Heartbeatイベントへの接続に成功しました。")
    else
        if connection then
            connection:Disconnect()
            connection = nil
            print("[TargetStrafe Debug] Heartbeatイベントを切断しました。")
        end
        
        cleanupVisuals()
        
        if lplr.Character then
            local humanoid = lplr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:Move(Vector3.zero, false)
                print("[TargetStrafe Debug] プレイヤーの移動を停止しました。")
            end
        end
    end
end

return TargetStrafe