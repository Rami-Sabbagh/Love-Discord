--- Permissions class
-- @classmod discord.permissions

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.
local bit = discord.utilities.bit --Universal bit library.

local band, bxor, bor = bit.band, bit.bxor, bit.bor

local permissions = class("discord.structures.Permissions")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not value) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--Permissions flags informations
local permissionsTable = {
    --1. name, 2. 2FA required, 3. value, 4. description, 5. channel type (T), 6. channel type (V)
    {"CREATE_INSTANT_INVITE", false, 0x00000001, "Allows creation of instant invites", true, true},
    {"KICK_MEMBERS", true, 0x00000002, "Allows kicking members", false, false},
    {"BAN_MEMBERS", true, 0x00000004, "Allows banning members", false, false},
    {"ADMINISTRATOR", true, 0x00000008, "Allows all permissions and bypasses channel permission overwrites", false, false},
    {"MANAGE_CHANNELS", true, 0x00000010, "Allows management and editing of channels", true, true},
    {"MANAGE_GUILD", true, 0x00000020, "Allows management and editing of the guild", false, false},
    {"ADD_REACTIONS", false, 0x00000040, "Allows for the addition of reactions to messages", true, false},
    {"VIEW_AUDIT_LOG", false, 0x00000080, "Allows for viewing of audit logs", false, false},
    {"VIEW_CHANNEL", false, 0x00000400, "Allows guild members to view a channel, which includes reading messages in text channels", true, true},
    {"SEND_MESSAGES", false, 0x00000800, "Allows for sending messages in a channel", true, false},
    {"SEND_TTS_MESSAGES", false, 0x00001000, "Allows for sending of /tts messages", true, false},
    {"MANAGE_MESSAGES", true, 0x00002000, "Allows for deletion of other users messages", true, false},
    {"EMBED_LINKS", false, 0x00004000, "Links sent by users with this permission will be auto-embedded", true, false},
    {"ATTACH_FILES", false, 0x00008000, "Allows for uploading images and files", true, false},
    {"READ_MESSAGE_HISTORY", false, 0x00010000, "Allows for reading of message history", true, false},
    {"MENTION_EVERYONE", false, 0x00020000, "Allows for using the @everyone tag to notify all users in a channel, and the @here tag to notify all online users in a channel", true, false},
    {"USE_EXTERNAL_EMOJIS", false, 0x00040000, "Allows the usage of custom emojis from other servers", true, false},
    {"CONNECT", false, 0x00100000, "Allows for joining of a voice channel", false, true},
    {"SPEAK", false, 0x00200000, "Allows for speaking in a voice channel", false, true},
    {"MUTE_MEMBERS", false, 0x00400000, "Allows for muting members in a voice channel", false, true},
    {"DEAFEN_MEMBERS", false, 0x00800000, "Allows for deafening of members in a voice channel", false, true},
    {"MOVE_MEMBERS", false, 0x01000000, "Allows for moving of members between voice channels", false, true},
    {"USE_VAD", false, 0x02000000, "Allows for using voice-activity-detection in a voice channel", false, true},
    {"PRIORITY_SPEAKER", false, 0x00000100, "Allows for using priority speaker in a voice channel", false, true},
    {"STREAM", false, 0x00000200, "Allows the user to go live", false, true},
    {"CHANGE_NICKNAME", false, 0x04000000, "Allows for modification of own nickname", false, false},
    {"MANAGE_NICKNAMES", false, 0x08000000, "Allows for modification of other users nicknames", false, false},
    {"MANAGE_ROLES", true, 0x10000000, "Allows management and editing of roles", true, true},
    {"MANAGE_WEBHOOKS", true, 0x20000000, "Allows management and editing of webhooks", true, true},
    {"MANAGE_EMOJIS", true, 0x40000000, "Allows management and editing of emojis", false, false}
}

--Permission name -> value table
local permissionFlag = {}
--Permission value -> name table
local flagPermission = {}
--Permission name -> listID table
local permissionID = {}
--A bitmask of all the permissions bits
local permissionsMask = 0

--Generate the lookup tables, and the bitmask
for k,v in pairs(permissionsTable) do
    permissionFlag[v[1]] = v[3]
    flagPermission[v[3]] = v[1]
    permissionID[v[1]] = k
    permissionsMask = v[3] + permissionsMask
end

--== Static Methods ==--

--Returns the description of a permission, errors on unknown permissions.
function permissions.static:getDescription(name)
    local ID = permissionID[name]
    if not ID then return error("Permission "..tostring(name).." is not known !") end
    return permissionsTable[ID][4]
end

--Tells if a permission required 2FA or not, errors on unknown permissions.
function permissions.static:requires2FA(name)
    local ID = permissionID[name]
    if not ID then return error("Permission "..tostring(name).." is not known !") end
    return permissionsTable[ID][2]
end

--== Methods ==--

--New permissions object
function permissions:initialize(bitfield, allowText, allowVoice)
    Verify(bitfield, "bitfield", "number", "nil")

    self.allowText, self.allowVoice = not not allowText, not not allowVoice
    self:_calculateMask()
    self.bitfield = bitfield or 0
end

--Replaces the current permissions bitfield
function permissions:replaceBitField(bitfield)
    Verify(bitfield, "bitfield", "number")
    self.bitfield = bitfield
end

--Returns the permissions bitfield, masked or unmasked to the allowed channel types
function permissions:getBitField(unmasked)
    if unmasked then
        return band(self.bitfield, permissionsMask)
    else
        return band(self.bitfield, self.mask)
    end
end

--Sets the channel types
function permissions:setAllowedChannelTypes(allowText, allowVoice)
    self.allowText, self.allowVoice = not not allowText, not not allowVoice
    self:_calculateMask()
end

--Gets the allowed channel types
function permissions:getAllowedChannelTypes()
    return self.allowText, self.allowVoice
end

--Inverts all the set permissions
function permissions:toggleAll()
    self.bitfield = bxor(self.bitfield, permissionsMask)
end

--Inverts a set of permissions (takes permissions names)
function permissions:toggle(...)
    for _, name in pairs({...}) do
        self.bitfield = bxor(self.bitfield, permissionFlag[name] or 0)
    end
end

--Sets a set of permissions (takes permissions names)
function permissions:set(state, ...)
    local setMask = 0
    for _, name in pairs({...}) do
        setMask = bor(setMask, permissionFlag[name] or 0)
    end

    if state then
        self.bitfield = bor(self.bitfield, setMask)
    else
        self.bitfield = band(self.bitfield, bxor(setMask, permissionsMask))
    end
end

--Returns the name of the first permission that matches the given state,
--Returns false when none match
function permissions:get(state, ...)
    for _, name in ipairs({...}) do
        local b = (band(self.bitfield, permissionFlag[name] or 0) > 0)
        if not state then b = not b end
        if b then return name end
    end

    return false
end

--Returns a list of the permissions with the given state
--offState (any/nil): Whether to treat unset bits as set or not
function permissions:listAll(offState)
    local list = {}
    
    for permName, permBit in pairs(permissionFlag) do
        local b = (band(bitfield, permBit) > 0)
        if offState then b = not b end
        if b then
            list[#list + 1] = permName
        end
    end

    return list
end

--== Operators Overrides ==--

--Returns a string with all the ON flags set
function permissions:__tostring()
    return table.concat(self:listAll(), ", ")
end

--Tests if the two permissions are the same
function permissions:__eq(other)
    return self.bitfield == other.bitfield
end

--Compares two permissions to know the more permittive one
function permissions:__lt(other)
    return #self:listAll() < #other:listAll()
end

--Compares two permissions to know the more permittive one
function permissions:__le(other)
    return #self:listAll() < #other:listAll()
end

--Merge 2 permissions into a new one
function permissions:__add(other)
    local allowText = self.allowText or other.allowText
    local allowVoice = self.allowVoice or other.allowVoice
    local bitfield = bor(self.bitfield, other.bitfield)
    return self.class(bitfield, allowText, allowVoice)
end

--Remove some permissions, and give a new object
function permissions:__sub(other)
    local allowText = self.allowText and other.allowText
    local allowVoice = self.allowVoice and other.allowVoice
    local new = self.class(self.bitfield, allowText, allowVoice)
    new:set(false, unpack(other:listAll()))
    return new
end

--Invert the current permissions, and give a new object
function permissions:__unm()
    local new = self.class(self.bitfield, self.allowText, self.allowVoice)
    new:toggleAll()
    return new
end

--== Internal Methods ==--

function permissions:_calculateMask()
    self.mask = 0
    for k,v in pairs(permissionsTable) do
        --If it doesn't violate any of the 2 rules
        if not ((not self.allowText and v[5]) or (not self.allowVoice and v[6])) then
            self.mask = self.mask + v[3]
        end
    end
end

return permissions