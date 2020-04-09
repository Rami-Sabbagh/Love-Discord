--Discörd - A Discord bot library by RamiLego4Game (Rami Sabbagh)

local libraryPath = ...
local class = require(libraryPath..".third-party.middleclass")

local discord = class("discord.Discord")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not value) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New instance
function discord:initialize(tokenType, token, connectInstantly, gatewayOptions)
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
    self.gatewayClass = self:_dofile("modules/gateway", self)

    --Load structures
    self.attachment = self:_dofile("structures/attachment", self)
    self.channelMention = self:_dofile("structures/channel_mention", self)
    self.channel = self:_dofile("structures/channel", self)
    self.embed = self:_dofile("structures/embed", self)
    self.emoji = self:_dofile("structures/emoji", self)
    self.guildMember = self:_dofile("structures/guild_member", self)
    self.guild = self:_dofile("structures/guild", self)
    self.message = self:_dofile("structures/message", self)
    self.permissions = self:_dofile("structures/permissions", self)
    self.reaction = self:_dofile("structures/reaction", self)
    self.role = self:_dofile("structures/role", self)
    self.snowflake = self:_dofile("structures/snowflake", self)
    self.user = self:_dofile("structures/user", self)

    --Registered events functions
    self.events = {}

    --Authorize the REST API
    self.rest:authorize(tokenType, token)
    --Initialize the gateway
    self.gateway = self.gatewayClass(gatewayOptions)
    --Hook into the gateway events system
    self.gateway:hookEvent("ANY", function(op, d, s, t)
        if op == 0 then
            if self["_"..t] then self["_"..t](self, op, d, s, t) end
        end
    end)
    --Connect instantly if allowed to
    if connectInstantly then
        self.gateway:connect()
    end
end

--Update the gateway and process gateway events
function discord:update(dt)
    if self.gateway:isConnected() then
        return self.gateway:update(dt)
    end
end

--Hook a function into an event
function discord:hookEvent(name, func)
    if self.events[name] then
        self.events[name][#self.events[name] + 1] = func
    else
        self.events[name] = {func}
    end
end

--Tells if the gateway is connected or not
function discord:isConnected()
    return self.gateway:isConnected()
end

--Connects the gateway if not already connected
function discord:connect()
    if self.gateway:isConnected() then return error("Already connected!") end
    self.gateway:connect()
end

--Disconnects from the gateway if connected
function discord:disconnect()
    if not self.gateway:isConnected() then return error("Not connected!") end
    self.gateway:disconnect()
end

--== Internal Gateway Events ==--

--TODO: Add all the events

function discord:_READY(op, d, s, t)
    local privateChannels = {}
    for k,v in pairs(d.private_channels) do
        privateChannels[k] = self.channel(v)
    end

    local guilds = {}
    for k,v in pairs(d.guilds) do
        guilds[k] = self.guild(v)
    end

    self:_triggerEvent("READY", {
        user = self.user(d.user),
        privateChannels = privateChannels,
        guilds = guilds
    })
end

function discord:_CHANNEL_CREATE(op, d, s, t)
    self:_triggerEvent("CHANNEL_CREATE", self.channel(d))
end

function discord:_CHANNEL_UPDATE(op, d, s, t)
    self:_triggerEvent("CHANNEL_UPDATE", self.channel(d))
end

function discord:_CHANNEL_DELETE(op, d, s, t)
    self:_triggerEvent("CHANNEL_DELETE", self.channel(d))
end

function discord:_GUILD_CREATE(op, d, s, t)
    self:_triggerEvent("GUILD_CREATE", self.guild(d))
end

function discord:_GUILD_UPDATE(op, d, s, t)
    self:_triggerEvent("GUILD_UPDATE", self.guild(d))
end

function discord:_GUILD_DELETE(op, d, s, t)
    self:_triggerEvent("GUILD_DELETE", self.guild(d))
end

function discord:_GUILD_MEMBER_ADD(op, d, s, t)
    self:_triggerEvent("GUILD_MEMBER_ADD", self.guildMember(d))
end

function discord:_GUILD_ROLE_CREATE(op, d, s, t)
    self:_triggerEvent("GUILD_ROLE_CREATE", self.snowflake(d.guild_id), self.role(d.role))
end

function discord:_GUILD_ROLE_UPDATE(op, d, s, t)
    self:_triggerEvent("GUILD_ROLE_UPDATE", self.snowflake(d.guild_id), self.role(d.role))
end

function discord:_GUILD_ROLE_DELETE(op, d, s, t)
    self:_triggerEvent("GUILD_ROLE_DELETE", self.snowflake(d.guild_id), self.snowflake(d.role_id))
end

function discord:_MESSAGE_CREATE(op, d, s, t)
    self:_triggerEvent("MESSAGE_CREATE", self.message(d))
end

function discord:_MESSAGE_UPDATE(op, d, s, t)
    self:_triggerEvent("MESSAGE_UPDATE", self.message(d))
end

function discord:_MESSAGE_REACTION_ADD(op, d, s, t)
    self:_triggerEvent("MESSAGE_REACTION_ADD", {
        userID = self.snowflake(d.user_id),
        channelID = self.snowflake(d.channel_id),
        messageID = self.snowflake(d.message_id),
        guildID = d.guild_id and self.snowflake(d.guild_id),
        emoji = self.emoji(d.emoji)
    })
end

--== Internal Methods ==--

--Triggers an event functions
function discord:_triggerEvent(name, ...)
    if self.events[name] then
        for _, func in ipairs(self.events[name]) do
            func(...)
        end
    end

    if self.events["ANY"] then
        for _, func in ipairs(self.events["ANY"]) do
            func(name, ...)
        end
    end
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