-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera

local Speed = {
    Name = "Speed",
    Description = "Increases your movement with self-simulated CFrame BHop physics.",
    TargetGame = "1_8arena"
}

-- 初期設定値
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

-- キャラクターのPivotから地面までのオフセットを自動計測する関数
local function getPivotOffset(model)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {model}
    
    local pivot = model:GetPivot()
    -- 20スタッド下方向にレイキャストして地面を検知
    local result = workspace:Raycast(pivot.Position, Vector3.new(0, -20, 0), raycastParams)
    if result then
        return pivot.Position.Y - result.Position.Y
    end
    return 3.0 -- 計測に失敗した場合の標準フォールバック
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

    -- 2. 自動ジャンプトグル (BHop)
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
            "[Speed Debug] Pure CFrame BHop Enabled. Settings: [Speed: %s] [AutoJump: %s]",
            tostring(Value.Value),
            tostring(AutoJump.Enabled)
        ))
        
        -- スパム防止および自作物理システム用のローカルステート
        local modelNotFoundLogged = false
        local characterFoundLogged = false
        local rootNotFoundLogged = false
        local lastMovingState = nil
        
        -- 🌟 自作物理ステート変数
        local verticalVelocity = 0
        local gravity = 196.2     -- Roblox標準重力
        local jumpVelocity = 50   -- Roblox標準ジャンプ初速
        local pivotOffset = 3.0   -- アバターに応じた地面までのオフセット
        local measuredOffset = false
        
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
            
            -- キャラクター検知および高さオフセットの自動計測
            if not characterFoundLogged then
                characterFoundLogged = true
                modelNotFoundLogged = false
                measuredOffset = true
                pivotOffset = getPivotOffset(model)
                print(string.format("[Speed Debug] Model loaded: %s | Measured Ground Offset: %.3f studs", model.Name, pivotOffset))
            end

            local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
            if not root then
                if not rootNotFoundLogged then
                    rootNotFoundLogged = true
                    warn("[Speed Debug] Root part not found inside the character model.")
                end
                return
            end
            rootNotFoundLogged = false

            local success, err = pcall(function()
                local dir = getMovementDirection()
                local isMoving = dir.Magnitude > 0

                -- 移動状態の変化検知ログ
                if isMoving ~= lastMovingState then
                    lastMovingState = isMoving
                    print(string.format(
                        "[Speed Debug] State Update -> IsMoving: %s (Dir: %s)",
                        tostring(isMoving),
                        tostring(dir)
                    ))
                end

                local cur = model:GetPivot()

                -- 1. 水平方向（X, Z）の移動計算
                local nextX = cur.Position.X + dir.X * (Value.Value * dt)
                local nextZ = cur.Position.Z + dir.Z * (Value.Value * dt)

                -- 2. 垂直方向（Y）の自作重力演算
                verticalVelocity = verticalVelocity - (gravity * dt)
                local targetY = cur.Position.Y + (verticalVelocity * dt)

                -- 3. 自作接地判定（真下へのショートレイキャスト）
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {model}
                
                -- 移動先座標の少し上（2スタッド）から15スタッド下に向けて、地面との交差を判定
                local rayStart = Vector3.new(nextX, targetY + 2, nextZ)
                local rayResult = workspace:Raycast(rayStart, Vector3.new(0, -15, 0), raycastParams)

                local groundY = nil
                if rayResult then
                    -- 地面の物理座標に自動計測したオフセットを乗せて「基準地面のCFrame Y」を決定
                    groundY = rayResult.Position.Y + pivotOffset
                end

                -- 計算上の高さが地面以下になった（着地した）場合の処理
                if groundY and targetY <= groundY then
                    targetY = groundY
                    verticalVelocity = 0 -- 落下速度の初期化
                    
                    -- 地面にいて、かつ移動入力がある場合は次のバニーホップを即座にシミュレート
                    if AutoJump.Enabled and isMoving then
                        verticalVelocity = jumpVelocity
                        print("[Speed Debug] [CFrame BHop] Ground hit. Automatically simulated jump force.")
                    end
                end

                -- 4. 計算した次フレームの3次元座標と回転を合わせてモデルを移動
                local nextPosition = Vector3.new(nextX, targetY, nextZ)
                model:PivotTo(CFrame.new(nextPosition) * (cur - cur.Position))
            end)
            
            if not success then
                warn("[Speed Hack Error]:", tostring(err))
            end
        end)
        
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("[Speed Debug] CFrame BHop Disabled.")
    end
end

return Speed