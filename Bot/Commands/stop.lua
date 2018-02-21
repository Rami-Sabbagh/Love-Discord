local discord, chid, data = ...

if data.author.id == "207435670854041602" then
  discord.channels.createMessage(chid, "Goodbye !")
  print("Bot shutdown")
  discord.gateway.disconnect()
  love.event.quit()
else
  discord.channels.createMessage(chid, "Only Rami can stop the bot !")
end