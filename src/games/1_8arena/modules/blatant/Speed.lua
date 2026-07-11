-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")

local Speed = {
    Name = "Speed",
    Description = "Increases your movement with various methods.",
    TargetGame = "1_8arena" -- 1.8 Arenaでのみ自動ロード
}

-- 設定値の初期値
Speed.Settings = {
    SpeedValue = 30,
    AutoJump = false
}

-- 各種UI要素のプレースホルダーオブジェクト
local Value = { Value = 30 }
local AutoJump = { Enabled = false }

-- 環境に依存しない getupvalue / setupvalue の取得
local getupvalue = (debug and debug.getupvalue) or getupvalue or (getgenv and getgenv().getupvalue) or (getfenv and getfenv().getupvalue)
local setupvalue = (debug and debug.setupvalue) or setupvalue or (getgenv and getgenv().setupvalue) or (getfenv and getfenv().setupvalue)

local moduleInstance = nil

function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- スライダーUIの生成
    Value = moduleObj:CreateSlider({
        Name = "Speed",
        Min = 1,
        Max = 90,
        Default = Speed.Settings.SpeedValue or 30,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Speed.Settings.SpeedValue = val
        end
    })

    -- トグルUIの生成
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
        print("[Speed Debug] Module Enabled.")
        
        local diagnosticsLogged = false
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            -- グローバル環境から最新の arena データおよび計算関数を取得
            local activeArena = getgenv().arena or arena
            local calcMoveVec = getgenv().calculateMoveVector or calculateMoveVector

            -- エクスプロイト環境、あるいは初期化関数の未ロード検知用セーフガード
            if not getupvalue or not setupvalue or not activeArena or not calcMoveVec then
                if not diagnosticsLogged then
                    diagnosticsLogged = true
                    warn("⚠️ --- Speed Diagnostics Failure ---")
                    warn("  - getupvalue function exists:", getupvalue ~= nil)
                    warn("  - setupvalue function exists:", setupvalue ~= nil)
                    warn("  - activeArena table exists:", activeArena ~= nil)
                    warn("  - calculateMoveVector exists:", calcMoveVec ~= nil)
                    warn("  Speed hack skipped to prevent client crash.")
                    warn("-------------------------------------")
                end
                return
            end

            -- 取得元の関数が存在しない場合はエラー防止のため一度スキップ
            if not activeArena.MoveFunction or not activeArena.TickFunction then
                return
            end

            local success, err = pcall(function()
                local movedir = calcMoveVec() * Value.Value
                local onground = getupvalue(activeArena.MoveFunction, 4)
                local velocity = getupvalue(activeArena.TickFunction, 6)

                -- 取得したアップバリューに異常がない場合のみ書き換えを実行
                if onground ~= nil and velocity ~= nil then
                    setupvalue(
                        activeArena.TickFunction, 
                        6, 
                        Vector3.new(
                            movedir.X, 
                            AutoJump.Enabled and onground and movedir.Magnitude > 0 and 20 or velocity.Y, 
                            movedir.Z
                        )
                    )
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
        print("[Speed Debug] Module Disabled.")
    end
end

return Speed