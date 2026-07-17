-- サービスの取得
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ローカルプレイヤー
local lplr = Players.LocalPlayer

-- UIテーブルの初期化 (スクリプトの最上部に配置して確実にnilを回避します)
local UI = {}

-- ========================================================
-- 【TargetStrafe モジュールの構築】
-- ========================================================

local TargetStrafe = {
    Name = "TargetStrafe",
    Description = "Automatically circles around your target opponent with void and wall prevention.",
    TargetGame = "lucky_blocks"
}

-- デフォルト設定
TargetStrafe.Settings = {
    DistanceValue = 6,
    SpeedValue = 12,
    SearchRangeValue = 80,
    AutoJump = true,
    DrawCircle = true,       -- 軌道エフェクトトグル
    TargetHighlight = true,  
    TargetTracer = true,
    DrawBillboard = true,    
    Color = Color3.fromRGB(255, 255, 255) -- デフォルト：純白の球体
}

-- 各種変数の初期化
local connection, currentTarget = nil, nil
local theta, direction, lastDirectionSwitchTime = 0, 1, 0
local lastPeriodicLog, lastTargetName, firstHeartbeatFired = 0, nil, false
local currentHighlight, tracerBeam, localAttachment, targetAttachment, targetBillboard = nil, nil, nil, nil, nil
local orbitSpheres = {}

-- ========================================================
-- 【ヘルパー関数群（コード削減用）】
-- ========================================================

-- インスタンスを安全に破棄する
local function clear(inst)
    if inst then inst:Destroy() end
    return nil
end

-- プロパティを指定してインスタンスをスマートに作成する
local function create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

-- アバターの高さ計算 (R6/R15対応)
local function getPivotOffset(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 2.0 end
    return humanoid.RigType == Enum.HumanoidRigType.R6 and 2.5 or (humanoid.HipHeight + (model.PrimaryPart.Size.Y / 2))
end

-- 壁と奈落を検知する
local function checkObstacles(myPos, dir, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    
    local isVoid = not workspace:Raycast(myPos + dir * 2, Vector3.new(0, -50, 0), params)
    local wall = workspace:Raycast(myPos, dir * 2, params)
    local isWall = wall and wall.Instance and wall.Instance.CanCollide
    
    return isVoid or isWall
end

-- 白いネオン球体とその軌跡（Trail）を生成する
local function createOrbitSpheres()
    if #orbitSpheres > 0 then return end
    for i = 1, 3 do
        local sphere = create("Part", {
            Name = "OrbitSphere_" .. i,
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(1.0, 1.0, 1.0),
            Material = Enum.Material.Neon,
            Color = TargetStrafe.Settings.Color,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CanTouch = false,
            Parent = workspace.Terrain
        })
        local att0 = create("Attachment", {Name = "Att0", Position = Vector3.new(0, 0.35, 0), Parent = sphere})
        local att1 = create("Attachment", {Name = "Att1", Position = Vector3.new(0, -0.35, 0), Parent = sphere})
        local trail = create("Trail", {
            Name = "Trail",
            Attachment0 = att0,
            Attachment1 = att1,
            Lifetime = 0.3,
            Color = ColorSequence.new(TargetStrafe.Settings.Color),
            Transparency = NumberSequence.new(0.2, 1),
            Parent = sphere
        })
        table.insert(orbitSpheres, {Part = sphere, Trail = trail})
    end
end

-- 3DフローティングHUDの作成
local function createBillboard(targetRoot)
    local bg = create("BillboardGui", {
        Size = UDim2.new(0, 150, 0, 48),
        AlwaysOnTop = true,
        StudsOffset = Vector3.new(0, 3.2, 0),
        Adornee = targetRoot,
        Parent = workspace.Terrain
    })
    local frame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = bg
    })
    create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    create("UIStroke", {Name = "BorderStroke", Thickness = 1, Transparency = 0.6, Color = Color3.fromRGB(255, 255, 255), Parent = frame})
    
    create("TextLabel", {
        Name = "NameLabel",
        Size = UDim2.new(1, -12, 0.4, 0),
        Position = UDim2.new(0, 6, 0.1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    create("TextLabel", {
        Name = "DistLabel",
        Size = UDim2.new(1, -12, 0.3, 0),
        Position = UDim2.new(0, 6, 0.45, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextSize = 8,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    local hpBg = create("Frame", {
        Name = "HPBackground",
        Size = UDim2.new(1, -12, 0.12, 0),
        Position = UDim2.new(0, 6, 0.78, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Parent = frame
    })
    create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = hpBg})
    
    local hpBar = create("Frame", {
        Name = "HPBar",
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = hpBg
    })
    create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = hpBar})
    
    return bg
end

-- ビジュアルの完全消去
local function cleanupVisuals()
    currentHighlight = clear(currentHighlight)
    tracerBeam = clear(tracerBeam)
    localAttachment = clear(localAttachment)
    targetAttachment = clear(targetAttachment)
    targetBillboard = clear(targetBillboard)
    for _, s in ipairs(orbitSpheres) do clear(s.Part) end
    table.clear(orbitSpheres)
end

-- ターゲット取得
local function findClosestTarget(rangeLimit)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter.PrimaryPart
    if not myRoot then return nil end

    local closestTarget, minDistance = nil, rangeLimit
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character.PrimaryPart then
            local distance = (myRoot.Position - player.Character.PrimaryPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closestTarget = player.Character
            end
        end
    end
    return closestTarget
end

-- UI設定の構築
function TargetStrafe.Init(moduleObj)
    UI = UI or {} -- 万が一の安全策（nil回避）

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
        Name = "Orbiting Spheres",
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
    UI.Color = moduleObj:CreateColorPicker({
        Name = "Theme Color",
        Color = TargetStrafe.Settings.Color,
        Function = function(val) TargetStrafe.Settings.Color = val end
    })
end

-- Strafe・エフェクト同期処理
local function onHeartbeat(dt)
    if not firstHeartbeatFired then
        firstHeartbeatFired = true
    end

    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end

    currentTarget = findClosestTarget(TargetStrafe.Settings.SearchRangeValue)
    
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos, targetPos = myRoot.Position, targetRoot.Position
        local targetName = currentTarget.Name

        if lastTargetName ~= targetName then
            cleanupVisuals()
            lastTargetName = targetName
        end

        local color = TargetStrafe.Settings.Color

        -- 1. ハイライトの制御
        if TargetStrafe.Settings.TargetHighlight then
            if not currentHighlight or currentHighlight.Parent ~= currentTarget then
                currentHighlight = clear(currentHighlight)
                currentHighlight = create("Highlight", {
                    OutlineColor = Color3.fromRGB(255, 255, 255),
                    FillTransparency = 0.65,
                    OutlineTransparency = 0.1,
                    Adornee = currentTarget,
                    Parent = currentTarget
                })
            end
            currentHighlight.FillColor = color
        else
            currentHighlight = clear(currentHighlight)
        end

        -- 2. 球体周回エフェクトの制御
        if TargetStrafe.Settings.DrawCircle then
            createOrbitSpheres()
            local radius = TargetStrafe.Settings.DistanceValue * 0.85
            local baseAngle = os.clock() * 5.0
            local floorOffset = getPivotOffset(currentTarget)

            for i, sphereData in ipairs(orbitSpheres) do
                local angle = baseAngle + (i * (math.pi * 2 / 3))
                local pos = targetPos + Vector3.new(
                    math.cos(angle) * radius,
                    (math.sin(angle) * 1.5) + (floorOffset * 0.4),
                    math.sin(angle) * radius
                )
                sphereData.Part.CFrame = CFrame.new(pos)
                sphereData.Part.Color = color
                sphereData.Trail.Color = ColorSequence.new(color)
            end
        else
            for _, s in ipairs(orbitSpheres) do clear(s.Part) end
            table.clear(orbitSpheres)
        end

        -- 3. トレーサーの制御
        if TargetStrafe.Settings.TargetTracer then
            if not tracerBeam then
                localAttachment = create("Attachment", {Parent = myRoot})
                targetAttachment = create("Attachment", {Parent = targetRoot})
                tracerBeam = create("Beam", {
                    Attachment0 = localAttachment,
                    Attachment1 = targetAttachment,
                    Width0 = 0.15,
                    Width1 = 0.15,
                    FaceCamera = true,
                    Transparency = NumberSequence.new(0.3),
                    Parent = workspace.Terrain
                })
            end
            tracerBeam.Color = ColorSequence.new(color)
        else
            tracerBeam = clear(tracerBeam)
            localAttachment = clear(localAttachment)
            targetAttachment = clear(targetAttachment)
        end

        -- 4. 3D Floating HUDの制御
        if TargetStrafe.Settings.DrawBillboard then
            if not targetBillboard then
                targetBillboard = createBillboard(targetRoot)
            end
            
            local frame = targetBillboard:FindFirstChild("MainFrame")
            if frame then
                local targetHumanoid = currentTarget:FindFirstChildOfClass("Humanoid")
                local hp = targetHumanoid and targetHumanoid.Health or 0
                local maxHp = targetHumanoid and targetHumanoid.MaxHealth or 100
                
                local nameLabel = frame:FindFirstChild("NameLabel")
                if nameLabel then nameLabel.Text = string.format("%s (%d HP)", targetName, math.round(hp)) end

                local distLabel = frame:FindFirstChild("DistLabel")
                if distLabel then distLabel.Text = string.format("Distance: %d studs", math.round((myPos - targetPos).Magnitude)) end

                local hpBg = frame:FindFirstChild("HPBackground")
                local hpBar = hpBg and hpBg:FindFirstChild("HPBar")
                if hpBar then
                    hpBar.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
                    hpBar.BackgroundColor3 = color
                end
            end
        else
            targetBillboard = clear(targetBillboard)
        end

        -- 旋回と移動方向の計算
        theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt) % (math.pi * 2)
        local desiredDistance = TargetStrafe.Settings.DistanceValue
        local nextPos = Vector3.new(
            targetPos.X + math.cos(theta) * desiredDistance,
            myPos.Y,
            targetPos.Z + math.sin(theta) * desiredDistance
        )
        local moveDirection = (nextPos - myPos).Unit

        -- ヘルパー関数で壁・奈落を検知して反転
        if checkObstacles(myPos, moveDirection, myCharacter) and (os.clock() - lastDirectionSwitchTime > 0.5) then
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
            cleanupVisuals()
            lastTargetName = nil
        end
        if humanoid.MoveDirection ~= Vector3.zero then
            humanoid:Move(Vector3.zero, false)
        end
    end
end

-- モジュールの有効化/無効化
function TargetStrafe.Callback(enabled)
    if enabled then
        theta, direction, lastDirectionSwitchTime, currentTarget, lastTargetName, firstHeartbeatFired, lastPeriodicLog = 0, 1, 0, nil, nil, false, 0
        connection = RunService.Heartbeat:Connect(onHeartbeat)
    else
        if connection then connection:Disconnect() connection = nil end
        cleanupVisuals()
        if lplr.Character then
            local humanoid = lplr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:Move(Vector3.zero, false) end
        end
    end
end

return TargetStrafe