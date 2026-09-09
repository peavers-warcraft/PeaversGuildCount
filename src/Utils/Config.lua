--------------------------------------------------------------------------------
-- PeaversGuildCount Configuration
-- Uses PeaversCommons.ConfigManager with AceDB-3.0 for profile management
--------------------------------------------------------------------------------

local addonName, PGC = ...

local PeaversCommons = _G.PeaversCommons
local ConfigManager = PeaversCommons.ConfigManager

-- PGC-specific defaults (these extend the common defaults from ConfigManager)
local PGC_DEFAULTS = {
    -- Frame position
    framePoint = "RIGHT",
    frameX = -20,
    frameY = 0,
    frameWidth = 250,
    frameHeight = 200,

    -- Bar settings
    barWidth = 230,
    barBgAlpha = 0.7,
    fontSize = 8,

    -- PGC-specific features
    hideOutOfCombat = false,
    displayMode = "PARTY_AND_RAID",
    sortOption = "COUNT_DESC",
    hideNoGuild = false,
    highlightMyGuild = true,
    showMemberTooltip = true,
}

-- Create the AceDB-backed config
PGC.Config = ConfigManager:NewWithAceDB(
    PGC,
    PGC_DEFAULTS,
    {
        savedVariablesName = "PeaversGuildCountDB",
        profileType = "shared",
        onProfileChanged = function()
            if not PGC.Core or not PGC.Core.frame then return end

            PGC.Core.frame:SetWidth(PGC.Config.frameWidth)
            PGC.Core:ApplyFramePosition()

            if PGC.BarManager and PGC.Core.contentFrame then
                PGC.BarManager:CreateBars(PGC.Core.contentFrame)
                PGC.BarManager:ResizeBars()
                PGC.Core:AdjustFrameHeight()
            end

            PGC.Core:UpdateTitleBarVisibility()
            PGC.Core:UpdateFrameLock()
            PGC.Core:UpdateFrameVisibility()
        end,
    }
)

return PGC.Config
