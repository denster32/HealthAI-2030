// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HealthAI2030ML",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "HealthAI2030ML",
            targets: ["HealthAI2030ML"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HealthAI2030ML",
            dependencies: [],
            path: "Sources/HealthAI2030ML"
        ),
        .testTarget(
            name: "HealthAI2030MLTests",
            dependencies: ["HealthAI2030ML"],
            path: "Tests/HealthAI2030MLTests"
        ),
    ]
)