// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CardiacHealth",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CardiacHealth",
            targets: ["CardiacHealth"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CardiacHealth",
            dependencies: []),
        .testTarget(
            name: "CardiacHealthTests",
            dependencies: ["CardiacHealth"]),
    ]
)