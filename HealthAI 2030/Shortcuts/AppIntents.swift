import AppIntents
import HealthKit
import SwiftUI

// MARK: - App Intents for HealthAI 2030

/// An App Intent to get the user's current heart rate.
@available(iOS 18.0, *)
struct GetHeartRateAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Heart Rate"
    static var description = IntentDescription("Gets the user's current heart rate from HealthKit.")

    @Dependency private var healthDataManager: HealthDataManager

    func perform() async throws -> some IntentResult & ProvidesStringResult {
        let heartRate = await healthDataManager.getCurrentHeartRate()

        let result = "Your current heart rate is \(Int(heartRate)) bpm."
        return .result(value: result)
    }
}

/// An App Intent to start sleep tracking.
@available(iOS 18.0, *)
struct StartSleepTrackingAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sleep Tracking"
    static var description = IntentDescription("Starts tracking the user's sleep.")

    @Dependency private var sleepOptimizationManager: SleepOptimizationManager

    func perform() async throws -> some IntentResult & ProvidesStringResult {
        sleepOptimizationManager.startSleepMonitoring()

        let result = "Sleep tracking started."
        return .result(value: result)
    }
}

/// An App Intent to log water intake.
@available(iOS 18.0, *)
struct LogWaterIntakeAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water Intake"
    static var description = IntentDescription("Logs a specified amount of water intake.")

    @Parameter(title: "Amount", description: "The amount of water in milliliters.")
    var amount: Double

    @Dependency private var healthDataManager: HealthDataManager

    func perform() async throws -> some IntentResult & ProvidesStringResult {
        healthDataManager.logWaterIntake(amount: amount)

        let result = "Logged \(Int(amount)) ml of water intake."
        return .result(value: result)
    }
}

// MARK: - App Shortcuts Provider

/// A provider for App Shortcuts.
@available(iOS 18.0, *)
struct HealthAI2030Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetHeartRateAppIntent(),
            phrases: [
                "What's my heart rate in \(.applicationName)?",
                "Get my heart rate using \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: StartSleepTrackingAppIntent(),
            phrases: [
                "Start sleep tracking in \(.applicationName)",
                "Begin tracking my sleep with \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: LogWaterIntakeAppIntent(),
            phrases: [
                "Log water intake in \(.applicationName)",
                "I drank \(\.$amount) milliliters of water using \(.applicationName)"
            ]
        )
    }
}

// MARK: - Dependency Manager (Placeholder)

/// A placeholder dependency manager for App Intents.
/// In a real app, this would manage dependencies like HealthDataManager.
@available(iOS 18.0, *)
class AppDependencyManager {
    static let shared = AppDependencyManager()
    private var dependencies: [String: Any] = [:]

    func add<T>(_ dependency: T) {
        let key = String(describing: T.self)
        dependencies[key] = dependency
    }

    func get<T>() -> T {
        let key = String(describing: T.self)
        guard let dependency = dependencies[key] as? T else {
            fatalError("Dependency \(key) not found. Ensure it is added in AppDependencyManager.")
        }
        return dependency
    }
}

@available(iOS 18.0, *)
private struct Dependency: AppIntent.Dependency {
    func resolve<T>() -> T {
        AppDependencyManager.shared.get()
    }
}