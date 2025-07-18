// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BiometricFusionKit",
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
            name: "BiometricFusionKit",
            targets: ["BiometricFusionKit"]
        ),
        .library(
            name: "BiometricProcessing",
            targets: ["BiometricProcessing"]
        ),
        .library(
            name: "HRVAnalysis",
            targets: ["HRVAnalysis"]
        ),
        .library(
            name: "BiometricSecurity",
            targets: ["BiometricSecurity"]
        )
    ],
    dependencies: [
        .package(path: "../HealthAI2030Core"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "BiometricFusionKit",
            dependencies: [
                "BiometricProcessing",
                "HRVAnalysis",
                "BiometricSecurity",
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .target(
            name: "BiometricProcessing",
            dependencies: [
                .product(name: "HealthAI2030Core", package: "HealthAI2030Core"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Numerics", package: "swift-numerics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "HRVAnalysis",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics"),
                .product(name: "ComplexModule", package: "swift-numerics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "BiometricSecurity",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "BiometricFusionKitTests",
            dependencies: ["BiometricFusionKit"]
        )
    ]
)