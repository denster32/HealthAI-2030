import HealthAI2030Core
import HealthAI2030Core
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SecurityComplianceKit",
    platforms: [
        .iOS(.v18), .macOS(.v15)
    ],
    products: [
        .library(name: "SecurityComplianceKit", targets: ["SecurityComplianceKit"])
    ],
    targets: [
        .target(
            name: "SecurityComplianceKit",
            dependencies: []
        ),
        .testTarget(
            name: "SecurityComplianceKitTests",
            dependencies: ["SecurityComplianceKit"]
        )
    ]
)
