local discord, data = ...

if not data.content then return end

local chid = data.channel_id
local content = data.content:lower()

if data.author.bot then return end --Ignore bot messages

local owoPatterns = {
  "[ou]+[%p]*[w]+[%p]*[ou]+",
  "[ow]+[%p]*[u]+[%p]*[ow]+"
}

for _, pattern in pairs(owoPatterns) do
  local spos, epos = content:find(pattern)
  if spos then
    discord.channels.createMessage(chid, __, {
      --title = "DON'T "..content:sub(spos, epos):upper(),
      --description = "**$350 PENALTY**",
      color = 0xEE0000,
      image = {
        url = "https://cdn.discordapp.com/attachments/440553300203667479/628171994218889216/unknown.png"
      }
    })
    break
  end
end