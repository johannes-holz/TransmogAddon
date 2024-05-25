local folder, core = ...

-- This is not intended as the WardrobeDressUpModel. It is used to test Mannequin Settings (Poses, FogNear/Far values, Scale, etc)

local modelColors = {
    DARKGREY = {0.05, 0.05, 0.05,},
}

local START_SEQUENCE = 21
-- Possible Poses to display MH held by offhand: 133, 199
-- nice MH pose 181, scale 1.2, new 2.98, far 3.12
-- another good pose 21
core.CreateWardrobeModelFrame = function(parent)
    local model = CreateFrame("DressUpModel", folder.."WardrobeModel", parent)
    model:SetSize(200, 300)
    model:EnableMouse()

	model.SetUnitOld = model.SetUnit
    model.SetUnit = function(self, unit)
		local x, y, z = self:GetPosition()
		self:SetPosition(0, 0, 0)
		self:SetUnitOld(unit)
		self:SetPosition(x, y, z)
	end
    
    model.seq = START_SEQUENCE 
    model.time = 0   
    model.speed = 1000

    model:SetScript("OnShow", function(self)
        self:SetUnit("player")
        self.time = 0
    end)

    model:SetScript("OnUpdate", function(self, e)
        self.time = self.time + self.speed * e
        self:SetSequenceTime(self.seq, self.time)
        self.modelText:SetText(self.seq)
        -- strange glitchy dance anims: 69, 197, 211
        -- if self.seq == 69 then
        -- 	self.seq = 197
        -- 	self.time = self.time - self.speed * e
        -- elseif self.seq == 197 then
        -- 	self.seq = 69
        -- 	self.time = self.time + self.speed * e
        -- end

        if self.turning then
            local curX, curY = GetCursorPosition()
            local difX = curX - self.x
            self.x = curX
            self:SetFacing(self:GetFacing() + difX / 100) --TODO: scale with screen resolution for consistent behaviour?
            
            for _, m in pairs(core.itemCollectionFrame.mannequins) do
                m:SetFacing(m:GetFacing() + difX / 100)
            end
        end
        if self.moving then
            local curX, curY = GetCursorPosition()
            local difX = curX - self.posX
            local difY = curY - self.posY
            self.posX = curX
            self.posY = curY
            local oldX, oldY, oldZ = self:GetPosition()
            self:SetPosition(oldX, oldY + difX / 100, oldZ + difY / 100) --TODO: scale with screen resolution for consistent behaviour?

            for _, m in pairs(core.itemCollectionFrame.mannequins) do
                local oldX, oldY, oldZ = m:GetPosition()
                m:SetPosition(oldX, oldY + difX / 100, oldZ + difY / 100)
            end
        end
    end)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.x = GetCursorPosition()
            self.turning = true
        elseif button == "RightButton" then
            self.posX, self.posY = GetCursorPosition()
            self.moving = true
        end
    end)
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.turning = nil
        elseif button == "RightButton" then
            self.moving = nil
        end
    end)
    a = model

    model:SetFogColor(unpack(modelColors.DARKGREY))


    model.background = model:CreateTexture(nil, "BACKGROUND")
    model.background:SetAllPoints()
    model.background:SetTexture(unpack(modelColors.DARKGREY))

    model.Preview = function(self, itemID)
        model:Undress()  
		model:TryOn(39519) -- Black Gloves
		model:TryOn(11731) -- Black Shoes
        model:TryOn(6835) -- Black Leggings
        model:TryOn(3427) -- Black Shirt
        model:TryOn(9998) -- Black West
        model:TryOn(itemID)
    end

    model.modelDownButton = core.CreateMeAButton(model, 28, 28, nil,
                                    "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 0, 0, 1, 1,
                                    "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down", 0, 0, 1, 1,
                                    "Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
                                    "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled", 0, 0, 1, 1)
    model.modelDownButton:SetPoint("TOPRIGHT", model, "BOTTOM", 0, 0)
    model.modelDownButton:SetScript("OnClick", function()
        local step = IsShiftKeyDown() and 10 or 1 
        model.seq = model.seq - step
        model.time = 0
        
        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            m.sequence = model.seq
            m.sequenceTime = model.time
        end
    end)

    model.modelUpButton = core.CreateMeAButton(model, 28, 28, nil,
                                "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 0, 0, 1, 1,
                                "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down", 0, 0, 1, 1,
                                "Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
                                "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled", 0, 0, 1, 1)
    model.modelUpButton:SetPoint("LEFT", model.modelDownButton, "RIGHT", 2, 0)
    model.modelUpButton:SetScript("OnClick", function()
        local step = IsShiftKeyDown() and 10 or 1 
        model.seq = model.seq + step
        model.time = 0

        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            m.sequence = model.seq
            m.sequenceTime = model.time
        end
    end)

    local stepSize = 0.05
    model.zoomInButton = core.CreateMeAButton(model, 28, 28, nil,
        "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 0, 0, 1, 1,
        "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down", 0, 0, 1, 1,
        "Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
        "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled", 0, 0, 1, 1)
    model.zoomInButton:SetPoint("BOTTOMLEFT", model, "RIGHT", 0, 0)
    model.zoomInButton:SetScript("OnClick", function()        
        local oldX, oldY, oldZ = model:GetPosition()
        model:SetPosition(oldX + stepSize, oldY, oldZ)

        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            local x, y, z = m:GetPosition()
            m:SetPosition(x + stepSize, y, z)
            m:SetFogNear(m:GetFogNear() - stepSize)
            m:SetFogFar(m:GetFogFar() - stepSize)
        end
    end)

    model.zoomOutButton = core.CreateMeAButton(model, 28, 28, nil,
        "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 0, 0, 1, 1,
        "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down", 0, 0, 1, 1,
        "Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
        "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled", 0, 0, 1, 1)
    model.zoomOutButton:SetPoint("TOPLEFT", model, "RIGHT", 0, 0)
    model.zoomOutButton:SetScript("OnClick", function()
        local oldX, oldY, oldZ = model:GetPosition()
        model:SetPosition(oldX - stepSize, oldY, oldZ)

        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            local x, y, z = m:GetPosition()
            m:SetPosition(x - stepSize, y, z)
            m:SetFogNear(m:GetFogNear() + stepSize)
            m:SetFogFar(m:GetFogFar() + stepSize)
            --/run for _, m in pairs(Addy.itemCollectionFrame.mannequins) do m:SetFogFar(m:GetFogFar() - 0.1); m:SetFogNear(m:GetFogFar() - 0.01)  end
        end
    end)

    model.modelText = model:CreateFontString()
    model.modelText:SetFontObject(GameFontWhite)
    model.modelText:SetPoint("RIGHT", model.modelDownButton, "LEFT", -8, 0)
    model.modelText:SetJustifyH("CENTER")
    model.modelText:SetJustifyV("CENTER")

    model.modelSliderNear = CreateFrame("Slider", "modelSliderNear", model, "OptionsSliderTemplate")
    model.modelSliderNear:SetSize(100, 20)
    model.modelSliderNear:SetOrientation("HORIZONTAL")
    model.modelSliderNear:SetPoint("TOP", model, "BOTTOM", 0, -40)
    model.modelSliderNear:SetMinMaxValues(0, 5)
    model.modelSliderNear:SetValueStep(0.02)
    model.modelSliderNear:SetScript("OnValueChanged", function(self, value)
        print(value)
        model.sequenceSpeed = value * 100
        model.speed = value * 200
        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            m.sequenceSpeed = value * 100
        end
    end)
    model.modelSliderNear:Enable()
    model.modelSliderNear:SetValue(2.9)
    model.modelSliderNear:Show()

    model.modelSliderDist = CreateFrame("Slider", "modelSliderNear", model, "OptionsSliderTemplate")
    model.modelSliderDist:SetSize(20, 200)
    model.modelSliderDist:SetOrientation("VERTICAL")
    model.modelSliderDist:SetPoint("LEFT", model, "RIGHT", 40, 0)
    model.modelSliderDist:SetMinMaxValues(-3, 3)
    model.modelSliderDist:SetValueStep(0.02)
    model.modelSliderDist:SetScript("OnValueChanged", function(self, value)
        print(value)
        
        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            local x, y, z = m:GetPosition()
            m:SetPosition(self:GetValue(), y, z)
        end
    end)
    model.modelSliderDist:Enable()
    model.modelSliderDist:SetValue(0)
    model.modelSliderDist:Show()

    model.modelSliderFar = CreateFrame("Slider", "modelSliderFar", model, "OptionsSliderTemplate")
    model.modelSliderFar:SetSize(200, 20)
    model.modelSliderFar:SetOrientation("HORIZONTAL")
    model.modelSliderFar:SetPoint("TOP", model, "BOTTOM", 0, -70)
    model.modelSliderFar:SetMinMaxValues(0, 5)
    model.modelSliderFar:SetValueStep(0.02)
    model.modelSliderFar:SetScript("OnValueChanged", function(self, value)
        model:SetFogFar(value)
        model:SetFogNear(value - 0.01)
        for _, m in pairs(core.itemCollectionFrame.mannequins) do
            m:SetFogColor(nil)
            m:SetFogFar(value)
            m:SetFogNear(value - 0.01)
        end

        print(value)
    end)
    model.modelSliderFar:Enable()
    model.modelSliderFar:SetValue(2.92)
    model.modelSliderFar:Show()

    model.saveButton = core.CreateMeATextButton(model, 112, 24, "Save")
	model.saveButton:SetPoint("LEFT", model.modelUpButton, "RIGHT", 8, 0)
	model.saveButton:Show()
    model.saveButton:SetScript("OnClick", function()
        print("uwu")
        local model = core.itemCollectionFrame.mannequins[1]

        local x, y, z = model:GetPosition()
        local facing = model:GetFacing()
        local near = model:GetFogNear()
        local far = model:GetFogFar()
        local seq = model.seq
        local time = model.time
        local speed = model.speed
        
        local _, race = UnitRace("player")
        -- local inventorySlot = select(2, core.GetTransmogLocationInfo(core.itemCollectionFrame.location))
        local slot = core.itemCollectionFrame.selectedSlot
        local category = core.itemCollectionFrame.selectedCategory or "Default"
        
        -- TransmoggyDB.newPositions = TransmoggyDB.newPositions or {}
        -- TransmoggyDB.newPositions[race] = TransmoggyDB.newPositions[race] or {}
        -- TransmoggyDB.newPositions[race][inventorySlot] = {
        --     x, y, z, facing, near, far, seq, time, 0
        -- }
        --print(x, y, z, facing, near, far, seq, time)

        local _, race = UnitRace("player")
        local sex = UnitSex("player")
        local id = core.sexRaceToID[sex][race]
        print(race, sex)
        print(core.sexRaceToID[sex][race])

        -- TransmoggyDB.modelPositionData = TransmoggyDB.modelPositionData or {
        --     x = {},
        --     y = {},
        --     z = {},
        --     facing = {},
        --     near = {},
        --     far = {},
        --     seq = {},
        --     time = {},
        -- }

        -- TransmoggyDB.modelPositionData.x[id] = x
        -- TransmoggyDB.modelPositionData.y[id] = y
        -- TransmoggyDB.modelPositionData.z[id] = z
        -- TransmoggyDB.modelPositionData.facing[id] = facing
        -- TransmoggyDB.modelPositionData.near[id] = near
        -- TransmoggyDB.modelPositionData.far[id] = far
        -- TransmoggyDB.modelPositionData.time[id] = time
        
        TransmoggyDB.positionData = TransmoggyDB.positionData or {}
        TransmoggyDB.positionData[id] = TransmoggyDB.positionData[id] or {}
        TransmoggyDB.positionData[id][slot] = TransmoggyDB.positionData[id][slot] or {}
        TransmoggyDB.positionData[id][slot][category] = { x, y, z, facing, near, far, seq, time }
        AM(TransmoggyDB.positionData[id][slot])

        -- TransmoggyDB.positionData = nil

        -- for _, m in pairs(core.itemCollectionFrame.mannequins) do
        --     DEB(m)
        -- end
        -- /run for _, m in pairs(Addy.itemCollectionFrame.mannequins) do DEB(m) end
    end)

    model:SetPosition(-0.3, -0.62, -0.5)
    model:SetFacing(2)

    return model
end

DEBUG = function(model)
    local x, y, z = model:GetPosition()
    local facing = model:GetFacing()
    local near = model:GetFogNear()
    local far = model:GetFogFar()
    core.am(x, y, z, facing, near, far)
end

DEB = function(model)
    local model = model or GetMouseFocus()
    
    local _, race = UnitRace("player")
    local inventorySlot = select(2, core.GetTransmogLocationInfo(core.itemCollectionFrame.location))

    if not TransmoggyDB.newPositions or not TransmoggyDB.newPositions[race] or not TransmoggyDB.newPositions[race][inventorySlot] then return end

    local x, y, z, facing, near, far, seq, time = unpack(TransmoggyDB.newPositions[race][inventorySlot])
    print(unpack(TransmoggyDB.newPositions[race][inventorySlot]))

    --model:SetUnit("player")
    local r, g, b = 0.1, 0.1, 0.1

    model:SetPosition(x, y, z)
    model:SetFacing(facing)
    model:SetFogColor(r, g, b)
    model:SetFogNear(near)
    model:SetFogFar(far)
    model:SetAnimation(seq, time, 0)

    
    model:Undress()  
    model:TryOnOld(39519) -- Black Gloves
    model:TryOnOld(11731) -- Black Shoes
    model:TryOnOld(6835) -- Black Leggings
    model:TryOnOld(3427) -- Black Shirt
    model:TryOnOld(9998) -- Black West
    model:TryOnOld(model.item)
end




-- local races = { "Human", "Orc", "Dwarf", "Night Elf", "Undead", "Tauren", "Gnome", "Troll", "Blood Elf", "Draenei" }
-- local sexes = { "Diverse", "Male", "Female" }
local raceIDs = { Human = 1, Orc = 2, Dwarf = 3, ["Night Elf"] = 4, Undead = 5, Tauren = 6, Gnome = 7, Troll = 8, ["Blood Elf"] = 9, Draenei = 10}
core.sexRaceToID = {}
for i = 2, 3 do -- male, female
    core.sexRaceToID[i] = {}
    for race, id in pairs(raceIDs) do -- races
        core.sexRaceToID[i][race] = 10 * (i - 2) + id
    end
end
AM(core.sexRaceToID)