--Love-Discord Bot Events Manager

local discord = require("Discord")

local em = {}

em.events = {}

function em.initialize()
  for k1, event in ipairs(love.filesystem.getDirectoryItems("Bot/Events")) do
    em.events[event] = {}
    
    --Gateway hook
    discord.gateway.events[event] = function(data)
      for k2, vfunc in ipairs(em.events[event]) do
        vfunc(discord,data)
      end
    end
    
    --Load the events and register them.
    for k2, file in ipairs(love.filesystem.getDirectoryItems("Bot/Events/"..event)) do
      local vfunc = love.filesystem.load("Bot/Events/"..event.."/"..file)
      table.insert(em.events[event],vfunc)
    end
  end
end

return em