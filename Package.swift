// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthAI 2030",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HealthAI 2030",
            targets: ["HealthAI 2030"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HealthAI 2030"
        ),
        .testTarget(
            name: "HealthAI 2030Tests",
            dependencies: ["HealthAI 2030"]
        ),
    ]
)
