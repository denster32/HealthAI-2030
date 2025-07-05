// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AR",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AR",
            targets: ["AR"]
        ),
    ],
    dependencies: [
        .package(path: "../../Kit/Utilities"),
        .package(path: "../../Kit/Analytics"),
        .package(path: "../../Packages/HealthAI2030Core")
    ],
    targets: [
        .target(
            name: "AR",
            dependencies: [
                "Utilities",
                "Analytics",
                "HealthAI2030Core"
            ],
            path: "AR"
        ),
        .testTarget(
            name: "ARTests",
            dependencies: ["AR"],
            path: "Tests/ARTests"
        )
    ]
) 