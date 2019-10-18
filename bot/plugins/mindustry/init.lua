--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local socket = require("socket")
local dataStorage = require("bot.data_storage")
local rolesManager = require("bot.roles_manager")

local plugin = {}

local serverCommand = botAPI.config.plugins.mindustry.server_command or error("Please configure the plugin in the bot's config.json file")
local serverFile --Created later using io.popen

--== Plugin Meta ==--

plugin.name = "MinDustry" --The visible name of the plugin
plugin.icon = ":joystick:" --The plugin icon to be shown in the help command
plugin.version = "V0.0.0" --The visible version string of the plugin
plugin.description = "Allows the control of a mindustry server running at the same system of the bot's one." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Shared Embeds ==--

local ownerEmbed = discord.embed()
ownerEmbed:setTitle("This command could be only used by the bot's owners :warning:")

--== Plugin Commands ==--

plugin.commands = {}; local commands = plugin.commands

--Mindustry command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("mindustry")
    usageEmbed:setDescription("Control the mindustry server running on the same machine of the bot.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "mindustry start /* Starts the server */",
        "mindustry kill /* Kills the server process */",
        "mindustry <command_name> [arg1, ...] /* Executes a server command */",
        "```"
    }, "\n"))

    local alreadyRunningEmbed = discord.embed()
    alreadyRunningEmbed:setTitle("The server is already running :warning:")
    
    local startedEmbed = discord.embed()
    startedEmbed:setTitle("The server has been started successfully :white_check_mark:")

    local notRunningEmbed = discord.embed()
    notRunningEmbed:setTitle("The server is not running :warning:")

    local failureEmbed = discord.embed()
    failureEmbed:setTitle("Failed to execute command :warning:")

    local successEmbed = discord.embed()
    successEmbed:setTitle("Executed command successfully :white_check_mark:")

    local closedEmbed = discord.embed()
    closedEmbed:setTitle("The server has been terminated successfully :white_check_mark:")

    function commands.mindustry(message, reply, commandName, action, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered by the help command
        if not botAPI:isFromOwner(message) then reply:send(false, ownerEmbed) return end
        if not action then reply:send(false, usageEmbed) return end

        if action == "start" then
            if serverFile then reply:send(false, alreadyRunningEmbed) return end
            serverFile = io.popen(serverCommand)
            reply:send(false, startedEmbed)
        elseif action == "kill" then
            os.execute("pkill -f 'java.*server'")
            serverFile:close(); serverFile = nil
            reply:send(false, closedEmbed)
        else
            if not serverFile then reply:send(false, notRunningEmbed) return end
            local tcp = socket.tcp()
            tcp:settimeout(action == "host" and 2 or 0.2, "t")
            local ok, err = tcp:connect("127.0.0.1", 6859)
            if not ok then
                failureEmbed:setDescription("Failed to connect into console socket: "..tostring(err))
                reply:send(false, failureEmbed)
                return
            end
            ok, err = tcp:send(table.concat({action, ...}, " ").."\n")
            if not ok then
                failureEmbed:setDescription("Failed to send command: "..tostring(err))
                reply:send(false, failureEmbed)
                return
            end
            local output = {"```\n"}
            while true do
                local ok, err, pdata = tcp:receive()
                if ok then
                    output[#output+1] = ok
                else
                    output[#output+1] = pdata
                    if err ~= "timeout" and action ~= "exit" then output[#output+1] = "Console socket connection terminated: "..tostring(err) end
                    break
                end
            end
            tcp:close() --Make sure the socket is closed
            output = table.concat(output,"\n").."\n```"
            if action == "exit" then serverFile:close(); serverFile = nil end --The server has been shutdown
            if #output <= 1024 then
                successEmbed:setField(1, "Output: :scroll:", output)
                reply:send(false, successEmbed)
            elseif #output < 1024*6 then
                successEmbed:setField(1)
                reply:send(false, successEmbed, {"output.txt", output:sub(5,-5)})
            else
                successEmbed:setField(1,"Output: :scroll:","Output too long to fit in a message or in a file!")
                reply:send(false, successEmbed)
            end
        end
    end
end

return plugin