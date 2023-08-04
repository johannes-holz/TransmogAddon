local folder, core = ...

-- TODO: Make these settings save per character instead of account. planning to revisit this when making options

MyAddonDB.isExpanded = MyAddonDB.isExpanded or true
MyAddonDB.isWatched = MyAddonDB.isWatched or false

local GetCurrencyListSizeOld = GetCurrencyListSize
GetCurrencyListSize = function()
    local normalSize = GetCurrencyListSizeOld()

    return normalSize + 2
end

-- local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(index)
local GetCurrencyListInfoOld = GetCurrencyListInfo
GetCurrencyListInfo = function(index)
    local normalListSize = GetCurrencyListSizeOld()

    if not index or type(index) ~= "number" or index <= normalListSize then
        return GetCurrencyListInfoOld(index)
    end

    if index == normalListSize + 1 then
        return core.TRANSMOG_NAME, true, MyAddonDB.isExpanded, false, false, 0, 0, nil, 0
    elseif MyAddonDB.isExpanded and index == normalListSize + 2 then
        return core.CURRENCY_NAME, false, true, false, MyAddonDB.isWatched, core.GetBalance().shards or 0, 0, core.CURRENCY_ICON, core.CURRENCY_FAKE_ITEMID
    end
    
    return nil
end

local ExpandCurrencyListOld = ExpandCurrencyList
ExpandCurrencyList = function(index, expanded)
    local normalListSize = GetCurrencyListSizeOld()

    if not index or type(index) ~= "number" or index <= normalListSize then
        return ExpandCurrencyListOld(index, expanded)
    end

    if index == normalListSize + 1 then
        MyAddonDB.isExpanded = (expanded == 1)
    end
end

local SetCurrencyBackpackOld = SetCurrencyBackpack
SetCurrencyBackpack = function(index, backpack)
    local normalListSize = GetCurrencyListSizeOld()

    if not index or type(index) ~= "number" or index <= normalListSize then
        return SetCurrencyBackpackOld(index, backpack)
    end

    if index == normalListSize + 2 then
        MyAddonDB.isWatched = (backpack == 1)
    end
end

GetBackpackCurrencyInfoOld = GetBackpackCurrencyInfo
GetBackpackCurrencyInfo = function(id)
    local name = GetBackpackCurrencyInfoOld(id)

    if name then
        return GetBackpackCurrencyInfoOld(id)
    end

    if (id == 1 or GetBackpackCurrencyInfoOld(id - 1)) and MyAddonDB.isWatched then
        return core.CURRENCY_NAME, core.GetBalance().shards or 0, 0, core.CURRENCY_ICON, core.CURRENCY_FAKE_ITEMID
    end
end

GameTooltip.SetCurrencyTokenOld = GameTooltip.SetCurrencyToken
GameTooltip.SetCurrencyToken = function(self, tokenID)
    local normalListSize = GetCurrencyListSizeOld()
    if tokenID == normalListSize + 2 then
        core.Tooltip_SetTransmogToken(self)
    else
        self:SetCurrencyTokenOld(tokenID)
    end
end

GameTooltip.SetBackpackTokenOld = GameTooltip.SetBackpackToken
GameTooltip.SetBackpackToken = function(self, id)
    print("SetBackpackToken", id)
    self:SetBackpackTokenOld(id)
    if not self:IsShown() then
        core.Tooltip_SetTransmogToken(self)
    end
end

core.Tooltip_SetTransmogToken = function(tooltip)
    local balance = core.GetBalance()

    tooltip:SetText(core.CURRENCY_NAME, 1, 1, 1, 1)
    tooltip:AddLine(core.CURRENCY_TOOLTIP_TEXT1, nil, nil, nil, 1)
    tooltip:AddLine(" ")
    if not balance.shards then
        tooltip:AddLine("Aktuell kann die Transmoginformation nicht abgefragt werden.", 0.9, 0.1, 0.1, 1)
    else
        tooltip:AddLine(core.CURRENCY_TOOLTIP_TEXT2, nil, nil, nil, 1)
        tooltip:AddLine(balance.shards .. "/" .. balance.shardsLimit)
        tooltip:AddLine(" ")
        tooltip:AddLine(core.CURRENCY_TOOLTIP_TEXT3, nil, nil, nil, 1)
        tooltip:AddLine("Total: " .. balance.weekly.total .. "/" .. balance.weekly.totalLimit)
        tooltip:AddLine("Raids: " .. balance.weekly.raid .. "/" .. balance.weekly.raidLimit)
        tooltip:AddLine("Dungeonfinder: " .. balance.weekly.lfg .. "/" .. balance.weekly.lfgLimit)
        tooltip:AddLine("Arena: " .. balance.weekly.arena .. "/" .. balance.weekly.arenaLimit)
        tooltip:AddLine("Battlegrounds: " .. balance.weekly.bg .. "/" .. balance.weekly.bgLimit)
    end
    tooltip:Show()
end

local f = CreateFrame("Frame")
f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
f:SetScript("OnEvent", function(self, event, ...)
    local count = 0

    for i = 1, 40 do
        local _, _, _, _, isWatched = GetCurrencyListInfo(i)
        if isWatched then count = count + 1 end
    end

    if count > MAX_WATCHED_TOKENS then -- 3 normal tokens are already being watched (maybe set, when addon was disabled), so no room for our token
        MyAddonDB.isWatched = false
    end
end)

f.update = function()
    if BackpackTokenFrame:IsShown() then BackpackTokenFrame_Update() end
    if TokenFrame:IsShown() then TokenFrame_Update() end
end
core.RegisterListener("balance", f)


-- TODO: Decide if we really want to hook this core function. Needed to make Balance Display work with some AddOns
-- somehow taints whole UI, so cant dirty hook getiteminfo like this anyway ..
-- could instead choose an existing item, that is not in use, as fake itemID and secureHook SetHyperlink to automatically change to SetTransmogToken for this item?

-- itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemID or "itemString" or "itemName" or "itemLink")
-- local GetItemInfoOld = GetItemInfo
-- GetItemInfo = function(item)
-- 	if item == core.CURRENCY_FAKE_ITEMID or item == core.CURRENCY_NAME then
-- 		return core.CURRENCY_NAME, core.CURRENCY_NAME, 1, 1, 0, "Plunder", "Verschiedenes", 2147483647, nil, core.CURRENCY_ICON, 0
-- 	end
-- 	return GetItemInfoOld(item)
-- end


-- GameTooltip.SetHyperlinkOld = GameTooltip.SetHyperlink
-- GameTooltip.SetHyperlink = function(self, link, ...)
-- 	if link == core.CURRENCY_FAKE_ITEMID or link == core.CURRENCY_NAME then
-- 		return GameTooltip:SetTransmogToken()		
-- 	end
-- 	print("Sethyperlinkold", link, ...)
-- 	return GameTooltip:SetHyperlinkOld(link, ...)
-- end