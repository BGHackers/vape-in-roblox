-- games/lucky_blocks/modules/blatant/Killaura.lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lplr = Players.LocalPlayer

local Killaura = {
    Name = "Killaura",
    Description = "Attacks nearby players using the Mawin_CK custom remote system.",
    TargetGame = "lucky_blocks"
}

-- 初期設定値
Killaura.Settings = {
    RangeValue = 30, -- Mawin_CK仕様のデフォルト30スタッド
    DelayValue = 0.1 -- Mawin_CK仕様のデフォルト0.1秒
}

-- UIコンポーネント用プレースホルダー
local Range = { Value = 30 }
local Delay = { Value = 0.1 }
local moduleInstance = nil

-- Mawin_CK様のロジックに完全準拠したターゲット捕捉（HPチェックを排除）
local function getClosestTarget(rangeLimit)
    local character = lplr.Character
    local localRoot = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
    if not localRoot then return nil end

    local target = nil
    local closestDist = rangeLimit

    for _, v in ipairs(Players:GetPlayers()) do
        -- 自分以外、かつキャラクターモデルが存在する場合
        if v ~= lplr and v.Character then
            local root = v.Character:FindFirstChild("HumanoidRootPart") or v.Character:FindFirstChild("Torso")
            
            -- ⚠️ HPやHumanoidオブジェクトの有無に関わらず、パーツの位置だけで判定
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
    
    print("[Killaura Init] Initializing Mawin_CK based UI components...")

    -- 1. 射程（Range）スライダー
    Range = moduleObj:CreateSlider({
        Name = "Range",
        Min = 5,
        Max = 50,
        Default = Killaura.Settings.RangeValue or 30,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Killaura.Settings.RangeValue = val
            print("[Killaura UI] Range adjusted to: " .. tostring(val))
        end
    })

    -- 2. 攻撃間隔（Delay）スライダー
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
        print("[Killaura Debug] Mawin_CK Killaura Enabled.")
        
        -- 先ほどのスキャンで確認された RemoteFunction の取得
        local successRemote, remote = pcall(function()
            return game:GetService("ReplicatedStorage").GameRemotes.Attack
        end)
        
        if successRemote and remote and remote:IsA("RemoteFunction") then
            print("[Killaura] Dedicated Remote verified: " .. remote:GetFullName())
        else
            warn("[Killaura] GameRemotes.Attack NOT found!")
        end
        
        local lastAttack = 0
        local connection
        
        connection = RunService.PreSimulation:Connect(function()
            local now = os.clock()
            if now - lastAttack >= Delay.Value then
                local target = getClosestTarget(Range.Value)
                
                -- 無駄なスパムによるBAN・キックを防ぐため、ターゲットが捕捉できたときのみパケットを送信します
                if target then
                    local success, err = pcall(function()
                        if remote and remote:IsA("RemoteFunction") then
                            -- Mawin_CK様と同様の引数アンパック形式での送信
                            local args = {
                                [1] = target
                            }
                            remote:InvokeServer(unpack(args))
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
        print("[Killaura Debug] Mawin_CK Killaura Disabled.")
    end
end

return Killaura