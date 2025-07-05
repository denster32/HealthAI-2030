// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HealthPrediction",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "HealthPrediction",
            targets: ["HealthPrediction"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.1.0"),
        .package(path: "../../Kit/Utilities"),
        .package(path: "../../Kit/Analytics"),
        .package(path: "../../Packages/HealthAI2030Core"),
        .package(path: "../../Packages/HealthAI2030Networking")
    ],
    targets: [
        .target(
            name: "HealthPrediction",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                "Utilities",
                "Analytics",
                "HealthAI2030Core",
                "HealthAI2030Networking"
            ],
            path: "HealthPrediction"
        ),
        .testTarget(
            name: "HealthPredictionTests",
            dependencies: ["HealthPrediction"],
            path: "Tests/HealthPredictionTests"
        )
    ]
) 