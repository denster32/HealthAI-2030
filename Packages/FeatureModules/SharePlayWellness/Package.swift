// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharePlayWellness",
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
            name: "SharePlayWellness",
            targets: ["SharePlayWellness"]
        ),
        .library(
            name: "MultiUserSync",
            targets: ["MultiUserSync"]
        ),
        .library(
            name: "GroupActivities",
            targets: ["GroupActivities"]
        )
    ],
    dependencies: [
        .package(path: "../../HealthAI2030Core"),
        .package(path: "../../HealthAI2030UI"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SharePlayWellness",
            dependencies: [
                "MultiUserSync",
                "GroupActivities",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthAI2030UI", package: "HealthAI2030UI")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .target(
            name: "MultiUserSync",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "GroupActivities",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SharePlayWellnessTests",
            dependencies: ["SharePlayWellness"]
        )
    ]
)