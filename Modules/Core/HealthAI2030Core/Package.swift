// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "HealthAI2030Core",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "HealthAI2030Core",
            targets: ["HealthAI2030Core"]),
    ],
    dependencies: [
        // Dependencies will be added here as needed
    ],
    targets: [
        .target(
            name: "HealthAI2030Core",
            dependencies: [],
            path: "Sources"
        )
    ]
)