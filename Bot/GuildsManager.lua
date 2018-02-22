--Love-Discord Bot Guilds Manager

local discord = require("Discord")

local gm = {}

gm.Guild = {} -- Guild[guild_id] = GuildObject
gm.GuildID = {} --GuildID[GuildName] = guild_id
gm.GuildChannel = {} -- GuildChannels[guild_id][ChannelName] = channel_id
gm.ChannelGuild = {} -- ChannelGuild[channel_id] = guild_id

function gm.guildCreate(data)
  
  gm.Guild[data.id] = data
  gm.GuildID[data.name] = data.id
  
  gm.GuildChannel[data.id] = {}
  if data.channels then
    for k, chdata in ipairs(data.channels) do
      if chdata.name then
        gm.GuildChannel[data.id][chdata.name] = chdata.id
      end
      gm.ChannelGuild[chdata.id] = data.id
    end
  end
  
end

return gm