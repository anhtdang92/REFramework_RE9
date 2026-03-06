-- RE9 Minimal No Film Grain (Optimized)
-- Created: 2026-03-02
-- Only uses the confirmed RenderingManager API

local mod = {
    name = "RE9 No Film Grain",
    version = "1.0.1",
}

local settings = {
    no_film_grain = true
}

-- Cache the singleton for performance (prevents lookup every frame)
local rendering_manager = nil

local function ApplySettings()
    -- Only look up once or if lost
    if not rendering_manager then
        rendering_manager = sdk.get_managed_singleton("app.RenderingManager")
    end

    if rendering_manager and rendering_manager.call then
        rendering_manager:call("set__IsFilmGrainCustomFilterEnable", not settings.no_film_grain)
    end
end

re.on_frame(function()
    ApplySettings()
end)

re.on_draw_ui(function()
    if imgui.tree_node(mod.name) then
        local changed, val = imgui.checkbox("Disable Film Grain", settings.no_film_grain)
        if changed then
            settings.no_film_grain = val
        end
        imgui.tree_pop()
    end
end)
