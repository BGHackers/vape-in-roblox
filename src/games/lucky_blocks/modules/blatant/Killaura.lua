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
    RangeValue = 20,
    DelayValue = 0.1
}

-- UIコンポーネント用プレースホルダー
local Range = { Value = 20 }
local Delay = { Value = 0.1 }

local moduleInstance = nil

-- 最も近くにいる、生存しているプレイヤーを取得する関数
local function getClosestTarget(rangeLimit)
    local vape = shared.vape or _G.mainapi
    local entitylib = vape and vape.Libraries and vape.Libraries.entity
    
    -- 1. 共通 entitylib が利用可能な場合（自動HP判定や特殊なキャラ構造に対応）
    if entitylib and entitylib.List then
        local localEntity = entitylib.character
        if not localEntity or not localEntity.RootPart then return nil end
        
        local target = nil
        local closestDist = rangeLimit
        
        for _, ent in ipairs(entitylib.List) do
            if ent.Targetable and ent.RootPart and ent.Health > 0 then
                local dist = (localEntity.RootPart.Position - ent.RootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    target = ent.Character
                end
            end
        end
        return target
    end

    -- 2. フォールバック（entitylibが読み込まれていない場合の標準的な走査）
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
    
    print("[Killaura Init] Initializing Lucky Block UI components...")

    -- 1. 射程調整スライダー
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

    -- 2. 攻撃間隔（ディレイ）調整スライダー
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
        print("[Killaura Debug] Lucky Blocks Killaura Enabled.")
        
        -- スキャン結果に基づき、正確なパスから RemoteFunction を取得
        local successRemote, remote = pcall(function()
            return game:GetService("ReplicatedStorage").GameRemotes.Attack
        end)
        
        if successRemote and remote and remote:IsA("RemoteFunction") then
            print("[Killaura] Target remote successfully found: " .. remote:GetFullName())
        else
            warn("[Killaura] Dedicated Remote (GameRemotes.Attack) was NOT found in ReplicatedStorage!")
        end
        
        local lastAttack = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local now = os.clock()
            if now - lastAttack >= Delay.Value then
                local target = getClosestTarget(Range.Value)
                if target then
                    local success, err = pcall(function()
                        if remote and remote:IsA("RemoteFunction") then
                            -- 🌟 ターゲットキャラクターを第一引数として InvokeServer で送信
                            remote:InvokeServer(target)
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
        print("[Killaura Debug] Lucky Blocks Killaura Disabled.")
    end
end

return Killaura