local HttpService = game:GetService("HttpService")
local BaseUrl = "https://raw.githubusercontent.com/BGHackers/vape-in-roblox/main/src/"
local moduleCache = {}
local oldRequire = require
getgenv().require = function(modulePath)
    local formattedPath = modulePath:gsub("%.", "/")
    if moduleCache[formattedPath] then
        return moduleCache[formattedPath]
    end
    local fileUrl = BaseUrl .. formattedPath .. ".lua?t=" .. tostring(os.time())
    local success, response = pcall(function()
        return game:HttpGet(fileUrl)
    end)
    if not success or not response then
        if oldRequire then
            local ok, res = pcall(oldRequire, modulePath)
            if ok then
                return res
            end
        end
        error("Failed to dynamically load module: " .. modulePath .. " (URL: " .. fileUrl .. ")")
    end
    local chunk, err = loadstring(response, "@src/" .. formattedPath .. ".lua")
    if not chunk then
        error("Syntax error in module " .. modulePath .. ": " .. tostring(err))
    end
    local result = chunk()
    moduleCache[formattedPath] = result
    return result
end
print("Initializing Vape core framework with cache busting...")
local success, err = pcall(function()
    return require("Main")
end)
if success then
    print("Vape framework successfully initialized.")
else
    error("Failed to initialize framework Main.lua: " .. tostring(err))
end