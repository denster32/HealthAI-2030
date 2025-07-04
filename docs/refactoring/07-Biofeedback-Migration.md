# Biofeedback Feature Migration Plan

This document outlines the detailed plan for migrating the existing "Biofeedback" feature from the `Packages/Biofeedback/` directory to the new feature-based architecture at `Modules/Features/Biofeedback/`. This migration follows the established pattern for refactoring features within the `HealthAI 2030` codebase.

## 1. Current State Analysis

The "Biofeedback" feature is currently located under `Packages/Biofeedback/`. It is assumed to contain the primary source files `Biofeedback.swift` and `BiofeedbackEngine.swift` within `Packages/Biofeedback/Sources/Biofeedback/`. The current integration method into the main application will be identified during the integration phase, likely through direct file inclusion or an implicit Swift Package Manager dependency not explicitly listed in the root `Package.swift`.

## 2. Migration Phases

The migration will be executed in three distinct phases: Module Creation, Code Removal, and Integration.

### Phase 1: Module Creation

This phase focuses on establishing the new `Modules/Features/Biofeedback/` package and relocating the core source files.

#### Steps:

1.  **Create New Directory Structure:**
    *   Create the base directory for the new Biofeedback feature module: `Modules/Features/Biofeedback/`
    *   Within this, create the standard Swift Package Manager source directory structure: `Modules/Features/Biofeedback/Sources/Biofeedback/`
    *   Create the test directory structure: `Modules/Features/Biofeedback/Tests/BiofeedbackTests/`

2.  **Move Source Files:**
    *   Move `Packages/Biofeedback/Sources/Biofeedback/Biofeedback.swift` to `Modules/Features/Biofeedback/Sources/Biofeedback/Biofeedback.swift`
    *   Move `Packages/Biofeedback/Sources/Biofeedback/BiofeedbackEngine.swift` to `Modules/Features/Biofeedback/Sources/Biofeedback/BiofeedbackEngine.swift`

3.  **Create New `Package.swift`:**
    *   Create a new `Package.swift` file at `Modules/Features/Biofeedback/Package.swift`. This file will define the `Biofeedback` module as a standalone Swift package.
    *   The `Package.swift` will declare the `Biofeedback` library product and its target, specifying any necessary dependencies (e.g., `HealthAI 2030` if it depends on core application components, or other `Managers` packages).
    *   An example structure for the new `Package.swift` would be:

        ```swift
        // swift-tools-version:6.2
        import PackageDescription

        let package = Package(
            name: "Biofeedback",
            platforms: [
                .iOS(.v18)
            ],
            products: [
                .library(
                    name: "Biofeedback",
                    targets: ["Biofeedback"]),
            ],
            dependencies: [
                // Add any dependencies specific to Biofeedback here, e.g.,
                // .package(path: "../../Managers"),
                // .package(path: "../../../HealthAI 2030")
            ],
            targets: [
                .target(
                    name: "Biofeedback",
                    dependencies: [
                        // Add product dependencies here
                    ],
                    path: "Sources/Biofeedback"
                ),
                .testTarget(
                    name: "BiofeedbackTests",
                    dependencies: ["Biofeedback"],
                    path: "Tests/BiofeedbackTests"
                ),
            ]
        )
        ```

### Phase 2: Code Removal

This phase involves the systematic deletion of the old package structure.

#### Steps:

1.  **Delete Old Package Directory:**
    *   Remove the entire `Packages/Biofeedback/` directory, including all its subdirectories and files. This ensures no remnants of the old structure remain.

### Phase 3: Integration

This phase focuses on updating the main application to correctly reference the new `Biofeedback` module and ensuring all existing usages are updated.

#### Steps:

1.  **Update Root `Package.swift`:**
    *   Open the root `Package.swift` file.
    *   **Remove Old Dependency:** If `Packages/Biofeedback` was explicitly listed as a dependency (which it currently does not appear to be, based on initial analysis, but this step is included for completeness), remove its entry from the `dependencies` array.
    *   **Add New Dependency:** Add the new `Modules/Features/Biofeedback` package as a local dependency:
        ```swift
        .package(path: "Modules/Features/Biofeedback"),
        ```
    *   **Update Target Dependencies:** In the `HealthAI 2030` target's `dependencies` array, replace any reference to the old `Biofeedback` product with the new one:
        ```swift
        .product(name: "Biofeedback", package: "Biofeedback")
        ```

2.  **Update Application Code References:**
    *   **Identify Usage:** Perform a comprehensive search across the entire `HealthAI 2030` project for all occurrences of `import Biofeedback`.
    *   **Update Import Statements:** Change all `import Biofeedback` statements to `import Biofeedback` (the module name remains the same, but the underlying package path changes).
    *   **Update Type References:** Identify and update any fully qualified type references (e.g., `Packages.Biofeedback.SomeType` if such existed) to simply `Biofeedback.SomeType` or just `SomeType` if the module is imported.
    *   **Key Areas to Check:**
        *   `HealthAI 2030/App/` (e.g., `AIHealthCoach.swift`, `AppDelegate.swift`, `SceneDelegate.swift`)
        *   `HealthAI 2030/Managers/` (e.g., `HealthDataManager.swift` or any other manager interacting with Biofeedback data/logic)
        *   `HealthAI 2030/Views/` (any views that display or interact with Biofeedback UI or data)
        *   `HealthAI 2030/CopilotSkills/` (if any Copilot skills integrate with Biofeedback)
        *   Any other files that might directly or indirectly depend on the `Biofeedback` package.

## 3. Verification

After completing the migration steps, a thorough verification process will be undertaken to ensure the Biofeedback feature functions correctly within the new architecture. This includes:

*   Building the project to confirm no compilation errors.
*   Running existing unit and UI tests related to Biofeedback.
*   Manual testing of the Biofeedback feature within the application.

## 4. Diagram

```mermaid
graph TD
    A[Start Migration] --> B{Phase 1: Module Creation};
    B --> C[Create Modules/Features/Biofeedback/ Structure];
    C --> D[Move Biofeedback.swift & BiofeedbackEngine.swift];
    D --> E[Create Modules/Features/Biofeedback/Package.swift];
    E --> F{Phase 2: Code Removal};
    F --> G[Delete Packages/Biofeedback/ Directory];
    G --> H{Phase 3: Integration};
    H --> I[Update Root Package.swift];
    I --> J[Update Application Code References (import Biofeedback)];
    J --> K[End Migration];
```

## 5. Next Steps

Upon approval of this plan, the implementation phase will commence.