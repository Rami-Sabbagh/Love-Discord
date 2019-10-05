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

--== Methods ==--

--New channel object
function channel:initialize(data)
    Verify(data, "data", "table", "string")
    if type(data) == "string" then
        local cdata = discord.rest:request("/channels/"..data)
        if not cdata then return error("Failed to fetch channel data") end --TODO: Proper REST error handling
        data = cdata
    end

    --== Basic Fields ==--

    self.id = discord.snowflake(data.id) --The id of this channel (snowflake)
    self.type = discord.enums.channeType[data.type] --The type of this channel (string)

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

--== Operators Overrides ==--

--Format the channel into it's message tag
function channel:__tostring()
    return discord.utilities.message.formatChannel(tostring(self.id))
end

return channel