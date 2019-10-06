--Discörd Böt Data smart storage table

--Steal the JSON library from Discörd
local json = require("discord.third-party.JSON")

--Make sure the data files exist
if not love.filesystem.getInfo("/data/") then love.filesystem.createDirectory("/data/") end

--Setup the weak reference table (so we don't have to read the table back if referenced somewhere else in the bot code (which is illegal))
local weakCache = setmetatable({}, { __mode = "kv" })

--A local table for temporary storing data tables
local cacheLifeTime = 10 --Keeps the data cached for 10 seconds
local encodePretty = true --Should the written data be pretty encoded ?
local cacheTimers = {}
local internalCache = {}
local modifiedFlags = {}

local function writeFile(path, data)
    path = path .. ".json"
    local parentDirectory = path:match(".+/")
    if parentDirectory and not love.filesystem.getInfo("/data/"..parentDirectory) then
        assert(love.filesystem.createDirectory("/data/"..parentDirectory))
    end

    assert(love.filesystem.write("/data/"..path, encodePretty and json:encode_pretty(data) or json:encode(data)))
end

--The smart cache table
local cache = setmetatable({}, {
    __index = function(t, k)
        cacheTimers[k] = cacheLifeTime --Revive the cached value
        if internalCache[k] then return internalCache[k] end
        if weakCache[k] then
            local v = weakCache[k]
            internalCache[k] = v
            return v
        end

        local fileName = "/data/"..tostring(k)..".json"
        local value = {}
        if love.filesystem.getInfo(fileName) then
            value = json:decode(love.filesystem.read(fileName))
        else
            modifiedFlags[k] = true --New table
        end

        internalCache[k] = value
        weakCache[k] = value
        return value
    end,

    __newindex = function(t, k, v)
        rawset(t, k, nil) --We want the smart cache table to stay empty

        cacheTimers[k] = cacheLifeTime --Revive the cached value
        weakCache[k] = v
        internalCache[k] = v
        modifiedFlags[k] = true
    end,

    --Important! for making sure the data is saved and unloaded aftere expiry
    __call = function(t, dt)
        if dt == -1 or dt == -2 then --Force write the data files
            --We write the whole weak referenced data tables
            for k,v in pairs(weakCache) do
                if modifiedFlags[k] then
                    local ok, err = pcall(writeFile, k, v)
                    if not ok then print("Failed to write data (", k, "): ", err, "/!\\") end
                end
            end

            modifiedFlags = {} --Clear the modified flags

            if dt == -2 then --Clear the local cache
                cacheTimers, internalCache = {}, {} --Poof, all gone
            end
        else --Update the cache timers
            for key, timer in pairs(cacheTimers) do
                cacheTimers[key] = timer - dt
                if timer <= 0 then --Time is out! Write the data and dereference
                    if modifiedFlags[key] then
                        writeFile(key, internalCache[key])
                    end

                    cacheTimers[key] = nil
                    internalCache[key] = nil
                    modifiedFlags[key] = nil
                    --We keep the weak reference, since that's the point of it
                end
            end
        end
    end
})

return cache