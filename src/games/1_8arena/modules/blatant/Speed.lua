-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")

local Speed = {
    Name = "Speed",
    Description = "Increases your movement with various methods.",
    TargetGame = "1_8arena" -- 🌟 1.8 Arenaでのみ自動ロード
}

-- 元のVapeコードに記述されている変数名に同期（ファイルローカルで初期定義）
local Value = { Value = 30 }
local AutoJump = { Enabled = false }

-- 各種エクスプロイトの環境差を吸収して関数を確実に取得
local getupvalue = (debug and debug.getupvalue) or getupvalue or (getgenv and getgenv().getupvalue) or (getfenv and getfenv().getupvalue)
local setupvalue = (debug and debug.setupvalue) or setupvalue or (getgenv and getgenv().setupvalue) or (getfenv and getfenv().setupvalue)

local moduleInstance = nil

function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj

    -- 🌟 元のテーブル形式パラメータ引数を100%サポートしてスライダーを生成
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

    -- 🌟 元のテーブル形式パラメータ引数を100%サポートしてトグルを生成
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
            -- 🌟 【超軽量】init.lua によって getgenv() に公開された変数を直接読み込みます
            local activeArena = getgenv().arena or arena
            local calcMoveVec = getgenv().calculateMoveVector or calculateMoveVector

            -- 万が一の未ロード時エラーを防ぐセーフガード
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

            local success, err = pcall(function()
                -- 🌟 元のオリジナルVapeと完全に同一のスマートな物理ハックを実行
                local movedir = calcMoveVec() * Value.Value
                local onground = getupvalue(activeArena.MoveFunction, 4)
                local velocity = getupvalue(activeArena.TickFunction, 6)

                setupvalue(
                    activeArena.TickFunction, 
                    6, 
                    Vector3.new(
                        movedir.X, 
                        AutoJump.Enabled and onground and movedir.Magnitude > 0 and 20 or velocity.Y, 
                        movedir.Z
                    )
                )
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