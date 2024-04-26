local folder, core = ...

core.FindEnchantNames = function()
    core.ScanningTooltip:SetHyperlink("item:2000")
    local enchantFontString = _G[core.ScanningTooltip:GetName() .. "TextLeft6"]

    for visualID, enchantInfo in pairs(core.enchants) do
        enchantInfo.names = {}
        for _, enchantID in pairs(enchantInfo.enchantIDs) do
            core.ScanningTooltip:SetOwner(WorldFrame)
            core.ScanningTooltip:SetHyperlink("item:2000:" .. enchantID)
            enchantInfo.names[enchantID] = enchantFontString:GetText() 
            core.ScanningTooltip:Hide()           
        end
    end
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

	optionsDDM.Initialize = function(self, level)
        local keys = {ENCHANT = 1, UNLOCKED_FILTER = 2} -- Filter nach Klasse, Fraktion?
        local enchant = self:GetParent().enchant
        local unlocked = self:GetParent().filter.unlocked

		local info
		if level == 1 then
			-- enchant preview
            -- now done thourgh enchant slot, but keeping the code for now
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

		elseif level == 2 then            
			local levelOneKey = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]
            
            if levelOneKey == keys.ENCHANT then
                info = UIDropDownMenu_CreateInfo()
                info.text = NONE
                info.arg1 = nil
                info.arg2 = nil
                info.func = optionsDDM.SetEnchant
                info.checked = optionsDDM:GetParent().enchant == info.arg1
                info.padding = 0
                UIDropDownMenu_AddButton(info, level)

                for _, enchantInfo in pairs(core.enchants) do
                    local id = enchantInfo.enchantIDs[1]
                    local name, _, tex = core.GetEnchantInfo(id)
                    info = UIDropDownMenu_CreateInfo()
                    info.text = name and (core.GetTextureString(tex, 12) .. " " .. name) or id
                    info.arg1 = id
                    info.arg2 = nil
                    info.func = optionsDDM.SetEnchant
                    info.checked = enchant == info.arg1
                    info.padding = 0
                    info.disabled = nil -- TODO: strange bug, that sometimes lowest ~5 enchant buttons are disabled
                    UIDropDownMenu_AddButton(info, level)
                end

            elseif levelOneKey == keys.UNLOCKED_FILTER then
                local buttons = { {text = ALL, arg1 = nil}, {text = YES, arg1 = 1}, {text = NO, arg1 = 0} }
                for _, button in pairs(buttons) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = button.text
                    info.arg1 = button.arg1
                    info.func = optionsDDM.SetUnlockedFilter
                    info.checked = unlocked == info.arg1
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
    -- skinDropDown:SetScale(0.9)

	return optionsDDM
end
