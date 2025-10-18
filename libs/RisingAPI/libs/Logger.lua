local Lib = LibStub:NewLibrary("RAPI_Logger", 1)
if not Lib then return end


local sformat = string.format


local Logger = {}
Logger.__index = Logger

Logger.TRACE = 1
Logger.INFO = 2
Logger.ERROR = 3
Logger.DISABLED = 10

function Lib.New(prefix)
	local obj = {
		_prefix = prefix or "[%s] ",
		_level = Logger.DISABLED,
	}
	setmetatable(obj, Logger)
	return obj
end

function Logger:_shouldLog(level)
	return level >= self._level
end

function Logger:setLevel(level)
	self._level = level
end

function Logger:enable()
	self:setLevel(Logger.INFO)
end

function Logger:disable()
	self:setLevel(Logger.DISABLED)
end

function Logger:isEnabled()
	return self._level < Logger.DISABLED
end

function Logger:log(tag, level, msg, ...)
	if self:_shouldLog(level) then
		if (type(msg) == "string") then
			print(sformat(self._prefix, tag) .. sformat(msg, ...))
		elseif (type(msg) == "function") then
			assert(select("#", ...) == 0)
			print(sformat(self._prefix, tag) .. sformat(msg()))
		else
			error("invalid log message type (expected string or function, got " .. type(msg) .. ")")
		end
	end
end

function Logger:error(tag, ...)
	return self:log(tag, Logger.ERROR, ...)
end

function Logger:info(tag, ...)
	return self:log(tag, Logger.INFO, ...)
end

function Logger:trace(tag, ...)
	return self:log(tag, Logger.TRACE, ...)
end
