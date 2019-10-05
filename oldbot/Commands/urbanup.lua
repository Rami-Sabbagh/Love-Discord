local discord, chid, data = ...

discord.channels.createMessage(chid, "This command no longer works due to the removal of urban dictionary API...")
if true then return end

local http = require("socket.http")

local term = table.concat({select(4,...)}, " ")
if term == "" then
  discord.channels.createMessage(chid, "Usage: `urbanup <term>`")
  return
end

discord.channels.triggerTypingIndicator(chid)

local res,code,headers,status = http.request("http://api.urbandictionary.com/v0/define?term="..discord.tools.urlEscape(term))

if res then
  local res = discord.json:decode(res)
  if res.result_type == "no_results" then
    discord.channels.createMessage(chid, "No results found.")
  else
    local best = 1
    local best_score = res.list[1].thumbs_up - res.list[1].thumbs_down
    for k,v in ipairs(res.list) do
      local score = v.thumbs_up - v.thumbs_down
      if score > best_score then
        best = k
        best_score = score
      end
    end
  
    local def = res.list[best]
    local deftext = def.definition
    if #deftext > 512 then deftext = deftext:sub(1,512).."..." end
    
    local embed = {
      title='"'..def.word..'" #'..def.defid,
      type="rich",
      description=deftext,
      url=def.permalink,
      color = 0x23A9E0,
      author = {name="Author: "..def.author,url="https://www.urbandictionary.com/author.php?author="..discord.tools.urlEscape(def.author)}
    }
    
    if #def.example > 0 then
      if #def.example > 128 then def.example = def.example:sub(1,128).."..." end
      embed.fields = {{name="Example:",value=def.example or "[NONE]"},
        {name="Tags:",value=table.concat(res.tags, ", ")},
        {name="Thumbs Up 👍:",value=def.thumbs_up,inline=true},
        {name="Thumbs Down 👎:",value=def.thumbs_down,inline=true}}
    else
      embed.fields = {{name="Tags:",value=table.concat(res.tags, ", ")},
        {name="Thumbs Up 👍:",value=def.thumbs_up,inline=true},
        {name="Thumbs Down 👎:",value=def.thumbs_down,inline=true}}
    end
    
    discord.channels.createMessage(chid, "", embed)
  end
else
  discord.channels.createMessage(chid, "Failed ! `"..tostring(code).."`")
end