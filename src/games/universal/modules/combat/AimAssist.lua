-- src/features/modules/impl/combat/AimAssist.lua
local AimAssist = {
    Name = "AimAssist",
    Description = "Smoothly guides your aim to opponents."
}

-- 使用する設定値の一括管理
AimAssist.Settings = {
    ResetAngle = false,
    ResetDelay = 0.5,
    TargetName = "",
    AimColor = { Hue = 0.44, Sat = 1, Value = 1, Opacity = 1 },
    TargetMode = "Distance", 
    Targets = { Players = true, NPCs = true, Friends = false }
}

function AimAssist.Init(moduleObj)
    
    -- ── 🌟 セクション1: ANGLE SETTINGS ──
    moduleObj:CreateSection("Angle Settings")

    -- 1. トグル設定（ON / OFF）
    moduleObj:CreateToggle("Reset angle", AimAssist.Settings.ResetAngle, function(state)
        AimAssist.Settings.ResetAngle = state
    end)

    -- 2. スライダー設定（数値調整）
    moduleObj:CreateSlider("Reset angle delay", 0.1, 5, AimAssist.Settings.ResetDelay, 0.1, " s", function(val)
        AimAssist.Settings.ResetDelay = val
    end)


    -- ── 🌟 セクション2: TARGET SETTINGS ──
    moduleObj:CreateSection("Target Settings")

    -- 3. テキストボックス設定（文字列入力）
    local targetBox = moduleObj:CreateTextBox("Target Name", AimAssist.Settings.TargetName, "Enter name...", function(val, enter)
        AimAssist.Settings.TargetName = val
    end)

    -- 4. ボタン設定（クリック実行）
    moduleObj:CreateButton("Reset Target", function()
        AimAssist.Settings.TargetName = ""
        if targetBox and targetBox.SetValue then
            targetBox:SetValue("")
        end
        print("Target Name has been reset via Button!")
    end, "rbxassetid://10734897387") -- ごみ箱アイコン

    -- 5. カラーピッカー設定（HSVカラー・不透明度・レインボー調整）
    moduleObj:CreateColorPicker("Target Color", AimAssist.Settings.AimColor, function(h, s, v, opacity)
        AimAssist.Settings.AimColor.Hue = h
        AimAssist.Settings.AimColor.Sat = s
        AimAssist.Settings.AimColor.Value = v
        AimAssist.Settings.AimColor.Opacity = opacity
    end)

    -- 6. ドロップダウン設定（単一選択リスト）
    moduleObj:CreateDropdown(
        "Target Mode", 
        {"Distance", "FOV", "Health"}, 
        AimAssist.Settings.TargetMode, 
        function(val, mouse)
            AimAssist.Settings.TargetMode = val
        end
    )

    -- 7. マルチドロップダウン設定（複数選択リスト）
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
        
        -- 現在の設定状態をコンソールに出力してデバッグ確認
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