--Basic operations plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local dataStorage = require("bot.data_storage")
local rolesManager = require("bot.roles_manager")
local pluginsManager = require("bot.plugins_manager")
local commandsManager = require("bot.commands_manager")

local plugin = {}

--== Plugin Meta ==--

plugin.name = "Settings" --The visible name of the plugin
plugin.icon = ":gear:" --The plugin icon to be shown in the help command
plugin.version = "V1.0.0" --The visible version string of the plugin
plugin.description = "Allows the configuration of the bot for each guild and channel." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

--Shared embed, could be used by any command
local adminEmbed = discord.embed()
adminEmbed:setTitle("You need to have administrator permissions to use this command :warning:")

plugin.commands = {}; local commands = plugin.commands

--Prefix command
do
    local prefixHelpDM = discord.embed()
    prefixHelpDM:setTitle("Usage: :notepad_spiral:")
    prefixHelpDM:setDescription(table.concat({
        "```css",
        "prefix channel <new_prefix>",
        "prefix clear channel",
        "```"
    },"\n"))

    local prefixHelp = discord.embed(prefixHelpDM:getAll())
    prefixHelp:setDescription(table.concat({
        "```css",
        "prefix channel <new_prefix>",
        "prefix guild <new_prefix>",
        "prefix clear channel",
        "prefix clear guild",
        "```"
    },"\n"))

    local showPrefix = discord.embed()
    showPrefix:setTitle("You need to have administrator permissions to set the prefix :warning:")
    showPrefix:setDescription("But you can use this command to check the prefix set :wink:")

    local replyEmbed = discord.embed()

    function commands.prefix(message, reply, commandName, level, newPrefix)
        local prefixData = dataStorage["commands_manager/prefix"]
        
        if not rolesManager:isFromAdmin(message) then
            local guildPrefix = prefixData[tostring(guildID)]
            local channelPrefix = prefixData[tostring(guildID or "").."_"..tostring(message:getChannelID())]
            showPrefix:setField(1, "Guild's Prefix:", guildPrefix and "`"..guildPrefix.."`" or "default (`"..commandsManager.defaultPrefix.."`)", true)
            showPrefix:setField(2, "Channel's Prefix:", channelPrefix and "`"..channelPrefix.."`" or "not set", true)
            reply:send(false, showPrefix)
            return
        end

        local guildID = message:getGuildID()

        if guildID then
            local guildPrefix = prefixData[tostring(guildID)]
            local channelPrefix = prefixData[tostring(guildID or "").."_"..tostring(message:getChannelID())]
            prefixHelp:setField(1, "Guild's Prefix:", guildPrefix and "`"..guildPrefix.."`" or "default (`"..commandsManager.defaultPrefix.."`)", true)
            prefixHelp:setField(2, "Channel's Prefix:", channelPrefix and "`"..channelPrefix.."`" or "not set", true)
        else
            local channelPrefix = prefixData["_"..tostring(message:getChannelID())]
            prefixHelpDM:setField(1, "DM Channel's Prefix:", channelPrefix and "`"..channelPrefix.."`" or "default (no prefix)")
        end

        if not (level and newPrefix) then reply:send(false, guildID and prefixHelp or prefixHelpDM) return end

        local prefixType

        if level == "clear" then
            if newPrefix == "guild" and not guildID or (newPrefix ~= "guild" and newPrefix ~= "channel") then
                reply:send(false, guildID and prefixHelp or prefixHelpDM) return end
            prefixType = newPrefix
        else
            if level == "guild" and not guildID or (level ~= "guild" and level ~= "channel") then
                reply:send(false, guildID and prefixHelp or prefixHelpDM) return end
            prefixType = level
        end

        local prefixKey = (prefixType == "guild") and tostring(guildID) or tostring(guildID or "").."_"..tostring(message:getChannelID())

        if level == "clear" then
            prefixData[prefixKey] = nil
            replyEmbed:setTitle("The "..newPrefix.."'s commands prefix has been cleared successfully :white_check_mark:")
            reply:send(false, replyEmbed)
        else
            prefixData[prefixKey] = newPrefix
            replyEmbed:setTitle(level:sub(1,1):upper()..level:sub(2,-1).."'s commands prefix has been set to `"..newPrefix.."` successfully :white_check_mark:")
            reply:send(false, replyEmbed)
        end

        dataStorage["commands_manager/prefix"] = prefixData
    end
end

--Plugins command
do
    local pluginsAdminUsage = discord.embed()
    pluginsAdminUsage:setTitle("Admin Usage: :notepad_spiral:")
    pluginsAdminUsage:setDescription(table.concat({
        "```css",
        "plugins <guild/channel> enable <plugin_id>",
        "  /* enables a specific plugin for this guild/channel */",
        "plugins <guild/channel> disable <plugin_id>",
        "  /* disables a specific plugin for this guild/channel */",
        "plugins channel clear <plugin_id>",
        "  /* clears the plugin state override for this channel */",
        "plugins <guild/channel> enable all",
        "  /* enables all plugins for this guild/channel */",
        "plugins <guild/channel> disable all",
        "  /* disables all plugins for this guild/channel */",
        "plugins channel clear <plugin_id>",
        "  /* clears all the plugins states override for this channel */",
        "plugins list /* lists all available plugins */",
        "plugins list <guild/channel>",
        "  /* lists the state of each plugin for this guild/channel */",
        "```"
    },"\n"))

    local pluginsDMUsage = discord.embed()
    pluginsDMUsage:setTitle("DM Usage: :notepad_spiral:")
    pluginsDMUsage:setDescription(table.concat({
        "```css",
        "plugins channel enable <plugin_id>",
        "  /* enables a specific plugin for this DM channel */",
        "plugins channel disable <plugin_id>",
        "  /* disables a specific plugin for this DM channel */",
        "plugins channel enable all",
        "  /* enables all plugins for this DM channel */",
        "plugins channel disable all",
        "  /* disables all plugins for this DM channel */",
        "plugins list /* lists all available plugins */",
        "plugins list channel",
        "  /* lists the state of each plugin for this DM channel */",
        "```"
    },"\n"))

    local pluginsUserUsage = discord.embed()
    pluginsUserUsage:setTitle("User Usage: :notepad_spiral:")
    pluginsUserUsage:setDescription(table.concat({
        "You need administrator permissions to enable/disable plugins,\nBut you could still check the available plugins list :wink:",
        "```css",
        "plugins list /* lists all available plugins */",
        "plugins list <guild/channel>",
        "  /* lists the state of each plugin for this guild/channel */",
        "```"
    },"\n"))

    local availablePluginsEmbed = discord.embed()
    availablePluginsEmbed:setTitle("Available Plugins: :tools:")

    local resultEmbed = discord.embed()

    function commands.plugins(message, reply, commandName, arg1, arg2, arg3)
        local isAdmin = rolesManager:isFromAdmin(message)
        local isDM = not message:getGuildID()

        local showHelp = (((arg1 ~= "guild" or isDM) and arg1 ~= "channel") or not isAdmin) and arg1 ~= "list"
        if not showHelp and arg1 ~= "list" and arg2 ~= "enable" and arg2 ~= "disable" and (isDM or arg1 == "channel" and arg2 ~= "clear") then showHelp = true end
        if not showHelp and arg1 == "list" and arg2 and (arg2 ~= "guild" or isDM) and arg2 ~= "channel" then showHelp = true end
        if not showHelp and arg1 ~= "list" and not arg3 then showHelp = true end

        if showHelp then reply:send(false, isAdmin and (isDM and pluginsDMUsage or pluginsAdminUsage) or pluginsUserUsage) return end

        local plugins = pluginsManager:getPlugins()
        local guildID, channelID = message:getGuildID(), message:getChannelID()

        if arg1 == "list" then
            if not arg2 then
                --List the available plugins
                local availablePlugins = {}
                for k,v in pairs(plugins) do table.insert(availablePlugins, "• `"..k.."`: "..(v and v.description or "no description")..".") end
                availablePlugins = table.concat(availablePlugins, "\n")
                availablePluginsEmbed:setDescription(availablePlugins)

                reply:send(false, availablePluginsEmbed)
            else
                local guildPlugins, channelPlugins = pluginsManager:getDisabledPlugins(guildID, channelID)

                local list = {}
                for pluginName, plugin in pairs(plugins) do
                    local state, override = false, false
                    if type(channelPlugins[pluginName]) ~= "nil" and arg2 ~= "guild" then state, override = channelPlugins[pluginName], not isDM
                    else state = guildPlugins[pluginName] end
                    table.insert(list, "• `"..pluginName.."`: "..(state and "disabled ✕" or "enabled ✓")..(override and " (overrides guild)" or ""))
                end
                list = table.concat(list, "\n")

                availablePluginsEmbed:setDescription(list)
                reply:send(False, availablePluginsEmbed)
            end
        else
            --Enable/Disable commands
            local key = (arg1 == "guild" and tostring(guildID) or tostring(guildID or "").."_"..tostring(channelID))
            local disabledPlugins = dataStorage["bot/disabled_plugins"]
            disabledPlugins[key] = disabledPlugins[key] or {}
            local pluginsList = disabledPlugins[key]

            local targetState = (arg2 == "disable")
            local action = targetState and "Disabled" or "Enabled"
            if arg2 == "clear" then targetState, action = nil, "Cleared" end

            if arg3 == "all" then
                for pluginName, plugin in pairs(plugins) do
                    pluginsList[pluginName] = targetState and pluginName ~= "settings"
                end

                dataStorage["bot/disabled_plugins"] = disabledPlugins
                resultEmbed:setTitle(action.." all plugins at "..arg1.." level successfully :white_check_mark:")
                if action == "Cleared" then resultEmbed:setTitle(action.." all plugins states overrides successfully :white_check_mark:") end
            else
                if not plugins[arg3] then
                    resultEmbed:setTitle("Plugin `"..arg3.."` doesn't exist:exclamation:")
                elseif arg3 == "settings" and arg2 == "disable" then
                    resultEmbed:setTitle("The settings plugin can't be disabled:exclamation:")
                else
                    pluginsList[arg3] = targetState
                    dataStorage["bot/disabled_plugins"] = disabledPlugins
                    resultEmbed:setTitle(action.." `"..arg3.."` plugin at "..arg1.." level successfully :white_check_mark:")
                    if action == "Cleared" then resultEmbed:setTitle(action.." `"..arg3.."` plugin state override successfully :white_check_mark:") end
                end
            end

            reply:send(false, resultEmbed)
        end
    end
end

--== Plugin Events ==--

plugin.events = {}; local events = plugin.events

return plugin