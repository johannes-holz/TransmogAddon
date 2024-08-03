local folder, core = ...

-- Have enchant spell data now
-- core.FindEnchantNames = function()
--     core.ScanningTooltip:SetHyperlink("item:2000")
--     local enchantFontString = _G[core.ScanningTooltip:GetName() .. "TextLeft6"]

--     for visualID, enchantInfo in pairs(core.enchants) do
--         enchantInfo.names = {}
--         for _, enchantID in pairs(enchantInfo.enchantIDs) do
--             core.ScanningTooltip:SetOwner(WorldFrame)
--             core.ScanningTooltip:SetHyperlink("item:2000:" .. enchantID)
--             enchantInfo.names[enchantID] = enchantFontString:GetText() 
--             core.ScanningTooltip:Hide()           
--         end
--     end
-- end

-- Might wanna move the masks into a Constants.lua
-- Filter selection is currently exclusive, but could be easily modified to allow selection of multiple classes/races
-- Just have to modify the filter setter to xor the selected field (and handle the "all" case differently)

-- localizedClass, ->englishClass, classIndex = UnitClass("unit")
core.classes = {
	["WARRIOR"] = 1,
	["PALADIN"] = 2,
	["HUNTER"] = 4,
	["ROGUE"] = 8,
	["PRIEST"] = 16,
	["DEATHKNIGHT"] = 32,
	["SHAMAN"] = 64,
	["MAGE"] = 128,
	["WARLOCK"] = 256,
	["MONK"] = 512,
	["DRUID"] = 1024,
	["DEMONHUNTER"] = 2048
}
-- ->englishFaction, localizedFaction = UnitFactionGroup(unit)
core.factions = {
	["Horde"] = 1,
	["Alliance"] = 2
}
-- race, raceEn<- = UnitRace("unit");
core.races = {
	["Human"] = 1,
	["Orc"] = 2,
	["Dwarf"] = 4,
	["NightElf"] = 8,
	["Undead"] = 16,
	["Tauren"] = 32,
	["Gnome"] = 64,
	["Troll"] = 128,
	["Goblin"] = 256,
	["BloodElf"] = 512,
	["Draenei"] = 1024,
	["Fel Orc"] = 2048,
	["Naga"] = 4096,
	["Broken"] = 8192,
	["Skeleton"] = 16384,
	["Vrykul"] = 32768,
	["Tuskarr"] = 65536,
	["Forest Troll"] = 131072,
	["Taunka"] = 262144,
	["Northrend Skeleton"] = 524288,
	["Ice Troll"] = 1048576,
	["Worgen"] = 2097152,
	["Pandaren Neutral"] = 8388608,
	["Pandaren Alliance"] = 16777216,
	["Pandaren Horde"] = 33554432
}

local classNames = UnitSex("player") == 2 and LOCALIZED_CLASS_NAMES_MALE or LOCALIZED_CLASS_NAMES_FEMALE
local classFilterButtons = { { text = ALL, arg1 = nil } }
for _, class in ipairs(CLASS_SORT_ORDER) do
    tinsert(classFilterButtons, { text = classNames[class], arg1 = core.classes[class] })
end

local factionFilterButtons = { { text = ALL, arg1 = nil } }
for _, faction in ipairs({ "Alliance", "Horde" }) do
    tinsert(factionFilterButtons, { text = faction, arg1 = core.factions[faction] }) -- TODO: where to get localized faction + races
end

local raceFilterButtons = { { text = ALL, arg1 = nil } }
for _, race in ipairs({ "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Orc", "Undead", "Tauren", "Troll", "BloodElf" }) do
    tinsert(raceFilterButtons, { text = race, arg1 = core.races[race] }) -- TODO: localize
end

core.CreateOptionsDDM = function(parent)
	local optionsDDM = CreateFrame("Frame", folder .. "ItemOptionsDropDown", parent, "UIDropDownMenuTemplate")

    optionsDDM.SetEnchant = function(self, arg1, arg2, checked)
        optionsDDM:GetParent():SetPreviewEnchant(arg1)
        CloseDropDownMenus()
    end

    optionsDDM.SetUnlockedFilter = function(self, arg1, arg2, checked)
        optionsDDM:GetParent():SetUnlockedFilter(arg1)
        CloseDropDownMenus()
    end

    optionsDDM.SetFilter = function(self, arg1, arg2, checked)
        print("setfilter", arg2, arg1)
        optionsDDM:GetParent():SetFilter(arg2, arg1)
        CloseDropDownMenus()
    end

	optionsDDM.Initialize = function(self, level)
        local keys = { ENCHANT = 1, UNLOCKED_FILTER = 2, CLASS_FILTER = 3, FACTION_FILTER = 4, RACE_FILTER = 5 }
        local enchant = self:GetParent().enchant
        local unlocked = self:GetParent().filter.unlocked
        local class = self:GetParent().filter.class
        local faction = self:GetParent().filter.faction
        local race = self:GetParent().filter.race

		local info
		if level == 1 then
			-- enchant preview
            -- now done through enchant slots, but keeping the code for now
			-- info = UIDropDownMenu_CreateInfo()
			-- info.text = core.ENCHANT_PREVIEW
			-- info.arg1 = nil
			-- info.arg2 = nil
			-- info.padding = 0
            -- info.notCheckable = true
            -- info.hasArrow = true
            -- info.value = { levelOneKey = keys.ENCHANT}
			-- UIDropDownMenu_AddButton(info, level)

            -- unlocked filter
			info = UIDropDownMenu_CreateInfo()
			info.text = core.UNLOCKED_FILTER
			info.arg1 = nil
			info.arg2 = nil
			info.padding = 0
            info.notCheckable = true
            info.hasArrow = true
            info.value = { levelOneKey = keys.UNLOCKED_FILTER}
			UIDropDownMenu_AddButton(info, level)
            
			info = UIDropDownMenu_CreateInfo()
			info.text = CLASS
			info.arg1 = nil
			info.arg2 = nil
			info.padding = 0
            info.notCheckable = true
            info.hasArrow = true
            info.value = { levelOneKey = keys.CLASS_FILTER}
			UIDropDownMenu_AddButton(info, level)

			info = UIDropDownMenu_CreateInfo()
			info.text = FACTION
			info.arg1 = nil
			info.arg2 = nil
			info.padding = 0
            info.notCheckable = true
            info.hasArrow = true
            info.value = { levelOneKey = keys.FACTION_FILTER}
			UIDropDownMenu_AddButton(info, level)

			info = UIDropDownMenu_CreateInfo()
			info.text = RACE
			info.arg1 = nil
			info.arg2 = nil
			info.padding = 0
            info.notCheckable = true
            info.hasArrow = true
            info.value = { levelOneKey = keys.RACE_FILTER}
			UIDropDownMenu_AddButton(info, level)

		elseif level == 2 then            
			local levelOneKey = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]
            
            if levelOneKey == keys.ENCHANT then
                info = UIDropDownMenu_CreateInfo()
                info.text = NONE
                info.arg1 = nil
                info.arg2 = nil
                info.func = self.SetEnchant
                info.checked = self:GetParent().enchant == info.arg1
                info.padding = 0
                UIDropDownMenu_AddButton(info, level)

                for _, enchantInfo in pairs(core.enchants) do
                    local id = enchantInfo.spellIDs[1]
                    local name, _, tex = GetSpellInfo(id)
                    info = UIDropDownMenu_CreateInfo()
                    info.text = name and (core.GetTextureString(tex, 12) .. " " .. name) or id
                    info.arg1 = id
                    info.arg2 = nil
                    info.func = self.SetEnchant
                    info.checked = enchant == info.arg1
                    info.padding = 0
                    info.disabled = nil -- TODO: strange bug, that sometimes lowest ~5 enchant buttons are disabled
                    UIDropDownMenu_AddButton(info, level)
                end

            elseif levelOneKey == keys.UNLOCKED_FILTER then
                local buttons = { {text = ALL, arg1 = nil}, {text = YES, arg1 = 1}, {text = NO, arg1 = 0} }
                for _, button in ipairs(buttons) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = button.text
                    info.arg1 = button.arg1
                    info.arg2 = "unlocked"
                    info.func = self.SetFilter
                    info.checked = unlocked == info.arg1
                    info.padding = 0
                    UIDropDownMenu_AddButton(info, level)
                end

            elseif levelOneKey == keys.CLASS_FILTER then
                for _, button in ipairs(classFilterButtons) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = button.text
                    info.arg1 = button.arg1
                    info.arg2 = "class"
                    info.func = self.SetFilter
                    info.checked = class == info.arg1 -- bit.band(classFilter, info.arg1) -- or just check for equality if we only allow one
                    info.padding = 0
                    UIDropDownMenu_AddButton(info, level)
                end
                
            elseif levelOneKey == keys.FACTION_FILTER then
                for _, button in ipairs(factionFilterButtons) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = button.text
                    info.arg1 = button.arg1
                    info.arg2 = "faction"
                    info.func = self.SetFilter
                    info.checked = faction == info.arg1
                    info.padding = 0
                    UIDropDownMenu_AddButton(info, level)
                end
                
            elseif levelOneKey == keys.RACE_FILTER then
                for _, button in ipairs(raceFilterButtons) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = button.text
                    info.arg1 = button.arg1
                    info.arg2 = "race"
                    info.func = self.SetFilter
                    info.checked = race == info.arg1
                    info.padding = 0
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
	end

	-- optionsDDM.update = function()
	-- 	local skinName = core.GetActiveSkinName()
	-- 	local text = skinName or NONE
	-- 	UIDropDownMenu_SetText(optionsDDM, text)
	-- end
	-- optionsDDM.update()	

	-- core.RegisterListener("activeSkin", optionsDDM)
	-- core.RegisterListener("skins", optionsDDM)
	
	UIDropDownMenu_SetText(optionsDDM, core.OPTIONS)
	UIDropDownMenu_JustifyText(optionsDDM, "RIGHT") 
	UIDropDownMenu_Initialize(optionsDDM, optionsDDM.Initialize)
    UIDropDownMenu_SetButtonWidth(optionsDDM, 40) -- Buttons get extended to fit biggest info.text

	UIDropDownMenu_SetWidth(optionsDDM, 80, 0)

	return optionsDDM
end
