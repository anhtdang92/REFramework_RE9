-- > RE9 Post Processing Control v2.2.2
-- > Uses direct camera component manipulation via sdk.get_primary_camera()
-- > Fixed "attempt to index a userdata value (upvalue 'ren')" by using get_managed_singleton

local mod = {
    name = "RE9 Post Processing Control",
    version = "2.2.2",
}

-- Default settings
local settings = {
    filmGrain_RM = false,    -- RenderingManager path
    filmGrain_LDR = false,   -- LDRPostProcess path
    fog = false,
    volumetricFog = true,
    godRay = false,
    lensFlare = false,
    motionBlur = false,
    depthOfField = false,
    colorCorrect = true,
    hazeFilter = true,
    radialBlur = true,
    lensDistortion = true,
    TAA = true,
    localExposure = true,
    customContrast = false,
    contrast = 1.0,
    sharpness = 1.0,
}

local initialized = false
local apply_count = 0
local errors = {}

local function log_error(label, err)
    errors[label] = tostring(err)
end

-- Helper to safely call and catch errors
local function safe_call(label, func)
    local ok, err = pcall(func)
    if not ok then
        log_error(label, err)
    else
        errors[label] = nil -- Clear error on success
    end
end

-- Helper to get component (robust version)
local function get_component(go, type_name)
    if not go then return nil end
    local type_def = sdk.find_type_definition(type_name)
    if not type_def then return nil end
    return go:call("get_Component(System.Type)", type_def)
end

local function ApplySettings()
    local cam = sdk.get_primary_camera()
    if not cam then return end
    
    local go = cam:call("get_GameObject")
    if not go then return end

    -- Use managed singleton for IL2CPP objects to allow :call()
    local ren = sdk.get_managed_singleton("app.RenderingManager")
    apply_count = apply_count + 1

    -- Film Grain (RenderingManager path)
    safe_call("FilmGrain_RM", function()
        -- In REFramework, we check if it's not nil AND has the call method
        if ren and ren.call then
            ren:call("set__IsFilmGrainCustomFilterEnable", settings.filmGrain_RM)
        end
    end)

    -- Camera Components
    safe_call("Components", function()
        -- Volumetric Fog
        local vfc = get_component(go, "via.render.VolumetricFogControl")
        if vfc and vfc.call then vfc:call("set_Enabled", settings.volumetricFog) end

        -- Standard Fog
        local fog = get_component(go, "via.render.Fog")
        if fog and fog.call then fog:call("set_Enabled", settings.fog) end

        -- God Rays
        local gr = get_component(go, "via.render.GodRay")
        if gr and gr.call then gr:call("set_Enabled", settings.godRay) end

        -- Lens Flare
        local lf = get_component(go, "via.render.LensFlare")
        if lf and lf.call then lf:call("set_Enabled", settings.lensFlare) end

        -- Motion Blur
        local mb = get_component(go, "via.render.MotionBlur")
        if mb and mb.call then mb:call("set_Enabled", settings.motionBlur) end

        -- Depth of Field
        local dof = get_component(go, "via.render.DepthOfField")
        if dof and dof.call then dof:call("set_Enabled", settings.depthOfField) end
    end)

    -- ToneMapping (TAA, Exposure, Contrast, Sharpness)
    safe_call("ToneMapping", function()
        local tm = get_component(go, "via.render.ToneMapping")
        if tm and tm.call then
            -- TAA
            tm:call("setTemporalAA", settings.TAA and 4 or 5)
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

    -- LDRPostProcess Granular Controls
    safe_call("LDRPostProcess", function()
        local ldr = get_component(go, "via.render.LDRPostProcess")
        if ldr and ldr.call then
            -- Color Correction
            local cc = ldr:call("get_ColorCorrect")
            if cc and cc.call then cc:call("set_Enabled", settings.colorCorrect) end
            
            -- Film Grain (LDR path)
            local fg = ldr:call("get_FilmGrain")
            if fg and fg.call then fg:call("set_Enabled", settings.filmGrain_LDR) end
            
            -- Haze Filter
            local haze = ldr:call("get_HazeFilter")
            if haze and haze.call then haze:call("set_Enabled", settings.hazeFilter) end
            
            -- Radial Blur
            local rb = ldr:call("get_RadialBlur")
            if rb and rb.call then rb:call("set_Enabled", settings.radialBlur) end
            
            -- Lens Distortion
            local ld = ldr:call("get_LensDistortion")
            if ld and ld.call then ld:call("set_Enabled", settings.lensDistortion) end
        end
    end)

    if not initialized then
        initialized = true
        print("[RE9 PostProcess v2.2.2] Initialized")
    end
end

-- Load/Save settings
local function LoadSettings()
    local cfg = json.load_file("re9_postprocess_settings.json")
    if cfg then 
        for k, v in pairs(cfg) do settings[k] = v end
    end
end

local function SaveSettings()
    json.dump_file("re9_postprocess_settings.json", settings)
end

LoadSettings()

re.on_frame(function()
    pcall(ApplySettings)
end)

re.on_config_save(SaveSettings)

-- UI
re.on_draw_ui(function()
    if imgui.tree_node(mod.name .. " v" .. mod.version) then
        local changed = false

        if imgui.button("Save Settings") then SaveSettings() end
        imgui.same_line()
        if imgui.button("Reset Defaults") then
            settings.volumetricFog = true
            settings.colorCorrect = true
            settings.hazeFilter = true
            settings.TAA = true
            settings.localExposure = true
            settings.contrast = 1.0
            settings.sharpness = 1.0
            SaveSettings()
        end
        imgui.spacing()

        imgui.text("Status: " .. (initialized and "Active" or "Waiting..."))
        imgui.text("Apply count: " .. apply_count)
        imgui.separator()

        imgui.text("Film Grain Debug:")
        changed, settings.filmGrain_RM = imgui.checkbox("Grain (RenderingManager)", settings.filmGrain_RM)
        changed, settings.filmGrain_LDR = imgui.checkbox("Grain (LDR Component)", settings.filmGrain_LDR)
        imgui.spacing()

        imgui.text("Visibility / Atmospheric:")
        changed, settings.volumetricFog = imgui.checkbox("Volumetric Fog", settings.volumetricFog)
        changed, settings.fog = imgui.checkbox("Standard Fog", settings.fog)
        changed, settings.godRay = imgui.checkbox("God Rays", settings.godRay)
        changed, settings.hazeFilter = imgui.checkbox("Haze Filter", settings.hazeFilter)
        imgui.spacing()

        imgui.text("Post Effects:")
        changed, settings.lensFlare = imgui.checkbox("Lens Flare", settings.lensFlare)
        changed, settings.motionBlur = imgui.checkbox("Motion Blur", settings.motionBlur)
        changed, settings.depthOfField = imgui.checkbox("Depth of Field", settings.depthOfField)
        changed, settings.radialBlur = imgui.checkbox("Radial Blur", settings.radialBlur)
        changed, settings.lensDistortion = imgui.checkbox("Lens Distortion", settings.lensDistortion)
        imgui.spacing()

        imgui.text("Color & AA:")
        changed, settings.TAA = imgui.checkbox("Temporal AA", settings.TAA)
        changed, settings.colorCorrect = imgui.checkbox("Color Correction", settings.colorCorrect)
        changed, settings.localExposure = imgui.checkbox("Local Exposure", settings.localExposure)
        
        imgui.spacing()
        changed, settings.customContrast = imgui.checkbox("Override Contrast", settings.customContrast)
        if settings.customContrast then
            changed, settings.contrast = imgui.slider_float("Contrast", settings.contrast, 0.0, 2.0)
        end
        changed, settings.sharpness = imgui.slider_float("Sharpness", settings.sharpness, 0.0, 2.0)

        -- Errors
        local has_err = false
        for _, _ in pairs(errors) do has_err = true break end
        if has_err then
            imgui.spacing()
            imgui.text_colored("ERRORS (if blocking):", 0xFF0000FF)
            for k, v in pairs(errors) do
                imgui.text("  " .. k .. ": " .. v)
            end
        end

        imgui.tree_pop()
    end
end)
