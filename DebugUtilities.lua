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



-- Globals used to test and compare stuff
STABLESIZE = function(tab)
	local c = 40
	for k, v in pairs(tab) do
		c = c + 4
		if type(v) == "table" then
			c = c + STABLESIZE(v)
		elseif type(v) == "string" then
			c = c + 16 + #v
		end
	end
	return c
end

local compressed = {}
COMPRI = function(withCompress)
	local nameStrings = {}
	local slot = "MainHandSlot"
	-- for _, slot in pairs(core.itemSlots) do
		for inventoryType, _ in pairs(core.slotItemTypes[slot]) do
			for cat, stringData in pairs(core.stringData[inventoryType]) do
				if not category or category == cat then
					tinsert(nameStrings, stringData.names) 
				end
			end
		end
	-- end

	local L = LibStub:GetLibrary("LibDeflate")
	local t1 = GetTime()

	-- local compressed = {}
	local lengthNormal = 0
	if withCompress then
		for i, names in pairs(nameStrings) do
			compressed[i] = L:CompressDeflate(names)
			lengthNormal = lengthNormal + #names
		end
	end

	local t2 = GetTime()
	
	local lengthCompressed = 0
	for i, names in pairs(compressed) do
		L:DecompressDeflate(names)
		lengthCompressed = lengthCompressed + #names
	end

	local t3 = GetTime()

	print("Compress:", t2 - t1, "Uncompress:", t3 - t2)
	print("normalLenght", lengthNormal, "compressed", lengthCompressed)
end

TESTI = function()
	local L = LibStub:GetLibrary("LibDeflate")
	for _, slot in pairs(core.itemSlots) do
		for inventoryType, _ in pairs(core.slotItemTypes[slot]) do
			for cat, stringData in pairs(core.stringData[inventoryType]) do
				if not category or category == cat then
					stringData.names = L:CompressDeflate(stringData.names)
				end
			end
		end
	end
end