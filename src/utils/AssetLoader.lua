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
        "vape_combat_icon.png", "vape_blatant_icon.png", "vape_render_icon.png",
        "vape_utility_icon.png", "vape_world_icon.png", "vape_inventory_icon.png",
        "vape_minigames_icon.png", "vape_friends_icon.png", "vape_profiles_icon.png", 
        "vape_blur_shadow.png", "vape_bind_icon.png"
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
local progressEvent = Instance.new("BindableEvent")
assets.OnProgress = progressEvent.Event
local downloadList = {
    {key = "vapeLogo", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/aa.png", file = "ape_logo_main.png", label = "Ape Main Logo"},
    {key = "v4Logo", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/textv4.png", file = "vape_v4_badge.png", label = "V4 Badge"},
    {key = "guiSettings", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guisettings.png", file = "vape_gui_settings.png", label = "Settings Gear"},
    {key = "combat", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/combaticon.png", file = "vape_combat_icon.png", label = "Combat Icon"},
    {key = "blatant", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blatanticon.png", file = "vape_blatant_icon.png", label = "Blatant Icon"},
    {key = "render", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/rendertab.png", file = "vape_render_icon.png", label = "Render Icon"},
    {key = "utility", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/utilityicon.png", file = "vape_utility_icon.png", label = "Utility Icon"},
    {key = "world", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/worldicon.png", file = "vape_world_icon.png", label = "World Icon"},
    {key = "inventory", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/inventoryicon.png", file = "vape_inventory_icon.png", label = "Inventory Icon"},
    {key = "minigames", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/miniicon.png", file = "vape_minigames_icon.png", label = "Minigames Icon"},
    {key = "friends", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/friendstab.png", file = "vape_friends_icon.png", label = "Friends Icon"},
    {key = "profiles", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/profilesicon.png", file = "vape_profiles_icon.png", label = "Profiles Icon"},
    {key = "blurShadow", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blur.png", file = "vape_blur_shadow.png", label = "Blur Shadow Layer"},
    {key = "bind", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/bind.png", file = "vape_bind_icon.png", label = "Keybind Icon"},
    {key = "guislider", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guislider.png", file = "vape_guislider.png", label = "GUI Slider"},
    {key = "guisliderrain", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/guisliderrain.png", file = "vape_guisliderrain.png", label = "Rainbow Slider"},
    {key = "warning", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/warning.png", file = "warning.png", label = "Warning Icon"},
    {key = "blurnotif", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/blurnotif.png", file = "blurnotif.png", label = "Notification Blur"},
    {key = "alert", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/alert.png", file = "alert.png", label = "Alert Icon"},
    {key = "info", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/info.png", file = "info.png", label = "Info Icon"},
    {key = "notification", url = "https://raw.githubusercontent.com/BGHackers/vape-rewrhite/main/notification.png", file = "notification.png", label = "Notification Background"}
}
function assets.loadAll()
    local total = #downloadList
    for i, item in ipairs(downloadList) do
        progressEvent:Fire(i / total, "Loading " .. item.label .. "...")
        assets[item.key] = loadOnlineImage(item.url, folderName .. "/assets/" .. item.file)
        task.wait(0.08) 
    end
    assets.arrow = "rbxassetid://10709791437"
    progressEvent:Fire(1.0, "Assets successfully loaded!")
end
return assets