-- loader.lua
local HttpService = game:GetService("HttpService")
local BaseUrl = "https://raw.githubusercontent.com/BGHackers/vape-in-roblox/main/src/"

local moduleCache = {}

local function httpRequire(path)
    if moduleCache[path] then 
        return moduleCache[path] 
    end

    local fileUrl = BaseUrl .. path
    if not string.match(fileUrl, "%.lua$") then 
        fileUrl = fileUrl .. ".lua" 
    end

    local success, response = pcall(function() 
        return game:HttpGet(fileUrl) 
    end)

    if not success or not response then 
        error("Failed to load: " .. path) 
    end

    local chunk, err = loadstring(response)
    if not chunk then 
        error("Compile error (" .. path .. "): " .. tostring(err)) 
    end

    local result = chunk()
    moduleCache[path] = result
    return result
end

local targetGame = "game1"

local baseSuccess, baseConfig = pcall(function()
    return httpRequire("games/" .. targetGame .. "/base")
end)

if not baseSuccess or type(baseConfig) ~= "table" then
    error("Failed to load base configuration for " .. targetGame)
end

for category, modules in pairs(baseConfig) do
    for _, modulePath in ipairs(modules) do
        task.spawn(function()
            local success, err = pcall(function() 
                httpRequire(modulePath) 
            end)
            if not success then
                warn("Failed to load module: " .. modulePath .. " (Error: " .. tostring(err) .. ")")
            end
        end)
    end
end