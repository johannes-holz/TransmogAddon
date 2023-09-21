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
local onlyMogableFilter = true
local nameFilter = true
local gossipFrameWidthBackup = 0

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
	for slot, pending in pairs(core.GetCurrentChanges()) do
		local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot, id)
		local _, link, _, _, _, _, _, _, _, tex = GetItemInfo(pendingID)
		if pendingID then
			local itemText = pendingID > 1 and (link and (core.GetTextureString(tex, 16) .. " " .. core.LinkToColoredString(link)) or pendingID) or core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
			tinsert(lines, core.SLOT_NAMES[slot])
			tinsert(lines, ": ")
			tinsert(lines, itemText)
			tinsert(lines, "\n")
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
					.. (costs.points and costs.copper and core.GetPriceString(costs.points, costs.copper) or "ERROR: Could not request costs from server.")				
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
    core.RequestPriceTotal()
    
    SetPortraitTexture(f.charTexture, "target")
end

local TransmogFrame_OnHide = function(self)
    PlaySound("igCharacterInfoClose")
	
    GossipFrameGreetingPanel:Show()
    GossipFrameCloseButton:Show()
    GossipFrame:SetAlpha(1)
    CloseGossip()
end


local SavePosition = function()
	local point, _, relativePoint, xOfs, yOfs = core.transmogFrame:GetPoint()
	if not MyAddonDB.Position then 
		MyAddonDB.Position = {}
	end
	MyAddonDB.Position.point = point
	MyAddonDB.Position.relativePoint = relativePoint
	MyAddonDB.Position.xOfs = xOfs
	MyAddonDB.Position.yOfs = yOfs	
end

local LoadPosition = function()
	if MyAddonDB.Position then
		core.transmogFrame:SetPoint(MyAddonDB.Position.point,UIParent,MyAddonDB.Position.relativePoint,MyAddonDB.Position.xOfs,MyAddonDB.Position.yOfs)
	else
		core.transmogFrame:SetPoint("CENTER", UIParent, "CENTER")
	end
end

core.PlayApplyAnimations = function()	
	for k, v in pairs(itemSlotFrames) do
		v:PlayApply()	
	end
end

core.InitializeFrame = function()	
	core.transmogFrame = CreateFrame("Frame", "MyAddonFrame", UIParent)
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

	--local func = CharacterFrameCloseButton:GetScript("OnClick")
	f:SetScript("OnShow", function()
		PlaySound("igCharacterInfoOpen")
		--CharacterFrame:Hide()
		--ToggleAchievementFrame()
		--ToggleAchievementFrame()
		--CharacterMicroButton_SetPushed()

		-- make an CollectionFrame:SetContainer function, that sets points etc, putting that stuff into onshow probable not optimal, since when we swap tabs, it would get called needlessly?
		-- at end of set container do self:SetTab(self.GetParent().selectedTab)
		f:SelectItemTab()

		--model:Hide() -- still needed?
		--model:Show()

		-- Request unlocks for all slots or only for currently selected slot?
		-- for slot, updateNeeded in pairs(core.availableMogsUpdateNeeded) do --TODO all the stuff about how and when to update unlocks for slot / item
		-- 	local itemID = core.TransmogGetSlotInfo(slot)
		-- 	if updateNeeded and itemID then
		-- 		core.RequestUnlocksSlot(slot)
		-- 	end
		-- end	
		
		if not core.GetBalance().shards then
			core.RequestBalance()
		end
		-- core.RequestPriceTotal() -- TODO: No point in using this anymore? If we want to request prices again, should probably make a function to recheck all pendings instead of using this
		
		SetPortraitTexture(f.portraitTexture, "target")
		f:update()
	end)

	f:SetScript("OnHide", function()	
		core.SetIsAtTransmogrifier(false)
		GossipFrameGreetingPanel:Show()
		GossipFrameCloseButton:Show()
		GossipFrame:SetAlpha(1)
		CloseGossip()
		PlaySound("igCharacterInfoClose")
	end)

	f.SelectItemTab = function(self)
		core.itemCollectionFrame:SetParent(self)
		core.itemCollectionFrame:SetPoint("TOPLEFT", model, "TOPRIGHT", 0, 4)
		core.itemCollectionFrame:Show()
		core.itemCollectionFrame:SetSlotAndCategory(core.GetSelectedSlot(), core.GetSelectedCategory(), true)
	end	
	
	f.BGTopLeft = f:CreateTexture(nil, "BACKGROUND")
	f.BGTopLeft:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AUCTIONFRAME-BID-TOPLEFT")
	f.BGTopLeft:SetSize(256 * SCALE, 256 * SCALE)
	f.BGTopLeft:SetPoint("TOPLEFT", f, "TOPLEFT")

	f.BGTop = f:CreateTexture(nil, "BACKGROUND")
	f.BGTop:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-Top")
	f.BGTop:SetSize(320 * SCALE, 256 * SCALE)
	f.BGTop:SetPoint("TOPLEFT", f.BGTopLeft, "TOPRIGHT")
	
	f.BGTopRight = f:CreateTexture(nil, "BACKGROUND")
	f.BGTopRight:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-TopRight")
	f.BGTopRight:SetSize(256* SCALE, 256 * SCALE)
	f.BGTopRight:SetPoint("TOPLEFT", f.BGTop, "TOPRIGHT")
	
	f.BGBottomLeft = f:CreateTexture(nil, "BACKGROUND")
	f.BGBottomLeft:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AUCTIONFRAME-BID-BOTLEFT")
	f.BGBottomLeft:SetSize(256 * SCALE, 256 * SCALE)
	f.BGBottomLeft:SetPoint("TOPLEFT", f.BGTopLeft, "BOTTOMLEFT")
	
	f.BGBottom = f:CreateTexture(nil, "BACKGROUND")
	f.BGBottom:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-Bot")
	f.BGBottom:SetSize(320 * SCALE, 256 * SCALE)
	f.BGBottom:SetPoint("TOPLEFT", f.BGBottomLeft, "TOPRIGHT")
	
	f.BGBottomRight = f:CreateTexture(nil, "BACKGROUND")
	f.BGBottomRight:SetTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AUCTIONFRAME-BID-BOTRIGHT")
	f.BGBottomRight:SetSize(256 * SCALE, 256 * SCALE)
	f.BGBottomRight:SetPoint("TOPLEFT", f.BGBottom, "TOPRIGHT")
	
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

	local exitButton = core.CreateMeAButton(f, 22 * SCALE, 22 * SCALE, nil,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Down", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", 90/512, 118/512, 451/512, 481/512,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled", 90/512, 118/512, 451/512, 481/512)
	--exitButton:SetFrameStrata("FULLSCREEN")																
	exitButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1 * SCALE, -15 * SCALE)
	exitButton:SetScript("OnClick", function() 
		f:Hide()
	end)
	
	f.portraitTexture = f:CreateTexture(nil, "BACKGROUND")
	f.portraitTexture:SetSize(58 * SCALE, 58 * SCALE)
	f.portraitTexture:SetPoint("TOPLEFT", 8 * SCALE, -7 * SCALE)
	SetPortraitTexture(f.portraitTexture, "player")

	local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	--local cancelButton = core.CreateMeACustomTexButton(model, 24, 24, "Interface\\AddOns\\".. folder .."\\images\\Transmogrify", left, top, right, bottom)
	local cancelButton = core.CreateMeACustomTexButton(model, doAllButtonWidth * SCALE, doAllButtonWidth * SCALE, "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 0, 0, 1, 1)
	cancelButton:SetPoint("TOPRIGHT", model, "TOPRIGHT", -4 * SCALE, -4 * SCALE)
	core.SetTooltip(cancelButton, core.RESET_ALL)
	cancelButton:SetScript("OnClick", function()
		core.SetCurrentChanges({})
	end)

	
	local left, top, right, bottom = 417/512, 90/512, 443/512,116/512
	local undressButton = core.CreateMeACustomTexButton(model, doAllButtonWidth * SCALE, doAllButtonWidth * SCALE, "Interface\\AddOns\\".. folder .."\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	--undressButton.ctex:SetAlpha(0.8)
	undressButton:SetPoint("TOPRIGHT", cancelButton, "TOPLEFT", -doAllButtonDistance * SCALE, 0)
	core.SetTooltip(undressButton, core.HIDE_ALL)
	
	undressButton:SetScript("OnClick", function()
		local tar = {}
		for _, slot in pairs(core.itemSlots) do
			tar[slot] = 1
		end
		core.SetCurrentChanges(tar)
	end)	
	undressButton:Show()

	core.showItemsUnderSkin = false -- Don't really wanna do the whole "SetX" "UpdateListeners" thing for this, since only preview model needs refresh
	local showItemsUnderSkinCheckButton = CreateFrame("CheckButton", folder .. "ShowItemsUnderSkinCheckButton", model)
	showItemsUnderSkinCheckButton:SetSize(20 * SCALE, 20 * SCALE)
	showItemsUnderSkinCheckButton:SetPoint("BOTTOMLEFT", 4 * SCALE, 4 * SCALE)
	showItemsUnderSkinCheckButton:SetChecked(core.showItemsUnderSkin)
	--skinOnItemsCheckButton:SetText("Only show mogable")
	--skinOnItemsCheckButton:GetNormalFontObject():SetTextColor(1, 1, 0)
	--skinOnItemsCheckButton.tooltip = "Only show the items you can currently use as Transmogsource."

	local makeTexture = function (frame, path, blend)
		local t = frame:CreateTexture()
		t:SetTexture(path)
		t:SetAllPoints(frame)
		if blend then
			t:SetBlendMode(blend)
		end
		return t
	end
	
	showItemsUnderSkinCheckButton:SetNormalTexture(makeTexture(showItemsUnderSkinCheckButton, "Interface\\Buttons\\UI-CheckBox-Up"))
	showItemsUnderSkinCheckButton:SetPushedTexture(makeTexture(showItemsUnderSkinCheckButton, "Interface\\Buttons\\UI-CheckBox-Down"))
	showItemsUnderSkinCheckButton:SetDisabledTexture(makeTexture(showItemsUnderSkinCheckButton, "Interface\\Buttons\\UI-CheckBox-Check-Disabled"))
	showItemsUnderSkinCheckButton:SetCheckedTexture(makeTexture(showItemsUnderSkinCheckButton, "Interface\\Buttons\\UI-CheckBox-Check"))
	showItemsUnderSkinCheckButton:SetHighlightTexture(makeTexture(showItemsUnderSkinCheckButton, "Interface\\Buttons\\UI-CheckBox-Highlight", "ADD"))
	core.SetTooltip(showItemsUnderSkinCheckButton, core.SHOW_ITEMS_UNDER_SKIN_TOOLTIP_TEXT, nil, nil, nil, nil, 1)
	showItemsUnderSkinCheckButton:SetScript("OnClick", function(self, button)
		core.showItemsUnderSkin = self:GetChecked()
		model:update()
	end)
	showItemsUnderSkinCheckButton.update = function(self)
		core.SetShown(self, core.GetSelectedSkin())
	end
	showItemsUnderSkinCheckButton:update()
	core.RegisterListener("selectedSkin", showItemsUnderSkinCheckButton)

	-- showItemsUnderSkinCheckButton.eyeTexture = showItemsUnderSkinCheckButton:CreateTexture()
	-- showItemsUnderSkinCheckButton.eyeTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-PORTRAIT")
	-- showItemsUnderSkinCheckButton.eyeTexture:SetSize(20 * SCALE, 20 * SCALE)
	-- showItemsUnderSkinCheckButton.eyeTexture:SetBlendMode("ADD")
	-- showItemsUnderSkinCheckButton.eyeTexture:SetPoint("LEFT", showItemsUnderSkinCheckButton, "RIGHT")

	local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	local removeAllMogButton = core.CreateMeACustomTexButton(model, doAllButtonWidth * SCALE, doAllButtonWidth * SCALE, "Interface\\AddOns\\".. folder .."\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	removeAllMogButton:SetPoint("RIGHT", undressButton, "LEFT", -doAllButtonDistance * SCALE, 0)
	core.SetTooltip(removeAllMogButton, core.UNMOG_ALL)
	
	removeAllMogButton:SetScript("OnClick", function()
		local tar = {}
		for _, slot in pairs(core.itemSlots) do				
			if slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot" then
				tar[slot] = 0
			end
		end
		core.SetCurrentChanges(tar)
	end)	
	removeAllMogButton:Show()

	for _, itemSlot in pairs(core.itemSlots) do
		if itemSlot ~= "MainHandEnchantSlot" and itemSlot ~= "SecondaryHandEnchantSlot" then
			itemSlotFrames[itemSlot] = core:CreateSlotButton(model, itemSlotWidth * SCALE, itemSlot)
		end
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

	itemSlotFrames["MainHandSlot"]:SetPoint("BOTTOMRIGHT", model, "BOTTOM", (core.HasRangeSlot() and -itemSlotWidth or 0) * SCALE, 10)
--	itemSlotFrames["SecondaryHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)
	itemSlotFrames["ShieldHandWeaponSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)
	itemSlotFrames["OffHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)

	itemSlotFrames["RangedSlot"]:SetPoint("LEFT", itemSlotFrames["OffHandSlot"], "RIGHT", itemSlotDistance * 2 * SCALE, 0)
	if not core.HasRangeSlot() then itemSlotFrames["RangedSlot"]:Hide() end -- TODO: remove rangeslot from core.itemSlots instead?
	
--	itemSlotFrames["MainHandEnchantSlot"]:SetPoint("RIGHT", itemSlotFrames["MainHandSlot"], "BOTTOMLEFT", -12, 0)
--	itemSlotFrames["SecondaryHandEnchantSlot"]:SetPoint("RIGHT", itemSlotFrames["SecondaryHandSlot"], "BOTTOMLEFT", -12, 0)
	
	
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
		local balString = balance.shards
		if balString == nil then balString = "?" end
		--balanceFrame.text:SetText(balString .. " |T" .. core.CURRENCY_ICON .. ":" .. 14 .. "|t\n" .. core.GetCoinTextureStringFull(GetMoney())) --balanceFrame:GetStringHeight()*1.3
		balanceFrame.text:SetText(core.GetPriceString(balance.shards, GetMoney(), true))
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
			itemSlotFrames["OffHandSlot"]:Show()
		else
			local ohItemID = core.GetInventoryItemID("player", 17)
			local itemType = ohItemID and select(9, GetItemInfo(ohItemID))
			local showOffHandSlot = not itemType or core.IsOffHandItemType(itemType)

			itemSlotFrames["MainHandSlot"]:SetPoint("BOTTOMRIGHT", model, "BOTTOM",  -itemSlotDistance / 2 * SCALE, 10)
			itemSlotFrames["OffHandSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", itemSlotDistance * SCALE, 0)
			itemSlotFrames["RangedSlot"]:SetPoint("LEFT", itemSlotFrames["MainHandSlot"], "RIGHT", (itemSlotWidth + itemSlotDistance * 3) * SCALE, 0)
			core.SetShown(itemSlotFrames["ShieldHandWeaponSlot"], not showOffHandSlot)
			core.SetShown(itemSlotFrames["OffHandSlot"], showOffHandSlot)
		end
		
		PanelTemplates_SetTab(f, selectedSkin and 2 or 1)
		f.buttons["tab2"]:SetText(selectedSkin and core.SKIN .. ": " .. core.GetShortenedString(selectedSkinName, 14) or f.TAB_NAMES[2])
		f.buttons["tab2"]:Hide()
		f.buttons["tab2"]:Show()
		f.buttons["tab2"]:Enable()
		--f.buttons["tab2"]:SetNormalTexture("Interface\\AddOns\\".. folder .."\\images\\UI-AuctionFrame-Bid-Top")
	end
	f.update()
	core.RegisterListener("selectedSkin", f)
	core.RegisterListener("inventory", f)
	
	f:Hide()
end

core.InitializeFrame()