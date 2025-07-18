// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SleepOptimization",
    platforms: [
        .iOS(.v18),
        .iPadOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SleepOptimization",
            targets: ["SleepOptimization"]
        ),
        .library(
            name: "SleepIntelligenceEngine",
            targets: ["SleepIntelligenceEngine"]
        ),
        .library(
            name: "CircadianRhythmEngine",
            targets: ["CircadianRhythmEngine"]
        )
    ],
    dependencies: [
        .package(path: "../../HealthAI2030Core"),
        .package(path: "../../HealthAI2030UI"),
        .package(url: "https://github.com/qdrant/qdrant-swift", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SleepOptimization",
            dependencies: [
                "SleepIntelligenceEngine",
                "CircadianRhythmEngine",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthAI2030UI", package: "HealthAI2030UI")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .target(
            name: "SleepIntelligenceEngine",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "QdrantSwift", package: "qdrant-swift"),
                .product(name: "Numerics", package: "swift-numerics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "CircadianRhythmEngine",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SleepOptimizationTests",
            dependencies: ["SleepOptimization"]
        )
    ]
)