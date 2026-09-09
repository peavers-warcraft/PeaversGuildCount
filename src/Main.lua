local addonName, PGC = ...

-- Check for PeaversCommons
local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r " .. addonName .. " requires PeaversCommons to work properly.")
    return
end

local AddonInit = PeaversCommons.AddonInit

local success = AddonInit:Setup(PGC, addonName, {
    modules = {"Core", "UI", "Utils", "Config"},
    slashCommand = "pgc",
    extraSlashCommands = {
        -- Preview the display with an example raid, without leaving the settings
        test = function()
            if PGC.TestMode then PGC.TestMode:Toggle() end
        end,
    }
})

if not success then return end

-- Expose addon namespace globally for PeaversUISetup integration
_G.PeaversGuildCount = PGC

PeaversCommons.Events:Init(addonName, function()
    PGC.Config:Initialize()

    if PGC.Config.useGlobalAppearance and PeaversCommons.GlobalAppearance then
        PeaversCommons.GlobalAppearance:RegisterAddon("PeaversGuildCount", PGC.Config, function()
            if PGC.BarManager and PGC.Core and PGC.Core.contentFrame then
                PGC.BarManager:CreateBars(PGC.Core.contentFrame)
                PGC.Core:AdjustFrameHeight()
            end
            if PGC.Core and PGC.Core.frame then
                PGC.Core.frame:SetBackdropColor(
                    PGC.Config.bgColor.r,
                    PGC.Config.bgColor.g,
                    PGC.Config.bgColor.b,
                    PGC.Config.bgAlpha
                )
            end
        end)
    end

    if PGC.ConfigUI and PGC.ConfigUI.Initialize then
        PGC.ConfigUI:Initialize()
    end

    if PGC.Patrons and PGC.Patrons.Initialize then
        PGC.Patrons:Initialize()
    end

    PGC.Core:Initialize()

    -- After Core, because it registers the frame Core builds
    if PGC.EditMode then
        PGC.EditMode:Register()
    end

    AddonInit:RegisterCommonEvents(PGC)

    -- Combat state, logout saves and roster visibility are already handled by
    -- RegisterCommonEvents above; what follows is only the guild data.

    -- The roster changing is the only thing that can change a guild count
    PeaversCommons.Events:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        PGC.BarManager:Refresh()
        PGC.GuildData:CleanupCache()
    end)

    -- Your own guild changes when you join, leave, or are kicked from one
    PeaversCommons.Events:RegisterEvent("PLAYER_GUILD_UPDATE", function()
        PGC.BarManager:Refresh(true)
    end)

    PeaversCommons.Events:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        PGC.BarManager:Refresh(true)
        PGC.Core:UpdateFrameVisibility()
    end)

    -- A slow sweep, not a data source. GROUP_ROSTER_UPDATE does the real work;
    -- this only catches a raider whose unit data had not arrived when their
    -- roster event fired, which would otherwise leave them counted as unguilded.
    PeaversCommons.Events:RegisterOnUpdate(3.0, function()
        if IsInGroup() then
            PGC.BarManager:Refresh()
        end
    end, "PGC_Update")

    C_Timer.After(0.5, function()
        PeaversCommons.SettingsUI:CreateRedirectPage(PGC, "PeaversGuildCount", "Peavers Guild Count")
    end)

    if PeaversCommons.ConfigRegistry then
        PeaversCommons.ConfigRegistry:Register({
            name = "PeaversGuildCount",
            displayName = "Guild Count",
            description = "Guild breakdown of your party or raid",
            addonRef = PGC,
            config = PGC.Config,
            pages = PGC.ConfigUI:GetPages(),
            order = 3,
        })
    end
end, {
    suppressAnnouncement = true
})
