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
function emoji:initialize(data, emojiID)
    if type(data) == "string" then
        --Fetch custom emoji
        if emojiID then
            Verify(emojiID, "emojiID", "string")
            local edata, reason = discord.rest:request("/guilds/"..data.."/emojis/"..emojiID)
            if not edata then return error("Failed to fetch emoji: "..tostring(reason)) end
            data = edata

        else --Standard emoji
            if not discord.utilities.message.emojis[data] then
                return error("Unknown emoji: "..data)
            end

            data = {
                name = data
            }
        end
    end

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

    --== Fix standard (unicode) emojis ==--
    if not self.id then
        if discord.utilities.message.emojisReversed[self.name] then
            self.name = discord.utilities.message.emojisReversed[self.name]
        end
    end
end

--== Methods ==--

--Returns emoji ID (snowflake/nil)
function emoji:getID() return self.id end

--Returns emoji name (string)
function emoji:getName() return self.name end

--== Operators Overrides ==--

--Fromat the emoji into it's message tag
function emoji:__tostring()
    if not self.id then
        return discord.utilities.message.emojis[self.name]
    end

    if self.animated then
        return discord.utilities.message.formatCustomAnimatedEmoji(self.name,self.id)
    else
        return discord.utilities.message.formatCustomEmoji(self.name,self.id)
    end
end

return emoji