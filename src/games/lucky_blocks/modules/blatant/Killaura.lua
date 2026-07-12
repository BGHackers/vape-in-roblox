-- src/games/1_8arena/modules/blatant/Killaura.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

local Killaura = {
    Name = "Killaura",
    Description = "Attacks nearby players automatically within a set range.",
    TargetGame = "1_8arena"
}

-- 初期設定値
Killaura.Settings = {
    RangeValue = 20,
    DelayValue = 0.1
}

-- UIコンポーネント用プレースホルダー
local Range = { Value = 20 }
local Delay = { Value = 0.1 }

local moduleInstance = nil

-- 最も近くにいる、生存しているプレイヤーを取得する関数
local function getClosestPlayer(rangeLimit)
    local target = nil
    local closestDist = rangeLimit
    
    local character = lplr.Character
    local localroot = character and character:FindFirstChild("HumanoidRootPart")
    if not localroot then return nil end

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lplr and v.Character then
            local root = v.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            
            -- 生存判定も含めてチェック
            if root and humanoid and humanoid.Health > 0 then
                local dist = (localroot.Position - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    target = v.Character
                end
            end
        end
    end
    return target
end

function Killaura.Init(moduleObj)
    moduleInstance = moduleObj
    
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Killaura.Name] = moduleObj
    
    print("[Killaura Init] Initializing UI components...")

    -- 1. 射程（Range）調整スライダー
    Range = moduleObj:CreateSlider({
        Name = "Range",
        Min = 5,
        Max = 50,
        Default = Killaura.Settings.RangeValue or 20,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Killaura.Settings.RangeValue = val
            print("[Killaura UI] Range adjusted to: " .. tostring(val))
        end
    })

    -- 2. 攻撃間隔（Delay）調整スライダー
    Delay = moduleObj:CreateSlider({
        Name = "Attack Delay",
        Min = 0.05,
        Max = 1,
        Default = Killaura.Settings.DelayValue or 0.1,
        Suffix = function(val)
            return "s"
        end,
        Function = function(val)
            Killaura.Settings.DelayValue = val
            print("[Killaura UI] Attack Delay adjusted to: " .. tostring(val) .. "s")
        end
    })
end

function Killaura.Callback(enabled)
    if enabled then
        print(string.format(
            "[Killaura Debug] Killaura Enabled. Settings: [Range: %s] [Delay: %s]",
            tostring(Range.Value),
            tostring(Delay.Value)
        ))
        
        local lastAttack = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local now = os.clock()
            -- 指定されたディレイ時間（ミリ秒）が経過しているかチェック
            if now - lastAttack >= Delay.Value then
                local target = getClosestPlayer(Range.Value)
                if target then
                    local success, err = pcall(function()
                        -- リモートイベント/ファンクションの安全な探索と実行
                        local gameRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
                        local attackRemote = gameRemotes and gameRemotes:FindFirstChild("Attack")
                        
                        if attackRemote then
                            attackRemote:InvokeServer(target)
                            lastAttack = now -- 最終攻撃時間を更新
                        end
                    end)
                    
                    if not success then
                        warn("[Killaura Error]:", tostring(err))
                    end
                end
            end
        end)
        
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("[Killaura Debug] Killaura Disabled.")
    end
end

return Killaura