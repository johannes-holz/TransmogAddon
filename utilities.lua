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

core.GetTextureString = function(texturePath, height)
	height = height or 0
	return "|T" .. texturePath .. ":" .. height .. "::2:0|t"
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
				.. ((points and copper) and ", " or "")
				.. (copper and core.GetCoinTextureString(copper) or "")
end

core.GetShortenedString = function(s, len)
	len = len and (len >= 3 and len or 3) or 20
	if strlen(s) < len then
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

core.SetEnabled = function(self, frame, enabled)
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
					i = i + 1;
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





--------------- Globals for easier debugging ------------------------

AM = core.am


-- Just for Debugging
core.MS = function(self, tab)
	local old = collectgarbage("count")
	local tmp = self.DeepCopy(tab)
	local new = collectgarbage("count")
	collectgarbage("collect")
	return new - old
end

core.WipeRec = function(self, tab)
	local count = 0
	for k, v in pairs(tab) do
		if type(v) == "table" then
			self:WipeRec(v)
		end
		tab[k] = nil
		count = count + 1
	end

	for i = count + 1, count * 2 do
		tab[i] = nil
	end
end

MSChildren = function( tab)
	for k, v in pairs(tab) do
		local mem = core:MS(v)
		if mem > 1 then
			print(k, mem)
		end
	end
end

CountRec = function(tab)
	local count = 0

	for k, v in pairs(tab) do
		if type(v) == "table" then
			count = count + CountRec(v)
		else
			count = count + 1
		end
	end

	return count
end

------

-- TODO: do we want to make certain transmog related utilities global or not?

-- using API provided function
-- GetVisualFromItemLink = function(link)
-- 	if not link then return end

-- 	local uniqueID = select(9, strsplit(":", link))

-- 	return uniqueID and bit.rshift(uniqueID, 16) or nil
-- end

core.GetInventoryItemID = function(unit, slotID)
	local link = GetInventoryItemLink(unit, slotID)

	if not link then return end

	local _, itemID = string.split(":", link)

	return tonumber(itemID)
end

-- We can't read out the visualID from item links from other players' inventories because of a bug, that causes the uniqueID to always be 0
-- We can still get the visualID from GetInventoryItemID and compare it to GetInventoryItemLink to know if it is transmogrified or not
core.GetInventoryVisualID = function(unit, slotID)
	if not unit or not slotID then return end

	if slotID == "MainHandEnchantSlot" or slotID == "SecondaryHandEnchantSlot" then return end
	
	if type(slotID) == "string" then slotID = GetInventorySlotInfo(slotID) end -- TODO: too hacky or just allow using slotname like this?

	local link = GetInventoryItemLink(unit, slotID)
	if UnitGUID(unit) ~= UnitGUID("player") then 
		local itemID = tonumber(select(3, string.find(link, "item:(%d+):")))
		local visualID = GetInventoryItemID(unit, slotID)
		return visualID == itemID and 0 or visualID
	else
		return link and core.API.GetVisualFromItemLink(link)
	end
end

core.GetContainerVisualID = function(bagID, slotID)
	local link = GetContainerItemLink(bagID, slotID)

	return core.API.GetVisualFromItemLink(link)
end





local knownTypes = { [0] = "player", [3] = "NPC", [4] = "pet", [5] = "vehicle" }
core.GetNPCID = function(guid)
	if not guid then return end

	local unitType = tonumber(guid:sub(5,5), 16) % 8
	
	return unitType == 3 and tonumber(guid:sub(8, 12), 16)
end


core.BACKDROP_BORDER_12_12 = {
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",	
	tileEdge = true,
	edgeSize = 12, 
	--insets = {left = 4, right = 4, top = 4, bottom = 4},
}
core.BACKDROP_TOAST_12_12 = {
	bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
	edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
	tile = true,
	tileEdge = true,
	tileSize = 12,
	edgeSize = 12,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
}
core.BACKDROP_TOAST_ONLY_BORDER_12_12 = {
	edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
	tileEdge = true,
	edgeSize = 12,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
}


BACKDROP_ACHIEVEMENTS_0_64 = {
	edgeFile = "Interface\\AchievementFrame\\UI-Achievement-WoodBorder",
	edgeSize = 64,
	tileEdge = true,
};
BACKDROP_ARENA_32_32 = {
	bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
	edgeFile = "Interface\\ArenaEnemyFrame\\UI-Arena-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 32, right = 32, top = 32, bottom = 32 },
};
BACKDROP_DIALOG_32_32 = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
};
BACKDROP_DARK_DIALOG_32_32 = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
};
BACKDROP_DIALOG_EDGE_32  = {
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tileEdge = true,
	edgeSize = 32,
};
BACKDROP_GOLD_DIALOG_32_32 = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
};
BACKDROP_WATERMARK_DIALOG_0_16 = {
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-TestWatermark-Border",
	tileEdge = true,
	edgeSize = 16,
};
BACKDROP_SLIDER_8_8 = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	tile = true,
	tileEdge = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 3, right = 3, top = 6, bottom = 6 },
};
BACKDROP_PARTY_32_32 = {
	bgFile = "Interface\\CharacterFrame\\UI-Party-Background",
	edgeFile = "Interface\\CharacterFrame\\UI-Party-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 32, right = 32, top = 32, bottom = 32 },
};
BACKDROP_TOAST_12_12 = {
	bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
	edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
	tile = true,
	tileEdge = true,
	tileSize = 12,
	edgeSize = 12,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
};
BACKDROP_CALLOUT_GLOW_0_16 = {
	edgeFile = "Interface\\TutorialFrame\\UI-TutorialFrame-CalloutGlow",
	edgeSize = 16,
	tileEdge = true,
};
BACKDROP_CALLOUT_GLOW_0_20 = {
	edgeFile = "Interface\\TutorialFrame\\UI-TutorialFrame-CalloutGlow",
	edgeSize = 20,
	tileEdge = true,
};
BACKDROP_TEXT_PANEL_0_16 = {
	edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
	tileEdge = true,
	edgeSize = 16,
};
BACKDROP_CHARACTER_CREATE_TOOLTIP_32_32 = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Glues\\Common\\TextPanel-Border",
	tile = true,
	tileEdge = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 8, right = 4, top = 4, bottom = 8 },
};
BACKDROP_WRATH_CHARACTER_CREATE_TOOLTIP_32_32 = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true,
	tileSize = 32,
	insets = { left = 10, right = 0, top = 10, bottom = 6 },
};
BACKDROP_TUTORIAL_16_16 = {
	bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileEdge = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 5, top = 3, bottom = 5 },
};