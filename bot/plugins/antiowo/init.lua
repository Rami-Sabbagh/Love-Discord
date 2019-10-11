--Basic operations plugin
local botAPI, discord, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")

local owoPatterns = {
    "[ouv°◔ʘ]+[%p]*[w]+[%p]*[ouv°◔ʘ]+",
    "[owv°◔ʘ]+[%p]*[u]+[%p]*[owv°◔ʘ]+",
    "[ouw°◔ʘ]+[%p]*[v]+[%p]*[ouw°◔ʘ]+"
}

local penalty = 350

local penaltyEmbed = discord.embed()

penaltyEmbed:setColor(0xEE0000)
penaltyEmbed:setImage("https://cdn.discordapp.com/attachments/440553300203667479/628171994218889216/unknown.png", false, 102, 142)

--Shared embed, could be used by any command
local ownerEmbed = discord.embed()
ownerEmbed:setTitle("This command could be only used by the bot's owners :warning:")

local plugin = {}

--== Plugin Meta ==--

plugin.name = "AntiOwO" --The visible name of the plugin
plugin.version = "V2.0.3" --The visible version string of the plugin
plugin.description = "Complains about everyone saying owo or it's varients" --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

plugin.commands = {}; local commands = plugin.commands

local usageEmbed = discord.embed()
usageEmbed:setTitle("Usage :notepad_spiral:")
usageEmbed:setDescription(table.concat({
    "```css",
    "antiowo report <mention_user> <owo_count>",
    "antiowo tell <mention_user>",
    "antiowo clear <mention_user>",
    "```"
},"\n"))

local function sendAntiOwOUsage(reply)
    reply:send(false, usageEmbed)
end

function commands.antiowo(message, reply, commandName, verb, arg1, arg2)
    if not botAPI:isFromOwner(message) and (not verb or verb ~= "tell") then reply:send(false, ownerEmbed) return end

    if not verb then sendAntiOwOUsage(reply) return end

    if verb == "report" then
        if not arg1 or not arg2 then sendAntiOwOUsage(reply) return end
        --if arg1:sub(1,1) ~= "<" or arg1:sub(-1,-1) ~= ">" then sendAntiOwOUsage(reply) return end
        if not tonumber(arg2) then sendAntiOwOUsage(reply) return end

        local owoCount = tonumber(arg2)
        local authorID = arg1:gsub("[<!@>]","")

        local penalties = dataStorage["plugins/antiowo/penalties"]
        penalties[authorID] = (penalties[authorID] or 0) + math.floor(penalty*owoCount)
        dataStorage["plugins/antiowo/penalties"] = penalties
        
        penaltyEmbed:setTitle("**$"..penalties[authorID].." PENALTY**")
        penaltyEmbed:setDescription("for "..arg1.." to pay!")

        message:getReplyChannel():send(nil, penaltyEmbed)
        message:delete()
    elseif verb == "tell" then
        if not arg1 then sendAntiOwOUsage(reply) return end
        local authorID = arg1:gsub("[<!@>]","")

        local penalties = dataStorage["plugins/antiowo/penalties"]
        local count = penalties[authorID] or 0

        if count <= 0 then
            message:getReplyChannel():send(arg1.." is not a weeb!")
        else
            message:getReplyChannel():send(arg1.." has $"..count.." to pay!\nWhich is `"..(count/36).."$` mike's dollars.")
        end
    elseif verb == "clear" then
        if not arg1 then sendAntiOwOUsage(reply) return end
        --if arg1:sub(1,1) ~= "<" or arg1:sub(-1,-1) ~= ">" then sendAntiOwOUsage(reply) return end
        local authorID = arg1:gsub("[<!@>]","")

        local penalties = dataStorage["plugins/antiowo/penalties"]
        penalties[authorID] = 0
        dataStorage["plugins/antiowo/penalties"] = penalties

        message:getReplyChannel():send("Cleared "..arg1.."'s penalties successfully :white_check_mark:")
    else
        sendAntiOwOUsage(reply)
    end
end

--== Plugin Events ==--

plugin.events = {}; local events = plugin.events

function events.MESSAGE_CREATE(message)
    local author = message:getAuthor()
    
    if author:isBot() then return end
    if author == botAPI.me then return end
    --if botAPI:isFromOwner(message) then return end

    local authorID = tostring(author:getID())

    local content = message:getContent():lower()

    local owoCount, nextPos = 0, 1

    for _, pattern in pairs(owoPatterns) do
        local spos, epos = content:find(pattern, nextPos)
        while spos do
            local owo = content:sub(spos, epos)
            if content:sub(spos-4, epos) == "antiowo" then
                --message:addReaction("eyes")
                return
            end

            local usage = dataStorage["plugins/antiowo/usage"]
            usage[owo] = math.min((usage[owo] or 0) + 1, 446744073709551615)
            dataStorage["plugins/antiowo/usage"] = usage

            owoCount, nextPos = owoCount + 1, epos
            spos, epos = content:find(pattern, nextPos)
        end
    end

    if owoCount > 0 then
        local penalties = dataStorage["plugins/antiowo/penalties"]
        penalties[authorID] = (penalties[authorID] or 0) + penalty*owoCount
        dataStorage["plugins/antiowo/penalties"] = penalties

        penaltyEmbed:setTitle("**$"..penalties[authorID].." PENALTY**")
        penaltyEmbed:setDescription("for "..tostring(author).." to pay!")

        message:getReplyChannel():send(nil, penaltyEmbed)
    end
end

plugin.events.MESSAGE_UPDATE = plugin.events.MESSAGE_CREATE

return plugin