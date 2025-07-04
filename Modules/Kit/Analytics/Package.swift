// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "Analytics",
            targets: ["Analytics"]),
    ],
    dependencies: [
        // Add any dependencies required by AnalyticsEngine, AnalyticsInsight, MetricManager
        // For example, if AnalyticsInsight depends on SwiftData or CloudKit, those might be external dependencies.
        // Based on current files, Foundation, Combine, SwiftData, CloudKit, MetricKit, OSLog are used.
        // SwiftData and CloudKit are system frameworks, so no explicit SPM dependency needed unless
        // they are wrapped in a separate local package.
    ],
    targets: [
        .target(
            name: "Analytics",
            dependencies: []), // Add dependencies if any
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["Analytics"]),
    ]
)