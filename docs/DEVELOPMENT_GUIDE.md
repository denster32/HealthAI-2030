# HealthAI 2030 Development Guide

## 🚀 Quick Start

### Prerequisites
- Xcode 16.0+
- iOS 18.0+ / macOS 15.0+
- Swift 6.0+

### Setup
```bash
git clone <repository-url>
cd "HealthAI 2030"
swift build
swift test
```

## 🏗️ Project Architecture

### Modular Structure
The project is organized as a Swift Package Manager workspace with 25+ independent modules:

```
HealthAI 2030/
├── Sources/HealthAI2030/          # Main app target
├── Packages/                      # Feature modules
│   ├── HealthAI2030Core/         # Core health data
│   ├── CardiacHealth/            # Heart health features
│   ├── MentalHealth/             # Mental wellness
│   ├── SleepTracking/            # Sleep analysis
│   └── ...                       # 22 more modules
├── Tests/                         # Test targets
└── Scripts/                       # Build and deployment
```

### Module Categories

#### Core Packages
- **HealthAI2030Core** - Foundation health models
- **HealthAI2030Networking** - API communication
- **HealthAI2030UI** - Shared UI components
- **HealthAI2030Graphics** - Metal graphics
- **HealthAI2030ML** - Machine learning
- **HealthAI2030Foundation** - Utilities

#### Feature Modules
- **CardiacHealth** - Heart monitoring
- **MentalHealth** - Wellness tracking
- **SleepTracking** - Sleep analysis
- **HealthPrediction** - AI predictions
- **CopilotSkills** - AI assistant
- **Metal4** - High-performance graphics
- **SmartHome** - Home automation
- **UserScripting** - Custom automation
- **Shortcuts** - Siri integration
- **LogWaterIntake** - Hydration
- **StartMeditation** - Mindfulness
- **AR** - Augmented reality
- **Biofeedback** - Real-time feedback

#### Shared Components
- **Shared** - Common utilities
- **SharedSettingsModule** - Settings management
- **HealthAIConversationalEngine** - NLP
- **Kit** - Development tools
- **ML** - ML utilities
- **SharedHealthSummary** - Data aggregation

## 💻 Development Workflow

### Adding New Features

1. **Create Module Structure**
```bash
mkdir -p Packages/NewFeature/Sources/NewFeature
```

2. **Add Source File**
```swift
// Packages/NewFeature/Sources/NewFeature/NewFeature.swift
import Foundation

@available(iOS 18.0, macOS 15.0, *)
public class NewFeature {
    public init() {}
    
    public func version() -> String {
        return "1.0.0"
    }
}
```

3. **Update Package.swift**
```swift
// Add product
.library(
    name: "NewFeature",
    targets: ["NewFeature"]
),

// Add target
.target(
    name: "NewFeature",
    dependencies: [],
    path: "Packages/NewFeature/Sources/NewFeature"
),

// Add to main target dependencies
.target(
    name: "HealthAI2030",
    dependencies: [
        // ... existing dependencies
        "NewFeature"
    ],
    path: "Sources/HealthAI2030"
)
```

4. **Add Tests**
```bash
mkdir -p Tests/NewFeatureTests
```

```swift
// Tests/NewFeatureTests/NewFeatureTests.swift
import XCTest
@testable import NewFeature

@available(iOS 18.0, macOS 15.0, *)
final class NewFeatureTests: XCTestCase {
    func testNewFeature() throws {
        let feature = NewFeature()
        XCTAssertEqual(feature.version(), "1.0.0")
    }
}
```

### Testing

#### Run All Tests
```bash
swift test
```

#### Run Specific Tests
```bash
swift test --filter HealthAI2030Tests
```

#### Run Test Script
```bash
bash Scripts/run_all_tests.sh
```

#### Verify Setup
```bash
bash Scripts/verify_setup.sh
```

### Building

#### Debug Build
```bash
swift build
```

#### Release Build
```bash
swift build -c release
```

#### Clean Build
```bash
swift package clean
swift build
```

## 📱 Platform-Specific Development

### iOS 18+ Features
- Use `@available(iOS 18.0, *)` for new features
- Leverage latest SwiftUI capabilities
- Implement Apple Intelligence features
- Use SwiftData for persistence

### macOS 15+ Features
- Support window management
- Implement menu bar integration
- Use Catalyst for iOS compatibility
- Leverage desktop-specific APIs

### Cross-Platform Considerations
- Use conditional compilation
- Implement platform-specific UI
- Handle device capabilities
- Test on all target platforms

## 🔧 Configuration

### Build Settings
The project is configured for:
- iOS 18.0+ minimum
- macOS 15.0+ minimum
- Swift 6.0 language features
- Modern concurrency support

### Dependencies
- **swift-argument-parser** - Command line tools
- Minimal external dependencies
- Focus on Apple frameworks

## 🧪 Testing Strategy

### Unit Tests
- Test individual modules
- Mock dependencies
- Test edge cases
- Ensure code coverage

### Integration Tests
- Test module interactions
- Test data flow
- Test error handling
- Test performance

### UI Tests
- Test user workflows
- Test accessibility
- Test cross-device compatibility
- Test edge cases

## 📦 Deployment

### Development
```bash
swift build
swift test
```

### Staging
```bash
bash Scripts/Release/validate_release.sh
```

### Production
```bash
bash Scripts/Release/release.sh
```

## 🔍 Debugging

### Common Issues

#### Build Errors
1. Check Swift version compatibility
2. Verify module dependencies
3. Clean and rebuild
4. Check platform availability

#### Test Failures
1. Check test target dependencies
2. Verify test data
3. Check availability annotations
4. Review test logic

#### Runtime Issues
1. Check platform availability
2. Verify API usage
3. Test on target devices
4. Review error handling

### Debug Tools
- Xcode debugger
- Swift Package Manager logs
- Test output analysis
- Performance profiling

## 📚 Best Practices

### Code Organization
- Keep modules focused and small
- Use clear naming conventions
- Document public APIs
- Follow Swift style guidelines

### Performance
- Use lazy loading
- Implement caching
- Optimize for target platforms
- Profile regularly

### Security
- Validate all inputs
- Use secure APIs
- Implement proper authentication
- Follow privacy guidelines

### Accessibility
- Support VoiceOver
- Implement Dynamic Type
- Use semantic markup
- Test with accessibility tools

## 🚀 Advanced Features

### SwiftData Integration
```swift
import SwiftData

@Model
class HealthRecord {
    var id: UUID
    var timestamp: Date
    var data: Data
    
    init(id: UUID = UUID(), timestamp: Date = Date(), data: Data) {
        self.id = id
        self.timestamp = timestamp
        self.data = data
    }
}
```

### Metal 4 Graphics
```swift
import Metal

class MetalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
    }
}
```

### Core ML Integration
```swift
import CoreML

class HealthPredictor {
    private let model: MLModel
    
    init() throws {
        model = try HealthModel()
    }
    
    func predict(input: HealthInput) throws -> HealthPrediction {
        return try model.prediction(from: input)
    }
}
```

## 📖 Resources

### Documentation
- [README.md](README.md) - Project overview
- [REORGANIZATION_SUMMARY.md](REORGANIZATION_SUMMARY.md) - Reorganization details
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

### Scripts
- `Scripts/run_all_tests.sh` - Run complete test suite
- `Scripts/verify_setup.sh` - Verify project setup
- `Scripts/Release/` - Deployment scripts

### Support
- Create GitHub issues for bugs
- Review test examples
- Check documentation
- Follow Apple guidelines

---

**Happy coding! 🎉** 