local _, PGC = ...

local ConfigUI = {}
PGC.ConfigUI = ConfigUI

local PeaversCommons = _G.PeaversCommons
if not PeaversCommons then
    print("|cffff0000Error:|r PeaversCommons not found.")
    return
end

local W = PeaversCommons.Widgets
local ConfigUIUtils = PeaversCommons.ConfigUIUtils

-- Applying a setting lives with the addon's schema, in EditMode.lua, so the
-- settings page and the Edit Mode panel cannot disagree about what a change
-- should do.

function ConfigUI:BuildInfoPage(parentFrame)
    local C = W.Colors
    ConfigUIUtils.BuildInfoPageWithEditMode(parentFrame, "Guild Count", {
        "Counts how many players from each guild are in your party or raid, as a " ..
            "sorted list of bars. One bar per guild, its value the number of players.",
        { command = "/pgc", desc = "toggle the display" },
        { command = "/pgc config", desc = "open the configuration panel" },
        { command = "/pgc test", desc = "preview the display with an example raid" },

        { header = "Reading the list" },
        "The longest bar is the guild with the most players present; every other " ..
            "bar is drawn relative to it. Hovering a bar lists the players it is " ..
            "counting.",
        "Each guild keeps the same colour every time you see it, so a group you " ..
            "raid with regularly stays recognisable.",

        { header = "Players in no guild" },
        "Unguilded players are counted together on their own bar. In a pug that is " ..
            "often the longest one. It can be switched off if you only care about " ..
            "actual guilds.",
        { text = "Guild membership arrives with the group roster, so the list is complete " ..
            "as soon as the group is - no scanning, no waiting.", color = C.accentLight },
    }, {
        title = "the guild count list",
        select = "the list",
        reset = function()
            PGC.Config:Reset()
            if PGC.ApplySetting then PGC.ApplySetting() end
            if PeaversCommons.EditModePanel then
                PeaversCommons.EditModePanel:Refresh()
            end
        end,
    })
end

function ConfigUI:GetPages()
    return {
        { key = "info", label = "Information", builder = function(f) ConfigUI:BuildInfoPage(f) end },
    }
end

function ConfigUI:BuildIntoFrame(parentFrame)
    self:BuildInfoPage(parentFrame)
    return parentFrame
end

function ConfigUI:InitializeOptions()
    local panel = ConfigUIUtils.CreateSettingsPanel(
        "Settings",
        "Configuration options for the guild count display"
    )
    local content = panel.content
    self:BuildIntoFrame(content)
    panel:UpdateContentHeight(content:GetHeight())
    return panel
end

function ConfigUI:OpenOptions()
    PGC.Config:Save()

    if _G.PeaversConfig and _G.PeaversConfig.MainFrame then
        _G.PeaversConfig.MainFrame:Show()
        _G.PeaversConfig.MainFrame:SelectAddon("PeaversGuildCount")
        return
    end

    if Settings and Settings.OpenToCategory then
        if PGC.directSettingsCategoryID then
            local success = pcall(Settings.OpenToCategory, PGC.directSettingsCategoryID)
            if success then return end
        end
        if PGC.directCategoryID then
            local success = pcall(Settings.OpenToCategory, PGC.directCategoryID)
            if success then return end
        end
    end

    if SettingsPanel then
        ShowUIPanel(SettingsPanel)
    end
end

PGC.Config.OpenOptionsCommand = function()
    ConfigUI:OpenOptions()
end

function ConfigUI:Initialize()
    self.panel = self:InitializeOptions()
end

return ConfigUI
