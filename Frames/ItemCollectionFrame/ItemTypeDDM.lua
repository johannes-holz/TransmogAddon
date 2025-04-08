local folder, core = ...

-- TODO: API function for possible types per TransmogLocation? Or just show whats usually possible? Could restrict to categories, for which some items are unlocked at NPC (with itemdata)

core.CreateItemTypeDDM = function(parent)
    local ddm = CreateFrame("Frame", folder.."ItemTypeDDM", parent, "UIDropDownMenuTemplate")
        
    local ItemTypeDDM_ButtonOnClick = function(self, arg1, arg2, checked)
        --print(UIDropDownMenu_GetText(self), UIDROPDOWNMENU_MENU_VALUE, arg1, arg2)
        --UIDropDownMenu_SetSelectedName(ddm, arg1)
        --UIDropDownMenu_SetText(ddm, arg1)
        if core.IsAtTransmogrifier() then
            -- print("at npc", arg1)
            core.SetSlotAndCategory(core.GetSelectedSlot(), arg1) -- TODO: fix this double method shit
        else
            -- print("not at npc", arg1)
            parent:SetSlotAndCategory(parent.selectedSlot, arg1)
        end
    end

    -- Gets called each time the DDM is opened and tells it what buttons we want to create
    local ItemTypeDDM_Initialize = function(self, level)
        if not parent.selectedSlot then return end

        local slot = parent.selectedSlot
        local cat = parent.selectedCategory
        local atTransmogrifier = core.IsAtTransmogrifier()
        
        local info = UIDropDownMenu_CreateInfo()
        local types = core.slotCategories[slot]

        -- pretty sure we don't need this anymore and if we would use this slot in collection, we wouldn't follow these exact rules
        -- if slot == "SecondaryHandSlot" then 
        --     if not IsSpellKnown(674) then -- Dualwielding
        --         types = {"Rüstung Schilde", "Rüstung Verschiedenes", "Verschiedenes Plunder"}
        --     elseif not (select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1) then -- Titangrip
        --         types = {"Rüstung Schilde", "Rüstung Verschiedenes", "Verschiedenes Plunder", "Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter", "Waffe Verschiedenes"}
        --     end
        -- end        
    
        -- if not atTransmogrifier then
        info.text = ALL
        info.arg1 = nil
        info.checked = not cat
        info.func = ItemTypeDDM_ButtonOnClick
        --info.justifyH = "RIGHT" -- doesn't do anything?? Only takes "CENTER" or nil as arguments, but somehow not even Center seems to work here. Could try scuffed solution with space/pixel? padding
        UIDropDownMenu_AddButton(info, level)
        -- end
        
        for _, itemType in pairs(types) do
            info.text = core.CATEGORY_DISPLAY_NAME[itemType] or core.RemoveFirstWordInString(itemType) -- TODO: Make all this category stuff less scuffed?
            info.arg1 = itemType
            info.checked = cat == itemType
            info.func = ItemTypeDDM_ButtonOnClick
            UIDropDownMenu_AddButton(info, level)
        end
    end

    --UIDropDownMenu_SetText(ddm, "Item Type")
    UIDropDownMenu_Initialize(ddm, ItemTypeDDM_Initialize)
    UIDropDownMenu_SetWidth(ddm, 130, 0)
    UIDropDownMenu_SetButtonWidth(ddm, 130)
    UIDropDownMenu_JustifyText(ddm, "RIGHT")

    return ddm
end