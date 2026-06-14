local Players = game:GetService("Players")
local isfolder = isfolder or function(path)
    local success, _ = pcall(listfiles, path)
    return success
end
local gameName = "Game"
if game.PlaceId == 6872274481 or game.PlaceId == 6872265039 or game.PlaceId == 14247545801 then
    gameName = "BedWars"
else
    local success, productInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and productInfo and productInfo.Name then
        gameName = productInfo.Name
    end
end
gameName = gameName:gsub("%s+", "_"):gsub("[^%w_]", "")
if gameName == "" then
    gameName = tostring(game.PlaceId)
end
local folderName = "vape"
if isfolder and isfolder("vape") then
    folderName = "vape_" .. gameName
end
if makefolder then
    pcall(makefolder, folderName)
    pcall(makefolder, folderName .. "/assets")
end
if delfile then
    local oldRootFiles = {
        "vape_logo_main.png", "vape_v4_badge.png", "vape_gui_settings.png",
        "vape_combat_icon.png", "vape_render_icon.png", "vape_utility_icon.png",
        "vape_world_icon.png", "vape_inventory_icon.png", "vape_minigames_icon.png",
        "vape_friends_icon.png", "vape_profiles_icon.png", "vape_blur_shadow.png"
    }
    for _, file in ipairs(oldRootFiles) do
        pcall(delfile, file)
    end
end
local getasset = getcustomasset or getgenv().getcustomasset
local request = request or http_request or (syn and syn.request)
local function loadOnlineImage(url, localName)
    if request and getasset then
        local success, response = pcall(function()
            return request({Url = url, Method = "GET"})
        end)
        if success and response and response.Success then
            local writeSuccess = pcall(writefile, localName, response.Body)
            if not writeSuccess then return nil end
            local assetSuccess, asset = pcall(getasset, localName)
            if assetSuccess and asset then return asset end
        end
    end
    return nil
end
local assets = {}
assets.vapeLogo = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/textvape.png", folderName .. "/assets/vape_logo_main.png")
assets.v4Logo = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/textv4.png", folderName .. "/assets/vape_v4_badge.png")
assets.guiSettings = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guisettings.png", folderName .. "/assets/vape_gui_settings.png")
assets.combat = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/combaticon.png", folderName .. "/assets/vape_combat_icon.png")
assets.render = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/rendertab.png", folderName .. "/assets/vape_render_icon.png")
assets.utility = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/utilityicon.png", folderName .. "/assets/vape_utility_icon.png")
assets.world = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/worldicon.png", folderName .. "/assets/vape_world_icon.png")
assets.inventory = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/inventoryicon.png", folderName .. "/assets/vape_inventory_icon.png")
assets.minigames = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/miniicon.png", folderName .. "/assets/vape_minigames_icon.png")
assets.friends = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/friendstab.png", folderName .. "/assets/vape_friends_icon.png")
assets.profiles = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/profilesicon.png", folderName .. "/assets/vape_profiles_icon.png")
assets.blurShadow = loadOnlineImage("https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blur.png", folderName .. "/assets/vape_blur_shadow.png")
assets.arrow = "rbxassetid://10709791437"
return assets