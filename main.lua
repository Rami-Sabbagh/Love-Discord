--LÖVE Discord, A WIP Discord API Library for LÖVE framework and LuaJIT
local botAPI = require("bot")

function love.load()
	print("Initializing BOT")
	botAPI:initialize()
end

function love.update(dt)
	botAPI:update(dt)
end

function love.quit()
	botAPI:quit("event")
end