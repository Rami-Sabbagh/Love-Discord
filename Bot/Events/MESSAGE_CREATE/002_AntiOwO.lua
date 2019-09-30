local discord, data = ...

local chid = data.channel_id
local content = data.content

if string.find(content:lower(),"owo") or string.find(content:lower(),"uwu") then
  discord.channels.createMessage(chid, "https://i.redd.it/cqpuzj8avzh11.png")
end