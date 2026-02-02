local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

addon.sadCore.savedVarsGlobalName = "SAdBars_Settings_Global"
addon.sadCore.savedVarsPerCharName = "SAdBars_Settings_Char"
addon.sadCore.compartmentFuncName = "SAdBars_Compartment_Func"
addon.actionBars = {
    { name = "MainMenuBar", frame = MainMenuBar, buttonPrefix = "ActionButton", displayName = "Bar 1" },
    { name = "MultiBarBottomLeft", frame = MultiBarBottomLeft, buttonPrefix = "MultiBarBottomLeftButton", displayName = "Bar 2" },
    { name = "MultiBarBottomRight", frame = MultiBarBottomRight, buttonPrefix = "MultiBarBottomRightButton", displayName = "Bar 3" },
    { name = "MultiBarRight", frame = MultiBarRight, buttonPrefix = "MultiBarRightButton", displayName = "Bar 4" },
    { name = "MultiBarLeft", frame = MultiBarLeft, buttonPrefix = "MultiBarLeftButton", displayName = "Bar 5" },
    { name = "MultiBar5", frame = MultiBar5, buttonPrefix = "MultiBar5Button", displayName = "Bar 6" },
    { name = "MultiBar6", frame = MultiBar6, buttonPrefix = "MultiBar6Button", displayName = "Bar 7" },
    { name = "MultiBar7", frame = MultiBar7, buttonPrefix = "MultiBar7Button", displayName = "Bar 8" },
    { name = "PetActionBar", frame = PetActionBar, buttonPrefix = "PetActionButton", displayName = "Pet Bar" },
    { name = "StanceBar", frame = StanceBar, buttonPrefix = "StanceButton", displayName = "Stance Bar" },
}

addon.vars = addon.vars or {
    borderWidth = 2,
    borderColor = "000000FF",
    iconZoom = 0.3,
    buttonPadding = 0
}

addon.gcdButtons = {}

function addon:UpdateActionBars()
    local startTime = debugprofilestop()
    self:Debug("UpdateActionBars: Starting")
    
    self:CustomizeProcGlow()
    self:HideSpellActivationOverlay()
    self:AddActionButtonBorders()
    self:SetButtonPadding()
    self:HideMacroText()
    self:HideKeybindText()
    self:HideSpellCastAnimFrame()
    self:AddActionBarBackgrounds()
    self:UpdateAssistedHighlightVisibility()
    self:CustomizeAssistedHighlightGlow()
    self:ZoomButtonIcons()
    self:CustomizeCooldownFont()
    self:CreateCustomGCDFrames()
    self:UpdateFadeBars()
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("UpdateActionBars: Completed in %.2fms", elapsed))
end

function addon:Initialize()
    self.author = "Rôkk-Wyrmrest Accord"
    
    -- Fade Bars Settings Panel
    local fadeControls = {}
    table.insert(fadeControls, {
        type = "header",
        name = "fadeBarsHeader"
    })
    
    for i, barInfo in ipairs(self.actionBars) do
        -- Skip MainMenuBar (Bar 1) as Blizzard doesn't allow it to be hidden
        if barInfo.name ~= "MainMenuBar" then
            table.insert(fadeControls, {
                type = "checkbox",
                name = "fadeBar" .. barInfo.name,
                default = false,
                onValueChange = function(isChecked)
                    addon:UpdateFadeBars()
                end
            })
        end
    end
    
    self:AddSettingsPanel("fadeBars", {
        title = "fadeBarsTitle",
        controls = fadeControls
    })
    
    self:RegisterSlashCommand("debug", function()
        addon:BuildGCDButtonList()
    end)
    
    self:RegisterSlashCommand("offgcd", function()
        local count = 0
        for _ in pairs(addon.offGCDSpells) do
            count = count + 1
        end
        
        if count == 0 then
            print("SAdBars: No OFF-GCD spells in list.")
            return
        end
        
        print(string.format("SAdBars: OFF-GCD Spells (%d):", count))
        for spellID, spellName in pairs(addon.offGCDSpells) do
            print(string.format("  - %s (ID: %d)", spellName, spellID))
        end
    end)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(event)
        self:Debug("Event: PLAYER_ENTERING_WORLD triggered")
        self:CombatSafe(function()
            self:UpdateActionBars()
        end)
    end)
    
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(...)
        local eventTable, eventName, unit, castGUID, spellID = ...
        
        if unit == "player" and spellID then
            self:Debug(string.format("UNIT_SPELLCAST_SUCCEEDED: spellID=%s", tostring(spellID)))
            addon:TriggerGCDAnimation(spellID)
        end
    end)
end

function addon:IterateActionButtons(callback)
    if type(callback) ~= "function" then return end
    
    local startTime = debugprofilestop()
    local buttonCount = 0
    
    for _, barInfo in ipairs(self.actionBars) do
        local prefix = barInfo.buttonPrefix
        for i = 1, 12 do
            local buttonName = prefix .. i
            local button = _G[buttonName]
            if button then
                buttonCount = buttonCount + 1
                callback(button, buttonName)
            end
        end
    end
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("IterateActionButtons: Processed %d buttons in %.2fms", buttonCount, elapsed))
end

function addon:IterateActionBars(callback)
    if type(callback) ~= "function" then return end
    
    for _, barInfo in ipairs(self.actionBars) do
        if barInfo.frame then
            callback(barInfo.frame, barInfo.name)
        end
    end
end

function addon:addBorder(bar, borderWidth, borderColor)
    if not bar then return end
    
    local size = borderWidth or addon.vars.borderWidth
    local colorHex = borderColor or addon.vars.borderColor
    local r, g, b, a = self:HexToRGB(colorHex)
    
    local borders = bar.SAdBars_Borders
    
    if borders then
        borders.top:SetColorTexture(r, g, b, a)
        borders.top:SetHeight(size)
        borders.bottom:SetColorTexture(r, g, b, a)
        borders.bottom:SetHeight(size)
        borders.left:SetColorTexture(r, g, b, a)
        borders.left:SetWidth(size)
        borders.right:SetColorTexture(r, g, b, a)
        borders.right:SetWidth(size)
    else
        borders = {}
        
        borders.top = bar:CreateTexture(nil, "OVERLAY")
        borders.top:SetColorTexture(r, g, b, a)
        borders.top:SetHeight(size)
        borders.top:ClearAllPoints()
        borders.top:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        borders.top:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        
        borders.bottom = bar:CreateTexture(nil, "OVERLAY")
        borders.bottom:SetColorTexture(r, g, b, a)
        borders.bottom:SetHeight(size)
        borders.bottom:ClearAllPoints()
        borders.bottom:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        borders.bottom:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        
        borders.left = bar:CreateTexture(nil, "OVERLAY")
        borders.left:SetColorTexture(r, g, b, a)
        borders.left:SetWidth(size)
        borders.left:ClearAllPoints()
        borders.left:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        borders.left:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        
        borders.right = bar:CreateTexture(nil, "OVERLAY")
        borders.right:SetColorTexture(r, g, b, a)
        borders.right:SetWidth(size)
        borders.right:ClearAllPoints()
        borders.right:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        borders.right:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        
        bar.SAdBars_Borders = borders
    end
end

function addon:CustomizeProcGlow()
    local startTime = debugprofilestop()
    self:Debug("CustomizeProcGlow: Starting")
    
    self:IterateActionButtons(function(button, buttonName)
        if button and button.SpellActivationAlert then
            button.SpellActivationAlert:Hide()
            button.SpellActivationAlert:SetAlpha(0)
            
            if not button.SpellActivationAlert.__SAdUI_HideHooked then
                button.SpellActivationAlert.__SAdUI_HideHooked = true
                hooksecurefunc(button.SpellActivationAlert, "Show", function(self)
                    addon:Debug("Hook: SpellActivationAlert.Show fired")
                    self:Hide()
                    self:SetAlpha(0)
                end)
            end
        end
    end)
    
    if ActionButtonSpellAlertManager and not ActionButtonSpellAlertManager.__SAdUI_Hooked then
        ActionButtonSpellAlertManager.__SAdUI_Hooked = true
        hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(self, actionButton)
            addon:Debug("Hook: ActionButtonSpellAlertManager.ShowAlert fired")
            if type(actionButton) ~= "table" then
                actionButton = self
            end
            
            if actionButton and actionButton.SpellActivationAlert then
                actionButton.SpellActivationAlert:Hide()
                actionButton.SpellActivationAlert:SetAlpha(0)
            end
        end)
    end
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("CustomizeProcGlow: Completed in %.2fms", elapsed))
end

function addon:HideSpellActivationOverlay()
    local startTime = debugprofilestop()
    self:Debug("HideSpellActivationOverlay: Starting")
    
    if SpellActivationOverlayFrame then
        SpellActivationOverlayFrame:Hide()
        SpellActivationOverlayFrame:SetAlpha(0)
        
        hooksecurefunc(SpellActivationOverlayFrame, "Show", function(self)
            addon:Debug("Hook: SpellActivationOverlayFrame.Show fired")
            self:Hide()
            self:SetAlpha(0)
        end)
    end
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("HideSpellActivationOverlay: Completed in %.2fms", elapsed))
end

function addon:AddActionButtonBorders()
    local startTime = debugprofilestop()
    self:Debug("AddActionButtonBorders: Starting")
    
    local function addButtonBorder(button, buttonName)
        if button then
            local normalTexture = button:GetNormalTexture()
            if normalTexture then
                normalTexture:SetAlpha(0)
                normalTexture:Hide()
            end
            
            if button.NormalTexture then
                button.NormalTexture:SetAlpha(0)
                button.NormalTexture:Hide()
            end
            
            addon:addBorder(button)
        end
    end
    
    self:IterateActionButtons(addButtonBorder)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("AddActionButtonBorders: Completed in %.2fms", elapsed))
end

function addon:SetButtonPadding()
    local startTime = debugprofilestop()
    self:Debug("SetButtonPadding: Starting")
    
    local padding = addon.vars.buttonPadding
    
    self:IterateActionBars(function(bar, name)
        if bar.SetAttribute then
            bar:SetAttribute("buttonSpacing", padding)
        end
        
        if bar.UpdateGridLayout then
            hooksecurefunc(bar, "UpdateGridLayout", function(self)
                addon:Debug(string.format("Hook: %s.UpdateGridLayout fired", name))
                if self.SetAttribute then
                    self:SetAttribute("buttonSpacing", padding)
                end
            end)
        end
        
        if bar.UpdateGridLayout then
            bar:UpdateGridLayout()
        elseif bar.Layout then
            bar:Layout()
        end
    end)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("SetButtonPadding: Completed in %.2fms", elapsed))
end

function addon:HideMacroText()
    local startTime = debugprofilestop()
    self:Debug("HideMacroText: Starting")
    
    local function hideButtonMacroText(button, buttonName)
        if button and button.Name then
            button.Name:SetAlpha(0)
            button.Name:Hide()
            hooksecurefunc(button.Name, "Show", function(self)
                addon:Debug(string.format("Hook: %s.Name.Show fired", buttonName))
                self:SetAlpha(0)
            end)
        end
    end
    
    self:IterateActionButtons(hideButtonMacroText)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("HideMacroText: Completed in %.2fms", elapsed))
end

function addon:HideKeybindText()
    local startTime = debugprofilestop()
    self:Debug("HideKeybindText: Starting")
    
    local function hideButtonKeybind(button, buttonName)
        if button and button.HotKey then
            button.HotKey:SetAlpha(0)
            button.HotKey:Hide()
            hooksecurefunc(button.HotKey, "Show", function(self)
                addon:Debug(string.format("Hook: %s.HotKey.Show fired", buttonName))
                self:SetAlpha(0)
            end)
        end
    end
    
    self:IterateActionButtons(hideButtonKeybind)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("HideKeybindText: Completed in %.2fms", elapsed))
end

function addon:HideSpellCastAnimFrame()
    local startTime = debugprofilestop()
    self:Debug("HideSpellCastAnimFrame: Starting")
    
    local function hideButtonGlow(button)
        if button and button.SpellCastAnimFrame then
            button.SpellCastAnimFrame:SetAlpha(0)
            button.SpellCastAnimFrame:Hide()
            
            hooksecurefunc(button.SpellCastAnimFrame, "Show", function(self)
                addon:Debug("Hook: SpellCastAnimFrame.Show fired")
                self:SetAlpha(0)
            end)
            
            if button.SpellCastAnimFrame.Fill then
                button.SpellCastAnimFrame.Fill:SetAlpha(0)
                button.SpellCastAnimFrame.Fill:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.Fill, "Show", function(self)
                    addon:Debug("Hook: SpellCastAnimFrame.Fill.Show fired")
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.InnerGlow then
                button.SpellCastAnimFrame.InnerGlow:SetAlpha(0)
                button.SpellCastAnimFrame.InnerGlow:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.InnerGlow, "Show", function(self)
                    addon:Debug("Hook: SpellCastAnimFrame.InnerGlow.Show fired")
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.FillMask then
                button.SpellCastAnimFrame.FillMask:SetAlpha(0)
                button.SpellCastAnimFrame.FillMask:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.FillMask, "Show", function(self)
                    addon:Debug("Hook: SpellCastAnimFrame.FillMask.Show fired")
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.Ants then
                button.SpellCastAnimFrame.Ants:SetAlpha(0)
                button.SpellCastAnimFrame.Ants:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.Ants, "Show", function(self)
                    addon:Debug("Hook: SpellCastAnimFrame.Ants.Show fired")
                    self:SetAlpha(0)
                end)
            end
            if button.SpellCastAnimFrame.Spark then
                button.SpellCastAnimFrame.Spark:SetAlpha(0)
                button.SpellCastAnimFrame.Spark:Hide()
                hooksecurefunc(button.SpellCastAnimFrame.Spark, "Show", function(self)
                    addon:Debug("Hook: SpellCastAnimFrame.Spark.Show fired")
                    self:SetAlpha(0)
                end)
            end
        end
        
        if button and button.InterruptDisplay then
            button.InterruptDisplay:SetAlpha(0)
            button.InterruptDisplay:Hide()
            hooksecurefunc(button.InterruptDisplay, "Show", function(self)
                addon:Debug("Hook: InterruptDisplay.Show fired")
                self:SetAlpha(0)
            end)
            if button.InterruptDisplay.Base then
                button.InterruptDisplay.Base:SetAlpha(0)
                button.InterruptDisplay.Base:Hide()
            end
            if button.InterruptDisplay.Highlight then
                button.InterruptDisplay.Highlight:SetAlpha(0)
                button.InterruptDisplay.Highlight:Hide()
            end
        end
        
        if button then
            local checkedTexture = button:GetCheckedTexture()
            if checkedTexture then
                checkedTexture:SetAlpha(0)
                checkedTexture:Hide()
            end
            hooksecurefunc(button, "SetChecked", function(self)
                if self:GetChecked() then
                    local tex = self:GetCheckedTexture()
                    if tex then
                        tex:SetAlpha(0)
                        tex:Hide()
                    end
                end
            end)
        end
    end
    
    self:IterateActionButtons(function(button, buttonName)
        hideButtonGlow(button)
    end)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("HideSpellCastAnimFrame: Completed in %.2fms", elapsed))
end

function addon:AddActionBarBackgrounds()
    local startTime = debugprofilestop()
    self:Debug("AddActionBarBackgrounds: Starting")
    
    self:IterateActionBars(function(bar, name)
        if bar.GetSettingValueBool then
            local alwaysShowButtons = bar:GetSettingValueBool(9)
            
            if alwaysShowButtons and not bar.SAdUI_Background then
                local bg = bar:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(bar)
                bg:SetColorTexture(0, 0, 0, 0.5)
                bar.SAdUI_Background = bg
            end
        end
    end)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("AddActionBarBackgrounds: Completed in %.2fms", elapsed))
end

function addon:UpdateAssistedHighlightVisibility()
    local startTime = debugprofilestop()
    self:Debug("UpdateAssistedHighlightVisibility: Starting")
    
    local inCombat = UnitAffectingCombat("player")
    
    self:IterateActionButtons(function(button, buttonName)
        if button.AssistedCombatHighlightFrame then
            local highlightFrame = button.AssistedCombatHighlightFrame
            if not inCombat then
                highlightFrame:Hide()
            end
        end
    end)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("UpdateAssistedHighlightVisibility: Completed in %.2fms", elapsed))
end

function addon:CustomizeAssistedHighlightGlow()
    local startTime = debugprofilestop()
    self:Debug("CustomizeAssistedHighlightGlow: Starting")
    
    -- Buttons where the glow should be hidden completely
    local hideGlowButtons = {
        ["MultiBarBottomLeftButton1"] = true,
        ["MultiBarBottomLeftButton6"] = true,
        ["MultiBarBottomLeftButton12"] = true,
    }
    
    local function UpdateAssistedHighlight(actionButton, shown)
        addon:Debug(string.format("UpdateAssistedHighlight called: shown=%s", tostring(shown)))
        local highlightFrame = actionButton.AssistedCombatHighlightFrame
        local inCombat = UnitAffectingCombat("player")
        
        -- Check if this button should have glow hidden
        local buttonName = actionButton:GetName()
        if buttonName and hideGlowButtons[buttonName] then
            if highlightFrame then
                highlightFrame:Hide()
            end
            return
        end
        
        if highlightFrame and highlightFrame:IsVisible() and shown and inCombat then
            local flipbook = highlightFrame.Flipbook
            if flipbook then
                flipbook:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
                flipbook:SetDesaturated(true)
                flipbook:SetVertexColor(1.0, 0.0, 1.0, 1.0) -- Magenta
                
                local anim = flipbook.Anim:GetAnimations()
                if anim then
                    flipbook:ClearAllPoints()
                    flipbook:SetSize(flipbook:GetSize())
                    flipbook:SetPoint("CENTER", highlightFrame, "CENTER", -1.5, 1)
                    
                    flipbook.Anim:Stop()
                    flipbook.Anim:Play()
                end
            end
        elseif highlightFrame and not inCombat then
            highlightFrame:Hide()
        end
    end
    
    if AssistedCombatManager then
        hooksecurefunc(AssistedCombatManager, "SetAssistedHighlightFrameShown", function(self, actionButton, shown)
            addon:Debug("Hook: AssistedCombatManager.SetAssistedHighlightFrameShown fired")
            UpdateAssistedHighlight(actionButton, shown)
        end)
    end
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("CustomizeAssistedHighlightGlow: Completed in %.2fms", elapsed))
end

function addon:ZoomButtonIcons()
    local startTime = debugprofilestop()
    self:Debug("ZoomButtonIcons: Starting")
    
    local zoom = addon.vars.iconZoom
    local inset = zoom / 2
    
    local function zoomButtonIcon(button, buttonName)
        if button and button.icon then
            button.icon:SetTexCoord(inset, 1 - inset, inset, 1 - inset)
            
            if button.cooldown then
                button.cooldown:ClearAllPoints()
                button.cooldown:SetAllPoints(button)
            end
        end
    end
    
    self:IterateActionButtons(zoomButtonIcon)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("ZoomButtonIcons: Completed in %.2fms", elapsed))
end

function addon:CustomizeCooldownFont()
    local startTime = debugprofilestop()
    self:Debug("CustomizeCooldownFont: Starting (currently disabled)")
    
--     local function adjustCooldownFont(button, buttonName)
--         if button and button.cooldown then
--             for _, region in pairs({button.cooldown:GetRegions()}) do
--                 if region:GetObjectType() == "FontString" then
--                     local font, _, flags = region:GetFont()
--                     if font then
--                         region:SetFont(font, 20, flags)
--                     end
--                 end
--             end
            
--             if not button.cooldown.__SAdBars_FontHooked then
--                 button.cooldown.__SAdBars_FontHooked = true
--                 hooksecurefunc(button.cooldown, "SetCooldown", function(self)
--                     addon:Debug(string.format("Hook: %s.cooldown.SetCooldown fired", buttonName))
--                     for _, region in pairs({self:GetRegions()}) do
--                         if region:GetObjectType() == "FontString" then
--                             local font, _, flags = region:GetFont()
--                             if font then
--                                 region:SetFont(font, 20, flags)
--                             end
--                         end
--                     end
--                 end)
--             end
--         end
--     end
    
--     self:IterateActionButtons(adjustCooldownFont)
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("CustomizeCooldownFont: Completed in %.2fms", elapsed))
end

function addon:UpdateFadeBars()
    local startTime = debugprofilestop()
    self:Debug("UpdateFadeBars: Starting")
    
    -- Create a list of bars that should fade
    local fadeBars = {}
    for _, barInfo in ipairs(self.actionBars) do
        local settingName = "fadeBar" .. barInfo.name
        local shouldFade = self:GetValue("fadeBars", settingName)
        if shouldFade and barInfo.frame then
            table.insert(fadeBars, barInfo.frame)
        end
    end
    
    -- If no bars are set to fade, clean up and exit
    if #fadeBars == 0 then
        for _, barInfo in ipairs(self.actionBars) do
            if barInfo.frame then
                barInfo.frame:SetAlpha(1)
                if barInfo.frame.SAdBars_FadeScripts then
                    barInfo.frame:SetScript("OnEnter", nil)
                    barInfo.frame:SetScript("OnLeave", nil)
                    barInfo.frame.SAdBars_FadeScripts = nil
                end
            end
        end
        local elapsed = debugprofilestop() - startTime
        self:Debug(string.format("UpdateFadeBars: No bars to fade, completed in %.2fms", elapsed))
        return
    end
    
    -- Function to fade all bars in
    local function FadeAllBarsIn()
        if InCombatLockdown() then
            -- In combat, set alpha directly without animation
            for _, bar in ipairs(fadeBars) do
                bar:SetAlpha(1)
            end
        else
            -- Out of combat, use smooth fade animation
            for _, bar in ipairs(fadeBars) do
                UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), 1)
            end
        end
    end
    
    -- Function to fade all bars out
    local function FadeAllBarsOut()
        if InCombatLockdown() then
            -- In combat, set alpha directly without animation
            for _, bar in ipairs(fadeBars) do
                bar:SetAlpha(0)
            end
        else
            -- Out of combat, use smooth fade animation
            for _, bar in ipairs(fadeBars) do
                UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
            end
        end
    end
    
    -- Set up mouse detection only on bars that are fading
    for _, barInfo in ipairs(self.actionBars) do
        if barInfo.frame then
            local settingName = "fadeBar" .. barInfo.name
            local shouldFade = self:GetValue("fadeBars", settingName)
            
            if shouldFade then
                -- This bar is faded, so hovering it should reveal all faded bars
                barInfo.frame:EnableMouse(true)
                barInfo.frame:SetScript("OnEnter", function()
                    FadeAllBarsIn()
                end)
                barInfo.frame:SetScript("OnLeave", function()
                    FadeAllBarsOut()
                end)
                barInfo.frame.SAdBars_FadeScripts = true
                
                -- Also attach handlers to all buttons in this bar
                local prefix = barInfo.buttonPrefix
                for i = 1, 12 do
                    local buttonName = prefix .. i
                    local button = _G[buttonName]
                    if button then
                        button:HookScript("OnEnter", function()
                            FadeAllBarsIn()
                        end)
                        button:HookScript("OnLeave", function()
                            FadeAllBarsOut()
                        end)
                    end
                end
            else
                -- This bar is not faded, remove any fade scripts
                if barInfo.frame.SAdBars_FadeScripts then
                    barInfo.frame:SetScript("OnEnter", nil)
                    barInfo.frame:SetScript("OnLeave", nil)
                    barInfo.frame.SAdBars_FadeScripts = nil
                end
            end
        end
    end
    
    -- Initial fade out for enabled bars
    for _, bar in ipairs(fadeBars) do
        bar:SetAlpha(0)
    end
    
    local elapsed = debugprofilestop() - startTime
    self:Debug(string.format("UpdateFadeBars: Configured %d bars to fade in %.2fms", #fadeBars, elapsed))
end

function addon:CreateCustomGCDFrames()
    self:Debug("CreateCustomGCDFrames: Stub function (implementation commented out)")
end

function addon:TriggerGCDAnimation(spellID)
    self:Debug(string.format("TriggerGCDAnimation: Stub function - spellID=%s (implementation commented out)", tostring(spellID)))
end

























-- function addon:DetectGCDSpell(spellID)
--     print(string.format("[SAdBars] DetectGCDSpell: checking spellID=%s", tostring(spellID)))
--     if not spellID then return nil end
    
--     local spellInfo = C_Spell.GetSpellInfo(spellID)
--     if not spellInfo then return nil end
    
--     local gcdInfo = C_Spell.GetSpellCooldown(61304)
--     local isOnGCD = gcdInfo and gcdInfo.duration > 0
    
--     print(string.format("[SAdBars] DetectGCDSpell: spellID=%s, isOnGCD=%s", tostring(spellID), tostring(isOnGCD)))
--     return isOnGCD
-- end

-- -- Static list of OFF-GCD spells: [spellID] = "SpellName"
-- addon.offGCDSpells = {
--     [116849] = "Life Cocoon",
-- }

-- -- Buttons that should show GCD swipe
-- addon.gcdEnabledButtons = {
--     ["ActionButton3"] = true,
--     ["ActionButton4"] = true,
--     ["ActionButton6"] = true,
--     ["ActionButton7"] = true,
--     ["ActionButton8"] = true,
--     ["MultiBarBottomLeftButton1"] = true,
--     ["MultiBarBottomLeftButton5"] = true,
--     ["MultiBarBottomLeftButton6"] = true,
--     ["MultiBarBottomLeftButton7"] = true,
--     ["MultiBarBottomLeftButton9"] = true,
--     ["MultiBarBottomLeftButton10"] = true,
--     ["MultiBarBottomLeftButton11"] = true,
--     ["MultiBarBottomLeftButton12"] = true,
-- }

-- function addon:CreateCustomGCDFrames()
--     local startTime = debugprofilestop()
--     print("[SAdBars] CreateCustomGCDFrames: Starting")
--     local frameCount = 0
    
--     local function createGCDFrame(button, buttonName)
--         if button and not button.SAdBars_GCDCooldown then
--             frameCount = frameCount + 1
--             print(string.format("[SAdBars] Creating GCD frame for %s", buttonName))
--             local gcdCooldown = CreateFrame("Cooldown", buttonName .. "_SAdBars_GCD", button, "CooldownFrameTemplate")
--             gcdCooldown:SetAllPoints(button)
--             gcdCooldown:SetDrawSwipe(true)
--             gcdCooldown:SetDrawEdge(true)
--             gcdCooldown:SetDrawBling(false)
--             gcdCooldown:SetSwipeColor(0, 0, 0, 0.8)
--             gcdCooldown:SetHideCountdownNumbers(true)
--             gcdCooldown:SetFrameStrata("HIGH")
--             gcdCooldown:SetFrameLevel(button:GetFrameLevel() + 10)
--             gcdCooldown:Show()
--             button.SAdBars_GCDCooldown = gcdCooldown
--         end
--     local startTime = debugprofilestop()
--     if not spellID then
--         print("[SAdBars] TriggerGCDAnimation: No spellID provided")
--         return
--     end
    
--     if addon.offGCDSpells[spellID] then
--         print(string.format("[SAdBars] TriggerGCDAnimation: spellID=%s is OFF-GCD, skipping", tostring(spellID)))
--         return
--     end

--     local gcdInfo = C_Spell.GetSpellCooldown(61304)
    
--     if not gcdInfo or gcdInfo.duration == 0 then
--         print("[SAdBars] TriggerGCDAnimation: No GCD active")
--         return
--     end
    
--     local startGCDTime = gcdInfo.startTime
--     local gcdDuration = gcdInfo.duration
--     local triggeredCount = 0
    
--     print(string.format("[SAdBars] TriggerGCDAnimation: spellID=%s, duration=%.2fs", tostring(spellID), gcdDuration))
    
--     self:IterateActionButtons(function(button, buttonName)
--         if button and button.SAdBars_GCDCooldown and button.action and addon.gcdEnabledButtons[buttonName] then
--             local actionType, actionID = GetActionInfo(button.action)
            
--             if actionType == "spell" or actionType == "macro" then
--                 triggeredCount = triggeredCount + 1
--                 button.SAdBars_GCDCooldown:SetCooldown(startGCDTime, gcdDuration)
--             end
--         end
--     end)
    
--     local elapsed = debugprofilestop() - startTime
--     print(string.format("[SAdBars] TriggerGCDAnimation: Triggered %d buttons in %.2fms", triggeredCount, elapsed)f:IterateActionButtons(function(button, buttonName)
--         if button and button.SAdBars_GCDCooldown and button.action and addon.gcdEnabledButtons[buttonName] then
--             local actionType, actionID = GetActionInfo(button.action)
            
--             if actionType == "spell" or actionType == "macro" then
--                 button.SAdBars_GCDCooldown:SetCooldown(startTime, gcdDuration)
--             end
--         end
--     end)
-- end
