--Discörd - A Discord bot library by RamiLego4Game (Rami Sabbagh)

local discord = {}

--Internal Fields
discord._path = ... --The require path into the Discörd library.
discord._directory = discord._directory:gsub("%.","/").."/" --The filesystem path to the Discörd library.

--Requires a sub-module in the Discörd library.
discord._require = function(path)
    local ok, err = pcall(require, path and discord._path.."."..path)
    if ok then return err end
    return error(err)
end

--Executes a file in the Discörd library.
discord._dofile = function(path, ...)
    local chunk, cerr = love.filesystem.load(discord._directory..path..".lua") --TODO: Don't depend on LÖVE

    if not chunk then return error(cerr) end
    local rets = {pcall(chunk, ...)}
    if not rets[1] then return error(rets[2]) end

    return select(2,unpack(rets))
end

--== Third-Party Libraries ==--

discord.websocket = discord._require("third-party.lua-websockets")
discord.json = discord._require("third-party.JSON")
discord.class = discord._require("third-party.middleclass")

return discord