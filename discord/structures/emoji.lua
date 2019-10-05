local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local emoji = class("discord.structures.Emoji")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function emoji:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    self.name = data.name --Emoji name (string)

    --== Optional Fields ==--

    --Emoji ID (snowflake)
    if data.id then self.id = discord.snowflake(data.id) end
    --Roles this emoji is whitelisted to (array of role objects)
    if data.roles then
        self.roles = {}
        for id, snowflake in pairs(data.roles) do
            self.roles[id] = discord.snowflake(snowflake)
        end
    end
    --User that created this emoji (user)
    if data.user then self.user = discord.user(data.user) end
    self.requireColons = data.require_colons --Whether this emoji must be wrapped in colons (boolean)
    self.managed = data.managed --Whether this emoji is managed (boolean)
    self.animated = data.animated --Whether this emoji is animated (boolean)
end

return emoji