local addonName, PGC = ...

--------------------------------------------------------------------------------
-- Edit Mode
--
-- The list is placed and configured in Blizzard's Edit Mode. All of the
-- machinery lives in PeaversCommons; what is here is the list of settings and
-- how to apply one after it changes.
--------------------------------------------------------------------------------

local PeaversCommons = _G.PeaversCommons

local EditMode = {}
PGC.EditMode = EditMode

--------------------------------------------------------------------------------
-- Applying a change
--------------------------------------------------------------------------------

function PGC.ApplySetting(key, value)
    local Config = PGC.Config

    if key == "frameX" or key == "frameY" then
        if PGC.Core and PGC.Core.ApplyFramePosition then
            PGC.Core:ApplyFramePosition()
        end
        return
    end

    if key == "frameWidth" then
        -- The bars sit inside the frame, so their width follows it.
        Config.barWidth = value - 20
        if PGC.Core and PGC.Core.frame then
            PGC.Core.frame:SetWidth(value)
            if PGC.BarManager then PGC.BarManager:ResizeBars() end
        end
    elseif key == "bgAlpha" or key == "bgColor" then
        if PGC.Core and PGC.Core.frame then
            local color = Config.bgColor or { r = 0, g = 0, b = 0 }
            local alpha = Config.bgAlpha or 0.8
            PGC.Core.frame:SetBackdropColor(color.r, color.g, color.b, alpha)
            PGC.Core.frame:SetBackdropBorderColor(0, 0, 0, alpha)
            if PGC.Core.titleBar then
                PGC.Core.titleBar:SetBackdropColor(color.r, color.g, color.b, alpha)
                PGC.Core.titleBar:SetBackdropBorderColor(0, 0, 0, alpha)
            end
        end
    elseif key == "lockPosition" then
        if PGC.Core then PGC.Core:UpdateFrameLock() end
    elseif key == "showTitleBar" then
        if PGC.Core then PGC.Core:UpdateTitleBarVisibility() end
    elseif key == "barAlpha" or key == "barBgAlpha" or key == "barTexture" or key == "textAlpha" then
        if PGC.BarManager then PGC.BarManager:ResizeBars() end
    elseif key == "displayMode" or key == "hideOutOfCombat" or key == "showOnLogin" then
        if PGC.Core and PGC.Core.UpdateFrameVisibility then
            PGC.Core:UpdateFrameVisibility()
        end
    elseif key == "sortOption" or key == "hideNoGuild" then
        -- These change which guilds are listed, or in what order
        if PGC.BarManager then PGC.BarManager:Refresh(true) end
    elseif key == "highlightMyGuild" then
        -- Only the colours change, so the bars stay where they are
        if PGC.BarManager then PGC.BarManager:RecolorBars() end
    elseif key == "showMemberTooltip" then
        -- Read when a bar is hovered, so there is nothing to redraw
        return
    else
        -- Everything else changes what a bar shows or how it is drawn
        if PGC.BarManager and PGC.Core and PGC.Core.contentFrame then
            PGC.BarManager:CreateBars(PGC.Core.contentFrame)
            PGC.Core:AdjustFrameHeight()
        end
    end
end

--------------------------------------------------------------------------------
-- Groups
--------------------------------------------------------------------------------

EditMode.SECTIONS = {
    { key = "frame", label = "Frame" },
    { key = "position", label = "Position" },
    { key = "bars", label = "Bars" },
    { key = "text", label = "Text" },
    { key = "list", label = "The List" },
    { key = "behaviour", label = "Behaviour" },
}

EditMode.ENTRIES = {
    ----------------------------------------------------------------- frame ---
    { key = "frameWidth", section = "frame" },
    { key = "showTitleBar", section = "frame" },
    { key = "bgColor", section = "frame" },
    { key = "bgAlpha", section = "frame" },
    { key = "lockPosition", section = "frame" },

    -------------------------------------------------------------- position ---
    { key = "frameX", section = "position", kind = "number" },
    { key = "frameY", section = "position", kind = "number" },

    ------------------------------------------------------------------ bars ---
    { key = "barHeight", section = "bars" },
    { key = "barSpacing", section = "bars" },
    { key = "barAlpha", section = "bars" },
    { key = "barBgAlpha", section = "bars" },
    { key = "barTexture", section = "bars", height = 300 },

    ------------------------------------------------------------------ text ---
    { key = "fontFace", section = "text", height = 300 },
    { key = "fontSize", section = "text" },
    { key = "fontOutline", section = "text" },
    { key = "fontShadow", section = "text" },
    { key = "textAlpha", section = "text" },

    ------------------------------------------------------------------ list ---
    {
        key = "sortOption", label = "Sort By", kind = "dropdown", section = "list",
        fallback = "COUNT_DESC",
        values = {
            { value = "COUNT_DESC", label = "Players, most first" },
            { value = "COUNT_ASC", label = "Players, fewest first" },
            { value = "NAME_ASC", label = "Guild name, A to Z" },
            { value = "NAME_DESC", label = "Guild name, Z to A" },
        },
    },
    {
        key = "hideNoGuild", label = "Hide Unguilded", kind = "checkbox",
        section = "list", default = false,
        desc = "Leave out the bar counting players who are in no guild.",
    },
    {
        key = "highlightMyGuild", label = "Highlight My Guild", kind = "checkbox",
        section = "list", default = true,
        desc = "Draw your own guild in the addon's accent colour instead of its "
            .. "usual one.",
    },
    {
        key = "showMemberTooltip", label = "Name Tooltip", kind = "checkbox",
        section = "list", default = true,
        desc = "Hovering a bar lists the players it is counting.",
    },

    ------------------------------------------------------------- behaviour ---
    { key = "showOnLogin", section = "behaviour" },
    { key = "hideOutOfCombat", section = "behaviour" },
    { key = "displayMode", section = "behaviour" },
}

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

-- Edit Mode reports an anchor point and an offset, which is what this addon
-- already stores. Nothing to convert, nothing to migrate.
local function SavePosition(_, point, x, y)
    PGC.Config.framePoint = point
    PGC.Config.frameX = x
    PGC.Config.frameY = y
    PGC.Config:Save()
end

-- The frame drags itself when unlocked, and Edit Mode drags it through its own
-- overlay. Both at once means two systems answering one drag.
local function ReleaseDragging(frame)
    for _, target in ipairs({ frame, PGC.Core.contentFrame }) do
        if target and target.RegisterForDrag then
            target:RegisterForDrag()
            target:SetScript("OnDragStart", nil)
            target:SetScript("OnDragStop", nil)
        end
    end
end

function EditMode:BuildSchema()
    if self.schema then return self.schema end

    self.schema = PeaversCommons.SettingsSchema:New({
        config = PGC.Config,
        sections = self.SECTIONS,
        entries = self.ENTRIES,
        apply = function(entry, _, value) PGC.ApplySetting(entry.key, value) end,
    })

    return self.schema
end

function EditMode:Register()
    if not PeaversCommons.EditMode or not PeaversCommons.EditMode.available then
        return false
    end
    if not PGC.Core or not PGC.Core.frame then return false end

    PeaversCommons.EditMode:Register({
        frame = PGC.Core.frame,
        name = "Peavers Guild Count",
        schema = self:BuildSchema(),
        default = {
            point = PGC.Config.defaults and PGC.Config.defaults.framePoint or "RIGHT",
            x = PGC.Config.defaults and PGC.Config.defaults.frameX or -20,
            y = PGC.Config.defaults and PGC.Config.defaults.frameY or 0,
        },
        onPositionChanged = SavePosition,
        onEnter = function(frame)
            ReleaseDragging(frame)
            -- The list can be hidden by the visibility rules, and a hidden frame
            -- takes its own Edit Mode handle down with it.
            frame:Show()
        end,
        onExit = function()
            if PGC.Core.UpdateFrameLock then PGC.Core:UpdateFrameLock() end
            if PGC.Core.UpdateFrameVisibility then PGC.Core:UpdateFrameVisibility() end
        end,
    })

    return true
end

return EditMode
