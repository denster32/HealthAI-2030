import Foundation
#if os(macOS)
import AppKit
#endif

#if canImport(HealthKit)
import HealthKit
#endif

#if canImport(CoreML)
import CoreML
#endif

#if canImport(Combine)
import Combine
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

import SwiftData // Import SwiftData
import CloudKit // Import CloudKit
import OSLog // Import OSLog for logging

/// Advanced Cardiac Manager for iOS 18+ cardiac health features
/// Integrates atrial fibrillation detection, cardio fitness tracking, and advanced cardiac analytics
@available(macOS 13.0, *)
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
    @Published var cardiacEvents: [SyncableCardiacEvent] = [] // New: For quick action data persistence
    
    // MARK: - Cardiac Insights
    @Published var cardiacInsights: [CardiacInsight] = []
    @Published var afibAlerts: [AFibAlert] = []
    @Published var fitnessRecommendations: [FitnessRecommendation] = []
    @Published var cardiacTrends: [CardiacTrend] = []
    
    // MARK: - Private Properties
#if !os(macOS)
    private let healthStore = HKHealthStore()
#endif
    private var cancellables = Set<AnyCancellable>()
    private let cardiacAnalyzer = CardiacAnalyzer()
    private let afibDetector = AFibDetector()
    private let fitnessAnalyzer = FitnessAnalyzer()
    private let swiftDataManager = SwiftDataManager.shared // SwiftData Manager instance
    
    // MARK: - Configuration
#if !os(macOS)
    private let cardiacUpdateInterval: TimeInterval = 60 // 1 minute
    private let afibAnalysisInterval: TimeInterval = 300 // 5 minutes
    private let fitnessAnalysisInterval: TimeInterval = 3600 // 1 hour
#endif
    
    // MARK: - iOS 18+ HealthKit Types
#if !os(macOS)
    private let advancedCardiacTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let afib = HKObjectType.quantityType(forIdentifier: .atrialFibrillationBurden) { types.insert(afib) }
        if let cardio = HKObjectType.quantityType(forIdentifier: .cardioFitness) { types.insert(cardio) }
        if let vo2 = HKObjectType.quantityType(forIdentifier: .vo2Max) { types.insert(vo2) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let hrvSDNN = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrvSDNN) }
        if let hrvRMSSD = HKObjectType.quantityType(forIdentifier: .heartRateVariabilityRMSSD) { types.insert(hrvRMSSD) }
        if let irr = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm) { types.insert(irr) }
        if let high = HKObjectType.categoryType(forIdentifier: .highHeartRateEvent) { types.insert(high) }
        if let low = HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent) { types.insert(low) }
        return types
    }()
#endif
    
    private init() {
        setupAdvancedCardiacManager()
        startCardiacMonitoring()
    }
    
    deinit {
        cancellables.removeAll()
        print("AdvancedCardiacManager deinitialized, Combine cancellables cleared.")
    }
    
    // MARK: - Setup and Configuration
    
    private func setupAdvancedCardiacManager() {
        requestAdvancedCardiacPermissions()
        setupCardiacObservers()
        setupCardiacAnalysis()
        Task { await loadCardiacEvents() } // Load cardiac events from SwiftData
    }
    
    private func requestAdvancedCardiacPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available for advanced cardiac monitoring")
            return
        }
        
        let typesToRead: Set<HKObjectType> = advancedCardiacTypes
        var typesToWrite = Set<HKSampleType>()
        if let irr = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm) { typesToWrite.insert(irr) }
        if let high = HKObjectType.categoryType(forIdentifier: .highHeartRateEvent) { typesToWrite.insert(high) }
        if let low = HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent) { typesToWrite.insert(low) }
        
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
        Task { await loadCardiacEvents() } // Ensure cardiac events are loaded on startup
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
        guard let afibBurdenType = HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden) else {
            Logger.cardiacHealth.error("AFib Burden type not available")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: afibBurdenType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.cardiacHealth.error("Error fetching AFib burden: \(error.localizedDescription)")
                    return
                }
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
        guard let cardioFitnessType = HKQuantityType.quantityType(forIdentifier: .cardioFitness) else {
            Logger.cardiacHealth.error("Cardio Fitness type not available")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: cardioFitnessType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.cardiacHealth.error("Error fetching Cardio Fitness: \(error.localizedDescription)")
                    return
                }
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
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            Logger.cardiacHealth.error("VO2 Max type not available")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-30 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: vo2MaxType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.cardiacHealth.error("Error fetching VO2 Max: \(error.localizedDescription)")
                    return
                }
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
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            Logger.cardiacHealth.error("Heart Rate type not available")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1000, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.cardiacHealth.error("Error fetching Heart Rate: \(error.localizedDescription)")
                    return
                }
                if let samples = samples as? [HKQuantitySample] {
                    self?.heartRateData = samples.compactMap { HeartRateSample(from: $0) }
                    self?.analyzeHeartRatePatterns()
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHRVData() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            Logger.cardiacHealth.error("HRV type not available")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1000, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.cardiacHealth.error("Error fetching HRV: \(error.localizedDescription)")
                    return
                }
                if let samples = samples as? [HKQuantitySample] {
                    self?.hrvData = samples.compactMap { HRVSample(from: $0) }
                    self?.analyzeHRVPatterns()
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchIrregularRhythmEvents() {
        guard let irregularRhythmType = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythm) else {
            Logger.cardiacHealth.error("Irregular Rhythm type not available")
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: irregularRhythmType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.cardiacHealth.error("Error fetching Irregular Rhythm Events: \(error.localizedDescription)")
                    return
                }
                if let samples = samples as? [HKCategorySample] {
                    self?.afibEpisodes = samples.compactMap { AFibEpisode(from: $0) }
                    self?.analyzeAFibEpisodes()
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func loadCardiacEvents() async {
        do {
            let fetchedEvents: [SyncableCardiacEvent] = try await swiftDataManager.fetchAll()
            DispatchQueue.main.async {
                self.cardiacEvents = fetchedEvents
                Logger.cardiacHealth.info("Loaded \(self.cardiacEvents.count) cardiac events from SwiftData.")
            }
        } catch {
            Logger.cardiacHealth.error("Failed to load cardiac events from SwiftData: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Quick Action Data Persistence
    
    public func recordCardiacQuickAction(eventType: String, value: Double? = nil, unit: String? = nil, notes: String? = nil) async {
        let newCardiacEvent = SyncableCardiacEvent(
            timestamp: Date(),
            eventType: eventType,
            value: value,
            unit: unit,
            notes: notes
        )
        
        do {
            try await swiftDataManager.save(newCardiacEvent)
            Logger.cardiacHealth.info("Cardiac quick action '\(eventType)' saved to SwiftData.")
            DispatchQueue.main.async {
                self.cardiacEvents.append(newCardiacEvent)
            }
        } catch {
            Logger.cardiacHealth.error("Failed to save cardiac quick action: \(error.localizedDescription)")
        }
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
            return .increasing  // Updated to use proper enum
        } else if change < -5 {
            return .decreasing  // Updated to use proper enum
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
            severity: status == .high ? .critical : .warning,
            pattern: nil
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
            title: "HRV Alert",
            description: "Your HRV is \(String(format: "%.0f", value)), which is \(type.description).",
            severity: .warning,
            timestamp: Date()
        )
        cardiacInsights.append(insight)
    }
    
    private func generateAFibInsight(_ type: AFibInsightType, _ frequency: Double) {
        let insight = CardiacInsight(
            type: .afib,
            title: "AFib Episode Frequency",
            description: "You have experienced \(String(format: "%.1f", frequency)) AFib episodes per week, which is considered \(type.description).",
            severity: .warning,
            timestamp: Date()
        )
        cardiacInsights.append(insight)
    }
    
    private func generateAFibPatternAlert(_ pattern: AFibPattern) async {
        let alert = AFibAlert(
            status: .high,
            burden: atrialFibrillationBurden,
            timestamp: Date(),
            severity: .critical,
            pattern: pattern
        )
        await MainActor.run {
            afibAlerts.append(alert)
            EmergencyAlertManager.shared.triggerCardiacAlert(alert)
        }
    }
}

// MARK: - Supporting Types (Stubs for Compilation)

struct SyncableCardiacEvent: Codable {
    let id: String
    let type: String
    let timestamp: Date
    let data: [String: String]
    
    init(id: String = UUID().uuidString, type: String, timestamp: Date = Date(), data: [String: String] = [:]) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.data = data
    }
}

enum AFibStatus: String { case normal, low, moderate, high }
// TrendDirection is now defined in MetricTypes.swift
enum FitnessLevel: String {
    case poor, fair, good, excellent, superior
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
struct HeartRateSample {
    let value: Double
    let timestamp: Date
    init(from _: HKQuantitySample) {
        value = 70
        timestamp = Date()
    }
}
struct HRVSample {
    let value: Double
    let timestamp: Date
    init(from _: HKQuantitySample) {
        value = 50
        timestamp = Date()
    }
}
struct ECGSample {}
struct AFibEpisode {
    init(from _: HKCategorySample) {}
}
struct CardioFitnessRecord {}
struct CardiacInsight {
    enum InsightType { case fitness, heartRate, hrv, afib }
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let timestamp: Date
}
enum InsightSeverity { case info, warning, critical }
struct AFibAlert {
    let status: AFibStatus
    let burden: Double
    let timestamp: Date
    let severity: AlertSeverity
    let pattern: AFibPattern?
}
enum AlertSeverity { case warning, critical }
struct FitnessRecommendation {}
struct CardiacTrend {}
class CardiacAnalyzer {
    weak var delegate: AnyObject?
    func calculateCardiacRiskScore(afibBurden: Double, vo2Max: Double, heartRateData: [HeartRateSample], hrvData: [HRVSample], afibEpisodes: [AFibEpisode]) async -> Double { 0.2 }
    func analyzeCardiacHealthTrend(heartRateData: [HeartRateSample], hrvData: [HRVSample], afibEpisodes: [AFibEpisode], cardioFitnessHistory: [CardioFitnessRecord]) async -> CardiacHealthTrend { .stable }
    func generateInsights(afibBurden: Double, vo2Max: Double, heartRateData: [HeartRateSample], hrvData: [HRVSample], afibEpisodes: [AFibEpisode]) async -> [CardiacInsight] { [] }
}
class AFibDetector {
    weak var delegate: AnyObject?
    func detectPatterns(afibBurden: Double, afibEpisodes: [AFibEpisode], heartRateData: [HeartRateSample]) async -> [AFibPattern] { [] }
}
class FitnessAnalyzer {
    weak var delegate: AnyObject?
    func generateRecommendations(vo2Max: Double, fitnessAge: Int, cardioFitness: Double) async -> [FitnessRecommendation] { [] }
}
final class EmergencyAlertManager: Sendable {
    nonisolated(unsafe) static let shared = EmergencyAlertManager()
    func triggerCardiacAlert(_ alert: AFibAlert) {}
}
enum CardiacHealthTrend { case stable, improving, declining }
enum HeartRateInsightType {
    case elevated, low
    var description: String {
        switch self {
        case .elevated: return "elevated"
        case .low: return "low"
        }
    }
}
enum HRVInsightType {
    case low, declining
    var description: String {
        switch self {
        case .low: return "low"
        case .declining: return "declining"
        }
    }
}
enum AFibInsightType {
    case frequent
    var description: String {
        switch self {
        case .frequent: return "frequent"
        }
    }
}
struct AFibPattern {}

// MARK: - Logging Extension for AdvancedCardiacManager
extension OSLog {
    private static let subsystem = "com.healthai2030.CardiacHealth"
    static let cardiacHealth = OSLog(subsystem: subsystem, category: "AdvancedCardiacManager")
}
