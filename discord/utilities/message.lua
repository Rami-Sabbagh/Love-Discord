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
    return string.format("<@%s>", id)
end

function messageUtilities.formatUserNick(id)
    return string.format("<@!%s>", id)
end

function messageUtilities.formatChannel(id)
    return string.format("<%#%s>", id) --TODO: Check if this works
end

function messageUtilities.formatRole(id)
    return string.format("<@&%s>", id)
end

function messageUtilities.formatCustomEmoji(name,id)
    return string.format("<:%s:%s>", name, id)
end

function messageUtilities.formatCustomAnimatedEmoji(name,id)
    return string.format("<a:%s:%s>", name, id)
end

function messageUtilities.patchEmojis(message)
    return message:gsub("[^<]?:[^%A:]-:", function(mstr)
        local noPreChar = mstr:sub(1,1) == ":" 
        local emojiName = noPreChar and mstr:sub(2,-2) or mstr:sub(3,-2)
        local unicode = messageUtilities.emojis[emojiName]
        
        if unicode then
            return noPreChar and unicode or mstr:sub(1,1) .. unicode
        else
            return false --Unknown emoji, don't replace
        end
    end)
end

return messageUtilities