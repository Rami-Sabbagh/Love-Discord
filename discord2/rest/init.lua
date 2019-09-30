--Discord REST API

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local rest = class("discord.Rest")

--Create a new instance
function rest:initialize()
    rest.version = 6 --The used version of Discord's REST API.
    rest.baseURL = "https://discordapp.com/api/v"..rest.version --The base URL of the used REST API version.


end

--Authorize the REST API
function rest:authorize(tokenType, token)
    self.tokenType = tokenType
    self.token = token
    self.authorization = self.tokenType.." "..self.token
end

return rest