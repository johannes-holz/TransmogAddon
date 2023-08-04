local Utils = LibStub:NewLibrary("RAPI_Utils", 1)
if not Utils then return end


local Promise = LibStub:GetLibrary("deferred")


function Utils.SplitAt(str, index)
	return string.sub(str, 1, index - 1), string.sub(str, index)
end


local C_Timer = {
	frame = nil,
	timers = {},
}
function C_Timer.After(duration, callback)
	if not C_Timer.frame then -- setup
		C_Timer.frame = CreateFrame("Frame")
		C_Timer.frame:SetScript("OnUpdate", function(self, elapsed)
			local i = 1
			while i <= #C_Timer.timers do
				local timer = C_Timer.timers[i]

				if elapsed >= timer.duration then
					timer.callback()
					table.remove(C_Timer.timers, i)
				else
					timer.duration = timer.duration - elapsed
					i = i + 1
				end
			end
		end)
	end

	table.insert(C_Timer.timers, { callback = callback, duration = duration })
end

function Utils.Wait(duration)
	local promise = Promise.New()
	C_Timer.After(duration, function()
		promise:resolve()
	end)
	return promise
end


function Utils.Extract(key)
	return function(object)
		return object[key]
	end
end

function Utils.Noop() end


local beforeUpdateFrame = CreateFrame("Frame")
local beforeUpdateQueue = {}
beforeUpdateFrame:SetScript("OnEvent", function()
	for _, func in ipairs(beforeUpdateQueue) do
		func()
	end
	beforeUpdateQueue = nil
end)
beforeUpdateFrame:RegisterEvent("PLAYER_LOGIN")

function Utils.DoAfterLogin(func)
	if (beforeUpdateQueue) then
		table.insert(beforeUpdateQueue, func)
	else
		func()
	end
end


-- Dump

local function formatLiteral(literal, prefix)
	if (type(literal) == "string") then
		return "\"" .. string.gsub(literal, "\124", "\124\124") .. "\""
	elseif (type(literal) == "table") then
		return "[" .. (prefix and (prefix .. ": ") or "") .. tostring(literal) .. "]"
	elseif (type(literal) == "function") then
		return "[" .. tostring(literal) .. "]"
	else
		return tostring(literal)
	end
end

local function isEmpty(obj)
	for key, value in pairs(obj) do
		return false
	end
	return true
end

local function isSmallArray(tbl)
	local maxIndex = #tbl
	if (maxIndex > 10) then
		return false
	end

	for key, value in pairs(tbl) do
		if (type(key) ~= "number" or key < 1 or key > maxIndex or type(value) == "table") then
			return false
		end
	end

	return true
end

local function dumpImpl(obj, alreadySeen, currDepth)
	if (type(obj) == "table" and currDepth <= 10) then
		alreadySeen[obj] = true

		if (isEmpty(obj)) then return "{}" end

		if (isSmallArray(obj)) then
			local result = "{ "
			for i = 1, #obj do
				result = result .. formatLiteral(obj[i]) .. ", "
			end
			return result .. "}"
		end

		local result = "{ "

		for key, value in pairs(obj) do
			result = result .. "[" .. formatLiteral(key) .. "] = "
			if (alreadySeen[value]) then
				result = result .. formatLiteral(value, "skipped (recursive)")
			else
				result = result .. dumpImpl(value, alreadySeen, currDepth + 1)
			end
			result = result .. ", "
		end

		return result .. "}"
	else
		return formatLiteral(obj)
	end
end

function Utils.Dump(object)
	return dumpImpl(object, {}, 1)
end

-- Event registry
local function safeCall(func, ...)
	local args = { ... }
	xpcall(function() func(unpack(args)) end, geterrorhandler())
end

local nextEventId = 0
local currentEventFiring = nil

local function registerEvent(self, event, handler)
	if (event == currentEventFiring) then
		error("Cannot register for a new event while the same event is currently firing")
	end

	local new = false
	if (self._events[event] == nil) then
		self._events[event] = {}
		new = true
	end

	local id = nextEventId
	nextEventId = nextEventId + 1
	self._events[event][id] = handler

	if (new and self._onUsed) then
		self._onUsed(event)
	end

	return function()
		self._events[event][id] = nil

		if (next(self._events[event]) == nil) then
			self._events[event] = nil
			if (self._onUnused) then
				self._onUnused(event)
			end
		end
	end
end

local function fireEvent(self, event, ...)
	assert(currentEventFiring == nil, "Recursively firing events is not supported")
	currentEventFiring = event
	local handlers = self._events[event]
	if (handlers ~= nil) then
		for _, handler in pairs(handlers) do
			safeCall(handler, ...)
		end
	end
	currentEventFiring = nil
end

function Utils.CreateEventRegistry(onUsed, onUnused)
	return {
		_events = {},
		_onUsed = onUsed,
		_onUnused = onUnused,
		register = registerEvent,
		fire = fireEvent,
	}
end
