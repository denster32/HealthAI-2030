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
    ],
    targets: [
        .target(
            name: "SleepTracking",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "SleepTrackingTests",
            dependencies: ["SleepTracking"]),
    ]
)