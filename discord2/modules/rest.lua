--Discord REST API

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.
local http_utils = discord.utilities.http

local rest = class("discord.modules.Rest")

--Create a new instance
function rest:initialize()
    self.version = 6 --The used version of Discord's REST API.
    self.baseURL = "https://discordapp.com/api/v"..self.version --The base URL of the used REST API version.

    --RateLimits
    self.rateLimitBuckets = {} --The rate limit buckets
end

--Authorize the REST API
function rest:authorize(tokenType, token)
    self.tokenType = tokenType
    self.token = token
    self.authorization = self.tokenType.." "..self.token
end

--Do a HTTP request, with proper authorization header
function rest:request(endpoint, data, method, headers, useMultipart)
    headers = headers or {}
    headers["Authorization"] = self.authorization
    local response_body, response_headers, status_code, status_line, failure_line = http_utils.request(self.baseURL..endpoint, data, method, headers, useMultipart)

    --RateLimits
    local headers = response_body and response_headers or status_code
    if type(headers) == "table" then
        if headers["x-ratelimit-limit"] then
            print("RATE LIMIT HEADER") --TODO: REMOVE ERRORS
            for k,v in pairs(headers) do print(k..":", v) end
            error("BOOM")
        elseif headers["x-ratelimit-global"] then
            print("RATE LIMIT HEADER")
            for k,v in pairs(headers) do print(k..":", v) end
            error("BOOM")
        end
    end

    return response_body, response_headers, status_code, status_line, failure_line
end

return rest