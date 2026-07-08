-- src/gui/components/Speed.lua
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

-- 🌟 各種エクスプロイトの環境差を吸収して関数を確実に取得
local getupvalue = (debug and debug.getupvalue) or getupvalue or (getgenv and getgenv().getupvalue) or (getfenv and getfenv().getupvalue)
local setupvalue = (debug and debug.setupvalue) or setupvalue or (getgenv and getgenv().setupvalue) or (getfenv and getfenv().setupvalue)

-- 🌟 【新規開発】メモリ(getgc)およびローカル関数upvaluesから隠れた「arena」を自動追跡してバインドするスキャナー
local function getArenaTable()
    -- 1. すでにグローバルに存在していれば即座に返す
    local globalArena = arena or _G.arena or (getgenv and getgenv().arena)
    if typeof(globalArena) == "table" and typeof(globalArena.MoveFunction) == "function" then
        return globalArena
    end

    -- 2. 無い場合はガベージコレクター(GC)から直接テーブルを検索
    local getgc = getgc or (getgenv and getgenv().getgc)
    if getgc then
        local success, result = pcall(function()
            for _, v in ipairs(getgc(true)) do
                if typeof(v) == "table" then
                    local ok, hasKeys = pcall(function()
                        return typeof(v.MoveFunction) == "function" and typeof(v.TickFunction) == "function"
                    end)
                    if ok and hasKeys then
                        print("[Speed Scanner] Found 'arena' table directly in GC!")
                        if getgenv then getgenv().arena = v end
                        return v
                    end
                end
            end

            -- 3. 【upvaluesスキャン】ローカル変数として隠されている場合、メモリ内の全関数から発掘
            for _, v in ipairs(getgc()) do
                if typeof(v) == "function" and getupvalue then
                    for i = 1, 100 do
                        local ok, name, val = pcall(getupvalue, v, i)
                        if not ok or not name then break end -- これ以上upvalueがない場合は終了

                        if typeof(val) == "table" then
                            local ok2, hasKeys = pcall(function()
                                return typeof(val.MoveFunction) == "function" and typeof(val.TickFunction) == "function"
                            end)
                            if ok2 and hasKeys then
                                print("[Speed Scanner] Successfully scavenged 'arena' from function upvalue: " .. tostring(name))
                                if getgenv then getgenv().arena = val end
                                return val
                            end
                        end
                    end
                end
            end
        end)
        if success and result then
            return result
        end
    end
    return nil
end

-- Roblox標準の移動ベクトルコントロールを取得
local localPlayer = Players.LocalPlayer
local controls = nil
pcall(function()
    local PlayerModule = localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
    controls = require(PlayerModule):GetControls()
end)

local function getMoveVector()
    local globalCalc = calculateMoveVector or _G.calculateMoveVector or (getgenv and getgenv().calculateMoveVector)
    if typeof(globalCalc) == "function" then
        local success, res = pcall(globalCalc)
        if success and res then return res end
    end
    
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
        
        local diagnosticsLogged = false
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local activeArena = getArenaTable()

            -- ── 🌟 何が欠落しているかをピンポイントで書き出す診断処理 ──
            if not getupvalue or not setupvalue or not activeArena then
                if not diagnosticsLogged then
                    diagnosticsLogged = true
                    warn("⚠️ --- Speed Diagnostics Failure ---")
                    warn("  - getupvalue function exists:", getupvalue ~= nil)
                    warn("  - setupvalue function exists:", setupvalue ~= nil)
                    warn("  - activeArena table exists:", activeArena ~= nil)
                    if activeArena then
                        warn("    - MoveFunction exists:", activeArena.MoveFunction ~= nil)
                        warn("    - TickFunction exists:", activeArena.TickFunction ~= nil)
                    end
                    warn("  Speed hack skipped to prevent client crash.")
                    warn("-------------------------------------")
                end
                return
            end

            local success, err = pcall(function()
                local moveVec = getMoveVector()
                local movedir = moveVec * Speed.Settings.SpeedValue
                
                local onground = getupvalue(activeArena.MoveFunction, 4)
                local velocity = getupvalue(activeArena.TickFunction, 6)

                -- 1.8 Arena 固有の Tick 物理ベクトルを直接オーバーライド
                setupvalue(
                    activeArena.TickFunction, 
                    6, 
                    Vector3.new(
                        movedir.X, 
                        Speed.Settings.AutoJump and onground and movedir.Magnitude > 0 and 20 or velocity.Y, 
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