-- src/games/1_8arena/init.lua

-- 🌟 task.spawn を使うことで、メインの require 処理を一切止めずに
-- バックグラウンドで安全にキャラクターのロード待機を行えるように非同期化
local run = function(func) task.spawn(func) end 

local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local replicatedFirst = cloneref(game:GetService('ReplicatedFirst'))
local collectionService = cloneref(game:GetService('CollectionService'))
local runService = cloneref(game:GetService('RunService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local arena = {}

local oldhit
local Spider = {Enabled = false}
local Phase = {Enabled = false}

local function calculateMoveVector()
	local vec = arena.MoveController:GetMoveVector()
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = Vector3.new((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
end

local function notif(...)
	local vape = shared.vape or _G.mainapi
	if vape and vape.CreateNotification then
		return vape:CreateNotification(...)
	end
end

run(function()
	-- vapeの初期化完了を非同期に待つことで、Main.luaとの競合を完全に防ぎます
	local vape = shared.vape
	if not vape then
		repeat
			vape = shared.vape
			task.wait()
		until vape or _G.mainapi
		vape = vape or _G.mainapi
	end

	local charscript = lplr.PlayerScripts:WaitForChild("CharacterController", 10)
	if not charscript then return end
	
	local env = getsenv(charscript)
	if not (env and env.startHit) then
		repeat
			env = getsenv(charscript)
			task.wait()
		until (env and env.startHit) or vape.Loaded == nil

		if vape.Loaded == nil then return end
	end

	arena = {
		Client = getsenv(charscript),
		PlayerState = require(charscript.PlayerState),
		Inventory = require(charscript.Inventory),
		MoveController = require(lplr.PlayerScripts.PlayerModule):GetControls(),
		SwingFunction = debug.getupvalue(getsenv(charscript).startHit, 1)
	}

	for _, v in ipairs(getconnections(runService.Heartbeat)) do
		if v.Function and islclosure(v.Function) and debug.getconstants(v.Function)[1] == 0.05 then
			arena.TickFunction = debug.getupvalue(v.Function, 3)
		end
	end

	for _, v in ipairs(getconnections(replicatedStorage.Remotes.LoadLocalCharacter.OnClientEvent)) do
		if v.Function then
			arena.MoveFunction = debug.getupvalue(v.Function, 9)
		end
	end

	getgenv().arena = arena
	getgenv().calculateMoveVector = calculateMoveVector

	vape:Clean(function()
		table.clear(arena)
		getgenv().arena = nil
		getgenv().calculateMoveVector = nil
	end)
end)

run(function()
	-- vape と entitylib の初期化完了を非同期に待ちます
	local vape = shared.vape
	if not vape then
		repeat
			vape = shared.vape
			task.wait()
		until vape or _G.mainapi
		vape = vape or _G.mainapi
	end

	local entitylib = vape.Libraries.entity
	local targetinfo = vape.Libraries.targetinfo

	local function waitForChildOfType(obj, name, timeout, prop)
		local checktick = tick() + timeout
		local returned
		repeat
			returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
			if returned or checktick < tick() then break end
			task.wait()
		until false
		return returned
	end

	entitylib.getUpdateConnections = function(ent)
		local connections = {}
		local healthVal = ent.Player:FindFirstChild('HealthValue') or ent.Player:WaitForChild('HealthValue', 5)
		if healthVal then
			table.insert(connections, healthVal:GetPropertyChangedSignal('Value'))
		end
		return connections
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end

		-- ローカルプレイヤーのキャラクター処理 (Workspace/LocalCharacter_[Username])
		if plr == lplr then
			local charInstance = typeof(char) == "Instance" and char or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name)
			local hum = (charInstance and charInstance:FindFirstChildOfClass('Humanoid')) or {GetState = function() end, Health = 100}
			local humrootpart = (charInstance and (charInstance:FindFirstChild('Torso') or charInstance:FindFirstChild('HumanoidRootPart'))) or gameCamera.CameraSubject
			local head = (charInstance and charInstance:FindFirstChild('Head')) or humrootpart

			local entity = {
				Connections = {},
				Character = charInstance,
				Health = 100,
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

			local healthVal = plr:FindFirstChild('HealthValue')
			if healthVal then
				entity.Health = healthVal.Value
				table.insert(entity.Connections, healthVal:GetPropertyChangedSignal('Value'):Connect(function()
					entity.Health = healthVal.Value
					entitylib.Events.EntityUpdated:Fire(entity)
				end))
			end

			entitylib.character = entity
			entitylib.isAlive = true
			entitylib.Events.LocalAdded:Fire(entity)
			return
		end

		-- 他のプレイヤーのキャラクター処理 (Workspace/OtherCharacters/[Username]_FakeCharacter)
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = char:WaitForChild('Torso', 10) or char:WaitForChild('HumanoidRootPart', 10)
			local head = char:WaitForChild('Head', 10) or humrootpart
			local val = plr:WaitForChild('HealthValue', 10)

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = val and val.Value or 100,
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					Hitbox = char:FindFirstChild('PlayerHitbox') or char,
					HipHeight = 3,
					MaxHealth = 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				entity.Targetable = entitylib.targetCheck(entity)
				for _, v in entitylib.getUpdateConnections(entity) do
					table.insert(entity.Connections, v:Connect(function()
						entity.Health = val and val.Value or 100
						entitylib.Events.EntityUpdated:Fire(entity)
					end))
				end

				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end

			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.addPlayer = function(plr) end

	local oldstart = entitylib.start
	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			-- 1. ローカルプレイヤーのキャラクター検知 (Workspace/LocalCharacter_[Username])
			local localCharName = "LocalCharacter_" .. lplr.Name
			
			table.insert(entitylib.Connections, workspace.ChildAdded:Connect(function(child)
				if child.Name == localCharName then
					entitylib.addEntity(child, lplr)
				end
			end))

			local initialLocalChar = workspace:FindFirstChild(localCharName)
			if initialLocalChar then
				entitylib.addEntity(initialLocalChar, lplr)
			end

			-- 2. 他のプレイヤーのキャラクター検知 (Workspace/OtherCharacters内の変更監視)
			local otherCharacters = workspace:WaitForChild("OtherCharacters", 10) or workspace:FindFirstChild("OtherCharacters")
			if otherCharacters then
				table.insert(entitylib.Connections, otherCharacters.ChildAdded:Connect(function(ent)
					-- 末尾の "_FakeCharacter" (14文字) を切り捨ててプレイヤー名を取得
					local plrName = ent.Name:sub(1, #ent.Name - 14)
					local plr = playersService:FindFirstChild(plrName)
					if plr then
						entitylib.refreshEntity(ent, plr)
					end
				end))

				for _, ent in otherCharacters:GetChildren() do
					local plrName = ent.Name:sub(1, #ent.Name - 14)
					local plr = playersService:FindFirstChild(plrName)
					if plr then
						entitylib.refreshEntity(ent, plr)
					end
				end
			end
		end
	end

	entitylib.start()
end)

-- 非同期に待機し、安全に不要モジュールをクリーンアップ
task.spawn(function()
	local vape = shared.vape
	if not vape then
		repeat
			vape = shared.vape
			task.wait()
		until vape or _G.mainapi
		vape = vape or _G.mainapi
	end

	if vape and vape.Remove then
		for _, v in ipairs({'AimAssist', 'Reach', 'SilentAim', 'AntiFall', 'Desync', 'Invisible', 'Jesus', 'MouseTP', 'Phase', 'SpinBot', 'Swim', 'TargetStrafe', 'AnimationPlayer', 'AntiRagdoll', 'ChatSpammer', 'Disabler', 'StateSpoofer', 'Freecam', 'Gravity', 'Parkour', 'SafeWalk', 'MurderMystery'}) do
			pcall(function()
				vape:Remove(v)
			end)
		end
	end
end)