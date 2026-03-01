# RenoDX Settings for LG C1 OLED

Recommended RenoDX settings for **LG C1** (65" at 5–6 ft). Adjust in-game: press **Home** → **Add-ons** → **RenoDX**.

## LG C1 Specs (Reference)
- Peak brightness: ~800 nits (HDR)
- True Black OLED (0 nits blacks)
- HDR10, Dolby Vision, HLG
- BT.2020 wide color gamut
- VESA DisplayHDR True Black 400

---

## Recommended Settings

### Tone Mapper
| Setting | Value | Notes |
|---------|-------|-------|
| **Tone Map Type** | RenoDX | Use RenoDX (not Vanilla) for proper HDR |
| **Peak Brightness** | 800 | Match C1's ~800 nits to avoid clipping |
| **Game Brightness** | 0.5–0.7 | Slight lift for OLED; adjust to taste |

*Note: Tone Mapper changes require toggling HDR off/on in-game to apply fully.*

### SDR EOTF Emulation
| Setting | Value | Notes |
|---------|-------|-------|
| **EOTF** | 2.2 (By Luminosity) | Matches C1 calibration; more natural than Per Channel |

### Color Grading
| Setting | Value | Notes |
|---------|-------|-------|
| **Exposure** | 0 | Start neutral |
| **Gamma** | 1.0 | Default |
| **Contrast** | 1.0–1.1 | OLED can handle slightly more |
| **Saturation** | 1.0 | Default; C1 has good color |
| **Highlights** | 1.0 | Preserve highlight detail |
| **Shadows** | 0.95–1.0 | Slight lift if needed; OLED blacks are already perfect |
| **Highlight Saturation** | 1.0 | Default |
| **Dechroma** | 0 | Off |
| **Flare** | 0 | Off or minimal |

### Effects (if using with Film Grain Disabler)
| Setting | Value | Notes |
|---------|-------|-------|
| **Noise** | 0 | Off — use REFramework film grain disabler instead |
| **Vanilla Film Grain** | Off | Off |
| **Custom Film Grain** | Off | Off |

### UI
| Setting | Value | Notes |
|---------|-------|-------|
| **UI Visibility** | 1.0 | Default |
| **UI Brightness** | 1.0 | Adjust if HUD is too bright/dim |

---

## Quick Start
1. Set **Tone Map Type** → RenoDX  
2. Set **Peak Brightness** → 800  
3. Set **SDR EOTF** → 2.2 (By Luminosity)  
4. Disable all **Effects** (Noise, Film Grain)  
5. Toggle HDR off/on in game settings to apply Tone Mapper changes  
6. Fine-tune **Game Brightness** and **Contrast** to taste  

---

## TV Settings (LG C1)
For best results, ensure:
- **HDMI Input**: Game Optimizer mode
- **Instant Game Response**: On
- **Peak Brightness**: High
- **Black Level**: Auto (or Low if PC outputs full range)
- **Dynamic Contrast**: Off
- **TruMotion**: Off (for responsiveness)
