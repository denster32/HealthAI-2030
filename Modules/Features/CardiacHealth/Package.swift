// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CardiacHealth",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
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