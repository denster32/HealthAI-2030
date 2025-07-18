// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HealthAI2030Foundation",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "HealthAI2030Foundation",
            targets: ["HealthAI2030Foundation"]
        )
    ],
    dependencies: [
        // Core dependencies will be added here
    ],
    targets: [
        .target(
            name: "HealthAI2030Foundation",
            dependencies: [],
            path: "Sources/HealthAI2030Foundation"
        ),
        .testTarget(
            name: "HealthAI2030FoundationTests",
            dependencies: ["HealthAI2030Foundation"],
            path: "Tests/HealthAI2030FoundationTests"
        )
    ]
)
