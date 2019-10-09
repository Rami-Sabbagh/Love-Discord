--Discörd Böt - A Basic Bot System

--Set the custom error handler
require("bot.error_handler")
--Load Discörd Library
local discord = require("discord")
--Load JSON library from the Discörd library
local json = require("discord.third-party.JSON")

--Load bot sub-systems
local pluginsManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")
local dataStorage = require("bot.data_storage")

--BOT API
local botAPI = {}

--Initialize the bot and connect into Discord
function botAPI:initialize(args)
    self.args = args
    self.adminRoles = {}
    self.guildOwners = {}

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
    self.discord:hookEvent("GUILD_ROLE_CREATE", self._GUILD_ROLE_CREATE)
    self.discord:hookEvent("GUILD_ROLE_UPDATE", self._GUILD_ROLE_UPDATE)
    self.discord:hookEvent("GUILD_ROLE_DELETE", self._GUILD_ROLE_DELETE)

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

--Tells if a provided snowflake is a developer one
function botAPI:isDeveloper(id)
    for k, devid in pairs(self.config.bot.developers) do
        if devid == id then return true end
    end
    return false
end

--Tells if a message is from a developer
function botAPI:isFromDeveloper(message)
    local authorID = tostring(message:getAuthor():getID())
    return self:isDeveloper(authorID)
end

--Tells if a provided role snowflake is an admin one
function botAPI:isAdmin(guildID, roleID)
    guildID, roleID = tostring(guildID), tostring(roleID)
    if not self.adminRoles[guildID] then return false end
    return self.adminRoles[guildID][roleID]
end

--Tells if a message is from an admin
function botAPI:isFromAdmin(message)
    local guildID = message:getGuildID()
    if not guildID then return true end --DM recipient is an admin
    guildID = tostring(guildID)

    --Guild owners are admins
    if self.guildOwners[guildID] == tostring(message:getAuthor():getID()) then return true end

    --Check if any role has admin power
    local member = message:getMember()
    local roles = member:getRoles()
    for _, role in pairs(roles) do
        if self.adminRoles[guildID][tostring(role)] then return true end
    end

    return botAPI:isFromDeveloper(message) --Developers are considered admins everywhere
end

--Update the bot
function botAPI:update(dt)
    dataStorage(dt)
    self.discord:update(dt)
end

--Quit the bot properly with the data saved
function botAPI:quit(a, ...)
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

    --Admin detection
    local guildID = tostring(guild:getID())
    botAPI.adminRoles[guildID] = {}
    botAPI.guildOwners[guildID] = tostring(guild:getOwnerID())
    for _, role in pairs(guild:getRoles()) do
        local permissions = role:getPermissions()
        if permissions:get(true, "ADMINISTRATOR") then
            botAPI.adminRoles[guildID][tostring(role:getID())] = true
        end
    end
end

--Admin detection
function botAPI._GUILD_ROLE_CREATE(guildID, role)
    guildID = tostring(guildID)
    if not botAPI.adminRoles[guildID] then botAPI.adminRoles[guildID] = {} end
    local isAdmin = role:getPermissions():get(true, "ADMINISTRATOR")
    botAPI.adminRoles[guildID][tostring(role:getID())] = isAdmin and true or nil
end

function botAPI._GUILD_ROLE_UPDATE(guildID, role)
    guildID = tostring(guildID)
    if not botAPI.adminRoles[guildID] then botAPI.adminRoles[guildID] = {} end
    local isAdmin = role:getPermissions():get(true, "ADMINISTRATOR")
    botAPI.adminRoles[guildID][tostring(role:getID())] = isAdmin and true or nil
end

function botAPI._GUILD_ROLE_DELETE(guildID, roleID)
    guildID = tostring(guildID)
    if not botAPI.adminRoles[guildID] then botAPI.adminRoles[guildID] = {} end
    botAPI.adminRoles[guildID][tostring(roleID)] = nil
end

--Pass the BOT API
return botAPI