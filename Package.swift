// swift-tools-version:5.7
// Version 1.0.0
import PackageDescription

let package = Package(
    name: "HealthAI 2030",
    defaultLocalization: "en",
    // Minimum supported platform for all modules
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        // Main library product for HealthAI 2030
        .library(
            name: "HealthAI 2030",
            targets: ["HealthAI 2030"]
        ),
    ],
    dependencies: [
        // .package(path: "Packages/Managers"), // Removed, no longer exists
        .package(path: "Modules/Features/LogWaterIntake"),
        .package(path: "Modules/Features/StartMeditation"),
        .package(path: "Modules/Features/SleepTracking"),
        .package(path: "Modules/Features/CardiacHealth"),
        .package(path: "Modules/Features/MentalHealth"),
        .package(path: "Modules/Features/SmartHome"),
        // .package(path: "Modules/Features/Biofeedback"), // Commented out if empty
        .package(path: "Modules/Kit/Analytics"),
    ],
    targets: [
        .target(
            name: "HealthAI 2030",
            dependencies: [
                // .product(name: "Managers", package: "Managers"),
                .product(name: "LogWaterIntake", package: "LogWaterIntake"),
                .product(name: "StartMeditation", package: "StartMeditation"),
                .product(name: "SleepTracking", package: "SleepTracking"),
                .product(name: "CardiacHealth", package: "CardiacHealth"),
                .product(name: "MentalHealth", package: "MentalHealth"),
                .product(name: "SmartHome", package: "SmartHome"),
                // .product(name: "Biofeedback", package: "Biofeedback"),
                .product(name: "Analytics", package: "Analytics")
            ],
            path: "HealthAI 2030/App", // Only include main app source directory
            exclude: [
                "../Documentation",
                "../ML",
                "../CopilotSkills",
                "../Resources",
                "../Assets.xcassets",
                "../Localization",
                "../Metal4",
                "../Views",
                "../Managers",
                "../Models",
                "../Security",
                "../Shortcuts",
                "../UserScripting",
                "../WatchKit Extension",
                "../AppleTV",
                "../macOS",
                "../iOS18Features",
                "../iOS26Dependencies.swift",
                "../HealthAI2030.xcdatamodeld",
                "../HealthAI2030_iOS.entitlements",
                "../ImplementationPlan.md",
                "../LICENSE",
                "../Task_Completion_Checklist.md"
            ]
        ),
        .testTarget(
            name: "HealthAI 2030Tests",
            dependencies: ["HealthAI 2030"],
            path: "HealthAI 2030Tests"
        ),
    ]
)
