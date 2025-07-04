# SmartHome Feature Migration Plan

This document outlines the step-by-step plan to migrate the `SmartHome` package into the new feature-based architecture.

## Phase 1: Module Creation

1.  **Create New Directory:** Create a new directory at `Modules/Features/SmartHome/`.
2.  **Move Source Files:** Move the contents of `Packages/SmartHome/Sources/SmartHome/` to `Modules/Features/SmartHome/Sources/SmartHome/`.
3.  **Move Test Files:** Move the contents of `Packages/SmartHome/Tests/SmartHomeTests/` to `Modules/Features/SmartHome/Tests/SmartHomeTests/`.
4.  **Create `Package.swift`:** Create a new `Package.swift` file inside `Modules/Features/SmartHome/`. The content of this file should be similar to the existing `Package.swift` in `Packages/SmartHome/`, but updated to reflect the new location.

    ```swift
    // swift-tools-version: 6.2
    // The swift-tools-version declares the minimum version of Swift required to build this package.

    import PackageDescription

    let package = Package(
        name: "SmartHome",
        platforms: [
            .iOS(.v15),
            .macOS(.v12),
            .watchOS(.v8),
            .tvOS(.v15)
        ],
        products: [
            // Products define the executables and libraries a package produces, making them visible to other packages.
            .library(
                name: "SmartHome",
                targets: ["SmartHome"]
            ),
        ],
        targets: [
            // Targets are the basic building blocks of a package, defining a module or a test suite.
            // Targets can depend on other targets in this package and products from dependencies.
            .target(
                name: "SmartHome"
            ),
            .testTarget(
                name: "SmartHomeTests",
                dependencies: ["SmartHome"]
            ),
        ]
    )
    ```

## Phase 2: Code Removal

1.  **Delete Old Package:** Once the new module is created and integrated, delete the entire `Packages/SmartHome/` directory.

## Phase 3: Integration

1.  **Update Root `Package.swift`:** Modify the root `Package.swift` file to remove the dependency on the old `Packages/SmartHome` package and add the new one.

    *   **Remove Old Dependency:** In the `dependencies` array of the root `Package.swift`, remove the line that points to the old `SmartHome` package. It will look something like this:

        ```swift
        // an example of what to remove
        .package(path: "Packages/SmartHome"),
        ```

    *   **Add New Dependency:** Add a new entry to the `dependencies` array to point to the new `SmartHome` feature module:

        ```swift
        .package(path: "Modules/Features/SmartHome"),
        ```

    *   **Update Target Dependencies:** In the `targets` section of the root `Package.swift`, find any target that had `"SmartHome"` as a dependency and ensure it still correctly references the module. The name of the product is the same, so the change should be minimal, but it's important to verify.

2.  **Resolve Packages:** After updating the `Package.swift` file, run `swift package resolve` to update the package dependencies.

## Verification

After completing the migration, build and run the project to ensure that all features that depend on the `SmartHome` module are still working correctly. Run the tests for the `SmartHome` module to verify that they all pass.