-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")

local Speed = {
    Name = "Speed",
    Description = "Increases your movement with various methods.",
    TargetGame = "1_8arena" -- 🌟 1.8 Arenaでのみ自動ロード
}

-- 設定値の管理
Speed.Settings = {
    SpeedValue = 30,
    AutoJump = false
}

local moduleInstance = nil

function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- 1. スライダー設定
    moduleObj:CreateSlider("Speed", 1, 90, Speed.Settings.SpeedValue, 1, function(val)
        return val == 1 and "stud" or "studs"
    end, function(val)
        Speed.Settings.SpeedValue = val
    end)

    -- 2. トグル設定
    moduleObj:CreateToggle("AutoJump", Speed.Settings.AutoJump, function(state)
        Speed.Settings.AutoJump = state
    end)
end

function Speed.Callback(enabled)
    if enabled then
        print("[Speed Debug] Module Enabled.")
        
        -- ── ① 起動時の依存関係チェック ──
        print("--- Speed Startup Diagnostics ---")
        print("calculateMoveVector exists:", typeof(calculateMoveVector) == "function")
        print("arena table exists:", typeof(arena) == "table")
        if typeof(arena) == "table" then
            print("  - arena.MoveFunction exists:", typeof(arena.MoveFunction) == "function")
            print("  - arena.TickFunction exists:", typeof(arena.TickFunction) == "function")
        end
        print("---------------------------------")
        
        local frameCount = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            -- ── ② 処理エラーの安全な捕捉と出力 ──
            local success, err = pcall(function()
                local movedir = calculateMoveVector() * Speed.Settings.SpeedValue
                local onground = debug.getupvalue(arena.MoveFunction, 4)
                local velocity = debug.getupvalue(arena.TickFunction, 6)

                -- ── ③ 60フレームに1回、現在の値をデバッグ出力（ラグ防止） ──
                frameCount = frameCount + 1
                if frameCount % 60 == 0 then
                    print(string.format("[Speed Loop] movedir: %s | onground: %s | velocity: %s", 
                        tostring(movedir), 
                        tostring(onground), 
                        tostring(velocity)
                    ))
                end

                -- 1.8 Arena 固有の Tick 物理ベクトルを直接オーバーライド
                debug.setupvalue(
                    arena.TickFunction, 
                    6, 
                    Vector3.new(
                        movedir.X, 
                        Speed.Settings.AutoJump and onground and movedir.Magnitude > 0 and 20 or velocity.Y, 
                        movedir.Z
                    )
                )
            end)
            
            -- エラーが発生していた場合は警告を出す
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