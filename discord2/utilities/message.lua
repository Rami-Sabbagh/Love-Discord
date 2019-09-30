--Message utilities, for formating user tags and such
local discord = ... --Passed as an argument

local messageUtilities = {}

--https://discordapp.com/developers/docs/reference#message-formatting

function messageUtilities.formatUser(id)
    return string.format("<@%d>", id)
end

function messageUtilities.formatUserNick(id)
    return string.format("<@!%d>", id)
end

function messageUtilities.formatChannel(id)
    return string.format("<%#%d>", id) --TODO: Check if this works
end

function messageUtilities.formatRole(id)
    return string.format("<@&%d>", id)
end

function messageUtilities.formatCustomEmoji(name,id)
    return string.format("<:%s:%d>", name, id)
end

function messageUtilities.formatCustomAnimatedEmoji(name,id)
    return string.format("<a:%s:%d>", name, id)
end

return messageUtilities