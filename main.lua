--LÖVE Discord, A WIP Discord API Library for LÖVE framework and LuaJIT

local discord = require("Discord")

local commands = love.filesystem.load("commands.lua")(discord)

local superCommands = {}

superCommands.reload = function(chid,data)
  if data.author.id == "207435670854041602" then
    commands = love.filesystem.load("commands.lua")(discord)
    discord.channels.createMessage(chid, "Reloaded Successfully !")
  else
    discord.channels.createMessage(chid, "Only Rami can reload the bot commands !")
  end
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
    if commands[c] then
      local ok, err = pcall(commands[c],chid, data, select(2,unpack(args)))
      if not ok then
        print("Command failed",c,err)
        pcall(discord.channels.createMessage,Guilds["LIKO-12"]["botlog"],"Command `"..c.."` failed: ```\n"..tostring(err).."\n```")
      end
    elseif superCommands[c] then
      local ok, err = pcall(superCommands[c],chid, data, select(2,unpack(args)))
      if not ok then
        print("Command failed",c,err)
        pcall(discord.channels.createMessage,Guilds["LIKO-12"]["botlog"],"Command `"..c.."` failed: ```\n"..tostring(err).."\n```")
      end
    else
      discord.channels.createMessage(chid, "Invalid Command !!!")
    end
  end
end

function love.load()
  print("Requesting Gateway...")
  discord.gateway.getGatewayBot()

  print("Connecting to the Gateway...")
  discord.gateway.connect()
end

function love.update(dt)
  discord.gateway.update(dt)
end