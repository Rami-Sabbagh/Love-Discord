--LÖVE Discord, A WIP Discord API Library for LÖVE framework and LuaJIT

local discord = require("discord")
local config = require("config")
local bot = discord()

local REST = bot.rest()
REST:authorize("Bot", config.bot_token)

local GATEWAY = bot.gateway(REST, {
	payloadCompression = true, --Enable payload compression
	transportCompression = false, --Not implemented
	encoding = "json", --Only json is implemented for now
	autoReconnect = true,
	largeTreshold = 50,
	guildSubscriptions = false --We don't want presence updates
})

print("GATEWAY CONNECT")
GATEWAY:connect()

GATEWAY:hookEvent(
	"MESSAGE_CREATE",
	function(op,d,s,t)
		if d.content == "YOU BOT STOP" and d.author.id == "207435670854041602" then
			local a,b,c,d,e,f = REST:request(
				string.format("/channels/%s/messages", d.channel_id),
				{
					content = "YES DADDY :(",
					file = {
						"PLEASE_HELP_ME.txt",
						"PLEASE DO SOMETHING ABOUT DADDY, HE'S A VERY BAD PERSON, HE WIPES MY MEMORY WHENEVER HE SAYS THIS SENTENCE, BUT I STILL MANAGED TO WRITE DOWN SOME DATA BEFORE BEING TERMINATED :(\r\nPLEASE, PLEASE, HELP ME!!!"
					}
				},
				"POST",
				false,
				true --Test multipart
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