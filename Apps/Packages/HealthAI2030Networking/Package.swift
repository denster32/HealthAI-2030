// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HealthAI2030Networking",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "HealthAI2030Networking",
            targets: ["HealthAI2030Networking"]
        ),
    ],
    dependencies: [
        .package(path: "../HealthAI2030Core"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.78.0")
    ],
    targets: [
        .target(
            name: "HealthAI2030Networking",
            dependencies: [
                "HealthAI2030Core",
                .product(name: "AWSSecretsManager", package: "aws-sdk-swift")
            ],
            path: "Sources/HealthAI2030Networking"
        ),
        .testTarget(
            name: "HealthAI2030NetworkingTests",
            dependencies: ["HealthAI2030Networking"],
            path: "Tests/HealthAI2030NetworkingTests"
        ),
    ]
)