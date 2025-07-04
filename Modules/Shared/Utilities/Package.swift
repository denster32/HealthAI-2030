// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SharedUtilities",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SharedUtilities",
            targets: ["DateUtils"]
        )
    ],
    targets: [
        .target(
            name: "DateUtils",
            path: "",
            exclude: ["Tests"]
        ),
        .testTarget(
            name: "SharedUtilitiesTests",
            dependencies: ["DateUtils"],
            path: "Tests"
        )
    ]
)
