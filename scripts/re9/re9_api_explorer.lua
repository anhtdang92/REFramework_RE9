-- > RE9 Debug: Deep rendering API exploration v3
-- > Enumerates enums, finds camera via sdk.get_primary_camera(), checks components

local mod_name = "RE9 API Explorer v3"
local dump_done = false
local results = {}
local frame_count = 0

local function add(line)
    table.insert(results, line or "")
end

local function dump_type_methods(type_name)
    local ok, err = pcall(function()
        local t = sdk.find_type_definition(type_name)
        if not t then
            add("--- " .. type_name .. ": NOT FOUND ---")
            return
        end
        add("")
        add("=== " .. type_name .. " ===")
        local methods = t:get_methods()
        local names = {}
        for i, method in ipairs(methods) do
            table.insert(names, method:get_name())
        end
        table.sort(names)
        for _, name in ipairs(names) do
            add("  " .. name)
        end
        add("  [Total: " .. #names .. " methods]")
    end)
    if not ok then
        add("--- " .. type_name .. ": ERROR: " .. tostring(err) .. " ---")
    end
end

local function enumerate_enum(type_name)
    local ok, err = pcall(function()
        local t = sdk.find_type_definition(type_name)
        if not t then
            add("--- ENUM " .. type_name .. ": NOT FOUND ---")
            return
        end
        add("")
        add("=== ENUM: " .. type_name .. " ===")
        local fields = t:get_fields()
        local entries = {}
        for i, field in ipairs(fields) do
            if field:is_static() then
                local name = field:get_name()
                local raw_value = field:get_data(nil)
                table.insert(entries, { name = name, value = raw_value })
            end
        end
        table.sort(entries, function(a, b)
            if type(a.value) == "number" and type(b.value) == "number" then
                return a.value < b.value
            end
            return tostring(a.name) < tostring(b.name)
        end)
        for _, entry in ipairs(entries) do
            add("  " .. tostring(entry.value) .. " = " .. entry.name)
        end
        add("  [Total: " .. #entries .. " values]")
    end)
    if not ok then
        add("--- ENUM " .. type_name .. ": ERROR: " .. tostring(err) .. " ---")
    end
end

local function explore_object(label, obj)
    if not obj then
        add("--- " .. label .. ": nil ---")
        return
    end
    local ok, err = pcall(function()
        local obj_type = obj:get_type_definition()
        if not obj_type then
            add("--- " .. label .. ": no type def ---")
            return
        end
        local type_name = obj_type:get_full_name()
        add("")
        add("=== " .. label .. " (type: " .. type_name .. ") ===")
        local methods = obj_type:get_methods()
        local names = {}
        for i, method in ipairs(methods) do
            table.insert(names, method:get_name())
        end
        table.sort(names)
        for _, name in ipairs(names) do
            add("  " .. name)
        end
        add("  [Total: " .. #names .. " methods]")

        local fields = obj_type:get_fields()
        if fields and #fields > 0 then
            add("  -- Fields --")
            for i, field in ipairs(fields) do
                local fname = field:get_name()
                local ftype = field:get_type()
                local ftype_name = ftype and ftype:get_full_name() or "?"
                local static = field:is_static() and " [static]" or ""
                local val = ""
                if not field:is_static() then
                    pcall(function()
                        local v = obj:get_field(fname)
                        val = " = " .. tostring(v)
                    end)
                end
                add("    " .. ftype_name .. " " .. fname .. static .. val)
            end
        end
    end)
    if not ok then
        add("--- " .. label .. ": ERROR: " .. tostring(err) .. " ---")
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

    frame_count = frame_count + 1
    if frame_count < 300 then return end

    results = {}
    add("=== RE9 Rendering API Dump v3 ===")
    add("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
    add("")

    -------------------------------------------------------
    -- SECTION 1: Enumerate key enums
    -------------------------------------------------------
    add("##################################################")
    add("# SECTION 1: ENUM ENUMERATION")
    add("##################################################")

    enumerate_enum("app.LayeredParamGroupBits")
    enumerate_enum("app.CustomFilterController.CustomFilterType")
    enumerate_enum("via.render.ToneMapping.TemporalAA")
    enumerate_enum("via.render.RenderConfig.LensDistortionSetting")
    enumerate_enum("via.render.ToneMapping.LocalExposureType")

    -- Try to find any post-processing related enums
    local extra_enums = {
        "app.PostEffectGroup",
        "app.PostEffectGroupBits",
        "app.RenderingManager.PostEffectGroup",
        "via.render.PostEffect",
        "via.render.PostEffectType",
        "app.ContextualPostEffectGroupBitsController.GroupType",
    }
    for _, enum_name in ipairs(extra_enums) do
        enumerate_enum(enum_name)
    end

    -------------------------------------------------------
    -- SECTION 2: PostEffectGroupBitsControl deep dive
    -------------------------------------------------------
    add("")
    add("##################################################")
    add("# SECTION 2: PostEffectGroupBitsControl")
    add("##################################################")
    pcall(function()
        local ctrl = renderingMgr:call("get_PostEffectGroupBitsControl")
        explore_object("PostEffectGroupBitsControl", ctrl)

        -- Also explore the type definition for requestSetGroupEnabled
        if ctrl then
            local ctrl_type = ctrl:get_type_definition()
            if ctrl_type then
                local method = ctrl_type:get_method("requestSetGroupEnabled")
                if method then
                    add("  >> requestSetGroupEnabled found!")
                    add("  >> Return type: " .. tostring(method:get_return_type():get_full_name()))
                    -- Try to get parameter count
                    pcall(function()
                        local num_params = method:get_num_params()
                        add("  >> Param count: " .. tostring(num_params))
                    end)
                end
            end
        end
    end)

    -------------------------------------------------------
    -- SECTION 3: CustomFilterController deep dive
    -------------------------------------------------------
    add("")
    add("##################################################")
    add("# SECTION 3: CustomFilterController")
    add("##################################################")
    pcall(function()
        local ctrl = renderingMgr:call("get_CustomFilterController")
        explore_object("CustomFilterController", ctrl)

        -- Try to get the CustomFilter object and explore it
        if ctrl then
            pcall(function()
                local filter = ctrl:get_field("_CustomFilter")
                explore_object("CustomFilter (_CustomFilter)", filter)
            end)
        end
    end)

    -------------------------------------------------------
    -- SECTION 4: Camera via sdk.get_primary_camera()
    -------------------------------------------------------
    add("")
    add("##################################################")
    add("# SECTION 4: CAMERA (sdk.get_primary_camera)")
    add("##################################################")

    local camera = sdk.get_primary_camera()
    if camera then
        add("sdk.get_primary_camera() = FOUND!")

        local cameraGO = nil
        pcall(function()
            cameraGO = camera:call("get_GameObject")
        end)

        if cameraGO then
            add("Camera GameObject = FOUND!")

            -- Check all component types
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
                "via.render.FilmicGrain",
                "via.render.ScreenSpaceReflection",
                "via.render.MotionBlur",
                "via.render.DepthOfField",
                "via.render.Vignette",
                "via.render.ChromaticAberration",
                "via.render.AmbientOcclusion",
                "via.render.ColorCorrect",
                "via.render.SpaceWarp",
                "via.render.IBL",
                "via.render.RenderConfig",
                "via.render.HDRPostProcess",
                "via.render.CustomFilter",
                "via.render.SSAO",
                "via.render.SSR",
            }

            add("")
            add("--- Component Presence Check ---")
            local found_types = {}
            for _, type_name in ipairs(check_types) do
                local comp = get_component(cameraGO, type_name)
                local status = comp and "FOUND ✓" or "not found"
                add("  " .. type_name .. ": " .. status)
                if comp then
                    table.insert(found_types, { name = type_name, comp = comp })
                end
            end

            -- Dump methods + Enabled state for found components
            for _, entry in ipairs(found_types) do
                dump_type_methods(entry.name)
                pcall(function()
                    local enabled = entry.comp:call("get_Enabled")
                    add("  >> get_Enabled() = " .. tostring(enabled))
                end)
            end
        else
            add("Camera GameObject: nil")
        end
    else
        add("sdk.get_primary_camera() = nil")

        -- Try alternative ways to find camera
        add("")
        add("--- Trying alternative camera singletons ---")
        local alt_singletons = {
            "app.CameraManager",
            "app.MainCameraManager",
            "app.CameraSystem",
            "app.camera.CameraManager",
            "app.PlayerCameraManager",
        }
        for _, name in ipairs(alt_singletons) do
            local mgr = sdk.get_managed_singleton(name)
            add("  " .. name .. ": " .. (mgr and "FOUND" or "nil"))
            if mgr then
                explore_object(name, mgr)
            end
        end
    end

    -------------------------------------------------------
    -- SECTION 5: Try finding singletons with rendering methods
    -------------------------------------------------------
    add("")
    add("##################################################")
    add("# SECTION 5: OTHER SINGLETONS")
    add("##################################################")

    local other_singletons = {
        "app.GraphicsManager",
        "app.GraphicsSetting",
        "app.OptionManager",
        "app.DisplayManager",
        "app.ScreenManager",
        "app.PostEffectManager",
        "app.EnvironmentManager",
        "app.WeatherManager",
        "app.LightManager",
        "app.SceneManager",
    }
    for _, name in ipairs(other_singletons) do
        local mgr = sdk.get_managed_singleton(name)
        if mgr then
            add("")
            add(">>> " .. name .. ": FOUND! <<<")
            explore_object(name, mgr)
        end
    end

    -------------------------------------------------------
    -- Write output
    -------------------------------------------------------
    local file = io.open("re9_rendering_api_dump.txt", "w")
    if file then
        for _, line in ipairs(results) do
            file:write(line .. "\n")
        end
        file:close()
    end

    for _, line in ipairs(results) do
        log.info(line)
    end

    dump_done = true
    log.info("[API Explorer v3] Done! " .. #results .. " lines")
end

re.on_frame(function()
    local ok, err = pcall(do_dump)
    if not ok and not dump_done then
        log.error("[API Explorer v3] Error: " .. tostring(err))
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

log.info("[API Explorer v3] Loaded. Will dump after ~5 sec.")
