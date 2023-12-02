local folder, core = ...


local invSlots = {
	INVTYPE_HEAD = "HeadSlot",
	INVTYPE_SHOULDER = "ShoulderSlot",
	INVTYPE_BODY = "ShirtSlot",
	INVTYPE_CLOAK = "BackSlot",
	INVTYPE_CHEST = "ChestSlot",
	INVTYPE_ROBE = "ChestSlot",
	INVTYPE_WAIST = "WaistSlot",
	INVTYPE_LEGS = "LegsSlot",
	INVTYPE_FEET = "FeetSlot",
	INVTYPE_WRIST = "WristSlot",
	INVTYPE_2HWEAPON = "MainHandSlot",
	INVTYPE_WEAPON = "MainHandSlot",
	INVTYPE_WEAPONMAINHAND = "MainHandSlot",
	INVTYPE_WEAPONOFFHAND = "SecondaryHandSlot",
	INVTYPE_SHIELD = "SecondaryHandSlot",
	INVTYPE_HOLDABLE = "SecondaryHandSlot",
	INVTYPE_RANGED = "RangedSlot",
	INVTYPE_RANGEDRIGHT = "RangedSlot",
	INVTYPE_THROWN = "RangedSlot",
	INVTYPE_HAND = "HandsSlot",
	INVTYPE_TABARD = "TabardSlot",
}

-- not working as intended
core.CreateDefaultTable = function(f)
	assert(type(f) == "function")
	local tbl, mtbl = {}, {}
	mtbl.__index = function(tbl, key)
		local val = rawget(tbl, key)
		return val or f()
	end
	setmetatable(tbl, mtbl)
	return tbl
end



outfitFrame.OnUpdate = function(self, elapsed)
	self.interval = 0.02
	self.e = (self.e or self.interval) - elapsed

	if self.e < 0 then
		self.e = self.e + self.interval
				 
		local doNotHide = UIDropDownMenu_GetCurrentDropDown() == self.outfitDDM and DropDownList1:IsShown()

		if not core.MouseIsOver(self) then
			self.targetAlpha = 0.6
		end

		local alpha = self:GetAlpha()
		local done = false
		if alpha <= self.targetAlpha then
			alpha = alpha + 0.05
			if alpha > self.targetAlpha then
				alpha = self.targetAlpha
			end
		elseif not doNotHide then
			alpha = alpha - 0.05                
			if alpha < self.targetAlpha then
				alpha = self.targetAlpha
				done = true
			end
		end
		self:SetAlpha(alpha)
		if done then
			self:SetScript("OnUpdate", nil)
		end
	end
end

outfitFrame.OnEnter = function(self)
	self.targetAlpha = 1
	self:SetScript("OnUpdate", self.OnUpdate)
end

outfitFrame:SetScript("OnEnter", outfitFrame.OnEnter)

-- compare speed of indexing single bytes from different strings or one block of bytes from one string.
-- the latter seems to be ~4times faster for larger amount of iterations
-- but for our use case where we have to iterate over ~5k items per slot, both options are totally viable (3ms vs 1ms on my machine)
TESTO = function()
	if not core.testo1 then
		for i = 1, 5 do
			core["testo" .. i] = strsub(core.awa, i * 100, 150000)
		end
	end

	local t1 = GetTime()
	local maxIter = 1
	local maxIndex = 5000
	for j = 1, maxIter do
		for i=1,maxIndex do
			local a = strbyte(core.awa, i)
			local b = strbyte(core.testo1, i + 100)
			local c = strbyte(core.testo2, i + 1000)
			local d = strbyte(core.testo3, i + 1030)
			local e = strbyte(core.testo4, i + 1001)
			local s = a + b + c + d + e
		end
	end
	print("Split strings time:", GetTime() - t1)

	
	local t1 = GetTime()
	for j = 1, maxIter do
		for i=1,maxIndex do
			local a, b, c, d, e = strbyte(core.awa, i, i + 4)
			local s = a + b + c + d + e
		end
	end
	print("One string time:", GetTime() - t1)
end


-- compared iterating over list of id tables vs list of string. tables are ~50% faster, not worth the memory overhead
core.itemIterator4 = function(slot, category, withNames)
	local strings = {}
	for inventoryType, _ in pairs(slotItemTypes[slot]) do
		for cat, itemIDs in pairs(core.testo.itemData[inventoryType]) do
			if not category or category == cat then
				tinsert(strings, itemIDs) -- strings are unique in lua, won't copy the string  
			end
		end
	end
	if #strings == 0 then return nil end

	local i, j = 0, 1
	return function()
		i = i + 1
		if i > #strings[j] then
			j = j + 1
			i = 1
		end
		if j > #strings then return nil end
		
		return strings[j][i]
	end
end

TESTO = function()
	local t1 = GetTime()
	local maxIter = 100
	local maxIndex = 5000
	for j = 1, maxIter do
		local c = 0
		for itemID in core.itemIterator3("MainHandSlot") do
			c = c + 1
			local name = GetItemInfo(itemID) or core.names[itemID]
		end
	end
	print("Iter3 time:", GetTime() - t1)

	
	local t1 = GetTime()
	for j = 1, maxIter do
		local c = 0
		for itemID in core.itemIterator4("MainHandSlot") do
			c = c + 1
			local name = GetItemInfo(itemID) or core.names[itemID]
		end
	end
	print("Iter4 time:", GetTime() - t1)
end