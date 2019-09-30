--Discörd - A Discord bot library by RamiLego4Game (Rami Sabbagh)

local class = discord._require("third-party.middleclass")

local discord = class("discord.Discord")

--New instance
function discord:initialize()
    --Internal Fields
    self._path = ... --The require path into the Discörd library.
    self._directory = self._directory:gsub("%.","/").."/" --The filesystem path to the Discörd library.
    self._userAgent = "DiscordBot (https://github.com/RamiLego4Game/Love-Discord, 2)"

    --Load third-party libraries
    self.websocket = self:_require("third-party.lua-websockets")
    self.json = self:_require("third-party.JSON")
    self.multipart = self:_require("third-party.multipart") --https://github.com/Kong/lua-multipart
    self.class = class
    self.https = self:_require("third-party.https")

    self.https.USERAGENT = self._userAgent --Set the useragent

    --Load utilities
    self.utilites = {}
    self.utilites.bit = self:_dofile("utilities/bit", self)
    self.utilites.http = self:_dofile("utilities/http", self)
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