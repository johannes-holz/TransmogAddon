local folder, core = ...

-- MyAddonDB.outfits = MyAddonDB.outfits or {}
-- Save per char or account?

core.GetOutfits = function()
    if not MyAddonDB then return end
    MyAddonDB.outfits = MyAddonDB.outfits or {}
    return MyAddonDB.outfits
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

core.RenameOutfit = function(oldName, newName)
    assert(oldName and MyAddonDB.outfits[oldName] and newName)

    local invalidReason = core.IsInvalidOutfitName(newName)
    if invalidReason then
        UIErrorsFrame:AddMessage(invalidReason, 1.0, 0.1, 0.1, 1.0)
        return
    end

    MyAddonDB.outfits = MyAddonDB.outfits or {}
    local set = MyAddonDB.outfits[oldName]
    MyAddonDB.outfits[oldName] = nil
    MyAddonDB.outfits[newName] = set 
    
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


core.IsValidSet = function(set)
    return set and type(set) == "table"
end

-- From wiki https://wowwiki-archive.fandom.com/wiki/ItemLink, supposedly works with item links, strings, ids:
-- local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

ChatFrame_OnHyperlinkShow_Orig = ChatFrame_OnHyperlinkShow
ChatFrame_OnHyperlinkShow = function(self, link, text, button)
    local apiSet = core.API.DecodeOutfitLink(text)
    if apiSet then
        local set = core.FromApiSet(apiSet)
        -- SetItemRef would call HandleModifiedItemClick for us. When hooking into OnHyperlinkShow, we have to do this manually
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
    if type(link) == "number" then return end
    local apiSet = core.API.DecodeOutfitLink(link)
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

core.IsRangedWeapon = function(itemID)
    local _, _, inventoryType = core.GetItemData(itemID)
    return inventoryType == 15 or inventoryType == 25 or inventoryType == 26
end


-- Outfitlink en-/decoding is now done by the API

--[===[

local outfitLinkType = "outfit"

local NUM_MAX_SLOTS = 15
local chatEncodingIDToSlot = {
    -- [1] = "HeadSlot",
    -- [2] = "ShoulderSlot",
    -- -- [3] = "SecondaryShoulderSlot",
    -- [4] = "BackSlot",
    -- [5] = "ChestSlot",
    -- [6] = "ShirtSlot",
    -- [7] = "TabardSlot",
    -- [8] = "WristSlot",
    -- [9] = "HandsSlot",
    -- [10] = "WaistSlot",
    -- [11] = "LegsSlot",
    -- [12] = "FeetSlot",
    -- [13] = "MainHandSlot",
    -- -- [14] = "SecondaryMainHandSlot",
    -- -- [15] = "MainHandEnchantSlot",
    -- [16] = "SecondaryHandSlot",
    -- -- [17] = "SecondaryHandEnchantSlot",
    -- -- [18] = "RangedSlot",
    [1] = "HeadSlot",
	  [2] = "ShoulderSlot",
	  [3] = "BackSlot",
	  [4] = "ChestSlot",
	  [5] = "ShirtSlot",
	  [6] = "TabardSlot",
	  [7] = "WristSlot",
	  [8] = "HandsSlot",
	  [9] = "WaistSlot",
	  [10] = "LegsSlot",
	  [11] = "FeetSlot",
	  [12] = "MainHandSlot",
    [13] = "ShieldHandWeaponSlot",
	  [14] = "OffHandSlot",
    [15] = "RangedSlot",
	-- [16] = "MainHandEnchantSlot",
	-- [17] = "ShieldHandWeaponEnchantSlot",
}
local chatEncodingSlotToID = {}
for k, v in pairs(chatEncodingIDToSlot) do
    chatEncodingSlotToID[v] = k
end

core.EncodeOutfit = function(items)
    local string = ""
    for i = 1, NUM_MAX_SLOTS do
        local slot = chatEncodingIDToSlot[i]
        string = string .. ":" .. (slot and items[slot] or "0")
    end
    -- print("encoded:", string)
    return string
end

core.DecodeOutfit = function(link)
    -- we accept link or string format, but want to work with outfitString
    if strfind(link, "|H") then
        link = select(3, strfind(link, "|H(.-)|h"))
    end
    -- print("before decoding:", link)

    local data = { select(2, strsplit(":", link)) }
    local set = {}
    for i, itemID in ipairs(data) do
        local slot = chatEncodingIDToSlot[i]
        if slot and itemID ~= "" then
            itemID = tonumber(itemID)
            if itemID and itemID > 0 then
                set[slot] = itemID
            end
        end
    end
    return set
end

local keySize = 89
local asciiOffset = 33
local groupSize = 3
local empty = "z"
local hidden = "{"

local encodeID = function(itemID)
    if not itemID then
        return empty
    elseif itemID == 1 then
        return hidden
    else
        local code = ""
        for j = 1, groupSize do
            code = strchar((itemID % keySize) + asciiOffset) .. code
            itemID = math.floor(itemID / keySize)
        end
        return code
    end
end

core.EncodeOutfit2 = function(items)
    local string = ":"
    for i = 1, NUM_MAX_SLOTS do
        local slot = chatEncodingIDToSlot[i]
        string = string .. encodeID(slot and items[slot])
    end
    return string
end

core.DecodeOutfit2 = function(link)
    -- we accept link or string format, but want to work with outfitString
    if strfind(link, "|H") then
        link = select(3, strfind(link, "|H(.-)|h"))
    end
    -- print("before decoding:", link)

    local data = { select(2, strsplit(":", link)) }
    local decoded = {}

    local i = 1
    while i <= strlen(data) do
        local c = strsub(data, i, i)
        if c == empty then
            tinsert(decoded, 0)
            i = i + 1
        elseif c == hidden then
            tinsert(decoded, 1)
            i = i + 1
        else
            local sum = 0
            for j = 0, groupSize - 1 do
                sum = sum * keySize
                sum = sum + strbyte(data, i + j) - asciiOffset
            end
            tinsert(decoded, sum)
            i = i + 3
        end
    end

    AM(decoded)

    local set = {}
    for i, itemID in ipairs(set) do    
        local slot = chatEncodingIDToSlot[i]
        if slot and itemID ~= "" then
            itemID = tonumber(itemID)
            if itemID and itemID > 0 then
                set[slot] = itemID
            end
        end
    end

    AM(set)

    return set
end

-- "\124cffff00ff\124Houtfit:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000\124h[Transmog Outfit]\124h\124r"
core.GenerateOutfitLink = function(set, name) -- allow name? better not imo
    if not set or not core.IsValidSet(set) then return end

    local displayName = "[Transmog Outfit]"
    local color = core.mogTooltipTextColor.hex or "ffff00ff"
    return "\124c" .. color .. "\124H" .. outfitLinkType .. core.EncodeOutfit(set) .. "\124h" .. displayName .. "\124h\124r"
end

--]===]





--[[
Directly:
Option A: Jemandem direkt die Setinfo schicken. Dann bräuchte der andere aber wie in DressMe eine Liste empfangener outfits. Bin ich kein Fan von

Chatlinks:
Chatlinks haben imo den großen Vorteil, dass der Empfänger eine einfache Möglichkeit hat, zu entscheiden, ob und wann er das Set angucken will
Sind equivalent wie man sich auch so schon einzelne Items verlinkt, Sender kann ganz einfach entscheiden wo und wem er etwas senden will etc.

Option B: Chatlink und auf CHAT_MSG Event das Set im entsprechenden Channel broadcasten. Nachteil: Man kann zB. in SAY und YELL nicht Addon Nachrichten verschicken
Option C: Quasi voll im Stiel von WA. CHATMSG, die von anderen AddonUsern in einen Link umgewandelt wird, der Absendername und Identifier enthält
            Klickt jemand auf den Link wird Set von Absender abgefragt und bei Erhalt der Tooltip aktualisiert (wenn sichtbar und richtige ID) bzw Set anprobiert
            Braucht viel Aufwand und Schutz vor Abuse, aber vermutlich die höchstwertigste Lösung
Option D: Setdaten direkt in die Nachricht schreiben. Vorteil: Spart extrem viel Aufwand und sollte am reibungslosesten funktionieren
            Nachteil: Chat wird für nicht-addon user ziemlich vollgespammt? Würde dann zB so aussehen:
            [name:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000:2000]

]]

--[[
Custom Itemlinks get denied by Server.
WeakAura appararently handles links by first just sending an unformated chat message alla "[WeakAuras: Charname - Displayname]"
People without the addon will see it like that, while people with addon will get it modified with chatfilters to a clickable link, that than has item link format and reads [Charname - Displayname]
On Clicking a custom Tooltip opens and in the background the data for Displayname will get requested from Charname

Unsure, why we do not directly send an addon chatmessage and manually add it to chatframe for everyone who received the message in the corresponding channel?
Maybe the latter is not so trivial, especially with chat addons etc?
]]
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

-- SendAddonMessage("prefix", "text", "type", "target")
-- Can't send AddonMessage in every channal. Particularly no say/yell. Technically we could just put full outfit into the normal message, and display it however we want with chat filter for other addon users
-- Might be seen as too spammy tho for non-addon users
-- Is the chat paste approach generally ok tho? If we do it as chat pasted link style, we have to do it full WA style tho? Or even more scuffed
-- SEND = function(set, name)
--     if not set then return end

--     SendAddonMessage("outfit v1", core.EncodeOutfit(set), "PARTY")

--     local msg = "[Outfit: " .. UnitName("player") .. " - " .. (name or "Unnamed") .. "]"
--     SendChatMessage(msg, "PARTY")
-- end

-- local received = {}

-- local f = CreateFrame("Frame")
-- f:RegisterEvent("CHAT_MSG_ADDON")
-- f:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
--     print(event, prefix, msg, channel, sender)

--     if prefix == "outfit v1" and DressUpModel:IsShown() then
--         local set = core.DecodeOutfit(msg)
--         received[sender] = set
--     end
-- end)

-- -- |cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
-- local function filterFunc(_, event, msg, player, l, cs, t, flag, channelId, ...)
--     local start, finish, characterName, outfitName = msg:find("%[Outfit: ([^%s]+) %- (.+)%]")
--     print(event, msg, player, start, finish, characterName, outfitName)
--     local newMsg = msg
--     if characterName and outfitName then
--         newMsg = msg:sub(1, start - 1)
--             .. "|c" .. core.mogTooltipTextColor.hex .. "|Hitem:" .. outfitLinkType .. ":" .. characterName .. ":::::::::::::::" .. "|h[" .. "Outfit" .. " - " .. outfitName .. "]|h|r"
--             .. msg:sub(finish + 1)
--     end
--     return false, newMsg, player, l, cs, t, flag, channelId, ...
-- end

-- ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", filterFunc)
-- ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", filterFunc)

-- not sure what the custom link exploit was, that caused trinity core to filter out custom links, but just stick to the way WA does it and prehook?
-- local ItemRefTooltip_OnSetHyperlink = function(self, itemString)
--     local linkData = { strsplit(":", itemString) } -- item:itemID:enchantID:gemID1:::::::
--     local _, linkType, sender = strsplit(":", itemString)
    
--     AM(linkType, sender)
--     if linkType == outfitLinkType and received[sender] then
--         -- no mod: open some kind of tooltip
--         AM("open tooltip with:", received[sender])
--     end
-- end
-- hooksecurefunc(ItemRefTooltip, "SetHyperlink", ItemRefTooltip_OnSetHyperlink)


-- blizzard uses explicit items for hidden slots


-- Slash commands
-- TODO: Blizzard Slash commands use different VisualIDs, so no point in trying to make ours compatible
        -- Any point to slash commands then? Maybe to be able to share in external chat
--[[
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
]]


-- SLASH_TEST1 = "/outfit"
-- SlashCmdList["TEST"] = function(msg)
--    print("Hello World!")
-- end 




-- local outfitLinkType = "outfit_v1"

-- local linkMap = {
    
-- }

-- local ItemRefTooltip_OnSetHyperlink = function(self, itemString)
--     local linkData = { strsplit(":", itemString) } -- item:itemID:enchantID:gemID1:::::::

--     if linkType == outfitLinkType then
--         -- Do whatever you want.
--         print("outfit link")
--     end
--     if linkData[2] == outfitLinkType then
--         print("data get")
--         AM(linkData)
--     end
-- end

-- hooksecurefunc(ItemRefTooltip, "SetHyperlink", ItemRefTooltip_OnSetHyperlink)

-- LINK = function()
--     print("|Hitem:" .. outfitLinkType .. ":1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20|h[Click here!]|h")
--     local link = "\124Hitem:" .. 2000
--     for i = 1, 10 do
--         link = link .. ":" .. (50000 + i)
--     end
--     link = link .. "\124h[Click here!]\124h"
--     print(link)

--     link = "|cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r"
--     ChatEdit_InsertLink(link)
-- end