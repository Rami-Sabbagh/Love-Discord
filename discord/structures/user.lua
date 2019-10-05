local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.
local bit = discord.utilities.bit --Universal bit API

local band = bit.band

local user = class("discord.structures.User")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--https://discordapp.com/developers/docs/resources/user#user-object-user-flags
local userFlags = {
    [1] = "Discord Employee",
    [2] = "Discord Partner",
    [4] = "HypeSquad Events",
    [8] = "Bug Hunter",

    [64] = "House Bravery",
    [128] = "House Brilliance",
    [256] = "House Balance",
    [512] = "Early Supporter",
    [1024] = "Team User"
}

--New user object
--data (table): The user data object received from discord
--data (string): The user snowflake as a string
--data (string): (@me) Fetches the user data of the current authenticated user
function user:initialize(data)
    Verify(data, "data", "table", "string")
    if type(data) == "string" then
        local udata = discord.rest:request("/users/"..data)
        if not udata then return error("Failed to fetch user data") end --TODO: Proper REST error handling
        data = udata
    end

    --== Basic Fields ==--

    --TODO: Add OAUTH2 Scope support
    self.id = discord.snowflake(data.id) --The user's id (snowflake)
    self.username = data.username --The user's name, not unique across the platform (string)
    self.discriminator = data.discriminator --The user's 4-digit discord-tag (string)

    --== Optional Fields ==--
    self.avatar = data.avatar --TODO: IMAGE OBJECT
    self.bot = data.bot --Whether the user belongs to an OAuth2 application (boolean)
    self.mfaEnabled = data.mfa_enabled --Whether the user has two factor enabled on their account (boolean)
    self.locale = data.locale --The user's chosen language option (string)
    self.verified = data.verified --Whether the email on this account has been verified (boolean)
    self.email = data.email --The user's email (string)
    --The flags on a user's account (table)
    if data.flags then
        print("USER FLAGS",data.flags)
        self.flags = {}
        for b, flag in pairs(userFlags) do
            if band(data.flags, b) > 0 then
                self.flags[#self.flags + 1] = flag
            end
        end
    end
    self.premiumType = discord.enums.premiumTypes[data.premium_type] --The type of Nitro subscription on a user's account (string)
end

return user