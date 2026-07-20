local AimAssist = {
    Name = "AimAssist",
    Description = "Smoothly guides your aim to opponents."
}
AimAssist.Settings = {
    ResetAngle = false,
    ResetDelay = 0.5,
    TargetName = "",
    AimColor = { Hue = 0.44, Sat = 1, Value = 1, Opacity = 1 },
    TargetMode = "Distance", 
    Targets = { Players = true, NPCs = true, Friends = false }
}
function AimAssist.Init(moduleObj)
    moduleObj:CreateSection("Angle Settings")
    moduleObj:CreateToggle("Reset angle", AimAssist.Settings.ResetAngle, function(state)
        AimAssist.Settings.ResetAngle = state
    end)
    moduleObj:CreateSlider("Reset angle delay", 0.1, 5, AimAssist.Settings.ResetDelay, 0.1, " s", function(val)
        AimAssist.Settings.ResetDelay = val
    end)
    moduleObj:CreateSection("Target Settings")
    local targetBox = moduleObj:CreateTextBox("Target Name", AimAssist.Settings.TargetName, "Enter name...", function(val, enter)
        AimAssist.Settings.TargetName = val
    end)
    moduleObj:CreateButton("Reset Target", function()
        AimAssist.Settings.TargetName = ""
        if targetBox and targetBox.SetValue then
            targetBox:SetValue("")
        end
        print("Target Name has been reset via Button!")
    end, "rbxassetid://10734897387")
    moduleObj:CreateColorPicker("Target Color", AimAssist.Settings.AimColor, function(h, s, v, opacity)
        AimAssist.Settings.AimColor.Hue = h
        AimAssist.Settings.AimColor.Sat = s
        AimAssist.Settings.AimColor.Value = v
        AimAssist.Settings.AimColor.Opacity = opacity
    end)
    moduleObj:CreateDropdown(
        "Target Mode", 
        {"Distance", "FOV", "Health"}, 
        AimAssist.Settings.TargetMode, 
        function(val, mouse)
            AimAssist.Settings.TargetMode = val
        end
    )
    moduleObj:CreateMultiDropdown(
        "Aim Targets",
        {"Players", "NPCs", "Friends"},
        AimAssist.Settings.Targets,
        function(updatedTable, mouse)
            AimAssist.Settings.Targets = updatedTable
        end
    )
end
function AimAssist.Callback(enabled)
    if enabled then
        local targetColor = Color3.fromHSV(
            AimAssist.Settings.AimColor.Hue,
            AimAssist.Settings.AimColor.Sat,
            AimAssist.Settings.AimColor.Value
        )
        print("====== AimAssist Enabled ======")
        print("Reset Angle:", AimAssist.Settings.ResetAngle)
        print("Reset Delay:", AimAssist.Settings.ResetDelay, "seconds")
        print("Specific Target:", AimAssist.Settings.TargetName ~= "" and AimAssist.Settings.TargetName or "None")
        print("Target Prioritization:", AimAssist.Settings.TargetMode)
        print("Aim Target Filters:")
        print("  - Players:", AimAssist.Settings.Targets.Players)
        print("  - NPCs:", AimAssist.Settings.Targets.NPCs)
        print("  - Friends:", AimAssist.Settings.Targets.Friends)
        print("Color RGB:", math.round(targetColor.R * 255) .. ", " .. math.round(targetColor.G * 255) .. ", " .. math.round(targetColor.B * 255))
        print("Color Opacity:", AimAssist.Settings.AimColor.Opacity)
        print("===============================")
    else
        print("AimAssist Disabled")
    end
end
return AimAssist