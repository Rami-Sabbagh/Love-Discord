--Basic operations plugin
local botAPI, discord, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")
local pluginManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")

local plugin = {}

--== Plugin Meta ==--

plugin.name = "Basic" --The visible name of the plugin
plugin.version = "V0.0.1" --The visible version string of the plugin
plugin.description = "Handles basic operations" --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

plugin.commands = {}
plugin.commands.ping = function(message, reply, commandName, ...)
    local letterI = commandName:sub(2,2)
    local letterO = (letterI == "I") and "O" or "o"
    local pong = commandName:sub(1,1)..letterO..commandName:sub(3,4)
    local explosion = (pong == "PONG") and " :boom:" or ""
    reply:send(pong.." :ping_pong:"..explosion)
end

plugin.commands.reload = function(message, reply, commandName, ...)
    if not botAPI:isFromDeveloper(message) then reply:send("This command is for developers only :warning:") return end

    local ok, err = pluginManager:reload()
    if ok then
        commandsManager:reloadCommands()
        reply:send("Reloaded successfully :white_check_mark:")
    else
        reply:send("Failed to reload :warning:\n||```\n"..err.."\n```||")
    end
end

plugin.commands.stop = function(message, reply, commandName, ...)
    if not botAPI:isFromDeveloper(message) then reply:send("This command is for developers only :warning:") return end
    reply:send("Goodbye :wave:")
    love.event.quit()
end

plugin.commands.restart = function(message, reply, commandName, ...)
    if not botAPI:isFromDeveloper(message) then reply:send("This command is for developers only :warning:") return end
    reply:send("Restarting :gear:")
    local pdata = dataStorage["plugins/basic/restart"]
    pdata.channelID = tostring(message:getChannelID())
    dataStorage["plugins/basic/restart"] = pdata
    love.event.quit("restart")
end

--[[
plugin.commands. = function(message, reply, commandName, ...)

end
]]

--== Plugin Events ==--

plugin.events = {}

plugin.events.READY = function(data)
    local pdata = dataStorage["plugins/basic/restart"]
    if pdata.channelID then
        local replyChannel = discord.channel{
            id = pdata.channelID,
            type = discord.enums.channelTypes["GUILD_TEXT"]
        }
        pdata.channelID = nil
        dataStorage["plugins/basic/restart"] = pdata

        pcall(replyChannel.send, replyChannel, "Restarted Successfully :white_check_mark:")
    end
end

return plugin