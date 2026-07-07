-- src/games/1_8arena/modules/blatant/Speed.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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

-- 🌟 【安全対策】各エクスプロイトの環境差を吸収して関数を確実に取得
local getupvalue = (debug and debug.getupvalue) or getupvalue or (getfenv and getfenv().getupvalue)
local setupvalue = (debug and debug.setupvalue) or setupvalue or (getfenv and getfenv().setupvalue)

-- 🌟 【安全対策】Roblox標準の移動ベクトルコントロールを取得
local localPlayer = Players.LocalPlayer
local controls = nil
pcall(function()
    local PlayerModule = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
    controls = require(PlayerModule):GetControls()
end)

-- 🌟 【安全対策】calculateMoveVector が無くても、Roblox標準から自動計算するフォールバック関数
local function getMoveVector()
    -- 1. グローバルに calculateMoveVector があれば優先使用
    local globalCalc = calculateMoveVector or _G.calculateMoveVector or (getgenv and getgenv().calculateMoveVector)
    if typeof(globalCalc) == "function" then
        local success, res = pcall(globalCalc)
        if success and res then return res end
    end
    
    -- 2. 無ければ標準のコントロールから MoveVector を取得してフォールバック
    if controls and controls.GetMoveVector then
        local success, res = pcall(function() return controls:GetMoveVector() end)
        if success and res then return res end
    end
    
    return Vector3.new(0, 0, 0)
end

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
        
        local frameCount = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            -- ── 🌟 安全な条件判定 ──
            -- アリーナの物理テーブルや必要関数が存在しない場合は、クラッシュを防ぐためスキップ
            if not getupvalue or not setupvalue or typeof(arena) ~= "table" or typeof(arena.MoveFunction) ~= "function" or typeof(arena.TickFunction) ~= "function" then
                frameCount = frameCount + 1
                if frameCount % 60 == 0 then
                    warn("[Speed] Missing required environment functions (debug/arena). Speed hack skipped.")
                end
                return
            end

            local success, err = pcall(function()
                -- 安全な移動ベクトル取得関数を呼び出し
                local moveVec = getMoveVector()
                local movedir = moveVec * Speed.Settings.SpeedValue
                
                local onground = getupvalue(arena.MoveFunction, 4)
                local velocity = getupvalue(arena.TickFunction, 6)

                frameCount = frameCount + 1
                if frameCount % 60 == 0 then
                    print(string.format("[Speed Loop] movedir: %s | onground: %s | velocity: %s", 
                        tostring(movedir), 
                        tostring(onground), 
                        tostring(velocity)
                    ))
                end

                -- 1.8 Arena 固有の Tick 物理ベクトルを直接オーバーライド
                setupvalue(
                    arena.TickFunction, 
                    6, 
                    Vector3.new(
                        movedir.X, 
                        Speed.Settings.AutoJump and onground and movedir.Magnitude > 0 and 20 or velocity.Y, 
                        movedir.Z
                    )
                )
            end)
            
            -- 万が一それ以外の不具合が発生した場合は警告を出す
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