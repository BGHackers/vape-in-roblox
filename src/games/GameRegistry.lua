-- src/games/GameRegistry.lua
local GameRegistry = {}

local places = {
    ["77790193039862"] = require("games.1_8arena.base"),
    ["109668355806967"] = require("games.hoplex.base"),
    ["81463261330977"] = require("games.pillars_of_fortune.base"),
    ["13956616152"] = require("games.bridge_duel.base"),
}

-- 全ゲーム共通のユニバーサルモジュール（games.universal.base からロード）
local universal = require("games.universal.base") 

function GameRegistry.getModules()
    local placeIdStr = tostring(game.PlaceId)
    
    -- 🌟 【デバッグ診断付き動的ロード】
    -- 1.8 Arena の時だけ init.lua を実行し、失敗した場合はその具体的な理由（404やパス違い等）を警告出力します
    if placeIdStr == "77790193039862" then
        local success, err = pcall(function()
            return require("games.1_8arena.init")
        end)
        if not success then
            warn("⚠️ [GameRegistry Error] Failed to load 'games.1_8arena.init':", tostring(err))
        end
    end

    local placeSpecific = places[placeIdStr] or {
        ["combat"] = {},
        ["blatant"] = {},
        ["Render"] = {},
        ["Utility"] = {},
        ["World"] = {},
        ["Inventory"] = {},
        ["Minigames"] = {}
    }

    local merged = {}
    local categories = {"combat", "blatant", "Render", "Utility", "World", "Inventory", "Minigames"}

    for _, category in ipairs(categories) do
        merged[category] = {}
        
        if universal and universal[category] then
            for _, mod in ipairs(universal[category]) do
                table.insert(merged[category], mod)
            end
        end
        
        if placeSpecific[category] then
            for _, mod in ipairs(placeSpecific[category]) do
                table.insert(merged[category], mod)
            end
        end
    end

    return merged
end

return GameRegistry