local folder, core = ...

-- ThoughtDump/TODO

local SlotButton_OnEnter = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(core.SLOT_NAMES[self.itemSlot])
	GameTooltip:Show()
end

local SlotButton_OnLeave = function(self)
	GameTooltip:Hide()
end

core.CreateSlotButtonFrame = function(self, parent, transmogLocation, size)
	local locationID, inventorySlot, slotID, textureName, itemSlot = core:GetTransmogLocationInfo(transmogLocation)
	--print(transmogLocation, locationID, inventorySlot, slotID, textureName)
	local f = core.CreateMeACustomTexButton(parent, size, size, textureName, 9/64, 9/64, 54/64, 54/64) --CreateMeATextButton(bar, 70, 24, "Undress")
	-- local f = core.CreateMeAButton(parent, 36, 36, nil,						
	-- 					textureName, 9/64, 9/64, 54/64, 54/64,
	-- 					"Interface/Buttons/UI-EmptySlot-White", 9/64, 9/64, 54/64,54/64,
	-- 					"Interface/Buttons/ButtonHilight-Square", 0, 0, 1, 1,
	-- 					"Interface/Buttons/UI-EmptySlot-Disabled", 9/64, 9/64, 54/64,54/64)

	
	f.selectedTexture = f:CreateTexture(nil, "ARTWORK")
	f.selectedTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	f.selectedTexture:SetTexCoord(106/512, 166/512, 338/512,397/512)
	f.selectedTexture:SetSize(1.26 * size, 1.26 * size)
	f.selectedTexture:SetPoint("CENTER")
	--f.selectedTexture:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale-1)
	--f.selectedTexture:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	f.selectedTexture:Hide()


	f.location = transmogLocation
	f.locationID = locationID
	f.slotID = slotID
	f.itemSlot = itemSlot

		
	f:EnableMouse()
	f:SetScript("OnEnter", SlotButton_OnEnter)
	f:SetScript("OnLeave", SlotButton_OnLeave)
	
	return f
end