-- games/1_8arena/modules/blatant/Killaura.lua
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

-- 1_8arenaの特殊なHP・配置構造に対応したターゲット取得関数
local function getClosestTarget(rangeLimit)
    local vape = shared.vape or _G.mainapi
    local entitylib = vape and vape.Libraries and vape.Libraries.entity
    
    -- 1. entitylib（先ほど全ゲーム対応化したもの）が利用可能な場合は、そちらのリストを優先使用
    if entitylib and entitylib.List then
        local localEntity = entitylib.character
        if not localEntity or not localEntity.RootPart then return nil end
        
        local target = nil
        local closestDist = rangeLimit
        
        for _, ent in ipairs(entitylib.List) do
            -- 自分以外、かつ生存しているエンティティ
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

    -- 2. フォールバック: entitylib がロードされていない場合の予備走査ロジック（1_8arena対応）
    local target = nil
    local closestDist = rangeLimit
    
    -- ローカルキャラクターの取得
    local localChar = lplr.Character or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name)
    local localRoot = localChar and (localChar:FindFirstChild("HumanoidRootPart") or localChar:FindFirstChild("Torso"))
    if not localRoot then return nil end

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lplr then
            -- 標準のキャラ、または1_8arenaのフェイクキャラクターを検索
            local char = v.Character 
                or (workspace:FindFirstChild("OtherCharacters") and workspace.OtherCharacters:FindFirstChild(v.Name .. "_FakeCharacter"))
                or workspace:FindFirstChild(v.Name)

            if char then
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                
                -- HPをHealthValueから安全に取得（1_8arena仕様）
                local healthVal = v:FindFirstChild("HealthValue") or char:FindFirstChild("HealthValue")
                local isAlive = true
                if healthVal then
                    isAlive = healthVal.Value > 0
                else
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    isAlive = humanoid and humanoid.Health > 0
                end
                
                if root and isAlive then
                    local dist = (localRoot.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        target = char
                    end
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

    -- 2. 攻撃間隔調整スライダー
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
            -- ディレイチェック
            if now - lastAttack >= Delay.Value then
                local target = getClosestTarget(Range.Value)
                if target then
                    local success, err = pcall(function()
                        -- リモートの取得と実行 (Mawin_CK の Remote構造に準拠)
                        local gameRemotes = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
                        local attackRemote = gameRemotes and gameRemotes:FindFirstChild("Attack")
                        
                        if attackRemote then
                            attackRemote:InvokeServer(target)
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