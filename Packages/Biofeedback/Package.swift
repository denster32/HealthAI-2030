// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Biofeedback",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "Biofeedback",
            targets: ["Biofeedback"]
        )
    ],
    dependencies: [
        // Core dependencies for biofeedback functionality
    ],
    targets: [
        .target(
            name: "Biofeedback",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "BiofeedbackTests",
            dependencies: ["Biofeedback"],
            path: "Tests"
        )
    ]
) 