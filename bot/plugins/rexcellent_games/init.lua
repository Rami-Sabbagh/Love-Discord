--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")
local rolesManager = require("bot.roles_manager")

local plugin = {}

local lastMessages = {}
local suggestionChannels = {}

--== Plugin Meta ==--

plugin.name = "Rexcellent Games" --The visible name of the plugin
plugin.version = "V0.0.1" --The visible version string of the plugin
plugin.description = "Contains Rexcellent Games Server special commands, works only there" --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Shared Embeds ==--

local noDMEmbed = discord.embed()
noDMEmbed:setTitle("This command could be used only in guilds (servers) :warning:")

local adminEmbed = discord.embed()
adminEmbed:setTitle("You need to have administrator permissions to use this command :warning:")

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

--Suggest Command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("Usage: :notepad_spiral:")
    usageEmbed:setDescription(table.concat({
        "```css",
        "suggestion <suggestion> /* Submit a suggestion */",
        "```"
    }, "\n"))

    local notSetupEmbed = discord.embed()
    notSetupEmbed:setTitle("Failed to send then suggestion :warning:")
    notSetupEmbed:setDescription("The suggestion system is not configured on this server !")

    local suggestionEmbed = discord.embed()
    suggestionEmbed:setTitle("Suggestion")

    local successEmbed = discord.embed()
    successEmbed:setTitle("The suggestions has been sent successfully :white_check_mark:")

    function commands.suggestion(message, reply, commandName, suggestion, ...)
        if not message:getGuildID() then reply:send(false, noDMEmbed) return end

        local guildID = tostring(message:getGuildID())
        local suggestionChannel = suggestionChannels[guildID]
        if not suggestionChannel then reply:send(false, notSetupEmbed) return end

        if not suggestion then reply:send(false, usageEmbed) return end
        suggestion = table.concat({suggestion, ...}, " ")

        suggestionEmbed:setDescription(suggestion)

        local author = message:getAuthor()
        suggestionEmbed:setFooter(string.format("Suggested by %s#%s", author:getUsername(), author:getDisciminator()))

        suggestionEmbed:setImage()
        local attachments = message:getAttachments()
        if attachments then
            for k, attachment in pairs(attachments) do
                if attachment:isImage() then
                    suggestionEmbed:setImage(attachment:getURL(), attachment:getProxyURL(), attachment:getWidth(), attachment:getHeight())
                    break
                end
            end
        end

        local sentMessage = suggestionChannel:send(false, suggestionEmbed)
        if sentMessage then
            sentMessage:addReaction(":thumbsup:")
            sentMessage:addReaction(":thumbsdown:")
        end

        reply:send(false, successEmbed)
    end
end

--SetSuggestChannel Command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("Usage: :notepad_spiral:")
    usageEmbed:setDescription(table.concat({
        "```css",
        "setSuggestionsChannel <new channel tag> /* Sets the channel for sending in suggestions */",
        "setSuggestionsChannel clear /* Clears the set channel for sending in suggestions and disables the suggestions system */",
        "```"
    }, "\n"))

    local successEmbed = discord.embed()
    successEmbed:setTitle("The suggestions channel has been set successfully :white_check_mark:")

    local failureEmbed = discord.embed()

    function commands.setsuggestionschannel(message, reply, commandName, channelTag)
        if not message:getGuildID() then reply:send(false, noDMEmbed) return end
        if not rolesManager:isFromAdmin(message) then reply:send(false, adminEmbed) return end
        if not channelTag then reply:send(false, usageEmbed) return end

        local guildID = message:getGuildID()

        channelTag = channelTag:gsub("[<#>]", "")
        if not channelTag:match("^%d*$") then
            failureEmbed:setTitle("Invalid channel :warning:")
            reply:send(false, failureEmbed)
            return
        end
        
        local channel, err = pcall(discord.channel, channelTag) --Fetch the channel object
        if not channel then
            print("Failed to set suggestion channel", err, channelTag)
            failureEmbed:setTitle("Failed to set suggestion channel :warning:")
            reply:send(false, failureEmbed)
            return
        end

        suggestionChannels[tostring(guildID)] = channel
        local suggestionSnowflakes = dataStorage["plugins/rexcellent_games/suggestions_snowflakes"]
        suggestionSnowflakes[tostring(guildID)] = channelTag
        dataStorage["plugins/rexcellent_games/suggestions_snowflakes"] = suggestionSnowflakes

        reply:send(false, successEmbed)
    end
end

--== Events ==--

plugin.events = {}; local events = plugin.events

--Track the last message sent for the "this" command to work
function events.MESSAGE_CREATE(message)
    local channelID = tostring(message:getChannelID())
    lastMessages[channelID] = message
end

--Retrieve each guild's suggestion channel
function events.GUILD_CREATE(guild)
    local suggestionSnowflakes = dataStorage["plugins/rexcellent_games/suggestions_snowflakes"]
    local guildID = tostring(guild:getID())
    local targetChannelID = suggestionSnowflakes[guildID]
    if not targetChannelID then return end --No suggestion channel for this guild

    local channels = guild:getChannels()
    if channels then
        for k, channel in pairs(channels) do
            local channelID = tostring(channel:getID())
            if targetChannelID == channelID then
                --Found
                suggestionChannels[guildID] = channel
                return
            end
        end
        --Channel not found, it must have been deleted
        suggestionChannels[guildID] = false
        --Even so, keep the local reference in the data storage
    end
end

--Fetch each guild's suggestion channel after reload
function events.RELOAD()
    local suggestionSnowflakes = dataStorage["plugins/rexcellent_games/suggestions_snowflakes"]
    for guildID, channelID in pairs(suggestionSnowflakes) do
        local channel, err = pcall(discord.channel, channelID)
        if not channel then print("Failed to fetch suggestion channel on reload:", err) else
            suggestionChannels[guildID] = channel
        end
    end
end

--TODO: HOOK INTO CHANNEL DELETE

return plugin