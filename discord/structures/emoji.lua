--- The discord emoji class.
-- It can be obtained either from a discord event, from some discörd objects, by constructing one for a standard emoji
-- or by fetching the custom emoji by it's id and guild id from discord servers.
-- @usage local standardEmoji = discord.emoji("smiley") --The constructed standard emoji.
-- @usage local customEmoji = discord.emoji("guild_id", "emoji_id") --The requested custom emoji.
-- @classmod discord.emoji

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local emoji = class("discord.structures.Emoji")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not value) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--TODO: Add weak tables caching of custom emojis

--- Create a new emoji object.
-- @tparam string|table data Either the emoji name string for a standard emoji, the standard emoji unicode string,
-- the guild ID string for a custom emoji or an emoji data table (from an internal api).
-- @tparam ?string emojiID The emoji ID string for a custom emoji.
-- @raise Request error when fails to request the custom emoji from discord servers.
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

    --- Internal fields.
    -- @section internal_fields

    --- Emoji name (string).
    self.name = data.name

    --== Optional Fields ==--

    --- Internal optional fields.
    -- @section internal_optional_fields

    --- Emoji ID (snowflake).
    -- @field self.id
    if data.id then self.id = discord.snowflake(data.id) end
    --- Roles this emoji is whitelisted to (array of role objects).
    -- @field self.roles
    if data.roles then
        self.roles = {}
        for id, snowflake in pairs(data.roles) do
            self.roles[id] = discord.snowflake(snowflake)
        end
    end
    --- User that created this emoji (user).
    -- @field self.user
    if data.user then self.user = discord.user(data.user) end

    --- Whether this emoji must be wrapped in colons (boolean).
    self.requireColons = data.require_colons
    --- Whether this emoji is managed (boolean).
    self.managed = data.managed
    --- Whether this emoji is animated (boolean).
    self.animated = data.animated

    ---
    -- @section end

    --== Fix standard (unicode) emojis ==--
    if not self.id then
        if discord.utilities.message.emojisReversed[self.name] then
            self.name = discord.utilities.message.emojisReversed[self.name]
        end
    end
end

--== Methods ==--

--- Get the emoji ID.
-- @treturn ?discord.snowflake The emoji's ID, `nil` when not known.
function emoji:getID() return self.id end

--- Get the emoji name.
-- @treturn string The emoji's name.
function emoji:getName() return self.name end

--== Operators Overrides ==--

--- Operators Overrides.
-- @section operators_overrides

--- Format the emoji into it's message tag.
-- Handles standard emojis custom emojis, and custom animated emojis properly.
-- @treturn string The emoji's message tag, ex: `<:emoji_name:emoji_id>`.
-- @usage local emoji_tag = tostring(my_emoji)
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