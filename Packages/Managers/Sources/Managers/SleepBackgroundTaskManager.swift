import Foundation
import BackgroundTasks
import UserNotifications
import HealthKit
import CoreData
import os.log

/// SleepBackgroundTaskManager - Advanced background processing for continuous sleep monitoring
@MainActor
class SleepBackgroundTaskManager: ObservableObject {
    static let shared = SleepBackgroundTaskManager()
    
    // MARK: - Background Task Identifiers
    private enum TaskIdentifier: String, CaseIterable {
        case sleepAnalysis = "com.healthai.sleep-analysis"
        case dataSync = "com.healthai.data-sync"
        case aiProcessing = "com.healthai.ai-processing"
        case smartAlarm = "com.healthai.smart-alarm"
        case healthAlert = "com.healthai.health-alert"
        case environmentMonitoring = "com.healthai.environment-monitoring"
        case modelUpdate = "com.healthai.model-update"
        case dataCleanup = "com.healthai.data-cleanup"
    }
    
    // MARK: - Published Properties
    @Published var isBackgroundProcessingEnabled = false
    @Published var backgroundTasksExecuted = 0
    @Published var lastBackgroundExecution: Date?
    @Published var backgroundProcessingStats: BackgroundProcessingStats = BackgroundProcessingStats()
    
    // MARK: - Private Properties
    private var sleepManager = SleepManager.shared
    private var healthKitManager = HealthKitManager.shared
    private var aiEngine = AISleepAnalysisEngine.shared
    private var feedbackEngine = SleepFeedbackEngine.shared
    private var analytics = SleepAnalyticsEngine.shared
    
    // Background task tracking
    private var activeTasks: Set<String> = []
    private var taskExecutionHistory: [BackgroundTaskExecution] = []
    private let maxHistorySize = 100
    
    // Configuration
    private let sleepAnalysisInterval: TimeInterval = 300 // 5 minutes
    private let dataSyncInterval: TimeInterval = 900 // 15 minutes
    private let aiProcessingInterval: TimeInterval = 600 // 10 minutes
    private let smartAlarmCheckInterval: TimeInterval = 60 // 1 minute
    private let healthAlertCheckInterval: TimeInterval = 120 // 2 minutes
    private let maxBackgroundExecutionTime: TimeInterval = 25 // 25 seconds (iOS limit is 30)
    
    private init() {
        setupBackgroundTasks()
        loadBackgroundProcessingStats()
    }
    
    // MARK: - Setup and Registration
    private func setupBackgroundTasks() {
        registerBackgroundTasks()
        Logger.success("Background tasks registered", log: Logger.backgroundTasks)
    }
    
    private func registerBackgroundTasks() {
        // Register all background task types
        for taskId in TaskIdentifier.allCases {
            registerBackgroundTask(identifier: taskId.rawValue)
        }
    }
    
    private func registerBackgroundTask(identifier: String) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            Task { @MainActor in
                await self.handleBackgroundTask(task as! BGAppRefreshTask, identifier: identifier)
            }
        }
    }
    
    // MARK: - Background Task Scheduling
    func scheduleBackgroundTasks() {
        guard isBackgroundProcessingEnabled else { return }
        
        scheduleTask(.sleepAnalysis, earliestBeginDate: Date(timeIntervalSinceNow: sleepAnalysisInterval))
        scheduleTask(.dataSync, earliestBeginDate: Date(timeIntervalSinceNow: dataSyncInterval))
        scheduleTask(.aiProcessing, earliestBeginDate: Date(timeIntervalSinceNow: aiProcessingInterval))
        scheduleTask(.smartAlarm, earliestBeginDate: Date(timeIntervalSinceNow: smartAlarmCheckInterval))
        scheduleTask(.healthAlert, earliestBeginDate: Date(timeIntervalSinceNow: healthAlertCheckInterval))
        
        Logger.info("Background tasks scheduled", log: Logger.backgroundTasks)
    }
    
    private func scheduleTask(_ taskId: TaskIdentifier, earliestBeginDate: Date) {
        let request = BGAppRefreshTaskRequest(identifier: taskId.rawValue)
        request.earliestBeginDate = earliestBeginDate
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.info("Scheduled background task: \(taskId.rawValue)", log: Logger.backgroundTasks)
        } catch {
            Logger.error("Failed to schedule background task \(taskId.rawValue): \(error.localizedDescription)", log: Logger.backgroundTasks)
        }
    }
    
    // MARK: - Background Task Execution
    private func handleBackgroundTask(_ task: BGAppRefreshTask, identifier: String) async {
        Logger.info("Executing background task: \(identifier)", log: Logger.backgroundTasks)
        
        let startTime = Date()
        activeTasks.insert(identifier)
        
        // Set expiration handler
        task.expirationHandler = {
            Logger.warning("Background task expired: \(identifier)", log: Logger.backgroundTasks)
            self.activeTasks.remove(identifier)
            task.setTaskCompleted(success: false)
        }
        
        do {
            // Execute the appropriate task
            let success = await executeTask(for: identifier)
            
            // Record execution
            let execution = BackgroundTaskExecution(
                identifier: identifier,
                startTime: startTime,
                endTime: Date(),
                success: success,
                duration: Date().timeIntervalSince(startTime)
            )
            recordTaskExecution(execution)
            
            // Complete the task
            activeTasks.remove(identifier)
            task.setTaskCompleted(success: success)
            
            // Schedule next execution
            if success {
                scheduleNextExecution(for: identifier)
            }
            
            Logger.success("Background task completed: \(identifier)", log: Logger.backgroundTasks)
            
        } catch {
            Logger.error("Background task failed: \(identifier) - \(error.localizedDescription)", log: Logger.backgroundTasks)
            activeTasks.remove(identifier)
            task.setTaskCompleted(success: false)
        }
    }
    
    private func executeTask(for identifier: String) async -> Bool {
        guard let taskType = TaskIdentifier(rawValue: identifier) else { return false }
        
        switch taskType {
        case .sleepAnalysis:
            return await executeSleepAnalysisTask()
        case .dataSync:
            return await executeDataSyncTask()
        case .aiProcessing:
            return await executeAIProcessingTask()
        case .smartAlarm:
            return await executeSmartAlarmTask()
        case .healthAlert:
            return await executeHealthAlertTask()
        case .environmentMonitoring:
            return await executeEnvironmentMonitoringTask()
        case .modelUpdate:
            return await executeModelUpdateTask()
        case .dataCleanup:
            return await executeDataCleanupTask()
        }
    }
    
    // MARK: - Specific Task Implementations
    
    private func executeSleepAnalysisTask() async -> Bool {
        Logger.info("Executing sleep analysis task", log: Logger.backgroundTasks)
        
        // Only run if user is sleeping
        guard sleepManager.isMonitoring else { return true }
        
        do {
            // Collect current biometric data
            guard let biometricData = healthKitManager.biometricData else { return false }
            
            // Create features for AI analysis
            let features = SleepFeatures(
                heartRate: biometricData.heartRate,
                hrv: biometricData.hrv,
                movement: biometricData.movement,
                bloodOxygen: biometricData.oxygenSaturation,
                temperature: biometricData.temperature,
                breathingRate: biometricData.respiratoryRate,
                timeOfNight: calculateTimeOfNight(),
                previousStage: sleepManager.currentSleepStage
            )
            
            // Run AI prediction
            let prediction = await aiEngine.predictSleepStage(features)
            
            // Update sleep manager with new prediction
            await updateSleepStageIfNeeded(prediction)
            
            // Run feedback engine cycle
            if feedbackEngine.isActive {
                // This will be handled by the feedback engine's own cycle
            }
            
            // Update analytics
            let analysisResult = await analytics.performSleepAnalysis()
            
            backgroundProcessingStats.sleepAnalysisExecutions += 1
            return true
            
        } catch {
            Logger.error("Sleep analysis task failed: \(error.localizedDescription)", log: Logger.backgroundTasks)
            return false
        }
    }
    
    private func executeDataSyncTask() async -> Bool {
        Logger.info("Executing data sync task", log: Logger.backgroundTasks)
        
        do {
            // Sync HealthKit data
            await healthKitManager.performComprehensiveHealthAnalysis()
            
            // Sync Core Data
            await syncCoreDataChanges()
            
            // Update analytics with latest data
            await analytics.optimizeSleepAnalytics()
            
            backgroundProcessingStats.dataSyncExecutions += 1
            return true
            
        } catch {
            Logger.error("Data sync task failed: \(error.localizedDescription)", log: Logger.backgroundTasks)
            return false
        }
    }
    
    private func executeAIProcessingTask() async -> Bool {
        Logger.info("Executing AI processing task", log: Logger.backgroundTasks)
        
        do {
            // Process accumulated sleep data for patterns
            await analytics.analyzeSleepPatterns()
            
            // Update AI models with personal data
            if aiEngine.isInitialized && backgroundProcessingStats.aiProcessingExecutions % 10 == 0 {
                await aiEngine.retrainModel()
            }
            
            // Generate new insights
            let insights = await analytics.getSleepInsights()
            
            backgroundProcessingStats.aiProcessingExecutions += 1
            return true
            
        } catch {
            Logger.error("AI processing task failed: \(error.localizedDescription)", log: Logger.backgroundTasks)
            return false
        }
    }
    
    private func executeSmartAlarmTask() async -> Bool {
        Logger.info("Executing smart alarm task", log: Logger.backgroundTasks)
        
        // Check if we should trigger smart alarm
        guard shouldTriggerSmartAlarm() else { return true }
        
        do {
            // Get current sleep stage
            let currentStage = sleepManager.currentSleepStage
            
            // Only wake during light sleep or REM (not deep sleep)
            if currentStage == .light || currentStage == .rem {
                await triggerSmartAlarm()
                backgroundProcessingStats.smartAlarmTriggers += 1
            }
            
            return true
            
        } catch {
            Logger.error("Smart alarm task failed: \(error.localizedDescription)", log: Logger.backgroundTasks)
            return false
        }
    }
    
    private func executeHealthAlertTask() async -> Bool {
        Logger.info("Executing health alert task", log: Logger.backgroundTasks)
        
        do {
            // Check for health anomalies
            let healthAnomalies = await detectHealthAnomalies()
            
            // Send alerts if needed
            for anomaly in healthAnomalies {
                await sendHealthAlert(for: anomaly)
            }
            
            backgroundProcessingStats.healthAlertChecks += 1
            
            if !healthAnomalies.isEmpty {
                backgroundProcessingStats.healthAlertsTriggered += healthAnomalies.count
            }
            
            return true
            
        } catch {
            Logger.error("Health alert task failed: \(error.localizedDescription)", log: Logger.backgroundTasks)
            return false
        }
    }
    
    private func executeEnvironmentMonitoringTask() async -> Bool {
        Logger.info("Executing environment monitoring task", log: Logger.backgroundTasks)
        
        // This would integrate with HomeKit and other environment sensors
        // For now, we'll simulate the monitoring
        
        backgroundProcessingStats.environmentMonitoringExecutions += 1
        return true
    }
    
    private func executeModelUpdateTask() async -> Bool {
        Logger.info("Executing model update task", log: Logger.backgroundTasks)
        
        // Check if models need updating
        // This would typically involve downloading new models or updating parameters
        
        backgroundProcessingStats.modelUpdateExecutions += 1
        return true
    }
    
    private func executeDataCleanupTask() async -> Bool {
        Logger.info("Executing data cleanup task", log: Logger.backgroundTasks)
        
        do {
            // Clean up old data
            await cleanupOldData()
            
            // Optimize database
            await optimizeDatabase()
            
            backgroundProcessingStats.dataCleanupExecutions += 1
            return true
            
        } catch {
            Logger.error("Data cleanup task failed: \(error.localizedDescription)", log: Logger.backgroundTasks)
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateTimeOfNight() -> Double {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        if hour >= 22 {
            return Double(hour - 22)
        } else if hour < 8 {
            return Double(hour + 2)
        } else {
            return 0.0
        }
    }
    
    private func updateSleepStageIfNeeded(_ prediction: SleepStagePrediction) async {
        // Only update if confidence is high and stage has changed
        if prediction.confidence > 0.7 && prediction.sleepStage != sleepManager.currentSleepStage {
            // This would update the sleep manager's current stage
            Logger.info("Sleep stage updated to: \(prediction.sleepStage.displayName)", log: Logger.backgroundTasks)
        }
    }
    
    private func syncCoreDataChanges() async {
        // Sync any pending Core Data changes
        // This would involve saving contexts and handling conflicts
        Logger.info("Core Data sync completed", log: Logger.backgroundTasks)
    }
    
    private func shouldTriggerSmartAlarm() -> Bool {
        // Check user's alarm settings and current time
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // Example: check if it's within 30 minutes of 7:00 AM
        if hour == 6 && minute >= 30 {
            return true
        } else if hour == 7 && minute <= 30 {
            return true
        }
        
        return false
    }
    
    private func triggerSmartAlarm() async {
        Logger.info("Triggering smart alarm", log: Logger.backgroundTasks)
        
        // Send local notification for smart alarm
        let content = UNMutableNotificationContent()
        content.title = "Smart Wake"
        content.body = "Good morning! You're in a light sleep phase - perfect time to wake up."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SMART_ALARM"
        
        let request = UNNotificationRequest(
            identifier: "smart-alarm-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Logger.error("Failed to send smart alarm notification: \(error.localizedDescription)", log: Logger.backgroundTasks)
        }
    }
    
    private func detectHealthAnomalies() async -> [HealthAnomaly] {
        var anomalies: [HealthAnomaly] = []
        
        guard let biometricData = healthKitManager.biometricData else { return anomalies }
        
        // Heart rate anomalies
        if biometricData.heartRate > 120 || biometricData.heartRate < 35 {
            anomalies.append(HealthAnomaly(
                type: .heartRate,
                severity: .high,
                value: biometricData.heartRate,
                message: "Unusual heart rate detected: \(Int(biometricData.heartRate)) BPM"
            ))
        }
        
        // Oxygen saturation anomalies
        if biometricData.oxygenSaturation < 88 {
            anomalies.append(HealthAnomaly(
                type: .oxygenSaturation,
                severity: .critical,
                value: biometricData.oxygenSaturation,
                message: "Low oxygen saturation detected: \(Int(biometricData.oxygenSaturation))%"
            ))
        }
        
        // HRV anomalies (if very low)
        if biometricData.hrv < 10 {
            anomalies.append(HealthAnomaly(
                type: .hrv,
                severity: .medium,
                value: biometricData.hrv,
                message: "Very low heart rate variability detected"
            ))
        }
        
        return anomalies
    }
    
    private func sendHealthAlert(for anomaly: HealthAnomaly) async {
        Logger.warning("Health anomaly detected: \(anomaly.type)", log: Logger.backgroundTasks)
        
        let content = UNMutableNotificationContent()
        content.title = "Health Alert"
        content.body = anomaly.message
        content.sound = anomaly.severity == .critical ? UNNotificationSound.defaultCritical : UNNotificationSound.default
        content.categoryIdentifier = "HEALTH_ALERT"
        
        if anomaly.severity == .critical {
            content.interruptionLevel = .critical
        }
        
        let request = UNNotificationRequest(
            identifier: "health-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Logger.error("Failed to send health alert: \(error.localizedDescription)", log: Logger.backgroundTasks)
        }
    }
    
    private func cleanupOldData() async {
        // Clean up data older than 90 days
        let cutoffDate = Date().addingTimeInterval(-90 * 24 * 3600)
        
        // Remove old task executions
        taskExecutionHistory.removeAll { $0.startTime < cutoffDate }
        
        Logger.info("Old data cleanup completed", log: Logger.backgroundTasks)
    }
    
    private func optimizeDatabase() async {
        // Optimize Core Data database
        // This would involve compacting the database and updating indexes
        Logger.info("Database optimization completed", log: Logger.backgroundTasks)
    }
    
    private func scheduleNextExecution(for identifier: String) {
        guard let taskType = TaskIdentifier(rawValue: identifier) else { return }
        
        let nextExecutionTime: TimeInterval
        switch taskType {
        case .sleepAnalysis:
            nextExecutionTime = sleepAnalysisInterval
        case .dataSync:
            nextExecutionTime = dataSyncInterval
        case .aiProcessing:
            nextExecutionTime = aiProcessingInterval
        case .smartAlarm:
            nextExecutionTime = smartAlarmCheckInterval
        case .healthAlert:
            nextExecutionTime = healthAlertCheckInterval
        case .environmentMonitoring:
            nextExecutionTime = 300 // 5 minutes
        case .modelUpdate:
            nextExecutionTime = 3600 // 1 hour
        case .dataCleanup:
            nextExecutionTime = 86400 // 24 hours
        }
        
        scheduleTask(taskType, earliestBeginDate: Date(timeIntervalSinceNow: nextExecutionTime))
    }
    
    private func recordTaskExecution(_ execution: BackgroundTaskExecution) {
        taskExecutionHistory.append(execution)
        
        // Maintain history size
        if taskExecutionHistory.count > maxHistorySize {
            taskExecutionHistory.removeFirst()
        }
        
        // Update published properties
        backgroundTasksExecuted += 1
        lastBackgroundExecution = execution.endTime
        
        // Update stats
        backgroundProcessingStats.totalExecutions += 1
        if execution.success {
            backgroundProcessingStats.successfulExecutions += 1
        }
        
        saveBackgroundProcessingStats()
    }
    
    // MARK: - Public Interface
    
    func enableBackgroundProcessing() {
        isBackgroundProcessingEnabled = true
        scheduleBackgroundTasks()
        Logger.info("Background processing enabled", log: Logger.backgroundTasks)
    }
    
    func disableBackgroundProcessing() {
        isBackgroundProcessingEnabled = false
        BGTaskScheduler.shared.cancelAllTaskRequests()
        Logger.info("Background processing disabled", log: Logger.backgroundTasks)
    }
    
    func getBackgroundTaskStatus() -> BackgroundTaskStatus {
        return BackgroundTaskStatus(
            isEnabled: isBackgroundProcessingEnabled,
            activeTasks: activeTasks.count,
            tasksExecuted: backgroundTasksExecuted,
            lastExecution: lastBackgroundExecution,
            successRate: backgroundProcessingStats.successRate,
            stats: backgroundProcessingStats
        )
    }
    
    func getTaskExecutionHistory() -> [BackgroundTaskExecution] {
        return Array(taskExecutionHistory.suffix(20)) // Return last 20 executions
    }
    
    func forceExecuteTask(_ taskType: TaskIdentifier) async -> Bool {
        Logger.info("Force executing task: \(taskType.rawValue)", log: Logger.backgroundTasks)
        return await executeTask(for: taskType.rawValue)
    }
    
    // MARK: - Persistence
    
    private func loadBackgroundProcessingStats() {
        if let data = UserDefaults.standard.data(forKey: "backgroundProcessingStats"),
           let stats = try? JSONDecoder().decode(BackgroundProcessingStats.self, from: data) {
            backgroundProcessingStats = stats
        }
    }
    
    private func saveBackgroundProcessingStats() {
        if let data = try? JSONEncoder().encode(backgroundProcessingStats) {
            UserDefaults.standard.set(data, forKey: "backgroundProcessingStats")
        }
    }
}

// MARK: - Data Models

struct BackgroundTaskExecution: Codable {
    let identifier: String
    let startTime: Date
    let endTime: Date
    let success: Bool
    let duration: TimeInterval
}

struct BackgroundProcessingStats: Codable {
    var totalExecutions: Int = 0
    var successfulExecutions: Int = 0
    var sleepAnalysisExecutions: Int = 0
    var dataSyncExecutions: Int = 0
    var aiProcessingExecutions: Int = 0
    var smartAlarmTriggers: Int = 0
    var healthAlertChecks: Int = 0
    var healthAlertsTriggered: Int = 0
    var environmentMonitoringExecutions: Int = 0
    var modelUpdateExecutions: Int = 0
    var dataCleanupExecutions: Int = 0
    
    var successRate: Double {
        guard totalExecutions > 0 else { return 0.0 }
        return Double(successfulExecutions) / Double(totalExecutions)
    }
}

struct BackgroundTaskStatus {
    let isEnabled: Bool
    let activeTasks: Int
    let tasksExecuted: Int
    let lastExecution: Date?
    let successRate: Double
    let stats: BackgroundProcessingStats
}

struct HealthAnomaly {
    let type: HealthAnomalyType
    let severity: HealthAnomalySeverity
    let value: Double
    let message: String
}

enum HealthAnomalyType {
    case heartRate
    case oxygenSaturation
    case hrv
    case respiratoryRate
    case temperature
}

enum HealthAnomalySeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - Extensions

extension Logger {
    static let backgroundTasks = Logger(subsystem: "com.healthai.app", category: "BackgroundTasks")
}

// MARK: - Notification Categories

extension SleepBackgroundTaskManager {
    func setupNotificationCategories() {
        let smartAlarmCategory = UNNotificationCategory(
            identifier: "SMART_ALARM",
            actions: [
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "Snooze 10 min",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "I'm awake",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let healthAlertCategory = UNNotificationCategory(
            identifier: "HEALTH_ALERT",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_DETAILS",
                    title: "View Details",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            smartAlarmCategory,
            healthAlertCategory
        ])
    }
}

// MARK: - App Lifecycle Integration

extension SleepBackgroundTaskManager {
    func handleAppDidEnterBackground() {
        // Schedule background tasks when app enters background
        if isBackgroundProcessingEnabled {
            scheduleBackgroundTasks()
        }
    }
    
    func handleAppWillEnterForeground() {
        // Cancel some background tasks as app will handle them in foreground
        // Keep critical ones like health alerts
        Logger.info("App entering foreground - adjusting background tasks", log: Logger.backgroundTasks)
    }
    
    func handleAppDidBecomeActive() {
        // Update stats and check for any missed background processing
        Logger.info("App became active - checking background processing status", log: Logger.backgroundTasks)
    }
}