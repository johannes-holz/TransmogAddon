local folder, core = ...

--MyAddonDB.outfits = MyAddonDB.outfits or {}

-- core.am(MyAddonDB)

core.GetOutfits = function()
    if not MyAddonDB then return end
    MyAddonDB.outfits = MyAddonDB.outfits or {}
    return MyAddonDB.outfits
end

core.IsInvalidOutfitName = function(name)    
	local denyMessage
	if string.len(name) < 1 then -- or name:gsub(" ", "") ?
		denyMessage = core.OUTFIT_NAME_TOO_SHORT
	elseif string.find(name, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz _.,'1234567890]") then
		denyMessage = core.OUTFIT_NAME_INVALID_CHARACTERS
    elseif core.GetOutfits()[name] then
        denyMessage = core.OUTFIT_NAME_ALREADY_IN_USE
    end
	
	return denyMessage
end

core.CreateOutfit = function(name, set)
    assert(name and set, "CreateOutfit: Missing name or set parameter")
    -- save as [name] = {slots} or [id] = {name = "name", slots = {slots}} ??
    local invalidReason = core.IsInvalidOutfitName(name)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end
    
    MyAddonDB.outfits = MyAddonDB.outfits or {}
    MyAddonDB.outfits[name] = core.DeepCopy(set)
    core.UpdateListeners("outfits")
    return true
end

core.DeleteOutfit = function(name)
    assert(name and MyAddonDB.outfits[name])

    MyAddonDB.outfits[name] = nil
    core.UpdateListeners("outfits")
end

core.RenameOutfit = function(oldName, newName) -- or oldName, newName ...    
    assert(oldName and MyAddonDB.outfits[oldName] and newName)

    local invalidReason = core.IsInvalidOutfitName(newName)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end

    MyAddonDB.outfits = MyAddonDB.outfits or {}
    MyAddonDB.outfits[newName] = MyAddonDB.outfits[oldName]
    MyAddonDB.outfits[oldName] = nil
    core.UpdateListeners("outfits")
    return true
end

core.SaveOutfit = function(name, set)
    assert(name and set and MyAddonDB.outfits[name])
    --AM("save", name, set)
    MyAddonDB.outfits[name] = set
    core.UpdateListeners("outfits")
    return true
end

--[[
wo speichern? MyAddonDB.Outfits ? MyAddonDB.Charname.Outfits?
Einblendbare Outfit "bar", die an DressUpModel und PreviewModel des Addons angezeigt wird?
Prinzipiell ist nicht ausgeschlossen, dass beides gleichzeitig angezeigt wird, daher braucht jedes model jeweils eine eigene bar?
Woher wissen wir, was am model angelegt ist?
    - Bei Previewmodel haben wir currentchanges und aktuelles gear bzw. aktueller Skin
    - Bei DressUpModel müssten TryOn, Undress, Reset? hooken oder überschreiben, um aktuellen Zustand zu wissen?
        - Unterschied zwischen DressUpModel Hooks und OnItemClick weiter modifizieren?
    - Idee: TryOn, OnShow? etc. modifizieren tabelle in DressUpModel, welche aktuellen Zustand halten soll
Aktuellen Zustand kann man speichern mit der Outfitbar. Wie? Braucht wohl wieder volles dropdown mit outfits (auswählen, overwrite?, (re)name, delete), save button?!

Der ganzen kram als Funktion schreiben, die einen übergebenen DressUpModel Frame "upgradet"?!
    - Gibt zB noch den AuctionHouse DressUpFrame, evtl. noch weitere?
- Undress Button, Print Button (für Debug oder auch permanent? evtl zu Link Outfit ändern?)
Wenn mans richtig fancy will, historie einführen (imo etwas für nen späteren release)
]]

-- Waffenslot logik (bzgl offhand/ohweapon, welche waffe tuen wir wann in welche hand)
-- Waffenanzeige
-- Wie Verzauberungen im Itemlink (und auf dem Gear) handlen?
-- Schonmal Undress Button, Print Button (für Debug oder auch permanent? evtl zu Link Outfit ändern?)?
-- Outfit Bar (vermutlich eine pro Model? Dabei hängt funktionalität ab, ob es ein einfaches DressUpModel ist, oder das Transmog Preview Model)

core.equipLocToInventorySlot = {
	INVTYPE_HEAD = "HeadSlot",
	INVTYPE_SHOULDER = "ShoulderSlot",
	INVTYPE_BODY = "ShirtSlot",
	INVTYPE_CHEST = "ChestSlot",
    INVTYPE_ROBE = "ChestSlot",
	INVTYPE_WAIST = "WaistSlot",
	INVTYPE_LEGS = "LegsSlot",
	INVTYPE_FEET = "FeetSlot",
	INVTYPE_WRIST = "WristSlot",
	INVTYPE_HAND = "HandsSlot",
	INVTYPE_WEAPONMAINHAND = "MainHandSlot",
	INVTYPE_WEAPONOFFHAND = "ShieldHandWeaponSlot", --"SecondaryHandSlot",
	INVTYPE_SHIELD = "OffHandSlot", --"SecondaryHandSlot",
	INVTYPE_HOLDABLE = "OffHandSlot", --"SecondaryHandSlot",
    INVTYPE_RANGED = "RangedSlot",
	INVTYPE_RANGEDRIGHT = "RangedSlot",
	INVTYPE_THROWN = "RangedSlot",
	INVTYPE_CLOAK = "BackSlot",
	INVTYPE_TABARD = "TabardSlot",
    -- INVTYPE_WEAPON, INVTYPE_2HWEAPON ? need special handling?
}

-- TODO: wenns funktioniert, nach util packen?
core.GetItemIDFromLink = function(itemLink)
    if type(itemLink) == "number" then
        return itemLink
    end

    itemLink = strmatch(itemLink, "item:(%d+)")
    return itemLink and tonumber(itemLink)
end

core.GetEnchantIDFromLink = function(itemLink)
    if type(itemLink) == "number" then
        return nil
    end

    itemLink = strmatch(itemLink, "item:%d+:(%d+)")
    return itemLink and tonumber(itemLink) or nil
end


local items = {}

DressUpModel.GetSlotInfo = function(self, itemSlot)
	assert(core.slotToID[itemSlot], "Invalid slot in DressUpModel.GetSlotInfo")

    return items[itemSlot]
end

DressUpModel.GetAll = function(self)
    return core.DeepCopy(items)
end

-- We allow setting slots to 1 (hidden) now. The original TryOn just ignores those. TODO: modify OnItemClick to allow setting hidden items
DressUpModel.SetSlot = function(self, itemSlot, itemID, silent)
	assert(core.slotToID[itemSlot], "Invalid slot in DressUpModel.SetSlot")
    if itemID and type(itemID) ~= "number" then
        itemID = core.GetItemIDFromLink(itemID)
    end
    assert(itemID == nil or itemID == 1 or core.GetItemData(itemID) ~= nil, "Invalid itemID in DressUpModel.SetSlot")

    if itemID then
        if itemSlot == "OffHandSlot" then
            items["ShieldHandWeaponSlot"] = nil
        elseif itemSlot == "ShieldHandWeaponSlot" then
            items["OffHandSlot"] = nil
        end
    end

    -- if items[itemSlot] == itemID then return end -- no changes (lastWeaponSlot might have changed. could be included here too ofc)

    items[itemSlot] = itemID
    if not silent then
        core.UpdateListeners("dressUpModel") -- Wieder so? Wird nicht aufgerufen bei tryon, wenn model nicht schon angezeigt wird, weil es zu diesem Zeitpunkt versteckt ist?
    end
end

DressUpModel.SetAll = function(self, set)
	assert(type(set) == "table")
	for slot, itemID in pairs(set) do
		assert(core.slotToID[slot])
		assert(type(itemID) == "number")
	end

	for _, slot in pairs(core.itemSlots) do
		self:SetSlot(slot, set[slot], true)
	end
	
	UpdateListeners("dressUpModel")
end

local weaponSlots = { MainHandSlot = true, ShieldHandWeaponSlot = true, OffHandSlot = true, RangedSlot = true, SecondaryHandSlot = true }
core.IsWeaponSlot = function(itemSlot)
    return weaponSlots[itemSlot]
end

local TryOnOld = DressUpModel.TryOn
DressUpModel.TryOnOld = DressUpModel.TryOn
DressUpModel.TryOn = function(self, itemLink, itemSlot)
    local itemID = core.GetItemIDFromLink(itemLink)
    local enchantID = core.GetEnchantIDFromLink(itemLink)
    print("enchant", enchantID)
    if not itemID then
        print("TryOn was called with invalid itemLink.")
        return
    end

    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemID)
    if not itemEquipLoc then
        core.QueryItem(itemID)        
        -- oder automatisch anlegen onItemInfo? Doof, wenn wir grade locked out sind und nach ewigkeiten nen random TryOn aufgerufen wird
        -- Ist zwar abfangbar mit maxTime, Model lnicht ausgeblendet und Slot nicht anders überschrieben in der Zeit, aber trotzdem unentschlossen                                                                                  
        print("Could not preview " .. itemLink .. ", because it has not been cached yet. Try again after a few seconds.")
        return
    end

    itemSlot = itemSlot or core.equipLocToInventorySlot[itemEquipLoc]
    if not itemSlot then
        if itemEquipLoc == "INVTYPE_WEAPON" then
            if self.lastWeaponSlot == "MainHandSlot" and core.CanDualWield() then
                itemSlot = "ShieldHandWeaponSlot"
            else
                itemSlot = "MainHandSlot"
            end
        end
        if itemEquipLoc == "INVTYPE_2HWEAPON" then
            if self.lastWeaponSlot == "MainHandSlot" and core.HasTitanGrip() and core.CanDualWield() then
                itemSlot = "ShieldHandWeaponSlot"
            else
                itemSlot = "MainHandSlot"
            end
        end
    end
                
    if not itemSlot then
        print("Could not find proper Inventory Slot for " .. itemLink .. ".")
        return
    end

    if core.IsWeaponSlot(itemSlot) then
        self.lastWeaponSlot = itemSlot
    end

    print("tryOn", itemID, itemEquipLoc, inventorySlot)
    self:SetSlot(itemSlot, enchantID and ("item:" .. itemID .. ":" .. enchantID) or itemID)
end

local UndressOld = DressUpModel.Undress
DressUpModel.Undress = function(self)
    self:SetAll({})
end

local DressOld = DressUpModel.Dress
DressUpModel.Dress = function(self)
    local skin = core.GetActiveSkin()

    local shownItems = {}
	for _, slot in pairs(core.itemSlots) do
        local itemID, visualID, skinVisualID = core.TransmogGetSlotInfo(slot, skin)
        local shown = (skin and skinVisualID) or visualID or itemID or nil

        if shown == 0 then
            shown = itemID or nil
        end
        shownItems[slot] = shown
    end

    self:SetAll(shownItems)
end

-- TODO: Weapon Display Logic. Allow only what we can display? Problem is, that Transmog allows more than we can display anyway, so we can't show what we wear in some cases
-- Also what do we do with outfits, we created on dualwield char or titangrip spec, that we are now unable to display ...
DressUpModel.update = function(self)
    local debug = {}
    for slot, itemID in pairs(items) do
        if core.IsWeaponSlot(slot) then
            debug[slot] = GetItemInfo(itemID)
        end
    end
    core.am(debug)

    UndressOld(self)
    for slot, itemID in pairs(items) do
        if not core.IsWeaponSlot(slot) then
            TryOnOld(self, itemID)
        end
    end

    local mh, ranged = items["MainHandSlot"], items["RangedSlot"]
    local oh = items["OffHandSlot"] or items["ShieldHandWeaponSlot"]

    if self.lastWeaponSlot == "RangedSlot" then
        if ranged and ranged > 1 then
            TryOnOld(self, ranged)
        end
    else
        core.ShowMeleeWeapons(self, mh, oh)
    end

    -- If we want that blizzlike item list frame
    if DressUpFrame.itemListFrame then
        for _, slot in pairs(core.itemSlots) do
            local _, link, _, _, _, _, _, _, _, texture = GetItemInfo(items[slot] or 1)
            DressUpFrame.itemListFrame.slotFrames[slot]:SetText(items[slot] == 1 and "      " .. core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex) or
                                                                items[slot] and (link and (core.GetTextureString(texture, 16) .. " " .. core.LinkToColoredString(link)) or items[slot]) or
                                                                "      " .. core.GetColoredString("(" .. core.SLOT_NAMES[slot] .. ")", core.greyTextColor.hex))
        end
    end
end
core.RegisterListener("dressUpModel", DressUpModel)

-- TODO: is this the way to do this? basically have to do Dress() OnShow, but that overwrites the TryOn item, which triggered the OnShow in the first place
    -- Another way could be to call show (maybe with tryonold), dress and update from SetSlot, if the model is not shown?
DressUpModel:HookScript("OnShow", function(self)
    tmp = core.DeepCopy(items)
    self:Dress()
    for slot, itemID in pairs(tmp) do
        self:SetSlot(slot, itemID, true)
    end
    self:update()
end)

DressUpModel:HookScript("OnHide", function(self)
    items = {}
end)


------------------------------------------------------------------


DressUpFrame.undressButton = core.CreateMeATextButton(DressUpFrame, 80, 22, core.UNDRESS)
DressUpFrame.undressButton:SetPoint("BOTTOMRIGHT", DressUpFrameResetButton, "BOTTOMLEFT")
DressUpFrame.undressButton:SetScript("OnClick", function(self)
    DressUpModel:Undress()
end)

DressUpFrame.printButton = core.CreateMeATextButton(DressUpFrame, 80, 22, core.PRINT)
DressUpFrame.printButton:SetPoint("BOTTOMRIGHT", DressUpFrame.undressButton, "BOTTOMLEFT")
DressUpFrame.printButton:SetScript("OnClick", function(self)
    for slot, itemID in pairs(items) do
        local _, itemLink = GetItemInfo(itemID)
        print(core.SLOT_NAMES[slot], ": ", itemLink or (itemID == 1 and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)) or itemID)
    end
end)

-- blizzlike item list frame. at least usefull for debugging atm
DressUpFrame.itemListFrame = CreateFrame("Frame", "ItemListFrame", DressUpFrame)
DressUpFrame.itemListFrame:SetSize(370, 370)
DressUpFrame.itemListFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPRIGHT", -40, -30)
DressUpFrame.itemListFrame:SetBackdrop(BACKDROP_TOAST_12_12)
DressUpFrame.itemListFrame:EnableMouse(true)
DressUpFrame.itemListFrame:SetToplevel(true)
-- UIPanelWindows["DressUpFrame"].width = DressUpFrame:GetWidth() + 200
DressUpFrame.itemListFrame:Hide()

DressUpFrame.itemListFrame.slotFrames = {}
for i, slot in pairs(core.itemSlots) do
    DressUpFrame.itemListFrame.slotFrames[slot] = DressUpFrame.itemListFrame:CreateFontString()
    DressUpFrame.itemListFrame.slotFrames[slot]:SetFontObject(GameFontWhiteSmall)
    DressUpFrame.itemListFrame.slotFrames[slot]:SetJustifyH("LEFT")
    DressUpFrame.itemListFrame.slotFrames[slot]:SetJustifyV("MIDDLE")
    if slot == "HeadSlot" then        
        DressUpFrame.itemListFrame.slotFrames[slot]:SetPoint("TOPLEFT", 10, -20)
    else        
        DressUpFrame.itemListFrame.slotFrames[slot]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotFrames[core.itemSlots[i - 1]], "BOTTOMLEFT", 0, -10)
    end
    DressUpFrame.itemListFrame.slotFrames[slot]:SetText(slot)
end

local defaultWidth = DressUpFrame:GetWidth()
DressUpFrame.itemListFrame:SetScript("OnShow", function(self)    
    -- UIPanelWindows[FrameName].width apparently is only used once at start to initialize panel frame attributes
    -- To change them later on, we have to set the frame attribute width directly and then call UpdateUIPanelPositions(currentFrame)
    DressUpFrame:SetAttribute("UIPanelLayout-" .. "width", defaultWidth + self:GetWidth() - 20)
	UpdateUIPanelPositions(DressUpFrame)
    self:Raise()
	PlaySound("igCharacterInfoOpen")
end)

DressUpFrame.itemListFrame:SetScript("OnHide", function(self)   
    DressUpFrame:SetAttribute("UIPanelLayout-" .. "width", defaultWidth)
	UpdateUIPanelPositions(DressUpFrame)
	PlaySound("igCharacterInfoClose")
end)

DressUpFrame.listButton = core.CreateMeATextButton(DressUpFrame, 22, 22, "L")
DressUpFrame.listButton:SetPoint("TOPRIGHT", -44, -44)
DressUpFrame.listButton:SetScript("OnClick", function(self)
    core.SetShown(self:GetParent().itemListFrame, not self:GetParent().itemListFrame:IsShown())
end)