--Love-Discord Bot Commands Manager

local cm = {}

cm.commands = {} --The loaded commands chunks
cm.prefix = "." --The default prefix is '.'

function cm.reload()
  cm.commands = {} --Clear the commands table
  
  for id, name in ipairs(love.filesystem.getDirectoryItems("Bot/Commands")) do
    local chunk, err = love.filesystem.load("Bot/Commands/"..name)
    if chunk then
      cm.commands[name:sub(1,-5)] = chunk
      print("Loaded",name:sub(1,-5))
    else
      print("Failed to load command '"..name.."'",err)
    end
  end
end

return cm