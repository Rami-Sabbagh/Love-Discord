--LIKO-12 Discord Library

local libpath = ...
local libdir = libpath:gsub("%.","/").."/"

local discord = {}

discord.requireLib = function(name)
  return assert(love.filesystem.load(libdir..name..".lua"))(discord)
end

--ThirdParty-Libraries
discord.json = require(libpath..".JSON")

--Constants
discord.apiEndpoint = "https://discordapp.com/api/v6/"
discord.httpcodes = discord.requireLib("httpcodes")

--The library path
discord.path = libpath

--JSON HTTP Request
discord.request = discord.requireLib("request")
discord.tools = discord.requireLib("tools")

--The configuration
discord.config = discord.requireLib("config")

--Bot authorization
if discord.config.bot_token then
  discord.authorization = "Bot "..discord.config.bot_token
end

--The modules
discord.oauth = discord.requireLib("oauth")
discord.gateway = discord.requireLib("gateway")
discord.users = discord.requireLib("users")
discord.channels = discord.requireLib("channels")

return discord