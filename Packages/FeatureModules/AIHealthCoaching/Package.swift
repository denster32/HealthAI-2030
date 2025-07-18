// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIHealthCoaching",
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
            name: "AIHealthCoaching",
            targets: ["AIHealthCoaching"]
        ),
        .library(
            name: "ConversationalAI",
            targets: ["ConversationalAI"]
        ),
        .library(
            name: "HealthReasoningEngine",
            targets: ["HealthReasoningEngine"]
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
            name: "AIHealthCoaching",
            dependencies: [
                "ConversationalAI",
                "HealthReasoningEngine",
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
            name: "ConversationalAI",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "HealthReasoningEngine",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthMetrics", package: "HealthMetrics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AIHealthCoachingTests",
            dependencies: ["AIHealthCoaching"]
        )
    ]
)