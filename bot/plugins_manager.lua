--Discörd Böt plugins manager
local pluginsManager = {}

--Initialize the plugin manager
function pluginsManager:initialize()
    self.botAPI = require("bot")
    self.discord = self.botAPI.discord

    print(string.rep("-", 40))
    --Load and initialize the available plugins
    print("Loading Plugins...")
    self.chunks = assert(self:_loadPlugins()) --Loaded plugins list
    print("Initializing Plugins...")
    self.plugins = assert(self:_initializePlugins(self.chunks)) --Initialized plugins list
    print(string.rep("-", 40))

    --Hook plugins events
    self.discord:hookEvent("ANY",function(eventName, ...)
        for pluginName, plugin in pairs(self.plugins) do
            if plugin.events then
                if plugin.events.ANY then
                    local ok, err = pcall(plugin.events.ANY, eventName, ...)
                    if not ok then print("/!\\ Plugin Event Error",pluginName,"ANY",err) end
                end

                if plugin.events[eventName] then
                    local ok, err = pcall(plugin.events[eventName], ...)
                    if not ok then print("/!\\ Plugin Event Error",pluginName,eventName,err) end
                end
            end
        end
    end)
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
    self.plugins = plugins
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
    local chunks = {} --New chunks table

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
        local ok, err = pcall(chunk, self.botAPI, self.discord, "bot.plugins."..pluginName, "bot/plugins/"..pluginName)
        if not ok then
            return false, "Failed to initialize '"..pluginName.."' plugin: "..tostring(err)
        end
        plugins[pluginName] = err
    end

    return plugins
end

return pluginsManager