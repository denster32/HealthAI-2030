// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LogWaterIntake",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "LogWaterIntake",
            targets: ["LogWaterIntake"]),
    ],
    dependencies: [
        // Add dependencies to other Core/Kit modules here later
    ],
    targets: [
        .target(
            name: "LogWaterIntake",
            dependencies: []),
        .testTarget(
            name: "LogWaterIntakeTests",
            dependencies: ["LogWaterIntake"]),
    ]
)