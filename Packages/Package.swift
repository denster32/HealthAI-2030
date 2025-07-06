// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HealthAI2030",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "HealthAI2030",
            targets: ["HealthAI2030"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.34.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0"),
        .package(path: "Packages/HealthAI2030Core"),
        .package(path: "Packages/HealthAI2030UI"),
        .package(path: "Packages/HealthAI2030Networking")
    ],
    targets: [
        // Main library target
        .target(
            name: "HealthAI2030",
            dependencies: [
                "SleepTracking",
                "CardiacHealth",
                "MentalHealth",
                "iOS18Features",
                "Analytics",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthAI2030UI", package: "HealthAI2030UI"),
                .product(name: "HealthAI2030Networking", package: "HealthAI2030Networking"),
                .product(name: "AWSSecretsManager", package: "aws-sdk-swift"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Apps/MainApp",
            exclude: ["Tests", "Resources/Info.plist"]
        ),
        
        // Feature modules
        .target(
            name: "SleepTracking",
            path: "Modules/Features/SleepTracking/SleepTracking"
        ),
        
        .target(
            name: "CardiacHealth", 
            path: "Modules/Features/CardiacHealth/CardiacHealth"
        ),
        
        .target(
            name: "MentalHealth",
            path: "Modules/Features/MentalHealth/MentalHealth"
        ),
        
        .target(
            name: "iOS18Features",
            path: "Modules/Features/iOS18Features/iOS18Features"
        ),
        
        .target(
            name: "Analytics",
            path: "Modules/Kit/Analytics/Analytics"
        ),
        
        // Test targets
        .testTarget(
            name: "HealthAI2030Tests",
            dependencies: [
                "HealthAI2030",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/Features"
        ),
        
        .testTarget(
            name: "SleepTrackingTests",
            dependencies: ["SleepTracking"],
            path: "Modules/Features/SleepTracking/Tests"
        ),
        
        .testTarget(
            name: "CardiacHealthTests",
            dependencies: ["CardiacHealth"],
            path: "Modules/Features/CardiacHealth/Tests"
        )
    ]
)