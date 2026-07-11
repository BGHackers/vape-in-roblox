-- 元のライブラリの関数を事前に退避
	local oldGetUpdateConnections = entitylib.getUpdateConnections
	local oldAddEntity = entitylib.addEntity

	-- 現在のゲームが 1_8arena の特殊環境であるかを判定する関数
	local function checkArenaGame()
		return workspace:FindFirstChild("OtherCharacters") ~= nil 
			or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) ~= nil
	end

	-- 安全に現在のHPを取得するヘルパー関数 (1_8arena専用 ＋ 標準フォールバック)
	local function getEntityHealth(plr, hum)
		if plr then
			local healthVal = plr:FindFirstChild('HealthValue')
			if healthVal then
				return healthVal.Value
			end
		end
		if hum and typeof(hum) == "Instance" and hum:IsA("Humanoid") then
			return hum.Health
		end
		return 100
	end

	-- HP同期用のシグナル接続を取得する関数 (全ゲーム対応仕様)
	entitylib.getUpdateConnections = function(ent)
		-- 1_8arena でなければ、標準の Vape 接続処理をそのまま返す
		if not checkArenaGame() then
			return oldGetUpdateConnections(ent)
		end
		
		local connections = {}
		-- Player が存在する場合のみ HealthValue の監視を登録 (NPCでのクラッシュ防止)
		if ent.Player then
			local healthVal = ent.Player:FindFirstChild('HealthValue')
			if healthVal then
				table.insert(connections, healthVal:GetPropertyChangedSignal('Value'))
			end
		end
		-- 標準の Humanoid.Health の監視も追加
		if ent.Humanoid and typeof(ent.Humanoid) == "Instance" and ent.Humanoid:IsA("Humanoid") then
			table.insert(connections, ent.Humanoid:GetPropertyChangedSignal('Health'))
		end
		return connections
	end

	-- エンティティ追加関数 (全ゲーム対応仕様)
	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end

		-- 1_8arena でなければ、元の標準 addEntity をそのまま実行
		if not checkArenaGame() then
			return oldAddEntity(char, plr, teamfunc)
		end

		-- --- 以下、1_8arena 専用の追加ロジック ---

		-- ローカルプレイヤーのキャラクター処理 (Workspace/LocalCharacter_[Username])
		if plr == lplr then
			local charInstance = typeof(char) == "Instance" and char or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name)
			local hum = (charInstance and charInstance:FindFirstChildOfClass('Humanoid')) or {GetState = function() end, Health = 100}
			local humrootpart = (charInstance and (charInstance:FindFirstChild('Torso') or charInstance:FindFirstChild('HumanoidRootPart'))) or gameCamera.CameraSubject
			local head = (charInstance and charInstance:FindFirstChild('Head')) or humrootpart

			local entity = {
				Connections = {},
				Character = charInstance,
				Health = getEntityHealth(plr, hum),
				Head = head,
				Humanoid = hum,
				HumanoidRootPart = humrootpart,
				HipHeight = 5,
				MaxHealth = 100,
				NPC = false,
				Player = plr,
				RootPart = humrootpart,
				TeamCheck = teamfunc
			}

			-- HP更新イベントの登録 (全ゲーム対応接続リストを使用)
			for _, v in ipairs(entitylib.getUpdateConnections(entity)) do
				table.insert(entity.Connections, v:Connect(function()
					entity.Health = getEntityHealth(plr, hum)
					entitylib.Events.EntityUpdated:Fire(entity)
				end))
			end

			entitylib.character = entity
			entitylib.isAlive = true
			entitylib.Events.LocalAdded:Fire(entity)
			return
		end

		-- 他のプレイヤー/NPCのキャラクター処理 (Workspace/OtherCharacters/[Username]_FakeCharacter)
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = char:WaitForChild('Torso', 10) or char:WaitForChild('HumanoidRootPart', 10)
			local head = char:WaitForChild('Head', 10) or humrootpart

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = getEntityHealth(plr, hum),
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					Hitbox = char:FindFirstChild('PlayerHitbox') or char,
					HipHeight = 3,
					MaxHealth = (hum and typeof(hum) == "Instance" and hum:IsA("Humanoid") and hum.MaxHealth) or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				entity.Targetable = entitylib.targetCheck(entity)
				
				-- HP更新イベントの登録
				for _, v in ipairs(entitylib.getUpdateConnections(entity)) do
					table.insert(entity.Connections, v:Connect(function()
						entity.Health = getEntityHealth(plr, hum)
						entitylib.Events.EntityUpdated:Fire(entity)
					end))
				end

				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end

			entitylib.EntityThreads[char] = nil
		end)
	end