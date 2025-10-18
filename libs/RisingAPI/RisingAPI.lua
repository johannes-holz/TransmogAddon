local NAME, VERSION = "RisingAPI", 3
local RisingAPI = LibStub:NewLibrary(NAME, VERSION)
LibStub(NAME)._currentModuleVersion = VERSION -- for module registration only (NOT necessarily the actual library version)
if not RisingAPI then return end


-- #######################################
-- ## Includes
local Promise = LibStub:GetLibrary("deferred")
local JSON = LibStub:GetLibrary("json.lua")
local logger = LibStub:GetLibrary("RAPI_Logger").New(YELLOW_FONT_COLOR_CODE .. "[API:%s] " .. FONT_COLOR_CODE_CLOSE)
local Utils = LibStub:GetLibrary("RAPI_Utils")

local wait, splitAt, doAfterLogin, dump = Utils.Wait, Utils.SplitAt, Utils.DoAfterLogin, Utils.Dump


-- #######################################
-- ## Constants
local PREFIX_CLIENT_REQUEST = "APIC"
local PREFIX_SERVER_REQUEST = "APIS"
local PREFIX_LENGTH = 4
local SERVER_NAME = "Server"
local REQUEST_TIMEOUT = 10

local LOG_OUT = "OUT"
local LOG_IN = "IN"

local MAX_CONTENT_LENGTH = 255 - PREFIX_LENGTH - 2 -- message length (prefix + wow's internal separator (1) + transaction id (1) + message length) must not exceed 255


-- #######################################
-- ## Misc
RisingAPI.Utils = Utils

function RisingAPI:debug(level)
	if (type(level) == "nil") then
		level = logger.INFO
	elseif (type(level) == "boolean") then
		level = level and logger.INFO or logger.DISABLED
	end

	logger:setLevel(level)

	if (logger:isEnabled()) then
		print("[API] Debug mode enabled.")
	else
		print("[API] Debug mode disabled.")
	end
end

-- #######################################
-- ## Client to server communication
RisingAPI._clientRequests = RisingAPI._clientRequests or {}
RisingAPI._lastRequestId = 0

local function increment(id)
	id = id + 1
	return (id > 127) and (id - 127) or id
end
function RisingAPI:_generateId()
	local id = increment(self._lastRequestId)
	while id ~= self._lastRequestId do
		if self._clientRequests[id] == nil then -- found free request id
			self._lastRequestId = id
			return id
		end

		id = increment(id)
	end

	error("failed to generate request id (all ids in use)")
end

local function splitContent(msg)
	local parts = {}
	local curr = nil
	local rest = msg

	while string.len(rest) > MAX_CONTENT_LENGTH do
		curr, rest = splitAt(rest, MAX_CONTENT_LENGTH + 1)
		table.insert(parts, curr)
	end

	table.insert(parts, rest)

	return parts
end

local function unpackValues(values)
	if (type(values) ~= "table") then
		return values
	end

	local newValues = {}

	for key, value in pairs(values) do
		if (type(key) == "number") then
			newValues[value] = true
		else
			newValues[key] = unpackValues(value)
		end
	end

	return newValues
end
RisingAPI.UnpackValues = unpackValues

function RisingAPI:request(opcode, params, requestedValues)
	local id = self:_generateId()
	local headerMid = string.char(id)
	local headerEnd = string.char(id + 127)

	local promise = Promise.New()
	self._clientRequests[id] = {
		promise = promise,
		response = {},
	}

	local requestBody = {
		opcode = opcode,
		params = params or {},
		request = unpackValues(requestedValues) or {},
	}

	requestBody.params.__json_object = true
	requestBody.request.__json_object = true

	logger:info(LOG_OUT, function() return "sending request (%d): %s", id, dump(requestBody) end)
	logger:trace(LOG_OUT, "outgoing request messages:")

	local messages = splitContent(JSON.Encode(requestBody))
	for i, message in ipairs(messages) do
		local header = (i == #messages) and headerEnd or headerMid
		logger:trace(LOG_OUT, YELLOW_FONT_COLOR_CODE .. "%d:" .. FONT_COLOR_CODE_CLOSE .. " %s", i, message)

		-- SendAddonMessage seems to drop messages if called too early in the loading process, but after PLAYER_LOGIN seems fine
		doAfterLogin(function()
			SendAddonMessage(PREFIX_CLIENT_REQUEST, header .. message, "WHISPER", SERVER_NAME)
		end)
	end

	wait(REQUEST_TIMEOUT):next(function()
		local request = self._clientRequests[id]
		if request and request.promise == promise then -- check whether our request is still open
			logger:info(LOG_OUT, "request (%d) timeout", id)
			promise:reject({ message = "request failed (timeout)" })
			self._clientRequests[id] = nil
		end
	end)

	return promise
end

function RisingAPI:_handleServerResponse(id, message, done)
	logger:trace(LOG_IN, "incoming server response message (%d): %s", id, message)

	local request = self._clientRequests[id]
	if not request then
		logger:error("invalid request id (request does not exist, might be caused by a previous request timeout)")
		return
	end

	table.insert(request.response, message)

	if done then
		local response = JSON.Decode(table.concat(request.response))
		if type(response) == "table" and response.error ~= nil then
			logger:info(LOG_IN, "rejecting with error (%d): %s", id, response.error)
			response.error, response.message = nil, response.error
			request.promise:reject(response)
		else
			logger:info(LOG_IN, function() return "resolving (%d): %s", id, dump(response) end)
			request.promise:resolve(response)
		end
		self._clientRequests[id] = nil
	end
end

-- #######################################
-- ## Server to client communication
RisingAPI._serverRequests = RisingAPI._serverRequests or {}

RisingAPI._events = RisingAPI._events or Utils.CreateEventRegistry(
	function(event)
		RisingAPI:request("event/register", { event = event }):catch(function(err)
			logger:error("failed to register for event \"%s\": %s", event, err.message)
		end)
	end,
	function(event)
		RisingAPI:request("event/unregister", { event = event }):catch(function(err)
			logger:error("failed to unregister from event \"%s\": %s", event, err.message)
		end)
	end
)

function RisingAPI:_handleServerRequest(id, message, done)
	logger:trace(LOG_IN, "incoming server request message (%d): %s", id, message)

	if not self._serverRequests[id] then
		self._serverRequests[id] = {
			parts = {}
		}
	end

	local request = self._serverRequests[id]

	table.insert(request.parts, message)

	if done then
		self._serverRequests[id] = nil
		local content = JSON.Decode(table.concat(request.parts))
		logger:info(LOG_IN, function() return "incoming server request (%d): %s", id, dump(content) end)

		if type(content) ~= "table" then
			error(("invalid request format (expected table, got %s)"):format(type(content)))
			return
		end

		-- note: The client library currently only supports events (= server requests with opcode "event/fire"
		-- and no response of the client). More complex requests may be implemented in the future.
		if content.opcode ~= "event/fire" then
			error(("recieved server request with opcode \"%s\", but only \"event/fire\" supported"):format(content.opcode))
		end

		logger:info(LOG_IN, "firing event: %s", content.event)
		self._events:fire(content.event, content.payload)
	end
end

function RisingAPI:registerEvent(event, handler)
	return self._events:register(event, handler)
end

-- #######################################
-- ## Setup CHAT_MSG_ADDON listener
local function parseMessage(message)
	if string.len(message) < 2 then
		error("invalid message (message must have at least 2 characters)") -- at least the request id and 1 char of content
	end

	local id, content = splitAt(message, 2)
	id = string.byte(id)

	if id < 1 or id > 254 then
		error("invalid request id (out of range [1, 254])")
	end

	local done = false
	if id > 127 then
		done = true
		id = id - 127
	end

	return id, content, done
end

RisingAPI._frame = RisingAPI._frame or CreateFrame("Frame")
RisingAPI._frame:RegisterEvent("CHAT_MSG_ADDON")
RisingAPI._frame:SetScript("OnEvent", function(self, event, prefix, message, dist, sender)
	logger:trace(LOG_IN, "incoming message (prefix: %s, sender: %s): %s", prefix, sender, message)
	if sender ~= SERVER_NAME then
		return
	end

	if prefix == PREFIX_CLIENT_REQUEST then
		RisingAPI:_handleServerResponse(parseMessage(message))
	elseif prefix == PREFIX_SERVER_REQUEST then
		RisingAPI:_handleServerRequest(parseMessage(message))
	end
end)

-- #######################################
-- ## Modules
function RisingAPI:newModule(name)
	local old = self[name]
	if old and old._version >= self._currentModuleVersion then
		return nil
	end
	self[name] = self[name] or {}
	self[name]._version = self._currentModuleVersion
	return self[name], self
end
