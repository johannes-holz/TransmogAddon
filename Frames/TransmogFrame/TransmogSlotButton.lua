local folder, core = ...

local GetInventoryItemID = core.GetInventoryItemID
local SetSlotAndCategory = core.SetSlotAndCategory
local FunctionOnItemInfo = core.FunctionOnItemInfo

local TRANSMOGRIFY_TEXTURE = "Interface\\AddOns\\".. folder .."\\images\\Transmogrify"
local PENDING_ANIMATION_TEXTURE_NORMAL = "Interface\\AddOns\\" .. folder .. "\\images\\PendingAnimationTexture-Purple"
local PENDING_ANIMATION_TEXTURE_SKIN = "Interface\\AddOns\\" .. folder .. "\\images\\PendingAnimationTexture-Blue"

-- TODO: change to GetItemIcon or can those be wrong / do we still somehow rely on this FOO/item query anyway?
local SlotButton_UpdateIcon
SlotButton_UpdateIcon = function(self)    
    local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(self.itemSlot)
	local selectedSkin = core.GetSelectedSkin()

	local shown = (pendingID and pendingID ~= core.HIDDEN_ID and pendingID ~= core.UNMOG_ID) and pendingID
				or (not pendingID and skinVisualID and skinVisualID ~= core.HIDDEN_ID and skinVisualID ~= core.UNMOG_ID) and skinVisualID
				or (not selectedSkin and not pendingID and not skinVisualID and visualID and visualID ~= core.HIDDEN_ID and visualID ~= core.UNMOG_ID) and visualID
				or (not selectedSkin) and itemID

	if not shown then
		self.itex:Hide()
	else
        local icon = self.isEnchantSlot and select(3, GetSpellInfo(shown)) or select(10, GetItemInfo(shown))

        if not icon then
            FunctionOnItemInfo(shown, SlotButton_UpdateIcon, self)
            return
        end

        self.itex:SetTexture(icon)
        self.itex:Show()	
    end
end

local SlotButton_OnEnter = function(self)
	if self.blockedTex:IsShown() then return end

	self.htex:Show()
	
	core.itemSlotOptionsFrame:SetOwner(self)
	core.itemSlotOptionsFrame:Show()
	
	local itemID, visualID, skinVisualID, pendingID, costsShards, costsCopper, canTransmogrify, cannotTransmogrifyReason = core.TransmogGetSlotInfo(self.itemSlot)
	local selectedSkin = core.GetSelectedSkin()

	local itemNames = {}
	local itemNameColors = {}
	local itemIcons = {}
	for k, v in pairs({itemID, visualID, skinVisualID, pendingID}) do
		if v then
			if self.isEnchantSlot then
				local name, _, icon = GetSpellInfo(v)
				itemNames[v] = name
				itemNameColors[v] = { 1.0, 0.82, 0.0 } -- NORMAL_FONT_COLOR
				itemIcons[v] = icon
			else
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
				GameTooltip:SetHyperlink("item:" .. v)
				local mytext =_G["GameTooltipTextLeft" .. 1]
				local tex = select(10, GetItemInfo(v))
				itemNames[v] = mytext:GetText()--"["..mytext:GetText().."]")
				itemNameColors[v] = { mytext:GetTextColor() }
				itemIcons[v] = tex
			end
		end
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
	GameTooltip:ClearLines()

	if selectedSkin then
		GameTooltip:AddLine(core.SLOT_NAMES[self.itemSlot], 1, 1, 1, 1)
		if skinVisualID and skinVisualID ~= core.UNMOG_ID then -- visual and skinVisual should never be UNMOG_ID anyway?
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(core.TRANSMOG_TOOLTIP_CURRENT_MOG, core.skinTextColor.r, core.skinTextColor.g, core.skinTextColor.b, core.skinTextColor.a)
			if skinVisualID == core.HIDDEN_ID then
				GameTooltip:AddLine(core.HIDDEN, core.skinTextColor.r, core.skinTextColor.g, core.skinTextColor.b, core.skinTextColor.a)
			else
				GameTooltip:AddLine(itemNames[skinVisualID], itemNameColors[skinVisualID][1], itemNameColors[skinVisualID][2], itemNameColors[skinVisualID][3])
			end
		end
		if pendingID then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(core.TRANSMOG_TOOLTIP_PENDING_CHANGE, core.skinTextColor.r, core.skinTextColor.g, core.skinTextColor.b, core.skinTextColor.a)
			if pendingID == core.UNMOG_ID then
				GameTooltip:AddLine(core.TRANSMOG_TOOLTIP_REMOVE_SKIN, core.yellowTextColor.r, core.yellowTextColor.g, core.yellowTextColor.b, core.yellowTextColor.a)
			elseif pendingID == core.HIDDEN_ID then
				GameTooltip:AddLine(core.HIDDEN, core.skinTextColor.r, core.skinTextColor.g, core.skinTextColor.b, core.skinTextColor.a)
			else
				GameTooltip:AddLine(itemNames[pendingID], itemNameColors[pendingID][1], itemNameColors[pendingID][2], itemNameColors[pendingID][3])
			end
		end
	else			
		if itemID then
			GameTooltip:AddLine(itemNames[itemID], itemNameColors[itemID][1], itemNameColors[itemID][2], itemNameColors[itemID][3])
		elseif self.isEnchantSlot then
			GameTooltip:AddLine(core.SLOT_NAMES[self.itemSlot], 1, 1, 1, 1)
		end
		if visualID and visualID ~= core.UNMOG_ID then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(core.TRANSMOG_TOOLTIP_CURRENT_MOG, core.mogTooltipTextColor.r, core.mogTooltipTextColor.g, core.mogTooltipTextColor.b, core.mogTooltipTextColor.a)
			if visualID == core.HIDDEN_ID then
				GameTooltip:AddLine(core.HIDDEN, core.mogTooltipTextColor.r, core.mogTooltipTextColor.g, core.mogTooltipTextColor.b, core.mogTooltipTextColor.a)
			else
				GameTooltip:AddLine(itemNames[visualID], itemNameColors[visualID][1], itemNameColors[visualID][2], itemNameColors[visualID][3])
			end
		end			
		if pendingID then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(core.TRANSMOG_TOOLTIP_PENDING_CHANGE, core.mogTooltipTextColor.r, core.mogTooltipTextColor.g, core.mogTooltipTextColor.b, core.mogTooltipTextColor.a)
			if pendingID == core.UNMOG_ID then
				GameTooltip:AddLine(core.TRANSMOG_TOOLTIP_REMOVE_MOG, core.yellowTextColor.r, core.yellowTextColor.g, core.yellowTextColor.b, core.yellowTextColor.a)
			elseif pendingID == core.HIDDEN_ID then
				GameTooltip:AddLine(core.HIDDEN, core.mogTooltipTextColor.r, core.mogTooltipTextColor.g, core.mogTooltipTextColor.b, core.mogTooltipTextColor.a)				
			else
				GameTooltip:AddLine(itemNames[pendingID], itemNameColors[pendingID][1], itemNameColors[pendingID][2], itemNameColors[pendingID][3])
			end
		end
	end

	if costsShards or costsCopper then
		local color = selectedSkin and core.skinTextColor or core.mogTooltipTextColor

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(core.COSTS .. ":", color.r, color.g, color.b, color.a)
		GameTooltip:AddLine(core.GetPriceString(costsShards, costsCopper, true))
	end

	if cannotTransmogrifyReason then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Error: " .. cannotTransmogrifyReason, 1, 0, 0, 1)
	end

	if not (core.db and core.db.profile.General.hideControlHints) then
        local rL, gL, bL = GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
        local rR, gR, bR = GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(core.LEFT_CLICK, core.SELECT, rL, gL, bL, rR, gR, bR)
		if not core.IsWeaponSlot(self.itemSlot) then
        	GameTooltip:AddDoubleLine(core.SHIFT_LEFT_CLICK, core.HIDE, rL, gL, bL, rR, gR, bR)
		end
        GameTooltip:AddDoubleLine(core.CONTROL_LEFT_CLICK, core.UNMOG, rL, gL, bL, rR, gR, bR)
        GameTooltip:AddDoubleLine(core.ALT_LEFT_CLICK, core.CLEAR_PENDING, rL, gL, bL, rR, gR, bR)
    end
		
	GameTooltip:Show()
end

local SlotButton_OnLeave = function(self)
	self.htex:Hide()
	GameTooltip:Hide()
	core.itemSlotOptionsFrame:QueueHide()
end

local SlotButton_OnMouseDown = function(self, button)		
	if self.blockedTex:IsShown() then return end
	
	if IsShiftKeyDown() then
		if not core.IsWeaponSlot(self.itemSlot) then
			core.UndressSlot(self.itemSlot)
		end
	elseif IsControlKeyDown() then
		core.UnmogSlot(self.itemSlot)
	elseif IsAltKeyDown() then
		core.ClearPendingSlot(self.itemSlot)
	else
		SetSlotAndCategory(self.itemSlot, not self.isEnchantSlot and core.GetDefaultCategory(self.itemSlot))
	end
end

local SlotButton_update = function(self) -- Show and hide the right textures    
	local itemID, visualID, skinVisualID, pendingID, _, _, canTransmogrify, cannotTransmogrifyReason = core.TransmogGetSlotInfo(self.itemSlot)
	local selectedSkin = core.GetSelectedSkin()
	
	local correspondingWeapon = self.isEnchantSlot and core.TransmogGetSlotInfo(core.GetCorrespondingSlot(self.itemSlot))
	-- Slot or corresponding weaponslot empty
	if not selectedSkin and
			(not self.isEnchantSlot and not itemID or 
			 self.isEnchantSlot and not correspondingWeapon) then
		self.blockedTex:Show()
		self.moggedTex:Hide()
		self.itex:Hide()
		self.hiddenTex:Hide()
		self.itex:SetVertexColor(1, 1, 1)
		self.borderBackground:SetVertexColor(1, 1, 1)
		self.moggedTex:SetVertexColor(1, 1, 1)
		self.changedTex:Hide()
		self.changedTex2:Hide()
		self.mogTexSelected:Hide()
		self:SetScript("OnUpdate", nil)
		return
	else
		self.blockedTex:Hide()
	end

	-- Transmogrified Border Texture
	if pendingID and not canTransmogrify then
		self.moggedTex:Show()
		self.moggedTex:SetTexCoord(284/512, 330/512, 1/512, 45/512) -- red
	elseif selectedSkin and skinVisualID then
		self.moggedTex:Show()
		self.moggedTex:SetTexCoord(192/512, 237/512, 1/512, 45/512) -- blue
	elseif not selectedSkin and visualID and visualID ~= core.UNMOG_ID then
		self.moggedTex:Show()
		self.moggedTex:SetTexCoord(239/512, 283/512, 1/512, 45/512) -- purple
	else
		self.moggedTex:Hide()
	end

	-- Item Hidden Texture
	if pendingID == core.HIDDEN_ID or not pendingID and (selectedSkin and skinVisualID == core.HIDDEN_ID or not selectedSkin and visualID == core.HIDDEN_ID) then 
		self.hiddenTex:Show()
		local hColor = 0.5
		self.itex:SetVertexColor(hColor, hColor, hColor)
		self.borderBackground:SetVertexColor(hColor, hColor, hColor)
		self.moggedTex:SetVertexColor(hColor, hColor, hColor)
	else
		self.hiddenTex:Hide()
		self.itex:SetVertexColor(1, 1, 1)
		self.borderBackground:SetVertexColor(1, 1, 1)
		self.moggedTex:SetVertexColor(1, 1, 1)
	end

	-- Item Icon
	SlotButton_UpdateIcon(self)

	--Changedswirlytex
	if not self.applying then
		if pendingID and canTransmogrify then
			self.changedTex:Show()
			self.changedTex2:Show()
			self:SetScript("OnUpdate", self.OnUpdate_Animation)
		else
			self.changedTex:Hide()
			self.changedTex2:Hide()
			self:SetScript("OnUpdate", nil)
		end
	end

	-- Slot is selected Texture
	core.SetShown(self.mogTexSelected, core.GetSelectedSlot() == self.itemSlot)

	if GameTooltip:GetOwner() == self then
		SlotButton_OnEnter(self)
	end
end


core.CreateSlotButton = function(parent, width, itemSlot)
	local f = CreateFrame("Frame", itemSlot .. "Frame", parent)
	f.itemSlot = itemSlot
	f.isEnchantSlot = core.IsEnchantSlot(itemSlot)
	f:SetSize(width, width)
	f:EnableMouse()
	
	local defaultBackgroundTexture = select(2, core.GetItemSlotInfo(itemSlot))

	f.ntex = f:CreateTexture(nil, "BACKGROUND")
	f.ntex:SetTexture(defaultBackgroundTexture)
	f.ntex:SetAllPoints()
	
	f.itex = f:CreateTexture(nil, "BORDER")
	f.itex:SetAllPoints()
	
	f.htex = f:CreateTexture(nil, "OVERLAY") -- "HIGHLIGHT" would show automatically on hover, but we don't want that on blocked slots (could disable/enable mouse I guess)
	f.htex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	f.htex:SetAlpha(0.8)
	f.htex:SetBlendMode("ADD")
	f.htex:SetAllPoints()
	f.htex:Hide()
	
	f.borderBackground = f:CreateTexture(nil, "BORDER")
	f.borderBackground:SetTexture(TRANSMOGRIFY_TEXTURE)	
	local scale = 0.25
	f.borderBackground:SetPoint("TOPLEFT", f ,"TOPLEFT", -width * scale, width * scale)
	f.borderBackground:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width * scale, -width * scale)
	f.borderBackground:SetTexCoord(0.2128,0.7890,0.2128,0.8867,0.3105,0.7890,0.3105,0.8867)
	
	f.mogTexSelected = f:CreateTexture(nil, "ARTWORK")
	f.mogTexSelected:SetTexture(TRANSMOGRIFY_TEXTURE)
	scale = 0.36
	f.mogTexSelected:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale-1)
	f.mogTexSelected:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	local left, top, right, bottom = 107/512, 339/512, 166/512,397/512
	f.mogTexSelected:SetTexCoord(left, right, top, bottom)
	
	f.moggedTex = f:CreateTexture(nil, "ARTWORK")
	f.moggedTex:SetTexture(TRANSMOGRIFY_TEXTURE)
	scale = 0.12
	f.moggedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.moggedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale - 1)
	f.moggedTex:SetTexCoord(239/512, 282/512, 1/512, 43/512)
	f.moggedTex:Hide()
	
	f.hiddenTex = f:CreateTexture(nil, "ARTWORK")
	f.hiddenTex:SetTexture(TRANSMOGRIFY_TEXTURE)
	scale = -0.09
	f.hiddenTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.hiddenTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	f.hiddenTex:SetTexCoord(418/512, 443/512, 90/512, 116/512)
	f.hiddenTex:SetAlpha(0.8)
	
	f.blockedTex = f:CreateTexture(nil, "ARTWORK")
	f.blockedTex:SetTexture(TRANSMOGRIFY_TEXTURE)
	scale = 0.0
	f.blockedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.blockedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	f.blockedTex:SetTexCoord(483/512, 511/512, 85/512, 117/512)
	
	f.changedTex = f:CreateTexture(nil, "OVERLAY")
	f.changedTex:SetTexture(PENDING_ANIMATION_TEXTURE_NORMAL)
	local offset = 0.14 * width
	f.changedTex:SetPoint("TOPLEFT", -offset, offset)
	f.changedTex:SetPoint("BOTTOMRIGHT", offset, -offset - 3)
	f.changedTex:SetTexCoord(1/256, 239/5/256, 1/256, 239/5/256)
	--f.changedTex:SetAlpha(0.8)
	
	f.changedTex2 = f:CreateTexture(nil, "OVERLAY")
	f.changedTex2:SetTexture(TRANSMOGRIFY_TEXTURE)
	local offset = 0.12 * width
	f.changedTex2:SetPoint("TOPLEFT", -offset, offset)
	f.changedTex2:SetPoint("BOTTOMRIGHT", offset, -offset)
	f.changedTex2:SetTexCoord(376/512, 417/512, 1/512, 42/512)

	local timeSinceLastFrame, frameLength = 0, 1/12
	local row, column = 0, 0
	--local multi = 1
	--local applying = false
	f.applying = false
	local applyingMulti = 0
	local applyingCount = 0
	
	
	f.OnUpdate_Animation = function(self, elapsed)
		timeSinceLastFrame = timeSinceLastFrame + elapsed
		if timeSinceLastFrame > frameLength then
			column = column + 1
			if column == 5 then
				column = 0
				row = row + 1
			end
			if row == 5 then
				column = 1
				row = 0
			end
			local left, top, right, bottom = (239/5*row+1)/256, (239/5*column+1)/256, 239/5*(row+1)/256, 239/5*(column+1)/256
			self.changedTex:SetTexCoord(left, right, top, bottom)
			timeSinceLastFrame = timeSinceLastFrame - frameLength
			
			
			if core.GetSelectedSkin() then
				self.changedTex:SetTexture(PENDING_ANIMATION_TEXTURE_SKIN)
				self.changedTex2:SetTexCoord(418/512, 459/512, 1/512, 42/512)
			else
				self.changedTex:SetTexture(PENDING_ANIMATION_TEXTURE_NORMAL)
				self.changedTex2:SetTexCoord(376/512, 417/512, 1/512, 42/512)
			end
			
			if self.applying then
				if applyingCount < 12 then
					if applyingCount < 3 then
						applyingMulti = applyingMulti + 0.15				
					else
						applyingMulti = applyingMulti - 0.1
					end
					self.changedTex:SetPoint("TOPLEFT", -width*applyingMulti, width*applyingMulti)
					self.changedTex:SetPoint("BOTTOMRIGHT", width*applyingMulti, -width*applyingMulti)
					self.changedTex2:SetPoint("TOPLEFT", -width*applyingMulti, width*applyingMulti)
					self.changedTex2:SetPoint("BOTTOMRIGHT", width*applyingMulti, -width*applyingMulti)
					self.changedTex2:SetAlpha(applyingMulti)
					applyingCount = applyingCount + 1
				else
					local itemID, visualID, _, pendingID, _, _, canTransmogrify = core.TransmogGetSlotInfo(self.itemSlot)

					if pendingID and (self.isEnchantSlot or canTransmogrify) then
						self.changedTex:Show()
						self.changedTex2:Show()
						self:SetScript("OnUpdate", self.OnUpdate_Animation)
					else
						self.changedTex:Hide()
						self.changedTex2:Hide()
						self:SetScript("OnUpdate", nil)
					end
					local offset = 0.14 * width
					self.changedTex:SetPoint("TOPLEFT", -offset, offset)
					self.changedTex:SetPoint("BOTTOMRIGHT", offset, -offset - 3)
					local offset = 0.12 * width
					self.changedTex2:SetPoint("TOPLEFT", -offset, offset)
					self.changedTex2:SetPoint("BOTTOMRIGHT", offset, -offset)	
					self.changedTex2:SetAlpha(1)	
					self.applying = false
					applyingMulti = 0
					applyingCount = 0
				end
			end
		end
			
		--local multi = 1 + 2 * math.sin(GetTime()*3)
		--f.changedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale*multi, width*scale*multi)
		--f.changedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale*multi, -width*scale-3*multi)
	end
	
	
	f.PlayApply = function(self)
         local itemID, visualID, skinVisualID, pendingID, _, _, canTransmogrify = core.TransmogGetSlotInfo(self.itemSlot)
		 local selectedSkin = core.GetSelectedSkin()

		if pendingID and (f.isEnchantSlot or canTransmogrify) then
			self.applying = true
			applyingMulti = 0
			applyingCount = 0
			self.changedTex:Show()
			self.changedTex2:Show()
			self:SetScript("OnUpdate", self.OnUpdate_Animation)
		end
	end

	
	f:SetScript("OnMouseDown", SlotButton_OnMouseDown)
	f:SetScript("OnEnter", SlotButton_OnEnter)
	f:SetScript("OnLeave", SlotButton_OnLeave)
	f:SetScript("OnShow", SlotButton_update)    
	
	f.update = SlotButton_update
	core.RegisterListener("currentChanges", f)
	core.RegisterListener("availableMogs", f)
	core.RegisterListener("selectedSlot", f)
	core.RegisterListener("selectedSkin", f)
	core.RegisterListener("inventory", f)
	core.RegisterListener("costs", f)

	return f
end


core.CreateItemSlotOptionsFrame = function(parent)
	local itemSlotWidth = parent:GetWidth()
	
	core.itemSlotOptionsFrame = CreateFrame("Frame", nil, parent)
	local itemSlotOptionsFrame = core.itemSlotOptionsFrame
	itemSlotOptionsFrame:SetSize(itemSlotWidth / 2, itemSlotWidth * 1.5)
	itemSlotOptionsFrame:Hide()
	
	
	local left, top, right, bottom = 417/512, 90/512, 443/512,116/512
	itemSlotOptionsFrame.undressButton = core.CreateMeACustomTexButton(itemSlotOptionsFrame, itemSlotWidth / 2, itemSlotWidth / 2, TRANSMOGRIFY_TEXTURE, left, top, right, bottom)
	itemSlotOptionsFrame.undressButton:SetPoint("TOPRIGHT", itemSlotOptionsFrame, "TOPRIGHT")
	core.SetTooltip(itemSlotOptionsFrame.undressButton, core.HIDE)
	
	itemSlotOptionsFrame.undressButton:SetScript("OnClick", function()
		core.UndressSlot(itemSlotOptionsFrame.owner.itemSlot)
	end)	

	local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	itemSlotOptionsFrame.removeMogButton = core.CreateMeACustomTexButton(itemSlotOptionsFrame, itemSlotWidth / 2, itemSlotWidth / 2, TRANSMOGRIFY_TEXTURE, left, top, right, bottom)
	itemSlotOptionsFrame.removeMogButton:SetPoint("TOPRIGHT", itemSlotOptionsFrame.undressButton, "BOTTOMRIGHT")
	core.SetTooltip(itemSlotOptionsFrame.removeMogButton, core.UNMOG)

	itemSlotOptionsFrame.removeMogButton:SetScript("OnClick", function()
		core.UnmogSlot(itemSlotOptionsFrame.owner.itemSlot)
	end)

	itemSlotOptionsFrame.clearPendingButton = core.CreateMeACustomTexButton(itemSlotOptionsFrame, itemSlotWidth / 2, itemSlotWidth / 2, "Interface\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent", 0, 0, 1, 1)
	itemSlotOptionsFrame.clearPendingButton:SetPoint("TOPRIGHT", itemSlotOptionsFrame.removeMogButton, "BOTTOMRIGHT")
	core.SetTooltip(itemSlotOptionsFrame.clearPendingButton, core.CLEAR_PENDING)

	itemSlotOptionsFrame.clearPendingButton:SetScript("OnClick", function()
		core.ClearPendingSlot(itemSlotOptionsFrame.owner.itemSlot)
	end)
	
	itemSlotOptionsFrame.SetOwner = function(self, frame)
		self.hideMe = false
		self:Hide()
		self.owner = frame
	end
	
	itemSlotOptionsFrame.QueueHide = function(self)
		self.hideMe = true
		core.MyWaitFunction(0.1, self.HideNow, self)
	end
	
	itemSlotOptionsFrame.HideNow = function(self)
		if self.hideMe == true then
			self:Hide()
		end
	end
	
	itemSlotOptionsFrame:SetScript("OnShow", function(self)
		if not self.owner then self:Hide(); return end
		self:SetPoint("RIGHT", self.owner, "LEFT", 0, core.IsWeaponSlot(self.owner.itemSlot) and itemSlotWidth / 4 or 0)
		core.SetShown(self.undressButton, not core.IsWeaponSlot(self.owner.itemSlot))
	end)
	
	local children = { itemSlotOptionsFrame:GetChildren() }

	for _, child in pairs(children) do
		child:HookScript("OnEnter", function(self)
			self:GetParent().hideMe = false
		end)
		child:HookScript("OnLeave", function(self)
			self:GetParent():QueueHide()
		end)
	end	
	
	itemSlotOptionsFrame:SetScript("OnLeave", function(self)
		self:Hide()
	end)
end