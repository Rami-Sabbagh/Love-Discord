local discord, chid, data = ...

local CommandsManager = require("Bot.CommandsManager")
local GuildsManager = require("Bot.GuildsManager")

if data.author.id == "207435670854041602" then
  local gid = GuildsManager.ChannelGuild[chid]
  if gid then
    local prefix = select(4,...)
    if prefix then
      CommandsManager.setPrefix(gid,prefix)
      discord.channels.createMessage(chid, "The prefix has been set to `"..prefix.."`")
    else
      discord.channels.createMessage(chid, "Usage: `setprefix <prefix>`")
    end
  else
    discord.channels.createMessage(chid, "Prefix can't be set in DM !")
  end
else
  discord.channels.createMessage(chid, "Only Rami can set the prefix !")
end