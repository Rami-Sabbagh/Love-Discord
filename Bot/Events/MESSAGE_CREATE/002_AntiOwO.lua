local discord, data = ...

local chid = data.channel_id
local content = data.content:lower()

local owoPatterns = {
  "[ou][w]+[ou]",
  "[ow][u]+[ow]"
}

for _, pattern in pairs(owoPatterns) do
  if content:find(pattern) then
    discord.channels.createMessage(chid, "https://i.redd.it/cqpuzj8avzh11.png")
  end
end