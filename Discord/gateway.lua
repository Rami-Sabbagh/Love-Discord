--Discord gateway implementation

local discord = ...

local gw = {}

gw.events = {} --For events handlers.

function gw.getGatewayBot()

  local data = assert(discord.request("gateway/bot"))
  
  gw.url = data.url
  gw.shards = data.shards
  
  print("Gateway: ",gw.url)
  
end

function gw.connect()
  
  print("Load websocket")
  local Websocket = require(discord.path..".lua-websockets")
  
  print("Create client")
  local client = Websocket.client.async()
  
  local params = {
    mode = "client",
    protocol = "any",
    verify = "none",
    options = {"all", "no_sslv2", "no_sslv3"}
  }
  
  print("Connect")
  assert(client:connect(gw.url.."/?v=6&encoding=json",false,params))
  
  print("Connected !")
  
  gw.client = client
  
end

function gw.disconnect()
  gw.client:close()
  
  print("Disconnected !")
end

function gw.send(op,d,t,s)
  local payload = {op=op,d=d,t=t,s=s}
  payload = discord.json:encode(payload,nil,{ null = "!NULL" })
  
  gw.client:send(payload)
end

function gw.receive()
  local message,opcode,close_was_clean,close_code,close_reason = gw.client:receive()
  
  if not message and close_reason ~= "Socket Timeout" then
    print("Lost connnection",close_was_clean,close_code,close_reason)
    
    print("Sleeping for 2 seconds")
    love.timer.sleep(2)
    print("Attemping to reconnect...")
    
    local params = {
      mode = "client",
      protocol = "any",
      verify = "none",
      options = {"all", "no_sslv2", "no_sslv3"}
    }
    assert(gw.client:connect(gw.url.."/?v=6&encoding=json",false,params))
    
    gw.sendReconnect()
  end
  
  if message then
    message = discord.json:decode(message)
  end
  
  return message
end

gw.hb_timer = 0

function gw.update(dt)
  local message = gw.receive()
  
  if message then
    local data = message.d
    local op = message.op
    local t = message.t
    local s = message.s
  
    if op == 0 then --Dispatch
      print("Dispatch",t,s)
      gw.sequence = s or gw.sequence
      
      if t == "READY" then
        print("Session: "..tostring(data.session_id))
        gw.session_id = data.session_id
      end
      
      if gw.events[t] then
        gw.events[t](data,t,s,discord)
      end
    elseif op == 1 then --Gateway Heartbeat
      print("Gateway heartbeat")
    elseif op == 7 then --Reconnect
      print("Should reconnect !")
    elseif op == 9 then --Invalid Session
      print("Invalid Session !")
    elseif op == 10 then --Gateway Hello
      gw.hb_time = data.heartbeat_interval/1000 --Convert to seconds.
      gw.shouldIdentify = not gw.reconnected
      print("Gateway Hello")
    elseif op == 11 then --Gateway Heartbeat ACK
      print("Gateway heartbeat ACK")
    end
  end
  
  --Client Heartbeat
  if gw.hb_time then
    gw.hb_timer = gw.hb_timer - dt
    if gw.hb_timer < 0 then
      gw.hb_timer = gw.hb_time
      
      gw.sendHeartbeat()
    end
  end
  
  --Identify
  if gw.shouldIdentify then
    gw.shouldIdentify = false
    gw.sendIdentify()
  end
end

function gw.sendHeartbeat()
  local message = {op = 1, d = (gw.sequence or "!NULL")}
  gw.send(1,"!NULL")
  print("Client heartbeat")
end

function gw.sendIdentify()
  local data = {
    token = discord.authorization,
    properties = {
      ["$os"] = love.system.getOS(),
      ["$browser"] = "LÖVE",
      ["$device"] = "LÖVE"
    },
    compress = false,
    large_threshold = 50,
    presence = {
      since = "!NULL",
      game = {
        name = "LÖVE",
        type = 0
      },
      status = "online",
      afk = false
    }
  }
  gw.send(2, data)
  print("Client Identify")
end

function gw.sendReconnect()
  if not gw.session_id then error("Can't reconnect !") end
  local data = {
    token = discord.authorization,
    session_id = gw.session_id,
    seq = gw.sequence
  }
  gw.send(6,data)
  gw.reconnected = true
  print("Client Reconnect")
end

return gw