// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmartHomeHealth",
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
            name: "SmartHomeHealth",
            targets: ["SmartHomeHealth"]
        ),
        .library(
            name: "EnvironmentalHealthEngine",
            targets: ["EnvironmentalHealthEngine"]
        ),
        .library(
            name: "SmartDeviceIntegration",
            targets: ["SmartDeviceIntegration"]
        ),
        .library(
            name: "HealthAutomation",
            targets: ["HealthAutomation"]
        )
    ],
    dependencies: [
        .package(path: "../../HealthAI2030Core"),
        .package(path: "../../HealthAI2030UI"),
        .package(path: "../HealthMetrics"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "SmartHomeHealth",
            dependencies: [
                "EnvironmentalHealthEngine",
                "SmartDeviceIntegration",
                "HealthAutomation",
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
            name: "EnvironmentalHealthEngine",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthMetrics", package: "HealthMetrics"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SmartDeviceIntegration",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "HealthAutomation",
            dependencies: [
                "EnvironmentalHealthEngine",
                "SmartDeviceIntegration",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SmartHomeHealthTests",
            dependencies: ["SmartHomeHealth"]
        )
    ]
)
