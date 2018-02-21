--Discord API Tools

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

return tools