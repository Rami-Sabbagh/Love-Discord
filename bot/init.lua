--Basic Bot System

--Load Discörd Library
local discord = require("discord")

--Load Configuration
local config = require("config")

--Load bot sub-systems
local pluginsManager = require("bot.plugins_manager")

--BOT API
local botAPI = {}

--Initialize the bot and connect into Discord
function botAPI:initialize()
    self.discord = discord("Bot", config.bot_token, false, {
        payloadCompression = true, --Enable payload compression
        transportCompression = false, --Not implemented
        encoding = "json", --Only json is implemented for now
        autoReconnect = true,
        largeTreshold = 50,
        guildSubscriptions = false --We don't want presence updates
    })

    pluginsManager:initialize()

    print("Connecting...")
    self.discord:connect()
end

--Update the bot
function botAPI:update(dt)
    self.discord:update(dt)
end

--Pass the BOT API
return botAPI