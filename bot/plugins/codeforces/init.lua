--Codeforces plugin
local botAPI, discord, pluginName, pluginPath, pluginDir = ...

local plugin = {}

--== Plugin Meta ==--

plugin.name = "Codeforces" --The visible name of the plugin
plugin.icon = ":bar_chart:" --The plugin icon to be shown in the help command
plugin.version = "V0.0.1" --The visible version string of the plugin
plugin.description = "Useful commands for Codeforces users." --The description of the plugin
plugin.author = "Rami#8688" --Usually the discord tag of the author, but could be anything else
plugin.authorEmail = "ramilego4game@gmail.com" --The email of the auther, could be left empty

--== Commands ==--

plugin.commands = {}; local commands = plugin.commands

do
    local usageEmbed = discord.embed()
    usageEmbed:setTitle("cf_contests")
    usageEmbed:setDescription("Work in progress :warning:")

    local function compareContests(c1, c2)
        return c1.relativeTimeSeconds > c2.relativeTimeSeconds
    end

    function commands.cf_contests(message, reply, commandName, ...)
        if commandName == "?" then reply:send(false, usageEmbed) return end --Triggered using the help command
        
        local data, err = discord.utilities.http.request("https://codeforces.com/api/contest.list")
        if not data then error(err) end
        if data.status ~= "OK" then error(discord.json:encode_pretty(data)) end

        local contests = {}

        for _, contest in ipairs(data.result) do
            if contest.phase == "BEFORE" or contest.phase == "CODING" then
                table.insert(contests, contest)
            end
        end

        table.sort(contests, compareContests)

        local replyEmbed = discord.embed()
        replyEmbed:setAuthor("Codeforces", "https://codeforces.com", "https://cdn.discordapp.com/attachments/667745243717828663/699234756843274260/favicon.png")
        replyEmbed:setTitle("Available contests:")

        for i=1, math.min(#contests, 25) do
            local contest = contests[i]

            local remainingTime = math.abs(contest.relativeTimeSeconds)
            remainingTime = string.format("%d:%d:%d",
                math.floor(remainingTime/3600),
                math.floor(remainingTime/60)%60,
                remainingTime%60
            )

            local duration = string.format("%dh %dm %ds",
                math.floor(contest.durationSeconds/3600),
                math.floor(contest.durationSeconds/60)%60,
                contest.durationSeconds%60
            )

            replyEmbed:setField(i, contest.name, string.format(table.concat({
                    "ID: `%d`",
                    "Phase: `%s`",
                    "Frozen: `%s`",
                    contest.relativeTimeSeconds < 0 and "Until start: `%s`" or "Since start: `%s`",
                    "Duration: `%s`"
                }, "\n"),
                contest.id,
                contest.phase,
                tostring(contest.frozen),
                remainingTime,
                duration
            ))
        end

        reply:send(false, replyEmbed)
    end
end

return plugin