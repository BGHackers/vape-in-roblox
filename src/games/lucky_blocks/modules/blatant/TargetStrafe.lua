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
    SpeedValue = 12,
    SearchRangeValue = 80,
    AutoJump = true
}

-- 変数の初期化
local connection = nil 
local currentTarget = nil
local theta = 0 -- 旋回の角度
local direction = 1 -- 1 = 時計回り, -1 = 反時計回り
local lastDirectionSwitchTime = 0

-- 【デバッグ用変数】
local lastPeriodicLog = 0
local lastTargetName = nil
local firstHeartbeatFired = false

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
    print("[TargetStrafe Debug] Init関数が呼び出されました。UIを作成します。")
    
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
        Min = 10, Max = 150,
        Default = TargetStrafe.Settings.SearchRangeValue,
        Suffix = function(val) return " studs" end,
        Function = function(val) TargetStrafe.Settings.SearchRangeValue = val end
    })

    UI.AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump (BHop)",
        Default = TargetStrafe.Settings.AutoJump,
        Function = function(state) TargetStrafe.Settings.AutoJump = state end
    })
    
    print("[TargetStrafe Debug] UIの作成が完了しました。")
end

-- Strafe処理の本体
local function onHeartbeat(dt)
    -- 【デバッグ】Heartbeatが正常に開始されたことを1度だけ出力
    if not firstHeartbeatFired then
        print("[TargetStrafe Debug] Heartbeatループが正常に開始されました。")
        firstHeartbeatFired = true
    end

    -- 【デバッグ】2秒ごとに動作状態（ステータス）をコンソールに出力
    if os.clock() - lastPeriodicLog > 2 then
        lastPeriodicLog = os.clock()
        local myCharacter = lplr.Character
        local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
        
        local status = "正常動作中"
        if not myCharacter then status = "エラー: キャラクターが存在しません"
        elseif not myRoot then status = "エラー: HumanoidRootPartがありません"
        elseif not humanoid then status = "エラー: Humanoidがありません"
        elseif humanoid:GetState() == Enum.HumanoidStateType.Dead then status = "エラー: プレイヤーが死亡しています"
        end
        
        local targetName = currentTarget and currentTarget.Name or "なし"
        print(string.format("[TargetStrafe Debug] ステータス: %s | ターゲット: %s | 旋回距離: %d | 速度: %d | 検知範囲: %d", 
            status, targetName, TargetStrafe.Settings.DistanceValue, TargetStrafe.Settings.SpeedValue, TargetStrafe.Settings.SearchRangeValue))
    end

    local myCharacter = lplr.Character
    if not myCharacter then return end
    
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end

    -- ターゲットを検索
    currentTarget = findClosestTarget(TargetStrafe.Settings.SearchRangeValue)
    
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos = myRoot.Position
        local targetPos = targetRoot.Position

        -- 【デバッグ】ターゲットが新しく捕らえられたとき、または切り替わったときにログ出力
        local targetName = currentTarget.Name
        if lastTargetName ~= targetName then
            print("[TargetStrafe Debug] ターゲットを新たに捕捉しました: " .. targetName)
            lastTargetName = targetName
        end

        -- 角度を更新
        theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt) % (math.pi * 2)
        
        -- 次の目標座標を計算 (XとZのみ)
        local desiredDistance = TargetStrafe.Settings.DistanceValue
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
            print(string.format("[TargetStrafe Debug] 壁または奈落を検知したため、回転方向を反転します。 (Void: %s, Wall: %s)", tostring(isVoid), tostring(isWall)))
            direction = -direction -- 回転方向を反転
            lastDirectionSwitchTime = os.clock()
            -- 角度を少し戻してスタックを防ぐ
            theta = (theta + direction * TargetStrafe.Settings.SpeedValue * dt * 3) % (math.pi * 2) 
            return -- このフレームでは移動しない
        end

        -- スムーズな移動
        humanoid:Move(moveDirection, false)
        
        -- ターゲットの方を常に見るようにキャラクターの向きを更新
        myRoot.CFrame = CFrame.lookAt(myPos, Vector3.new(targetPos.X, myPos.Y, targetPos.Z))
        
        -- 自動ジャンプ (BHop)
        if TargetStrafe.Settings.AutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
        end
    else
        -- 【デバッグ】直前までターゲットがいたのに見失った場合にログ出力
        if lastTargetName ~= nil then
            print("[TargetStrafe Debug] ターゲットを見失いました。")
            lastTargetName = nil
        end

        -- ターゲットがいない場合は移動を停止
        if humanoid.MoveDirection ~= Vector3.zero then
            humanoid:Move(Vector3.zero, false)
        end
    end
end

-- モジュールの有効/無効を切り替える関数
function TargetStrafe.Callback(enabled)
    print("[TargetStrafe Debug] Callbackが呼び出されました。設定値(Enabled): " .. tostring(enabled))
    
    if enabled then
        -- 初期化
        theta = 0
        direction = 1
        lastDirectionSwitchTime = 0
        currentTarget = nil
        lastTargetName = nil
        firstHeartbeatFired = false
        lastPeriodicLog = 0
        
        -- 接続を作成し、変数に保存
        connection = RunService.Heartbeat:Connect(onHeartbeat)
        print("[TargetStrafe Debug] Heartbeatイベントへの接続に成功しました。")
    else
        -- 接続が存在すれば、それを切断する
        if connection then
            connection:Disconnect()
            connection = nil
            print("[TargetStrafe Debug] Heartbeatイベントの切断に成功しました。")
        end
        
        -- 念のため、移動を停止させる
        if lplr.Character then
            local humanoid = lplr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:Move(Vector3.zero, false)
                print("[TargetStrafe Debug] プレイヤーの移動コマンドをクリア（停止）しました。")
            end
        end
    end
end

return TargetStrafe