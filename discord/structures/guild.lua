local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local guild = class("discord.structures.Guild")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if v == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild object
--data: The data table recieved from discord.
function guild:initialize(data)
    
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

return guild