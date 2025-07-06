// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HealthAI2030Graphics",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "HealthAI2030Graphics",
            targets: ["HealthAI2030Graphics"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HealthAI2030Graphics",
            dependencies: [],
            path: "Sources/HealthAI2030Graphics"
        ),
        .testTarget(
            name: "HealthAI2030GraphicsTests",
            dependencies: ["HealthAI2030Graphics"],
            path: "Tests/HealthAI2030GraphicsTests"
        ),
    ]
)