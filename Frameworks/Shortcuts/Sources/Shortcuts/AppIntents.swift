import AppIntents
import HealthKit
import SwiftUI
import MentalHealth

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

/// An App Intent to get a daily health summary.
@available(iOS 18.0, *)
struct GetDailyHealthSummaryAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Daily Health Summary"
    static var description = IntentDescription("Gets a summary of the user's health data for the day.")

    func perform() async throws -> some IntentResult & ProvidesStringResult {
        let summary = DailyHealthSummaryProvider.getTodaysSummary()
        return .result(value: summary)
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
            intent: GetMentalHealthInsightsAppIntent(),
            phrases: [
                "What are my mental health insights in \(.applicationName)?",
                "Get mental health insights using \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: GetDailyHealthSummaryAppIntent(),
            phrases: [
                "What's my daily health summary in \(.applicationName)?",
                "Get my health summary for today using \(.applicationName)"
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
    private let lock = NSLock()

    /// Register a dependency instance for a given type.
    func add<T>(_ dependency: T) {
        let key = String(describing: T.self)
        lock.lock(); defer { lock.unlock() }
        dependencies[key] = dependency
    }

    /// Retrieve a dependency instance for a given type, or nil if not found.
    func get<T>() -> T? {
        let key = String(describing: T.self)
        lock.lock(); defer { lock.unlock() }
        guard let dependency = dependencies[key] as? T else {
            print("[AppDependencyManager] Warning: Dependency \(key) not found. Returning nil.")
            return nil
        }
        return dependency
    }

    /// Remove a dependency for a given type.
    func remove<T>(_ type: T.Type) {
        let key = String(describing: T.self)
        lock.lock(); defer { lock.unlock() }
        dependencies.removeValue(forKey: key)
    }

    /// Clear all dependencies (for testing or teardown).
    func clear() {
        lock.lock(); defer { lock.unlock() }
        dependencies.removeAll()
    }
}

/// Property wrapper for AppIntent dependency injection.
@available(iOS 18.0, *)
@propertyWrapper
struct Dependency<T>: DynamicProperty {
    private var value: T?
    public var wrappedValue: T {
        mutating get {
            if value == nil {
                value = AppDependencyManager.shared.get()
                if value == nil {
                    fatalError("[Dependency] Could not resolve dependency of type \(T.self). Make sure it is registered in AppDependencyManager.")
                }
            }
            return value!
        }
        set { value = newValue }
    }
    init() {}
}