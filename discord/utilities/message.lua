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

--https://discord.com/developers/docs/reference#message-formatting

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
    return message:gsub("[^:]?[^:]?:%a-:", function(mstr)
        local prefix = mstr:match("^[^:]-:") or ""
        if prefix:sub(1,1) == "<" then return false end --This is a custom emoji tag, ignore it!

        local emojiName = mstr:match(":%a-:"):sub(2,-2)
        local unicode = messageUtilities.emojis[emojiName]

        if unicode then
            return prefix:sub(1,-2) .. unicode
        else
            return false --Unknown emoji, don't replace
        end
    end)
end

return messageUtilities