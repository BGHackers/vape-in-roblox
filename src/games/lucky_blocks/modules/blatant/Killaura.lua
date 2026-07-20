local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local Killaura = {
    Name = "Killaura",
    Description = "Attacks nearby players by firing the Lucky Block attack RemoteFunction.",
    TargetGame = "lucky_blocks"
}
Killaura.Settings = {
    RangeValue = 30,
    DelayValue = 0.1
}
local Range = { Value = 30 }
local Delay = { Value = 0.1 }
local moduleInstance = nil
local killauraActive = false
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
    print("[Killaura Init] Initializing Thread-based UI components...")
    Range = moduleObj:CreateSlider({
        Name = "Range",
        Min = 5,
        Max = 30,
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
    killauraActive = enabled
    if enabled then
        print("[Killaura Debug] Thread Loop Killaura Enabled.")
        local successRemote, remote = pcall(function()
            return game:GetService("ReplicatedStorage").GameRemotes.Attack
        end)
        if successRemote and remote and remote:IsA("RemoteFunction") then
            task.spawn(function()
                while killauraActive do
                    local target = getClosestTarget(Range.Value)
                    if target then
                        local success, err = pcall(function()
                            local args = {
                                [1] = target
                            }
                            remote:InvokeServer(unpack(args))
                        end)
                        if not success then
                            warn("[Killaura Error]:", tostring(err))
                        end
                    end
                    task.wait(Delay.Value)
                end
            end)
        else
            warn("[Killaura Debug] GameRemotes.Attack NOT found!")
        end
    else
        print("[Killaura Debug] Thread Loop Killaura Disabled.")
    end
end
return Killaura