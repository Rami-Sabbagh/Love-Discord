local discord = ... --Passed as an argument.
local class = discord.class --Middleclass.

local embed = class("discord.structures.Embed")

--A function for verifying the arguments types of a method
local function Verify(value, name, ...)
    local vt, types = type(value), {...}
    for _, t in pairs(types) do if vt == t or (t=="nil" and not v) then return end end --Verified successfully
    types = table.concat(types, "/")
    local emsg = string.format("%s should be %s, provided: %s", name, types, vt)
    error(emsg, 3)
end

--New guild member object
function embed:initialize(data)
    Verify(data, "data", "table", "nil")

    data = data or {}
    
    --== Optional Fields ==--

    self.title = data.title --Title of embed (string)
    self.type = data.type --Type of embed (string)
    self.description = data.description --Description of embed (string)
    self.url = data.url --URL of embed (string)
    self.timestamp = data.timestamp --Timestamp of embed content (number)
    self.color = data.color --Color code of the embed (number) --TODO: COLOR OBJECT
    if data.footer then --Footer information
        self.footer = {
            text = data.footer.text,
            iconURL = data.footer.icon_url,
            proxyIconURL = data.proxy_icon_url
        }
    end
    if data.image then --Image information
        self.image = {
            url = data.image.url,
            proxyURL = data.image.proxyURL,
            height = data.image.height,
            width = data.image.width
        }
    end
    if data.thumbnail then --Thumbnail information
        self.thumbnail = {
            url = data.thumbnail.url,
            proxyURL = data.thumbnail.proxyURL,
            height = data.thumbnail.height,
            width = data.thumbnail.width
        }
    end
    if data.video then --Video information
        self.video = {
            url = data.video.url,
            height = data.video.height,
            width = data.video.width
        }
    end
    if data.provider then --Provider information
        self.provider = {
            name = data.provider.name,
            url = data.provider.url
        }
    end
    if data.author then --Author information
        self.author = {
            name = data.author.name,
            url = data.author.url,
            iconURL = data.author.icon_url,
            proxyIconURL = data.author.proxy_icon_url
        }
    end
    self.fields = data.fields or {} --Fields information
end

--== Methods ==--

--Getters--
function embed:getTitle() return self.title end
function embed:getType() return self.type end
function embed:getDescription() return self.description end
function embed:getURL() return self.url end
function embed:getTimestamp() return self.timestamp end
function embed:getColor() return self.color end
function embed:getFooter()
    if self.footer then
        return self.footer.text, self.footer.iconURL, self.footer.proxyIconURL
    end
end
function embed:getImage()
    if self.image then
        return self.image.url, self.image.proxyURL, self.image.width, self.image.height
    end
end
function embed:getThumbnail()
    if self.thumbnail then
        return self.thumbnail.url, self.thumbnail.proxyURL, self.thumbnail.width, self.thumbnail.height
    end
end
function embed:getVideo()
    if self.video then
        return self.video.url, self.video.width, self.video.height
    end
end
function embed:getProvider()
    if self.provider then
        return self.provider.name, self.provider.url
    end
end
function embed:getAuthor()
    if self.author then
        return self.author.name, self.author.url, self.author.iconURL, self.author.proxyIconURL
    end
end
function embed:getFieldsCount() return #self.fields end
function embed:getField(id)
    Verify(id, "id", "number")
    id = math.floor(id)
    local field = self.fields[id]
    if field then
        return field.name, field.value, field.inline
    end
end
function embed:getAll()
    local e = {}

    e.title = self.title
    e.type = self.type
    e.description = self.description
    e.url = self.url
    e.timestamp = self.timestamp
    e.color = self.color
    if self.footer then
        e.footer = {
            text = self.footer.text,
            icon_url = self.footer.iconURL,
            proxy_icon_url = self.footer.proxy_icon_url
        }
    end
    if self.image then
        e.image = {
            url = self.image.url,
            proxy_url = self.image.proxyURL,
            width = self.image.width,
            height = self.image.height
        }
    end
    if self.thumbnail then
        e.thumbnail = {
            url = self.thumbnail.url,
            proxy_url = self.thumbnail.proxyURL,
            width = self.thumbnail.width,
            height = self.thumbnail.height
        }
    end
    if self.video then
        e.video = {
            url = self.video.url,
            width = self.video.width,
            height = self.video.height
        }
    end
    if self.provider then
        e.provider = {
            name = self.provider.name,
            url = self.provider.url
        }
    end
    if self.author then
        e.author = {
            name = self.author.name,
            url = self.author.url,
            icon_url = self.author.iconURL,
            proxy_icon_url = self.author.proxyIconURL
        }
    end
    if #self.fields > 0 then
        e.fields = {}
        for id, field in pairs(self.fields) do
            e.fields[id] = {
                name = field.name,
                value = field.value,
                inline = field.inline
            }
        end
    end

    return e
end

--Setters--
function embed:setTitle(title)
    Verify(title, "title", "string", "nil")
    if title and #title > 256 then return error("Title can't be more than 256 characters!") end
    self.title = title or nil
    return self
end

function embed:setType(type)
    Verify(type, "type", "string", "nil")
    self.type = type or nil
    return self
end

function embed:setDescription(description)
    Verify(description, "description", "string", "nil")
    if description and #description > 2048 then return error("Description can't be more than 2048 characters!") end
    self.description = description or nil
    return self
end

function embed:setURL(url)
    Verify(url, "url", "string", "nil")
    self.url = url or nil
    return self
end

function embed:setTimestamp(timestamp)
    Verify(timestamp, "timestamp", "number", "nil")
    self.timestamp = timestamp or nil
    return self
end

function embed:setColor(color)
    Verify(color, "color", "number", "nil")
    self.color = color or nill
    return self
end

function embed:setFooter(text, iconURL, proxyIconURL)
    Verify(text, "text", "string", "nil")
    Verify(iconURL, "iconURL", "string", "nil")
    Verify(proxyIconURL, "proxyIconURL", "string", "nil")

    --Clear Footer
    if not (text or iconURL or proxyIconURL) then
        self.footer = nil
    --Set Footer
    else
        if text and #text > 2048 then return error("Footer text can't be longer than 2048 characters!") end

        self.footer = {
            text = text or nil,
            iconURL = iconURL or nil,
            proxyIconURL = proxyIconURL or nil
        }
    end

    return self
end

function embed:setImage(url, proxyURL, width, height)
    Verify(url, "url", "string", "nil")
    Verify(proxyURL, "proxyURL", "string", "nil")
    Verify(width, "width", "number", "nil")
    Verify(height, "height", "number", "nil")

    --Clear Image
    if not (url or proxyURL or width or height) then
        self.image = nil
    --Set Image
    else
        self.image = {
            url = url or nil,
            proxyURL = proxyURL or nil,
            width = width or nil,
            height = height or nil
        }
    end

    return self
end

function embed:setThumbnail(url, proxyURL, width, height)
    Verify(url, "url", "string", "nil")
    Verify(proxyURL, "proxyURL", "string", "nil")
    Verify(width, "width", "number", "nil")
    Verify(height, "height", "number", "nil")

    --Clear Thumbnail
    if not (url or proxyURL or width or height) then
        self.thumbnail = nil
    --Set Thumbnail
    else
        self.thumbnail = {
            url = url or nil,
            proxyURL = proxyURL or nil,
            width = width or nil,
            height = height or nil
        }
    end

    return self
end

function embed:setVideo(url, width, height)
    Verify(url, "url", "string", "nil")
    Verify(width, "width", "number", "nil")
    Verify(height, "height", "number", "nil")

    --Clear Video
    if not (url or width or height) then
        self.video = nil
    --Set Video
    else
        self.video = {
            url = url or nil,
            proxyURL = proxyURL or nil,
            width = width or nil,
            height = height or nil
        }
    end

    return self
end

function embed:setProvider(name, url)
    Verify(name, "name", "string", "nil")
    Verify(url, "url", "string", "nil")

    --Clear Provider
    if not (name or url) then
        self.provider = nil
    --Set Provider
    else
        self.provider = {
            name = name or nil,
            url = url or nil
        }
    end

    return self
end

function embed:setAuthor(name, url, iconURL, proxyIconURL)
    Verify(name, "name", "string", "nil")
    Verify(url, "url", "string", "nil")
    Verify(iconURL, "iconURL", "string", "nil")
    Verify(proxyIconURL, "proxyIconURL", "string", "nil")

    --Clear Author
    if not (name or url or iconURL or proxyIconURL) then
        self.author = nil
    --Set Author
    else
        if name and #name > 256 then return error("Author name can't be more than 256 characters!") end

        self.author = {
            name = name or nil,
            url = url or nil,
            iconURL = iconURL or nil,
            proxyIconURL = proxyIconURL or nil
        }
    end

    return self
end

function embed:setField(id, name, value, inline)
    Verify(id, "id", "number")
    id = math.floor(id)
    if id < 1 or id > 25 then return error("Field id must be a number between 1 and 25") end
    if not (name and value) and (name or value) then return error("Both name and value are required!") end
    if name then --Set field
        name, value = tostring(name), tostring(value)
        if #name > 1024 then return error("Field name can't be more than 1024 characters!") end
        if #value > 2048 then return error("Field value can't be more than 2048 characters!") end

        --Create fields before this field
        if id > 1 and not self.fields[id-1] then
            for i=1, id-1 do
                self.fields[i] = {
                    name = "",
                    value = ""
                }
            end
        end

        --Set the actual field
        self.fields[id] = {
            name = name,
            value = value,
            inline = not not inline
        }
    else --Clear field
        table.remove(self.fields, id)
    end

    return self
end

return embed