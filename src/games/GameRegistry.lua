-- src/games/GameRegistry.lua
local GameRegistry = {}

local places = {
    -- 🌟 フォルダ名が正確に一致しているか確認し、無いものは行頭に -- を書いてコメントアウトしてください。
    ["77790193039862"] = require("games.1_8arena.base"), -- 1_8arena
    ["109668355806967"] = require("games.hoplex.base"),    -- hoplex
    ["81463261330977"] = require("games.pillars_of_fortune.base"), -- pillars_of_fortune
    -- ["13956616152"] = require("games.bridge_duel.base"), -- 🌟 まだフォルダが無い場合はコメントアウト
}

-- 🌟 universal フォルダも作成していない場合は、一旦コメントアウトしてください
local universal = require("games.universal.base") 

-- 現在のプレイスIDに合致する「マージ済みの」モジュールリストを返す関数
function GameRegistry.getModules()
    local placeIdStr = tostring(game.PlaceId)
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
        
        -- ユニバーサルモジュールを合流
        if universal and universal[category] then
            for _, mod in ipairs(universal[category]) do
                table.insert(merged[category], mod)
            end
        end
        
        -- プレイス固有モジュールを合流
        if placeSpecific[category] then
            for _, mod in ipairs(placeSpecific[category]) do
                table.insert(merged[category], mod)
            end
        end
    end

    return merged
end

return GameRegistry