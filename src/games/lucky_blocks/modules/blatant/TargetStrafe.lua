-- games/lucky_blocks/modules/blatant/TargetStrafe.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

local TargetStrafe = {
    Name = "TargetStrafe",
    Description = "Automatically circles around your target opponent to evade hits.",
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

-- 最も近くにいるプレイヤーを検出（HP判定なし仕様）
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
    
    print("[TargetStrafe Init] Initializing UI components...")

    -- 1. 旋回半径の設定
    Distance = moduleObj:CreateSlider({
        Name = "Strafe Distance",
        Min = 2,
        Max = 20,
        Default = TargetStrafe.Settings.DistanceValue or 6,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.DistanceValue = val end
    })

    -- 2. 旋回速度の設定
    Speed = moduleObj:CreateSlider({
        Name = "Strafe Speed",
        Min = 1,
        Max = 30,
        Default = TargetStrafe.Settings.SpeedValue or 10,
        Suffix = function(val) return "" end,
        Function = function(val) TargetStrafe.Settings.SpeedValue = val end
    })

    -- 3. 索敵ロックオン範囲の設定
    SearchRange = moduleObj:CreateSlider({
        Name = "Search Range",
        Min = 10,
        Max = 50,
        Default = TargetStrafe.Settings.SearchRangeValue or 30,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.SearchRangeValue = val end
    })

    -- 4. 自動ジャンプ（BHop）トグル
    AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump (BHop)",
        Default = TargetStrafe.Settings.AutoJump,
        Function = function(state) TargetStrafe.Settings.AutoJump = state end
    })
end

function TargetStrafe.Callback(enabled)
    if enabled then
        print("[TargetStrafe Debug] TargetStrafe Enabled.")
        theta = 0 -- 開始時に旋回角度をリセット
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
                    -- 円形座標のラジアン角度を進める
                    theta = (theta + Speed.Value * dt) % (math.pi * 2)
                    
                    -- 敵の位置を中心とした円軌道の新座標を三角関数（sin, cos）で計算
                    local targetPos = targetRoot.Position
                    local localPos = root.Position
                    
                    local nextX = targetPos.X + math.cos(theta) * Distance.Value
                    local nextZ = targetPos.Z + math.sin(theta) * Distance.Value
                    local nextY = localPos.Y -- 高さはプレイヤーの物理位置をそのまま維持
                    
                    local nextPosition = Vector3.new(nextX, nextY, nextZ)
                    
                    -- 🌟 敵の方向を向きつつ、算出した周回軌道へキャラクターをスムーズにCFrame移動
                    local lookCFrame = CFrame.lookAt(nextPosition, Vector3.new(targetPos.X, nextPosition.Y, targetPos.Z))
                    character:PivotTo(lookCFrame)
                    
                    -- 地上にいる場合のみ自動ジャンプを実行（バニーホップ）
                    if AutoJump.Enabled and humanoid.FloorMaterial ~= Enum.Material.Air then
                        humanoid.Jump = true
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