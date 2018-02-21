--LIKO-12 Discord Library Config

local conf = {}

--OAuth
conf.clientID = ""
conf.clientSecret = ""
conf.oAuth_redirect_uri = "https://ramilego4game.github.io/LIKO-12-Discord/index.html"
conf.oAuth_scopes = {
  "identify", "guilds", "messages.read"
}

--Bot
--conf.bot_token = "" -- Only if you want to create a bot.

--Other
conf.agent = "DiscordBot (https://github.com/RamiLego4Game/LIKO-12, 1)"

return conf