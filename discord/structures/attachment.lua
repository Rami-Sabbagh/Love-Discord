--- Attachment class
-- @classmod discord.attachment

local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local attachment = class("discord.structures.Attachment")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function attachment:initialize(data)
    Verify(data, "data", "table")

    --== Basic Fields ==--

    self.id = discord.snowflake(data.id) --Attachment ID (snowflake)
    self.filename = data.filename --Name of file attached (string)
    self.size = data.size --Size of file in bytes (number)
    self.url = data.url --Source url of file (string)
    self.proxyURL = data.proxy_url --A proxied url of file (string)

    --== Optional Fields ==--

    self.height = data.height --Height of file (if image) (number)
    self.width = data.width --Width of file (if image) (number)
end

--== Methods ==--

function attachment:getID() return self.id end
function attachment:getFilename() return self.filename end
function attachment:getSize() return self.size end
function attachment:getURL() return self.url end
function attachment:getProxyURL() return self.proxyURL end
function attachment:getHeight() return self.height end
function attachment:getWidth() return self.width end

function attachment:isImage() return not not (self.width and self.height) end

return attachment