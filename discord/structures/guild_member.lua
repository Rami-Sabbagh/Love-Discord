local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local guildMember = class("discord.structures.GuildMember")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function guildMember:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    self.user = discord.user(data.user) --The user this guild member represents (user)
    self.roles = {} --Array of roles snowflakes (array of snowflakes)
    for id, snowflake in pairs(data.roles) do
        self.roles[id] = discord.snowflake(snowflake)
    end
    self.joinedAt = data.joined_at --When the user joined the guild (number)
    self.deaf = data.deaf --Whether the user is deafened in voice channels (boolean)
    self.mute = data.mute --Whether the user is muted in voice channels (boolean)

    --== Optional Fields ==--

    self.nick = data.nick --This users guild nickname (if one is set)
    self.premiumSince = data.premium_since --When the user used their Nitro boost on the server (number)
end

return guildMember