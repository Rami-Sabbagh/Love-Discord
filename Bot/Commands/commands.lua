local discord, chid, data = ...

local CommandsManager = require("Bot.CommandsManager")

local cs = {}
for k,v in pairs(CommandsManager.commands) do
  table.insert(cs,k)
end
local msg = "```css\n"..table.concat(cs,", ").."\n```"
discord.channels.createMessage(chid, msg)