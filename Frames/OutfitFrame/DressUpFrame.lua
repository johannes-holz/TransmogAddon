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

DressUpModel.shadowFormFlamesModel = CreateFrame("PlayerModel", folder .. "DressUpModelShadowModel", DressUpModel)
DressUpModel.shadowFormFlamesModel:SetPoint("Center")
DressUpModel.shadowFormFlamesModel:SetModel("SPELLS/Shadow_Form_Precast.m2")
DressUpModel.shadowFormFlamesModel:SetAlpha(0.6)
DressUpModel.shadowFormFlamesModel:SetAllPoints()
DressUpModel.shadowFormFlamesModel:Hide()

local offTex = "Interface\\Icons\\spell_shadow_shadowform"
local onTex = "Interface\\Icons\\spell_shadow_chilltouch"

DressUpModel.shadowFormButton = core.CreateMeACustomTexButton(DressUpModel, 24, 24, "Interface\\Buttons\\CheckButtonHilight", 9/64, 9/64, 54/64, 54/64)
DressUpModel.shadowFormButton:SetPoint("BOTTOMRIGHT", -5, 5)
DressUpModel.shadowFormButton:SetScript("OnClick", function(self, button)
    DressUpModel:SetShadowForm(not DressUpModel:GetShadowForm())
    core.PlayButtonSound()
end)
core.SetTooltip2(DressUpModel.shadowFormButton, core.SHADOW_FORM_TOOLTIP_TITLE, 1, 1, 1, nil,
                                                core.SHADOW_FORM_TOOLTIP_TEXT, nil, nil, nil, 1)

-- DressUpModel.testButton = core.CreateCustomCheckButton(DressUpModel, "$parentTestButton", 20, 20)
-- DressUpModel.testButton:SetPoint("BOTTOMRIGHT", -50, 8)
-- DressUpModel.testButton:SetScript("OnClick", function(self, button)
--     print("hi", self:GetChecked())
--     core.PlayButtonSound()
--     DressUpModel:SetShadowForm(not DressUpModel:GetShadowForm())
-- end)
-- core.SetTooltip2(DressUpModel.testButton, core.SHADOW_FORM_TOOLTIP_TITLE, 1, 1, 1, nil,
--                                           core.SHADOW_FORM_TOOLTIP_TEXT, nil, nil, nil, 1)

DressUpModel.SetShadowForm = function(self, form)
    self:SetLight(unpack(form and core.LIGHT.shadowForm or core.LIGHT.default))
    self:SetAlpha(form and 0.75 or 1)
    core.SetShown(self.shadowFormFlamesModel, form)
    self.shadowFormFlamesModel:SetModel("SPELLS/Shadow_Form_Precast.m2")
    local x, y, z = self:GetPosition()
    self.shadowFormFlamesModel:SetPosition(x, y, z + 0.2)
    self.shadowFormEnabled = form
    self.shadowFormButton:SetCustomTexture(form and onTex or offTex)
    -- self.testButton:SetNormalTexture(form and onTex or offTex)
end

DressUpModel.GetShadowForm = function(self)
    return self.shadowFormEnabled
end


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

-- We allow setting slots to 1 (hidden) now. The original TryOn just ignores these calls anyway. Problem with enchants, as there is an enchant with ID=1 :)
-- Item info should not be needed at this point: We can check itemType for OH stuff with item data and we just have to call a display update on item query
-- TODO: modify OnItemClick to allow setting hidden items?
DressUpModel.SetSlot = function(self, itemSlot, itemID, silent)
    -- print(itemSlot, itemID, silent)
	assert(itemSlot and core.slotToID[itemSlot], "Invalid slot in DressUpModel.SetSlot:" .. (itemSlot or "nil"))
    if itemID and type(itemID) ~= "number" then
        itemID = core.GetItemIDFromLink(itemID)
    end
    if itemID == 0 then
        itemID = nil
    end

    local isEnchantSlot = core.IsEnchantSlot(itemSlot)
    local isValidEnchant = true -- TODO: check whether this is a weapon enchant?

    assert(itemID == nil or itemID == 1 or ((isEnchantSlot and isValidEnchant) or core.GetItemData(itemID) ~= nil), "Invalid itemID in DressUpModel.SetSlot")

    if not isEnchantSlot and itemID then
        local itemSubType, itemEquipLoc
        if itemID > 1 then
            local _, _, _, _, _, _, subType, _, equipLoc = GetItemInfo(itemID)
            if not subType then -- TODO: Hide this scuffness in data function?
                local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
                itemSubType = class and core.classSubclassToType[class][subClass] -- contains categories (type + subtype) now, but CanBeTitanGripped accepts either
                itemEquipLoc = inventoryType and core.inventoryTypes[inventoryType]
            else
                itemSubType, itemEquipLoc = subType, equipLoc
            end
            local equipLocID = core.inventoryTypeToID[itemEquipLoc]
            -- Wrong slot+item combination might arise, if we implement slot click preview, e.g. mh has oh enchant and we try to preview that in mh
            -- assert(equipLocID and core.slotItemTypes[itemSlot][equipLocID], "Incompatible item and slot in DressUpModel.SetSlot")
            if not (equipLocID and core.slotItemTypes[itemSlot][equipLocID]) then
                UIErrorsFrame:AddMessage("Can not preview this item in this slot.", 1.0, 0.1, 0.1, 1.0)
                return
            end
        end

        -- Only allow Offhand or ShieldHandWeapon?
        if itemSlot == "OffHandSlot" then
            items["ShieldHandWeaponSlot"] = nil
        elseif itemSlot == "ShieldHandWeaponSlot" then -- TODO: or only clear when we can preview it?
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
        -- If we allow OH-only weapons for non dual wielders, we need to clear their OH when setting MH
        if itemSlot == "MainHandSlot" and itemID > 1 and not core.CanDualWield() then
            items["ShieldHandWeaponSlot"] = nil
        end
        -- Only allow dualwield things we can display?
        if itemSlot == "ShieldHandWeaponSlot" and itemID > 1 then
            if not itemSubType or (not core.CanDualWield() or (itemEquipLoc == "INVTYPE_2HWEAPON" and not (core.HasTitanGrip() and core.CanBeTitanGripped(itemSubType)))) then
                -- Allow OH-only weapons so non-dualwielders can still preview, like the original DressUpModel does?
                if itemEquipLoc == "INVTYPE_WEAPONOFFHAND" then
                    items["MainHandSlot"] = nil
                else
                    itemID = items[itemSlot] -- or just return? if we return instead and dont update view, we need to do this check before we do any other changes to items
                    UIErrorsFrame:AddMessage(core.CAN_NOT_DRESS_OFFHAND, 1.0, 0.1, 0.1, 1.0)
                end
                -- Should we allow setting these freely instead and then check in Dress instead what we can display + indicate somehow if we cant display offhand?
                -- Otherwise kinda cringe behaviour for especially enhas and furies with different dual spec?
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
    for _, slot in pairs(core.enchantSlots) do 
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
    local itemID = core.GetRecipeInfo(itemLink) or core.GetItemIDFromLink(itemLink)
    local enchantID = core.GetEnchantIDFromLink(itemLink)
    
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

    -- print("DressUp", itemLink, itemSlot, itemEquipLoc, itemID, enchantID)

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
        -- print("Could not find proper Inventory Slot for " .. itemLink .. ". Maybe it is an invisible inventory item like rings or trinkets.")
        return
    end

    if core.IsWeaponSlot(itemSlot) then
        self.lastWeaponSlot = itemSlot -- TODO: Revisit. Should we reset it on equipping sets? prioritize empty slot? etc.
    end

    -- print("tryOn", itemID, itemEquipLoc, inventorySlot)
    self:SetSlot(itemSlot, itemID)
    if enchantID and (itemSlot == "MainHandSlot") then
        self:SetSlot("MainHandEnchantSlot", enchantID)
    end
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
    -- TODO: new function for this or allow enchants in GetShownItem?
    local mhEnchant = core.GetInventoryEnchantID("player", 16)
    local ohEnchant = core.GetInventoryEnchantID("player", 17)
    local oh = GetShownItem("ShieldHandWeaponSlot")

    -- print("DressUpModel mhEnchant, ohEnchant, oh", mhEnchant, ohEnchant, oh)

    shownItems["MainHandEnchantSlot"] = mhEnchant
    shownItems["SecondaryHandEnchantSlot"] = ohEnchant

    self:SetAll(shownItems)
end

-- Normally SetUnit on e.g. "target", sets DressUpModel to use target model and currently visible items
-- But since we have no reliable way to know what those items are (target might be opposing faction or not in range), we can't have that. Allow changing unit, but show our current item state
-- Maybe implement "steal look" button in InspectFrame
local SetUnitOld = DressUpModel.SetUnit
DressUpModel.SetUnit = function(self, unit)
    SetUnitOld(self, unit)
    self:update()
end

local SetCreatureOld = DressUpModel.SetCreature
DressUpModel.SetCreature = function(self, creatureID)
    SetCreatureOld(self, creatureID)
    self:update()
end

-- TODO: Weapon Display Logic. Allow only what we can display? Transmog allows more than what we can display anyway, so we can't even show what we wear in some cases
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
        if not core.IsWeaponSlot(slot) and not core.IsEnchantSlot(slot) then
            TryOnOld(self, itemID)
        end
    end

    local mh, ranged = items["MainHandSlot"], items["RangedSlot"]
    local oh = items["OffHandSlot"] or items["ShieldHandWeaponSlot"]
    local mhEnchant, ohEnchant = items["MainHandEnchantSlot"], items["SecondaryHandEnchantSlot"]

    mh = (mh and mh > 1 and mhEnchant and "item:" .. mh .. ":" .. mhEnchant) or mh
    oh = (oh and oh > 1 and ohEnchant and "item:" .. oh .. ":" .. ohEnchant) or oh

    if (not mh and not oh) then -- or self.lastWeaponSlot == "RangedSlot" then -- TODO: not needed here if we only allow melee or ranged. Still using it for toggling 1h equip slot
        if ranged and ranged > 1 then
            TryOnOld(self, ranged)
        end
    else
        core.ShowMeleeWeapons(self, mh, oh)
    end

    -- If we want that blizzlike item list frame
    if DressUpFrame.itemListFrame then
        for _, slot in pairs(core.allSlots) do
            local itemID = items[slot]
            if itemID and itemID > 1 then
                if core.IsEnchantSlot(slot) then
                    local name, _, tex = core.GetEnchantInfo(itemID)
                    DressUpFrame.itemListFrame.slotButtons[slot]:SetText("      " .. (name and (core.GetTextureString(tex) .. " " .. NORMAL_FONT_COLOR_CODE .. name .. FONT_COLOR_CODE_CLOSE) or "unknown enchant localize me")) -- core.GetTextureString(texture, 16) .. " " .. (link or core.LOADING2))
                else
                    local texture = GetItemIcon(itemID)
                    local _, link = GetItemInfo(itemID)
                    -- link = link and core.GetShortenedString(core.LinkToColoredString(link), 42) or nil
                    link = link and core.LinkToColoredString(link) or nil
                    DressUpFrame.itemListFrame.slotButtons[slot]:SetText(core.GetTextureString(texture, 16) .. " " .. (link or core.LOADING2))
                end
            else
                DressUpFrame.itemListFrame.slotButtons[slot]:SetText("      " .. (itemID == 1 and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
                                                                                            or core.GetColoredString("(" .. core.SLOT_NAMES[slot] .. ")", core.greyTextColor.hex)))
            end
        end
    end
end
core.RegisterListener("dressUpModel", DressUpModel)

-- TODO: is this the way to do this? basically have to do Dress() OnShow, but that overwrites the TryOn item, which triggered the OnShow in the first place
    -- Another way could be to call show (maybe with tryonold), dress and update from SetSlot, if the model is not shown?
DressUpModel:HookScript("OnShow", function(self)
    local tmp = core.DeepCopy(items) -- if we clear items on hide, tmp only contains the item from the DressUpItemLink call
    self:Dress()
    for slot, itemID in pairs(tmp) do
        self:SetSlot(slot, itemID, true)
    end
    self:update()    
    core.SetShown(DressUpFrame.itemListFrame, TransmoggyDB.ShowItemListFrame)
    -- self:SetShadowForm(self:GetShadowForm()) -- Alpha gets overwritten, if we do not delay this -.-
    core.MyWaitFunction(0.01, self.SetShadowForm, self, self:GetShadowForm())
end)

DressUpModel:HookScript("OnHide", function(self)
    items = {} -- TODO: make optional if we wanna reset our model or remember our last state, so we dont loose changes on accident. Not resetting can be confusing tho
end)


------------------------------------------------------------------


DressUpFrame.undressButton = core.CreateMeATextButton(DressUpFrame, 80, 22, core.UNDRESS)
DressUpFrame.undressButton:SetPoint("BOTTOMRIGHT", DressUpFrameResetButton, "BOTTOMLEFT")
DressUpFrame.undressButton:SetScript("OnClick", function(self)
    DressUpModel:Undress()
    core.PlayButtonSound()
end)

DressUpFrame.printButton = core.CreateMeATextButton(DressUpFrame, 80, 22, core.SHARE)
DressUpFrame.printButton:SetPoint("BOTTOMRIGHT", DressUpFrame.undressButton, "BOTTOMLEFT")
DressUpFrame.printButton:SetScript("OnClick", function(self)
    local link = core.API.EncodeOutfitLink(core.ToApiSet(items, true)) -- , "I bims, 1 Outfit. Now with enchants!")

    -- core.am("Input:", core.ToApiSet(items, true))
    -- core.am("Decoded:", core.API.DecodeOutfitLink(link))
    -- link = "\124cffaa00ff\124Houtfit:0:0:0:0:0:0:0:0:1:0:0:0:0:0:0\124h[Transmog Outfit]\124h\124r"
    -- link = "\124cffaa00ff\124Houtfit:0:0:0:0:0:0:0:0:1:0:0:0:0:0:0\124h[Transmog Outfit uwu " .. core.GetTextureString("Interface/Buttons/UI-CheckBox-Check") .. "]\124h\124r"
    -- link = "\124cffaa00ff\124Houtfit:0" ..core.GetTextureString("Interface/Buttons/UI-CheckBox-Check") .. ":0:0:0:0:0:0:0:1:0:0:0:0:0:0\124h[Transmog Outfit]\124h\124r"
    -- print(link)

    local chatFrame = SELECTED_CHAT_FRAME or ChatFrame1
    local editBox = _G[chatFrame:GetName() .. "EditBox"]
    editBox:SetFocus()
    ChatEdit_InsertLink(link)
    core.PlayButtonSound()
end)

-- List of current items on the model. TODO: nicer background, Button Hover Texture?, Modifier Click explanation
DressUpFrame.itemListFrame = CreateFrame("Frame", "ItemListFrame", DressUpFrame)
DressUpFrame.itemListFrame:SetSize(200, 400)
DressUpFrame.itemListFrame:SetPoint("TOPLEFT", DressUpFrame, "TOPRIGHT", -40, -30)
DressUpFrame.itemListFrame:SetBackdrop(core.BACKDROP_ITEM_LIST)
DressUpFrame.itemListFrame:SetBackdropColor(0.125, 0.125, 0.25, 1)
DressUpFrame.itemListFrame:EnableMouse(true)
DressUpFrame.itemListFrame:SetToplevel(true)

local SlotListButton_SetText = function(self, text)
    self.text:SetText(text or "")
    if GetMouseFocus() == self then
        self:GetScript("OnEnter")(self)
    end
end

local SlotListButton_OnClick = function(self, button)
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
end

local SlotListButton_OnEnter = function(self)
    local itemID = items[self.slot]
    
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")   
    if itemID and itemID > 1 then        
        if core.IsEnchantSlot(self.slot) then
            local spellID = core.GetEnchantSpellID(itemID)
            GameTooltip:SetHyperlink("enchant:" .. spellID) -- Do we really want that ugly enchant tooltip tho?
        else
            GameTooltip:SetHyperlink("item:" .. itemID)
        end
    else
        GameTooltip:SetText((itemID and (core.HIDDEN .. " - ") or "") .. core.SLOT_NAMES[self.slot])
    end
    GameTooltip:Show()
    for i = 1, 3 do
        _G["ShoppingTooltip" .. i]:Hide()
    end
end

local SlotListButton_OnLeave = function(self)
    GameTooltip:Hide()
end

core.CreateSlotListButton = function(parent, slot)
    local slotButton = CreateFrame("Button", "SlotList" .. slot .. "Button", parent)    
    slotButton.slot = slot

    slotButton:SetSize(parent:GetWidth() - 20, 20)
    -- slotButton:SetPoint("Left")
    -- slotButton:SetPoint("Right")
    slotButton:EnableMouse(true)

    slotButton.text = slotButton:CreateFontString()
    slotButton.text:SetFontObject(GameFontWhiteSmall)
    slotButton.text:SetJustifyH("LEFT")
    slotButton.text:SetJustifyV("MIDDLE")
    slotButton.text:SetPoint("LEFT")
    slotButton.text:SetPoint("RIGHT")
    slotButton.text:SetHeight(14)

    slotButton.SetText = SlotListButton_SetText

    slotButton:SetScript("OnClick", SlotListButton_OnClick)

    slotButton:SetScript("OnEnter", SlotListButton_OnEnter)

    slotButton:SetScript("OnLeave", SlotListButton_OnLeave)

    return slotButton
end

DressUpFrame.itemListFrame.slotButtons = {}

for i, slot in pairs(core.itemSlots) do
    DressUpFrame.itemListFrame.slotButtons[slot] = core.CreateSlotListButton(DressUpFrame.itemListFrame, slot)
    if slot == "HeadSlot" then        
        DressUpFrame.itemListFrame.slotButtons[slot]:SetPoint("TOPLEFT", 10, -15)
    else        
        DressUpFrame.itemListFrame.slotButtons[slot]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotButtons[core.itemSlots[i - 1]], "BOTTOMLEFT", 0, -2)
    end
    DressUpFrame.itemListFrame.slotButtons[slot]:SetText(slot)
end

DressUpFrame.itemListFrame.slotButtons["MainHandEnchantSlot"] = core.CreateSlotListButton(DressUpFrame.itemListFrame, "MainHandEnchantSlot")
DressUpFrame.itemListFrame.slotButtons["MainHandEnchantSlot"]:SetText("MainHandEnchantSlot")
DressUpFrame.itemListFrame.slotButtons["MainHandEnchantSlot"]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotButtons["MainHandSlot"], "BOTTOMLEFT", 0, -2)
DressUpFrame.itemListFrame.slotButtons["ShieldHandWeaponSlot"]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotButtons["MainHandEnchantSlot"], "BOTTOMLEFT", 0, -2)

DressUpFrame.itemListFrame.slotButtons["SecondaryHandEnchantSlot"] = core.CreateSlotListButton(DressUpFrame.itemListFrame, "SecondaryHandEnchantSlot")
DressUpFrame.itemListFrame.slotButtons["SecondaryHandEnchantSlot"]:SetText("SecondaryHandEnchantSlot")
DressUpFrame.itemListFrame.slotButtons["SecondaryHandEnchantSlot"]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotButtons["ShieldHandWeaponSlot"], "BOTTOMLEFT", 0, -2)
DressUpFrame.itemListFrame.slotButtons["OffHandSlot"]:SetPoint("TOPLEFT", DressUpFrame.itemListFrame.slotButtons["SecondaryHandEnchantSlot"], "BOTTOMLEFT", 0, -2)

local defaultWidth = DressUpFrame:GetWidth() -- don't think we have to cache this as the uipanel width attribute is different from GetWidth() ?
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
    TransmoggyDB.ShowItemListFrame = not TransmoggyDB.ShowItemListFrame
    core.SetShown(self:GetParent().itemListFrame, TransmoggyDB.ShowItemListFrame) -- not self:GetParent().itemListFrame:IsShown())
end)

