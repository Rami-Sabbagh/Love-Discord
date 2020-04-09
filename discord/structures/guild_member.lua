--- Guild member class
-- @classmod discord.guildMember

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local guildMember = class("discord.structures.GuildMember")

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

--New guild member object
function guildMember:initialize(data, userID)
    Verify(data, "data", "table", "string")

    if type(data) == "string" then
        Verify(userID, "userID", "string")

        local endpoint = string.format("/guilds/%s/members/%s", data, userID)
        data = Request(endpoint)
    end

    --== Basic Fields ==--

    self.roles = {} --Array of roles snowflakes (array of snowflakes)
    for id, snowflake in pairs(data.roles) do
        self.roles[id] = discord.snowflake(snowflake)
    end
    self.joinedAt = data.joined_at --When the user joined the guild (number)
    self.deaf = data.deaf --Whether the user is deafened in voice channels (boolean)
    self.mute = data.mute --Whether the user is muted in voice channels (boolean)

    --== Optional Fields ==--

    --The user this guild member represents (user)
    if data.user then self.user = discord.user(data.user) end
    self.nick = data.nick --This users guild nickname (if one is set)
    self.premiumSince = data.premium_since --When the user used their Nitro boost on the server (number)
end

--== Methods ==--

--Returns the user's nickname if set on this guild
function guildMember:getNick() return self.nick end

--Returns the timestamp which the user has been booting the server since (if he's boosting)
function guildMember:getPremiumSince() return self.premiumSince end

--Returns a list of roles snowflakes the member has
function guildMember:getRoles()
    local roles = {}
    for k,v in pairs(self.roles) do roles[k] = v end
    return roles
end

--Returns the user object if received
function guildMember:getUser() return self.user end

--Returns a timestamp of when the user joined the guild
function guildMember:getJoinedAt() return self.joinedAt end

--Tells if the user is deafened in voice channels
function guildMember:isDeafened() return self.deaf end

--Tells if the user is muted in voice channels
function guildMember:isMuted() return self.mute end

return guildMember