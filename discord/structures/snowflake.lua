local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local snowflake = class("discord.structures.Snowflake")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if v == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New snowflake object
--sf (string): The snowflake to initialize with.
--sf (number): Create a new snowflake with this time.
--sf (nil): Create a new snowflake with the time of creation.
function snowflake:initialize(sf)
    Verify(sf, "snowflake", "string", "number", "nil")

    if type(sf) == "number" then
        if sf < 1420070400 then return error("Discord didn't exist at that time!") end
        sf = discord.utilities.snowflake.fromTime(sf, 2)
    elseif not sf then
        if os.time() < 1420070400 then return error("Discord doesn't exist yet!") end
        sf = discord.utilities.snowflake.new(3)
    end

    if not tonumber(sf) then return error("Invalid Snowflake!") end
    local data = discord.utilities.snowflake.decode(sf)
    self.time, self.processID, self.workerID, self.increment = data.time, data.processID, data.workerID, self.increment
    self.sf = sf
end

--Returns the time of the snowflake
function snowflake:getTime()
    return self.time
end

--Returns the workerID of the snowflake
function snowflake:getWorkerID()
    return self.workerID
end

--Returns the processID of the snowflake
function snowflake:getProcessID()
    return self.processID
end

--Returns the increment of the snowflake
function snowflake:getIncrement()
    return self.increment
end

--Returns the snowflake's information
function snowflake:getInformation()
    return self.time, self.workerID, self.processID, self.increment
end

--Returns the snowflake string
function snowflake:getString()
    return self.sf
end

--Returns the snowflake as a number
function snowflake:getNumber()
    return tonumber(self.sf)
end

--Returns the time since discord epoch
function snowflake:getTimeSinceDiscordEpoch()
    return self.time - 1420070400
end

--== Operator Overrides ==--

--Returns the snowflake as a string
function snowflake:__tostring()
    return self.sf
end

--Tests if the two snowflakes are the same
function snowflake:__eq(other)
    return self.sf == other.sf
end

--Compares two snowflakes, which one is the newer
function snowflake:__lt(other)
    return self.sf < other.sf
end

--Compares two snowflakes, which one is the newer
function snowflake:__le(other)
    return self.sf <= other.sf
end

return snowflake