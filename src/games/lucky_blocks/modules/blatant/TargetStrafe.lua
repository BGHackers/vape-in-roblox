local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

local UI = {}
local TargetStrafe = {
    Name = "TargetStrafe",
    Description = "Automatically circles around your target opponent with void and wall prevention.",
    TargetGame = "lucky_blocks"
}

TargetStrafe.Settings = {
    DistanceValue = 6,
    SpeedValue = 12,
    SearchRangeValue = 80,
    AutoJump = true,
    Visuals = true,
}

local connection, currentTarget = nil, nil
local theta, direction, lastDirectionSwitchTime = 0, 1, 0
local lastTargetName = nil
local lastHeartbeatCheck = 0
local lastSafeCFrame = nil
local visualHighlight = nil
local visualRing = nil
local myAttachment = nil
local targetAttachment = nil
local visualBeam = nil

local function isInsidePart(part, pos)
    if not part then return false end
    local localPos = part.CFrame:PointToObjectSpace(pos)
    local size = part.Size
    return math.abs(localPos.X) < size.X / 2
       and math.abs(localPos.Y) < size.Y / 2
       and math.abs(localPos.Z) < size.Z / 2
end

local function checkObstacles(myPos, dir, char)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    local checkDist = 3
    local nextFloorPos = myPos + dir * checkDist
    local rayDown = workspace:Raycast(nextFloorPos, Vector3.new(0, -15, 0), params)
    local isVoid = not rayDown
    local isWall = false
    local wallName = ""
    local directionsToCheck = {
        dir * 2.5,
        (CFrame.Angles(0, math.rad(30), 0) * dir) * 2,
        (CFrame.Angles(0, math.rad(-30), 0) * dir) * 2
    }
    for _, d in ipairs(directionsToCheck) do
        local wall = workspace:Raycast(myPos, d, params)
        if wall and wall.Instance and wall.Instance.CanCollide then
            isWall = true
            wallName = wall.Instance.Name
            break
        end
    end
    if isVoid then
        return true, "Void"
    elseif isWall then
        return true, "Wall (" .. wallName .. ")"
    end
    return false, nil
end

local function findClosestTarget(rangeLimit)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter.PrimaryPart
    if not myRoot then 
        return nil 
    end
    local closestTarget, minDistance = nil, rangeLimit
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character.PrimaryPart then
            local char = player.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and not char:FindFirstChildOfClass("ForceField") then
                local distance = (myRoot.Position - char.PrimaryPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestTarget = char
                end
            end
        end
    end
    return closestTarget
end

local function updateVisuals(targetChar)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not TargetStrafe.Settings.Visuals or not myRoot or not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
        if visualHighlight then visualHighlight.Enabled = false end
        if visualRing then visualRing.Visible = false end
        if visualBeam then visualBeam.Enabled = false end
        return
    end
    local targetRoot = targetChar.HumanoidRootPart
    local colorSelf = Color3.fromRGB(0, 255, 255)
    local colorTarget = Color3.fromRGB(255, 0, 127)
    if not visualHighlight or visualHighlight.Parent == nil then
        visualHighlight = Instance.new("Highlight")
        visualHighlight.Name = "StrafeTargetHighlight"
        visualHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        visualHighlight.FillColor = colorTarget
        visualHighlight.FillOpacity = 0.15
        visualHighlight.OutlineColor = colorTarget
        visualHighlight.OutlineOpacity = 0.9
        visualHighlight.Parent = workspace:WaitForChild("Terrain")
    end
    visualHighlight.Adornee = targetChar
    visualHighlight.Enabled = true
    if not visualRing or visualRing.Parent == nil then
        visualRing = Instance.new("CylinderHandleAdornment")
        visualRing.Name = "StrafeTargetRing"
        visualRing.Height = 0.01
        visualRing.Color3 = colorTarget
        visualRing.AlwaysOnTop = true
        visualRing.ZIndex = 5
        visualRing.Transparency = 0.5
        visualRing.Parent = workspace:WaitForChild("Terrain")
    end
    visualRing.Adornee = targetRoot
    visualRing.Radius = TargetStrafe.Settings.DistanceValue
    visualRing.CFrame = CFrame.new(0, -2.8, 0) * CFrame.Angles(math.rad(90), 0, 0)
    visualRing.Visible = true
    if not myAttachment or myAttachment.Parent ~= myRoot then
        if myAttachment then myAttachment:Destroy() end
        myAttachment = Instance.new("Attachment")
        myAttachment.Name = "StrafeMyAttachment"
        myAttachment.Parent = myRoot
    end
    if not targetAttachment or targetAttachment.Parent ~= targetRoot then
        if targetAttachment then targetAttachment:Destroy() end
        targetAttachment = Instance.new("Attachment")
        targetAttachment.Name = "StrafeTargetAttachment"
        targetAttachment.Parent = targetRoot
    end
    if not visualBeam or visualBeam.Parent == nil then
        visualBeam = Instance.new("Beam")
        visualBeam.Name = "StrafeVisualBeam"
        visualBeam.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorSelf),
            ColorSequenceKeypoint.new(1, colorTarget)
        })
        visualBeam.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(0.15, 0),
            NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint.new(1, 0.4)
        })
        visualBeam.LightEmission = 1
        visualBeam.LightInfluence = 0
        visualBeam.Width0 = 0.03
        visualBeam.Width1 = 0.03
        visualBeam.FaceCamera = true
        visualBeam.Parent = workspace:WaitForChild("Terrain")
    end
    visualBeam.Attachment0 = myAttachment
    visualBeam.Attachment1 = targetAttachment
    visualBeam.Enabled = true
end

local function clearVisuals()
    if visualHighlight then
        visualHighlight:Destroy()
        visualHighlight = nil
    end
    if visualRing then
        visualRing:Destroy()
        visualRing = nil
    end
    if visualBeam then
        visualBeam:Destroy()
        visualBeam = nil
    end
    if myAttachment then
        myAttachment:Destroy()
        myAttachment = nil
    end
    if targetAttachment then
        targetAttachment:Destroy()
        targetAttachment = nil
    end
end

-- 🌟 【ここが本番】Sliderの実装は外にあるので、moduleObjから呼び出すだけになります
function TargetStrafe.Init(moduleObj)
    print("[TargetStrafe Debug] Init called (UI creation)")
    UI = UI or {}

    -- スライダーの引数として、テーブル（設定）を渡す形に対応
    UI.Distance = moduleObj:CreateSlider({
        Name = "Strafe Distance",
        Min = 2,
        Max = 20,
        Default = TargetStrafe.Settings.DistanceValue,
        Suffix = "studs",
        Function = function(val) TargetStrafe.Settings.DistanceValue = val end
    })

    UI.Speed = moduleObj:CreateSlider({
        Name = "Strafe Speed",
        Min = 1,
        Max = 30,
        Default = TargetStrafe.Settings.SpeedValue,
        Function = function(val) TargetStrafe.Settings.SpeedValue = val end
    })

    UI.SearchRange = moduleObj:CreateSlider({
        Name = "Search Range",
        Min = 10,
        Max = 150,
        Default = TargetStrafe.Settings.SearchRangeValue,
        Suffix = "studs",
        Function = function(val) TargetStrafe.Settings.SearchRangeValue = val end
    })

    -- Toggleはライブラリ標準のものを想定
    UI.AutoJump = moduleObj:CreateToggle({
        Name = "AutoJump (BHop)",
        Default = TargetStrafe.Settings.AutoJump,
        Function = function(state) TargetStrafe.Settings.AutoJump = state end
    })

    UI.Visuals = moduleObj:CreateToggle({
        Name = "Show Visuals",
        Default = TargetStrafe.Settings.Visuals,
        Function = function(state) TargetStrafe.Settings.Visuals = state end
    })
end

local function onHeartbeat(dt)
    local myCharacter = lplr.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local humanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
    if os.clock() - lastHeartbeatCheck > 5 then
        lastHeartbeatCheck = os.clock()
        local charExists = myCharacter ~= nil
        local rootExists = myRoot ~= nil
        local humState = humanoid and humanoid:GetState().Name or "None"
        print(string.format("[TargetStrafe Debug] Heartbeat active. Character: %s, Root: %s, State: %s", tostring(charExists), tostring(rootExists), humState))
    end
    if not myRoot or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        updateVisuals(nil)
        return
    end
    local loadingBlocker = workspace:FindFirstChild("Misc") and workspace.Misc:FindFirstChild("LoadingBlocker")
    if loadingBlocker and loadingBlocker:IsA("BasePart") then
        if isInsidePart(loadingBlocker, myRoot.Position) then
            if lastSafeCFrame then
                myRoot.CFrame = lastSafeCFrame
                print("[TargetStrafe Debug] LoadingBlocker bypass blocked! Teleported back to safety.")
                return 
            else
                local blockerCF = loadingBlocker.CFrame
                local blockerSize = loadingBlocker.Size
                myRoot.CFrame = blockerCF * CFrame.new(0, 0, blockerSize.Z / 2 + 5)
                print("[TargetStrafe Debug] Initial LoadingBlocker bypass blocked! Forced player out.")
                return
            end
        else
            lastSafeCFrame = myRoot.CFrame
        end
    end
    currentTarget = findClosestTarget(TargetStrafe.Settings.SearchRangeValue)
    if currentTarget and currentTarget.PrimaryPart then
        local targetRoot = currentTarget.PrimaryPart
        local myPos, targetPos = myRoot.Position, targetRoot.Position
        local targetName = currentTarget.Name
        updateVisuals(currentTarget)
        if lastTargetName ~= targetName then
            print("[TargetStrafe Debug] Target Changed: " .. targetName .. " | Distance: " .. math.round((myPos - targetPos).Magnitude) .. " studs")
            lastTargetName = targetName
            local relative = myPos - targetPos
            theta = math.atan2(relative.Z, relative.X)
            print("[TargetStrafe Debug] Initialized start theta to: " .. tostring(theta))
            
            -- ロックオン通知（外部の通知システムがある場合はここで呼び出す）
            if shared.vape and shared.vape.mainapi and shared.vape.mainapi.CreateNotification then
                shared.vape.mainapi:CreateNotification("Target Lock", "Locked onto " .. targetName, 3, "info")
            end
        end
        theta = (theta + direction * (TargetStrafe.Settings.SpeedValue / TargetStrafe.Settings.DistanceValue) * dt) % (math.pi * 2)
        local desiredDistance = TargetStrafe.Settings.DistanceValue
        local nextPos = Vector3.new(
            targetPos.X + math.cos(theta) * desiredDistance,
            myPos.Y,
            targetPos.Z + math.sin(theta) * desiredDistance
        )
        local moveDirection = (nextPos - myPos).Unit
        local hasObstacle, obstacleType = checkObstacles(myPos, moveDirection, myCharacter)
        if hasObstacle and (os.clock() - lastDirectionSwitchTime > 0.5) then
            direction = -direction 
            lastDirectionSwitchTime = os.clock()
            print("[TargetStrafe Debug] " .. obstacleType .. " detected! Switched direction to: " .. direction)
            
            if shared.vape and shared.vape.mainapi and shared.vape.mainapi.CreateNotification then
                shared.vape.mainapi:CreateNotification("Avoidance", obstacleType .. " detected! Reversing orbit.", 2.5, "warning")
            end
            
            theta = (theta + direction * (TargetStrafe.Settings.SpeedValue / TargetStrafe.Settings.DistanceValue) * dt * 3) % (math.pi * 2)
            nextPos = Vector3.new(
                targetPos.X + math.cos(theta) * desiredDistance,
                myPos.Y,
                targetPos.Z + math.sin(theta) * desiredDistance
            )
            moveDirection = (nextPos - myPos).Unit
        end
        local targetVelocity = moveDirection * TargetStrafe.Settings.SpeedValue
        myRoot.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, myRoot.AssemblyLinearVelocity.Y, targetVelocity.Z)
        myRoot.CFrame = CFrame.lookAt(nextPos, Vector3.new(targetPos.X, nextPos.Y, targetPos.Z))
        if TargetStrafe.Settings.AutoJump and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
        end
    else
        updateVisuals(nil)
        if lastTargetName ~= nil then
            print("[TargetStrafe Debug] Lost target.")
            
            if shared.vape and shared.vape.mainapi and shared.vape.mainapi.CreateNotification then
                shared.vape.mainapi:CreateNotification("Target Lock", "Lost target: " .. lastTargetName, 2.5, "warning")
            end
            
            lastTargetName = nil
            myRoot.AssemblyLinearVelocity = Vector3.new(0, myRoot.AssemblyLinearVelocity.Y, 0)
        end
    end
end

function TargetStrafe.Callback(enabled)
    print("[TargetStrafe Debug] Callback toggled. Enabled state: " .. tostring(enabled))
    if enabled then
        theta, direction, lastDirectionSwitchTime, currentTarget, lastTargetName, lastSafeCFrame = 0, 1, 0, nil, nil, nil
        connection = RunService.Heartbeat:Connect(onHeartbeat)
        print("[TargetStrafe Debug] Heartbeat event connected.")
        
        if shared.vape and shared.vape.mainapi and shared.vape.mainapi.CreateNotification then
            shared.vape.mainapi:CreateNotification("TargetStrafe", "Module enabled successfully", 3, "info")
        end
    else
        if connection then 
            connection:Disconnect() 
            connection = nil 
            print("[TargetStrafe Debug] Heartbeat event disconnected.")
        end
        clearVisuals()
        
        if shared.vape and shared.vape.mainapi and shared.vape.mainapi.CreateNotification then
            shared.vape.mainapi:CreateNotification("TargetStrafe", "Module disabled successfully", 3, "info")
        end
    end
end

return TargetStrafe