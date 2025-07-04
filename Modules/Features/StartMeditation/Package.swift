// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "StartMeditation",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "StartMeditation",
            targets: ["StartMeditation"]),
    ],
    dependencies: [
        .package(path: "../../../Packages/Managers")
    ],
    targets: [
        .target(
            name: "StartMeditation",
            dependencies: ["Managers"]),
        .testTarget(
            name: "StartMeditationTests",
            dependencies: ["StartMeditation"]),
    ]
)