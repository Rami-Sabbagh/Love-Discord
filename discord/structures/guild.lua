local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local guild = class("discord.structures.Guild")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild object
--data (table): The data table recieved from discord.
--data (id): The id of the guild (the snowflake in string format), the guild data would be fetching using the REST API
function guild:initialize(data)
    Verify(data, "data", "table", "string")
    if type(data) == "string" then
        local gdata = discord.rest:request("/guilds/"..data)
        if not gdata then return error("Failed to fetch guild data") end --TODO: Proper REST error handling
        data = gdata
    end
    
    --== Unavailbale Guild Fields ==--
    self.id = discord.snowflake(data.id) --The guild ID (snowflake)
    self.unavailable = data.unavailable or false --Is the guild available (boolean)
    if self.unavailable then return end --No more data to process

    --== Available Guild Fields ==--
    self.name = data.name --The guild name (string)
    self.ownerID = discord.snowflake(data.owner_id) --The guild owner ID (snowflake)
    self.region = region --TODO: Voice Region structure object

    --== Optional Fields ==--
    self.icon = data.icon --The guild icon (string - icon hash) --TODO: image url object
    self.splash = data.splash --The guild splash (string - splash hash) --TODO: image url object
    self.owner = data.owner --Whether or not the user is the owner of the guild (boolean/nil), depends on the source of the guild object
    if data.permissions then
        self.permissions = discord.permissions(data.permissions) --Total permissions for the user in the guild (does not include channel overrides) (permissions object)
    end
    if self.afk_timeout then
        --TODO: VOICE CHANNEL OBJECT HERE
    end
    self.embedEnabled = data.embed_enabled
    if self.embed_channel_id then
        --TODO: TEXT CHANNEL OBJECT HERE
    end

    --TODO: Add the fields after the verification_level one https://discordapp.com/developers/docs/resources/guild

end

--Returns the guild ID (snowflake)
function guild:getID() return self.id end

--Returns the guild name if known (string/nil)
function guild:getName() return self.name end

--== Operator Overrides ==--

--Returns the guild name, or id if the name is unknown
function guild:__tostring()
    return self.name or tostring(self.id)
end

return guild