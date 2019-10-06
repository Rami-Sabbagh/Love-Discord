--Discörd Böt commands manager
local commandsManager = {}

local pluginsManager = require("bot.plugins_manager")
local dataStorage = require("bot.data_storage")

--Initialize the commands manager
function commandsManager:initialize()
    self.botAPI = require("bot")
    self.discord = self.botAPI.discord

    self.defaultPrefix = self.botAPI.config.bot.prefix or "."

    --Hook self event
    local hooks = {"MESSAGE_CREATE"}
    for _, hookName in pairs(hooks) do
        local selfFunc = self["_"..hookName]
        local hookFunc = function(...)
            return selfFunc(self, ...)
        end
        self.discord:hookEvent(hookName, hookFunc)
    end

    self.unknownEmojis = {
        "question", "grey_question", "thinking",
        --[["GWchadThink:366999782348292108",
        "GWchadThinkeyes:366999794117246976",
        "GWchadThonkery:366999788803325952",
        "GWlulurdWaitWhat:402868030918492160",
        "GWmythiBlobCool:388310072264228865"]]
    }

    self:reloadCommands()
end

--Reloads the commands list from plugins
function commandsManager:reloadCommands()
    --A merged list of commands
    self.commands = {}

    local plugins = pluginsManager:getPlugins()
    for pluginName, plugin in pairs(plugins) do
        if plugin.commands then
            for commandName, commandFunc in pairs(plugin.commands) do
                if self.commands[commandName] then print("WARNING /!\\ Conflicting command",commandName,"in",pluginName) end
                self.commands[commandName] = commandFunc
            end
        end
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
    local channelID = message:getChannelID()
    local content = message:getContent()
    local guildID = message:getGuildID()
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
        love.event.quit()
        return
    end

    local prefixData = dataStorage["commands_manager/prefix"]

    --Parse the command prefix

    --List the possible prefixes
    local prefixes = {
        prefixData[tostring(guildID or "").."_"..tostring(channelID)] or prefixData[tostring(guildID)] or self.defaultPrefix,
        self.botAPI.me:getTag().." ",
        self.botAPI.me:getNickTag().." ",
        (not guildID and "") --DMs don't need a prefix
    }

    --Check if any prefix is match, and strip it if so, otherwise return
    for id, prefix in ipairs(prefixes) do
        if prefix and content:sub(1,#prefix) == prefix then content = content:sub(#prefix+1, -1) break end
        if id == #prefixes then return end --Didn't match any
    end

    --Parse the command syntax
    local command, nextPos, spos, epos = {}, 1, content:find("%S+", nextPos)
    if spos > 1 then return end --There's whitespace between the prefix and the actual command
    while spos do
        local substr = content:sub(spos, epos)
        if not substr:find("`") then
            command[#command + 1], nextPos = substr, epos + 2
        else
            local blockS, blockE = content:find("```%a+%c+.-```", spos)
            if blockS then --Multiline block in multiple lines
                local prestr = content:sub(spos, blockS-1)
                if #prestr ~= "" then command[#command + 1] = prestr end

                local headerS, headerE = content:find("```%a*%c", blockS)
                command[#command + 1], nextPos = content:sub(headerE+1, blockE-4), blockE + 1

            else
                local blockS, blockE = content:find("```.-```", spos) --Multiline block in a single line
                if blockS then command[#command + 1], nextPos = content:sub(blockS+3, blockE-3), blockE + 1
                else local boxS, boxE = content:find("`.-`", spos)
                    if boxS then
                        local prestr = content:sub(spos, boxS-1)
                        if #prestr ~= "" then command[#command + 1] = prestr end

                        command[#command + 1], nextPos = content:sub(boxS+1, boxE-1), boxE + 1
                    else
                        command[#command + 1], nextPos = substr, epos + 2
                    end
                end
            end
        end

        spos, epos = content:find("%S+", nextPos)
    end

    if #command == 0 then return end --Empty command, shouldn't happen

    --Commands statistics
    --Even invalid commands are logged, why, because it would be interesting to see what people try to do

    local commandStatistics = dataStorage["commands_manager/command_statistics"]
    local usageStatistics = dataStorage["commands_manager/usage_statistics"]

    commandStatistics[command[1]] = (commandStatistics[command[1]] or 0) + 1
    local usage = message:getContent() --We're going to store the whole original message content
    usageStatistics[usage] = (usageStatistics[usage] or 0) + 1

    dataStorage["commands_manager/command_statistics"] = commandStatistics
    dataStorage["commands_manager/usage_statistics"] = usageStatistics

    --Command execution
    local commandName = string.lower(command[1])
    
    if self.commands[commandName] then
        local ok, err = pcall(self.commands[commandName], message, replyChannel, unpack(command))
        if not ok then
            local crashReports = dataStorage["commands_manager/crash_reports"]
            local crashID = tostring(os.time())
            local traceback = debug.traceback(err or "unknown error") or err or "unknown error"
            local report = "Command: "..message:getContent().."\n"..traceback

            crashReports[crashID] = report
            dataStorage["commands_manager/crash_reports"] = crashReports

            print("/!\\ Failed to execute command (", id, "):", report)

            pcall(replyChannel.send, replyChannel, table.concat({
                "**Failed to execute command** :warning:",
                "The crash has been reported to the developers with id: `"..crashID.."`",
                "Crash details:",
                "||```",
                report,
                "```||"
            },"\n"))
        end
    else
        local r = math.random(1, #self.unknownEmojis)
        local e = self.unknownEmojis[r]

        pcall(message.addReaction, message, e)
    end
end

return commandsManager