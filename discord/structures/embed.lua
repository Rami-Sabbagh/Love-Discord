local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local embed = class("discord.structures.Embed")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function embed:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    
    
    --== Optional Fields ==--

    self.title = data.title --Title of embed (string)
    self.type = data.type --Type of embed (string)
    self.description = data.description --Description of embed (string)
    self.url = data.url --URL of embed (string)
    self.timestamp = data.timestamp --Timestamp of embed content (number)
    self.color = data.color --Color code of the embed (number) --TODO: COLOR OBJECT
    --TODO: ADD THE REST OF FIELDS
end

return embed