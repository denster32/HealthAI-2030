import Foundation
import HealthKit
import CoreML
import Combine
import SwiftUI

/// Advanced Cardiac Manager for iOS 18+ cardiac health features
/// Integrates atrial fibrillation detection, cardio fitness tracking, and advanced cardiac analytics
@MainActor
class AdvancedCardiacManager: ObservableObject {
    static let shared = AdvancedCardiacManager()
    
    // MARK: - Published Properties
    @Published var atrialFibrillationBurden: Double = 0.0
    @Published var cardioFitness: Double = 0.0
    @Published var fitnessAge: Int = 0
    @Published var vo2Max: Double = 0.0
    @Published var cardiacRiskScore: Double = 0.0
    @Published var afibStatus: AFibStatus = .normal
    @Published var cardiacHealthTrend: CardiacHealthTrend = .stable
    
    // MARK: - Cardiac Data
    @Published var heartRateData: [HeartRateSample] = []
    @Published var hrvData: [HRVSample] = []
    @Published var ecgData: [ECGSample] = []
    @Published var afibEpisodes: [AFibEpisode] = []
    @Published var cardioFitnessHistory: [CardioFitnessRecord] = []
    
    // MARK: - Cardiac Insights
    @Published var cardiacInsights: [CardiacInsight] = []
    @Published var afibAlerts: [AFibAlert] = []
    @Published var fitnessRecommendations: [FitnessRecommendation] = []
    @Published var cardiacTrends: [CardiacTrend] = []
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    private let cardiacAnalyzer = CardiacAnalyzer()
    private let afibDetector = AFibDetector()
    private let fitnessAnalyzer = FitnessAnalyzer()
    
    // MARK: - Configuration
    private let cardiacUpdateInterval: TimeInterval = 60 // 1 minute
    private let afibAnalysisInterval: TimeInterval = 300 // 5 minutes
    private let fitnessAnalysisInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - iOS 18+ HealthKit Types
    private let advancedCardiacTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .atrialFibrillationBurden)!,
        HKObjectType.quantityType(forIdentifier: .cardioFitness)!,
        HKObjectType.quantityType(forIdentifier: .vo2Max)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilityRMSSD)!,
        HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm)!,
        HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!,
        HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)!
    ]
    
    private init() {
        setupAdvancedCardiacManager()
        startCardiacMonitoring()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupAdvancedCardiacManager() {
        requestAdvancedCardiacPermissions()
        setupCardiacObservers()
        setupCardiacAnalysis()
    }
    
    private func requestAdvancedCardiacPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available for advanced cardiac monitoring")
            return
        }
        
        let typesToRead: Set<HKObjectType> = advancedCardiacTypes
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm)!,
            HKObjectType.categoryType(forIdentifier: .highHeartRateEvent)!,
            HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("Advanced cardiac permissions granted")
                    self?.startCardiacDataCollection()
                } else {
                    print("Advanced cardiac permissions denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func setupCardiacObservers() {
        // Setup observers for advanced cardiac data changes
        setupAFibBurdenObserver()
        setupCardioFitnessObserver()
        setupVO2MaxObserver()
        setupHeartRateObserver()
        setupHRVObserver()
        setupIrregularRhythmObserver()
    }
    
    private func setupCardiacAnalysis() {
        // Initialize cardiac analysis components
        cardiacAnalyzer.delegate = self
        afibDetector.delegate = self
        fitnessAnalyzer.delegate = self
    }
    
    // MARK: - Cardiac Data Collection
    
    private func startCardiacDataCollection() {
        fetchAFibBurden()
        fetchCardioFitness()
        fetchVO2Max()
        fetchHeartRateData()
        fetchHRVData()
        fetchIrregularRhythmEvents()
        
        // Start periodic cardiac analysis
        startPeriodicAnalysis()
    }
    
    private func setupAFibBurdenObserver() {
        guard let afibBurdenType = HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden) else { return }
        
        let query = HKObserverQuery(sampleType: afibBurdenType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchAFibBurden()
            completion()
        }
        
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: afibBurdenType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for AFib burden: \(error)")
            }
        }
    }
    
    private func setupCardioFitnessObserver() {
        guard let cardioFitnessType = HKQuantityType.quantityType(forIdentifier: .cardioFitness) else { return }
        
        let query = HKObserverQuery(sampleType: cardioFitnessType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchCardioFitness()
            completion()
        }
        
        healthStore.execute(query)
    }
    
    private func setupVO2MaxObserver() {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return }
        
        let query = HKObserverQuery(sampleType: vo2MaxType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchVO2Max()
            completion()
        }
        
        healthStore.execute(query)
    }
    
    private func setupHeartRateObserver() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchHeartRateData()
            completion()
        }
        
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for heart rate: \(error)")
            }
        }
    }
    
    private func setupHRVObserver() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchHRVData()
            completion()
        }
        
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for HRV: \(error)")
            }
        }
    }
    
    private func setupIrregularRhythmObserver() {
        guard let irregularRhythmType = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm) else { return }
        
        let query = HKObserverQuery(sampleType: irregularRhythmType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchIrregularRhythmEvents()
            completion()
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Data Fetching
    
    private func fetchAFibBurden() {
        guard let afibBurdenType = HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: afibBurdenType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    let burden = sample.quantity.doubleValue(for: HKUnit.percent())
                    self?.atrialFibrillationBurden = burden
                    self?.analyzeAFibStatus(burden)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchCardioFitness() {
        guard let cardioFitnessType = HKQuantityType.quantityType(forIdentifier: .cardioFitness) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: cardioFitnessType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    let fitness = sample.quantity.doubleValue(for: HKUnit(from: "mL/min/kg"))
                    self?.cardioFitness = fitness
                    self?.calculateFitnessAge(fitness)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchVO2Max() {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-30 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: vo2MaxType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let sample = samples?.first as? HKQuantitySample {
                    let vo2Max = sample.quantity.doubleValue(for: HKUnit(from: "mL/min/kg"))
                    self?.vo2Max = vo2Max
                    self?.analyzeCardioFitness(vo2Max)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRateData() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1000, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKQuantitySample] {
                    self?.heartRateData = samples.compactMap { HeartRateSample(from: $0) }
                    self?.analyzeHeartRatePatterns()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHRVData() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1000, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKQuantitySample] {
                    self?.hrvData = samples.compactMap { HRVSample(from: $0) }
                    self?.analyzeHRVPatterns()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchIrregularRhythmEvents() {
        guard let irregularRhythmType = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: irregularRhythmType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKCategorySample] {
                    self?.afibEpisodes = samples.compactMap { AFibEpisode(from: $0) }
                    self?.analyzeAFibEpisodes()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Cardiac Analysis
    
    private func startPeriodicAnalysis() {
        Timer.publish(every: cardiacUpdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performCardiacAnalysis()
            }
            .store(in: &cancellables)
    }
    
    private func performCardiacAnalysis() {
        Task {
            await analyzeCardiacRiskScore()
            await analyzeCardiacHealthTrend()
            await generateCardiacInsights()
            await generateFitnessRecommendations()
            await detectAFibPatterns()
        }
    }
    
    private func analyzeAFibStatus(_ burden: Double) {
        let newStatus: AFibStatus
        
        switch burden {
        case 0..<1:
            newStatus = .normal
        case 1..<5:
            newStatus = .low
        case 5..<15:
            newStatus = .moderate
        default:
            newStatus = .high
        }
        
        if newStatus != afibStatus {
            afibStatus = newStatus
            generateAFibAlert(newStatus, burden)
        }
    }
    
    private func calculateFitnessAge(_ fitness: Double) {
        // Calculate fitness age based on VO2 Max
        // This is a simplified calculation - in practice, this would be more complex
        let baseAge = 30
        let fitnessAge = baseAge - Int((fitness - 30) / 2)
        self.fitnessAge = max(20, min(80, fitnessAge))
    }
    
    private func analyzeCardioFitness(_ vo2Max: Double) {
        // Analyze cardio fitness level
        let fitnessLevel: FitnessLevel
        
        switch vo2Max {
        case 0..<30:
            fitnessLevel = .poor
        case 30..<40:
            fitnessLevel = .fair
        case 40..<50:
            fitnessLevel = .good
        case 50..<60:
            fitnessLevel = .excellent
        default:
            fitnessLevel = .superior
        }
        
        // Generate fitness insights
        generateFitnessInsight(fitnessLevel, vo2Max)
    }
    
    private func analyzeHeartRatePatterns() {
        guard !heartRateData.isEmpty else { return }
        
        let recentHeartRates = heartRateData.prefix(100)
        let averageHeartRate = recentHeartRates.reduce(0) { $0 + $1.value } / Double(recentHeartRates.count)
        
        // Analyze heart rate variability
        let heartRateVariability = calculateHeartRateVariability(recentHeartRates)
        
        // Generate insights based on patterns
        if averageHeartRate > 100 {
            generateHeartRateInsight(.elevated, averageHeartRate)
        } else if averageHeartRate < 50 {
            generateHeartRateInsight(.low, averageHeartRate)
        }
        
        if heartRateVariability < 20 {
            generateHRVInsight(.low, heartRateVariability)
        }
    }
    
    private func analyzeHRVPatterns() {
        guard !hrvData.isEmpty else { return }
        
        let recentHRV = hrvData.prefix(50)
        let averageHRV = recentHRV.reduce(0) { $0 + $1.value } / Double(recentHRV.count)
        
        // Analyze HRV trends
        let hrvTrend = calculateHRVTrend(recentHRV)
        
        if hrvTrend == .declining {
            generateHRVInsight(.declining, averageHRV)
        }
    }
    
    private func analyzeAFibEpisodes() {
        guard !afibEpisodes.isEmpty else { return }
        
        let recentEpisodes = afibEpisodes.prefix(10)
        let episodeFrequency = Double(recentEpisodes.count) / 7.0 // Episodes per week
        
        if episodeFrequency > 3 {
            generateAFibInsight(.frequent, episodeFrequency)
        }
    }
    
    private func analyzeCardiacRiskScore() async {
        let riskScore = await cardiacAnalyzer.calculateCardiacRiskScore(
            afibBurden: atrialFibrillationBurden,
            vo2Max: vo2Max,
            heartRateData: heartRateData,
            hrvData: hrvData,
            afibEpisodes: afibEpisodes
        )
        
        await MainActor.run {
            cardiacRiskScore = riskScore
        }
    }
    
    private func analyzeCardiacHealthTrend() async {
        let trend = await cardiacAnalyzer.analyzeCardiacHealthTrend(
            heartRateData: heartRateData,
            hrvData: hrvData,
            afibEpisodes: afibEpisodes,
            cardioFitnessHistory: cardioFitnessHistory
        )
        
        await MainActor.run {
            cardiacHealthTrend = trend
        }
    }
    
    private func generateCardiacInsights() async {
        let insights = await cardiacAnalyzer.generateInsights(
            afibBurden: atrialFibrillationBurden,
            vo2Max: vo2Max,
            heartRateData: heartRateData,
            hrvData: hrvData,
            afibEpisodes: afibEpisodes
        )
        
        await MainActor.run {
            cardiacInsights = insights
        }
    }
    
    private func generateFitnessRecommendations() async {
        let recommendations = await fitnessAnalyzer.generateRecommendations(
            vo2Max: vo2Max,
            fitnessAge: fitnessAge,
            cardioFitness: cardioFitness
        )
        
        await MainActor.run {
            fitnessRecommendations = recommendations
        }
    }
    
    private func detectAFibPatterns() async {
        let patterns = await afibDetector.detectPatterns(
            afibBurden: atrialFibrillationBurden,
            afibEpisodes: afibEpisodes,
            heartRateData: heartRateData
        )
        
        if let pattern = patterns.first {
            await generateAFibPatternAlert(pattern)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateHeartRateVariability(_ heartRates: ArraySlice<HeartRateSample>) -> Double {
        guard heartRates.count > 1 else { return 0 }
        
        let intervals = zip(heartRates, heartRates.dropFirst()).map { first, second in
            second.timestamp.timeIntervalSince(first.timestamp)
        }
        
        let meanInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.reduce(0) { sum, interval in
            sum + pow(interval - meanInterval, 2)
        } / Double(intervals.count)
        
        return sqrt(variance)
    }
    
    private func calculateHRVTrend(_ hrvData: ArraySlice<HRVSample>) -> TrendDirection {
        guard hrvData.count > 5 else { return .stable }
        
        let firstHalf = hrvData.prefix(hrvData.count / 2)
        let secondHalf = hrvData.suffix(hrvData.count / 2)
        
        let firstAverage = firstHalf.reduce(0) { $0 + $1.value } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0) { $0 + $1.value } / Double(secondHalf.count)
        
        let change = secondAverage - firstAverage
        
        if change > 5 {
            return .improving
        } else if change < -5 {
            return .declining
        } else {
            return .stable
        }
    }
    
    // MARK: - Alert Generation
    
    private func generateAFibAlert(_ status: AFibStatus, _ burden: Double) {
        let alert = AFibAlert(
            status: status,
            burden: burden,
            timestamp: Date(),
            severity: status == .high ? .critical : .warning
        )
        
        afibAlerts.append(alert)
        
        // Trigger emergency alert if critical
        if status == .high {
            EmergencyAlertManager.shared.triggerCardiacAlert(alert)
        }
    }
    
    private func generateFitnessInsight(_ level: FitnessLevel, _ vo2Max: Double) {
        let insight = CardiacInsight(
            type: .fitness,
            title: "Cardio Fitness Level",
            description: "Your VO2 Max of \(String(format: "%.1f", vo2Max)) indicates \(level.displayName) fitness.",
            severity: level == .poor ? .warning : .info,
            timestamp: Date()
        )
        
        cardiacInsights.append(insight)
    }
    
    private func generateHeartRateInsight(_ type: HeartRateInsightType, _ value: Double) {
        let insight = CardiacInsight(
            type: .heartRate,
            title: "Heart Rate Alert",
            description: "Your average heart rate is \(String(format: "%.0f", value)) BPM, which is \(type.description).",
            severity: .warning,
            timestamp: Date()
        )
        
        cardiacInsights.append(insight)
    }
    
    private func generateHRVInsight(_ type: HRVInsightType, _ value: Double) {
        let insight = CardiacInsight(
            type: .hrv,
            title: "Heart Rate Variability",
            description: "Your HRV of \(String(format: "%.1f", value)) ms indicates \(type.description).",
            severity: type == .low ? .warning : .info,
            timestamp: Date()
        )
        
        cardiacInsights.append(insight)
    }
    
    private func generateAFibInsight(_ type: AFibInsightType, _ frequency: Double) {
        let insight = CardiacInsight(
            type: .afib,
            title: "Atrial Fibrillation Pattern",
            description: "You're experiencing \(String(format: "%.1f", frequency)) AFib episodes per week.",
            severity: .warning,
            timestamp: Date()
        )
        
        cardiacInsights.append(insight)
    }
    
    private func generateAFibPatternAlert(_ pattern: AFibPattern) async {
        let alert = AFibAlert(
            status: .moderate,
            burden: atrialFibrillationBurden,
            timestamp: Date(),
            severity: .warning,
            pattern: pattern
        )
        
        await MainActor.run {
            afibAlerts.append(alert)
        }
    }
}

// MARK: - Supporting Types

struct HeartRateSample {
    let timestamp: Date
    let value: Double
    let unit: String
    
    init?(from sample: HKQuantitySample) {
        self.timestamp = sample.startDate
        self.value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
        self.unit = "BPM"
    }
}

struct HRVSample {
    let timestamp: Date
    let value: Double
    let unit: String
    
    init?(from sample: HKQuantitySample) {
        self.timestamp = sample.startDate
        self.value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)))
        self.unit = "ms"
    }
}

struct ECGSample {
    let timestamp: Date
    let data: [Double]
    let classification: ECGClassification
    
    enum ECGClassification {
        case normal
        case atrialFibrillation
        case inconclusive
        case poorSignal
    }
}

struct AFibEpisode {
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let burden: Double
    
    init?(from sample: HKCategorySample) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.duration = sample.endDate.timeIntervalSince(sample.startDate)
        self.burden = sample.metadata?["burden"] as? Double ?? 0.0
    }
}

struct CardioFitnessRecord {
    let timestamp: Date
    let vo2Max: Double
    let fitnessAge: Int
    let confidence: Double
}

enum AFibStatus {
    case normal
    case low
    case moderate
    case high
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        }
    }
}

enum CardiacHealthTrend {
    case improving
    case stable
    case declining
    case critical
    
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .critical: return "Critical"
        }
    }
}

enum FitnessLevel {
    case poor
    case fair
    case good
    case excellent
    case superior
    
    var displayName: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        case .superior: return "Superior"
        }
    }
}

enum TrendDirection {
    case improving
    case stable
    case declining
}

enum HeartRateInsightType {
    case elevated
    case low
    case normal
    
    var description: String {
        switch self {
        case .elevated: return "elevated"
        case .low: return "low"
        case .normal: return "normal"
        }
    }
}

enum HRVInsightType {
    case low
    case normal
    case declining
    
    var description: String {
        switch self {
        case .low: return "low variability"
        case .normal: return "normal variability"
        case .declining: return "declining variability"
        }
    }
}

enum AFibInsightType {
    case frequent
    case occasional
    case rare
    
    var description: String {
        switch self {
        case .frequent: return "frequent episodes"
        case .occasional: return "occasional episodes"
        case .rare: return "rare episodes"
        }
    }
}

struct CardiacInsight {
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let timestamp: Date
    
    enum InsightType {
        case afib
        case fitness
        case heartRate
        case hrv
        case general
    }
    
    enum InsightSeverity {
        case info
        case warning
        case critical
    }
}

struct AFibAlert {
    let status: AFibStatus
    let burden: Double
    let timestamp: Date
    let severity: AlertSeverity
    let pattern: AFibPattern?
    
    enum AlertSeverity {
        case info
        case warning
        case critical
    }
}

struct AFibPattern {
    let type: PatternType
    let frequency: Double
    let duration: TimeInterval
    let riskLevel: RiskLevel
    
    enum PatternType {
        case paroxysmal
        case persistent
        case permanent
    }
    
    enum RiskLevel {
        case low
        case moderate
        case high
    }
}

struct FitnessRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let duration: TimeInterval
    let intensity: Intensity
    let priority: Priority
    
    enum RecommendationType {
        case cardio
        case strength
        case flexibility
        case recovery
    }
    
    enum Intensity {
        case low
        case moderate
        case high
    }
    
    enum Priority {
        case low
        case medium
        case high
    }
}

struct CardiacTrend {
    let metric: String
    let value: Double
    let trend: TrendDirection
    let timestamp: Date
}

// MARK: - Analysis Components (Placeholder Classes)

class CardiacAnalyzer {
    weak var delegate: AdvancedCardiacManager?
    
    func calculateCardiacRiskScore(afibBurden: Double, vo2Max: Double, heartRateData: [HeartRateSample], hrvData: [HRVSample], afibEpisodes: [AFibEpisode]) async -> Double {
        // Calculate comprehensive cardiac risk score
        let afibRisk = calculateAFibRisk(afibBurden, afibEpisodes)
        let fitnessRisk = calculateFitnessRisk(vo2Max)
        let heartRateRisk = calculateHeartRateRisk(heartRateData)
        let hrvRisk = calculateHRVRisk(hrvData)
        
        return (afibRisk + fitnessRisk + heartRateRisk + hrvRisk) / 4.0
    }
    
    func analyzeCardiacHealthTrend(heartRateData: [HeartRateSample], hrvData: [HRVSample], afibEpisodes: [AFibEpisode], cardioFitnessHistory: [CardioFitnessRecord]) async -> CardiacHealthTrend {
        // Analyze overall cardiac health trend
        return .stable // Placeholder
    }
    
    func generateInsights(afibBurden: Double, vo2Max: Double, heartRateData: [HeartRateSample], hrvData: [HRVSample], afibEpisodes: [AFibEpisode]) async -> [CardiacInsight] {
        // Generate cardiac health insights
        return [] // Placeholder
    }
    
    private func calculateAFibRisk(_ burden: Double, _ episodes: [AFibEpisode]) -> Double {
        let burdenRisk = min(burden / 10.0, 1.0)
        let episodeRisk = min(Double(episodes.count) / 10.0, 1.0)
        return (burdenRisk + episodeRisk) / 2.0
    }
    
    private func calculateFitnessRisk(_ vo2Max: Double) -> Double {
        return max(0, 1.0 - (vo2Max / 60.0))
    }
    
    private func calculateHeartRateRisk(_ heartRateData: [HeartRateSample]) -> Double {
        guard !heartRateData.isEmpty else { return 0.5 }
        let averageHR = heartRateData.reduce(0) { $0 + $1.value } / Double(heartRateData.count)
        return averageHR > 100 ? 0.8 : (averageHR < 50 ? 0.7 : 0.2)
    }
    
    private func calculateHRVRisk(_ hrvData: [HRVSample]) -> Double {
        guard !hrvData.isEmpty else { return 0.5 }
        let averageHRV = hrvData.reduce(0) { $0 + $1.value } / Double(hrvData.count)
        return averageHRV < 20 ? 0.8 : 0.2
    }
}

class AFibDetector {
    weak var delegate: AdvancedCardiacManager?
    
    func detectPatterns(afibBurden: Double, afibEpisodes: [AFibEpisode], heartRateData: [HeartRateSample]) async -> [AFibPattern] {
        // Detect AFib patterns and return analysis
        return [] // Placeholder
    }
}

class FitnessAnalyzer {
    weak var delegate: AdvancedCardiacManager?
    
    func generateRecommendations(vo2Max: Double, fitnessAge: Int, cardioFitness: Double) async -> [FitnessRecommendation] {
        // Generate personalized fitness recommendations
        return [] // Placeholder
    }
} 