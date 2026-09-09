local addonName, PGC = ...

--------------------------------------------------------------------------------
-- GuildData
--
-- Buckets everyone in the current party or raid by their guild and keeps a
-- count per guild. Unlike item level, guild membership needs no inspect: the
-- server sends it with the unit, so a scan is a single cheap pass over the
-- roster.
--------------------------------------------------------------------------------

PGC.GuildData = {
    counts = {},        -- guildKey -> number of players
    members = {},       -- guildKey -> array of player names
    labels = {},        -- guildKey -> display name
    guildOrder = {},    -- Sorted array of guild keys
    highestCount = 0,
    myGuildKey = nil,   -- The player's own guild, for highlighting

    -- guid -> guildKey. GetGuildInfo can briefly return nothing for a player
    -- whose unit data has not arrived yet, which would otherwise drop them into
    -- the unguilded bucket for a second. Remembering what we last saw keeps the
    -- list steady.
    guidCache = {},
}

local GuildData = PGC.GuildData

-- Players with no guild are still worth showing: in a pug it is usually the
-- largest bar on the list.
local NO_GUILD_KEY = "\1NOGUILD"
local NO_GUILD_LABEL = "No Guild"

GuildData.NO_GUILD_KEY = NO_GUILD_KEY
GuildData.NO_GUILD_LABEL = NO_GUILD_LABEL

-- Bar colours. Guilds have no colour of their own, so one is picked from this
-- palette by hashing the guild name. The same guild therefore keeps the same
-- colour across sessions and between raids, which is what makes the list
-- readable at a glance.
local PALETTE = {
    { 0.36, 0.68, 0.89 },
    { 0.94, 0.55, 0.35 },
    { 0.47, 0.78, 0.51 },
    { 0.85, 0.47, 0.71 },
    { 0.71, 0.60, 0.90 },
    { 0.95, 0.79, 0.36 },
    { 0.40, 0.79, 0.75 },
    { 0.88, 0.45, 0.45 },
    { 0.60, 0.72, 0.42 },
    { 0.70, 0.62, 0.51 },
}

-- The player's own guild, when highlighting is on
local MY_GUILD_COLOR = { 0.23, 0.74, 0.97 }
local NO_GUILD_COLOR = { 0.55, 0.55, 0.55 }

--------------------------------------------------------------------------------
-- Identity
--------------------------------------------------------------------------------

-- Blizzard's secret-value system can hide unit identity. Only UnitGUID and
-- UnitIsUnit are affected here; guild name itself is not restricted.
function GuildData:CanReadIdentity(unit)
    if not unit then return false end
    if not C_Secrets or not C_Secrets.HasSecretRestrictions then return true end
    if not C_Secrets.HasSecretRestrictions() then return true end

    if C_Secrets.ShouldUnitIdentityBeSecret and C_Secrets.ShouldUnitIdentityBeSecret(unit) then
        return false
    end

    return true
end

--------------------------------------------------------------------------------
-- Guild lookup
--------------------------------------------------------------------------------

-- Guilds on different realms can share a name, so the realm is part of the key.
-- GetGuildInfo only returns a realm for cross-realm units, which is exactly
-- when the distinction matters.
local function BuildKey(guildName, realm)
    if realm and realm ~= "" then
        return guildName .. "-" .. realm
    end
    return guildName
end

-- Returns key, label for the unit's guild, or nil if the unit has none.
function GuildData:GetGuild(unit)
    if not unit then return nil end

    local guildName, _, _, realm = GetGuildInfo(unit)

    if guildName and guildName ~= "" then
        local key = BuildKey(guildName, realm)
        local label = guildName

        if realm and realm ~= "" then
            label = guildName .. " (" .. realm .. ")"
        end

        if self:CanReadIdentity(unit) then
            local guid = UnitGUID(unit)
            if guid then
                self.guidCache[guid] = { key = key, label = label }
            end
        end

        return key, label
    end

    -- Nothing came back. Fall back to whatever we last knew about this player,
    -- so a unit whose data has not loaded yet does not flicker into "No Guild".
    if self:CanReadIdentity(unit) then
        local guid = UnitGUID(unit)
        local cached = guid and self.guidCache[guid]
        if cached then
            return cached.key, cached.label
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Colours
--------------------------------------------------------------------------------

-- Deterministic string hash, so a guild's colour never changes between reloads
local function HashString(text)
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + text:byte(i)) % 4294967296
    end
    return hash
end

function GuildData:GetColor(guildKey)
    if guildKey == NO_GUILD_KEY then
        return unpack(NO_GUILD_COLOR)
    end

    if PGC.Config.highlightMyGuild and guildKey == self.myGuildKey then
        return unpack(MY_GUILD_COLOR)
    end

    local index = (HashString(guildKey) % #PALETTE) + 1
    return unpack(PALETTE[index])
end

--------------------------------------------------------------------------------
-- Display
--------------------------------------------------------------------------------

function GuildData:GetLabel(guildKey)
    return self.labels[guildKey] or guildKey
end

function GuildData:GetCount(guildKey)
    return self.counts[guildKey] or 0
end

function GuildData:GetMembers(guildKey)
    return self.members[guildKey] or {}
end

-- The largest guild fills the bar; everyone else is drawn relative to it.
function GuildData:GetHighestCount()
    return math.max(1, self.highestCount or 0)
end

function GuildData:CalculateBarValues(count)
    local percent = (count / self:GetHighestCount()) * 100
    return math.max(1, math.min(100, percent))
end

-- Total players counted, which is what the title bar reports
function GuildData:GetTotals()
    local players, guilds = 0, 0

    for _, key in ipairs(self.guildOrder) do
        players = players + (self.counts[key] or 0)
        guilds = guilds + 1
    end

    return players, guilds
end

--------------------------------------------------------------------------------
-- Scanning
--------------------------------------------------------------------------------

-- Collect the unit tokens for everyone currently grouped, the player included.
local function CollectUnits()
    local units = { "player" }

    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                units[#units + 1] = unit
            end
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                units[#units + 1] = unit
            end
        end
    end

    return units
end

function GuildData:ScanGroup()
    -- Test mode owns the roster; a real scan would wipe the preview
    if PGC.TestMode and PGC.TestMode:IsActive() then return end

    wipe(self.counts)
    wipe(self.members)
    wipe(self.labels)
    wipe(self.guildOrder)

    self.myGuildKey = nil

    local hideNoGuild = PGC.Config.hideNoGuild

    for _, unit in ipairs(CollectUnits()) do
        local key, label = self:GetGuild(unit)

        if not key then
            key, label = NO_GUILD_KEY, NO_GUILD_LABEL
        end

        if UnitIsUnit(unit, "player") and key ~= NO_GUILD_KEY then
            self.myGuildKey = key
        end

        if not (hideNoGuild and key == NO_GUILD_KEY) then
            if not self.counts[key] then
                self.counts[key] = 0
                self.members[key] = {}
                self.labels[key] = label
                self.guildOrder[#self.guildOrder + 1] = key
            end

            self.counts[key] = self.counts[key] + 1
            self.members[key][#self.members[key] + 1] = UnitName(unit) or "Unknown"
        end
    end

    self:SortGuildOrder()
    self:RecalculateHighest()
end

function GuildData:SortGuildOrder()
    local sortOption = PGC.Config.sortOption
    local counts = self.counts

    if sortOption == "COUNT_ASC" then
        table.sort(self.guildOrder, function(a, b)
            if counts[a] == counts[b] then
                return self:GetLabel(a) < self:GetLabel(b)
            end
            return counts[a] < counts[b]
        end)
    elseif sortOption == "NAME_ASC" then
        table.sort(self.guildOrder, function(a, b)
            return self:GetLabel(a) < self:GetLabel(b)
        end)
    elseif sortOption == "NAME_DESC" then
        table.sort(self.guildOrder, function(a, b)
            return self:GetLabel(a) > self:GetLabel(b)
        end)
    else
        -- Default: biggest guild first, ties broken alphabetically so the order
        -- does not shuffle between scans
        table.sort(self.guildOrder, function(a, b)
            if counts[a] == counts[b] then
                return self:GetLabel(a) < self:GetLabel(b)
            end
            return counts[a] > counts[b]
        end)
    end

    -- Member lists are shown in a tooltip, so they get sorted too
    for _, members in pairs(self.members) do
        table.sort(members)
    end
end

function GuildData:RecalculateHighest()
    local highest = 0

    for _, count in pairs(self.counts) do
        if count > highest then
            highest = count
        end
    end

    self.highestCount = highest
end

-- Keep the identity cache from growing without bound across a long session.
-- It only holds a guild key per player seen, so a few raids' worth is nothing.
function GuildData:CleanupCache()
    local count = 0
    for _ in pairs(self.guidCache) do
        count = count + 1
    end

    if count > 1000 then
        wipe(self.guidCache)
    end
end

return GuildData
