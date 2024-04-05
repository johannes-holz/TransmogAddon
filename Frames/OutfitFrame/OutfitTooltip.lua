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

-- TODO: refresh on iteminfo with second parameter, that indicates that this is a refresh and should not show, if tooltip is set to something else?
core.ShowOutfitTooltip = function(set)
    -- Imitate item tooltip behaviour and hide tooltip, if we click on same outfit again?
    if core.DeepCompare(set, core.ItemRefTooltipTryOnButton.set) then
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
        for _, slot in pairs(core.itemSlots) do            
            local itemID = set[slot]
            if itemID and itemID > 1 then
                local texture = GetItemIcon(itemID)
                local _, link = GetItemInfo(itemID)
                -- link = link and core.GetShortenedString(core.LinkToColoredString(link), 42) or nil
                link = link and core.LinkToColoredString(link) or nil
                ItemRefTooltip:AddLine(core.GetTextureString(texture, 16) .. " " .. (link or core.LOADING2))
            else
                ItemRefTooltip:AddLine("      " .. (itemID == 1 and core.GetColoredString(core.HIDDEN, core.mogTooltipTextColor.hex)
                                                                or core.GetColoredString("(" .. core.SLOT_NAMES[slot] .. ")", core.greyTextColor.hex)))
            end
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
end

ItemRefTooltip:HookScript("OnHide", core.HideOutfitTooltipStuff)