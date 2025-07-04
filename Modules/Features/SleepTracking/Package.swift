// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SleepTracking",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SleepTracking",
            targets: ["SleepTracking"]),
    ],
    dependencies: [
        .package(path: "../../../Packages/Models"),
        .package(path: "../../../Packages/Managers"),
        .package(path: "../../../Packages/Analytics"),
        .package(path: "../../../Packages/ML"),
        .package(path: "../../../Packages/Utilities"),
    ],
    targets: [
        .target(
            name: "SleepTracking",
            dependencies: [
                "Models",
                "Managers",
                "Analytics",
                "ML",
                "Utilities"
            ]
        ),
        .testTarget(
            name: "SleepTrackingTests",
            dependencies: ["SleepTracking"]),
    ]
)