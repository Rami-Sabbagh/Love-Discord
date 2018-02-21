--OAuth2 Implementation

local discord = ...

local oauth = {}

function oauth.requestAutorization()
  local url = discord.apiEndpoint.."oauth2/authorize?"
  
  local args = {}
  
  args.response_type = "code"
  args.client_id = discord.config.clientID
  args.scope = table.concat(discord.config.oAuth_scopes,"%20")
  args.redirect_uri = http.urlEscape(discord.config.oAuth_redirect_uri)
  
  oauth.state = {}
  
  --Generate a random state string.
  for i=1,16 do
    oauth.state[i] = string.format("%x",math.random(0,15))
  end
  
  oauth.state = table.concat(oauth.state)
  
  args.state = oauth.state
  
  args = http.urlEncode(args)
  
  url = url..args
  
  openURL(url)
end

function oauth.readAuthorizationCode(acode)
  local state = acode:sub(1,oauth.state:len())
  local code = acode:sub(oauth.state:len()+1,-1)
  
  if state ~= oauth.state then return false, "Incorrect State !, "..state.." should be: "..oauth.state end
  return code
end

function oauth.exchangeToken(code)
  
  local url = discord.apiEndpoint.."oauth2/token"
  
  local headers = {
    ["Content-Type"] = "application/x-www-form-urlencoded",
    ["User-Argent"] = discord.config.agent
  }
  
  local postData = {
    client_id = discord.config.clientID,
    client_secret = discord.config.clientSecret,
    grant_type = "authorization_code",
    code = code,
    redirect_uri = http.urlEscape(discord.config.oAuth_redirect_uri)
  }
  
  postData = http.urlEncode(postData)
  
  local data = assert(http.post(url, postData, headers))
  
  cprint(data)
  
  data = discord.json:decode(data)
  
  oauth.token = data.access_token
  oauth.token_type = data.token_type
  oauth.expires_in = data.expires_in
  oauth.refresh_token = data.refresh_token
  
  discord.authorization = oauth.token_type.." "..oauth.token
  
end

function oauth.refreshToken()
  
  local url = discord.apiEndpoint.."oauth2/token"
  
  local headers = {
    ["Content-Type"] = "application/x-www-form-urlencoded",
    ["User-Argent"] = discord.config.agent
  }
  
  local postData = {
    client_id = discord.config.clientID,
    client_secret = discord.config.clientSecret,
    grant_type = "refresh_token",
    refresh_token = discord.oauth.refresh_token,
    redirect_uri = http.urlEscape(discord.config.oAuth_redirect_uri)
  }
  
  postData = http.urlEncode(postData)
  
  local data = assert(http.post(url, postData, headers))
  
  data = discord.json:decode(data)
  
  oauth.token = data.access_token
  oauth.token_type = data.token_type
  oauth.expires_in = data.expires_in
  oauth.refresh_token = data.refresh_token
  
  discord.authorization = oauth.token_type.." "..oauth.token
  
end

function oauth.revokeToken()
  
  local url = discord.apiEndpoint.."oauth2/token/revoke"
  
  local headers = {
    ["Content-Type"] = "application/x-www-form-urlencoded",
    ["User-Argent"] = discord.config.agent
  }
  
  local postData = {
    client_id = discord.config.clientID,
    client_secret = discord.config.clientSecret,
    token = discord.oauth.token
  }
  
  postData = http.urlEncode(postData)
  
  assert(http.post(url, postData, headers))
  
  oauth.token = nil
  oauth.token_type = nil
  oauth.expires_in = nil
  oauth.refresh_token = nil
  discord.authorization = nil
  
end

function oauth.update(dt)
  if oauth.token then
    oauth.expires_in = oauth.expires_in - dt
    
    --Refresh in the last hour.
    if oauth.expires_in <= 60*60 then
      oauth.refreshToken()
    end
  end
end

return oauth