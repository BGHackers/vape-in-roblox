-- games/lucky_blocks/modules/blatant/Killaura.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

local function getAttackRemote()
    local rep = game:GetService("ReplicatedStorage")
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
    
    print("[Killaura Init] Initializing Remote-Only UI components...")

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
            "[Killaura Debug] Remote-Only Killaura Enabled. Settings: [Range: %s] [Delay: %s]",
            tostring(Range.Value),
            tostring(Delay.Value)
        ))
        
        local lastAttack = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local now = os.clock()
            if now - lastAttack >= Delay.Value then
                local target = getClosestTarget(Range.Value)
                if target then
                    local success, err = pcall(function()
                        local remote = getAttackRemote()
                        if remote then
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer(target)
                            elseif remote:IsA("RemoteFunction") then
                                remote:InvokeServer(target)
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
        print("[Killaura Debug] Remote-Only Killaura Disabled.")
    end
end

return Killaura