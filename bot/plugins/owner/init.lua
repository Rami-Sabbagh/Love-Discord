--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local ffi = require("ffi")
local dataStorage = require("bot.data_storage")
local pluginsManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")

local plugin = {}

--== Plugin Meta ==--

plugin.name = "Owner" --The visible name of the plugin
plugin.icon = ":radio_button:" --The plugin icon to be shown in the help command
plugin.version = "V2.1.0" --The visible version string of the plugin
plugin.description = "Contains commands available only to the owners of the bot." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

--Shared embed, could be used by any command
local ownerEmbed = discord.embed()
ownerEmbed:setTitle("This command could be only used by the bot's owners :warning:")

plugin.commands = {}; local commands = plugin.commands

--Reload command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("reload")
    usageEmbed:setDescription("Reloads the bot plugins.")
    usageEmbed:setField(1, "Usage: :notepad_sprial:", "```css\nreload\n```")

    local reloadEmbedSuccess = discord.embed()
    reloadEmbedSuccess:setTitle("Reloaded successfully :white_check_mark:")
    local reloadEmbedFailure = discord.embed()
    reloadEmbedFailure:setTitle("Failed to reload :warning:")

    function commands.reload(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end

        local ok, err = pluginsManager:reload()
        if ok then
            commandsManager:reloadCommands()
            reply:send(false, reloadEmbedSuccess)
        else
            reloadEmbedFailure:setDescription("||```\n"..err:gsub("plugin: ","plugin:\n").."\n```||")
            reply:send(false, reloadEmbedFailure)
        end
    end
end

--Stop command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("stop")
    usageEmbed:setDescription("Terminates the bot's process.")
    usageEmbed:setField(1, "Usage: :notepad_sprial:", "```css\nstop\n```")

    function commands.stop(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end
        reply:send("Goodbye :wave:")
        love.event.quit()
    end
end

--Restart command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("restart")
    usageEmbed:setDescription("Restarts the bot's process.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\nrestart\n```")

    local restartEmbed = discord.embed()
    restartEmbed:setTitle(":gear: Restarting :gear:")
    restartEmbed:setDescription("This might take a while...")
    function commands.restart(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end

        love.event.quit("restart")

        local pdata = dataStorage["plugins/basic/restart"]
        pdata.channelID = tostring(message:getChannelID())
        pdata.timestamp = os.time()
        dataStorage["plugins/basic/restart"] = pdata

        reply:send(false, restartEmbed)
    end
end

--Dumpdata command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("dumpdata")
    usageEmbed:setDescription("Dumps the storage data for the requested package.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\ndumpdata <package_name>\n```")

    function commands.dumpdata(message, reply, commandName, dname)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end
        if not dname then reply:send(false, usageEmbed) return end

        local data = discord.json:encode_pretty(dataStorage[dname])
        local message = table.concat({
            "```json",
            data,
            "```"
        },"\n")
        
        if #message > 2000 then
            reply:send("Data too large, uploaded in a file :wink:", false, {dname:gsub("/","_")..".json",data})
        else
            reply:send(message)
        end
    end
end

--Execute command
do
    local executeUsage = discord.embed()
    executeUsage:setTitle("execute")
    executeUsage:setDescription("Executes Lua code under the bot's environment.")
    executeUsage:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "execute <lua_code_block> [no_log]",
        "execute `[ATTACHMENT]` [no_log]",
        "  /* Execute code from the first attached file */",
        "```"
    },"\n"))

    local errorEmbed = discord.embed()
    errorEmbed:setTitle("Failed to execute lua code :warning:")

    local outputEmbed = discord.embed()
    outputEmbed:setTitle("Executed successfully :white_check_mark:")

    function commands.execute(message, reply, commandName, luaCode, nolog, ...)
        if commandName == "?" then reply:send(false, executeUsage) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end
        if not luaCode then reply:send(false, executeUsage) return end

        if luaCode == "[ATTACHMENT]" then
            local attachment = message:getAttachments()[1]
            local fileURL = attachment:getURL()

            local respondBody, httpErr = discord.utilities.http.request(fileURL)
            if not respondBody then
                errorEmbed:setField(1, "Download Error:", "```\n"..httpErr.."\n```")
                reply:send(false, errorEmbed)
                return
            end

            luaCode = respondBody
        end

        local chunk, err = loadstring(luaCode, "codeblock")
        if not chunk then
            errorEmbed:setField(1, "Compile Error:", "```\n"..err:gsub('%[string "codeblock"%]', "").."\n```")
            reply:send(false, errorEmbed)
            return
        end

        local showOutput = false
        local output = {"```"}

        local env = {}
        local superEnv = _G
        setmetatable(env, { __index = function(t,k) return superEnv[k] end })

        env.botAPI, env.discord = botAPI, discord
        env.json = discord.json
        env.pluginsManager, env.commandsManager, env.dataStorage = pluginsManager, commandsManager, dataStorage
        env.message, env.reply = message, reply
        env.bit, env.http, env.rest = discord.utilities.bit, discord.utilities.http, discord.rest
        env.band, env.bor, env.lshift, env.rshift, env.bxor = env.bit.band, env.bit.bor, env.bit.lshift, env.bit.rshift, env.bit.bxor
        env.ffi = ffi
        env.print = function(...)
            local args = {...}; for k,v in pairs(args) do args[k] = tostring(v) end
            local msg = table.concat(args, " ")
            output[#output + 1] = msg
            showOutput = true
        end

        setfenv(chunk, env)

        local ok, rerr = pcall(chunk, ...)
        if not ok then
            errorEmbed:setField(1, "Runtime Error:", "```\n"..rerr:gsub('%[string "codeblock"%]', "").."\n```")
            reply:send(false, errorEmbed)
            return
        end

        local outputFile
        if showOutput then
            env.print("```")
            local outputString = table.concat(output, "\n")
            if #outputString > 2048 then
                outputFile = outputString:sub(5,-5)
                outputEmbed:setField(1, "Output:", "Output too large, uploaded in a file :wink:")
            else
                outputEmbed:setField(1, "Output:", outputString)
            end
        else
            outputEmbed:setField(1)
        end

        if tostring(nolog) == "true" then
            if message:getGuildID() then pcall(message.delete, message) end
        else
            reply:send(false, outputEmbed, outputFile and {string.format("output-%d.txt"}, os.time()), outputFile} )
            --reply:send("Data too large, uploaded in a file :wink:", false, {dname:gsub("/","_")..".json",data})
        end
    end
end

--Pulls the bot's git repository
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("gitupdate")
    usageEmbed:setDescription("Updates the bot's internal code from the git repository.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\ngitupdate\n```")

    --Executes a command, and returns it's output
    local function capture(cmd, raw)
        local f = assert(io.popen(cmd, 'r'))
        local s = assert(f:read('*a'))
        f:close()
        if raw then return s end
        s = string.gsub(s, '^%s+', '')
        s = string.gsub(s, '%s+$', '')
        s = string.gsub(s, '[\n\r]+', ' ')
        return s
    end

    function commands.gitupdate(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end
        local output1 = capture("git -C "..love.filesystem.getSource().." add *")
        local output2 = capture("git -C "..love.filesystem.getSource().." checkout -- "..love.filesystem.getSource())
        local output3 = capture("git -C "..love.filesystem.getSource().." pull")
        local fieldsCount = 1
        
        local resultEmbed = discord.embed()
        resultEmbed:setTitle("Execution output: :scroll:")
        if output1 ~= "" then resultEmbed:setField(fieldsCount, "Git Add:", "` "..output1:gsub("\n", " `\n` ").." `"); fieldsCount = fieldsCount + 1 end
        if output2 ~= "" then resultEmbed:setField(fieldsCount, "Git Checkout:", "` "..output2:gsub("\n", " `\n` ").." `"); fieldsCount = fieldsCount + 1 end
        if output3 ~= "" then resultEmbed:setField(fieldsCount, "Git Pull:", "` "..output3:gsub("\n", " `\n` ").." `"); fieldsCount = fieldsCount + 1 end
        reply:send(false, resultEmbed)
    end
end

--CMD command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("cmd")
    usageEmbed:setDescription("Executes a shell command under the bot's host system.")
    usageEmbed:setField(1, "Usage: :notepad_sprial:", "```css\ncmd <command> [...]\n```")

    --Executes a command, and returns it's output
    local function capture(cmd, raw)
        local f = assert(io.popen(cmd, 'r'))
        local s = assert(f:read('*a'))
        f:close()
        if raw then return s end
        s = string.gsub(s, '^%s+', '')
        s = string.gsub(s, '%s+$', '')
        s = string.gsub(s, '[\n\r]+', ' ')
        return s
    end

    local resultEmbed = discord.embed()
    resultEmbed:setTitle("Execution output: :scroll:")

    function commands.cmd(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end
        local cmd = table.concat({...}, " ")
        local output = capture(cmd)
        resultEmbed:setDescription("```\n"..output.."\n```")
        reply:send(false, resultEmbed)
    end
end

--== Plugin Events ==--

plugin.events = {}; local events = plugin.events

do
    local restartedEmbed = discord.embed()
    restartedEmbed:setTitle("Restarted Successfully :white_check_mark:")

    function events.READY(data)
        local pdata = dataStorage["plugins/basic/restart"]
        if pdata.channelID then
            local replyChannel = discord.channel{
                id = pdata.channelID,
                type = discord.enums.channelTypes["GUILD_TEXT"]
            }

            local delay = os.time() - pdata.timestamp
            restartedEmbed:setDescription("Operation took "..delay.." seconds:stopwatch:")

            pdata.channelID = nil
            pdata.timestamp = nil
            dataStorage["plugins/basic/restart"] = pdata

            pcall(replyChannel.send, replyChannel, false, restartedEmbed)
        end
    end
end

return plugin