# REFramework (RE9 Fork) [![Build status](https://github.com/praydog/reframework/actions/workflows/dev-release.yml/badge.svg)](https://github.com/praydog/REFramework-nightly/releases)

A fork of [praydog/REFramework](https://github.com/praydog/REFramework) focused on **Resident Evil 9: Requiem** modding and fixes.

## RE9-Specific Additions

### Film Grain Disabler
RE9 ships with a forced film grain / noise post-processing filter that cannot be toggled from the in-game graphics menu or `config.ini`. This fork includes a Lua script (`scripts/re9/re9_disable_postprocessing.lua`) and bundles a [Nexus Mods community script](https://www.nexusmods.com/residentevilrequiem) that disables it at runtime via REFramework.

**How it works:** The script accesses `app.RenderingManager` and calls `set__IsFilmGrainCustomFilterEnable(false)` every frame to force the custom film grain filter off.

### Installation (RE9)
1. **Use the official REFramework build** — Download [RE9.zip](https://github.com/praydog/REFramework-nightly/releases) (click "Show all Assets"), extract `dinput8.dll` into your RE9 game folder (next to `re9.exe`)
2. Copy the `reframework/autorun/disable_film_grain.lua` script into `<game folder>/reframework/autorun/`
3. Launch the game — press **Insert** to open the REFramework overlay

**Do not build from source for normal use.** Self-built REFramework (especially with `DEVELOPER_MODE=ON`) causes severe stutter — menu and gameplay drop below 10 fps periodically. The official nightly is built with release settings and runs correctly. This fork exists for scripts, documentation, and setup guides — not for producing the DLL.

### Disabling All Mods (RE9)

To temporarily run the game without any mods, rename these files in your game folder:

| Mod | File | Disable | Re-enable |
|-----|------|---------|-----------|
| REFramework (film grain disabler, FOV, etc.) | `dinput8.dll` | Rename to `dinput8.dll.disabled` | Rename back to `dinput8.dll` |
| ReShade (includes RenoDX HDR addon) | `dxgi.dll` | Rename to `dxgi.dll.disabled` | Rename back to `dxgi.dll` |

**Disable all:**
```
dinput8.dll       → dinput8.dll.disabled   (REFramework)
dxgi.dll          → dxgi.dll.disabled      (ReShade + RenoDX)
```

**Re-enable all:** Reverse the renames (remove `.disabled` from the filenames).

You can disable them individually — e.g. only rename `dxgi.dll` to keep REFramework but turn off ReShade/RenoDX.

### RenoDX Performance Warning

**RenoDX (ReShade HDR addon) causes severe stutter** — periodic FPS drops below 10 fps every ~10 seconds. Disabling Frame Generation does not fix it. ReShade itself does not cause stutter; only the RenoDX addon is responsible. You can keep ReShade (`dxgi.dll`) active and simply remove or disable the `renodx-re9requiem.addon64` file to eliminate the stutter while retaining other ReShade functionality.

---

## Original REFramework

A mod framework, scripting platform, and modding tool for RE Engine games. Inspired by and uses code from [Kanan](https://github.com/cursey/kanan-new)

## Installation
The last stable build can be downloaded from the [Releases](https://github.com/praydog/REFramework/releases) page.

For newer builds, check out the [Nightly Developer Builds](https://github.com/praydog/REFramework-nightly/releases)

### Non-VR
* Extract only the `dinput8.dll` from the zip file into your game folder.

### VR
* Install SteamVR (unless you're using OpenXR on a supported headset)
* Extract the whole zip file into your corresponding game folder.

[VR Troubleshooting/FAQ](https://github.com/praydog/REFramework/wiki/VR-Troubleshooting)

### Proton/Linux
Add the launch option `WINEDLLOVERRIDES="dinput8.dll=n,b" %command%` to your game through Steam's properties after extraction.

Example game folder: G:\SteamLibrary\steamapps\common\RESIDENT EVIL 2 BIOHAZARD RE2

Supports both DirectX 11 and DirectX 12.

## Included Mods
* Lua Scripting API & Plugin System (All games, check out the [Wiki](https://cursey.github.io/reframework-book/))
* VR
  * Generic 6DOF VR support for all games
  * Motion controls for RE2/RE3/RE7/RE8
* First Person (RE2, RE3)
* Manual Flashlight (RE2, RE3, RE8)
* Free Camera (All games)
* Scene Timescale (All games)
* FOV Slider (All games)
* Vignette Disabler (All games)
* Ultrawide/Aspect Ratio fixes (All games)
* GUI Hider/Disabler (All games)

## Included Fixes
* RE8 Startup Crash
* RE8 Stutters (killing enemies, taking damage, etc...)
* MHRise/RE8 crashes related to third party DLLs

## Included Tools (Developer Mode)
* Game Objects Display
* Object Explorer

## Supported Games
* **Resident Evil 9: Requiem** (primary target of this fork)
* Resident Evil 2
* Resident Evil 3
* Resident Evil 4
* Resident Evil 7
* Resident Evil Village
* Resident Evil Requiem
* Devil May Cry 5
* Street Fighter 6
* Monster Hunter Rise
* Monster Hunter Wilds
* Monster Hunter Stories 3
* Dragon's Dogma 2
* Ghosts 'n Goblins Resurrection (Using `RE8` build)
* Apollo Justice: Ace Attorney Trilogy (Using `DD2` build)
* Kunitsu-Gami: Path of the Goddess (Using `DD2` build)
* Onimusha 2: Samurai's Destiny (Using `MHWILDS` build)

## Thanks
[SkacikPL](https://github.com/SkacikPL) for originally creating the Manual Flashlight mod.

[cursey](https://github.com/cursey/) for helping develop the VR component and the scripting system.

[The Hitchhiker](https://github.com/youwereeatenbyalid/) and [alphaZomega](https://github.com/alphazolam) for the great help stress testing, creating scripts for the scripting system, and helpful suggestions.
