local discord, chid, data = ...

local msg = table.concat({select(4,...)}," ")
if msg:gsub("%s","") == "" then
  discord.channels.createMessage(chid, "[Invalid Message]")
else
  discord.channels.createMessage(chid, msg)
end