# Play Store Graphic Assets Requirements

## Required Graphics

### 1. App Icon
| Specification | Requirement |
|--------------|-------------|
| **Size** | 512 x 512 px |
| **Format** | PNG (32-bit with alpha) |
| **File** | `icon_512.png` |
| **Notes** | No rounded corners (Google applies them), no transparency recommended |

**Current icon source**: `assets/tflite/images/logo.jpeg`

---

### 2. Feature Graphic (Required)
| Specification | Requirement |
|--------------|-------------|
| **Size** | 1024 x 500 px |
| **Format** | PNG or JPEG |
| **File** | `feature_graphic.png` |
| **Notes** | Displayed at top of store listing, no text in bottom 15% |

**Suggested Design**:
- Background: Nature/forest gradient (teal to green)
- Center: SoundScape logo with bird silhouette
- Text: "SoundScape" + tagline "Identify Birds by Sound"
- Waveform graphic element

---

### 3. Screenshots (Min 2, Max 8)

#### Phone Screenshots
| Specification | Requirement |
|--------------|-------------|
| **Size** | 1080 x 1920 px (9:16) or 1080 x 2340 px |
| **Format** | PNG or JPEG |
| **Min Required** | 2 |
| **Max Allowed** | 8 |

**Recommended Screenshots**:

| # | Screen | Filename | Description |
|---|--------|----------|-------------|
| 1 | Home | `screenshot_01_home.png` | Recording interface with waveform |
| 2 | Results | `screenshot_02_results.png` | Species identification with confidence |
| 3 | Library | `screenshot_03_library.png` | Recording library list view |
| 4 | Map | `screenshot_04_map.png` | Map with recording markers |
| 5 | Details | `screenshot_05_details.png` | Recording detail with species info |
| 6 | Noise Monitor | `screenshot_06_noise.png` | Decibel meter screen |

#### 7-inch Tablet Screenshots (Optional)
| Specification | Requirement |
|--------------|-------------|
| **Size** | 1200 x 1920 px |
| **Format** | PNG or JPEG |
| **Max Allowed** | 8 |

#### 10-inch Tablet Screenshots (Optional)
| Specification | Requirement |
|--------------|-------------|
| **Size** | 1920 x 1200 px or 2560 x 1600 px |
| **Format** | PNG or JPEG |
| **Max Allowed** | 8 |

---

### 4. TV Banner (If applicable)
| Specification | Requirement |
|--------------|-------------|
| **Size** | 1280 x 720 px |
| **Format** | PNG or JPEG |
| **Notes** | Only if targeting Android TV |

---

## Screenshot Best Practices

### Do's ✅
- Show actual app screens (not mockups)
- Highlight key features
- Use device frames (optional but recommended)
- Add brief captions/annotations
- Show the app in action
- Use high contrast colors

### Don'ts ❌
- Don't use low-resolution images
- Don't show personal data/info
- Don't include device status bars with real data
- Don't use excessive text overlay
- Don't show competitors' apps

---

## Color Palette for Graphics

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Teal | `#009688` | Brand color, buttons |
| Dark Teal | `#00796B` | Headers, accents |
| Light Teal | `#B2DFDB` | Backgrounds |
| White | `#FFFFFF` | Text, icons |
| Dark Gray | `#212121` | Text |

---

## Screenshot Annotations Template

```
┌─────────────────────────────────────┐
│  🎤 Record Bird Sounds              │  <- Caption (top)
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     [App Screenshot]        │    │
│  │                             │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Real-time waveform visualization   │  <- Description (bottom)
└─────────────────────────────────────┘
```

---

## File Checklist

```
playstore/
├── graphics/
│   ├── icon_512.png              [ ] Required
│   ├── feature_graphic.png       [ ] Required
│   ├── screenshots/
│   │   ├── phone/
│   │   │   ├── screenshot_01.png [ ] Required (min 2)
│   │   │   ├── screenshot_02.png [ ] Required
│   │   │   ├── screenshot_03.png [ ] Optional
│   │   │   ├── screenshot_04.png [ ] Optional
│   │   │   ├── screenshot_05.png [ ] Optional
│   │   │   └── screenshot_06.png [ ] Optional
│   │   ├── tablet_7/             [ ] Optional
│   │   └── tablet_10/            [ ] Optional
│   └── promo_video.mp4           [ ] Optional (YouTube link)
```

---

## Promo Video (Optional but Recommended)

| Specification | Requirement |
|--------------|-------------|
| **Platform** | YouTube |
| **Length** | 30 seconds - 2 minutes |
| **Resolution** | 1080p minimum |
| **Content** | App demo, features showcase |

**Video Script Suggestion**:
1. (0-5s) SoundScape logo + tagline
2. (5-15s) Show recording interface in nature
3. (15-25s) AI identification in action
4. (25-35s) Map and library features
5. (35-45s) Key features bullet points
6. (45-50s) Download CTA + logo

---

## Tools for Creating Graphics

- **Figma** (free): Design feature graphic, add text overlays
- **Canva** (free): Quick graphics with templates
- **Screenshot tools**: Android Studio device frames
- **flutter_launcher_icons**: Generate app icons

### Generate 512x512 Icon Command
```bash
# From existing logo
flutter pub run flutter_launcher_icons:main
# Or manually resize assets/tflite/images/logo.jpeg
```
