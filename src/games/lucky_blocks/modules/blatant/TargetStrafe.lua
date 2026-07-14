-- games/lucky_blocks/modules/blatant/TargetStrafe.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

local TargetStrafe = {
    Name = "TargetStrafe",
    Description = "Automatically circles around your target opponent with void and wall prevention.",
    TargetGame = "lucky_blocks"
}

-- 初期設定値
TargetStrafe.Settings = {
    DistanceValue = 6,
    SpeedValue = 10,
    SearchRangeValue = 30,
    AutoJump = true
}

local Distance = { Value = 6 }
local Speed = { Value = 10 }
local SearchRange = { Value = 30 }
local AutoJump = { Enabled = true }

local moduleInstance = nil
local theta = 0 -- 旋回の角度ステート
local direction = 1 -- 1 = 時計回り, -1 = 反時計回り
local lastDirectionSwitch = 0

-- 🌟 【新規】アバターに応じた地面から腰（RootPart）までの正確な高さを計算する関数
local function getPivotOffset(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
    
    if humanoid and typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid") then
        if humanoid.RigType == Enum.RigType.R6 then
            return 3.0 -- R6アバターの標準高度
        else
            local rootSizeY = root and root.Size.Y or 2
            return humanoid.HipHeight + (rootSizeY / 2) -- R15アバターの標準高度
        end
    end
    return 3.0
end

-- 最も近くにいるプレイヤーを検出
local function getClosestTarget(rangeLimit)
    local character = lplr.Character
    local localRoot = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
    if not localRoot then return nil end

    local target = nil
    local closestDist = rangeLimit

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lplr and v.Character then
            local root = v.Character:FindFirstChild("HumanoidRootPart") or v.Character:FindFirstChild("Torso")
            if root then
                local dist = (localRoot.Position - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    target = v.Character
                end
            end
        end
    end
    return target
end

function TargetStrafe.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[TargetStrafe.Name] = moduleObj
    
    print("[TargetStrafe Init] Initializing Safe UI components...")

    Distance = moduleObj:CreateSlider({
        Name = "Strafe Distance",
        Min = 2,
        Max = 20,
        Default = TargetStrafe.Settings.DistanceValue or 6,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.DistanceValue = val end
    })

    Speed = moduleObj:CreateSlider({
        Name = "Strafe Speed",
        Min = 1,
        Max = 30,
        Default = TargetStrafe.Settings.SpeedValue or 10,
        Suffix = function(val) return "" end,
        Function = function(val) TargetStrafe.Settings.SpeedValue = val end
    })

    SearchRange = moduleObj:CreateSlider({
        Name = "Search Range",
        Min = 10,
        Max = 50,
        Default = TargetStrafe.Settings.SearchRangeValue or 30,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.SearchRangeValue = val end
    })

    AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump (BHop)",
        Default = TargetStrafe.Settings.AutoJump,
        Function = function(state) TargetStrafe.Settings.AutoJump = state end
    })
end

function TargetStrafe.Callback(enabled)
    if enabled then
        print("[TargetStrafe Debug] Ground-Locked TargetStrafe Enabled.")
        theta = 0
        direction = 1
        lastDirectionSwitch = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function(dt)
            local character = lplr.Character
            if not character then return end
            
            local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not root or not humanoid then return end
            
            -- ロックオン対象を検索
            local targetChar = getClosestTarget(SearchRange.Value)
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
                if targetRoot then
                    -- 旋回角度の更新
                    theta = (theta + direction * Speed.Value * dt) % (math.pi * 2)
                    
                    local targetPos = targetRoot.Position
                    local localPos = root.Position
                    
                    local nextX = targetPos.X + math.cos(theta) * Distance.Value
                    local nextZ = targetPos.Z + math.sin(theta) * Distance.Value
                    
                    -- 🌟 【修正】沈み込みを完全に防ぐY座標（高さ）の制御システム
                    local nextY = localPos.Y
                    local pivotOffset = getPivotOffset(character)
                    
                    -- レイキャスト用の除外設定
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {character, targetChar}
                    
                    -- 移動予定の先の地面をレイキャストで検出
                    local floorOrigin = Vector3.new(nextX, localPos.Y + 3, nextZ)
                    local floorResult = workspace:Raycast(floorOrigin, Vector3.new(0, -25, 0), params)
                    local voidDetected = (floorResult == nil)
                    
                    if floorResult then
                        local groundY = floorResult.Position.Y + pivotOffset
                        
                        if humanoid.FloorMaterial ~= Enum.Material.Air then
                            -- 地上にいる場合：Y座標を床の高さに強制ロックして沈み込みを完全にゼロにします
                            nextY = groundY
                        else
                            -- 空中にいる場合（ジャンプ・落下中）：落下時に床を貫通しないよう、着地寸前のみ地面にスナップ
                            if localPos.Y - groundY < 0.5 then
                                nextY = groundY
                            end
                        end
                    end
                    
                    local nextPosition = Vector3.new(nextX, nextY, nextZ)
                    
                    -- 移動方向ベクトル
                    local moveVec = (nextPosition - localPos)
                    local moveDir = moveVec.Magnitude > 0 and moveVec.Unit or root.CFrame.LookVector
                    
                    -- 壁検知システム
                    local hipOrigin = localPos + Vector3.new(0, 0.5, 0)
                    local wallResult = workspace:Raycast(hipOrigin, moveDir * 4, params)
                    
                    local wallDetected = false
                    local highWallDetected = false
                    
                    if wallResult and wallResult.Instance and wallResult.Instance.CanCollide then
                        wallDetected = true
                        local headOrigin = localPos + Vector3.new(0, 3, 0)
                        local headResult = workspace:Raycast(headOrigin, moveDir * 4, params)
                        if headResult and headResult.Instance and headResult.Instance.CanCollide then
                            highWallDetected = true
                        end
                    end
                    
                    -- 旋回反転トリガー（奈落 or 高すぎる壁に直面した場合）
                    if (voidDetected or highWallDetected) and (os.clock() - lastDirectionSwitch > 0.5) then
                        direction = -direction
                        lastDirectionSwitch = os.clock()
                        theta = (theta - 2 * direction * Speed.Value * dt) % (math.pi * 2)
                        return
                    end
                    
                    -- 通常の自動壁ジャンプ
                    if wallDetected and not highWallDetected then
                        humanoid.Jump = true
                    end
                    
                    -- 落下しない（安全な床が確保されている）場合のみ移動を実行
                    if not voidDetected then
                        local lookCFrame = CFrame.lookAt(nextPosition, Vector3.new(targetPos.X, nextPosition.Y, targetPos.Z))
                        character:PivotTo(lookCFrame)
                        
                        -- 通常時のAutoJump (BHop)
                        if AutoJump.Enabled and humanoid.FloorMaterial ~= Enum.Material.Air then
                            humanoid.Jump = true
                        end
                    end
                end
            end
        end)
        
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("[TargetStrafe Debug] TargetStrafe Disabled.")
    end
end

return TargetStrafe