local folder, core = ...

core.GetOutfits = function()
    if not TransmoggyDB then return end
    TransmoggyDB.outfits = TransmoggyDB.outfits or {}
    return TransmoggyDB.outfits
end

core.IsInvalidOutfitName = function(name)    
	local denyMessage
	if string.len(name) < 1 then -- or require visible char with name:gsub(" ", "") ?
		denyMessage = core.OUTFIT_NAME_TOO_SHORT
	elseif string.find(name, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz _.,'1234567890]") then
		denyMessage = core.OUTFIT_NAME_INVALID_CHARACTERS
    elseif core.GetOutfits()[name] then
        denyMessage = core.OUTFIT_NAME_ALREADY_IN_USE
    end
	
	return denyMessage
end

core.CreateOutfit = function(name, set)
    assert(name and set, "CreateOutfit: Missing name or set parameter")

    local invalidReason = core.IsInvalidOutfitName(name)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end
    
    TransmoggyDB.outfits = TransmoggyDB.outfits or {}
    TransmoggyDB.outfits[name] = core.DeepCopy(set)
    core.UpdateListeners("outfits")
    return true
end

core.DeleteOutfit = function(name)
    assert(name and TransmoggyDB.outfits[name])

    TransmoggyDB.outfits[name] = nil
    core.UpdateListeners("outfits")
end

core.RenameOutfit = function(oldName, newName)
    assert(oldName and TransmoggyDB.outfits[oldName] and newName)

    local invalidReason = core.IsInvalidOutfitName(newName)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end

    TransmoggyDB.outfits = TransmoggyDB.outfits or {}
    local set = TransmoggyDB.outfits[oldName]
    TransmoggyDB.outfits[oldName] = nil
    TransmoggyDB.outfits[newName] = set 
    
    core.UpdateListeners("outfits")
    return true
end

core.SaveOutfit = function(name, set)
    assert(name and set and TransmoggyDB.outfits[name])
    
    TransmoggyDB.outfits[name] = set
    core.UpdateListeners("outfits")
    return true
end


core.IsValidSet = function(set)
    return set and type(set) == "table"
end

ChatFrame_OnHyperlinkShow_Orig = ChatFrame_OnHyperlinkShow
ChatFrame_OnHyperlinkShow = function(self, link, text, button)
    local apiSet = type(text) == "string" and core.API.DecodeOutfitLink(text)
    if apiSet then
        local set = core.FromApiSet(apiSet)
        
        if IsModifiedClick("CHATLINK") then
            if ChatEdit_InsertLink(text) then
                return true
            end
        end

        if IsModifiedClick("DRESSUP") then
            DressUpItemLink(text)
            return true
        end

        core.ShowOutfitTooltip(set)
        return true
    end

    core.HideOutfitTooltipStuff() -- or Hook OnTooltipCleared?
    
    return ChatFrame_OnHyperlinkShow_Orig(self, link, text, button)
end

local OnDressUpItemLink = function(link)
    local apiSet = type(link) == "string" and core.API.DecodeOutfitLink(link)
    if apiSet then
        if not DressUpFrame:IsShown() then
            ShowUIPanel(DressUpFrame)
            DressUpModel:SetUnit("player")
        end
        DressUpModel:SetAll(core.FromApiSet(apiSet))
        return true
    end
end

local DressUpItemLinkOrig = DressUpItemLink
DressUpItemLink = function(link)
    if not OnDressUpItemLink(link) then
        return DressUpItemLinkOrig(link)
    end
end
