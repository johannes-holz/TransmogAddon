local folder, core = ...

-- These are not in use, just examples how to use the old item data

-- className, classFilename<- = UnitClass(unitId)
core.classes = {
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
	["DEMONHUNTER"] = 2048
}

-- race, raceEn<- = UnitRace("unit");
core.races = {
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
	["Pandaren Horde"] = 33554432
}

-- englishFaction<-, localizedFaction = UnitFactionGroup(unit)
core.factions = {
	["Horde"] = 1,
	["Alliance"] = 2
}
	
core.func = core.func or {}

-- In BuildList: if not xFilter or isXAllowed(playerX, items[itemID][x]) then tinsert(list, itemID)
core.func.isClassAllowed = function(class, itemClassMask)
	if not class or not core.classes[class] then DEFAULT_CHAT_FRAME:AddMessage(folder..": Wrong usage of core.func.isClassAllowed!", 1, 0, 0); return false end

	if not itemClassMask or not (bit.band(core.classes[class], itemClassMask) == 0)
		then return
	else
		return false
	end
end

core.func.isRaceAllowed = function(race, itemRaceMask)
	if not race or not core.races[race] then DEFAULT_CHAT_FRAME:AddMessage(folder..": Wrong usage of core.func.isRaceAllowed!", 1, 0, 0); return false end
	
	if not itemRaceMask or not (bit.band(core.races[race], itemRaceMask) == 0) then
		return true
	else
		return false
	end
end

core.func.isFactionAllowed = function(faction, itemFactionMask)
	if not faction or not core.factions[faction] then DEFAULT_CHAT_FRAME:AddMessage(folder..": Wrong usage of core.func.isFactionAllowed!", 1, 0, 0); return false end
	
	if not itemFactionMask or not (bit.band(core.factions[faction], itemFactionMask) == 0) then
		return true
	else
		return false
	end
end

--[[for k, v in pairs(core.races) do
	local allowed = core.func.isRaceAllowed(k, 8388607)

	if allowed then DEFAULT_CHAT_FRAME:AddMessage(k) end
end]]