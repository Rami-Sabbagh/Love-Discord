--Basic operations plugin
local botAPI, discord, pluginPath, pluginDir = ...

local ffi = require("ffi")
local dataStorage = require("bot.data_storage")
local pluginManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")

local plugin = {}

--== Plugin Meta ==--

plugin.name = "Basic" --The visible name of the plugin
plugin.version = "V2.0.0" --The visible version string of the plugin
plugin.description = "Handles basic operations" --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

--Shared embed, could be used by any command
local adminEmbed = discord.embed()
adminEmbed:setTitle("You need to have administrator permissions to use this command :warning:")

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

    commands.help = commands.commands --Temporary
end

function commands.ping(message, reply, commandName, ...)
    local letterI = commandName:sub(2,2)
    local letterO = (letterI == "I") and "O" or "o"
    local pong = commandName:sub(1,1)..letterO..commandName:sub(3,4)
    local explosion = (pong == "PONG") and " :boom:" or ""
    if pong == "PONG" then pong = "**PONG**" end
    reply:send(pong.." :ping_pong:"..explosion)
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

    local showPrefix = discord.embed()
    showPrefix:setTitle("You need to have administrator permissions to set the prefix :warning:")
    showPrefix:setDescription("But you can use this command to check the prefix set :wink:")

    local replyEmbed = discord.embed()

    function commands.setprefix(message, reply, commandName, level, newPrefix)
        local prefixData = dataStorage["commands_manager/prefix"]
        
        if not botAPI:isFromAdmin(message) then
            local guildPrefix = prefixData[tostring(guildID)]
            local channelPrefix = prefixData[tostring(guildID or "").."_"..tostring(message:getChannelID())]
            showPrefix:setField(1, "Guild's Prefix:", guildPrefix and "`"..guildPrefix.."`" or "default (`"..commandsManager.defaultPrefix.."`)", true)
            showPrefix:setField(2, "Channel's Prefix:", channelPrefix and "`"..channelPrefix.."`" or "not set", true)
            reply:send(false, showPrefix)
            return
        end

        local guildID = message:getGuildID()

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

--Say command
do
    local sayUsage = discord.embed()
    sayUsage:setTitle("Usage: :notepad_spiral:")
    sayUsage:setDescription("```css\nsay <content> [...]\n```")

    local everyoneEmbed = discord.embed()
    everyoneEmbed:setTitle("You need to have administrator permissions to mention everyone :warning:")

    function commands.say(message, reply, commandName, ...)
        local content = table.concat({...}, " ")
        if content == "" then reply:send(false, sayUsage) return end
        if content:find("@everyone") and not botAPI:isFromAdmin(message) then reply:send(false, everyoneEmbed) return end
        reply:send(content)

        if message:getGuildID() then pcall(message.delete, message) end
    end
end

--Embed command
do
    local replyEmbed = discord.embed()
    local embedUsage = discord.embed()
    embedUsage:setTitle("Usage: :notepad_spiral:")
    embedUsage:setDescription("```css\nembed [title] [description]\n```")

    local everyoneEmbed = discord.embed()
    everyoneEmbed:setTitle("You need to have administrator permissions to mention everyone :warning:")

    function commands.embed(message, reply, commandName, title, description)
        if not (title or description) then reply:send(false, embedUsage) return end

        if title and title:find("@everyone") and not botAPI:isFromAdmin(message) then reply:send(false, everyoneEmbed) return end
        if description and description:find("@everyone") and not botAPI:isFromAdmin(message) then reply:send(false, everyoneEmbed) return end

        replyEmbed:setTitle(title)
        replyEmbed:setDescription(description)

        reply:send(false, replyEmbed)

        if message:getGuildID() then pcall(message.delete, message) end
    end
end

--Snowflake command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("Usage: :notepad_spiral:")
    usageEmbed:setDescription(table.concat({
        "```css",
        "snowflake <snowflake> /* Prints snowflake information */",
        "snowflake /* Prints information of self generated snowflake */",
        "```"
    }, "\n"))

    local infoEmbed = discord.embed()
    infoEmbed:setTitle("Snowflake information: :clipboard:")

    function commands.snowflake(message, reply, commandName, sf)
        if sf == "help" then reply:send(false, usageEmbed) return end
        sf = discord.snowflake(sf)

        infoEmbed:setDescription(tostring(sf))

        infoEmbed:setField(1, "Timestamp", sf:getTime(), true)
        infoEmbed:setField(2, "Date/Time", os.date("%c", sf:getTime()), true)
        infoEmbed:setField(3, "Discord Timestamp", sf:getTimeSinceDiscordEpoch(), true)

        infoEmbed:setField(4, "Worker ID:", sf:getWorkerID(), true)
        infoEmbed:setField(5, "Process ID:", sf:getProcessID(), true)
        infoEmbed:setField(6, "Increment:", sf:getIncrement(), true)

        reply:send(false, infoEmbed)
    end
end

--== Plugin Events ==--

plugin.events = {}; local events = plugin.events

return plugin