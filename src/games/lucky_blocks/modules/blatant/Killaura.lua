-- games/lucky_blocks/modules/blatant/Killaura.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

-- 🌟 【リモートの設定】
local function getAttackRemote()
    local rep = game:GetService("ReplicatedStorage")
    
    -- ここでリモート候補を順番に探します
    return rep:FindFirstChild("GameRemotes") and rep.GameRemotes:FindFirstChild("Attack")
        or rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Attack")
        or rep:FindFirstChild("Attack")
end

local Killaura = {
    Name = "Killaura",
    Description = "Attacks nearby players by purely firing the game's attack remote.",
    TargetGame = "lucky_blocks"
}

Killaura.Settings = {
    RangeValue = 20,
    DelayValue = 0.1
}

local Range = { Value = 20 }
local Delay = { Value = 0.1 }
local moduleInstance = nil

local function getClosestTarget(rangeLimit)
    local character = lplr.Character
    local localRoot = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
    if not localRoot then return nil end

    local target = nil
    local closestDist = rangeLimit

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lplr and v.Character then
            local root = v.Character:FindFirstChild("HumanoidRootPart") or v.Character:FindFirstChild("Torso")
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            
            if root and humanoid and humanoid.Health > 0 then
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
    
    Range = moduleObj:CreateSlider({
        Name = "Range",
        Min = 5,
        Max = 50,
        Default = Killaura.Settings.RangeValue or 20,
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
        print("[Killaura Debug] Killaura Enabled.")
        
        -- 🌟 【検知テスト】ONにした瞬間にリモートの存在チェックを実行
        local remote = getAttackRemote()
        if remote then
            -- 緑色の文字などで見つかったリモートのフルパスをコンソールに出力
            print("=========================================")
            print("🎉 [Killaura] リモート検知成功！")
            print("パス: " .. remote:GetFullName())
            print("クラス名: " .. remote.ClassName)
            print("=========================================")
        else
            -- 見つからなかった場合は警告を出力
            warn("=========================================")
            warn("⚠️ [Killaura] リモートが検知できませんでした！")
            warn(" getAttackRemote() 内のパスを確認してください。")
            warn("=========================================")
        end
        
        local lastAttack = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local now = os.clock()
            if now - lastAttack >= Delay.Value then
                local target = getClosestTarget(Range.Value)
                if target then
                    local success, err = pcall(function()
                        local activeRemote = getAttackRemote()
                        if activeRemote then
                            if activeRemote:IsA("RemoteEvent") then
                                activeRemote:FireServer(target)
                            elseif activeRemote:IsA("RemoteFunction") then
                                activeRemote:InvokeServer(target)
                            end
                            lastAttack = now
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