
local bot = {}

local discord = require("Discord")

local CommandsManager = require("Bot.CommandsManager")
local EventsManager = require("Bot.EventsManager")

function bot.initialize()
  print("Loading Events...")
  EventsManager.initialize()
  
  print("Loading Commands...")
  CommandsManager.reload()
  
  while true do
    print("Requesting Gateway...")
    local ok, err = pcall(discord.gateway.getGatewayBot)
    if ok then break end
    
    print("Failed, Reason:",tostring(err))
    print("Retrying in 5 seconds...")
    love.timer.sleep(5)
  end

  while true do
    print("Connecting to the Gateway...")
    local ok, err = pcall(discord.gateway.connect)
    if ok then break end
    
    print("Failed, Reason:",tostring(err))
    print("Retrying in 5 seconds...")
    love.timer.sleep(5)
  end
end

function bot.update(dt)
  discord.gateway.update(dt)
end

return bot