// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SmartHome",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SmartHome",
            targets: ["SmartHome"]
        ),
    ],
    dependencies: [
        .package(path: "../../Kit/Utilities"),
        .package(path: "../../Kit/Analytics"),
        .package(path: "../../Packages/HealthAI2030Core")
    ],
    targets: [
        .target(
            name: "SmartHome",
            dependencies: [
                "Utilities",
                "Analytics",
                "HealthAI2030Core"
            ],
            path: "SmartHome"
        ),
        .testTarget(
            name: "SmartHomeTests",
            dependencies: ["SmartHome"],
            path: "Tests/SmartHomeTests"
        )
    ]
) 