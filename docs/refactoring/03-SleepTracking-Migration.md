# Migration Plan: Sleep Tracking Feature

This document outlines the plan to migrate the "Sleep Tracking" feature into its own Swift package, `SleepTracking`. This refactoring will improve modularity, testability, and maintainability.

## Phase 1: Module Creation

The first phase is to create the new `SleepTracking` module and its internal structure.

### 1.1. Create Module Directory and `Package.swift`

Create the following directory structure:

```
Modules/Features/SleepTracking/
├── Package.swift
└── Sources/
    └── SleepTracking/
```

The `Package.swift` file will define the new module:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SleepTracking",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SleepTracking",
            targets: ["SleepTracking"]),
    ],
    dependencies: [
        .package(path: "../../../Packages/Models"),
        .package(path: "../../../Packages/Managers"),
        .package(path: "../../../Packages/Analytics"),
        .package(path: "../../../Packages/ML"),
        .package(path: "../../../Packages/Utilities"),
    ],
    targets: [
        .target(
            name: "SleepTracking",
            dependencies: [
                "Models",
                "Managers",
                "Analytics",
                "ML",
                "Utilities"
            ]
        ),
        .testTarget(
            name: "SleepTrackingTests",
            dependencies: ["SleepTracking"]),
    ]
)
```

### 1.2. Create Public Interfaces

The `SleepTracking` module will expose a public interface for other modules to interact with. This will include:

*   A public `SleepTrackingFactory` to create views and services.
*   Public views for the sleep summary widget and sleep optimization.
*   Public data models for sleep data.

### 1.3. Move Existing Code

The following files will be moved into the `SleepTracking` module:

**Managers:**

*   `Packages/Managers/Sources/Managers/SleepManager.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Managers/SleepManager.swift`
*   `Packages/Managers/Sources/Managers/SleepOptimizationManager.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Managers/SleepOptimizationManager.swift`

**Views:**

*   `HealthAI2030Widgets/SleepSummaryWidget.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Views/SleepSummaryWidget.swift`
*   `HealthAI 2030/Views/SleepArchitectureCard.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Views/SleepArchitectureCard.swift`
*   `HealthAI 2030 tvOS/Views/SleepOptimizationView.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Views/SleepOptimizationView.swift`
*   `HealthAI 2030 WatchKit App/SleepSessionView.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Views/SleepSessionView.swift`

**Models:**

*   `Packages/Models/Sources/Models/SleepSession.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Models/SleepSession.swift`
*   `Packages/Models/Sources/Models/SleepFeatures.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Models/SleepFeatures.swift`
*   `Packages/Models/Sources/Models/SleepMetrics.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Models/SleepMetrics.swift`
*   `Packages/Models/Sources/Models/SleepOptimization.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Models/SleepOptimization.swift`
*   `Packages/Models/Sources/Models/SleepStage.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Models/SleepStage.swift`

**Analytics:**

*   `Packages/Analytics/Sources/Analytics/AdvancedSleepAnalytics.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Analytics/AdvancedSleepAnalytics.swift`
*   `Packages/Analytics/Sources/Analytics/SleepAnalyticsEngine.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Analytics/SleepAnalyticsEngine.swift`
*   `Packages/Analytics/Sources/Analytics/SleepPatternAnalyzer.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/Analytics/SleepPatternAnalyzer.swift`

**ML:**

*   `Packages/ML/Sources/ML/SleepStageClassifier.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/ML/SleepStageClassifier.swift`
*   `Packages/ML/Sources/ML/SleepFeatureExtractor.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/ML/SleepFeatureExtractor.swift`
*   `Packages/ML/Sources/ML/CircadianRhythmAnalyzer.swift` -> `Modules/Features/SleepTracking/Sources/SleepTracking/ML/CircadianRhythmAnalyzer.swift`

**Tests:**

*   `HealthAI 2030Tests/SleepOptimizationTests.swift` -> `Modules/Features/SleepTracking/Tests/SleepTrackingTests/SleepOptimizationTests.swift`

## Phase 2: Code Removal

After moving the code to the new module, the old files will be removed from the project. This will be done using a series of `diffs`.

### 2.1. Remove Old Files

The following files will be removed:

*   `Packages/Managers/Sources/Managers/SleepManager.swift`
*   `Packages/Managers/Sources/Managers/SleepOptimizationManager.swift`
*   `HealthAI2030Widgets/SleepSummaryWidget.swift`
*   `HealthAI 2030/Views/SleepArchitectureCard.swift`
*   `HealthAI 2030 tvOS/Views/SleepOptimizationView.swift`
*   `HealthAI 2030 WatchKit App/SleepSessionView.swift`
*   `Packages/Models/Sources/Models/SleepSession.swift`
*   `Packages/Models/Sources/Models/SleepFeatures.swift`
*   `Packages/Models/Sources/Models/SleepMetrics.swift`
*   `Packages/Models/Sources/Models/SleepOptimization.swift`
*   `Packages/Models/Sources/Models/SleepStage.swift`
*   `Packages/Analytics/Sources/Analytics/AdvancedSleepAnalytics.swift`
*   `Packages/Analytics/Sources/Analytics/SleepAnalyticsEngine.swift`
*   `Packages/Analytics/Sources/Analytics/SleepPatternAnalyzer.swift`
*   `Packages/ML/Sources/ML/SleepStageClassifier.swift`
*   `Packages/ML/Sources/ML/SleepFeatureExtractor.swift`
*   `Packages/ML/Sources/ML/CircadianRhythmAnalyzer.swift`
*   `HealthAI 2030Tests/SleepOptimizationTests.swift`

### 2.2. Update Project Files

The `HealthAI 2030.xcodeproj/project.pbxproj` file will be updated to remove references to the old files.

## Phase 3: Integration

The final phase is to integrate the new `SleepTracking` module into the main application.

### 3.1. Update `Package.swift`

The root `Package.swift` file will be updated to include the new `SleepTracking` module as a dependency for the main app, widgets, and other relevant targets.

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "HealthAI-2030",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v12),
        .tvOS(.v15)
    ],
    products: [
        .executable(
            name: "HealthAI 2030",
            targets: ["HealthAI 2030"]),
    ],
    dependencies: [
        .package(path: "Modules/Features/LogWaterIntake"),
        .package(path: "Modules/Features/StartMeditation"),
        .package(path: "Modules/Features/SleepTracking"), // Add this line
        .package(path: "Packages/Analytics"),
        .package(path: "Packages/Managers"),
        .package(path: "Packages/Models"),
        .package(path: "Packages/ML"),
        .package(path: "Packages/Utilities"),
    ],
    targets: [
        .executableTarget(
            name: "HealthAI 2030",
            dependencies: [
                "LogWaterIntake",
                "StartMeditation",
                "SleepTracking", // Add this line
                "Analytics",
                "Managers",
                "Models",
                "ML",
                "Utilities"
            ]
        ),
        // ... other targets
    ]
)
```

### 3.2. Update App Code

The main app code will be updated to use the new `SleepTracking` module. This will involve:

*   Importing the `SleepTracking` module.
*   Using the `SleepTrackingFactory` to create views and services.
*   Updating any code that directly referenced the old sleep-related files.

This migration will be a significant undertaking, but it will result in a more modular and maintainable codebase.