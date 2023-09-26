local folder, core = ...

--[[
thought dump:
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


-- Hooking at this point would need fixes to interact with other addons, even Blizzard Auction UI already overwrites this.
-- The latter could be fixed by overwriting again on Auction UI's ADDON_LOADED event
-- Probably no need tho, hooking onto DressUpModel seems to work fine
--[==[
DressUpItemLink = function(link, slot)
	if not link or not IsDressableItem(link) then
		return
	end
	if not DressUpFrame:IsShown() then
		ShowUIPanel(DressUpFrame)
		DressUpModel:SetUnit("player")
	end
	DressUpModel:TryOn(link, slot)
end
]==]

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

local items = {}

DressUpModel.GetSlotInfo = function(self, itemSlot)
	assert(core.slotToID[itemSlot], "Invalid slot in DressUpModel.GetSlotInfo")

    return items[itemSlot]
end

DressUpModel.GetAll = function(self)
    return core.DeepCopy(items)
end

-- We allow setting slots to 1 (hidden) now. The original TryOn just ignores these calls anyway.
-- TODO: modify OnItemClick to allow setting hidden items?
-- TODO: How to secure GetItemInfo? 
DressUpModel.SetSlot = function(self, itemSlot, itemID, silent)
	assert(core.slotToID[itemSlot], "Invalid slot in DressUpModel.SetSlot")
    if itemID and type(itemID) ~= "number" then
        itemID = core.GetItemIDFromLink(itemID)
    end
    assert(itemID == nil or itemID == 1 or core.GetItemData(itemID) ~= nil, "Invalid itemID in DressUpModel.SetSlot")

    if itemID then
        -- Only allow Offhand or ShieldHandWeapon?
        if itemSlot == "OffHandSlot" then
            items["ShieldHandWeaponSlot"] = nil
        elseif itemSlot == "ShieldHandWeaponSlot" then
            items["OffHandSlot"] = nil
        end
        -- Only allow melee or ranged Weapons?        
        if itemSlot == "RangedSlot" then
            items["MainHandSlot"] = nil
            items["ShieldHandWeaponSlot"] = nil
            items["OffHandSlot"] = nil
        elseif itemSlot == "MainHandSlot" or itemSlot == "ShieldHandWeaponSlot" or itemSlot == "OffHandSlot"then
            items["RangedSlot"] = nil
        end
        -- Only allow things we can display?
        if itemID > 1 and itemSlot == "ShieldHandWeaponSlot" then
            local _, _, _, _, _, _, itemSubType, _, itemEquipLoc = GetItemInfo(itemID)
            if not itemSubType then -- TODO: Hide this scuffness in data function
                local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
                itemSubType = core.classSubclassToType[class][subClass] -- it's category now, but CanBeTitanGripped accepts either
                itemEquipLoc = core.inventoryTypes[inventoryType]
            end
            if not core.CanDualWield() or (itemEquipLoc == "INVTYPE_2HWEAPON" and not (core.HasTitanGrip() and core.CanBeTitanGripped(itemSubType))) then
                itemID = items[itemSlot]
                UIErrorsFrame:AddMessage(core.CAN_NOT_DRESS_OFFHAND, 1.0, 0.1, 0.1, 1.0)
            end
        end
    end

    -- if items[itemSlot] == itemID then return end -- no changes (lastWeaponSlot might have changed. could be included here too ofc)

    items[itemSlot] = itemID
    if not silent then
        core.UpdateListeners("dressUpModel") -- Wieder so? Wird nicht aufgerufen bei tryon, wenn model nicht schon angezeigt wird, weil es zu diesem Zeitpunkt versteckt ist?
    end

    if itemID and itemID > 1 and not GetItemInfo(itemID) then
        core.FunctionOnItemInfo(itemID, core.UpdateListeners, "dressUpModel")
    end
end

DressUpModel.SetAll = function(self, set)
	assert(type(set) == "table")
	for slot, itemID in pairs(set) do
		assert(core.slotToID[slot])
		assert(type(itemID) == "number")
	end

	local _, class = UnitClass("player")
    if class ~= "HUNTER" then
        if set["MainHandSlot"] or set["ShieldHandWeaponSlot"] or set["OffHandSlot"] then
            set["RangedSlot"] = nil
        end
    else
        if set["RangedSlot"] then
            items["MainHandSlot"] = nil
            items["ShieldHandWeaponSlot"] = nil
            items["OffHandSlot"] = nil
        end
    end
    
    items = {}

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

    print("DressUp", itemLink, itemSlot, itemEquipLoc)

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
        self.lastWeaponSlot = itemSlot -- TODO: Revisit. Should we reset it on equipping sets? prioritize empty slot? etc.
    end

    -- print("tryOn", itemID, itemEquipLoc, inventorySlot)
    self:SetSlot(itemSlot, enchantID and ("item:" .. itemID .. ":" .. enchantID) or itemID)
end

local UndressOld = DressUpModel.Undress
DressUpModel.Undress = function(self)
    self:SetAll({})
end

local GetShownItem = function(slot, skin)   
    local itemID, visualID, skinVisualID = core.TransmogGetSlotInfo(slot, skin)

    local shown = (itemID and skin and skinVisualID) or visualID or itemID or nil
    if shown == 0 then
        shown = itemID or nil
    end
    return shown
end

local DressOld = DressUpModel.Dress
DressUpModel.Dress = function(self)
    local skin = core.GetActiveSkin()

    local shownItems = {}
	for _, slot in pairs(core.itemSlots) do
        shownItems[slot] = GetShownItem(slot, skin)
    end

    self:SetAll(shownItems)
end

-- TODO: Weapon Display Logic. Allow only what we can display? Problem is, that Transmog allows more than we can display anyway, so we can't show what we wear in some cases
-- Also what do we do with outfits, we created on dualwield char or titangrip spec, that we are now unable to display ...
DressUpModel.update = function(self)
    -- local debug = {}
    -- for slot, itemID in pairs(items) do
    --     if core.IsWeaponSlot(slot) then
    --         debug[slot] = GetItemInfo(itemID)
    --     end
    -- end
    -- core.am(debug)

    UndressOld(self)
    for slot, itemID in pairs(items) do
        if not core.IsWeaponSlot(slot) then
            TryOnOld(self, itemID)
        end
    end

    local mh, ranged = items["MainHandSlot"], items["RangedSlot"]
    local oh = items["OffHandSlot"] or items["ShieldHandWeaponSlot"]

    if (not mh and not oh) then -- or self.lastWeaponSlot == "RangedSlot" then -- TODO: not needed here if we only allow melee or ranged. Still using it for toggling 1h equip slot
        if ranged and ranged > 1 then
            TryOnOld(self, ranged)
        end
    else
        core.ShowMeleeWeapons(self, mh, oh)
    end

    -- If we want that blizzlike item list frame
    if DressUpFrame.itemListFrame then
        for _, slot in pairs(core.itemSlots) do
            local itemID = items[slot]
            if itemID and itemID > 1 then
                local texture = GetItemIcon(itemID)
                local _, link = GetItemInfo(itemID)
                -- link = link and core.GetShortenedString(core.LinkToColoredString(link), 42) or nil
                link = link and core.LinkToColoredString(link) or nil
                DressUpFrame.itemListFrame.slotFrames[slot]:SetText(core.GetTextureString(texture, 16) .. " " .. (link or core.LOADING2))
            else
                DressUpFrame.itemListFrame.slotFrames[slot]:SetText("      " .. (itemID == 1 and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
                                                                                            or core.GetColoredString("(" .. core.SLOT_NAMES[slot] .. ")", core.greyTextColor.hex)))
            end
        end
    end
end
core.RegisterListener("dressUpModel", DressUpModel)

-- TODO: is this the way to do this? basically have to do Dress() OnShow, but that overwrites the TryOn item, which triggered the OnShow in the first place
    -- Another way could be to call show (maybe with tryonold), dress and update from SetSlot, if the model is not shown?
DressUpModel:HookScript("OnShow", function(self)
    tmp = core.DeepCopy(items) -- tmp should only contain the item from the TryOn call, that caused Frame to show
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
DressUpFrame.itemListFrame:SetSize(200, 370)
DressUpFrame.itemListFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPRIGHT", -40, -30)
DressUpFrame.itemListFrame:SetBackdrop(BACKDROP_TOAST_12_12)
DressUpFrame.itemListFrame:EnableMouse(true)
DressUpFrame.itemListFrame:SetToplevel(true)
-- UIPanelWindows["DressUpFrame"].width = DressUpFrame:GetWidth() + 200
DressUpFrame.itemListFrame:Hide()

core.CreateSlotListFrame = function(parent, slot)
    local slotFrame = CreateFrame("Button", "SlotList" .. slot .. "Frame", parent)    
    slotFrame.slot = slot

    slotFrame:SetSize(parent:GetWidth() - 20, 20)
    -- slotFrame:SetPoint("Left")
    -- slotFrame:SetPoint("Right")
    slotFrame:EnableMouse(true)

    slotFrame.text = slotFrame:CreateFontString()
    slotFrame.text:SetFontObject(GameFontWhiteSmall)
    slotFrame.text:SetJustifyH("LEFT")
    slotFrame.text:SetJustifyV("MIDDLE")
    slotFrame.text:SetAllPoints()

    slotFrame.SetText = function(self, text)
        self.text:SetText(text or "")
        if GetMouseFocus() == self then
            self:GetScript("OnEnter")(self)
        end
    end

    slotFrame:SetScript("OnClick", function(self, button)
        local itemID = items[self.slot]
        local _, itemLink = GetItemInfo(itemID or 0)
        
        if IsShiftKeyDown() then
			if ChatEdit_InsertLink(itemLink or "") then
				return true
			end
            DressUpModel:SetSlot(self.slot, 1)
            return
        elseif IsControlKeyDown() then
            DressUpModel:SetSlot(self.slot, nil)
            return
        elseif IsAltKeyDown() then
            DressUpModel:SetSlot(self.slot, GetShownItem(self.slot, core.GetActiveSkin()))
            return
        else
            core.ShowItemInWardrobe(itemID, self.slot)
        end
    end)

    slotFrame:SetScript("OnEnter", function(self)
        local itemID = items[self.slot]
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")   
        if itemID and itemID > 1 then     
            GameTooltip:SetHyperlink("item:" .. itemID)
        else
            GameTooltip:SetText((itemID and (core.HIDDEN .. " - ") or "") .. core.SLOT_NAMES[slot])
        end
        GameTooltip:Show()
        for i = 1, 3 do
            _G["ShoppingTooltip" .. i]:Hide()
        end
    end)

    slotFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return slotFrame
end

DressUpFrame.itemListFrame.slotFrames = {}
for i, slot in pairs(core.itemSlots) do
    DressUpFrame.itemListFrame.slotFrames[slot] = core.CreateSlotListFrame(DressUpFrame.itemListFrame, slot)
    if slot == "HeadSlot" then        
        DressUpFrame.itemListFrame.slotFrames[slot]:SetPoint("TOPLEFT", 10, -20)
    else        
        DressUpFrame.itemListFrame.slotFrames[slot]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotFrames[core.itemSlots[i - 1]], "BOTTOMLEFT", 0, -2)
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

DressUpFrame.listButton = core.CreateMeACustomTexButton(DressUpFrame, 28, 28, GetItemIcon(2725), 9/64, 9/64, 54/64, 54/64) -- core.CreateMeATextButton(DressUpFrame, 22, 22, "L")
DressUpFrame.listButton:SetPoint("TOPRIGHT", -44, -40)
DressUpFrame.listButton:SetScript("OnClick", function(self)
    core.SetShown(self:GetParent().itemListFrame, not self:GetParent().itemListFrame:IsShown())
end)