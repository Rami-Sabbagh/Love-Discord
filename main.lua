--LÖVE Discord, A WIP Discord API Library for LÖVE framework and LuaJIT

local bot = require("bot")

function love.load()
  bot.initialize()
end

function love.update(dt)
  bot.update(dt)
end