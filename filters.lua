MyAddon, myadd = ...


-- className, classFilename<- = UnitClass(unitId)
myadd.classes = {
	["WARRIOR"] = 1,
	["PALADIN"] = 2,
	["HUNTER"] = 4,
	["ROGUE"] = 8,
	["PRIEST"] = 16,
	["DEATHKNIGHT"] = 32,
	["SHAMAN"] = 64,
	["MAGE"] = 128,
	["WARLOCK"] = 256,
	["MONK"] = 512,
	["DRUID"] = 1024,
	["DEMONHUNTER"] = 2048,}

-- race, raceEn<- = UnitRace("unit");
myadd.races = {
	["Human"] = 1,
	["Orc"] = 2,
	["Dwarf"] = 4,
	["Night Elf"] = 8,
	["Undead"] = 16,
	["Tauren"] = 32,
	["Gnome"] = 64,
	["Troll "] = 128,
	["Goblin"] = 256,
	["Blood Elf"] = 512,
	["Draenei"] = 1024,
	["Fel Orc"] = 2048,
	["Naga"] = 4096,
	["Broken"] = 8192,
	["Skeleton"] = 16384,
	["Vrykul"] = 32768,
	["Tuskarr"] = 65536,
	["Forest Troll"] = 131072,
	["Taunka"] = 262144,
	["Northrend Skeleton"] = 524288,
	["Ice Troll"] = 1048576,
	["Worgen"] = 2097152,
	["Pandaren Neutral"] = 8388608,
	["Pandaren Alliance"] = 16777216,
	["Pandaren Horde"] = 33554432,}

-- englishFaction<-, localizedFaction = UnitFactionGroup(unit)
myadd.factions = {
	["Horde"] = 1,
	["Alliance"] = 2,}
	
myadd.func = myadd.func or {}

-- In BuildList: if not xFilter or isXAllowed(playerX, items[itemID][x]) then tinsert(list, itemID)
myadd.func.isClassAllowed = function(class, itemClassMask)
	if not class or not myadd.classes[class] then DEFAULT_CHAT_FRAME:AddMessage(MyAddon..": Wrong usage of myadd.func.isClassAllowed!", 1, 0, 0); return false end

	if not itemClassMask or not (bit.band(myadd.classes[class], itemClassMask) == 0)
		then return
	else
		return false
	end
end

myadd.func.isRaceAllowed = function(race, itemRaceMask)
	if not race or not myadd.races[race] then DEFAULT_CHAT_FRAME:AddMessage(MyAddon..": Wrong usage of myadd.func.isRaceAllowed!", 1, 0, 0); return false end
	
	if not itemRaceMask or not (bit.band(myadd.races[race], itemRaceMask) == 0) then
		return true
	else
		return false
	end
end

myadd.func.isFactionAllowed = function(faction, itemFactionMask)
	if not faction or not myadd.factions[faction] then DEFAULT_CHAT_FRAME:AddMessage(MyAddon..": Wrong usage of myadd.func.isFactionAllowed!", 1, 0, 0); return false end
	
	if not itemFactionMask or not (bit.band(myadd.factions[faction], itemFactionMask) == 0) then
		return true
	else
		return false
	end
end

--[[for k, v in pairs(myadd.races) do
	local allowed = myadd.func.isRaceAllowed(k, 8388607)

	if allowed then DEFAULT_CHAT_FRAME:AddMessage(k) end
end]]