// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Biofeedback",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Biofeedback",
            targets: ["Biofeedback"]),
    ],
    dependencies: [
        // Add any dependencies specific to Biofeedback here, e.g.,
        // .package(path: "../../../HealthAI 2030")
    ],
    targets: [
        .target(
            name: "Biofeedback",
            dependencies: [
                // Add product dependencies here
            ],
            path: "Sources/Biofeedback"
        ),
        .testTarget(
            name: "BiofeedbackTests",
            dependencies: ["Biofeedback"],
            path: "Tests/BiofeedbackTests"
        ),
    ]
)