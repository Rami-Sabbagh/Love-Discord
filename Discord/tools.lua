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