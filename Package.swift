// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HealthAI2030",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "HealthAI2030",
            targets: ["HealthAI2030"]
        ),
    ],
    dependencies: [],
    targets: [
        // Main app target
        .target(
            name: "HealthAI2030",
            dependencies: [
                .product(name: "SwiftData", package: "swift-data"),
                "SleepTracking"
            ],
            path: "Source",
            exclude: ["Info.plist"],
            sources: ["App", "Shared"]
        ),
        
        // Sleep Tracking module
        .target(
            name: "SleepTracking",
            dependencies: [
                .product(name: "SwiftData", package: "swift-data"),
                .product(name: "OSLog", package: "swift-log")
            ],
            path: "Modules/Features/SleepTracking/Sources"
        ),
        
        // Tests
        .testTarget(
            name: "SleepTrackingTests",
            dependencies: ["SleepTracking"],
            path: "Modules/Features/SleepTracking/Tests"
        ),
        
        .testTarget(
            name: "HealthAI2030Tests",
            dependencies: ["HealthAI2030"],
            path: "Tests"
        )
    ]
)