--- The discord message class.
-- It can be obtained either from a discord event, or by requesting a message by it's ID from the discord servers.
-- @usage local fetchedMessage = discord.message("channel_id", "message_id") --The requested message.
-- @classmod discord.message

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.
local bit = discord.utilities.bit --Universal bit API.

local band = bit.band

local message = class("discord.structures.Message")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not value) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--REST Request with proper error handling (uses error level 3)
local function Request(endpoint, data, method, headers, useMultipart)
    local response_body, response_headers, status_code, status_line, failure_code, failure_line = discord.rest:request(endpoint, data, method, headers, useMultipart)
    if not response_body then
        error(response_headers, 3)
    else
        return response_body, response_headers, status_code, status_line
    end
end

--https://discordapp.com/developers/docs/resources/channel#message-object-message-flags
local messageFlags = {
    [1] = "CROSSPOSTED",
    [2] = "IS_CROSSPOST",
    [4] = "SUPPRESS_EMBEDS"
}

--- Create a new message object.
-- Either from an internal message data table, or by requesting the message data from discord servers.
-- @tparam table|string data Either a message data table (from an internal api), or a `Guild ID` as a string.
-- @tparam ?string messageID The `Message ID` as a string to fetch, only when `data` is a `Guild ID`.
-- @raise Request error when fails to request the message from discord servers.
function message:initialize(data, messageID)
    Verify(data, "data", "table", "string")

    if type(data) == "string" then
        Verify(messageID, "messageID", "string")

        local endpoint = string.format("/channels/%s/messages/%s", data, messageID)
        data = Request(endpoint)
    end

    --== Basic Fields ==--

    --- Internal fields.
    -- @section internal_fields

    --- ID of the message (snowflake)
    self.id = discord.snowflake(data.id)
    --- ID of the channel the message was sent in (snowflake)
    self.channelID = discord.snowflake(data.channel_id)
    --- Contents of the message (string)
    self.content = data.content
    --- When the message was sent (number)
    self.timestamp = data.timestamp
    --- Whether this was a TTS message (boolean)
    self.tts = data.tts
    --- Where this message mentions everyone (boolean)
    self.mentionEveryone = data.mention_everyone
    --- Whether this message is pinned (boolean)
    self.pinned = data.pinned
    --- Type of message (string)
    self.type = discord.enums.messageTypes[data.type]

    --== Optional Fields ==--

    --- Internal optional fields
    -- @section internal_optional_fields

    --- The author of this message (not guaranteed to be a valid user) (user)
    -- @field self.author
    if data.author then self.author = discord.user(data.author) end
    --- ID of the guild the message was sent in (snowflake)
    -- @field self.guildID
    if data.guild_id then self.guildID = discord.snowflake(data.guild_id) end
    --- Member properties for this message's author (guild member)
    -- @field self.member
    if data.member then self.member = discord.guildMember(data.member) end
    --- When the message was edited (or null if never) (number)
    self.editedTimestamp = data.edited_timestamp
    --- Users specifically mentioned in the message (array of user objects)
    -- @field self.mentions
    if data.mentions then
        self.mentions = {}
        for id, udata in pairs(data.mentions) do
            self.mentions[id] = discord.user(udata)
        end
    end
    --- Roles specifically mentioned in this message (array of snowflake objects)
    -- @field self.mentionRoles
    if data.mention_roles then
        self.mentionRoles = {}
        for id, snowflake in pairs(data.mention_roles) do
            self.mentionRoles[id] = discord.snowflake(snowflake)
        end
    end
    --- Any attached files (array of attachment objects)
    -- @field self.attachments
    if data.attachments then 
        self.attachments = {}
        for id, adata in pairs(data.attachments) do
            self.attachments[id] = discord.attachment(adata)
        end
    end
    --- Any embedded (array of embed objects)
    -- @field self.embeds
    if data.embeds then
        self.embeds = {}
        for id, edata in pairs(data.embeds) do
            self.embeds[id] = discord.embed(edata)
        end
    end
    --- Channels specifically mentioned in this message (array of channel mention objects)
    -- @field self.mentionChannels
    if data.mention_channels then
        self.mentionChannels = {}
        for id, cmdata in pairs(data.mention_channels) do
            self.mentionChannels[id] = discord.channelMention(cmdata)
        end
    end
    --- Reactions to the message (array of reaction objects)
    -- @field self.reactions
    if data.reactions then
        self.reactions = {}
        for id, rdata in pairs(data.reactions) do
            self.reactions[id] = discord.reaction(rdata)
        end
    end
    --- Used for validating a message was sent (snowflake)
    -- @field self.nonce
    if data.nonce then self.nonce = discord.snowflake(data.nonce) end
    --- If the message is generated by a webhook, this is the webhook's id (snowflake)
    -- @field self.webhookID
    if data.webhook_id then self.webhookID = discord.snowflake(data.webhook_id) end

    self.activity = data.activity --TODO: MESSAGE ACTIVITY OBJECT
    self.application = data.application --TODO: MESSAGE APPLICATION OBJECT
    self.messageReference = data.message_reference --TODO: MESSAGE REFERENCE OBJECT

    --- Message flags, describes extra features of the message (array of strings)
    -- @field self.flags
    if data.flags then
        self.flags = {}
        for b, flag in pairs(messageFlags) do
            if band(data.flags,b) > 0 then
                self.flags[#self.flags + 1] = flag
            end
        end
    end

    ---
    -- @section end
end

--== Methods ==--

--- Add a reaction to the message.
-- @tparam string|discord.emoji emoji The reaction to add, either a string which is the name of a standard emoji (ex `sweat`), or an emoji object.
-- @raise Request error on failure.
function message:addReaction(emoji)
    Verify(emoji, "emoji", "table", "string")
    if type(emoji) == "string" then
        emoji = discord.utilities.message.emojis[emoji] or emoji
    else
        emoji = emoji:getName()..":"..emoji:getID()
    end

    local endpoint = string.format("/channels/%s/messages/%s/reactions/%s/@me", tostring(self.channelID), tostring(self.id), emoji)
    Request(endpoint, nil, "PUT")
end

--- Delete the message.
-- @raise Request error on failure.
function message:delete()
    local endpoint = string.format("/channels/%s/messages/%s", tostring(self.channelID), tostring(self.id))
    Request(endpoint, nil, "DELETE")
end

--- Edits the message.
-- @tparam ?string content The new message content, standard emojis are automatically replaced with their unicode character.
-- @tparam ?discord.embed embed The new embed content of the message.
-- @raise `Messages content can't be longer than 2000 characters!`, `Either content or embed parameter has to be present!`
-- or request error on failure.
function message:edit(content, embed)
    Verify(content, "content", "string", "nil")
    Verify(embed, "embed", "table", "nil")

    if content and #content > 2000 then return error("Messages content can't be longer than 2000 characters!") end
    if content then content = discord.utilities.message.patchEmojis(content) end
    if embed then embed = embed:getAll() end

    if not content and not embed then return error("Either content or embed parameter has to be present!") end

    local endpoint = string.format("/channels/%s/messages/%s", tostring(self.channelID), tostring(self.id))
    return discord.message(Request(endpoint, {content = content or nil, embed = embed or nil}, "PATCH"))
end

--- Check if the message is pinned or not.
-- @treturn ?boolean Whether the message is pinned or not, `nil` when not known.
function message:isPinned() return self.pinned end

--- Check if the message was sent with `text to speech`.
-- @treturn ?boolean Whether the message was send with `text to speech` or not, `nil` when not known.
function message:isTTS() return self.tts end

--- Check if a user was mentioned or not in this message.
-- @tparam discord.user user The user to check.
-- @treturn boolean whether the user was mentioned or not.
function message:isUserMentioned(user)
    Verify(user, "user", "table")
    if not self.mentions then return false end --Can't know
    for k,v in pairs(self.mentions) do
        if v == user then return true end
    end
    return false
end

--- Get the user object of the message's author.
-- @treturn discord.user The author of the message.
function message:getAuthor() return self.author end

--- Get the list of attachments if there are any.
-- @treturn ?{discord.attachment,...} The message's attachments, `nil` when there are none, or if not known.
function message:getAttachments()
    if self.attachments then
        local attachments = {}
        for k,v in pairs(self.attachments) do attachments[k] = v end
        return attachments
    end
end

--- Get channel ID/snowflake of which the message was sent in.
-- @treturn discord.snowflake The channel ID/snowflake.
function message:getChannelID() return self.channelID end

--- Get the message content.
-- @treturn ?string The message content, or `nil` when it doesn't have content (embed only).
function message:getContent() return self.content end

--- Get the message embeds if there are any.
-- @treturn ?{discord.embed,...} An array for embed objects.
function message:getEmbeds()
    if self.embeds then
        local embeds = {}
        for k,v in pairs(self.embeds) do embeds[k] = v end
        return embeds
    end
end

--- Get the guild ID of the channel the message is sent in, would return nil for DM channels
-- @treturn ?discord.snowflake The guild ID/snowflake for the channel the message was sent in, `nil` if it was sent in a DM channel.
function message:getGuildID() return self.guildID end

--- Get the ID/snowflake of the message
-- @treturn discord.snowflake The ID/snowflake of the message.
function message:getID() return self.id end

--- Get the guild member of the message if the message was sent in a guild.
-- @treturn ?discord.guild_member The guild member object. `nil` if it was not known, or in a DM channel.
function message:getMember() return self.member end

--- Get the list of specifically mentioned user.
-- @treturn {discord.user,...} The mentioned users array, can be an empty table if we don't know which users are mentioned.
function message:getMentions()
    if not self.mentions then return {} end --Can't know
    local mentions = {}
    for k,v in pairs(self.mentions) do
        mentions[k] = v
    end
    return mentions
end

--- Get a fake channel object for ONLY replying to the message.
--
-- Only the channel ID has a proper value, and the channel type is just set into `GUILD_TEXT` for messages with guild ID
-- , and into `DM` for other messages.
--
-- Other channel fields are just nil.
-- @treturn discord.channel A fake channel object to send a reply message using it.
function message:getReplyChannel()
    return discord.channel{
        id = tostring(self.channelID),
        type = discord.enums.channelTypes[self.guildID and "GUILD_TEXT" or "DM"]
    }
end

--- Get the timestamp of the message.
-- @treturn number A `os.time()` timestamp as provided by discord.
function message:getTimestamp() return self.timestamp end

--- Returns the type of the message.
-- @treturn string The type of the message.
-- @see discord.enums.messageTypes
function message:getType() return self.type end

return message