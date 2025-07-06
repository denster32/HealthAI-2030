// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HealthAI2030",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18)
    ],
    products: [
        // MARK: - Core Products (Essential - always included)
        .library(
            name: "HealthAI2030Core",
            targets: ["HealthAI2030Core"]
        ),
        .library(
            name: "HealthAI2030Foundation",
            targets: ["HealthAI2030Foundation"]
        ),
        .library(
            name: "HealthAI2030Networking",
            targets: ["HealthAI2030Networking"]
        ),
        .library(
            name: "HealthAI2030UI",
            targets: ["HealthAI2030UI"]
        ),
        
        // MARK: - Feature Products (Lazy loaded)
        .library(
            name: "HealthAI2030Features",
            targets: [
                "CardiacHealth",
                "MentalHealth", 
                "SleepTracking",
                "HealthPrediction"
            ]
        ),
        
        // MARK: - Optional Products (On-demand)
        .library(
            name: "HealthAI2030Optional",
            targets: [
                "HealthAI2030ML",
                "HealthAI2030Graphics",
                "Metal4",
                "AR",
                "SmartHome",
                "UserScripting"
            ]
        ),
        
        // MARK: - Platform-Specific Products
        .library(
            name: "HealthAI2030iOS",
            targets: ["iOS18Features"]
        ),
        .library(
            name: "HealthAI2030Widgets",
            targets: ["HealthAI2030Widgets"]
        ),
        
        // MARK: - Integration Products
        .library(
            name: "HealthAI2030Shortcuts",
            targets: ["Shortcuts", "CopilotSkills"]
        ),
        .library(
            name: "HealthAI2030Wellness",
            targets: ["StartMeditation", "LogWaterIntake", "Biofeedback"]
        ),
        
        // MARK: - Main App (Optimized)
        .library(
            name: "HealthAI2030",
            targets: ["HealthAI2030"]
        ),
        
        // MARK: - Shared Components
        .library(
            name: "Shared",
            targets: ["Shared"]
        ),
        .library(
            name: "SharedSettingsModule",
            targets: ["SharedSettingsModule"]
        ),
        .library(
            name: "HealthAIConversationalEngine",
            targets: ["HealthAIConversationalEngine"]
        ),
        .library(
            name: "Kit",
            targets: ["Kit"]
        ),
        .library(
            name: "SharedHealthSummary",
            targets: ["SharedHealthSummary"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(path: "Apps/MainApp/Packages/HealthAI2030Analytics")
    ],
    targets: [
        // MARK: - Main Target (Core Dependencies Only)
        .target(
            name: "HealthAI2030",
            dependencies: [
                "HealthAI2030Core",
                "HealthAI2030Foundation",
                "HealthAI2030Networking",
                "HealthAI2030UI",
                "Shared",
                "Kit"
            ],
            path: "Sources/HealthAI2030"
        ),
        
        // MARK: - Core Targets
        .target(
            name: "HealthAI2030Core",
            dependencies: [
                .product(name: "HealthAI2030Analytics", package: "HealthAI2030Analytics"),
                "HealthAI2030Foundation"
            ],
            path: "Packages/HealthAI2030Core/Sources"
        ),
        .target(
            name: "HealthAI2030Foundation",
            dependencies: [],
            path: "Packages/HealthAI2030Foundation/Sources"
        ),
        .target(
            name: "HealthAI2030Networking",
            dependencies: ["HealthAI2030Foundation"],
            path: "Packages/HealthAI2030Networking/Sources"
        ),
        .target(
            name: "HealthAI2030UI",
            dependencies: ["HealthAI2030Foundation"],
            path: "Packages/HealthAI2030UI/Sources"
        ),
        
        // MARK: - Feature Targets (Lazy Loaded)
        .target(
            name: "CardiacHealth",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/CardiacHealth/Sources"
        ),
        .target(
            name: "MentalHealth",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/MentalHealth/Sources"
        ),
        .target(
            name: "SleepTracking",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/SleepTracking/Sources"
        ),
        .target(
            name: "HealthPrediction",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/HealthPrediction/Sources"
        ),
        
        // MARK: - Optional Targets (On-Demand)
        .target(
            name: "HealthAI2030ML",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/HealthAI2030ML/Sources"
        ),
        .target(
            name: "HealthAI2030Graphics",
            dependencies: ["HealthAI2030Foundation"],
            path: "Packages/HealthAI2030Graphics/Sources"
        ),
        .target(
            name: "Metal4",
            dependencies: ["HealthAI2030Graphics"],
            path: "Packages/Metal4/Sources"
        ),
        .target(
            name: "AR",
            dependencies: ["HealthAI2030Graphics"],
            path: "Packages/AR/Sources"
        ),
        .target(
            name: "SmartHome",
            dependencies: ["HealthAI2030Core"],
            path: "Modules/Features/SmartHome/SmartHome"
        ),
        .target(
            name: "UserScripting",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/UserScripting/Sources"
        ),
        
        // MARK: - Platform-Specific Targets
        .target(
            name: "iOS18Features",
            dependencies: ["HealthAI2030UI"],
            path: "Packages/iOS18Features/Sources"
        ),
        .target(
            name: "HealthAI2030Widgets",
            dependencies: ["HealthAI2030UI"],
            path: "Packages/HealthAI2030Widgets/Sources"
        ),
        
        // MARK: - Integration Targets
        .target(
            name: "Shortcuts",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/Shortcuts/Sources"
        ),
        .target(
            name: "CopilotSkills",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/CopilotSkills/Sources"
        ),
        .target(
            name: "StartMeditation",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/StartMeditation/Sources"
        ),
        .target(
            name: "LogWaterIntake",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/LogWaterIntake/Sources"
        ),
        .target(
            name: "Biofeedback",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/Biofeedback/Sources"
        ),
        
        // MARK: - Shared Targets
        .target(
            name: "Shared",
            dependencies: [],
            path: "Packages/Shared/Sources"
        ),
        .target(
            name: "SharedSettingsModule",
            dependencies: ["Shared"],
            path: "Packages/SharedSettingsModule/Sources"
        ),
        .target(
            name: "HealthAIConversationalEngine",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/HealthAIConversationalEngine/Sources"
        ),
        .target(
            name: "Kit",
            dependencies: ["HealthAI2030Foundation"],
            path: "Packages/Kit/Sources"
        ),
        .target(
            name: "SharedHealthSummary",
            dependencies: ["HealthAI2030Core"],
            path: "Packages/SharedHealthSummary/Sources"
        ),
        
        // MARK: - Test Targets
        .testTarget(
            name: "HealthAI2030Tests",
            dependencies: ["HealthAI2030", "HealthAI2030Core"],
            path: "Tests/HealthAI2030Tests"
        ),
        .testTarget(
            name: "HealthAI2030IntegrationTests",
            dependencies: ["HealthAI2030"],
            path: "Tests/HealthAI2030IntegrationTests"
        ),
        .testTarget(
            name: "HealthAI2030UITests",
            dependencies: ["HealthAI2030"],
            path: "Tests/HealthAI2030UITests"
        ),
        .testTarget(
            name: "CardiacHealthTests",
            dependencies: ["CardiacHealth"],
            path: "Tests/CardiacHealthTests"
        )
    ]
)