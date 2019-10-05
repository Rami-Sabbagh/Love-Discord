local discord, chid, data = ...

if data.author.id == "207435670854041602" then
  local code = data.content:sub(string.len(".execute ```lua")+1,-4)
  local chunk, err = loadstring(code)
  if chunk then
    local ok, err = pcall(chunk,discord,chid)
    if ok then
      discord.channels.createMessage(chid, "Executed Successfully !")
    else
      discord.channels.createMessage(chid, "Failed to execute: ```\n"..tostring(err).."\n```")
    end
  else
    discord.channels.createMessage(chid, "Failed to compile: ```\n"..tostring(err).."\n```")
  end
else
  discord.channels.createMessage(chid, "Only Rami can execute lua code !")
end