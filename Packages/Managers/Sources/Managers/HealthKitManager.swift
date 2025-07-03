import Foundation
import HealthKit
import SwiftUI
import os.log


/// Enhanced HealthKitManager - Advanced health data analysis and predictive analytics
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var biometricData: BiometricData?
    @Published var isAuthorized = false
    @Published var isAvailable = false
    @Published var lastUpdated = Date()
    @Published var lastSyncDate: Date?
    @Published var syncStatus = "Not synced"
    
    // NEW: Individual permission status properties
    @Published var heartRatePermission = false
    @Published var hrvPermission = false
    @Published var respiratoryRatePermission = false
    @Published var sleepAnalysisPermission = false
    @Published var oxygenSaturationPermission = false
    @Published var bodyTemperaturePermission = false
    
    // MARK: - Computed Properties for UI
    
    var lastSleepDuration: String {
        guard let lastSession = sleepData.last else {
            return "No data"
        }
        
        let duration = lastSession.endDate.timeIntervalSince(lastSession.startDate)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        return "\(hours)h \(minutes)m"
    }
    
    var averageSleepDuration: String {
        guard !sleepData.isEmpty else {
            return "No data"
        }
        
        let totalDuration = sleepData.reduce(0) { total, session in
            total + session.endDate.timeIntervalSince(session.startDate)
        }
        
        let averageDuration = totalDuration / Double(sleepData.count)
        let hours = Int(averageDuration) / 3600
        let minutes = Int(averageDuration) % 3600 / 60
        
        return "\(hours)h \(minutes)m"
    }
    
    var sleepEfficiency: Double {
        guard let lastSession = sleepData.last else {
            return 0.0
        }
        
        let totalDuration = lastSession.endDate.timeIntervalSince(lastSession.startDate)
        let timeInBed = lastSession.timeInBed ?? totalDuration
        
        return timeInBed > 0 ? (totalDuration / timeInBed) * 100 : 0.0
    }
    
    var sleepQualityScore: Double {
        guard let lastSession = sleepData.last else {
            return 0.0
        }
        
        // Calculate sleep quality based on multiple factors
        let durationScore = calculateDurationScore(lastSession)
        let efficiencyScore = sleepEfficiency / 100.0
        let consistencyScore = calculateConsistencyScore()
        let biometricScore = calculateBiometricScore()
        
        // Weighted average
        let qualityScore = (durationScore * 0.3 + 
                           efficiencyScore * 0.3 + 
                           consistencyScore * 0.2 + 
                           biometricScore * 0.2)
        
        return min(100.0, max(0.0, qualityScore * 100))
    }
    
    private func calculateDurationScore(_ session: SleepSession) -> Double {
        let duration = session.endDate.timeIntervalSince(session.startDate)
        let hours = duration / 3600
        
        // Optimal sleep duration is 7-9 hours
        if hours >= 7.0 && hours <= 9.0 {
            return 1.0
        } else if hours >= 6.0 && hours <= 10.0 {
            return 0.8
        } else if hours >= 5.0 && hours <= 11.0 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateConsistencyScore() -> Double {
        guard sleepData.count >= 7 else {
            return 0.5 // Default score for insufficient data
        }
        
        // Calculate consistency of sleep times over the last week
        let recentSessions = Array(sleepData.suffix(7))
        let bedTimes = recentSessions.map { session in
            Calendar.current.component(.hour, from: session.startDate)
        }
        
        let averageBedTime = bedTimes.reduce(0, +) / bedTimes.count
        let variance = bedTimes.reduce(0) { total, hour in
            total + pow(Double(hour - averageBedTime), 2)
        } / Double(bedTimes.count)
        
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = higher consistency
        if standardDeviation <= 1.0 {
            return 1.0
        } else if standardDeviation <= 2.0 {
            return 0.8
        } else if standardDeviation <= 3.0 {
            return 0.6
        } else {
            return 0.4
        }
    }
    
    private func calculateBiometricScore() -> Double {
        guard let biometricData = biometricData else {
            return 0.5
        }
        
        // Calculate score based on current biometric readings
        let heartRateScore = calculateHeartRateScore(biometricData.heartRate)
        let hrvScore = calculateHRVScore(biometricData.hrv)
        let respiratoryScore = calculateRespiratoryScore(biometricData.respiratoryRate)
        
        return (heartRateScore + hrvScore + respiratoryScore) / 3.0
    }
    
    private func calculateHeartRateScore(_ heartRate: Double) -> Double {
        // Optimal resting heart rate is 60-100 BPM
        if heartRate >= 60 && heartRate <= 100 {
            return 1.0
        } else if heartRate >= 50 && heartRate <= 110 {
            return 0.8
        } else if heartRate >= 40 && heartRate <= 120 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateHRVScore(_ hrv: Double) -> Double {
        // Higher HRV generally indicates better health
        if hrv >= 50 {
            return 1.0
        } else if hrv >= 30 {
            return 0.8
        } else if hrv >= 20 {
            return 0.6
        } else {
            return 0.4
        }
    }
    
    private func calculateRespiratoryScore(_ respiratoryRate: Double) -> Double {
        // Normal respiratory rate is 12-20 breaths per minute
        if respiratoryRate >= 12 && respiratoryRate <= 20 {
            return 1.0
        } else if respiratoryRate >= 10 && respiratoryRate <= 24 {
            return 0.8
        } else if respiratoryRate >= 8 && respiratoryRate <= 28 {
            return 0.6
        } else {
            return 0.4
        }
    }
    
    // MARK: - Published Properties
    @Published var currentHeartRate: Double = 0.0
    @Published var currentHRV: Double = 0.0
    @Published var currentRespiratoryRate: Double = 0.0
    @Published var sleepData: [SleepSession] = []
    
    // NEW: Advanced Health Analysis Features
    @Published var sleepPatterns: [SleepPattern] = []
    @Published var biometricTrends: BiometricTrends?
    @Published var healthInsights: [HealthInsight] = []
    @Published var sleepPredictions: SleepPrediction?
    @Published var healthScore: Float = 0.0
    @Published var recoveryStatus: RecoveryStatus = .unknown
    @Published var stressLevel: StressLevel = .low
    @Published var sleepQualityTrend: SleepQualityTrend = .stable
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    private var hrvQuery: HKQuery?
    private var movementQuery: HKQuery?
    
    // NEW: Advanced Analysis Components
    private var sleepPatternAnalyzer: SleepPatternAnalyzer?
    private var biometricAnalyzer: BiometricAnalyzer?
    private var healthPredictor: HealthPredictor?
    private var recoveryAnalyzer: RecoveryAnalyzer?
    private var stressAnalyzer: StressAnalyzer?
    private var trendAnalyzer: TrendAnalyzer?
    
    // MARK: - Configuration
    private let updateInterval: TimeInterval = 60 // 1 minute
    private let analysisWindow: TimeInterval = 24 * 60 * 60 // 24 hours
    private let trendWindow: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // NEW: Enhanced Configuration
    private let sleepPatternThreshold: Float = 0.7
    private let biometricCorrelationThreshold: Float = 0.6
    private let predictionConfidenceThreshold: Float = 0.8
    private let healthScoreWeights: [String: Float] = [
        "sleepQuality": 0.3,
        "heartRate": 0.2,
        "hrv": 0.25,
        "respiratoryRate": 0.15,
        "stressLevel": 0.1
    ]
    
    private init() {
        checkAvailability()
        checkAuthorizationStatus()
        setupAdvancedAnalyzers()
    }
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Enhanced HealthKit Setup
    
    private func setupHealthKitManager() {
        checkAuthorizationStatus()
        Logger.success("HealthKit manager initialized", log: Logger.healthKit)
    }
    
    private func setupAdvancedAnalyzers() {
        // NEW: Initialize advanced analysis components
        sleepPatternAnalyzer = SleepPatternAnalyzer()
        biometricAnalyzer = BiometricAnalyzer()
        healthPredictor = HealthPredictor()
        recoveryAnalyzer = RecoveryAnalyzer()
        stressAnalyzer = StressAnalyzer()
        trendAnalyzer = TrendAnalyzer()
        
        Logger.success("Advanced health analyzers initialized", log: Logger.healthKit)
    }
    
    // MARK: - Authorization
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit is not available on this device", log: Logger.healthKit)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.getRequestStatusForAuthorization(toShare: typesToWrite, read: typesToRead) { status, error in
            DispatchQueue.main.async {
                self.isAuthorized = status == .unnecessary
            }
        }
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit is not available on this device", log: Logger.healthKit)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            requestedPermissions = true
            Logger.success("HealthKit authorization successful", log: Logger.healthKit)
        } catch {
            Logger.error("HealthKit authorization failed: \(error.localizedDescription)", log: Logger.healthKit)
        }
    }
    
    // MARK: - Biometric Data Collection
    func startBiometricMonitoring() {
        guard isAuthorized else {
            Logger.error("HealthKit not authorized", log: Logger.healthKit)
            return
        }
        Logger.info("Starting biometric monitoring", log: Logger.healthKit)
        // Initialize biometric data if needed
        if biometricData == nil {
            biometricData = BiometricData()
        }
        startHeartRateMonitoring()
        startHRVMonitoring()
        startMovementMonitoring()
    }
    
    func stopBiometricMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        if let query = hrvQuery {
            healthStore.stop(query)
            hrvQuery = nil
        }
        if let query = movementQuery {
            healthStore.stop(query)
            movementQuery = nil
        }
        Logger.info("Stopped biometric monitoring", log: Logger.healthKit)
    }
    
    // MARK: - Heart Rate Monitoring
    private func startHeartRateMonitoring() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, anchor, error in
            self.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.processHeartRateSamples(samples)
        }
        
        heartRateQuery = query
        healthStore.execute(query)
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        let latestSample = samples.last
        let heartRate = latestSample?.quantity.doubleValue(for: HKUnit(from: "count/min")) ?? 0
        
        self.biometricData?.heartRate = heartRate
        self.lastUpdated = Date()
    }
    
    // MARK: - HRV Monitoring
    private func startHRVMonitoring() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let query = HKAnchoredObjectQuery(type: hrvType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, anchor, error in
            self.processHRVSamples(samples)
        }
        
        query.updateHandler = { query, samples, deletedObjects, anchor, error in
            self.processHRVSamples(samples)
        }
        
        hrvQuery = query
        healthStore.execute(query)
    }
    
    private func processHRVSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        let latestSample = samples.last
        let hrv = latestSample?.quantity.doubleValue(for: HKUnit(from: "ms")) ?? 0
        
        self.biometricData?.hrv = hrv
        self.lastUpdated = Date()
    }
    
    // MARK: - Movement Monitoring
    private func startMovementMonitoring() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, statistics, error in
            self.processMovementData(statistics)
        }
        
        movementQuery = query
        healthStore.execute(query)
    }
    
    private func processMovementData(_ statistics: HKStatistics?) {
        let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
        
        self.biometricData?.movement = steps
        self.lastUpdated = Date()
    }
    
    // MARK: - Sleep Data Management
    func saveSleepSession(_ session: SleepSession) async {
        guard isAuthorized else {
            Logger.error("HealthKit not authorized", log: Logger.healthKit)
            return
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sleepSample = HKCategorySample(
            type: sleepType,
            value: session.sleepStage.rawValue,
            start: session.startTime,
            end: session.endTime,
            metadata: [
                "duration": session.duration,
                "quality": session.quality,
                "cycles": session.cycleCount
            ]
        )
        
        do {
            try await healthStore.save(sleepSample)
            Logger.success("Sleep session saved to HealthKit", log: Logger.healthKit)
        } catch {
            Logger.error("Failed to save sleep session: \(error.localizedDescription)", log: Logger.healthKit)
        }
    }
    
    // MARK: - Data Retrieval
    func fetchSleepData(from startDate: Date, to endDate: Date) async -> [SleepSession] {
        guard isAuthorized else { return [] }
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        do {
            let samples = try await healthStore.samples(of: sleepType, predicate: predicate, sortDescriptors: [sortDescriptor])
            Logger.info("Fetched \(samples.count) sleep data samples from HealthKit", log: Logger.healthKit)
            return samples.compactMap { sample in
                guard let categorySample = sample as? HKCategorySample else { return nil }
                return SleepSession(from: categorySample)
            }
        } catch {
            Logger.error("Failed to fetch sleep data: \(error.localizedDescription)", log: Logger.healthKit)
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func checkAvailability() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        if !isAvailable {
            Logger.warning("HealthKit is not available on this device", log: Logger.healthKit)
        }
    }
    
    private func checkAuthorizationStatus() async {
        guard isAvailable else { return }
        
        do {
            let status = try await healthStore.statusForAuthorizationRequest(toShare: nil, read: requiredTypes)
            
            await MainActor.run {
                isAuthorized = status == .sharingAuthorized
                
                // Check individual permissions
                checkIndividualPermissions()
            }
            
            Logger.info("HealthKit authorization status: \(status.rawValue)", log: Logger.healthKit)
        } catch {
            Logger.error("Failed to check authorization status: \(error.localizedDescription)", log: Logger.healthKit)
        }
    }
    
    private func checkIndividualPermissions() {
        // Check each permission individually
        heartRatePermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!) == .sharingAuthorized
        hrvPermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!) == .sharingAuthorized
        respiratoryRatePermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .respiratoryRate)!) == .sharingAuthorized
        sleepAnalysisPermission = healthStore.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!) == .sharingAuthorized
        oxygenSaturationPermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!) == .sharingAuthorized
        bodyTemperaturePermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .bodyTemperature)!) == .sharingAuthorized
    }
    
    private func fetchHeartRateData() async throws -> [HKQuantitySample] {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-86400), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let samples = samples as? [HKQuantitySample] {
                    continuation.resume(returning: samples)
                } else {
                    continuation.resume(returning: [])
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchSleepAnalysisData() async throws -> [HKCategorySample] {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-86400), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let samples = samples as? [HKCategorySample] {
                    continuation.resume(returning: samples)
                } else {
                    continuation.resume(returning: [])
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchBiometricData() async throws -> [String: [HKQuantitySample]] {
        var biometricData: [String: [HKQuantitySample]] = [:]
        
        // Fetch HRV data
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvData = try await fetchQuantityData(for: hrvType)
        biometricData["hrv"] = hrvData
        
        // Fetch respiratory rate data
        let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        let respiratoryData = try await fetchQuantityData(for: respiratoryType)
        biometricData["respiratory"] = respiratoryData
        
        // Fetch oxygen saturation data
        let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        let oxygenData = try await fetchQuantityData(for: oxygenType)
        biometricData["oxygen"] = oxygenData
        
        // Fetch body temperature data
        let temperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
        let temperatureData = try await fetchQuantityData(for: temperatureType)
        biometricData["temperature"] = temperatureData
        
        return biometricData
    }
    
    private func fetchQuantityData(for quantityType: HKQuantityType) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-86400), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let samples = samples as? [HKQuantitySample] {
                    continuation.resume(returning: samples)
                } else {
                    continuation.resume(returning: [])
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func processHealthData(heartRate: [HKQuantitySample], sleep: [HKCategorySample], biometric: [String: [HKQuantitySample]]) async {
        // Process and store the health data
        // This would typically involve saving to Core Data or other local storage
        
        Logger.info("Processed \(heartRate.count) heart rate samples, \(sleep.count) sleep samples", log: Logger.healthKit)
        
        // Update the sleep manager with new data
        await SleepManager.shared.updateWithHealthData(heartRate: heartRate, sleep: sleep, biometric: biometric)
    }
    
    // MARK: - NEW: Advanced Health Data Analysis
    
    func performComprehensiveHealthAnalysis() async {
        Logger.info("Starting comprehensive health data analysis", log: Logger.healthKit)
        
        // Step 1: Sleep Pattern Recognition
        await analyzeSleepPatterns()
        
        // Step 2: Biometric Trend Analysis
        await analyzeBiometricTrends()
        
        // Step 3: Health Correlation Analysis
        await analyzeHealthCorrelations()
        
        // Step 4: Predictive Analytics
        await performPredictiveAnalytics()
        
        // Step 5: Recovery Status Analysis
        await analyzeRecoveryStatus()
        
        // Step 6: Stress Level Analysis
        await analyzeStressLevel()
        
        // Step 7: Generate Health Insights
        await generateHealthInsights()
        
        // Step 8: Calculate Health Score
        await calculateHealthScore()
        
        Logger.success("Comprehensive health analysis completed", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Sleep Pattern Recognition
    
    private func analyzeSleepPatterns() async {
        guard let sleepPatternAnalyzer = sleepPatternAnalyzer else { return }
        
        let sleepData = await fetchSleepData(from: Date().addingTimeInterval(-trendWindow), to: Date())
        
        let patterns = await sleepPatternAnalyzer.identifyPatterns(sleepData)
        
        await MainActor.run {
            self.sleepPatterns = patterns
        }
        
        // Analyze sleep quality trends
        let qualityTrend = await sleepPatternAnalyzer.analyzeQualityTrend(sleepData)
        
        await MainActor.run {
            self.sleepQualityTrend = qualityTrend
        }
        
        Logger.info("Identified \(patterns.count) sleep patterns", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Biometric Trend Analysis
    
    private func analyzeBiometricTrends() async {
        guard let biometricAnalyzer = biometricAnalyzer else { return }
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-trendWindow)
        
        // Collect biometric data
        let heartRateData = await fetchHeartRateData(from: startDate, to: endDate)
        let hrvData = await fetchHRVData(from: startDate, to: endDate)
        let respiratoryData = await fetchRespiratoryRateData(from: startDate, to: endDate)
        
        // Analyze trends
        let trends = await biometricAnalyzer.analyzeTrends(
            heartRate: heartRateData,
            hrv: hrvData,
            respiratoryRate: respiratoryData
        )
        
        await MainActor.run {
            self.biometricTrends = trends
        }
        
        Logger.info("Biometric trends analyzed", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Health Correlation Analysis
    
    private func analyzeHealthCorrelations() async {
        guard let biometricAnalyzer = biometricAnalyzer else { return }
        
        let correlations = await biometricAnalyzer.analyzeCorrelations(
            sleepData: sleepData,
            biometricTrends: biometricTrends
        )
        
        // Store correlations for insights
        await MainActor.run {
            // Update insights with correlation data
            let correlationInsight = HealthInsight(
                type: .correlation,
                title: "Health Correlations",
                description: "Analysis of relationships between sleep and biometric data",
                severity: .info,
                data: correlations
            )
            self.healthInsights.append(correlationInsight)
        }
        
        Logger.info("Health correlations analyzed", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Predictive Analytics
    
    private func performPredictiveAnalytics() async {
        guard let healthPredictor = healthPredictor else { return }
        
        let prediction = await healthPredictor.predictSleepQuality(
            sleepPatterns: sleepPatterns,
            biometricTrends: biometricTrends,
            historicalData: sleepData
        )
        
        await MainActor.run {
            self.sleepPredictions = prediction
        }
        
        Logger.info("Sleep predictions generated", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Recovery Status Analysis
    
    private func analyzeRecoveryStatus() async {
        guard let recoveryAnalyzer = recoveryAnalyzer else { return }
        
        let recoveryStatus = await recoveryAnalyzer.analyzeRecoveryStatus(
            heartRate: currentHeartRate,
            hrv: currentHRV,
            sleepQuality: sleepData.last?.quality ?? 0.0,
            sleepDuration: sleepData.last?.duration ?? 0.0
        )
        
        await MainActor.run {
            self.recoveryStatus = recoveryStatus
        }
        
        Logger.info("Recovery status analyzed: \(recoveryStatus)", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Stress Level Analysis
    
    private func analyzeStressLevel() async {
        guard let stressAnalyzer = stressAnalyzer else { return }
        
        let stressLevel = await stressAnalyzer.analyzeStressLevel(
            heartRate: currentHeartRate,
            hrv: currentHRV,
            respiratoryRate: currentRespiratoryRate,
            sleepQuality: sleepData.last?.quality ?? 0.0
        )
        
        await MainActor.run {
            self.stressLevel = stressLevel
        }
        
        Logger.info("Stress level analyzed: \(stressLevel)", log: Logger.healthKit)
    }
    
    // MARK: - NEW: Health Insights Generation
    
    private func generateHealthInsights() async {
        var insights: [HealthInsight] = []
        
        // Sleep pattern insights
        if let sleepInsight = generateSleepInsight() {
            insights.append(sleepInsight)
        }
        
        // Biometric insights
        if let biometricInsight = generateBiometricInsight() {
            insights.append(biometricInsight)
        }
        
        // Recovery insights
        if let recoveryInsight = generateRecoveryInsight() {
            insights.append(recoveryInsight)
        }
        
        // Stress insights
        if let stressInsight = generateStressInsight() {
            insights.append(stressInsight)
        }
        
        // Prediction insights
        if let predictionInsight = generatePredictionInsight() {
            insights.append(predictionInsight)
        }
        
        await MainActor.run {
            self.healthInsights = insights
        }
        
        Logger.info("Generated \(insights.count) health insights", log: Logger.healthKit)
    }
    
    private func generateSleepInsight() -> HealthInsight? {
        guard let lastSleep = sleepData.last else { return nil }
        
        let quality = lastSleep.quality
        let duration = lastSleep.duration / 3600 // Convert to hours
        
        if quality < 0.6 {
            return HealthInsight(
                type: .sleep,
                title: "Sleep Quality Alert",
                description: "Your sleep quality was below optimal levels. Consider improving your sleep environment or routine.",
                severity: .warning,
                data: ["quality": quality, "duration": duration]
            )
        } else if duration < 7 {
            return HealthInsight(
                type: .sleep,
                title: "Sleep Duration Notice",
                description: "You slept for \(String(format: "%.1f", duration)) hours. Aim for 7-9 hours for optimal health.",
                severity: .info,
                data: ["quality": quality, "duration": duration]
            )
        }
        
        return nil
    }
    
    private func generateBiometricInsight() -> HealthInsight? {
        guard let trends = biometricTrends else { return nil }
        
        if trends.heartRateTrend == .increasing {
            return HealthInsight(
                type: .biometric,
                title: "Heart Rate Trend",
                description: "Your resting heart rate has been increasing. This may indicate stress or poor recovery.",
                severity: .warning,
                data: ["trend": "increasing"]
            )
        }
        
        if trends.hrvTrend == .decreasing {
            return HealthInsight(
                type: .biometric,
                title: "HRV Decline",
                description: "Your heart rate variability has been decreasing. Focus on stress management and recovery.",
                severity: .warning,
                data: ["trend": "decreasing"]
            )
        }
        
        return nil
    }
    
    private func generateRecoveryInsight() -> HealthInsight? {
        switch recoveryStatus {
        case .poor:
            return HealthInsight(
                type: .recovery,
                title: "Poor Recovery Detected",
                description: "Your body shows signs of poor recovery. Consider rest days and stress reduction.",
                severity: .warning,
                data: ["status": "poor"]
            )
        case .excellent:
            return HealthInsight(
                type: .recovery,
                title: "Excellent Recovery",
                description: "Your recovery metrics are excellent! You're ready for high-intensity activities.",
                severity: .success,
                data: ["status": "excellent"]
            )
        default:
            return nil
        }
    }
    
    private func generateStressInsight() -> HealthInsight? {
        switch stressLevel {
        case .high:
            return HealthInsight(
                type: .stress,
                title: "High Stress Detected",
                description: "Your biometric data indicates high stress levels. Consider relaxation techniques.",
                severity: .warning,
                data: ["level": "high"]
            )
        case .moderate:
            return HealthInsight(
                type: .stress,
                title: "Moderate Stress",
                description: "You're experiencing moderate stress. Monitor your stress management strategies.",
                severity: .info,
                data: ["level": "moderate"]
            )
        default:
            return nil
        }
    }
    
    private func generatePredictionInsight() -> HealthInsight? {
        guard let prediction = sleepPredictions else { return nil }
        
        if prediction.confidence > predictionConfidenceThreshold {
            return HealthInsight(
                type: .prediction,
                title: "Sleep Quality Prediction",
                description: "Based on your patterns, tonight's sleep quality is predicted to be \(String(format: "%.1f", prediction.expectedQuality * 100))%.",
                severity: .info,
                data: ["predictedQuality": prediction.expectedQuality, "confidence": prediction.confidence]
            )
        }
        
        return nil
    }
    
    // MARK: - NEW: Health Score Calculation
    
    private func calculateHealthScore() async {
        var score: Float = 0.0
        
        // Sleep quality component
        let sleepQuality = sleepData.last?.quality ?? 0.0
        score += sleepQuality * (healthScoreWeights["sleepQuality"] ?? 0.25)
        
        // Heart rate component
        let heartRateScore = calculateHeartRateScore(currentHeartRate)
        score += heartRateScore * (healthScoreWeights["heartRate"] ?? 0.2)
        
        // HRV component
        let hrvScore = calculateHRVScore(currentHRV)
        score += hrvScore * (healthScoreWeights["hrv"] ?? 0.2)
        
        // Respiratory rate component
        let respiratoryScore = calculateRespiratoryScore(currentRespiratoryRate)
        score += respiratoryScore * (healthScoreWeights["respiratoryRate"] ?? 0.15)
        
        // Stress level component
        let stressScore = calculateStressScore(stressLevel)
        score += stressScore * (healthScoreWeights["stressLevel"] ?? 0.2)
        
        await MainActor.run {
            self.healthScore = min(max(score, 0.0), 1.0)
        }
        
        Logger.info("Health score calculated: \(healthScore)", log: Logger.healthKit)
    }
    
    private func calculateHeartRateScore(_ heartRate: Double) -> Float {
        // Optimal resting heart rate is 60-100 BPM
        if heartRate >= 60 && heartRate <= 100 {
            return 1.0
        } else if heartRate >= 50 && heartRate <= 110 {
            return 0.8
        } else if heartRate >= 40 && heartRate <= 120 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateHRVScore(_ hrv: Double) -> Float {
        // Higher HRV is generally better
        if hrv >= 50 {
            return 1.0
        } else if hrv >= 30 {
            return 0.8
        } else if hrv >= 20 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateRespiratoryScore(_ respiratoryRate: Double) -> Float {
        // Normal respiratory rate is 12-20 breaths per minute
        if respiratoryRate >= 12 && respiratoryRate <= 20 {
            return 1.0
        } else if respiratoryRate >= 10 && respiratoryRate <= 25 {
            return 0.8
        } else if respiratoryRate >= 8 && respiratoryRate <= 30 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateStressScore(_ stressLevel: StressLevel) -> Float {
        switch stressLevel {
        case .low:
            return 1.0
        case .moderate:
            return 0.7
        case .high:
            return 0.4
        }
    }
    
    // MARK: - Enhanced Data Fetching
    
    func fetchHeartRateData(from startDate: Date, to endDate: Date) async -> [HeartRateData] {
        guard isAuthorized else { return [] }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            Logger.error("Heart rate type not available", log: Logger.healthKit)
            return []
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        do {
            let samples = try await healthStore.samples(of: heartRateType, predicate: predicate)
            return samples.compactMap { sample in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                return HeartRateData(
                    value: quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                    timestamp: quantitySample.startDate
                )
            }
        } catch {
            Logger.error("Failed to fetch heart rate data: \(error.localizedDescription)", log: Logger.healthKit)
            return []
        }
    }
    
    func fetchHRVData(from startDate: Date, to endDate: Date) async -> [HRVData] {
        guard isAuthorized else { return [] }
        
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            Logger.error("HRV type not available", log: Logger.healthKit)
            return []
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        do {
            let samples = try await healthStore.samples(of: hrvType, predicate: predicate)
            return samples.compactMap { sample in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                return HRVData(
                    value: quantitySample.quantity.doubleValue(for: .secondUnit(with: .milli)),
                    timestamp: quantitySample.startDate
                )
            }
        } catch {
            Logger.error("Failed to fetch HRV data: \(error.localizedDescription)", log: Logger.healthKit)
            return []
        }
    }
    
    func fetchRespiratoryRateData(from startDate: Date, to endDate: Date) async -> [RespiratoryRateData] {
        guard isAuthorized else { return [] }
        
        guard let respiratoryType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            Logger.error("Respiratory rate type not available", log: Logger.healthKit)
            return []
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        do {
            let samples = try await healthStore.samples(of: respiratoryType, predicate: predicate)
            return samples.compactMap { sample in
                guard let quantitySample = sample as? HKQuantitySample else { return nil }
                return RespiratoryRateData(
                    value: quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())),
                    timestamp: quantitySample.startDate
                )
            }
        } catch {
            Logger.error("Failed to fetch respiratory rate data: \(error.localizedDescription)", log: Logger.healthKit)
            return []
        }
    }
    
    // MARK: - Public Interface
    
    func getHealthSummary() -> HealthSummary {
        return HealthSummary(
            healthScore: healthScore,
            recoveryStatus: recoveryStatus,
            stressLevel: stressLevel,
            sleepQualityTrend: sleepQualityTrend,
            insights: healthInsights,
            predictions: sleepPredictions
        )
    }
    
    func getBiometricSummary() -> BiometricSummary {
        return BiometricSummary(
            heartRate: currentHeartRate,
            hrv: currentHRV,
            respiratoryRate: currentRespiratoryRate,
            trends: biometricTrends
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateSleepConsistency(_ sessions: [SleepSession]) -> Double {
        guard sessions.count > 1 else { return 1.0 }
        
        let startTimes = sessions.map { $0.startTime }
        let sortedTimes = startTimes.sorted()
        
        var timeDifferences: [TimeInterval] = []
        for i in 1..<sortedTimes.count {
            let diff = abs(sortedTimes[i].timeIntervalSince(sortedTimes[i-1]))
            timeDifferences.append(diff)
        }
        
        let avgDifference = timeDifferences.reduce(0, +) / Double(timeDifferences.count)
        return max(0, 1.0 - (avgDifference / (24 * 3600)))
    }
    
    private func calculateBiometricHealth(_ data: [BiometricData]) -> Double {
        guard !data.isEmpty else { return 0.5 }
        
        let heartRates = data.map { $0.heartRate }
        let hrvs = data.map { $0.hrv }
        let bloodOxygens = data.map { $0.oxygenSaturation }
        
        let hrHealth = heartRates.map { hr in
            if hr >= 60 && hr <= 100 { return 1.0 }
            else if hr >= 50 && hr <= 110 { return 0.8 }
            else { return 0.5 }
        }.reduce(0, +) / Double(heartRates.count)
        
        let hrvHealth = hrvs.map { hrv in
            if hrv >= 20 && hrv <= 60 { return 1.0 }
            else if hrv >= 15 && hrv <= 80 { return 0.8 }
            else { return 0.5 }
        }.reduce(0, +) / Double(hrvs.count)
        
        let spo2Health = bloodOxygens.map { spo2 in
            if spo2 >= 95 { return 1.0 }
            else if spo2 >= 90 { return 0.8 }
            else { return 0.3 }
        }.reduce(0, +) / Double(bloodOxygens.count)
        
        return (hrHealth + hrvHealth + spo2Health) / 3.0
    }
    
    private func predictQualityFromPatterns(avgQuality: Double, consistency: Double, biometricHealth: Double) -> Double {
        // Weighted prediction based on historical patterns
        let baseQuality = avgQuality * 0.6
        let consistencyBonus = consistency * 0.2
        let biometricBonus = biometricHealth * 0.2
        
        return min(1.0, baseQuality + consistencyBonus + biometricBonus)
    }
    
    private func predictDurationFromPatterns(avgDuration: TimeInterval, consistency: Double) -> TimeInterval {
        // Predict duration with some variation based on consistency
        let variation = (1.0 - consistency) * 0.5 // Less consistent = more variation
        let predictedDuration = avgDuration * (1.0 + Double.random(in: -variation...variation))
        
        return max(6.0 * 3600, min(10.0 * 3600, predictedDuration)) // 6-10 hours
    }
    
    private func calculatePredictionConfidence(dataPoints: Int, consistency: Double, biometricHealth: Double) -> Double {
        let dataConfidence = min(1.0, Double(dataPoints) / 7.0) // More data = higher confidence
        let consistencyConfidence = consistency
        let biometricConfidence = biometricHealth
        
        return (dataConfidence + consistencyConfidence + biometricConfidence) / 3.0
    }
    
    private func calculateStressLevel(_ data: [BiometricData]) -> Double {
        guard !data.isEmpty else { return 0.5 }
        
        let heartRates = data.map { $0.heartRate }
        let hrvs = data.map { $0.hrv }
        
        let hrStress = heartRates.map { hr in
            if hr > 80 { return 1.0 }
            else if hr > 70 { return 0.7 }
            else if hr > 60 { return 0.4 }
            else { return 0.2 }
        }.reduce(0, +) / Double(heartRates.count)
        
        let hrvStress = hrvs.map { hrv in
            if hrv < 20 { return 1.0 }
            else if hrv < 30 { return 0.7 }
            else if hrv < 40 { return 0.4 }
            else { return 0.2 }
        }.reduce(0, +) / Double(hrvs.count)
        
        return (hrStress + hrvStress) / 2.0
    }
    
    private func calculateRecoveryStatus(_ sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.5 }
        
        let recentSessions = Array(sessions.suffix(3))
        let avgDeepSleep = recentSessions.map { $0.deepSleepPercentage }.reduce(0, +) / Double(recentSessions.count)
        let avgQuality = recentSessions.map { $0.sleepQuality }.reduce(0, +) / Double(recentSessions.count)
        
        let deepSleepScore = avgDeepSleep / 100.0
        return (deepSleepScore + avgQuality) / 2.0
    }
    
    private func groupSessionsByWeek(_ sessions: [SleepSession]) -> [Date: [SleepSession]] {
        var groups: [Date: [SleepSession]] = [:]
        
        for session in sessions {
            let weekStart = getWeekStart(for: session.startTime)
            if groups[weekStart] == nil {
                groups[weekStart] = []
            }
            groups[weekStart]?.append(session)
        }
        
        return groups
    }
    
    private func getWeekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func analyzeWeeklyPattern(_ sessions: [SleepSession], weekStart: Date) -> SleepPattern {
        guard !sessions.isEmpty else {
            return SleepPattern(
                type: .irregular,
                startDate: weekStart,
                endDate: weekStart,
                averageDuration: 0,
                averageQuality: 0,
                consistency: 0,
                insights: []
            )
        }
        
        let durations = sessions.map { $0.duration }
        let qualities = sessions.map { calculateQualityScore($0) }
        let startTimes = sessions.map { $0.startTime }
        
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let avgQuality = qualities.reduce(0, +) / Double(qualities.count)
        let consistency = calculateConsistency(startTimes, durations)
        
        let patternType = determinePatternType(
            avgDuration: avgDuration,
            avgQuality: avgQuality,
            consistency: consistency,
            sessionCount: sessions.count
        )
        
        let insights = generatePatternInsights(
            sessions: sessions,
            patternType: patternType,
            avgDuration: avgDuration,
            avgQuality: avgQuality
        )
        
        return SleepPattern(
            type: patternType,
            startDate: weekStart,
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart,
            averageDuration: avgDuration,
            averageQuality: avgQuality,
            consistency: consistency,
            insights: insights
        )
    }
    
    private func calculateQualityScore(_ session: SleepSession) -> Double {
        // Multi-factor quality calculation
        let durationScore = min(session.duration / 8.0, 1.0) // Optimal: 8 hours
        let efficiencyScore = session.sleepEfficiency
        let deepSleepScore = session.deepSleepPercentage / 100.0
        let remSleepScore = session.remSleepPercentage / 100.0
        
        // Weighted average
        return durationScore * 0.3 + efficiencyScore * 0.3 + deepSleepScore * 0.2 + remSleepScore * 0.2
    }
    
    private func calculateConsistency(_ startTimes: [Date], _ durations: [TimeInterval]) -> Double {
        guard startTimes.count > 1 else { return 1.0 }
        
        // Calculate consistency of sleep timing
        let sortedTimes = startTimes.sorted()
        var timeDifferences: [TimeInterval] = []
        
        for i in 1..<sortedTimes.count {
            let diff = abs(sortedTimes[i].timeIntervalSince(sortedTimes[i-1]))
            timeDifferences.append(diff)
        }
        
        let avgDifference = timeDifferences.reduce(0, +) / Double(timeDifferences.count)
        let consistency = max(0, 1.0 - (avgDifference / (24 * 3600))) // Normalize to 24 hours
        
        return consistency
    }
    
    private func determinePatternType(avgDuration: TimeInterval, avgQuality: Double, consistency: Double, sessionCount: Int) -> SleepPatternType {
        if sessionCount < 3 {
            return .irregular
        }
        
        if consistency > 0.8 && avgQuality > 0.7 {
            return .consistent
        } else if avgDuration < 6.0 {
            return .shortSleep
        } else if avgDuration > 9.0 {
            return .longSleep
        } else if avgQuality < 0.5 {
            return .poorQuality
        } else if avgQuality > 0.8 {
            return .goodQuality
        } else {
            return .irregular
        }
    }
    
    private func generatePatternInsights(sessions: [SleepSession], patternType: SleepPatternType, avgDuration: TimeInterval, avgQuality: Double) -> [String] {
        var insights: [String] = []
        
        switch patternType {
        case .consistent:
            insights.append("Excellent sleep consistency! Your regular sleep schedule is working well.")
        case .shortSleep:
            insights.append("You're getting less than 6 hours of sleep on average. Consider extending your sleep time.")
        case .longSleep:
            insights.append("You're sleeping more than 9 hours regularly. This might indicate underlying fatigue or health issues.")
        case .poorQuality:
            insights.append("Sleep quality is below optimal levels. Consider improving your sleep environment.")
        case .goodQuality:
            insights.append("Great sleep quality! Your sleep habits are supporting good rest.")
        case .irregular:
            insights.append("Your sleep schedule is irregular. Try to maintain consistent bedtimes.")
        }
        
        if avgDuration < 7.0 {
            insights.append("Consider increasing sleep duration to 7-9 hours for optimal health.")
        }
        
        if avgQuality < 0.6 {
            insights.append("Focus on sleep hygiene practices to improve sleep quality.")
        }
        
        return insights
    }
    
    private func calculateLinearTrend<T: BinaryFloatingPoint>(_ values: [T]) -> Double {
        guard values.count > 1 else { return 0.0 }

        let n = Double(values.count)
        let indices = (0..<values.count).map { Double($0) }

        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0) { $0 + Double($1) }
        let sumXY = zip(indices, values).map { $0 * Double($1) }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        return slope
    }
    
    private func analyzeTrend(_ values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }
        
        // Use linear regression to determine trend
        let trend = calculateLinearTrend(values)
        
        if trend > 0.1 {
            return .increasing
        } else if trend < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func calculateCorrelationMatrix(_ data: [BiometricData]) -> [String: Float] {
        var correlations: [String: Float] = [:]
        
        let heartRates = data.map { $0.heartRate }
        let hrvs = data.map { $0.hrv }
        let respiratoryRates = data.map { $0.respiratoryRate }
        let bloodOxygens = data.map { $0.oxygenSaturation }
        let temperatures = data.map { $0.temperature }
        
        correlations["heartRate_hrv"] = calculateCorrelation(heartRates, hrvs)
        correlations["heartRate_respiratory"] = calculateCorrelation(heartRates, respiratoryRates)
        correlations["heartRate_bloodOxygen"] = calculateCorrelation(heartRates, bloodOxygens)
        correlations["hrv_respiratory"] = calculateCorrelation(hrvs, respiratoryRates)
        correlations["hrv_bloodOxygen"] = calculateCorrelation(hrvs, bloodOxygens)
        correlations["respiratory_bloodOxygen"] = calculateCorrelation(respiratoryRates, bloodOxygens)
        
        return correlations
    }
    
    private func calculateCorrelation<T: BinaryFloatingPoint>(_ x: [T], _ y: [T]) -> Float {
        guard x.count == y.count && x.count > 1 else { return 0.0 }

        let n = Double(x.count)
        let sumX = x.reduce(0) { $0 + Double($1) }
        let sumY = y.reduce(0) { $0 + Double($1) }
        let sumXY = zip(x, y).map { Double($0) * Double($1) }.reduce(0, +)
        let sumX2 = x.map { Double($0) * Double($0) }.reduce(0, +)
        let sumY2 = y.map { Double($0) * Double($0) }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        return denominator != 0 ? Float(numerator / denominator) : 0.0
    }
    
    private func calculateStatistics<T: BinaryFloatingPoint>(_ values: [T]) -> (mean: Double, stdDev: Double) {
        guard !values.isEmpty else { return (0, 0) }

        let mean = values.reduce(0) { $0 + Double($1) } / Double(values.count)
        let squaredDifferences = values.map { pow(Double($0) - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        return (mean: mean, stdDev: stdDev)
    }
}

// MARK: - Data Models
struct BiometricData: Codable {
    let timestamp: Date
    var heartRate: Double
    var hrv: Double
    var movement: Double
    var oxygenSaturation: Double
    var respiratoryRate: Double
    
    init(timestamp: Date = Date(), heartRate: Double = 0, hrv: Double = 0, movement: Double = 0, oxygenSaturation: Double = 0, respiratoryRate: Double = 0) {
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.hrv = hrv
        self.movement = movement
        self.oxygenSaturation = oxygenSaturation
        self.respiratoryRate = respiratoryRate
    }
}

// MARK: - SleepSession Extension
extension SleepSession {
    init(from sample: HKCategorySample) {
        let sleepStage: SleepStage
        switch sample.value {
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            sleepStage = .awake
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            sleepStage = .light
        case HKCategoryValueSleepAnalysis.asleep.rawValue:
            sleepStage = .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            sleepStage = .rem
        default:
            sleepStage = .awake
        }
        
        self.init(
            startTime: sample.startDate,
            endTime: sample.endDate,
            sleepStage: sleepStage,
            quality: 0.0,
            cycleCount: 0
        )
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let timeOnly: DateFormatter =