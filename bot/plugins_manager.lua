--Discörd bot plugins manager
local botAPI, discord = ...

local pluginsManager = {}

--Initialize the plugin manager
function pluginsManager:initialize()
    print(string.rep("-", 40))
    --Load and initialize the available plugins
    print("Loading Plugins...")
    self.chunks = assert(self:_loadPlugins()) --Loaded plugins list
    print("Initializing Plugins...")
    self.plugins = assert(self:_initializePlugins(self.chunks)) --Initialized plugins list
    print(string.rep("-", 40))
end

--Reloads the plugin manager
function pluginsManager:reload()
    --Attempt to reload the plugins
    print(string.rep("-", 40))
    print("Reloading Plugins...")
    local chunks, err = self:_loadPlugins()
    if not chunks then return false, err end
    print("Reinitializing Plugins...")
    local plugins, err = self:_initializePlugins(chunks)
    if not plugins then return false, err end
    print(string.rep("-", 40))
    return true --Success
end

--Returns the list of initialized plugins
function pluginsManager:getPlugins()
    return self.plugins
end

--== Internal Methods ==--

--Loads the chunks of the plugins
function pluginsManager:_loadPlugins()
    local chunk = {} --New chunks table

    for _, pluginName in ipairs(love.filesystem.getDirectoryItems("/bot/plugins/")) do
        local chunk, err = love.filesystem.load("/bot/plugins/"..pluginName.."/init.lua")
        if not chunk then
            return false, "Failed to load '"..pluginName.."' plugin: "..tostring(err)
        end
        chunks[pluginName] = chunk
    end

    return chunks
end

--Initialize the plugins chunks
function pluginsManager:_initializePlugins(chunks)
    local plugins = {}

    for pluginName, chunk in pairs(chunks) do
        local ok, err = pcall(chunk, botAPI, discord, "bot.plugins."..pluginName, "bot/plugins/"..pluginName)
        if not ok then
            return false, "Failed to enable initialize '"..pluginName.."' plugin: "..tostring(err)
        end
        plugins[pluginName] = ok
    end

    return plugins
end

return pluginsManager