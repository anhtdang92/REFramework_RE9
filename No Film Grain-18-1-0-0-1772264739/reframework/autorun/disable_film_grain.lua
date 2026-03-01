-- > RE9 Requiem - Disable Film Grain
-- > Place in: reframework/autorun/disable_film_grain.lua

local log_tag = "[FilmGrainDisabler]"
local disable_active = true

-- Load saved setting
local saved = json.load_file("film_grain_disabler.json")
if saved ~= nil and saved.disable_active ~= nil then
    disable_active = saved.disable_active
end

local function apply_film_grain()
    local mgr = sdk.get_managed_singleton("app.RenderingManager")
    if not mgr then return end

    if disable_active then
        mgr:call("set__IsFilmGrainCustomFilterEnable", false)
    else
        mgr:call("set__IsFilmGrainCustomFilterEnable", true)
    end
end

re.on_frame(function()
    apply_film_grain()
end)

re.on_config_save(function()
    json.dump_file("film_grain_disabler.json", { disable_active = disable_active })
end)

re.on_draw_ui(function()
    if imgui.tree_node("Film Grain Disabler") then
        local changed
        changed, disable_active = imgui.checkbox("Disable Film Grain", disable_active)
        if changed then
            apply_film_grain()
            json.dump_file("film_grain_disabler.json", { disable_active = disable_active })
        end

        local mgr = sdk.get_managed_singleton("app.RenderingManager")
        if mgr then
            local val = mgr:call("get__IsFilmGrainCustomFilterEnable")
            imgui.text("Film grain currently: " .. (val and "ON" or "OFF"))
        else
            imgui.text("RenderingManager: not found")
        end
        imgui.tree_pop()
    end
end)

log.info(log_tag .. " Script loaded. Film grain disabler " .. (disable_active and "active" or "inactive"))