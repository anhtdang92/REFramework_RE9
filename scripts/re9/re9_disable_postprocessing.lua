local mod = {
    name = "RE9 Post Processing Control",
    version = "1.0.0",
}

local settings = {
    filmGrain = true,
    lensDistortion = true,
    lensFlare = true,
    bloom = true,
    volumetricFog = true,
    fog = true,
    godRay = true,
    colorCorrect = true,
    TAA = true,
    jitter = true,
    localExposure = true,
    customContrast = false,
    contrast = 1.0,
}

local graphicsManager, cameraManager
local graphicsSetting, displaySettings
local tonemapping, tonemappingType
local colorCorrectComponent
local TAAStrength, localExposureType, lensDistortionSetting
local initialized = false

local function GenerateEnum(typename, double_ended)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[name] = raw_value
            if double_ended then
                enum[raw_value] = name
            end
        end
    end

    return enum
end

local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then return nil end
    return game_object:call("getComponent(System.Type)", t)
end

local function SaveSettings()
    json.dump_file("re9_postprocessing.json", settings)
end

local function LoadSettings()
    local loaded = json.load_file("re9_postprocessing.json")
    if loaded ~= nil then
        for key, val in pairs(loaded) do
            settings[key] = val
        end
    end
end

local function ApplySettings()
    -- Re-acquire managers every frame in case of scene changes
    graphicsManager = sdk.get_managed_singleton("app.GraphicsManager")
    if not graphicsManager then return end

    cameraManager = sdk.get_managed_singleton("app.CameraManager")

    -- Film grain: use app.RenderingManager (the only approach that works at runtime in RE9)
    local renderingManager = sdk.get_managed_singleton("app.RenderingManager")
    if renderingManager then
        renderingManager:call("set__IsFilmGrainCustomFilterEnable", settings.filmGrain)
    end

    graphicsSetting = graphicsManager:call("get_NowGraphicsSetting")

    if graphicsSetting then
        graphicsSetting:call("set_FilmGrain_Enable", settings.filmGrain)
        graphicsSetting:call("set_LensFlare_Enable", settings.lensFlare)
        graphicsSetting:call("set_Fog_Enable", settings.fog)
        graphicsSetting:call("set_VolumetricFogControl_Enable", settings.volumetricFog)
        graphicsSetting:call("set_GodRay_Enable", settings.godRay)

        pcall(function()
            if not lensDistortionSetting then
                lensDistortionSetting = GenerateEnum("via.render.RenderConfig.LensDistortionSetting", true)
            end
            if lensDistortionSetting then
                graphicsSetting:call("set_LensDistortionSetting",
                    settings.lensDistortion and lensDistortionSetting.ON or lensDistortionSetting.OFF)
            end
        end)

        graphicsManager:call("setGraphicsSetting", graphicsSetting)
    end

    -- Re-acquire camera components every frame
    if cameraManager then
        local camera = cameraManager:call("get_PrimaryCamera")
        if camera then
            local cameraGO = camera:call("get_GameObject")
            if cameraGO then
                tonemapping = get_component(cameraGO, "via.render.ToneMapping")

                local ldrPost = get_component(cameraGO, "via.render.LDRPostProcess")
                if ldrPost then
                    colorCorrectComponent = ldrPost:call("get_ColorCorrect")
                end
            end
        end
    end

    if tonemapping then
        if not TAAStrength then
            TAAStrength = GenerateEnum("via.render.ToneMapping.TemporalAA", true)
        end
        if TAAStrength then
            tonemapping:call("setTemporalAA",
                settings.TAA and TAAStrength.Manual or TAAStrength.Disable)
        end
        tonemapping:call("set_EchoEnabled", settings.jitter)
        tonemapping:call("set_EnableLocalExposure", settings.localExposure)

        if settings.customContrast then
            tonemapping:call("set_Contrast", settings.contrast)
        end
    end

    if colorCorrectComponent then
        colorCorrectComponent:call("set_Enabled", settings.colorCorrect)
    end

    if not initialized then
        initialized = true
        log.info("[RE9 PostProcess] Initialized successfully")
    end
end

LoadSettings()
re.on_frame(function()
    ApplySettings()
end)
re.on_config_save(SaveSettings)

re.on_draw_ui(function()
    if imgui.tree_node(mod.name .. " v" .. mod.version) then
        local changed = false

        imgui.text("Film grain is OFF by default. Toggle options below.")
        imgui.spacing()

        -- Save/Load buttons
        if imgui.button("Save Settings") then SaveSettings() end
        imgui.same_line()
        if imgui.button("Reset Defaults") then
            settings.filmGrain = false
            settings.lensDistortion = false
            settings.lensFlare = true
            settings.bloom = true
            settings.volumetricFog = true
            settings.fog = true
            settings.godRay = true
            settings.colorCorrect = true
            settings.TAA = true
            settings.jitter = true
            settings.localExposure = true
            settings.customContrast = false
            settings.contrast = 1.0
            ApplySettings()
        end
        imgui.spacing()
        imgui.separator()

        imgui.text("Post Processing Effects")
        imgui.spacing()

        changed, settings.filmGrain = imgui.checkbox("Film Grain", settings.filmGrain)
        if changed then ApplySettings() end

        changed, settings.lensDistortion = imgui.checkbox("Lens Distortion", settings.lensDistortion)
        if changed then ApplySettings() end

        changed, settings.lensFlare = imgui.checkbox("Lens Flare", settings.lensFlare)
        if changed then ApplySettings() end

        changed, settings.godRay = imgui.checkbox("God Rays", settings.godRay)
        if changed then ApplySettings() end

        changed, settings.fog = imgui.checkbox("Fog", settings.fog)
        if changed then ApplySettings() end

        changed, settings.volumetricFog = imgui.checkbox("Volumetric Fog", settings.volumetricFog)
        if changed then ApplySettings() end

        imgui.spacing()
        imgui.separator()
        imgui.text("Anti-Aliasing & Color")
        imgui.spacing()

        changed, settings.colorCorrect = imgui.checkbox("Color Correction", settings.colorCorrect)
        if changed then ApplySettings() end

        changed, settings.TAA = imgui.checkbox("TAA", settings.TAA)
        if changed then ApplySettings() end

        changed, settings.jitter = imgui.checkbox("TAA Jitter", settings.jitter)
        if changed then ApplySettings() end

        changed, settings.localExposure = imgui.checkbox("Local Exposure", settings.localExposure)
        if changed then ApplySettings() end

        imgui.spacing()
        imgui.separator()
        imgui.text("Contrast")
        imgui.spacing()

        changed, settings.customContrast = imgui.checkbox("Custom Contrast", settings.customContrast)
        if changed then ApplySettings() end

        if settings.customContrast then
            changed, settings.contrast = imgui.drag_float("Contrast", settings.contrast, 0.01, 0.01, 5.0)
            if changed then ApplySettings() end
        end

        imgui.tree_pop()
    end
end)
