local folder, core = ...

---- Table utils ----
core.Contains = function(tab, element)
	for _, value in pairs(tab) do
		if value == element then
			return true
	 	end
	end
	return false
end

core.Length = function(tab)
	local count = 0
	for _ in pairs(tab) do count = count + 1 end
	return count
end

core.GetKeySet = function(tab)
	local set = {}
	for key, _ in pairs(tab) do
		table.insert(set, key)
	end
	return set
end

local DeepCompare
DeepCompare = function(t1, t2, ignore_mt)
	local type1 = type(t1)
	local type2 = type(t2)
	if type1 ~= type2 then return false end
	-- non-table types can be directly compared
	if type1 ~= 'table' and type2 ~= 'table' then return t1 == t2 end

	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end

	for k1, v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not DeepCompare(v1,v2) then return false end
	end

	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not DeepCompare(v1,v2) then return false end
	end

	return true
end
core.DeepCompare = DeepCompare

local DeepCopy
DeepCopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
core.DeepCopy = DeepCopy

core.ToNoCasePattern = function(s)
	s = string.gsub(s, "%a", function (c)
		return string.format("[%s%s]", string.lower(c), string.upper(c))
	end)
	return s
end

local pack = function(...)
	return { n = select("#", ...), ... }
end

-- auto truncate numbers?
-- local tostring = function(object)
-- 	if type(object) == "number" then
-- 		return string.format("%.3f", object)
-- 	else
-- 		return tostring(object)
-- 	end
-- end
  
local function amHelperTable(printResult, tab)
	for k, v in pairs(tab) do
		printResult = printResult .. tostring(k) .. ": "
		if type(v) == "table" then
			printResult = printResult .. "{"
			printResult = amHelperTable(printResult, v)
			printResult = printResult .. "} "
		else
			printResult = printResult .. tostring(v) .. ", "
		end
	end
	
	return printResult
end

-- replacement for print that can display table content
core.am = function(...)

	local args = pack(...)
	local printResult = ""
	for i = 1, args.n do
		if type(args[i]) == "table" then
			printResult = printResult .. "{"
			printResult = amHelperTable(printResult, args[i])
			printResult = printResult .. "} "
		else
			printResult = printResult .. tostring(args[i]) .. " "
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage(printResult)
end

core.Debug = function(...)
	if not TransmoggyDB.debugEnabled then return end
	core.am(...)
end

core.ToggleDebug = function()
	TransmoggyDB.debugEnabled = not TransmoggyDB.debugEnabled
	print(folder .. " - Debug messages are now " .. (TransmoggyDB.debugEnabled and "enabled." or "disabled."))
end

core.GetTextureString = function(texturePath, height)
	height = height or 0
	return "|T" .. texturePath .. ":" .. height .. ":" .. height .. ":2:0|t"
end

core.GetCoinTextureString = function(money, texHeight)
	texHeight = texHeight or 0
	local texFormat = ":".. texHeight .. "::2:0"
	
	local gold, silver, copper
	
	copper = money % 100
	silver = math.floor((money / 100) % 100)
	gold = math.floor((money / 10000))
	
	return (gold > 0 and (gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon" .. texFormat .. "|t ") or "")
		.. (silver > 0 and (silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon" .. texFormat .. "|t ") or "")
		.. (copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon" .. texFormat .. "|t ")
end

core.GetCoinTextureStringFull = function(money, texHeight)
	texHeight = texHeight or 0
	local texFormat = ":".. texHeight .. "::2:0"
	
	local gold, silver, copper
	
	copper = money % 100
	silver = math.floor((money / 100) % 100)
	gold = math.floor((money / 10000))
	
	return gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon" .. texFormat .. "|t " ..
		silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon" .. texFormat .. "|t " ..
		copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon" .. texFormat .. "|t "
end


core.GetPriceString = function(points, copper, showZero)
	if not showZero then
		if points == 0 then points = nil end
		if copper == 0 then copper = nil end
	end


	return (points and (points .. core.GetTextureString(core.CURRENCY_ICON)) or "")
				.. ((points and copper) and "  " or "")
				.. (copper and core.GetCoinTextureString(copper) or "")
end

core.GetShortenedString = function(s, len)
	len = len and (len >= 3 and len or 3) or 20
	if strlen(s) <= len then
		return s
	else
		return strsub(s, 1, len - 3) .. "..."
	end
end

core.GetColoredString = function(s, hex)
	return "\124c" .. hex .. s .. "\124r"
end

core.LinkToColoredString = function(itemLink)
	if not itemLink then return end
	local name = strmatch(itemLink, "\124h%[(.-)%]\124h")
	if not name then return end
	return strsub(itemLink, 0, 10) .. name .. "\124r"
end

core.RemoveFirstWordInString = function(s)
	local start = strfind(s, " ")
	return start and strsub(s, start + 1) or ""
end

core.GetEscapedString = function(s)
	return string.gsub(s, "(%W)", "%%%1")
end

core.SetShown = function(region, shown)
	if shown then
		region:Show()
	else
		region:Hide()
	end
end

core.SetEnabled = function(frame, enabled)
	if enabled then
		frame:Enable()
	else
		frame:Disable()
	end
end

core.UIDropDownMenu_SetEnabled = function(dropDown, enabled)
	if enabled then
		UIDropDownMenu_EnableDropDown(dropDown)
	else
		UIDropDownMenu_DisableDropDown(dropDown)
	end
end

-- Fix for Tooltip Bug, see: https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip#Blizzard's_GameTooltip
-- GameTooltipTextLeft9 and GameTooltipTextRight9 are incorrectly named GameTooltipTextLeft1 and GameTooltipTextRight1 instead
-- TODO: Still encountering the bug sometimes? Solved by calling this after PLAYER_ENTERING_WORLD?
core.FixTooltip = function(tooltip)
	local initItem = core.DUMMY_WEAPONS.TOOLTIP_FIX_ITEM -- i.e. 32479 (any item with enough lines to trigger tooltip to generate the problematic line 9)
	if not GetItemInfo(initItem) then
		core.FunctionOnItemInfo(initItem, core.FixTooltip, tooltip)
		return
	end

	tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	tooltip:SetHyperlink("item:" .. initItem)

	local regions = { tooltip:GetRegions() }
	local buggoLeft, buggoRight
	for i, region in pairs(regions) do
		if region and region:GetObjectType() == "FontString" then
			local _, anchor = region:GetPoint(1)
			if region:GetName() == region:GetParent():GetName() .. "TextLeft1" and anchor ~= region:GetParent() then
				buggoLeft = region
			elseif region:GetName() == region:GetParent():GetName() .. "TextRight1" and not anchor or anchor == buggoLeft then
				buggoRight = region
			end
		end
	end

	if buggoLeft then
		_G[tooltip:GetName()  .. "TextLeft9"] = buggoLeft
		_G[tooltip:GetName()  .. "TextRight9"] = buggoRight
	end

	tooltip:Hide()
end

core.SetTooltip = function(frame, text, r, g, b, a, wrap)
	if not frame or not text then return end
	frame:HookScript("OnEnter", function(self)		
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text, r, g, b, a, wrap)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

core.SetTooltip2 = function(frame, title, r1, g1, b1, wrap1, text, r2, g2, b2, wrap2)
	if not frame or not title then return end
	frame:HookScript("OnEnter", function(self)		
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(title, r1, g1, b1, wrap1)
		GameTooltip:AddLine(text, r2, g2, b2, wrap2)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

core.MouseIsOver = function(frame)
	local x, y = GetCursorPosition()
	local s = frame:GetEffectiveScale()
	x, y = x / s, y / s
	return x >= frame:GetLeft() and x <= frame:GetRight() and y >= frame:GetBottom() and y <= frame:GetTop()
end

core.PlayButtonSound = function()
	PlaySound("gsTitleOptionOK")
end

local waitTable = {}
local waitFrame = nil
local updateInterval, timeSinceLastUpdate = 0.5, 0 --optional
local maxParallelTasks = 100

core.MyWaitFunction = function(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
		return false
	end
	if(waitFrame == nil) then
		waitFrame = CreateFrame("Frame",nil, UIParent)
		waitFrame:SetScript("OnUpdate", function(self, elapse)
			local count = #waitTable
			if count == 0 then
				waitFrame:Hide()
				return
			end
			if count > maxParallelTasks then --Only x at a time, REMOVE IF TASKS ARE SUPPOSED TO BE EXECUTED IN PARALLEL!!
				count = maxParallelTasks
			end
			--[[
			timeSinceLastUpdate = timeSinceLastUpdate + elapse
			if false then
			if timeSinceLastUpdate < updateInterval then
			timeSinceLastUpdate = timeSinceLastUpdate + elapse
			return false
			else
			timeSinceLastUpdate = 0
			elapse = updateInterval
			end
			end
			]]--
			local i = 1

			while(i<=count) do
				local waitRecord = tremove(waitTable,i)
				local d = tremove(waitRecord,1)
				local f = tremove(waitRecord,1)
				local p = tremove(waitRecord,1)
				if(d>elapse) then
					tinsert(waitTable,i,{d-elapse,f,p})
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(waitTable, 1, {delay,func,{...}})
	if not waitFrame:IsShown() then
		waitFrame:Show()
	end
	return true
end


-- TODO: do we want to make certain transmog related utilities and fixes global?
core.GetInventoryItemID = function(unit, slotID)
	local link = GetInventoryItemLink(unit, slotID)

	if not link then return end

	local _, itemID = string.split(":", link)

	return tonumber(itemID)
end

core.GetVisualFromItemLink = function(link)
	local itemID, enchantID = core.API.NoTransmog, core.API.NoTransmog
	if link then
		itemID, enchantID = core.API.GetVisualFromItemLink(link)
	end

	return (itemID == core.API.HideItem and core.HIDDEN_ID) or (itemID == core.API.NoTransmog and core.UNMOG_ID) or itemID,
		   (enchantID == core.API.HideItem and core.HIDDEN_ID) or (enchantID == core.API.NoTransmog and core.UNMOG_ID) or enchantID
end

-- We can't read out the visualID from item links from other players' inventories because of a bug on RG, that causes the uniqueID to always be 0 for other players
-- We can still get the visualID from GetInventoryItemID and compare it to GetInventoryItemLink (which returns the real item) to know if it is transmogrified or not
core.GetInventoryVisualID = function(unit, slotID)
	if not unit or not slotID then return end
	
	if type(slotID) == "string" then slotID = core.slotToID[slotID] end -- TODO: too hacky or just allow using slotname like this?
	
	if not slotID then return end

	if slotID == core.slotToID["MainHandEnchantSlot"] or slotID == core.slotToID["SecondaryHandEnchantSlot"] then
		-- local correspondingSlot = core.GetCorrespondingSlot(core.idToSlot[slotID])
		-- slotID = core.slotToID[correspondingSlot]
		-- return core.GetInventoryEnchantID(unit, -slotID) -- TODO: How will we get enchant visuals?
		return
	end	

	local link = GetInventoryItemLink(unit, slotID)

	if not link then return end

	if UnitGUID(unit) ~= UnitGUID("player") then 
		local itemID = core.GetItemIDFromLink(link)
		local visualID = GetInventoryItemID(unit, slotID)
		return (visualID == itemID and core.UNMOG_ID) or (visualID == core.API.HideItem and core.HIDDEN_ID) or visualID -- or just nil for no transmog?
	else
		return core.GetVisualFromItemLink(link) -- returns a tuple of visualID, illusionID for weapons now
	end
end

core.GetContainerVisualID = function(bagID, slotID)
	local link = GetContainerItemLink(bagID, slotID)
	return core.GetVisualFromItemLink(link)
end

-- TODO: Or allow EnchantSlots in GetInventoryItemID and GetInventoryVisualID instead?
core.GetInventoryEnchantID = function(unit, slotID)
	if not unit or not slotID then return end

	if slotID == "MainHandEnchantSlot" or slotID == "SecondaryHandEnchantSlot" then return end
	
	if type(slotID) == "string" then slotID = GetInventorySlotInfo(slotID) end

	local link = GetInventoryItemLink(unit, slotID)
	local enchantID = link and tonumber(select(3, string.find(link, "item:%d+:(%d+)")))
	enchantID = core.EnchantToSpellID(enchantID)

	return enchantID ~= 0 and enchantID
end

core.GetInventoryEnchantVisualID = function(unit, slotID)
	if not unit or not slotID then return end

	if slotID == "MainHandEnchantSlot" or slotID == "SecondaryHandEnchantSlot" then return end
	
	if type(slotID) == "string" then slotID = GetInventorySlotInfo(slotID) end

	local link = GetInventoryItemLink(unit, slotID)

	-- if UnitGUID(unit) ~= UnitGUID("player") then return end -- Bug that we don't get UniqueID info for other players, no fix atm

	local visualID, enchantVisualID = core.GetVisualFromItemLink(link)

	return enchantVisualID
end



local knownTypes = { [0] = "player", [3] = "NPC", [4] = "pet", [5] = "vehicle" }
core.GetNPCID = function(guid)
	if not guid then return end

	local unitType = tonumber(guid:sub(5,5), 16) % 8
	
	return unitType == 3 and tonumber(guid:sub(8, 12), 16)
end

core.GetItemIDFromLink = function(itemLink)
    if not itemLink or type(itemLink) == "number" then
        return itemLink
    end

    itemLink = strmatch(itemLink, "item:(%d+)")
    return itemLink and tonumber(itemLink)
end

core.GetSpellIDFromLink = function(spellLink)
    if type(spellLink) == "number" then
        return spellLink
    end

    spellLink = strmatch(spellLink, "spell:(%d+)")
    return spellLink and tonumber(spellLink)
end

core.GetEnchantIDFromLink = function(itemLink)
    if type(itemLink) == "number" then
        return nil
    end

    itemLink = strmatch(itemLink, "item:%d+:(%d+)")
    return itemLink and tonumber(itemLink) or nil
end

core.DecodeItemLink = function(link)
    local itemString = link and link:match("|H(.*)|h.*|h") or link or ""
	return strsplit(":", itemString)
end

core.ToPrintableLink = function(link)
	return link and gsub(link, "\124", "\124\124") or ""
end