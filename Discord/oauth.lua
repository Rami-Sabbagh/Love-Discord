--OAuth2 Implementation

local discord = ...

local oauth = {}

function oauth.requestAutorization()
  local url = discord.apiEndpoint.."oauth2/authorize?"
  
  local args = {}
  
  args.response_type = "code"
  args.client_id = discord.config.clientID
  args.scope = table.concat(discord.config.oAuth_scopes,"%20")
  args.redirect_uri = discord.tools.urlEscape(discord.config.oAuth_redirect_uri)
  
  oauth.state = {}
  
  --Generate a random state string.
  for i=1,16 do
    oauth.state[i] = string.format("%x",math.random(0,15))
  end
  
  oauth.state = table.concat(oauth.state)
  
  args.state = oauth.state
  
  args = discord.tools.urlEncode(args)
  
  url = url..args
  
  love.system.openURL(url)
end

function oauth.readAuthorizationCode(acode)
  local state = acode:sub(1,oauth.state:len())
  local code = acode:sub(oauth.state:len()+1,-1)
  
  if state ~= oauth.state then return false, "Incorrect State !, "..state.." should be: "..oauth.state end
  return code
end

return oauth