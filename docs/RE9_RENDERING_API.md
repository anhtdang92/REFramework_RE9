# RE9 Rendering API Reference

> Research notes for creating REFramework Lua mods for Resident Evil 9 (Requiem).
> Generated from runtime API exploration using `re9_api_explorer.lua` v3.

---

## Critical Discovery: `app.GraphicsManager` Does NOT Exist

The MH Wilds `setGraphicsSetting` pattern **does not work in RE9**. Effects must be controlled through `app.RenderingManager` and direct camera component manipulation via `sdk.get_primary_camera()`.

---

## Enum Reference

### `app.LayeredParamGroupBits` (Post-Effect Groups)
| Value | Name |
|-------|------|
| 0 | None |
| 1 | Group_00 |
| 2 | Group_01 |
| 4 | Group_02 |
| 8 | Group_03 |
| 16 | Group_04 |
| 32 | Group_05 |
| 64 | Group_06 |
| 128 | Group_07 |

### `app.CustomFilterController.CustomFilterType`
| Value | Name |
|-------|------|
| 0 | None |
| 1 | **FilmGrain** |
| 2 | Scope |
| 3 | SurveillanceCamera |
| 4 | GlitchNoise |

### `via.render.ToneMapping.TemporalAA`
| Value | Name |
|-------|------|
| 0 | Legacy |
| 1 | Manual |
| 2 | Weak |
| 3 | Mild |
| 4 | Strong |
| 5 | **Disable** |

### `via.render.RenderConfig.LensDistortionSetting`
| Value | Name |
|-------|------|
| 0 | ON |
| 1 | DistortionOnly |
| 2 | **OFF** |

### `via.render.ToneMapping.LocalExposureType`
| Value | Name |
|-------|------|
| 0 | Legacy |
| 1 | BlurredLuminance |
| 2 | LocalLaplacian |

---

## Camera Components (via `sdk.get_primary_camera()`)

`sdk.get_primary_camera()` works in RE9. Access components via:
```lua
local camera = sdk.get_primary_camera()
local go = camera:call("get_GameObject")
local comp = go:call("getComponent(System.Type)", sdk.typeof("via.render.Foo"))
```

### Found Components

| Component | Enabled | Methods | Runtime Toggle |
|-----------|---------|---------|----------------|
| `via.render.ToneMapping` | ✅ true | 193 | `set_Enabled(bool)`, `setTemporalAA()`, `set_Contrast()`, `set_EnableLocalExposure()`, `set_EchoEnabled()`, `set_Sharpness()` |
| `via.render.LDRPostProcess` | ✅ true | 18 | `set_Enabled(bool)` — contains sub-objects: `get_ColorCorrect`, `get_FilmGrain`, `get_LensDistortion`, `get_HazeFilter`, `get_RadialBlur`, `get_ImagePlane` |
| `via.render.Fog` | ❌ false | 90 | `set_Enabled(bool)`, `set_Density()`, `set_Intensity()`, `set_MaxOpacity()`, `set_StartDistance()` |
| `via.render.VolumetricFogControl` | ✅ true | 102 | `set_Enabled(bool)`, `set_ShadowEnabled()`, `set_EmissionEnabled()` |
| `via.render.GodRay` | ❌ false | 46 | `set_Enabled(bool)`, `set_Density()`, `set_Exposure()`, `set_Weight()`, `set_SunIntensity()` |
| `via.render.LensFlare` | ❌ false | 36 | `set_Enabled(bool)`, `set_Bloom()`, `set_BloomThreshold()`, `set_Dispersion()` |
| `via.render.MotionBlur` | ❌ false | 10 | `set_Enabled(bool)`, `set_ShutterAngle()` |
| `via.render.DepthOfField` | ❌ false | 97 | `set_Enabled(bool)`, `set_FocusDistance()`, `set_FNumber()` |
| `via.render.CustomFilter` | ❌ false | 15 | `set_Enabled(bool)` |

### Not Found on Camera
```
via.render.ExponentialHeightFog, via.render.VolumetricFog,
via.render.LensDistortion, via.render.Bloom, via.render.FilmGrain,
via.render.FilmicGrain, via.render.ScreenSpaceReflection, via.render.Vignette,
via.render.ChromaticAberration, via.render.AmbientOcclusion, via.render.ColorCorrect,
via.render.SpaceWarp, via.render.IBL, via.render.RenderConfig,
via.render.HDRPostProcess, via.render.SSAO, via.render.SSR
```

---

## `app.RenderingManager` (Singleton) — 77 methods

```lua
local mgr = sdk.get_managed_singleton("app.RenderingManager")
```

### Confirmed Working
| Method | Effect |
|--------|--------|
| `set__IsFilmGrainCustomFilterEnable(bool)` | ✅ Toggles film grain real-time |

### Key Methods to Explore
| Method | Purpose |
|--------|---------|
| `get_PostEffectGroupBitsControl` | Returns `app.ContextualPostEffectGroupBitsController` |
| `get_CustomFilterController` | Returns `app.CustomFilterController` |
| `updateVolumetricFog` | Volumetric fog pipeline |
| `updateLDRProcess` | LDR post-processing |
| `updateToneMapping` | Tone mapping |
| `updateVisualFilter` | Visual filters |

---

## `PostEffectGroupBitsControl`

Type: `app.ContextualPostEffectGroupBitsController`

| Method | Params | Returns |
|--------|--------|---------|
| `requestSetGroupEnabled` | **2 params** | `void` |
| `setApply` | | |
| `onApply` | | |
| `reset` | | |

Fields: `_TargetBits = 0` (LayeredParamGroupBits), `_Apply = false`

> **Next step:** Call `requestSetGroupEnabled(group_bit, bool)` with each Group_00–Group_07 value to find which group controls which effect.

---

## `CustomFilterController`

Type: `app.CustomFilterController`

### Filter Types Available
- `0 = None`, `1 = FilmGrain`, `2 = Scope`, `3 = SurveillanceCamera`, `4 = GlitchNoise`

### Key Methods
| Method | Purpose |
|--------|---------|
| `requestActivate(type)` | Activate a filter type |
| `requestDeactivate(type)` | Deactivate a filter type |
| `clearCustomFilter` | Clear all filters |
| `getCurrentTopPriorityType` | Get active filter |

Fields: `_CurrentType = 0` (None), `_CustomFilter` → `via.render.CustomFilter` object

---

## `LDRPostProcess` Sub-Objects

`via.render.LDRPostProcess` has getter/setter methods for sub-components:
- `get_ColorCorrect` / `set_ColorCorrect` — Color correction
- **`get_FilmGrain`** / `set_FilmGrain` — Film grain (alternative path!)
- `get_LensDistortion` / `set_LensDistortion` — Lens distortion
- `get_HazeFilter` / `set_HazeFilter` — Haze filter
- `get_RadialBlur` / `set_RadialBlur` — Radial blur
- `get_ImagePlane` / `set_ImagePlane` — Image plane
- `get_ColorDeficiencySimulation` / `set_ColorDeficiencySimulation` — Color deficiency sim

---

## Other Singletons Found

| Singleton | Methods | Notes |
|-----------|---------|-------|
| `app.OptionManager` | 0 | Empty — wrapper only |
| `app.LightManager` | 120 | Controls lights, assist lights, day/night, god rays indirectly |

### Not Found
```
app.GraphicsManager, app.GraphicsSetting, app.DisplayManager,
app.ScreenManager, app.PostEffectManager, app.EnvironmentManager,
app.WeatherManager, app.SceneManager
```

---

## Recommended Mod Strategy

### For each effect, use the DIRECT camera component approach:

```lua
local camera = sdk.get_primary_camera()
local go = camera:call("get_GameObject")

-- Disable Fog
local fog = go:call("getComponent(System.Type)", sdk.typeof("via.render.Fog"))
if fog then fog:call("set_Enabled", false) end

-- Disable God Rays
local godray = go:call("getComponent(System.Type)", sdk.typeof("via.render.GodRay"))
if godray then godray:call("set_Enabled", false) end

-- Disable Lens Flare
local lensflare = go:call("getComponent(System.Type)", sdk.typeof("via.render.LensFlare"))
if lensflare then lensflare:call("set_Enabled", false) end

-- Disable Motion Blur
local mb = go:call("getComponent(System.Type)", sdk.typeof("via.render.MotionBlur"))
if mb then mb:call("set_Enabled", false) end

-- Disable Depth of Field
local dof = go:call("getComponent(System.Type)", sdk.typeof("via.render.DepthOfField"))
if dof then dof:call("set_Enabled", false) end

-- Film Grain (via RenderingManager — confirmed working)
local renderMgr = sdk.get_managed_singleton("app.RenderingManager")
if renderMgr then renderMgr:call("set__IsFilmGrainCustomFilterEnable", false) end

-- TAA (via ToneMapping component)
local tm = go:call("getComponent(System.Type)", sdk.typeof("via.render.ToneMapping"))
if tm then tm:call("setTemporalAA", 5) end -- 5 = Disable

-- Color Correction (via LDRPostProcess sub-object)
local ldr = go:call("getComponent(System.Type)", sdk.typeof("via.render.LDRPostProcess"))
if ldr then
    local cc = ldr:call("get_ColorCorrect")
    if cc then cc:call("set_Enabled", false) end
end
```

### Apply every frame via `re.on_frame()` to prevent game from overriding.

---

## Research Priorities (Remaining)

1. **Test `set_Enabled(false)` on camera components** — Fog, GodRay, LensFlare all show `Enabled = false` already, need to test toggling ON then OFF
2. **Test `requestSetGroupEnabled(group_bit, enabled)`** — Try each Group_00–07 to discover what they control
3. **Explore `LDRPostProcess.get_FilmGrain()`** — Alternative film grain path through camera component
4. **Test `requestDeactivate(1)`** on CustomFilterController — Deactivate FilmGrain filter type
