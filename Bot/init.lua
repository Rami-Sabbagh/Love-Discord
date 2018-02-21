
local bot = {}

local discord = require("Discord")
local CommandsManager = require("Bot.CommandsManager")

--Splits a string at each white space.
local function split(str)
  local t = {}
  for val in str:gmatch("%S+") do
    table.insert(t, val)
  end
  return unpack(t)
end

--Bot variables
local GuildsData, Guilds = {}, {}
local Channels = {}

--Gateway events
discord.gateway.events["GUILD_CREATE"] = function(data)
  GuildsData[data.id] = data
  Guilds[data.name] = {}
  
  if data.channels then
    for k,v in pairs(data.channels) do
      Guilds[data.name][v.name] = v.id
      print("Channel",data.name,v.name,v.id)
    end
  end
end

discord.gateway.events["MESSAGE_CREATE"] = function(data)
  if data.author.bot then return end --Bot messages are ignored.
  
  local chid = data.channel_id
  local content = data.content
  local args = {split(content)}
  
  print("Message: "..content)
  
  if args[1] and args[1]:sub(1,1) == "." then
    local c = args[1]:sub(2,-1)
    print("Command "..c)
    if CommandsManager.commands[c] then
      local ok, err = pcall(CommandsManager.commands[c],discord,chid, data, select(2,unpack(args)))
      if not ok then
        print("Command failed",c,err)
        pcall(discord.channels.createMessage,Guilds["LIKO-12"]["botlog"],"Command `"..c.."` failed: ```\n"..tostring(err).."\n```")
      end
    else
      discord.channels.createMessage(chid, "Invalid Command !!!")
    end
  elseif string.find(content:lower(),"issue #%d+") then
    local issueid = string.match(content:lower(),"issue #%d+"):sub(8,-1)
    discord.channels.createMessage(chid, "https://bitbucket.org/rude/love/issues/"..issueid.."/")
  end
end

function bot.initialize()
  print("Loading Commands...")
  CommandsManager.reload()
  
  print("Requesting Gateway...")
  discord.gateway.getGatewayBot()

  print("Connecting to the Gateway...")
  discord.gateway.connect()
end

function bot.update(dt)
  discord.gateway.update(dt)
end

return bot