// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HealthAI2030Networking",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "HealthAI2030Networking",
            targets: ["HealthAI2030Networking"]
        )
    ],
    dependencies: [
        // Core dependencies will be added here
    ],
    targets: [
        .target(
            name: "HealthAI2030Networking",
            dependencies: [],
            path: "Sources/HealthAI2030Networking"
        ),
        .testTarget(
            name: "HealthAI2030NetworkingTests",
            dependencies: ["HealthAI2030Networking"],
            path: "Tests/HealthAI2030NetworkingTests"
        )
    ]
)
