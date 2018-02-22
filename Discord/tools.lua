--Discord API Tools

local bit = require("bit")

local discord = ...

local tools = {}

function tools.decodeSnowflake(sf)
  sf = tonumber(sf)
  local time = bit.rshift(sf,22)
  time = time + 1420070400000
  
  local workerID = bit.band(sf,0x3E0000)
  workerID = bit.rshift(workerID,17)
  
  local processID = bit.band(sf, 0x1F000)
  processID = bit.rshift(processID,12)
  
  local Increment = bit.band(sf, 0xFFF)
  
  return time, workerID, processID, Increment
end

function tools.snowflake2Time(sf)
  sf = tonumber(sf)
  local time = bit.rshift(sf,22)
  
  return time + 1420070400000
end

function tools.time2Snowflake(time)
  time = time - 14200700000
  return tostring(bit.lshift(time,22))
end

function tools.generateSnowflake()
  return tools.time2Snowflake(os.time())
end

local pnames = {
  "CREATE_INSTANT_INVITE", "KICK_MEMBERS", "BAN_MEMBERS", "ADMINISTRATOR", "MANAGE_CHANNELS", "MANAGE_GUILD", "ADD_REACTIONS", "VIEW_AUDIT_LOG", "VIEW_CHANNEL", "SEND_MESSAGES", "SEND_TTS_MESSAGES", "MANAGE_MESSAGES", "EMBED_LINKS", "ATTACH_FILES", "READ_MESSAGE_HISTORY", "MENTION_EVERYONE", "USE_EXTERNAL_EMOJIS", "CONNECT", "SPEAK", "MUTE_MEMBERS", "DEAFEN_MEMBERS", "MOVE_MEMBERS", "USE_VAD", "CHANGE_NICKNAME", "MANAGE_NICKNAMES", "MANAGE_ROLES", "MANAGE_WEBHOOKS", "MANAGE_EMOJIS",
}

function tools.decodePermissions(perm)
  local p = {}
  for k, permission in ipairs(pnames) do
    if bit.band(perm,1) > 0 then
      p[permission] = true
    end
    perm = bit.rshift(perm,1)
  end
  return p
end

function tools.urlEscape(str)
  if type(str) ~= "string" then return error("STR must be a string, provided: "..type(str)) end
  str = str:gsub("\n", "\r\n")
  str = str:gsub("\r\r\n", "\r\n")
  str = str:gsub("([^A-Za-z0-9 %-%_%.])", function(c)
    local n = string.byte(c)
    if n < 128 then
      -- ASCII
      return string.format("%%%02X", n)
    else
      -- Non-ASCII (encode as UTF-8)
      return string.format("%%%02X", 192 + bit.band( bit.arshift(n,6), 31 )) .. 
             string.format("%%%02X", 128 + bit.band( n, 63 ))
    end
  end)
  
  str = str:gsub(" ", "+")
  
  return str
end

function tools.urlEncode(data)
  local encode = {}
  
  for k,v in pairs(data) do
    encode[#encode + 1] = k.."="..v
  end
  
  return table.concat(encode,"&")
end

return tools