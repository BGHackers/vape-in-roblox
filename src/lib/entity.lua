-- 元のライブラリの関数を事前に退避
	local oldGetUpdateConnections = entitylib.getUpdateConnections
	local oldAddEntity = entitylib.addEntity

	-- 安全に現在のHPを取得するヘルパー関数 (1_8arenaなどの特殊仕様 ＋ 標準仕様のハイブリッド)
	local function getEntityHealth(plr, char, hum)
		-- 1. Player配下の HealthValue を最優先でチェック
		if plr then
			local healthVal = plr:FindFirstChild('HealthValue')
			if healthVal then
				return healthVal.Value
			end
		end
		-- 2. Character配下の HealthValue をチェック
		if char and typeof(char) == "Instance" then
			local healthVal = char:FindFirstChild('HealthValue')
			if healthVal then
				return healthVal.Value
			end
		end
		-- 3. 標準の Humanoid.Health をチェック
		if hum and typeof(hum) == "Instance" and hum:IsA("Humanoid") then
			return hum.Health
		end
		return 100
	end

	-- HP同期用のシグナル接続を取得する関数 (全ゲーム対応仕様)
	entitylib.getUpdateConnections = function(ent)
		local connections = {}
		
		-- 1. Player配下の HealthValue の監視
		if ent.Player then
			local healthVal = ent.Player:FindFirstChild('HealthValue')
			if healthVal then
				table.insert(connections, healthVal:GetPropertyChangedSignal('Value'))
			end
		end
		
		-- 2. Character配下の HealthValue の監視
		if ent.Character and typeof(ent.Character) == "Instance" then
			local healthVal = ent.Character:FindFirstChild('HealthValue')
			if healthVal then
				table.insert(connections, healthVal:GetPropertyChangedSignal('Value'))
			end
		end
		
		-- 3. 標準の Humanoid.Health の監視
		if ent.Humanoid and typeof(ent.Humanoid) == "Instance" and ent.Humanoid:IsA("Humanoid") then
			table.insert(connections, ent.Humanoid:GetPropertyChangedSignal('Health'))
		end
		
		-- 元の接続処理をマージして安全に返す (エラーを回避するためpcall)
		local success, oldConnections = pcall(oldGetUpdateConnections, ent)
		if success and type(oldConnections) == "table" then
			for _, conn in ipairs(oldConnections) do
				table.insert(connections, conn)
			end
		end
		
		return connections
	end

	-- エンティティ追加関数 (全ゲーム対応仕様)
	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end

		-- 1. キャラクターの実体（Instance）を解決
		local charInstance = char
		if plr == lplr then
			-- 1_8arenaのローカルプレイヤーパスを最優先し、無ければ標準キャラクターにフォールバック
			charInstance = typeof(char) == "Instance" and char 
				or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) 
				or lplr.Character
		end

		local hum = charInstance and typeof(charInstance) == "Instance" and charInstance:FindFirstChildOfClass('Humanoid')
		local humrootpart = charInstance and typeof(charInstance) == "Instance" and (
			charInstance:FindFirstChild('Torso') 
			or charInstance:FindFirstChild('HumanoidRootPart')
		)

		-- 特殊な環境（1_8arenaフォルダ、特殊Hitbox、またはカスタムHealthValueを持つ環境）であるかを動的に判定
		local isSpecialGame = workspace:FindFirstChild("OtherCharacters") ~= nil 
			or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) ~= nil
			or (charInstance and typeof(charInstance) == "Instance" and (charInstance:FindFirstChild("PlayerHitbox") or charInstance:FindFirstChild("HealthValue")))

		-- 特殊な構造を持たない標準の通常ゲームであれば、ライブラリ本来の addEntity 処理に安全に委ねる
		if not isSpecialGame then
			return oldAddEntity(char, plr, teamfunc)
		end

		-- --- 以下、特殊仕様のゲームにおけるエンティティ追加ロジック ---
		
		-- ローカルプレイヤー
		if plr == lplr then
			local fallbackRoot = humrootpart or gameCamera.CameraSubject
			local head = (charInstance and typeof(charInstance) == "Instance" and charInstance:FindFirstChild('Head')) or fallbackRoot
			local humanoidObj = hum or {GetState = function() end, Health = 100}

			local entity = {
				Connections = {},
				Character = charInstance,
				Health = getEntityHealth(plr, charInstance, humanoidObj),
				Head = head,
				Humanoid = humanoidObj,
				HumanoidRootPart = fallbackRoot,
				HipHeight = (humanoidObj and typeof(humanoidObj) == "Instance" and humanoidObj:IsA("Humanoid") and humanoidObj.HipHeight) or 5,
				MaxHealth = (humanoidObj and typeof(humanoidObj) == "Instance" and humanoidObj:IsA("Humanoid") and humanoidObj.MaxHealth) or 100,
				NPC = false,
				Player = plr,
				RootPart = fallbackRoot,
				TeamCheck = teamfunc
			}

			-- HP更新イベントの登録 ( getUpdateConnections を使用 )
			for _, v in ipairs(entitylib.getUpdateConnections(entity)) do
				table.insert(entity.Connections, v:Connect(function()
					entity.Health = getEntityHealth(plr, charInstance, humanoidObj)
					entitylib.Events.EntityUpdated:Fire(entity)
				end))
			end

			entitylib.character = entity
			entitylib.isAlive = true
			entitylib.Events.LocalAdded:Fire(entity)
			return
		end

		-- 他のプレイヤー/NPC
		entitylib.EntityThreads[charInstance] = task.spawn(function()
			local resolvedHum = hum or waitForChildOfType(charInstance, 'Humanoid', 10)
			local resolvedRoot = humrootpart or charInstance:WaitForChild('Torso', 10) or charInstance:WaitForChild('HumanoidRootPart', 10)
			local head = (charInstance and charInstance:FindFirstChild('Head')) or resolvedRoot

			if resolvedHum and resolvedRoot then
				local entity = {
					Connections = {},
					Character = charInstance,
					Health = getEntityHealth(plr, charInstance, resolvedHum),
					Head = head,
					Humanoid = resolvedHum,
					HumanoidRootPart = resolvedRoot,
					Hitbox = charInstance:FindFirstChild('PlayerHitbox') or charInstance,
					HipHeight = (resolvedHum and typeof(resolvedHum) == "Instance" and resolvedHum:IsA("Humanoid") and resolvedHum.HipHeight) or 3,
					MaxHealth = (resolvedHum and typeof(resolvedHum) == "Instance" and resolvedHum:IsA("Humanoid") and resolvedHum.MaxHealth) or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = resolvedRoot,
					TeamCheck = teamfunc
				}

				entity.Targetable = entitylib.targetCheck(entity)
				
				-- HP更新イベントの登録
				for _, v in ipairs(entitylib.getUpdateConnections(entity)) do
					table.insert(entity.Connections, v:Connect(function()
						entity.Health = getEntityHealth(plr, charInstance, resolvedHum)
						entitylib.Events.EntityUpdated:Fire(entity)
					end))
				end

				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end

			entitylib.EntityThreads[charInstance] = nil
		end)
	end