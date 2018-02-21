--JSON request

local discord = ...

local web = WEB

return function(url, data, method)
  if not web then return false, "JSON Request Requires WEB Peripheral" end
  
  --The request arguments.
  local args = {}
  
  --The request header.
  args.headers = {
    ["User-Argent"] = discord.config.agent,
    ["Authorization"] = discord.authorization
  }
  
  --POST method
  if data then
    args.method = "POST"
    args.data = discord.json:encode(data,nil,{ null = "!NULL" })
  end
  
  --Set method
  args.method = method or args.method
  
  --Send the web request
  local ticket = WEB.send(discord.apiEndpoint..url,args)
  
  --Wait for it to arrived
  for event, id, url, data, errnum, errmsg, errline in pullEvent do
    
    --Here it is !
    if event == "webrequest" then
      --Yes, this is the correct package !
      if id == ticket then
        
        if data then
          data.code = tonumber(data.code)
          
          if data.code < 100 or data.code >= 300 then --Too bad...
            cprint("HTTP Failed Request Body: "..tostring(data.body))
            if discord.httpcodes[data.code] then
              cprint("HTTP Error ("..data.code.."): "..discord.httpcodes[data.code][1].." -> "..discord.httpcodes[data.code][2])
              return false, "HTTP Error ("..data.code.."): "..discord.httpcodes[data.code][1].." -> "..discord.httpcodes[data.code][2], data.code
            else
              return false, "HTTP Error: "..data.code
            end
          end
          
          local ok, decoded = pcall(discord.json.decode,discord.json,data.body) --Yay
          
          if ok then
            return decoded, data
          else
            return data.body, data
          end
        else --Oh, no, it failed
          return false, errmsg
        end
        
      end
    elseif event == "keypressed" then
      
      if id == "escape" then
        return false, "Request Canceled" --Well, the user changed his mind
      end
      
    end
  end
end