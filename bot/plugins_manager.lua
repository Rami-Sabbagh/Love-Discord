--- Discörd Böt plugins manager.
-- @module bot.plugins_manager
-- @alias pluginsManager
local pluginsManager = {}

local dataStorage = require("bot.data_storage")

--[[Used data storage:
commands_manager/disabled_plugins
]]

local function triggerPluginsEvent(eventName, ...)
    for pluginName, plugin in pairs(pluginsManager.plugins) do
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
end

--- Initialize the plugin manager.
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
    self.discord:hookEvent("ANY", triggerPluginsEvent)
end

--- Reload the plugin manager.
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
    print("Triggering Plugins Reload Event...")
    triggerPluginsEvent("RELOAD")
    print(string.rep("-", 40))
    return true --Success
end

--- Update the plugins.
-- Called automatically by the bot api.
-- @tparam number dt The time between the last update call and this call in seconds.
function pluginsManager:update(dt)
    triggerPluginsEvent("UPDATE", dt)
end

--- Get the list of initialized plugins.
-- @treturn table The initialized plugins table, don't modify!
-- @todo Proper plugin ldoc object.
function pluginsManager:getPlugins()
    return self.plugins
end

--- Get a table of disabled plugins for a certain guild/channel.
-- @tparam ?string guildID The guild ID.
-- @tparam ?string channelID The channel ID.
-- @treturn table The disabled plugins at guild level table, don't modify!
-- @treturn table The disabled plugins at channel level table, don't modify!
function pluginsManager:getDisabledPlugins(guildID, channelID)
    local disabledPlugins = dataStorage["bot/disabled_plugins"]
    local guildKey, channelKey = tostring(guildID or ""), tostring(guildID or "").."_"..tostring(channelID or "")
    return disabledPlugins[guildKey] or {}, disabledPlugins[channelKey] or {}
end

--Check if a plugin is disabled or not for a certain guild/channel.
function pluginsManager:isPluginDisabled(guildID, channelID, pluginName)
    local guildPlugins, channelPlugins = pluginsManager:getDisabledPlugins(guildID, channelID)

    if type(channelPlugins[pluginName]) ~= "nil" then return channelPlugins[pluginName]
    else return guildPlugins[pluginName] end
end

--== Internal Methods ==--

--Loads the chunks of the plugins
function pluginsManager:_loadPlugins()
    local chunks = {} --New chunks table

    for _, pluginName in ipairs(love.filesystem.getDirectoryItems("/bot/plugins/")) do
        local ok, chunk, err = pcall(love.filesystem.load, "/bot/plugins/"..pluginName.."/init.lua")
        if not (ok and chunk) then
            return false, "Failed to load '"..pluginName.."' plugin: "..tostring(chunk or err)
        end
        chunks[pluginName] = chunk
    end

    return chunks
end

--Initialize the plugins chunks
function pluginsManager:_initializePlugins(chunks)
    local plugins = {}

    for pluginName, chunk in pairs(chunks) do
        local ok, err = pcall(chunk, self.botAPI, self.discord, pluginName, "bot.plugins."..pluginName, "bot/plugins/"..pluginName)
        if not ok then
            return false, "Failed to initialize '"..pluginName.."' plugin: "..tostring(err)
        end
        plugins[pluginName] = err
    end

    return plugins
end

return pluginsManager