import Foundation
import BackgroundTasks
import UIKit

class BackgroundTaskScheduler {
    static let shared = BackgroundTaskScheduler()
    
    private let healthDataSyncTaskIdentifier = "com.healthai2030.healthDataSync"
    private let sleepAnalysisTaskIdentifier = "com.healthai2030.sleepAnalysis"
    private let modelUpdateTaskIdentifier = "com.healthai2030.modelUpdate"
    private let environmentSyncTaskIdentifier = "com.healthai2030.environmentSync"
    
    private init() {}
    
    // MARK: - Task Registration
    
    func registerBackgroundTasks() {
        registerHealthDataSyncTask()
        registerSleepAnalysisTask()
        registerModelUpdateTask()
        registerEnvironmentSyncTask()
    }
    
    private func registerHealthDataSyncTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: healthDataSyncTaskIdentifier, using: nil) { task in
            self.handleHealthDataSync(task: task as! BGAppRefreshTask)
        }
    }
    
    private func registerSleepAnalysisTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: sleepAnalysisTaskIdentifier, using: nil) { task in
            self.handleSleepAnalysis(task: task as! BGProcessingTask)
        }
    }
    
    private func registerModelUpdateTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: modelUpdateTaskIdentifier, using: nil) { task in
            self.handleModelUpdate(task: task as! BGProcessingTask)
        }
    }
    
    private func registerEnvironmentSyncTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: environmentSyncTaskIdentifier, using: nil) { task in
            self.handleEnvironmentSync(task: task as! BGAppRefreshTask)
        }
    }
    
    // MARK: - Task Scheduling
    
    func scheduleHealthDataSync() {
        let request = BGAppRefreshTaskRequest(identifier: healthDataSyncTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Health data sync task scheduled")
        } catch {
            print("Failed to schedule health data sync task: \(error)")
        }
    }
    
    func scheduleSleepAnalysis() {
        let request = BGProcessingTaskRequest(identifier: sleepAnalysisTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Sleep analysis task scheduled")
        } catch {
            print("Failed to schedule sleep analysis task: \(error)")
        }
    }
    
    func scheduleModelUpdate() {
        let request = BGProcessingTaskRequest(identifier: modelUpdateTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Model update task scheduled")
        } catch {
            print("Failed to schedule model update task: \(error)")
        }
    }
    
    func scheduleEnvironmentSync() {
        let request = BGAppRefreshTaskRequest(identifier: environmentSyncTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10 * 60) // 10 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Environment sync task scheduled")
        } catch {
            print("Failed to schedule environment sync task: \(error)")
        }
    }
    
    // MARK: - Task Handlers
    
    private func handleHealthDataSync(task: BGAppRefreshTask) {
        // Schedule the next sync
        scheduleHealthDataSync()
        
        // Create a task to track background execution
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform health data sync
        let healthManager = HealthDataManager.shared
        healthManager.refreshData()
        
        // Save data to Core Data
        let healthData = HealthDataSnapshot(
            heartRate: healthManager.currentHeartRate,
            hrv: healthManager.currentHRV,
            oxygenSaturation: healthManager.currentOxygenSaturation,
            bodyTemperature: healthManager.currentBodyTemperature,
            stepCount: healthManager.stepCount,
            activeEnergyBurned: healthManager.activeEnergyBurned,
            sleepData: healthManager.sleepData,
            timestamp: Date()
        )
        
        CoreDataManager.shared.saveHealthData(healthData)
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
    }
    
    private func handleSleepAnalysis(task: BGProcessingTask) {
        // Schedule the next analysis
        scheduleSleepAnalysis()
        
        // Create a task to track background execution
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform sleep analysis
        let sleepManager = SleepOptimizationManager.shared
        let sleepReport = sleepManager.getSleepReport()
        
        // Save sleep report to Core Data
        CoreDataManager.shared.saveSleepReport(sleepReport)
        
        // Update sleep metrics
        sleepManager.updateSleepMetrics()
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
    }
    
    private func handleModelUpdate(task: BGProcessingTask) {
        // Schedule the next update
        scheduleModelUpdate()
        
        // Create a task to track background execution
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform model updates
        let mlManager = MLModelManager.shared
        
        // Update models with new data
        let trainingData = generateTrainingData()
        mlManager.updateModelLocally(trainingData: trainingData)
        
        // Sync with federated learning server
        mlManager.syncWithFederatedServer()
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
    }
    
    private func handleEnvironmentSync(task: BGAppRefreshTask) {
        // Schedule the next sync
        scheduleEnvironmentSync()
        
        // Create a task to track background execution
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform environment sync
        let environmentManager = EnvironmentManager.shared
        let environmentData = environmentManager.getCurrentEnvironment()
        
        // Save environment data to Core Data
        CoreDataManager.shared.saveEnvironmentData(environmentData)
        
        // Check for environment alerts
        let airQualityHealth = environmentManager.checkAirQualityHealth()
        if airQualityHealth.hasAlerts() {
            // Handle environment alerts
            handleEnvironmentAlerts(airQualityHealth.getAlerts())
        }
        
        // Mark task as completed
        task.setTaskCompleted(success: true)
    }
    
    // MARK: - Helper Methods
    
    private func generateTrainingData() -> [TrainingSample] {
        // Generate training data from recent health data
        let recentHealthData = CoreDataManager.shared.loadHealthData(for: Date())
        
        return recentHealthData.map { entity in
            TrainingSample(
                features: [
                    entity.heartRate,
                    entity.hrv,
                    entity.oxygenSaturation,
                    entity.bodyTemperature
                ],
                label: 1.0, // Would be determined by health status
                timestamp: entity.timestamp ?? Date()
            )
        }
    }
    
    private func handleEnvironmentAlerts(_ alerts: [EnvironmentAlert]) {
        for alert in alerts {
            // Create health alert from environment alert
            let healthAlert = HealthAlert(
                type: .environmental,
                severity: alert.severity,
                message: alert.message,
                timestamp: alert.timestamp,
                confidence: 0.9,
                recommendedAction: "Check environment settings"
            )
            
            // Save to Core Data
            CoreDataManager.shared.saveHealthAlert(healthAlert)
            
            // Send notification if needed
            if alert.severity == .high || alert.severity == .critical {
                sendEnvironmentAlertNotification(alert)
            }
        }
    }
    
    private func sendEnvironmentAlertNotification(_ alert: EnvironmentAlert) {
        let content = UNMutableNotificationContent()
        content.title = "Environment Alert"
        content.body = alert.message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send environment alert notification: \(error)")
            }
        }
    }
    
    // MARK: - Task Management
    
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        print("All background tasks cancelled")
    }
    
    func getPendingTasks() -> [String] {
        // This would require additional implementation to track pending tasks
        // For now, return empty array
        return []
    }
    
    // MARK: - Periodic Scheduling
    
    func startPeriodicScheduling() {
        // Schedule initial tasks
        scheduleHealthDataSync()
        scheduleSleepAnalysis()
        scheduleModelUpdate()
        scheduleEnvironmentSync()
        
        // Set up periodic scheduling
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.scheduleHealthDataSync()
        }
        
        Timer.scheduledTimer(withTimeInterval: 7200, repeats: true) { _ in
            self.scheduleSleepAnalysis()
        }
        
        Timer.scheduledTimer(withTimeInterval: 14400, repeats: true) { _ in
            self.scheduleModelUpdate()
        }
        
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            self.scheduleEnvironmentSync()
        }
    }
    
    func stopPeriodicScheduling() {
        cancelAllTasks()
    }
}

// MARK: - Background Task Extensions

extension BackgroundTaskScheduler {
    func handleAppDidEnterBackground() {
        // Schedule background tasks when app enters background
        scheduleHealthDataSync()
        scheduleSleepAnalysis()
        scheduleModelUpdate()
        scheduleEnvironmentSync()
    }
    
    func handleAppWillEnterForeground() {
        // Cancel background tasks when app enters foreground
        // This is optional - you might want to let them complete
        // cancelAllTasks()
    }
}

// MARK: - Task Configuration

struct BackgroundTaskConfiguration {
    let identifier: String
    let requiresNetwork: Bool
    let requiresExternalPower: Bool
    let earliestBeginDate: TimeInterval
    let maxExecutionTime: TimeInterval
}

extension BackgroundTaskScheduler {
    func configureTask(_ configuration: BackgroundTaskConfiguration) {
        switch configuration.identifier {
        case healthDataSyncTaskIdentifier:
            configureHealthDataSyncTask(configuration)
        case sleepAnalysisTaskIdentifier:
            configureSleepAnalysisTask(configuration)
        case modelUpdateTaskIdentifier:
            configureModelUpdateTask(configuration)
        case environmentSyncTaskIdentifier:
            configureEnvironmentSyncTask(configuration)
        default:
            break
        }
    }
    
    private func configureHealthDataSyncTask(_ config: BackgroundTaskConfiguration) {
        let request = BGAppRefreshTaskRequest(identifier: config.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: config.earliestBeginDate)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to configure health data sync task: \(error)")
        }
    }
    
    private func configureSleepAnalysisTask(_ config: BackgroundTaskConfiguration) {
        let request = BGProcessingTaskRequest(identifier: config.identifier)
        request.requiresNetworkConnectivity = config.requiresNetwork
        request.requiresExternalPower = config.requiresExternalPower
        request.earliestBeginDate = Date(timeIntervalSinceNow: config.earliestBeginDate)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to configure sleep analysis task: \(error)")
        }
    }
    
    private func configureModelUpdateTask(_ config: BackgroundTaskConfiguration) {
        let request = BGProcessingTaskRequest(identifier: config.identifier)
        request.requiresNetworkConnectivity = config.requiresNetwork
        request.requiresExternalPower = config.requiresExternalPower
        request.earliestBeginDate = Date(timeIntervalSinceNow: config.earliestBeginDate)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to configure model update task: \(error)")
        }
    }
    
    private func configureEnvironmentSyncTask(_ config: BackgroundTaskConfiguration) {
        let request = BGAppRefreshTaskRequest(identifier: config.identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: config.earliestBeginDate)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to configure environment sync task: \(error)")
        }
    }
} 