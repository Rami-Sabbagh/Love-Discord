local term = require("terminal")

term.reload()

local discord = require("Libraries.Discord")

local command = (...) or ""

color(6)

if command == "oauth" then
  
  discord.oauth.requestAutorization()
  
  return
end

local commands = {}

function commands.whatami(chid)
  discord.channels.createMessage(chid, "I'm a Discord bot written and running in LIKO-12")
end

function commands.say(chid, data, ...)
  local msg = table.concat({...}," ")
  discord.channels.createMessage(chid, data.author.username..": "..msg)
end

function commands.commands(chid)
  local cs = {}
  for k,v in pairs(commands) do
    table.insert(cs,k)
  end
  local msg = "```\n"..table.concat(cs,", ").."\n```"
  discord.channels.createMessage(chid, msg)
end

function commands.docs(chid,data,item)
  local item = item or ""
  local url = "https://liko-12.readthedocs.io/en/latest/"..item:gsub("%.","/").."/"
  
  discord.channels.createMessage(chid, url)
end

function commands.help(chid,data,topic)
  for name,id in pairs(Guilds["Unofficial Principia Discord"]) do
    if id == chid then
      discord.channels.createMessage(chid, "This command is not allowed in `Unofficial Principia Discord`")
      return
    end
  end
  
  local topic = topic or "Welcome"
  
  local helpPath = require("Programs/help",true).getHelpPath()
  
  local function nextPath()
    if helpPath:sub(-1)~=";" then helpPath=helpPath..";" end
    return helpPath:gmatch("(.-);")
  end
  
  local doc --The help document to print

  for path in nextPath() do
    if fs.exists(path..topic) then
      doc = path..topic break
    elseif fs.exists(path..topic..".md") then
      doc = path..topic..".md" break
    end
  end
  
  if not doc then 
    discord.channels.createMessage(chid,"Help file not found '"..topic.."' !")
    return
  end
  
  doc = fs.read(doc)
  doc = doc:gsub("\r\n","\n")
  
  discord.channels.createMessage(chid,doc)
end

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
      cprint("Channel",data.name,v.name,v.id)
    end
  end
end

discord.gateway.events["MESSAGE_CREATE"] = function(data)
  if data.author.bot then return end --Bot messages are ignored.
  
  local chid = data.channel_id
  local content = data.content
  local args = {split(content)}
  
  print("Message: "..content)
  
  if args[1] and args[1] == ">" then
    local c = args[2]
    print("Command "..c)
    if commands[c] then
      local ok, err = pcall(commands[c],chid, data, select(3,unpack(args)))
      if not ok then
        cprint("Command failed",c,err)
        pcall(discord.channels.createMessage,Guilds["LIKO-12"]["botlog"],"Command `"..c.."` failed: ```\n"..tostring(err).."\n```")
      end
    else
      discord.channels.createMessage(chid, "Invalid Command !!!")
    end
  end
end

print("Requesting Gateway...") flip()

discord.gateway.getGatewayBot()

print("Connecting to the Gateway...") flip()

discord.gateway.connect()

print("Entering the pullEvent loop...") flip()

for event, a,b,c,d,e,f in pullEvent do
  if event == "update" then
    discord.gateway.update(a)
  elseif event == "keypressed" then
    if a == "escape" then
      break
    elseif a == "h" then
      discord.channels.createMessage(Guilds["LIKO-12"]["general"],"Hello everyone")
    end
  end
end

print("Disconnecting...") flip()

discord.gateway.disconnect()