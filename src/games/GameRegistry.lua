-- src/games/GameRegistry.lua
local GameRegistry = {}

-- src/games/GameRegistry.lua

local places = {
    -- 🌟 1.8 Arena (接続時に自動で init.lua の初期化を走らせてから、base.lua をロードさせます)
    ["77790193039862"] = (function()
        pcall(require, "games.1_8arena.init") -- 🌟 自動で init を実行
        return require("games.1_8arena.base")
    end)(),

    -- 2. Hoplex
    ["109668355806967"] = require("games.hoplex.base"),

    -- 3. Pillars of Fortune
    ["81463261330977"] = require("games.pillars_of_fortune.base"),

    -- 7. Bridge Duel (まだフォルダが無い場合はコメントアウト)
    -- ["13956616152"] = require("games.bridge_duel.base"),
}

-- 🌟 universal フォルダも作成していない場合は、一旦コメントアウトしてください
local universal = require("games.universal.base") 

-- src/games/GameRegistry.lua
function GameRegistry.getModules()
    local placeIdStr = tostring(game.PlaceId)
    local placeSpecific = places[placeIdStr]
    
    local merged = {}
    local categories = {"combat", "blatant", "Render", "Utility", "World", "Inventory", "Minigames"}

    for _, category in ipairs(categories) do
        merged[category] = {}
        
        if placeSpecific then
            -- If game-specific modules exist, load ONLY game-specific modules
            if placeSpecific[category] then
                for _, mod in ipairs(placeSpecific[category]) do
                    table.insert(merged[category], mod)
                end
            end
        else
            -- If no game-specific modules exist, load universal modules as a fallback
            if universal and universal[category] then
                for _, mod in ipairs(universal[category]) do
                    table.insert(merged[category], mod)
                end
            end
        end
    end

    return merged
end

return GameRegistry