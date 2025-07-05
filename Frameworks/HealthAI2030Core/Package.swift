import HealthAI2030Core
import HealthAI2030Core
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HealthAI2030Core",
    platforms: [
        .iOS(.v18), .macOS(.v15)
    ],
    products: [
        .library(name: "HealthAI2030Core", targets: ["HealthAI2030Core"])
    ],
    targets: [
        .target(
            name: "HealthAI2030Core",
            dependencies: []
        ),
        .testTarget(
            name: "HealthAI2030CoreTests",
            dependencies: ["HealthAI2030Core"]
        )
    ]
)
