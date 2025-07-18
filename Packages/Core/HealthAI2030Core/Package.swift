// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HealthAI2030Core",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "HealthAI2030Core",
            targets: ["HealthAI2030Core"]
        )
    ],
    dependencies: [
        // Core dependencies will be added here
    ],
    targets: [
        .target(
            name: "HealthAI2030Core",
            dependencies: [],
            path: "Sources/HealthAI2030Core"
        ),
        .testTarget(
            name: "HealthAI2030CoreTests",
            dependencies: ["HealthAI2030Core"],
            path: "Tests/HealthAI2030CoreTests"
        )
    ]
)
