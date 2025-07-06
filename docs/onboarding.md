# Developer Onboarding Guide

## Welcome to HealthAI 2030! 🚀

This guide will help you get up and running with the HealthAI 2030 project quickly and efficiently. Whether you're a new contributor, team member, or just exploring the codebase, this guide covers everything you need to know.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Environment Setup](#environment-setup)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Code Standards](#code-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Common Tasks](#common-tasks)
8. [Troubleshooting](#troubleshooting)
9. [Resources](#resources)

## Quick Start

### Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Xcode 15.2+** installed
- [ ] **iOS 18.0+ SDK** installed
- [ ] **macOS 15.0+ SDK** installed
- [ ] **Apple Developer Account** (for device testing)
- [ ] **Git** configured with your credentials
- [ ] **SwiftLint** installed (optional, for code quality)

### 5-Minute Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/healthai-2030/HealthAI-2030.git
   cd HealthAI-2030
   ```

2. **Install dependencies**
   ```bash
   swift package resolve
   ```

3. **Open in Xcode**
   ```bash
   open HealthAI2030App.xcworkspace
   ```

4. **Build and run**
   - Select iOS Simulator (iPhone 15 Pro recommended)
   - Press `Cmd+R` to build and run
   - The app should launch successfully

5. **Run tests**
   ```bash
   swift test
   ```

🎉 **Congratulations!** You're now ready to start developing.

## Environment Setup

### Required Software

#### Xcode Setup
- **Version**: 15.2 or later
- **Platforms**: iOS 18.0+, macOS 15.0+, watchOS 11.0+, tvOS 18.0+
- **Extensions**: Install recommended extensions for Swift development

#### Command Line Tools
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Verify installation
xcode-select -p
```

#### SwiftLint (Recommended)
```bash
# Install via Homebrew
brew install swiftlint

# Or install via CocoaPods
pod install swiftlint

# Verify installation
swiftlint version
```

### Development Environment

#### Git Configuration
```bash
# Set up your Git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Configure Git for the project
git config core.autocrlf input
git config core.safecrlf warn
```

#### Xcode Preferences
1. **General**
   - Enable "Show line numbers"
   - Enable "Show page guide"
   - Set "Page guide column" to 120

2. **Text Editing**
   - Enable "Automatically trim trailing whitespace"
   - Enable "Including whitespace-only lines"

3. **Key Bindings**
   - Familiarize yourself with common shortcuts
   - Consider installing custom key bindings

#### Recommended Xcode Extensions
- **SwiftLint** - Code style enforcement
- **SwiftFormat** - Automatic code formatting
- **GitLens** - Enhanced Git integration
- **Rainbow** - Color highlighting
- **Bracket Pair Colorizer** - Code structure visualization

## Project Structure

### High-Level Architecture

```
HealthAI 2030/
├── Apps/                          # Application targets
│   ├── MainApp/                   # Main iOS application
│   ├── macOSApp/                  # macOS application
│   ├── WatchApp/                  # Apple Watch app
│   └── TVApp/                     # Apple TV app
├── Frameworks/                    # Core frameworks
│   ├── HealthAI2030Core/          # Core data and business logic
│   ├── HealthAI2030UI/            # UI components and views
│   └── HealthAI2030Networking/    # Networking layer
├── Modules/                       # Feature modules
│   ├── Core/                      # Core functionality
│   ├── Advanced/                  # Advanced features and AI
│   └── Features/                  # Feature-specific modules
├── Scripts/                       # Build and deployment scripts
├── Tests/                         # Test suites
├── docs/                          # Documentation
└── Configuration/                 # Build configurations
```

### Key Directories Explained

#### `Apps/MainApp/`
- **Views/**: SwiftUI views and UI components
- **Services/**: Business logic and service layer
- **Models/**: Data models and Core Data entities
- **Resources/**: Assets, localization, and configuration files

#### `Frameworks/HealthAI2030Core/`
- **Sources/**: Core business logic and data management
- **Tests/**: Unit tests for core functionality
- **Package.swift**: Swift Package Manager configuration

#### `Modules/`
- **Core/**: Essential functionality (health data, analytics)
- **Advanced/**: AI/ML features and advanced analytics
- **Features/**: Feature-specific implementations

### File Naming Conventions

- **Views**: `PascalCase` (e.g., `HealthDashboardView.swift`)
- **Models**: `PascalCase` (e.g., `HealthData.swift`)
- **Services**: `PascalCase` + "Manager" (e.g., `HealthDataManager.swift`)
- **Extensions**: `PascalCase` + "Extension" (e.g., `HealthDataExtension.swift`)
- **Tests**: `PascalCase` + "Tests" (e.g., `HealthDataManagerTests.swift`)

## Development Workflow

### Branch Strategy

We follow a **Git Flow** approach:

```
main (production)
├── develop (integration)
├── feature/feature-name
├── bugfix/bug-description
└── hotfix/critical-fix
```

### Workflow Steps

1. **Create Feature Branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write code following our standards
   - Add comprehensive tests
   - Update documentation if needed

3. **Test Locally**
   ```bash
   # Run all tests
   swift test
   
   # Run specific test suite
   swift test --filter YourFeatureTests
   
   # Check code quality
   swiftlint lint
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add new health monitoring feature"
   ```

5. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   # Create Pull Request on GitHub
   ```

### Commit Message Format

We follow the **Conventional Commits** standard:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build/tooling changes

**Examples:**
```bash
git commit -m "feat(health): add heart rate monitoring"
git commit -m "fix(ui): resolve dashboard layout issue"
git commit -m "docs(api): update API documentation"
```

## Code Standards

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with project-specific additions:

#### Naming Conventions
```swift
// ✅ Good
class HealthDataManager {
    func fetchHealthData() async throws -> [HealthData] {
        // Implementation
    }
}

// ❌ Bad
class healthDataManager {
    func fetch_health_data() async throws -> [healthData] {
        // Implementation
    }
}
```

#### Documentation
```swift
/// Fetches health data for the specified date range.
/// - Parameters:
///   - startDate: The start date for the data range
///   - endDate: The end date for the data range
///   - dataType: The type of health data to fetch
/// - Returns: An array of health data records
/// - Throws: `HealthDataError` if the operation fails
func fetchHealthData(
    startDate: Date,
    endDate: Date,
    dataType: HealthDataType
) async throws -> [HealthData] {
    // Implementation
}
```

#### Error Handling
```swift
// ✅ Good
do {
    let data = try await fetchHealthData()
    // Handle success
} catch HealthDataError.notFound {
    // Handle specific error
} catch {
    // Handle other errors
    logger.error("Failed to fetch health data: \(error)")
}

// ❌ Bad
let data = try! await fetchHealthData()
```

### SwiftUI Guidelines

#### View Structure
```swift
struct HealthDashboardView: View {
    // MARK: - Properties
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var showingDetail = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                // Content
            }
            .navigationTitle("Health Dashboard")
            .sheet(isPresented: $showingDetail) {
                DetailView()
            }
        }
    }
}

// MARK: - Preview
struct HealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDashboardView()
    }
}
```

#### State Management
```swift
// ✅ Use @StateObject for view models
@StateObject private var viewModel = HealthDashboardViewModel()

// ✅ Use @State for local view state
@State private var isExpanded = false

// ✅ Use @Binding for child views
@Binding var selectedItem: HealthData?
```

### Architecture Patterns

#### MVVM Pattern
```swift
// Model
struct HealthData: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double
    let type: HealthDataType
}

// ViewModel
@MainActor
class HealthDashboardViewModel: ObservableObject {
    @Published var healthData: [HealthData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthDataManager = HealthDataManager.shared
    
    func loadHealthData() async {
        isLoading = true
        do {
            healthData = try await healthDataManager.fetchHealthData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// View
struct HealthDashboardView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    
    var body: some View {
        List(viewModel.healthData) { data in
            HealthDataRow(data: data)
        }
        .task {
            await viewModel.loadHealthData()
        }
    }
}
```

## Testing Guidelines

### Test Structure

#### Unit Tests
```swift
final class HealthDataManagerTests: XCTestCase {
    var healthDataManager: HealthDataManager!
    
    override func setUp() {
        super.setUp()
        healthDataManager = HealthDataManager()
    }
    
    override func tearDown() {
        healthDataManager = nil
        super.tearDown()
    }
    
    func testFetchHealthData_WithValidDateRange_ReturnsData() async throws {
        // Given
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400)
        
        // When
        let result = try await healthDataManager.fetchHealthData(
            startDate: startDate,
            endDate: endDate,
            dataType: .heartRate
        )
        
        // Then
        XCTAssertFalse(result.isEmpty)
    }
}
```

#### UI Tests
```swift
final class HealthDashboardUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testHealthDashboard_DisplaysHealthData() {
        // Given
        let dashboard = app.navigationBars["Health Dashboard"]
        
        // When & Then
        XCTAssertTrue(dashboard.exists)
        XCTAssertTrue(app.tables.firstMatch.exists)
    }
}
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter HealthDataManagerTests

# Run with coverage
swift test --enable-code-coverage

# Run UI tests
xcodebuild test -scheme HealthAI2030App -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage Requirements

- **Unit Tests**: Minimum 80% coverage
- **Integration Tests**: All critical paths
- **UI Tests**: All main user flows
- **Performance Tests**: Critical performance paths

## Common Tasks

### Adding a New Feature

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-feature-name
   ```

2. **Create Module Structure**
   ```
   Modules/Features/NewFeature/
   ├── Sources/
   │   ├── Models/
   │   ├── Views/
   │   ├── ViewModels/
   │   └── Services/
   └── Tests/
   ```

3. **Implement Feature**
   - Create data models
   - Implement business logic
   - Create SwiftUI views
   - Add unit tests

4. **Update Documentation**
   - Update API documentation
   - Add usage examples
   - Update README if needed

### Debugging

#### Common Debugging Techniques

```swift
// 1. Use print statements for quick debugging
print("Debug: \(variable)")

// 2. Use breakpoints in Xcode
// Set breakpoints in the debugger

// 3. Use assertions for development
assert(condition, "Debug message")

// 4. Use logging for production debugging
import os.log

let logger = Logger(subsystem: "com.healthai2030", category: "debug")
logger.debug("Debug message: \(variable)")
```

#### Performance Debugging

```swift
// Measure execution time
let start = CFAbsoluteTimeGetCurrent()
// Your code here
let end = CFAbsoluteTimeGetCurrent()
print("Execution time: \(end - start) seconds")

// Use Instruments for detailed profiling
// Xcode → Product → Profile
```

### Code Review Process

1. **Self-Review Checklist**
   - [ ] Code follows style guidelines
   - [ ] Tests are written and passing
   - [ ] Documentation is updated
   - [ ] No debugging code left in
   - [ ] Performance considerations addressed

2. **Pull Request Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Refactoring

   ## Testing
   - [ ] Unit tests added/updated
   - [ ] UI tests added/updated
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   ```

## Troubleshooting

### Common Issues

#### Build Errors

**"No such module" Error**
```bash
# Clean build folder
Xcode → Product → Clean Build Folder

# Reset package cache
swift package reset

# Reinstall dependencies
swift package resolve
```

**Code Signing Issues**
1. Check provisioning profiles in Xcode
2. Verify Apple Developer account settings
3. Clean and rebuild project

#### Runtime Errors

**HealthKit Permission Issues**
```swift
// Check HealthKit availability
guard HKHealthStore.isHealthDataAvailable() else {
    // Handle HealthKit not available
    return
}

// Request permissions
try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
```

**Core Data Issues**
```swift
// Check Core Data stack initialization
guard let container = try? ModelContainer(for: HealthData.self) else {
    // Handle Core Data initialization failure
    return
}
```

#### Performance Issues

**Memory Leaks**
- Use Instruments to identify leaks
- Check for retain cycles in closures
- Ensure proper weak references

**Slow UI**
- Profile with Instruments
- Check for expensive operations on main thread
- Use background queues for heavy operations

### Getting Help

1. **Check Documentation**
   - [API Documentation](APIDocumentation.md)
   - [Architecture Guide](architecture.md)
   - [Troubleshooting Guide](troubleshooting.md)

2. **Search Issues**
   - Check existing GitHub issues
   - Search for similar problems

3. **Ask for Help**
   - Create a new issue with detailed information
   - Join our Slack channel
   - Contact the team

## Resources

### Documentation
- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit/)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata/)

### Tools
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Code formatting
- [Instruments](https://developer.apple.com/documentation/xcode/instruments) - Performance profiling

### Community
- [Swift Forums](https://forums.swift.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/swift)
- [GitHub Discussions](https://github.com/healthai-2030/HealthAI-2030/discussions)

### Internal Resources
- [Project Wiki](../../wiki)
- [Team Slack](https://healthai2030.slack.com)
- [Design System](https://figma.com/file/healthai2030-design-system)

---

## Next Steps

1. **Explore the Codebase**
   - Start with `Apps/MainApp/Views/` to understand the UI
   - Review `Frameworks/HealthAI2030Core/` for core functionality
   - Check `Modules/` for feature implementations

2. **Pick a First Issue**
   - Look for issues labeled "good first issue"
   - Start with documentation or simple bug fixes
   - Ask for guidance if needed

3. **Join the Community**
   - Introduce yourself in GitHub Discussions
   - Join our Slack channel
   - Follow our development blog

4. **Contribute**
   - Submit your first pull request
   - Help review other contributions
   - Share your knowledge with the team

**Welcome to the HealthAI 2030 team! 🎉**

We're excited to have you on board and can't wait to see what you'll build with us.

---

*Last updated: December 2024*
*Version: 1.0* 