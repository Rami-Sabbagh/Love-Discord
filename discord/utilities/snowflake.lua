local discord = ... --Passed as an argument
local bit = discord.utilities.bit --Universal bitwise interface

--Localised functions and values
local band, lshift, rshift = bit.band, bit.lshift, bit.rshift

--The snowflake module
local snowflake = {}

snowflake.workerID = 1 --The worker ID of the generated snowflakes
snowflake.processID = 0 --The process ID of the generated snowflakes
snowflake.increment = 0 --The increment of the snowflakes generated using this API

--Decodes a snowflake, returns a table with the decoded information
function snowflake.decode(sf)
    sf = tonumber(sf)
    local time = bit.rshift(sf,22)
    time = time + 1420070400

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
    return bit.rshift(sf,22) + 1420070400
end

--Generates a snowflake from the given time value
function snowflake.fromTime(time, worker)
    time = time - 1420070400
    time = lshift(time, 5) + (worker or snowflake.workerID)
    time = lshift(time, 5) + snowflake.processID
    time = lshift(time, 12) + snowflake.increment
    snowflake.increment = snowflake.increment + 1 --Increase the increment counter for this process

    return tostring(time)
end

--Generates a new snowflake for the current moment
function snowflake.new(worker)
    return snowflake.fromTime(os.time(), worker)
end

return snowflake