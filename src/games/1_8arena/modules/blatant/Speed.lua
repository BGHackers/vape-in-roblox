-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera

local Speed = {
    Name = "Speed",
    Description = "Increases your movement using FPS-independent TPWalk.",
    TargetGame = "1_8arena"
}

-- 初期設定値テーブル
Speed.Settings = {
    SpeedValue = 30,
    AutoJump = true
}

-- UIコンポーネント用プレースホルダー
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
    
    print("[Speed Init] Initializing UI components...")

    -- 1. 速度調整スライダー
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
            print("[Speed UI] Speed adjusted to: " .. tostring(val))
        end
    })

    -- 2. 自動ジャンプトグル
    AutoJump = moduleObj:CreateToggle({
        Name = "BHop / AutoJump",
        Default = Speed.Settings.AutoJump,
        Function = function(state)
            Speed.Settings.AutoJump = state
            print("[Speed UI] BHop / AutoJump toggled to: " .. tostring(state))
        end
    })
end

function Speed.Callback(enabled)
    if enabled then
        print(string.format(
            "[Speed Debug] TPWalk Enabled. Active settings: [Speed: %s] [AutoJump: %s]",
            tostring(Value.Value),
            tostring(AutoJump.Enabled)
        ))
        
        -- スパム防止用の各種状態記録バッファ
        local modelNotFoundLogged = false
        local characterFoundLogged = false
        local rootNotFoundLogged = false
        local lastMovingState = nil
        
        local connection
        
        connection = RunService.PreSimulation:Connect(function(dt)
            local vape = shared.vape or _G.mainapi
            local entitylib = vape and vape.Libraries and vape.Libraries.entity
            
            local model = getLocalCharacterModel(entitylib)
            if not model then
                if not modelNotFoundLogged then
                    modelNotFoundLogged = true
                    characterFoundLogged = false
                    warn("[Speed Debug] Local character model not found! Waiting for load...")
                end
                return
            end
            
            -- キャラクター検知時のログ
            if not characterFoundLogged then
                characterFoundLogged = true
                modelNotFoundLogged = false
                print("[Speed Debug] Local character model found: " .. tostring(model.Name))
            end

            local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not root then
                if not rootNotFoundLogged then
                    rootNotFoundLogged = true
                    warn("[Speed Debug] Root part (Torso/HumanoidRootPart) not found inside the character model.")
                end
                return
            end
            rootNotFoundLogged = false

            local success, err = pcall(function()
                local dir = getMovementDirection()
                local isMoving = dir.Magnitude > 0

                -- 移動状態の変化検知用ログ
                if isMoving ~= lastMovingState then
                    lastMovingState = isMoving
                    print(string.format(
                        "[Speed Debug] TPWalk State Update -> IsMoving: %s (Dir: %s)",
                        tostring(isMoving),
                        tostring(dir)
                    ))
                end

                -- =========================================================
                -- TPWalk (CFrameピボットテレポート方式)
                -- =========================================================
                if isMoving then
                    local cur = model:GetPivot()
                    -- FPSに依存しないよう経過時間(dt)を計算に乗じて等速化
                    local nextPosition = cur.Position + dir * (Value.Value * dt)
                    model:PivotTo(CFrame.new(nextPosition) * (cur - cur.Position))

                    -- TPWalk実行中のジャンプ処理
                    if AutoJump.Enabled then
                        local onground = false
                        if humanoid then
                            onground = humanoid.FloorMaterial ~= Enum.Material.Air
                        else
                            -- Humanoidが存在しない場合の代替接地判定
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                            raycastParams.FilterDescendantsInstances = {model}
                            local result = workspace:Raycast(root.Position, Vector3.new(0, -3.5, 0), raycastParams)
                            onground = result ~= nil
                        end

                        if onground then
                            if humanoid then
                                print("[Speed Debug] [TPWalk] Ground detected. Triggering standard Jump.")
                                humanoid.Jump = true
                            else
                                print("[Speed Debug] [TPWalk] Ground detected (No Humanoid). Triggering fallback jump velocity.")
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
        print("[Speed Debug] TPWalk Disabled.")
    end
end

return Speed