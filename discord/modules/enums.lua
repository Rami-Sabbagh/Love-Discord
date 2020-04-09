--- Discord Enums.
-- @module discord.enums

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

enums.activityTypes = enum{
    [0] = "Game",
    [1] = "Steaming",
    [2] = "Listening",
    [3] = "Watching" --Not documented
}

enums.channelTypes = enum{
    [0] = "GUILD_TEXT",
    [1] = "DM",
    [2] = "GUILD_VOICE",
    [3] = "GROUP_DM",
    [4] = "GUILD_CATEGORY",
    [5] = "GUILD_NEWS",
    [6] = "GUILD_STORE"
}

enums.explicitContentFilterLevels = enum{
    [0] = "DISABLED",
    [1] = "MEMBERS_WITHOUT_ROLES",
    [2] = "ALL_MEMBERS"
}

enums.messageNotificationsLevels = enum{
    [0] = "ALL_MESSAGES",
    [1] = "ONLY_MENTIONS"
}

--- Message types
-- @todo Write a LDoc extension for enums
enums.messageTypes = enum{
    [0] = "DEFAULT",
    [1] = "RECIPIENT_ADD",
    [2] = "RECIPIENT_REMOVE",
    [3] = "CALL",
    [4] = "CHANNEL_NAME_CHANGE",
    [5] = "CHANNEL_ICON_CHANGE",
    [6] = "CHANNEL_PINNED_MESSAGE",
    [7] = "GUILD_MEMBER_JOIN",
    [8] = "USER_PREMIUM_GUILD_SUBSCRIPTION",
    [9] = "USER_PREMIUM_GUILD_SUBSCRIPTION_TIER_1",
    [10] = "USER_PREMIUM_GUILD_SUBSCRIPTION_TIER_2",
    [11] = "USER_PREMIUM_GUILD_SUBSCRIPTION_TIER_3",
    [12] = "CHANNEL_FOLLOW_ADD",
    [13] = "GUILD_DISCOVERY_DISQUALIFIED",
    [14] = "GUILD_DISCOVERY_QUALIFIED"
}

enums.mfaLevels = enum{
    [0] = "NONE",
    [1] = "ELEVATED"
}

enums.premiumTypes = enum{
    [0] = "Normal",
    [1] = "Nitro Classic",
    [2] = "Nitro"
}

enums.verificationLevels = enum{
    [0] = "NONE",
    [1] = "LOW",
    [2] = "MEDIUM",
    [3] = "HIGH",
    [4] = "VERY_HIGH"
}

return enums