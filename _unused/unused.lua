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