local addonName, PGC = ...

--------------------------------------------------------------------------------
-- PGC StatBar - Extends PeaversCommons.StatBar with per-guild colours
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons
local BaseStatBar = PeaversCommons.StatBar

PGC.StatBar = {}
local StatBar = PGC.StatBar

setmetatable(StatBar, { __index = BaseStatBar })

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

function StatBar:New(parent, name, guildKey)
    local obj = BaseStatBar.New(self, parent, name, guildKey, PGC.Config)

    setmetatable(obj, { __index = StatBar })

    obj:InitTooltip()
    obj:UpdateNameText()

    return obj
end

-- Rebinds a pooled bar to a different guild. Without this a reused bar keeps
-- the previous guild's label, colour key and value-comparison state.
function StatBar:Reset(parent, name, guildKey)
    self.name = name
    self.statType = guildKey
    self.value = 0
    self.initialized = false

    if self.textManager then
        if self.textManager.SetName then
            self.textManager:SetName(name)
        end
        self:UpdateNameText()
    end

    if self.animationGroup then
        self.animationGroup:Stop()
    end
end

--------------------------------------------------------------------------------
-- Colour
--------------------------------------------------------------------------------

function StatBar:UpdateColor()
    local r, g, b = 0.8, 0.8, 0.8

    if self.statType and PGC.GuildData then
        r, g, b = PGC.GuildData:GetColor(self.statType)
    end

    self.statusBar:SetColor(r or 0.8, g or 0.8, b or 0.8, PGC.Config.barAlpha or 1.0)
end

--------------------------------------------------------------------------------
-- Values
--------------------------------------------------------------------------------

-- Bar length is the guild's share of the largest guild present
function StatBar:CalculateBarValues(value, maxValue)
    if PGC.GuildData then
        return PGC.GuildData:CalculateBarValues(value or 0)
    end
    return BaseStatBar.CalculateBarValues(self, value, maxValue)
end

function StatBar:GetDisplayValue(value)
    return tostring(math.floor((value or 0) + 0.5))
end

function StatBar:Update(value, maxValue, change, noAnimation)
    if self.initialized and self.value == value then return end

    self.initialized = true
    self.value = value or 0

    local percentValue = self:CalculateBarValues(self.value, maxValue)

    self.statusBar:SetMinMaxValues(0, 100)
    self.statusBar:SetValue(percentValue, noAnimation)

    self.textManager:SetValue(self:GetDisplayValue(self.value))
end

--------------------------------------------------------------------------------
-- Mouse - tooltip, and passing a drag through to the window
--------------------------------------------------------------------------------

-- The bars cover the whole content area, so a bar that takes the mouse for its
-- tooltip also takes the drag that moves the window. Each bar therefore hands
-- the drag back to the frame it sits in, on the same terms FrameLock uses:
-- nothing moves while the position is locked, and Edit Mode drags it itself.
local function CanDragWindow()
    if PGC.Config.lockPosition then return false end

    local EditMode = PeaversCommons.EditMode
    if EditMode and EditMode.IsEditing and EditMode:IsEditing() then return false end

    return PGC.Core and PGC.Core.frame ~= nil
end

local function SaveWindowPosition()
    local frame = PGC.Core and PGC.Core.frame
    if not frame then return end

    local point, _, _, x, y = frame:GetPoint()
    PGC.Config.framePoint = point
    PGC.Config.frameX = x
    PGC.Config.frameY = y
    PGC.Config:Save()
end

function StatBar:InitTooltip()
    if self.tooltipInitialized then return end
    self.tooltipInitialized = true

    self.frame:EnableMouse(true)
    self.frame:SetScript("OnEnter", function() self:ShowTooltip() end)
    self.frame:SetScript("OnLeave", function() self:HideTooltip() end)

    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function()
        if CanDragWindow() then
            self.draggingWindow = true
            PGC.Core.frame:StartMoving()
        end
    end)
    self.frame:SetScript("OnDragStop", function()
        -- Only finish a drag this bar actually started, so a drag refused above
        -- cannot overwrite a position Edit Mode is in the middle of setting.
        if not self.draggingWindow then return end

        self.draggingWindow = false
        PGC.Core.frame:StopMovingOrSizing()
        SaveWindowPosition()
    end)
end

function StatBar:ShowTooltip()
    if not PGC.Config.showMemberTooltip then return end
    if not self.statType or not PGC.GuildData then return end

    local members = PGC.GuildData:GetMembers(self.statType)
    if #members == 0 then return end

    GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
    GameTooltip:AddLine(PGC.GuildData:GetLabel(self.statType), 1, 1, 1)
    GameTooltip:AddLine(#members .. (#members == 1 and " player" or " players"), 0.7, 0.7, 0.7)
    GameTooltip:AddLine(" ")

    for _, name in ipairs(members) do
        GameTooltip:AddLine(name, 0.9, 0.9, 0.9)
    end

    GameTooltip:Show()
end

function StatBar:HideTooltip()
    GameTooltip:Hide()
end

--------------------------------------------------------------------------------
-- Position
--------------------------------------------------------------------------------

function StatBar:SetPosition(x, y, anchorPoint)
    self.yOffset = y
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", self.frame:GetParent(), "TOPLEFT", x, y)
    self.frame:SetPoint("TOPRIGHT", self.frame:GetParent(), "TOPRIGHT", 0, y)
end

--------------------------------------------------------------------------------
-- Appearance
--------------------------------------------------------------------------------

-- textManager keeps its own copy of the name, so assigning bar.name alone has
-- no visible effect until it is pushed through SetName.
function StatBar:UpdateNameText()
    if self.textManager then
        if self.textManager.SetName and self.name then
            self.textManager:SetName(self.name)
        end
        if self.textManager.UpdateNameTruncation then
            self.textManager:UpdateNameTruncation()
        end
    end
end

function StatBar:UpdateFont()
    self.textManager:UpdateFont(
        PGC.Config.fontFace,
        PGC.Config.fontSize,
        PGC.Config.fontOutline,
        PGC.Config.fontShadow
    )
    self.textManager:SetTextAlpha(PGC.Config.barAlpha or 1.0)
    self:UpdateNameText()
end

function StatBar:UpdateTexture()
    self.statusBar:SetTexture(PGC.Config.barTexture)
    self:UpdateColor()
end

function StatBar:UpdateHeight()
    self.frame:SetHeight(PGC.Config.barHeight)
    self.statusBar:SetHeight(PGC.Config.barHeight)
    self:UpdateNameText()
end

function StatBar:UpdateWidth()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", self.frame:GetParent(), "TOPLEFT", 0, self.yOffset)
    self.frame:SetPoint("TOPRIGHT", self.frame:GetParent(), "TOPRIGHT", 0, self.yOffset)
    self:UpdateNameText()
end

return StatBar
