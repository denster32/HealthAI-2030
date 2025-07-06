# HealthAI 2030

[![Build Status](https://github.com/<owner>/<repo>/actions/workflows/build.yml/badge.svg)](https://github.com/<owner>/<repo>/actions)
[![Coverage Status](https://coveralls.io/repos/github/<owner>/<repo>/badge.svg?branch=main)](https://coveralls.io/github/<owner>/<repo>?branch=main)

**A next-generation, cross-platform health application leveraging the latest Apple technologies (iOS 18+, macOS 15+, watchOS 11+, tvOS 18+). HealthAI 2030 provides deep, actionable health insights, advanced analytics, and seamless device integration.**

---

## ✨ Features

- Advanced health analytics (sleep, cardiac, respiratory, mental health)
- AI Health Coach and explainable recommendations
- Multi-platform: iPhone, Apple Watch, Apple TV, Mac
- AR Health Visualizer
- Smart Home integration (lighting, temperature, automation)
- Biofeedback & meditation
- Federated learning and privacy-preserving ML
- Extensible Copilot skill/plugin system
- WidgetKit & Shortcuts
- Full accessibility and localization support
- Modular Swift Package architecture

## 🚀 Installation

1. **Requirements:**
   - Xcode 16+
   - Swift 5.10+
   - iOS 18+, macOS 15+, watchOS 11+, tvOS 18+

2. **Clone the repository:**

   ```sh
   git clone <repo-url>
   ```

3. **Open the project:**
   - Open `HealthAI 2030.xcodeproj` in Xcode.

4. **Resolve dependencies:**
   - All dependencies are managed via Swift Package Manager (SPM). Xcode will auto-resolve them.

5. **Build and run:**
   - Select the desired scheme and target device, then build and run.

## 📱 Usage

- Launch the app on your device or simulator.
- Explore features such as health analytics, environment control, smart home integration, and more.
- For advanced features, see in-app documentation and `/docs/`.

## 🧪 Testing

- Unit tests: Run via Xcode’s Test navigator (`⌘U`).
- UI tests: Available for main user flows.
- Test targets: `HealthAI 2030Tests`, `HealthAI 2030UITests`, and module-specific tests.

## 🤝 Contributing

- Fork the repository and create a feature branch.
- Follow Swift naming conventions and Apple’s Human Interface Guidelines.
- Use SwiftUI and MVVM for new features.
- Write unit and UI tests for new code.
- Submit a pull request with a clear description.

## 🏗️ Architecture

- Built with SwiftUI and MVVM (or @Observable for iOS 18+)
- Modularized via Swift Packages (SPM)
- Managers serve as ViewModels/service layers
- Core Data/SwiftData for persistence
- Metal for high-performance visualizations
- Full accessibility and localization support

## 📚 Documentation

This project uses DocC for comprehensive API documentation:

```bash
swift package generate-documentation --target "HealthAI 2030" --disable-indexing --output-path ./HealthAI2030DocC
```

### Key Documentation
- **[Architecture Guide](docs/architecture.md)** - Detailed system architecture
- **[API Reference](docs/README.md)** - Complete API documentation
- **[Deployment Guide](TESTFLIGHT_CHECKLIST.md)** - Release process
- **[Contributing Guide](CONTRIBUTING.md)** - Development guidelines
- **[Security Guide](SECURITY.md)** - Security and privacy information

## 🎯 Usage Examples

### Quick Health Actions
```swift
// Log mood with contextual data
let moodEntry = MoodEntry(mood: .good, context: "After workout")
HealthDataManager.shared.logMood(moodEntry)

// Start guided breathing session
let breathingSession = BreathingSession(duration: 300, pattern: .boxBreathing)
BreathingManager.shared.startSession(breathingSession)

// Record mental state assessment
let mentalState = MentalState(focus: .high, stress: .low, energy: .medium)
MentalHealthManager.shared.recordState(mentalState)
```

### System Intelligence Integration
```swift
// Configure intelligent health automation
let rule = HealthAutomationRule(
    trigger: .heartRateSpike(threshold: 120),
    action: .suggestBreathingExercise,
    conditions: [.notDuringWorkout, .userAvailable]
)
SystemIntelligence.shared.addRule(rule)
```

## 🗂️ Project Folder & File Organization

This project follows Apple’s recommended Xcode organization for clarity, scalability, and maintainability. All files are grouped by function to ensure a logical and future-proof structure.

### Main Structure

```text
HealthAI-2030/
├── Features/           # Feature modules (e.g., Sleep, SmartHome, Meditation)
│   └── <Feature>/     # Each feature contains its Views, ViewModels, Services, etc.
├── Models/            # Data models
├── Views/             # Shared SwiftUI views
├── ViewModels/        # Shared view models
├── Services/          # Network, data, and logic services
├── Helpers/           # Utility classes and helpers
├── Extensions/        # Swift extensions (e.g., String+Validation.swift)
├── UIComponents/      # Reusable UI components
```

## iOS 18 Optimizations

- **@Observable Framework**: Replaced traditional `ObservableObject` with the new `@Observable` macro for simplified state management.
- **Swift Concurrency**: Implemented `async`/`await` patterns and structured concurrency throughout the codebase.
- **SwiftData**: Migrated from CoreData to SwiftData for modern persistence and synchronization.
- **Live Activities**: Integrated health monitoring in Dynamic Island and Lock Screen.
- **Interactive Widgets**: Enhanced widget interactions for quick access to health data.

## Release Guide

### Steps to Release

1. **Run validation**

   ```sh
   ./Scripts/validate_release.sh
   ```

   - Ensures test coverage >90% and no unresolved TODOs.

2. **Run release script**

   ```sh
   ./Scripts/release.sh
   ```

   - Runs tests, builds, tags the version, and pushes the tag to origin.

3. **CI/CD**

   - GitHub Actions will build, test, and upload coverage for the new tag.

4. **App Store/TestFlight**

   - For iOS/macOS/tvOS/watchOS, archive and upload via Xcode Organizer as needed.

5. **Update Changelog**

   - Add any last-minute fixes or notes to `CHANGELOG.md`.

---

## 🛡️ Accessibility & Apple Guidelines

- Uses standard SwiftUI components and supports Dark Mode
- Full accessibility support (VoiceOver, Dynamic Type)
- Modular, scalable architecture
- All dependencies managed via SPM
- Ready for App Store/TestFlight deployment

## 🌍 Localization & Resources

- All language-specific resources in `Localization/`
- High-res and AR/VR assets in `Resources/`
- Accessibility resources in `Accessibility/`

## 🗺️ Roadmap

### Upcoming Features
- **Skill Marketplace UI** - Community-driven health plugins
- **Enhanced User Scripting** - Advanced health automations
- **Third-party API Support** - Integration with more health services  
- **Explainable AI** - Transparent health recommendations
- **Data Privacy Dashboard** - Advanced privacy controls
- **Community Plugin System** - User-submitted health skills

### Current Development
- CoreML model integration improvements
- Advanced sleep stage classification
- Enhanced cross-device synchronization
- Performance optimizations for iOS 18

For detailed roadmap, see [ROADMAP.md](ROADMAP.md)

## 📄 License

This project is licensed under the MIT License. See `LICENSE` for details.

---

For more details, see the `/docs/` folder and in-app help.
