local folder, core = ...

local modelPositions = {
	["Human"] = {0.1, 0, 0.05},
	["NightElf"] = {-0.2, 0, 0.15},
	["Gnome"] = {1, 0, 0.3},
	["Troll"] = {-0.4, 0, 0.05},
	["Tauren"] = {-0.4, 0, 0.05},
	["BloodElf"] = {-0.4, 0, 0.1},
	["Draenei"] = {-0.3, 0, 0.15},
	["Scourge"] = {-0.2, 0, 0.1},
	["Dwarf"] = {0.2, 0, 0.1},
	["Orc"] = {0, 0, 0.05},
}

core.TwoHandExclusive = {[core.ITEM_SUB_CLASSES.POLEARMS] = true, [core.ITEM_SUB_CLASSES.STAVES] = true, [core.ITEM_SUB_CLASSES.FISHING_POLES] = true}

core.CreatePreviewModel = function(parent, width, height)
	local model = CreateFrame("DressUpModel", folder.."PreviewModel", parent)
	model:SetSize(width, height)
	model:EnableMouse()
	model:EnableMouseWheel()

	model.border = CreateFrame("Frame", nil, model)
	model.border:SetPoint("BOTTOMLEFT", -4, -4)
	model.border:SetPoint("TOPRIGHT", 4, 4)
	model.border:SetBackdrop(core.BACKDROP_TOAST_ONLY_BORDER_12_12)	
	
	model:SetUnit("player")	
	local _, race = UnitRace("player")
	model.standardPos = modelPositions[race] or {0, 0, 0}
	model.posBackup = {0, 0, 0} -- Pos must be set to 0, 0, 0 on hide, otherwise camera gets translated on next show. So we have to save our last Position and set it again OnShow
	model.texRatio, model.texCutoff = 3/4, 0	
	
	model.seqtime = 0
	model.seq = -1
	
	model.ChangeSequence = function(self, number)
		assert(type(number) == "number")
		--core.am("Set Model Animation to:", number)
		self.seq = number
		self.seqtime = 0
	end
	
	local multi = 1000
	local onUpdateNormal = function(self, elapsed)
		if model.seq < 0 or model.seq > 506 then return end
		model.seqtime = model.seqtime + elapsed*multi
		model:SetSequenceTime(model.seq, model.seqtime)
	end
	
    local rotSpeed = 1 / 100
	local onUpdateTurning = function(self, elapsed)
		onUpdateNormal(self, elapsed)
		local curX, curY = GetCursorPosition()
		local dif = curX - model.x
		model:SetFacing(model.facing + dif * rotSpeed) -- TODO: scale with screen resolution for consistent behaviour?
	end
	
	local turning, dragging = false, false
	model:SetScript("OnMouseDown", function(self, button)
		CloseDropDownMenus()
		if button == "LeftButton" then
			if dragging then return end
			turning = true
			model.x, model.y = GetCursorPosition()
			model.facing = model:GetFacing()
			self:SetScript("OnUpdate", onUpdateTurning)
		elseif button == "RightButton" then
			if turning then return end
			dragging = true
		end
	end)
	
	model:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			turning = false
		elseif button == "RightButton" then
			dragging = false
		end
		if not turning and not dragging then self:SetScript("OnUpdate", onUpdateNormal) end		
	end)
	
	model:SetScript("OnShow", function(self)
		model:SetPosition(model.posBackup[1], model.posBackup[2], model.posBackup[3])
		self:SetScript("OnUpdate", onUpdateNormal)
		
		-- kappa
		local weekday, month, day, year = CalendarGetDate()
		if month == 4 and day == 1 and not self.openedBefore then
			self.openedBefore = true
			model:SetModel("CREATURE/Tauren_MountedCanoe/Tauren_MountedCanoe.m2")
		else
			model:SetUnit("player")
		end
		-- shiny bladestorm
		model:ChangeSequence((math.random() > 0.9999) and 126 or -1)
		
		model:update()
	end)

	model:SetScript("OnHide", function(self)
		turning, dragging = false, false
		model.posBackup[1], model.posBackup[2], model.posBackup[3] = model:GetPosition() 
		model:SetPosition(model.standardPos[1], model.standardPos[2], model.standardPos[3])
		--[[model.texRatio, model.texCutoff = 3/4, 0
		model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)		
		model.BGTopLeft:SetTexCoord(model.texCutoff,1,0,1) --(0,0,middleCutOff,1,1,0,1,1)
		model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomLeft:SetTexCoord(model.texCutoff,1,0,0.5-model.texCutoff*2)
		model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
		model.BGTopRight:SetTexCoord(0,0.95-model.texCutoff,0,1)
		model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomRight:SetTexCoord(0,0.95-model.texCutoff,0,0.5-model.texCutoff*2)]] --Only needed if full reset is desired on hide
		--self:SetScript("OnUpdate", nil) --Happens automatically
	end)
	--TODO: -maybe on enter self.controllFrame:Show() etc
	
	--TODO: Bei langeweile am Fakezoom weiterarbeiten
	model:SetScript("OnMouseWheel", function(self, delta)
		--TODO: Scroll auf bestimmte Körperstellen ermöglichen?
		--camera is in (2, 0, 0?) depends on race and gets translated depending on modelposition at the point of init/show
		--model:SetModelScale(1.5)
		--model:SetPosition(0, 0, -0.5)
		local scale = model:GetModelScale()
		local x, y, z = model:GetPosition()
		--core.am(x)
		if delta < 0 and x > 0.1 then
			--if x > 0.65 then z = z + x / 20 end
			x = x - 0.05
			model.texRatio = model.texRatio - 0.014
			model.texCutoff = model.texCutoff-0.01
		elseif delta > 0 and x < 1 then
			x = x + 0.05
			--if x > 0.65 then z = z - x / 20 end
			model.texRatio = model.texRatio + 0.014
			model.texCutoff = model.texCutoff+0.01
		end
		--Hängt von der Kameraposition und der Hintergrundtexture ab und braucht daher auch pro rasse/geschlecht abgestimmte parameter
		--Nach oben hin auch weniger punktflucht als zur seite? bei himmel gut, bei wänden und co weniger
		--local middleCutOff = model.texCutoff * model.texRatio        --   Strahlensatz: 1 / model.texRatio = 	model.texCutoff / middleCutOff
		model:SetPosition(x, y, z)
		model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)		
		model.BGTopLeft:SetTexCoord(model.texCutoff,1,0,1) --(0,0,middleCutOff,1,1,0,1,1)
		model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomLeft:SetTexCoord(model.texCutoff,1,0,0.5-model.texCutoff*2)
		model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
		model.BGTopRight:SetTexCoord(0,0.95-model.texCutoff,0,1)
		model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomRight:SetTexCoord(0,0.95-model.texCutoff,0,0.5-model.texCutoff*2)
	end)
	
	local _, race = UnitRace("player")
	--if race == "Gnome" then race = "Dwarf" end
	--elseif race == "Troll" then race = "Orc" end
	local path = "Interface\\DressUpFrame\\"
	if race == "Gnome" or race == "Troll" or race == "Orc" then
		--race = "Nightborne"--"Nightborne"--"TROLL"--"Worgen"--"HighmountainTauren"
		path = "Interface\\AddOns\\".. folder .."\\images\\"
		--model.texRatio = 4/5 --spillt textur über
		--model:SetPosition(0.1, 0, -0.1)
	end
	
	model.BGTopLeft = model:CreateTexture(nil, "BACKGROUND")
	model.BGTopLeft:SetWidth(model:GetWidth()*4/5)
	model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)
	model.BGTopLeft:SetPoint("TOPLEFT", model, "TOPLEFT", 0, 0)
	model.BGTopLeft:SetTexture(path.."DressUpBackground-"..race.."1")
	
	model.BGTopRight = model:CreateTexture(nil, "BACKGROUND")
	model.BGTopRight:SetWidth(model:GetWidth()*1/5)
	model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
	model.BGTopRight:SetPoint("TOPRIGHT", model, "TOPRIGHT", 0, 0)
	model.BGTopRight:SetTexture(path.."DressUpBackground-"..race.."2")	
	model.BGTopRight:SetTexCoord(0,0.95,0,1)
	
	model.BGBottomLeft = model:CreateTexture(nil, "BACKGROUND")
	model.BGBottomLeft:SetWidth(model:GetWidth()*4/5)
	model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
	model.BGBottomLeft:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 0, 0)
	model.BGBottomLeft:SetTexture(path.."DressUpBackground-"..race.."3")
	model.BGBottomLeft:SetTexCoord(0,1,0,0.5)
	
	model.BGBottomRight = model:CreateTexture(nil, "BACKGROUND")
	model.BGBottomRight:SetWidth(model:GetWidth()*1/5)
	model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
	model.BGBottomRight:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0, 0)
	model.BGBottomRight:SetTexture(path.."DressUpBackground-"..race.."4")
	model.BGBottomRight:SetTexCoord(0,0.95,0,0.5)

    model.textFrame = CreateFrame("Frame", nil, model)
    model.textFrame:SetAllPoints()

    model.cantPreviewMessage = model.textFrame:CreateFontString()
    model.cantPreviewMessage:SetFontObject(GameFontRed)
    model.cantPreviewMessage:SetPoint("BOTTOM", 0, model:GetHeight() / 5)
    model.cantPreviewMessage:SetJustifyH("CENTER")
    model.cantPreviewMessage:SetJustifyV("MIDDLE")
    model.cantPreviewMessage:SetText(core.CAN_NOT_PREVIEW)
    
    model.mhHidesOH = model.textFrame:CreateFontString()
    model.mhHidesOH:SetFontObject(GameFontRed)
    model.mhHidesOH:SetPoint("TOP", model.cantPreviewMessage, "BOTTOM", 0, -4)
    model.mhHidesOH:SetJustifyH("CENTER")
    model.mhHidesOH:SetJustifyV("MIDDLE")
    model.mhHidesOH:SetText(core.OH_WILL_BE_HIDDEN)

    model.ohAppearanceNotShown = model.textFrame:CreateFontString()
    model.ohAppearanceNotShown:SetFontObject(GameFontRed)
    model.ohAppearanceNotShown:SetPoint("TOP", model.mhHidesOH, "BOTTOM", 0, -4)
    model.ohAppearanceNotShown:SetJustifyH("CENTER")
    model.ohAppearanceNotShown:SetJustifyV("MIDDLE")
    model.ohAppearanceNotShown:SetText(core.OH_APPEARANCE_WONT_BE_SHOWN)

	model.GetItemsToDisplay = function(self, includeHidden)	
		local skin = core.GetSelectedSkin()
		local selectedSlot = core.GetSelectedSlot()

		local itemsToShow = {}
		for _, slot in pairs(core.itemSlots) do        
            local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot)

			local show = pendingID or (skin and skinVisualID) or ((not skin or core.showItemsUnderSkin) and (visualID or itemID)) or nil

			if show == 0 then
				show = (not skin or core.showItemsUnderSkin) and itemID or nil
			elseif show == 1 and not includeHidden then
				show = nil
			end

            itemsToShow[slot] = show	
		end
		return itemsToShow
	end
	
	model.update = function(self)
		if not model:IsShown() then return end
		local selectedSlot = core.GetSelectedSlot()

		if core.IsWeaponSlot(selectedSlot) then
			model.lastWeaponSlot = selectedSlot -- make displayed weapon depend on last selected weapon slot?
		end
	
		local itemsToShow = self:GetItemsToDisplay()

		model:Undress()
        model.cantPreviewMessage:Hide()
		
		for k, v in pairs(itemsToShow) do
			if not core.Contains({"MainHandSlot", "MainHandEnchantSlot", "SecondaryHandEnchantSlot", "SecondaryHandSlot", "RangedSlot", "OffHandSlot", "ShieldHandWeaponSlot"}, k) then
				model:TryOn(v)
			end
		end

		-- TODO: Are we happy with this offhand display behaviour?. maybe remember last offhand slot and also range slot/melee slot and show that one instead of always melee weps?
		-- TODO: still the problem that we cant display 2h in offhand for dualwielders without titangrip. what do we do here?		

		local mh = itemsToShow["MainHandSlot"]
		--if mh and itemsToShow["MainHandEnchantSlot"] then mh = "item:"..mh..":"..itemsToShow["MainHandEnchantSlot"] end
		local oh = (selectedSlot == "OffHandSlot" or selectedSlot == "ShieldHandWeaponSlot") and itemsToShow[selectedSlot]
					or not (selectedSlot == "OffHandSlot" or selectedSlot == "ShieldHandWeaponSlot") and (itemsToShow["ShieldHandWeaponSlot"] or itemsToShow["OffHandSlot"]) or nil
		--if oh and itemsToShow["SecondaryHandEnchantSlot"] then oh = "item:"..oh..":"..itemsToShow["SecondaryHandEnchantSlot"] end

        local mhWeaponType = mh and select(7, GetItemInfo(mh))
        local ohWeaponType = oh and select(7, GetItemInfo(oh))
        
        core.SetShown(model.mhHidesOH, mhWeaponType and ohWeaponType and core.TwoHandExclusive[mhWeaponType])
        core.SetShown(model.ohAppearanceNotShown, ohWeaponType and core.TwoHandExclusive[ohWeaponType])

        if ohWeaponType and core.TwoHandExclusive[ohWeaponType] then
            oh = core.TransmogGetSlotInfo("SecondaryHandSlot")
        end
		
		if core.GetSelectedSlot() == "RangedSlot" then
			if itemsToShow["RangedSlot"] then
				model:TryOn(itemsToShow["RangedSlot"])
			end		
		else
			local cantPreviewBoth = core.ShowMeleeWeapons(model, mh, oh)
            if cantPreviewBoth then
                model.cantPreviewMessage:Show()
                if core.GetSelectedSlot() == "SecondaryHandSlot" then
                    core.ShowMeleeWeapons(model, nil, oh)
                end
            end
		end
	end

	core.RegisterListener("currentChanges", model)
	core.RegisterListener("selectedSlot", model)
	core.RegisterListener("inventory", model)
	core.RegisterListener("selectedSkin", model)
	

	------------------- Outfit Stuff -------------------
	model.GetAll = function(self)
		return self:GetItemsToDisplay(true)
	end
	model.SetAll = function(self, set)
		core.SetCurrentChanges(set)
	end

	----------------------------------------------------
	
	return model
end