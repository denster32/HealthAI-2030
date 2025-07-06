## Analytics Package Migration Plan

**Context:**
This document outlines the plan for migrating the existing "Analytics" functionality within the `HealthAI 2030` codebase to a new feature-first architecture. The current analytics components are distributed, and this migration aims to consolidate them into a dedicated Swift Package Manager (SPM) module at `Modules/Kit/Analytics/`.

**Scope of "Analytics" Package for Migration:**
Based on analysis, the core components identified for this migration are:
*   `HealthAI 2030/AnalyticsEngine.swift`
*   The `AnalyticsInsight` class within `HealthAI 2030/Models/CloudKitSyncModels.swift`
*   `HealthAI 2030/Managers/MetricManager.swift`

**Migration Plan:**

### Phase 1: Module Creation

This phase involves setting up the new module structure and moving the identified source files into it.

1.  **Create New Directory Structure:**
    *   Create the base directory for the new module: `Modules/Kit/Analytics/`
    *   Inside `Modules/Kit/Analytics/`, create the standard SPM source and test directories:
        *   `Modules/Kit/Analytics/Sources/Analytics/`
        *   `Modules/Kit/Analytics/Tests/AnalyticsTests/`

2.  **Create `Package.swift` for the new module:**
    *   Create a `Package.swift` file at `Modules/Kit/Analytics/Package.swift` with the following content:

    ```swift
    // swift-tools-version:6.2
    import PackageDescription

    let package = Package(
        name: "Analytics",
        platforms: [
            .iOS(.v18),
            .macOS(.v15),
            .watchOS(.v11),
            .tvOS(.v18)
        ],
        products: [
            .library(
                name: "Analytics",
                targets: ["Analytics"]),
        ],
        dependencies: [
            // Add any dependencies required by AnalyticsEngine, AnalyticsInsight, MetricManager
            // For example, if AnalyticsInsight depends on SwiftData or CloudKit, those might be external dependencies.
            // Based on current files, Foundation, Combine, SwiftData, CloudKit, MetricKit, OSLog are used.
            // SwiftData and CloudKit are system frameworks, so no explicit SPM dependency needed unless
            // they are wrapped in a separate local package.
        ],
        targets: [
            .target(
                name: "Analytics",
                dependencies: []), // Add dependencies if any
            .testTarget(
                name: "AnalyticsTests",
                dependencies: ["Analytics"]),
        ]
    )
    ```

3.  **Move Source Files:**
    *   Move `HealthAI 2030/AnalyticsEngine.swift` to `Modules/Kit/Analytics/Sources/Analytics/AnalyticsEngine.swift`.
    *   Move `HealthAI 2030/Managers/MetricManager.swift` to `Modules/Kit/Analytics/Sources/Analytics/MetricManager.swift`.
    *   **Refactor `AnalyticsInsight`:** The `AnalyticsInsight` class is currently part of `HealthAI 2030/Models/CloudKitSyncModels.swift`. To properly modularize, `AnalyticsInsight` should be extracted into its own file within the new `Analytics` module.
        *   Create a new file: `Modules/Kit/Analytics/Sources/Analytics/AnalyticsInsight.swift`.
        *   Move the `AnalyticsInsight` class definition (lines 103-134) and its `CKSyncable` extension (lines 296-342) from `HealthAI 2030/Models/CloudKitSyncModels.swift` to the new `AnalyticsInsight.swift` file.
        *   Ensure necessary imports (`Foundation`, `SwiftData`, `CloudKit`) are present in `AnalyticsInsight.swift`.
        *   Update `HealthAI 2030/Models/CloudKitSyncModels.swift` to remove the `AnalyticsInsight` definition.

### Phase 2: Code Removal

This phase focuses on cleaning up the old directory structure.

1.  **Delete Old Files:**
    *   Delete the original `HealthAI 2030/AnalyticsEngine.swift` file.
    *   Delete the original `HealthAI 2030/Managers/MetricManager.swift` file.
    *   Ensure `AnalyticsInsight` is removed from `HealthAI 2030/Models/CloudKitSyncModels.swift` after its migration.

### Phase 3: Integration

This phase involves updating the root `Package.swift` and all references within the application.

1.  **Update Root `Package.swift`:**
    *   Open the root `Package.swift` file.
    *   **Add New Package Dependency:** Add a new local package dependency for the `Analytics` module:
        ```swift
        .package(path: "Modules/Kit/Analytics"),
        ```
    *   **Add New Product Dependency:** Add the `Analytics` product to the `HealthAI 2030` target's dependencies:
        ```swift
        .product(name: "Analytics", package: "Analytics"),
        ```
    *   **Remove Old References (if any):** If `AnalyticsEngine` or `MetricManager` were previously referenced as direct source files in the `HealthAI 2030` target's `path` or `sources` array (which they are not, as they are currently just files within the main app bundle), those references would need to be removed. In this case, they are not explicitly listed as targets, so no removal is needed here.

2.  **Identify and Update References in the Application:**
    *   Perform a project-wide search for imports and usages of `AnalyticsEngine`, `PredictiveAnalyticsManager`, `AdvancedSleepAnalytics`, `MacAnalyticsEngine`, `AnalyticsInsight`, and `MetricManager`.
    *   **Update Imports:** Change `import HealthAI_2030` (if it was implicitly providing access to these types) or direct references to `AnalyticsEngine`, `MetricManager`, `AnalyticsInsight` to `import Analytics` in all relevant Swift files.
    *   **Update Instantiations/Usages:**
        *   Anywhere `AnalyticsEngine.shared` is used, ensure it now correctly references the type from the new `Analytics` module.
        *   Anywhere `AnalyticsInsight` is used (e.g., in `CloudKitSyncModels.swift` for `MLModelUpdate`, `ExportRequest`, or in various `View` files), ensure it correctly references the type from the new `Analytics` module.
        *   Anywhere `MetricManager.shared` is used, ensure it correctly references the type from the new `Analytics` module.
        *   For other analytics-related managers (e.g., `PredictiveAnalyticsManager`, `AdvancedSleepAnalytics`, `MacAnalyticsEngine`), analyze their dependencies. If they directly depend on `AnalyticsEngine`, `AnalyticsInsight`, or `MetricManager`, ensure their imports and usages are updated to reflect the new module structure. These managers themselves might become part of the `Analytics` module or depend on it.

**Verification:**
After the migration steps are completed, a thorough verification process will be necessary:
*   Build the project to ensure no compilation errors.
*   Run all existing unit and UI tests to confirm functionality.
*   Manually test features that rely on analytics (e.g., `AnalyticsView`, `AdvancedAnalyticsDashboardView`, `CrossDeviceSyncView`, `HealthAlertsView`, `DashboardView`, `MainTabView`, `SleepCoachingView`, macOS and tvOS analytics dashboards) to ensure data processing and display are correct.

**Next Steps:**
Once this plan is reviewed and approved, I will switch to "Code" mode to begin the implementation.