// Version 1.0.0
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "HealthAI 2030",
    // Minimum supported platform for all modules
    platforms: [
        .iOS(.v18)
    ],
    products: [
        // Main library product for HealthAI 2030
        .library(
            name: "HealthAI 2030",
            targets: ["HealthAI 2030"]
        ),
    ],
    dependencies: [
        .package(path: "Packages/Managers"),
        .package(path: "Modules/Features/LogWaterIntake"),
        .package(path: "Modules/Features/StartMeditation"),
        .package(path: "Modules/Features/SleepTracking"),
        .package(path: "Modules/Features/CardiacHealth"),
        .package(path: "Modules/Features/MentalHealth"),
        .package(path: "Modules/Features/SmartHome"),
        .package(path: "Modules/Features/Biofeedback"),
        .package(path: "Modules/Kit/Analytics"),
    ],
    targets: [
        .target(
            name: "HealthAI 2030",
            dependencies: [
                .product(name: "Managers", package: "Managers"),
                .product(name: "LogWaterIntake", package: "LogWaterIntake"),
                .product(name: "StartMeditation", package: "StartMeditation"),
                .product(name: "SleepTracking", package: "SleepTracking"),
                .product(name: "CardiacHealth", package: "CardiacHealth"),
                .product(name: "MentalHealth", package: "MentalHealth"),
                .product(name: "SmartHome", package: "SmartHome"),
                .product(name: "Biofeedback", package: "Biofeedback"),
                .product(name: "Analytics", package: "Analytics")
            ],
            path: "HealthAI 2030"
        ),
        .testTarget(
            name: "HealthAI 2030Tests",
            dependencies: ["HealthAI 2030"],
            path: "HealthAI 2030Tests"
        ),
    ]
)
