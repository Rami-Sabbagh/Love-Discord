--Discord User API

local discord = ...

local uapi = {}

function uapi.getCurrentUser()
  return assert(discord.request("users/@me"))
end

function uapi.getUser(id)
  return assert(discord.request("users/"..tostring(id)))
end

function uapi.modifyCurrentUser(username,avatar)
  local data = {
    username = username,
    avatar = avatar
  }
  
  return assert(discord.request("users/@me",data,"PATCH"))
end

function uapi.getCurrentUserGuilds(before,after,limit)
  local data = {
    before=before,after=after,limit=limit
  }
  
  data = http.urlencode(data)
  
  return assert(discord.request("users/@me/guilds?"..data))
end

function uapi.leaveGuild(id)
  return assert(discord.request("users/@me/guilds/"..id,false,"DELETE"))
end

function uapi.getUserDMs()
  return assert(discord.request("users/@me/channels"))
end

function uapi.createDM(recipient_id)
  local data = {
    recipient_id = recipient_id
  }
  
  return assert(discord.request("users/@me/channels",data,"POST"))
end

function uapi.createGroupDM(access_tokens,nicks)
  local data = {
    access_tokens=access_tokens,
    nicks=nicks
  }
  
  return assert(discord.request("users/@me/channels",data,"POST"))
end

function uapi.getUserConnections()
  return assert(discord.request("users/@me/connections"))
end

return uapi