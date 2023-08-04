local Lib = LibStub:NewLibrary("RAPI_Logger", 1)
if not Lib then return end


local sformat = string.format


local logger = {}
logger.__index = logger

logger.TRACE = 1
logger.INFO = 2
logger.ERROR = 3
logger.DISABLED = 10

function Lib.New(prefix)
	local obj = {
		_prefix = prefix or "[%s] ",
		_level = logger.DISABLED,
	}
	setmetatable(obj, logger)
	return obj
end

function logger:_shouldLog(level)
	return level >= self._level
end

function logger:setLevel(level)
	self._level = level
end

function logger:enable()
	self:setLevel(logger.INFO)
end

function logger:disable()
	self:setLevel(logger.DISABLED)
end

function logger:isEnabled()
	return self._level < logger.DISABLED
end

function logger:log(tag, level, msg, ...)
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

function logger:logError(tag, ...)
	return self:log(tag, logger.ERROR, ...)
end

function logger:logInfo(tag, ...)
	return self:log(tag, logger.INFO, ...)
end

function logger:logTrace(tag, ...)
	return self:log(tag, logger.TRACE, ...)
end

function logger:error(msg, ...)
	if self:_shouldLog(logger.ERROR) then
		error(sformat(msg, ...))
	end
end

function logger:assert(cond, msg, ...)
	if not cond and self:_shouldLog(logger.ERROR)  then
		error(sformat(msg, ...))
	end
end
