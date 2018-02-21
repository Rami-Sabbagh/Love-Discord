local discord, chid, data = ...

local CommandsManager = require("Bot.CommandsManager")

if data.author.id == "207435670854041602" then
  CommandsManager.reload()
  discord.channels.createMessage(chid, "Reloaded Successfully !")
else
  discord.channels.createMessage(chid, "Only Rami can reload the bot commands !")
end