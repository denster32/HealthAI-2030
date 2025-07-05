// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HealthAI2030Core",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "HealthAI2030Core",
            targets: ["HealthAI2030Core"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.34.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "HealthAI2030Core",
            dependencies: [
                .product(name: "AWSSecretsManager", package: "aws-sdk-swift"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources/HealthAI2030Core"
        ),
        .testTarget(
            name: "HealthAI2030CoreTests",
            dependencies: ["HealthAI2030Core"],
            path: "Tests/HealthAI2030CoreTests"
        ),
    ]
)