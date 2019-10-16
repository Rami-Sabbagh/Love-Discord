--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")
local rolesManager = require("bot.roles_manager")

local plugin = {}

local lastMessages = {}

--== Plugin Meta ==--

plugin.name = "Rexcellent Games" --The visible name of the plugin
plugin.icon = ":question:" --The plugin icon to be shown in the help command
plugin.version = "V0.0.1" --The visible version string of the plugin
plugin.description = "Contains Rexcellent Games Server special commands, works only there." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

plugin.commands = {}; local commands = plugin.commands

do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("this")
    usageEmbed:setDescription("Reacts with the <:this:580812863111954442> emoji on the last message, and deletes the original command message if possible.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\nthis\n```")

    function commands.this(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        local channelID = tostring(message:getChannelID())
        
        local lastMessage = lastMessages[channelID]
        if lastMessage then
            pcall(lastMessage.addReaction, lastMessage, "this:580812863111954442")
            lastMessages[channelID] = nil --We don't want to react again
        end

        if message:getGuildID() then pcall(message.delete, message) end
    end
end

do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("antisnipe")
    usageEmbed:setDescription("Deletes the original command message if possible so that snipe utilities (which display the latest deleted message) would not show the actual delete message.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\nantisnipe\n```")

    function commands.antisnipe(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if message:getGuildID() then pcall(message.delete, message) end
    end
end

--== Events ==--

plugin.events = {}; local events = plugin.events

--Track the last message sent for the "this" command to work
function events.MESSAGE_CREATE(message)
    local channelID = tostring(message:getChannelID())
    lastMessages[channelID] = message
end

return plugin