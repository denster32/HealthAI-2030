# Mental Health Feature Migration Plan

This document outlines the steps to migrate the "Mental Health" feature to its own Swift Package module.

## Phase 1: Module Creation

1.  **Create the directory structure for the new module:**
    ```bash
    mkdir -p Modules/Features/MentalHealth/Sources/MentalHealth/Views
    mkdir -p Modules/Features/MentalHealth/Sources/MentalHealth/Managers
    mkdir -p Modules/Features/MentalHealth/Sources/MentalHealth/Models
    mkdir -p Modules/Features/MentalHealth/Sources/MentalHealth/Shortcuts
    mkdir -p Modules/Features/MentalHealth/Tests/MentalHealthTests
    ```

2.  **Create the `Package.swift` for the new module:**
    Create a new file at `Modules/Features/MentalHealth/Package.swift` with the following content:

    ```swift
    // swift-tools-version:5.9
    import PackageDescription

    let package = Package(
        name: "MentalHealth",
        platforms: [
            .iOS(.v16),
            .macOS(.v13),
            .watchOS(.v9)
        ],
        products: [
            .library(
                name: "MentalHealth",
                targets: ["MentalHealth"]),
        ],
        dependencies: [
            .package(path: "../../../Packages/Analytics"),
            .package(path: "../../../Packages/Utilities"),
            .package(path: "../../../Packages/Models"),
        ],
        targets: [
            .target(
                name: "MentalHealth",
                dependencies: [
                    "Analytics",
                    "Utilities",
                    "Models"
                ],
                path: "Sources/MentalHealth"
            ),
            .testTarget(
                name: "MentalHealthTests",
                dependencies: ["MentalHealth"],
                path: "Tests/MentalHealthTests"
            ),
        ]
    )
    ```

3.  **Move the core files to the new module:**
    -   Move `Packages/Managers/Sources/Managers/MentalHealthManager.swift` to `Modules/Features/MentalHealth/Sources/MentalHealth/Managers/MentalHealthManager.swift`.
    -   Move `HealthAI 2030/Views/MentalHealthDashboardView.swift` to `Modules/Features/MentalHealth/Sources/MentalHealth/Views/MentalHealthDashboardView.swift`.
    -   Move the `MentalHealthWidget` related structs from `HealthAI 2030/Views/Widgets.swift` to a new file at `Modules/Features/MentalHealth/Sources/MentalHealth/Views/MentalHealthWidget.swift`.
    -   Move `GetMentalHealthInsightsAppIntent` from `HealthAI 2030/Shortcuts/AppIntents.swift` to `Modules/Features/MentalHealth/Sources/MentalHealth/Shortcuts/AppIntents.swift`.
    -   The models `MentalHealthContext`, `MentalHealthInsight`, etc. are inside `MentalHealthManager.swift`. They should be extracted to their own file `Modules/Features/MentalHealth/Sources/MentalHealth/Models/MentalHealthModels.swift`.

## Phase 2: Code Removal and Refactoring

This phase involves removing the old code and adjusting the remaining code to use the new module.

1.  **`Packages/Managers/Sources/Managers/MentalHealthManager.swift`:**
    -   This file will be moved, so it should be deleted from its original location.

2.  **`HealthAI 2030/Views/MentalHealthDashboardView.swift`:**
    -   This file will be moved, so it should be deleted from its original location.

3.  **`HealthAI 2030/Views/Widgets.swift`:**
    -   Remove the `MentalHealthWidget`, `MentalHealthTimelineProvider`, `MentalHealthEntry`, `MentalHealthWidgetView`, `MentalHealthSmallView`, and `MentalHealthMediumView` structs.
    -   The `AllWidgets` struct will need to be updated to import `MentalHealth` and reference `MentalHealthWidget()`.

4.  **`HealthAI 2030/Shortcuts/AppIntents.swift`:**
    -   Remove the `GetMentalHealthInsightsAppIntent` struct.
    -   The `AppShortcuts` provider will need to be updated to import `MentalHealth` and include the intent from the new module.

5.  **Update consumers of `MentalHealthManager`:**
    -   Files like `HealthAI 2030/Views/MainTabView.swift`, `HealthAI 2030/HealthAI_2030App.swift`, `Packages/Utilities/Sources/Utilities/SystemIntelligenceManager.swift`, etc., will need to be updated to import `MentalHealth` to access `MentalHealthManager`.

    Example diff for `HealthAI 2030/Views/MainTabView.swift`:
    ```diff
    --- a/HealthAI 2030/Views/MainTabView.swift
    +++ b/HealthAI 2030/Views/MainTabView.swift
    @@ -1,5 +1,6 @@
     import SwiftUI
     import CardiacHealth
    +import MentalHealth
     
     struct MainTabView: View {
         @StateObject private var sceneState = SceneState()
    ```

## Phase 3: Integration

1.  **Update `Package.swift` at the root of the project:**
    -   Add the new `MentalHealth` module to the dependencies of the `HealthAI 2030` target.

    ```swift
    // ... in root Package.swift
    .package(path: "Modules/Features/MentalHealth"),
    // ...
    
    // ... in the main target dependencies
    .product(name: "MentalHealth", package: "MentalHealth"),
    // ...
    ```

This plan provides a clear path to modularizing the Mental Health feature, improving code organization and separation of concerns.