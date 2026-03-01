-- > RE9 Requiem - Disable Film Grain
-- > Place in: reframework/autorun/disable_film_grain.lua
-- > Makle sure you fucking have REFramework pls?

local log_tag = "[FilmGrainDisabler]"

local function disable_film_grain()
    local mgr = sdk.get_managed_singleton("app.RenderingManager")
    if mgr and mgr:call("get__IsFilmGrainCustomFilterEnable") then
        mgr:call("set__IsFilmGrainCustomFilterEnable", false)
    end
end

re.on_frame(function()
    disable_film_grain()
end)

re.on_draw_ui(function()
    if imgui.tree_node("Film Grain Disabler") then
        local mgr = sdk.get_managed_singleton("app.RenderingManager")
        if mgr then
            local val = mgr:call("get__IsFilmGrainCustomFilterEnable")
            imgui.text("Film grain enabled: " .. tostring(val))
        else
            imgui.text("RenderingManager: not found")
        end
        imgui.tree_pop()
    end
end)

log.info(log_tag .. " Script loaded. Film grain disable active...")