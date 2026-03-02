-- > RE9 Debug: Dump rendering APIs + explore PostEffectGroupBitsControl & CustomFilterController
-- > Also waits for camera to be ready before checking camera components

local mod_name = "RE9 Rendering API Explorer v2"
local dump_done = false
local results = {}
local frame_count = 0

local function dump_type_methods(type_name)
    local ok, err = pcall(function()
        local t = sdk.find_type_definition(type_name)
        if not t then
            table.insert(results, "--- " .. type_name .. ": NOT FOUND ---")
            return
        end

        table.insert(results, "")
        table.insert(results, "=== " .. type_name .. " ===")

        local methods = t:get_methods()
        local names = {}
        for i, method in ipairs(methods) do
            table.insert(names, method:get_name())
        end

        table.sort(names)
        for _, name in ipairs(names) do
            table.insert(results, "  " .. name)
        end
        table.insert(results, "  [Total: " .. #names .. " methods]")
    end)
    if not ok then
        table.insert(results, "--- " .. type_name .. ": ERROR: " .. tostring(err) .. " ---")
    end
end

local function dump_type_fields(type_name)
    local ok, err = pcall(function()
        local t = sdk.find_type_definition(type_name)
        if not t then return end

        local fields = t:get_fields()
        if not fields or #fields == 0 then return end

        table.insert(results, "  -- Fields --")
        for i, field in ipairs(fields) do
            local name = field:get_name()
            local ftype = field:get_type()
            local ftype_name = ftype and ftype:get_full_name() or "?"
            local static = field:is_static() and " [static]" or ""
            table.insert(results, "  " .. ftype_name .. " " .. name .. static)
        end
    end)
end

local function explore_object(label, obj)
    if not obj then
        table.insert(results, "--- " .. label .. ": nil ---")
        return
    end

    local ok, err = pcall(function()
        local obj_type = obj:get_type_definition()
        if not obj_type then
            table.insert(results, "--- " .. label .. ": no type definition ---")
            return
        end

        local type_name = obj_type:get_full_name()
        table.insert(results, "")
        table.insert(results, "=== " .. label .. " (type: " .. type_name .. ") ===")

        -- Dump methods
        local methods = obj_type:get_methods()
        local names = {}
        for i, method in ipairs(methods) do
            table.insert(names, method:get_name())
        end
        table.sort(names)
        for _, name in ipairs(names) do
            table.insert(results, "  " .. name)
        end
        table.insert(results, "  [Total: " .. #names .. " methods]")

        -- Dump fields
        local fields = obj_type:get_fields()
        if fields and #fields > 0 then
            table.insert(results, "  -- Fields --")
            for i, field in ipairs(fields) do
                local fname = field:get_name()
                local ftype = field:get_type()
                local ftype_name = ftype and ftype:get_full_name() or "?"
                local static = field:is_static() and " [static]" or ""
                local val = ""
                -- Try to read non-static field values
                if not field:is_static() then
                    pcall(function()
                        local v = obj:get_field(fname)
                        val = " = " .. tostring(v)
                    end)
                end
                table.insert(results, "    " .. ftype_name .. " " .. fname .. static .. val)
            end
        end
    end)
    if not ok then
        table.insert(results, "--- " .. label .. ": ERROR: " .. tostring(err) .. " ---")
    end
end

local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then return nil end
    return game_object:call("getComponent(System.Type)", t)
end

local function do_dump()
    if dump_done then return end

    local renderingMgr = sdk.get_managed_singleton("app.RenderingManager")
    if not renderingMgr then return end

    -- Wait extra frames for camera to be ready
    frame_count = frame_count + 1
    if frame_count < 300 then return end  -- Wait ~5 seconds at 60fps

    results = {}
    table.insert(results, "=== RE9 Rendering API Dump v2 ===")
    table.insert(results, "")

    -- 1. RenderingManager methods
    dump_type_methods("app.RenderingManager")

    -- 2. Explore PostEffectGroupBitsControl
    table.insert(results, "")
    table.insert(results, "========== EXPLORING PostEffectGroupBitsControl ==========")
    pcall(function()
        local ctrl = renderingMgr:call("get_PostEffectGroupBitsControl")
        explore_object("PostEffectGroupBitsControl", ctrl)
    end)

    -- 3. Explore CustomFilterController
    table.insert(results, "")
    table.insert(results, "========== EXPLORING CustomFilterController ==========")
    pcall(function()
        local ctrl = renderingMgr:call("get_CustomFilterController")
        explore_object("CustomFilterController", ctrl)
    end)

    -- 4. Camera components
    table.insert(results, "")
    table.insert(results, "========== CAMERA COMPONENTS ==========")
    local cameraMgr = sdk.get_managed_singleton("app.CameraManager")
    if cameraMgr then
        local camera = cameraMgr:call("get_PrimaryCamera")
        if camera then
            local cameraGO = camera:call("get_GameObject")
            if cameraGO then
                table.insert(results, "Camera GameObject found!")

                local check_types = {
                    "via.render.ToneMapping",
                    "via.render.LDRPostProcess",
                    "via.render.Fog",
                    "via.render.ExponentialHeightFog",
                    "via.render.VolumetricFog",
                    "via.render.VolumetricFogControl",
                    "via.render.GodRay",
                    "via.render.LensFlare",
                    "via.render.LensDistortion",
                    "via.render.Bloom",
                    "via.render.FilmGrain",
                    "via.render.ScreenSpaceReflection",
                    "via.render.MotionBlur",
                    "via.render.DepthOfField",
                    "via.render.Vignette",
                    "via.render.ChromaticAberration",
                    "via.render.AmbientOcclusion",
                    "via.render.ColorCorrect",
                    "via.render.FilmicGrain",
                    "via.render.SpaceWarp",
                    "via.render.IBL",
                    "via.render.RenderConfig",
                }

                table.insert(results, "")
                table.insert(results, "--- Component Presence Check ---")
                for _, type_name in ipairs(check_types) do
                    local comp = get_component(cameraGO, type_name)
                    local status = comp and "FOUND ✓" or "not found"
                    table.insert(results, "  " .. type_name .. ": " .. status)
                end

                -- Dump methods for found components
                for _, type_name in ipairs(check_types) do
                    local comp = get_component(cameraGO, type_name)
                    if comp then
                        dump_type_methods(type_name)

                        -- Try to read Enabled state
                        pcall(function()
                            local enabled = comp:call("get_Enabled")
                            table.insert(results, "  >> Enabled = " .. tostring(enabled))
                        end)
                    end
                end
            else
                table.insert(results, "Camera GameObject: nil")
            end
        else
            table.insert(results, "Primary Camera: nil")
        end
    else
        table.insert(results, "CameraManager: nil")
    end

    -- 5. GraphicsManager for reference
    dump_type_methods("app.GraphicsManager")

    -- Write to file
    local file = io.open("re9_rendering_api_dump.txt", "w")
    if file then
        for _, line in ipairs(results) do
            file:write(line .. "\n")
        end
        file:close()
    end

    -- Write to log
    for _, line in ipairs(results) do
        log.info(line)
    end

    dump_done = true
    log.info("[API Explorer v2] Done! " .. #results .. " lines")
end

re.on_frame(function()
    local ok, err = pcall(do_dump)
    if not ok and not dump_done then
        log.error("[API Explorer v2] Error: " .. tostring(err))
    end
end)

re.on_draw_ui(function()
    if imgui.tree_node(mod_name) then
        if dump_done then
            imgui.text("Done! " .. #results .. " lines")
            imgui.text("File: reframework/data/re9_rendering_api_dump.txt")
            if imgui.button("Re-dump") then dump_done = false; frame_count = 250 end
            imgui.separator()
            for _, line in ipairs(results) do
                imgui.text(line)
            end
        else
            imgui.text("Waiting... frame " .. frame_count .. "/300")
        end
        imgui.tree_pop()
    end
end)

log.info("[API Explorer v2] Loaded. Will dump after ~5 sec in-game.")
