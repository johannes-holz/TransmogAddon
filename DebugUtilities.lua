local folder, core = ...

--------------- Globals for easier debugging ------------------------

AM = core.am
-- TODO: REMOVE! just used for debug
Addy = core
_G["core"] = core


-- Just for Debugging
core.MS = function(self, tab)
	local old = collectgarbage("count")
	local tmp = self.DeepCopy(tab)
	local new = collectgarbage("count")
	collectgarbage("collect")
	return new - old
end

core.WipeRec = function(self, tab)
	local count = 0
	for k, v in pairs(tab) do
		if type(v) == "table" then
			self:WipeRec(v)
		end
		tab[k] = nil
		count = count + 1
	end

	for i = count + 1, count * 2 do
		tab[i] = nil
	end
end

-- Bobby = function()
--     core:WipeRec(core.itemInfo)
--     core:WipeRec(core.displayIDs)
--     collectgarbage("collect")
-- end

MSChildren = function( tab)
	for k, v in pairs(tab) do
		local mem = core:MS(v)
		if mem > 1 then
			print(k, mem)
		end
	end
end

CountRec = function(tab)
	local count = 0

	for k, v in pairs(tab) do
		if type(v) == "table" then
			count = count + CountRec(v)
		else
			count = count + 1
		end
	end

	return count
end
