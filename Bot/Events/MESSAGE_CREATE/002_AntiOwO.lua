local discord, data = ...

local chid = data.channel_id
local content = data.content:lower()

if data.author.bot then return end --Ignore bot messages

local owoPatterns = {
  "[ou]+[%A]*[w]+[%A]*[ou]+",
  "[ow]+[%A]*[u]+[%A]*[ow]+"
}

for _, pattern in pairs(owoPatterns) do
  if content:find(pattern) then
    discord.channels.createMessage(chid, "https://i.redd.it/cqpuzj8avzh11.png")
    break
  end
end