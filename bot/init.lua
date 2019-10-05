--Basic Bot System

--Load Discörd Library
local discord = require("discord")

--Load Configuration
local config = require("config")

--BOT API
local botAPI = {}

--Initialize the bot and connect into Discord
function botAPI:initialize()
    self.bot = discord("Bot", config.bot_token, true, {
        payloadCompression = true, --Enable payload compression
        transportCompression = false, --Not implemented
        encoding = "json", --Only json is implemented for now
        autoReconnect = true,
        largeTreshold = 50,
        guildSubscriptions = false --We don't want presence updates
    })


end

--Update the bot
function botAPI:update(dt)
    self.bot:update(dt)
end

--Pass the BOT API
return botAPI