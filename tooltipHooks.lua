local folder, core = ...

-- TODOs:
-- (low prio) fix set boni display for other players
	-- Need to think about how to encode and use setdata. we would probably need 2 more item info: id of the set and id of the item under which name the item gets shown in the set boni
	-- maybe we can just use an extra table for this if set data is small enough
	-- Then scan all inventory slots and count items that belong to the set. if they belong to our set, look up their display items name and add them to table {name = true}
	-- then fix relevant tooltip lines

local GetInventoryVisualID = core.GetInventoryVisualID

-- Minimal scanning Tooltip to get correct player Setboni (https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip)
core.ScanningTooltip = CreateFrame("GameTooltip", folder .. "ScanningTooltip")
ScanningTooltip = core.ScanningTooltip
ScanningTooltip:SetOwner( WorldFrame, "ANCHOR_NONE" )
ScanningTooltip:AddFontStrings(ScanningTooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ), ScanningTooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ))

-- Getting VisualID works differently for units, that are not the player
local lastUnit, lastSlot
local SetLastUnit = function(self, unit, slot, nameOnly)
	lastUnit, lastSlot = unit, slot -- This gets called too late, after we do our OnItem stuff. Getting Unit/Slot atm from OwnerFrame, unsure if that's the way to go
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

 -- for non player units we get visualID through GetInventoryItemID, for the player can get the itemtransmog from the itemlink and skin information through the API GetSkins()
 -- TODO: Fix TransmogLine + Hiding Scuffness, maybe seperate by task into multiple functions, not sure
local last = 0
local function TooltipAddMogLine(tooltip)
	tooltip:Show()

	local name, link = tooltip:GetItem()
	if not link then return end

	local lastUnit, lastSlot = OwnerFrame_GetUnitSlot(tooltip:GetOwner())

	local itemID = core.GetItemIDFromLink(link)

	-- Recipe Hack: OnTooltipSetItem gets called 2 times for recipes, the first time for the crafting item (but link is still the recipe)
	if core.GetRecipeInfo(itemID) and GetTime() - last > 0.005 then
		itemID = core.GetRecipeInfo(itemID)
		last = GetTime()
	end

	local visualID = lastUnit and GetInventoryVisualID(lastUnit, lastSlot) or core.API.GetVisualFromItemLink(link)
	local skinVisualID = lastUnit and UnitGUID(lastUnit) == UnitGUID("player") and core.GetInventorySkinID(lastSlot)

	local itemUnlocked = core.GetItemData(itemID)
	local visualUnlocked = core.GetItemData(visualID)
	local skinVisualUnlocked = core.GetItemData(skinVisualID)	

	if itemUnlocked and itemUnlocked ~= 1 then -- GetItemData returned "not unlocked", but not nil, so it is dressable item. can't use IsDressableItem(itemID), because it also returns true for trinkets, recipes, ...
		local text = (core.IsVisualUnlocked(itemID) == 1) and core.APPEARANCE_NOT_COLLECTED_TEXT_B or core.APPEARANCE_NOT_COLLECTED_TEXT_A
		local color = core.appearanceNotCollectedTooltipColor
		tooltip:AddLine(text, color.r, color.g, color.b, color.a, 1)
	end

	local textLeft1, textLeft2
	if strfind(tooltip:GetName(), "Shopping") then -- Compare Item tooltips, that contain extra "Currently equipped" line
		textLeft1 = _G[tooltip:GetName() .. "TextLeft2"]
		textLeft2 = _G[tooltip:GetName() .. "TextLeft3"]
	else
		textLeft1 = _G[tooltip:GetName() .. "TextLeft1"] -- or regions[10] -- GameTooltipTextLeft1 --regions[10]
		textLeft2 = _G[tooltip:GetName() .. "TextLeft2"] -- or regions[12] -- GameTooltipTextLeft2 --regions[12]
	end

	local text = ""
	if visualID and visualID > 0 then
		text = "\124c" .. core.mogTooltipTextColor.hex .. core.ITEM_TOOLTIP_TRANSMOGRIFIED_TO .. "\n"
		if visualID == 1 then	
			text = text .. core.HIDDEN .. "\124r"
		else
			local mogName = GetItemInfo(visualID)
			if mogName then			
				text = text .. mogName .. "\124r" -- .. (visualUnlocked == 1 and core.GetTextureString("Interface/Buttons/UI-CheckBox-Check", 12) or "") 
			else
				text = text .. core.ITEM_TOOLTIP_FETCHING_NAME .. visualID .. "\124r" --.. (visualUnlocked == 1 and core.GetTextureString("Interface/Buttons/UI-CheckBox-Check", 12) or "") 
				core.FunctionOnItemInfo(visualID, TooltipAddMogLine, tooltip, link) -- player transmog items seem to be cached anyway, but probably needed for Hyperlinks from chat
			end
		end
		if skinVisualID then text = text .. "\n" end
	end	
	if skinVisualID then
		local skinName = skinVisualID == 1 and core.HIDDEN or GetItemInfo(skinVisualID)
		text = text .. "\124c" .. core.skinTextColor.hex .. core.ITEM_TOOLTIP_ACTIVE_SKIN .. "\n" .. (skinName or skinVisualID) .. "\124r"
	end
		
	if not tooltip.mogText then	
		tooltip.mogText = tooltip:CreateFontString()
		tooltip.mogText:SetFontObject(textLeft2:GetFontObject())
		tooltip.mogText:SetJustifyH("LEFT")
		--tooltip.mogText:SetTextColor(core.mogTooltipTextColor.r, core.mogTooltipTextColor.g, core.mogTooltipTextColor.b, core.mogTooltipTextColor.a)
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
	-- Not quite sure, but I feel like this approach is preferable to moving all tooltip lines around
	tooltip.mogText:SetText(text)	
	textLeft1:SetJustifyV("TOP")	
	textLeft1:SetJustifyH("LEFT")	

	-- tell mogText to do a line break if any line does not fit into the tooltip:
	-- tooltip.mogText:SetWidth(math.max(tooltip:GetWidth() - 15, 200))

	-- if we don't want a line break in mog names and instead want the tooltip to horizontally increase in size:
	textLeft1:SetWidth(math.max(tooltip.mogText:GetStringWidth(), tooltip:GetWidth()))
	textLeft1:SetHeight(textLeft1:GetStringHeight() + tooltip.mogText:GetHeight())
	tooltip:Show() -- triggers resize

	if tooltip == GameTooltip and visualID and visualID > 1 then
		core.SetExtraItemTooltip(visualID, "ANCHOR_TOP") -- TODO: Options
	end
end

local function TooltipHideMogLine(tooltip)
	if tooltip.HideTransmogLine then
		tooltip:HideTransmogLine()
	end
end 
		
core.TooltipDisplayTransmog = TooltipAddMogLine -- used by extra tooltip. why tho. and combine it with OnTTCleared Hook if we use it on other tooltips?


local tooltips = { GameTooltip, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3 }

for _, tooltip in pairs(tooltips) do
	tooltip:HookScript("OnTooltipSetItem", TooltipAddMogLine)
end

for _, tooltip in pairs(tooltips) do
	tooltip:HookScript("OnTooltipCleared", TooltipHideMogLine)
end

-- Adds "item/visual not collected" line to recipe spells
-- TODO: received recipe data is missing recipes, that are only taught by the trainer or a spell (instead of being taught by an item)
local OnTooltipSetSpell = function(tooltip)
	local name, rank, spellID = tooltip:GetSpell()
	
	if spellID and core.GetSpellRecipeInfo(spellID) then
		local itemID = core.GetSpellRecipeInfo(spellID)
		local itemUnlocked = core.GetItemData(itemID)

		if itemUnlocked and itemUnlocked ~= 1 then -- GetItemData returned "not unlocked", but not nil, so it is dressable item. can't use IsDressableItem(itemID), because it also returns true for trinkets, recipes, ...
			local text = (core.IsVisualUnlocked(itemID) == 1) and core.APPEARANCE_NOT_COLLECTED_TEXT_B or core.APPEARANCE_NOT_COLLECTED_TEXT_A
			local color = core.appearanceNotCollectedTooltipColor
			tooltip:AddLine(text, color.r, color.g, color.b, color.a, 1)
		end
	end
end

GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
ItemRefTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)

-- or use lastUnit, lastSlot again
GetInspectFrameVisualID = function(frame)
	if not frame then return end

	--if UnitGUID("target") == UnitGUID("player") then return end

	local _, _, slot = string.find(frame:GetName(), "Inspect(%a+Slot)")
	if not slot then return end

	--local slotID = slotToID[slot] -- there is also Inspect*Slot:GetID()
	--if not slotID then return end

	return GetInventoryVisualID("target", frame:GetID())
end


 -- Original code of HandleModifiedItemClick:
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

-- What to preview / insert into chat
-- Since a lot of AddOns are prehooking this function, we might have to ensure, that we are last to hook
-- If any AddOn has problem with this, we can add support or give the option to disable this
core.PreHook_ModifiedItemClick = function()
	local HandleModifiedItemClickOrig = HandleModifiedItemClick
	HandleModifiedItemClick = function(link, ...)
		if (link and string.find(link, "|Htransmogset|h")) then
			return HandleModifiedItemClickOrig(link, ...)
		end
		if not link or not strfind(link, "item:(%d*)") then
			return HandleModifiedItemClickOrig(link, ...)
		end


		-- if IsAltKeyDown() and fakeOptionsOpenWadrobeWithAlt then
			--core.wardrobeFrame:OpenItem(link)
			--ShowUIPanel(core.wardrobeFrame)
		-- end

		if IsModifiedClick("DRESSUP") and IsModifiedClick("CHATLINK") then
			local lastUnit, lastSlot = OwnerFrame_GetUnitSlot(GetMouseFocus())
			local visualID = lastUnit and GetInventoryVisualID(lastUnit, lastSlot) or core.API.GetVisualFromItemLink(link) -- Do we want to show transmog or skin for player?
			if visualID > 1 then
				_, link = GetItemInfo(visualID)
			elseif visualID == 1 then
				link = core.HIDDEN
			end
		end
		HandleModifiedItemClickOrig(link, ...)

		-- if IsModifiedClick("DRESSUP") then	
		-- 	if IsShiftKeyDown() then -- options for disable or reversed behaviour (show tmog as default and show base item with shift). use modifiers directly or use IsModifiedClick("DRESSUP")?
		-- 		local visualID = lastUnit and GetInventoryVisualID(lastUnit, lastSlot) or core.API.GetVisualFromItemLink(link)
				
		-- 		if visualID == 0 then
		-- 			return HandleModifiedItemClickOrig(link, ...)
		-- 		elseif visualID == 1 then -- To "display" hidden items we need to modify our DressUpFrame to keep track of all shown items, so we can do a full undress + reshow all other items
		-- 			if not DressUpFrame:IsShown() then
		-- 				ShowUIPanel(DressUpFrame);
		-- 				DressUpModel:SetUnit("player");
		-- 			end
		-- 			return true
		-- 		else
		-- 			local _, visualLink = GetItemInfo(visualID)
		-- 			return HandleModifiedItemClickOrig(visualLink or visualID, ...) -- TODO: would need proper queue with OnItemInfo and ID counter, so uncached info gets found while only latest request per slot gets accepted
		-- 		end														-- have table where we save the latest known change for a slot. compare this with the time we keep in oniteminfo. probably overkill for a minor problem tho
		-- 	end
			
		-- 	return HandleModifiedItemClickOrig(link, ...)
		-- else
		-- 	return HandleModifiedItemClickOrig(link, ...)
		-- end
	end
end
 
-- Makes client show correct inventory item textures again instead of their tmog's texture. Gets more complicated when skins are in use, see below
GetInventoryItemTextureOld = GetInventoryItemTexture
GetInventoryItemTexture = function(unit, slotID)
	local link = GetInventoryItemLink(unit, slotID)
	if not link or not GetItemInfo(link) then
		return GetInventoryItemTextureOld(unit, slotID)
	else
		return select(10, GetItemInfo(link))
	end
end

-- [=====[

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
-- GetInventoryItemLink return value never changes for other players with activated skin until a new NotifyInspect call is made
-- TODO: AddOns like GearScore spam NotifyInspect on MouseOver and cause glitchy behaviour. Probably best to disable NotifyInspect while InspectFrame is open.
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
--f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("UNIT_STATS")
f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
f:RegisterEvent("UNIT_MODEL_CHANGED")


local blockingActive = false
core.NotifyInspectOld = _G.NotifyInspect
_G.NotifyInspect = function(unit)
	-- Credit to InspectFix AddOn by oscarucb, https://www.curseforge.com/wow/addons/inspectfix
	-- Should not be used together tho
    local str = debugstack(2)
    local addon = string.match(str,'[%s%c]+([^:%s%c]*)\\[^\\:%s%c]+:')
    addon = string.gsub(addon or "unknown",'I?n?t?e?r?f?a?c?e\\AddOns\\',"")

	if blockingActive and not strfind(addon, "Blizzard_InspectUI") then
		-- print("blocked notify from", addon)
		return
	end

	-- print(addon, "yo u can come in")
	core.NotifyInspectOld(unit)
end

f:SetScript("OnEvent", function(self, event, ...)
	--print(event, ...)
	local name = ...
	if name == "Blizzard_InspectUI" then
		f:UnregisterEvent("ADDON_LOADED")
		f:SetParent(InspectPaperDollFrame)		
		for id, slot in pairs(core.idToSlot) do
			f.buttons[id] = _G["Inspect" .. slot]
		end
		f:SetScript("OnUpdate", f.onUpdate)		

		hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(self)
			if self == GetMouseFocus() then
				InspectPaperDollItemSlotButton_OnEnter(self)
			end
		end)
		
		-- hooksecurefunc(InspectFrame_UnitChanged, function(self)
		-- 	print("Unit changed!")
		-- 	-- core.NotifyInspectOld()
		-- 	_G.NotifyInspect("hihi")
		-- end)

		-- hooksecurefunc(NotifyInspect, function()
		-- 	print("Notify")
		-- end)
		
		-- local dummyFunction = function() end
		
		InspectFrame:HookScript("OnShow", function(self)
			-- _G.NotifyInspect = dummyFunction
			-- print("NO NOtifyrino")
			blockingActive = true
		end)
		InspectFrame:HookScript("OnHide", function(self)
			-- _G.NotifyInspect = core.NotifyInspectOld
			blockingActive = false
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
		if self.toggle % 4 == 0 and InspectFrame.unit and InspectFrame.unit ~= "player" then
			-- print("Notified!", InspectFrame.unit)
			core.NotifyInspectOld(InspectFrame.unit)
		end		
		for id, slot in pairs(core.idToSlot) do
			local item = GetInventoryItemLink(InspectFrame.unit, id)
			if item ~= self.lastScan[id] then
				--print(item, GetTime())
				InspectPaperDollItemSlotButton_Update(self.buttons[id])
				-- if self.buttons[id] == GetMouseFocus() then
				-- 	InspectPaperDollItemSlotButton_OnEnter(self.buttons[id])
				-- end
			end
			self.lastScan[id] = item
		end		
	end
end

-- ]=====]

-- Setboni display fix for player. Scans hidden tooltip and copies setboni lines over to GameTooltip, when GameTooltip is set to an inventory item
local SetInventoryItem_SetFix = function(self, unit, slot, nameOnly)
	if nameOnly or not unit or UnitGUID(unit) ~= UnitGUID("player") or slot > 19 then return end
	local name, link = self:GetItem()
	if not link then return end

	local offset = slot == 16 and GetInventoryItemLink("player", 17) and 2 or 1 -- if we have an OH equipped and current slot is MH, SetHyperLinkCompare shows MH in second ShoppingTooltip
	ScanningTooltip:SetHyperlinkCompareItem(link, offset) -- or just use SetHyperlink and search for correct start line in GameTooltip to avoid the scuffness of CompareItem?
	local scanningTooltipTextLeft = ScanningTooltip:GetName() .. "TextLeft"

	local start, last, done
	for i = 1, ScanningTooltip:NumLines() do
		if not done then
			local text = _G[scanningTooltipTextLeft .. i]:GetText()
			if start or strfind(text, "%(%d/%d%)") then
				start = i
				if strfind(text, "Set: ") then
					last = i
				elseif last then
					done = true
				end
				if not done then
					_G["GameTooltipTextLeft" .. (i - 1)]:SetText(text)
					_G["GameTooltipTextLeft" .. (i - 1)]:SetTextColor(_G[scanningTooltipTextLeft .. i]:GetTextColor())
				end
			end
		end
	end	
end
hooksecurefunc(GameTooltip, "SetInventoryItem", SetInventoryItem_SetFix)