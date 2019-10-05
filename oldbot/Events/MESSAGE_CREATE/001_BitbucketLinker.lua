local discord, data = ...

if data.author.bot then return end --Bot messages are ignored.

local chid = data.channel_id
local content = data.content

if string.find(content:lower(),"issue #%d+") then
  local issueid = string.match(content:lower(),"issue #%d+"):sub(8,-1)
  discord.channels.createMessage(chid, "https://bitbucket.org/rude/love/issues/"..issueid.."/")
end