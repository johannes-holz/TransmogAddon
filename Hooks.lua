local folder, core = ...

-- Minimal scanning Tooltip (https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip)
core.ScanningTooltip = CreateFrame("GameTooltip", folder .. "ScanningTooltip", nil, "GameTooltipTemplate")
local ScanningTooltip = core.ScanningTooltip
ScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
ScanningTooltip:AddFontStrings(
	ScanningTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
	ScanningTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
)

-- Getting VisualID works differently for units, that are not the player
local lastUnit, lastSlot
local SetLastUnit = function(self, unit, slot, nameOnly)
	lastUnit, lastSlot = unit, slot -- This gets called too late, after we do our OnItem stuff. Getting Unit/Slot from OwnerFrame (CharacterFrame or InspectFrame) atm, unsure if that's the way to go
end
hooksecurefunc(GameTooltip, "SetInventoryItem", SetLastUnit)
local OnTooltipCleared = function(self)
	lastUnit, lastSlot = nil, nil
end
GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)

local OwnerFrame_GetUnitSlot = function(f)
	if not f or not f:GetName() then return end
	local s = strmatch(f:GetName(), "Inspect(%a-Slot)")
	if s then
		return InspectFrame.unit, s
	end
	s = strmatch(f:GetName(), "Character(%a-Slot)")
	if s then
		return "player", s
	end
end


-- No easy way to know how many tooltip lines are from Blizzard?
-- Depending on whether SetInventoryItem, SetHyperlink, etc. is called, there might be extra lines like
	-- <Shift Right Click to Gem>, Equipment Sets: X, Soulbound, ...

-- Idea 1:
-- Identify which lines might be extra compared to hyperlinks
-- Walk forward from last scanning tooltip line until we encounter a line that is not one of those lines

local valid = {
	["Ausrüstungs-S"] = true, -- Can an item be part of a set and not be collected?
	-- ["Verkaufspreis:"] = true, -- this is text is in moneyFrame, not a tooltip line
	["<Zum Sockeln S"] = true,
	["Equipment Sets"] = true,
	["<Shift Right C"] = true,
}

local BlizzNumLines = function(tooltip, link)
	ScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	ScanningTooltip:ClearLines()
	ScanningTooltip:SetHyperlink(link)

	local numLines = tooltip:NumLines()

	-- Find last non empty line in scanning tooltip
	local lastText
	for i = ScanningTooltip:NumLines(), 1, -1 do
		local line = _G[ScanningTooltip:GetName() .. "TextLeft" .. i]
		if not line then return numLines end
		lastText = line:GetText()
		if not (lastText == " " or lastText == "") then
			break
		end
	end

	-- Find first money line in tooltip
	local moneyLine
	local moneyFrame = _G[tooltip:GetName() .. "MoneyFrame" .. 1]
	if moneyFrame and moneyFrame:IsShown() then
		local point, relativeTo, relativePoint, xOfs, yOfs = moneyFrame:GetPoint(1)
		if relativeTo then
			moneyLine = relativeTo
		end
	end

	-- Iterate over tooltip up to lastText and possibly valid extra lines
	local closeToEnd
	for i = 1, tooltip:NumLines() do
		local line = _G[tooltip:GetName() .. "TextLeft" .. i]
		if not line then return numLines end
		local text = line:GetText()
		-- print(lastText, text, closeToEnd, valid[string.sub(text, 1, 14)], line == moneyLine, moneyFrame and moneyFrame:IsShown())
		if text == lastText then
			closeToEnd = true
		elseif closeToEnd and not (valid[string.sub(text, 1, 14)] or line == moneyLine) then
			numLines = i - 1
			break
		end
	end

	return numLines
end



-- Idea 2:
-- Hook AddLine, AddDoubleLine and ClearLines (and GameTooltip_OnTooltipAddMoney? This could technically also be called from addons?)
-- This somehow gets called for these special blizzard lines too, so no point?
-- local lineCount = {}

-- local OnAddLine = function(tooltip, ...)
-- 	print(tooltip:NumLines(), ...)
-- 	if lineCount[tooltip] then return end
-- 	lineCount[tooltip] = tooltip:NumLines() - 1
-- 	-- print(lineCount[tooltip])
-- end

-- local OnClearLines = function(tooltip)
-- 	lineCount[tooltip] = nil
-- 	-- print("cleared")
-- end

-- local AddLineTracking = function(tooltip)
-- 	hooksecurefunc(tooltip, "AddLine", OnAddLine)
-- 	hooksecurefunc(tooltip, "AddDoubleLine", OnAddLine)
-- 	hooksecurefunc(tooltip, "ClearLines", OnClearLines)
-- 	tooltip:HookScript("OnHide", OnClearLines)
-- end

-- AddLineTracking(GameTooltip)

-- Idea3:
-- Hook all the SetXItem functions of tooltip to know which function to call on scanning tooltip?


local Tooltip_AddCollectedLine = function(tooltip, itemID, link)
	if not core.db.profile.General.tooltipCollectedStatus then return end

	local itemUnlocked = core.GetItemData(itemID)

	-- Hack to insert our line directly under blizzards lines
	local blizzNumLines = BlizzNumLines(tooltip, link)
	
	if not tooltip.collectedText then	
		tooltip.collectedText = tooltip:CreateFontString()
		tooltip.collectedText:SetFontObject("GameTooltipText")
		tooltip.collectedText:SetJustifyH("LEFT")
		
		tooltip:HookScript("OnHide", function(self)
			self.collectedText:SetText("")
			local line = self.collectedAnchor
			if line and line.oldHeight then
				line:SetHeight(line:GetStringHeight())
				line:SetJustifyV("MIDDLE")
				line.oldHeight = nil
			end
			local moneyFrame = _G[tooltip:GetName() .. "MoneyFrame" .. 1]
			if moneyFrame then			
				moneyFrame:ClearAllPoints()
			end
		end)
	end	

	local text
	if itemUnlocked and itemUnlocked ~= 1 then
		if core.requestUnlocksAllFailed then
			text = RED_FONT_COLOR_CODE .. core.APPEARANCE_NOT_COLLECTED_TEXT_NO .. FONT_COLOR_CODE_CLOSE
		else
			text = (core.IsVisualUnlocked(itemID) == 1) and core.APPEARANCE_NOT_COLLECTED_TEXT_B or core.APPEARANCE_NOT_COLLECTED_TEXT_A
			text = "|c" .. core.appearanceNotCollectedTooltipColor.hex .. text .. FONT_COLOR_CODE_CLOSE
		end
	end

	if text then
		tooltip.collectedText:SetText(text)

		tooltip.collectedAnchor = _G[tooltip:GetName() .. "TextLeft" .. blizzNumLines]
		tooltip.collectedAnchor.oldHeight = tooltip.collectedAnchor:GetHeight()
		tooltip.collectedAnchor:SetJustifyV("TOP")	
		tooltip.collectedAnchor:SetWidth(math.max(tooltip.collectedText:GetStringWidth(), tooltip:GetWidth()))
		tooltip.collectedAnchor:SetHeight(tooltip.collectedAnchor:GetStringHeight() + tooltip.collectedText:GetHeight())

		local moneyFrame = _G[tooltip:GetName() .. "MoneyFrame" .. 1]
		if moneyFrame then				
			local point, relativeTo, relativePoint, offsetX, offsetY = moneyFrame:GetPoint(1)
			if relativeTo then
				moneyFrame:ClearAllPoints()
				moneyFrame:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", offsetX, offsetY)
			end
		end

		tooltip.collectedText:ClearAllPoints()
		tooltip.collectedText:SetPoint("BOTTOMLEFT", tooltip.collectedAnchor, "BOTTOMLEFT")
		
		tooltip:Show()
	end

	-- If we do not care about the line's positioning, just remove all that scuffness above and call AddLine:
	-- if itemUnlocked and itemUnlocked ~= 1 then 	-- or just check for == 0? (nil: not a dressable item (or missing in our data), 0: not unlocked, 1: unlocked)
	-- 	if core.requestUnlocksAllFailed then
	-- 		tooltip:AddLine(core.APPEARANCE_NOT_COLLECTED_TEXT_NO, 1.0, 0.1, 0.1, 1.0)
	-- 	else
	-- 		local text = (core.IsVisualUnlocked(itemID) == 1) and core.APPEARANCE_NOT_COLLECTED_TEXT_B or core.APPEARANCE_NOT_COLLECTED_TEXT_A
	-- 		local color = core.appearanceNotCollectedTooltipColor
	-- 		tooltip:AddLine(text, color.r, color.g, color.b, color.a, 1)
	-- 	end
	-- end
end

 -- For the player we can get visualID and illusionID from the item link and skin information through the API via GetSkins()
 -- For other players we only get visualID through GetInventoryItemID. Here we can not differentiate between skin and item visual and can not get illusions
 -- TODO: Maybe seperate by task into multiple functions, not sure
local ignoreRecipeCall = {}
local function OnTooltipSetItem(tooltip)
	tooltip:Show()

	local name, link = tooltip:GetItem()
	if not link then return end

	local lastUnit, lastSlot = OwnerFrame_GetUnitSlot(tooltip:GetOwner())
	local correspondingEnchantSlot = lastSlot and core.GetCorrespondingSlot(lastSlot)

	local itemID = core.GetItemIDFromLink(link)

	-- Recipe Hack
	-- OnTooltipSetItem somehow gets called twice for recipes, first for the produced item and then for the recipe itself
	-- GetItem() returns the recipe both times, so in the first call we map to the produced item to insert our lines and remember to ignore the next call for this tooltip
	if core.GetRecipeInfo(itemID) and not ignoreRecipeCall[tooltip] then
		itemID = core.GetRecipeInfo(itemID)
		ignoreRecipeCall[tooltip] = 1
	else
		ignoreRecipeCall[tooltip] = nil
		-- return
	end

	local visualID, illusionID = core.GetVisualFromItemLink(link)				-- Read out visualID and illusionID from itemLink's uniqueID field
	if lastUnit and UnitGUID(lastUnit) ~= UnitGUID("player") then				-- A bug causes the uniqueID to be always 0 while inspecting other players
		visualID, illusionID = core.GetInventoryVisualID(lastUnit, lastSlot)	-- We can still get visualID with a trick, illusionID can not be retrieved for other players sadly
	end
	local skinVisualID = lastUnit and UnitGUID(lastUnit) == UnitGUID("player") and core.GetInventorySkinID(lastSlot)	-- For player inventory also show skin visual and illusion
	local skinIllusionID = correspondingEnchantSlot and lastUnit and UnitGUID(lastUnit) == UnitGUID("player") and core.GetInventorySkinID(correspondingEnchantSlot)

	Tooltip_AddCollectedLine(tooltip, itemID, link) -- TODO: Do we also want a collected status display for the visual?

	local textLeft1, textLeft2
	if strfind(tooltip:GetName(), "Shopping") then -- Compare Item tooltips have an extra "Currently equipped" line
		textLeft1 = _G[tooltip:GetName() .. "TextLeft2"]
		textLeft2 = _G[tooltip:GetName() .. "TextLeft3"]
	else
		textLeft1 = _G[tooltip:GetName() .. "TextLeft1"] -- or regions[10]
		textLeft2 = _G[tooltip:GetName() .. "TextLeft2"] -- or regions[12]
	end

	local text = ""
	if visualID and visualID ~= core.UNMOG_ID then
		text = "\124c" .. core.mogTooltipTextColor.hex .. core.ITEM_TOOLTIP_TRANSMOGRIFIED_TO .. "\n"		
		local mogName = visualID == core.HIDDEN_ID and core.HIDDEN or core.GetItemName(visualID) -- Do we want guaranteed up to date server info (GetItemInfo) or avoid flickering tooltip for uncached items (core.GetItemName)?
		text = text .. (mogName or (core.ITEM_TOOLTIP_FETCHING_NAME .. visualID)) .. "\124r"
		if not mogName then
			core.FunctionOnItemInfo(visualID, OnTooltipSetItem, tooltip) -- player transmog items seem to be cached anyway, but probably needed for Hyperlinks from chat
		end
		if illusionID and illusionID ~= core.UNMOG_ID or skinVisualID or skinIllusionID then text = text .. "\n" end
	end	
	if illusionID and illusionID ~= core.UNMOG_ID then
		local illusionName = illusionID == core.HIDDEN_ID and core.HIDDEN or GetSpellInfo(illusionID)
		text = text .. "\124c" .. core.mogTooltipTextColor.hex .. "Illusion: " .. (illusionName or illusionID) .. "\124r"
		if skinVisualID or skinIllusionID then text = text .. "\n" end
	end
	if skinVisualID then
		local skinName = skinVisualID == core.HIDDEN_ID and core.HIDDEN or core.GetItemName(skinVisualID) -- GetItemInfo(skinVisualID)? Skin should always be cached
		text = text .. "\124c" .. core.skinTextColor.hex .. core.ITEM_TOOLTIP_ACTIVE_SKIN .. "\n" .. (skinName or skinVisualID) .. "\124r"		
		if skinIllusionID then text = text .. "\n" end
	end
	if skinIllusionID and skinIllusionID ~= core.UNMOG_ID then
		local skinIllusionName = skinIllusionID == core.HIDDEN_ID and core.HIDDEN or GetSpellInfo(skinIllusionID)
		text = text .. "\124c" .. core.skinTextColor.hex .. "Illusion: " .. (skinIllusionName or skinIllusionID) .. "\124r"
	end
		
	if not tooltip.mogText then	
		tooltip.mogText = tooltip:CreateFontString()
		tooltip.mogText:SetFontObject(textLeft2:GetFontObject())
		tooltip.mogText:SetJustifyH("LEFT")
		tooltip.mogText:SetPoint("BOTTOMLEFT", textLeft2, "TOPLEFT", 0, 1)

		tooltip.HideTransmogLine = function(self)
			if textLeft1.justifyHOld then
				textLeft1:SetHeight(textLeft1:GetStringHeight())
				textLeft1:SetJustifyH(textLeft1.justifyHOld)
				textLeft1:SetJustifyV(textLeft1.justifyVOld)
				textLeft1.justifyHOld, textLeft1.justifyVOld = nil, nil
				self.mogText:SetText("")
			end			
		end

		tooltip:HookScript("OnHide", tooltip.HideTransmogLine)
	end

	textLeft1.justifyHOld = textLeft1:GetJustifyH()
	textLeft1.justifyVOld = textLeft1:GetJustifyV()
	tooltip.mogText:SetText(text)	
	textLeft1:SetJustifyV("TOP")	
	textLeft1:SetJustifyH("LEFT")	

	-- Either tell mogText to do a line break if any transmog line does not fit into the tooltip:
	-- tooltip.mogText:SetWidth(math.max(tooltip:GetWidth() - 15, 200))

	-- or if we want the tooltip to increase in width instead:
	textLeft1:SetWidth(math.max(tooltip.mogText:GetStringWidth(), tooltip:GetWidth()))
	textLeft1:SetHeight(textLeft1:GetStringHeight() + tooltip.mogText:GetHeight())
	tooltip:Show() -- triggers resize

	if core.db.profile.General.extraItemTooltip and tooltip == GameTooltip and visualID and visualID ~= core.HIDDEN_ID and visualID ~= core.UNMOG_ID then
		core.SetExtraItemTooltip(visualID, "ANCHOR_TOP")
	end
end

local function OnTooltipCleared(tooltip)
	if tooltip.HideTransmogLine then
		tooltip:HideTransmogLine()
	end
end

core.HookItemTooltip = function(tooltip)
	tooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	tooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
end


local tooltips = { GameTooltip, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3 }

for _, tooltip in pairs(tooltips) do
	core.HookItemTooltip(tooltip)
end

-- Add collected line to recipe spell tooltips
local OnTooltipSetSpell = function(tooltip)
	local name, rank, spellID = tooltip:GetSpell()
	
	if spellID and core.GetSpellRecipeInfo(spellID) then
		local itemID = core.GetSpellRecipeInfo(spellID)		
		Tooltip_AddCollectedLine(tooltip, itemID)
	end
end

for _, tooltip in pairs({GameTooltip, ItemRefTooltip}) do
	tooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
end

 -- Original code of HandleModifiedItemClick in ItemButtonTemplate.lua:
--  function HandleModifiedItemClick(link)
-- 	if ( IsModifiedClick("CHATLINK") ) then
-- 		if ( ChatEdit_InsertLink(link) ) then
-- 			return true;
-- 		end
-- 	end
-- 	if ( IsModifiedClick("DRESSUP") ) then
-- 		DressUpItemLink(link);
-- 		return true;
-- 	end
-- 	return false;
-- end

-- Allow preview/linking of items visual
-- Since a lot of AddOns are prehooking this function, we might have to ensure, that we are last to hook
core.PreHook_ModifiedItemClick = function()
	local HandleModifiedItemClickOrig = HandleModifiedItemClick
	HandleModifiedItemClick = function(link, ...)
		if not link or not strfind(link, "item:(%d*)") then
			return HandleModifiedItemClickOrig(link, ...)
		end
		if (link and string.find(link, "|Htransmogset|h")) then
			return HandleModifiedItemClickOrig(link, ...)
		end

		-- core.QueryItem(core.GetItemIDFromLink(link))

		-- TODO: Give option to swap behaviour (modifiers for normal vs visual)?
		-- TODO: InsertLink/DressUp directly, so that we can set hidden slots, uncached items and equip weapons by slot during inspect?

		-- If both modifiers are clicked, chat insert or dressup the transmog item
		if IsModifiedClick("DRESSUP") and IsModifiedClick("CHATLINK") then
			local lastUnit, lastSlot = OwnerFrame_GetUnitSlot(GetMouseFocus())
			local visualID = lastUnit and core.GetInventoryVisualID(lastUnit, lastSlot) or core.GetVisualFromItemLink(link) -- Do we want to show transmog or skin for player?
			if visualID == core.HIDDEN_ID then
				link = core.HIDDEN
			elseif visualID ~= core.UNMOG_ID then
				_, link = GetItemInfo(visualID)
			end
		end

		return HandleModifiedItemClickOrig(link, ...)
	end
end
 
-- Make client show correct inventory item textures instead of their tmog's texture. Gets more scuffed when skins are in use, see below
local GetInventoryItemTextureOld = GetInventoryItemTexture
GetInventoryItemTexture = function(unit, slotID)
	local link = GetInventoryItemLink(unit, slotID)
	if (core.db and not core.db.profile.General.fixItemIcons) or not link or not GetItemInfo(link) then
		return GetInventoryItemTextureOld(unit, slotID)
	else
		return select(10, GetItemInfo(link))
	end
end

-- PaperDollFrame Skin Fix
-- UNIT_INVENTORY_CHANGED does not fire when using a skin, so we call update to PaperDollItemSlot on PLAYER_EQUIPMENT_CHANGED
local f = CreateFrame("Frame", nil, PaperDollFrame) -- only needed while PaperDollFrame is shown
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:SetScript("OnEvent", function(self, event, ...)
	local slot, isEquipped = ...
	if not isEquipped or not core.idToSlot[slot] then return end
	PaperDollItemSlotButton_Update(_G["Character" .. core.idToSlot[slot]])
end)

-- InspectFrame Skin Fix
-- GetInventoryItemLink's return value currently does not change for other players with activated skin until a new NotifyInspect call is made
-- GearScore spams NI when hovering InspectFrame slots, so this might go unnoticed until one uses the texture fix
-- We 'fix' this by periodically calling NI and slot updates
-- To avoid slots starting to flicker (and to fix talent inspect), we block NI calls from other AddOns while InspectFrame is open
local f = CreateFrame("Frame") -- can't parent to InspectFrame directly, as it isn't loaded yet
f:RegisterEvent("ADDON_LOADED")
-- All of these do not fire anymore, when the inventory change is hidden by a skin
-- f:RegisterEvent("INSPECT_READY")
-- f:RegisterEvent("UNIT_STATS")
-- f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
-- f:RegisterEvent("UNIT_MODEL_CHANGED")

-- Block NotifyInspect from other AddOns (GearScore) while InspectFrame is open
-- A different approach could be to block if UnitGUID(unit) ~= UnitGUID(InspectFrame.unit) (and InspectFrame is open)
local NotifyInspectOrig = NotifyInspect
NotifyInspect = function(unit)
    local str = debugstack(2, 1, 0)
    local file = string.match(str, "([^:%s%c]*):[%d]+: in function")
    local addon = file and string.match(file, "I?n?t?e?r?f?a?c?e[\\/]?A?d?d?O?n?s?[\\/](.-)[\\/]") or "unknown"

	if InspectFrame and InspectFrame:IsShown() and not strfind(addon, "Blizzard_InspectUI") then
		core.Debug("Blocked NotifyInspect from", addon)
		return
	end

	NotifyInspectOrig(unit)
end

f:SetScript("OnEvent", function(self, event, ...)
	local name = ...
	if event == "ADDON_LOADED" and name == "Blizzard_InspectUI" then
		f:UnregisterEvent("ADDON_LOADED")
		f:SetParent(InspectPaperDollFrame)
		for id, slot in pairs(core.idToSlot) do
			if id > 0 then
				f.buttons[id] = _G["Inspect" .. slot]
			end
		end
		f:SetScript("OnUpdate", f.onUpdate)		

		hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(self)
			if self == GetMouseFocus() then
				InspectPaperDollItemSlotButton_OnEnter(self)
			end
		end)
	end
end)

f.UPDATE_INTERVAL = 0.2
f.lastScan = {}
f.buttons = {}
f.onUpdate = function(self, e)
	self.e = (self.e or 0) + e
	if self.e > self.UPDATE_INTERVAL then
		self.e = self.e - self.UPDATE_INTERVAL
		self.toggle = (self.toggle or 0) + 1
		-- Regularly call NotifyInspect while InspectFrame is open
		if self.toggle % 5 == 0 and InspectFrame.unit and InspectFrame.unit ~= "player" then
			NotifyInspectOrig(InspectFrame.unit)
		end
		-- Update Buttons with high refresh rate (as INSPECT_READY does not fire)
		for id, slot in pairs(core.idToSlot) do
			if id > 0 then
				local item = GetInventoryItemLink(InspectFrame.unit, id)
				if item ~= self.lastScan[id] then
					InspectPaperDollItemSlotButton_Update(self.buttons[id])
				end
				self.lastScan[id] = item
			end
		end		
	end
end

-- Setboni display fix for player. Scans hidden tooltip and copies setboni lines over to GameTooltip, when GameTooltip is set to an inventory item
local SetInventoryItem_SetFix = function(self, unit, slot, nameOnly)
	if nameOnly or not unit or UnitGUID(unit) ~= UnitGUID("player") or slot > 19 then return end
	local name, link = self:GetItem()
	if not link then return end

	local offset = slot == 16 and GetInventoryItemLink("player", 17) and 2 or 1 -- if we have an OH equipped and current slot is MH, SetHyperLinkCompare shows MH in second ShoppingTooltip
	ScanningTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	ScanningTooltip:ClearLines()
	ScanningTooltip:SetHyperlinkCompareItem(link, offset) -- or just use SetHyperlink and search for correct start line in GameTooltip to avoid the scuffness of CompareItem?
	local scanningTooltipTextLeft = ScanningTooltip:GetName() .. "TextLeft"

	local start, last
	for i = 1, ScanningTooltip:NumLines() do
		local text = _G[scanningTooltipTextLeft .. i]:GetText()
		local r, g, b = _G[scanningTooltipTextLeft .. i]:GetTextColor()

		start = start or (strfind(text, "%(%d/%d%)") and i) -- set specific lines should start with a line that says x out of y pieces

		if start then
			if strfind(text, "Set: ") then	-- the final lines list the setboni
				last = i
			elseif last then -- if we have reached setboni and then encounter a different line, we can stop
				break
			end
			_G["GameTooltipTextLeft" .. (i - 1)]:SetText(text) -- need to offset by one, if we use compare scanning tooltip
			_G["GameTooltipTextLeft" .. (i - 1)]:SetTextColor(r, g, b)
		end
	end	
end
hooksecurefunc(GameTooltip, "SetInventoryItem", SetInventoryItem_SetFix)