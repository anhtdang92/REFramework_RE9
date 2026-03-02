# RE9 Rendering API Reference

> Research notes for creating REFramework Lua mods for Resident Evil 9 (Requiem).
> Generated from runtime API exploration using `re9_api_explorer.lua`.

---

## Key Discovery: `app.GraphicsManager` Does NOT Exist in RE9

The MH Wilds post-processing script pattern (`graphicsSetting:call("set_FilmGrain_Enable", ...)` → `graphicsManager:call("setGraphicsSetting", ...)`) **does not work in RE9** because `app.GraphicsManager` doesn't exist. Effects must be controlled through other singletons and camera components.

---

## Working Runtime APIs

### `app.RenderingManager` (Singleton)

The primary rendering singleton. Film grain is controlled here.

```lua
local mgr = sdk.get_managed_singleton("app.RenderingManager")
```

#### Confirmed Working

| Method | Effect |
|--------|--------|
| `set__IsFilmGrainCustomFilterEnable(bool)` | ✅ Toggles film grain in real-time |
| `get__IsFilmGrainCustomFilterEnable()` | Returns current film grain state |

#### Potentially Useful Methods (Untested)

| Method | Likely Purpose |
|--------|---------------|
| `activateFilmGrainCustomFilter` | Activate film grain filter |
| `get_PostEffectGroupBitsControl` | Returns bitfield controller for post-effect groups |
| `get_CustomFilterController` / `set_CustomFilterController` | Custom visual filter system |
| `updateVolumetricFog` | Volumetric fog update — may accept params |
| `updateLDRProcess` | LDR post-processing (color correction) |
| `updateToneMapping` | Tone mapping updates |
| `updateVisualFilter` | Visual filter control |
| `setDirectionalLight` | Directional light (god rays depend on this) |
| `requestVolumetricParticle` | Volumetric particles |
| `setCameraFOV` | Camera field of view |
| `setWindPower` | Wind power (hair/cloth physics) |
| `setDefaultShadowLodBias` / `clearDefaultShadowLodBias` | Shadow LOD control |
| `updateFrameGenerationSkip` | Frame generation (DLSS FG) |
| `updateReflexLowLatencyMode` | NVIDIA Reflex |

<details>
<summary>Full method list (77 methods)</summary>

```
.cctor, .ctor, activateFilmGrainCustomFilter, add_OnCutEvent,
add_OnSetupOnSystemReady, applyDisableOutputID, applySSSSSControlParam,
clearDefaultShadowLodBias, clearFromCamera, clearUserGlobalParam, eventCut,
getHairColorModifyRate, getScopeViewController, get_CustomFilterController,
get_IsRenderOutputCutScene, get_IsSetuppedFromCamera,
get_PostEffectGroupBitsControl, get_ShaderWarmingProgressRate,
get_ToneMappingQueryRealEV, get__IsFilmGrainCustomFilterEnable, lateUpdate,
onDestroy, onEventCut, onEventEnd, onEventEndWithCut, onEventEndWithSeamless,
onEventStart, onEventStartWithCut, onEventStartWithSeamless,
onOptionValueChanged, onStartEventCameraCut, registerCatalog,
registerDisableOutputID, registerScopeCameraController,
registerScopeViewController, remove_OnCutEvent, remove_OnSetupOnSystemReady,
requestCut, requestHairColorModifyRate, requestShaderWarming,
requestStrandsDepthThreshold, requestVolumetricParticle, reset, setCameraFOV,
setDefaultShadowLodBias, setDirectionalLight, setHairColorModifyRate,
setPlayerPosition, setShaderTimer, setUIShaderTimer, setWindPower,
set_CustomFilterController, set_IsRenderOutputCutScene,
set_ToneMappingQueryRealEV, set__IsFilmGrainCustomFilterEnable,
setupFromCamera, setupOnSystemReady, start, startIngame, unregisterCatalog,
unregisterDisableOutputID, unregisterScopeCameraController,
unregisterScopeViewController, updateCut, updateFrameGenerationSkip,
updateHairColorDodifyRAte, updateLDRProcess, updateReflexLowLatencyMode,
updateRenderOutputCutScene, updateShaderWarming, updateStrandsDepthThreshold,
updateToneMapping, updateVisualFilter, updateVolumetricFog
```

</details>

---

### `PostEffectGroupBitsControl` (via RenderingManager)

Type: `app.ContextualPostEffectGroupBitsController`

Accessed via: `renderingMgr:call("get_PostEffectGroupBitsControl")`

> **High-priority lead.** The `requestSetGroupEnabled` method likely provides master toggles for post-effect groups (fog, god rays, etc.) using a bitfield.

| Method | Purpose |
|--------|---------|
| `requestSetGroupEnabled` | ⭐ Toggle effect groups on/off |
| `setApply` | Apply pending changes |
| `onApply` | Apply callback |
| `optionValueFixed` | Lock option value |
| `reset` | Reset to defaults |

**Fields:**
| Type | Name | Observed Value |
|------|------|---------------|
| `app.LayeredParamGroupBits` | `_TargetBits` | `0` |
| `System.Boolean` | `_Apply` | `false` |

**Next steps:** Enumerate `app.LayeredParamGroupBits` to discover which bit corresponds to which effect group, then call `requestSetGroupEnabled` with specific group IDs.

---

### `CustomFilterController` (via RenderingManager)

Type: `app.CustomFilterController`

Accessed via: `renderingMgr:call("get_CustomFilterController")`

Controls visual filters (film grain is one). Has a priority system for stacking filters.

| Method | Purpose |
|--------|---------|
| `registerCustomFilter` | Register a new filter |
| `requestActivate` | Activate a filter |
| `requestDeactivate` | Deactivate a filter |
| `changeCustomFilter` | Change active filter |
| `clearCustomFilter` | Clear filter |
| `getCurrentTopPriorityType` | Get highest-priority active filter |
| `setSwitchType` | Set filter switch behavior |
| `setEventControlEnable` / `isEventControlEnable` | Event-driven filter control |

**Fields:**
| Type | Name | Observed Value |
|------|------|---------------|
| `CustomFilterType` | `_CurrentType` | `0` |
| `via.render.CustomFilter` | `_CustomFilter` | Object pointer |
| `Dictionary<CustomFilterType, CustomFilterTypeBase>` | `_CustomFilterDict` | Object pointer |

**Next steps:** Enumerate `app.CustomFilterController.CustomFilterType` to discover available filter types, then use `requestDeactivate` to disable specific filters.

---

## Camera Components — Not Yet Explored

> **Problem:** `app.CameraManager` returns `nil` in RE9. The camera manager class likely has a different name.

### Known Working Camera Component APIs (from MH Wilds reference)

These work in other RE Engine games via `getComponent` on the camera's GameObject:

| Component | Methods | Controls |
|-----------|---------|----------|
| `via.render.ToneMapping` | `setTemporalAA`, `set_EchoEnabled`, `set_EnableLocalExposure`, `set_Contrast` | TAA, jitter, local exposure, contrast |
| `via.render.LDRPostProcess` → `get_ColorCorrect` | `set_Enabled` | Color correction |

### Components to Search For (once camera is found)

```
via.render.ToneMapping, via.render.LDRPostProcess, via.render.Fog,
via.render.ExponentialHeightFog, via.render.VolumetricFog,
via.render.VolumetricFogControl, via.render.GodRay, via.render.LensFlare,
via.render.LensDistortion, via.render.Bloom, via.render.FilmGrain,
via.render.ScreenSpaceReflection, via.render.MotionBlur, via.render.DepthOfField,
via.render.Vignette, via.render.ChromaticAberration, via.render.AmbientOcclusion,
via.render.ColorCorrect, via.render.FilmicGrain, via.render.SpaceWarp,
via.render.IBL, via.render.RenderConfig
```

---

## Research Priorities

1. **Find the RE9 camera manager** — Try `sdk.get_primary_camera()` directly instead of going through `app.CameraManager`
2. **Enumerate `app.LayeredParamGroupBits`** — Discover the bit values for each effect group
3. **Enumerate `app.CustomFilterController.CustomFilterType`** — Discover available filter types
4. **Test `requestSetGroupEnabled`** — Try toggling effect groups via the bitfield controller
5. **Test `requestDeactivate`** on CustomFilterController — Try disabling specific custom filters

---

## RE Engine Rendering Architecture (General)

```
┌─────────────────────────────────┐
│ Settings Pipeline (startup only)│
│ GraphicsManager → setGraphics   │  ❌ Does not work at runtime
│ Setting → set_FilmGrain_Enable  │     (RE9: class doesn't even exist)
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Runtime Rendering (per-frame)   │
│ RenderingManager → direct props │  ✅ Works (film grain)
│ Camera components → set_Enabled │  ✅ Works (TAA, color correction)
│ PostEffectGroupBits → bitfield  │  ⭐ Untested — likely master switch
└─────────────────────────────────┘
```

## Reference Scripts

| Script | Status | What It Does |
|--------|--------|-------------|
| `disable_film_grain.lua` | ✅ Deployed | Kills film grain every frame via RenderingManager |
| `re9_disable_postprocessing.lua` | ⚠️ Experimental | Tries GraphicsManager (doesn't work in RE9) |
| `re9_api_explorer.lua` | 🔧 Debug tool | Dumps API methods to `re9_rendering_api_dump.txt` |
