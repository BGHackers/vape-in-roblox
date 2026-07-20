	local oldGetUpdateConnections = entitylib.getUpdateConnections
	local oldAddEntity = entitylib.addEntity
	local function getEntityHealth(plr, char, hum)
		if plr then
			local healthVal = plr:FindFirstChild('HealthValue')
			if healthVal then
				return healthVal.Value
			end
		end
		if char and typeof(char) == "Instance" then
			local healthVal = char:FindFirstChild('HealthValue')
			if healthVal then
				return healthVal.Value
			end
		end
		if hum and typeof(hum) == "Instance" and hum:IsA("Humanoid") then
			return hum.Health
		end
		return 100
	end
	entitylib.getUpdateConnections = function(ent)
		local connections = {}
			local healthVal = ent.Player:FindFirstChild('HealthValue')
			if healthVal then
				table.insert(connections, healthVal:GetPropertyChangedSignal('Value'))
			end
		end
			local healthVal = ent.Character:FindFirstChild('HealthValue')
			if healthVal then
				table.insert(connections, healthVal:GetPropertyChangedSignal('Value'))
			end
		end
			table.insert(connections, ent.Humanoid:GetPropertyChangedSignal('Health'))
		end
		local success, oldConnections = pcall(oldGetUpdateConnections, ent)
		if success and type(oldConnections) == "table" then
			for _, conn in ipairs(oldConnections) do
				table.insert(connections, conn)
			end
		end
		return connections
	end
	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		local charInstance = char
		if plr == lplr then
			charInstance = typeof(char) == "Instance" and char
				or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name)
				or lplr.Character
		end
		local hum = charInstance and typeof(charInstance) == "Instance" and charInstance:FindFirstChildOfClass('Humanoid')
		local humrootpart = charInstance and typeof(charInstance) == "Instance" and (
			charInstance:FindFirstChild('Torso')
			or charInstance:FindFirstChild('HumanoidRootPart')
		)
			or workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) ~= nil
			or (charInstance and typeof(charInstance) == "Instance" and (charInstance:FindFirstChild("PlayerHitbox") or charInstance:FindFirstChild("HealthValue")))
			return oldAddEntity(char, plr, teamfunc)
		end
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