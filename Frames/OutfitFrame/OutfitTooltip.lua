local folder, core = ...

core.ItemRefTooltipTryOnButton = core.CreateMeATextButton(ItemRefTooltip, 90, 22, core.TRY_ON)
core.ItemRefTooltipTryOnButton:SetPoint("BOTTOM", 0, 10)

core.ItemRefTooltipTryOnButton:SetScript("OnClick", function(self)
    if not DressUpFrame:IsShown() then
        ShowUIPanel(DressUpFrame)
        DressUpModel:SetUnit("player")
    end
    DressUpModel:SetAll(self.set)
end)

core.ItemRefTooltipTryOnButton:SetScript("OnHide", function(self)
    self.set = nil
end)

local counter = 0
core.ShowOutfitTooltip = function(set, isRefreshOf)
    if isRefreshOf then
        if counter > isRefreshOf then
            return
        end
    else
        counter = counter + 1
    end
    
    -- Imitate item tooltip behaviour and hide tooltip, if we click on same outfit again?
    if not isRefreshOf and core.DeepCompare(set, core.ItemRefTooltipTryOnButton.set) then
        HideUIPanel(ItemRefTooltip)
        return
    end

    ShowUIPanel(ItemRefTooltip)
    if ( not ItemRefTooltip:IsShown() ) then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    end
    ItemRefTooltip:ClearLines()

    ItemRefTooltip:AddLine(core.GetColoredString(core.OUTFIT, core.mogTooltipTextColor.hex))
    ItemRefTooltip:AddLine(" ")

    if not core.IsValidSet(set) then
        ItemRefTooltip.AddDoubleLine("Invalid Outfit data or format.")
    else
        local needsRefresh
        for _, slot in ipairs(core.allSlots) do
            if core.IsEnchantSlot(slot) then
                local enchantID = set[slot]
                if enchantID and enchantID ~= core.HIDDEN_ID and enchantID ~= core.UNMOG_ID then
                    local name, _, tex = GetSpellInfo(enchantID)
                    ItemRefTooltip:AddLine("      " .. (name and (core.GetTextureString(tex) .. " " .. name) or "unknown enchant localize me"))
                else
                    ItemRefTooltip:AddLine("      " .. (enchantID == core.HIDDEN_ID and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
                                                                    or core.GetColoredString("(" .. core.SLOT_NAMES[slot] .. ")", core.greyTextColor.hex)))
                end
            else
                local itemID = set[slot]
                if itemID and itemID ~= core.HIDDEN_ID and itemID ~= core.UNMOG_ID then
                    local texture = GetItemIcon(itemID)
                    local _, link = GetItemInfo(itemID)
                    -- link = link and core.GetShortenedString(core.LinkToColoredString(link), 42) or nil
                    link = link and core.LinkToColoredString(link)
                    ItemRefTooltip:AddLine((texture and core.GetTextureString(texture, 16) or "") .. " " .. (link or core.LOADING2))
                    -- if not link then core.FunctionOnItemInfo(itemID, core.ShowOutfitTooltip, set, counter) end
                    if not link then core.QueryItem(itemID); needsRefresh = itemID end
                else
                    ItemRefTooltip:AddLine("      " .. (itemID == core.HIDDEN_ID and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
                                                                    or core.GetColoredString("(" .. core.SLOT_NAMES[slot] .. ")", core.greyTextColor.hex)))
                end
            end
            if needsRefresh then core.FunctionOnItemInfo(needsRefresh, core.ShowOutfitTooltip, set, counter) end
        end

        ItemRefTooltip:AddLine(" ")
        ItemRefTooltip:AddLine(" ")

        core.ItemRefTooltipTryOnButton.set = set
        core.ItemRefTooltipTryOnButton:Show()
    end
    ItemRefTooltip:Show()
end

core.HideOutfitTooltipStuff = function()
    core.ItemRefTooltipTryOnButton:Hide()
    counter = counter + 1
end

ItemRefTooltip:HookScript("OnHide", core.HideOutfitTooltipStuff)