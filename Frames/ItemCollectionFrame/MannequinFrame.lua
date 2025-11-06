local folder, core = ...

-- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
local LIGHT = {
	default = {
		1,					-- enabled
		0, 0, 1, 0,			-- omni (enabled, r, g, b)
		1, 0.7, 0.7, 0.7,	-- ambient (enabled, r, g, b)
		1, 0.8, 0.8, 0.64,	-- directional (enabled, r, g, b)
	},
	shadowForm = {
		1,
		0, 0, 1, 0,
		1, 0.16, 0, 0.23,
		0,
	},
	locked = {
		1,
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
	self.slot = nil
	self.itemID = nil
end

local Model_OnShow = function(self)
	self:SetUnit("player")
	self:Undress()
	if self.itemID and self.slot then self:TryOn(self.itemID, self.slot) end
end

-- Another DressUpModel feature: How far the model moves with SetPosition depends on the aspect ratio
local Model_SetPosition = function(self, x, y, z)
	local width = GetScreenWidth()
	local height = GetScreenHeight()
	local screenRatio = width / height
	local factor = (screenRatio / (16 / 9)) ^ 0.8 -- This conversion seems to work good enough for most realistic aspect ratios (tested between 5:4 and 3:1)
	x, y, z = x / factor, y / factor, z / factor
	
	self:SetPositionOld(x, y, z)
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

	local atTransmogrifier = core.IsAtTransmogrifier()
	
	self:Undress()
	
	if core.db.profile.General.clothedMannequins then
		if not (slot == "ChestSlot" or slot == "ShirtSlot" or slot == "TabardSlot" or slot == "WristSlot" or slot == "HandsSlot") then
			-- self:TryOnOld(3427) -- Black Shirt
			-- self:TryOnOld(41253) -- Darkblue Shirt		
			self:TryOnOld(9434) -- Black West			
			-- self:TryOnOld(14637) -- Black West2		
			-- self:TryOnOld(7110) -- Black Sweater
			-- self:TryOnOld(6834) -- Black Smoking	
			-- self:TryOnOld(41254) -- Dark Shirt	
			-- self:TryOnOld(41254) -- Dark Shirt	
			self:TryOnOld(39519) -- Black Gloves
		end
		if slot == "WristSlot" or slot == "HandsSlot" then		
			self:TryOnOld(14637) -- Black West2, has short sleeves
		end
		if slot ~= "LegsSlot" and slot ~= "FeetSlot" then
			self:TryOnOld(11731) -- Black Shoes
			self:TryOnOld(6835) -- Black Leggings
		end
	end

	if core.IsEnchantSlot(slot) then -- itemID is the enchantVisualID in this case atm
		local enchantID = (itemID == core.HIDDEN_ID and 0 or core.enchants[itemID]["spellIDs"][1])
		enchantID = core.SpellToEnchantID(enchantID) or 0
		local dummyWeapon = (slot == "MainHandEnchantSlot" or core.CanDualWield()) and core.DUMMY_WEAPONS.ENCHANT_PREVIEW_WEAPON or core.DUMMY_WEAPONS.ENCHANT_PREVIEW_OFFHAND_WEAPON
		local itemString = "item:" .. dummyWeapon .. ":" .. enchantID
		if slot == "MainHandEnchantSlot" then 
			core.ShowMeleeWeapons(self, itemString, nil)
		elseif slot == "SecondaryHandEnchantSlot" then
			core.ShowMeleeWeapons(self, nil, itemString)
		end
		self:SetLoading(false)
	elseif GetItemInfo(itemID) then
		local realSlot = core.itemCollectionFrame.selectedSlot
		local correspondingEnchantSlot = core.IsEnchantableSlot(realSlot) and core.GetCorrespondingSlot(realSlot)
		local enchant
		if correspondingEnchantSlot and core.itemCollectionFrame.previewWeaponEnchants then
			if not atTransmogrifier then
				enchant = core.itemCollectionFrame.enchant
			else
				local skin = core.GetSelectedSkin()
				local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(correspondingEnchantSlot, skin)
				enchant = pendingID or (skin and skinVisualID) or (not skin and (visualID or itemID)) or nil
			end
		end
		local itemString = "item:" .. itemID .. ":" .. (core.SpellToEnchantID(enchant) or 0)
		-- print("item", itemString)
		if slot == "MainHandSlot" then 
			core.ShowMeleeWeapons(self, itemString, nil)
		elseif slot == "ShieldHandWeaponSlot" then
			core.ShowMeleeWeapons(self, nil, itemString)
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
local hiddenGroup = { core.HIDDEN_ID }
local Model_UpdateBorders = function(self)
	local slot = self:GetParent():GetParent().selectedSlot -- TryOn uses different slot for OH display stuff. Here we care about the real slot
	local isEnchantSlot = slot and core.IsEnchantSlot(slot)

	if slot and self.itemID and core.IsAtTransmogrifier() then
		local skinID = core.GetSelectedSkin()
		local equippedID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot)
		if not isEnchantSlot then
			local _, displayGroup = core.GetItemData(self.itemID)
			core.SetShown(self.equippedTexture, not skinID and ((self.itemID == equippedID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(equippedID))))))
			core.SetShown(self.visualTexture, not skinID and ((self.itemID == visualID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(visualID))))))
			core.SetShown(self.skinVisualTexture, (self.itemID == skinVisualID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(skinVisualID)))))
			core.SetShown(self.pendingTexture, (self.itemID == pendingID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(pendingID)))))
		else
			local enchantGroup = self.itemID ~= core.HIDDEN_ID and core.enchants[self.itemID].spellIDs or hiddenGroup
			core.SetShown(self.equippedTexture, not skinID and core.Contains(enchantGroup, equippedID))
			core.SetShown(self.visualTexture, not skinID and core.Contains(enchantGroup, visualID))
			core.SetShown(self.skinVisualTexture, core.Contains(enchantGroup, skinVisualID))
			core.SetShown(self.pendingTexture, core.Contains(enchantGroup, pendingID))
		end
		if self.pendingTexture:IsShown() then
			if skinID then 
				self.pendingTexture:SetTexCoord(192/512, 290/512, 252/512, 378/512)
			else
				self.pendingTexture:SetTexCoord(96/512, 192/512, 252/512, 378/512)
			end
		end
	else
		self.equippedTexture:Hide()
		self.visualTexture:Hide()
		self.skinVisualTexture:Hide()
		self.pendingTexture:Hide()

		if isEnchantSlot and self.itemID then
			local previewEnchant = self:GetParent():GetParent().enchant
			local enchantGroup = self.itemID ~= core.HIDDEN_ID and core.enchants[self.itemID].spellIDs or hiddenGroup
			if previewEnchant and core.Contains(enchantGroup, previewEnchant)
					or not previewEnchant and self.itemID == core.HIDDEN_ID then
				self.equippedTexture:Show()
			end
		end
	end
end

local Model_update = function(self)
	self:UpdateBorders()
end

local Model_SetAnimation = function(self, sequenceID, sequenceTime, sequenceSpeed) -- requires that SetSequenceTime(seq, time) is called in OnUpdate
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

local UPDATE_INTERVAL = 0.1
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

	local FRAME_TEXTURE = "Interface\\AddOns\\".. folder .."\\Images\\Frames"

	m.id = id
	m.GetID = Model_GetID	

	m.SetUnitOld = m.SetUnit
	m.SetUnit = Model_SetUnit

	m.SetPositionOld = m.SetPosition
	m.SetPosition = Model_SetPosition
	
	m.borderFrame = CreateFrame("Frame", nil, m)
	m.borderFrame:SetAllPoints()

	local borderAnchor = m.borderFrame -- If we'd rather have the models above the border, set this to m
	
	m.opaqueBGTex = m:CreateTexture(nil, "BACKGROUND")
	m.opaqueBGTex:SetTexture(0.1, 0.1, 0.1)
	m.opaqueBGTex:SetPoint("BOTTOMLEFT", 1, 1)
	m.opaqueBGTex:SetPoint("TOPRIGHT", -1, -1)

	local offset = 0.08 * height

	m.backTex = borderAnchor:CreateTexture(nil, "BORDER")
	m.backTex:SetTexture(FRAME_TEXTURE)
	m.backTex:SetTexCoord(0/512, 96/512, 0/512, 126/512)
	m.backTex:SetPoint("TOPLEFT", -offset, offset)
	m.backTex:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.backTex:SetVertexColor(0.8, 1, 1)

	m.lockedTexture = borderAnchor:CreateTexture(nil, "BORDER")
	m.lockedTexture:SetTexture(FRAME_TEXTURE)
	m.lockedTexture:SetTexCoord(96/512, 192/512, 0/512, 126/512)
	m.lockedTexture:SetPoint("TOPLEFT", -offset, offset)
	m.lockedTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	
	m.highTex = borderAnchor:CreateTexture(nil, "OVERLAY")
	m.highTex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	m.highTex:SetTexCoord(0, 1, 0, 1)
	m.highTex:SetPoint("TOPLEFT", -offset * 0.5, offset * 0.5)
	m.highTex:SetPoint("BOTTOMRIGHT", offset * 0.5, -offset * 0.5)
	m.highTex:SetBlendMode("ADD")
	m.highTex:SetAlpha(0.4)
	m.highTex:Hide()

	m.equippedTexture = borderAnchor:CreateTexture(nil, "ARTWORK")
	m.equippedTexture:SetTexture(FRAME_TEXTURE)
	m.equippedTexture:SetTexCoord(0/512, 96/512, 126/512, 252/512)
	m.equippedTexture:SetPoint("TOPLEFT", -offset, offset)
	m.equippedTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.equippedTexture:SetAlpha(0.4)
	m.equippedTexture:SetBlendMode("ADD")
	
	m.visualTexture = borderAnchor:CreateTexture(nil, "ARTWORK")
	m.visualTexture:SetTexture(FRAME_TEXTURE)
	m.visualTexture:SetTexCoord(96/512, 192/512, 126/512, 252/512)
	m.visualTexture:SetPoint("TOPLEFT", -offset, offset)
	m.visualTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.visualTexture:SetAlpha(0.4)
	m.visualTexture:SetBlendMode("ADD")
	

	m.skinVisualTexture = borderAnchor:CreateTexture(nil, "ARTWORK")
	m.skinVisualTexture:SetTexture(FRAME_TEXTURE)
	m.skinVisualTexture:SetTexCoord(192/512, 290/512, 126/512, 252/512)
	m.skinVisualTexture:SetPoint("TOPLEFT", -offset, offset)
	m.skinVisualTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.skinVisualTexture:SetAlpha(0.6)
	m.skinVisualTexture:SetBlendMode("ADD")
	
	m.pendingTexture = borderAnchor:CreateTexture(nil, "ARTWORK")
	m.pendingTexture:SetTexture(FRAME_TEXTURE)
	m.pendingTexture:SetTexCoord(96/512, 192/512, 252/512, 378/512)
	m.pendingTexture:SetPoint("TOPLEFT", -offset, offset)
	m.pendingTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	-- m.pendingTexture:SetAlpha(0.8)
	m.pendingTexture:SetBlendMode("ADD")

	-- m.transmogPending = {5/512, 101/512, 3/512, 127/512}
	-- m.skinPending = {196/512, 292/512, 218/512, 342/512}
	-- m.transmogPending = {8/512, 98/512, 8/512, 122/512}
	-- m.skinPending = {199/512, 289/512, 223/512, 337/512}

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

