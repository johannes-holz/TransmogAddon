local folder, core = ...

-- TODOs:
-- (low prio) fremde setboni fixen mithilfe der erhaltenen daten. dafür erstmal überlegen, wie wir daten einpflegen. vermutlich ein feld in getitemdata mit link auf die (reduzierte?) setid?
-- dann eine tabelle von setID = encodedBoniRequirements. wie mapped man jetzt noch inventory item auf das richtige setitem? bräuchte eigentlich ein weiteres feld in itemData, aber das würde fast alle verbleibenden bits kosten?

local GetInventoryVisualID = core.GetInventoryVisualID

-- Minimal scanning Tooltip to get correct player Setboni (https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip)
core.ScanningTooltip = CreateFrame("GameTooltip", folder .. "ScanningTooltip")
ScanningTooltip = core.ScanningTooltip
ScanningTooltip:SetOwner( WorldFrame, "ANCHOR_NONE" )
ScanningTooltip:AddFontStrings(ScanningTooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ), ScanningTooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ))

-- Getting VisualID works differently for non-player units
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

 -- for non player units we get visualID through GetInventoryItemID, for the player can get the itemtransmog through its itemlink and skin information through the API GetSkins()
local function TooltipAddMogLine(tooltip)
	--if not tooltip:IsShown() then return end
	tooltip:Show()

	local name, link = tooltip:GetItem()
	if not link then return end

	local lastUnit, lastSlot = OwnerFrame_GetUnitSlot(tooltip:GetOwner())

	local itemID = tonumber(select(3, string.find(link, "item:(%d+):")))
	local visualID = lastUnit and GetInventoryVisualID(lastUnit, lastSlot) or core.API.GetVisualFromItemLink(link)
	local skinVisualID = lastUnit and UnitGUID(lastUnit) == UnitGUID("player") and core.GetInventorySkinID(lastSlot)

	local itemUnlocked = core.GetItemData(itemID)
	local visualUnlocked = core.GetItemData(visualID)
	local skinVisualUnlocked = core.GetItemData(skinVisualID)	

	if itemUnlocked and itemUnlocked ~= 1 then -- GetItemData returned "not unlocked", but not nil, so it is dressable item. can't use IsDressableItem(itemID), because it also returns true for trinkets, recipes, ...
		local text = (core:IsVisualUnlocked(itemID) == 1) and core.APPEARANCE_NOT_COLLECTED_TEXT_B or core.APPEARANCE_NOT_COLLECTED_TEXT_A
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

	-- using table and concat somehow creates more garbage :)

	-- local text = {}
	-- if visualID and visualID > 0 then
	-- 	tinsert(text, "\124c")
	-- 	tinsert(text, core.mogTooltipTextColor.hex)
	-- 	tinsert(text, "Transmogrified to:")
	-- 	tinsert(text, "\n")
	-- 	if visualID == 1 then				
	-- 		tinsert(text, core.HIDDEN)
	-- 		tinsert(text, "\124r")
	-- 	else
	-- 		local mogName = GetItemInfo(visualID)
	-- 		if mogName then
	-- 			tinsert(text, mogName)
	-- 			tinsert(text, "\124r")
	-- 		else				
	-- 			tinsert(text, "fetching name for itemID ")
	-- 			tinsert(text, visualID)
	-- 			tinsert(text, "\124r")
	-- 			core.FunctionOnItemInfo(visualID, TooltipAddMogLine, tooltip, link) -- player transmog items seem to be cached anyway, but probably needed for Hyperlinks from chat
	-- 		end
	-- 	end
	-- 	if skinVisualID then 
	-- 		tinsert(text, "\n")
	-- 	end
	-- end	
	-- if skinVisualID then
	-- 	local skinName = skinVisualID == 1 and "Hidden" or GetItemInfo(skinVisualID)
	-- 	tinsert(text, "\124c")
	-- 	tinsert(text, core.skinTextColor.hex)
	-- 	tinsert(text, "Active Skin:")
	-- 	tinsert(text, "\n")
	-- 	tinsert(text, skinName or skinVisualID)
	-- 	tinsert(text, "\124r")
	-- end
	-- text = table.concat(text, "")
		
	if not tooltip.mogText then	
		tooltip.mogText = tooltip:CreateFontString()
		tooltip.mogText:SetFontObject(textLeft2:GetFontObject())
		tooltip.mogText:SetJustifyH("LEFT")
		--tooltip.mogText:SetTextColor(core.mogTooltipTextColor.r, core.mogTooltipTextColor.g, core.mogTooltipTextColor.b, core.mogTooltipTextColor.a)
		tooltip.mogText:SetPoint("BOTTOMLEFT", textLeft2, "TOPLEFT", 0, 1)

		tooltip:HookScript("OnHide", function()
			--textLeft1:SetJustifyV("MIDDLE")
			if textLeft1.justifyHOld then
				textLeft1:SetHeight(textLeft1:GetStringHeight())
				textLeft1:SetJustifyH(textLeft1.justifyHOld)
				textLeft1:SetJustifyV(textLeft1.justifyVOld)
				textLeft1.justifyHOld, textLeft1.justifyVOld = nil, nil
				tooltip.mogText:SetText("")
			end
		end)
	end
	
	textLeft1.justifyHOld = textLeft1:GetJustifyH()
	textLeft1.justifyVOld = textLeft1:GetJustifyV()
	-- Not quite sure, but I feel like this way is better than moving all tooltip lines around and will probably not collide with other addons
	tooltip.mogText:SetText(text)	
	textLeft1:SetJustifyV("TOP")	
	textLeft1:SetJustifyH("LEFT")	

	-- tell mogText to do a line break if any line does not fit into the tooltip:
	-- tooltip.mogText:SetWidth(math.max(tooltip:GetWidth() - 15, 200))
	-- if we don't want a line break in mog names and instead want the tooltip to horizontally increase in size:
	textLeft1:SetWidth(math.max(tooltip.mogText:GetStringWidth(), tooltip:GetWidth()))
	textLeft1:SetHeight(textLeft1:GetStringHeight() + tooltip.mogText:GetHeight())
	tooltip:Show() -- for resize

	if tooltip == GameTooltip and visualID and visualID > 1 then
		core.SetExtraItemTooltip(visualID, "ANCHOR_TOP") -- TODO: Options
	end
end

local tooltips = {GameTooltip, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3}

for _, tooltip in pairs(tooltips) do
	tooltip:HookScript("OnTooltipSetItem", TooltipAddMogLine)
end

-- TODO: change to removable posthooks, so we can have option to disable these
-- GameTooltip:HookScript("OnTooltipSetItem", TooltipAddMogLine)


--hooksecurefunc(ItemRefTooltip, "SetHyperlink", TooltipAddMogLine)
--ItemRefTooltip:HookScript("OnTooltipSetItem", TooltipAddMogLine)


core.TooltipDisplayTransmog = TooltipAddMogLine -- ??


-- other stuff where we might want to display item collection status:
-- recipe item: not sure yet if theres a way to find crafted item id from recipe tooltip
-- trainer: might be able to do hook SetTrainerService(i) and get itemLink from GetTrainerServiceItemLink(i)
-- trade ui: SetTradeSkillItem(TradeSkillFrame.selectedSkill, self:GetID()), GetTradeSkillReagentItemLink(i, j)



-- ShoppingTooltips would need modified version of AddMogLine since they have an extra line on top that says "currently equipped". But not sure if this is really needed
-- if GameTooltip.shoppingTooltips then -- TODO: Find global names or check if those are always created already / hook it somewhere where they are
-- 	for k, shoppingTooltip in pairs(GameTooltip.shoppingTooltips) do
-- 		--shoppingTooltip:HookScript("OnTooltipSetItem", HandleItem)
-- 		hooksecurefunc(shoppingTooltip, "SetHyperlinkCompareItem", HandleItem, shoppingTooltip)
-- 	end
-- end




-- hooksecurefunc("SetItemRef", function(link, ...)  -- TODO: This might taint our code when we call OnItemInfo in TooltipAddMogLine?
-- 	TooltipAddMogLine(ItemRefTooltip, link)
-- end)


--[[
hooksecurefunc("ChatFrame_OnHyperlinkShow", function(self, link, text, button)
	--am(link)
end)
--]]

--[[
local SetHyperlinkOrig = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
    if link and string.sub(link, 1, 11) == "transmogset" then
        return
    end
	
    return SetHyperlinkOrig(self, link, ...)
end
--]]

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


-- What to preview / insert into chat
-- Since everyone and their mother is prehooking this function, we might have to ensure, that we are last to hook
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

 --https://www.mmo-champion.com/threads/2184270-Track-hidden-aura
 
 
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
-- As above but also the return values from GetInventoryItemLink never update for other players with skins without a new NotifyInspect call
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
--f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("UNIT_STATS")
local test = {"UNIT_PORTRAIT_UPDATE"}
for _, event in pairs(test) do
	f:RegisterEvent(event)
end
f:RegisterEvent("UNIT_MODEL_CHANGED")
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
	end
end)
f.UPDATE_INTERVAL = 0.5
f.lastScan = {}
f.buttons = {}
f.onUpdate = function(self, e)
	self.e = (self.e or 0) + e
	if self.e > self.UPDATE_INTERVAL then
		self.e = self.e - self.UPDATE_INTERVAL
		self.toggle = (self.toggle or 0) + 1
		if self.toggle % 4 == 0 and InspectFrame.unit and InspectFrame.unit ~= "player" then
			--print("Notified!", GetTime())
			NotifyInspect(InspectFrame.unit)
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

local SetInventoryItem_SetFix = function(self, unit, slot, nameOnly) -- Only works for player atm (scans hidden tooltip for correct SetBoni display in with SetHyperlink(CompareItem))
	if nameOnly or not unit or UnitGUID(unit) ~= UnitGUID("player") then return end
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



-- Old bad player set boni fix

-- core.L = {
-- 	boundOnEquip = "Wird beim Anlegen gebunden",
-- 	boundOnPickup = "Wird beim Aufheben gebunden",
-- 	soulbound = "Seelengebunden",
-- }

-- Fixes set boni display for the player inventory by overwriting SetInventoryItem's tooltip with SetHyperlink, which displays player set boni correctly
-- Could alternatively use SetHyperlink on hidden tooltip and manually copy the correct lines to the GameTooltip
-- SetHyperlinkCompareItem displays set boni and soulbound status correctly, but adds "currently equipped" line at start, which is harder to fix than just fixing the soulbound line I belive
-- I could not find a simple hack to fix the display of other people's set boni. Would probably need complete setdata, something like: setID = {itemID = setID}, setBoni = {setID = {2, 4, 7}}

-- Breaks some stuff (i.e. temp. enchants), so we have to parse hidden tooltip and copy the setlines (text and color?)
-- GameTooltip.SetInventoryItemOld = GameTooltip.SetInventoryItem
-- GameTooltip.SetInventoryItem = function(self, unit, slot, nameOnly)
-- 	lastUnit, lastSlot = unit, slot
-- 	local hasItem, hasCooldown, repairCost = self:SetInventoryItemOld(unit, slot, nameOnly)

-- 	local link = GetInventoryItemLink(unit, slot)

-- 	if link and UnitGUID(unit) == UnitGUID("player") then
-- 		local owner = GameTooltip:GetOwner()
-- 		local anchor, x, y = GameTooltip:GetAnchorType()
-- 		self:SetOwner(owner, anchor, x, y)
-- 		lastUnit, lastSlot = unit, slot -- got reset by SetOwner()
-- 		--self:SetUnit("player") -- setting a tooltip to the same item twice hides the tooltip. can avoid this by either setting it to something else between the calls or calling SetOwner with the current parameters, which clears the tooltip
-- 		self:ClearLines()
-- 		self:SetHyperlink(link)
-- 		if GameTooltipTextLeft2:GetText() == core.L.boundOnPickup or GameTooltipTextLeft2:GetText() == core.L.boundOnEquip then GameTooltipTextLeft2:SetText(core.L.soulbound) end
-- 		-- Still missing durability (repair status) line. maybe use comparehyperlink after all and loop over all lines?
-- 	end

-- 	return hasItem, hasCooldown, repairCost
-- end


-- Somehow breaks SetHyperlinkCompareItem stuff, so use above secure hook, which works
-- GameTooltip.SetInventoryItemOld = GameTooltip.SetInventoryItem
-- GameTooltip.SetInventoryItem = function(self, unit, slot, nameOnly) -- Is it save to hook this unsecurely?
-- 	lastUnit, lastSlot = unit, slot
-- 	return self:SetInventoryItemOld(unit, slot, nameOnly)
-- end

-- not sure if we should fix this and call the old function something like GetInventoryVisualID, which could handle the different behaviour for player and other units, probably more correct?
-- choosing not to overwrite this atm, correct information an be retrivied via core.GetInventoryItemID and core.GetInventoryVisualID?
--[[
GetInventoryItemIDOld = GetInventoryItemID
GetInventoryItemID = function(unit, slotID)
	local link = GetInventoryItemLink(unit, slotID)
	if not link then
		return GetInventoryItemIDOld(unit, slotID)
	else
		local _, itemID = string.split(":", link)
		print(itemID, link, gsub(link, "\124", "\124\124"))
		return tonumber(itemID)
	end
end
--]]


--[[
GetContainerItemLinkOld = GetContainerItemLink
GetContainerItemLink = function(...)
	print("itemlinky")
	return GetContainerItemLinkOld(...)
end
GetContainerItemInfoOld = GetContainerItemInfo
GetContainerItemInfo = function(...)
	print("informative")
	return GetContainerItemInfoOld(...)
end
GetContainerItemIDOld = GetContainerItemID
GetContainerItemID = function(...)
	print("ID YO")
	return GetContainerItemIDOld(...)
end
--]]


 --[[ 

-- original function from ItemButtonTemplate.lua
function HandleModifiedItemClick(link)
	if ( IsModifiedClick("CHATLINK") ) then
		if ( ChatEdit_InsertLink(link) ) then
			return true;
		end
	end
	if ( IsModifiedClick("DRESSUP") ) then
		DressUpItemLink(link);
		return true;
	end
	return false;
end

 ]]
 
--[[
local SendTmogLink = function()
	local link = "|Hplayer:Kaso|h[Kaso]|h"
	
	SendChatMessage(link)
	SendChatMessage("uwu")
	print(link)
end

SendTmogLink()
	]]
--[[
ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
	local name, link = tooltip:GetItem()
	if not link then return end
	local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
	  linkLevel, specializationID, reforgeId, unknown1, unknown2 = strsplit(":", link)
	  
	--am("OnTooltipSetItem", itemId)
	local tmogID = bit.rshift(uniqueId, 16)
	
	--TooltipAddMogLine(ItemRefTooltip, itemId)
	
--	if tooltip.notFirstTime then
--		TooltipAddMogLine(ItemRefTooltip, itemId)
--	else
--		tooltip.notFirstTime = true
--		ItemRefTooltip:Hide()
--		MyWaitFunction(0.3, ItemRefTooltip.SetHyperlink, ItemRefTooltip, link, ...)
--	end
end)]]

--Here no problems with first tooltip?!?!?
--[[
local SetHyperlink = ItemRefTooltip.SetHyperlink
ItemRefTooltip.SetHyperlink = function(self, link)	
	local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
	  linkLevel, specializationID, reforgeId, unknown1, unknown2 = strsplit(":", link)
	  
	am(itemId)
	
	SetHyperlink(self, link)
	TooltipAddMogLine(ItemRefTooltip, itemId)
end]]

--hooksecurefunc("SetItemRef", am("SetItemRef"))
--hooksecurefunc("ChatFrame_OnHyperlinkShow", function(...)
--    print("ToggleBackpack called.")
--end)

--hooksecurefunc("ItemRefTooltip_SetHyperlink", function(...)
--	am(...)
--end)



-- SetBoniDisplay Hack. would need data about which sets mix (gladiator, t7-10, some classic sets?, etc) and how many parts are needed for each setbonus of every set
--[[


local allInventorySlots = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"RangedSlot",
	"AmmoSlot"
}


local FindSetItemBaseName = function(itemName)
	local baseItemName
	if string.find(itemName, ".* des %a+ Gladiators") then
		baseItemName = string.sub(itemName, 1, select(1, string.find(itemName, string.match(itemName, ".* des (%a+) Gladiators"))) - 1) .. "Gladiators"
	elseif string.find(itemName, "%a+ Gladiator's .*") then
		baseItemName = string.sub(itemName, select(2, string.find(itemName, string.match(itemName, "(%a+) Gladiator's .*"))) + 2)
		
	elseif string.find(itemName, "%a+ %a+ des Ymirjarfürsten") then
		baseItemName = string.sub(itemName, select(2, string.find(itemName, string.match(itemName, "(%a+) %a+ des Ymirjarfürsten"))) + 2)
	end
	
	return baseItemName
end

local function FixSetDisplay()	-- pointless to take tooltip as param and then iterate over gametooltips lines
	if not GameTooltip:GetOwner() then return end
	
	local ownerName = GameTooltip:GetOwner():GetName()	
	

	local currentItems, setItemBaseNames = {}, {}
	local setName, setLine, setCount, setMax, isSetItemLine
	for i=1,40 do		
		local line = _G["GameTooltipTextLeft" .. i]
		--
		--am(string.format('%q', '(%d/%d)'))
		--local str = "Schlachtrüstung des Schreckenspanzers (8/8)"
		--am(string.sub(str, string.find(str, "%(%d/%d%)")))
		if line then
			--am(line:GetName(), line:GetText(), line:GetTextColor())
			if isSetItemLine then
				if line:GetText() == " " then
					isSetItemLine = false
				else
					local setItemName = string.gsub(line:GetText(), '^%s*(.-)%s*$', '%1')
					
					local r, g, b, a = line:GetTextColor()
					
					if r < 0.75 then
						for slot, currentItem in pairs(currentItems) do
							if (currentItem == setItemName or (setItemBaseNames[slot] and setItemBaseNames[slot] == setItemName)) then	
								line:SetTextColor(myadd.setItemTooltipTextColor.r, myadd.setItemTooltipTextColor.g, myadd.setItemTooltipTextColor.b, myadd.setItemTooltipTextColor.a)
								line:SetText("  "..currentItem)
								setCount = setCount + 1
							end
						end
					end	
					
					if r > 0.75 and not myadd.Contains(currentItems, setItemName) then
						line:SetTextColor(myadd.setItemMissingTooltipTextColor.r, myadd.setItemMissingTooltipTextColor.g, myadd.setItemMissingTooltipTextColor.b, myadd.setItemMissingTooltipTextColor.a)
						local setItemBaseName = FindSetItemBaseName(setItemName)
						if setItemBaseName then
							line:SetText("  "..setItemBaseName)
						end
						setCount = setCount - 1
					end
				end
			end
			if line:GetText() and string.find(line:GetText(), "%(%d/%d%)") then
				setLine = line
				setName = string.match(line:GetText(), "(.+) %(%d/%d%)")
				setMax = tonumber(string.match(line:GetText(), ".*%(%d/(%d)%)"))
				setCount = tonumber(string.match(line:GetText(), ".*%((%d)/%d%)"))
				for k, v in pairs(allInventorySlots) do
					if GetInventoryItemID("player", GetInventorySlotInfo(v)) then
						currentItems[v] = GetItemInfo(GetInventoryItemID("player", GetInventorySlotInfo(v)))
						
						setItemBaseNames[v] = FindSetItemBaseName(currentItems[v])
					end
				end
				isSetItemLine = true
			end
			if line:GetText() and string.find(line:GetText(), "%(%d%) Set:.*") then
				local required = tonumber(string.match(line:GetText(), "%((%d)%) Set:.*"))
				if setCount >= required then
					line:SetTextColor(myadd.bonusTooltipTextColor.r, myadd.bonusTooltipTextColor.g, myadd.bonusTooltipTextColor.b, myadd.bonusTooltipTextColor.a)
					line:SetText(string.sub(line:GetText(), 5))
				end
			end
			--TODO: False Positive Setboni ausgrauen. benötigt info darüber, wie viele parts jeweilige boni benötigen und variable die tracked um den wievielten setbonus es sich handelt, um tabelle nutzen zu können die sagt Ymirjarfürsten = {2,4}
					--oder den ganzen kram mehr id basiert machen?
					--nachfragen wie man an die setdaten kommt, die auf https://db.rising-gods.de/?itemsets dargestellt werden?
					--aus https://wow.tools/dbc/?dbc=itemset&build=3.3.5.12340&locale=deDE#page=1&search=ymir könnte man die bonus thresholds extrahieren
		end
	end
	if setLine then
		setLine:SetText(setName.." ("..setCount.."/"..setMax..")")
	end
end



]]