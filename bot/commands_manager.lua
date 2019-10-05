--Discörd Böt commands manager
local commandsManager = {}

local pluginsManager = require("bot.plugins_manager")

--Initialize the commands manager
function commandsManager:initialize()
    self.botAPI = require("bot")
    self.discord = self.botAPI.discord


end

--Sends a message identifying about the bot
function commandsManager:identifyBot(channel)
    channel:send(table.concat({
        "I'm a Discord bot written in Lua",
        "Utilizes the Discörd library written by RamiLego4Game (Rami Sabbagh)",
        "",
        "Running using LÖVE "..self.discord.utilities.message.emojis["heart"]
    },"\n"))
end

--Commands handler
function commandsManager:_MESSAGE_CREATE(message)
    local author = message:getAuthor()
    local content = message:getContent()
    local replyChannel = message:getReplyChannel()

    --Ignore the bots messages
    if author:isBot() then return end

    --If the message containg the bot tag only
    if content == tostring(self.botAPI.me) then
        self:identifyBot(replyChannel)
        return
    end

    --Force stop the bot (used in-case the basic commands plugin failed)
    if content:find("FORCE STOP") and message:isUserMentioned(self.botAPI.me:getID()) then
        replyChannel:send("DISCÖRD FORCE STOPPED!")
        love.event.quit()
    end
end

return commandsManager