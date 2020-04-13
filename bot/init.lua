--- Discörd Böt, A basic bot system.
-- @module bot
-- @alias botAPI
local botAPI = {}

--Set the custom error handler
require("bot.error_handler")
--Load Discörd Library
local discord = require("discord")
--Load JSON library from the Discörd library
local json = require("discord.third-party.JSON")

--Load bot sub-systems
local rolesManager = require("bot.roles_manager")
local pluginsManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")
local dataStorage = require("bot.data_storage")

--- Initialize the bot and connect into Discord.
-- @tparam table args The command line arguments passed to the bot, can be an empty table.
-- @raise Errors when it fails to load the bot's configuration file.
function botAPI:initialize(args)
    --- The command line arguments passed to the bot.
    self.args = args

    print("Loading configuration...")

    if not love.filesystem.getInfo("/bot/config.json") then error("Please create the bot configuration file at /bot/config.json, based on the file in /bot/config_template.json") end
    --- The bot's configuration file decoded, from `bot/config.json`.
    self.config = json:decode(love.filesystem.read("/bot/config.json"))

    print("Initializing...")

    --- The discörd library instance for the bot.
    self.discord = discord("Bot", self.config.bot.token, false, {
        payloadCompression = true, --Enable payload compression
        transportCompression = false, --Not implemented
        encoding = "json", --Only json is implemented for now
        autoReconnect = true,
        largeTreshold = 50,
        guildSubscriptions = false, --We don't want presence updates

        presence = {
            game = {
                name = "you 👀",
                type = 3 --Watching
            },
            status = "online",
            afk = false
        }
    })

    --Events
    self.discord:hookEvent("READY", self._READY)
    self.discord:hookEvent("GUILD_CREATE", self._GUILD_CREATE)

    rolesManager:initialize()
    pluginsManager:initialize()
    commandsManager:initialize()

    local gdata = dataStorage["bot/gateway"]

    if gdata.url and gdata.info then
        print("Using cached gateway url ;)")
        self.discord.gateway.gatewayURL = gdata.url
        self.discord.gateway.gatewayInfo = gdata.info
    end

    print("Connecting...")
    self.discord:connect()
    print("Connected :)")
end

--- Check if a provided snowflake is for a bot owner user.
-- @tparam string id The snowflake as a string.
-- @treturn boolean `true` if it's an owner snowflake, `false` otherwise.
function botAPI:isOwner(id)
    for k, ownerid in pairs(self.config.bot.owners) do
        if ownerid == id then return true end
    end
    return false
end

--- Check if a message is from a bot owner.
-- @tparam discord.message message The message to check it's owner.
-- @treturn boolean `true` if it's a message from a bot owner, `false` otherwise.
function botAPI:isFromOwner(message)
    local authorID = tostring(message:getAuthor():getID())
    return self:isOwner(authorID)
end

--- Check if a provided snowflake is for a bot developer user.
-- @tparam string id The snowflake as a string.
-- @treturn boolean `true` if it's a developer snowflake, `false` otherwise.
function botAPI:isDeveloper(id)
    for k, devid in pairs(self.config.bot.developers) do
        if devid == id then return true end
    end
    return false
end

--- Check if a message is from a bot developer.
-- @tparam discord.message message The message to check it's owner.
-- @treturn boolean `true` if it's a message from a bot developer, `false` otherwise.
function botAPI:isFromDeveloper(message)
    local authorID = tostring(message:getAuthor():getID())
    return self:isDeveloper(authorID)
end

--- Update the bot.
-- @tparam number dt The time between the last update call and this call in seconds.
function botAPI:update(dt)
    dataStorage(dt)
    if self.discord:update(dt) then
        pluginsManager:update(dt)
    end
end

--- Quit the bot properly with the data saved.
function botAPI:quit()
    dataStorage(-2)
    self.discord:disconnect()
end

--== Events ==--

--Hook to get the bot user object
function botAPI._READY(data)
    botAPI.me = data.user

    local gdata = dataStorage["bot/gateway"]

    gdata.url = botAPI.discord.gateway.gatewayURL
    gdata.info = botAPI.discord.gateway.gatewayInfo

    dataStorage["bot/gateway"] = gdata
end

--Write a list of the guilds the bot is in
function botAPI._GUILD_CREATE(guild)
    local GLIST = dataStorage["bot/guilds"]

    local id, name = tostring(guild:getID()), tostring(guild)
    if not GLIST[id] or GLIST[id] ~= name then
        GLIST[id] = name
        dataStorage["bot/guilds"] = GLIST
    end
end

--Pass the BOT API
return botAPI