# RE9 Mod Setup Guide

This fork bundles several mods for **Resident Evil 9: Requiem**. Below is a summary of each mod, what it does, and how to install/configure it.

---

## Mods Overview

| Mod | Type | File(s) | Status |
|-----|------|---------|--------|
| REFramework | DLL (core) | `dinput8.dll` | Required base framework |
| Film Grain Disabler | Lua script | `reframework/autorun/disable_film_grain.lua` | Simple, always-on |
| Post Processing Control | Lua script | `reframework/autorun/re9_disable_postprocessing.lua` | Full UI, configurable |
| ReShade | DLL | `dxgi.dll` | Optional graphics injector |
| RenoDX HDR | ReShade addon | `renodx-re9requiem.addon64` | Optional HDR tone mapping |

---

## 1. REFramework (`dinput8.dll`)

The core mod framework. Provides the in-game overlay (press **Insert**), Lua scripting API, plugin system, and built-in mods (FOV slider, free camera, vignette disabler, ultrawide fixes, etc.).

**Install:** Download from [REFramework Nightly](https://github.com/praydog/REFramework-nightly/releases) → extract `dinput8.dll` into the game folder next to `re9.exe`.

> **Do not build from source for normal use.** Self-built DLLs cause severe stutter. Use the official nightly release.

---

## 2. Film Grain Disabler (`disable_film_grain.lua`)

**Source:** [Nexus Mods](https://www.nexusmods.com/residentevilrequiem) (bundled in `No Film Grain-18-1-0-0-1772264739/`)

A minimal script that disables RE9's forced film grain every frame by calling:
```lua
sdk.get_managed_singleton("app.RenderingManager"):call("set__IsFilmGrainCustomFilterEnable", false)
```

**Install:** Copy to `<game folder>/reframework/autorun/disable_film_grain.lua`

No configuration needed — it runs automatically. Shows a status readout in the REFramework overlay.

---

## 3. Post Processing Control (`re9_disable_postprocessing.lua`)

A comprehensive script with a full ImGui settings panel. Controls the following effects:

| Effect | Description |
|--------|-------------|
| Film Grain | Forced noise filter |
| Lens Distortion | Barrel/pincushion distortion |
| Lens Flare | Light flare effects |
| God Rays | Volumetric light shafts |
| Fog | Distance fog |
| Volumetric Fog | 3D fog volumes |
| Color Correction | LDR color grading |
| TAA | Temporal anti-aliasing |
| TAA Jitter | Sub-pixel jitter for TAA |
| Local Exposure | Per-region exposure adjustment |
| Custom Contrast | Override contrast (slider 0.01–5.0) |

**Install:** Copy to `<game folder>/reframework/autorun/re9_disable_postprocessing.lua`

**Configure:** Press **Insert** in-game → find "RE9 Post Processing Control" panel → toggle effects on/off. Click "Save Settings" to persist to `re9_postprocessing.json`.

> **Note:** If you have both this script and `disable_film_grain.lua` installed, they won't conflict — but this script already covers film grain, so the simpler one is redundant.

---

## 4. ReShade (`dxgi.dll`)

A generic graphics post-processing injector. Provides shader effects (sharpening, color grading, etc.) and loads addons like RenoDX.

**Install:** Place `dxgi.dll` in the game folder.

**Disable:** Rename `dxgi.dll` → `dxgi.dll.disabled`

ReShade itself does **not** cause performance issues.

---

## 5. RenoDX HDR Addon (`renodx-re9requiem.addon64`)

A ReShade addon that provides HDR tone mapping for RE9. Requires ReShade (`dxgi.dll`) to be active.

**Configure:** In-game press **Home** → **Add-ons** → **RenoDX**. See [RenoDX_LG_C1_Settings.md](../RenoDX_LG_C1_Settings.md) for recommended LG C1 OLED calibration.

> ⚠️ **Performance Warning:** RenoDX causes severe stutter (FPS drops below 10 every ~10 seconds). ReShade itself is fine — only the RenoDX addon causes this. To fix: remove or rename `renodx-re9requiem.addon64` while keeping `dxgi.dll` active.

---

## Disabling Mods

| Mod | How to Disable |
|-----|----------------|
| REFramework | Rename `dinput8.dll` → `dinput8.dll.disabled` |
| ReShade + all addons | Rename `dxgi.dll` → `dxgi.dll.disabled` |
| RenoDX only | Remove/rename `renodx-re9requiem.addon64` |
| Any Lua script | Remove from `reframework/autorun/` |

To re-enable, reverse the rename.

---

## Game Folder Layout

```
<RE9 game folder>/
├── re9.exe
├── dinput8.dll              ← REFramework
├── dxgi.dll                 ← ReShade
├── renodx-re9requiem.addon64 ← RenoDX addon
├── ReShade.ini
├── reframework/
│   └── autorun/
│       ├── disable_film_grain.lua
│       └── re9_disable_postprocessing.lua
└── ...
```
