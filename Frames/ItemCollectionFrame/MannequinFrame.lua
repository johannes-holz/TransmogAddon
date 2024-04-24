local folder, core = ...

-- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
local LIGHT = {
	default = {1,			-- enabled
		0, 0, 1, 0,			-- omni (enabled, r, g, b)
		1, 0.7, 0.7, 0.7,	-- ambient (enabled, r, g, b)
		1, 0.8, 0.8, 0.64,	-- directional (enabled, r, g, b)
	},
	shadowForm = {1,
		0, 0, 1, 0,
		1, 0.16, 0, 0.23,
		0,
	},
	locked = {1,
		0, 0, 1, 0,
		0.8, 0.7, 0.7, 0.7,
		0.8, 0.8, 0.8, 0.64,
	},
}
core.LIGHT = LIGHT

-- Model frames get reset to the initial position on SetUnit and OnHide, but their internal x, y, z values do not.
-- When calling SetPosition(x, y, z) it moves the model by the difference to its own internal position, so if we don't manage this ourselves, it will stop working as intended after SetUnit/Hide.
-- For Example: SetPosition(1, 0, 0) -> SetUnit("player") -> SetPosition(1, 0, 0). The second SetPosition call would not move the model away from the origin, since its internal x value is still 1.
-- There are different ways to fix this, I chose to reset the models to (0, 0, 0) before SetUnit and OnHide, so that the interal values match with what we see.
local Model_SetUnit = function(self, unit)
	local x, y, z = self:GetPosition()
	self:SetPosition(0, 0, 0)
	self:SetUnitOld(unit)
	self:SetPosition(x, y, z)
end

local Model_OnHide = function(self)
	self:SetPosition(0, 0, 0)
end

local Model_OnShow = function(self)
	self:SetUnit("player")
	self:Undress()
	if self.itemID then self:TryOn(self.itemID) end
end

local Model_GetID = function(self)
	return self.id
end

local Model_SetLoading = function(self, loading)
	core.SetShown(self.loadingFrame, loading)
	self.loading = loading
	if loading then
		self:SetFogColor(0.1, 0.1, 0.1)
		self:SetFogNear(0)
		self:SetFogFar(0.1)
	else
		--self:SetFogColor(nil)
		self:SetFogNear(10)
	end
end

-- Set and show display item. If we don't have the item cached, we query it and show a loading frame. The loading frame also periodically checks, if the item has been loaded
local Model_TryOn = function(self, itemID, slot)
	assert(type(itemID) == "number")  -- expects clean numerical itemID!
	self.itemID = itemID
	self.slot = slot
	-- slot = slot or self:GetParent():GetParent().selectedSlot

	if core.IsEnchantSlot(slot) then
		local dummyWeapon = (slot == "MainHandEnchantSlot" or core.CanDualWield()) and core.DUMMY_WEAPONS.ENCHANT_PREVIEW_WEAPON or core.DUMMY_WEAPONS.ENCHANT_PREVIEW_OFFHAND_WEAPON
		local itemString = "item:" .. dummyWeapon .. ":" .. (itemID == 0 and 0 or core.enchants[itemID]["enchantIDs"][1]) -- itemID is the enchantID in this case
		-- self:TryOnOld(1485) -- TODO: use equip to slot functionality instead of doing the weapon slot manipulation manually like this?
		-- self:TryOnOld("item:2000:" .. (itemID == 0 and 0 or core.enchants[itemID]["enchantIDs"][1]))
		self:Undress()
		if slot == "MainHandEnchantSlot" then 
			core.ShowMeleeWeapons(self, itemString, nil)
		elseif slot == "SecondaryHandEnchantSlot" then
			core.ShowMeleeWeapons(self, nil, itemString)
		end
		self:SetLoading(false)
	elseif GetItemInfo(itemID) then
		local enchant = core.itemCollectionFrame.previewWeaponEnchants and core.itemCollectionFrame.enchant
		local itemString = enchant and "item:" .. itemID .. ":" .. enchant or itemID
		self:Undress()
		if core.db.profile.General.clothedMannequins then
			if not (slot == "ChestSlot" or slot == "ShirtSlot" or slot == "TabardSlot" or slot == "WristSlot" or slot == "HandsSlot") then
				self:TryOnOld(3427) -- Black Shirt
				-- self:TryOnOld(41253) -- Darkblue Shirt		
				-- self:TryOnOld(9998) -- Black West			
				-- self:TryOnOld(14637) -- Black West2		
				-- self:TryOnOld(7110) -- Black Sweater
				-- self:TryOnOld(6834) -- Black Smoking	
				-- self:TryOnOld(41254) -- Dark Shirt	
				self:TryOnOld(39519) -- Black Gloves
			end
			if slot == "WristSlot" or slot == "HandsSlot" then		
				self:TryOnOld(14637) -- Black West2
			end
			if slot ~= "LegsSlot" and slot ~= "FeetSlot" then
				self:TryOnOld(11731) -- Black Shoes
				self:TryOnOld(6835) -- Black Leggings
			end
		end
		if slot == "MainHandSlot" then 
			core.ShowMeleeWeapons(self, itemString, nil)
		elseif slot == "ShieldHandWeaponSlot" then
			core.ShowMeleeWeapons(self, nil, itemString) -- TODO: fails for 2H weapons without titangrip. would need to find a good model animation + position, where both hands are on the weapon
		else
			self:TryOnOld(itemString)
		end
		self:SetLoading(false)
	else
		self:SetLoading(true)
		core.QueryItem(itemID)
	end
	self:UpdateBorders()
end

-- Displays a special border for equipped item, current transmog, skin or pending
local Model_UpdateBorders = function(self)
	local slot = self:GetParent():GetParent().selectedSlot -- TryOn uses different slot for OH display stuff. Here we care about the real slot
	local isEnchantSlot = slot and core.IsEnchantSlot(slot)

	if slot and self.itemID and core.IsAtTransmogrifier() then
		local _, displayGroup = core.GetItemData(self.itemID)
		local skinID = core.GetSelectedSkin()
		local equippedID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot)

		core.SetShown(self.equippedTexture, not skinID and ((self.itemID == equippedID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(equippedID))))))
		core.SetShown(self.visualTexture, not skinID and ((self.itemID == visualID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(visualID))))))
		core.SetShown(self.skinVisualTexture, (self.itemID == skinVisualID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(skinVisualID)))))
		core.SetShown(self.pendingTexture, (self.itemID == pendingID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(pendingID)))))
		if self.pendingTexture:IsShown() then
			if skinID then 
				self.pendingTexture:SetTexCoord(196/512, 292/512, 218/512, 342/512)
			else
				self.pendingTexture:SetTexCoord(5/512, 101/512, 3/512, 127/512)
			end
		end
	else
		self.equippedTexture:Hide()
		self.visualTexture:Hide()
		self.skinVisualTexture:Hide()
		self.pendingTexture:Hide()

		if isEnchantSlot and self.itemID then
			local enchant = self.itemID ~= 0 and core.enchants[self.itemID].enchantIDs[1] or nil
			if enchant == self:GetParent():GetParent().enchant then
				self.equippedTexture:Show()
			end
		end
	end
end

local Model_update = function(self)
	self:UpdateBorders()
end

local Model_SetAnimation = function(self, sequenceID, sequenceTime, sequenceSpeed) -- requires that SetSequence(...) is called in OnUpdate
	-- core.am("Set Model Animation:", sequenceID, sequenceTime, sequenceSpeed)
	self.sequence = (sequenceID and sequenceID >= 0 and sequenceID <= 506) and sequenceID or 15 -- sequence ID must be in the range 0, 506
	self.sequenceTime = sequenceTime or 0
	self.sequenceSpeed = sequenceSpeed or 1000
end

local Model_OnUpdate = function(self, elapsed) -- this lets us use different model animation (some will be glitchy). without setting this in OnUpdate, it will show the default standing animation
	self.sequenceTime = self.sequenceTime + elapsed * self.sequenceSpeed
	self:SetSequenceTime(self.sequence, self.sequenceTime)
end

local Model_SetDisplayMode = function(self, unlocked) -- change style depending on whether the item is unlocked or not
	self:SetAlpha(unlocked and 1 or 0.8)
	core.SetShown(self.lockedTexture, not unlocked)
	self:SetLight(unpack(LIGHT[unlocked and "default" or "locked"]))
end

local UPDATE_INTERVAL = 0.5
local LoadingFrame_OnUpdate = function(self, e)
	self.elapsed = (self.elapsed or 0) + e
	if self.elapsed > UPDATE_INTERVAL then
		self.elapsed = self.elapsed - UPDATE_INTERVAL
		local itemID = self:GetParent().itemID
		local slot = self:GetParent().slot
		if GetItemInfo(itemID) then
			self:GetParent():TryOn(itemID, slot)
			self:Hide()
		end
	end
end

core.CreateMannequinFrame = function(parent, id, width, height)
	local m = CreateFrame("DressUpModel", folder .. "Mannequin" .. id, parent)
	-- Setting frame strata to HIGH or above would cause the main model to be loaded before the mannequins (models (frames?) get loaded back to front)
	-- This causes ugly clipping tho in combination with SetTopLevel frames, so have to find another way
	-- m:SetFrameStrata("HIGH")
	m:SetSize(width, height)
	m:EnableMouse()
	m:EnableMouseWheel()

	m.id = id
	m.GetID = Model_GetID	

	m.SetUnitOld = m.SetUnit
	m.SetUnit = Model_SetUnit		
	
	-- m.borderFrame = CreateFrame("Frame", nil, m)
	-- m.borderFrame:SetAllPoints()
	
	m.opaqueBGTex = m:CreateTexture(nil, "BACKGROUND")
	m.opaqueBGTex:SetTexture(0.1, 0.1, 0.1)
	m.opaqueBGTex:SetPoint("BOTTOMLEFT", 1, 1)
	m.opaqueBGTex:SetPoint("TOPRIGHT", -1, -1)

	local offset = 0.05 * height

	m.backTex = m:CreateTexture(nil, "BORDER")
	m.backTex:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.backTex:SetTexCoord(5/512, 95/512, 131/512, 247/512)
	m.backTex:SetPoint("TOPLEFT", -offset, offset)
	m.backTex:SetPoint("BOTTOMRIGHT", offset, -offset)
	
	m.highTex = m:CreateTexture(nil, "HIGHLIGHT")
	m.highTex:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.highTex:SetTexCoord(5/512, 95/512, 255/512, 372/512)
	--local scale = 0.025
	--local left, top, right, bottom = 104/512, 225/512, 190/512,336/512
	--m.highTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	--m.highTex:SetAllPoints()
	m.highTex:SetPoint("TOPLEFT", -offset, offset)
	m.highTex:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.highTex:SetBlendMode("ADD")
	m.highTex:SetAlpha(0.8)

	m.lockedTexture = m:CreateTexture(nil, "BORDER")
	m.lockedTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.lockedTexture:SetTexCoord(5/512, 95/512, 255/512, 372/512)
	m.lockedTexture:SetPoint("TOPLEFT", -offset, offset)
	m.lockedTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.lockedTexture:SetAlpha(1)
	m.lockedTexture:SetVertexColor(0.4, 0.4, 0.4)

	m.equippedTexture = m:CreateTexture(nil, "ARTWORK")
	m.equippedTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.equippedTexture:SetTexCoord(104/512, 189/512, 0/512, 111/512)
	m.equippedTexture:SetPoint("TOPLEFT", -offset * 0.5, offset * 0.5)
	m.equippedTexture:SetPoint("BOTTOMRIGHT", offset * 0.5, -offset * 0.5)
	m.equippedTexture:SetAlpha(0.5)
	
	m.visualTexture = m:CreateTexture(nil, "ARTWORK")
	m.visualTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.visualTexture:SetTexCoord(104/512, 189/512, 112/512, 223/512)
	m.visualTexture:SetPoint("TOPLEFT", -offset * 0.5, offset * 0.5)
	m.visualTexture:SetPoint("BOTTOMRIGHT", offset * 0.5, -offset * 0.5)
	m.visualTexture:SetAlpha(0.5)

	m.skinVisualTexture = m:CreateTexture(nil, "ARTWORK")
	m.skinVisualTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.skinVisualTexture:SetTexCoord(104/512, 189/512, 224/512, 336/512)
	m.skinVisualTexture:SetPoint("TOPLEFT", -offset * 0.5, offset * 0.5)
	m.skinVisualTexture:SetPoint("BOTTOMRIGHT", offset * 0.5, -offset * 0.5)
	m.skinVisualTexture:SetAlpha(0.5)
	
	offset = 0.08 * height
	m.pendingTexture = m:CreateTexture(nil, "ARTWORK")
	m.pendingTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.pendingTexture:SetTexCoord(5/512, 101/512, 3/512, 127/512)
	m.pendingTexture:SetPoint("TOPLEFT", -offset, offset)
	m.pendingTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.pendingTexture:SetAlpha(0.8)

	-- m.transmogPending = {5/512, 101/512, 3/512, 127/512}
	-- m.skinPending = {196/512, 292/512, 218/512, 342/512}
	-- m.transmogPending = {8/512, 98/512, 8/512, 122/512}
	-- m.skinPending = {199/512, 289/512, 223/512, 337/512}


	-- m.testFrame = CreateFrame("Frame", folder.."Mannequin"..id.."LoadingFrame", m)
	-- m.testFrame:SetAllPoints()
	-- m.testFrame.tex = m.testFrame:CreateTexture(nil, "OVERLAY")
	-- m.testFrame.tex:SetAllPoints()
	-- m.testFrame.tex:SetTexture(0,0,0)
	-- m.testFrame.tex:SetAlpha(0.5)

	m.loadingFrame = CreateFrame("Frame", folder.."Mannequin"..id.."LoadingFrame", m)
	m.loadingFrame:SetAllPoints()
	m.loadingFrame:EnableMouse()

	m.loadingFrame.text = m.loadingFrame:CreateFontString()
	m.loadingFrame.text:SetFontObject(GameFontNormal)
	m.loadingFrame.text:SetPoint("CENTER")
	m.loadingFrame.text:SetJustifyH("CENTER")
	m.loadingFrame.text:SetJustifyV("MIDDLE")
	m.loadingFrame.text:SetText(core.LOADING1)
	
	m.loadingFrame.texture = m.loadingFrame:CreateTexture(nil, "BACKGROUND")
	m.loadingFrame.texture:SetPoint("CENTER")
	m.loadingFrame.texture:SetSize(m.loadingFrame.text:GetSize())
	m.loadingFrame.texture:SetTexture(0.1, 0.1, 0.1)

	m.loadingFrame:SetScript("OnUpdate", LoadingFrame_OnUpdate)

	m.SetLoading = Model_SetLoading

	-- TODO: Display of 2H in offhand without titangrip
	m.TryOnOld = m.TryOn
	m.TryOn = Model_TryOn

	m.SetDisplayMode = Model_SetDisplayMode
		
	m.sequence = 15 -- Standing Still Animation
	m.sequenceTime = 0
	m.sequenceSpeed = 1000	
	m.SetAnimation = Model_SetAnimation

	m.UpdateBorders = Model_UpdateBorders
	m.update = Model_update

	core.RegisterListener("currentChanges", m)
	core.RegisterListener("selectedSkin", m)
	core.RegisterListener("inventory", m)
	-- core.RegisterListener("availableMogs", m)
	
	m:SetScript("OnUpdate", Model_OnUpdate)
	m:SetScript("OnHide", Model_OnHide)
	m:SetScript("OnShow", Model_OnShow)

	m:Hide()
	return m
end

