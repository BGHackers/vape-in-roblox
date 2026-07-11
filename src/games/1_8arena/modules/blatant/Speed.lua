-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera

local Speed = {
    Name = "Speed",
    Description = "Increases your movement with dynamic custom methods.",
    TargetGame = "1_8arena"
}

-- 初期設定値テーブル（Method を追加）
Speed.Settings = {
    Method = "Velocity", -- デフォルトはマイクラ風物理速度
    SpeedValue = 30,
    AutoJump = true
}

-- UIコンポーネント用プレースホルダー
local Method = { Value = "Velocity" }
local Value = { Value = 30 }
local AutoJump = { Enabled = true }

local moduleInstance = nil

-- 移動ベクトルの算出（マルチデバイス・キーボード両対応）
local function getMovementDirection()
    local calcMoveVec = getgenv().calculateMoveVector
    if calcMoveVec then
        local success, vec = pcall(calcMoveVec)
        if success and vec and vec.Magnitude > 0 then
            return vec
        end
    end
    
    local look = Vector3.new(gameCamera.CFrame.LookVector.X, 0, gameCamera.CFrame.LookVector.Z)
    local right = Vector3.new(gameCamera.CFrame.RightVector.X, 0, gameCamera.CFrame.RightVector.Z)
    if look.Magnitude > 0 then look = look.Unit end
    if right.Magnitude > 0 then right = right.Unit end
    
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
    
    return dir.Magnitude > 0 and dir.Unit or Vector3.zero
end

-- 安全なローカルキャラクターモデルの取得
local function getLocalCharacterModel(entitylib)
    if entitylib and entitylib.isAlive and entitylib.character then
        if typeof(entitylib.character.Character) == "Instance" then
            return entitylib.character.Character
        end
    end
    return workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) or lplr.Character
end

function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- 🌟 1. 移動方式を選択するドロップダウンの追加
    Method = moduleObj:CreateDropdown({
        Name = "Method",
        List = {"Velocity", "TPWalk"},
        Default = Speed.Settings.Method or "Velocity",
        Function = function(val)
            Speed.Settings.Method = val
        end
    })

    -- 2. 速度調整スライダー
    Value = moduleObj:CreateSlider({
        Name = "Speed",
        Min = 1,
        Max = 150,
        Default = Speed.Settings.SpeedValue or 30,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Speed.Settings.SpeedValue = val
        end
    })

    -- 3. 自動ジャンプトグル (BHop / AutoJump)
    AutoJump = moduleObj:CreateToggle({
        Name = "BHop / AutoJump",
        Default = Speed.Settings.AutoJump,
        Function = function(state)
            Speed.Settings.AutoJump = state
        end
    })
end

function Speed.Callback(enabled)
    if enabled then
        print("[Speed Debug] Hybrid Speed Module Enabled.")
        
        local connection
        
        connection = RunService.PreSimulation:Connect(function(dt)
            local vape = shared.vape or _G.mainapi
            local entitylib = vape and vape.Libraries and vape.Libraries.entity
            
            local model = getLocalCharacterModel(entitylib)
            if not model then return end

            local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not root then return end

            local success, err = pcall(function()
                local dir = getMovementDirection()
                local isMoving = dir.Magnitude > 0

                if Method.Value == "Velocity" then
                    if isMoving then
                        local targetVel = dir * Value.Value
                        root.AssemblyLinearVelocity = Vector3.new(
                            targetVel.X,
                            root.AssemblyLinearVelocity.Y,
                            targetVel.Z
                        )
                    else
                        -- 静止時は慣性を瞬時に殺す
                        root.AssemblyLinearVelocity = Vector3.new(
                            0,
                            root.AssemblyLinearVelocity.Y,
                            0
                        )
                    end

                    -- 自動連続ジャンプ (BHop)
                    if AutoJump.Enabled and isMoving then
                        local onground = false
                        if humanoid then
                            onground = humanoid.FloorMaterial ~= Enum.Material.Air
                        else
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                            raycastParams.FilterDescendantsInstances = {model}
                            local result = workspace:Raycast(root.Position, Vector3.new(0, -3.5, 0), raycastParams)
                            onground = result ~= nil
                        end

                        if onground then
                            root.AssemblyLinearVelocity = Vector3.new(
                                root.AssemblyLinearVelocity.X,
                                38,
                                root.AssemblyLinearVelocity.Z
                            )
                        end
                    end

                -- =========================================================
                -- 方式 B: TPWalk (CFrameピボットテレポート)
                -- =========================================================
                elseif Method.Value == "TPWalk" then
                    if isMoving then
                        local cur = model:GetPivot()
                        -- FPSの影響を受けないように経過時間(dt)を計算に使用
                        local nextPosition = cur.Position + dir * (Value.Value * dt)
                        model:PivotTo(CFrame.new(nextPosition) * (cur - cur.Position))

                        -- TPWalk時のオートジャンプ
                        if AutoJump.Enabled then
                            if humanoid then
                                if humanoid.FloorMaterial ~= Enum.Material.Air then
                                    humanoid.Jump = true
                                end
                            else
                                root.AssemblyLinearVelocity = Vector3.new(
                                    root.AssemblyLinearVelocity.X,
                                    50,
                                    root.AssemblyLinearVelocity.Z
                                )
                            end
                        end
                    end
                end
            end)
            
            if not success then
                warn("[Speed Hack Error]:", tostring(err))
            end
        end)
        
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("[Speed Debug] Hybrid Speed Module Disabled.")
    end
end

return Speed