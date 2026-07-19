-- サービスの取得
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ローカルプレイヤー
local lplr = Players.LocalPlayer

-- UIテーブルの初期化
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
}

-- 各種変数の初期化
local connection, currentTarget = nil, nil
local theta, direction, lastDirectionSwitchTime = 0, 1, 0

-- デバッグ用の変数
local lastTargetName = nil
local lastHeartbeatCheck = 0

-- ========================================================
-- 【ヘルパー関数群】
-- ========================================================

-- 壁と奈落を検知する（デバッグ情報付き）
local function checkObstacles(myPos, dir, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    
    -- 下方向への判定を深く（-100 studs）して、ジャンプ中（Freefall）でも床を検知しやすくする
    local rayDown = workspace:Raycast(myPos + dir * 2.5, Vector3.new(0, -100, 0), params)
    local isVoid = not rayDown
    
    local wall = workspace:Raycast(myPos, dir * 2, params)
    local isWall = wall and wall.Instance and wall.Instance.CanCollide
    
    if isVoid then
        return true, "Void"
    elseif isWall then
        return true, "Wall (" .. wall.Instance.Name .. ")"
    end
    return false, nil
end

-- ターゲット取得
local function findClosestTarget(rangeLimit)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter.PrimaryPart
    if not myRoot then 
        return nil 
    end

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
    print("[TargetStrafe Debug] Init called (UI creation)")
    UI = UI or {}

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
end

-- Strafe処理
local function onHeartbeat(dt)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    
    -- 5秒おきに動作中であることをログに表示（動作の生存確認）
    if os.clock() - lastHeartbeatCheck > 5 then
        lastHeartbeatCheck = os.clock()
        local charExists = myCharacter ~= nil
        local rootExists = myRoot ~= nil
        local humState = humanoid and humanoid:GetState().Name or "None"
        print(string.format("[TargetStrafe Debug] Heartbeat active. Character: %s, Root: %s, State: %s", tostring(charExists), tostring(rootExists), humState))
    end

    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end

    currentTarget = findClosestTarget(TargetStrafe.Settings.SearchRangeValue)
    
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos, targetPos = myRoot.Position, targetRoot.Position
        local targetName = currentTarget.Name

        -- ターゲットの切り替わり
        if lastTargetName ~= targetName then
            print("[TargetStrafe Debug] Target Changed: " .. targetName .. " | Distance: " .. math.round((myPos - targetPos).Magnitude) .. " studs")
            lastTargetName = targetName
        end

        -- 旋回と移動方向の初期計算
        theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt) % (math.pi * 2)
        local desiredDistance = TargetStrafe.Settings.DistanceValue
        local nextPos = Vector3.new(
            targetPos.X + math.cos(theta) * desiredDistance,
            myPos.Y,
            targetPos.Z + math.sin(theta) * desiredDistance
        )
        local moveDirection = (nextPos - myPos).Unit

        -- 壁・奈落を検知して反転
        local hasObstacle, obstacleType = checkObstacles(myPos, moveDirection, myCharacter)
        if hasObstacle and (os.clock() - lastDirectionSwitchTime > 0.5) then
            direction = -direction 
            lastDirectionSwitchTime = os.clock()
            print("[TargetStrafe Debug] " .. obstacleType .. " detected! Switched direction to: " .. direction)
            
            -- 【重要】returnせず、そのフレーム内で即座に逆方向へ再計算して動き続ける
            theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt * 3) % (math.pi * 2)
            nextPos = Vector3.new(
                targetPos.X + math.cos(theta) * desiredDistance,
                myPos.Y,
                targetPos.Z + math.sin(theta) * desiredDistance
            )
            moveDirection = (nextPos - myPos).Unit
        end

        -- 実際にキャラクターを移動・回転させる
        humanoid:Move(moveDirection, false)
        myRoot.CFrame = CFrame.lookAt(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
        
        if TargetStrafe.Settings.AutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
        end
    else
        -- ターゲットを見失った（いなくなった）場合
        if lastTargetName ~= nil then
            print("[TargetStrafe Debug] Lost target.")
            lastTargetName = nil
        end

        if humanoid.MoveDirection ~= Vector3.zero then
            humanoid:Move(Vector3.zero, false)
        end
    end
end

-- モジュールの有効化/無効化
function TargetStrafe.Callback(enabled)
    print("[TargetStrafe Debug] Callback toggled. Enabled state: " .. tostring(enabled))
    if enabled then
        theta, direction, lastDirectionSwitchTime, currentTarget, lastTargetName = 0, 1, 0, nil, nil
        connection = RunService.Heartbeat:Connect(onHeartbeat)
        print("[TargetStrafe Debug] Heartbeat event connected.")
    else
        if connection then 
            connection:Disconnect() 
            connection = nil 
            print("[TargetStrafe Debug] Heartbeat event disconnected.")
        end
        if lplr.Character then
            local humanoid = lplr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then 
                humanoid:Move(Vector3.zero, false) 
            end
        end
    end
end

return TargetStrafe