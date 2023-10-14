local folder, core = ...

-- Extra tooltip, that is attached to GameTooltip and shows item's visual while shift is pressed (also used to display item information in collection)
core.extraItemTooltip = CreateFrame("GameTooltip", folder .. "ExtraItemTooltip", GameTooltip, "GameTooltipTemplate")
core.extraItemTooltip:AddFontStrings(core.extraItemTooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
									 core.extraItemTooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ))
core.FixTooltip(core.extraItemTooltip)

core.extraItemTooltip:RegisterEvent("MODIFIER_STATE_CHANGED")
core.extraItemTooltip:SetScript("OnEvent", function(self, event, modifier, pressed, ...)
	if event == "MODIFIER_STATE_CHANGED" and (modifier == "LSHIFT" or modifier == "RSHIFT") then
		-- print(event, modifier, pressed, GameTooltip:GetOwner() and GameTooltip:GetOwner():GetName())
		self.pressed = pressed == 1
		if pressed == 1 then
			core.ShowExtraItemTooltip()
		else
			core.extraItemTooltip:Hide()
		end
	end
end)
GameTooltip:HookScript("OnHide", function(self)
	core.extraItemTooltip.item, core.extraItemTooltip.anchor = nil, nil
end)

core.SetExtraItemTooltip = function(itemID, anchor)
	core.extraItemTooltip.item = itemID
	core.extraItemTooltip.anchor = anchor

	-- print("????", core.extraItemTooltip:IsShown(), IsShiftKeyDown()) both of these are the opposite  as expected, when tabbing through mannequin items

	if core.extraItemTooltip.pressed or core.extraItemTooltip:IsShown() or IsShiftKeyDown()then
		core.ShowExtraItemTooltip()
	end
end

core.ShowExtraItemTooltip = function()
	local tooltip = core.extraItemTooltip
	if not tooltip.item then return end

	local item, anchor = tooltip.item, tooltip.anchor
	tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
	tooltip:SetHyperlink("item:" .. item)
	tooltip:Show()

    -- horizontal or vertical
	if anchor == "RIGHT" then
		local rightPos = GameTooltip:GetRight()
		local totalWidth = tooltip:GetWidth()
		tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")		
		tooltip:ClearAllPoints()
		if rightPos + totalWidth > GetScreenWidth() then
			tooltip:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT", 0, 0)
		else
			tooltip:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 0, 0)
		end
	else -- if anchor == "BOTTOM" then		
		local bottomPos = GameTooltip:GetRight()
		local totalHeight = tooltip:GetHeight()
		tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")		
		tooltip:ClearAllPoints()
		if bottomPos - totalHeight < 0 then
			tooltip:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 0)
		else
			tooltip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, 0)
		end
	end
	tooltip:SetHyperlink("item:" .. tooltip.item)
	tooltip:Show()
end

core.extraItemTooltip:HookScript("OnTooltipSetItem", core.TooltipDisplayTransmog)