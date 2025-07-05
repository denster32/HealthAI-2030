import HealthAI2030Core
import HealthAI2030Core
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SleepIntelligenceKit",
    platforms: [
        .iOS(.v18), .macOS(.v15)
    ],
    products: [
        .library(name: "SleepIntelligenceKit", targets: ["SleepIntelligenceKit"])
    ],
    targets: [
        .target(
            name: "SleepIntelligenceKit",
            dependencies: []
        ),
        .testTarget(
            name: "SleepIntelligenceKitTests",
            dependencies: ["SleepIntelligenceKit"]
        )
    ]
)
