--- Channel mention class
-- @classmod discord.channelMention

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local channelMention = class("discord.structures.ChannelMention")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function channelMention:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    self.id = discord.snowflake(data.id) --ID of the channel (snowflake)
    self.guildID = discord.snowflake(data.guild_id) --ID of the guild containing the channel (snowflake)
    self.type = discord.enums.channelTypes[data.type] --The type of channel (string)
    self.name = data.name --The name of the channel (string)
end

return channelMention