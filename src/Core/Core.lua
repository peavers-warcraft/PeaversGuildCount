local addonName, PGC = ...
local Core = {}
PGC.Core = Core

Core.inCombat = false

-- Builds the addon's frame and its bars
function Core:Initialize()
    PGC.GuildData:ScanGroup()

    self.frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.frame:SetSize(PGC.Config.frameWidth, PGC.Config.frameHeight)
    self.frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 1,
    })
    self.frame:SetBackdropColor(PGC.Config.bgColor.r, PGC.Config.bgColor.g, PGC.Config.bgColor.b, PGC.Config.bgAlpha)
    self.frame:SetBackdropBorderColor(0, 0, 0, PGC.Config.bgAlpha)

    self.titleBar = PGC.TitleBar:Create(self.frame)

    self.contentFrame = CreateFrame("Frame", nil, self.frame)
    self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -20)
    self.contentFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 0)

    self:UpdateTitleBarVisibility()

    PGC.BarManager:CreateBars(self.contentFrame)
    self:AdjustFrameHeight()
    self:UpdateTitle()

    -- Position last, so the frame is already its final height
    self.frame:SetPoint(PGC.Config.framePoint, PGC.Config.frameX, PGC.Config.frameY)

    self:UpdateFrameLock()
    self:UpdateFrameVisibility()
end

-- The title bar carries the headline number: how many players across how many
-- guilds, which is the question the addon exists to answer.
function Core:UpdateTitle()
    if not self.titleBar or not self.titleBar.UpdateSubtitle then return end

    local players, guilds = PGC.GuildData:GetTotals()

    if guilds == 0 then
        self.titleBar:UpdateSubtitle("")
        return
    end

    self.titleBar:UpdateSubtitle(string.format(
        "%d in %d %s", players, guilds, guilds == 1 and "guild" or "guilds"
    ))
end

function Core:AdjustFrameHeight()
    PGC.BarManager:AdjustFrameHeight(self.frame, self.contentFrame, PGC.Config.showTitleBar)
end

function Core:UpdateFrameLock()
    local PeaversCommons = _G.PeaversCommons
    PeaversCommons.FrameLock:ApplyFromConfig(
        self.frame,
        self.contentFrame,
        PGC.Config,
        function() PGC.Config:Save() end
    )
end

function Core:UpdateTitleBarVisibility()
    if not self.titleBar then return end

    if PGC.Config.showTitleBar then
        self.titleBar:Show()
        self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -20)
    else
        self.titleBar:Hide()
        self.contentFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    end

    self:AdjustFrameHeight()
end

function Core:ApplyFramePosition()
    if self.frame and PGC.Config then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(
            PGC.Config.framePoint or "CENTER",
            PGC.Config.frameX or 0,
            PGC.Config.frameY or 0
        )
    end
end

function Core:UpdateFrameVisibility()
    local PeaversCommons = _G.PeaversCommons

    -- Test mode previews the display while solo, so it has to override display
    -- modes like "party and raid" that would otherwise hide it
    if PGC.TestMode and PGC.TestMode:IsActive() then
        if self.frame then self.frame:Show() end
        return true
    end

    return PeaversCommons.VisibilityManager:UpdateVisibility(self.frame, PGC.Config, self.inCombat)
end

return Core
