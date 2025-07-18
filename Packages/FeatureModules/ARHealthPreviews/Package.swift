// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ARHealthPreviews",
    platforms: [
        .iOS(.v18),
        .iPadOS(.v18),
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "ARHealthPreviews",
            targets: ["ARHealthPreviews"]
        ),
        .library(
            name: "RealityHealthKit",
            targets: ["RealityHealthKit"]
        ),
        .library(
            name: "SpatialHealthAnalytics",
            targets: ["SpatialHealthAnalytics"]
        )
    ],
    dependencies: [
        .package(path: "../../HealthAI2030Core"),
        .package(path: "../../HealthAI2030UI"),
        .package(path: "../HealthMetrics"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ARHealthPreviews",
            dependencies: [
                "RealityHealthKit",
                "SpatialHealthAnalytics",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthAI2030UI", package: "HealthAI2030UI"),
                .product(name: "HealthMetrics", package: "HealthMetrics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .target(
            name: "RealityHealthKit",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SpatialHealthAnalytics",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ARHealthPreviewsTests",
            dependencies: ["ARHealthPreviews"]
        )
    ]
)