local folder, core = ...

-- TODO: Get localized Strings, Ask API for possible types per TransmogLocation? Or just show whats usually possible?
-- local slotItemTypes = {
-- 	["HeadSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["ShoulderSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["BackSlot"] = {"Rüstung Stoff"},
-- 	["ChestSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["ShirtSlot"] = {"Rüstung Verschiedenes"},
-- 	["TabardSlot"] = {"Rüstung Verschiedenes"},
-- 	["WristSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["HandsSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["WaistSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["LegsSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["FeetSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
-- 	["MainHandSlot"] = {"Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
-- 		"Waffe Stangenwaffen", "Waffe Stäbe", "Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Angelruten", "Waffe Verschiedenes"},
-- 	["SecondaryHandSlot"] = {"Rüstung Schilde", "Rüstung Verschiedenes", "Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
-- 		"Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Verschiedenes", "Verschiedenes Plunder"},
        

-- 	["ShieldHandWeaponSlot"] = {"Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
--     "Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Verschiedenes", "Verschiedenes Plunder"},
--     ["OffHandSlot"] = {"Rüstung Schilde", "Rüstung Verschiedenes"},

-- 	["RangedSlot"] = {"Waffe Bogen", "Waffe Armbrüste",	"Waffe Schusswaffen", "Waffe Wurfwaffen", "Waffe Zauberstäbe"},
-- 	["MainHandEnchantSlot"] = {},
-- 	["SecondaryHandEnchantSlot"] = {},
-- }

core.SlotCategoryCount = function(slot)
    return core.slotCategories[slot] and core.Length(core.slotCategories[slot]) or nil
end

core.CreateItemTypeDDM = function(self, parent)
    local ddm = CreateFrame("Frame", folder.."ItemTypeDDM", parent, "UIDropDownMenuTemplate")
        
    local ItemTypeDDM_ButtonOnClick = function(self, arg1, arg2, checked)
        --print(UIDropDownMenu_GetText(self), UIDROPDOWNMENU_MENU_VALUE, arg1, arg2)
        --UIDropDownMenu_SetSelectedName(ddm, arg1)
        --UIDropDownMenu_SetText(ddm, arg1)
        if core.IsAtTransmogrifier() then
            print("uwu", arg1)
            core.SetSlotAndCategory(core.GetSelectedSlot(), arg1) -- TODO: fix this double method shit
        else
            print("awa")
            parent:SetSlotAndCategory(parent.selectedSlot, arg1)
        end
    end

    -- Creates the Buttons for the DropDownMenu and gets called each time the DDM is opened
    local ItemTypeDDM_Initialize = function(self, level)
        if not parent.selectedSlot then return end

        local slot = parent.selectedSlot
        local cat = parent.selectedCategory
        
        local info = UIDropDownMenu_CreateInfo()
        local types = core.slotCategories[slot]
        if slot == "SecondaryHandSlot" then 
            if not IsSpellKnown(674) then -- Dualwielding
                types = {"Rüstung Schilde", "Rüstung Verschiedenes", "Verschiedenes Plunder"}
            elseif not (select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1) then -- Titangrip
                types = {"Rüstung Schilde", "Rüstung Verschiedenes", "Verschiedenes Plunder", "Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter", "Waffe Verschiedenes"}
            end
        end        
        
        for _, itemType in pairs(types) do
            info.text = core.RemoveFirstWordInString(itemType) -- TODO: All this stuff less scuffed?
            info.arg1 = itemType
            info.checked = cat == itemType
            info.func = ItemTypeDDM_ButtonOnClick
            --info.justifyH = "RIGHT" -- doesn't do anything?? Only takes "CENTER" or nil as arguments, but somehow not even Center seems to work here. Could try scuffed solution with space/pixel? padding
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