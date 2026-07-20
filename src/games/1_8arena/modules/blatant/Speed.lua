local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local gameCamera = workspace.CurrentCamera
local Speed = {
    Name = "Speed",
    Description = "Increases your movement with advanced CFrame physics.",
    TargetGame = "1_8arena"
}
Speed.Settings = {
    SpeedValue = 30,
    JumpHeight = 6,
    AutoJump = true
}
local Value = { Value = 30 }
local JumpHeight = { Value = 6 }
local AutoJump = { Enabled = true }
local moduleInstance = nil
local function getMovementDirection()
    local calcMoveVec = getgenv().calculateMoveVector
    if calcMoveVec then
        local success, vec = pcall(calcMoveVec)
        if success and vec and vec.Magnitude > 0 then
            return vec
        end
    end
    local look = Vector3.new(gameCamera.CFrame.LookVector.X, 0, gameCamera.CFrame.LookVector.Z)
    local right = Vector3.new(gameCamera.CFrame.RightVector.X, 0, gameCamera.CFrame.RightVector.Z)
    if look.Magnitude > 0 then look = look.Unit end
    if right.Magnitude > 0 then right = right.Unit end
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + look end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - look end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - right end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + right end
    return dir.Magnitude > 0 and dir.Unit or Vector3.zero
end
local function getLocalCharacterModel(entitylib)
    if entitylib and entitylib.isAlive and entitylib.character then
        if typeof(entitylib.character.Character) == "Instance" then
            return entitylib.character.Character
        end
    end
    return workspace:FindFirstChild("LocalCharacter_" .. lplr.Name) or lplr.Character
end
local function getPivotOffset(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
    if humanoid and typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid") then
        if humanoid.RigType == Enum.RigType.R6 then
            return 3.0
        else
            local rootSizeY = root and root.Size.Y or 2
            return humanoid.HipHeight + (rootSizeY / 2)
        end
    end
    return 3.0
end
function Speed.Init(moduleObj)
    moduleInstance = moduleObj
    _G.vapeModules = _G.vapeModules or {}
    _G.vapeModules[Speed.Name] = moduleObj
    print("[Speed Init] Initializing UI components...")
    Value = moduleObj:CreateSlider({
        Name = "Speed",
        Min = 1,
        Max = 150,
        Default = Speed.Settings.SpeedValue or 30,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Speed.Settings.SpeedValue = val
            print("[Speed UI] Speed adjusted to: " .. tostring(val))
        end
    })
    JumpHeight = moduleObj:CreateSlider({
        Name = "Jump Height",
        Min = 1,
        Max = 25,
        Default = Speed.Settings.JumpHeight or 6,
        Suffix = function(val)
            return val == 1 and "stud" or "studs"
        end,
        Function = function(val)
            Speed.Settings.JumpHeight = val
            print("[Speed UI] Jump Height adjusted to: " .. tostring(val) .. " studs")
        end
    })
    AutoJump = moduleObj:CreateToggle({
        Name = "BHop / AutoJump",
        Default = Speed.Settings.AutoJump,
        Function = function(state)
            Speed.Settings.AutoJump = state
            print("[Speed UI] BHop / AutoJump toggled to: " .. tostring(state))
        end
    })
end
function Speed.Callback(enabled)
    if enabled then
        print(string.format(
            "[Speed Debug] Pure CFrame BHop Enabled. Settings: [Speed: %s] [Target Height: %s] [AutoJump: %s]",
            tostring(Value.Value),
            tostring(JumpHeight.Value),
            tostring(AutoJump.Enabled)
        ))
        local modelNotFoundLogged = false
        local characterFoundLogged = false
        local rootNotFoundLogged = false
        local lastMovingState = nil
        local verticalVelocity = 0
        local gravity = 140.0
        local pivotOffset = 3.0
        local measuredOffset = false
        local rawY = nil
        local connection
        connection = RunService.PreSimulation:Connect(function(dt)
            local vape = shared.vape or _G.mainapi
            local entitylib = vape and vape.Libraries and vape.Libraries.entity
            local model = getLocalCharacterModel(entitylib)
            if not model then
                if not modelNotFoundLogged then
                    modelNotFoundLogged = true
                    characterFoundLogged = false
                    warn("[Speed Debug] Local character model not found! Waiting for load...")
                end
                return
            end
            if not characterFoundLogged then
                characterFoundLogged = true
                modelNotFoundLogged = false
                measuredOffset = true
                pivotOffset = getPivotOffset(model)
                print(string.format("[Speed Debug] Model loaded: %s | Active Ground Offset: %.3f studs", model.Name, pivotOffset))
            end
            local root = model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not root then
                if not rootNotFoundLogged then
                    rootNotFoundLogged = true
                    warn("[Speed Debug] Root part not found inside the character model.")
                end
                return
            end
            rootNotFoundLogged = false
            local success, err = pcall(function()
                local dir = getMovementDirection()
                local isMoving = dir.Magnitude > 0
                if isMoving ~= lastMovingState then
                    lastMovingState = isMoving
                    print(string.format(
                        "[Speed Debug] State Update -> IsMoving: %s (Dir: %s)",
                        tostring(isMoving),
                        tostring(dir)
                    ))
                end
                local cur = model:GetPivot()
                if not rawY or not isMoving or math.abs(rawY - cur.Position.Y) > 5 then
                    rawY = cur.Position.Y
                end
                local nextX = cur.Position.X + dir.X * (Value.Value * dt)
                local nextZ = cur.Position.Z + dir.Z * (Value.Value * dt)
                verticalVelocity = verticalVelocity - (gravity * dt)
                rawY = rawY + (verticalVelocity * dt)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {model}
                local rayStart = Vector3.new(nextX, rawY + 2, nextZ)
                local rayResult = workspace:Raycast(rayStart, Vector3.new(0, -15, 0), raycastParams)
                local groundY = nil
                if rayResult then
                    groundY = rayResult.Position.Y + pivotOffset
                end
                if groundY and rawY <= groundY then
                    rawY = groundY
                    verticalVelocity = 0
                    if AutoJump.Enabled and isMoving then
                        verticalVelocity = math.sqrt(2 * gravity * JumpHeight.Value)
                    end
                end
                local smoothY = cur.Position.Y + (rawY - cur.Position.Y) * (1 - math.exp(-22 * dt))
                local nextPosition = Vector3.new(nextX, smoothY, nextZ)
                model:PivotTo(CFrame.new(nextPosition) * (cur - cur.Position))
            end)
            if not success then
                warn("[Speed Hack Error]:", tostring(err))
            end
        end)
        if moduleInstance then
            moduleInstance:Clean(connection)
        end
    else
        print("[Speed Debug] CFrame BHop Disabled.")
    end
end
return Speed