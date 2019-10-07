--Basic operations plugin
local botAPI, discord, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")

local owoPatterns = {
    "[ouv°]+[%p]*[w]+[%p]*[ouv°]+",
    "[owv°]+[%p]*[u]+[%p]*[owv°]+",
    "[ouw°]+[%p]*[v]+[%p]*[ouw°]+",
}

local penalty = 350

local plugin = {}

--== Plugin Meta ==--

plugin.name = "AntiOwO" --The visible name of the plugin
plugin.version = "V2.0.1" --The visible version string of the plugin
plugin.description = "Complains about everyone saying owo or it's varients" --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

plugin.commands = {}

--== Plugin Events ==--

plugin.events = {}

plugin.events.MESSAGE_CREATE = function(message)
    local author = message:getAuthor()
    
    if author:isBot() then return end
    if author == botAPI.me then return end
    --if botAPI:isFromDeveloper(message) then return end

    local authorID = tostring(author:getID())

    local content = message:getContent():lower()

    for _, pattern in pairs(owoPatterns) do
        local spos, epos = content:find(pattern)
        if spos then
            local owo = content:sub(spos, epos)
            if content:sub(spos-4, epos) == "antiowo" then
                message:addReaction("eyes")
                return
            end

            local usage = dataStorage["plugins/antiowo/usage"]
            usage[owo] = math.min((usage[owo] or 0) + 1, 446744073709551615)
            dataStorage["plugins/antiowo/usage"] = usage

            local penalties = dataStorage["plugins/antiowo/penalties"]
            penalties[authorID] = (penalties[authorID] or 0) + penalty
            dataStorage["plugins/antiowo/penalties"] = penalties
            
            --TODO: Add embed support and not use a hack
            discord.rest:request("/channels/"..tostring(message:getChannelID()).."/messages", {
                embed = {
                    --title = "DON'T "..content:sub(spos, epos):upper(),
                    title = "**$"..penalties[authorID].." PENALTY**",
                    description = "for "..tostring(author).." to pay!",
                    color = 0xEE0000,
                    image = {
                        url = "https://cdn.discordapp.com/attachments/440553300203667479/628171994218889216/unknown.png"
                    }
                }
            })
            break
        end
    end
end

plugin.events.MESSAGE_UPDATE = plugin.events.MESSAGE_CREATE

return plugin