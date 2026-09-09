local addonName, PGC = ...

--------------------------------------------------------------------------------
-- PGC TitleBar - Uses PeaversCommons.TitleBar
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons

PGC.TitleBar = {}
local TitleBar = PGC.TitleBar

function TitleBar:Create(parentFrame)
    return PeaversCommons.TitleBar:Create(parentFrame, PGC.Config, {
        title = "PGC",
        version = PGC.version or "1.0.0",
        leftPadding = 6
    })
end

return TitleBar
