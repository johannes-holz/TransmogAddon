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

    local SetEnchant = function(self, arg1, arg2, checked)
        optionsDDM:GetParent():SetPreviewEnchant(arg1)
        CloseDropDownMenus()
    end

	optionsDDM.Initialize = function(self, level)
        local enchant = parent.enchant
        local keys = {"ENCHANT"}

		local info
		if level == 1 then
			-- preview enchant
			info = UIDropDownMenu_CreateInfo()
			info.text = core.ENCHANT_PREVIEW
			info.arg1 = nil
			info.arg2 = nil
			info.padding = 0
            info.notCheckable = true
            info.hasArrow = true
            info.value = { levelOneKey = keys.ENCHANT}
			UIDropDownMenu_AddButton(info, level)


		elseif level == 2 then            
			local levelOneKey = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]
            
            if levelOnKey == keys.ENCHANT then
                info = UIDropDownMenu_CreateInfo()
                info.text = NONE
                info.arg1 = nil
                info.arg2 = nil
                info.func = SetEnchant
                info.checked = optionsDDM:GetParent().enchant == info.arg1
                info.padding = 0
                UIDropDownMenu_AddButton(info, level)

                for _, enchantInfo in pairs(core.enchants) do
                    local id = enchantInfo.enchantIDs[1]
                    info = UIDropDownMenu_CreateInfo()
                    info.text = enchantInfo.names and enchantInfo.names[enchantInfo.enchantIDs[1]] or enchantInfo.enchantIDs[1]
                    info.arg1 = id
                    info.arg2 = nil
                    info.func = SetEnchant
                    info.checked = optionsDDM:GetParent().enchant == info.arg1
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
