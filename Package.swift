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
        .library(
            name: "HealthAI2030",
            targets: ["HealthAI2030"]
        ),
        .library(
            name: "HealthAI2030Core",
            targets: ["HealthAI2030Core"]
        ),
        .library(
            name: "HealthAI2030Networking",
            targets: ["HealthAI2030Networking"]
        ),
        .library(
            name: "HealthAI2030UI",
            targets: ["HealthAI2030UI"]
        ),
        .library(
            name: "HealthAI2030Graphics",
            targets: ["HealthAI2030Graphics"]
        ),
        .library(
            name: "HealthAI2030ML",
            targets: ["HealthAI2030ML"]
        ),
        .library(
            name: "HealthAI2030Foundation",
            targets: ["HealthAI2030Foundation"]
        ),
        .library(
            name: "CardiacHealth",
            targets: ["CardiacHealth"]
        ),
        .library(
            name: "MentalHealth",
            targets: ["MentalHealth"]
        ),
        .library(
            name: "iOS18Features",
            targets: ["iOS18Features"]
        ),
        .library(
            name: "SleepTracking",
            targets: ["SleepTracking"]
        ),
        .library(
            name: "HealthPrediction",
            targets: ["HealthPrediction"]
        ),
        .library(
            name: "CopilotSkills",
            targets: ["CopilotSkills"]
        ),
        .library(
            name: "Metal4",
            targets: ["Metal4"]
        ),
        .library(
            name: "SmartHome",
            targets: ["SmartHome"]
        ),
        .library(
            name: "UserScripting",
            targets: ["UserScripting"]
        ),
        .library(
            name: "Shortcuts",
            targets: ["Shortcuts"]
        ),
        .library(
            name: "LogWaterIntake",
            targets: ["LogWaterIntake"]
        ),
        .library(
            name: "StartMeditation",
            targets: ["StartMeditation"]
        ),
        .library(
            name: "AR",
            targets: ["AR"]
        ),
        .library(
            name: "Biofeedback",
            targets: ["Biofeedback"]
        ),
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
        .target(
            name: "HealthAI2030",
            dependencies: [
                "HealthAI2030Core",
                "HealthAI2030Networking",
                "HealthAI2030UI",
                "HealthAI2030Graphics",
                "HealthAI2030ML",
                "HealthAI2030Foundation",
                "CardiacHealth",
                "MentalHealth",
                "iOS18Features",
                "SleepTracking",
                "HealthPrediction",
                "CopilotSkills",
                "Metal4",
                "SmartHome",
                "UserScripting",
                "Shortcuts",
                "LogWaterIntake",
                "StartMeditation",
                "AR",
                "Biofeedback",
                "Shared",
                "SharedSettingsModule",
                "HealthAIConversationalEngine",
                "Kit",
                "SharedHealthSummary",
                .product(name: "HealthAI2030Analytics", package: "HealthAI2030Analytics")
            ],
            path: "Sources/HealthAI2030"
        ),
        .target(
            name: "HealthAI2030Core",
            dependencies: [.product(name: "HealthAI2030Analytics", package: "HealthAI2030Analytics")],
            path: "Packages/HealthAI2030Core/Sources"
        ),
        .target(
            name: "HealthAI2030Networking",
            dependencies: [],
            path: "Packages/HealthAI2030Networking/Sources"
        ),
        .target(
            name: "HealthAI2030UI",
            dependencies: [],
            path: "Packages/HealthAI2030UI/Sources"
        ),
        .target(
            name: "HealthAI2030Graphics",
            dependencies: [],
            path: "Packages/HealthAI2030Graphics/Sources"
        ),
        .target(
            name: "HealthAI2030ML",
            dependencies: [],
            path: "Packages/HealthAI2030ML/Sources"
        ),
        .target(
            name: "HealthAI2030Foundation",
            dependencies: [],
            path: "Packages/HealthAI2030Foundation/Sources"
        ),
        .target(
            name: "CardiacHealth",
            dependencies: [],
            path: "Packages/CardiacHealth/Sources"
        ),
        .target(
            name: "MentalHealth",
            dependencies: [],
            path: "Packages/MentalHealth/Sources"
        ),
        .target(
            name: "iOS18Features",
            dependencies: [],
            path: "Packages/iOS18Features/Sources"
        ),
        .target(
            name: "SleepTracking",
            dependencies: [],
            path: "Packages/SleepTracking/Sources"
        ),
        .target(
            name: "HealthPrediction",
            dependencies: [],
            path: "Packages/HealthPrediction/Sources"
        ),
        .target(
            name: "CopilotSkills",
            dependencies: [],
            path: "Packages/CopilotSkills/Sources"
        ),
        .target(
            name: "Metal4",
            dependencies: [],
            path: "Packages/Metal4/Sources"
        ),
        .target(
            name: "SmartHome",
            dependencies: [],
            path: "Modules/Features/SmartHome/SmartHome" //Fixed
        ),
        .target(
            name: "UserScripting",
            dependencies: [],
            path: "Packages/UserScripting/Sources"
        ),
        .target(
            name: "Shortcuts",
            dependencies: [],
            path: "Packages/Shortcuts/Sources"
        ),
        .target(
            name: "LogWaterIntake",
            dependencies: [],
            path: "Packages/LogWaterIntake/Sources"
        ),
        .target(
            name: "StartMeditation",
            dependencies: [],
            path: "Packages/StartMeditation/Sources"
        ),
        .target(
            name: "AR",
            dependencies: [],
            path: "Packages/AR/Sources"
        ),
        .target(
            name: "Biofeedback",
            dependencies: [],
            path: "Packages/Biofeedback/Sources"
        ),
        .target(
            name: "Shared",
            dependencies: [],
            path: "Packages/Shared/Sources"
        ),
        .target(
            name: "SharedSettingsModule",
            dependencies: [],
            path: "Packages/SharedSettingsModule/Sources"
        ),
        .target(
            name: "HealthAIConversationalEngine",
            dependencies: [],
            path: "Packages/HealthAIConversationalEngine/Sources"
        ),
        .target(
            name: "Kit",
            dependencies: [],
            path: "Packages/Kit/Sources"
        ),

        .target(
            name: "SharedHealthSummary",
            dependencies: [],
            path: "Packages/SharedHealthSummary/Sources"
        ),
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