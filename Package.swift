// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        // Example: Add a CLI tool or additional libraries here as needed
        // .executable(name: "healthai-cli", targets: ["HealthAI_CLI"]),
    ],
    dependencies: [
            // Local package dependencies for modular features
            .package(path: "Packages/Managers"),
            .package(path: "Modules/Features/LogWaterIntake"),
            .package(path: "Modules/Features/StartMeditation"),
            .package(path: "Modules/Features/SleepTracking"),
            .package(path: "Modules/Features/CardiacHealth"),
            .package(path: "Modules/Features/MentalHealth"),
            .package(path: "Modules/Features/SmartHome"),
            .package(path: "Modules/Features/Biofeedback"),
            .package(path: "Modules/Kit/Analytics"),
            // Example: Add external dependencies here as needed
            // .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        ],
    targets: [
        // Main target for the HealthAI 2030 library
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
        // Test target for HealthAI 2030
        .testTarget(
            name: "HealthAI 2030Tests",
            dependencies: ["HealthAI 2030"],
            path: "HealthAI 2030Tests"
        ),
        // Example: Add CLI or feature targets here as needed
        // .executableTarget(
        //     name: "HealthAI_CLI",
        //     dependencies: ["HealthAI 2030", .product(name: "ArgumentParser", package: "swift-argument-parser")],
        //     path: "CLI"
        // ),
    ],
    swiftLanguageModes: [.v6]
)
// For further customization and integration, see the README.md for project guidelines and best practices.
