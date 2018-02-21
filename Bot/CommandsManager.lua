--Love-Discord Bot Commands Manager

local discord = require("Discord")

local cm = {}

cm.commands = {} --The loaded commands chunks
cm.prefixes = {}

if love.filesystem.exists("prefix.json") then
  cm.prefixes = discord.json:decode(love.filesystem.read("prefix.json"))
else
  love.filesystem.write("prefix.json",discord.json:encode_pretty(cm.prefixes))
end

function cm.reload()
  cm.commands = {} --Clear the commands table
  
  for id, name in ipairs(love.filesystem.getDirectoryItems("Bot/Commands")) do
    local ok, chunk = pcall(love.filesystem.load,"Bot/Commands/"..name)
    if ok then
      cm.commands[name:sub(1,-5)] = chunk
      print("Loaded",name:sub(1,-5))
    else
      print("Failed to load command '"..name.."'",chunk)
    end
  end
end

function cm.setPrefix(p)
  cm.prefix = p
  love.filesystem.write("prefix.txt",cm.prefix)
end

return cm