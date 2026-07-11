-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")

local Speed = {
    Name = "Speed",
    Description = "Increases your movement using TPWalk (CFrame teleportation).",
    TargetGame = "1_8arena"
}

-- 設定値テーブル
Speed.Settings = {
    SpeedValue = 30,
    AutoJump = false
}

-- UIパラメータのプレースホルダー
local Value = { Value = 30 }
local AutoJump = { Enabled = false }

local moduleInstance = nil

function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- スライダーUIの作成 (TPWalkの移動速度)
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

    -- オートジャンプトグルの作成
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
        print("[Speed Debug] TPWalk Module Enabled.")
        
        local connection
        
        connection = RunService.PreSimulation:Connect(function(dt)
            -- 共通の vape / entitylib ライブラリを安全に動的取得
            local vape = shared.vape or _G.mainapi
            local entitylib = vape and vape.Libraries and vape.Libraries.entity
            local calcMoveVec = getgenv().calculateMoveVector or calculateMoveVector

            -- ライブラリや計算関数が未ロードの場合は処理をスキップ
            if not entitylib or not calcMoveVec then
                return
            end

            -- entitylib を通じてローカルプレイヤーが生存しているか、キャラクターが紐づいているか確認
            if not entitylib.isAlive or not entitylib.character then
                return
            end

            local character = entitylib.character
            local root = character.RootPart
            local humanoid = character.Humanoid

            if not root then
                return
            end

            local success, err = pcall(function()
                -- 入力方向ベクトルの取得
                local movevec = calcMoveVec()
                if movevec.Magnitude > 0 then
                    -- TPWalk実行: デルタタイム(dt)を乗算してフレームレート依存のない滑らかな移動を実現
                    -- 速度設定値の大きさに応じたCFrameのテレポート加算を行います
                    root.CFrame = root.CFrame + (movevec * Value.Value * dt)

                    -- オートジャンプが有効な場合の処理
                    if AutoJump.Enabled then
                        -- 接地状態の判定 (FloorMaterial を使用)
                        local onground = true
                        if humanoid and typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid") then
                            onground = humanoid.FloorMaterial ~= Enum.Material.Air
                        end

                        if onground then
                            -- 上方向の物理速度を適用してジャンプを発生させます
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
        print("[Speed Debug] TPWalk Module Disabled.")
    end
end

return Speed