-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera

local Speed = {
    Name = "Speed",
    Description = "Increases your movement using CFrame Pivot TPWalk.",
    TargetGame = "1_8arena"
}

-- 設定値テーブル
Speed.Settings = {
    SpeedValue = 30,
    AutoJump = false
}

-- UIパラメータ用のプレースホルダー
local Value = { Value = 30 }
local AutoJump = { Enabled = false }

local moduleInstance = nil

-- デバイスを問わず現在の移動方向を安全に算出する関数
local function getMovementDirection()
    -- 1. init.lua が提供するマルチデバイス対応の計算ベクトルを最優先で使用
    local calcMoveVec = getgenv().calculateMoveVector
    if calcMoveVec then
        local success, vec = pcall(calcMoveVec)
        if success and vec and vec.Magnitude > 0 then
            return vec
        end
    end
    
    -- 2. 上記が利用できない場合、キーボード（WASD）とカメラ向きによるフォールバック計算
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

-- 安全にキャラクターモデルを特定する関数
local function getLocalCharacterModel(entitylib)
    -- 1. entitylib から直接キャラクターのモデルを取得
    if entitylib and entitylib.isAlive and entitylib.character then
        if typeof(entitylib.character.Character) == "Instance" then
            return entitylib.character.Character
        end
    end
    -- 2. entitylib が遅延している場合のフォールバック（1_8arena専用 ＋ 通常Robloxモデル）
    return workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) or lplr.Character
end

function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- スライダーUIの生成（最大150スタッド/秒までサポート）
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

    -- オートジャンプトグルの生成
    AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump",
        Default = Speed.Settings.AutoJump or false,
        Function = function(state)
            Speed.Settings.AutoJump = state
        end
    })
end

function Speed.Callback(enabled)
    if enabled then
        print("[Speed Debug] CFrame Pivot TPWalk Enabled.")
        
        local connection
        
        connection = RunService.PreSimulation:Connect(function(dt)
            local vape = shared.vape or _G.mainapi
            local entitylib = vape and vape.Libraries and vape.Libraries.entity
            
            -- 移動対象となるキャラクターモデルの安全な取得
            local model = getLocalCharacterModel(entitylib)
            if not model then
                return
            end

            local success, err = pcall(function()
                -- 入力された移動方向を取得
                local dir = getMovementDirection()
                if dir.Magnitude > 0 then
                    -- 現在のピボットCFrameを取得
                    local cur = model:GetPivot()
                    
                    -- 🌟 経過時間(dt)を掛け合わせ、FPSに依存しない正確な速度 (Value.Value スタッド/秒) で移動位置を計算
                    local nextPosition = cur.Position + dir * (Value.Value * dt)
                    
                    -- 元の向き成分 (cur - cur.Position) を乗算してキャラクターの角度を崩さずにモデル全体を移動
                    model:PivotTo(CFrame.new(nextPosition) * (cur - cur.Position))

                    -- オートジャンプ処理
                    if AutoJump.Enabled then
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
                        
                        if humanoid then
                            -- 接地判定を確認し標準ジャンプ処理を実行
                            if humanoid.FloorMaterial ~= Enum.Material.Air then
                                humanoid.Jump = true
                            end
                        elseif root then
                            -- カスタムキャラクター用物理フォールバック（垂直速度の変更）
                            root.AssemblyLinearVelocity = Vector3.new(
                                root.AssemblyLinearVelocity.X,
                                50,
                                root.AssemblyLinearVelocity.Z
                            )
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
        print("[Speed Debug] CFrame Pivot TPWalk Disabled.")
    end
end

return Speed