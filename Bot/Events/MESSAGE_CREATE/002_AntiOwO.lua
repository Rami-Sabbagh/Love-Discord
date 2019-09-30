local discord, data = ...

local chid = data.channel_id
local content = data.content:lower()

if data.author.bot then return end --Ignore bot messages

local owoPatterns = {
  "[ou]+[%A]*[w]+[%A]*[ou]+",
  "[ouw]+[%A]*[w]+[%A]*[ou]+",
  "[ou]+[%A]*[w]+[%A]*[ouw]+",

  "[ow]+[%A]*[u]+[%A]*[ow]+",
  "[ouw]+[%A]*[u]+[%A]*[ow]+",
  "[ow]+[%A]*[u]+[%A]*[ouw]+"
}

for _, pattern in pairs(owoPatterns) do
  if content:find(pattern) then
    discord.channels.createMessage(chid, "https://i.redd.it/cqpuzj8avzh11.png")
    break
  end
end