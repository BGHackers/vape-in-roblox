-- games/lucky_blocks/modules/blatant/Killaura.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

local Killaura = {
    Name = "Killaura",
    Description = "Attacks nearby players by firing the Lucky Block attack RemoteFunction.",
    TargetGame = "lucky_blocks"
}

-- 初期設定値
Killaura.Settings = {
    RangeValue = 30,
    DelayValue = 0.1
}

local Range = { Value = 30 }
local Delay = { Value = 0.1 }
local moduleInstance = nil

-- 最も近くにいるプレイヤーを検出（HPチェックなしのMawin_CK仕様）
local function getClosestTarget(rangeLimit)
    local character = lplr.Character
    local localRoot = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
    if not localRoot then return nil end

    local target = nil
    local closestDist = rangeLimit

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lplr and v.Character then
            local root = v.Character:FindFirstChild("HumanoidRootPart") or v.Character:FindFirstChild("Torso")
            
            if root then
                local dist = (localRoot.Position - root.Position).Magnitude
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
    
    print("[Killaura Init] Initializing Debug-equipped UI components...")

    Range = moduleObj:CreateSlider({
        Name = "Range",
        Min = 5,
        Max = 50,
        Default = Killaura.Settings.RangeValue or 30,
        Suffix = function(val) return val == 1 and "stud" or "studs" end,
        Function = function(val) Killaura.Settings.RangeValue = val end
    })

    Delay = moduleObj:CreateSlider({
        Name = "Attack Delay",
        Min = 0.05,
        Max = 1,
        Default = Killaura.Settings.DelayValue or 0.1,
        Suffix = function(val) return "s" end,
        Function = function(val) Killaura.Settings.DelayValue = val end
    })
end

function Killaura.Callback(enabled)
    if enabled then
        print("[Killaura Debug] Lucky Blocks Killaura Enabled.")
        
        -- リモートの取得
        local successRemote, remote = pcall(function()
            return game:GetService("ReplicatedStorage").GameRemotes.Attack
        end)
        
        if successRemote and remote and remote:IsA("RemoteFunction") then
            print("[Killaura Debug] 専用リモートの確認完了: " .. remote:GetFullName())
        else
            warn("[Killaura Debug] 専用リモート (GameRemotes.Attack) が見つかりません！")
        end
        
        local lastAttack = 0
        local lastLogTime = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local now = os.clock()
            if now - lastAttack >= Delay.Value then
                local target = getClosestTarget(Range.Value)
                
                if target then
                    -- 🌟 ターゲットを検知している場合のログを出力
                    local dist = 0
                    pcall(function()
                        dist = math.floor((lplr.Character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude)
                    end)
                    print(string.format("[Killaura] 🎯 敵を捕捉中: %s (距離: %d studs) -> リモート送信中...", target.Name, dist))
                    
                    local success, err = pcall(function()
                        if remote and remote:IsA("RemoteFunction") then
                            local args = { target }
                            remote:InvokeServer(unpack(args))
                            lastAttack = now
                        end
                    end)
                    
                    if not success then
                        warn("[Killaura Error]:", tostring(err))
                    end
                else
                    -- 🌟 ターゲットがいない場合（ログでコンソールが埋まらないよう、2秒ごとに1度だけ状況を出力）
                    if now - lastLogTime >= 2 then
                        print("[Killaura Info] 範囲内にターゲットになるプレイヤーがいません。（※自分自身は除外されます）")
                        lastLogTime = now
                    end
                end
            end
        end)
        
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("[Killaura Debug] Lucky Blocks Killaura Disabled.")
    end
end

return Killaura