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

## 📂 Project Structure

- `HealthAI 2030/`: Main app target
- `HealthAI 2030 macOS/`, `tvOS/`, `WatchKit App/`: Platform-specific targets
- `Modules/`: Feature-based Swift packages
- `Scripts/`: Build, lint, and maintenance scripts
- `Tests/`: Unit and UI tests
- `docs/`: Architecture and API documentation

## 🗂️ Project Folder & File Organization

This project follows Apple’s recommended Xcode organization for clarity, scalability, and maintainability. All files are grouped by feature and function, not by type, to ensure a logical and future-proof structure.

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
├── Resources/         # Assets.xcassets, fonts, and localization
│   ├── Assets.xcassets/
│   │   ├── icons/
│   │   ├── images/
│   │   └── colors/
│   └── Localization/
│       ├── en.lproj/
│       ├── fr.lproj/
│       └── ...
├── Scripts/           # Build, lint, and maintenance scripts
├── Tests/             # Unit and UI tests
├── docs/              # Architecture and API documentation
└── ...
```


### Rationale for Each Group

- **Features/**: All files for a feature (Views, ViewModels, Services) are grouped together for modularity and scalability.
- **Models/**: Contains all data models used across the app.
- **Views/**: Shared SwiftUI views not tied to a single feature.
- **ViewModels/**: Shared view models for UI logic.
- **Services/**: Network, data, and business logic services.
- **Helpers/**: Utility classes and functions.
- **Extensions/**: Swift extensions for types and UI.
- **UIComponents/**: Reusable UI elements (buttons, cards, etc.).
- **Resources/**: All assets, images, fonts, and localization files.
- **Scripts/**: Automation and maintenance scripts.
- **Tests/**: All test targets and files.
- **docs/**: Project documentation.


### Naming Conventions

- **Classes/Files**: PascalCase (e.g., `UserProfileView.swift`)
- **Variables/Methods**: camelCase (e.g., `fetchData()`)
- **Folders**: PascalCase or clear, descriptive names (e.g., `ViewModels`, `Helpers`)
- **Assets**: Lowercase with underscores (e.g., `user_avatar.png`)
- **Localization**: Use standard Apple `.lproj` folders (e.g., `en.lproj`)


### Contributor Checklist

- [ ] Group all files for a feature in `Features/<Feature>/`.
- [ ] Use PascalCase for files/classes, camelCase for variables/methods.
- [ ] Avoid spaces and special characters in names.
- [ ] Organize assets in `Assets.xcassets` by type (icons, images, colors).
- [ ] Place all localization files in `Resources/Localization/` with language subfolders.
- [ ] Add or update documentation for any new folder/group.
- [ ] Remove or merge empty/legacy folders during refactoring.
- [ ] Review and update the `README.md` when the structure changes.
- [ ] Use Xcode groups to match the folder structure on disk.

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

## 🗺️ Roadmap & Known Issues

- See `ROADMAP.md` for planned features and improvements
- Known issues are tracked in GitHub Issues

## 📄 License

This project is licensed under the MIT License. See `LICENSE` for details.

---

For more details, see the `/docs/` folder and in-app help.
