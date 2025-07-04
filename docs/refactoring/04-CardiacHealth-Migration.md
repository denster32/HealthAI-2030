# Migration Plan: Cardiac Health Feature

This document outlines the step-by-step plan to migrate the "Cardiac Health" feature into its own Swift package.

## Phase 1: Module Creation

We will create a new Swift package at `Modules/Features/CardiacHealth`. This package will encapsulate all cardiac-related functionality.

### 1.1. Create `Package.swift`

A new `Package.swift` file will be created in `Modules/Features/CardiacHealth/` to define the module.

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CardiacHealth",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CardiacHealth",
            targets: ["CardiacHealth"]),
    ],
    dependencies: [
        .package(path: "../../../Packages/Models"),
        .package(path: "../../../Packages/Analytics"),
        .package(path: "../../../Packages/Utilities"),
    ],
    targets: [
        .target(
            name: "CardiacHealth",
            dependencies: ["Models", "Analytics", "Utilities"]),
        .testTarget(
            name: "CardiacHealthTests",
            dependencies: ["CardiacHealth"]),
    ]
)
```

### 1.2. Create Source Directories

The following directory structure will be created:

```
Modules/Features/CardiacHealth/
├── Sources/
│   └── CardiacHealth/
│       ├── Managers/
│       │   ├── AdvancedCardiacManager.swift
│       │   ├── CardiacEmergencyHandler.swift
│       │   └── ECGInsightManager.swift
│       ├── Models/
│       │   └── CardiacModels.swift
│       └── Views/
│           └── CardiacHealthDashboard.swift
└── Tests/
    └── CardiacHealthTests/
        └── CardiacHealthTests.swift
```

## Phase 2: Code Removal

The following files, now redundant, will be removed from their original locations in `Packages/Managers/Sources/Managers/`.

*   `AdvancedCardiacManager.swift`
*   `CardiacEmergencyHandler.swift`
*   `ECGInsightManager.swift`

We will also remove the `CardiacHealthAnalyzer.swift` file from `Packages/Analytics/Sources/Analytics/`. Its functionality will be moved into the new module.

## Phase 3: Integration

Finally, we will integrate the new `CardiacHealth` module into the main project by updating the root `Package.swift`.

### 3.1. Update Root `Package.swift`

The root `Package.swift` will be modified to include the new `CardiacHealth` module as a dependency for the main application target.

```swift
// ... existing package definition
    dependencies: [
        // ... other dependencies
        .package(path: "Modules/Features/CardiacHealth"),
    ],
    targets: [
        .target(
            name: "HealthAI 2030",
            dependencies: [
                // ... other dependencies
                "CardiacHealth",
            ]
        ),
        // ... other targets
    ]
// ... rest of package definition
```

This plan ensures a clean separation of concerns and improves the project's modularity.