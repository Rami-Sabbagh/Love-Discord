local discord, chid, data = ...

local section = table.concat({select(4,...)}, " ")
if section == "" then
  discord.channels.createMessage(chid, "Usage: `wiki <seciton name>`")
  return
end

local url = "http://love2d.org/wiki/"..discord.tools.urlEscape(section)

discord.channels.createMessage(chid, url)