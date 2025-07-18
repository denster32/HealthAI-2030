// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HealthAI2030",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        // MARK: - Core Products (Essential)
        .library(
            name: "HealthAI2030Core",
            targets: ["HealthAI2030Core"]
        ),
        .library(
            name: "HealthAI2030UI",
            targets: ["HealthAI2030UI"]
        ),
        .library(
            name: "HealthAI2030Networking",
            targets: ["HealthAI2030Networking"]
        ),
        .library(
            name: "HealthAI2030Foundation",
            targets: ["HealthAI2030Foundation"]
        ),
        
        // MARK: - Feature Products (Consolidated)
        .library(
            name: "Sleep",
            targets: ["Sleep"]
        ),
        .library(
            name: "SmartHome",
            targets: ["SmartHome"]
        ),
        .library(
            name: "HealthMetrics",
            targets: ["HealthMetrics"]
        ),
        .library(
            name: "CardiacHealth",
            targets: ["CardiacHealth"]
        ),
        .library(
            name: "MentalHealth",
            targets: ["MentalHealth"]
        ),
        
        // MARK: - Platform Products
        .library(
            name: "BiometricFusion",
            targets: ["BiometricFusion"]
        ),
        .library(
            name: "SharePlayWellness",
            targets: ["SharePlayWellness"]
        ),
        .library(
            name: "AIHealthCoaching",
            targets: ["AIHealthCoaching"]
        ),
        
        // MARK: - App Targets
        .executable(
            name: "HealthAI2030",
            targets: ["HealthAI2030"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0")
    ],
    targets: [
        // MARK: - App Target
        .executableTarget(
            name: "HealthAI2030",
            dependencies: [
                "HealthAI2030Core",
                "HealthAI2030UI",
                "HealthAI2030Networking",
                "HealthAI2030Foundation",
                "Sleep",
                "SmartHome",
                "HealthMetrics",
                "CardiacHealth",
                "MentalHealth"
            ],
            path: "Sources/HealthAI2030"
        ),
        
        // MARK: - Core Framework Targets
        .target(
            name: "HealthAI2030Core",
            dependencies: [
                "HealthAI2030Foundation",
                .product(name: "Numerics", package: "swift-numerics")
            ],
            path: "Packages/Core/HealthAI2030Core/Sources/HealthAI2030Core"
        ),
        .target(
            name: "HealthAI2030UI",
            dependencies: ["HealthAI2030Core", "HealthAI2030Foundation"],
            path: "Packages/Core/HealthAI2030UI/Sources/HealthAI2030UI"
        ),
        .target(
            name: "HealthAI2030Networking",
            dependencies: ["HealthAI2030Core", "HealthAI2030Foundation"],
            path: "Packages/Core/HealthAI2030Networking/Sources/HealthAI2030Networking"
        ),
        .target(
            name: "HealthAI2030Foundation",
            dependencies: [],
            path: "Packages/Core/HealthAI2030Foundation/Sources/HealthAI2030Foundation"
        ),
        
        // MARK: - Consolidated Feature Targets
        .target(
            name: "Sleep",
            dependencies: ["HealthAI2030Core", "HealthAI2030UI"],
            path: "Packages/Features/Sleep/Sources/Sleep"
        ),
        .target(
            name: "SmartHome",
            dependencies: ["HealthAI2030Core", "HealthAI2030UI"],
            path: "Packages/Features/SmartHome/Sources/SmartHome"
        ),
        .target(
            name: "HealthMetrics",
            dependencies: [
                "HealthAI2030Core",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Numerics", package: "swift-numerics"),
                .product(name: "Algorithms", package: "swift-algorithms")
            ],
            path: "Packages/FeatureModules/HealthMetrics/Sources/MetricsAnalytics"
        ),
        .target(
            name: "CardiacHealth",
            dependencies: ["HealthAI2030Core"],
            path: "Sources/Features/CardiacHealth/Sources/CardiacHealth"
        ),
        .target(
            name: "MentalHealth",
            dependencies: ["HealthAI2030Core"],
            path: "Sources/Features/MentalHealth/Sources/MentalHealth"
        ),
        
        // MARK: - Advanced Feature Targets
        .target(
            name: "BiometricFusion",
            dependencies: ["HealthAI2030Core"],
            path: "Frameworks/BiometricFusionKit/Sources/BiometricFusionKit"
        ),
        .target(
            name: "SharePlayWellness",
            dependencies: ["HealthAI2030Core", "HealthAI2030UI"],
            path: "Packages/FeatureModules/SharePlayWellness/Sources/SharePlayWellness"
        ),
        .target(
            name: "AIHealthCoaching",
            dependencies: ["HealthAI2030Core", "HealthAI2030UI"],
            path: "Packages/FeatureModules/AIHealthCoaching/Sources/AIHealthCoaching"
        ),
        
        // MARK: - Test Targets
        .testTarget(
            name: "HealthAI2030Tests",
            dependencies: [
                "HealthAI2030Core",
                "Sleep",
                "SmartHome",
                "HealthMetrics"
            ],
            path: "Tests/HealthAI2030Tests"
        ),
        .testTarget(
            name: "HealthAI2030CoreTests",
            dependencies: ["HealthAI2030Core"],
            path: "Tests/HealthAI2030CoreTests"
        ),
        .testTarget(
            name: "HealthAI2030UITests",
            dependencies: ["HealthAI2030UI"],
            path: "Tests/HealthAI2030UITests"
        ),
    ]
)
