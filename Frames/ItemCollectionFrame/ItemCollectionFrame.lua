local folder, core = ...

------------- UPDOOTS -------------
local strfind = strfind
local strmatch = strmatch
local strlower = strlower
local strsub = strsub
local tonumber = tonumber
local GetItemInfo = GetItemInfo
-----------------------------------

local HEADER_HEIGHT, BOTTOM_HEIGHT, SIDE_PADDING = 40, 30, 12

----------- ItemCollectionFrame -----------

core.itemCollectionFrame = CreateFrame("Frame", folder .. "ItemCollectionFrame", UIParent)
local itemCollectionFrame = core.itemCollectionFrame

-- itemCollectionFrame.backgroundTexture = itemCollectionFrame:CreateTexture(nil, "BACKGROUND")
-- itemCollectionFrame.backgroundTexture:SetAllPoints()
-- itemCollectionFrame.backgroundTexture:SetTexture(0.3, 0.3, 0.3)

-- itemCollectionFrame:SetBackdrop({
-- 	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
--   	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
--   	tile = 1, tileSize = 12, edgeSize = 12, 
--   	insets = {left = 4, right = 4, top = 4, bottom = 4},
-- })

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

	self:SetBackdrop(not atTransmogrifier and BACKDROP_TOAST_12_12 or {})

	core.SetShown(self.optionsDDM, not atTransmogrifier)

	self.searchBox:ClearAllPoints()
	self.unlockedStatusBar:ClearAllPoints()

	if not atTransmogrifier then
		PlaySound("igCharacterInfoOpen")
		self.slotButtons["Head"]:Click()
		self.unlockedStatusBar:SetPoint("BOTTOM", self, "TOP", 0, 10)
		self.unlockedStatusBar:Show()
		self.searchBox:SetPoint("LEFT", self.unlockedStatusBar, "RIGHT", 20, 1)
		--self.searchBox:SetPoint("BOTTOMRIGHT", self.itemTypeDDM, "TOPLEFT", 3, 12)
	else
		self.searchBox:SetPoint("RIGHT", self.itemTypeDDM, "LEFT", 0, 3)
		self.unlockedStatusBar:Hide()
	end
end)

itemCollectionFrame:SetScript("OnHide", function(self)	
	if not core.IsAtTransmogrifier() then
		PlaySound("igCharacterInfoClose")
	end

	-- when slot is nil, update list does not iterate over items, so using setters here, does not cause a reapeted item iteration
	-- probably still better to give setters "silent" option, so they don't trigger updates
	self:SetSlotAndCategory(nil, nil)
	-- self.enchant = nil
	-- self.filter = {}
	-- self:ClearData()
	-- self.selectedSlot = nil
	-- self.selectedCategory = nil
	self:SetPreviewEnchant(nil)
	self:SetUnlockedFilter(nil)
	self.searchBox:SetText("")
end)

itemCollectionFrame.SetSlotAndCategory = function(self, slot, category, update)
	--print("set location, type", locationName, itemType)
	if not update and itemCollectionFrame.selectedSlot == slot and itemCollectionFrame.selectedCategory == category then return end
	
	-- if theres only one category in slot, select it, just so it gets shown in ddm? core.SetSlotAndCategory would need this too? :/
	-- if not category and slot and core.slotCategories[slot] and core.Length(core.slotCategories[slot]) == 1 then
	-- 	category = core.slotCategories[1] -- TODO: why no worky?
	-- end

	self.selectedSlot = slot
	self.selectedCategory = category
	
	-- highlight current slot button in wardrobe
	if not core.IsAtTransmogrifier() then
		for _, button in pairs(self.slotButtons) do
			core.SetShown(button.selectedTexture, button.itemSlot == slot)
		end
		core.SetShown(self.enchantSlotButton.selectedTexture, self.enchantSlotButton.itemSlot == slot)
	end

	-- TODO: setshown all the other shit: shown = not (atNpc and not slot)
	core.SetShown(self.noSlotSelectedText, not slot)
	core.SetShown(self.searchBox, slot)
	core.SetShown(self.itemTypeDDM, slot)
	core.SetShown(self.pageDownButton, slot)
	core.SetShown(self.pageUpButton, slot)
	core.SetShown(self.pageText, slot)
	
	UIDropDownMenu_SetText(self.itemTypeDDM, category and (core.CATEGORY_DISPLAY_NAME[category] or core.RemoveFirstWordInString(category)) or core.SELECT_ITEM_TYPE)
	if UIDropDownMenu_GetCurrentDropDown() == self.itemTypeDDM then CloseDropDownMenus() end
	core.UIDropDownMenu_SetEnabled(self.itemTypeDDM, slot and core.slotCategories[slot] and core.Length(core.slotCategories[slot]) > 1)

	self:UpdateDisplayList()
end


----------- TransmogLocation / InventorySlots Buttons -----------

local BUTTON_WIDTH = 28
local BUTTON_SPACING, BUTTON_SPACING_WIDE = 2, 10

local slots = core.API.Slots
--local order = { slots.Head, slots.Shoulders, slots.Back, slots.Chest, slots.Body, slots.Tabard, slots.Wrists, slots.Hands, slots.Waist, slots.Legs, slots.Feet, slots.MainHand, slots.ShieldHandWeapon, slots.OffHand }
local order = {"Head", "Shoulders", "Back", "Chest", "Body", "Tabard", "Wrists", "Hands", "Waist", "Legs", "Feet", "MainHand", "ShieldHandWeapon", "OffHand", "Ranged"}

itemCollectionFrame.slotButtons = {}
for i, name in pairs(order) do
	itemCollectionFrame.slotButtons[name] = core.CreateSlotButtonFrame(itemCollectionFrame, name, BUTTON_WIDTH)
	if name == "Head" then
		itemCollectionFrame.slotButtons[name]:SetPoint("TOPLEFT", SIDE_PADDING, -10)
	elseif name == "MainHand" then
		itemCollectionFrame.slotButtons[name]:SetPoint("TOPLEFT", itemCollectionFrame.slotButtons[order[i - 1]], "TOPRIGHT", BUTTON_SPACING_WIDE, 0)
	else	
		itemCollectionFrame.slotButtons[name]:SetPoint("TOPLEFT", itemCollectionFrame.slotButtons[order[i - 1]], "TOPRIGHT", BUTTON_SPACING, 0)
	end
end


--- TEST

-- enchantSlots = { "MainHandEnchantSlot", "OffHandEnchantSlot" }
itemCollectionFrame.enchantSlotButton = core.CreateEnchantSlotButton(itemCollectionFrame.slotButtons["MainHand"], core.enchantSlots[1], BUTTON_WIDTH * 0.6)
itemCollectionFrame.enchantSlotButton:SetPoint("CENTER", itemCollectionFrame.slotButtons["MainHand"], "BOTTOMRIGHT")

----------- ItemType DropDownMenu -----------

itemCollectionFrame.itemTypeDDM = core:CreateItemTypeDDM(itemCollectionFrame)
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
displayFrame:SetPoint("TOPLEFT", itemCollectionFrame, "TOPLEFT", SIDE_PADDING, -HEADER_HEIGHT) -- TODO: point to upper bar with slotbuttons and options and or save dropdownmenu
displayFrame:SetSize(WIDTH, HEIGHT)
displayFrame:EnableMouseWheel()

-- displayFrame.backgroundTexture = displayFrame:CreateTexture(nil, "BACKGROUND")
-- displayFrame.backgroundTexture:SetAllPoints()
-- displayFrame.backgroundTexture:SetTexture(0.5, 0.5, 0.5, 0.5)

----------- MannequinFrames -----------

itemCollectionFrame.mannequins = {}
for i = 1, mannequinCount do
	itemCollectionFrame.mannequins[i] = core:CreateMannequinFrame(displayFrame, i, (WIDTH - IN_BETWEEN_PADDING * (MANNEQUIN_COLCOUNT + 1)) / MANNEQUIN_COLCOUNT,
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
			itemCollectionFrame.mannequins[i] = core:CreateMannequinFrame(displayFrame, i, (WIDTH - IN_BETWEEN_PADDING * (MANNEQUIN_COLCOUNT + 1)) / MANNEQUIN_COLCOUNT,
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
itemCollectionFrame.pageDownButton:SetPoint("TOPLEFT", displayFrame, "BOTTOM", 0, 0)
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

------------------------------------------------------

itemCollectionFrame.noSlotSelectedText = itemCollectionFrame:CreateFontString()
itemCollectionFrame.noSlotSelectedText:SetFontObject(GameFontNormal)
itemCollectionFrame.noSlotSelectedText:SetPoint("CENTER", itemCollectionFrame.displayFrame, "CENTER", 0, 0)
itemCollectionFrame.noSlotSelectedText:SetJustifyH("CENTER")
itemCollectionFrame.noSlotSelectedText:SetJustifyV("MIDDLE")
itemCollectionFrame.noSlotSelectedText:SetText(core.NO_SLOT_SELECTED_TEXT)

------------------------------------------------------

itemCollectionFrame.UpdateMannequins = function(self)
	local _, race = UnitRace("player")
	if not core.mannequinPositions[race] then race = "Human" end
	--local inventorySlot = select(2, core:GetTransmogLocationInfo(self.location))
	local slot, category = self.selectedSlot, self.selectedCategory
	local pos = (slot and race) and core.mannequinPositions[race][slot] or {0, 0, 0, 0}
	local list = self.displayList-- core:GetItemsToDisplay()
	
	local sequenceID, sequenceTime = 15, 100

	local sex = UnitSex("player")
	local id = core.sexRaceToID[sex][race]
	local posCat = category or "Default"
	if MyAddonDB.positionData and MyAddonDB.positionData[id] and MyAddonDB.positionData[id][slot] and MyAddonDB.positionData[id][slot][posCat] then
		local x, y, z, facing, near, far, seq, time = unpack(MyAddonDB.positionData[id][slot][posCat])
		pos = { x, y, z, facing }
		sequenceID, sequenceTime = seq, time
		-- pos = MyAddonDB.positionData[id][slot]
	end

	--local enchantID = 3789

	for i = 1, mannequinCount do
		local itemID = list[mannequinCount * (self.page - 1) + i]
		local mannequin = self.mannequins[i]

		if not itemID then
			mannequin:SetPosition(0, 0, 0)
			mannequin:Hide()
		else
			mannequin:SetDisplayMode(self.visualUnlocked[itemID] == 1)

			mannequin:SetPosition(pos[1], pos[2], pos[3])
			mannequin:SetFacing(pos[4])
			if sequenceID then
				mannequin:SetAnimation(sequenceID, sequenceTime)
			end
			if not core.IsEnchantSlot(slot) then
				local _, _, _, class, subClass = core.GetItemData(itemID)
				if class == 2 and subClass == 2 then mannequin:SetFacing(-pos[4]) end -- Bows
			end
			mannequin:Undress()			
			mannequin:TryOn(itemID, slot) --"item:"..itemID..":"..enchantID -- MannequinFrame displays chosen enchant itself
			mannequin:Show()
		end
		-- if slot == "MainHandSlot" then DEB(mannequin) end -- Was used for tests showing weapons with greyed out model
	end
end


local selected = 1
local Mannequin_SelectNextSourceItem = function(self, backwards)
	local itemID = itemCollectionFrame.displayList[mannequinCount * (itemCollectionFrame.page - 1) + self:GetID()]
	local _, displayGroup = core.GetItemData(itemID)
	local n = itemCollectionFrame.displayGroups[displayGroup] and #itemCollectionFrame.displayGroups[displayGroup] or 1

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

	if isEnchantSlot then
		if not itemID then print("Error: expected enchantVisualID in mannequin's OnClick") end
		itemCollectionFrame:SetPreviewEnchant(itemID ~= 0 and core.enchants[itemID].enchantIDs[1] or nil)  -- TODO: make enchant choosable and hide this data specific stuff
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
				return
			end
			
			if core.IsAtTransmogrifier() then
				core.SetPending(core.GetSelectedSlot(), itemID)
			else
				-- DressUpItemLink(itemCollectionFrame.enchant and ("item:" .. itemID .. ":" .. itemCollectionFrame.enchant) or itemID)
				link = itemCollectionFrame.enchant and ("item:" .. itemID .. ":" .. itemCollectionFrame.enchant) or itemID
				if not DressUpFrame:IsShown() then
					ShowUIPanel(DressUpFrame)
					DressUpModel:SetUnit("player")
				end
				print("Call DressUpModel TryOn with", link, itemCollectionFrame.selectedSlot)
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

	local itemName, itemLink = GetItemInfo(itemID)
	-- local tmpItemType, _, invType = select(7, GetItemInfo(itemID))
	if not itemLink then core.FunctionOnItemInfoUnique(itemID, mannequin:GetScript("OnEnter"), mannequin) end
	local leftText = (itemCount == selected and "> " or "- ") .. core.GetTextureString(GetItemIcon(itemID)) .. " " .. (core.LinkToColoredString(itemLink) --[[and (itemLink .. " (" .. tmpItemType .. ", " .. invType .. ")")]] or core.LOADING2)

	if unlocked == 1 and itemLink then
		GameTooltip:AddDoubleLine(leftText, core.COLLECTED, nil, nil, nil, 0.1, 1, 0.1)
	else		
		GameTooltip:AddDoubleLine(leftText, "           ", nil, nil, nil, 0.1, 1, 0.1)
	end
	--if unlocked ~= 1 then _G["GameTooltipTextLeft"..GameTooltip:NumLines()]:SetAlpha(lockedAlpha) end
end

local lastItem
local Mannequin_OnEnter = function(self)
	if GetMouseFocus() ~= self then return end -- TODO: Find better solution for all this (gets queued on iteminfo when we where missing on of the iteminfos, can generate a lot of garbage on scroll)
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
        SetOverrideBindingClick(self, true, "TAB", self:GetName(), "RightButton") -- TODO: NO COMBAT. Any other way to avoid possibly breaking binds in combat while still allowing normal movement?
		SetOverrideBindingClick(self, true, "SHIFT-TAB", self:GetName(), "SHIFT-RightButton")
		itemCount = 0

		GameTooltip:AddLine(atTransmogrifier and core.APPEARANCE_TOOLTIP_TEXT1B or core.APPEARANCE_TOOLTIP_TEXT1A, 1, 1, 1, nil)
		GameTooltip:AddLine(" ")
		
		local _, displayGroup = core.GetItemData(itemID)
		if isEnchantSlot then
			if itemID == 0 then
				GameTooltip:AddLine("Hidden Enchant yoyoyoyo")
			else
				for _, id in pairs(core.enchants[itemID].enchantIDs) do
					local name, _, tex = core.GetEnchantInfo(id)
					GameTooltip:AddLine(core.GetTextureString(tex) .. " " .. name)
				end
			end
		elseif itemCollectionFrame.displayGroups[displayGroup] then
			for _, alternativeItemID in pairs(itemCollectionFrame.displayGroups[displayGroup]) do
				TooltipAddItemLineHelper(self, alternativeItemID)
			end
			if #itemCollectionFrame.displayGroups[displayGroup] > 1 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(core.APPEARANCE_TOOLTIP_TEXT2, 0.5, 0.5, 0.5, 1)
			end
		else			
			TooltipAddItemLineHelper(self, itemID)
		end
		GameTooltip:Show()
		if isEnchantSlot then
			-- TODO: maybe: ExtraTooltip Enchant Spell Tooltip?
		else
			core.SetExtraItemTooltip(displayGroup and itemCollectionFrame.displayGroups[displayGroup] and itemCollectionFrame.displayGroups[displayGroup][selected] or itemID, "RIGHT")
		end
	end
end

local Mannequin_OnLeave = function(self)
	selected = 1
	ClearOverrideBindings(self)
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

itemCollectionFrame.GoToItem = function(self, itemID)
	local page = 1

	local _, displayGroup = core.GetItemData(itemID)
	if itemCollectionFrame.displayGroups[displayGroup] then
		itemID = itemCollectionFrame.displayGroups[displayGroup][1]
	end
	
	for i, listItem in pairs(itemCollectionFrame.displayList) do
		-- local _, displayGroup = core.GetItemData(listItem)
		
		-- if itemCollectionFrame.displayGroups[displayGroup] then
		-- 	for _, groupItem in pairs() do
		-- 		if groupItem == itemID then
		-- 			page = 1 + floor(i / mannequinCount)
		-- 			break
		-- 		end
		-- 	end
		-- else
		if listItem == itemID then
			page = 1 + floor(i / mannequinCount)
			break
		end
	end

	self:SetPage(page)
end


-- Either clear enchant, filters, etc. OnHide or we have save them per/in parent frame (wardrobe, transmog)
itemCollectionFrame.SetPreviewEnchant = function(self, enchantID)
	self.enchant = enchantID	
	self:UpdateMannequins()
end

itemCollectionFrame.filter = {}
itemCollectionFrame.SetUnlockedFilter = function(self, filterStatus)
	self.filter.unlocked = filterStatus
	self:UpdateDisplayList()
end

-- Mappings to match slots/categories with our item data. Probably should change item data at some point, to hide/optimize some of this
-- e.g. there is no reason we have to use 3 bytes in our itemData for equipLoc (MH, 2H, ROBE etc), class (ARMOR, WEAPON) and subclass (CLOTH, DAGGER)
-- At the least class+subclass could easily me replaced by a single ID
-- (Could also change our category identifiers to the same ID's on that occasion and only use localized names for display and when we have to find out the equipped weapon cat)
-- (Could get that items category from itemdata anyway tho, if we assume that our item data is complete)
-- There are 96 combinations of type, class and subclass in our data, so all 3 would fit into one byte (with one bit to spare, but bit operations are probably more expensive then they are worth)
-- When we can map these to slot + cat, before list iteration we could generate dict that says our current slot + cat selection allows certain ids
-- In iteration we only need one table lookup to know if an item fits selection
-- TODO: if we touch/rework our item data to include more data (class, faction, color?), implement these changes?

-- These are IDs for itemTypes (2H, 1H, MH, OH, etc) in the item data. Not to be confused with inventorySlotIDs
local slotItemTypes = core.slotItemTypes -- gets defined in dataUtils now and is also not needed here anymore. dataUtils provides slot iterators now

local typeToClassSubclass = {
	[core.CATEGORIES.ARMOR_CLOTH] = {4, 1},
	[core.CATEGORIES.ARMOR_LEATHER] = {4, 2},
	[core.CATEGORIES.ARMOR_MAIL] = {4, 3},
	[core.CATEGORIES.ARMOR_PLATE] = {4, 4},
	[core.CATEGORIES.ARMOR_MISC] = {4, 0},
	[core.CATEGORIES.ARMOR_SHIELDS] = {4, 6},
	[core.CATEGORIES.WEAPON_DAGGERS] = {2, 15},
	[core.CATEGORIES.WEAPON_FIST_WEAPONS] = {2, 13},
	[core.CATEGORIES.WEAPON_1H_AXES] = {2, 0},
	[core.CATEGORIES.WEAPON_1H_MACES] = {2, 4},
	[core.CATEGORIES.WEAPON_1H_SWORDS] = {2, 7},
	[core.CATEGORIES.WEAPON_POLEARMS] = {2, 6},
	[core.CATEGORIES.WEAPON_STAVES] = {2, 10},
	[core.CATEGORIES.WEAPON_2H_AXES] = {2, 1},
	[core.CATEGORIES.WEAPON_2H_MACES] = {2, 5},
	[core.CATEGORIES.WEAPON_2H_SWORDS] = {2, 8},
	[core.CATEGORIES.WEAPON_FISHING_POLES] = {2, 20},
	[core.CATEGORIES.WEAPON_MISC] = {2, 14},
	[core.CATEGORIES.MISC_JUNK] = {15, 0},
	[core.CATEGORIES.WEAPON_BOWS] = {2, 2},
	[core.CATEGORIES.WEAPON_CROSSBOWS] = {2, 18},
	[core.CATEGORIES.WEAPON_GUNS] = {2, 3},
	[core.CATEGORIES.WEAPON_THROWN] = {2, 16},
	[core.CATEGORIES.WEAPON_WANDS] = {2, 19},
	[core.CATEGORIES.TRADE_GOODS_MEAT] = {7, 8},
	[core.CATEGORIES.CONSUMABLE_CONSUMABLE] = {0, 0},
	[core.CATEGORIES.QUEST_QUEST] = {12, 0},
	[core.CATEGORIES.WEAPON_1H_EXOTICA] = {2, 11},
	--["Rüstung Buchbände"] = {4, 7},
	--["Rüstung Götzen"] = {4, 8},
	--["Rüstung Totems"] = {4, 9},
	--["Rüstung Siegel"] = {4, 10},
}
core.typeToClassSubclass = typeToClassSubclass

core.classSubclassToType = {
	[4] = { -- Armor
		[0] = core.CATEGORIES.ARMOR_MISC,
		[1] = core.CATEGORIES.ARMOR_CLOTH,
		[2] = core.CATEGORIES.ARMOR_LEATHER,
		[3] = core.CATEGORIES.ARMOR_MAIL,
		[4] = core.CATEGORIES.ARMOR_PLATE,
		[6] = core.CATEGORIES.ARMOR_SHIELDS,
	},
	[2] = { -- Weapon
		[15] = core.CATEGORIES.WEAPON_DAGGERS,
		[13] = core.CATEGORIES.WEAPON_FIST_WEAPONS,
		[0] = core.CATEGORIES.WEAPON_1H_AXES,
		[4] = core.CATEGORIES.WEAPON_1H_MACES,
		[7] = core.CATEGORIES.WEAPON_1H_SWORDS,
		[6] = core.CATEGORIES.WEAPON_POLEARMS,
		[10] = core.CATEGORIES.WEAPON_STAVES,
		[1] = core.CATEGORIES.WEAPON_2H_AXES,
		[5] = core.CATEGORIES.WEAPON_2H_MACES,
		[8] = core.CATEGORIES.WEAPON_2H_SWORDS,
		[20] = core.CATEGORIES.WEAPON_FISHING_POLES,
		[14] = core.CATEGORIES.WEAPON_MISC,
		[2] = core.CATEGORIES.WEAPON_BOWS,
		[18] = core.CATEGORIES.WEAPON_CROSSBOWS,
		[3] = core.CATEGORIES.WEAPON_GUNS,
		[16] = core.CATEGORIES.WEAPON_THROWN,
		[19] = core.CATEGORIES.WEAPON_WANDS,
		[11] = core.CATEGORIES.WEAPON_1H_EXOTICA, -- 1H_EXOTICA. There is exactly one item in our itemData of this type (32407 - "Creature - Maiev's Glaive"). Unlockable, but not obtainable through normal means
	},
	[15] = { -- Miscellaneous
		[0] = core.CATEGORIES.MISC_JUNK, -- Mostly offhand fish. 2 test chests (34025, 37126)
	},
	[12] = { -- Questitem
		[0] = core.CATEGORIES.QUEST_QUEST, -- Equipable quest items, can be a lot of different slots. Not unlockable anyway tho?
	},
	[0] = { -- Consumable
		[0] = core.CATEGORIES.CONSUMABLE_CONSUMABLE, -- A single item has this type, unlockable and obtainable (22743 - "Bloosail Sash")
	},
	[7] = { -- Trade goods
		[8] = core.CATEGORIES.TRADE_GOODS_MEAT, -- Two equippable offhand fish, unlockable and obtainable (27515, 27516)
	},
}

-- basically the same as core.slotCategories, but as dict for faster lookup
local slotHasCategory = {}
for _, slot in pairs(core.itemSlots) do
	slotHasCategory[slot] = {}
	for _, category in pairs(core.slotCategories[slot]) do
		slotHasCategory[slot][category] = true
	end
end

itemCollectionFrame.ClearData = function(self)
	if self.displayList then
		wipe(self.displayList)
		wipe(self.displayGroups)
		wipe(self.itemUnlocked)
		wipe(self.visualUnlocked)
		--wipe(self.displayGroup)
		--collectgarbage() -- any point in doing this manually?
	else
		self.displayList = {}
		self.displayGroups = {}  -- filtered according to selection (item types, unlock status, etc.)
		self.itemUnlocked = {}
		self.visualUnlocked = {}
		--self.displayGroup = {}
	end
end

itemCollectionFrame.UpdateDisplayList = function(self)
	self:ClearData()

	local atTransmogrifier = core.IsAtTransmogrifier()
	local slot, category = self.selectedSlot, self.selectedCategory

	print("atNPC:", atTransmogrifier, "slot:", slot, "cat:", category)

	local classFilter = (category and typeToClassSubclass[category]) and typeToClassSubclass[category][1]
	local subClassFilter = (category and typeToClassSubclass[category]) and typeToClassSubclass[category][2]

	print("LIST:", slot, category, classFilter, subClassFilter)

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
	
	local unlockedCount = 0 -- TODO: Attempt at Unlocked StatusBar
	local itemCount = 0 -- tmp for testing/debugging

	local slotTypes = slotItemTypes[slot]
	local slotCats = slotHasCategory[slot]

	local memCount = collectgarbage("count")
	if slot and core.IsEnchantSlot(slot) then
		table.insert(self.displayList, 0) -- Hidden/No enchant
		for enchantVisualID, enchantInfo in pairs(core.enchants) do
			if searchTerm then
				for _, enchantID in pairs(enchantInfo.enchantIDs) do					
                    local name = core.GetEnchantInfo(enchantID)
					if enchantID == searchTerm or (name and strfind(name, searchTerm)) then
						table.insert(self.displayList, enchantVisualID)
						break
					end
				end
			else
				table.insert(self.displayList, enchantVisualID)
			end
		end
	
	elseif slot and slotTypes and slotCats then
		local withNames = searchTerm and not searchByID
		for itemID, itemName in core.ItemIterator(slot, category, withNames) do
			itemCount = itemCount + 1
			local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
			local itemCategory = core.classSubclassToType[class][subClass]
			
			if slotTypes[inventoryType] and slotCats[itemCategory]
					-- and (not classFilter or (class == classFilter and subClass == subClassFilter))
					and (not category or category == itemCategory)
					-- and (not atTransmogrifier or core.IsAvailableSourceItem(itemID, slot)) then
					and ((atTransmogrifier and core.IsAvailableSourceItem(itemID, slot)) or
							(not atTransmogrifier and (not self.filter.unlocked or unlocked == self.filter.unlocked))) then
					
				-- local itemName = (searchTerm and not searchByID and (GetItemInfo(itemID) or core.names[itemID])) or nil
				if not searchTerm or itemID == searchTerm or (itemName and strfind(itemName, searchTerm)) then --strfind(strlower(itemName), strlower(searchTerm))) then --[[strfind(itemName, searchTerm)) then]] --strfind(name, searchTerm)) then
					
					self.itemUnlocked[itemID] = unlocked
					self.visualUnlocked[itemID] = unlocked

					if displayGroup == 0 or not self.displayGroups[displayGroup] then
						table.insert(self.displayList, itemID)
						
						if displayGroup == 0 and unlocked == 1 then
							unlockedCount = unlockedCount + 1 -- here counting just the visuals without display group
						end
						
						if displayGroup ~= 0 then
							self.displayGroups[displayGroup] = {} -- TODO: How to avoid this garbage generation
						end
					end

					if self.displayGroups[displayGroup] then
						table.insert(self.displayGroups[displayGroup], itemID)
					end
				end
			end
		end

		print("TYPE COUNT", DEBUG_TYPE_COUNT)

		print("itemCount:", itemCount, "total item count, hardcoded atm:", 22420)

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
				unlockedCount = unlockedCount + 1 -- and here count the unlocked visuals with display group
			end
		end
		
		-- table.insert(self.displayList, 1) -- hidden item at start of list
		-- self.visualUnlocked[1] = 1

		local t2 = GetTime()

		table.sort(self.displayList, function(a, b) -- TODO: sorting like this only compares the items we picked to represent a visual group
			-- Would need O(n log n) ? GetItemData calls per attribute. Better to cache relevant item data, even if it generates some garbage?
			local unlockedA = self.visualUnlocked[a] --core.GetItemData(a) --
			local unlockedB = self.visualUnlocked[b] --core.GetItemData(b) --

			-- if a == 1 or b == 1 then
			-- 	return a == 1
			-- else
			if unlockedA == unlockedB then
				return a > b
			else
				return unlockedA > unlockedB
			end
		end)

		local t3 = GetTime()

		print("garbage:", collectgarbage("count") - memCount)
		collectgarbage("collect")
		local t4 = GetTime()
		print("Time for BuildList:", t2 - t1, "Time for Sort:", t3 - t2, "Time for collect:", t4 - t3)
	end

	itemCollectionFrame.unlockedStatusBar:SetMinMaxValues(0, table.getn(self.displayList))
	itemCollectionFrame.unlockedStatusBar:SetValue(unlockedCount)

	self:SetPage(1)
end


------------ TEMP UnlockedStatusBar ---------------

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
itemCollectionFrame.unlockedStatusBar.SetMinMaxValues = function(self, min, max) -- why the fuck does this not trigger OnValue changed
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

local model = core.CreateWardrobeModelFrame(core.itemCollectionFrame)
model:SetPoint("TOPLEFT", model:GetParent(), "TOPRIGHT")