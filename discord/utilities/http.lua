--- HTTP Utilities, contains usefull formatting and requesting functions
-- @module discord.utilities.http

local discord = ... --Passed as an argument
local https = discord.https
local json = discord.json
local multipart = discord.multipart

local ltn12 = require("ltn12")
local url_utils = require("socket.url")

local http_utils = {}

--- The https response codes explainations.
-- @table http_utils.codes
http_utils.codes = {
    [200] = {"OK","The request completed successfully"},
    [201] = {"CREATED", "The entity was created successfully"},
    [204] = {"NO CONTENT", "The request completed successfully but returned no content"},
    [304] = {"NOT MODIFIED", "The entity was not modified (no action was taken)"},
    [400] = {"BAD REQUEST", "The request was improperly formatted, or the server couldn't understand it"},
    [401] = {"UNAUTHORIZED", "The Authorization header was missing or invalid"},
    [403] = {"FORBIDDEN", "The Authorization token you passed did not have permission to the resource"},
    [404] = {"NOT FOUND", "The resource at the location specified doesn't exist"},
    [405] = {"METHOD NOT ALLOWED", "The HTTP method used is not valid for the location specified"},
    [429] = {"TOO MANY REQUESTS", "You've made too many requests, see Rate Limits"},
    [502] = {"GATEWAY UNAVAILABLE", "There was not a gateway available to process your request. Wait a bit and retry"}
}

--- Encode a table into a query string.
-- @tparam table t The query table.
-- @treturn string The encoded query string.
function http_utils.encodeQuery(t)
    local query = {}
    for k,v in pairs(t) do
        query[#query + 1] = url_utils.escape(k).."="..url_utils.escape(v)
    end
    return table.concat(query, "&")
end

--- Execute a http request synchronously.
-- @tparam string|table url The request url, or a url table in lua-socket format.
-- @tparam ?string|table data The request body data.
-- @tparam ?string method The request method: GET, POST, etc.
-- @tparam ?table headers The request headers table.
-- @tparam ?boolean useMultipart Whether use multipart/form-data instead of json to encode the request data (when provided in a table).
-- @treturn boolean `true` then the request has been done successfully, `false` otherwise.
-- @treturn string|table The error string on failure, otherwise it's the reponse body data, automatically decode if it was JSON.
-- @treturn ?table The response headers (only on success).
-- @treturn ?number The response status code (only on success).
-- @treturn ?string The response status line (only on success).
function http_utils.request(url, data, method, headers, useMultipart)

    --Construct the url if it's a table
    if type(url) == "table" then url = url_utils.build(url) end

    --Set default headers
    headers = headers or {}
    headers["User-Agent"] = discord._userAgent

    --Use an empty table for data when the request method is neither GET
    if method and method ~= "GET" then data = data or {} end

    --Convert the data into json or multipart
    if type(data) == "table" then
        if useMultipart then
            --Convert into multipart
            local ContentType = "multipart/form-data; boundary="..multipart.RANDOM_BOUNDARY
            local mp = multipart("", ContentType)
            for k,v in pairs(data) do
                --Encode the table fields into JSON, since multipart doesn't support tables...
                if type(v) == "table" then
                    if k == "payload_json" then
                        v = json:encode(v,nil,{ null = "\0" })
                        mp:set_simple(k,v)
                    elseif k == "file" then
                        mp:set_file(k,v[1],v[2])
                    end
                else
                    mp:set_simple(k,v)
                end
            end
            data = mp:tostring()
            headers["Content-Type"] = ContentType
        elseif not method or method ~= "GET" then
            --Convert into JSON
            data = json:encode(data,nil,{ null = "\0" })
            headers["Content-Type"] = "application/json"
        else
            --Convert into url query, when the method is set into GET
            local query = http_utils.encodeQuery(data)
            local parsed_url = url_utils.parse(url)
            parsed_url.query = query
            url = url_utils.build(parsed_url)
            data = nil
        end

    elseif data then
        data = tostring(data)
        if not headers["Content-Type"] then headers["Content-Type"] = "application/json" end
    end

    --Set the content length header
    if data then headers["Content-Length"] = #data end

    --Set the request method, POST when there's data to send, GET otherwise.
    method = method or (data and "POST" or "GET")

    --Request body source
    local source = data and ltn12.source.string(data) or nil

    --Response body sink
    local response_body = {}
    local sink = ltn12.sink.table(response_body)

    --The request options
    local request = {}
    request.url = url --Set the request url.
    request.method = method --Set the request method.
    request.headers = headers --Set the request headers.
    request.sink = sink --Set the response body sink.
    request.source = source --Set the request body source.

    --Do the actual HTTP request
    local ok, status_code, response_headers, status_line = https.request(request)

    response_body = table.concat(response_body, "") --Convert the received data into a string.

    if ok then
        status_code = tonumber(status_code)

        --Check if the response wasn't an error response...
        if status_code < 100 or status_code >= 300 then
            print("HTTP Failed, Response Body:", response_body)
            if http_utils.codes[status_code] then
                print("HTTP Error ("..status_code.."):", http_utils.codes[status_code][1].." -> "..http_utils.codes[status_code][2])
                return false, "HTTP Error ("..status_code.."):", http_utils.codes[status_code][1].." -> "..http_utils.codes[status_code][2], response_body, response_headers, status_code, status_line
            else
                return false, "HTTP Error: "..status_code, response_body, response_headers, status_code, status_line
            end
        end

        --Decode the response body if it's JSON data
        if response_headers["content-type"] and response_headers["content-type"]:match("^application/json") then
            response_body = json:decode(response_body)
        end

        return response_body, response_headers, status_code, status_line

    else
        return false, "HTTP Failed: "..tostring(status_code)
    end
end

return http_utils