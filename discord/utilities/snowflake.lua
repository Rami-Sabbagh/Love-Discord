local discord = ... --Passed as an argument
local bit = discord.utilities.bit --Universal bitwise interface

--Localised functions and values
local band, lshift, rshift = bit.band, bit.lshift, bit.rshift
local floor = math.floor

--The snowflake module
local snowflake = {}

snowflake.workerID = 1 --The worker ID of the generated snowflakes
snowflake.processID = 0 --The process ID of the generated snowflakes
snowflake.increment = 0 --The increment of the snowflakes generated using this API

--Divides a decimal number string by 2, the result is also a string
local function divideByTwo(str)
    local remainder = 0
    local newNum, newNumLen = {}, 1
    for digit in str:gmatch("%d") do
        newNum[newNumLen] = floor(digit/2) + remainder
        remainder = digit % 2 > 0 and 5 or 0
        newNumLen = newNumLen + 1
    end
    return table.concat(newNum, ""):gsub("^0*", ""), (tonumber(str:sub(-1, -1)) % 2 == 1)
end

--Converts a decimal string into a binary string, using manual math
local function str2bin(str)
    local bits, bitslen = {}, 1
    local isOne
    while str ~= "" do
        str, isOne = divideByTwo(str)
        bits[bitslen] = isOne and "1" or "0"
        bitslen = bitslen + 1
    end
    if bitslen % 2 == 0 then bits[bitslen] = "" else bitslen = bitslen - 1 end
    --Reverse bits order
    for i=1, bitslen/2 do bits[i], bits[bitslen-i+1] = bits[bitslen-i+1], bits[i] end
    bits = table.concat(bits, "")
    return bits
end

--For fixing the decoded timestamp
local fixFactor = 1024/1000

--Decodes a snowflake, returns a table with the decoded information
function snowflake.decode(sf)
    local timeBits = str2bin(sf)
    local largePart, smallPart = timeBits:sub(1,-33), timeBits:sub(-32, -23)
    largePart, smallPart = tonumber(largePart, 2) or 0, tonumber(smallPart, 2) or 0
    local time = largePart*fixFactor + smallPart/1000
    time = math.floor(time + 1420070400)
    
    sf = tonumber(sf)

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