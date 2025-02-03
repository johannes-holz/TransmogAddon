local folder, core = ...


--[[ ScrollFrame Attempt. Don't feel like ScrollFrame is needed tho
local function CreateScrollFrame(parent)
    local frame = CreateFrame("Frame", folder .. "EnchantUnlockFrame", UIParent, "UIPanelDialogTemplate")
    frame:SetSize(340, 250)
    frame:SetPoint("CENTER")
    
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetToplevel(true) -- raises frame level to be on top of other frames on mouse click
    tinsert(UISpecialFrames, frame:GetName()) -- close on escape

    frame.title:SetText("UNLOCKABLE ENCHANTS")


    local scrollFrame = CreateFrame("ScrollFrame", folder .. "EnchantScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 200)
    scrollFrame:SetPoint("BOTTOMLEFT", 5, 9)    
    scrollFrame:SetPoint("TOPRIGHT", -30, -27)

    -- scrollFrame:SetBackdrop(core.BACKDROP_TOAST_ONLY_BORDER_12_12)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetPoint("TOP")
    content:SetSize(280, 200)
    scrollFrame:SetScrollChild(content)
    content.buttons = {}

    return frame, scrollFrame, content
end

local function CreateButton(parent, index, itemID)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(280, 40)
    button:SetPoint("TOP", 10, -(index - 1) * 45 - 10)
    
    button:SetScript("OnClick", function()
        core.debug("Ausgewähltes Item:", itemID)
    end)

    button.SetItem = function(self, itemID)
        self.itemID = itemID
        self:SetText(itemID)
    end

    button:SetItem(itemID)
    
    return button
end

core.UpdateScrollFrame = function(content, items)
    for i, item in ipairs(items) do
        content.buttons[i] = content.buttons[i] or CreateButton(content, i, item)
        content.buttons[i]:SetItem(item)
        content.buttons[i]:Show()
    end
    for i = #items + 1, #content.buttons do
        content.buttons[i]:Hide()
    end
    content:SetHeight(#items * 45)
end


a = {1, 2, 3, 4, 5, 6, 7, 8}
b = {1, 2, 3}


FrameYo, SF, Content = CreateScrollFrame(UIParent)
core.UpdateScrollFrame(Content, a)

]]

-- EnchantScrolls to enchant spellID map ([itemID] = spellID)
-- local unlockMapping = {
--     [38879] = 23799,
--     [38919] = 27971,
--     [38923] = 27981,
--     [38925] = 27984,
--     [38926] = 28003,
--     [38927] = 28004,
--     [38946] = 34010,
--     [44453] = 60621,
--     [45056] = 62948,
-- }

core.FindUnlockables = function()
    local itemToSpellMap = core.enchantInfo.itemToSpellID
    local items = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemID = GetContainerItemID(bag, slot)
            local spellID = itemID and itemToSpellMap[itemID]
            local unlocked = spellID and core.GetEnchantData(spellID)
            if spellID and unlocked ~= 1 then
                tinsert(items, itemID)
            end
        end
    end
    return items
end

StaticPopupDialogs["UnlockEnchantsPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)
        core.RequestUnlockVisuals(data.items)
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

--Expects a valid selection of enchant scrolls or similar items that can be used to unlock enchants
core.OpenUnlockEnchantsPopup = function(items)
    local data = {}
    data.items = items
    data.disable = not items or #items == 0
    if not data.disable then
        data.text = core.ENCHANT_UNLOCK_POPUP_TEXT
        for i, itemID in ipairs(items) do
            local tex = GetItemIcon(itemID) or ""
            local name, link = GetItemInfo(itemID)
            data.text = data.text .. "\n" .. core.GetTextureString(tex) .. " " .. (link and core.LinkToColoredString(link) or itemID)
        end
        
        local popup = StaticPopup_Show("UnlockEnchantsPopup", nil, nil, data)
    end
end

core.CreateUnlockEnchantsButton = function(parent, width, height)
    local button = CreateFrame("Button", nil, parent) -- , "UIPanelButtonTemplate")
    button:SetSize(width, height)
    -- button:SetText("Unlock Enchants")
    button:SetMotionScriptsWhileDisabled(true)

    button:SetScript("OnClick", function(self, button)
        local items = core.FindUnlockables()
        core.OpenUnlockEnchantsPopup(items)
    end)

    button:HookScript("OnEnter", function(self)    
        local text = self:IsEnabled() == 1 and core.ENCHANT_UNLOCK_BUTTON_TOOLTIP1 or core.ENCHANT_UNLOCK_BUTTON_TOOLTIP2
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, 1)
        GameTooltip:Show()
    end)

    button:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    button:HookScript("OnMouseDown", function(self, b)
        if self:IsEnabled() == 0 then return end
        self.oldPoint = { self:GetPoint(1) }
        local point, relativeTo, relativePoint, xOfs, yOfs = unpack(self.oldPoint)
        self:ClearAllPoints()
        self:SetPoint(point, relativeTo, relativePoint, xOfs - 1, yOfs - 1)
    end)

    button:HookScript("OnMouseUp", function(self, b)
        if self:IsEnabled() == 0 then return end
        self:ClearAllPoints()
        self:SetPoint(unpack(self.oldPoint))
    end)

    local enchantButtonTex = "Interface/Icons/inv_scroll_05"

    button:SetNormalTexture(enchantButtonTex)
    button:SetPushedTextOffset(-10, 50)
    button:SetPushedTexture(enchantButtonTex)
    button:GetPushedTexture():ClearAllPoints()
    button:GetPushedTexture():SetPoint("BOTTOMLEFT", 1, 1)
    button:GetPushedTexture():SetPoint("TOPRIGHT", -1, -1)
    -- button:SetPushedTextOffset(-10, 50)
    -- button:GetPushedTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    -- button:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", 0, 0, 1, 1)
    button:GetHighlightTexture():SetBlendMode("ADD")
    button:SetDisabledTexture(enchantButtonTex)
    button:GetDisabledTexture():SetDesaturated(1)

    button.plusTex = button:CreateTexture(nil, "OVERLAY")
    button.plusTex:SetTexture("Interface/Buttons/UI-PlusMinus-Buttons")
    button.plusTex:SetTexCoord(0, 0.5, 0, 0.5)
    button.plusTex:SetSize(button:GetWidth() / 2, button:GetHeight() / 2)
    button.plusTex:SetPoint("BOTTOMRIGHT")
    button.plusTex:SetAlpha(0.8)

	button.update = function(self)
        if #core.FindUnlockables() > 0 then self:Enable() else self:Disable() end
		core.SetShown(self, selectedSlot and core.IsEnchantSlot(selectedSlot))
	end
	core.RegisterListener("selectedSlot", button)

    button:HookScript("OnShow", button.update)

    return button
end