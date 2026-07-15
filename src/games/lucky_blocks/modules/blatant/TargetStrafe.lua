-- サービスの取得
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ローカルプレイヤー
local lplr = Players.LocalPlayer

-- モジュールの基本情報
local TargetStrafe = {
    Name = "TargetStrafe",
    Description = "Automatically circles around your target opponent with void and wall prevention.",
    TargetGame = "lucky_blocks"
}

-- 設定のデフォルト値
TargetStrafe.Settings = {
    DistanceValue = 6,
    SpeedValue = 10,
    SearchRangeValue = 30,
    AutoJump = true
}

-- 変数の初期化
local connection = nil -- ◆修正点1: イベント接続を管理する変数を外で宣言
local currentTarget = nil
local theta = 0 -- 旋回の角度
local direction = 1 -- 1 = 時計回り, -1 = 反時計回り
local lastDirectionSwitchTime = 0

-- UIコンポーネントを保持するテーブル
local UI = {}

-- アバターの腰（HumanoidRootPart）の高さを取得する関数 (R6/R15対応)
local function getPivotOffset(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 2.0 end -- デフォルト値

    if humanoid.RigType == Enum.RigType.R6 then
        return 2.5 -- R6アバターの標準的な高さ
    else
        -- R15アバターはHipHeightから計算
        return humanoid.HipHeight + (model.PrimaryPart.Size.Y / 2)
    end
end

-- 指定範囲内で最も近いプレイヤーをターゲットとして取得する関数
local function findClosestTarget(rangeLimit)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter.PrimaryPart
    if not myRoot then return nil end

    local closestTarget = nil
    local minDistance = rangeLimit

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character.PrimaryPart then
            local targetRoot = player.Character.PrimaryPart
            local distance = (myRoot.Position - targetRoot.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closestTarget = player.Character
            end
        end
    end
    return closestTarget
end

-- モジュールの初期化（UI作成）
function TargetStrafe.Init(moduleObj)
    UI.Distance = moduleObj:CreateSlider({
        Name = "Strafe Distance",
        Min = 2, Max = 20,
        Default = TargetStrafe.Settings.DistanceValue,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.DistanceValue = val end
    })

    UI.Speed = moduleObj:CreateSlider({
        Name = "Strafe Speed",
        Min = 1, Max = 30,
        Default = TargetStrafe.Settings.SpeedValue,
        Function = function(val) TargetStrafe.Settings.SpeedValue = val end
    })

    UI.SearchRange = moduleObj:CreateSlider({
        Name = "Search Range",
        Min = 10, Max = 50,
        Default = TargetStrafe.Settings.SearchRangeValue,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.SearchRangeValue = val end
    })

    UI.AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump (BHop)",
        Default = TargetStrafe.Settings.AutoJump,
        Function = function(state) TargetStrafe.Settings.AutoJump = state end
    })
end

-- Strafe処理の本体
local function onHeartbeat(dt)
    local myCharacter = lplr.Character
    if not myCharacter then return end
    
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end

    -- ターゲットを検索
    currentTarget = findClosestTarget(UI.SearchRange.Value) -- ◆修正点3: UIの値を直接参照
    
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos = myRoot.Position
        local targetPos = targetRoot.Position

        -- 角度を更新
        theta = (theta + direction * UI.Speed.Value * dt) % (math.pi * 2) -- ◆修正点3: UIの値を直接参照
        
        -- 次の目標座標を計算 (XとZのみ)
        local desiredDistance = UI.Distance.Value -- ◆修正点3: UIの値を直接参照
        local nextX = targetPos.X + math.cos(theta) * desiredDistance
        local nextZ = targetPos.Z + math.sin(theta) * desiredDistance
        local nextPos = Vector3.new(nextX, myPos.Y, nextZ)
        
        -- 移動方向ベクトルを計算
        local moveDirection = (nextPos - myPos).Unit

        -- レイキャスト用のパラメータ設定
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {myCharacter}

        -- 1. 虚空（奈落）検知
        local groundCheckOrigin = myPos + moveDirection * 2
        local groundRay = workspace:Raycast(groundCheckOrigin, Vector3.new(0, -50, 0), raycastParams)
        local isVoid = not groundRay

        -- 2. 壁検知
        local wallRay = workspace:Raycast(myPos, moveDirection * 2, raycastParams)
        local isWall = wallRay and wallRay.Instance and wallRay.Instance.CanCollide

        -- 奈落に落ちそう or 壁に衝突しそうな場合、クールダウンを考慮して方向転換
        if (isVoid or isWall) and (os.clock() - lastDirectionSwitchTime > 0.5) then
            direction = -direction -- 回転方向を反転
            lastDirectionSwitchTime = os.clock()
            -- 角度を少し戻してスタックを防ぐ
            theta = (theta + direction * UI.Speed.Value * dt * 3) % (math.pi * 2) 
            return -- このフレームでは移動しない
        end

        -- ◆修正点2: スムーズな移動と回転
        -- 移動方向をヒューマノイドに設定
        humanoid.MoveDirection = moveDirection
        -- ターゲットの方を常に見るようにキャラクターの向きを更新
        myRoot.CFrame = CFrame.lookAt(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
        
        -- 自動ジャンプ (BHop)
        if UI.AutoJump.Enabled and humanoid.FloorMaterial ~= Enum.Material.Air then -- ◆修正点3: UIの値を直接参照
            humanoid.Jump = true
        end
    else
        -- ターゲットがいない場合は移動を停止
        if humanoid.MoveDirection ~= Vector3.zero then
            humanoid.MoveDirection = Vector3.zero
        end
    end
end

-- モジュールの有効/無効を切り替える関数
function TargetStrafe.Callback(enabled)
    if enabled then
        -- 初期化
        theta = 0
        direction = 1
        lastDirectionSwitchTime = 0
        currentTarget = nil
        
        -- ◆修正点1: 接続を作成し、変数に保存
        connection = RunService.Heartbeat:Connect(onHeartbeat)
    else
        -- ◆修正点1: 接続が存在すれば、それを切断する
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        -- 念のため、移動を停止させる
        if lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid") then
            lplr.Character.Humanoid.MoveDirection = Vector3.zero
        end
    end
end

return TargetStrafe