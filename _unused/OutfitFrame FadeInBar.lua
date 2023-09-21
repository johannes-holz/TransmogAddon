local folder, core = ...

local counter = 1
core.CreateOutfitFrame = function(parent)
    local outfitFrame = CreateFrame("Frame", folder .. "OutfitFrame" .. counter, parent)
    outfitFrame:SetSize(220, 32)
    outfitFrame:SetPoint("TOP", 20, -2)
    outfitFrame:EnableMouse(true)
    outfitFrame:SetBackdrop(BACKDROP_TUTORIAL_16_16)
    outfitFrame:SetAlpha(0.6)

    outfitFrame.SetSelectedOutfit = function(self, name)
        local outfits = core.GetOutfits()
        assert(name == nil or outfits and outfits[name])
        
        self.selectedOutfit = name
        if name then
            self:GetParent():SetAll(outfits[name])
        end
        core.UpdateListeners("selectedOutfit")
    end

    outfitFrame.GetSelectedOutfit = function(self)
        return self.selectedOutfit
    end

    -- outfitFrame.GetSelectedOutfitName = function(self)
    --     local outfits = core.GetOutfits()
    --     return outfits and self.selectedOutfit and outfits[self.selectedOutfit] and outfits[self.selectedOutfit].name
    -- end

    outfitFrame.update = function(self)
        local outfits = core.GetOutfits()

        if not outfits[self.selectedOutfit] then
            self:SetSelectedOutfit(nil)
        end
    end
    core.RegisterListener("outfits", outfitFrame)

    outfitFrame:SetScript("OnHide", function(self)
        self:SetSelectedOutfit(nil)
    end)

    outfitFrame.outfitDDM = core.CreateOutfitDDM(outfitFrame)
    outfitFrame.outfitDDM:SetPoint("LEFT", -15, -2)

    outfitFrame.saveButton = core.CreateMeATextButton(outfitFrame, 80, 22, SAVE)
    outfitFrame.saveButton:SetPoint("RIGHT", -5, 0)
    outfitFrame.saveButton:SetScript("OnClick", function(self)
        local selectedOutfit = self:GetParent().selectedOutfit
        local slots = self:GetParent():GetParent():GetAll()
        if not selectedOutfit then return end

        core.SaveOutfit(selectedOutfit, slots)
    end)
    outfitFrame.saveButton.update = function(self)
        self:Disable()

        if not self:GetParent().selectedOutfit then
            return
        end

        local modelState = self:GetParent():GetParent():GetAll()
        local outfit = core.GetOutfits()[self:GetParent().selectedOutfit]

        for _, slot in pairs(core.itemSlots) do
            if modelState[slot] ~= outfit[slot] then
                self:Enable()
                return
            end
        end
    end
    core.RegisterListener("outfits", outfitFrame.saveButton)
    core.RegisterListener("selectedOutfit", outfitFrame.saveButton)
    core.RegisterListener("dressUpModel", outfitFrame.saveButton)
    outfitFrame.saveButton:SetScript("OnShow", outfitFrame.saveButton.update)    

    
    outfitFrame.interval = 0.05
    outfitFrame.e = outfitFrame.interval
    outfitFrame.fadeOutDelay = 0
    outfitFrame.fadeOutTimer = outfitFrame.fadeOutDelay
    outfitFrame.OnUpdate = function(self, elapsed)
        self.e = self.e - elapsed

        if self.e < 0 then
            self.e = self.e + self.interval
                     
            local show = core.MouseIsOver(self) or UIDropDownMenu_GetCurrentDropDown() == self.outfitDDM and DropDownList1:IsShown() or StaticPopup1:IsShown()
            self.targetAlpha = show and 1 or 0.6
            self.fadeOutTimer = show and self.fadeOutDelay or self.fadeOutTimer - self.interval

            local alpha = self:GetAlpha()
            if alpha == self.targetAlpha then
                return
            elseif alpha < self.targetAlpha then
                alpha = min(self.targetAlpha, alpha + 0.1)
            elseif self.fadeOutTimer < 0 then
                alpha = max(self.targetAlpha, alpha - 0.1)
            end
            self:SetAlpha(alpha)
        end
    end
    outfitFrame:SetScript("OnUpdate", outfitFrame.OnUpdate)

    return outfitFrame
end

core.CreateOutfitFrame(DressUpModel)