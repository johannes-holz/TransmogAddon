local folder, core = ...

-- UPDOOTS --
local rshift = bit.rshift
local lshift = bit.lshift
local mod = bit.mod

local strbyte = strbyte


-- Becomes neccessary when we need more than 32 bits per item!!!
-- local rShiftOld = bit.rshift
-- local pot = {}
-- for i = 0, 63 do
-- 	pot[i] = 2 ^ i
-- end
-- rshift = function(num, bits)
-- 	if num >= pot[32] or bits > 31 then
-- 		return math.floor(num / pot[bits])
-- 	else
-- 		return rshiftOld(num, bits)
-- 	end
-- end



core.inventoryTypes = { -- These IDs are used in our original item Data
	[1] = "INVTYPE_HEAD",
	[3] = "INVTYPE_SHOULDER",
	[4] = "INVTYPE_BODY",
	[5] = "INVTYPE_CHEST",
	[20] = "INVTYPE_ROBE",
	[6] = "INVTYPE_WAIST",
	[7] = "INVTYPE_LEGS",
	[8] = "INVTYPE_FEET",
	[9] = "INVTYPE_WRIST",
	[10] = "INVTYPE_HAND",
	[16] = "INVTYPE_CLOAK",
	[19] = "INVTYPE_TABARD",
	[13] = "INVTYPE_WEAPON",
	[14] = "INVTYPE_SHIELD",
	[17] = "INVTYPE_2HWEAPON",
	[21] = "INVTYPE_WEAPONMAINHAND",
	[22] = "INVTYPE_WEAPONOFFHAND",
	[23] = "INVTYPE_HOLDABLE",
	[15] = "INVTYPE_RANGED",
	[25] = "INVTYPE_THROWN",
	[26] = "INVTYPE_RANGEDRIGHT",
}


-- These are are called in the loading process and afterwards the generated data gets converted to a more compressed data format. Calling these later on would not influence our compressed data atm
-- Want to change the way our data is stored in file at some point (thousands AddItem calls -> table), so we dont generate so much garbage at load (and loading should also be quicker?)

core.AddEnchant = function(visualID, enchantID, spellID)
	if not (visualID and enchantID) then return false end
	--core.am(visualID..", "..enchantID)
	core.enchants = core.enchants or {}
	if core.enchants[visualID] then
		table.insert(core.enchants[visualID]["enchantIDs"], enchantID)
	else 
		core.enchants[visualID] = {["enchantIDs"] = {enchantID}}
	end
	core.enchantInfo = core.enchantInfo or {}
	core.enchantInfo["visualID"] = core.enchantInfo["visualID"] or {}
	core.enchantInfo["spellID"] = core.enchantInfo["spellID"] or {}
	
	core.enchantInfo["visualID"][enchantID] = visualID
	core.enchantInfo["spellID"][enchantID] = spellID
end

-- /run for _, id in pairs(Addy.enchants[29].enchantIDs) do print(Addy.GetEnchantInfo(id)) end
core.GetEnchantInfo = function(enchantID)
	local spellID = core.enchantInfo.spellID[enchantID]
	if spellID then
		return GetSpellInfo(spellID)
	end
end

core.AddColor = function(color, itemID)
	--core.am(itemID.." is "..color)
	--FunctionOnItemInfo(itemID, function()
		core.colors = core.colors or {}
		core.colors[color] = core.colors[color] or {}
		core.colors[color][itemID] = true
	--end)
end

core.AddItem = function(displayID,itemID,class,subClass,inventoryType,quality,requiredLevel,allowableRace,allowableClass,allowableFaction)
	if not core.inventoryTypes[inventoryType] then return end
	core.displayIDs = core.displayIDs or {}
	if core.displayIDs[displayID] and core.Contains(core.displayIDs[displayID], itemID) then return end
	if core.displayIDs[displayID] then
		table.insert(core.displayIDs[displayID], itemID)
	else 
		core.displayIDs[displayID] = { itemID }
	end
	core.itemInfo = core.itemInfo or {} --TODO: den krma nicht tausendmal aufrufen? oder wird das eh rauscompiliert
	core.itemInfo["displayID"] = core.itemInfo["displayID"] or {}
	core.itemInfo["class"] = core.itemInfo["class"] or {}
	core.itemInfo["subClass"] = core.itemInfo["subClass"] or {}
	core.itemInfo["inventoryType"] = core.itemInfo["inventoryType"] or {}
	--core.itemInfo["quality"] = core.itemInfo["quality"] or {}
	--core.itemInfo["requiredLevel"] = core.itemInfo["requiredLevel"] or {}
	--core.itemInfo["allowableRace"] = core.itemInfo["allowableRace"] or {}
	--core.itemInfo["allowableClass"] = core.itemInfo["allowableClass"] or {}
	--core.itemInfo["allowableFaction"] = core.itemInfo["allowableFaction"] or {}
		
	core.itemInfo["displayID"][itemID] = displayID
	core.itemInfo["class"][itemID] = class
	core.itemInfo["subClass"][itemID] = subClass
	core.itemInfo["inventoryType"][itemID] = inventoryType
	--core.itemInfo["quality"][itemID] = quality
	--core.itemInfo["requiredLevel"][itemID] = requiredLevel
	--core.itemInfo["allowableRace"][itemID] = allowableRace
	--core.itemInfo["allowableClass"][itemID] = allowableClass
	--core.itemInfo["allowableFaction"][itemID] = allowableFaction
end


-- LUA 5.1 stores all numbers as doubles and are only precise up to 2^53!!!
-- Also the default rshift does not work for numbers >= 2^32

-- Start/Attempt at building more compressed item Data, see "TODO BuildList Thoughts.txt". Maybe give option to use uncompressed data, if people with bad pcs struggle with the increased workload on item iteration
-- Would need restart and then we just dont compress, dont drop our original tables and change GetItemData to just return their values

-- TODO: inventoryType, class, subclass can be further compressed by using a single field in data that can be mapped to the three values and class is mostly  redundant information anyway (there is weapon misc and armor misc tho..)
-- grouping these together would also mean speeding up the iteration
-- currently we return numerical values for everything (unlocked = 1, locked = 0). change so getitemdata returns proper values, boolean etc?

-- TODO: make it possible to add new items to data? i.e. we receive unlocked item, that is not in itemData. itemType, class and subclass can be retrieved with oniteminfo. there is no way to receive visual ID ingame,
-- but then we will just assume no visual group, which is fine imo. class restrictions could be parsed from tooltip, but not factions. kinda w/e tho for items, that we have unlocked. could also make the faction filtering to assume unlocked = own faction


local encodings = {"unlocked", "displayID", "inventoryType", "class", "subClass"}
local encodingLength = {
	unlocked = 1,
	displayID = 13, -- not the original displayID, but the groupID we generated
	inventoryType = 5, -- could save 8 bit combining this with class and subclass, also speedup
	class = 4,
	subClass = 5,
}
local encodingStart = {}
local c = 0
for i, key in pairs(encodings) do
	encodingStart[key] = c
	c = c + encodingLength[key]
end
-- for key, pos in pairs(core.encodingStart) do
-- 	print("key", key, "start", pos)
-- end
for key, pos in pairs(encodingLength) do
	encodingLength[key] = lshift(1, pos)
end

local encoded = {}
for key, start in pairs(encodingStart) do
    encoded[key] = 2 ^ start
end

 -- Not in use. I put this directly into GetItemData to avoid the extra function call (GetItemData has to be fast when iterating over all items)
local Decode = function(data, key)
	local tmp = rshift(data, encodingStart[key])
	return mod(tmp, encodingLength[key])
	
	-- if key == "itemType" then
	-- 	return unpack(myItemTypes[tmp])
	-- else
	-- 	return tmp
	-- end
end

local GetItemData
GetItemData = function(itemID, i)
	i = i or 1

	if not core.itemData[itemID] or not encodings[i] then return nil end

    local key = encodings[i]
    local tmp = rshift(core.itemData[itemID], encodingStart[key])
	return mod(tmp, encodingLength[key]), GetItemData(itemID, i + 1)  -- tested recursion vs filling/unpacking a table: recursion was much faster and also creates no garbage!
end

core.GenerateCompressedItemData = function()
	assert(core.itemData == nil, "GenerateCompressedItemData should only be called once at the start of the loading process!")

	-- core.itemData = MyAddonDB.itemData
	-- core.groupData = MyAddonDB.groupData
	-- if true then return end

	-- print("Memory before displayGroup Table:", collectgarbage("count"))

	core.groupData = {}

	local displayGroups = {} -- find displayIDs which are used by more than one item, the rest can be dropped and receives displayGroup = 0
	local groupCount = 0
	for displayID, itemIDs in pairs(core.displayIDs) do
		if table.getn(itemIDs) > 1 then
			groupCount = groupCount + 1
			displayGroups[displayID] = groupCount

			core.groupData[groupCount] = {}
			for _, itemID in pairs(itemIDs) do
				table.insert(core.groupData[groupCount], itemID)
			end
		end
	end
	
	-- print("Memory after displayGroup Table:", collectgarbage("count"))
	-- print("Display group count:", groupCount)

	core.itemData = {} -- [itemID] = data. Data is 64 bit number, which contains 1 bit unlocked, 11 bit displayGroup, x bit itemType etc

	-- for i = 1, 19000 do -- filling itemData with enough consecutive dummy entries causes lua to put all entries into the array part of the table, which saves us ~250KB memory size, but increases iteration times slightly
	-- 	core.itemData[i] = 0
	-- end

	local count = 0
	for itemID, displayID in pairs(core.itemInfo.displayID) do		
		local data = 0

        data = data + (displayGroups[displayID] or 0) * encoded.displayID
        
		local inventoryType = core.itemInfo.inventoryType[itemID] -- TODO: make a mapping: class, subclass, inventoryType? <-> itemType
		data = data + inventoryType * encoded.inventoryType
		
		local class = core.itemInfo.class[itemID] -- TODO: make a mapping: class, subclass, inventoryType? <-> itemType
		data = data + class * encoded.class
		
		local subClass = core.itemInfo.subClass[itemID] -- TODO: make a mapping: class, subclass, inventoryType? <-> itemType
		data = data + subClass * encoded.subClass

		core.itemData[itemID] = data
		count = count + 1
	end
	core.count = count

	-- core.itemNames = {} 
	-- for itemID, _ in pairs(core.itemData) do
	-- 	core.itemNames[itemID] = "AABBCCDD" .. (GetItemInfo(itemID) or "GroßerHelmdesKuhlenDoods" .. itemID)
	-- end

	core.itemInfo = nil
	core.displayIDs = nil
	collectgarbage("collect")
	
	-- 
	-- core.names = core.names or {} -- If we cache all itemnames, we would another ~3MB memory. Could maybe save 1mb from itemData by combining the two, but probably increases itemData iteration time by a lot, since we have to do expensive string operations?
	-- for itemID, _ in pairs(core.itemData) do
	-- 	core.names[itemID] = "Schuppengamaschen des zornerfüllten Gladiators" .. itemID
	-- end


	--MyAddonDB.itemData = core.itemData
	--MyAddonDB.groupData = core.groupData


	-- for itemID, _ in pairs(core.itemData) do
	-- 	local unlocked, displayGroup, inventoryType, class, subClass = core.GetItemData(itemID)

	-- 	local group = displayGroups[core.itemInfo.displayID[itemID]] or 0

	-- 	if displayGroup ~= group then core.am("displayGroup Bug!", displayGroup, group) end
	-- 	if inventoryType ~= core.itemInfo.inventoryType[itemID] then core.am("invType Bug!", itemID, inventoryType, core.itemInfo.inventoryType[itemID]) end
	-- 	if class ~= core.itemInfo.class[itemID] then core.am("class Bug!", itemID, class, core.itemInfo.class[itemID]) end
	-- 	if subClass ~= core.itemInfo.subClass[itemID] then core.am("subClass Bug!", itemID, subClass, core.itemInfo.subClass[itemID]) end
		
	-- end
end

core.GetItemData = GetItemData --function(itemID, i) -- TODO: allow access to i? 
   -- return GetItemData(itemID, i)
--end

core.SetUnlocked = function(self, itemID)
    local unlocked = GetItemData(itemID)
    if unlocked ~= 1 then
        core.itemData[itemID] = (core.itemData[itemID] or 0) + encoded.unlocked
    end
end


-- TODO: As long as visualGroups contain items of different types (MH + OH, cloth + leather, etc) this information is not that useful imo
-- Leaning towards splitting up these groups so that they only contain one type of item
-- Alternatively, if we don't want to do that, we could return 2, if itemID and unlocked alternativevItemID have different item types
core.IsVisualUnlocked = function(self, itemID)
	local unlocked, visualGroup = core.GetItemData(itemID)

	if not visualGroup or visualGroup == 0 then
		return unlocked
	end

	for _, alternativeItemID in pairs(core.groupData[visualGroup]) do
		local unlocked = core.GetItemData(alternativeItemID)
		if unlocked == 1 then return 1 end
	end

	return 0
end

core.IsItemUnlocked = function(itemID)
	local unlocked = core.GetItemData(itemID)

	return unlocked
end




-- Bobby = function()
--     core:WipeRec(core.itemInfo)
--     core:WipeRec(core.displayIDs)
--     collectgarbage("collect")
-- end

------------ Experimenting with Compressing Data into big String -----------------------------------

local function newStack ()
	return {""}   -- starts with an empty string
  end
  
local function addString (stack, s)
	table.insert(stack, s)    -- push 's' into the the stack
	for i = table.getn(stack) - 1, 1, -1 do
		if string.len(stack[i]) > string.len(stack[i+1]) then
			break
		end
		stack[i] = stack[i] .. table.remove(stack)
	end
end

-- shift operations only work as intended for 32 bit numbers, can modify them, but numbers are not precise above 2^53
-- local byteCount = 4
-- local maxByte = byteCount - 1
-- local numToByteString = function(num)
-- 	local t = {}
-- 	for i = 0, maxByte do
-- 		t[byteCount - i] = string.char(bit.band(rshift(num, i * 8), 0xFF))
-- 	end
-- 	return table.concat(t)
-- end
-- NTBS = numToByteString




-- DecodeData = function(num, i)
-- 	i = i or 1

-- 	if not num or not encodings[i] then return nil end

--     local key = encodings[i]
--     local tmp = rshift(num, encodingStart[key])
-- 	return mod(tmp, encodingLength[key]), DecodeData(num, i + 1)
-- end

-- local facA, facB, facC, facD, facE, facF, facG, facH = 2 ^ 56, 2 ^ 48, 2 ^ 40, 2 ^ 32, 2 ^ 24, 2 ^ 16, 2 ^ 8, 2 ^ 0
-- byteStringToNum = function(s, i)
-- 	i = i or 1
-- 	local e, f, g, h = strbyte(s, i, i + maxByte)
-- 	return --[[a * facA + b * facB + c * facC + d * facD +]] e * facE + f * facF + g * facG + h * facH
-- end

-- core.GetItemData2 = function(itemID)
-- 	local num = byteStringToNum(core.uwu, (itemID - 1) * byteCount + 1)

-- 	return DecodeData(num)
-- end

-- local encodings = {"unlocked", "displayID", "inventoryType", "class", "subClass"}
-- local encodingLength = {
-- 	unlocked = 1,
-- 	displayID = 13, -- not the original displayID, but the groupID we generated
-- 	inventoryType = 5, -- could save 8 bit combining this with class and subclass, also speedup
-- 	class = 4,
-- 	subClass = 5,
-- }
-- core.GetItemData3 = function(itemID)
-- 	local a, b, c, d, e, f = strbyte(core.awa, (itemID - 1) * 6 + 1, itemID * 6)

-- 	local displayID = lshift(b, 8) + c

-- 	return a, displayID, d, e, f
-- end

-- Iterating like this is super fast and pog, what about setting unlocked tho?? lua strings are immutable, so to change a char, we have to copy whole string
-- could keep string in smaller chunks so we dont have to copy whole string every time
-- splitting by invType does not synergize with our method at all sadly

-- should really combine invType, class and subclass into a single key, that we either decode back to the 3 fields here in GetItemData or work everywhere with that key
-- saves 100KB and iteration time

-- Not sure if that doesn't get too scuffed, but technically we could save a "next Item in VisualGroup"-ID instead of the visualGroup itself
-- Would also take 2 Byte, still allows iterating over visualgroup, so we could save on another 365KB, that is needed for visualGroup table atm, but do we really need that?
-- would need full iteration over those tho, to check during collection list build, whether we already added a visual, idk

-- Example of custom iterator from https://stackoverflow.com/questions/46006462/lua-custom-iterator-proper-way-to-define


local ToByteString = function(itemID)
	local unlocked, displayGroup, inventoryType, class, subClass = GetItemData(itemID)

	local a = strchar(unlocked)
	local b = strchar(rshift(displayGroup, 8))
	local c = strchar(bit.band(displayGroup, 0xFF))
	local d = strchar(inventoryType)
	local e = strchar(class)
	local f = strchar(subClass)

	return a .. b .. c .. d .. e .. f
end

-- TODO: Change format from one big string to maybe 1k long or shorter strings, so when we set unlock, we dont copy whole string but only a small part
core.GenerateStringData = function()	
	local data = newStack()
	for i = 1, 55000 do
		addString(data, core.itemData[i] and ToByteString(i) or "\0\0\0\0\0\0")
		if GetItemInfo(i) then core.names[i] = nil end
	end
	local tmp = {}
	for itemID, itemName in pairs(core.names) do
		tmp[itemID] = itemName
	end
	core.names = tmp

	core.awa = table.concat(data)
	core.itemData = nil
	collectgarbage("collect")
end

core.GetItemData = function(itemID)
	if not core.awa or not itemID or itemID < 1 or itemID > 55000 then return end
	local a, b, c, d, e, f = strbyte(core.awa, (itemID - 1) * 6 + 1, itemID * 6)

	if (d == 0) then return end

	local displayID = lshift(b, 8) + c

	return a, displayID, d, e, f
end

local ReplaceChar = function(s, pos, c)
    return s:sub(1, pos - 1) .. c .. s:sub(pos + 1)
end


core.SetUnlocked = function(itemID)
	if core.awa then
		local unlocked = core.GetItemData(itemID)
		print("Before:", itemID, unlocked)
		if unlocked ~= 1 then
			core.awa = ReplaceChar(core.awa, (itemID - 1) * 6 + 1, strchar(1))
		end
		unlocked = core.GetItemData(itemID)
		print("After:", itemID, unlocked)
	elseif core.itemData then
		local unlocked = GetItemData(itemID)
		if unlocked ~= 1 then
			core.itemData[itemID] = (core.itemData[itemID] or 0) + encoded.unlocked
		end
	else
		print("ERROR in SetUnlocked: Neither string, nor table data exists to write to")
	end
end

-- called like this: for itemID in core.itemIterator() do print(itemID) end
-- (could just use a for loop atm, but planning to split data string into smaller bits, and then we want to hide the exact implementation to the outside)
-- should also split data by invType or smth to drastically reduce iteration time for free, can let the iterator take optional slot param to then only iterate over invtypes of that slot e.g.
core.itemIterator = function()
	local i = 1
	return function()
		repeat
			if i > 55000 then return nil end
			i = i + 1
		until
			strbyte(core.awa, (i - 2) * 6 + 4) ~= 0

		return i - 1
	end
end