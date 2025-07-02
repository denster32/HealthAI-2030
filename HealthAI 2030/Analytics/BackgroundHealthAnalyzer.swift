import Foundation
import HealthKit
import CoreML
import Combine

class BackgroundHealthAnalyzer: ObservableObject {
    static let shared = BackgroundHealthAnalyzer()
    
    private let healthStore = HKHealthStore()
    private let mlModelManager = MLModelManager.shared
    private let predictiveAnalytics = PredictiveAnalyticsManager.shared
    
    // Real-time health data streams
    private var healthDataStreams: [HKObjectType: HKObserverQuery] = [:]
    private var backgroundDeliveryQueries: [HKObjectType: HKObserverQuery] = [:]
    
    // Analysis results
    @Published var currentHealthStatus: HealthStatus = .unknown
    @Published var sleepQualityScore: Double = 0.0
    @Published var stressLevel: StressLevel = .unknown
    @Published var recoveryScore: Double = 0.0
    @Published var healthTrends: [HealthTrend] = []
    
    // Real-time monitoring
    @Published var isMonitoring: Bool = false
    @Published var lastUpdateTime: Date = Date()
    
    // Health thresholds and alerts
    private var healthThresholds: HealthThresholds = HealthThresholds()
    @Published var activeAlerts: [HealthAlert] = []
    
    // Data processing
    private let dataProcessor = HealthDataProcessor()
    private let anomalyDetector = AnomalyDetector()
    private let trendAnalyzer = TrendAnalyzer()
    
    // Background task management
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var analysisTimer: Timer?
    
    private init() {
        setupHealthKit()
        setupBackgroundProcessing()
    }
    
    // MARK: - HealthKit Setup
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available")
            return
        }
        
        // Request authorization for required data types
        let dataTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .sleepChanges)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.startMonitoring()
                }
            } else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Background Processing Setup
    
    private func setupBackgroundProcessing() {
        // Enable background app refresh
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        // Register for background processing
        registerBackgroundTasks()
    }
    
    private func registerBackgroundTasks() {
        // Register background health analysis task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.healthai.backgroundHealthAnalysis", using: nil) { task in
            self.handleBackgroundHealthAnalysis(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Health Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        setupHealthDataStreams()
        startBackgroundAnalysis()
        
        print("Background health monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        stopHealthDataStreams()
        stopBackgroundAnalysis()
        
        print("Background health monitoring stopped")
    }
    
    private func setupHealthDataStreams() {
        // Heart Rate monitoring
        setupHeartRateMonitoring()
        
        // Heart Rate Variability monitoring
        setupHRVMonitoring()
        
        // Sleep monitoring
        setupSleepMonitoring()
        
        // Activity monitoring
        setupActivityMonitoring()
        
        // Respiratory monitoring
        setupRespiratoryMonitoring()
    }
    
    private func setupHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let heartRateQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completion, error in
            self?.processHeartRateData()
            completion()
        }
        
        healthStore.execute(heartRateQuery)
        healthDataStreams[heartRateType] = heartRateQuery
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if success {
                print("Background heart rate delivery enabled")
            } else {
                print("Failed to enable background heart rate delivery: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupHRVMonitoring() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let hrvQuery = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] query, completion, error in
            self?.processHRVData()
            completion()
        }
        
        healthStore.execute(hrvQuery)
        healthDataStreams[hrvType] = hrvQuery
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if success {
                print("Background HRV delivery enabled")
            } else {
                print("Failed to enable background HRV delivery: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupSleepMonitoring() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let sleepQuery = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] query, completion, error in
            self?.processSleepData()
            completion()
        }
        
        healthStore.execute(sleepQuery)
        healthDataStreams[sleepType] = sleepQuery
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { success, error in
            if success {
                print("Background sleep delivery enabled")
            } else {
                print("Failed to enable background sleep delivery: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupActivityMonitoring() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let activityQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] query, completion, error in
            self?.processActivityData()
            completion()
        }
        
        healthStore.execute(activityQuery)
        healthDataStreams[stepType] = activityQuery
        
        // Enable background delivery for both
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("Background step count delivery enabled")
            }
        }
        
        healthStore.enableBackgroundDelivery(for: energyType, frequency: .immediate) { success, error in
            if success {
                print("Background energy delivery enabled")
            }
        }
    }
    
    private func setupRespiratoryMonitoring() {
        guard let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate),
              let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let respiratoryQuery = HKObserverQuery(sampleType: respiratoryType, predicate: nil) { [weak self] query, completion, error in
            self?.processRespiratoryData()
            completion()
        }
        
        healthStore.execute(respiratoryQuery)
        healthDataStreams[respiratoryType] = respiratoryQuery
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: respiratoryType, frequency: .immediate) { success, error in
            if success {
                print("Background respiratory delivery enabled")
            }
        }
        
        healthStore.enableBackgroundDelivery(for: oxygenType, frequency: .immediate) { success, error in
            if success {
                print("Background oxygen delivery enabled")
            }
        }
    }
    
    private func stopHealthDataStreams() {
        for (_, query) in healthDataStreams {
            healthStore.stop(query)
        }
        healthDataStreams.removeAll()
    }
    
    // MARK: - Data Processing
    
    private func processHeartRateData() {
        fetchLatestHeartRate { [weak self] heartRate in
            guard let self = self, let heartRate = heartRate else { return }
            
            DispatchQueue.main.async {
                self.updateHealthStatus(with: heartRate)
                self.checkHeartRateThresholds(heartRate)
                self.lastUpdateTime = Date()
            }
        }
    }
    
    private func processHRVData() {
        fetchLatestHRV { [weak self] hrv in
            guard let self = self, let hrv = hrv else { return }
            
            DispatchQueue.main.async {
                self.updateStressLevel(with: hrv)
                self.updateRecoveryScore(with: hrv)
                self.lastUpdateTime = Date()
            }
        }
    }
    
    private func processSleepData() {
        fetchLatestSleepData { [weak self] sleepData in
            guard let self = self, let sleepData = sleepData else { return }
            
            DispatchQueue.main.async {
                self.updateSleepQualityScore(with: sleepData)
                self.lastUpdateTime = Date()
            }
        }
    }
    
    private func processActivityData() {
        fetchLatestActivityData { [weak self] activityData in
            guard let self = self, let activityData = activityData else { return }
            
            DispatchQueue.main.async {
                self.updateActivityMetrics(with: activityData)
                self.lastUpdateTime = Date()
            }
        }
    }
    
    private func processRespiratoryData() {
        fetchLatestRespiratoryData { [weak self] respiratoryData in
            guard let self = self, let respiratoryData = respiratoryData else { return }
            
            DispatchQueue.main.async {
                self.updateRespiratoryMetrics(with: respiratoryData)
                self.lastUpdateTime = Date()
            }
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchLatestHeartRate(completion: @escaping (Double?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHRV(completion: @escaping (Double?) -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            
            let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            completion(hrv)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestSleepData(completion: @escaping (SleepData?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-86400), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else {
                completion(nil)
                return
            }
            
            let sleepData = self.dataProcessor.processSleepSamples(samples)
            completion(sleepData)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestActivityData(completion: @escaping (ActivityData?) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-86400), end: Date(), options: .strictStartDate)
        
        let stepQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            
            let energyQuery = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, energyResult, _ in
                let energy = energyResult?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                
                let activityData = ActivityData(steps: steps, calories: energy, date: Date())
                completion(activityData)
            }
            
            self.healthStore.execute(energyQuery)
        }
        
        healthStore.execute(stepQuery)
    }
    
    private func fetchLatestRespiratoryData(completion: @escaping (RespiratoryData?) -> Void) {
        guard let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate),
              let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let respiratoryQuery = HKSampleQuery(sampleType: respiratoryType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let respiratorySample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            
            let respiratoryRate = respiratorySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            
            let oxygenQuery = HKSampleQuery(sampleType: oxygenType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, oxygenSamples, error in
                guard let oxygenSample = oxygenSamples?.first as? HKQuantitySample else {
                    let respiratoryData = RespiratoryData(respiratoryRate: respiratoryRate, oxygenSaturation: nil, date: Date())
                    completion(respiratoryData)
                    return
                }
                
                let oxygenSaturation = oxygenSample.quantity.doubleValue(for: HKUnit.percent())
                let respiratoryData = RespiratoryData(respiratoryRate: respiratoryRate, oxygenSaturation: oxygenSaturation, date: Date())
                completion(respiratoryData)
            }
            
            self.healthStore.execute(oxygenQuery)
        }
        
        healthStore.execute(respiratoryQuery)
    }
    
    // MARK: - Health Status Updates
    
    private func updateHealthStatus(with heartRate: Double) {
        // Update current health status based on heart rate and other metrics
        let newStatus = dataProcessor.calculateHealthStatus(heartRate: heartRate, hrv: nil, sleepQuality: sleepQualityScore)
        currentHealthStatus = newStatus
        
        // Add to health trends
        let trend = HealthTrend(type: .heartRate, value: heartRate, timestamp: Date())
        healthTrends.append(trend)
        
        // Keep only last 24 hours of trends
        let oneDayAgo = Date().addingTimeInterval(-86400)
        healthTrends = healthTrends.filter { $0.timestamp > oneDayAgo }
    }
    
    private func updateStressLevel(with hrv: Double) {
        stressLevel = dataProcessor.calculateStressLevel(hrv: hrv)
        
        let trend = HealthTrend(type: .hrv, value: hrv, timestamp: Date())
        healthTrends.append(trend)
    }
    
    private func updateRecoveryScore(with hrv: Double) {
        recoveryScore = dataProcessor.calculateRecoveryScore(hrv: hrv, sleepQuality: sleepQualityScore)
    }
    
    private func updateSleepQualityScore(with sleepData: SleepData) {
        sleepQualityScore = dataProcessor.calculateSleepQualityScore(sleepData)
        
        let trend = HealthTrend(type: .sleepQuality, value: sleepQualityScore, timestamp: Date())
        healthTrends.append(trend)
    }
    
    private func updateActivityMetrics(with activityData: ActivityData) {
        // Update activity-related metrics
        let trend = HealthTrend(type: .steps, value: activityData.steps, timestamp: Date())
        healthTrends.append(trend)
    }
    
    private func updateRespiratoryMetrics(with respiratoryData: RespiratoryData) {
        let trend = HealthTrend(type: .respiratoryRate, value: respiratoryData.respiratoryRate, timestamp: Date())
        healthTrends.append(trend)
    }
    
    // MARK: - Threshold Monitoring
    
    private func checkHeartRateThresholds(_ heartRate: Double) {
        if heartRate > healthThresholds.maxHeartRate {
            let alert = HealthAlert(
                type: .highHeartRate,
                severity: .warning,
                message: "Heart rate is elevated: \(Int(heartRate)) BPM",
                timestamp: Date()
            )
            addAlert(alert)
        } else if heartRate < healthThresholds.minHeartRate {
            let alert = HealthAlert(
                type: .lowHeartRate,
                severity: .warning,
                message: "Heart rate is low: \(Int(heartRate)) BPM",
                timestamp: Date()
            )
            addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: HealthAlert) {
        activeAlerts.append(alert)
        
        // Keep only recent alerts (last 24 hours)
        let oneDayAgo = Date().addingTimeInterval(-86400)
        activeAlerts = activeAlerts.filter { $0.timestamp > oneDayAgo }
        
        // Send notification for high severity alerts
        if alert.severity == .critical {
            sendHealthAlertNotification(alert)
        }
    }
    
    private func sendHealthAlertNotification(_ alert: HealthAlert) {
        let content = UNMutableNotificationContent()
        content.title = "Health Alert"
        content.body = alert.message
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Background Analysis
    
    private func startBackgroundAnalysis() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performBackgroundAnalysis()
        }
    }
    
    private func stopBackgroundAnalysis() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }
    
    private func performBackgroundAnalysis() {
        // Perform comprehensive health analysis
        analyzeHealthTrends()
        detectAnomalies()
        updatePredictions()
        
        // Schedule background task
        scheduleBackgroundHealthAnalysis()
    }
    
    private func analyzeHealthTrends() {
        let trends = trendAnalyzer.analyzeTrends(healthTrends)
        
        // Update predictions based on trends
        predictiveAnalytics.updatePredictions(with: trends)
    }
    
    private func detectAnomalies() {
        let anomalies = anomalyDetector.detectAnomalies(in: healthTrends)
        
        for anomaly in anomalies {
            let alert = HealthAlert(
                type: .anomaly,
                severity: .warning,
                message: "Unusual health pattern detected: \(anomaly.description)",
                timestamp: Date()
            )
            addAlert(alert)
        }
    }
    
    private func updatePredictions() {
        // Update health predictions based on current data
        predictiveAnalytics.updateHealthPredictions(
            heartRate: nil,
            hrv: nil,
            sleepQuality: sleepQualityScore,
            stressLevel: stressLevel
        )
    }
    
    // MARK: - Background Task Handling
    
    private func scheduleBackgroundHealthAnalysis() {
        let request = BGProcessingTaskRequest(identifier: "com.healthai.backgroundHealthAnalysis")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background health analysis: \(error)")
        }
    }
    
    private func handleBackgroundHealthAnalysis(task: BGProcessingTask) {
        // Set up background task
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            task.setTaskCompleted(success: false)
        }
        
        // Perform analysis
        performBackgroundAnalysis()
        
        // Complete task
        task.setTaskCompleted(success: true)
        
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    // MARK: - Public Interface
    
    func getHealthSummary() -> HealthSummary {
        return HealthSummary(
            currentStatus: currentHealthStatus,
            sleepQuality: sleepQualityScore,
            stressLevel: stressLevel,
            recoveryScore: recoveryScore,
            lastUpdate: lastUpdateTime,
            activeAlerts: activeAlerts
        )
    }
    
    func getHealthTrends(for type: HealthTrendType, duration: TimeInterval) -> [HealthTrend] {
        let cutoffTime = Date().addingTimeInterval(-duration)
        return healthTrends.filter { $0.type == type && $0.timestamp > cutoffTime }
    }
    
    func clearAlerts() {
        activeAlerts.removeAll()
    }
}

// MARK: - Supporting Types

enum HealthStatus {
    case excellent
    case good
    case fair
    case poor
    case critical
    case unknown
}

enum StressLevel {
    case low
    case moderate
    case high
    case critical
    case unknown
}

enum HealthTrendType {
    case heartRate
    case hrv
    case sleepQuality
    case steps
    case respiratoryRate
    case temperature
    case bloodPressure
}

struct HealthTrend {
    let type: HealthTrendType
    let value: Double
    let timestamp: Date
}

struct HealthAlert {
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let timestamp: Date
}

enum AlertType {
    case highHeartRate
    case lowHeartRate
    case lowHRV
    case poorSleep
    case anomaly
    case stress
}

enum AlertSeverity {
    case info
    case warning
    case critical
}

struct HealthThresholds {
    var maxHeartRate: Double = 100
    var minHeartRate: Double = 50
    var minHRV: Double = 30
    var minSleepQuality: Double = 0.7
}

struct HealthSummary {
    let currentStatus: HealthStatus
    let sleepQuality: Double
    let stressLevel: StressLevel
    let recoveryScore: Double
    let lastUpdate: Date
    let activeAlerts: [HealthAlert]
}

struct SleepData {
    let totalSleepTime: TimeInterval
    let deepSleepTime: TimeInterval
    let remSleepTime: TimeInterval
    let lightSleepTime: TimeInterval
    let wakeCount: Int
    let sleepEfficiency: Double
}

struct ActivityData {
    let steps: Double
    let calories: Double
    let date: Date
}

struct RespiratoryData {
    let respiratoryRate: Double
    let oxygenSaturation: Double?
    let date: Date
}

// MARK: - Data Processing Classes

class HealthDataProcessor {
    func calculateHealthStatus(heartRate: Double, hrv: Double?, sleepQuality: Double) -> HealthStatus {
        // Complex health status calculation
        var score = 0.0
        
        // Heart rate scoring
        if heartRate >= 60 && heartRate <= 100 {
            score += 0.4
        } else if heartRate >= 50 && heartRate <= 110 {
            score += 0.2
        }
        
        // HRV scoring
        if let hrv = hrv {
            if hrv >= 50 {
                score += 0.3
            } else if hrv >= 30 {
                score += 0.2
            }
        }
        
        // Sleep quality scoring
        score += sleepQuality * 0.3
        
        // Determine status
        switch score {
        case 0.8...1.0:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .fair
        case 0.2..<0.4:
            return .poor
        default:
            return .critical
        }
    }
    
    func calculateStressLevel(hrv: Double) -> StressLevel {
        switch hrv {
        case 60...:
            return .low
        case 40..<60:
            return .moderate
        case 20..<40:
            return .high
        default:
            return .critical
        }
    }
    
    func calculateRecoveryScore(hrv: Double, sleepQuality: Double) -> Double {
        let hrvScore = min(hrv / 100.0, 1.0)
        let sleepScore = sleepQuality
        return (hrvScore * 0.6) + (sleepScore * 0.4)
    }
    
    func calculateSleepQualityScore(_ sleepData: SleepData) -> Double {
        let efficiency = sleepData.sleepEfficiency
        let deepSleepRatio = sleepData.deepSleepTime / sleepData.totalSleepTime
        let remSleepRatio = sleepData.remSleepTime / sleepData.totalSleepTime
        
        let score = (efficiency * 0.4) + (deepSleepRatio * 0.3) + (remSleepRatio * 0.3)
        return min(score, 1.0)
    }
    
    func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData {
        // Process sleep samples to extract sleep data
        var totalSleepTime: TimeInterval = 0
        var deepSleepTime: TimeInterval = 0
        var remSleepTime: TimeInterval = 0
        var lightSleepTime: TimeInterval = 0
        var wakeCount = 0
        
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                totalSleepTime += duration
            case HKCategoryValueSleepAnalysis.asleep.rawValue:
                // Assume light sleep for now
                lightSleepTime += duration
            default:
                break
            }
        }
        
        let sleepEfficiency = totalSleepTime > 0 ? (totalSleepTime - lightSleepTime) / totalSleepTime : 0
        
        return SleepData(
            totalSleepTime: totalSleepTime,
            deepSleepTime: deepSleepTime,
            remSleepTime: remSleepTime,
            lightSleepTime: lightSleepTime,
            wakeCount: wakeCount,
            sleepEfficiency: sleepEfficiency
        )
    }
}

class AnomalyDetector {
    func detectAnomalies(in trends: [HealthTrend]) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        // Simple anomaly detection based on statistical outliers
        for trendType in [HealthTrendType.heartRate, .hrv, .sleepQuality] {
            let typeTrends = trends.filter { $0.type == trendType }
            if let anomaly = detectStatisticalAnomaly(in: typeTrends) {
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    private func detectStatisticalAnomaly(in trends: [HealthTrend]) -> Anomaly? {
        guard trends.count >= 5 else { return nil }
        
        let values = trends.map { $0.value }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Check for outliers (beyond 2 standard deviations)
        for trend in trends.suffix(3) {
            let zScore = abs(trend.value - mean) / standardDeviation
            if zScore > 2.0 {
                return Anomaly(
                    type: trend.type,
                    value: trend.value,
                    expectedRange: (mean - 2 * standardDeviation, mean + 2 * standardDeviation),
                    timestamp: trend.timestamp,
                    description: "Unusual \(trend.type) value: \(trend.value)"
                )
            }
        }
        
        return nil
    }
}

class TrendAnalyzer {
    func analyzeTrends(_ trends: [HealthTrend]) -> [TrendAnalysis] {
        var analyses: [TrendAnalysis] = []
        
        for trendType in [HealthTrendType.heartRate, .hrv, .sleepQuality] {
            let typeTrends = trends.filter { $0.type == trendType }
            if let analysis = analyzeTrend(typeTrends) {
                analyses.append(analysis)
            }
        }
        
        return analyses
    }
    
    private func analyzeTrend(_ trends: [HealthTrend]) -> TrendAnalysis? {
        guard trends.count >= 3 else { return nil }
        
        let recentTrends = Array(trends.suffix(3))
        let values = recentTrends.map { $0.value }
        
        // Calculate trend direction
        let firstValue = values.first!
        let lastValue = values.last!
        let change = lastValue - firstValue
        let percentChange = (change / firstValue) * 100
        
        let direction: TrendDirection
        if percentChange > 5 {
            direction = .increasing
        } else if percentChange < -5 {
            direction = .decreasing
        } else {
            direction = .stable
        }
        
        return TrendAnalysis(
            type: trends.first!.type,
            direction: direction,
            percentChange: percentChange,
            duration: recentTrends.last!.timestamp.timeIntervalSince(recentTrends.first!.timestamp)
        )
    }
}

struct Anomaly {
    let type: HealthTrendType
    let value: Double
    let expectedRange: (min: Double, max: Double)
    let timestamp: Date
    let description: String
}

struct TrendAnalysis {
    let type: HealthTrendType
    let direction: TrendDirection
    let percentChange: Double
    let duration: TimeInterval
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
} 
