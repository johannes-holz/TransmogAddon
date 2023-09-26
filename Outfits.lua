local folder, core = ...

--MyAddonDB.outfits = MyAddonDB.outfits or {}
-- Save per char or account?

core.GetOutfits = function()
    if not MyAddonDB then return end
    MyAddonDB.outfits = MyAddonDB.outfits or {}
    return MyAddonDB.outfits
end

core.IsInvalidOutfitName = function(name)    
	local denyMessage
	if string.len(name) < 1 then -- or name:gsub(" ", "") ?
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
    -- save as [name] = {slots} or [id] = {name = "name", slots = {slots}} ??
    local invalidReason = core.IsInvalidOutfitName(name)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end
    
    MyAddonDB.outfits = MyAddonDB.outfits or {}
    MyAddonDB.outfits[name] = core.DeepCopy(set)
    core.UpdateListeners("outfits")
    return true
end

core.DeleteOutfit = function(name)
    assert(name and MyAddonDB.outfits[name])

    MyAddonDB.outfits[name] = nil
    core.UpdateListeners("outfits")
end

core.RenameOutfit = function(oldName, newName) -- or oldName, newName ...    
    assert(oldName and MyAddonDB.outfits[oldName] and newName)

    local invalidReason = core.IsInvalidOutfitName(newName)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end

    MyAddonDB.outfits = MyAddonDB.outfits or {}
    MyAddonDB.outfits[newName] = MyAddonDB.outfits[oldName]
    MyAddonDB.outfits[oldName] = nil
    core.UpdateListeners("outfits")
    return true
end

core.SaveOutfit = function(name, set)
    assert(name and set and MyAddonDB.outfits[name])
    --AM("save", name, set)
    MyAddonDB.outfits[name] = set
    core.UpdateListeners("outfits")
    return true
end

-- Attempt at Outfit links

-- just realized it uses appearanceIDs and maybe not even the same ones as our original data
-- so no point in trying to stick to the same format?

-- Outfit slash command sample:
-- /outfit v1 7019,7017,0,0,7022,0,0,7015,7020,7016,7018,7021,70216,0,0,0,0
-- "v1" is the version so future formats won't break older slash commands
-- The comma-separated values are as follows:
-- 		Head		- appearanceID
--		Shoulder	- appearanceID
--		Shoulder	- secondaryAppearanceID (0 if shoulders aren't split)
-- 		Back		- appearanceID
--		Chest		- appearanceID
--		Body		- appearanceID
--		Tabard		- appearanceID
--		Wrist		- appearanceID
--		Hand		- appearanceID
--		Waist		- appearanceID
--		Legs		- appearanceID
--		Feet		- appearanceID
--		MainHand	- appearanceID
--		MainHand	- secondaryAppearanceID (0 if the weapon is from Legion Artifacts category, -1 otherwise)
--		MainHand	- illusionID
--		OffHand		- appearanceID
--		OffHand		- illusionID

local slashCommandMap = {
	[1] = "HeadSlot",
	[2] = "ShoulderSlot",
	[4] = "BackSlot",
	[5] = "ChestSlot",
	[6] = "ShirtSlot",
	[7] = "TabardSlot",
	[8] = "WristSlot",
	[9] = "HandsSlot",
	[10] = "WaistSlot",
	[11] = "LegsSlot",
	[12] = "FeetSlot",
	[13] = "MainHandSlot",
	-- [15] = "MainHandEnchantSlot",
	[16] = "SecondaryHandSlot",
	-- [17] = "SecondaryHandEnchantSlot",
	-- [18] = "RangedSlot",
}

-- blizzard uses explicit items for hidden slots

core.IsRangedWeapon = function(itemID)
    local _, _, inventoryType = core.GetItemData(itemID)
    return inventoryType == 15 or inventoryType == 25 or inventoryType == 26
end

-- Slash commands
core.ParseOutfitSlashCommand = function(msg)
    print(msg)
    if string.sub(msg, 1, 3) == "v1 " then
        -- TODO: Do some checking for correct format, params, length etc
        local items = { string.split(",", string.sub(msg, 4)) }
        local set = {}
        for i, itemID in pairs(items) do
            itemID = tonumber(itemID)
            local itemSlot = slashCommandMap[i]

            if itemSlot and itemID > 1 and core.GetItemData(itemID) then
                if itemSlot == "MainHandSlot" then
                    if core.IsRangedWeapon(itemID) then
                        itemSlot = "RangedSlot"
                    end
                end

                set[itemSlot] = itemID
            end
        end

        AM(set)        
        if not DressUpFrame:IsShown() then
            ShowUIPanel(DressUpFrame)
            DressUpModel:SetUnit("player")
        end
        DressUpModel:SetAll(set)
    end
end

SLASH_OUTFIT1 = "/outfit"
SlashCmdList["OUTFIT"] = core.ParseOutfitSlashCommand



-- SLASH_TEST1 = "/outfit"
-- SlashCmdList["TEST"] = function(msg)
--    print("Hello World!")
-- end 

--[[
Custom Itemlinks get denied by TrinityCore.
WeakAura appararently handles links by first just sending an unformated chat message alla "[WeakAuras: Charname - Displayname]"
People without the addon will see it like that, while people with addon will get it modified with chatfilters to a clickable link, that than has item link format and reads [Charname - Displayname]
On Clicking a custom Tooltip opens and in the background the data for Displayname will get requested from Charname

Unsure, why we do not directly we an addon chatmessage and manually add it to chatframe for everyone who received the message in the corresponding channel?
Maybe the latter is not so trivial, especially with chat addons etc?
]]



local outfitLinkType = "outfit_v1"

local linkMap = {
    
}

local ItemRefTooltip_OnSetHyperlink = function(self, itemString)
    local linkData = { strsplit(":", itemString) } -- item:itemID:enchantID:gemID1:::::::

    if linkType == outfitLinkType then
        -- Do whatever you want.
        print("outfit link")
    end
    if linkData[2] == outfitLinkType then
        print("data get")
        AM(linkData)
    end
end

hooksecurefunc(ItemRefTooltip, "SetHyperlink", ItemRefTooltip_OnSetHyperlink)

LINK = function()
    print("|Hitem:" .. outfitLinkType .. ":1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20|h[Click here!]|h")
    local link = "\124Hitem:" .. 2000
    for i = 1, 10 do
        link = link .. ":" .. (50000 + i)
    end
    link = link .. "\124h[Click here!]\124h"
    print(link)

    link = "|cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r"
    ChatEdit_InsertLink(link)
end


local function filterFunc(_, event, msg, player, l, cs, t, flag, channelId, ...)
    print(event, msg, player)
end
    

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", filterFunc)