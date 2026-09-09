local addonName, PGC = ...

--[[
    PGC TestMode - fills the display with a fake raid so appearance settings can
    be previewed while solo.

    The fake data is written straight into GuildData's count tables rather than
    into the GUID cache, so it can never be mistaken for a real player and never
    survives a disable. ScanGroup bails out while test mode is active, which
    stops a roster event from wiping the preview.

    Test mode is intentionally NOT persisted: a /reload always returns to the
    real group, so nobody can get stuck looking at fake bars.
]]

PGC.TestMode = {
    active = false,
}

local TestMode = PGC.TestMode

-- A plausible pug shape: one guild running it, a couple of smaller groups
-- along for the ride, and a tail of unguilded players.
local GUILDS = {
    { name = "Midnight Sanctum", count = 11 },
    { name = "Ashen Covenant", count = 5 },
    { name = "Wyrmrest Irregulars", count = 3 },
    { name = "Last Pull", count = 2 },
}

local NAME_POOL = {
    "Bulwark", "Stonehide", "Lightwell", "Riverbloom", "Sunmender", "Emberfang",
    "Nightreave", "Grimhowl", "Thundergale", "Voidstep", "Frostbourne", "Dawnscale",
    "Ashvale", "Brightspear", "Cinderwake", "Duskmantle", "Everfrost", "Gloomtide",
    "Hallowmere", "Ironvow", "Kestrelwing", "Moonquill", "Palegrove", "Ravenshold",
    "Silverbrand", "Stormcaller", "Thornwild", "Umbershade", "Wyrmrest", "Zephyrbane",
}

local UNGUILDED_COUNT = 4

function TestMode:IsActive()
    return self.active == true
end

function TestMode:Toggle()
    if self.active then
        self:Disable()
    else
        self:Enable()
    end
    return self.active
end

function TestMode:Enable()
    if self.active then return end

    local GuildData = PGC.GuildData
    self.active = true

    wipe(GuildData.counts)
    wipe(GuildData.members)
    wipe(GuildData.labels)
    wipe(GuildData.guildOrder)

    -- Names are dealt from one shared pool so no player appears twice
    local pool = {}
    for _, name in ipairs(NAME_POOL) do pool[#pool + 1] = name end

    local function TakeName()
        if #pool == 0 then return "Someone" end
        return table.remove(pool, math.random(#pool))
    end

    local function AddGuild(key, label, count)
        GuildData.counts[key] = count
        GuildData.labels[key] = label
        GuildData.members[key] = {}
        GuildData.guildOrder[#GuildData.guildOrder + 1] = key

        for _ = 1, count do
            table.insert(GuildData.members[key], TakeName())
        end
    end

    for _, guild in ipairs(GUILDS) do
        AddGuild(guild.name, guild.name, guild.count)
    end

    if not PGC.Config.hideNoGuild then
        AddGuild(GuildData.NO_GUILD_KEY, GuildData.NO_GUILD_LABEL, UNGUILDED_COUNT)
    end

    -- Highlight the first guild as though it were the player's own, so the
    -- "highlight my guild" setting has something to demonstrate
    GuildData.myGuildKey = GUILDS[1].name

    GuildData:SortGuildOrder()
    GuildData:RecalculateHighest()

    if PGC.BarManager then
        PGC.BarManager:RebuildBars()
    end

    if PGC.Core then
        PGC.Core:UpdateTitle()
        PGC.Core:UpdateFrameVisibility()
    end

    self:Print("Test mode |cff44ff44ON|r - showing an example raid. Run again to " ..
        "return to your real group.")
end

function TestMode:Disable()
    if not self.active then return end

    self.active = false

    PGC.GuildData:ScanGroup()

    if PGC.BarManager then
        PGC.BarManager:RebuildBars()
    end

    if PGC.Core then
        PGC.Core:UpdateTitle()
        PGC.Core:UpdateFrameVisibility()
    end

    self:Print("Test mode |cffff4444OFF|r.")
end

function TestMode:Print(msg)
    if PGC.Utils and PGC.Utils.Print then
        PGC.Utils.Print(msg)
    else
        print("|cff3abdf7PeaversGuildCount|r: " .. msg)
    end
end

return TestMode
