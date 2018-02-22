local discord, chid, data = ...

if data.author.id == "207435670854041602" then
  discord.channels.createMessage(chid, "Goodbye !")
  print("Bot Restart")
  discord.gateway.disconnect()
  love.event.quit("restart")
else
  discord.channels.createMessage(chid, "Only Rami can restart the bot !")
end