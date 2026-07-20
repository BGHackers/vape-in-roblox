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
    Visuals = true, -- ビジュアル表示の初期設定
}

-- 各種変数の初期化
local connection, currentTarget = nil, nil
local theta, direction, lastDirectionSwitchTime = 0, 1, 0

-- デバッグ・すり抜け防止用の変数
local lastTargetName = nil
local lastHeartbeatCheck = 0
local lastSafeCFrame = nil -- 安全な座標を保存する変数

-- ビジュアル用のオブジェクト変数
local visualRing = nil
local myAttachment = nil
local targetAttachment = nil
local visualBeam = nil

-- ========================================================
-- 【ヘルパー関数群】
-- ========================================================

-- Partの内部（バウンディングボックス内）に座標があるかを正確に判定する（傾き対応）
local function isInsidePart(part, pos)
    if not part then return false end
    local localPos = part.CFrame:PointToObjectSpace(pos)
    local size = part.Size
    return math.abs(localPos.X) < size.X / 2
       and math.abs(localPos.Y) < size.Y / 2
       and math.abs(localPos.Z) < size.Z / 2
end

-- 先回りで壁と奈落を検知する（改善：検知範囲の多角化）
local function checkObstacles(myPos, dir, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    
    -- 1. 奈落の先回り検知（進行方向の少し先から斜め下へキャスト）
    local checkDist = 3
    local nextFloorPos = myPos + dir * checkDist
    local rayDown = workspace:Raycast(nextFloorPos, Vector3.new(0, -15, 0), params)
    local isVoid = not rayDown
    
    -- 2. 壁の先回り検知（正面に加え、左右30度の斜め前方へキャストして壁への擦り付けを回避）
    local isWall = false
    local wallName = ""
    local directionsToCheck = {
        dir * 2.5,
        (CFrame.Angles(0, math.rad(30), 0) * dir) * 2,
        (CFrame.Angles(0, math.rad(-30), 0) * dir) * 2
    }
    
    for _, d in ipairs(directionsToCheck) do
        local wall = workspace:Raycast(myPos, d, params)
        if wall and wall.Instance and wall.Instance.CanCollide then
            isWall = true
            wallName = wall.Instance.Name
            break
        end
    end
    
    if isVoid then
        return true, "Void"
    elseif isWall then
        return true, "Wall (" .. wallName .. ")"
    end
    return false, nil
end

-- ターゲット取得（改善：生存確認および無敵判定の追加）
local function findClosestTarget(rangeLimit)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter.PrimaryPart
    if not myRoot then 
        return nil 
    end

    local closestTarget, minDistance = nil, rangeLimit
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character.PrimaryPart then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            -- 生存しており、初期スポーンなどの無敵状態（ForceField）ではないプレイヤーのみを狙う
            if hum and hum.Health > 0 and not char:FindFirstChildOfClass("ForceField") then
                local distance = (myRoot.Position - char.PrimaryPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestTarget = char
                end
            end
        end
    end
    return closestTarget
end

-- ビジュアル（足元の白い輪 ＋ 自分と繋ぐ白いビーム）の作成・更新
local function updateVisuals(targetChar)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

    -- ビジュアルが無効、またはターゲットや自分が無効な場合は非表示にする
    if not TargetStrafe.Settings.Visuals or not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") or not myRoot then
        if visualRing then visualRing.Visible = false end
        if visualBeam then visualBeam.Enabled = false end
        return
    end

    local targetRoot = targetChar.HumanoidRootPart
    local themeColor = Color3.fromRGB(255, 255, 255) -- 白（動画のスタイルに合わせる）

    -- 1. ターゲットの足元の白い平らな円 (CylinderHandleAdornment)
    if not visualRing or visualRing.Parent == nil then
        visualRing = Instance.new("CylinderHandleAdornment")
        visualRing.Name = "StrafeVisualRing"
        visualRing.Height = 0.01 -- 極限まで薄くして地面に平らに見せる
        visualRing.Color3 = themeColor
        visualRing.AlwaysOnTop = true -- 壁越しでも表示
        visualRing.ZIndex = 5
        visualRing.Transparency = 0.8 -- 動画のような薄い半透明
        visualRing.Parent = workspace:WaitForChild("Terrain")
    end

    visualRing.Adornee = targetRoot
    visualRing.Radius = TargetStrafe.Settings.DistanceValue
    -- ターゲットの足元に位置合わせし、Cylinderを水平にするために回転
    visualRing.CFrame = CFrame.new(0, -2, 0) * CFrame.Angles(math.rad(90), 0, 0)
    visualRing.Visible = true

    -- 2. 自分と相手を繋ぐ光る白いビーム (Beam)
    -- 自分側のアタッチメント作成
    if not myAttachment or myAttachment.Parent ~= myRoot then
        if myAttachment then myAttachment:Destroy() end
        myAttachment = Instance.new("Attachment")
        myAttachment.Name = "StrafeMyAttachment"
        myAttachment.Parent = myRoot
    end

    -- ターゲット側のアタッチメント作成
    if not targetAttachment or targetAttachment.Parent ~= targetRoot then
        if targetAttachment then targetAttachment:Destroy() end
        targetAttachment = Instance.new("Attachment")
        targetAttachment.Name = "StrafeTargetAttachment"
        targetAttachment.Parent = targetRoot
    end

    -- ビーム本体の作成・更新
    if not visualBeam or visualBeam.Parent == nil then
        visualBeam = Instance.new("Beam")
        visualBeam.Name = "StrafeVisualBeam"
        visualBeam.Color = ColorSequence.new(themeColor)
        visualBeam.LightEmission = 1 -- ネオンのように発光させる
        visualBeam.LightInfluence = 0
        visualBeam.Width0 = 0.08 -- 開始点の太さ（動画のように細く綺麗に）
        visualBeam.Width1 = 0.08 -- 終了点の太さ
        visualBeam.TextureSpeed = 0
        visualBeam.FaceCamera = true
        visualBeam.Parent = workspace:WaitForChild("Terrain")
    end

    visualBeam.Attachment0 = myAttachment
    visualBeam.Attachment1 = targetAttachment
    visualBeam.Enabled = true
end

-- ビジュアルの完全消去
local function clearVisuals()
    if visualRing then
        visualRing:Destroy()
        visualRing = nil
    end
    if visualBeam then
        visualBeam:Destroy()
        visualBeam = nil
    end
    if myAttachment then
        myAttachment:Destroy()
        myAttachment = nil
    end
    if targetAttachment then
        targetAttachment:Destroy()
        targetAttachment = nil
    end
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
    -- ビジュアル表示のON/OFFトグルを追加
    UI.Visuals = moduleObj:CreateToggle({
        Name = "Show Visuals",
        Default = TargetStrafe.Settings.Visuals,
        Function = function(state) TargetStrafe.Settings.Visuals = state end
    })
end

-- Strafe処理
local function onHeartbeat(dt)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    
    -- 5秒おきの生存チェック
    if os.clock() - lastHeartbeatCheck > 5 then
        lastHeartbeatCheck = os.clock()
        local charExists = myCharacter ~= nil
        local rootExists = myRoot ~= nil
        local humState = humanoid and humanoid:GetState().Name or "None"
        print(string.format("[TargetStrafe Debug] Heartbeat active. Character: %s, Root: %s, State: %s", tostring(charExists), tostring(rootExists), humState))
    end

    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        updateVisuals(nil) -- ビジュアルをオフにする
        return
    end

    -- ========================================================
    -- 【LoadingBlocker すり抜け・侵入検知システム】
    -- ========================================================
    local loadingBlocker = workspace:FindFirstChild("Misc") and workspace.Misc:FindFirstChild("LoadingBlocker")
    if loadingBlocker and loadingBlocker:IsA("BasePart") then
        if isInsidePart(loadingBlocker, myRoot.Position) then
            if lastSafeCFrame then
                myRoot.CFrame = lastSafeCFrame
                print("[TargetStrafe Debug] LoadingBlocker bypass blocked! Teleported back to safety.")
                return 
            else
                local blockerCF = loadingBlocker.CFrame
                local blockerSize = loadingBlocker.Size
                myRoot.CFrame = blockerCF * CFrame.new(0, 0, blockerSize.Z / 2 + 5)
                print("[TargetStrafe Debug] Initial LoadingBlocker bypass blocked! Forced player out.")
                return
            end
        else
            lastSafeCFrame = myRoot.CFrame
        end
    end
    -- ========================================================

    currentTarget = findClosestTarget(TargetStrafe.Settings.SearchRangeValue)
    
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos, targetPos = myRoot.Position, targetRoot.Position
        local targetName = currentTarget.Name

        -- ビジュアルを更新（白いサークルと白いレーザー）
        updateVisuals(currentTarget)

        -- ターゲット変更時の処理
        if lastTargetName ~= targetName then
            print("[TargetStrafe Debug] Target Changed: " .. targetName .. " | Distance: " .. math.round((myPos - targetPos).Magnitude) .. " studs")
            lastTargetName = targetName
            
            local relative = myPos - targetPos
            theta = math.atan2(relative.Z, relative.X)
            print("[TargetStrafe Debug] Initialized start theta to: " .. tostring(theta))
        end

        -- 旋回角度の更新
        theta = (theta + direction * (TargetStrafe.Settings.SpeedValue / TargetStrafe.Settings.DistanceValue) * dt) % (math.pi * 2)
        local desiredDistance = TargetStrafe.Settings.DistanceValue
        local nextPos = Vector3.new(
            targetPos.X + math.cos(theta) * desiredDistance,
            myPos.Y, -- 自身の高さを保持
            targetPos.Z + math.sin(theta) * desiredDistance
        )
        local moveDirection = (nextPos - myPos).Unit

        -- 壁・奈落を検知して反転
        local hasObstacle, obstacleType = checkObstacles(myPos, moveDirection, myCharacter)
        if hasObstacle and (os.clock() - lastDirectionSwitchTime > 0.5) then
            direction = -direction 
            lastDirectionSwitchTime = os.clock()
            print("[TargetStrafe Debug] " .. obstacleType .. " detected! Switched direction to: " .. direction)
            
            theta = (theta + direction * (TargetStrafe.Settings.SpeedValue / TargetStrafe.Settings.DistanceValue) * dt * 3) % (math.pi * 2)
            nextPos = Vector3.new(
                targetPos.X + math.cos(theta) * desiredDistance,
                myPos.Y,
                targetPos.Z + math.sin(theta) * desiredDistance
            )
            moveDirection = (nextPos - myPos).Unit
        end

        -- ========================================================
        -- 【改善：アセンブリ速度（物理）の同期】
        -- ========================================================
        local targetVelocity = moveDirection * TargetStrafe.Settings.SpeedValue
        myRoot.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, myRoot.AssemblyLinearVelocity.Y, targetVelocity.Z)

        -- 位置の移動と向きの回転を同時に適用
        myRoot.CFrame = CFrame.lookAt(nextPos, Vector3.new(targetPos.X, nextPos.Y, targetPos.Z))
        -- ========================================================
        
        -- 自動ジャンプ処理
        if TargetStrafe.Settings.AutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
        end
    else
        updateVisuals(nil) -- ターゲットがいない場合はビジュアルをオフ
        if lastTargetName ~= nil then
            print("[TargetStrafe Debug] Lost target.")
            lastTargetName = nil
            myRoot.AssemblyLinearVelocity = Vector3.new(0, myRoot.AssemblyLinearVelocity.Y, 0)
        end
    end
end

-- モジュールの有効化/無効化
function TargetStrafe.Callback(enabled)
    print("[TargetStrafe Debug] Callback toggled. Enabled state: " .. tostring(enabled))
    if enabled then
        theta, direction, lastDirectionSwitchTime, currentTarget, lastTargetName, lastSafeCFrame = 0, 1, 0, nil, nil, nil
        connection = RunService.Heartbeat:Connect(onHeartbeat)
        print("[TargetStrafe Debug] Heartbeat event connected.")
    else
        if connection then 
            connection:Disconnect() 
            connection = nil 
            print("[TargetStrafe Debug] Heartbeat event disconnected.")
        end
        clearVisuals() -- 無効化時はビジュアルを完全に削除
    end
end

return TargetStrafe