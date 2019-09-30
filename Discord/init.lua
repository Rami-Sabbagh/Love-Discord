--LIKO-12 Discord Library

local libpath = ...
local libdir = libpath:gsub("%.","/").."/"

local discord = {}

discord.dofile = function(name)
  return assert(love.filesystem.load(libdir..name..".lua"))(discord)
end

discord.require = function(name)
  return require(libpath.."."..name)
end

--ThirdParty-Libraries
discord.json = require(libpath..".JSON")

--Constants
discord.apiEndpoint = "https://discordapp.com/api/v6/"
discord.httpcodes = discord.dofile("httpcodes")

--The library path
discord.path = libpath

--JSON HTTP Request
discord.request = discord.dofile("request")
discord.tools = discord.dofile("tools")

--The configuration
discord.config = discord.dofile("config")

--Bot authorization
if discord.config.bot_token then
  discord.authorization = "Bot "..discord.config.bot_token
end

--The modules
discord.oauth = discord.dofile("oauth")
discord.gateway = discord.dofile("gateway")
discord.users = discord.dofile("users")
discord.channels = discord.dofile("channels")

return discord