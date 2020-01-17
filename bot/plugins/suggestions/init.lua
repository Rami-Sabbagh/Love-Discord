--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")
local rolesManager = require("bot.roles_manager")

local plugin = {}

local suggestionChannels = {}

--== Plugin Meta ==--

plugin.name = "Suggestions" --The visible name of the plugin
plugin.icon = ":envelope:" --The plugin icon to be shown in the help command
plugin.version = "V1.1.0" --The visible version string of the plugin
plugin.description = "A basic suggestions system." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Shared Embeds ==--

local noDMEmbed = discord.embed()
noDMEmbed:setTitle("This command could be used only in servers :warning:")

local adminEmbed = discord.embed()
adminEmbed:setTitle("You need to have administrator permissions to use this command :warning:")

--== Shared Methods ==--
local defaultReactions = {
    upvote = "thumbsup",
    downvote = "thumbsdown",
    accepted = "white_check_mark",
    rejected = "negative_squared_cross_mark",
    done = "ballot_box_with_check"
}

local function getReactionEmoji(guildID, id, fetch)
    local suggestionEmojies = dataStorage["plugins/rexcellent_games/suggestions_emojies"]
    local guildEmojies = suggestionEmojies[tostring(guildID)] or {}
    
    local emojiID = guildEmojies[id] or defaultReactions[id]
    
    if fetch and tonumber(emojiID) then
        local emoji = discord.emoji(false, emojiID)
        return emoji:getName()..":"..tostring(emoji:getID())
    else
        return emojiID
    end
end

--== Commands ==--

plugin.commands = {}; local commands = plugin.commands

--Suggest Command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("suggest")
    usageEmbed:setDescription("Submit a suggestion for the server admins to inspect.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "suggestion <suggestion> /* Submit a suggestion */",
        "```"
    }, "\n"))

    local notSetupEmbed = discord.embed()
    notSetupEmbed:setTitle("Failed to send the suggestion :warning:")
    notSetupEmbed:setDescription("The suggestions system is not configured on this server !")

    local suggestionEmbed = discord.embed()
    suggestionEmbed:setTitle("Suggestion")
    suggestionEmbed:setColor(0xDBBF59)

    local successEmbed = discord.embed()
    successEmbed:setTitle("The suggestion has been sent successfully :white_check_mark:")

    function commands.suggestion(message, reply, commandName, suggestion, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
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
            sentMessage:addReaction(getReactionEmoji(guildID, "upvote"))
            love.timer.sleep(1) --Sleep 1 second between the reactions so the ratelimit is not faced instantly
            sentMessage:addReaction(getReactionEmoji(guildID, "downvote"))
        end

        reply:send(false, successEmbed)
    end

    commands.suggest = commands.suggestion --Alias
end

--SetSuggestChannel Command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("setSuggestionsChannel")
    usageEmbed:setDescription("Sets the channel for sending suggestion embeds into.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "setSuggestionsChannel <new channel tag> /* Sets the channel for sending in suggestions */",
        "setSuggestionsChannel clear /* Clears the set channel for sending in suggestions and disables the suggestions system */",
        "```"
    }, "\n"))

    local successEmbed = discord.embed()
    successEmbed:setTitle("The suggestions channel has been set successfully :white_check_mark:")

    local failureEmbed = discord.embed()

    function commands.setsuggestionschannel(message, reply, commandName, channelTag)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
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

local waitingReaction = {}

--SetSuggestionsReaction
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("setSuggestionsReaction")
    usageEmbed:setDescription("Customize the suggestions reactions emojis for your guild.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "setSuggestionsReaction upvote /* Set the emoji for the upvote reaction */",
        "setSuggestionsReaction downvote /* Set the emoji for the downvote reaction */",
        "setSuggestionsReaction accepted /* Set the emoji for the accepted reaction */",
        "setSuggestionsReaction rejected /* Set the emoji for the rejected reaction */",
        "setSuggestionsReaction done /* Set the emoji for the done reaction */",
        "",
        "setSuggestionsChannel reset /* Restore the original reactions emojis */",
        "```"
    }, "\n"))

    local resetEmbed = discord.embed()
    resetEmbed:setTitle("The suggestions reaction has been reset successfully :white_check_mark:")

    local waitingEmbed = discord.embed()

    local actionsNames = {"upvote", "downvote", "accepted", "rejected", "done", "reset"}
    for k,v in ipairs(actionsNames) do actionsNames[v] = k end

    function commands.setsuggestionsreaction(message, reply, commandName, action)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not message:getGuildID() then reply:send(false, noDMEmbed) return end
        if not rolesManager:isFromAdmin(message) then reply:send(false, adminEmbed) return end
        if not action then reply:send(false, usageEmbed) return end
        if not actionsNames[action] then reply:send(false, usageEmbed) return end

        local guildID = tostring(message:getGuildID())

        --Delete the previous request
        if waitingReaction.message then
            waitingReaction.message:delete()
            waitingReaction = {}
        end

        if action == "reset" then
            local suggestionEmojies = dataStorage["plugins/rexcellent_games/suggestions_emojies"]
            suggestionsEmojies[guildID] = {}
            dataStorage["plugins/rexcellent_games/suggestions_emojies"] = suggestionEmojies
            reply:send(false, resetEmbed)
            return
        end

        waitingEmbed:setTitle("Please react with the new emoji for `"..action.."`")
        local waitingMessage = reply:send(false, waitingEmbed)

        waitingReaction.message = waitingMessage
        waitingReaction.requestMessage = message
        waitingReaction.action = action
    end
end

--== Events ==--

plugin.events = {}; local events = plugin.events

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

--Unregister the suggestions channel when deleted
function events.CHANNEL_DELETE(channel)
    local guildID = channel:getGuildID()
    if not guildID then return end --DM channel
    guildID = tostring(guildID)

    if suggestionChannels[guildID] ~= channel then return end --Not a suggestions channel

    --Unregister the channel
    suggestionChannels[guildID] = nil
    local suggestionSnowflakes = dataStorage["plugins/rexcellent_games/suggestions_snowflakes"]
    suggestionSnowflakes[guildID] = nil
    dataStorage["plugins/rexcellent_games/suggestions_snowflakes"] = suggestionSnowflakes
end

local reactionActions = {
    ["accepted"] = { verb = "Accepted", color = 0x5FF44B },
    ["rejected"] = { verb = "Denied", color = 0xEF5047 },
    ["done"] = { verb = "Done", color = 0x42B0F4 }
}

--Suggestion Accepted/Denied/Done
local function suggestionReaction(info)
    local userID, guildID, channelID, messageID = info.userID, info.guildID, info.channelID, info.messageID
    local emoji = info.emoji

    if not guildID then return end --DM reaction
    if not suggestionChannels[tostring(guildID)] then return end --This guild doesn't have a suggestions channel
    if suggestionChannels[tostring(guildID)]:getID() ~= channelID then return end --It's not the suggestions channel

    local emojiName = tostring(emoji:getID() or emoji:getName())

    local action
    for k,v in pairs(reactionActions) do
        if emojiName == getReactionEmoji(guildID, k) then
            action = v
            break
        end
    end
    if not action then return end --Useless reaction

    --Figure out if he's an admin doing this
    local reactionMember = discord.guildMember(tostring(guildID), tostring(userID))
    if not (rolesManager:doesMemberHaveAdminRole(guildID, reactionMember) or rolesManager:isGuildOwner(guildID, userID)) then return end --Not an admin

    local message = discord.message(tostring(channelID), tostring(messageID))
    local author = message:getAuthor()

    --Check if the suggestion embed is from bot itself
    if author ~= botAPI.me then return end --Ignore the message
    if #message:getContent() > 0 then return end --Ignore the messages with text content

    for k, embed in pairs(message:getEmbeds()) do
        if embed:getType() == "rich" then
            local title, description = embed:getTitle(), embed:getDescription()
            if title and description then
                --Suggestions embeds only
                if title == "Suggestion" or title == "Suggestion Accepted" or title == "Suggestion Rejected" or title == "Suggestion Done" then
                    local patchedEmbed = discord.embed(embed:getAll())
                    patchedEmbed:setTitle("Suggestion "..action.verb)
                    patchedEmbed:setColor(action.color)

                    local user = reactionMember:getUser()
                    patchedEmbed:setFooter(action.verb.." by "..user:getUsername().."#"..user:getDiscriminator()..", "..patchedEmbed:getFooter())

                    message:edit(false, patchedEmbed)

                    break
                end
            end
        end
    end
end

--Suggestion reactions customization
--TODO: Reject the reaction if other action has the same emoji!
local function customizationReaction(info)
    if not waitingReaction.message then return end

    local userID, guildID, channelID, messageID = info.userID, info.guildID, info.channelID, info.messageID
    local emoji = info.emoji

    if messageID ~= waitingReaction.message:getID() then return end
    if userID ~= waitingReaction.requestMessage:getAuthor():getID() then return end
    
    local suggestionEmojies = dataStorage["plugins/rexcellent_games/suggestions_emojies"]
    local guildEmojis = suggestionEmojies[tostring(guildID)] or {}

    guildEmojis[waitingReaction.action] = tostring(emoji:getID() or emoji:getName())

    suggestionEmojies[tostring(guildID)] = guildEmojis
    dataStorage["plugins/rexcellent_games/suggestions_emojies"] = suggestionEmojies

    local reactionSetEmbed = discord.embed()
    reactionSetEmbed:setTitle("The suggestions `"..waitingReaction.action.."` reaction has been set successfully for this guild :white_check_mark:")

    waitingReaction.message:edit(false, reactionSetEmbed)
    waitingReaction = {}
end

function events.MESSAGE_REACTION_ADD(info)
    suggestionReaction(info)
    customizationReaction(info)
end

return plugin