--Discord REST API

local discord = ... --Passed as an argument.
local http_utils = discord.utilities.http

local sleep --Sleep function
if love then sleep = love.timer.sleep --Use love.timer sleep
else sleep = require("socket.sleep") end --Use luasocket sleep

local rest = {}

--Create a new instance
function rest:initialize()
    self.version = 6 --The used version of Discord's REST API.
    self.baseURL = "https://discordapp.com/api/v"..self.version --The base URL of the used REST API version.

    --RateLimits
    self.rateLimitBuckets = {} --The rate limit buckets
    self.rateLimits = {} --The endpoint-to-bucket list
end

--Authorize the REST API
function rest:authorize(tokenType, token)
    self.tokenType = tokenType
    self.token = token
    self.authorization = self.tokenType.." "..self.token
end

--Do a HTTP request, with proper authorization header
function rest:request(endpoint, data, method, headers, useMultipart)
    --Hang on ratelimits
    if self.rateLimits[endpoint] then
        local bucket = self.rateLimitBuckets[self.rateLimits[endpoint]]
        local timeLeft = os.time() - bucket.reset
        if bucket.remaining == 0 and timeLeft > 0 then
            print("RATE LIMIT REACHED !!!!!") --TODO: Proper logging
            print("Sleeping for",timeleft,"seconds...") --DEBUG
            sleep(timeLeft)
        elseif timeLeft <= 0 then --Invalidate the bucket
            local bucketID = self.rateLimits[endpoint]
            self.rateLimitBuckets[bucketID] = nil

            --Invalidate all the urls using the same bucket
            for k,v in pairs(self.rateLimits) do
                if v and v == bucketID then
                    self.rateLimits[k] = nil
                end
            end
        else --Consume a use of this endpoint
            bucket.remaining = bucket.remaining - 1
        end
    end

    headers = headers or {}
    headers["Authorization"] = self.authorization
    local response_body, response_headers, status_code, status_line, failure_line = http_utils.request(self.baseURL..endpoint, data, method, headers, useMultipart)

    --RateLimits
    local headers = response_body and response_headers or status_code
    if type(headers) == "table" then
        if headers["x-ratelimit-limit"] then
            local bucketID = headers["x-ratelimit-bucket"]
            self.rateLimitBuckets[bucketID] = {
                global = false,
                limit = headers["x-ratelimit-limit"],
                remaining = headers["x-ratelimit-remaining"],
                reset = headers["x-ratelimit-reset"],
                reset_after = headers["x-ratelimit-reset_after"]
            }
            self.rateLimits[endpoint] = bucketID
            if headers["Retry-After"] then
                --Ratelimitted
                return self:request(endpoint, data, method, headers, useMultipart) --Would sleep until the ratelimit is lifted
            end
        elseif headers["x-ratelimit-global"] then
            local bucketID = "global"
            self.rateLimitBuckets[bucketID] = {
                global = true,
                limit = 0,
                remaining = 0,
                reset = os.time() + math.ceil(headers["Retry-After"]/1000),
                reset_after = math.ceil(headers["Retry-After"]/1000)
            }
            self.rateLimits[endpoint] = bucketID
            return self:request(endpoint, data, method, headers, useMultipart) --Handles the ratelimit properly
        end
    else --Connection failed, unconsume the API usage
        if self.rateLimits[endpoint] then
            local bucket = self.rateLimitBuckets[self.rateLimits[endpoint]]
            if not bucket.global then
                bucket.remaining = bucket.remaining + 1 --Connection failure doesn't count toward the ratelimit
            end
        end
    end

    return response_body, response_headers, status_code, status_line, failure_line
end

rest:initialize()

return rest