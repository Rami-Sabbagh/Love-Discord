--LÖVE Discord Library Config
local conf = {}

--OAuth
conf.clientID = "415821797129322496"
conf.clientSecret = "oipZihjnaSYZLSzW9s8LIFuoEo9FckqS"
conf.oAuth_redirect_uri = "https://ramilego4game.github.io/LIKO-12-Discord/index.html"
conf.oAuth_scopes = {
  "identify", "guilds", "messages.read"
}

--Bot
conf.bot_token = "NDE1ODIxNzk3MTI5MzIyNDk2.XZEUfw.OyK_xBlfSFBO458g2ab4aOa8-Pg" -- Only if you want to create a bot.

--Other
conf.agent = "DiscordBot (https://love2d.org, 1)"

return conf