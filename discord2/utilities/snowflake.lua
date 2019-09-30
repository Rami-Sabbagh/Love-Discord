local discord = ... --Passed as an argument
local bit = discord.utilities.bit --Universal bitwise interface

--Localised functions and values
local band, lshift, rshift = bit.band, bit.lshift, bit.rshift

--The snowflake module
local snowflake = {}

snowflake.
snowflake.increment = 0 --The increment of the snowflakes generated using this API

--Decodes a snowflake, returns a table with the decoded information
function snowflake.decode(sf)
    sf = tonumber(sf)
    local time = bit.rshift(sf,22)
    time = time + 1420070400000

    local workerID = bit.band(sf,0x3E0000)
    workerID = bit.rshift(workerID,17)

    local processID = bit.band(sf, 0x1F000)
    processID = bit.rshift(processID,12)

    local increment = bit.band(sf, 0xFFF)

    return {
        time = time, workerID = workerID, processID = processID, increment = increment
    }
end

--Converts a snowflake into a os.time() compatible value
function snowflake.toTime(sf)
    sf = tonumber(sf)
    local time = bit.rshift(sf,22)
    
    return time + 1420070400000
end

return snowflake