--Discörd - A Discord bot library by RamiLego4Game (Rami Sabbagh)

local libraryPath = ...
local class = require(libraryPath..".third-party.middleclass")

local discord = class("discord.Discord")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New instance
function discord:initialize(tokenType, token)
    Verify(tokenType, "tokenType", "string")
    Verify(token, "token", "string")

    if tokenType ~= "Bot" and tokenType ~= "Bearer" then
        return error("Unknown token type: "..tokenType)
    end

    --Internal Fields
    self._path = libraryPath --The require path into the Discörd library.
    self._directory = self._path:gsub("%.","/").."/" --The filesystem path to the Discörd library.
    self._userAgent = "DiscordBot (https://github.com/RamiLego4Game/Love-Discord, 2)"

    --Load third-party libraries
    self.websocket = self:_require("third-party.lua-websockets")
    self.json = self:_require("third-party.JSON")
    self.multipart = self:_require("third-party.multipart") --https://github.com/Kong/lua-multipart
    self.class = class
    self.https = self:_require("third-party.https")

    self.https.USERAGENT = self._userAgent --Set the useragent

    --Load utilities
    self.utilities = {}
    self.utilities.bit = self:_dofile("utilities/bit", self)
    self.utilities.http = self:_dofile("utilities/http", self)
    self.utilities.snowflake = self:_dofile("utilities/snowflake", self)
    self.utilities.message = self:_dofile("utilities/message", self)

    --Load modules
    self.enums = self:_dofile("modules/enums")
    self.rest = self:_dofile("modules/rest", self)
    self.gateway = self:_dofile("modules/gateway", self)

    --Load structures
    self.attachment = self:_dofile("structures/attachment", self)
    self.channelMention = self:_dofile("structures/channel_mention", self)
    self.channel = self:_dofile("structures/channel", self)
    self.embed = self:_dofile("structures/embed", self)
    self.emoji = self:_dofile("structures/emoji", self)
    self.guildMember = self:_dofile("structures/guild_member", self)
    self.guild = self:_dofile("structures/guild", self)
    self.message = self:_dofile("structures/message", self)
    self.snowflake = self:_dofile("structures/snowflake", self)
    self.permissions = self:_dofile("structures/permissions", self)
    self.reaction = self:_dofile("structures/reaction", self)
    self.user = self:_dofile("structures/user", self)

    --Authorize the REST API
    self.rest:authorize(tokenType, token)
end

--Requires a sub-module in the Discörd library.
function discord:_require(path)
    local ok, err = pcall(require, path and self._path.."."..path)
    if ok then return err end
    return error(err)
end

--Executes a file in the Discörd library.
function discord:_dofile(path, ...)
    local chunk, cerr = love.filesystem.load(self._directory..path..".lua") --TODO: Don't depend on LÖVE

    if not chunk then return error(cerr) end
    local rets = {pcall(chunk, ...)}
    if not rets[1] then return error(rets[2]) end

    return select(2,unpack(rets))
end

return discord