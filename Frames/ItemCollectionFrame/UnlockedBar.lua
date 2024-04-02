local folder, core = ...

local STATUS_BAR_COLOR = { r = 20 / 255, g = 0.7, b = 8 / 255 } --30 / 255, 1, 12 / 255

local UnlockedBar_OnValueChange = function(self, value)
    local min, max = self:GetMinMaxValues()
    self.text:SetText(value .. " / " .. max)
end

local UnlockedBar_OnMouseDown = function(self, button)
    print("bar click")
end

core.CreateUnlockedBar = function(parent, slot)
    local bar  = CreateFrame("StatusBar", folder .. "UnlockedStatusBar" .. slot, parent)
    bar:SetSize(160, 12)
    -- bar:SetPoint("CENTER", itemCollectionFrame.pageDownButton, "RIGHT", itemCollectionFrame.displayFrame:GetWidth() / 4, 0)
    -- bar:SetPoint("LEFT", itemCollectionFrame.pageUpButton, "RIGHT", 10, 0)
    bar:SetOrientation("HORIZONTAL")
    bar:SetStatusBarTexture("interface/targetingframe/ui-statusbar.blp", "BACKGROUND")
    bar:SetStatusBarColor(STATUS_BAR_COLOR.r, STATUS_BAR_COLOR.g, STATUS_BAR_COLOR.b)
    bar:EnableMouse()

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
    bar.SetMinMaxValues = function(self, min, max) -- why does this not trigger OnValue changed!?
        self:SetMinMaxValuesOld(min, max)
        local value = self:GetValue()
        self:GetScript("OnValueChanged")(self, value)
    end

    bar:SetScript("OnMouseDown", UnlockedBar_OnMouseDown)

    return bar
end

--- temp test ---
-- local bar = core.CreateUnlockedBar(core.itemCollectionFrame, "HeadSlot")
-- bar:SetPoint("RIGHT", bar:GetParent(), "LEFT") 
-- bar:Show()


core.ComputeSlotUnlocks = function()
    local withNames = nil
    local searchTerm = nil

    local unlocks = {}

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
end