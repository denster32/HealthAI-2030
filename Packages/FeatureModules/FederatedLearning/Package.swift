// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FederatedLearning",
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
            name: "FederatedLearning",
            targets: ["FederatedLearning"]
        ),
        .library(
            name: "PrivacyPreservingML",
            targets: ["PrivacyPreservingML"]
        ),
        .library(
            name: "FederatedCoordination",
            targets: ["FederatedCoordination"]
        )
    ],
    dependencies: [
        .package(path: "../../HealthAI2030Core"),
        .package(path: "../HealthMetrics"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "FederatedLearning",
            dependencies: [
                "PrivacyPreservingML",
                "FederatedCoordination",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "HealthMetrics", package: "HealthMetrics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .target(
            name: "PrivacyPreservingML",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Numerics", package: "swift-numerics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "FederatedCoordination",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FederatedLearningTests",
            dependencies: ["FederatedLearning"]
        )
    ]
)