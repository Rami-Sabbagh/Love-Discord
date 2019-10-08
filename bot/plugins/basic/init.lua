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

--Shared embed, could be used by any command
local adminEmbed = discord.embed()
adminEmbed:setTitle("You need to have administrator permissions to use this command :warning:")

--Shared embed, could be used by any command
local developerEmbed = discord.embed()
developerEmbed:setTitle("This command could be only used by the bot's developers :warning:")

plugin.commands = {}; local commands = plugin.commands

--Commands command, lists available commands
do
    local commandsEmbed = discord.embed()
    commandsEmbed:setTitle("Available commands: :tools:")

    function commands.commands(message, reply, commandName, ...)
        if not commandsEmbed:getDescription() then
            local commandsList = {}
            for c in pairs(commandsManager:getCommands()) do commandsList[#commandsList + 1] = c end
            commandsList = table.concat(commandsList, ", ")
            commandsEmbed:setDescription(table.concat({
                "```css",
                commandsList,
                "```"
            }, "\n"))
        end

        reply:send(false, commandsEmbed)
    end
end

function commands.ping(message, reply, commandName, ...)
    local letterI = commandName:sub(2,2)
    local letterO = (letterI == "I") and "O" or "o"
    local pong = commandName:sub(1,1)..letterO..commandName:sub(3,4)
    local explosion = (pong == "PONG") and " :boom:" or ""
    if pong == "PONG" then pong = "**PONG**" end
    reply:send(pong.." :ping_pong:"..explosion)
end

--Reload command
do
    local reloadEmbedSuccess = discord.embed()
    reloadEmbedSuccess:setTitle("Reloaded successfully :white_check_mark:")
    local reloadEmbedFailure = discord.embed()
    reloadEmbedFailure:setTitle("Failed to reload :warning:")

    function commands.reload(message, reply, commandName, ...)
        if not botAPI:isFromDeveloper(message) then reply:send(false, developerEmbed) return end

        local ok, err = pluginManager:reload()
        if ok then
            commandsManager:reloadCommands()
            reply:send(false, reloadEmbedSuccess)
        else
            reloadEmbedFailure:setDescription("||```\n"..err:gsub("plugin: ","plugin:\n").."\n```||")
            reply:send(false, reloadEmbedFailure)
        end
    end
end

function commands.stop(message, reply, commandName, ...)
    if not botAPI:isFromDeveloper(message) then reply:send(false, developerEmbed) return end
    reply:send("Goodbye :wave:")
    love.event.quit()
end

--Restart command
do
    local restartEmbed = discord.embed()
    restartEmbed:setTitle(":gear: Restarting :gear:")
    restartEmbed:setDescription("This might take a while...")
    function commands.restart(message, reply, commandName, ...)
        if not botAPI:isFromDeveloper(message) then reply:send(false, developerEmbed) return end
        
        love.event.quit("restart")

        local pdata = dataStorage["plugins/basic/restart"]
        pdata.channelID = tostring(message:getChannelID())
        pdata.timestamp = os.time()
        dataStorage["plugins/basic/restart"] = pdata

        reply:send(false, restartEmbed)
        reply:triggerTypingIndicator()
        discord.gateway.disconnect = function() end --Show the bot as online while restarting xd
    end
end

function commands.dumpdata(message, reply, commandName, dname)
    if not botAPI:isFromDeveloper(message) then reply:send(false, developerEmbed) return end
    if not dname then reply:send("Missing package name!") end

    local data = discord.json:encode_pretty(dataStorage[dname])
    local message = table.concat({
        "```json",
        data,
        "```"
    },"\n")
    
    if #message > 2000 then
        reply:send("Data too large, uploaded in a file :wink:", false, {dname:gsub("/","_")..".json",data})
    else
        reply:send(message)
    end
end

function commands.data(message, reply, commandName, action, dname)
    if not botAPI:isFromDeveloper(message) then reply:send(false, developerEmbed) return end
end

--Setprefix command
do
    local setprefixHelpDM = discord.embed()
    setprefixHelpDM:setTitle("Usage: :notepad_spiral:")
    setprefixHelpDM:setDescription(table.concat({
        "```css",
        "setprefix channel <new_prefix>",
        "setprefix clear channel",
        "```"
    },"\n"))

    local setprefixHelp = discord.embed(setprefixHelpDM:getAll())
    setprefixHelp:setDescription(table.concat({
        "```css",
        "setprefix channel <new_prefix>",
        "setprefix guild <new_prefix>",
        "setprefix clear channel",
        "setprefix clear guild",
        "```"
    },"\n"))

    local replyEmbed = discord.embed()

    function commands.setprefix(message, reply, commandName, level, newPrefix)
        if not botAPI:isFromAdmin(message) then reply:send(false, adminEmbed) return end

        local guildID = message:getGuildID()

        local prefixData = dataStorage["commands_manager/prefix"]

        if guildID then
            local guildPrefix = prefixData[tostring(guildID)]
            local channelPrefix = prefixData[tostring(guildID or "").."_"..tostring(message:getChannelID())]
            setprefixHelp:setField(1, "Guild's Prefix:", guildPrefix and "`"..guildPrefix.."`" or "default (`"..commandsManager.defaultPrefix.."`)", true)
            setprefixHelp:setField(2, "Channel's Prefix:", channelPrefix and "`"..channelPrefix.."`" or "not set", true)
        else
            local channelPrefix = prefixData["_"..tostring(message:getChannelID())]
            setprefixHelpDM:setField(1, "DM Channel's Prefix:", channelPrefix and "`"..channelPrefix.."`" or "default (no prefix)")
        end

        if not (level and newPrefix) then reply:send(false, guildID and setprefixHelp or setprefixHelpDM) return end

        local prefixType

        if level == "clear" then
            if newPrefix == "guild" and not guildID or (newPrefix ~= "guild" and newPrefix ~= "channel") then
                reply:send(false, guildID and setprefixHelp or setprefixHelpDM) return end
            prefixType = newPrefix
        else
            if level == "guild" and not guildID or (level ~= "guild" and level ~= "channel") then
                reply:send(false, guildID and setprefixHelp or setprefixHelpDM) return end
            prefixType = level
        end

        local prefixKey = (prefixType == "guild") and tostring(guildID) or tostring(guildID or "").."_"..tostring(message:getChannelID())

        if level == "clear" then
            prefixData[prefixKey] = nil
            replyEmbed:setTitle("The "..newPrefix.."'s commands prefix has been cleared successfully :white_check_mark:")
            reply:send(false, replyEmbed)
        else
            prefixData[prefixKey] = newPrefix
            replyEmbed:setTitle(level:sub(1,1):upper()..level:sub(2,-1).."'s commands prefix has been set to `"..newPrefix.."` successfully :white_check_mark:")
            reply:send(false, replyEmbed)
        end

        dataStorage["commands_manager/prefix"] = prefixData
    end
end

--[[
plugin.commands. = function(message, reply, commandName, ...)

end
]]

--== Plugin Events ==--

plugin.events = {}; local events = plugin.events

do
    local restartedEmbed = discord.embed()
    restartedEmbed:setTitle("Restarted Successfully :white_check_mark:")

    function events.READY(data)
        local pdata = dataStorage["plugins/basic/restart"]
        if pdata.channelID then
            local replyChannel = discord.channel{
                id = pdata.channelID,
                type = discord.enums.channelTypes["GUILD_TEXT"]
            }

            local delay = os.time() - pdata.timestamp
            restartedEmbed:setDescription("Operation took "..delay.." seconds:stopwatch:")

            pdata.channelID = nil
            pdata.timestamp = nil
            dataStorage["plugins/basic/restart"] = pdata

            pcall(replyChannel.send, replyChannel, false, restartedEmbed)
        end
    end
end

return plugin