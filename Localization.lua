local addonName = ...
local SAdCore = LibStub("SAdCore-1")
local addon = SAdCore:GetAddon(addonName)

-- Localization
-- The locale table is automatically initialized by SAdCore

-- English
addon.locale.enEN = {
    -- Fade Bars Panel
    fadeBarsTitle = "Fade Bars",
    fadeBarsHeader = "Enable Fade on Mouseover",
    fadeBarMainMenuBar = "Bar 1",
    fadeBarMainMenuBarTooltip = "Fade Bar 1 when not moused over",
    fadeBarMultiBarBottomLeft = "Bar 2",
    fadeBarMultiBarBottomLeftTooltip = "Fade Bar 2 when not moused over",
    fadeBarMultiBarBottomRight = "Bar 3",
    fadeBarMultiBarBottomRightTooltip = "Fade Bar 3 when not moused over",
    fadeBarMultiBarRight = "Bar 4",
    fadeBarMultiBarRightTooltip = "Fade Bar 4 when not moused over",
    fadeBarMultiBarLeft = "Bar 5",
    fadeBarMultiBarLeftTooltip = "Fade Bar 5 when not moused over",
    fadeBarMultiBar5 = "Bar 6",
    fadeBarMultiBar5Tooltip = "Fade Bar 6 when not moused over",
    fadeBarMultiBar6 = "Bar 7",
    fadeBarMultiBar6Tooltip = "Fade Bar 7 when not moused over",
    fadeBarMultiBar7 = "Bar 8",
    fadeBarMultiBar7Tooltip = "Fade Bar 8 when not moused over",
    fadeBarPetActionBar = "Pet Bar",
    fadeBarPetActionBarTooltip = "Fade Pet Bar when not moused over",
    fadeBarStanceBar = "Stance Bar",
    fadeBarStanceBarTooltip = "Fade Stance Bar when not moused over",
}

-- Spanish
addon.locale.esES = {
}

addon.locale.esMX = addon.locale.esES

-- Portuguese
addon.locale.ptBR = {
}

-- French
addon.locale.frFR = {
}

-- German
addon.locale.deDE = {
}

-- Russian
addon.locale.ruRU = {
}
