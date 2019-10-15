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
noDMEmbed:setTitle("This command could be used only in servers :warning:")

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
    successEmbed:setColor(0xDBBF59)

    function commands.suggestion(message, reply, commandName, suggestion, ...)
        if not message:getGuildID() then reply:send(false, noDMEmbed) return end

        local guildID = tostring(message:getGuildID())
        local suggestionChannel = suggestionChannels[guildID]
        if not suggestionChannel then reply:send(false, notSetupEmbed) return end

        if not suggestion then reply:send(false, usageEmbed) return end
        suggestion = table.concat({suggestion, ...}, " ")

        suggestionEmbed:setDescription(suggestion)

        local author = message:getAuthor()
        suggestionEmbed:setFooter(string.format("Suggested by %s#%s", author:getUsername(), author:getDiscriminator()))

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
            sentMessage:addReaction("thumbsup")
            sentMessage:addReaction("thumbsdown")
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
        
        local ok, channel = pcall(discord.channel, channelTag) --Fetch the channel object
        if not ok then
            print("Failed to set suggestion channel", channel, channelTag)
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
    print("Fetching suggestions channels...")
    local suggestionSnowflakes = dataStorage["plugins/rexcellent_games/suggestions_snowflakes"]
    for guildID, channelID in pairs(suggestionSnowflakes) do
        local ok, channel = pcall(discord.channel, channelID)
        if not ok then print("Failed to fetch suggestion channel on reload:", channel, channelID) else
            suggestionChannels[guildID] = channel
        end
    end
end

--TODO: HOOK INTO CHANNEL DELETE

local reactionActions = {
    ["white_check_mark"] = { verb = "Accepted", color = 0x5FF44B },
    ["negative_squared_cross_mark"] = { verb = "Denied", color = 0xEF5047 },
    ["ballot_box_with_check"] = { verb = "Done", color = 0x42B0F4 }
}

--Suggestion Accepted/Denied/Done
function events.MESSAGE_REACTION_ADD(info)
    print("CP 1")
    local userID, guildID, channelID, messageID = info.userID, info.guildID, info.channelID, info.messageID
    local emoji = info.emoji

    --Figure out if he's an admin doing this
    local reactionMember = discord.guildMember(tostring(guildID), tostring(userID))
    if not rolesManager:doesMemberHaveAdminRole(guildID, reactionMember) then return end --Not an admin

    print("CP 2")

    local message = discord.message(tostring(channelID), tostring(messageID))
    local author = message:getAuthor()

    --Check if the suggestion embed is from bot itself
    if author ~= botAPI.me then return end --Ignore the message
    if #message:getContent() > 0 then return end --Ignore the messages with text content

    print("CP 3")

    for k, embed in pairs(message:getEmbeds()) do
        print("CP 4")
        if embed:getType() == "rich" then
            print("CP 5")
            local title, description = embed:getTitle(), embed:getDescription()
            if title and description then
                print("CP 6")
                --Suggestions embeds only
                if title == "Suggestion" or title == "Suggestion Accepted" or title == "Suggestion Rejected" or title == "Suggestion Done" then
                    print("CP 7")
                    local patchedEmbed = discord.embed(embed:getAll())
                    local emojiName = emoji:getName()
                    local action = reactionActions[emojiName]
                    if action then
                        print("CP 8")
                        patchedEmbed:setTitle("Suggestion "..action.verb)
                        patchedEmbed:setColor(action.color)
                        local user = member:getUser()
                        patchedEmbed:setFooter(action.verb.." by "..user:getUsername().."#"..user:getDiscriminator()..", "..patchedEmbed:getFooter())

                        message:getReplyChannel():send(false, patchedEmbed)
                    end

                    break
                end
            end
        end
    end
end

return plugin