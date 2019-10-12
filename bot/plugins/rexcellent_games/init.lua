--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local plugin = {}

local lastMessages = {}

--== Plugin Meta ==--

plugin.name = "Rexcellent Games" --The visible name of the plugin
plugin.version = "V0.0.1" --The visible version string of the plugin
plugin.description = "Contains Rexcellent Games Server special commands, only works there" --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

plugin.commands = {}; local commands = plugin.commands

function commands.this(message, reply, commandName, ...)
    local channelID = tostring(message:getChannelID())
    
    local lastMessage = lastMessages[channelID]
    if lastMessage then
        pcall(lastMessage.addReaction, lastMessage, "this:580812863111954442")
        lastMessages[channelID] = nil --We don't want to react again
    end

    if message:getGuildID() then pcall(message.delete, message) end
end

function commands.antisnipe(message, reply, commandName, ...)
    if message:getGuildID() then pcall(message.delete, message) end
end

--== Events ==--

plugin.events = {}; local events = plugin.events

function events.MESSAGE_CREATE(message)
    local channelID = tostring(message:getChannelID())
    lastMessages[channelID] = message
end

return plugin