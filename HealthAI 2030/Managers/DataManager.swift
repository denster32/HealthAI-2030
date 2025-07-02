import Foundation
import HealthKit
import CoreML
import os.log

/// DataManager - Handles real sleep data collection and model training
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var isCollectingData = false
    @Published var dataPointsCollected = 0
    @Published var lastDataCollection = Date()
    @Published var modelTrainingProgress: Double = 0.0
    @Published var isAnalyzingHistoricalData = false
    @Published var historicalAnalysisProgress: Double = 0.0
    @Published var historicalDataPoints = 0
    @Published var hasCompletedInitialAnalysis = false
    
    private let healthStore = HKHealthStore()
    private var sleepDataHistory: [LabeledSleepData] = []
    private let maxDataPoints = 10000
    
    private init() {
        // Check if initial analysis has been completed
        hasCompletedInitialAnalysis = UserDefaults.standard.bool(forKey: "hasCompletedInitialAnalysis")
    }
    
    // MARK: - Initial Setup and Historical Analysis
    func performInitialSetup() async {
        // Check if initial analysis has already been completed
        if hasCompletedInitialAnalysis {
            Logger.info("Initial analysis already completed", log: Logger.dataManager)
            return
        }
        
        await MainActor.run {
            self.isAnalyzingHistoricalData = true
            self.historicalAnalysisProgress = 0.0
        }
        
        Logger.info("Starting initial historical data analysis...", log: Logger.dataManager)
        
        do {
            // Request HealthKit permissions
            await requestHealthKitPermissions()
            
            // Analyze historical sleep data
            await analyzeHistoricalSleepData()
            
            // Analyze historical biometric data
            await analyzeHistoricalBiometricData()
            
            // Establish user baseline
            await establishUserBaseline()
            
            // Mark analysis as completed
            await MainActor.run {
                self.hasCompletedInitialAnalysis = true
                self.isAnalyzingHistoricalData = false
                self.historicalAnalysisProgress = 1.0
            }
            
            UserDefaults.standard.set(true, forKey: "hasCompletedInitialAnalysis")
            
            Logger.success("Initial historical analysis completed successfully!", log: Logger.dataManager)
            Logger.info("Analyzed \(historicalDataPoints) historical data points", log: Logger.dataManager)
            
        } catch {
            Logger.error("Initial analysis failed: \(error.localizedDescription)", log: Logger.dataManager)
            
            await MainActor.run {
                self.isAnalyzingHistoricalData = false
                self.historicalAnalysisProgress = 0.0
            }
        }
    }
    
    private func analyzeHistoricalSleepData() async {
        await MainActor.run {
            self.historicalAnalysisProgress = 0.2
        }
        
        Logger.info("Analyzing historical sleep data...", log: Logger.dataManager)
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            
            let sleepSamples = try await fetchHistoricalSleepData(from: startDate, to: endDate)
            
            await MainActor.run {
                self.historicalAnalysisProgress = 0.4
            }
            
            Logger.info("Found \(sleepSamples.count) historical sleep samples", log: Logger.dataManager)
            
            // Process each sleep sample
            for sample in sleepSamples {
                await processHistoricalSleepSample(sample)
            }
            
            await MainActor.run {
                self.historicalAnalysisProgress = 0.6
            }
            
        } catch {
            Logger.error("Failed to analyze historical sleep data: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    private func analyzeHistoricalBiometricData() async {
        await MainActor.run {
            self.historicalAnalysisProgress = 0.7
        }
        
        Logger.info("Analyzing historical biometric data...", log: Logger.dataManager)
        
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            
            let biometricSamples = try await fetchHistoricalBiometricData(from: startDate, to: endDate)
            
            await MainActor.run {
                self.historicalDataPoints += biometricSamples.count
            }
            
            Logger.info("Found \(biometricSamples.count) historical biometric samples", log: Logger.dataManager)
            
            await processHistoricalBiometricData(biometricSamples)
            
            await MainActor.run {
                self.historicalAnalysisProgress = 0.9
            }
            
        } catch {
            Logger.error("Failed to analyze historical biometric data: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    private func establishUserBaseline() async {
        await MainActor.run {
            self.historicalAnalysisProgress = 0.95
        }
        
        Logger.info("Establishing user baseline...", log: Logger.dataManager)
        
        if let baseline = await createInitialUserBaseline() {
            await MainActor.run {
                self.userBaseline = baseline
            }
            
            if let data = try? JSONEncoder().encode(baseline) {
                UserDefaults.standard.set(data, forKey: "userSleepBaseline")
            }
            
            Logger.success("User baseline established", log: Logger.dataManager)
        }
        
        await MainActor.run {
            self.historicalAnalysisProgress = 1.0
        }
    }
    
    private func fetchHistoricalSleepData(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await healthStore.samples(of: sleepType, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    private func fetchHistoricalBiometricData(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        var allSamples: [HKQuantitySample] = []
        
        // Heart rate data
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let samples = try await healthStore.samples(of: heartRateType, predicate: predicate)
            allSamples.append(contentsOf: samples)
        }
        
        // HRV data
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let samples = try await healthStore.samples(of: hrvType, predicate: predicate)
            allSamples.append(contentsOf: samples)
        }
        
        // Blood oxygen data
        if let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let samples = try await healthStore.samples(of: oxygenType, predicate: predicate)
            allSamples.append(contentsOf: samples)
        }
        
        return allSamples
    }
    
    private func processHistoricalSleepSample(_ sample: HKCategorySample) async {
        // Convert HealthKit sleep sample to our format
        let sleepStage = mapSleepAnalysisToStage(sample.value)
        
        // Create labeled data point
        let labeledData = LabeledSleepData(
            timestamp: sample.startDate,
            features: createFeaturesFromHistoricalData(sample),
            predictedStage: sleepStage,
            actualStage: sleepStage,
            confidence: 0.8, // High confidence for historical data
            sleepQuality: calculateHistoricalSleepQuality(sample)
        )
        
        await addToHistory(labeledData)
    }
    
    private func processHistoricalBiometricData(_ samples: [HKQuantitySample]) async {
        // Group samples by time and create features
        let groupedSamples = Dictionary(grouping: samples) { sample in
            Calendar.current.startOfHour(for: sample.startDate)
        }
        
        for (hour, hourSamples) in groupedSamples {
            let features = createFeaturesFromBiometricSamples(hourSamples)
            
            // Create labeled data point
            let labeledData = LabeledSleepData(
                timestamp: hour,
                features: features,
                predictedStage: .light, // Default for historical data
                actualStage: nil,
                confidence: 0.6,
                sleepQuality: 0.7
            )
            
            await addToHistory(labeledData)
        }
    }
    
    private func createFeaturesFromHistoricalData(_ sample: HKCategorySample) -> SleepFeatures {
        // Create features from historical sleep data
        return SleepFeatures(
            heartRate: 65.0, // Default values for historical data
            heartRateVariability: 35.0,
            movement: 0.2,
            respiratoryRate: 14.0,
            oxygenSaturation: 97.0,
            temperature: 36.8,
            timeOfDay: calculateTimeOfNight(for: sample.startDate),
            previousStage: .awake,
            
            heartRateMin: 0.0, heartRateMax: 0.0, heartRateStdDev: 0.0,
            hrvMin: 0.0, hrvMax: 0.0, hrvStdDev: 0.0,
            bloodOxygenMin: 0.0, bloodOxygenMax: 0.0, bloodOxygenStdDev: 0.0,
            
            previousStageDuration: 0.0,
            heartRateChangeRate: 0.0,
            hrvChangeRate: 0.0,
            bloodOxygenChangeRate: 0.0
        )
    }
    
    private func createFeaturesFromBiometricSamples(_ samples: [HKQuantitySample]) -> SleepFeatures {
        // Aggregate biometric samples into features
        var heartRate = 65.0
        var hrv = 35.0
        var bloodOxygen = 97.0
        
        for sample in samples {
            switch sample.quantityType.identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
                hrv = sample.quantity.doubleValue(for: HKUnit(from: "ms"))
            case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
                bloodOxygen = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            default:
                break
            }
        }
        
        let heartRates = samples.filter { $0.quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue }.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
        let hrvs = samples.filter { $0.quantityType.identifier == HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue }.map { $0.quantity.doubleValue(for: HKUnit(from: "ms")) }
        let bloodOxygens = samples.filter { $0.quantityType.identifier == HKQuantityTypeIdentifier.oxygenSaturation.rawValue }.map { $0.quantity.doubleValue(for: HKUnit.percent()) * 100 }
        
        return SleepFeatures(
            heartRate: heartRate,
            heartRateVariability: hrv,
            movement: 0.2, // Placeholder, needs actual movement data
            respiratoryRate: 14.0, // Placeholder, needs actual respiratory rate data
            oxygenSaturation: bloodOxygen,
            temperature: 36.8, // Placeholder, needs actual temperature data
            timeOfDay: calculateTimeOfNight(for: samples.first?.startDate ?? Date()),
            previousStage: .awake, // Placeholder, needs actual previous stage
            
            heartRateMin: heartRates.min() ?? 0.0,
            heartRateMax: heartRates.max() ?? 0.0,
            heartRateStdDev: heartRates.stdDev(),
            hrvMin: hrvs.min() ?? 0.0,
            hrvMax: hrvs.max() ?? 0.0,
            hrvStdDev: hrvs.stdDev(),
            bloodOxygenMin: bloodOxygens.min() ?? 0.0,
            bloodOxygenMax: bloodOxygens.max() ?? 0.0,
            bloodOxygenStdDev: bloodOxygens.stdDev(),
            
            previousStageDuration: 0.0, // Placeholder
            heartRateChangeRate: calculateRateOfChange(heartRates),
            hrvChangeRate: calculateRateOfChange(hrvs),
            bloodOxygenChangeRate: calculateRateOfChange(bloodOxygens)
        )
    }
    
    private func calculateRateOfChange(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }
        return (values.last! - values.first!) / Double(values.count - 1)
    }
    
    private func getPreviousStageDuration() -> TimeInterval {
        // This would require tracking the duration of each sleep stage.
        // For now, return a placeholder.
        return 0.0
    }
    
    // MARK: - Adaptive User Baseline
    @Published var userBaseline: UserSleepBaseline? {
        didSet {
            if let baseline = userBaseline, let data = try? JSONEncoder().encode(baseline) {
                UserDefaults.standard.set(data, forKey: "userSleepBaseline")
            }
        }
    }
    
    private func updateAdaptiveUserBaseline(with newData: LabeledSleepData) {
        guard var currentBaseline = userBaseline else {
            // If no baseline exists, create an initial one from the new data
            userBaseline = UserSleepBaseline(
                averageSleepDuration: newData.features.previousStageDuration,
                averageDeepSleepPercentage: newData.predictedStage == .deep ? 1.0 : 0.0,
                averageREMSleepPercentage: newData.predictedStage == .rem ? 1.0 : 0.0,
                averageSleepEfficiency: newData.sleepQuality,
                typicalBedTime: newData.timestamp,
                typicalWakeTime: newData.timestamp, // This needs more sophisticated logic
                sleepLatency: 0.0, // Needs more sophisticated logic
                cycleLength: 0.0 // Needs more sophisticated logic
            )
            return
        }
        
        let alpha = 0.1 // Smoothing factor for exponential smoothing
        
        // Update average sleep quality
        currentBaseline.averageSleepQuality = alpha * newData.sleepQuality + (1 - alpha) * currentBaseline.averageSleepQuality
        
        // Update average heart rate
        currentBaseline.averageHeartRate = alpha * newData.features.heartRate + (1 - alpha) * currentBaseline.averageHeartRate
        
        // Update average HRV
        currentBaseline.averageHRV = alpha * newData.features.heartRateVariability + (1 - alpha) * currentBaseline.averageHRV
        
        // Update other baseline metrics adaptively as needed
        // For example, averageDeepSleepPercentage, averageREMSleepPercentage, etc.
        
        userBaseline = currentBaseline
    }
    
    // MARK: - Anomaly Detection
    private func detectAnomalies(features: SleepFeatures) -> [SleepInsight] {
        var anomalies: [SleepInsight] = []
        
        // Simple rule-based anomaly detection
        if features.heartRate > 120 || features.heartRate < 40 {
            anomalies.append(SleepInsight(title: "Abnormal Heart Rate", description: "Detected an unusually high or low heart rate: \(features.heartRate) BPM.", insightType: .anomaly, confidence: 0.9))
        }
        
        if features.bloodOxygen < 85 {
            anomalies.append(SleepInsight(title: "Low Blood Oxygen", description: "Detected a significant drop in blood oxygen saturation: \(features.bloodOxygen)%.", insightType: .anomaly, confidence: 0.95, insightCategory: .warning))
        }
        
        // Add more rules as needed for other features
        
        return anomalies
    }
    
    // MARK: - Helper Extensions
    
    // Extension to calculate standard deviation for an array of Doubles
    extension Array where Element == Double {
        func stdDev() -> Double {
            guard !isEmpty else { return 0.0 }
            let mean = self.reduce(0, +) / Double(self.count)
            let variance = self.map { pow($0 - mean, 2) }.reduce(0, +) / Double(self.count)
            return sqrt(variance)
        }
    }
    
    // Extension for Calendar to get start of hour
    extension Calendar {
        func startOfHour(for date: Date) -> Date {
            let components = dateComponents([.year, .month, .day, .hour], from: date)
            return self.date(from: components)!
        }
    }
    
    // MARK: - User Sleep Baseline
    @Published var userBaseline: UserSleepBaseline?
    
    private func createInitialUserBaseline() async -> UserSleepBaseline? {
        guard !sleepDataHistory.isEmpty else { return nil }
        
        let baseline = UserSleepBaseline()
        
        // Calculate averages from historical data
        let heartRates = sleepDataHistory.compactMap { $0.features.heartRate }
        let hrvs = sleepDataHistory.compactMap { $0.features.heartRateVariability }
        let qualities = sleepDataHistory.map { $0.sleepQuality }
        
        if !heartRates.isEmpty {
            baseline.averageHeartRate = heartRates.reduce(0, +) / Double(heartRates.count)
        }
        
        if !hrvs.isEmpty {
            baseline.averageHRV = hrvs.reduce(0, +) / Double(hrvs.count)
        }
        
        if !qualities.isEmpty {
            baseline.averageSleepQuality = qualities.reduce(0, +) / Double(qualities.count)
        }
        
        baseline.dataPoints = sleepDataHistory.count
        baseline.personalizationLevel = min(1.0, Double(sleepDataHistory.count) / 100.0)
        
        return baseline
    }
    
    private func calculateTimeOfNight(for date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Calculate time since typical sleep start (11 PM)
        if hour >= 23 {
            return Double(hour - 23)
        } else if hour < 7 {
            return Double(hour + 1)
        } else {
            return 0.0
        }
    }
    
    // MARK: - Data Collection
    func startDataCollection() async {
        await MainActor.run {
            self.isCollectingData = true
        }
        
        Logger.info("Starting real sleep data collection...", log: Logger.dataManager)
        
        do {
            // Request HealthKit permissions if not already granted
            await requestHealthKitPermissions()
            
            // Start collecting sleep data
            await collectSleepData()
            
            await MainActor.run {
                self.isCollectingData = false
            }
            
        } catch {
            Logger.error("Failed to start data collection: \(error.localizedDescription)", log: Logger.dataManager)
            
            await MainActor.run {
                self.isCollectingData = false
            }
        }
    }
    
    private func requestHealthKitPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit is not available on this device", log: Logger.dataManager)
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
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            Logger.success("HealthKit permissions granted", log: Logger.dataManager)
        } catch {
            Logger.error("HealthKit permissions failed: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    func stopDataCollection() async {
        await MainActor.run {
            self.isCollectingData = false
        }
        
        Logger.info("Stopped sleep data collection", log: Logger.dataManager)
    }
    
    private func collectSleepData() async {
        while isCollectingData {
            do {
                let sleepData = try await fetchCurrentSleepData()
                
                if let labeledData = await labelSleepData(sleepData) {
                    await addToHistory(labeledData)
                    
                    // Update adaptive user baseline
                    updateAdaptiveUserBaseline(with: labeledData)
                    
                    // Perform anomaly detection
                    let anomalies = detectAnomalies(features: labeledData.features)
                    if !anomalies.isEmpty {
                        for anomaly in anomalies {
                            Logger.warning("Detected anomaly: \(anomaly.title) - \(anomaly.description)", log: Logger.dataManager)
                            // Further actions for anomalies can be added here (e.g., trigger alerts)
                        }
                    }
                    
                    await MainActor.run {
                        self.dataPointsCollected += 1
                        self.lastDataCollection = Date()
                    }
                }
                
                // Adaptive sampling rate
                let collectionInterval = determineAdaptiveSamplingInterval()
                try await Task.sleep(nanoseconds: UInt64(collectionInterval * 1_000_000_000))
                
            } catch {
                Logger.error("Error collecting sleep data: \(error.localizedDescription)", log: Logger.dataManager)
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Wait 1 minute on error
            }
        }
    }
    
    private func determineAdaptiveSamplingInterval() -> TimeInterval {
        // Default interval
        var interval: TimeInterval = 30.0 // 30 seconds
        
        // Example: Adjust based on last predicted sleep stage
        if let lastStage = sleepDataHistory.last?.predictedStage {
            switch lastStage {
            case .deep:
                interval = 60.0 // Less frequent during deep sleep
            case .awake:
                interval = 10.0 // More frequent during awake periods
            case .rem, .light:
                interval = 30.0
            case .unknown:
                interval = 30.0
            }
        }
        
        // Example: Adjust based on device battery level (conceptual, requires BatteryManager)
        // if BatteryManager.shared.batteryLevel < 0.20 {
        //     interval *= 2 // Double interval if battery is low
        // }
        
        // Example: Adjust based on user activity (conceptual, requires ActivityManager)
        // if ActivityManager.shared.isUserActive {
        //     interval = 5.0 // Very frequent if user is active
        // }
        
        return interval
    }
    
    private func fetchCurrentSleepData() async throws -> RawSleepData {
        let now = Date()
        let startOfCurrentSleepSession = Calendar.current.date(byAdding: .hour, value: -8, to: now) ?? Calendar.current.startOfDay(for: now) // Assume max 8 hour sleep session for current data
        
        // Fetch heart rate data
        let heartRateData = try await fetchHeartRateData(from: startOfCurrentSleepSession, to: now)
        
        // Fetch HRV data
        let hrvData = try await fetchHRVData(from: startOfCurrentSleepSession, to: now)
        
        // Fetch blood oxygen data
        let bloodOxygenData = try await fetchBloodOxygenData(from: startOfCurrentSleepSession, to: now)
        
        // Fetch respiratory rate data
        let respiratoryData = try await fetchRespiratoryData(from: startOfCurrentSleepSession, to: now)
        
        // Fetch temperature data
        let temperatureData = try await fetchTemperatureData(from: startOfCurrentSleepSession, to: now)
        
        // Fetch sleep analysis data
        let sleepAnalysisData = try await fetchSleepAnalysisData(from: startOfCurrentSleepSession, to: now)
        
        return RawSleepData(
            timestamp: now,
            heartRate: heartRateData,
            hrv: hrvData,
            bloodOxygen: bloodOxygenData,
            respiratoryRate: respiratoryData,
            temperature: temperatureData,
            sleepAnalysis: sleepAnalysisData
        )
    }
    
    private func fetchHeartRateData(from start: Date, to end: Date) async throws -> Double {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        }
        
        return 0.0
    }
    
    private func fetchHRVData(from start: Date, to end: Date) async throws -> Double {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit(from: "ms"))
        }
        
        return 0.0
    }
    
    private func fetchBloodOxygenData(from start: Date, to end: Date) async throws -> Double {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: oxygenType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit.percent()) * 100
        }
        
        return 0.0
    }
    
    private func fetchRespiratoryData(from start: Date, to end: Date) async throws -> Double {
        guard let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: respiratoryType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        }
        
        return 0.0
    }
    
    private func fetchTemperatureData(from start: Date, to end: Date) async throws -> Double {
        guard let temperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: temperatureType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
        }
        
        return 0.0
    }
    
    private func fetchSleepAnalysisData(from start: Date, to end: Date) async throws -> SleepStage? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: sleepType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKCategorySample {
            return mapSleepAnalysisToStage(sample.value)
        }
        
        return nil
    }
    
    private func mapSleepAnalysisToStage(_ value: Int) -> SleepStage {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return .awake
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return .light
        case HKCategoryValueSleepAnalysis.asleep.rawValue:
            return .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return .rem
        default:
            return .light
        }
    }
    
    // MARK: - Data Labeling
    private func labelSleepData(_ rawData: RawSleepData) async -> LabeledSleepData? {
        // Use AI engine to predict sleep stage
        let features = SleepFeatures(
            heartRate: rawData.heartRate,
            heartRateVariability: rawData.hrv,
            movement: 0.0, // Will be calculated from other sensors
            respiratoryRate: rawData.respiratoryRate,
            oxygenSaturation: rawData.bloodOxygen,
            temperature: rawData.temperature,
            timeOfDay: calculateTimeOfNight(),
            previousStage: getPreviousStage(),
            
            heartRateMin: 0.0, heartRateMax: 0.0, heartRateStdDev: 0.0, // These will be populated from time-windowed data
            hrvMin: 0.0, hrvMax: 0.0, hrvStdDev: 0.0,
            bloodOxygenMin: 0.0, bloodOxygenMax: 0.0, bloodOxygenStdDev: 0.0,
            
            previousStageDuration: getPreviousStageDuration(),
            heartRateChangeRate: 0.0, // Will be calculated from time-windowed data
            hrvChangeRate: 0.0,
            bloodOxygenChangeRate: 0.0
        )
        
        let prediction = AISleepAnalysisEngine.shared.predictSleepStage(features)
        
        // Create labeled data point
        return LabeledSleepData(
            timestamp: rawData.timestamp,
            features: features,
            predictedStage: prediction.sleepStage,
            actualStage: rawData.sleepAnalysis,
            confidence: prediction.confidence,
            sleepQuality: prediction.sleepQuality
        )
    }
    
    private func calculateTimeOfNight() -> Double {
        // Calculate time since sleep start (simplified)
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Assume sleep starts around 11 PM
        if hour >= 23 {
            return Double(hour - 23)
        } else if hour < 7 {
            return Double(hour + 1)
        } else {
            return 0.0 // Not sleep time
        }
    }
    
    private func getPreviousStage() -> SleepStage {
        return sleepDataHistory.last?.predictedStage ?? .awake
    }
    
    private func addToHistory(_ data: LabeledSleepData) async {
        await MainActor.run {
            self.sleepDataHistory.append(data)
            
            // Maintain history size
            if self.sleepDataHistory.count > self.maxDataPoints {
                self.sleepDataHistory.removeFirst()
            }
        }
    }
    
    // MARK: - Model Training
    func trainModel() async {
        guard sleepDataHistory.count >= 100 else {
            Logger.error("Insufficient data for training. Need at least 100 data points.", log: Logger.dataManager)
            return
        }
        
        await MainActor.run {
            self.modelTrainingProgress = 0.0
        }
        
        Logger.info("Starting model training with \(sleepDataHistory.count) data points...", log: Logger.dataManager)
        
        do {
            // Prepare training data
            let trainingData = prepareTrainingData()
            
            // Train the model
            let model = try await performModelTraining(data: trainingData)
            
            // Save the trained model
            try await saveTrainedModel(model)
            
            await MainActor.run {
                self.modelTrainingProgress = 1.0
            }
            
            Logger.success("Model training completed successfully!", log: Logger.dataManager)
            
        } catch {
            Logger.error("Model training failed: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    private func prepareTrainingData() -> TrainingData {
        let features = sleepDataHistory.map { $0.features }
        let labels = sleepDataHistory.map { $0.predictedStage.rawValue }
        
        return TrainingData(
            features: features,
            labels: labels,
            timestamps: sleepDataHistory.map { $0.timestamp }
        )
    }
    
    private func performModelTraining(data: TrainingData) async throws -> MLModel {
        Logger.info("Starting real model training with Create ML", log: Logger.dataManager)
        
        await MainActor.run {
            self.modelTrainingProgress = 0.1
        }
        
        // Step 1: Prepare training data in Create ML format
        let trainingData = try await prepareCreateMLData(data)
        await updateTrainingProgress(0.2)
        
        // Step 2: Configure model parameters
        let modelParameters = configureModelParameters()
        await updateTrainingProgress(0.3)
        
        // Step 3: Create and train the model
        let model = try await trainCreateMLModel(trainingData: trainingData, parameters: modelParameters)
        await updateTrainingProgress(0.8)
        
        // Step 4: Validate the model
        let validationResult = try await validateTrainedModel(model, data: data)
        await updateTrainingProgress(0.9)
        
        // Step 5: Save model metadata
        try await saveModelMetadata(validationResult)
        await updateTrainingProgress(1.0)
        
        Logger.success("Model training completed successfully with accuracy: \(validationResult.accuracy)", log: Logger.dataManager)
        
        return model
    }
    
    private func prepareCreateMLData(_ data: TrainingData) async throws -> MLDataTable {
        Logger.info("Preparing Create ML training data", log: Logger.dataManager)
        
        // Convert our training data to Create ML format
        var featureColumns: [String: [Double]] = [:]
        var labelColumn: [String] = []
        
        for (index, features) in data.features.enumerated() {
            // Add normalized features
            featureColumns["heartRate"] = (featureColumns["heartRate"] ?? []) + [features.heartRateNormalized]
            featureColumns["hrv"] = (featureColumns["hrv"] ?? []) + [features.hrvNormalized]
            featureColumns["movement"] = (featureColumns["movement"] ?? []) + [features.movementNormalized]
            featureColumns["bloodOxygen"] = (featureColumns["bloodOxygen"] ?? []) + [features.bloodOxygenNormalized]
            featureColumns["temperature"] = (featureColumns["temperature"] ?? []) + [features.temperatureNormalized]
            featureColumns["breathingRate"] = (featureColumns["breathingRate"] ?? []) + [features.breathingRateNormalized]
            featureColumns["timeOfNight"] = (featureColumns["timeOfNight"] ?? []) + [features.timeOfNightNormalized]
            featureColumns["previousStage"] = (featureColumns["previousStage"] ?? []) + [features.previousStageNormalized]
            
            // Add new features
            featureColumns["heartRateMin"] = (featureColumns["heartRateMin"] ?? []) + [features.heartRateMinNormalized]
            featureColumns["heartRateMax"] = (featureColumns["heartRateMax"] ?? []) + [features.heartRateMaxNormalized]
            featureColumns["heartRateStdDev"] = (featureColumns["heartRateStdDev"] ?? []) + [features.heartRateStdDevNormalized]
            featureColumns["hrvMin"] = (featureColumns["hrvMin"] ?? []) + [features.hrvMinNormalized]
            featureColumns["hrvMax"] = (featureColumns["hrvMax"] ?? []) + [features.hrvMaxNormalized]
            featureColumns["hrvStdDev"] = (featureColumns["hrvStdDev"] ?? []) + [features.hrvStdDevNormalized]
            featureColumns["bloodOxygenMin"] = (featureColumns["bloodOxygenMin"] ?? []) + [features.bloodOxygenMinNormalized]
            featureColumns["bloodOxygenMax"] = (featureColumns["bloodOxygenMax"] ?? []) + [features.bloodOxygenMaxNormalized]
            featureColumns["bloodOxygenStdDev"] = (featureColumns["bloodOxygenStdDev"] ?? []) + [features.bloodOxygenStdDevNormalized]
            featureColumns["previousStageDuration"] = (featureColumns["previousStageDuration"] ?? []) + [features.previousStageDurationNormalized]
            featureColumns["heartRateChangeRate"] = (featureColumns["heartRateChangeRate"] ?? []) + [features.heartRateChangeRateNormalized]
            featureColumns["hrvChangeRate"] = (featureColumns["hrvChangeRate"] ?? []) + [features.hrvChangeRateNormalized]
            featureColumns["bloodOxygenChangeRate"] = (featureColumns["bloodOxygenChangeRate"] ?? []) + [features.bloodOxygenChangeRateNormalized]
            
            // Add label
            let stageName = SleepStage(rawValue: data.labels[index])?.displayName ?? "unknown"
            labelColumn.append(stageName)
        }
        
        // Create MLDataTable
        let dataTable = try MLDataTable(dictionary: featureColumns)
        
        // Add label column
        let labelDataTable = try MLDataTable(column: labelColumn, named: "sleepStage")
        let combinedTable = dataTable.join(with: labelDataTable)
        
        Logger.success("Created training data table with \(combinedTable.rows.count) samples", log: Logger.dataManager)
        return combinedTable
    }
    
    private func configureModelParameters() -> MLClassifier.ModelParameters {
        var parameters = MLClassifier.ModelParameters()
        
        // Configure neural network parameters
        parameters.algorithm = .neuralNetwork
        parameters.validation = .holdOut(fraction: 0.2)
        parameters.maxIterations = 1000
        parameters.regularization = 0.01
        
        // Configure neural network architecture
        parameters.neuralNetworkParameters = MLNeuralNetworkParameters()
        // Proposing a more advanced neural network architecture (e.g., deeper or with more complex layers)
        // For an RNN/LSTM, Create ML's direct support is limited to specific model types.
        // This would typically involve training the model in a framework like TensorFlow/PyTorch
        // and then converting it to Core ML format.
        // For now, we'll simulate a deeper feed-forward network.
        parameters.neuralNetworkParameters?.hiddenLayers = [128, 64, 32] // Example: Deeper network
        parameters.neuralNetworkParameters?.activationFunction = .relu
        
        Logger.info("Configured model parameters for neural network training", log: Logger.dataManager)
        return parameters
    }
    
    private func trainCreateMLModel(trainingData: MLDataTable, parameters: MLClassifier.ModelParameters) async throws -> MLModel {
        Logger.info("Training Create ML classifier", log: Logger.dataManager)
        
        let startTime = Date()
        
        // Train the classifier
        let classifier = try MLClassifier(trainingData: trainingData,
                                        targetColumn: "sleepStage",
                                        parameters: parameters)
        
        let trainingTime = Date().timeIntervalSince(startTime)
        Logger.success("Model training completed in \(String(format: "%.2f", trainingTime)) seconds", log: Logger.dataManager)
        
        return classifier.model
    }
    
    private func validateTrainedModel(_ model: MLModel, data: TrainingData) async throws -> ModelValidationResult {
        Logger.info("Validating trained model", log: Logger.dataManager)
        
        // Create validation data (last 20% of data)
        let validationSize = data.features.count / 5
        let validationFeatures = Array(data.features.suffix(validationSize))
        let validationLabels = Array(data.labels.suffix(validationSize))
        
        var correctPredictions = 0
        var totalPredictions = 0
        
        for (index, features) in validationFeatures.enumerated() {
            do {
                let prediction = try await makePrediction(model: model, features: features)
                let actualStage = SleepStage(rawValue: validationLabels[index]) ?? .light
                
                if prediction.sleepStage == actualStage {
                    correctPredictions += 1
                }
                totalPredictions += 1
            } catch {
                Logger.error("Prediction failed during validation: \(error.localizedDescription)", log: Logger.dataManager)
            }
        }
        
        let accuracy = totalPredictions > 0 ? Double(correctPredictions) / Double(totalPredictions) : 0.0
        
        let validationResult = ModelValidationResult(
            accuracy: accuracy,
            totalSamples: totalPredictions,
            correctPredictions: correctPredictions,
            trainingDataSize: data.features.count,
            validationDataSize: validationFeatures.count
        )
        
        Logger.success("Model validation completed with accuracy: \(String(format: "%.2f", accuracy * 100))%", log: Logger.dataManager)
        return validationResult
    }
    
    private func makePrediction(model: MLModel, features: SleepFeatures) async throws -> SleepStagePrediction {
        // Create ML feature provider
        let featureDictionary: [String: MLFeatureValue] = [
            "heartRate": MLFeatureValue(double: features.heartRateNormalized),
            "hrv": MLFeatureValue(double: features.hrvNormalized),
            "movement": MLFeatureValue(double: features.movementNormalized),
            "bloodOxygen": MLFeatureValue(double: features.bloodOxygenNormalized),
            "temperature": MLFeatureValue(double: features.temperatureNormalized),
            "breathingRate": MLFeatureValue(double: features.breathingRateNormalized),
            "timeOfNight": MLFeatureValue(double: features.timeOfNightNormalized),
            "previousStage": MLFeatureValue(double: features.previousStageNormalized),
            
            // Add new features to the input dictionary
            "heartRateMin": MLFeatureValue(double: features.heartRateMinNormalized),
            "heartRateMax": MLFeatureValue(double: features.heartRateMaxNormalized),
            "heartRateStdDev": MLFeatureValue(double: features.heartRateStdDevNormalized),
            "hrvMin": MLFeatureValue(double: features.hrvMinNormalized),
            "hrvMax": MLFeatureValue(double: features.hrvMaxNormalized),
            "hrvStdDev": MLFeatureValue(double: features.hrvStdDevNormalized),
            "bloodOxygenMin": MLFeatureValue(double: features.bloodOxygenMinNormalized),
            "bloodOxygenMax": MLFeatureValue(double: features.bloodOxygenMaxNormalized),
            "bloodOxygenStdDev": MLFeatureValue(double: features.bloodOxygenStdDevNormalized),
            "previousStageDuration": MLFeatureValue(double: features.previousStageDurationNormalized),
            "heartRateChangeRate": MLFeatureValue(double: features.heartRateChangeRateNormalized),
            "hrvChangeRate": MLFeatureValue(double: features.hrvChangeRateNormalized),
            "bloodOxygenChangeRate": MLFeatureValue(double: features.bloodOxygenChangeRateNormalized)
        ]
        
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: featureDictionary)
        let prediction = try model.prediction(from: inputFeatures)
        
        // Extract prediction result
        if let classLabel = prediction.featureValue(for: "sleepStage")?.stringValue {
            let sleepStage = SleepStage.fromDisplayName(classLabel) ?? .light
            
            // Get confidence scores for each stage
            var stageProbabilities: [SleepStage: Double] = [:]
            if let probabilities = prediction.featureValue(for: "sleepStageProbability")?.dictionaryValue as? [String: Double] {
                for (stageName, probability) in probabilities {
                    if let stage = SleepStage.fromDisplayName(stageName) {
                        stageProbabilities[stage] = probability
                    }
                }
            }
            
            return SleepStagePrediction(
                sleepStage: sleepStage,
                confidence: stageProbabilities[sleepStage] ?? 0.0, // Use actual confidence from model
                sleepQuality: calculateSleepQuality(predictedStage: sleepStage, stageProbabilities: stageProbabilities, features: features),
                stageProbabilities: stageProbabilities
            )
        }
        
        throw DataError.predictionFailed
    }
    
    private func saveTrainedModel(_ model: MLModel) async throws {
        Logger.info("Saving trained model...", log: Logger.dataManager)
        
        let fileManager = FileManager.default
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let modelURL = documentsDirectory.appendingPathComponent("SleepStagePredictor.mlmodel")
        
        do {
            try model.write(to: modelURL)
            Logger.success("Trained model saved to: \(modelURL.lastPathComponent)", log: Logger.dataManager)
        } catch {
            Logger.error("Failed to save trained model: \(error.localizedDescription)", log: Logger.dataManager)
            throw DataError.modelSaveFailed
        }
    }
    
    private func saveModelMetadata(_ validationResult: ModelValidationResult) async throws {
        let metadata = ModelMetadata(
            trainingDate: Date(),
            accuracy: validationResult.accuracy,
            totalSamples: validationResult.totalSamples,
            correctPredictions: validationResult.correctPredictions,
            trainingDataSize: validationResult.trainingDataSize,
            validationDataSize: validationResult.validationDataSize,
            modelVersion: "1.0"
        )
        
        if let data = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(data, forKey: "ModelMetadata")
            Logger.success("Model metadata saved", log: Logger.dataManager)
        }
    }
    
    private func updateTrainingProgress(_ progress: Double) async {
        await MainActor.run {
            self.modelTrainingProgress = progress
        }
    }
    
    private func calculateSleepQuality(predictedStage: SleepStage, stageProbabilities: [SleepStage: Double], features: SleepFeatures) -> Double {
        // Leverage ML model's outputs and other features for a more accurate sleep quality score
        var qualityScore = 0.0
        
        // Factor in predicted stage confidence
        if let confidence = stageProbabilities[predictedStage] {
            qualityScore += confidence * 0.4 // 40% weight from confidence
        }
        
        // Factor in deep sleep and REM probabilities
        qualityScore += (stageProbabilities[.deep] ?? 0.0) * 0.3 // 30% weight from deep sleep probability
        qualityScore += (stageProbabilities[.rem] ?? 0.0) * 0.2 // 20% weight from REM sleep probability
        
        // Factor in biometric features (e.g., heart rate variability, blood oxygen)
        // Higher HRV and stable blood oxygen generally indicate better sleep quality
        qualityScore += (features.heartRateVariabilityNormalized) * 0.05 // 5% weight from HRV
        qualityScore += (features.bloodOxygenNormalized) * 0.05 // 5% weight from blood oxygen
        
        // Normalize to a 0-1 range
        return max(0.0, min(1.0, qualityScore))
    }
    
    // MARK: - Data Export
    func exportTrainingData() -> Data? {
        let exportData = TrainingDataExport(
            dataPoints: sleepDataHistory.count,
            dateRange: (sleepDataHistory.first?.timestamp, sleepDataHistory.last?.timestamp),
            features: sleepDataHistory.map { $0.features },
            predictions: sleepDataHistory.map { $0.predictedStage },
            actualStages: sleepDataHistory.compactMap { $0.actualStage },
            confidences: sleepDataHistory.map { $0.confidence },
            sleepQualities: sleepDataHistory.map { $0.sleepQuality }
        )
        
        do {
            let data = try JSONEncoder().encode(exportData)
            Logger.success("Training data exported successfully", log: Logger.dataManager)
            return data
        } catch {
            Logger.error("Failed to export training data: \(error.localizedDescription)", log: Logger.dataManager)
            return nil
        }
    }
}

// MARK: - SleepFeatures Normalization Extension
extension SleepFeatures {
    var heartRateNormalized: Double { return (heartRate - 40) / 120 } // Assuming HR between 40-160
    var hrvNormalized: Double { return hrv / 100 } // Assuming HRV between 0-100
    var movementNormalized: Double { return movement } // Assuming movement is already 0-1
    var bloodOxygenNormalized: Double { return (oxygenSaturation - 80) / 20 } // Assuming SpO2 between 80-100
    var temperatureNormalized: Double { return (temperature - 35) / 5 } // Assuming temp between 35-40
    var breathingRateNormalized: Double { return (respiratoryRate - 10) / 20 } // Assuming BR between 10-30
    var timeOfNightNormalized: Double { return timeOfDay / 8 } // Assuming sleep session is max 8 hours
    var previousStageNormalized: Double { return Double(previousStage.rawValue) / Double(SleepStage.allCases.count - 1) }
    
    var heartRateMinNormalized: Double { return (heartRateMin - 40) / 120 }
    var heartRateMaxNormalized: Double { return (heartRateMax - 40) / 120 }
    var heartRateStdDevNormalized: Double { return heartRateStdDev / 20 } // Assuming std dev up to 20
    var hrvMinNormalized: Double { return hrvMin / 100 }
    var hrvMaxNormalized: Double { return hrvMax / 100 }
    var hrvStdDevNormalized: Double { return hrvStdDev / 20 }
    var bloodOxygenMinNormalized: Double { return (bloodOxygenMin - 80) / 20 }
    var bloodOxygenMaxNormalized: Double { return (bloodOxygenMax - 80) / 20 }
    var bloodOxygenStdDevNormalized: Double { return bloodOxygenStdDev / 5 }
    
    var previousStageDurationNormalized: Double { return previousStageDuration / (8 * 3600) } // Normalize by max sleep duration
    var heartRateChangeRateNormalized: Double { return (heartRateChangeRate + 10) / 20 } // Assuming change rate between -10 and 10
    var hrvChangeRateNormalized: Double { return (hrvChangeRate + 10) / 20 }
    var bloodOxygenChangeRateNormalized: Double { return (bloodOxygenChangeRate + 5) / 10 }
}
    
    private func calculateHistoricalSleepQuality(_ sample: HKCategorySample) -> Double {
        // Calculate sleep quality based on sleep stage and duration
        let duration = sample.endDate.timeIntervalSince(sample.startDate)
        let stage = mapSleepAnalysisToStage(sample.value)
        
        var quality = 0.5 // Base quality
        
        // Duration factor
        if duration > 6 * 3600 { // More than 6 hours
            quality += 0.2
        } else if duration > 4 * 3600 { // More than 4 hours
            quality += 0.1
        }
        
        // Stage factor
        switch stage {
        case .deep:
            quality += 0.2
        case .rem:
            quality += 0.15
        case .light:
            quality += 0.1
        case .awake:
            quality -= 0.1
        }
        
        return max(0.0, min(1.0, quality))
    }
    
    private func createInitialUserBaseline() async -> UserSleepBaseline? {
        guard !sleepDataHistory.isEmpty else { return nil }
        
        let baseline = UserSleepBaseline()
        
        // Calculate averages from historical data
        let heartRates = sleepDataHistory.compactMap { $0.features.heartRateNormalized * 60 + 40 } // Convert back to BPM
        let hrvs = sleepDataHistory.compactMap { $0.features.hrvNormalized * 80 + 10 } // Convert back to ms
        let qualities = sleepDataHistory.map { $0.sleepQuality }
        
        if !heartRates.isEmpty {
            baseline.averageHeartRate = heartRates.reduce(0, +) / Double(heartRates.count)
        }
        
        if !hrvs.isEmpty {
            baseline.averageHRV = hrvs.reduce(0, +) / Double(hrvs.count)
        }
        
        if !qualities.isEmpty {
            baseline.averageSleepQuality = qualities.reduce(0, +) / Double(qualities.count)
        }
        
        baseline.dataPoints = sleepDataHistory.count
        baseline.personalizationLevel = min(1.0, Double(sleepDataHistory.count) / 100.0)
        
        return baseline
    }
    
    private func calculateTimeOfNight(for date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Calculate time since typical sleep start (11 PM)
        if hour >= 23 {
            return Double(hour - 23)
        } else if hour < 7 {
            return Double(hour + 1)
        } else {
            return 0.0
        }
    }
    
    // MARK: - Data Collection
    func startDataCollection() async {
        await MainActor.run {
            self.isCollectingData = true
        }
        
        Logger.info("Starting real sleep data collection...", log: Logger.dataManager)
        
        do {
            // Request HealthKit permissions if not already granted
            await requestHealthKitPermissions()
            
            // Start collecting sleep data
            await collectSleepData()
            
            await MainActor.run {
                self.isCollectingData = false
            }
            
        } catch {
            Logger.error("Failed to start data collection: \(error.localizedDescription)", log: Logger.dataManager)
            
            await MainActor.run {
                self.isCollectingData = false
            }
        }
    }
    
    private func requestHealthKitPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit is not available on this device", log: Logger.dataManager)
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
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            Logger.success("HealthKit permissions granted", log: Logger.dataManager)
        } catch {
            Logger.error("HealthKit permissions failed: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    func stopDataCollection() async {
        await MainActor.run {
            self.isCollectingData = false
        }
        
        Logger.info("Stopped sleep data collection", log: Logger.dataManager)
    }
    
    private func collectSleepData() async {
        while isCollectingData {
            do {
                let sleepData = try await fetchCurrentSleepData()
                
                if let labeledData = await labelSleepData(sleepData) {
                    await addToHistory(labeledData)
                    
                    await MainActor.run {
                        self.dataPointsCollected += 1
                        self.lastDataCollection = Date()
                    }
                }
                
                // Wait 30 seconds before next collection
                try await Task.sleep(nanoseconds: 30_000_000_000)
                
            } catch {
                Logger.error("Error collecting sleep data: \(error.localizedDescription)", log: Logger.dataManager)
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Wait 1 minute on error
            }
        }
    }
    
    private func fetchCurrentSleepData() async throws -> RawSleepData {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        // Fetch heart rate data
        let heartRateData = try await fetchHeartRateData(from: startOfDay, to: now)
        
        // Fetch HRV data
        let hrvData = try await fetchHRVData(from: startOfDay, to: now)
        
        // Fetch blood oxygen data
        let bloodOxygenData = try await fetchBloodOxygenData(from: startOfDay, to: now)
        
        // Fetch respiratory rate data
        let respiratoryData = try await fetchRespiratoryData(from: startOfDay, to: now)
        
        // Fetch temperature data
        let temperatureData = try await fetchTemperatureData(from: startOfDay, to: now)
        
        // Fetch sleep analysis data
        let sleepAnalysisData = try await fetchSleepAnalysisData(from: startOfDay, to: now)
        
        return RawSleepData(
            timestamp: now,
            heartRate: heartRateData,
            hrv: hrvData,
            bloodOxygen: bloodOxygenData,
            respiratoryRate: respiratoryData,
            temperature: temperatureData,
            sleepAnalysis: sleepAnalysisData
        )
    }
    
    private func fetchHeartRateData(from start: Date, to end: Date) async throws -> Double {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        }
        
        return 0.0
    }
    
    private func fetchHRVData(from start: Date, to end: Date) async throws -> Double {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit(from: "ms"))
        }
        
        return 0.0
    }
    
    private func fetchBloodOxygenData(from start: Date, to end: Date) async throws -> Double {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: oxygenType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit.percent()) * 100
        }
        
        return 0.0
    }
    
    private func fetchRespiratoryData(from start: Date, to end: Date) async throws -> Double {
        guard let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: respiratoryType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        }
        
        return 0.0
    }
    
    private func fetchTemperatureData(from start: Date, to end: Date) async throws -> Double {
        guard let temperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: temperatureType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKQuantitySample {
            return sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
        }
        
        return 0.0
    }
    
    private func fetchSleepAnalysisData(from start: Date, to end: Date) async throws -> SleepStage? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let samples = try await healthStore.samples(of: sleepType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor])
        
        if let sample = samples.first as? HKCategorySample {
            return mapSleepAnalysisToStage(sample.value)
        }
        
        return nil
    }
    
    private func mapSleepAnalysisToStage(_ value: Int) -> SleepStage {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return .awake
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return .light
        case HKCategoryValueSleepAnalysis.asleep.rawValue:
            return .deep
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return .rem
        default:
            return .light
        }
    }
    
    // MARK: - Data Labeling
    private func labelSleepData(_ rawData: RawSleepData) async -> LabeledSleepData? {
        // Use AI engine to predict sleep stage
        let features = SleepFeatures(
            heartRate: rawData.heartRate,
            hrv: rawData.hrv,
            movement: 0.0, // Will be calculated from other sensors
            bloodOxygen: rawData.bloodOxygen,
            temperature: rawData.temperature,
            breathingRate: rawData.respiratoryRate,
            timeOfNight: calculateTimeOfNight(),
            previousStage: getPreviousStage()
        )
        
        let prediction = AISleepAnalysisEngine.shared.predictSleepStage(features)
        
        // Create labeled data point
        return LabeledSleepData(
            timestamp: rawData.timestamp,
            features: features,
            predictedStage: prediction.sleepStage,
            actualStage: rawData.sleepAnalysis,
            confidence: prediction.confidence,
            sleepQuality: prediction.sleepQuality
        )
    }
    
    private func calculateTimeOfNight() -> Double {
        // Calculate time since sleep start (simplified)
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Assume sleep starts around 11 PM
        if hour >= 23 {
            return Double(hour - 23)
        } else if hour < 7 {
            return Double(hour + 1)
        } else {
            return 0.0 // Not sleep time
        }
    }
    
    private func getPreviousStage() -> SleepStage {
        return sleepDataHistory.last?.predictedStage ?? .awake
    }
    
    private func addToHistory(_ data: LabeledSleepData) async {
        await MainActor.run {
            self.sleepDataHistory.append(data)
            
            // Maintain history size
            if self.sleepDataHistory.count > self.maxDataPoints {
                self.sleepDataHistory.removeFirst()
            }
        }
    }
    
    // MARK: - Model Training
    func trainModel() async {
        guard sleepDataHistory.count >= 100 else {
            Logger.error("Insufficient data for training. Need at least 100 data points.", log: Logger.dataManager)
            return
        }
        
        await MainActor.run {
            self.modelTrainingProgress = 0.0
        }
        
        Logger.info("Starting model training with \(sleepDataHistory.count) data points...", log: Logger.dataManager)
        
        do {
            // Prepare training data
            let trainingData = prepareTrainingData()
            
            // Train the model
            let model = try await performModelTraining(data: trainingData)
            
            // Save the trained model
            try await saveTrainedModel(model)
            
            await MainActor.run {
                self.modelTrainingProgress = 1.0
            }
            
            Logger.success("Model training completed successfully!", log: Logger.dataManager)
            
        } catch {
            Logger.error("Model training failed: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    private func prepareTrainingData() -> TrainingData {
        let features = sleepDataHistory.map { $0.features }
        let labels = sleepDataHistory.map { $0.predictedStage.rawValue }
        
        return TrainingData(
            features: features,
            labels: labels,
            timestamps: sleepDataHistory.map { $0.timestamp }
        )
    }
    
    private func performModelTraining(data: TrainingData) async throws -> MLModel {
        Logger.info("Starting real model training with Create ML", log: Logger.dataManager)
        
        await MainActor.run {
            self.modelTrainingProgress = 0.1
        }
        
        // Step 1: Prepare training data in Create ML format
        let trainingData = try await prepareCreateMLData(data)
        await updateTrainingProgress(0.2)
        
        // Step 2: Configure model parameters
        let modelParameters = configureModelParameters()
        await updateTrainingProgress(0.3)
        
        // Step 3: Create and train the model
        let model = try await trainCreateMLModel(trainingData: trainingData, parameters: modelParameters)
        await updateTrainingProgress(0.8)
        
        // Step 4: Validate the model
        let validationResult = try await validateTrainedModel(model, data: data)
        await updateTrainingProgress(0.9)
        
        // Step 5: Save model metadata
        try await saveModelMetadata(validationResult)
        await updateTrainingProgress(1.0)
        
        Logger.success("Model training completed successfully with accuracy: \(validationResult.accuracy)", log: Logger.dataManager)
        
        return model
    }
    
    private func prepareCreateMLData(_ data: TrainingData) async throws -> MLDataTable {
        Logger.info("Preparing Create ML training data", log: Logger.dataManager)
        
        // Convert our training data to Create ML format
        var featureColumns: [String: [Double]] = [:]
        var labelColumn: [String] = []
        
        for (index, features) in data.features.enumerated() {
            // Add normalized features
            featureColumns["heartRate"] = (featureColumns["heartRate"] ?? []) + [features.heartRateNormalized]
            featureColumns["hrv"] = (featureColumns["hrv"] ?? []) + [features.hrvNormalized]
            featureColumns["movement"] = (featureColumns["movement"] ?? []) + [features.movementNormalized]
            featureColumns["bloodOxygen"] = (featureColumns["bloodOxygen"] ?? []) + [features.bloodOxygenNormalized]
            featureColumns["temperature"] = (featureColumns["temperature"] ?? []) + [features.temperatureNormalized]
            featureColumns["breathingRate"] = (featureColumns["breathingRate"] ?? []) + [features.breathingRateNormalized]
            featureColumns["timeOfNight"] = (featureColumns["timeOfNight"] ?? []) + [features.timeOfNightNormalized]
            featureColumns["previousStage"] = (featureColumns["previousStage"] ?? []) + [features.previousStageNormalized]
            
            // Add label
            let stageName = SleepStage(rawValue: data.labels[index])?.displayName ?? "unknown"
            labelColumn.append(stageName)
        }
        
        // Create MLDataTable
        let dataTable = try MLDataTable(dictionary: featureColumns)
        
        // Add label column
        let labelDataTable = try MLDataTable(column: labelColumn, named: "sleepStage")
        let combinedTable = dataTable.join(with: labelDataTable)
        
        Logger.success("Created training data table with \(combinedTable.rows.count) samples", log: Logger.dataManager)
        return combinedTable
    }
    
    private func configureModelParameters() -> MLClassifier.ModelParameters {
        var parameters = MLClassifier.ModelParameters()
        
        // Configure neural network parameters
        parameters.algorithm = .neuralNetwork
        parameters.validation = .holdOut(fraction: 0.2)
        parameters.maxIterations = 1000
        parameters.regularization = 0.01
        
        // Configure neural network architecture
        parameters.neuralNetworkParameters = MLNeuralNetworkParameters()
        parameters.neuralNetworkParameters?.hiddenLayers = [64, 32] // 64 -> 32 -> output
        parameters.neuralNetworkParameters?.activationFunction = .relu
        
        Logger.info("Configured model parameters for neural network training", log: Logger.dataManager)
        return parameters
    }
    
    private func trainCreateMLModel(trainingData: MLDataTable, parameters: MLClassifier.ModelParameters) async throws -> MLModel {
        Logger.info("Training Create ML classifier", log: Logger.dataManager)
        
        let startTime = Date()
        
        // Train the classifier
        let classifier = try MLClassifier(trainingData: trainingData, 
                                        targetColumn: "sleepStage", 
                                        parameters: parameters)
        
        let trainingTime = Date().timeIntervalSince(startTime)
        Logger.success("Model training completed in \(String(format: "%.2f", trainingTime)) seconds", log: Logger.dataManager)
        
        return classifier.model
    }
    
    private func validateTrainedModel(_ model: MLModel, data: TrainingData) async throws -> ModelValidationResult {
        Logger.info("Validating trained model", log: Logger.dataManager)
        
        // Create validation data (last 20% of data)
        let validationSize = data.features.count / 5
        let validationFeatures = Array(data.features.suffix(validationSize))
        let validationLabels = Array(data.labels.suffix(validationSize))
        
        var correctPredictions = 0
        var totalPredictions = 0
        
        for (index, features) in validationFeatures.enumerated() {
            do {
                let prediction = try await makePrediction(model: model, features: features)
                let actualStage = SleepStage(rawValue: validationLabels[index]) ?? .light
                
                if prediction.sleepStage == actualStage {
                    correctPredictions += 1
                }
                totalPredictions += 1
            } catch {
                Logger.error("Prediction failed during validation: \(error.localizedDescription)", log: Logger.dataManager)
            }
        }
        
        let accuracy = totalPredictions > 0 ? Double(correctPredictions) / Double(totalPredictions) : 0.0
        
        let validationResult = ModelValidationResult(
            accuracy: accuracy,
            totalSamples: totalPredictions,
            correctPredictions: correctPredictions,
            trainingDataSize: data.features.count,
            validationDataSize: validationFeatures.count
        )
        
        Logger.success("Model validation completed with accuracy: \(String(format: "%.2f", accuracy * 100))%", log: Logger.dataManager)
        return validationResult
    }
    
    private func makePrediction(model: MLModel, features: SleepFeatures) async throws -> SleepStagePrediction {
        // Create ML feature provider
        let featureDictionary: [String: MLFeatureValue] = [
            "heartRate": MLFeatureValue(double: features.heartRateNormalized),
            "hrv": MLFeatureValue(double: features.hrvNormalized),
            "movement": MLFeatureValue(double: features.movementNormalized),
            "bloodOxygen": MLFeatureValue(double: features.bloodOxygenNormalized),
            "temperature": MLFeatureValue(double: features.temperatureNormalized),
            "breathingRate": MLFeatureValue(double: features.breathingRateNormalized),
            "timeOfNight": MLFeatureValue(double: features.timeOfNightNormalized),
            "previousStage": MLFeatureValue(double: features.previousStageNormalized)
        ]
        
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: featureDictionary)
        let prediction = try model.prediction(from: inputFeatures)
        
        // Extract prediction result
        if let classLabel = prediction.featureValue(for: "sleepStage")?.stringValue {
            let sleepStage = SleepStage.fromDisplayName(classLabel) ?? .light
            return SleepStagePrediction(
                sleepStage: sleepStage,
                confidence: 0.8, // Default confidence for validation
                sleepQuality: calculateSleepQuality(features)
            )
        }
        
        throw DataError.predictionFailed
    }
    
    private func saveModelMetadata(_ validationResult: ModelValidationResult) async throws {
        let metadata = ModelMetadata(
            trainingDate: Date(),
            accuracy: validationResult.accuracy,
            totalSamples: validationResult.totalSamples,
            correctPredictions: validationResult.correctPredictions,
            trainingDataSize: validationResult.trainingDataSize,
            validationDataSize: validationResult.validationDataSize,
            modelVersion: "1.0"
        )
        
        if let data = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(data, forKey: "ModelMetadata")
            Logger.success("Model metadata saved", log: Logger.dataManager)
        }
    }
    
    private func updateTrainingProgress(_ progress: Double) async {
        await MainActor.run {
            self.modelTrainingProgress = progress
        }
    }
    
    private func calculateSleepQuality(_ features: SleepFeatures) -> Double {
        // Calculate sleep quality based on features
        let heartRateScore = max(0, 1 - abs(features.heartRate - 60) / 60)
        let movementScore = max(0, 1 - features.movement)
        let hrvScore = min(1, features.hrv / 100)
        let bloodOxygenScore = max(0, (features.bloodOxygen - 90) / 10)
        
        return (heartRateScore * 0.3 + movementScore * 0.3 + hrvScore * 0.2 + bloodOxygenScore * 0.2)
    }
    
    // MARK: - Data Export
    func exportTrainingData() -> Data? {
        let exportData = TrainingDataExport(
            dataPoints: sleepDataHistory.count,
            dateRange: (sleepDataHistory.first?.timestamp, sleepDataHistory.last?.timestamp),
            features: sleepDataHistory.map { $0.features },
            predictions: sleepDataHistory.map { $0.predictedStage },
            actualStages: sleepDataHistory.compactMap { $0.actualStage },
            confidences: sleepDataHistory.map { $0.confidence },
            sleepQualities: sleepDataHistory.map { $0.sleepQuality }
        )
        
        do {
            let data = try JSONEncoder().encode(exportData)
            Logger.success("Training data exported successfully", log: Logger.dataManager)
            return data
        } catch {
            Logger.error("Failed to export training data: \(error.localizedDescription)", log: Logger.dataManager)
            return nil
        }
    }
}

// MARK: - Data Models
struct RawSleepData {
    let timestamp: Date
    let heartRate: Double
    let hrv: Double
    let bloodOxygen: Double
    let respiratoryRate: Double
    let temperature: Double
    let sleepAnalysis: SleepStage?
}

struct LabeledSleepData {
    let timestamp: Date
    let features: SleepFeatures
    let predictedStage: SleepStage
    let actualStage: SleepStage?
    let confidence: Double
    let sleepQuality: Double
}

struct TrainingData {
    let features: [SleepFeatures]
    let labels: [Int]
    let timestamps: [Date]
}

struct TrainingDataExport: Codable {
    let dataPoints: Int
    let dateRange: (Date?, Date?)
    let features: [SleepFeatures]
    let predictions: [SleepStage]
    let actualStages: [SleepStage]
    let confidences: [Double]
    let sleepQualities: [Double]
}

enum DataError: Error {
    case unsupportedDataType
    case insufficientData
    case trainingNotImplemented
    case modelSaveFailed
    case predictionFailed
}

// MARK: - SleepFeatures Codable
extension SleepFeatures: Codable {}

// MARK: - Supporting Types

struct ModelValidationResult {
    let accuracy: Double
    let totalSamples: Int
    let correctPredictions: Int
    let trainingDataSize: Int
    let validationDataSize: Int
}

struct ModelMetadata: Codable {
    let trainingDate: Date
    let accuracy: Double
    let totalSamples: Int
    let correctPredictions: Int
    let trainingDataSize: Int
    let validationDataSize: Int
    let modelVersion: String
}

// MARK: - SleepStage Extension

extension SleepStage {
    static func fromDisplayName(_ displayName: String) -> SleepStage? {
        switch displayName.lowercased() {
        case "awake": return .awake
        case "light sleep": return .light
        case "deep sleep": return .deep
        case "rem": return .rem
        default: return nil
        }
    }
}

// MARK: - DataError Extension

extension DataError {
    static let predictionFailed = DataError.unsupportedDataType // Reuse existing error
} 