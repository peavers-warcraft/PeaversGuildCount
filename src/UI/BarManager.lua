local addonName, PGC = ...

--------------------------------------------------------------------------------
-- BarManager - one bar per guild, laid out top to bottom
--------------------------------------------------------------------------------

PGC.BarManager = {}
local BarManager = PGC.BarManager

BarManager.previousValues = {}

-- Vertical step between bars, honouring a spacing of zero
local function BarStep()
    if PGC.Config.barSpacing == 0 then
        return PGC.Config.barHeight
    end
    return PGC.Config.barHeight + PGC.Config.barSpacing
end

-- A fingerprint of which guilds are shown and in what order. Comparing this
-- between scans is what decides whether the bars can simply be updated in place
-- or have to be laid out again.
local function OrderSignature()
    return table.concat(PGC.GuildData.guildOrder, "\2")
end

-- Rebuild every bar from the current guild list
function BarManager:RebuildBars()
    local parent = PGC.Core and PGC.Core.contentFrame
    if not parent then return 0 end

    PGC.BarPool:ReleaseAll()
    wipe(self.previousValues)
    self.lastSignature = OrderSignature()

    local yOffset = 0

    for _, guildKey in ipairs(PGC.GuildData.guildOrder) do
        local label = PGC.GuildData:GetLabel(guildKey)
        local bar = PGC.BarPool:Acquire(parent, label, guildKey)
        bar:SetPosition(0, yOffset)

        local count = PGC.GuildData:GetCount(guildKey)
        bar:Update(count, nil, nil, true)
        bar:UpdateColor()

        self.previousValues[guildKey] = count

        yOffset = yOffset - BarStep()
    end

    PGC.Core:AdjustFrameHeight()

    return math.abs(yOffset)
end

-- Reposition existing bars after a sort change, without recreating them
function BarManager:ReorderBars()
    local yOffset = 0

    for _, guildKey in ipairs(PGC.GuildData.guildOrder) do
        local bar = PGC.BarPool:GetBar(guildKey)
        if bar then
            local label = PGC.GuildData:GetLabel(guildKey)
            if bar.name ~= label then
                bar.name = label
                bar:UpdateNameText()
            end

            bar:SetPosition(0, yOffset)
            bar:Update(PGC.GuildData:GetCount(guildKey), nil, nil, true)

            yOffset = yOffset - BarStep()
        end
    end

    PGC.Core:AdjustFrameHeight()
end

-- Refresh values on the bars that already exist. A guild appearing or leaving
-- the group changes the bar set, which needs a rebuild instead.
function BarManager:UpdateAllBars(forceUpdate, noAnimation)
    local inCombat = InCombatLockdown()
    local highestChanged = false

    local currentHighest = PGC.GuildData:GetHighestCount()
    if currentHighest ~= self.previousHighestCount then
        highestChanged = true
        self.previousHighestCount = currentHighest
    end

    -- Suppress animation in combat, and when every bar is being rescaled
    local useNoAnimation = noAnimation or highestChanged or inCombat

    local missingBar = false

    for _, guildKey in ipairs(PGC.GuildData.guildOrder) do
        local bar = PGC.BarPool:GetBar(guildKey)

        if not bar then
            missingBar = true
        else
            local count = PGC.GuildData:GetCount(guildKey)
            local previous = self.previousValues[guildKey] or 0

            local label = PGC.GuildData:GetLabel(guildKey)
            if bar.name ~= label then
                bar.name = label
                bar:UpdateNameText()
            end

            local valueChanged = (count ~= previous)

            if forceUpdate or highestChanged or valueChanged then
                bar:Update(count, nil, nil, useNoAnimation)

                if forceUpdate then
                    bar:UpdateColor()
                end
            end

            if valueChanged then
                self.previousValues[guildKey] = count
            end
        end
    end

    -- A bar count mismatch means a guild joined or left the group, which the
    -- pool cannot express by updating values alone.
    if missingBar or PGC.BarPool:GetInUseCount() ~= #PGC.GuildData.guildOrder then
        self:RebuildBars()
    end
end

-- Repaint without moving anything. Highlighting your own guild changes only
-- which colour each bar is drawn in.
function BarManager:RecolorBars()
    for _, guildKey in ipairs(PGC.GuildData.guildOrder) do
        local bar = PGC.BarPool:GetBar(guildKey)
        if bar then
            bar:UpdateColor()
        end
    end
end

function BarManager:ResizeBars()
    for _, guildKey in ipairs(PGC.GuildData.guildOrder) do
        local bar = PGC.BarPool:GetBar(guildKey)
        if bar then
            bar:UpdateHeight()
            bar:UpdateWidth()
            bar:UpdateTexture()
            bar:UpdateFont()
            bar:UpdateBackgroundOpacity()
        end
    end

    self:RebuildBars()
end

function BarManager:AdjustFrameHeight(frame, contentFrame, titleBarVisible)
    local barCount = PGC.BarPool:GetInUseCount()
    local contentHeight = 0

    if barCount > 0 then
        if PGC.Config.barSpacing == 0 then
            contentHeight = barCount * PGC.Config.barHeight
        else
            contentHeight = barCount * (PGC.Config.barHeight + PGC.Config.barSpacing) - PGC.Config.barSpacing
        end
    end

    if contentHeight == 0 then
        frame:SetHeight(titleBarVisible and 20 or 10)
    else
        frame:SetHeight(titleBarVisible and (contentHeight + 20) or contentHeight)
    end
end

function BarManager:GetBar(guildKey)
    return PGC.BarPool:GetBar(guildKey)
end

function BarManager:GetBarCount()
    return PGC.BarPool:GetInUseCount()
end

function BarManager:CreateBars(parent)
    return self:RebuildBars()
end

-- Rescan the group and redraw. This is the entry point every event uses.
--
-- A guild joining, leaving, or changing places in the sort order all change the
-- layout, so those get a rebuild. A count changing without moving anything only
-- needs the values refreshed, which is the common case during a raid night.
function BarManager:Refresh(forceRebuild)
    PGC.GuildData:ScanGroup()

    if forceRebuild or OrderSignature() ~= self.lastSignature then
        self:RebuildBars()
    else
        self:UpdateAllBars()
    end

    if PGC.Core and PGC.Core.UpdateTitle then
        PGC.Core:UpdateTitle()
    end
end

return BarManager
