-- > RE9 Debug: Dump rendering-related methods
-- > Much simpler version - just lists method names

local mod_name = "RE9 Rendering API Explorer"
local dump_done = false
local results = {}

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
            local name = method:get_name()
            table.insert(names, name)
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

local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then return nil end
    return game_object:call("getComponent(System.Type)", t)
end

local function do_dump()
    if dump_done then return end

    local renderingMgr = sdk.get_managed_singleton("app.RenderingManager")
    if not renderingMgr then return end

    results = {}
    table.insert(results, "=== RE9 Rendering API Dump ===")

    -- The key one - where film grain toggle lives
    dump_type_methods("app.RenderingManager")

    -- Camera components
    local cameraMgr = sdk.get_managed_singleton("app.CameraManager")
    if cameraMgr then
        local camera = cameraMgr:call("get_PrimaryCamera")
        if camera then
            local cameraGO = camera:call("get_GameObject")
            if cameraGO then
                -- List what components exist on camera
                table.insert(results, "")
                table.insert(results, "=== Camera Component Check ===")

                local check_types = {
                    "via.render.ToneMapping",
                    "via.render.LDRPostProcess",
                    "via.render.Fog",
                    "via.render.ExponentialHeightFog",
                    "via.render.VolumetricFog",
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
                }

                for _, type_name in ipairs(check_types) do
                    local comp = get_component(cameraGO, type_name)
                    local status = comp and "FOUND" or "not found"
                    table.insert(results, "  " .. type_name .. ": " .. status)
                    if comp then
                        dump_type_methods(type_name)
                    end
                end
            end
        end
    end

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
    log.info("[API Explorer] Done! " .. #results .. " lines -> re9_rendering_api_dump.txt")
end

re.on_frame(function()
    local ok, err = pcall(do_dump)
    if not ok and not dump_done then
        log.error("[API Explorer] Error: " .. tostring(err))
    end
end)

re.on_draw_ui(function()
    if imgui.tree_node(mod_name) then
        if dump_done then
            imgui.text("Done! " .. #results .. " lines")
            imgui.text("File: re9_rendering_api_dump.txt")
            if imgui.button("Re-dump") then dump_done = false end
            imgui.separator()
            for _, line in ipairs(results) do
                imgui.text(line)
            end
        else
            imgui.text("Waiting for game to initialize...")
        end
        imgui.tree_pop()
    end
end)

log.info("[API Explorer] Loaded.")
