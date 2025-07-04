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
        .package(path: "../../../Packages/Managers"),
    ],
    targets: [
        .target(
            name: "SleepTracking",
            dependencies: [
                "Managers",
            ]
        ),
        .testTarget(
            name: "SleepTrackingTests",
            dependencies: ["SleepTracking"]),
    ]
)