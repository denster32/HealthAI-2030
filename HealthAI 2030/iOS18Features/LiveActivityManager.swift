import Foundation
import ActivityKit
import SwiftUI
import Combine
import OSLog

// MARK: - Live Activity Manager for iOS 18

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeSleepActivity: Activity<SleepTrackingAttributes>?
    @Published var activeWorkoutActivity: Activity<WorkoutTrackingAttributes>?
    @Published var activeHealthAlertActivity: Activity<HealthAlertAttributes>?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.healthai2030.liveactivity", category: "manager")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupActivityMonitoring()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        logger.info("Initializing Live Activity Manager")
        
        // Check for existing activities
        await checkExistingActivities()
        
        // Setup activity updates
        setupActivityUpdates()
    }
    
    // MARK: - Sleep Tracking Activity
    
    func startSleepTrackingActivity() async {
        logger.info("Starting sleep tracking Live Activity")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled")
            return
        }
        
        let attributes = SleepTrackingAttributes()
        let initialState = SleepTrackingAttributes.ContentState(
            sleepStage: .awake,
            sleepQuality: 0.0,
            duration: 0,
            heartRate: 0,
            temperature: 0,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: .token
            )
            
            await MainActor.run {
                self.activeSleepActivity = activity
            }
            
            logger.info("Sleep tracking Live Activity started with ID: \(activity.id)")
        } catch {
            logger.error("Failed to start sleep tracking Live Activity: \(error)")
        }
    }
    
    func updateSleepTrackingActivity(
        sleepStage: SleepStage,
        quality: Double,
        duration: TimeInterval,
        heartRate: Double,
        temperature: Double
    ) async {
        guard let activity = activeSleepActivity else {
            logger.warning("No active sleep tracking activity to update")
            return
        }
        
        let updatedState = SleepTrackingAttributes.ContentState(
            sleepStage: sleepStage,
            sleepQuality: quality,
            duration: duration,
            heartRate: heartRate,
            temperature: temperature,
            lastUpdated: Date()
        )
        
        await activity.update(.init(state: updatedState, staleDate: nil))
        logger.debug("Updated sleep tracking Live Activity")
    }
    
    func endSleepTrackingActivity() async {
        guard let activity = activeSleepActivity else {
            logger.warning("No active sleep tracking activity to end")
            return
        }
        
        let finalState = SleepTrackingAttributes.ContentState(
            sleepStage: .awake,
            sleepQuality: activity.content.state.sleepQuality,
            duration: activity.content.state.duration,
            heartRate: activity.content.state.heartRate,
            temperature: activity.content.state.temperature,
            lastUpdated: Date()
        )
        
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .default)
        
        await MainActor.run {
            self.activeSleepActivity = nil
        }
        
        logger.info("Ended sleep tracking Live Activity")
    }
    
    // MARK: - Workout Tracking Activity
    
    func startWorkoutActivity(workoutType: WorkoutType) async {
        logger.info("Starting workout tracking Live Activity for \(workoutType)")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled")
            return
        }
        
        let attributes = WorkoutTrackingAttributes()
        let initialState = WorkoutTrackingAttributes.ContentState(
            workoutType: workoutType,
            duration: 0,
            calories: 0,
            heartRate: 0,
            pace: 0,
            distance: 0,
            isActive: true,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: .token
            )
            
            await MainActor.run {
                self.activeWorkoutActivity = activity
            }
            
            logger.info("Workout tracking Live Activity started with ID: \(activity.id)")
        } catch {
            logger.error("Failed to start workout tracking Live Activity: \(error)")
        }
    }
    
    func updateWorkoutActivity(
        duration: TimeInterval,
        calories: Double,
        heartRate: Double,
        pace: Double,
        distance: Double
    ) async {
        guard let activity = activeWorkoutActivity else {
            logger.warning("No active workout activity to update")
            return
        }
        
        let updatedState = WorkoutTrackingAttributes.ContentState(
            workoutType: activity.content.state.workoutType,
            duration: duration,
            calories: calories,
            heartRate: heartRate,
            pace: pace,
            distance: distance,
            isActive: true,
            lastUpdated: Date()
        )
        
        await activity.update(.init(state: updatedState, staleDate: nil))
        logger.debug("Updated workout tracking Live Activity")
    }
    
    func endWorkoutActivity() async {
        guard let activity = activeWorkoutActivity else {
            logger.warning("No active workout activity to end")
            return
        }
        
        let finalState = WorkoutTrackingAttributes.ContentState(
            workoutType: activity.content.state.workoutType,
            duration: activity.content.state.duration,
            calories: activity.content.state.calories,
            heartRate: activity.content.state.heartRate,
            pace: activity.content.state.pace,
            distance: activity.content.state.distance,
            isActive: false,
            lastUpdated: Date()
        )
        
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .default)
        
        await MainActor.run {
            self.activeWorkoutActivity = nil
        }
        
        logger.info("Ended workout tracking Live Activity")
    }
    
    // MARK: - Health Alert Activity
    
    func startHealthAlertActivity(alert: HealthAlert) async {
        logger.info("Starting health alert Live Activity")
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled")
            return
        }
        
        let attributes = HealthAlertAttributes()
        let initialState = HealthAlertAttributes.ContentState(
            alertType: alert.type,
            severity: alert.severity,
            message: alert.message,
            actionRequired: alert.actionRequired,
            timestamp: alert.timestamp,
            isResolved: false
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: .token
            )
            
            await MainActor.run {
                self.activeHealthAlertActivity = activity
            }
            
            logger.info("Health alert Live Activity started with ID: \(activity.id)")
        } catch {
            logger.error("Failed to start health alert Live Activity: \(error)")
        }
    }
    
    func resolveHealthAlertActivity() async {
        guard let activity = activeHealthAlertActivity else {
            logger.warning("No active health alert activity to resolve")
            return
        }
        
        let resolvedState = HealthAlertAttributes.ContentState(
            alertType: activity.content.state.alertType,
            severity: activity.content.state.severity,
            message: activity.content.state.message,
            actionRequired: activity.content.state.actionRequired,
            timestamp: activity.content.state.timestamp,
            isResolved: true
        )
        
        await activity.update(.init(state: resolvedState, staleDate: nil))
        
        // End the activity after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Task {
                await activity.end(.init(state: resolvedState, staleDate: nil), dismissalPolicy: .default)
                await MainActor.run {
                    self.activeHealthAlertActivity = nil
                }
            }
        }
        
        logger.info("Resolved health alert Live Activity")
    }
    
    // MARK: - Activity Management
    
    func updateActivities() async {
        logger.debug("Updating all Live Activities")
        
        // Update activities with latest data
        if activeSleepActivity != nil {
            // Get latest sleep data and update
            await updateSleepDataFromManagers()
        }
        
        if activeWorkoutActivity != nil {
            // Get latest workout data and update
            await updateWorkoutDataFromManagers()
        }
    }
    
    func endAllActivities() async {
        logger.info("Ending all Live Activities")
        
        if activeSleepActivity != nil {
            await endSleepTrackingActivity()
        }
        
        if activeWorkoutActivity != nil {
            await endWorkoutActivity()
        }
        
        if activeHealthAlertActivity != nil {
            await resolveHealthAlertActivity()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupActivityMonitoring() {
        // Monitor activity state changes
        NotificationCenter.default.publisher(for: .sleepTrackingStarted)
            .sink { [weak self] _ in
                Task {
                    await self?.startSleepTrackingActivity()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .sleepTrackingEnded)
            .sink { [weak self] _ in
                Task {
                    await self?.endSleepTrackingActivity()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .workoutStarted)
            .compactMap { $0.object as? WorkoutType }
            .sink { [weak self] workoutType in
                Task {
                    await self?.startWorkoutActivity(workoutType: workoutType)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .workoutEnded)
            .sink { [weak self] _ in
                Task {
                    await self?.endWorkoutActivity()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .healthAlertTriggered)
            .compactMap { $0.object as? HealthAlert }
            .sink { [weak self] alert in
                Task {
                    await self?.startHealthAlertActivity(alert: alert)
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkExistingActivities() async {
        // Check for existing sleep tracking activities
        for activity in Activity<SleepTrackingAttributes>.activities {
            if activity.activityState == .active {
                await MainActor.run {
                    self.activeSleepActivity = activity
                }
                logger.info("Found existing sleep tracking Live Activity")
                break
            }
        }
        
        // Check for existing workout activities
        for activity in Activity<WorkoutTrackingAttributes>.activities {
            if activity.activityState == .active {
                await MainActor.run {
                    self.activeWorkoutActivity = activity
                }
                logger.info("Found existing workout tracking Live Activity")
                break
            }
        }
        
        // Check for existing health alert activities
        for activity in Activity<HealthAlertAttributes>.activities {
            if activity.activityState == .active {
                await MainActor.run {
                    self.activeHealthAlertActivity = activity
                }
                logger.info("Found existing health alert Live Activity")
                break
            }
        }
    }
    
    private func setupActivityUpdates() {
        // Setup periodic updates for active activities
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.updateActivities()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateSleepDataFromManagers() async {
        // This would integrate with actual health managers
        // For now, using placeholder values
        await updateSleepTrackingActivity(
            sleepStage: .light,
            quality: 0.75,
            duration: 3600, // 1 hour
            heartRate: 65,
            temperature: 98.6
        )
    }
    
    private func updateWorkoutDataFromManagers() async {
        // This would integrate with actual workout managers
        // For now, using placeholder values
        await updateWorkoutActivity(
            duration: 1800, // 30 minutes
            calories: 250,
            heartRate: 140,
            pace: 8.5, // minutes per mile
            distance: 3.5 // miles
        )
    }
}

// MARK: - Activity Attributes

struct SleepTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let sleepStage: SleepStage
        let sleepQuality: Double
        let duration: TimeInterval
        let heartRate: Double
        let temperature: Double
        let lastUpdated: Date
    }
}

struct WorkoutTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let workoutType: WorkoutType
        let duration: TimeInterval
        let calories: Double
        let heartRate: Double
        let pace: Double
        let distance: Double
        let isActive: Bool
        let lastUpdated: Date
    }
}

struct HealthAlertAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let alertType: HealthAlertType
        let severity: AlertSeverity
        let message: String
        let actionRequired: Bool
        let timestamp: Date
        let isResolved: Bool
    }
}

// MARK: - Supporting Types

enum WorkoutType: String, Codable, CaseIterable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case yoga = "yoga"
    case strength = "strength"
    case cardio = "cardio"
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .strength: return "Strength Training"
        case .cardio: return "Cardio"
        }
    }
    
    var emoji: String {
        switch self {
        case .running: return "🏃‍♂️"
        case .walking: return "🚶‍♂️"
        case .cycling: return "🚴‍♂️"
        case .swimming: return "🏊‍♂️"
        case .yoga: return "🧘‍♂️"
        case .strength: return "💪"
        case .cardio: return "❤️"
        }
    }
}

enum HealthAlertType: String, Codable, CaseIterable {
    case heartRateAnomaly = "heart_rate_anomaly"
    case sleepDisruption = "sleep_disruption"
    case stressLevel = "stress_level"
    case hydrationReminder = "hydration_reminder"
    case medicationReminder = "medication_reminder"
    case exerciseReminder = "exercise_reminder"
    
    var displayName: String {
        switch self {
        case .heartRateAnomaly: return "Heart Rate Alert"
        case .sleepDisruption: return "Sleep Alert"
        case .stressLevel: return "Stress Alert"
        case .hydrationReminder: return "Hydration Reminder"
        case .medicationReminder: return "Medication Reminder"
        case .exerciseReminder: return "Exercise Reminder"
        }
    }
    
    var emoji: String {
        switch self {
        case .heartRateAnomaly: return "💓"
        case .sleepDisruption: return "😴"
        case .stressLevel: return "😰"
        case .hydrationReminder: return "💧"
        case .medicationReminder: return "💊"
        case .exerciseReminder: return "🏃‍♂️"
        }
    }
}

enum AlertSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let sleepTrackingStarted = Notification.Name("sleepTrackingStarted")
    static let sleepTrackingEnded = Notification.Name("sleepTrackingEnded")
    static let workoutStarted = Notification.Name("workoutStarted")
    static let workoutEnded = Notification.Name("workoutEnded")
    static let healthAlertTriggered = Notification.Name("healthAlertTriggered")
}

// MARK: - Health Alert Model

struct HealthAlert {
    let type: HealthAlertType
    let severity: AlertSeverity
    let message: String
    let actionRequired: Bool
    let timestamp: Date
}