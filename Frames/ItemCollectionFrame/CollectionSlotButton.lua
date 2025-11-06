local folder, core = ...

-- TODO: Item and enchant slot pretty much work the same now, combine the code into one button generator

local SlotButton_OnEnter = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(core.SLOT_NAMES[self.itemSlot])
	GameTooltip:Show()
end

local SlotButton_OnLeave = function(self)
	GameTooltip:Hide()
end

local SlotButton_OnClick = function(self, button)
	core.itemCollectionFrame:SetSlotAndCategory(self.itemSlot, nil)
end

core.CreateSlotButtonFrame = function(parent, transmogLocation, size)
	local locationID, inventorySlot, slotID, textureName, itemSlot = core.GetTransmogLocationInfo(transmogLocation)
	local f = core.CreateMeACustomTexButton(parent, size, size, textureName, 9/64, 9/64, 54/64, 54/64)
	
	f.selectedTexture = f:CreateTexture(nil, "OVERLAY")
	
	-- custom frame
	f.selectedTexture:SetTexture("Interface\\AddOns\\".. folder .."\\Images\\Buttons")
	f.selectedTexture:SetTexCoord(0, 66/512, 146/512, 212/512)
	f.selectedTexture:SetSize(1.28 * size, 1.28 * size)

	-- achievement icon frame, is this always loaded?
	-- f.selectedTexture:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
	-- f.selectedTexture:SetTexCoord(0, 72/128, 0, 72/128)
	-- f.selectedTexture:SetSize(1.26 * size, 1.26 * size)

	-- standard button highlight
	-- f.selectedTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	-- f.selectedTexture:SetTexCoord(0, 1, 0, 1)
	-- f.selectedTexture:SetBlendMode("ADD")
	-- f.selectedTexture:SetSize(size, size)
	
	f.selectedTexture:SetPoint("CENTER")
	f.selectedTexture:Hide()

	f.location = transmogLocation
	f.locationID = locationID
	f.slotID = slotID
	f.itemSlot = itemSlot
		
	f:EnableMouse()
	f:SetScript("OnEnter", SlotButton_OnEnter)
	f:SetScript("OnLeave", SlotButton_OnLeave)
	f:SetScript("OnClick", SlotButton_OnClick)
	
	return f
end

------- Enchant Buttons -----------------

local EnchantSlotButton_OnEnter = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(core.SLOT_NAMES[self.itemSlot])
	GameTooltip:Show()
end

local EnchantSlotButton_OnLeave = function(self)
	GameTooltip:Hide()
end

local EnchantSlotButton_OnClick = function(self, button)
	core.itemCollectionFrame:SetSlotAndCategory(self.itemSlot, nil)
end

core.CreateEnchantSlotButton = function(parent, slot, size)
	local f = core.CreateMeACustomTexButton(parent, size, size, "Interface\\Icons\\INV_Scroll_04", 9/64, 9/64, 54/64, 54/64)

	f.selectedTexture = f:CreateTexture(nil, "OVERLAY")

	f.selectedTexture:SetTexture("Interface\\AddOns\\".. folder .."\\Images\\Buttons")
	f.selectedTexture:SetTexCoord(0, 66/512, 146/512, 212/512)
	f.selectedTexture:SetSize(1.28 * size, 1.28 * size)

	-- f.selectedTexture:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
	-- f.selectedTexture:SetTexCoord(0, 72/128, 0, 72/128)
	-- f.selectedTexture:SetSize(1.26 * size, 1.26 * size)
	
	-- f.selectedTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
	-- f.selectedTexture:SetTexCoord(0, 1, 0, 1)
	-- f.selectedTexture:SetBlendMode("ADD")
	-- f.selectedTexture:SetSize(size, size)

	f.selectedTexture:SetPoint("CENTER")
	f.selectedTexture:Hide()
	
	f.itemSlot = slot

	f:SetScript("OnEnter", EnchantSlotButton_OnEnter)
	f:SetScript("OnLeave", EnchantSlotButton_OnLeave)
	f:SetScript("OnClick", EnchantSlotButton_OnClick)

	return f
end
