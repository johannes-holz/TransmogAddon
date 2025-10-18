local folder, core = ...

------------- UPDOOTS -------------
local strfind = strfind
local strmatch = strmatch
local strlower = strlower
local strsub = strsub
local tonumber = tonumber
local GetItemInfo = GetItemInfo
local band = bit.band
-----------------------------------

local HEADER_HEIGHT, BOTTOM_HEIGHT, SIDE_PADDING = 40, 30, 12

----------- ItemCollectionFrame -----------

core.itemCollectionFrame = CreateFrame("Frame", folder .. "ItemCollectionFrame", UIParent)
local itemCollectionFrame = core.itemCollectionFrame
itemCollectionFrame:EnableMouse()
itemCollectionFrame:Hide()

itemCollectionFrame.Resize = function(self)
	self:SetHeight(self.displayFrame:GetHeight() + HEADER_HEIGHT + BOTTOM_HEIGHT)
	self:SetWidth(self.displayFrame:GetWidth() + SIDE_PADDING * 2)
end

itemCollectionFrame:SetScript("OnShow", function(self)
	local atTransmogrifier = core.IsAtTransmogrifier()

	for name, button in pairs(self.slotButtons) do
		core.SetShown(button, not atTransmogrifier)
	end

	self:Resize()

	self:SetScale(atTransmogrifier and core.transmogFrame.scale / 1.2 or 1)

	self:SetBackdrop(not atTransmogrifier and core.BACKDROP_ITEM_COLLECTION or {})
	self:SetBackdropBorderColor(0.675, 0.5, 0.125, 1)
	self:SetBackdropColor(0.375, 0.375, 0.375, 1)

	core.SetShown(self.optionsDDM, not atTransmogrifier)

	self.searchBox:ClearAllPoints()
	self.unlockedStatusBar:ClearAllPoints()

	if not atTransmogrifier then
		self.slotButtons["Head"]:Click()
		self.unlockedStatusBar:SetPoint("BOTTOM", self, "TOP", 0, 10)
		self.unlockedStatusBar:Show()
		self.searchBox:SetPoint("LEFT", self.unlockedStatusBar, "RIGHT", 15, 1)
	else
		self.searchBox:SetPoint("RIGHT", self.itemTypeDDM, "LEFT", 0, 3)
		self.unlockedStatusBar:Hide()
	end

	if not self.page then
		self:SetSlotAndCategory(nil, nil) -- Dirty way to init. Maybe find cleaner way
	end
end)

itemCollectionFrame:SetScript("OnHide", function(self)
	self:SetSlotAndCategory(nil, nil) -- clear slot first, so clearing the other fields does not cause further item iterations
	self:SetPreviewEnchant(nil)
	self:ClearFilters()
	self.searchBox:SetText("")
end)

itemCollectionFrame.SetSlotAndCategory = function(self, slot, category, update)
	--print("set location, type", locationName, itemType)
	if not update and itemCollectionFrame.selectedSlot == slot and itemCollectionFrame.selectedCategory == category then return end
	
	self.selectedSlot = slot
	self.selectedCategory = category
	
	-- highlight current slot button in wardrobe
	if not core.IsAtTransmogrifier() then
		for _, button in pairs(self.slotButtons) do
			core.SetShown(button.selectedTexture, button.itemSlot == slot)
		end
		for _, button in pairs(self.enchantSlotButtons) do
			core.SetShown(button.selectedTexture, button.itemSlot == slot)
		end
	end

	core.SetShown(self.noSlotSelectedText, not slot)
	core.SetShown(self.searchBox, slot)
	core.SetShown(self.itemTypeDDM, slot)
	core.SetShown(self.pageDownButton, slot)
	core.SetShown(self.pageUpButton, slot)
	core.SetShown(self.pageText, slot)

	core.SetShown(self.enchantCheckButton, slot == "MainHandSlot" or slot == "ShieldHandWeaponSlot")
	if core.IsAtTransmogrifier() then
		-- TODO: This preview enchant solution is not great
		-- How to handle this? For inventory ok like this? For Skin we would want ability, to select enchant? :/
		if slot == "MainHandSlot" or slot == "ShieldHandWeaponSlot" then
			self:SetPreviewEnchant(core.GetInventoryEnchantID("player", core.slotToID[slot]), true)
		end
	end

	UIDropDownMenu_SetText(self.itemTypeDDM, category and (core.CATEGORY_DISPLAY_NAME[category] or core.RemoveFirstWordInString(category)) or core.SELECT_ITEM_TYPE)
	if UIDropDownMenu_GetCurrentDropDown() == self.itemTypeDDM then CloseDropDownMenus() end
	core.UIDropDownMenu_SetEnabled(self.itemTypeDDM, slot and core.slotCategories[slot] and core.Length(core.slotCategories[slot]) > 1)

	self:UpdateDisplayList()
end

----------- TransmogLocation / InventorySlots Buttons -----------

local BUTTON_WIDTH = 28
local BUTTON_SPACING, BUTTON_SPACING_WIDE = 2, 10

local slots = core.API.Slots
--local order = { slots.Head, slots.Shoulders, slots.Back, slots.Chest, slots.Body, slots.Tabard, slots.Wrists, slots.Hands, slots.Waist, slots.Legs, slots.Feet, slots.MainHandWeapon, slots.OffHandWeapon, slots.OffHand }
local order = {"Head", "Shoulders", "Back", "Chest", "Body", "Tabard", "Wrists", "Hands", "Waist", "Legs", "Feet", "MainHandWeapon", "OffHandWeapon", "OffHand", "Ranged"}

itemCollectionFrame.slotButtons = {}
for i, name in pairs(order) do
	itemCollectionFrame.slotButtons[name] = core.CreateSlotButtonFrame(itemCollectionFrame, name, BUTTON_WIDTH)
	if name == "Head" then
		itemCollectionFrame.slotButtons[name]:SetPoint("TOPLEFT", SIDE_PADDING, -10)
	elseif name == "MainHandWeapon" then
		itemCollectionFrame.slotButtons[name]:SetPoint("TOPLEFT", itemCollectionFrame.slotButtons[order[i - 1]], "TOPRIGHT", BUTTON_SPACING_WIDE, 0)
	else	
		itemCollectionFrame.slotButtons[name]:SetPoint("TOPLEFT", itemCollectionFrame.slotButtons[order[i - 1]], "TOPRIGHT", BUTTON_SPACING, 0)
	end
end

itemCollectionFrame.enchantSlotButtons = {}
itemCollectionFrame.enchantSlotButtons["MainHandEnchantSlot"] = core.CreateEnchantSlotButton(itemCollectionFrame.slotButtons["MainHandWeapon"], "MainHandEnchantSlot", BUTTON_WIDTH * 0.6)
itemCollectionFrame.enchantSlotButtons["MainHandEnchantSlot"]:SetPoint("CENTER", itemCollectionFrame.slotButtons["MainHandWeapon"], "BOTTOMRIGHT", -3, 3)
itemCollectionFrame.enchantSlotButtons["SecondaryHandEnchantSlot"] = core.CreateEnchantSlotButton(itemCollectionFrame.slotButtons["OffHandWeapon"], "SecondaryHandEnchantSlot", BUTTON_WIDTH * 0.6)
itemCollectionFrame.enchantSlotButtons["SecondaryHandEnchantSlot"]:SetPoint("CENTER", itemCollectionFrame.slotButtons["OffHandWeapon"], "BOTTOMRIGHT", -3, 3)

----------- ItemType DropDownMenu -----------

itemCollectionFrame.itemTypeDDM = core.CreateItemTypeDDM(itemCollectionFrame)
itemCollectionFrame.itemTypeDDM:SetPoint("TOPRIGHT", -SIDE_PADDING - 40, -10)
itemCollectionFrame.itemTypeDDM:Show()


----------- DisplayFrame -----------

--local WIDTH, HEIGHT = 630, 347
local WIDTH, HEIGHT = 621, 333
local IN_BETWEEN_PADDING = 8

local MANNEQUIN_MAX_ROWCOUNT = 3
local MANNEQUIN_MAX_COLCOUNT = 6
local MANNEQUIN_MAX_COUNT = MANNEQUIN_MAX_ROWCOUNT * MANNEQUIN_MAX_COLCOUNT

local MANNEQUIN_ROWCOUNT = 3
local MANNEQUIN_COLCOUNT = 6

local mannequinCount = MANNEQUIN_ROWCOUNT * MANNEQUIN_COLCOUNT

itemCollectionFrame.displayFrame = CreateFrame("Frame", folder.."DisplayFrame", itemCollectionFrame)
local displayFrame = itemCollectionFrame.displayFrame
displayFrame:SetPoint("TOPLEFT", itemCollectionFrame, "TOPLEFT", SIDE_PADDING, -HEADER_HEIGHT)
displayFrame:SetSize(WIDTH, HEIGHT)
displayFrame:EnableMouseWheel()

-- displayFrame.backgroundTexture = displayFrame:CreateTexture(nil, "BACKGROUND")
-- displayFrame.backgroundTexture:SetAllPoints()
-- displayFrame.backgroundTexture:SetTexture(0.5, 0.5, 0.5, 0.5)

----------- MannequinFrames -----------

itemCollectionFrame.mannequins = {}
for i = 1, mannequinCount do
	itemCollectionFrame.mannequins[i] = core.CreateMannequinFrame(displayFrame, i, (WIDTH - IN_BETWEEN_PADDING * (MANNEQUIN_COLCOUNT + 1)) / MANNEQUIN_COLCOUNT,
																				(HEIGHT - IN_BETWEEN_PADDING * (MANNEQUIN_ROWCOUNT + 1)) / MANNEQUIN_ROWCOUNT)
	if i == 1 then
		itemCollectionFrame.mannequins[i]:SetPoint("TOPLEFT", IN_BETWEEN_PADDING, -IN_BETWEEN_PADDING)
	elseif i % MANNEQUIN_COLCOUNT == 1 then
		itemCollectionFrame.mannequins[i]:SetPoint("TOPLEFT", itemCollectionFrame.mannequins[i - MANNEQUIN_COLCOUNT], "BOTTOMLEFT", 0, -IN_BETWEEN_PADDING)
	else
		itemCollectionFrame.mannequins[i]:SetPoint("TOPLEFT", itemCollectionFrame.mannequins[i - 1], "TOPRIGHT", IN_BETWEEN_PADDING, 0)
	end
end

itemCollectionFrame.ChangeMannequinCount = function(self, row, col)
	local oldCount = mannequinCount
	MANNEQUIN_ROWCOUNT = row > MANNEQUIN_MAX_ROWCOUNT and MANNEQUIN_MAX_ROWCOUNT or row < 1 and 1 or row
	MANNEQUIN_COLCOUNT = col > MANNEQUIN_MAX_COLCOUNT and MANNEQUIN_MAX_COLCOUNT or col < 1 and 1 or col

	mannequinCount = MANNEQUIN_ROWCOUNT * MANNEQUIN_COLCOUNT

	for i = 1, math.max(oldCount, mannequinCount) do
		if not itemCollectionFrame.mannequins[i] then
			itemCollectionFrame.mannequins[i] = core.CreateMannequinFrame(displayFrame, i, (WIDTH - IN_BETWEEN_PADDING * (MANNEQUIN_COLCOUNT + 1)) / MANNEQUIN_COLCOUNT,
																							(HEIGHT - IN_BETWEEN_PADDING * (MANNEQUIN_ROWCOUNT + 1)) / MANNEQUIN_ROWCOUNT)
		end
		itemCollectionFrame.mannequins[i]:SetSize((WIDTH - IN_BETWEEN_PADDING * (MANNEQUIN_COLCOUNT + 1)) / MANNEQUIN_COLCOUNT, (HEIGHT - IN_BETWEEN_PADDING * (MANNEQUIN_ROWCOUNT + 1)) / MANNEQUIN_ROWCOUNT);
		core.SetShown(itemCollectionFrame.mannequins[i], i <= mannequinCount)

		if i == 1 then
			itemCollectionFrame.mannequins[i]:SetPoint("TOPLEFT", IN_BETWEEN_PADDING, -IN_BETWEEN_PADDING)
		elseif i % MANNEQUIN_COLCOUNT == 1 then
			itemCollectionFrame.mannequins[i]:SetPoint("TOPLEFT", itemCollectionFrame.mannequins[i - MANNEQUIN_COLCOUNT], "BOTTOMLEFT", 0, -IN_BETWEEN_PADDING)
		else
			itemCollectionFrame.mannequins[i]:SetPoint("TOPLEFT", itemCollectionFrame.mannequins[i - 1], "TOPRIGHT", IN_BETWEEN_PADDING, 0)
		end
	end

	itemCollectionFrame:SetPage(1)
end

----------- Page Up/Down Buttons -----------

itemCollectionFrame.pageDownButton = core.CreateMeAButton(itemCollectionFrame, 28, 28, nil,
								"Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 0, 0, 1, 1,
								"Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down", 0, 0, 1, 1,
								"Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
								"Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled", 0, 0, 1, 1)
itemCollectionFrame.pageDownButton:SetPoint("TOPLEFT", displayFrame, "BOTTOM", 0, 3)
itemCollectionFrame.pageDownButton:SetScript("OnClick", function()	
	itemCollectionFrame:SetPage(itemCollectionFrame.page - 1)
end)

itemCollectionFrame.pageUpButton = core.CreateMeAButton(itemCollectionFrame, 28, 28, nil,
							"Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 0, 0, 1, 1,
							"Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down", 0, 0, 1, 1,
							"Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
							"Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled", 0, 0, 1, 1)
itemCollectionFrame.pageUpButton:SetPoint("LEFT", itemCollectionFrame.pageDownButton, "RIGHT", 2, 0)
itemCollectionFrame.pageUpButton:SetScript("OnClick", function()
	itemCollectionFrame:SetPage(itemCollectionFrame.page + 1)
end)

itemCollectionFrame.pageText = itemCollectionFrame:CreateFontString()
itemCollectionFrame.pageText:SetFontObject(GameFontWhiteSmall)
itemCollectionFrame.pageText:SetPoint("RIGHT", itemCollectionFrame.pageDownButton, "LEFT", -8, 0)
itemCollectionFrame.pageText:SetJustifyH("CENTER")
itemCollectionFrame.pageText:SetJustifyV("MIDDLE")

---------- Text to show when the list is empty --------------

itemCollectionFrame.noSlotSelectedText = itemCollectionFrame:CreateFontString()
itemCollectionFrame.noSlotSelectedText:SetFontObject(GameFontNormal)
itemCollectionFrame.noSlotSelectedText:SetPoint("CENTER", itemCollectionFrame.displayFrame, "CENTER", 0, 0)
itemCollectionFrame.noSlotSelectedText:SetJustifyH("CENTER")
itemCollectionFrame.noSlotSelectedText:SetJustifyV("MIDDLE")
itemCollectionFrame.noSlotSelectedText:SetText(core.NO_SLOT_SELECTED_TEXT)

itemCollectionFrame.noUnlocksText = itemCollectionFrame:CreateFontString()
itemCollectionFrame.noUnlocksText:SetFontObject(GameFontNormal)
itemCollectionFrame.noUnlocksText:SetWidth(500)
itemCollectionFrame.noUnlocksText:SetPoint("CENTER", itemCollectionFrame.displayFrame, "CENTER", 0, 0)
itemCollectionFrame.noUnlocksText:SetJustifyH("CENTER")
itemCollectionFrame.noUnlocksText:SetJustifyV("MIDDLE")
itemCollectionFrame.noUnlocksText:SetText(textA)

------------------------------------------------------

-- local FindEnchantToShow = function(slot)
-- 	local correspondingEnchantSlot = core.GetCorrespondingSlot(slot)
-- 	if correspondingEnchantSlot then
-- 		local skin = core.GetSelectedSkin()
-- 		local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(correspondingEnchantSlot, skin)
-- 		return pendingID or (skin and skinVisualID) or (not skin and (visualID or itemID)) or nil
-- 	end
-- end

-- TODO: Most of this code should probably be moved to MannequinFrame
itemCollectionFrame.UpdateMannequins = function(self)
	-- print("UpdateMannequins")
	local _, race = UnitRace("player")
	local sex = UnitSex("player") -- 1: Neutrum/Unknown, 2: Male, 3: Female
	local positions = TransmoggyDB.mannequinPositions and TransmoggyDB.mannequinPositions[sex] or core.mannequinPositions[sex]
	if not positions[race] then race = "Human" end
	--local inventorySlot = select(2, core.GetTransmogLocationInfo(self.location))
	local slot, category = self.selectedSlot, self.selectedCategory
	local isEnchantSlot = core.IsEnchantSlot(slot)
	local x, y, z, facing = unpack((slot and race) and positions[race][slot] or { 0, 0, 0, 0 })
	local list = self.displayList-- core:GetItemsToDisplay()
	local canDualWield = core.CanDualWield()
	local hasTitanGrip = core.HasTitanGrip()
	
	local sequenceID, sequenceTime = 15, 100

	-- local sex = UnitSex("player")
	-- local id = core.sexRaceToID[sex][race]
	-- local posCat = category or "Default"
	-- if TransmoggyDB.positionData and TransmoggyDB.positionData[id] and TransmoggyDB.positionData[id][slot] and TransmoggyDB.positionData[id][slot][posCat] then
	-- 	local x, y, z, facing, near, far, seq, time = unpack(TransmoggyDB.positionData[id][slot][posCat])
	-- 	pos = { x, y, z, facing }
	-- 	sequenceID, sequenceTime = seq, time
	-- 	-- pos = TransmoggyDB.positionData[id][slot]
	-- end

	-- local atTransmogrifier = core.IsAtTransmogrifier()
	-- local previewEnchant = not isEnchantSlot and (not atTransmogrifier and self.enchant or FindEnchantToShow(slot))
	-- local dummyWeapon = (slot == "MainHandEnchantSlot" or canDualWield) and core.DUMMY_WEAPONS.ENCHANT_PREVIEW_WEAPON or core.DUMMY_WEAPONS.ENCHANT_PREVIEW_OFFHAND_WEAPON

	for i = 1, mannequinCount do
		local itemID = list[mannequinCount * (self.page - 1) + i]
		local mannequin = self.mannequins[i]

		if not itemID then
			mannequin:Hide()
		else
			if not mannequin:IsShown() then			
				mannequin:Show()
			end
			local itemCategory, itemEquipLoc
			if not isEnchantSlot then
				local _, _, inventoryType, class, subClass = core.GetItemData(itemID)
				itemCategory = class and subClass and core.classSubclassToType[class][subClass]
				itemEquipLoc = inventoryType and core.inventoryTypes[inventoryType]
			end
			local isTwoHand = itemEquipLoc == "INVTYPE_2HWEAPON"
			local canBeTitanGripped = core.CanBeTitanGripped(itemCategory)
			local displaySlot = slot
			-- scuffed fix for offhand weapon display
			-- TODO: find and implement animation pose, where the weapon is gripped by both hands or the weapon arm is stretched out
			if (slot == "ShieldHandWeaponSlot") and (not canDualWield or (isTwoHand and (not canBeTitanGripped or not hasTitanGrip))) then
				displaySlot = "MainHandSlot"
				y = -y + 0.2
			end
			
			mannequin:SetDisplayMode(self.visualUnlocked[itemID] == 1)
			mannequin:SetPosition(x, y, z)
			mannequin:SetFacing(itemCategory == core.CATEGORIES.WEAPON_BOWS and -facing or facing) -- bows are held in the left hand
			mannequin:SetAnimation(sequenceID, sequenceTime)
			-- mannequin:Undress()
			mannequin:TryOn(itemID, displaySlot)

			-- temp
			-- local enchantID = isEnchantSlot and core.enchants[itemID].enchantIDs[1] or previewEnchant
			-- local itemID = isEnchantSlot and dummyWeapon or itemID 
			-- mannequin:TryOn(itemID, enchantID, displaySlot)
			
			----- border stuff -----		
			-- if core.IsAtTransmogrifier() then
			-- 	if not isEnchantSlot then
			-- 		local _, displayGroup = core.GetItemData(itemID)
			-- 		local skinID = core.GetSelectedSkin()
			-- 		local equippedID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot)
			
			-- 		core.SetShown(mannequin.equippedTexture, not skinID and ((itemID == equippedID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(equippedID))))))
			-- 		core.SetShown(mannequin.visualTexture, not skinID and ((itemID == visualID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(visualID))))))
			-- 		core.SetShown(mannequin.skinVisualTexture, (itemID == skinVisualID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(skinVisualID)))))
			-- 		core.SetShown(mannequin.pendingTexture, (itemID == pendingID) or (displayGroup and (displayGroup > 0) and (displayGroup == select(2, core.GetItemData(pendingID)))))
			-- 		if mannequin.pendingTexture:IsShown() then
			-- 			if skinID then 
			-- 				mannequin.pendingTexture:SetTexCoord(196/512, 292/512, 218/512, 342/512)
			-- 			else
			-- 				mannequin.pendingTexture:SetTexCoord(5/512, 101/512, 3/512, 127/512)
			-- 			end
			-- 		end
			-- 	end
			-- else
			-- 	mannequin.equippedTexture:Hide()
			-- 	mannequin.visualTexture:Hide()
			-- 	mannequin.skinVisualTexture:Hide()
			-- 	mannequin.pendingTexture:Hide()
		
			-- 	if isEnchantSlot then
			-- 		if self.enchant and core.contains(core.enchants[itemID].enchantIDs, self.enchant) then
			-- 			self.equippedTexture:Show()
			-- 		end
			-- 	end
			-- end

		end
		-- if slot == "MainHandSlot" then DEB(mannequin) end -- Was used for tests showing weapons with grayed out model
	end
end

local selected = 1
local Mannequin_SelectNextSourceItem = function(self, backwards)
	local itemID = itemCollectionFrame.displayList[mannequinCount * (itemCollectionFrame.page - 1) + self:GetID()]
	local isEnchantSlot = core.IsEnchantSlot(itemCollectionFrame.selectedSlot)
	local n = 1

	if isEnchantSlot then
		n = itemCollectionFrame.displayGroups[itemID] and #itemCollectionFrame.displayGroups[itemID] or 1
	else
		local _, displayGroup = core.GetItemData(itemID)
		n = itemCollectionFrame.displayGroups[displayGroup] and #itemCollectionFrame.displayGroups[displayGroup] or 1
	end

	selected = (selected + n - 1 + (backwards and -1 or 1)) % n + 1 -- modulo in 1-based indexing: add (n - 1) to convert to 0-based index, do modulo, add 1 to get back to 1-based index
	self:GetScript("OnEnter")(self)
end
	

local Mannequin_OnMouseDown = function(self, button)
	if button == "RightButton" or button == "SHIFT-RightButton" then
		Mannequin_SelectNextSourceItem(self, IsShiftKeyDown() or button == "SHIFT-RightButton")
		return
	end

	local itemID = itemCollectionFrame.displayList[mannequinCount * (itemCollectionFrame.page - 1) + self:GetID()] --core:GetItemsToDisplay()[mannequinCount * (itemCollectionFrame.page - 1) + self:GetID()]
	local isEnchantSlot = core.IsEnchantSlot(itemCollectionFrame.selectedSlot)
	local atTransmogrifier = core.IsAtTransmogrifier()

	if isEnchantSlot then
		if not itemID then core.Debug("Error: expected enchantVisualID in mannequin's OnClick") end
		local enchantID = itemCollectionFrame.displayGroups[itemID][selected] -- itemID ~= core.HIDDEN_ID and itemCollectionFrame.displayGroups[itemID][selected] or itemID

		if enchantID then
			if IsModifiedClick("CHATLINK") then
				-- Fallback to GetSpellInfo is for runes, which do not return a spell link for some reason
				local enchantLink = enchantID == core.HIDDEN_ID and core.HIDDEN or enchantID and (GetSpellLink(enchantID) or GetSpellInfo(enchantID)) or ""
				if ChatEdit_InsertLink(enchantLink) then
					return true
				end
				core.ShowURLPopup(enchantID, isEnchantSlot)
				return
			else
				if atTransmogrifier then
					core.SetPending(core.GetSelectedSlot(), enchantID)
				else				
					itemCollectionFrame:SetPreviewEnchant(enchantID) -- TODO: idk how to handle preview enchant stuff -.-
					if not DressUpFrame:IsShown() then
						ShowUIPanel(DressUpFrame)
						DressUpModel:SetUnit("player")
					end
					DressUpModel:SetSlot(itemCollectionFrame.selectedSlot, enchantID)		
				end
			end
		end
	else
		local _, displayGroup = core.GetItemData(itemID)
		if itemCollectionFrame.displayGroups[displayGroup] then
			itemID = itemCollectionFrame.displayGroups[displayGroup][selected]
		end

		if itemID and GetItemInfo(itemID) then
			local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
			local itemName, itemLink = GetItemInfo(itemID)

			if IsModifiedClick("CHATLINK") then
				if ChatEdit_InsertLink(itemLink) then
					return true
				end				
				core.ShowURLPopup(itemID, isEnchantSlot)
				return
			else			
				if atTransmogrifier then
					core.SetPending(core.GetSelectedSlot(), itemID)
				else
					-- DressUpItemLink(itemCollectionFrame.enchant and ("item:" .. itemID .. ":" .. itemCollectionFrame.enchant) or itemID)
					local link = itemID -- itemCollectionFrame.enchant and ("item:" .. itemID .. ":" .. itemCollectionFrame.enchant) or itemID -- TODO: which behaviour do we want
					if not DressUpFrame:IsShown() then
						ShowUIPanel(DressUpFrame)
						DressUpModel:SetUnit("player")
					end
					core.Debug("Call DressUpModel TryOn with", link, itemCollectionFrame.selectedSlot)
					DressUpModel:TryOn(link, itemCollectionFrame.selectedSlot)
					-- if itemCollectionFrame.model then
					-- 	itemCollectionFrame.model:Undress()
					-- 	itemCollectionFrame.model:Preview(itemID)
					-- 	itemCollectionFrame.model:TryOn("item:"..itemID..":3789")
					-- end
				end
			end
		end
	end
end

-- itemCollectionFrame.tabDummy = CreateFrame("Button", folder .. "TabDummy", itemCollectionFrame)
-- itemCollectionFrame.tabDummy:SetScript("OnClick", function(self)
-- 	print(GetMouseFocus():GetID())
-- end)
local lastMannequinEntered
for i = 1, NUM_CHAT_WINDOWS do
	local editBox = _G["ChatFrame" .. i .. "EditBox"]
	editBox:HookScript("OnTabPressed", function(self)
		if lastMannequinEntered and itemCollectionFrame:IsShown() then
			Mannequin_OnMouseDown(lastMannequinEntered, "RightButton")
		end
	end)
end

local itemCount = 0
local TooltipAddItemLineHelper = function(mannequin, itemID)
	itemCount = itemCount + 1
	local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
	local atTransmogrifier = core.IsAtTransmogrifier()
	local isAvailable = core.IsAvailableSourceItem(itemID, itemCollectionFrame.selectedSlot)

	local itemName, itemLink = GetItemInfo(itemID)
	-- local tmpItemType, _, invType = select(7, GetItemInfo(itemID))
	if not itemLink then core.FunctionOnItemInfoUnique(itemID, mannequin:GetScript("OnEnter"), mannequin) end
	local leftText = (itemCount == selected and "> " or "- ") .. core.GetTextureString(GetItemIcon(itemID)) .. " " .. (core.LinkToColoredString(itemLink) --[[and (itemLink .. " (" .. tmpItemType .. ", " .. invType .. ")")]] or core.LOADING2)

	if unlocked == 1 and itemLink then
		GameTooltip:AddDoubleLine(leftText, core.COLLECTED, nil, nil, nil, 0.1, 1, 0.1)
	elseif unlocked == 0 and itemLink and atTransmogrifier and isAvailable then
		GameTooltip:AddDoubleLine(leftText, core.AVAILABLE .. "*", nil, nil, nil, 0.6, 0.7, 0.1)
	else		
		GameTooltip:AddDoubleLine(leftText, "           ", nil, nil, nil, 0.1, 1, 0.1)
	end
end

-- This lets us restore the normal TAB bindings, incase we get infight while hovering a mannequin
-- (It might even be possible to set TAB bind OnEnter/OnLeave infight via SecureHandlerEnterLeaveTemplate, but making everything protected just for that functionality is not worth the hassle imo)
local BindingManager = CreateFrame("Frame", folder .. "BindingManager", UIParent, "SecureHandlerStateTemplate")
RegisterStateDriver(BindingManager, "combatstate", "[combat] infight; outfight")
BindingManager:SetAttribute("_onstate-combatstate", [[ -- arguments: self, stateid, newstate
    if newstate == "infight" then
		self:ClearBindings()
	end
]])

local lastItem
local Mannequin_OnEnter = function(self)
	if GetMouseFocus() ~= self then return end -- Refresh call from OnItemInfo. TODO: Find better solution for this? (queries uncached source items, but can generate a lot of garbage when scrolling through the list)
	lastMannequinEntered = self

	local atTransmogrifier = core.IsAtTransmogrifier()
	local isEnchantSlot = core.IsEnchantSlot(itemCollectionFrame.selectedSlot)

	local itemID = itemCollectionFrame.displayList[mannequinCount * (itemCollectionFrame.page - 1) + self:GetID()] --core:GetItemsToDisplay()[mannequinCount * (itemCollectionFrame.page - 1) + self:GetID()]
	if itemID ~= lastItem then
		selected = 1
	end
	lastItem = itemID

	if itemID then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if not InCombatLockdown() then
			SetOverrideBindingClick(BindingManager, true, "TAB", self:GetName(), "RightButton")
			SetOverrideBindingClick(BindingManager, true, "SHIFT-TAB", self:GetName(), "SHIFT-RightButton")
		end
		itemCount = 0

		GameTooltip:AddLine(atTransmogrifier and core.APPEARANCE_TOOLTIP_TEXT1B or core.APPEARANCE_TOOLTIP_TEXT1A, 1, 1, 1, nil)
		GameTooltip:AddLine(" ")
		
		if isEnchantSlot then
			if itemID == core.HIDDEN_ID or itemID == core.UNMOG_ID then
				GameTooltip:AddLine("> " .. "No/Hidden Enchant localize me")
			else
				for i, spellID in ipairs(itemCollectionFrame.displayGroups[itemID]) do
					local name, _, tex = GetSpellInfo(spellID)
					local unlocked = core.GetEnchantData(spellID)
					local leftText = (i == selected and "> " or "- ") .. core.GetTextureString(tex) .. " " .. name
					if unlocked == 1 then
						GameTooltip:AddDoubleLine(leftText, core.COLLECTED, nil, nil, nil, 0.1, 1, 0.1)
					else
						GameTooltip:AddDoubleLine(leftText, "           ", nil, nil, nil, 0.1, 1, 0.1)
					end
				end
				
				if #itemCollectionFrame.displayGroups[itemID] > 1 then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(core.APPEARANCE_TOOLTIP_TEXT2, 0.5, 0.5, 0.5, 1)
				end
			end
			-- TODO: ExtraTooltip Enchant Spell Tooltip?
		else
			local _, displayGroupID = core.GetItemData(itemID)
			local displayGroup = displayGroupID and itemCollectionFrame.displayGroups[displayGroupID]
			local hasNotUnlockedItems
			if displayGroup then
				for _, alternativeItemID in pairs(displayGroup) do
					TooltipAddItemLineHelper(self, alternativeItemID)
					local unlocked = core.GetItemData(alternativeItemID)
					hasNotUnlockedItems = hasNotUnlockedItems or (unlocked == 0)
				end
				if #displayGroup > 1 then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(core.APPEARANCE_TOOLTIP_TEXT2, 0.5, 0.5, 0.5, 1)
				end
			else			
				TooltipAddItemLineHelper(self, itemID)
				local unlocked = core.GetItemData(itemID)
				hasNotUnlockedItems = hasNotUnlockedItems or (unlocked == 0)
			end
			if not atTransmogrifier and core.GetDisplayGroupSize(itemID) > (displayGroup and #displayGroup or 1) then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(core.APPEARANCE_TOOLTIP_TEXT3, 0.5, 0.5, 0.5, 1)
			end
			if atTransmogrifier and hasNotUnlockedItems then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(core.APPEARANCE_TOOLTIP_TEXT4, 0.5, 0.5, 0.5, 1)
			end
			core.SetExtraItemTooltip(displayGroup and displayGroup[selected] or itemID, "RIGHT")
		end
		GameTooltip:Show()
	end
end

local Mannequin_OnLeave = function(self)
	selected = 1
	if not InCombatLockdown() then
		ClearOverrideBindings(BindingManager)
	end
	GameTooltip:Hide()
end

local Mannequin_OnMouseWheel = function(self, delta)
	if delta < 0 then
		itemCollectionFrame:NextPage()
	else
		itemCollectionFrame:PreviousPage()
	end

	if self:IsShown() and self:GetScript("OnEnter") then
		self:GetScript("OnEnter")(self)
	end
end

for i = 1, mannequinCount do
	itemCollectionFrame.mannequins[i]:SetScript("OnMouseDown", Mannequin_OnMouseDown)
	itemCollectionFrame.mannequins[i]:SetScript("OnEnter", Mannequin_OnEnter)
	itemCollectionFrame.mannequins[i]:SetScript("OnLeave", Mannequin_OnLeave)
	itemCollectionFrame.mannequins[i]:SetScript("OnMousewheel", Mannequin_OnMouseWheel)
end
displayFrame:SetScript("OnMousewheel", Mannequin_OnMouseWheel)


itemCollectionFrame.GetMaxPage = function(self)
	local list = itemCollectionFrame.displayList

	return list and math.ceil(table.getn(list) / mannequinCount) or 1
end

itemCollectionFrame.SetPage = function(self, num)
	local lowestPage = 1
	local highestPage = self:GetMaxPage()
	
	if num > highestPage then
		self.page = highestPage
	elseif num < lowestPage then
		self.page = lowestPage
	else
		self.page = num
	end

	itemCollectionFrame.pageText:SetText(core.PAGE .. " " .. self.page .. " / " .. highestPage)
	core.SetEnabled(self.pageDownButton, self.page > lowestPage)
	core.SetEnabled(self.pageUpButton, self.page < highestPage)
	
	self:UpdateMannequins()
end

itemCollectionFrame.NextPage = function(self)
	if self.page < self:GetMaxPage() then
		self:SetPage(self.page + 1)
	end
end

itemCollectionFrame.PreviousPage = function(self)
	if self.page > 1 then
		self:SetPage(self.page - 1)
	end
end

-- Requires that we have already selected the appropriate slot. TODO: Need some highlighting texture or animation on the corresponding mannequin
itemCollectionFrame.GoToItem = function(self, itemID)
	local page = 1

	local _, displayGroup = core.GetItemData(itemID)
	if self.displayGroups[displayGroup] then
		itemID = self.displayGroups[displayGroup][1]
	end
	
	for i, listItem in ipairs(self.displayList) do
		if listItem == itemID then
			page = 1 + floor(i / mannequinCount)
			break
		end
	end

	self:SetPage(page)
end

-- Either clear enchant, filters, etc. OnHide or we have to save them per/in parent frame (wardrobe, transmog)
itemCollectionFrame.SetPreviewEnchant = function(self, enchantID, silent)
	if self.enchant == enchantID then return end
	self.enchant = enchantID
	if not silent then
		self:UpdateMannequins()
	end
end

itemCollectionFrame.filter = {}
itemCollectionFrame.filterTypes = { unlocked = true, class = true, race = true, faction = true}

itemCollectionFrame.SetFilter = function(self, filter, filterStatus)
	assert(filter and self.filterTypes[filter], "Missing or unknown filter type in itemCollectionFrame.SetFilter:", filter or "nil")
	self.filter[filter] = filterStatus
	self:UpdateDisplayList()
end

itemCollectionFrame.ClearFilters = function(self)
	itemCollectionFrame.filter = {}
	self:UpdateDisplayList()
end


itemCollectionFrame.ClearData = function(self)	
	self.displayList = {}
	self.displayGroups = {}
	self.itemUnlocked = {}
	self.visualUnlocked = {}
end

itemCollectionFrame.UpdateDisplayList = function(self)
	self:ClearData()
	-- print("UpdateDisplayList")

	local atTransmogrifier = core.IsAtTransmogrifier()
	local slot, category = self.selectedSlot, self.selectedCategory

	local isEnchantSlot = core.IsEnchantSlot(slot)
	local hiddenID = core.HIDDEN_ID

	-- print("atNPC:", atTransmogrifier, "slot:", slot, "cat:", category)

	local t1 = GetTime()

	local searchTerm = core.GetEscapedString(itemCollectionFrame.searchBox:GetText())
	local searchByID = false
	if strmatch(searchTerm, "^%-?%d+$") then
		searchTerm = tonumber(searchTerm)
		searchByID = true
	else
		searchTerm = core.ToNoCasePattern(searchTerm)
	end	
	if strlen(searchTerm) == 0 then
		searchTerm = nil
	end

	local unlockedFilter = self.filter.unlocked	
	local factionFilter = self.filter.faction
	local classFilter = self.filter.class
	local raceFilter = self.filter.race
	local hasExtraFilter = factionFilter or classFilter or raceFilter

	local showQAEnchants = core.db.profile.General.showQAEnchants
	
	local unlockedCount = 0 -- For unlocked statusbar

	-- local memCount = collectgarbage("count")
	if slot then
		if isEnchantSlot then
			for enchantVisualID, enchantInfo in pairs(core.enchants) do
				local group = {}
				local visualUnlocked
				for _, spellID in pairs(enchantInfo.spellIDs) do
					local enchantName = GetSpellInfo(spellID)
					local unlocked, _, _, _, allowableClass, available = core.GetEnchantData(spellID)
					
					if (atTransmogrifier and core.IsAvailableSourceItem(spellID, slot)) or
							(not atTransmogrifier and (showQAEnchants or available)
												  and (not unlockedFilter or unlocked == unlockedFilter)
												  and (not classFilter or band(classFilter, allowableClass) ~= 0)) then
						if not searchTerm or spellID == searchTerm or (enchantName and strfind(enchantName, searchTerm)) then
							self.itemUnlocked[spellID] = 1
							visualUnlocked = visualUnlocked or unlocked == 1
							tinsert(group, spellID)
						end
					end
				end
				if #group > 0 then
					tinsert(self.displayList, enchantVisualID)
					self.displayGroups[enchantVisualID] = group
					unlockedCount = unlockedCount + (visualUnlocked and 1 or 0)
					self.visualUnlocked[enchantVisualID] = visualUnlocked and 1 or 0
				end
			end
		else
			local withNames = searchTerm and not searchByID
			for itemID, itemName in core.ItemIterator(slot, category, withNames) do
				local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
				local allowableClass, allowableFaction, allowableRace
				if hasExtraFilter then
					allowableClass, allowableFaction, allowableRace = core.GetItemData2(itemID)
				end
				
				if (atTransmogrifier and core.IsAvailableSourceItem(itemID, slot)) or
						(not atTransmogrifier and (not unlockedFilter or unlocked == unlockedFilter)) then
					
					if not hasExtraFilter or
							((not classFilter or not allowableClass or band(classFilter, allowableClass) ~= 0) 
							and (not factionFilter or not allowableFaction or band(factionFilter, allowableFaction) ~= 0)
							and (not raceFilter or not allowableRace or band(raceFilter, allowableRace) ~= 0)) then

						if not searchTerm or itemID == searchTerm or (itemName and strfind(itemName, searchTerm)) then --strfind(strlower(itemName), strlower(searchTerm))) then --[[strfind(itemName, searchTerm)) then]] --strfind(name, searchTerm)) then
							
							self.itemUnlocked[itemID] = unlocked
							self.visualUnlocked[itemID] = unlocked	-- this will track whether the visual is unlocked by an item that fits the current selection

							if displayGroup == 0 or not self.displayGroups[displayGroup] then
								table.insert(self.displayList, itemID)
								
								if displayGroup == 0 and unlocked == 1 then
									unlockedCount = unlockedCount + 1 -- counting the unlocked visuals without display group
								end
								
								if displayGroup ~= 0 then
									self.displayGroups[displayGroup] = {} -- temporary displayGroups that only contain items that fit the current selection
								end
							end

							if self.displayGroups[displayGroup] then
								table.insert(self.displayGroups[displayGroup], itemID)
							end
						end
					end
				end
			end

			for displayID, items in pairs(self.displayGroups) do
				local visualUnlocked = 0
				for _, itemID in pairs(items) do
					if self.itemUnlocked[itemID] == 1 then
						visualUnlocked = 1
					end
				end
				for _, itemID in pairs(items) do
					self.visualUnlocked[itemID] = visualUnlocked
				end
				if visualUnlocked == 1 then
					unlockedCount = unlockedCount + 1 -- count the unlocked visuals with display group
				end
			end
		end
		
		-- table.insert(self.displayList, 1) -- hidden item at start of list, would need special handling in mannequins and in almost all functions here?
		-- self.visualUnlocked[1] = 1

		local t2 = GetTime()

		table.sort(self.displayList, function(a, b) -- TODO: sorting like this only compares the items we picked to represent a visual group, so sort by itemID is weird
			local unlockedA = self.visualUnlocked[a] --core.GetItemData(a) --
			local unlockedB = self.visualUnlocked[b] --core.GetItemData(b) --

			if a == hiddenID or b == hiddenID then
				return a == 1
			elseif unlockedA == unlockedB then
				return a > b
			else
				return unlockedA > unlockedB
			end
		end)

		local t3 = GetTime()

		-- print("garbage:", collectgarbage("count") - memCount)
		collectgarbage("collect")
		local t4 = GetTime()
		--print("Time for BuildList:", t2 - t1, "Time for Sort:", t3 - t2, "Time for collect:", t4 - t3)
	end

	itemCollectionFrame.unlockedStatusBar:SetMinMaxValues(0, table.getn(self.displayList))
	itemCollectionFrame.unlockedStatusBar:SetValue(unlockedCount)
	
	itemCollectionFrame.noUnlocksText:SetText(isEnchantSlot and (core.NO_UNLOCKS_HINT_TEXT1 .. core.NO_UNLOCKS_HINT_TEXT2) or core.NO_UNLOCKS_HINT_TEXT1)
	core.SetShown(itemCollectionFrame.noUnlocksText, atTransmogrifier and slot and (#self.displayList == 0) and core.receivedAvailableMogsAnswer)

	self:SetPage(1)
end


------------ UnlockedStatusBar ---------------

itemCollectionFrame.unlockedStatusBar = CreateFrame("StatusBar", folder.."UnlockedStatusBar", itemCollectionFrame)
itemCollectionFrame.unlockedStatusBar:SetSize(160, 12)
--itemCollectionFrame.unlockedStatusBar:SetPoint("CENTER", itemCollectionFrame.pageDownButton, "RIGHT", itemCollectionFrame.displayFrame:GetWidth() / 4, 0)
itemCollectionFrame.unlockedStatusBar:SetPoint("LEFT", itemCollectionFrame.pageUpButton, "RIGHT", 10, 0)
itemCollectionFrame.unlockedStatusBar:SetOrientation("HORIZONTAL")
itemCollectionFrame.unlockedStatusBar:SetStatusBarTexture("interface/targetingframe/ui-statusbar.blp", "BACKGROUND")
itemCollectionFrame.unlockedStatusBar:SetStatusBarColor(20 / 255, 0.7, 8 / 255) --30 / 255, 1, 12 / 255)
itemCollectionFrame.unlockedStatusBar:EnableMouse()

itemCollectionFrame.unlockedStatusBar.border = itemCollectionFrame.unlockedStatusBar:CreateTexture(nil, "BORDER")
itemCollectionFrame.unlockedStatusBar.border:SetTexture("interface/tooltips/ui-statusbar-border.blp")
itemCollectionFrame.unlockedStatusBar.border:SetPoint("BOTTOMLEFT", -2, -2)
itemCollectionFrame.unlockedStatusBar.border:SetPoint("TOPRIGHT", 2, 2)

itemCollectionFrame.unlockedStatusBar.text = itemCollectionFrame.unlockedStatusBar:CreateFontString()
itemCollectionFrame.unlockedStatusBar.text:SetFontObject(GameFontWhiteSmall)
itemCollectionFrame.unlockedStatusBar.text:SetPoint("CENTER")
itemCollectionFrame.unlockedStatusBar.text:SetJustifyH("CENTER")
itemCollectionFrame.unlockedStatusBar.text:SetJustifyV("MIDDLE")

itemCollectionFrame.unlockedStatusBar:SetScript("OnValueChanged", function(self, value)
	local min, max = self:GetMinMaxValues()
	itemCollectionFrame.unlockedStatusBar.text:SetText(value .. " / " .. max)
end)

itemCollectionFrame.unlockedStatusBar.SetMinMaxValuesOld = itemCollectionFrame.unlockedStatusBar.SetMinMaxValues
itemCollectionFrame.unlockedStatusBar.SetMinMaxValues = function(self, min, max) -- why does this not trigger OnValue changed!?
	self:SetMinMaxValuesOld(min, max)
	local value = self:GetValue()
	self:GetScript("OnValueChanged")(self, value)
end

core.SetTooltip(itemCollectionFrame.unlockedStatusBar, core.UNLOCKED_BAR_TOOLTIP_TEXT1, nil, nil, nil, nil, 1)

--------------- SearchBox ---------------------------

itemCollectionFrame.searchBox = core.CreateSearchBox(folder .. "SearchBox", itemCollectionFrame)
itemCollectionFrame.searchBox:SetPoint("RIGHT", itemCollectionFrame.pageDownButton, "LEFT", -90, 0)
itemCollectionFrame.searchBox:SetSize(120, 20)
itemCollectionFrame.searchBox.updateDelay = 0.5
itemCollectionFrame.searchBox:SetFontObject(GameFontWhiteSmall)
itemCollectionFrame.searchBox:SetAutoFocus(false)	
itemCollectionFrame.searchBox:HookScript("OnTextChanged", function(self)
	if not self.initDone then self.initDone = true; return end -- Ignore the first call
	self.lastChange = GetTime()
	self:SetScript("OnUpdate", function(self, elapsed)
		if GetTime() > self.lastChange + self.updateDelay then
			self:SetScript("OnUpdate", nil)
			itemCollectionFrame:UpdateDisplayList()
		end
	end)
end)
core.SetTooltip(itemCollectionFrame.searchBox, core.SEARCHBOX_TOOLTIP_TEXT1, nil, nil, nil, nil, 1)
itemCollectionFrame.searchBox:Show()


--------------- OptionsDDM ---------------------------

itemCollectionFrame.optionsDDM = core.CreateOptionsDDM(itemCollectionFrame)
itemCollectionFrame.optionsDDM:SetPoint("LEFT", itemCollectionFrame.searchBox, "RIGHT", -10, -3)
itemCollectionFrame.optionsDDM:Show()


--------------- CheckBox Show Enchants ---------------

itemCollectionFrame.previewWeaponEnchants = true

itemCollectionFrame.enchantCheckButton = CreateFrame("CheckButton", folder .. "ShowEnchantsCheckButton", itemCollectionFrame, "UICheckButtonTemplate")
_G[itemCollectionFrame.enchantCheckButton:GetName() .. "Text"]:SetText(core.ENCHANT_PREVIEW)
itemCollectionFrame.enchantCheckButton:SetSize(20, 20)
itemCollectionFrame.enchantCheckButton:SetPoint("BOTTOMRIGHT", -(_G[itemCollectionFrame.enchantCheckButton:GetName() .. "Text"]:GetWidth() + 20), 10)
itemCollectionFrame.enchantCheckButton:SetChecked(itemCollectionFrame.previewWeaponEnchants)
itemCollectionFrame.enchantCheckButton:SetScript("OnClick", function(self, button)
	itemCollectionFrame.previewWeaponEnchants = self:GetChecked()
	itemCollectionFrame:UpdateMannequins()
end)
core.SetTooltip(itemCollectionFrame.enchantCheckButton, core.ENCHANT_PREVIEW_BUTTON_TOOLTIP_TEXT, nil, nil, nil, nil, 1)


--------------- Link Popup ---------------
local locale = string.sub(GetLocale(), 1, 2)

local urlBases = {
	"https://db.rising-gods.de/?",
	"https://www.wowhead.com/wotlk/" .. locale .. "/",
}
local urlTexts = {
	"Rising Gods URL:",
	"Wowhead URL:"
}
local copyURLPopup = strupper(folder) .. "_COPY_URL_POPUP"

StaticPopupDialogs[copyURLPopup] = {
    text = "",
    button1 = core.TOGGLE_URL,
    button2 = CLOSE,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    hasEditBox = 1,
    hasWideEditBox = 1,
    preferredIndex = 3,
    OnShow = function(self, data)
		TransmoggyDB.preferredURL = TransmoggyDB.preferredURL or 1
        self.text:SetText(urlTexts[TransmoggyDB.preferredURL])
        self.wideEditBox:SetText(urlBases[TransmoggyDB.preferredURL] .. (data.isSpell and "spell" or "item") .. "=" .. data.itemID)
        self.wideEditBox:HighlightText()
    end,
    OnAccept = function(self, data)
        TransmoggyDB.preferredURL = ((TransmoggyDB.preferredURL or 1) + #urlBases) % #urlBases + 1
    end,
    OnCancel = function(self, data)
        data.close = true
    end,
    OnHide = function(self, data)
        if not data.close then
            StaticPopup_Show(copyURLPopup, nil, nil, data)
        end
    end,	
	EditBoxOnEscapePressed = function(self, data)
		data.close = true
		self:GetParent():Hide()
	end,
	EditBoxOnEnterPressed = function(self, data)
		data.close = true
		self:GetParent():Hide()
	end,	
	OnUpdate = function(self, ellapsed) -- EditBoxOnTextChanged doesn't seem to work for wideEditBox -.-
		TransmoggyDB.preferredURL = TransmoggyDB.preferredURL or 1
        self.wideEditBox:SetText(urlBases[TransmoggyDB.preferredURL] .. (self.data.isSpell and "spell" or "item") .. "=" .. self.data.itemID)
        self.wideEditBox:HighlightText()
	end,
}

core.ShowURLPopup = function(itemID, isSpell)
	if StaticPopup_Visible(copyURLPopup) then
        StaticPopup_Hide(copyURLPopup)
    end

	local data = {
		itemID = itemID or 0,
		isSpell = isSpell,
	}

	return StaticPopup_Show(copyURLPopup, nil, nil, data)
end