--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local rolesManager = require("bot.roles_manager")
local commandsManager = require("bot.commands_manager")
local pluginsManager = require("bot.plugins_manager")

local plugin = {}

--== Plugin Meta ==--

plugin.name = "Basic" --The visible name of the plugin
plugin.icon = ":books:" --The plugin icon to be shown in the help command
plugin.version = "V2.0.0" --The visible version string of the plugin
plugin.description = "Handles basic operations." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

--Shared embed, could be used by any command
local adminEmbed = discord.embed()
adminEmbed:setTitle("You need to have administrator permissions to use this command :warning:")

plugin.commands = {}; local commands = plugin.commands

--Help command, lists available commands and could request help for each command or plugin
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("help")
    usageEmbed:setDescription("Provides information about the available plugins and their commands usage.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "help /* Provides a list of available plugins and some information about the bot */",
        "help <pluginName> /* Provides more information about the requested plugin and it's command list */",
        "help <commandName> /* Provides the usage information of the requested command */",
        "```"
    }, "\n"))

    local notFoundEmbed = discord.embed()
    notFoundEmbed:setTitle("Command/Plugin doesn't exist :warning:")

    local mainEmbed = discord.embed()
    mainEmbed:setFooter("Use |help help| for more information on how to use this command.")

    function commands.help(message, reply, commandName, arg1)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command

        --Provide help about a plugin or a command
        if arg1 then
            local commands = commandsManager:getCommands()

            --Plugin help
            local plugins = pluginsManager:getPlugins()
            for internalName, p in pairs(plugins) do
                if (internalName == arg1 and not commands[arg1:lower()]) or p.name == arg1 then
                    local pluginEmbed = discord.embed()
                    pluginEmbed:setTitle(p.name.." "..p.icon)
                    pluginEmbed:setDescription(p.description)
                    pluginEmbed:setField(1, "Version:", p.version)

                    local pCommands = p.commands
                    if pCommands then
                        local clist = {}
                        for k,v in pairs(pCommands) do clist[#clist+1] = k end
                        if #clist > 0 then
                            table.sort(clist)
                            clist = table.concat(clist, ", ")
                            pluginEmbed:setField(2, "Commands:", "```css\n"..clist.."\n```")
                        end
                    end

                    if not pluginEmbed:getField(2) then
                        pluginEmbed:setField(2, "Commands:", "The plugin has no commands :thinking:")
                    end

                    pluginEmbed:setFooter("Plugin by "..p.author:gsub("_", "\\_").." ("..p.authorEmail:gsub("_", "\\_")..")")
                    reply:send(false, pluginEmbed)
                    return
                end
            end

            --Command help
            if commands[arg1:lower()] then
                commands[arg1:lower()](message, reply, "?")
                return
            end

            --Not found
            reply:send(false, notFoundEmbed)
        --Provide the main help embed
        else
            if not mainEmbed:getField(1) then
                local plugins = pluginsManager:getPlugins()
                local plist = {}
                for id, p in pairs(plugins) do
                    plist[#plist + 1] = p.icon.." **"..p.name.."** (ID: _"..id:gsub("_", "\\_").."_)"
                end
                table.sort(plist, function(v1, v2)
                    v1, v2 = v1:gsub("^:.-: ", ""), v2:gsub("^:.-: ", "")
                    return v1 < v2
                end)
                plist = table.concat(plist, "\n")
                mainEmbed:setField(1, "Available Plugins: :tools:", plist)
            end

            reply:send(false, mainEmbed)
        end
    end
end

--Commands command, lists available commands
do
    local commandsEmbed = discord.embed()
    commandsEmbed:setTitle("Available commands: :tools:")

    local usageEmbed = discord.embed()
    usageEmbed:setTitle("commands")
    usageEmbed:setDescription("Provides the list of available commands.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\ncommands\n```")

    local mainEmbed = discord.embed()


    function commands.commands(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command

        if not commandsEmbed:getDescription() then
            local commandsList = {}
            for c in pairs(commandsManager:getCommands()) do commandsList[#commandsList + 1] = c end
            commandsList = table.concat(commandsList, ", ")
            commandsEmbed:setDescription(table.concat({
                "```css",
                commandsList,
                "```"
            }, "\n"))
        end

        reply:send(false, commandsEmbed)
    end
end

--Ping command
do
    local usageEmbed = discord.embed()
    usageEmbed:setDescription(":ping_pong:")

    function commands.ping(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command

        local letterI = commandName:sub(2,2)
        local letterO = (letterI == "I") and "O" or "o"
        local pong = commandName:sub(1,1)..letterO..commandName:sub(3,4)
        local explosion = (pong == "PONG") and " :boom:" or ""
        if pong == "PONG" then pong = "**PONG**" end
        reply:send(pong.." :ping_pong:"..explosion)
    end
end

--Say command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("say")
    usageEmbed:setDescription("Makes the bot send a message, and delete the original command message if allowed.")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", "```css\nsay <content> [...]\n```")

    local everyoneEmbed = discord.embed()
    everyoneEmbed:setTitle("You need to have administrator permissions to mention everyone :warning:")

    function commands.say(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command

        local content = table.concat({...}, " ")
        if content == "" then reply:send(false, usageEmbed) return end
        if content:find("@everyone") and not rolesManager:isFromAdmin(message) then reply:send(false, everyoneEmbed) return end
        reply:send(content)

        if message:getGuildID() then pcall(message.delete, message) end
    end
end

--Embed command
do
    local replyEmbed = discord.embed()
    local embedUsage = discord.embed()
    embedUsage:setTitle("embed")
    embedUsage:setDescription("Makes the bot send a message in an embed format, and delete the original command message if allowed.")
    embedUsage:setField(1, "Usage: :notepad_spiral:", "```css\nembed [title] [description]\n```")

    local everyoneEmbed = discord.embed()
    everyoneEmbed:setTitle("You need to have administrator permissions to mention everyone :warning:")

    function commands.embed(message, reply, commandName, title, description)
        if commandName == "?" then reply:send(false, embedUsage) return end --Triggered using the help command
        if not (title or description) then reply:send(false, embedUsage) return end

        if title and title:find("@everyone") and not rolesManager:isFromAdmin(message) then reply:send(false, everyoneEmbed) return end
        if description and description:find("@everyone") and not rolesManager:isFromAdmin(message) then reply:send(false, everyoneEmbed) return end

        replyEmbed:setTitle(title)
        replyEmbed:setDescription(description)

        reply:send(false, replyEmbed)

        if message:getGuildID() then pcall(message.delete, message) end
    end
end

--Snowflake command
do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("snowflake")
    usageEmbed:setDescription("Decodes the provided snowflake and sends it's information")
    usageEmbed:setField(1, "Usage: :notepad_spiral:", table.concat({
        "```css",
        "snowflake <snowflake> /* Prints snowflake information */",
        "snowflake /* Prints information of self generated snowflake */",
        "```"
    }, "\n"))

    local infoEmbed = discord.embed()
    infoEmbed:setTitle("Snowflake information: :clipboard:")

    function commands.snowflake(message, reply, commandName, sf)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        if not sf then reply:send(false, usageEmbed) return end
        sf = discord.snowflake(sf)

        infoEmbed:setDescription(tostring(sf))

        infoEmbed:setField(1, "Timestamp", sf:getTime(), true)
        infoEmbed:setField(2, "Date/Time", os.date("%c", sf:getTime()), true)
        infoEmbed:setField(3, "Discord Timestamp", sf:getTimeSinceDiscordEpoch(), true)

        infoEmbed:setField(4, "Worker ID:", sf:getWorkerID(), true)
        infoEmbed:setField(5, "Process ID:", sf:getProcessID(), true)
        infoEmbed:setField(6, "Increment:", sf:getIncrement(), true)

        reply:send(false, infoEmbed)
    end
end

--== Plugin Events ==--

plugin.events = {}; local events = plugin.events

return plugin