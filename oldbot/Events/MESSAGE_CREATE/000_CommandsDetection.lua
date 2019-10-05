local discord, data = ...

local CommandsManager = require("Bot.CommandsManager")
local GuildsManager = require("Bot.GuildsManager")

local ThinkingEmojies = {
  "❓", --Red question mark
  "❔", --Grey question mark
  "🤔" --Thinking face
}

--Splits a string at each white space.
local function split(str)
  local t = {}
  for val in str:gmatch("%S+") do
    table.insert(t, val)
  end
  return unpack(t)
end

if data.author.bot then return end --Bot messages are ignored.

local chid = data.channel_id
local content = data.content
local args = {split(content)}
local gid = GuildsManager.ChannelGuild[chid]

local prefix = CommandsManager.getPrefix(gid)

print("Message: "..content)

if args[1] and args[1]:sub(#prefix,#prefix) == prefix then
  local c = args[1]:sub(#prefix+1,-1)
  print("Command "..c)
  if CommandsManager.commands[c] then
    local ok, err = pcall(CommandsManager.commands[c],discord,chid, data, select(2,unpack(args)))
    if not ok then
      print("Command failed",c,err)
      if GuildsManager.GuildID["LIKO-12"] then
        local chidlog = GuildsManager.GuildChannel[GuildsManager.GuildID["LIKO-12"]]["botlog"]
        pcall(discord.channels.createMessage,chidlog,"Command `"..c.."` failed: ```\n"..tostring(err).."\n```")
      end
    end
  else
    local emoji = ThinkingEmojies[math.random(1,#ThinkingEmojies)]
    pcall(discord.channels.createReaction,chid,data.id,emoji)
  end
end