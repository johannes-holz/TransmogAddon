local folder, core = ...

local BAR_COLOR = { r = 20 / 255, g = 0.7, b = 8 / 255 } --30 / 255, 1, 12 / 255
local BAR_WIDTH, BAR_HEIGHT = 120, 12

local UnlockedBar_OnValueChange = function(self, value)
    local min, max = self:GetMinMaxValues()
    self.text:SetText(value .. " / " .. max)
end

local UnlockedBar_OnMouseDown = function(self, button)
    print("bar click")
end

local Bar_SetMinMaxValues = function(self, min, max)
    self:SetMinMaxValuesOld(min, max)
    local value = self:GetValue()
    self:GetScript("OnValueChanged")(self, value)
end

core.CreateUnlockedBar = function(parent, slot)
    local bar  = CreateFrame("StatusBar", folder .. "UnlockedStatusBar" .. slot, parent)
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
    -- bar:SetPoint("CENTER", itemCollectionFrame.pageDownButton, "RIGHT", itemCollectionFrame.displayFrame:GetWidth() / 4, 0)
    -- bar:SetPoint("LEFT", itemCollectionFrame.pageUpButton, "RIGHT", 10, 0)
    bar:SetOrientation("HORIZONTAL")
    bar:SetStatusBarTexture("interface/targetingframe/ui-statusbar.blp", "BACKGROUND")
    bar:SetStatusBarColor(BAR_COLOR.r, BAR_COLOR.g, BAR_COLOR.b)
    bar:EnableMouse()

    bar.slot = slot

    bar.border = bar:CreateTexture(nil, "BORDER")
    bar.border:SetTexture("interface/tooltips/ui-statusbar-border.blp")
    bar.border:SetPoint("BOTTOMLEFT", -2, -2)
    bar.border:SetPoint("TOPRIGHT", 2, 2)

    bar.text = bar:CreateFontString()
    bar.text:SetFontObject(GameFontWhiteSmall)
    bar.text:SetPoint("CENTER")
    bar.text:SetJustifyH("CENTER")
    bar.text:SetJustifyV("MIDDLE")

    bar:SetScript("OnValueChanged", UnlockedBar_OnValueChange)

    bar.SetMinMaxValuesOld = bar.SetMinMaxValues
    bar.SetMinMaxValues = Bar_SetMinMaxValues

    bar:SetScript("OnMouseDown", UnlockedBar_OnMouseDown)

    return bar
end

core.ComputeSlotUnlocks = function()
    local withNames = nil
    local searchTerm = nil

    local unlocks = {}

    -- TODO: using invType iterator and sum up results would avoid counting overlap for the weaponSlots
    for _, slot in pairs(core.itemSlots) do
        local itemUnlocked = {}
        local visualUnlocked = {}    
        local displayGroups = {}

        local unlockedCount, totalCount = 0, 0
        local itemUnlockCount, itemTotalCount = 0, 0
        for itemID in core.ItemIterator(slot) do
            local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)
            itemTotalCount = itemTotalCount + 1
            itemUnlockCount = itemUnlockCount + ((unlocked == 1) and 1 or 0)
                    
            itemUnlocked[itemID] = unlocked
            visualUnlocked[itemID] = unlocked	-- this will track whether the visual is unlocked by an item that fits the current selection

            if displayGroup == 0 or not displayGroups[displayGroup] then
                totalCount = totalCount + 1
                
                if displayGroup == 0 and unlocked == 1 then
                    unlockedCount = unlockedCount + 1 -- counting the unlocked visuals without display group
                end
                
                if displayGroup ~= 0 then
                    displayGroups[displayGroup] = {} -- temporary displayGroups that only contain items that fit the current selection
                end
            end

            if displayGroups[displayGroup] then
                table.insert(displayGroups[displayGroup], itemID)
            end
        end
        
        for displayID, items in pairs(displayGroups) do
            local unlocked = 0
            for _, itemID in pairs(items) do
                if itemUnlocked[itemID] == 1 then
                    unlocked = 1
                end
            end
            for _, itemID in pairs(items) do
                visualUnlocked[itemID] = unlocked
            end
            if unlocked == 1 then
                unlockedCount = unlockedCount + 1 -- count the unlocked visuals with display group
            end
        end
        
        unlocks[slot] = {vUnlocked = unlockedCount, vTotal = totalCount, cUnlocked = itemUnlockCount, cTotal = itemTotalCount}
    end

    core.am(unlocks)
    return unlocks
end



--- temp test ---
-- local bar = core.CreateUnlockedBar(core.itemCollectionFrame, "HeadSlot")
-- bar:SetPoint("RIGHT", bar:GetParent(), "LEFT") 
-- bar:Show()

local COLS = 4
local SPACING_HOR, SPACING_VERT = 30, 40
local SPACING_LEFT, SPACING_TOP = 40, 120

core.CreateUnlocksOverviewFrame = function(parent)
    local frame = CreateFrame("Frame", folder .. "UnlocksOverviewFrame", parent)    
    -- frame:SetSize(width, height)
    -- frame:SetAllPoints()
    frame:SetSize(600, 400)
    frame:SetPoint("BOTTOM", parent, "TOP")
    
	frame:SetBackdrop(BACKDROP_Test_1)
	frame:SetBackdropBorderColor(0.675, 0.5, 0.125, 1)
	frame:SetBackdropColor(0.375, 0.375, 0.375, 1)

    frame.bars = {}
    for i, slot in ipairs(core.itemSlots) do
        local bar = core.CreateUnlockedBar(frame, slot)
        frame.bars[slot] = bar

        bar.title = bar:CreateFontString()
        bar.title:SetFontObject(GameFontNormal)
        bar.title:SetPoint("CENTER", 0, 20)
        bar.title:SetJustifyH("CENTER")
        bar.title:SetJustifyV("MIDDLE")
        bar.title:SetText(core.SLOT_NAMES[slot])


        if (i - 1) % COLS == 0 then
            if i == 1 then
                bar:SetPoint("TOPLEFT", SPACING_LEFT, -SPACING_TOP)
            else
                bar:SetPoint("TOPLEFT", frame.bars[core.itemSlots[i - COLS]], "BOTTOMLEFT", 0, -SPACING_VERT)
            end
        else
            bar:SetPoint("TOPLEFT", frame.bars[core.itemSlots[i - 1]], "TOPRIGHT", SPACING_HOR, 0)
        end
    end

    frame.bars.MainHandSlot:SetPoint("TOPLEFT", frame.bars.WaistSlot, "BOTTOMLEFT", 0, -SPACING_VERT)
    frame.bars.ShieldHandWeaponSlot:SetPoint("TOPLEFT", frame.bars.MainHandSlot, "TOPRIGHT", SPACING_HOR, 0)
    frame.bars.OffHandSlot:SetPoint("TOPLEFT", frame.bars.ShieldHandWeaponSlot, "TOPRIGHT", SPACING_HOR, 0)
    frame.bars.RangedSlot:SetPoint("TOPLEFT", frame.bars.OffHandSlot, "TOPRIGHT", SPACING_HOR, 0)
    if not core.HasShieldHandWeaponSlot() then
        frame.bars.ShieldHandWeaponSlot:Hide()
        frame.bars.OffHandSlot:SetPoint("TOPLEFT", frame.bars.MainHandSlot, "TOPRIGHT", SPACING_HOR, 0)
    end
    if not core.HasRangeSlot() then
        frame.bars.RangedSlot:Hide()
    end

    frame.UpdateBars = function(self)
        self.unlocks = core.ComputeSlotUnlocks()

        for _, bar in pairs(self.bars) do
            bar:SetMinMaxValues(0, self.unlocks[bar.slot].vTotal)
            bar:SetValue(self.unlocks[bar.slot].vUnlocked)
        end
    end

    frame.OnShow = function(self)
        self:UpdateBars()
        self:SetSize(core.itemCollectionFrame:GetSize())
    end

    frame:SetScript("OnShow", frame.OnShow)

    frame.update = function(self)
        if not self:IsShown() then return end
        frame:UpdateBars()
    end
    core.RegisterListener("unlocks", frame)

    return frame
end

-- local test = core.CreateUnlocksOverviewFrame(core.itemCollectionFrame)