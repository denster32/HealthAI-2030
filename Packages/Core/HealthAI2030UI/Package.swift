// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HealthAI2030UI",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "HealthAI2030UI",
            targets: ["HealthAI2030UI"]
        )
    ],
    dependencies: [
        // Core dependencies will be added here
    ],
    targets: [
        .target(
            name: "HealthAI2030UI",
            dependencies: [],
            path: "Sources/HealthAI2030UI"
        ),
        .testTarget(
            name: "HealthAI2030UITests",
            dependencies: ["HealthAI2030UI"],
            path: "Tests/HealthAI2030UITests"
        )
    ]
)
