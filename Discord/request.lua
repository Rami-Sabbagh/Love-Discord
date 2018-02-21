--JSON request

local https = require("https")
local ltn12 = require("ltn12")
local url = require("socket.url")

local discord = ...

local function urlencode(data)
  local query = {}
  for k,v in pairs(data) do
    if v then
      query[#query + 1] = string.format("%s=%s",tostring(k),tostring(v))
    end
  end
  return table.concat(query,"&")
end

return function(urlstr, data, method, reqHeaders)
  
  --The request arguments.
  local args = {}
  
  --The request method
  local m = data and "POST" or "GET"
  m = method or m
  
  args.method = m
  
  --The request header.
  args.headers = {
    ["User-Argent"] = discord.config.agent,
    ["Authorization"] = discord.authorization
  }
  
  --Parse the url
  args.url = url.parse(discord.apiEndpoint..urlstr)
  
  if data then
    if m == "GET" then
      --Put in the query if needed
      local query = urlencode(data)
      if query ~= "" then
        args.url.query = query
      end
      args.headers["content-type"] = "application/x-www-form-urlencoded"
    else
      --JSON Content
      local data = discord.json:encode(data,nil,{ null = "!NULL" })
      args.source = ltn12.source.string(data)
      args.headers["content-length"] = #data
      args.headers["content-type"] = "application/json"
    end
  end
  
  --Rebuild the url
  args.url = url.build(args.url)
  
  --Data receiving
  local result_table = {}
  args.sink = ltn12.sink.table(result_table)
  
  --Merge Headers
  if reqHeaders then
    for k,v in pairs(reqHeaders) do
      args.headers[k] = v
    end
  end
  
  --The request time
  local res, code, headers, status = https.request(args)
  
  local result = table.concat(result_table)
  
  if res then
    code = tonumber(code)
    
    if code < 100 or code >= 300 then --Too bad...
      print("HTTP Failed Request Body: "..tostring(result))
      if discord.httpcodes[code] then
        print("HTTP Error ("..code.."): "..discord.httpcodes[code][1].." -> "..discord.httpcodes[code][2])
        return false, "HTTP Error ("..code.."): "..discord.httpcodes[code][1].." -> "..discord.httpcodes[code][2], code
      else
        return false, "HTTP Error: "..code
      end
    end
    
    local ok, decoded = pcall(discord.json.decode,discord.json,result) --Yay
    
    if ok then
      return decoded, {res, code, headers, status}
    else
      return result, {res, code, headers, status}
    end
  else
    return false, "HTTPS Failed: "..tostring(code)
  end
end