local M = LibStub:NewLibrary("deferred", 1)
if not M then return end

local deferred = {}
deferred.__index = deferred

local PENDING = 0
local RESOLVING = 1
local REJECTING = 2
local RESOLVED = 3
local REJECTED = 4

local function finish(deferred, state)
	state = state or REJECTED
	for i, f in ipairs(deferred.queue) do
		if state == RESOLVED then
			f:resolve(deferred.value)
		else
			f:reject(deferred.value)
		end
	end
	deferred.state = state
end

local function isfunction(f)
	if type(f) == 'table' then
		local mt = getmetatable(f)
		return mt ~= nil and type(mt.__call) == 'function'
	end
	return type(f) == 'function'
end

local function promise(deferred, next, success, failure, nonpromisecb)
	if type(deferred) == 'table' and type(deferred.value) == 'table' and isfunction(next) then
		local called = false
		local ok, err = pcall(next, deferred.value, function(v)
			if called then return end
			called = true
			deferred.value = v
			success()
		end, function(v)
			if called then return end
			called = true
			deferred.value = v
			failure()
		end)
		if not ok and not called then
			deferred.value = err
			failure()
		end
	else
		nonpromisecb()
	end
end

local function fire(deferred)
	local next
	if type(deferred.value) == 'table' then
		next = deferred.value.next
	end
	promise(deferred, next, function()
		deferred.state = RESOLVING
		fire(deferred)
	end, function()
		deferred.state = REJECTING
		fire(deferred)
	end, function()
		local ok
		local v
		if deferred.state == RESOLVING and isfunction(deferred.success) then
			ok, v = pcall(deferred.success, deferred.value)
		elseif deferred.state == REJECTING and isfunction(deferred.failure) then
			ok, v = pcall(deferred.failure, deferred.value)
			if ok then
				deferred.state = RESOLVING
			end
		end

		if ok ~= nil then
			if ok then
				deferred.value = v
			else
				deferred.value = v
				return finish(deferred)
			end
		end

		if deferred.value == deferred then
			deferred.value = pcall(error, 'resolving promise with itself')
			return finish(deferred)
		else
			promise(deferred, next, function()
				finish(deferred, RESOLVED)
			end, function(state)
				finish(deferred, state)
			end, function()
				finish(deferred, deferred.state == RESOLVING and RESOLVED)
			end)
		end
	end)
end

local function resolve(deferred, state, value)
	if deferred.state == 0 then
		deferred.value = value
		deferred.state = state
		fire(deferred)
	end
	return deferred
end

--
-- PUBLIC API
--
function deferred:resolve(value)
	return resolve(self, RESOLVING, value)
end

function deferred:reject(value)
	return resolve(self, REJECTING, value)
end

function deferred:catch(failure)
	return self:next(nil, failure)
end

function deferred:finally(onFinally)
	return self:next(
		function(v)
			onFinally()
			return v
		end,
		function(e)
			onFinally()
			error(e)
		end
	)
end

function M.New(options)
	if isfunction(options) then
		local d = M.New()
		local ok, err = pcall(options, d)
		if not ok then
			d:reject(err)
		end
		return d
	end
	options = options or {}
	local d
	d = {
		next = function(self, success, failure)
			local next = M.New({success = success, failure = failure, extend = options.extend})
			if d.state == RESOLVED then
				next:resolve(d.value)
			elseif d.state == REJECTED then
				next:reject(d.value)
			else
				table.insert(d.queue, next)
			end
			return next
		end,
		state = 0,
		queue = {},
		success = options.success,
		failure = options.failure,
	}
	d = setmetatable(d, deferred)
	if isfunction(options.extend) then
		options.extend(d)
	end
	return d
end

function M.All(args)
	local d = M.New()
	if #args == 0 then
		return d:resolve({})
	end

	local pending = #args
	local results = {}

	local function handleResolve(i)
		return function(value)
			if (results ~= nil) then
				results[i] = value
				pending = pending - 1
				if pending == 0 then
					d:resolve(results)
				end
			end
		end
	end

	local function handleReject(err)
		results = nil
		d:reject(err)
	end

	for i = 1, pending do
		args[i]:next(handleResolve(i), handleReject)
	end
	return d
end

function M.AllSettled(args)
	local d = M.New()
	if #args == 0 then
		return d:resolve({})
	end

	local pending = #args
	local results = {}

	local function handleSettled(i, resolved)
		return function(value)
			if (resolved) then
				results[i] = { status = "fulfilled", value = value }
			else
				results[i] = { status = "rejected", reason = value }
			end
			pending = pending - 1
			if pending == 0 then
				d:resolve(results)
			end
		end
	end

	for i = 1, pending do
		args[i]:next(handleSettled(i, true), handleSettled(i, false))
	end
	return d
end

function M.Any(args)
	local d = M.New()
	if #args == 0 then
		return d:reject({})
	end

	local pending = #args
	local errors = {}

	local function handleResolve(val)
		d:resolve(val)
	end

	local function handleError(i)
		return function(err)
			errors[i] = err
			pending = pending - 1
			if pending == 0 then
				d:reject(errors)
			end
		end
	end

	for i = 1, pending do
		args[i]:next(handleResolve, handleError(i))
	end

	return d
end

function M.Race(args)
	local d = M.New()
	for _, v in ipairs(args) do
		v:next(function(res)
			d:resolve(res)
		end, function(err)
			d:reject(err)
		end)
	end
	return d
end

function M.Resolved(value)
	return M.New():resolve(value)
end

function M.Rejected(err)
	return M.New():reject(err)
end
