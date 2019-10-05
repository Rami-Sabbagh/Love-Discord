--LÖVE Discord, A WIP Discord API Library for LÖVE framework and LuaJIT

local discord = require("discord")
local config = require("config")
local bot = discord("Bot", config.bot_token)

local GATEWAY = bot.gateway{
	payloadCompression = true, --Enable payload compression
	transportCompression = false, --Not implemented
	encoding = "json", --Only json is implemented for now
	autoReconnect = true,
	largeTreshold = 50,
	guildSubscriptions = false --We don't want presence updates
}

print("GATEWAY CONNECT")
GATEWAY:connect()

GATEWAY:hookEvent(
	"MESSAGE_CREATE",
	function(op,d,s,t)
		if d.content == "SHOW ME YOUR INFO" and d.author.id == "207435670854041602" then
			local USER = bot.user("@me")
			local info = {}
			for k,v in pairs(USER) do
				if type(v) ~= "function" and k ~= "class" and (type(v) ~= "table" or k == "flags") then
					info[k] = v
				elseif k == "id" then
					info[k] = tostring(v)
				end
			end
			info = bot.json:encode_pretty(info)

			bot.rest:request(
				string.format("/channels/%s/messages", d.channel_id),
				{
					content = "Here's all what I know about him:\n```json\n" .. info .. "\n```"
				}
			)
		end

		if d.content == "YOU BOT STOP" and d.author.id == "207435670854041602" then
			local a,b,c,d,e,f = bot.rest:request(
				string.format("/channels/%s/messages", d.channel_id),
				{
					content = "YES SIR o7"
				}
			)
			print("RESPONSE",a,b,c,d,e,f)
			if type(a) == "table" then
				for k,v in pairs(a) do
					print(k,v)
				end
				print("ATTACHMENTS")
				for k,v in pairs(a.attachments) do
					print(k,v)
				end
			end
			GATEWAY:disconnect()
			love.event.quit()
		end
	end
)

function love.update(dt)
	GATEWAY:update(dt)
end