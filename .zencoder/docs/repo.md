# HealthAI 2030 Information

## Summary
HealthAI 2030 is a multi-platform health and wellness application for iOS, watchOS, tvOS, and macOS. It leverages advanced analytics, machine learning, augmented reality, and smart home automation to provide personalized health insights and recommendations. The application features AI-powered health coaching, biofeedback meditation, federated learning, and an extensible "Copilot" skill system.

## Structure
- **HealthAI 2030/**: Main iOS application target with shared code
- **HealthAI 2030 WatchKit App/**: watchOS application target
- **HealthAI 2030 macOS/**: macOS application target
- **HealthAI 2030 tvOS/**: tvOS application target
- **Packages/**: Modular Swift packages (Analytics, ML, Audio, etc.)
- **Scripts/**: Helper scripts for build phases and maintenance
- **Tests/**: Non-Xcode-target tests
- **docs/**: Architecture diagrams and documentation

## Language & Runtime
**Language**: Swift (primary), Python (ML components)
**Swift Version**: 6.2 (minimum required)
**Build System**: Xcode, Swift Package Manager
**Package Manager**: Swift Package Manager

## Dependencies
**Swift Packages**:
- Analytics: Health data analytics components
- Audio: Audio processing for meditation and biofeedback
- Biofeedback: Biometric feedback processing
- ML: Machine learning models and inference
- Managers: Service layer components
- Models: Data models
- SmartHome: Smart home integration
- Utilities: Shared utility functions

**Python Dependencies** (for ML training):
- pandas (≥1.5.0)
- numpy (≥1.21.0)
- create-ml (≥1.0.0)
- scikit-learn (≥1.1.0)
- coremltools (≥6.0.0)

## Build & Installation
```bash
# Build the iOS app
xcodebuild -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15'

# Lint code
swiftlint

# Format code
swiftformat .

# Generate documentation
xcodebuild docbuild -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Main Components
- **UI Layer**: Built with SwiftUI for declarative user interfaces
- **State Management**: MVVM-like pattern with Manager classes
- **Data Persistence**: Core Data with CloudKit synchronization
- **ML Pipeline**: Python training scripts with CoreML model integration
- **Copilot Skills**: Extensible AI capabilities system
- **Multi-platform Support**: Shared code with platform-specific adaptations

## Testing
**Frameworks**: XCTest
**Test Locations**:
- HealthAI 2030Tests/: Main application tests
- HealthAI 2030UITests/: UI tests
- Tests/: Additional test suites
- Package-specific tests in each package directory

**Test Types**:
- Unit tests
- UI tests
- Performance tests
- Snapshot tests
- Property-based tests

**Run Command**:
```bash
xcodebuild test -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Key Features
- Advanced Health Analytics
- AI Health Coach
- AR Health Visualizer
- Smart Home Integration
- Biofeedback & Meditation
- Federated Learning
- Extensible AI with Copilot skills
- User Customization with scripting
- WidgetKit & Shortcuts integration
- Explainable AI
- Data Privacy Dashboard