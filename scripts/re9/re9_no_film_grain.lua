-- RE9 Minimal No Film Grain
-- Only uses the confirmed RenderingManager API to avoid side effects

local mod = {
    name = "RE9 No Film Grain",
    version = "1.0.0",
}

local settings = {
    no_film_grain = true
}

local function ApplySettings()
    local ren = sdk.get_managed_singleton("app.RenderingManager")
    if ren and ren.call then
        -- This is the specific method we confirmed works without affecting lighting much
        ren:call("set__IsFilmGrainCustomFilterEnable", not settings.no_film_grain)
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
