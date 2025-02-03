local folder, core = ...

local OUTFIT_NAME_MAX_LENGTH = 20
local DROPDOWN_DISPLAY_LENGTH = 20
local POPUP_DISPLAY_LENGTH = 20

local popups = { CreateOutfitPopup = true, RenameOutfitPopup = true, DeleteOutfitPopup = true, OverwriteOutfitPopup = true }
core.IsOutfitPopupActive = function()
	for index = 1, STATICPOPUP_NUMDIALOGS do
		local frame = _G["StaticPopup" .. index]
		if frame:IsShown() and frame.which and popups[frame.which] then
			return true
		end
	end
end

local CreateOutfitPopup_OnAccept = function(self, data)
	local name = self.editBox:GetText()
	local success = core.CreateOutfit(name, data.set)
	if success then
		data.outfitFrame:SetSelectedOutfit(name)
	end
end

StaticPopupDialogs["CreateOutfitPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = CreateOutfitPopup_OnAccept,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(OUTFIT_NAME_MAX_LENGTH)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		CreateOutfitPopup_OnAccept(self:GetParent(), data)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["RenameOutfitPopup"] = {
	text = "",
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		core.RenameOutfit(data.name, self.editBox:GetText())
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(OUTFIT_NAME_MAX_LENGTH)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		core.RenameOutfit(data.name, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["DeleteOutfitPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)
		core.DeleteOutfit(data.name)
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		if data.disable then
			StaticPopup1Button1:Disable()
		end
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["OverwriteOutfitPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)
		core.SaveOutfit(data.name, data.model:GetAll())
	end,
	OnShow = function(self, data)
		self.text:SetText(data.text)
		if data.disable then
			StaticPopup1Button1:Disable()
		end
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
}

local ShowCreateOutfitPopup = function(set, outfitFrame)
	local data = {}
	data.text = core.CREATE_OUTFIT_TEXT1
	data.set = set
	data.outfitFrame = outfitFrame
				
	StaticPopup_Show("CreateOutfitPopup", nil, nil, data)
end

local ShowOverwriteOutfitPopup = function(name, model)
	local outfits = core.GetOutfits()
	assert(outfits and outfits[name])

	local data = {}
	data.name = name
	data.model = model
	data.text = core.OVERWRITE_OUTFIT_TEXT1 .. "\"" .. core.GetShortenedString(name, POPUP_DISPLAY_LENGTH) .. "\"" .. core.OVERWRITE_OUTFIT_TEXT2

	StaticPopup_Show("OverwriteOutfitPopup", nil, nil, data)
end

local ShowRenameOutfitPopup = function(name)
	local outfits = core.GetOutfits()
	assert(outfits and outfits[name])

	local data = {}
	--data.id = id
	data.name = name
	data.text = core.RENAME_OUTFIT_TEXT1 .. "\"" .. core.GetShortenedString(name, POPUP_DISPLAY_LENGTH) .. "\"" .. core.RENAME_OUTFIT_TEXT2

	StaticPopup_Show("RenameOutfitPopup", nil, nil, data)
end

local ShowDeleteOutfitPopup = function(name)
	local outfits = core.GetOutfits()
	assert(name and outfits and outfits[name])

	local data = {}
	data.name = name
	data.text = core.DELETE_OUTFIT_TEXT1 .. "\"" .. core.GetShortenedString(name, POPUP_DISPLAY_LENGTH) .. "\"" .. core.DELETE_OUTFIT_TEXT2

	StaticPopup_Show("DeleteOutfitPopup", nil, nil, data)
end

local counter = 1
core.CreateOutfitDDM = function(parent)
	local outfitDropDown = CreateFrame("Frame", folder .. "OutfitDropDown" .. counter, parent, "UIDropDownMenuTemplate")
	counter = counter + 1
	--UIDropDownMenu_SetWidth(skinDropDown, 100, 0) -- Use in place of dropDown:SetWidth

	outfitDropDown.SelectOutfit = function(self, arg1, arg2, checked)
		local outfitID, outfitName = arg1, arg2
		parent:SetSelectedOutfit(outfitName)
		CloseDropDownMenus()
	end
	
	outfitDropDown.Initialize = function(self, level)
		UIDropDownMenu_SetButtonWidth(outfitDropDown, 40)
		outfitDropDown.update()

        local outfits = core.GetOutfits()
		local selectedOutfit = parent:GetSelectedOutfit()		

		local info
		if level == 1 then
			-- no outfit (there isn't really a reason to deselect the outfit)
			-- info = UIDropDownMenu_CreateInfo()
			-- info.text = NONE
			-- info.arg1 = nil
			-- info.arg2 = nil
			-- info.func = self.SelectOutfit
			-- info.checked = name == selectedOutfit
			-- info.padding = 0
			-- info.hasArrow = nil
			-- info.value = { ["levelOneKey"] = id }
			-- --info.minWidth = 200 ace lib function
			-- UIDropDownMenu_AddButton(info, level)

			-- outfits
			for name, slots in pairs(outfits) do
				info = UIDropDownMenu_CreateInfo()
				info.text = core.GetShortenedString(name, DROPDOWN_DISPLAY_LENGTH)
				info.arg1 = name
				info.arg2 = name
				info.func = self.SelectOutfit
				info.checked = name == selectedOutfit
				info.padding = 0
				info.hasArrow = true
				info.value = { ["levelOneKey"] = name }
				--info.minWidth = 200 ace lib function
				UIDropDownMenu_AddButton(info, level)
			end

			-- create new outfit
			info = UIDropDownMenu_CreateInfo()
			info.text = "|TInterface\\Icons\\Spell_ChargePositive:14:14:0:0|t " .. core.NEW_OUTFIT .. "|r"
			--info.icon = "Interface\\Icons\\Spell_ChargePositive"
			info.arg1 = info.text
			info.notCheckable = true
			--info.leftPadding = 100 -- ace only
			--info.padding = 120
			info.func = function(self, arg1, arg2, checked)
				ShowCreateOutfitPopup(parent:GetParent():GetAll(), parent)
				CloseDropDownMenus()
			end
			info.value = info.text
			info.colorCode = "|cff00ff00"
			info.justifyH = "CENTER" -- akzeptiert kein RIGHT?
			UIDropDownMenu_AddButton(info, level)
			
		elseif level == 2 then
			local levelOneKey = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]
			----------------------------------------------------------------------------	
			info = UIDropDownMenu_CreateInfo()					
			info.text = core.EQUIP
			info.arg1 = levelOneKey
			info.arg2 = levelOneKey
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = core.EQUIP}
			info.notCheckable = true
			info.padding = 0
			info.func = self.SelectOutfit
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)
			----------------------------------------------------------------------------		
			info = UIDropDownMenu_CreateInfo()					
			info.text = core.OVERWRITE
			info.arg1 = levelOneKey
			info.arg2 = levelOneKey
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = core.OVERWRITE}
			info.notCheckable = true
			info.padding = 0
			info.disabled = not outfitDropDown:GetParent():ModelDiffersFromOutfit(levelOneKey)
			info.func = function(self, arg1, arg2, checked)				
				ShowOverwriteOutfitPopup(levelOneKey, outfitDropDown:GetParent():GetParent())
				CloseDropDownMenus()
			end
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)
			----------------------------------------------------------------------------		
			info = UIDropDownMenu_CreateInfo()					
			info.text = core.RENAME
			info.arg1 = levelOneKey
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = core.RENAME}
			info.notCheckable = true
			info.padding = 0
			info.func = function(self, arg1, arg2, checked)
				ShowRenameOutfitPopup(levelOneKey)
				CloseDropDownMenus()
			end
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)
			----------------------------------------------------------------------------	
			info = UIDropDownMenu_CreateInfo()
			info.text = DELETE
			info.arg1 = levelOneKey
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = DELETE}
			info.notCheckable = true
			info.padding = 0
			info.func = function(self, arg1, arg2, checked)
				ShowDeleteOutfitPopup(levelOneKey)
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(info, level)	
		end

		
		--UIDropDownMenu_SetWidth(skinDropDown, 100, 0) -- Use in place of dropDown:SetWidth
	end

	outfitDropDown.update = function()
		local outfit = parent:GetSelectedOutfit()
		local text = outfit or core.GetColoredString(core.NO_OUTFIT, core.greyTextColor.hex)
		UIDropDownMenu_SetText(outfitDropDown, text)
	end
	outfitDropDown.update()

	core.RegisterListener("selectedSkin", outfitDropDown)
	core.RegisterListener("skins", outfitDropDown)
	core.RegisterListener("outfits", outfitDropDown)
	
	UIDropDownMenu_JustifyText(outfitDropDown, "LEFT") 
	UIDropDownMenu_Initialize(outfitDropDown, outfitDropDown.Initialize)
	
	return outfitDropDown
end