local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local guild = class("discord.structures.Guild")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild object
--data (table): The data table recieved from discord.
--data (id): The id of the guild (the snowflake in string format), the guild data would be fetching using the REST API
function guild:initialize(data)
    Verify(data, "data", "table", "string")
    if type(data) == "string" then
        local gdata = discord.rest:request("/guilds/"..data)
        if not gdata then return error("Failed to fetch guild data") end --TODO: Proper REST error handling
        data = gdata
    end
    
    --== Unavailbale Guild Fields ==--
    self.id = discord.snowflake(data.id) --The guild ID (snowflake)
    self.unavailable = data.unavailable or false --Is the guild available (boolean)
    if self.unavailable then return end --No more data to process

    --== Available Guild Fields ==--
    self.name = data.name --The guild name (string)
    self.ownerID = discord.snowflake(data.owner_id) --The guild owner ID (snowflake)
    self.region = region --TODO: Voice Region structure object
    self.afkTimeout = data.afk_timeout --Afk timeout in seconds (number)
    self.verificationLevel = discord.enums.verificationLevels[data.verification_level] --Verification level required for the guild (string)
    self.defaultMessageNotifications = discord.enums.messageNotificationsLevels[data.default_message_notifications] --Default message notifications level (string)
    self.explicitContentFilter = discord.enums.explicitContentFilterLevels[data.explicit_content_filter] --Explicit content filter level (string)
    self.roles = {} --Array of role objects
    for id, role in pairs(data.roles) do self.roles[id] = discord.role(role) end
    self.emojis = {} --Array of emoji objects
    for id, emoji in pairs(data.emojis) do self.emojis[id] = discord.emoji(emoji) end
    self.features = data.features --Enabled guild features (array of strings)
    self.mfaLevel = discord.enums.mfaLevels[data.mfa_level] --Required MFA level for the guild (string)


    --== Optional Fields ==--
    self.icon = data.icon --The guild icon (string - icon hash) --TODO: image url object
    self.splash = data.splash --The guild splash (string - splash hash) --TODO: image url object
    self.owner = data.owner --Whether or not the user is the owner of the guild (boolean/nil), depends on the source of the guild object
    --Total permissions for the user in the guild (does not include channel overrides) (permissions object)
    if data.permissions then self.permissions = discord.permissions(data.permissions) end
    --Id of afk channel (snowflake)
    if data.afk_channel_id then self.afkChannelID = discord.snowflake(data.after_channel_id) end
    self.embedEnabled = data.embed_enabled --Whether this guild is embeddable (e.g. widget) (boolean)
    if data.embed_channel_id then self.embedChannelID = discord.snowflake(data.embed_channel_id) end --The channel id that the widget will generate an invite to (snowflake)
    --Application id of the guild creator if it is bot-created (snowflake)
    if data.application_id then self.applicationID = discord.snowflake(application_id) end
    self.widgetEnabled = data.widget_enabled --Whether or not the server widget is enabled (boolean)
    --The channel id for the server widget (snowflake)
    if data.widget_channel_id then self.widgetChannelID = discord.snowflake(data.widget_channel_id) end
    --The id of the channel to which system messages are sent (snowflake)
    if data.system_channel_id then self.systemChannelID = discord.snowflake(data.system_channel_id) end
    self.joinedAt = data.joined_at --When this guild was joined at (number)
    self.large = data.large --Whether this is considered a large guild (boolean)
    self.memberCount = data.member_count --Total number of members in this guild (number)
    --TODO: voice_states field
    if data.members then --Users in the guild (array of guild members)
        self.members = {}
        for id, member in pairs(data.members) do self.members[id] = discord.guildMember(member) end
    end
    if data.channels then --Guild channels (array of channels)
        self.channels = {}
        for id, channel in pairs(data.channels) do self.channels[id] = discord.channel(channel) end
    end
    --TODO: Presences field

    --TODO: Add the fields after the presences one https://discordapp.com/developers/docs/resources/guild

end

--== Methods ==--

--Returns the guild ID (snowflake)
function guild:getID() return self.id end

--Returns the guild name if known (string/nil)
function guild:getName() return self.name end

--Returns the guild roles (array of roles, or nil)
function guild:getRoles()
    if self.roles then
        local roles = {}
        for k,v in pairs(self.roles) do roles[k] = v end
        return roles
    end
end

--== Operator Overrides ==--

--Returns the guild name, or id if the name is unknown
function guild:__tostring()
    return self.name or tostring(self.id)
end

return guild