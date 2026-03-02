-- > RE9 Post Processing Control v2
-- > Uses direct camera component manipulation via sdk.get_primary_camera()
-- > Place in: reframework/autorun/

local mod = {
    name = "RE9 Post Processing Control",
    version = "2.0.0",
}

-- Default settings (false = effect disabled)
local settings = {
    filmGrain = false,
    fog = false,
    volumetricFog = true,
    godRay = false,
    lensFlare = false,
    motionBlur = false,
    depthOfField = false,
    colorCorrect = true,
    TAA = true,
    localExposure = true,
    customContrast = false,
    contrast = 1.0,
    sharpness = 1.0,
}

local initialized = false

-- Save/Load
local function SaveSettings()
    json.dump_file("re9_postprocessing_v2.json", settings)
end

local function LoadSettings()
    local loaded = json.load_file("re9_postprocessing_v2.json")
    if loaded then
        for key, val in pairs(loaded) do
            settings[key] = val
        end
    end
end

-- Helper to get component from GameObject
local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then return nil end
    return game_object:call("getComponent(System.Type)", t)
end

-- Generate enum lookup table
local TAAStrength = nil
local function get_taa_enum()
    if TAAStrength then return TAAStrength end
    local t = sdk.find_type_definition("via.render.ToneMapping.TemporalAA")
    if not t then return nil end
    TAAStrength = {}
    for i, field in ipairs(t:get_fields()) do
        if field:is_static() then
            TAAStrength[field:get_name()] = field:get_data(nil)
        end
    end
    return TAAStrength
end

-- Error tracking for UI display
local errors = {}
local apply_count = 0

local function safe_call(label, fn)
    local ok, err = pcall(fn)
    if not ok then
        errors[label] = tostring(err)
        if apply_count < 3 then  -- only log first few frames
            log.error("[RE9 PostProcess] " .. label .. ": " .. tostring(err))
        end
    else
        errors[label] = nil
    end
end

-- Main apply function — called every frame
local function ApplySettings()
    apply_count = apply_count + 1

    -- 1. Film Grain via RenderingManager
    safe_call("FilmGrain (RenderingManager)", function()
        local renderMgr = sdk.get_managed_singleton("app.RenderingManager")
        if renderMgr then
            renderMgr:call("set__IsFilmGrainCustomFilterEnable", settings.filmGrain)
        end
    end)

    -- 2. Camera components via sdk.get_primary_camera()
    local camera = sdk.get_primary_camera()
    if not camera then return end

    local go = camera:call("get_GameObject")
    if not go then return end

    -- Film Grain ALSO via LDRPostProcess (alternative/additional path)
    safe_call("FilmGrain (LDR)", function()
        local ldr = get_component(go, "via.render.LDRPostProcess")
        if ldr then
            local fg = ldr:call("get_FilmGrain")
            if fg then
                fg:call("set_Enabled", settings.filmGrain)
            end
        end
    end)

    -- Fog
    safe_call("Fog", function()
        local fog = get_component(go, "via.render.Fog")
        if fog then fog:call("set_Enabled", settings.fog) end
    end)

    -- Volumetric Fog
    safe_call("VolumetricFog", function()
        local vfog = get_component(go, "via.render.VolumetricFogControl")
        if vfog then vfog:call("set_Enabled", settings.volumetricFog) end
    end)

    -- God Rays
    safe_call("GodRay", function()
        local godray = get_component(go, "via.render.GodRay")
        if godray then godray:call("set_Enabled", settings.godRay) end
    end)

    -- Lens Flare
    safe_call("LensFlare", function()
        local lf = get_component(go, "via.render.LensFlare")
        if lf then lf:call("set_Enabled", settings.lensFlare) end
    end)

    -- Lens Distortion (via LDRPostProcess sub-object)
    safe_call("LensDistortion", function()
        local ldr = get_component(go, "via.render.LDRPostProcess")
        if ldr then
            local ld = ldr:call("get_LensDistortion")
            if ld then
                ld:call("set_Enabled", settings.lensFlare) -- reuse lensFlare toggle
            end
        end
    end)

    -- Motion Blur
    safe_call("MotionBlur", function()
        local mb = get_component(go, "via.render.MotionBlur")
        if mb then mb:call("set_Enabled", settings.motionBlur) end
    end)

    -- Depth of Field
    safe_call("DepthOfField", function()
        local dof = get_component(go, "via.render.DepthOfField")
        if dof then dof:call("set_Enabled", settings.depthOfField) end
    end)

    -- ToneMapping (TAA, local exposure, contrast, sharpness)
    safe_call("ToneMapping/TAA", function()
        local tm = get_component(go, "via.render.ToneMapping")
        if tm then
            -- TAA - use raw integer: 5 = Disable, 4 = Strong
            tm:call("setTemporalAA", settings.TAA and 4 or 5)

            -- Echo/Jitter (related to TAA)
            tm:call("set_EchoEnabled", settings.TAA)

            -- Local Exposure
            tm:call("set_EnableLocalExposure", settings.localExposure)

            -- Contrast
            if settings.customContrast then
                tm:call("set_Contrast", settings.contrast)
            end

            -- Sharpness
            tm:call("set_Sharpness", settings.sharpness)
        end
    end)

    -- Color Correction (via LDRPostProcess sub-object)
    safe_call("ColorCorrect", function()
        local ldr = get_component(go, "via.render.LDRPostProcess")
        if ldr then
            local cc = ldr:call("get_ColorCorrect")
            if cc then
                cc:call("set_Enabled", settings.colorCorrect)
            end
        end
    end)

    if not initialized then
        initialized = true
        log.info("[RE9 PostProcess v2] Initialized — using direct camera components")
    end
end

-- Load settings and start
LoadSettings()

re.on_frame(function()
    pcall(ApplySettings)
end)

re.on_config_save(SaveSettings)

-- UI
re.on_draw_ui(function()
    if imgui.tree_node(mod.name .. " v" .. mod.version) then
        local changed = false

        -- Save/Load/Reset
        if imgui.button("Save") then SaveSettings() end
        imgui.same_line()
        if imgui.button("Reset Defaults") then
            settings.filmGrain = false
            settings.fog = false
            settings.volumetricFog = true
            settings.godRay = false
            settings.lensFlare = false
            settings.motionBlur = false
            settings.depthOfField = false
            settings.colorCorrect = true
            settings.TAA = true
            settings.localExposure = true
            settings.customContrast = false
            settings.contrast = 1.0
            settings.sharpness = 1.0
            SaveSettings()
        end
        imgui.spacing()
        imgui.separator()

        -- Post-Processing Effects
        imgui.text("Post-Processing Effects")
        imgui.spacing()

        changed, settings.filmGrain = imgui.checkbox("Film Grain", settings.filmGrain)
        changed, settings.fog = imgui.checkbox("Fog", settings.fog)
        changed, settings.volumetricFog = imgui.checkbox("Volumetric Fog", settings.volumetricFog)
        changed, settings.godRay = imgui.checkbox("God Rays", settings.godRay)
        changed, settings.lensFlare = imgui.checkbox("Lens Flare", settings.lensFlare)
        changed, settings.motionBlur = imgui.checkbox("Motion Blur", settings.motionBlur)
        changed, settings.depthOfField = imgui.checkbox("Depth of Field", settings.depthOfField)

        imgui.spacing()
        imgui.separator()
        imgui.text("Anti-Aliasing & Color")
        imgui.spacing()

        changed, settings.TAA = imgui.checkbox("TAA", settings.TAA)
        changed, settings.colorCorrect = imgui.checkbox("Color Correction", settings.colorCorrect)
        changed, settings.localExposure = imgui.checkbox("Local Exposure", settings.localExposure)

        imgui.spacing()
        imgui.separator()
        imgui.text("Adjustments")
        imgui.spacing()

        changed, settings.sharpness = imgui.drag_float("Sharpness", settings.sharpness, 0.01, 0.0, 5.0)

        changed, settings.customContrast = imgui.checkbox("Custom Contrast", settings.customContrast)
        if settings.customContrast then
            changed, settings.contrast = imgui.drag_float("Contrast", settings.contrast, 0.01, 0.01, 5.0)
        end

        imgui.spacing()
        imgui.separator()
        imgui.text("Status: " .. (initialized and "Active" or "Waiting for camera..."))
        imgui.text("Apply count: " .. apply_count)

        -- Error diagnostics
        local has_errors = false
        for label, err in pairs(errors) do
            has_errors = true
        end

        if has_errors then
            imgui.spacing()
            imgui.text("ERRORS:")
            for label, err in pairs(errors) do
                imgui.text("  [!] " .. label .. ": " .. err)
            end
        else
            imgui.text("No errors detected")
        end

        imgui.tree_pop()
    end
end)

log.info("[RE9 PostProcess v2] Loaded — direct camera component approach")
