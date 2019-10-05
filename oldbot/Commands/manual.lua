local discord, chid, data = ...

local section = table.concat({select(4,...)}, " ")
if section == "" then
  discord.channels.createMessage(chid, "Usage: `manual <seciton name>`")
  return
end

local url = "http://www.lua.org/manual/5.1/manual.html#pdf-"..discord.tools.urlEscape(section)

discord.channels.createMessage(chid, url)