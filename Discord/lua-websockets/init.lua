local reqPrefix = ...
local frame = require(reqPrefix..".frame")

return {
  client = require(reqPrefix..".client"),
  CONTINUATION = frame.CONTINUATION,
  TEXT = frame.TEXT,
  BINARY = frame.BINARY,
  CLOSE = frame.CLOSE,
  PING = frame.PING,
  PONG = frame.PONG
}
