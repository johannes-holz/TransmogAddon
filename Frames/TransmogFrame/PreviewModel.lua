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

core.TwoHandExclusive = { [core.ITEM_SUB_CLASSES.POLEARMS] = true, [core.ITEM_SUB_CLASSES.STAVES] = true, [core.ITEM_SUB_CLASSES.FISHING_POLES] = true }
core.MHOnly = { INVTYPE_WEAPONMAINHAND = true }
core.OHOnly = { INVTYPE_WEAPONOFFHAND = true }

local Model_SetUnit = function(self, unit)
	local x, y, z = self:GetPosition()
	self:SetPosition(0, 0, 0)
	self:SetUnitOld(unit)
	self:SetPosition(x, y, z)
end

core.CreatePreviewModel = function(parent, width, height)
	local model = CreateFrame("DressUpModel", folder .. "PreviewModel", parent)
	model:SetSize(width, height)
	model:EnableMouse()
	model:EnableMouseWheel()

	local _, race = UnitRace("player")
	local _, class = UnitClass("player")

	model.border = CreateFrame("Frame", nil, model)
	model.border:SetPoint("BOTTOMLEFT", -4, -4)
	model.border:SetPoint("TOPRIGHT", 4, 4)
	model.border:SetBackdrop(core.BACKDROP_TOAST_ONLY_BORDER_12_12)	

	model.SetUnitOld = model.SetUnit
	model.SetUnit = Model_SetUnit
	
	model:SetUnit("player")
	model.posBackup = modelPositions[race] or { 0, 0, 0 }
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
		model:SetFacing(model.facing + dif * rotSpeed)
	end
	
	model.isTurning, model.isDragging = false, false
	model:SetScript("OnMouseDown", function(self, button)
		CloseDropDownMenus()
		if button == "LeftButton" then
			if model.isDragging then return end
			model.isTurning = true
			model.x, model.y = GetCursorPosition()
			model.facing = model:GetFacing()
			self:SetScript("OnUpdate", onUpdateTurning)
		elseif button == "RightButton" then
			if model.isTurning then return end
			model.isDragging = true
		end
	end)
	
	model:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			model.isTurning = false
		elseif button == "RightButton" then
			model.isDragging = false
		end
		if not model.isTurning and not model.isDragging then self:SetScript("OnUpdate", onUpdateNormal) end		
	end)
	
	model:SetScript("OnShow", function(self)
		self:SetPosition(unpack(self.posBackup))

		self:SetScript("OnUpdate", onUpdateNormal)
		
		-- kappa
		local weekday, month, day, year = CalendarGetDate()
		if month == 4 and day == 1 and not self.openedBefore then
			self.openedBefore = true
			self:SetModel("CREATURE/Tauren_MountedCanoe/Tauren_MountedCanoe.m2")
		else
			self:SetUnit("player")
		end
		-- shiny bladestorm
		self:ChangeSequence((math.random() > 0.9999) and 126 or -1)

		if self.SetShadowForm then
			self:SetShadowForm(self:GetShadowForm())
		end
		
		self:update()
	end)

	model:SetScript("OnHide", function(self)
		model.isTurning, model.isDragging = false, false
		model.posBackup[1], model.posBackup[2], model.posBackup[3] = model:GetPosition()
		model:SetPosition(0, 0, 0)
		--[[model.texRatio, model.texCutoff = 3/4, 0
		model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)		
		model.BGTopLeft:SetTexCoord(model.texCutoff,1,0,1) --(0,0,middleCutOff,1,1,0,1,1)
		model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomLeft:SetTexCoord(model.texCutoff,1,0,0.5-model.texCutoff*2)
		model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
		model.BGTopRight:SetTexCoord(0,0.95-model.texCutoff,0,1)
		model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomRight:SetTexCoord(0,0.95-model.texCutoff,0,0.5-model.texCutoff*2)]] --Only needed if full reset is desired on hide
		--self:SetScript("OnUpdate", nil) -- OnUpdate only gets called for shown frames
	end)
	
	--TODO: Improve or remove fake texture zoom
	model:SetScript("OnMouseWheel", function(self, delta)
		--TODO: Allow scrolling on specific positions?
		-- camera is in (2, 0, 0?) depends on race and gets translated depending on modelposition at the point of init/show
		--model:SetModelScale(1.5)
		--model:SetPosition(0, 0, -0.5)
		-- local scale = model:GetModelScale()
		local x, y, z = model:GetPosition()
		if delta < 0 and x > 0.1 then
			--if x > 0.65 then z = z + x / 20 end
			x = x - 0.05
			model.texRatio = model.texRatio - 0.014
			model.texCutoff = model.texCutoff - 0.01
		elseif delta > 0 and x < 0.9 then
			x = x + 0.05
			--if x > 0.65 then z = z - x / 20 end
			model.texRatio = model.texRatio + 0.014
			model.texCutoff = model.texCutoff + 0.01
		end

		-- fake zoom on background texture. should probably just remove this and allow positional zoom instead and maybe even model dragging, even tho it looks bad
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
		-- race = "Nightborne"--"Nightborne"--"TROLL"--"Worgen"--"HighmountainTauren"
		path = "Interface\\AddOns\\".. folder .."\\images\\DressUpFrame\\"
		-- model.texRatio = 4/5 --spillt textur über
		-- model:SetPosition(0.1, 0, -0.1)
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
	model.cantPreviewMessage:SetWidth(200)
    model.cantPreviewMessage:SetPoint("BOTTOM", 0, model:GetHeight() / 4)
    model.cantPreviewMessage:SetJustifyH("CENTER")
    model.cantPreviewMessage:SetJustifyV("MIDDLE")
    model.cantPreviewMessage:SetText(core.CAN_NOT_PREVIEW)

    model.ohAppearanceNotShown = model.textFrame:CreateFontString()
    model.ohAppearanceNotShown:SetFontObject(GameFontRed)
	model.ohAppearanceNotShown:SetWidth(200)
    model.ohAppearanceNotShown:SetPoint("BOTTOM", model.cantPreviewMessage, "BOTTOM", 0, 0) -- I think cantPreview and ohAppearanceNotShown are mutually exclusive?
    model.ohAppearanceNotShown:SetJustifyH("CENTER")
    model.ohAppearanceNotShown:SetJustifyV("MIDDLE")
    model.ohAppearanceNotShown:SetText(core.OH_APPEARANCE_WONT_BE_SHOWN)
    
    model.mhHidesOH = model.textFrame:CreateFontString()
    model.mhHidesOH:SetFontObject(GameFontRed)
	model.mhHidesOH:SetWidth(200)
    model.mhHidesOH:SetPoint("TOP", model.cantPreviewMessage, "BOTTOM", 0, -6)
    model.mhHidesOH:SetJustifyH("CENTER")
    model.mhHidesOH:SetJustifyV("MIDDLE")
    model.mhHidesOH:SetText(core.OH_WILL_BE_HIDDEN)


	model.GetItemsToDisplay = function(self, includeHidden)
		local skin = core.GetSelectedSkin()
		local selectedSlot = core.GetSelectedSlot()

		local itemsToShow = {}
		for _, slot in pairs(core.allSlots) do        
            local itemID, visualID, skinVisualID, pendingID = core.TransmogGetSlotInfo(slot, skin)
			local isEnchantSlot = core.IsEnchantSlot(slot)
			local correspondingSlot = isEnchantSlot and core.GetCorrespondingSlot(slot)
			local correspondingWeaponID = correspondingSlot and core.TransmogGetSlotInfo(correspondingSlot, skin)

			local show = pendingID or (skin and skinVisualID) or ((not skin or self.showItemsUnderSkin) and (visualID or itemID)) or nil

			if self.showItemsUnderSkin and
					(isEnchantSlot and not correspondingWeaponID or not isEnchantSlot and not itemID) then
				show = nil 	-- skin won't show if there is no item in slot (enchantmogs don't need an enchant in "slot")
			end

			if show == core.UNMOG_ID then
				show = (not skin or self.showItemsUnderSkin) and itemID or nil	-- pending or visual is nomog/unmog: show item
			elseif show == core.HIDDEN_ID and not includeHidden then
				show = nil														-- show hidden item: nothing to show
			end

            itemsToShow[slot] = show
		end
		return itemsToShow
	end
	
	model.update = function(self)
		if not model:IsShown() then return end

		local selectedSlot = core.GetSelectedSlot()
		local skin = core.GetSelectedSkin()

		-- make displayed weapon depend on last selected weapon slot?
		-- not sure if this would confuse people
		-- if core.IsWeaponSlot(selectedSlot) then
		-- 	model.lastWeaponSlot = selectedSlot 
		-- elseif model.lastWeaponSlot then
		-- 	selectedSlot = model.lastWeaponSlot
		-- end
	
		local itemsToShow = self:GetItemsToDisplay()

		model:Undress()
		
		for slot, item in pairs(itemsToShow) do
			if not (core.IsEnchantSlot(slot) or core.IsWeaponSlot(slot)) then
				model:TryOn(item)
			end
		end

		-- TODO: Are we happy with this offhand display behaviour?. maybe remember last offhand slot and also range slot/melee slot and show that one instead of always melee weps?

		-- Weapon display logic:
		local mh = itemsToShow["MainHandSlot"]
		local oh = (selectedSlot == "OffHandSlot" or selectedSlot == "ShieldHandWeaponSlot") and itemsToShow[selectedSlot]
					or not (selectedSlot == "OffHandSlot" or selectedSlot == "ShieldHandWeaponSlot") and (itemsToShow["ShieldHandWeaponSlot"] or itemsToShow["OffHandSlot"]) or nil

        local mhWeaponType = mh and select(7, GetItemInfo(mh))
        local ohWeaponType = oh and select(7, GetItemInfo(oh))

        local mhInvType = mh and select(9, GetItemInfo(mh))
        local ohInvType = oh and select(9, GetItemInfo(oh))

		-- Staff/polearm/fishing pole transmogs will not be shown while in the offhand. Similar for MH/OH exclusive weapons in the wrong slot. Confusing ...
		local mhTransmogHidden = mhWeaponType and core.OHOnly[mhInvType]
		local ohTransmogHidden = ohWeaponType and core.TwoHandExclusive[ohWeaponType] or core.MHOnly[ohInvType]

		-- TODO: Check mh in oh, oh in mh, mh is fishing pole
		
		mh = mhTransmogHidden and core.TransmogGetSlotInfo("MainHandSlot") or mh
		oh = ohTransmogHidden and core.TransmogGetSlotInfo("SecondaryHandSlot") or oh
		
		-- How to handle enchants? :)
		local mhEnchant = core.SpellToEnchantID(itemsToShow["MainHandEnchantSlot"])
		local ohEnchant = core.SpellToEnchantID(itemsToShow["SecondaryHandEnchantSlot"])
		if mh and mhEnchant then mh = "item:" .. mh .. ":" .. mhEnchant end
		if oh and ohEnchant then oh = "item:" .. oh .. ":" .. ohEnchant end
        
		model.ohAppearanceNotShown:SetText((mhTransmogHidden and ohTransmogHidden) and core.MH_OH_APPEARANCE_WONT_BE_SHOWN or
											mhTransmogHidden and core.MH_APPEARANCE_WONT_BE_SHOWN or core.OH_APPEARANCE_WONT_BE_SHOWN)
        core.SetShown(model.mhHidesOH, mhWeaponType and ohWeaponType and core.TwoHandExclusive[mhWeaponType])
        core.SetShown(model.ohAppearanceNotShown, mhTransmogHidden or ohTransmogHidden)
        model.cantPreviewMessage:Hide()
		
		if selectedSlot == "RangedSlot" then
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
		core.UpdateListeners("previewModel") -- also update model's Outfitframe
	end

	core.RegisterListener("currentChanges", model)
	core.RegisterListener("selectedSlot", model)
	core.RegisterListener("inventory", model)
	core.RegisterListener("selectedSkin", model)
	

	---- Outfit Stuff ----

	-- TODO: Why are we not using the same method for model update and GetAll?
		-- What do we want to save in an outfit here? Whats visible (then see previous question)?
		-- Or do we want to allow saving all weapon slots, so we can remember a full skin?
	model.GetAll = function(self)
		local items = self:GetItemsToDisplay(true)		
		local selectedSlot = core.GetSelectedSlot()

        -- Only allow Offhand or ShieldHandWeapon in outfits?
        if selectedSlot == "OffHandSlot" then
            items["ShieldHandWeaponSlot"] = nil
        elseif selectedSlot == "ShieldHandWeaponSlot" then
            items["OffHandSlot"] = nil
        end
        -- Only allow melee or ranged Weapons?        
        if selectedSlot == "RangedSlot" then
            items["MainHandSlot"] = nil
            items["ShieldHandWeaponSlot"] = nil
            items["OffHandSlot"] = nil
        elseif selectedSlot == "MainHandSlot" or selectedSlot == "ShieldHandWeaponSlot" or selectedSlot == "OffHandSlot"then
            items["RangedSlot"] = nil
        end
        -- Only allow things we can display?
		local ohWeapon = items["ShieldHandWeaponSlot"]
        if ohWeapon then
            local itemSubType, _, itemEquipLoc = select(7, GetItemInfo(ohWeapon))
            if not core.CanDualWield() or (itemEquipLoc == "INVTYPE_2HWEAPON" and not (core.HasTitanGrip() and core.CanBeTitanGripped(itemSubType))) then
                items["ShieldHandWeaponSlot"] = nil
            end
        end

		return items
	end

	model.SetAll = function(self, set)
		core.SetCurrentChanges(set)
		core.SetSlotAndCategory(nil, nil)
	end
	
	---- Shadowform Simulation ----

	if class == "PRIEST" then
		model.shadowFormFlamesModel = CreateFrame("PlayerModel", folder .. "$parentShadowModel", model)
		model.shadowFormFlamesModel:SetPoint("Center")
		model.shadowFormFlamesModel:SetModel("SPELLS/Shadow_Form_Precast.m2")
		model.shadowFormFlamesModel:SetAlpha(0.6)
		model.shadowFormFlamesModel:SetAllPoints()
		model.shadowFormFlamesModel:Hide()
		model.shadowFormFlamesModel:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) - elapsed
			if self.elapsed < 0 then
				self.elapsed = 0.1
				local x, y, z = model:GetPosition()
				self:SetPosition(x, y, z + 0.2)
			end
		end)

		local offTex = "Interface\\Icons\\spell_shadow_shadowform"
		local onTex = "Interface\\Icons\\spell_shadow_chilltouch"

		model.shadowFormButton = core.CreateMeACustomTexButton(model, 24, 24, offTex, 9/64, 9/64, 54/64, 54/64)
		model.shadowFormButton:SetPoint("BOTTOMRIGHT", -5, 5)
		model.shadowFormButton:SetScript("OnClick", function(self, button)    
			model:SetShadowForm(not model:GetShadowForm())
		end)
		core.SetTooltip2(model.shadowFormButton, core.SHADOW_FORM_TOOLTIP_TITLE, 1, 1, 1, nil,
														core.SHADOW_FORM_TOOLTIP_TEXT, nil, nil, nil, 1)

		model.SetShadowForm = function(self, form)
			self:SetLight(unpack(form and core.LIGHT.shadowForm or core.LIGHT.default))
			self:SetAlpha(form and 0.75 or 1)
			core.SetShown(self.shadowFormFlamesModel, form)
			self.shadowFormFlamesModel:SetModel("SPELLS/Shadow_Form_Precast.m2")
			local x, y, z = self:GetPosition()
			self.shadowFormFlamesModel:SetPosition(x, y, z + 0.2)
			self.shadowFormEnabled = form
			self.shadowFormButton:SetCustomTexture(form and onTex or offTex)
		end

		model.GetShadowForm = function(self)
			return self.shadowFormEnabled
		end
	end

	-- model.too = model.TryOn
	-- model.TryOn = function(self, ...)
	-- 	-- print("previeModel", ...)
	-- 	self:too(...)
	-- end

	-----------------------------------
	
	return model
end