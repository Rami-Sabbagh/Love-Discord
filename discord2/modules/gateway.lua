--Discord Gateway system

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.
local json = discord.json --JSON library.
local websocket = discord.websocket --lua-websocket library.
local url_utils = require("socket.url") --LuaSocket url utilities.
local http_utils = discord.utilities.http --HTPP utilities.

local gateway = class("discord.modules.Gateway")

--Create a new instance
function gateway:initialize(rest)
    self.rest = rest
    if not self.rest.tokenType then error("The REST API has to be authorized first!") end

    --The version of the gateway
    self.version = 6
    self.encoding = "json" --TODO: Add ETF support
    self.compress = false --TODO: Add zlib-stream compression support

    self.websocket_params = {
        mode = "client",
        protocol = "any",
        verify = "none",
        options = {"all", "no_sslv2", "no_sslv3"}
    }

    self.json_options = { null = "\0" } --Passed into JSON:encode(v,nil,options)
end

--Tells if this is a bot gateway
function gateway:isBot()
    return (self.rest.tokenType == "Bot") --Just check the token type
end

--Updates the gateway connection information
--Returns true on success, otherwise false and failure reason.
function gateway:updateEndpoint()
    --TODO: Close existing websocket and reconnect
    if self.websocket then error("TODO") end

    local gatewayInfo, failure = self:_getGateway()
    if not gatewayInfo then return false, failure end

    self.gatewayInfo = gatewayInfo
    self.gatewayURL = self.gatewayInfo.url

    return true
end

--Connect to the gateway
--Returns true on success, otherwise false and failure reason.
function gateway:connect()
    if self.websocket then return error("Already connected!") end

    --Get the gateway url
    if not self.gatewayURL then
        local ok, err = self:updateEndpoint()
        if not ok then return false, err end
    end

    local client = websocket.client.async() --Create a new websocket client

    --Add in query options
    local socketURL = url_utils.parse(self.gatewayURL)
    local socketQuery = {v=self.version, encoding=self.encoding}
    if self.compress then socketQuery.compress = self.compress end
    socketURL.query = socketQuery
    socketURL = url_utils.build(socketURL)

    --Connect to the websocket
    local ok, err = client:connect(socketURL, false, self.websocket_params)
    if not ok then return false, err end

    --The websocket is now connected and ready for usage!
    self.websocket = client
end

--== Internal Methods ==--

--Internal method, returns the information of the Gateway to use.
--Returns gateway information on success, otherwise false and failure reason on failure.
function gateway:_getGateway()
    --TODO: Cache the gateway url for Bearer tokens.
    local isBot = self:isBot()
    local gatewayInformation, failure_reason = self.rest:request(isBot and "/gateway/bot" or "/gateway")
    return gatewayInformation, failure_reason
end

return gateway