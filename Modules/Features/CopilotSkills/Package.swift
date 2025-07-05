// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CopilotSkills",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "CopilotSkills",
            targets: ["CopilotSkills"]
        ),
    ],
    dependencies: [
        .package(path: "../../Kit/Utilities"),
        .package(path: "../../Kit/Analytics"),
        .package(path: "../../Kit/Components"),
        .package(path: "../../Packages/HealthAI2030Core"),
        .package(path: "../../Packages/HealthAI2030Networking")
    ],
    targets: [
        .target(
            name: "CopilotSkills",
            dependencies: [
                "Utilities",
                "Analytics", 
                "Components",
                "HealthAI2030Core",
                "HealthAI2030Networking"
            ],
            path: "CopilotSkills"
        ),
        .testTarget(
            name: "CopilotSkillsTests",
            dependencies: ["CopilotSkills"],
            path: "Tests/CopilotSkillsTests"
        )
    ]
) 