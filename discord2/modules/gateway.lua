--Discord Gateway system

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.
local json = discord.json --JSON library.
local websocket = discord.websocket --lua-websocket library.
local url_utils = require("socket.url") --LuaSocket url utilities.
local http_utils = discord.utilities.http --HTPP utilities.

local sleep --Sleep function
if love then sleep = love.timer.sleep --Use love.timer sleep
else sleep = require("socket.sleep") end --Use luasocket sleep

local gateway = class("discord.modules.Gateway")

--Create a new instance
function gateway:initialize(rest, options)
    self.rest = rest
    if not self.rest.authorization then error("The REST API has to be authorized first!") end

    --The version of the gateway
    self.version = 6
    self.encoding = "json" --TODO: Add ETF support
    self.transportCompression = false --TODO: Add zlib-stream compression support
    self.payloadCompression = false --Payload compression support

    self.websocket = false --The websocket when connected
    self.websocketParams = {
        mode = "client",
        protocol = "any",
        verify = "none",
        options = {"all", "no_sslv2", "no_sslv3"}
    }

    self.jsonOptions = { null = "\0" } --Passed into JSON:encode(v,nil,options)

    self.gatewayInfo = false --The gateway information table retrieved when requesting the gateway URL
    self.gatewayURL = false --The gateway URL for connecting into.

    self.heartbeatInterval = false --Retrieved from the Hello payload
    self.heartbeatTimer = false --The heartbeat timer
    self.heartbeatACK = false --Used for detecting zombied connections
    self.sessionID = false --The session ID
    self.lastSequence = false --The last sequence number of a dispatch event
    self.reconnect = false --A flag for sending resume event instead of identify when possible

    --TODO: State fields
    --self.connecting = false --True when identifying with the gateway, false after READY event is recieved
    --self.ready = false --True after receiving the READY event
    --self.reconnecting = false --True when trying to reconnect
    --self.resumed = false --True after receving the RESUMED event

    self.autoReconnect = true --A flag to automatically reconnect when failing
    self.largeTreshold = 50 --Value between 50 and 250, total number of members where the gateway will stop sending offline members in the guild member list
    --self.shard = {1,1} --TODO: Add shards support.
    self.presence = {
        since = 0,
        game = {
            name = "Discörd",
            type = 0
        },
        status = "online",
        afk = true
    }
    self.guildSubscriptions = true --Enables dispatching of guild subscription events (presence and typing events)

    self.options = options or {} --Configuration options
    if self.options.encoding then self.encoding = self.options.encoding end
    if self.options.transportCompression then self.transportCompression = self.options.transportCompression end
    if self.options.payloadCompression then self.payloadCompression = true end
    if tostring(self.options.autoReconnect) == "false" then self.autoReconnect = false end
    if self.options.largeTreshold then self.largeTreshold = self.options.largeTreshold end
    --TODO: Add shards support
    if self.options.presence then self.presence = self.options.presence end
    if tostring(self.options.guildSubscriptions) == "false" then self.guildSubscriptions = false end

    self.events = {} --Events functions to trigger
end

--Hook a function to an event
function gateway:hookEvent(name, func)
    if self.events[name] then
        self.events[name][#self.events[name] + 1] = func
    else
        self.events[name] = {func}
    end
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
function gateway:connect(reconnect)
    if self.websocket then return error("Gateway already connected!") end

    --Get the gateway url
    if not self.gatewayURL then
        --Keep trying again and again if autoConnect is true
        while true do
            local ok, err = self:updateEndpoint()
            if not (ok or self.autoReconnect) then
                return false, err
            elseif ok then
                break
            else
                print("Failed to fetch gateway endpoint", err) --DEBUG
                print("Sleeping for 5 seconds..") --DEBUG
                sleep(5) --SLEEP
            end
        end
    end

    local client = websocket.client.async() --Create a new websocket client

    --Add in query options
    local socketQuery = {v=self.version, encoding=self.encoding}
    if self.transportCompression then socketQuery.transportCompression = self.transportCompression end
    local socketURL = self.gatewayURL.."/?"..http_utils.encodeQuery(socketQuery)

    --Connect to the websocket
    local ok, err = client:connect(socketURL, false, self.websocketParams)
    if not ok then
        --If failed to connect, then invalidate the gateway URL, so they get updated.
        self.gatewayInfo, self.gatewayURL = false, false

        if self.autoReconnect then
            print("Websocket connection failed...") --DEBUG
            return self:connect(reconnect) --Try again
        else
            return false, err
        end
    end

    --The websocket is now connected and ready for usage!
    self.websocket = client
    self.reconnect = (reconnect and self.sessionID and self.lastSequence) or false
    if not self.reconnect then
        --Reset those 2 variables because we're not reconnecting
        self.sessionID, self.lastSequence = false, false
    end

    --Success!
    return true
end

--Disconnect from the gateway
function gateway:disconnect()
    if not self.websocket then return error("The gateway is not connected!") end

    self.websocket:close()
    self.websocket = false

    --Reset some variables
    self.heartbeatInterval = false --Retrieved from the Hello payload
    self.heartbeatTimer = false --The heartbeat timer
    self.heartbeatACK = false --Used for detecting zombied connections
    --Session ID and Last Sequence are not reset because they could be used for reconnection
end

--Tells if the gateway is connected
function gateway:isConnected()
    return not not self.websocket --(not not) is used for converting into a boolean
end

--Sends a payload to the gateway
--Returns true on success, false and reason on failure.
function gateway:send(op, d, s, t)
    if not self.websocket then return error("The gateway is not connected!") end

    local payload = { op=op, d=d, s=s, t=t }
    if self.encoding == "json" then --TODO: Add ETF support
        payload = json:encode(payload, nil, self.jsonOptions)
    end

    if #payload > 4096 then return false, "Too large payload!" end
    self.websocket:send(payload)

    return true
end

--Receives a payload from the gateway, non-blocking, most of the time it would give timeout error (because it's non-blocking!)
function gateway:receive()
    if not self.websocket then return error("The gateway is not connected!") end

    local payload, opcode, closeWasClean, closeCode, closeReason = self.websocket:receive()
    if not payload and closeReason ~= "Socket Timeout" then
        print("LOST CONNECTION "..table.concat({ tostring(closeWasClean), tostring(closeCode), tostring(closeReason) }, " ")) --DEBUG
        self:disconnect() --We're dead
        return false, true
    end

    --Decode and decompress the payload
    if payload then
        if self.payloadCompression then
            --Attempt decompression
            local ok, decompressed = pcall(love.data.decompress, "string", "zlib", payload)
            if ok then payload = decompressed end
        end

        --TODO: ETF Support
        if self.encoding == "json" then
            payload = json:decode(payload)
        end
    end

    return payload, false
end

--Pull new payloads from the gateway if any are there, also runs the heartbeat timer.
--Required for the gateway connection to stay alive and work properly!
function gateway:update(dt)
    if not self.websocket then return false end --Not connected

    --Receive new payloads
    local payload, lostConnection = self:receive()

    if lostConnection then
        if self.autoReconnect then
            print("Sleeping for 5 seconds") --DEBUG
            sleep(5) --SLEEP
            self:connect(true)
            return true --Forgive us for this lost update
        else
            return false --The connection is dead
        end
    end

    --Got new payload
    if payload then
        local op, d, s, t = payload.op, payload.d, payload.s, payload.t
        print("RECEIVE", op, d, s, t) --DEBUG

        if op == 0 then --Dispatch, dispatches an event
            print("DISPATCH", t) --DEBUG

            --Trigger gateway events handlers
            if self["_"..t] then self["_"..t](self, op, d, s, t) end

            --Trigger non-gateway events handlers
            if self.events[t] then
                for k, func in pairs(self.events[t]) do
                    func(op, d, s, t)
                end
            end

            --Special hook triggered for any event
            if self.events["ANY"] then
                for k, func in pairs(self.events["ANY"]) do
                    func(op, d, s, t)
                end
            end

            self.lastSequence = s
        elseif op == 1 then --Heartbeat, used for ping checking
            self:send(11, "\0") --Reply with heartbeat ACK

        elseif op == 7 then --Reconnect, used to tell clients to reconnect to the gateway
            print("RECONNECT PAYLOAD!") --DEBUG
            --Reconnect as requested
            self:disconnect()
            self:connect(true)

        elseif op == 9 then --Invalid Session, used to notify client they have an invalid session id
            print("INVALID SESSION!, RESUMABLE: "..tostring(d)) --DEBUG
            local randTime = math.random(1,5) --Sleep for a random amount of time as required by discord
            print("Sleeping for",randTime,"seconds...") --DEBUG
            sleep(randTime) --SLEEP
            if d and self.sessionID and self.lastSequence then
                print("Resuming...")
                self:sendResume()
            else
                print("Reidentifying...")
                self:sendIdentify()
            end

        elseif op == 10 then --Hello, sent immediately after connecting, contains heartbeat and server debug information
            if self.reconnect then
                self.reconnect = false --Flag consumed
                self:sendResume()
            else
                self:sendIdentify()
            end

            --Set the heartbeat clock
            self.heartbeatInterval = d.heartbeat_interval/1000
            self.heartbeatTimer = self.heartbeatInterval
            self.heartbeatACK = true

        elseif op == 11 then --Heartbeat ACK, sent immediately following a client heartbeat that was received
            self.heartbeatACK = true

        else --Unknown
            print("UNKOWN GATEWAY PAYLOAD!", op, d, s, t)
        end
    end

    --Heartbeat
    if self.heartbeatTimer then
        self.heartbeatTimer = self.heartbeatTimer - dt
        if self.heartbeatTimer <= 0 then
            if not self.heartbeatACK then
                print("Zombied Connection!") --DEBUG
                self:disconnect() --The connection is zombied!
                if self.autoConnect then
                    self:connect(true)
                    return true --Forgive us for the lost update
                else
                    return false --Lost connection
                end
            end

            self:sendHeartbeat()

            self.heartbeatACK = false --Reset the ACK flag
            self.heartbeatTimer = self.heartbeatInterval
        end
    end

    return true --The connection is still alive
end

--Sends Heartbeat payload
function gateway:sendHeartbeat()
    self:send(1, self.lastSequence or "\0")
end

--Sends Identify payload
function gateway:sendIdentify()
    self:send(2,{
        token = self.rest.authorization,
        properties = {
            ["$os"] = love.system.getOS(), --TODO: Don't depend on LÖVE
            ["$browser"] = "Discörd", -- ;)
            ["$device"] = "Discörd"
        },
        compress = self.payloadCompression or nil,
        large_threshold = self.largeTreshold,
        shard = self.shard, --TODO: Shards support
        presence = self.presence,
        guild_subscriptions = self.guildSubscriptions
    })
end

--Sends Status Update payload
function gateway:sendStatusUpdate(since, game, status, afk)
    self.presence = {
        since = since or self.presence.since,
        game = game or self.presence.game,
        status = status or self.presence.status,
        afk = afk or self.presence.afk
    }

    self:send(3, self.presence)
end

--Sends Voice State Update payload
function gateway:sendVoiceStateUpdate(guildID, channelID, selfMute, selfDeaf)
    self:send(4, {
        guild_id = guildID,
        channel_id = channelID or "\0",
        self_mute = selfMute,
        self_deaf = selfDeaf
    })
end

--Sends Resume payload
function gateway:sendResume()
    self:send(6, {
        token = self.rest.authorization,
        session_id = self.sessionID,
        seq = self.lastSequence
    })
end

--Sends RequestGuildMembers
function gateway:sendRequestGuildMembers(guildID, query, limit, userIDs)
    self:send(8, {
        guild_id = guildID,
        query = query or "",
        limit = limit or 0,
        userIDs = userIDs
    })
end

--== Internal Methods ==--

--Internal method, returns the information of the Gateway to use.
--Returns gateway information on success, otherwise false and failure reason on failure.
function gateway:_getGateway()
    --TODO: Cache the gateway url for Bearer tokens (write a local file).
    local isBot = self:isBot()
    local gatewayInformation, failure_reason = self.rest:request(isBot and "/gateway/bot" or "/gateway")
    return gatewayInformation, failure_reason
end

--Internal method, called when the READY event is dispatched
function gateway:_READY(op, d, s, t)
    self.sessionID = d.session_id
    --TODO: Make use of the other information provided with this event
end

--Internal method, called when the RESUMED event is dispatched
function gateway:_RESUMED(op, d, s, t)
    print("RESUMED Successfully!") --DEBUG
end

return gateway