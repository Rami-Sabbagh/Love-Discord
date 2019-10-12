--Discörd Böt roles mananger
local rolesManager = {}

--Initialize the role manager and hook it's event
function rolesManager:initialize()
    self.botAPI = require("bot")
    self.discord = self.botAPI.discord

    self.adminRoles, self.guildOwners = {}, {}

    --Hook events
    self.discord:hookEvent("GUILD_CREATE", self._GUILD_CREATE)
    self.discord:hookEvent("GUILD_ROLE_CREATE", self._GUILD_ROLE_CREATE)
    self.discord:hookEvent("GUILD_ROLE_UPDATE", self._GUILD_ROLE_UPDATE)
    self.discord:hookEvent("GUILD_ROLE_DELETE", self._GUILD_ROLE_DELETE)
end

--Tells if a provided role snowflake is an admin one
function rolesManager:isAdmin(guildID, roleID)
    guildID, roleID = tostring(guildID), tostring(roleID)
    if not self.adminRoles[guildID] then return false end
    return self.adminRoles[guildID][roleID]
end

--Tells if a message is from an admin
function rolesManager:isFromAdmin(message)
    local guildID = message:getGuildID()
    if not guildID then return true end --DM recipient is an admin
    guildID = tostring(guildID)

    --Guild owners are admins
    if self.guildOwners[guildID] == tostring(message:getAuthor():getID()) then return true end

    --Check if any role has admin power
    local member = message:getMember()
    local roles = member:getRoles()
    for _, role in pairs(roles) do
        if self.adminRoles[guildID][tostring(role)] then return true end
    end

    return self.botAPI:isFromOwner(message) --Bot owners are considered admins everywhere
end

--== Events ==--

--Admin detection
function rolesManager._GUILD_CREATE(guild)
    local guildID = tostring(guild:getID())
    rolesManager.adminRoles[guildID] = {}
    rolesManager.guildOwners[guildID] = tostring(guild:getOwnerID())
    for _, role in pairs(guild:getRoles()) do
        local permissions = role:getPermissions()
        if permissions:get(true, "ADMINISTRATOR") then
            rolesManager.adminRoles[guildID][tostring(role:getID())] = true
        end
    end
end

function rolesManager._GUILD_ROLE_CREATE(guildID, role)
    guildID = tostring(guildID)
    if not rolesManager.adminRoles[guildID] then rolesManager.adminRoles[guildID] = {} end
    local isAdmin = role:getPermissions():get(true, "ADMINISTRATOR")
    rolesManager.adminRoles[guildID][tostring(role:getID())] = isAdmin and true or nil
end

function rolesManager._GUILD_ROLE_UPDATE(guildID, role)
    guildID = tostring(guildID)
    if not rolesManager.adminRoles[guildID] then rolesManager.adminRoles[guildID] = {} end
    local isAdmin = role:getPermissions():get(true, "ADMINISTRATOR")
    rolesManager.adminRoles[guildID][tostring(role:getID())] = isAdmin and true or nil
end

function rolesManager._GUILD_ROLE_DELETE(guildID, roleID)
    guildID = tostring(guildID)
    if not rolesManager.adminRoles[guildID] then rolesManager.adminRoles[guildID] = {} end
    rolesManager.adminRoles[guildID][tostring(roleID)] = nil
end

return rolesManager