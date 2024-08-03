local folder, core = ...

local SCALE = 1.2
local WIDTH, HEIGHT = 832, 446
local model, skinDropDown, applyButton, costsFrame, itemSlotOptionsFrame
local itemSlotFrames = {}
local MODEL_WIDTH, MODEL_HEIGHT = 270, 333
local modelHeight = 400
local itemSlotWidth = 24 --modelHeight / 8 - 2
local doAllButtonWidth = 16
local doAllButtonDistance = 1
local itemSlotDistance = 12

StaticPopupDialogs["ApplyTransmogPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)		
		local costs = core.GetCosts()
		local balance = core.GetBalance()
		if not costs.copper or not balance.shards then
			UIErrorsFrame:AddMessage(core.APPLY_ERROR1, 1.0, 0.1, 0.1, 1.0)
		elseif GetMoney() < costs.copper or balance.shards < costs.points then
			UIErrorsFrame:AddMessage(core.APPLY_ERROR2, 1.0, 0.1, 0.1, 1.0)
		else
			core.RequestApplyCurrentChanges()
		end
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

local ShowApplyTransmogPopup = function()
	-- Or ask server for correct price again before showing final confirmation popup?
	local costs = core.GetCosts()
	local balance = core.GetBalance()
	local skins = core.GetSkins()
	local id = core.GetSelectedSkin()
	costs.points = costs.points or costs.shards

	local lines = {}
	for _, slot in ipairs(core.allSlots) do
		local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot, id)
		local isEnchantSlot = core.IsEnchantSlot(slot)
		if pendingID then
			local name, link, tex, _
			if isEnchantSlot then
				name, _, tex = GetSpellInfo(pendingID)
			else
				_, link, _, _, _, _, _, _, _, tex = GetItemInfo(pendingID)
			end
			local itemText = pendingID == core.HIDDEN_ID and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex) or 
							pendingID == core.UNMOG_ID and core.GetColoredString(core.TRANSMOG_TOOLTIP_REMOVE_MOG, core.yellowTextColor.hex) or
							isEnchantSlot and (core.GetTextureString(tex, 16) .. " " .. core.GetColoredString(name, core.normalFontColor.hex)) or
							link and (core.GetTextureString(tex, 16) .. " " .. core.LinkToColoredString(link)) or pendingID
			local line = core.SLOT_NAMES[slot] .. ": " .. itemText .. "\n"
			tinsert(lines, line)
			-- if strlen(line) < 100 then
			-- 	line = line .. strrep(" ", 100 - strlen(line))
			-- end
			-- line = line .. "\n"
			-- tinsert(lines, line)

		-- 	tinsert(lines, core.SLOT_NAMES[slot])
		-- 	tinsert(lines, ": ")
		-- 	tinsert(lines, itemText)
		-- 	tinsert(lines, "\n")		
		end
	end			

	local data = {}
	data.id = id
	data.name = id and skins[id].name or nil
	-- data.disable = not costs.points or not costs.copper or not balance.shards or costs.points > balance.shards or costs.copper > GetMoney()
	data.disable = not costs.points or not costs.copper or not balance.shards
	data.text = (id and (core.APPLY_TO_SKIN_TEXT1 .. " " .. core.SkinPopupDisplay(data.id, data.name)) or core.APPLY_TO_INVENTORY_TEXT1)
					.. " " .. core.APPLY_TO_INVENTORY_TEXT2 .. "\n\n"
					.. table.concat(lines) .. "\n"
					.. (costs.points and costs.copper and core.GetPriceString(costs.points, costs.copper) or core.APPLY_ERROR1)				
	local popup = StaticPopup_Show("ApplyTransmogPopup", nil, nil, data)
end

-- not in use yet
local TransmogFrame_OnShow = function(self)
    HideUIPanel(WardrobeFrame) -- TODO - Probably can not make our transmog frame a standard UI Panel, if we want to be able to go back to GossipFrame after Opening
    core.SetAtTransmogrifier(1) -- Better do an OpenTransmogWindow() function, which gets called through Gossip Hook or Button and sets this?

    PlaySound("igCharacterInfoOpen")

    -- TODO: check out all of this:
    -- model:Hide() --needed?
    -- model:Show()
    -- for slot, updateNeeded in pairs(core.availableMogsUpdateNeeded) do --TODO all the stuff about how and when to update unlocks for slot / item
    --     local itemID = core.TransmogGetSlotInfo(slot)
    --     if updateNeeded and itemID then
    --         core.RequestUnlocksSlot(slot)
    --     end
    -- end		
    if not core.GetBalance().shards then
		core.RequestBalance()
	end
    -- core.RequestPriceTotal()
	local npcID = UnitExists("target") and core.GetNPCID(UnitGUID("target"))

	if npcID == core.TMOG_NPC_ID then
    	SetPortraitTexture(f.portraitTexture, "target")
	else
		SetPortraitToTexture(f.portraitTexture, "interface/icons/inv_mushroom_11")
	end
end

local TransmogFrame_OnHide = function(self)
    PlaySound("igCharacterInfoClose")
	
	core.UnHideGossipFrame()
    CloseGossip()
end


local SavePosition = function()
	local point, _, relativePoint, xOfs, yOfs = core.transmogFrame:GetPoint()
	if not TransmoggyDB.Position then 
		TransmoggyDB.Position = {}
	end
	TransmoggyDB.Position.point = point
	TransmoggyDB.Position.relativePoint = relativePoint
	TransmoggyDB.Position.xOfs = xOfs
	TransmoggyDB.Position.yOfs = yOfs	
end

local LoadPosition = function()
	if TransmoggyDB.Position then
		core.transmogFrame:SetPoint(TransmoggyDB.Position.point,UIParent,TransmoggyDB.Position.relativePoint,TransmoggyDB.Position.xOfs,TransmoggyDB.Position.yOfs)
	else
		core.transmogFrame:SetPoint("CENTER", UIParent, "CENTER")
	end
end

core.PlayApplyAnimations = function()	
	for k, v in pairs(itemSlotFrames) do
		v:PlayApply()	
	end
end

do
	core.transmogFrame = CreateFrame("Frame", folder .. "TransmogFrame", UIParent)
	local f = core.transmogFrame
	f.scale = SCALE

	f:SetClampedToScreen(true) 
	f:SetFrameStrata("MEDIUM")
	f:SetToplevel(true) -- raises frame level to be on top of other frames on mouse click
	tinsert(UISpecialFrames, f:GetName()) -- close on escape
	f:SetSize(WIDTH * SCALE, HEIGHT * SCALE) --TODO: make independent of /run print(UIParent:GetScale()) ?
	f:SetPoint("CENTER")
	LoadPosition()
	f:EnableMouse(true)
	f:SetMovable(true)

	f:SetScript("OnShow", function(self)
		-- make an CollectionFrame:SetContainer function, that sets points etc, putting that stuff into onshow probable not optimal, since when we swap tabs, it would get called needlessly?
		-- at end of set container do self:SetTab(self.GetParent().selectedTab)
		self:SelectItemTab()

		-- Request unlocks for all slots or only for currently selected slot?
		-- for slot, updateNeeded in pairs(core.availableMogsUpdateNeeded) do --TODO all the stuff about how and when to update unlocks for slot / item
		-- 	local itemID = core.TransmogGetSlotInfo(slot)
		-- 	if updateNeeded and itemID then
		-- 		core.RequestUnlocksSlot(slot)
		-- 	end
		-- end
		-- TODO: Either recheck all pendings, clear all pendings or clear pending on equipment changed?
		
		if not core.GetBalance().shards then
			core.RequestBalance()
		end

		local npcID = UnitExists("target") and core.GetNPCID(UnitGUID("target"))

		if npcID == core.TMOG_NPC_ID then
			SetPortraitTexture(f.portraitTexture, "target")
		else
			SetPortraitToTexture(f.portraitTexture, "interface/icons/inv_mushroom_11") -- "Interface/Icons/Achievement_Boss_Algalon_01"
		end

		f:update()
		PlaySound("igCharacterInfoOpen")
	end)

	f:SetScript("OnHide", function(self)	
		core.SetIsAtTransmogrifier(false)
		core.UnHideGossipFrame()
		PlaySound("igCharacterInfoClose")
	end)

	f.SelectItemTab = function(self)
		core.itemCollectionFrame:SetParent(self)
		core.itemCollectionFrame:ClearAllPoints()
		core.itemCollectionFrame:SetPoint("TOPLEFT", model, "TOPRIGHT", 0, 4)
		core.itemCollectionFrame:Show()
		core.itemCollectionFrame:SetSlotAndCategory(core.GetSelectedSlot(), core.GetSelectedCategory(), true)
	end	
	
	f.BGTopLeft = f:CreateTexture(nil, "BORDER")
	f.BGTopLeft:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AUCTIONFRAME-BID-TOPLEFT")
	f.BGTopLeft:SetSize(256 * SCALE, 256 * SCALE)
	f.BGTopLeft:SetPoint("TOPLEFT", f, "TOPLEFT")

	f.BGTop = f:CreateTexture(nil, "BORDER")
	f.BGTop:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-Top")
	f.BGTop:SetSize(320 * SCALE, 256 * SCALE)
	f.BGTop:SetPoint("TOPLEFT", f.BGTopLeft, "TOPRIGHT")
	
	f.BGTopRight = f:CreateTexture(nil, "BORDER")
	f.BGTopRight:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-TopRight")
	f.BGTopRight:SetSize(256* SCALE, 256 * SCALE)
	f.BGTopRight:SetPoint("TOPLEFT", f.BGTop, "TOPRIGHT")
	
	f.BGBottomLeft = f:CreateTexture(nil, "BORDER")
	f.BGBottomLeft:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AUCTIONFRAME-BID-BOTLEFT")
	f.BGBottomLeft:SetSize(256 * SCALE, 256 * SCALE)
	f.BGBottomLeft:SetPoint("TOPLEFT", f.BGTopLeft, "BOTTOMLEFT")
	
	f.BGBottom = f:CreateTexture(nil, "BORDER")
	f.BGBottom:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-Bot")
	f.BGBottom:SetSize(320 * SCALE, 256 * SCALE)
	f.BGBottom:SetPoint("TOPLEFT", f.BGBottomLeft, "TOPRIGHT")
	
	f.BGBottomRight = f:CreateTexture(nil, "BORDER")
	f.BGBottomRight:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AUCTIONFRAME-BID-BOTRIGHT")
	f.BGBottomRight:SetSize(256 * SCALE, 256 * SCALE)
	f.BGBottomRight:SetPoint("TOPLEFT", f.BGBottom, "TOPRIGHT")
	
	f.portraitTexture = f:CreateTexture(nil, "BACKGROUND")
	f.portraitTexture:SetSize(62 * SCALE, 62 * SCALE)
	f.portraitTexture:SetPoint("TOPLEFT", 7 * SCALE, -4 * SCALE)
	SetPortraitTexture(f.portraitTexture, "player")
	
	f:SetScript("OnMouseDown",function(self,button)
		CloseDropDownMenus()
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)
	f:SetScript("OnMouseUp",function(self,button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
			SavePosition()
		end
	end)
	
	model = core.CreatePreviewModel(f, MODEL_WIDTH * SCALE, MODEL_HEIGHT * SCALE)
	core.previewModel = model
	model:SetPoint("TOPLEFT", 20 * SCALE, -74 * SCALE)

	f.exitButton = core.CreateMeAButton(f, 22 * SCALE, 22 * SCALE, nil,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Down", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled", 90/512, 118/512, 451/512, 481/512)		
	f.exitButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1 * SCALE, -15 * SCALE)
	f.exitButton:SetScript("OnClick", function() 
		CloseGossip()
		f:Hide()
	end)

	f.minimizeButton = core.CreateMeAButton(f, 22 * SCALE, 22 * SCALE, nil,
		"Interface\\Buttons\\UI-Panel-SmallerButton-Up", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-SmallerButton-Down", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-SmallerButton-Disabled", 90/512, 118/512, 451/512, 481/512)
	f.minimizeButton:SetPoint("RIGHT", f.exitButton, "LEFT")
	f.minimizeButton:SetScript("OnClick", function()
		f:Hide()
	end)
	
	-- local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	-- f.cancelAllButton = core.CreateMeACustomTexButton(model, 24, 24, "Interface\\AddOns\\".. folder .."\\images\\Transmogrify", left, top, right, bottom)
	f.cancelAllButton = core.CreateMeACustomTexButton(model, doAllButtonWidth * SCALE, doAllButtonWidth * SCALE, "Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent", 0, 0, 1, 1)
	f.cancelAllButton:SetPoint("TOPRIGHT", model, "TOPRIGHT", -4 * SCALE, -4 * SCALE)
	f.cancelAllButton:SetScript("OnClick", function()
		core.SetCurrentChanges({})
	end)
	core.SetTooltip(f.cancelAllButton, core.RESET_ALL)
	
	local left, top, right, bottom = 417/512, 90/512, 443/512,116/512
	f.undressAllButton = core.CreateMeACustomTexButton(model, doAllButtonWidth * SCALE, doAllButtonWidth * SCALE, "Interface\\AddOns\\" .. folder .. "\\images\\Transmogrify", left, top, right, bottom)
	f.undressAllButton:SetPoint("TOPRIGHT", f.cancelAllButton, "TOPLEFT", -doAllButtonDistance * SCALE, 0)	
	f.undressAllButton:SetScript("OnClick", function()
		local tar = {}
		for _, slot in pairs(core.allSlots) do
			tar[slot] = core.HIDDEN_ID
		end
		core.SetCurrentChanges(tar)
	end)
	core.SetTooltip(f.undressAllButton, core.HIDE_ALL)

	local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	f.removeAllMogButton = core.CreateMeACustomTexButton(model, doAllButtonWidth * SCALE, doAllButtonWidth * SCALE, "Interface\\AddOns\\".. folder .."\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	f.removeAllMogButton:SetPoint("RIGHT", f.undressAllButton, "LEFT", -doAllButtonDistance * SCALE, 0)	
	f.removeAllMogButton:SetScript("OnClick", function()
		local tar = {}
		for _, slot in pairs(core.allSlots) do
			tar[slot] = core.UNMOG_ID
		end
		core.SetCurrentChanges(tar)
	end)	
	core.SetTooltip(f.removeAllMogButton, core.UNMOG_ALL)

	model.showItemsUnderSkin = false
	f.showItemsUnderSkinCheckButton = CreateFrame("CheckButton", folder .. "ShowItemsUnderSkinCheckButton", model, "UICheckButtonTemplate")
	f.showItemsUnderSkinCheckButton:SetSize(20 * SCALE, 20 * SCALE)
	f.showItemsUnderSkinCheckButton:SetPoint("BOTTOMLEFT", 4 * SCALE, 4 * SCALE)
	f.showItemsUnderSkinCheckButton:SetChecked(model.showItemsUnderSkin)
	f.showItemsUnderSkinCheckButton:SetScript("OnClick", function(self, button)
		model.showItemsUnderSkin = self:GetChecked()
		model:update()
	end)
	getglobal(f.showItemsUnderSkinCheckButton:GetName() .. "Text"):SetText(core.EQUIP_PREVIEW)
	core.SetTooltip(f.showItemsUnderSkinCheckButton, core.SHOW_ITEMS_UNDER_SKIN_TOOLTIP_TEXT, nil, nil, nil, nil, 1)
	f.showItemsUnderSkinCheckButton.update = function(self)
		core.SetShown(self, core.GetSelectedSkin())
	end
	f.showItemsUnderSkinCheckButton:update()
	core.RegisterListener("selectedSkin", f.showItemsUnderSkinCheckButton)

	for _, itemSlot in pairs(core.itemSlots) do
		itemSlotFrames[itemSlot] = core.CreateSlotButton(model, itemSlotWidth * SCALE, itemSlot)
	end

	for _, enchantSlot in pairs(core.enchantSlots) do
		itemSlotFrames[enchantSlot] = core.CreateSlotButton(model, 0.6 * itemSlotWidth * SCALE, enchantSlot)
	end

	itemSlotOptionsFrame = core.CreateItemSlotOptionsFrame(itemSlotFrames["HeadSlot"])

	itemSlotFrames["ChestSlot"]:SetPoint("LEFT", model, "LEFT", 10, 0)
	itemSlotFrames["ShirtSlot"]:SetPoint("TOP", itemSlotFrames["ChestSlot"], "BOTTOM", 0, -itemSlotDistance * SCALE)
	itemSlotFrames["TabardSlot"]:SetPoint("TOP", itemSlotFrames["ShirtSlot"], "BOTTOM", 0, -itemSlotDistance * SCALE)
	itemSlotFrames["WristSlot"]:SetPoint("TOP", itemSlotFrames["TabardSlot"], "BOTTOM", 0, -itemSlotDistance * SCALE)
	itemSlotFrames["BackSlot"]:SetPoint("BOTTOM", itemSlotFrames["ChestSlot"], "TOP", 0, itemSlotDistance * SCALE)
	itemSlotFrames["ShoulderSlot"]:SetPoint("BOTTOM", itemSlotFrames["BackSlot"], "TOP", 0, itemSlotDistance * SCALE)	
	itemSlotFrames["HeadSlot"]:SetPoint("BOTTOM", itemSlotFrames["ShoulderSlot"], "TOP", 0, itemSlotDistance * SCALE)
	
	itemSlotFrames["WaistSlot"]:SetPoint("BOTTOMRIGHT", model, "RIGHT", -10, itemSlotDistance * SCALE / 2)
	itemSlotFrames["HandsSlot"]:SetPoint("BOTTOM", itemSlotFrames["WaistSlot"], "TOP", 0, itemSlotDistance * SCALE)
	itemSlotFrames["LegsSlot"]:SetPoint("TOP", itemSlotFrames["WaistSlot"], "BOTTOM", 0, -itemSlotDistance * SCALE)
	itemSlotFrames["FeetSlot"]:SetPoint("TOP", itemSlotFrames["LegsSlot"], "BOTTOM", 0, -itemSlotDistance * SCALE)

	itemSlotFrames["MainHandSlot"]:SetPoint("BOTTOMRIGHT", model, "BOTTOM", (core.HasRangedSlot() and -itemSlotWidth or 0) * SCALE, 10)
--	itemSlotFrames["SecondaryHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)
	itemSlotFrames["ShieldHandWeaponSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)
	itemSlotFrames["OffHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)

	itemSlotFrames["RangedSlot"]:SetPoint("LEFT", itemSlotFrames["OffHandSlot"], "RIGHT", itemSlotDistance * 2 * SCALE, 0)
	if not core.HasRangedSlot() then itemSlotFrames["RangedSlot"]:Hide() end
	
	itemSlotFrames["MainHandEnchantSlot"]:SetPoint("BOTTOM", itemSlotFrames["MainHandSlot"], "TOP", 0, 7 * SCALE)
	itemSlotFrames["SecondaryHandEnchantSlot"]:SetPoint("BOTTOM", itemSlotFrames["ShieldHandWeaponSlot"], "TOP", 0, 7 * SCALE)
	-- itemSlotFrames["MainHandEnchantSlot"]:SetParent(itemSlotFrames["MainHandSlot"])
	-- itemSlotFrames["MainHandEnchantSlot"]:SetFrameLevel(itemSlotFrames["MainHandSlot"])
	-- itemSlotFrames["SecondaryHandEnchantSlot"]:SetParent(itemSlotFrames["ShieldHandWeaponSlot"])
	
	
	skinDropDown = core.CreateSkinDropDown(f)
	--skinDropDown:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 66 * SCALE, -72 * SCALE	)
	--skinDropDown:Show()

	applyButton = core.CreateMeATextButton(f, 112 *  SCALE, 20 * SCALE, "Apply")
	applyButton:SetPoint("BOTTOMLEFT", 180 * SCALE, 15 * SCALE)
	applyButton:Show()
	
	applyButton:SetScript("OnClick", function()
		local costs = core.GetCosts()
		local balance = core.GetBalance()
		
		local showConfirmPopup = true

		if showConfirmPopup then
			ShowApplyTransmogPopup()
		else
			if not costs.copper or not balance.shards then
				UIErrorsFrame:AddMessage(core.APPLY_ERROR1, 1.0, 0.1, 0.1, 1.0)
			elseif GetMoney() < costs.copper or balance.shards < costs.points then
				UIErrorsFrame:AddMessage(core.APPLY_ERROR2, 1.0, 0.1, 0.1, 1.0)
			else
				core.RequestApplyCurrentChanges()
			end
		end
	end)
	applyButton.update = function()	
		applyButton:SetText(core.GetSelectedSkin() and core.APPLY_TO_SKIN or core.APPLY_TO_ITEMS)

		local costs = core.GetCosts()
		local balance = core.GetBalance()

		local enable = true

		-- for k, slot in pairs(core.itemSlots) do
		-- 	if not enable and slot ~= "MainHandEnchantSlot" and slot ~= "SecondaryHandEnchantSlot" then
		-- 		local itemID, visualID, _, pendingID = core.TransmogGetSlotInfo(slot)

		-- 		if pendingID then
		-- 			enable = true --applyButton:Enable()
		-- 		end
		-- 	end
		-- end	
		-- for k, slot in pairs(core.itemSlots) do
		-- 	if enable and slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot" then
		-- 		local itemID, visualID, _, pendingID = core.TransmogGetSlotInfo(slot)
				
		-- 		if pendingID and not canReceiveTransmog(itemID, pendingID, slot) then
		-- 			enable = false
		-- 		end
		-- 	end
		-- end

		-- if not costs.copper or not balance.shards or GetMoney() < costs.copper or balance.shards < costs.points then
		if not costs.copper or not balance.shards then -- When not enough funds: Allow clicking button and show error message on click instead of disabling?
			enable = false
		end
		
		if enable then
			applyButton:Enable()
		else
			applyButton:Disable()
		end
	end		
	applyButton.update()
	core.RegisterListener("costs", applyButton)
	core.RegisterListener("currentChanges", applyButton)
	core.RegisterListener("currentMogs", applyButton)
	core.RegisterListener("money", applyButton)
	core.RegisterListener("selectedSkin", applyButton)
	
	costsFrame = f:CreateFontString()
	costsFrame:SetFontObject(SCALE == 1 and "GameFontWhiteSmall" or "GameFontWhite")
	costsFrame:SetPoint("RIGHT", applyButton, "LEFT", -8 * SCALE, 0)
	costsFrame:SetSize(160, 20)
	costsFrame:SetJustifyH("RIGHT")

	costsFrame.update = function()
		local enable = true		

		local costs = core.GetCosts()

		-- for k, slot in pairs(core.itemSlots) do
		-- 	if not enable and slot ~= "MainHandEnchantSlot" and slot ~= "SecondaryHandEnchantSlot" then
		-- 		local itemID, visualID, _, pendingID = core.TransmogGetSlotInfo(slot)

		-- 		if pendingID then
		-- 			enable = true --applyButton:Enable()
		-- 		end
		-- 	end
		-- end	

		-- for k, slot in pairs(core.itemSlots) do
		-- 	if enable and slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot" then
		-- 		local itemID, visualID, _, pendingID = core.TransmogGetSlotInfo(slot)
				
		-- 		if pendingID and not canReceiveTransmog(itemID, pendingID, slot) then
		-- 			enable = false
		-- 		end
		-- 	end
		-- end

		if not costs.copper then
			enable = false
		end
		
		if enable then
			costsFrame:SetText(core.GetPriceString(costs.points, costs.copper, true))
		else
			costsFrame:SetText("")
		end
	end
	costsFrame.update()
	core.RegisterListener("costs", costsFrame)

	balanceFrame = CreateFrame("Frame", nil, f)
	balanceFrame:SetPoint("BOTTOMRIGHT", -7 * SCALE, 14 * SCALE)
	balanceFrame:SetSize(200, 22 * SCALE)
	balanceFrame:EnableMouse()
	balanceFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		core.Tooltip_SetTransmogToken(GameTooltip)
	end)
	balanceFrame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)		
	balanceFrame.text = balanceFrame:CreateFontString()
	balanceFrame.text:SetFontObject(SCALE == 1 and "GameFontWhiteSmall" or "GameFontWhite")
	balanceFrame.text:SetPoint("RIGHT", -4 * SCALE, 0)
	balanceFrame.text:SetJustifyH("RIGHT")

	balanceFrame.background = balanceFrame:CreateTexture(nil, "BACKGROUND")--"UI-MONEYFRAME-BORDER")
	balanceFrame.background:SetTexture("Interface\\MONEYFRAME\\UI-MONEYFRAME-BORDER")
	balanceFrame.background:SetTexCoord(0, 1, 0, 19/32)
	balanceFrame.background:SetAllPoints()

	balanceFrame.update = function()
		local balance = core.GetBalance()
		balanceFrame.text:SetText(core.GetPriceString(balance and balance.shards or "?", GetMoney(), true))
		-- local balString = balance.shards
		-- if balString == nil then balString = "?" end
		-- balanceFrame.text:SetText(balString .. " |T" .. core.CURRENCY_ICON .. ":" .. 14 .. "|t\n" .. core.GetCoinTextureStringFull(GetMoney())) --balanceFrame:GetStringHeight()*1.3
	end
	balanceFrame.update()
	core.RegisterListener("balance", balanceFrame)
	core.RegisterListener("money", balanceFrame)
	
	local titleFrame = f:CreateFontString()
	titleFrame:SetFontObject("GameFontNormal")
	--titleFrame:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
	titleFrame:SetText(core.TRANSMOGRIFY)
	titleFrame:SetPoint("TOP", f, "TOP", 0, -19 * SCALE)


	-- f.inventoryButton = core.CreateMeATextButton(f, 100, 24, "Inventory")
	-- f.inventoryButton:SetPoint("BOTTOMRIGHT", model, "TOP", -5 * SCALE, 5 * SCALE)
	-- f.inventoryButton:SetScript("OnClick", function(self, button)
	-- 	core.SetSelectedSkin(nil)
	-- end)

	-- f.skinsButton = core.CreateMeATextButton(f, 100, 24, "Skins...")
	-- f.skinsButton:SetPoint("BOTTOMLEFT", model, "TOP", 5 * SCALE, 5 * SCALE)
	-- f.skinsButton:SetScript("OnClick", function(self, button)
	-- 	ToggleDropDownMenu(1, nil, skinDropDown, "MyAddonFrame", 0, 0)
	-- end)


	------- Inventory/Skins Tabs/Buttons -------------------
	f.TAB_NAMES = {core.INVENTORY, core.SKINS}
	f.tabs = {}
	f.buttons = {}

	local function tab_OnClick(self)
		--local selectedTab = PanelTemplates_GetSelectedTab(self:GetParent())
		-- local tab = tabs[selectedTab]
		-- if tab ~= nil then
		-- 	tab:Hide()
		-- end
		local id = self:GetID()
		if id == 1 then
			core.SetSelectedSkin(nil)
			core.SetSlotAndCategory(nil, nil)
			CloseDropDownMenus()
		else
			ToggleDropDownMenu(1, nil, skinDropDown, self:GetName(), 0, 0)
		end
		--tabs[self:GetID()]:Show()
		PlaySound("gsTitleOptionOK")
	end

	-- CharacterFrameTabButtonTemplate
	-- OptionsFrameTabButtonTemplate
	-- AchievementFrame has Example how to do it with simple Buttons instead of Tabs?
	-- since we still want to klick on skin tab, while we are already on a skin, we have to build our own tab buttons I think
	-- Just needs normal, active and highlight texture, a SetActive(true) function, if we want could make it auto resize on SetText
	-- active just changes the visual, we can still click on it to select another skin
	-- https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/SharedXML/SharedUIPanelTemplates.xml
	-- https://github.com/wowgaming/3.3.5-interface-files/blob/main/Blizzard_AchievementUI/Blizzard_AchievementUI.xml
	for i = 1, #f.TAB_NAMES do
		f.buttons["tab" .. i] = CreateFrame("Button", "$parentTab" .. i, f, "OptionsFrameTabButtonTemplate")
		local btn = f.buttons["tab" .. i]
		btn:SetText(f.TAB_NAMES[i])
		btn:SetID(i)
		if i == 1 then
			btn:SetPoint("BOTTOMRIGHT", model, "TOP", -5 * SCALE, 2 * SCALE)
		else
			btn:SetPoint("BOTTOMLEFT", f.buttons["tab" .. (i - 1)], "BOTTOMRIGHT")
		end
		btn:SetScript("OnClick", tab_OnClick)
		btn:SetScale(SCALE == 1 and 1 or 1.1)
	end	
	PanelTemplates_SetNumTabs(f, #f.TAB_NAMES)
	--tab_OnClick(_G[f:GetName().."Tab1"])
	
	f.update = function()
		local selectedSkin = core.GetSelectedSkin()
		local selectedSlot = core.GetSelectedSlot()
		local selectedSkinName = core.GetSelectedSkinName()

		if selectedSkin then
			local hasShieldHandWeaponSlot = core.HasShieldHandWeaponSlot()
			local i = hasShieldHandWeaponSlot and 2 or 1

			itemSlotFrames["MainHandSlot"]:SetPoint("BOTTOMRIGHT", model, "BOTTOM", ((hasShieldHandWeaponSlot and -itemSlotWidth or 0) - itemSlotDistance) / 2 * SCALE, 10)
			itemSlotFrames["OffHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", (itemSlotWidth * (i - 1) + itemSlotDistance * i) * SCALE, 0)
			itemSlotFrames["RangedSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", (itemSlotWidth * i + itemSlotDistance * (i + 2)) * SCALE, 0)
			core.SetShown(itemSlotFrames["ShieldHandWeaponSlot"], hasShieldHandWeaponSlot)
			core.SetShown(itemSlotFrames["SecondaryHandEnchantSlot"], hasShieldHandWeaponSlot)
			itemSlotFrames["OffHandSlot"]:Show()
		else
			local ohItemID = core.GetInventoryItemID("player", 17)
			local itemType = ohItemID and select(9, GetItemInfo(ohItemID))
			local showOffHandSlot = not itemType or core.IsOffHandItemType(itemType)

			itemSlotFrames["MainHandSlot"]:SetPoint("BOTTOMRIGHT", model, "BOTTOM",  -itemSlotDistance / 2 * SCALE, 10)
			itemSlotFrames["OffHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)
			itemSlotFrames["RangedSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", (itemSlotWidth + itemSlotDistance * 3) * SCALE, 0)
			core.SetShown(itemSlotFrames["ShieldHandWeaponSlot"], not showOffHandSlot)
			core.SetShown(itemSlotFrames["SecondaryHandEnchantSlot"], not showOffHandSlot)
			core.SetShown(itemSlotFrames["OffHandSlot"], showOffHandSlot)
		end
		
		PanelTemplates_SetTab(f, selectedSkin and 2 or 1)
		f.buttons["tab2"]:SetText(selectedSkin and core.SKIN .. ": " .. core.GetShortenedString(selectedSkinName, 14) or f.TAB_NAMES[2])
		f.buttons["tab2"]:Hide()
		f.buttons["tab2"]:Show()
		f.buttons["tab2"]:Enable()
		--f.buttons["tab2"]:SetNormalTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-Top")
		
		StaticPopup_Hide("ApplyTransmogPopup")		
		StaticPopup_Hide("TransferVisualsToSkinPopup")
	end
	f.update()
	core.RegisterListener("selectedSkin", f)
	core.RegisterListener("inventory", f)
	core.RegisterListener("currentChanges", f)
	
	f:Hide()
end