--Discörd Böt commands manager
local commandsManager = {}

local pluginsManager = require("bot.plugins_manager")

--Initialize the commands manager
function commandsManager:initialize()
    self.botAPI = require("bot")
    self.discord = self.botAPI.discord

    --Hook self event
    local hooks = {"MESSAGE_CREATE"}
    for _, hookName in pairs(hooks) do
        local selfFunc = self["_"..hookName]
        local hookFunc = function(...)
            return selfFunc(self, ...)
        end
        self.discord:hookEvent(hookName, hookFunc)
    end
end

--Sends a message identifying about the bot
function commandsManager:identifyBot(channel)
    channel:send(table.concat({
        "I'm a Discord bot written and operating in Lua :full_moon_with_face:",
        "Utilizes the Discörd library :books: written by RamiLego4Game (Rami Sabbagh) :sunglasses:",
        "Running using LÖVE :heart:"
    },"\n"))
end

--Commands handler
function commandsManager:_MESSAGE_CREATE(message)
    local author = message:getAuthor()
    local authorID = author:getID()
    local content = message:getContent()
    local replyChannel = message:getReplyChannel()

    --Ignore self messages
    if author == self.botAPI.me then return end

    --Ignore the bots messages
    if author:isBot() then return end

    --If the message containg the bot tag only
    if content:match("^<@!?%d+>$") and message:isUserMentioned(self.botAPI.me) then
        print("Sending a message about the bot...")
        self:identifyBot(replyChannel)
        return
    end

    local fromDeveloper = false
    for _, developerID in pairs(self.botAPI.config.bot.developers) do
        if developerID == tostring(authorID) then
            fromDeveloper = true
            break
        end
    end

    --Force stop the bot (used in-case the basic commands plugin failed)
    if fromDeveloper and content:lower():find("force stop") and message:isUserMentioned(self.botAPI.me) then
        replyChannel:send(tostring(self.botAPI.me) .. " has been force stopped :octagonal_sign:")
        love.event.quit()
    end
end

return commandsManager