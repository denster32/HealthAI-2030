# Asset Generation Instructions for HealthAI 2030

This document provides explicit, LLM-friendly instructions for generating all required assets for the HealthAI 2030 project. Follow these guidelines exactly to ensure assets are ready to be dropped into the project with no renaming or reorganization required.

---

## General Guidelines
- **File Naming:** Use the exact filenames and extensions provided below.
- **Folder Structure:** Place each asset in the specified folder path, relative to the project root (`HealthAI 2030/`).
- **Format:** Use the specified file format (e.g., PNG, MP3, USDZ, PDF, etc.).
- **Size/Specs:** Adhere to the required dimensions, duration, bitrate, or other specs.
- **Description:** Follow the description and style notes for each asset.
- **Accessibility:** Where noted, ensure assets are accessible (e.g., high contrast, alt text, etc.).

---

## Asset List & Specifications

### 1. App Icons & UI Images
| Filename                  | Folder Path                        | Format | Size/Specs         | Description/Style                                      |
|---------------------------|------------------------------------|--------|--------------------|--------------------------------------------------------|
| AIHealthCoachIcon.png     | Assets.xcassets/AIHealthCoachIcon.imageset/ | PNG    | 1024x1024 px, transparent | Modern, friendly AI health coach icon, blue/green palette |
| ARVisualizerIcon.png      | Assets.xcassets/ARVisualizerIcon.imageset/  | PNG    | 1024x1024 px, transparent | AR/3D visualizer icon, futuristic, purple/teal          |
| BiofeedbackIcon.png       | Assets.xcassets/BiofeedbackIcon.imageset/   | PNG    | 1024x1024 px, transparent | Biofeedback/heartbeat icon, red/white, clean lines      |
| SmartHomeIcon.png         | Assets.xcassets/SmartHomeIcon.imageset/     | PNG    | 1024x1024 px, transparent | Smart home/house icon, warm yellow/gray, minimal        |
| AnalyticsIcon.png         | Assets.xcassets/AnalyticsIcon.imageset/     | PNG    | 1024x1024 px, transparent | Analytics/chart icon, green/blue, modern flat style     |

### 2. 3D Models (AR/Visualization)
| Filename                  | Folder Path         | Format | Size/Specs         | Description/Style                                      |
|---------------------------|---------------------|--------|--------------------|--------------------------------------------------------|
| HeartModel.usdz           | Resources/          | USDZ   | <5MB, <50k polys   | Anatomically correct heart, red/pink, AR-optimized     |
| BrainModel.usdz           | Resources/          | USDZ   | <5MB, <50k polys   | Realistic brain, light gray/purple, AR-optimized       |
| LungModel.usdz            | Resources/          | USDZ   | <5MB, <50k polys   | Realistic lungs, pink/blue, AR-optimized               |
| SleepPod.usdz             | Resources/          | USDZ   | <5MB, <50k polys   | Futuristic sleep pod, white/blue, smooth surfaces      |
| EnvironmentModel.usdz     | Resources/          | USDZ   | <5MB, <50k polys   | Indoor environment, modern, neutral colors             |

### 3. Audio Files (Premium Content)
| Filename                  | Folder Path         | Format | Size/Specs         | Description/Style                                      |
|---------------------------|---------------------|--------|--------------------|--------------------------------------------------------|
| sleep_soundscape.mp3      | Audio/              | MP3    | 320kbps, 3 min     | Gentle ambient soundscape for sleep, soft, loopable    |
| guided_meditation.m4a     | Audio/              | M4A    | 256kbps, 5 min     | Calm, clear voice, guided meditation, neutral accent   |
| ai_coach_voice.m4a        | Audio/              | M4A    | 256kbps, 1 min     | Friendly AI coach voice, motivational, neutral accent  |
| deep_sleep_waves.wav      | Audio/              | WAV    | 16-bit, 44.1kHz, 2 min | Deep, slow ocean waves, relaxing, loopable         |
| focus_binaural.mp3        | Audio/              | MP3    | 320kbps, 10 min    | Binaural beats for focus, subtle, no vocals            |
| family_dashboard_theme.m4a| Audio/              | M4A    | 256kbps, 30 sec    | Upbeat, family-friendly theme, instrumental            |
| ar_ambient.mp3            | Audio/              | MP3    | 320kbps, 2 min     | Futuristic ambient music for AR, light, non-distracting|

### 4. Animation/Data (Lottie/JSON)
| Filename                  | Folder Path         | Format | Size/Specs         | Description/Style                                      |
|---------------------------|---------------------|--------|--------------------|--------------------------------------------------------|
| confetti_animation.json   | Resources/          | JSON   | <500KB             | Lottie confetti burst, colorful, celebratory           |
| fireworks_animation.json  | Resources/          | JSON   | <500KB             | Lottie fireworks, night sky, vibrant                   |
| stars_animation.json      | Resources/          | JSON   | <500KB             | Lottie twinkling stars, subtle, dark background        |
| celebration_animation.json| Resources/          | JSON   | <500KB             | Lottie celebration, streamers, confetti, festive       |

### 5. Video Tutorials
| Filename                  | Folder Path         | Format | Size/Specs         | Description/Style                                      |
|---------------------------|---------------------|--------|--------------------|--------------------------------------------------------|
| onboarding_tutorial.mp4   | Resources/          | MP4    | 1080p, <30MB, 2 min| App onboarding, UI walkthrough, friendly narration     |
| dashboard_walkthrough.mp4 | Resources/          | MP4    | 1080p, <30MB, 2 min| Dashboard features, highlights, clear visuals          |
| sleep_tutorial.mp4        | Resources/          | MP4    | 1080p, <30MB, 2 min| Sleep optimization, calming visuals, voiceover         |
| analytics_tutorial.mp4    | Resources/          | MP4    | 1080p, <30MB, 2 min| Analytics features, charts, engaging transitions       |
| environment_tutorial.mp4  | Resources/          | MP4    | 1080p, <30MB, 2 min| Smart home/environment, HomeKit demo, clear narration  |
| ar_intro.mp4              | Resources/          | MP4    | 1080p, <30MB, 1 min| AR features, 3D overlays, immersive demo               |

### 6. Documentation (PDF)
| Filename                  | Folder Path         | Format | Size/Specs         | Description/Style                                      |
|---------------------------|---------------------|--------|--------------------|--------------------------------------------------------|
| user_guide.pdf            | Documentation/      | PDF    | <10MB, 20+ pages   | Comprehensive user guide, screenshots, accessible      |
| api_reference.pdf         | Documentation/      | PDF    | <10MB, 15+ pages   | API reference, code samples, clear structure           |
| troubleshooting.pdf       | Documentation/      | PDF    | <5MB, 10+ pages    | Troubleshooting guide, FAQs, step-by-step solutions    |
| quick_start.pdf           | Documentation/      | PDF    | <5MB, 5+ pages     | Quick start guide, setup steps, large text             |
| advanced_features.pdf     | Documentation/      | PDF    | <10MB, 10+ pages   | Advanced features, tips, diagrams                      |
| accessibility_guide.pdf   | Documentation/      | PDF    | <5MB, 5+ pages     | Accessibility features, large text, high contrast      |
| localization_guide.pdf    | Documentation/      | PDF    | <5MB, 5+ pages     | Localization, supported languages, screenshots         |

### 7. Accessibility Resources
| Filename                  | Folder Path         | Format | Size/Specs         | Description/Style                                      |
|---------------------------|---------------------|--------|--------------------|--------------------------------------------------------|
| voiceover_script.txt      | Accessibility/      | TXT    | <100KB             | Voiceover script, plain text, clear instructions       |
| haptic_guide.txt          | Accessibility/      | TXT    | <100KB             | Haptic feedback guide, plain text, step-by-step        |
| large_print_guide.pdf     | Accessibility/      | PDF    | <5MB, 5+ pages     | Large print, high contrast, accessible                 |
| dyslexia_guide.pdf        | Accessibility/      | PDF    | <5MB, 5+ pages     | Dyslexia-friendly, OpenDyslexic font, high contrast    |
| color_blind_guide.pdf     | Accessibility/      | PDF    | <5MB, 5+ pages     | Color-blind accessible, diagrams, large text           |
| sign_language_guide.pdf   | Accessibility/      | PDF    | <5MB, 5+ pages     | Sign language, diagrams, step-by-step                  |

---

## Special Notes
- All assets must be original or fully licensed for commercial use.
- Use modern, clean, and accessible design principles.
- For images and icons, provide alt text or a short description in a separate `.txt` file if possible.
- For audio, ensure seamless looping where noted and provide a fade-in/fade-out.
- For 3D models, optimize for AR (low poly, PBR textures, centered origin).
- For Lottie/JSON, test animation in LottieFiles or similar before delivery.
- For PDFs, ensure selectable text (not just images) and accessibility tagging.

---

## Delivery
- Place all assets in the correct folders as specified above, using the exact filenames.
- Do not zip or rename files.
- Notify the HealthAI 2030 team when assets are ready for review.

---

This document is designed for use by LLMs or human designers to generate and deliver assets that can be immediately integrated into the HealthAI 2030 project.
