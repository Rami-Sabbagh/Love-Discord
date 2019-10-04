--Message utilities, for formating user tags and such
local discord = ... --Passed as an argument
local json = discord.json

local messageUtilities = {}

--TODO: Do not depend on LÖVE
--Emojis lists, generated from https://github.com/Necktrox/discord-emoji
messageUtilities.emojis = json:decode(love.filesystem.read(discord._directory.."assets/emojis_list.json"))
messageUtilities.emojisReversed = json:decode(love.filesystem.read(discord._directory.."assets/emojis_reverse_list.json"))
messageUtilities.emojisText = json:decode(love.filesystem.read(discord._directory.."assets/emojis_text_list.json"))

--TODO: Add emojis utilities

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