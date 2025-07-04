// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CardiacHealth",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CardiacHealth",
            targets: ["CardiacHealth"]),
    ],
    dependencies: [
        .package(path: "../../../Packages/Models"),
        .package(path: "../../../Packages/Analytics"),
        .package(path: "../../../Packages/Utilities"),
    ],
    targets: [
        .target(
            name: "CardiacHealth",
            dependencies: ["Models", "Analytics", "Utilities"]),
        .testTarget(
            name: "CardiacHealthTests",
            dependencies: ["CardiacHealth"]),
    ]
)