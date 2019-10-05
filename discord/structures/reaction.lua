local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local reaction = class("discord.structures.Reaction")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function reaction:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    self.count = data.count --Times this emoji has been used to react (number)
    self.me = data.me --Whether the curret user reacted using this emoji (boolean)
    self.emoji = discord.emoji(data.emoji) --Emoji information (emoji)
end

return reaction