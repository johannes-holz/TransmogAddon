local folder, core = ...

-- Outfitframe with dropdown and save button
-- Needs to be parented to DressUpModel Frame, that has to implement a GetAll and SetAll method
local counter = 1
core.CreateOutfitFrame = function(parent)
    local outfitFrame = CreateFrame("Frame", folder .. "OutfitFrame" .. counter, parent)
    outfitFrame:SetSize(220, 31)
    outfitFrame:EnableMouse(true)

    outfitFrame.SetSelectedOutfit = function(self, name)
        local outfits = core.GetOutfits()
        assert(name == nil or outfits and outfits[name])
        
        self.selectedOutfit = name
        if name then
            self:GetParent():SetAll(outfits[name])
        end
        self.outfitDDM:update()
        self.saveButton:update()
    end

    outfitFrame.GetSelectedOutfit = function(self)
        return self.selectedOutfit
    end

    outfitFrame.ModelDiffersFromOutfit = function(self, outfit)
        if not outfit then return false end
        local model = self:GetParent()
        local modelSlots = model:GetAll()
        local outfitSlots = core.GetOutfits()[outfit]
    
        for _, slot in pairs(core.itemSlots) do
            if modelSlots[slot] ~= outfitSlots[slot] then
                return true
            end
        end
        return false
    end

    -- outfitFrame.GetSelectedOutfitName = function(self)
    --     local outfits = core.GetOutfits()
    --     return outfits and self.selectedOutfit and outfits[self.selectedOutfit] and outfits[self.selectedOutfit].name
    -- end

    outfitFrame:SetScript("OnHide", function(self)
        self:SetSelectedOutfit(nil)
    end)

    outfitFrame.update = function(self)
        local outfits = core.GetOutfits()

        if not outfits[self.selectedOutfit] then
            self:SetSelectedOutfit(nil)
        end
    end
    core.RegisterListener("outfits", outfitFrame)

    outfitFrame.saveButton = core.CreateMeATextButton(outfitFrame, 70, 22, SAVE)
    outfitFrame.saveButton:SetPoint("TOPRIGHT", -4, -4)
    outfitFrame.saveButton:SetScript("OnClick", function(self)
        local selectedOutfit = self:GetParent().selectedOutfit
        local slots = self:GetParent():GetParent():GetAll()
        if not selectedOutfit then return end

        core.SaveOutfit(selectedOutfit, slots)
    end)
    outfitFrame.saveButton.update = function(self)
        local outfit = self:GetParent().selectedOutfit
        core.SetEnabled(self, outfit and self:GetParent():ModelDiffersFromOutfit(outfit))
    end
    core.RegisterListener("outfits", outfitFrame.saveButton)
    core.RegisterListener("dressUpModel", outfitFrame.saveButton)
    core.RegisterListener("previewModel", outfitFrame.saveButton)
    outfitFrame.saveButton:SetScript("OnShow", outfitFrame.saveButton.update)        

    outfitFrame.outfitDDM = core.CreateOutfitDDM(outfitFrame)
    outfitFrame.outfitDDM:SetPoint("TOPRIGHT", outfitFrame.saveButton, "TOPLEFT", -34, 3)

    -- Fade In/Out code
    outfitFrame.fadedAlpha = 0.4
    outfitFrame.interval = 0.05
    outfitFrame.speed = 0.12
    outfitFrame.e = outfitFrame.interval
    outfitFrame.fadeOutDelay = 0
    outfitFrame.fadeOutTimer = outfitFrame.fadeOutDelay
    outfitFrame.OnUpdate = function(self, elapsed)
        self.e = self.e - elapsed

        if self.e < 0 then
            self.e = self.e + self.interval
            
            local currentDDM = UIDropDownMenu_GetCurrentDropDown()
            local ddmActive = DropDownList1:IsShown()
            local show = core.MouseIsOver(self) or currentDDM == self.outfitDDM and ddmActive or core.IsOutfitPopupActive()
            local show = show and not (currentDDM ~= self.outfitDDM and ddmActive)
            self.targetAlpha = show and 1 or self.fadedAlpha
            self.fadeOutTimer = show and self.fadeOutDelay or self.fadeOutTimer - self.interval

            local alpha = self:GetAlpha()
            if alpha == self.targetAlpha then
                return
            elseif alpha < self.targetAlpha then
                alpha = min(self.targetAlpha, alpha + self.speed)
            elseif self.fadeOutTimer < 0 then
                alpha = max(self.targetAlpha, alpha - self.speed)
            end
            self:SetAlpha(alpha)
        end
    end
    outfitFrame.EnableFading = function(self, fading)
        self:SetScript("OnUpdate", fading and self.OnUpdate or nil)
    end
    outfitFrame.EnableBackground = function(self, background)
        self:SetBackdrop(background and BACKDROP_TUTORIAL_16_16 or nil)
    end

    outfitFrame.Resize = function(self)
        self:SetWidth(self.outfitDDM:GetWidth() + self.saveButton:GetWidth() + 24)
    end    
    outfitFrame.outfitDDM:HookScript("OnSizeChanged", function(self)
        self:GetParent():Resize()
    end)
    outfitFrame.saveButton:HookScript("OnSizeChanged", function(self)
        self:GetParent():Resize()
    end)

    return outfitFrame
end

DressUpFrameDescriptionText:Hide()
core.dressUpModelOutfitFrame = core.CreateOutfitFrame(DressUpModel)
core.dressUpModelOutfitFrame:SetPoint("BOTTOMRIGHT", DressUpModel, "TOPRIGHT", -40, 6)
UIDropDownMenu_SetWidth(core.dressUpModelOutfitFrame.outfitDDM, 110, 0)

core.previewModelOutfitFrame = core.CreateOutfitFrame(core.previewModel)
core.previewModelOutfitFrame:SetPoint("TOPRIGHT", core.previewModel, "TOPRIGHT", -67 * core.transmogFrame.scale, -1)
UIDropDownMenu_SetWidth(core.previewModelOutfitFrame.outfitDDM, 100, 0)
core.previewModelOutfitFrame:SetScale(0.9)
core.previewModelOutfitFrame:EnableFading(true)
core.previewModelOutfitFrame:EnableBackground(true)