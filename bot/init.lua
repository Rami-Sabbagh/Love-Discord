--Discörd Böt - A Basic Bot System

--Load Discörd Library
local discord = require("discord")
--Load JSON library from the Discörd library
local json = require("discord.third-party.JSON")

--Load bot sub-systems
local pluginsManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")

--BOT API
local botAPI = {}

--Initialize the bot and connect into Discord
function botAPI:initialize()
    print("Loading configuration...")

    if not love.filesystem.getInfo("/bot/config.json") then error("Please create the bot configuration file at /bot/config.json, based on the file in /bot/config_template.json") end
    self.config = json:decode(love.filesystem.read("/bot/config.json"))

    print("Initializing...")

    self.discord = discord("Bot", self.config.bot.token, false, {
        payloadCompression = true, --Enable payload compression
        transportCompression = false, --Not implemented
        encoding = "json", --Only json is implemented for now
        autoReconnect = true,
        largeTreshold = 50,
        guildSubscriptions = false --We don't want presence updates
    })

    --Hook to get the bot user object
    self.discord:hookEvent("READY", function(data)
        self.me = data.user
        print("BOT ID",tostring(self.me:getID()))
    end)

    pluginsManager:initialize()
    commandsManager:initialize()

    print("Connecting...")
    self.discord:connect()
    print("Connected :)")
end

--Update the bot
function botAPI:update(dt)
    self.discord:update(dt)
end

--Pass the BOT API
return botAPI