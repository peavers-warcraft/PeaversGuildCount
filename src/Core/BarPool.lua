local addonName, PGC = ...

--------------------------------------------------------------------------------
-- PGC BarPool - PeaversCommons.BarPool with a factory for PGC.StatBar
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons

PGC.BarPool = PeaversCommons.BarPool:New({
    maxPoolSize = 20,

    factory = function(parent, name)
        return PGC.StatBar:New(parent, name, name)
    end,

    resetter = function(bar)
        if bar.animationGroup then
            bar.animationGroup:Stop()
        end
        if bar.frame then
            bar.frame:Hide()
        end
    end,
})

-- Rebind the bar to whichever guild is being acquired. The base Acquire sets
-- the pool key before handing the bar back, so there is nothing useful to
-- compare against here - always Reset, it is cheap.
local baseAcquire = PGC.BarPool.Acquire
function PGC.BarPool:Acquire(parent, name, guildKey)
    local bar = baseAcquire(self, parent, name, guildKey)

    if bar and bar.Reset then
        bar:Reset(parent, name, guildKey)
    end

    -- Release hides bars, so Acquire has to show them again
    if bar and bar.frame then
        bar.frame:Show()
    end

    return bar
end

function PGC.BarPool:GetInUseCount()
    return self:GetActiveCount()
end

return PGC.BarPool
