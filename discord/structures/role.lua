local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local role = class("discord.structures.Role")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function role:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    self.id = discord.snowflake(data.id) --Attachment ID (snowflake)
    self.name = data.name --Role name (string)
    self.color = data.color --Integer representation of hexadecimal color code (number)
    self.hoist = data.hoist --If this role is pinned in the user listing (boolean)
    self.permissions = discord.permissions(data.permissions) --Permission bit set (permissions)
    self.managed = data.managed --Ehether this role is managed by an integration (boolean)
    self.mentionable = data.mentionable --Whether this role is mentionable (boolean)

end

--== Methods ==--

--Returns the role ID (snowflake)
function role:getID() return self.id end

--Returns the role name (string)
function role:getName() return self.name end

--Returns the role color (number)
function role:getColor() return self.color end

--Returns the role permissions (permissions)
function role:getPermissions() return self.permissions end

--Is the role managed (boolean)
function role:isManaged() return self.managed end

--Is the role mentionable
function role:isMentionable() return self.mentionable end

--Is the role pinned (boolean)
function role:isPinned() return self.hoist end

return role