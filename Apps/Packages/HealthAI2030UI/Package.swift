// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HealthAI2030UI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "HealthAI2030UI",
            targets: ["HealthAI2030UI"]
        ),
    ],
    dependencies: [
        .package(path: "../HealthAI2030Core")
    ],
    targets: [
        .target(
            name: "HealthAI2030UI",
            dependencies: ["HealthAI2030Core"],
            path: "Sources/HealthAI2030UI"
        ),
        .testTarget(
            name: "HealthAI2030UITests",
            dependencies: ["HealthAI2030UI"],
            path: "Tests/HealthAI2030UITests"
        ),
    ]
)