--Discörd Böt commands manager
local commandsManager = {}

local pluginsManager = require("bot.plugins_manager")
local dataStorage = require("bot.data_storage")

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
    print("Sending the about bot message...")

    local ok, err = pcall(channel.send, channel, table.concat({
        "I'm a Discord bot written and operating in Lua :full_moon_with_face:",
        "Utilizes the Discörd library :books: written by RamiLego4Game (Rami Sabbagh) :sunglasses:",
        "Running using LÖVE :heart:"
    },"\n"))

    if ok then print("Sent then about bot message successfully!") else
        print("Failed to send about bot message:",err) end
end

--Commands handler
function commandsManager:_MESSAGE_CREATE(message)
    local author = message:getAuthor()
    local authorID = author:getID()
    local content = message:getContent()
    local replyChannel = message:getReplyChannel() --A channel object for only sending a reply message, it can't be used to tell anything about the channel (except the ID)

    --Ignore self messages
    if author == self.botAPI.me then return end

    --Ignore the bots messages
    if author:isBot() then return end

    --If the message containg the bot tag only
    if content:match("^<@!?%d+>$") and message:isUserMentioned(self.botAPI.me) then
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
        print("Sending abort message...")
        local ok, err = pcall(replyChannel.send, replyChannel, tostring(self.botAPI.me) .. " has been force stopped :octagonal_sign:")
        if ok then print("Sent abort message successfully!") else print("Failed to send abort message:", err) end

        self.discord:disconnect()
        self.botAPI:quit()
    end


end

return commandsManager