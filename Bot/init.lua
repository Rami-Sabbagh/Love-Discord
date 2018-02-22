
local bot = {}

local discord = require("Discord")

local CommandsManager = require("Bot.CommandsManager")
local EventsManager = require("Bot.EventsManager")

function bot.initialize()
  print("Loading Events...")
  EventsManager.initialize()
  
  print("Loading Commands...")
  CommandsManager.reload()
  
  print("Requesting Gateway...")
  discord.gateway.getGatewayBot()

  print("Connecting to the Gateway...")
  discord.gateway.connect()
end

function bot.update(dt)
  discord.gateway.update(dt)
end

return bot