# Refactoring Plan: LogWaterIntake Feature Migration

This document outlines the step-by-step process for migrating the "Log Water Intake" functionality into a self-contained feature module as part of the new "Feature-First" architecture.

## Phase 1: Create the New Feature Module

### Step 1.1: Create Module Directory and `Package.swift`

A new Swift Package will be created at `Modules/Features/LogWaterIntake/`.

**Action:** Create file `Modules/Features/LogWaterIntake/Package.swift` with the following content:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LogWaterIntake",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "LogWaterIntake",
            targets: ["LogWaterIntake"]),
    ],
    dependencies: [
        // Add dependencies to other Core/Kit modules here later
    ],
    targets: [
        .target(
            name: "LogWaterIntake",
            dependencies: []),
        .testTarget(
            name: "LogWaterIntakeTests",
            dependencies: ["LogWaterIntake"]),
    ]
)
```

### Step 1.2: Create the Source File for Feature Logic

The core logic for the feature will be consolidated into a single new file.

**Action:** Create file `Modules/Features/LogWaterIntake/Sources/LogWaterIntake/LogWaterIntake.swift` with the following content:

```swift
import Foundation
import HealthKit
import AppIntents

// MARK: - Core Logging Logic

public class WaterIntakeLogger {
    private let healthStore: HKHealthStore

    public init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    public func logWaterIntake(amountInMilliliters: Double) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            // In a real app, throw a specific error here
            print("HealthKit is not available.")
            return
        }

        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amountInMilliliters)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())

        try await healthStore.save(waterSample)
    }
}

// MARK: - App Intent

@available(iOS 18.0, *)
public struct LogWaterIntakeAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log Water Intake"
    public static var description = IntentDescription("Logs a specified amount of water intake.")

    @Parameter(title: "Amount", description: "The amount of water in milliliters.")
    public var amount: Double

    public init() {}

    public init(amount: Double) {
        self.amount = amount
    }

    public func perform() async throws -> some IntentResult & ProvidesStringResult {
        let logger = WaterIntakeLogger()
        try await logger.logWaterIntake(amountInMilliliters: amount)
        let result = "Logged \(Int(amount)) ml of water intake."
        return .result(value: result)
    }
}
```

## Phase 2: Refactor Existing Codebase

### Step 2.1: Remove Logic from `HealthDataManager`

The old water logging function will be removed.

**Action:** In `Packages/Managers/Sources/Managers/HealthDataManager.swift`, remove the entire `logWaterIntake` function.

```diff
--- a/Packages/Managers/Sources/Managers/HealthDataManager.swift
+++ b/Packages/Managers/Sources/Managers/HealthDataManager.swift
@@ -852,19 +852,4 @@
         }
     }
 
-    func logWaterIntake(amount: Double) {
-        guard isAuthorized else {
-            print("HealthDataManager: Not authorized to log water intake.")
-            return
-        }
-
-        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
-            print("HealthDataManager: Dietary Water type not available.")
-            return
-        }
-
-        let waterQuantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: amount)
-        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())
-
-        healthStore.save(waterSample) { success, error in
-            if success {
-                print("HealthDataManager: Successfully logged \(amount) ml of water intake.")
-            } else if let error = error {
-                print("HealthDataManager: Failed to log water intake: \(error.localizedDescription)")
-            }
-        }
-    }
 }
```

### Step 2.2: Remove Logic from `AppIntents.swift`

The old App Intent definition will be removed.

**Action:** In `HealthAI 2030/Shortcuts/AppIntents.swift`, remove the `LogWaterIntakeAppIntent` struct and its corresponding `AppShortcut` definition.

### Step 2.3: Update Project Dependencies

The main project needs to be aware of the new local module.

**Action:** Modify the root `Package.swift` to add the new module as a local dependency and add it to the main application target.

```diff
--- a/Package.swift
+++ b/Package.swift
@@ -XX,XX +XX,XX @@
     ],
     targets: [
         .target(
-            name: "HealthAI 2030",
+            name: "HealthAI2030",
             dependencies: [
                 .product(name: "Analytics", package: "Analytics"),
                 .product(name: "Managers", package: "Managers"),
+                .product(name: "LogWaterIntake", package: "LogWaterIntake")
             ],
             // ... other settings
         ),
+        .package(path: "Modules/Features/LogWaterIntake"),
         // ... other targets
     ]
 )
```
(Note: The exact changes to the root `Package.swift` will depend on its current structure, but the principle is to add the local package and link the library.)

## Phase 3: Verification

After the changes are applied, the project should be built to ensure that:
1.  The new module compiles successfully.
2.  The main application compiles successfully with the new dependency.
3.  The old references to `logWaterIntake` and `LogWaterIntakeAppIntent` are flagged as errors, and can then be updated to use the new module.

---

Please review this detailed plan. Once you approve it, I will request to switch to the "Code" mode to begin the implementation.