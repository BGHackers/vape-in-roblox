-- loader.lua
local HttpService = game:GetService("HttpService")
local BaseUrl = "https://raw.githubusercontent.com/BGHackers/vape-in-roblox/main/src/"
local moduleCache = {}

-- Overwrite global require to dynamically fetch and run modules via HTTP
local oldRequire = require
getgenv().require = function(modulePath)
    -- Convert dot notation (e.g., gui.components.Button) to path slashes
    local formattedPath = modulePath:gsub("%.", "/")

    if moduleCache[formattedPath] then
        return moduleCache[formattedPath]
    end

    local fileUrl = BaseUrl .. formattedPath .. ".lua"
    local success, response = pcall(function()
        return game:HttpGet(fileUrl)
    end)

    if not success or not response then
        -- Fallback to standard require for internal Roblox ModuleScripts
        if oldRequire then
            local ok, res = pcall(oldRequire, modulePath)
            if ok then
                return res
            end
        end
        error("Failed to dynamically load module: " .. modulePath .. " (URL: " .. fileUrl .. ")")
    end

    local chunk, err = loadstring(response)
    if not chunk then
        error("Syntax error in module " .. modulePath .. ": " .. tostring(err))
    end

    local result = chunk()
    moduleCache[formattedPath] = result
    return result
end

-- Run the core framework Main.lua
print("Initializing Vape core framework...")

local success, err = pcall(function()
    return require("Main")
end)

if success then
    print("Vape framework successfully initialized.")
else
    error("Failed to initialize framework Main.lua: " .. tostring(err))
end