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
    ],
    targets: [
        .target(
            name: "CardiacHealth",
            dependencies: []),
        .testTarget(
            name: "CardiacHealthTests",
            dependencies: ["CardiacHealth"]),
    ]
)