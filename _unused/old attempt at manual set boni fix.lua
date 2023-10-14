

-- SetBoniDisplay Hack. would need data about which sets mix (gladiator, t7-10, some classic sets?, etc) and how many parts are needed for each setbonus of every set
--[[


local allInventorySlots = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"RangedSlot",
	"AmmoSlot"
}


local FindSetItemBaseName = function(itemName)
	local baseItemName
	if string.find(itemName, ".* des %a+ Gladiators") then
		baseItemName = string.sub(itemName, 1, select(1, string.find(itemName, string.match(itemName, ".* des (%a+) Gladiators"))) - 1) .. "Gladiators"
	elseif string.find(itemName, "%a+ Gladiator's .*") then
		baseItemName = string.sub(itemName, select(2, string.find(itemName, string.match(itemName, "(%a+) Gladiator's .*"))) + 2)
		
	elseif string.find(itemName, "%a+ %a+ des Ymirjarfürsten") then
		baseItemName = string.sub(itemName, select(2, string.find(itemName, string.match(itemName, "(%a+) %a+ des Ymirjarfürsten"))) + 2)
	end
	
	return baseItemName
end

local function FixSetDisplay()	-- pointless to take tooltip as param and then iterate over gametooltips lines
	if not GameTooltip:GetOwner() then return end
	
	local ownerName = GameTooltip:GetOwner():GetName()	
	

	local currentItems, setItemBaseNames = {}, {}
	local setName, setLine, setCount, setMax, isSetItemLine
	for i=1,40 do		
		local line = _G["GameTooltipTextLeft" .. i]
		--
		--am(string.format('%q', '(%d/%d)'))
		--local str = "Schlachtrüstung des Schreckenspanzers (8/8)"
		--am(string.sub(str, string.find(str, "%(%d/%d%)")))
		if line then
			--am(line:GetName(), line:GetText(), line:GetTextColor())
			if isSetItemLine then
				if line:GetText() == " " then
					isSetItemLine = false
				else
					local setItemName = string.gsub(line:GetText(), '^%s*(.-)%s*$', '%1')
					
					local r, g, b, a = line:GetTextColor()
					
					if r < 0.75 then
						for slot, currentItem in pairs(currentItems) do
							if (currentItem == setItemName or (setItemBaseNames[slot] and setItemBaseNames[slot] == setItemName)) then	
								line:SetTextColor(myadd.setItemTooltipTextColor.r, myadd.setItemTooltipTextColor.g, myadd.setItemTooltipTextColor.b, myadd.setItemTooltipTextColor.a)
								line:SetText("  "..currentItem)
								setCount = setCount + 1
							end
						end
					end	
					
					if r > 0.75 and not myadd.Contains(currentItems, setItemName) then
						line:SetTextColor(myadd.setItemMissingTooltipTextColor.r, myadd.setItemMissingTooltipTextColor.g, myadd.setItemMissingTooltipTextColor.b, myadd.setItemMissingTooltipTextColor.a)
						local setItemBaseName = FindSetItemBaseName(setItemName)
						if setItemBaseName then
							line:SetText("  "..setItemBaseName)
						end
						setCount = setCount - 1
					end
				end
			end
			if line:GetText() and string.find(line:GetText(), "%(%d/%d%)") then
				setLine = line
				setName = string.match(line:GetText(), "(.+) %(%d/%d%)")
				setMax = tonumber(string.match(line:GetText(), ".*%(%d/(%d)%)"))
				setCount = tonumber(string.match(line:GetText(), ".*%((%d)/%d%)"))
				for k, v in pairs(allInventorySlots) do
					if GetInventoryItemID("player", GetInventorySlotInfo(v)) then
						currentItems[v] = GetItemInfo(GetInventoryItemID("player", GetInventorySlotInfo(v)))
						
						setItemBaseNames[v] = FindSetItemBaseName(currentItems[v])
					end
				end
				isSetItemLine = true
			end
			if line:GetText() and string.find(line:GetText(), "%(%d%) Set:.*") then
				local required = tonumber(string.match(line:GetText(), "%((%d)%) Set:.*"))
				if setCount >= required then
					line:SetTextColor(myadd.bonusTooltipTextColor.r, myadd.bonusTooltipTextColor.g, myadd.bonusTooltipTextColor.b, myadd.bonusTooltipTextColor.a)
					line:SetText(string.sub(line:GetText(), 5))
				end
			end
			--TODO: False Positive Setboni ausgrauen. benötigt info darüber, wie viele parts jeweilige boni benötigen und variable die tracked um den wievielten setbonus es sich handelt, um tabelle nutzen zu können die sagt Ymirjarfürsten = {2,4}
					--oder den ganzen kram mehr id basiert machen?
					--nachfragen wie man an die setdaten kommt, die auf https://db.rising-gods.de/?itemsets dargestellt werden?
					--aus https://wow.tools/dbc/?dbc=itemset&build=3.3.5.12340&locale=deDE#page=1&search=ymir könnte man die bonus thresholds extrahieren
		end
	end
	if setLine then
		setLine:SetText(setName.." ("..setCount.."/"..setMax..")")
	end
end



]]