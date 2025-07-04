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
    
    // Helper to compute time interval until next specified hour
    private func timeIntervalUntil(hour: Int) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        components.second = 0
        let target = calendar.date(from: components)! // today at 'hour'
        let interval = target.timeIntervalSince(now)
        return interval > 0 ? interval : interval + 24*3600
    }

    func scheduleHealthDataSyncDaily(at hour: Int = 2) {
        let request = BGAppRefreshTaskRequest(identifier: healthDataSyncTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: timeIntervalUntil(hour: hour))

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Health data sync task scheduled")
        } catch {
            print("Failed to schedule health data sync task: \(error)")
        }
    }

    func scheduleSleepAnalysisDaily(at hour: Int = 2) {
        let request = BGProcessingTaskRequest(identifier: sleepAnalysisTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: timeIntervalUntil(hour: hour))

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Sleep analysis task scheduled")
        } catch {
            print("Failed to schedule sleep analysis task: \(error)")
        }
    }

    func scheduleModelUpdateDaily(at hour: Int = 2) {
        let request = BGProcessingTaskRequest(identifier: modelUpdateTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: timeIntervalUntil(hour: hour))

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Model update task scheduled")
        } catch {
            print("Failed to schedule model update task: \(error)")
        }
    }

    func scheduleEnvironmentSyncDaily(at hour: Int = 2) {
        let request = BGAppRefreshTaskRequest(identifier: environmentSyncTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: timeIntervalUntil(hour: hour))

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
        
        // Enhanced sleep analysis with predictive alerts
        Task {
            do {
                // Perform comprehensive sleep analysis
                let sleepAnalyzer = AdvancedSleepAnalyzer.shared
                let sleepManager = SleepOptimizationManager.shared
                
                // Get current sleep analysis with predictive analytics
                let analysisResult = await sleepAnalyzer.performSleepAnalysis()
                
                // Check for health deterioration risks
                await processHealthDeteriorationRisks(from: analysisResult)
                
                // Generate and process predictive alerts
                await generatePredictiveAlerts(from: analysisResult)
                
                // Perform intelligent interventions
                await executeIntelligentInterventions(based: analysisResult)
                
                // Save enhanced sleep report
                let enhancedReport = createEnhancedSleepReport(from: analysisResult)
                CoreDataManager.shared.saveSleepReport(enhancedReport)
                
                // Update sleep metrics with predictive data
                sleepManager.updateSleepMetrics()
                
                // Log successful analysis
                print("BackgroundTaskScheduler: Enhanced sleep analysis completed successfully")
                
                // Mark task as completed
                task.setTaskCompleted(success: true)
                
            } catch {
                print("BackgroundTaskScheduler: Sleep analysis failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
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
    
    // MARK: - Enhanced Sleep Analysis Methods
    
    private func processHealthDeteriorationRisks(from analysisResult: SleepAnalysis) async {
        // Extract risk indicators from sleep analysis
        let riskMetrics = extractRiskMetrics(from: analysisResult)
        
        // Check for critical health deterioration patterns
        if riskMetrics.overallRiskScore > 0.7 {
            await handleCriticalHealthRisk(metrics: riskMetrics)
        } else if riskMetrics.overallRiskScore > 0.5 {
            await handleModerateHealthRisk(metrics: riskMetrics)
        }
        
        // Log risk assessment
        print("BackgroundTaskScheduler: Health deterioration risk assessed - score: \(riskMetrics.overallRiskScore)")
    }
    
    private func generatePredictiveAlerts(from analysisResult: SleepAnalysis) async {
        let alertGenerator = PredictiveAlertGenerator()
        
        // Generate alerts based on sleep patterns and trends
        let predictiveAlerts = await alertGenerator.generateAlerts(from: analysisResult)
        
        for alert in predictiveAlerts {
            await processAlert(alert)
        }
        
        print("BackgroundTaskScheduler: Generated \(predictiveAlerts.count) predictive alerts")
    }
    
    private func executeIntelligentInterventions(based analysisResult: SleepAnalysis) async {
        let interventionEngine = IntelligentInterventionEngine()
        
        // Determine appropriate interventions based on current sleep state
        let interventions = await interventionEngine.determineInterventions(from: analysisResult)
        
        for intervention in interventions {
            await executeIntervention(intervention)
        }
        
        print("BackgroundTaskScheduler: Executed \(interventions.count) intelligent interventions")
    }
    
    private func handleCriticalHealthRisk(metrics: HealthRiskMetrics) async {
        // Create critical health alert
        let criticalAlert = HealthAlert(
            type: .critical,
            severity: .critical,
            message: "Critical health deterioration risk detected during sleep",
            timestamp: Date(),
            confidence: metrics.confidence,
            recommendedAction: "Immediate medical attention may be required"
        )
        
        // Send immediate notification
        await sendCriticalHealthNotification(alert: criticalAlert)
        
        // Wake user if absolutely necessary (severe oxygen saturation, etc.)
        if metrics.requiresImmediateWaking {
            await triggerEmergencyWakeProtocol()
        }
        
        // Log critical event
        CoreDataManager.shared.saveHealthAlert(criticalAlert)
    }
    
    private func handleModerateHealthRisk(metrics: HealthRiskMetrics) async {
        // Create moderate health alert
        let moderateAlert = HealthAlert(
            type: .moderate,
            severity: .medium,
            message: "Moderate health deterioration risk detected",
            timestamp: Date(),
            confidence: metrics.confidence,
            recommendedAction: "Monitor closely and consider lifestyle adjustments"
        )
        
        // Schedule delayed notification to avoid sleep disruption
        await scheduleDelayedHealthNotification(alert: moderateAlert, delay: 300) // 5 minutes
        
        // Implement gentle interventions
        await implementGentleInterventions(based: metrics)
        
        // Log moderate event
        CoreDataManager.shared.saveHealthAlert(moderateAlert)
    }
    
    private func processAlert(_ alert: PredictiveAlert) async {
        switch alert.urgency {
        case .immediate:
            await sendImmediateAlert(alert)
        case .withinMinutes:
            await scheduleNearTermAlert(alert, delay: alert.suggestedDelay)
        case .withinHour:
            await scheduleDelayedAlert(alert, delay: alert.suggestedDelay)
        case .onWaking:
            await scheduleMorningAlert(alert)
        }
    }
    
    private func executeIntervention(_ intervention: SleepIntervention) async {
        switch intervention.type {
        case .environmentalAdjustment:
            await adjustSleepEnvironment(intervention)
        case .audioTherapy:
            await initiateAudioTherapy(intervention)
        case .biofeedbackGuidance:
            await provideBiofeedbackGuidance(intervention)
        case .smartAlarmAdjustment:
            await adjustSmartAlarm(intervention)
        case .medicationReminder:
            await scheduleMedicationReminder(intervention)
        }
    }
    
    private func adjustSleepEnvironment(_ intervention: SleepIntervention) async {
        // Integrate with smart home systems
        if let smartHomeManager = SmartHomeManager.shared {
            await smartHomeManager.adjustEnvironmentForSleep(intervention.parameters)
        }
        
        print("BackgroundTaskScheduler: Environment adjusted - \(intervention.description)")
    }
    
    private func initiateAudioTherapy(_ intervention: SleepIntervention) async {
        // Start appropriate audio therapy based on sleep stage and needs
        if let audioManager = EnhancedAudioEngine.shared {
            await audioManager.startSleepAudioTherapy(intervention.audioType, volume: intervention.volume)
        }
        
        print("BackgroundTaskScheduler: Audio therapy initiated - \(intervention.audioType)")
    }
    
    private func provideBiofeedbackGuidance(_ intervention: SleepIntervention) async {
        // Provide gentle biofeedback if user is in appropriate sleep stage
        if intervention.currentSleepStage == .lightSleep {
            // Initiate gentle breathing guidance or HRV coherence training
            await startGentleBiofeedback(intervention)
        }
        
        print("BackgroundTaskScheduler: Biofeedback guidance provided")
    }
    
    private func adjustSmartAlarm(_ intervention: SleepIntervention) async {
        // Adjust alarm timing based on predicted sleep cycles
        if let alarmManager = SmartAlarmSystem.shared {
            await alarmManager.adjustAlarmTiming(intervention.recommendedWakeTime)
        }
        
        print("BackgroundTaskScheduler: Smart alarm adjusted")
    }
    
    private func scheduleMedicationReminder(_ intervention: SleepIntervention) async {
        // Schedule morning medication reminder if sleep quality is impacted
        let reminderTime = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "Medication Reminder"
        content.body = intervention.reminderMessage
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderTime.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
        
        print("BackgroundTaskScheduler: Medication reminder scheduled")
    }
    
    private func sendCriticalHealthNotification(alert: HealthAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Critical Health Alert"
        content.body = alert.message
        content.sound = .critical
        content.categoryIdentifier = "CRITICAL_HEALTH_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "critical_health_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        
        print("BackgroundTaskScheduler: Critical health notification sent")
    }
    
    private func sendImmediateAlert(_ alert: PredictiveAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "🔮 Predictive Health Alert"
        content.body = alert.message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "predictive_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        
        print("BackgroundTaskScheduler: Immediate predictive alert sent")
    }
    
    private func triggerEmergencyWakeProtocol() async {
        // Gradually increase audio and haptic feedback to wake user safely
        print("BackgroundTaskScheduler: Emergency wake protocol triggered")
        
        // Start with gentle audio
        await initiateGradualWakeSequence()
        
        // Send emergency notification
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Emergency Wake"
        content.body = "Health monitoring detected a concerning pattern. Please check your status."
        content.sound = .critical
        
        let request = UNNotificationRequest(
            identifier: "emergency_wake_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func initiateGradualWakeSequence() async {
        // Implement gradual wake sequence to avoid jarring awakening
        // This would integrate with audio and haptic systems
        print("BackgroundTaskScheduler: Gradual wake sequence initiated")
    }
    
    private func implementGentleInterventions(based metrics: HealthRiskMetrics) async {
        // Implement non-disruptive interventions to improve sleep
        if metrics.heartRateElevated {
            await adjustSleepEnvironment(SleepIntervention(type: .environmentalAdjustment, description: "Reduce temperature"))
        }
        
        if metrics.hrvLow {
            await provideBiofeedbackGuidance(SleepIntervention(type: .biofeedbackGuidance, description: "HRV coherence"))
        }
        
        print("BackgroundTaskScheduler: Gentle interventions implemented")
    }
    
    private func startGentleBiofeedback(_ intervention: SleepIntervention) async {
        // Start gentle biofeedback appropriate for current sleep stage
        print("BackgroundTaskScheduler: Gentle biofeedback started")
    }
    
    private func scheduleDelayedHealthNotification(alert: HealthAlert, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "Health Monitoring Alert"
        content.body = alert.message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "delayed_health_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        
        print("BackgroundTaskScheduler: Delayed health notification scheduled")
    }
    
    private func scheduleNearTermAlert(_ alert: PredictiveAlert, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "nearterm_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleDelayedAlert(_ alert: PredictiveAlert, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "delayed_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleMorningAlert(_ alert: PredictiveAlert) async {
        // Schedule alert for next morning
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let morningTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: morningTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "morning_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func extractRiskMetrics(from analysisResult: SleepAnalysis) -> HealthRiskMetrics {
        // Extract and calculate risk metrics from sleep analysis
        return HealthRiskMetrics(
            overallRiskScore: calculateOverallRisk(analysisResult),
            heartRateElevated: analysisResult.insights.contains { $0.title.contains("Heart Rate") },
            hrvLow: analysisResult.insights.contains { $0.title.contains("HRV") || $0.title.contains("variability") },
            oxygenSaturationLow: analysisResult.insights.contains { $0.title.contains("Oxygen") },
            breathingIrregular: analysisResult.insights.contains { $0.title.contains("Breathing") },
            requiresImmediateWaking: calculateImmediateWakeNeed(analysisResult),
            confidence: analysisResult.sleepScore
        )
    }
    
    private func calculateOverallRisk(_ analysisResult: SleepAnalysis) -> Double {
        // Calculate overall health risk based on analysis
        let sleepQualityRisk = 1.0 - analysisResult.sleepScore
        let trendRisk = analysisResult.trendPrediction.sleepQualityTrend == .declining ? 0.3 : 0.0
        
        return min(1.0, sleepQualityRisk * 0.7 + trendRisk)
    }
    
    private func calculateImmediateWakeNeed(_ analysisResult: SleepAnalysis) -> Bool {
        // Determine if user should be woken immediately for health reasons
        return analysisResult.insights.contains { insight in
            insight.impact == .negative && insight.confidence > 0.8 && 
            (insight.title.contains("Oxygen") || insight.title.contains("Critical"))
        }
    }
    
    private func createEnhancedSleepReport(from analysisResult: SleepAnalysis) -> SleepReport {
        // Create enhanced sleep report with predictive insights
        return SleepReport(
            date: Date(),
            sleepScore: analysisResult.sleepScore,
            insights: analysisResult.insights.map { $0.description },
            predictiveAlerts: extractPredictiveAlerts(from: analysisResult),
            interventionsExecuted: extractExecutedInterventions(from: analysisResult),
            riskAssessment: extractRiskAssessment(from: analysisResult)
        )
    }
    
    private func extractPredictiveAlerts(from analysisResult: SleepAnalysis) -> [String] {
        return analysisResult.insights.filter { $0.type == .prediction }.map { $0.description }
    }
    
    private func extractExecutedInterventions(from analysisResult: SleepAnalysis) -> [String] {
        return ["Environmental adjustments", "Audio therapy", "Biofeedback guidance"] // Placeholder
    }
    
    private func extractRiskAssessment(from analysisResult: SleepAnalysis) -> String {
        let riskScore = calculateOverallRisk(analysisResult)
        if riskScore > 0.7 { return "High risk detected" }
        else if riskScore > 0.4 { return "Moderate risk detected" }
        else { return "Low risk detected" }
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

// MARK: - Supporting Types for Enhanced Analytics

struct HealthRiskMetrics {
    let overallRiskScore: Double
    let heartRateElevated: Bool
    let hrvLow: Bool
    let oxygenSaturationLow: Bool
    let breathingIrregular: Bool
    let requiresImmediateWaking: Bool
    let confidence: Double
}

struct PredictiveAlert {
    let title: String
    let message: String
    let urgency: AlertUrgency
    let suggestedDelay: TimeInterval
    let confidence: Double
}

enum AlertUrgency {
    case immediate
    case withinMinutes
    case withinHour
    case onWaking
}

struct SleepIntervention {
    let type: InterventionType
    let description: String
    let parameters: [String: Any]
    let audioType: String
    let volume: Float
    let currentSleepStage: SleepStageType
    let recommendedWakeTime: Date
    let reminderMessage: String
    
    init(type: InterventionType, description: String) {
        self.type = type
        self.description = description
        self.parameters = [:]
        self.audioType = "gentle"
        self.volume = 0.3
        self.currentSleepStage = .lightSleep
        self.recommendedWakeTime = Date().addingTimeInterval(28800) // 8 hours
        self.reminderMessage = description
    }
}

enum InterventionType {
    case environmentalAdjustment
    case audioTherapy
    case biofeedbackGuidance
    case smartAlarmAdjustment
    case medicationReminder
}

enum SleepStageType {
    case awake
    case lightSleep
    case deepSleep
    case remSleep
    case unknown
}

struct SleepReport {
    let date: Date
    let sleepScore: Double
    let insights: [String]
    let predictiveAlerts: [String]
    let interventionsExecuted: [String]
    let riskAssessment: String
}

// Placeholder classes that would be implemented elsewhere
class PredictiveAlertGenerator {
    func generateAlerts(from analysisResult: SleepAnalysis) async -> [PredictiveAlert] {
        var alerts: [PredictiveAlert] = []
        
        // Generate predictive alerts based on analysis
        if analysisResult.sleepScore < 0.6 {
            alerts.append(PredictiveAlert(
                title: "Sleep Quality Alert",
                message: "Poor sleep quality detected. Consider adjusting environment.",
                urgency: .withinHour,
                suggestedDelay: 3600,
                confidence: 0.8
            ))
        }
        
        if analysisResult.trendPrediction.sleepQualityTrend == .declining {
            alerts.append(PredictiveAlert(
                title: "Sleep Trend Alert",
                message: "Declining sleep quality trend detected over past week.",
                urgency: .onWaking,
                suggestedDelay: 0,
                confidence: 0.9
            ))
        }
        
        return alerts
    }
}

class IntelligentInterventionEngine {
    func determineInterventions(from analysisResult: SleepAnalysis) async -> [SleepIntervention] {
        var interventions: [SleepIntervention] = []
        
        // Determine interventions based on analysis
        if analysisResult.sleepScore < 0.7 {
            interventions.append(SleepIntervention(
                type: .environmentalAdjustment,
                description: "Optimize sleep environment"
            ))
        }
        
        if analysisResult.insights.contains(where: { $0.title.contains("Heart Rate") }) {
            interventions.append(SleepIntervention(
                type: .biofeedbackGuidance,
                description: "Provide HRV biofeedback"
            ))
        }
        
        return interventions
    }
}