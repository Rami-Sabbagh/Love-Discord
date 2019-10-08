local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local channel = class("discord.structures.Channel")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
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

--== Methods ==--

--New channel object
function channel:initialize(data)
    Verify(data, "data", "table", "string")
    if type(data) == "string" then
        data = Request("/channels/"..data)
    end

    --== Basic Fields ==--

    self.id = discord.snowflake(data.id) --The id of this channel (snowflake)
    self.type = discord.enums.channelTypes[data.type] --The type of this channel (string)

    --== Optional Fields ==--

    --The id of the parent guild (snowflake)
    if data.guild_id then self.guildID = discord.snowflake(data.guild_id) end
    self.position = data.position --Sorting position of the channel (number)
    self.permissionOverwrites = data.permission_overwrites --TODO: Permissions overwrites object
    self.name = data.name --The name of the channel (2-100 characters) (string)
    self.topic = data.topic --The channel topic (0-1024 characters) (string)
    self.nsfw = data.nsfw --Whether the channel is nsfw (boolean)
    --the id of the last message sent in this channel (may not point to an existing or valid message) (snowflake)
    if data.last_message_id then self.lastMessageID = discord.snowflake(data.last_message_id) end
    self.bitrate = data.bitrate --The bitrate (in bits) of the voice channel (number)
    self.userLimit = data.user_limit --The user limit of the voice channel (number)
    self.rateLimitPerUser = data.rate_limit_per_user --Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission manage_messages or manage_channel, are unaffected (number)
    --The recipients of the DM (array of user objects)
    if data.recipients then
        self.recipients = {}
        for id, udata in pairs(data.recipients) do
            self.recipients[id] = discord.user(udata) --New user object
        end
    end
    self.icon = data.icon --TODO: IMAGE OBJECTS
    --The id of the DM creator (snowflake)
    if data.owner_id then self.ownerID = discord.snowflake(data.owner_id) end
    --Application id of the group DM creator if it is bot-created (snowflake)
    if data.application_id then self.applicationID = discord.snowflake(data.application_id) end
    --ID of the parent category for a channel (snowflake)
    if data.parent_id then self.parentID = discord.snowflake(data.parent_id) end
    self.lastPinTimestamp = data.last_pin_timestamp --When the last pinned message was pinned (number)
end

--Tells if this is a text channel
local textChannelTypes = {"GUILD_TEXT", "DM", "GROUP_DM"}
function channel:isText()
    for k, v in pairs(textChannelTypes) do
        if self.type == v then return true end
    end
    return false
end

--Tells if this is a DM channel
function channel:isDM() return self.type == "DM" end

--Tells if this is a DM group channel
function channel:isGroupDM() return self.type == "GROUP_DM" end

--Tells the type of the channel
function channel:getType() return self.type end

local function patchEmbed(t)
    for k,v in pairs(t) do
        if type(v) == "table" then
            patchEmbed(v)
        elseif type(v) == "string" and (k == "name" or k == "value" or k == "text" or k == "title" or k == "description") then
            t[k] = discord.utilities.message.patchEmojis(v)
        end
    end
end

--Send a message into the channel
--File is array of [filename, filedata]
function channel:send(content, embed, file, tts)
    if not self:isText() then return error("Can't send messages on non-text channels!") end
    Verify(embed, "embed", "table", "nil")
    Verify(file, "file", "table", "nil")

    --The message request body
    local data = {
        content = content and tostring(content) or nil,
        nonce = discord.utilities.snowflake.new(),
        tts = not not tts
    }

    --Convert standard emojis tags into 
    if data.content then data.content = discord.utilities.message.patchEmojis(data.content) end

    --Inject the embed data
    if embed then data.embed = embed:getAll(); patchEmbed(data.embed) end

    if not (data.content or data.embed or file) then return error("A message should have at least content or an embed or a file") end
    if data.content and #data.content > 2000 then error("Messages content can't be longer than 2000 characters!") end

    if file then
        Verify(file[1], "file[1] (filename)", "string")
        Verify(file[2], "file[2] (filedata)", "string")

        if #file[2] > 7*1024 then return error("Can't upload files bigger than 7MB !") end

        data = {
            payload_json = data,
            file = file
        }
    end

    local endpoint = string.format("/channels/%s/messages", tostring(self.id))

    local mdata = Request(endpoint, data, "POST", {}, not not file)
    return discord.message(mdata)
end

function channel:triggerTypingIndicator()
    local endpoint = string.format("/channels/%s/typing", tostring(self.id))
    Request(endpoint, false, "POST")
end

--== Operators Overrides ==--

--Format the channel into it's message tag
function channel:__tostring()
    return discord.utilities.message.formatChannel(tostring(self.id))
end

return channel