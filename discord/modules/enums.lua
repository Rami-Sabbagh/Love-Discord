--Discord Enums

local enums = {}

--New enum, adds in the reverse keys
local function enum(e)
    for k,v in pairs(e) do
        if type(k) == "number" then
            e[v] = k --Add reverse entries
        end
    end

    return e
end

enums.channelTypes = enum{
    [0] = "GUILD_TEXT",
    [1] = "DM",
    [2] = "GUILD_VOICE",
    [3] = "GROUP_DM",
    [4] = "GUILD_CATEGORY",
    [5] = "GUILD_NEWS",
    [6] = "GUILD_STORE"
}

return enums