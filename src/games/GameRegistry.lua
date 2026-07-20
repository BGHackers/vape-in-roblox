local GameRegistry = {}
local places = {
    ["77790193039862"] = require("games.1_8arena.base"),
    ["109668355806967"] = require("games.hoplex.base"),
    ["81463261330977"] = require("games.pillars_of_fortune.base"),
    ["13956616152"] = require("games.bridge_duel.base"),
    ["100596840912680"] = require("games.lucky_blocks.base"),
}
local universal = require("games.universal.base") 
function GameRegistry.getModules()
    local placeIdStr = tostring(game.PlaceId)
    local placeSpecific = places[placeIdStr]
    local merged = {}
    local categories = {"combat", "blatant", "Render", "Utility", "World", "Inventory", "Minigames"}
    for _, category in ipairs(categories) do
        merged[category] = {}
        if placeSpecific then
            if placeSpecific[category] then
                for _, mod in ipairs(placeSpecific[category]) do
                    table.insert(merged[category], mod)
                end
            end
        else
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