local folder, core = ...

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
        print("Ausgewähltes Item:", itemID)
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



local unlockMapping = {
    [38923] = 27981,
    [38925] = 27984,
    [38926] = 28003,
    [38927] = 28004,
    [44453] = 60621,
    [38919] = 27971,
}

core.FindUnlockables = function()
    local items = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemID = GetContainerItemID(bag, slot)
            local spellID = itemID and unlockMapping[itemID]
            local unlocked = spellID and core.GetEnchantData(spellID)
            if spellID and unlocked ~= 1 then
                tinsert(items, itemID)
            end
        end
    end
    return items
end

a = {1, 2, 3, 4, 5, 6, 7, 8}
b = {1, 2, 3}


FrameYo, SF, Content = CreateScrollFrame(UIParent)
core.UpdateScrollFrame(Content, a)


StaticPopupDialogs["UnlockEnchantsPopup"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = nil,
	OnAccept = function(self, data)
        core.RequestUnlockVisuals(data.items)
        core.am("Request unlocks", data.items)
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
        data.text = "Seid ihr sicher, dass ihr folgende Verzauberungen zur Transmogrifikation freischalten wollt? Die Gegenstände werden dabei zerstört.\n"
        for i, itemID in ipairs(items) do
            local tex = GetItemIcon(itemID) or ""
            local name, link = GetItemInfo(itemID)
            data.text = data.text .. "\n" .. core.GetTextureString(tex) .. " " .. (link and core.LinkToColoredString(link) or itemID)
        end
    else
        data.text = "Keine Verzauberungen zum Freischalten ausgewählt."
    end
    local popup = StaticPopup_Show("UnlockEnchantsPopup", nil, nil, data)
end

core.CreateUnlockEnchantsButton = function(parent, width, height)

    local UnlockEnchantsButton = CreateFrame("Button", nil, parent) -- , "UIPanelButtonTemplate")
    UnlockEnchantsButton:SetSize(width, height)
    -- UnlockEnchantsButton:SetText("Unlock Enchants")
    UnlockEnchantsButton:SetMotionScriptsWhileDisabled(true)

    UnlockEnchantsButton:SetScript("OnClick", function(self, button)
        local items = core.FindUnlockables()
        core.OpenUnlockEnchantsPopup(items)
    end)

    UnlockEnchantsButton:HookScript("OnEnter", function(self)    
        local text = self:IsEnabled() == 1 and "Schaltet Verzauberungen aus eurem Inventar zur Transmogrifikation frei."
                                    or "Ihr habt keine Schriftrollen zum Freischalten von Transmogrifikationen."	
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, 1)
        GameTooltip:Show()
    end)

    UnlockEnchantsButton:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    UnlockEnchantsButton:HookScript("OnMouseDown", function(self, button)
        if self:IsEnabled() == 0 then return end
        self.oldPoint = {UnlockEnchantsButton:GetPoint(1)}
        local point, relativeTo, relativePoint, xOfs, yOfs = unpack(self.oldPoint)
        self:ClearAllPoints()
        self:SetPoint(point, relativeTo, relativePoint, xOfs - 1, yOfs - 1)
    end)

    UnlockEnchantsButton:HookScript("OnMouseUp", function(self, button)
        if self:IsEnabled() == 0 then return end
        self:ClearAllPoints()
        self:SetPoint(unpack(self.oldPoint))
    end)

    local enchantButtonTex = "Interface/Icons/inv_scroll_05"

    UnlockEnchantsButton:SetNormalTexture(enchantButtonTex)
    UnlockEnchantsButton:SetPushedTextOffset(-10, 50)
    UnlockEnchantsButton:SetPushedTexture(enchantButtonTex)
    UnlockEnchantsButton:GetPushedTexture():ClearAllPoints()
    UnlockEnchantsButton:GetPushedTexture():SetPoint("BOTTOMLEFT", 1, 1)
    UnlockEnchantsButton:GetPushedTexture():SetPoint("TOPRIGHT", -1, -1)
    -- UnlockEnchantsButton:SetPushedTextOffset(-10, 50)
    -- UnlockEnchantsButton:GetPushedTexture():SetTexCoord(0.1, 0.9, 0.1, 0.9)
    UnlockEnchantsButton:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
    -- UnlockEnchantsButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", 0, 0, 1, 1)
    UnlockEnchantsButton:GetHighlightTexture():SetBlendMode("ADD")
    UnlockEnchantsButton:SetDisabledTexture(enchantButtonTex)
    UnlockEnchantsButton:GetDisabledTexture():SetDesaturated(1)

    UnlockEnchantsButton.plusTex = UnlockEnchantsButton:CreateTexture(nil, "OVERLAY")
    UnlockEnchantsButton.plusTex:SetTexture("Interface/Buttons/UI-PlusMinus-Buttons")
    UnlockEnchantsButton.plusTex:SetTexCoord(0, 0.5, 0, 0.5)
    UnlockEnchantsButton.plusTex:SetSize(UnlockEnchantsButton:GetWidth() / 2, UnlockEnchantsButton:GetHeight() / 2)
    UnlockEnchantsButton.plusTex:SetPoint("BOTTOMRIGHT")
    UnlockEnchantsButton.plusTex:SetAlpha(0.8)

	UnlockEnchantsButton.update = function(self)
		print("yoyoyo", selectedSlot and core.IsEnchantSlot(selectedSlot))
        if #core.FindUnlockables() > 0 then self:Enable() else self:Disable() end
		core.SetShown(self, selectedSlot and core.IsEnchantSlot(selectedSlot))
	end
	core.RegisterListener("selectedSlot", UnlockEnchantsButton)

    UnlockEnchantsButton:HookScript("OnShow", UnlockEnchantsButton.update)

    return UnlockEnchantsButton
end