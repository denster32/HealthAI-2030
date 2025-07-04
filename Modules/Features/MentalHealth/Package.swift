// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MentalHealth",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "MentalHealth",
            targets: ["MentalHealth"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MentalHealth",
            dependencies: [
            ],
            path: "Sources/MentalHealth"
        ),
        .testTarget(
            name: "MentalHealthTests",
            dependencies: ["MentalHealth"],
            path: "Tests/MentalHealthTests"
        ),
    ]
)