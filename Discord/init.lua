--LIKO-12 Discord Library

local libpath = ...

local discord = {}

--ThirdParty-Libraries
discord.json = require(libpath..".JSON")

--Constants
discord.apiEndpoint = "https://discordapp.com/api/v6/"
discord.httpcodes = require(libpath..".httpcodes", discord)

--The library path
discord.path = libpath

--JSON HTTP Request
discord.request = require(libpath..".request", discord)
discord.tools = require(libpath..".tools", discord)

--The configuration
discord.config = require(libpath..".config", discord)

--Bot authorization
if discord.config.bot_token then
  discord.authorization = "Bot "..discord.config.bot_token
end

--The modules
discord.oauth = require(libpath..".oauth", discord)
discord.gateway = require(libpath..".gateway", discord)
discord.users = require(libpath..".users", discord)
discord.channels = require(libpath..".channels", discord)

return discord