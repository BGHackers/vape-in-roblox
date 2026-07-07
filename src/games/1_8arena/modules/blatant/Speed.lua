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
    
    -- 🌟 将来他のモジュールから参照されるときのために、マップに登録だけ残しておきます
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- 1. スライダー設定 (CreateSlider)
    moduleObj:CreateSlider("Speed", 1, 90, Speed.Settings.SpeedValue, 1, function(val)
        return val == 1 and "stud" or "studs"
    end, function(val)
        Speed.Settings.SpeedValue = val
    end)

    -- 2. トグル設定 (CreateToggle)
    moduleObj:CreateToggle("AutoJump", Speed.Settings.AutoJump, function(state)
        Speed.Settings.AutoJump = state
    end)
end

function Speed.Callback(enabled)
    if enabled then
        print("Speed Activated")
        
        -- 毎フレームの移動物理のオーバーライド処理を開始
        local connection
        connection = RunService.PreSimulation:Connect(function()
            pcall(function()
                local movedir = calculateMoveVector() * Speed.Settings.SpeedValue
                local onground = debug.getupvalue(arena.MoveFunction, 4)
                local velocity = debug.getupvalue(arena.TickFunction, 6)

                -- 🌟 1.8 Arena 固有の Tick 物理ベクトルを直接オーバーライド
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
        end)
        
        -- 🌟 クリーンアップマネージャーに接続を登録 (OFFにした瞬間に自動接続切断)
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("Speed Deactivated")
    end
end

return Speed