# Asset and Resource References in HealthAI 2030

| Asset Type      | File/Resource Name or Path                | Code Location (file:line)                                 | Usage Context/Notes                       |
|----------------|--------------------------------------------|----------------------------------------------------------|--------------------------------------------|
| Image (icon)   | AIHealthCoachIcon.png                      | Assets.xcassets/AIHealthCoachIcon.imageset/Contents.json:5 | App icon/UI asset                          |
| Image (icon)   | ARVisualizerIcon.png                       | Assets.xcassets/ARVisualizerIcon.imageset/Contents.json:5  | App icon/UI asset                          |
| Image (icon)   | BiofeedbackIcon.png                        | Assets.xcassets/BiofeedbackIcon.imageset/Contents.json:5   | App icon/UI asset                          |
| Image (icon)   | SmartHomeIcon.png                          | Assets.xcassets/SmartHomeIcon.imageset/Contents.json:5     | App icon/UI asset                          |
| Image (icon)   | AnalyticsIcon.png                          | Assets.xcassets/AnalyticsIcon.imageset/Contents.json:5     | App icon/UI asset                          |
| 3D Model       | HeartModel.usdz                            | Resources/PremiumAssets.swift:17, AR/ARHealthVisualizerView.swift:9 | AR/3D visualization                        |
| 3D Model       | BrainModel.usdz                            | Resources/PremiumAssets.swift:18                          | AR/3D visualization                        |
| 3D Model       | LungModel.usdz                             | Resources/PremiumAssets.swift:19                          | AR/3D visualization                        |
| 3D Model       | SleepPod.usdz                              | Resources/PremiumAssets.swift:20                          | AR/3D visualization                        |
| 3D Model       | EnvironmentModel.usdz                      | Resources/PremiumAssets.swift:21                          | AR/3D visualization                        |
| Audio          | sleep_soundscape.mp3                       | Audio/PremiumAudio.swift:8                                | Premium audio content                      |
| Audio          | guided_meditation.m4a                      | Audio/PremiumAudio.swift:9                                | Premium audio content                      |
| Audio          | ai_coach_voice.m4a                         | Audio/PremiumAudio.swift:10                               | Premium audio content                      |
| Audio          | deep_sleep_waves.wav                       | Audio/PremiumAudio.swift:11                               | Premium audio content                      |
| Audio          | focus_binaural.mp3                         | Audio/PremiumAudio.swift:12                               | Premium audio content                      |
| Audio          | family_dashboard_theme.m4a                 | Audio/PremiumAudio.swift:13                               | Premium audio content                      |
| Audio          | ar_ambient.mp3                             | Audio/PremiumAudio.swift:14                               | Premium audio content                      |
| Animation/Data | confetti_animation.json                    | Resources/PremiumAvatars.swift:9                          | Lottie/animation asset                     |
| Animation/Data | fireworks_animation.json                   | Resources/PremiumAvatars.swift:10                         | Lottie/animation asset                     |
| Animation/Data | stars_animation.json                       | Resources/PremiumAvatars.swift:11                         | Lottie/animation asset                     |
| Animation/Data | celebration_animation.json                 | Resources/PremiumAvatars.swift:12                         | Lottie/animation asset                     |
| Video          | onboarding_tutorial.mp4                    | Resources/InAppTutorials.swift:7                          | In-app tutorial video                      |
| Video          | dashboard_walkthrough.mp4                  | Resources/InAppTutorials.swift:8                          | In-app tutorial video                      |
| Video          | sleep_tutorial.mp4                         | Resources/InAppTutorials.swift:9                          | In-app tutorial video                      |
| Video          | analytics_tutorial.mp4                     | Resources/InAppTutorials.swift:10                         | In-app tutorial video                      |
| Video          | environment_tutorial.mp4                   | Resources/InAppTutorials.swift:11                         | In-app tutorial video                      |
| Video          | ar_intro.mp4                               | Resources/InAppTutorials.swift:12                         | In-app tutorial video                      |
| PDF Doc        | user_guide.pdf                             | Documentation/OfflineDocumentation.swift:7                | Offline documentation                      |
| PDF Doc        | api_reference.pdf                          | Documentation/OfflineDocumentation.swift:8                | Offline documentation                      |
| PDF Doc        | troubleshooting.pdf                        | Documentation/OfflineDocumentation.swift:9                | Offline documentation                      |
| PDF Doc        | quick_start.pdf                            | Documentation/OfflineDocumentation.swift:10               | Offline documentation                      |
| PDF Doc        | advanced_features.pdf                      | Documentation/OfflineDocumentation.swift:11               | Offline documentation                      |
| PDF Doc        | accessibility_guide.pdf                    | Documentation/OfflineDocumentation.swift:12               | Offline documentation                      |
| PDF Doc        | localization_guide.pdf                     | Documentation/OfflineDocumentation.swift:13               | Offline documentation                      |
| Text           | voiceover_script.txt                       | Accessibility/AccessibilityResources.swift:7              | Accessibility resource                     |
| Text           | haptic_guide.txt                           | Accessibility/AccessibilityResources.swift:8              | Accessibility resource                     |
| PDF Doc        | large_print_guide.pdf                      | Accessibility/AccessibilityResources.swift:9              | Accessibility resource                     |
| PDF Doc        | dyslexia_guide.pdf                         | Accessibility/AccessibilityResources.swift:10             | Accessibility resource                     |
| PDF Doc        | color_blind_guide.pdf                      | Accessibility/AccessibilityResources.swift:11             | Accessibility resource                     |
| PDF Doc        | sign_language_guide.pdf                    | Accessibility/AccessibilityResources.swift:12             | Accessibility resource                     |
| Plist/Config   | info.plist, ExportOptions.plist            | Utilities/PerformanceOptimizer.swift:1486,1497,1500       | Build/test scripts, config                 |
| Workspace      | SomnaSync.xcworkspace                      | Utilities/PerformanceOptimizer.swift:1463,1468,1492       | Build/test scripts                         |
| IPA/App        | SomnaSync.app, SomnaSync.ipa               | Utilities/PerformanceOptimizer.swift:1454,1459,1479,1506,1509 | Build/test scripts                     |
| Markdown      | optimization_report.md                      | Utilities/PerformanceOptimizer.swift:1510                 | Build/test scripts, reporting              |
| Audio         | .m4a (dynamic filename)                     | ML/AudioGenerationEngine.swift:880                        | Audio file output (dynamic)                |
