local folder, core = ...

-- ThoughtDump/TODO
-- one texture for normal border/unmoggable/hover (or extra for hover?)
-- one texture for Big Border showing: Original Item - Yellow?, Current Visual - Purple, Pending?, Current Skin? - Blue?

-- SetLight(enabled, omni, dirX, dirY, dirZ, ambIntensity, ambR, ambG, ambB, dirIntensity, dirR, dirG, dirB)
local LIGHT = {
	default = {1,
		0, 0, 1, 0,
		1, 0.7, 0.7, 0.7,
		1, 0.8, 0.8, 0.64,
	},
	shadowForm = {1,
		0, 0, 1, 0,
		1, 0.16, 0, 0.23,
		0,
	},
	locked = {1,
		0, 0, 1, 0,
		0.8, 0.7, 0.7, 0.7,
		0.8, 0.8, 0.8, 0.64,
	},
}

core.mannequinPositions = {
	["Human"] = {
		["HeadSlot"] = {1.8, 0, -0.74, 0},
		["ShoulderSlot"] = {1.65, 0, -0.6, 0},
		["ChestSlot"] = {1.55, 0, -0.3, 0},
		["ShirtSlot"] = {1.55, 0, -0.3, 0},
		["TabardSlot"] = {1.55, 0, -0.3, 0},
		["WristSlot"] = {1.75, 0, -0.1, 0},
		["HandsSlot"] = {1.75, 0, -0.1, 0},
		["WaistSlot"] = {1.75, 0, -0.1, 0},
		["LegsSlot"] = {1.15, 0, 0.28, 0},	
		["FeetSlot"] = {1.5, 0, 0.5, 0},
		["BackSlot"] = {1, 0, -0.05, math.pi},
		["MainHandSlot"] = {0.6, -0.2, 0, math.pi * 0.4},
		["SecondaryHandSlot"] = {0.6, 0, 0, -math.pi * 0.4},
		["ShieldHandWeaponSlot"] = {0.6, 0, 0, -math.pi * 0.4},
		["OffHandSlot"] = {0.6, 0, 0, -math.pi * 0.4},
		["MainHandEnchantSlot"] = {0.6, 0, 0, math.pi * 0.2},
		["SecondaryHandEnchantSlot"] = {0.6, 0, 0, -math.pi * 0.2},
		["RangedSlot"] = {0.6, 0, 0, math.pi * 0.2},},
	["NightElf"] = {
		["HeadSlot"] = {3, 0, -0.82, 0},
		["ShoulderSlot"] = {2.45, 0, -0.6, 0},
		["ChestSlot"] = {2.65, 0, -0.3, 0},
		["ShirtSlot"] = {2.65, 0, -0.3, 0},
		["TabardSlot"] = {2.65, 0, -0.3, 0},
		["WristSlot"] = {2.75, 0, -0.13, 0},
		["HandsSlot"] = {2.75, 0, -0.13, 0},
		["WaistSlot"] = {2.75, 0, -0.13, 0},
		["LegsSlot"] = {1.79, 0, 0.32, 0},	
		["FeetSlot"] = {2.6, 0, 0.62, 0},
		["BackSlot"] = {1.7, 0, -0.05, math.pi},
		["MainHandSlot"] = {1.5, 0, 0, math.pi * 0.2},
		["SecondaryHandSlot"] = {1.5, 0, 0, -math.pi * 0.2},
		["ShieldHandWeaponSlot"] = {1.5, 0, 0, -math.pi * 0.2},
		["OffHandSlot"] = {1.5, 0, 0, -math.pi * 0.2},
		["MainHandEnchantSlot"] = {1.5, 0, 0, math.pi * 0.2},
		["SecondaryHandEnchantSlot"] = {1.5, 0, 0, -math.pi * 0.2},
		["RangedSlot"] = {1.5, 0, 0, math.pi * 0.2},},
	["Gnome"] = {
		["HeadSlot"] = {0.9, 0, -0.18, 0},
		["ShoulderSlot"] = {0.82, 0, 0, 0},
		["ChestSlot"] = {1.14, 0, 0.17, 0},
		["ShirtSlot"] = {1.14, 0, 0.17, 0},
		["TabardSlot"] = {1.14, 0, 0.17, 0},
		["WristSlot"] = {1.14, 0, 0.14, 0},
		["HandsSlot"] = {1, 0, 0.14, 0},
		["WaistSlot"] = {1.2, 0, 0.21, 0},
		["LegsSlot"] = {1, 0, 0.28, 0},	
		["FeetSlot"] = {1.1, 0, 0.34, 0},
		["BackSlot"] = {0.8, 0, 0.2, math.pi},
		["MainHandSlot"] = {0, 0, 0.1, math.pi * 0.3},
		["SecondaryHandSlot"] = {0, 0, 0.1, -math.pi * 0.3}, 
		["ShieldHandWeaponSlot"] = {0, 0, 0.1, -math.pi * 0.3}, 
		["OffHandSlot"] = {0, 0, 0.1, -math.pi * 0.3}, 
		["MainHandEnchantSlot"] = {0, 0, 0.1, math.pi * 0.3},
		["SecondaryHandEnchantSlot"] = {0, 0, 0.1, -math.pi * 0.3},
		["RangedSlot"] = {0, 0, 0.1, math.pi * 0.3},},
	--[[head 1.04, 0, -0.18
shoulder 0.82, 0, 0
chest 1.14, 0, 0.14
shirt
tabard
wrist
hands
wrists
legs 1.2, 0, 0.28
feet 1.16, 0, 0.4
mh 0, 0, 0.1
oh same?
	["axe"] = {0.2, 0, 0, math.pi * 0.4},
	["sword"] = {0.2, 0, 0, math.pi * 0.4},
	["mace"] = {0.2, 0, 0, math.pi * 0.4},
	["dagger"] = {1.1, 0, 0, math.pi * 0.3},
	["fistweapon"] = {0.9, 0, 0, math.pi * 0.3},
	["polearm"] = {0.2, 0, 0, math.pi * 0.2},
	["staff"] = {0.2, 0, 0, math.pi * 0.4},
	["fishingpole"] = {0.2, 0, 0, math.pi * 0.4},
	["bow"] = {0.2, 0, 0, math.pi * 0.4},
	["crossbow"] = {0.2, 0, 0, math.pi * 0.4},
	["gun"] = {0.2, 0, 0, math.pi * 0.4},
	["thrown"] = {0.2, 0, 0, math.pi * 0.4},
	["wand"] = {0.2, 0, 0, math.pi * 0.4},
	["offhand"] = {0.2, 0, 0, -math.pi * 0.4},
	["shield"] = {0.2, 0, 0, -math.pi * 0.4},]]--
}





local UPDATE_INTERVAL = 0.5
local LoadingOnUpdate = function(self, e)
	self.elapsed = (self.elapsed or 0) + e
	if self.elapsed > UPDATE_INTERVAL then
		self.elapsed = self.elapsed - UPDATE_INTERVAL
		local item = self:GetParent().item
		if GetItemInfo(item) then
			self:GetParent():TryOn(item)
			self:Hide()
		end
	end
end



core.CreateMannequinFrame = function(self, parent, id, width, height)
	local m = CreateFrame("DressUpModel", folder.."Mannequin"..id, parent)
	
	m.SetUnitOld = m.SetUnit
	m.SetUnit = function(self, unit)
		local x, y, z = self:GetPosition()
		self:SetPosition(0, 0, 0)
		self:SetUnitOld(unit)
		self:SetPosition(x, y, z)
	end

	m.HideOld = m.Hide
	m.Hide = function(self)
		self:SetPosition(0, 0, 0)
		self:HideOld()
	end


	m.id = id
	m.GetID = function(self)
		return self.id
	end

	m:SetSize(width, height)
		
	m:EnableMouse()
	m:EnableMouseWheel()
	
	m.backgroundTexture = m:CreateTexture(nil, "BACKGROUND")
	m.backgroundTexture:SetTexture(0, 0, 0)
	m.backgroundTexture:SetPoint("BOTTOMLEFT", 1, 1)
	m.backgroundTexture:SetPoint("TOPRIGHT", -1, -1)


	local offset = 0.05 * height

	m.backTex = m:CreateTexture(nil, "BACKGROUND")
	m.backTex:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.backTex:SetTexCoord(5/512, 95/512, 131/512, 247/512)
	m.backTex:SetPoint("TOPLEFT", -offset, offset)
	m.backTex:SetPoint("BOTTOMRIGHT", offset, -offset)
	
	m.highTex = m:CreateTexture(nil, "HIGHLIGHT")
	m.highTex:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.highTex:SetTexCoord(5/512, 95/512, 255/512, 372/512)
	--local scale = 0.025
	--local left, top, right, bottom = 104/512, 225/512, 190/512,336/512
	--m.highTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	--m.highTex:SetAllPoints()
	m.highTex:SetPoint("TOPLEFT", -offset, offset)
	m.highTex:SetPoint("BOTTOMRIGHT", offset, -offset)
	--m.highTex:SetBlendMode("ADD")
	m.highTex:SetAlpha(0.8)

	m.lockedTexture = m:CreateTexture(nil, "BORDER")
	m.lockedTexture:SetTexture("Interface\\AddOns\\".. folder .."\\images\\Transmogrify")
	m.lockedTexture:SetTexCoord(5/512, 95/512, 255/512, 372/512)
	m.lockedTexture:SetPoint("TOPLEFT", -offset, offset)
	m.lockedTexture:SetPoint("BOTTOMRIGHT", offset, -offset)
	m.lockedTexture:SetAlpha(1)
	m.lockedTexture:SetVertexColor(0.4, 0.4, 0.4)

	m.testFrame = CreateFrame("Frame", folder.."Mannequin"..id.."LoadingFrame", m)
	m.testFrame:SetAllPoints()
	m.testFrame.tex = m.testFrame:CreateTexture(nil, "OVERLAY")
	m.testFrame.tex:SetAllPoints()
	m.testFrame.tex:SetTexture(0,0,0)
	m.testFrame.tex:SetAlpha(0.5)




	m.loadingFrame = CreateFrame("Frame", folder.."Mannequin"..id.."LoadingFrame", m)
	m.loadingFrame:SetAllPoints()
	m.loadingFrame:EnableMouse()

	m.loadingFrame.text = m.loadingFrame:CreateFontString()
	m.loadingFrame.text:SetFontObject(GameFontNormal)
	m.loadingFrame.text:SetPoint("CENTER")
	m.loadingFrame.text:SetJustifyH("CENTER")
	m.loadingFrame.text:SetJustifyV("MIDDLE")
	m.loadingFrame.text:SetText("Loading ...")
	
	m.loadingFrame.texture = m.loadingFrame:CreateTexture(nil, "BACKGROUND")
	m.loadingFrame.texture:SetPoint("CENTER")
	m.loadingFrame.texture:SetSize(m.loadingFrame.text:GetSize())
	m.loadingFrame.texture:SetTexture(0.1, 0.1, 0.1)

	m.loadingFrame:SetScript("OnUpdate", LoadingOnUpdate)

	m.SetLoading = function(self, loading)
		core.SetShown(self.loadingFrame, loading)
		if loading then
			self:SetFogColor(0.1, 0.1, 0.1)
			self:SetFogNear(0)
			self:SetFogFar(0.1)
		else
			--self:SetFogColor(nil)
			self:SetFogNear(10)
		end
	end

	m.TryOnOld = m.TryOn
	m.TryOn = function(self, itemID) -- or link/string
		self.item = itemID
		if GetItemInfo(itemID) then
			local enchant = core.itemCollectionFrame.enchant
			self:Undress()
			-- self:TryOnOld(39519) -- Black Gloves
			-- self:TryOnOld(11731) -- Black Shoes
			-- self:TryOnOld(6835) -- Black Leggings
			-- self:TryOnOld(3427) -- Black Shirt
			-- self:TryOnOld(9998) -- Black West
			local slot = self:GetParent():GetParent().selectedSlot
			if slot == "MainHandSlot" then self:TryOnOld(1485) end
			if slot == "ShieldHandWeaponSlot" then self:TryOnOld(1485); self:TryOnOld(20954) end -- TODO: irgendwann nochmal korrekt machen mit fog etc? diese lösung failed für 2h ohne titangrip
			self:TryOnOld(enchant and "item:" .. itemID .. ":" .. enchant or itemID)
			self:SetLoading(false)
		else
			self:SetLoading(true)
			core.QueryItem(itemID)
		end
	end

	m.SetDisplayMode = function(self, unlocked)
		self:SetAlpha(unlocked and 1 or 0.8)
		core.SetShown(self.lockedTexture, not unlocked)
		core.SetShown(self.testFrame, false and not unlocked)

		self:SetLight(unpack(LIGHT[unlocked and "default" or "locked"]))
	end

	
	
		
	m.sequence = 15 -- Standing Still Animation
	m.sequenceTime = 0
	m.sequenceSpeed = 1000
	
	m.SetAnimation = function(self, sequenceID, sequenceTime, sequenceSpeed)
		core.am("Set Model Animation to "..sequenceID..".")
		self.sequence = sequenceID
		self.sequenceTime = sequenceTime or 0
		self.sequenceSpeed = sequenceSpeed or 1000
	end
	
	m.onUpdateNormal = function(self, elapsed) -- this lets us use different model animation (some will be glitchy). without setting this in OnUpdate, it will show the default standing animation
		if self.sequence < 0 or self.sequence > 506 then return end -- Sequence must be in the range 0, 506

		self.sequenceTime = self.sequenceTime + elapsed * self.sequenceSpeed
		self:SetSequenceTime(self.sequence, self.sequenceTime)
	end	
	m:SetScript("OnUpdate", m.onUpdateNormal)


	m.ShowTooltip = function(self)
		-- local iid = list[8*(page-1)+tonumber(m:GetName())]
		
		-- if selectedSlot == "MainHandEnchantSlot" or selectedSlot == "SecondaryHandEnchantSlot" then
		-- 	local enchantID, spellID, mogEnchantName
		-- 	_, enchantID = iid:match("item:(%d+):(%d+)")
		-- 	enchantID = tonumber(enchantID)				
		-- 	visualID = myadd.enchantInfo["visualID"][enchantID]
			
		-- 	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
		-- 	GameTooltip:ClearLines()
		-- 	for k, v in pairs(myadd.enchants[visualID]["enchantIDs"]) do
		-- 		spellID = myadd.enchantInfo["spellID"][v]
		-- 		mogEnchantName = GetSpellInfo(spellID)		
		-- 		GameTooltip:AddLine(mogEnchantName, 1, 1, 1)
		-- 	end
		-- 	GameTooltip:Show()
		-- 	return
		-- end
		
		-- local dispID = myadd.itemInfo["displayID"][iid]
		-- local itemNames = {}
		-- local itemNameColors = {}
		-- for k, v in pairs(myadd.displayIDs[dispID]) do
		-- 	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
		-- 	GameTooltip:SetHyperlink("item:"..v)
		-- 	local mytext =_G["GameTooltipTextLeft"..1]
		-- 	--am( mytext:GetText())
		-- 	tinsert(itemNames, mytext:GetText())--.." - "..v)
		-- 	tinsert(itemNameColors, { mytext:GetTextColor() })
		-- end
		-- --am(itemNames)
		-- GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
		-- GameTooltip:ClearLines()
		-- for i=1,length(itemNames) do
		-- 	GameTooltip:AddLine(itemNames[i], itemNameColors[i][1], itemNameColors[i][2], itemNameColors[i][3])
		-- end
		-- GameTooltip:Show()
	end
	
	-- m:SetScript("OnMouseDown", function()
	-- 	local iid = list[8*(page-1)+tonumber(m:GetName())] --TODO: weniger scuffed lösung finden?

	-- 	if iid then
	-- 		am("")
	-- 		if selectedSlot == "MainHandEnchantSlot" or selectedSlot == "SecondaryHandEnchantSlot" then
	-- 			local itemID, enchantID = iid:match("item:(%d+):(%d+)")
	-- 			iid = tonumber(enchantID)
	-- 			am("Enchant: "..iid)
	-- 		else
	-- 			if IsControlKeyDown() then
	-- 				local dispID = myadd.itemInfo["displayID"][iid]
					
	-- 				--am("DisplayID: "..dispID)
	-- 				--am(myadd.displayIDs[dispID])
	-- 				for k, v in pairs(myadd.displayIDs[dispID]) do
	-- 					FunctionOnItemInfo(v, function()
	-- 						am(v .. " - "..select(1, GetItemInfo(v)))--..", displayID: "..myadd.itemInfo["displayID"][v])
	-- 					end)
	-- 				end
	-- 			else
	-- 				FunctionOnItemInfo(v, function()
	-- 					am(iid .. " - "..select(1, GetItemInfo(iid)))--..", displayID: "..myadd.itemInfo["displayID"][iid])
	-- 				end)
	-- 			end
	-- 		end
	-- 		TryOn(model, iid, selectedSlot)
	-- 	end
	-- end)
	-- m:SetScript("OnEnter", m.ShowTooltip)
	-- m:SetScript("OnLeave", function(self)
	-- 	GameTooltip:Hide()
	-- end)
	-- m:SetScript("OnMouseWheel", function(self, delta)
	-- 	if delta < 1 then
	-- 		SetPage(page+1)
	-- 	else
	-- 		SetPage(page-1)
	-- 	end
	-- 	if m:IsShown() then
	-- 		m.ShowTooltip(self)
	-- 	end
	-- 	--[[local x, y, z = m:GetPosition()
	-- 	local a = m:GetFacing()
	-- 	if IsShiftKeyDown() then		
	-- 		m:SetPosition(x, y, z+0.03*delta)
	-- 	elseif IsControlKeyDown() then
	-- 		m:SetFacing(a+0.03*delta)
	-- 	else
	-- 		m:SetPosition(x+0.1*delta, y, z)
	-- 	end		
	-- 	x, y, z = m:GetPosition()
	-- 	a = m:GetFacing()
	-- 	am(x, y, z, a)]]
	-- end)
	m:SetScript("OnHide", function(self)
		self:SetPosition(0, 0, 0)
		self:UnregisterEvent("OnKeyDown")
	end)
	m:SetScript("OnShow", function(self)
		--[[
		if not m.item then return end
		local _, race = UnitRace("player")
		if not core.mannequinPositions[race] then race = "Human" end
		local pos = core.mannequinPositions[race][selectedSlot] or {0, 0, 0, 0}
		m:Undress()
		m:TryOn(m.item)
		m:SetPosition(pos[1], pos[2], pos[3])
		m:SetFacing(pos[4])
		]]
		self:SetUnit("player")
		self:Undress()
		if self.item then self:TryOn(self.item) end
		self:RegisterEvent("OnKeyDown")
	end)

	m:SetScript("OnEvent", function(self, event, ...)
		print(self:GetID(), event, ...)
	end)

	m:Hide()
	return m
end

