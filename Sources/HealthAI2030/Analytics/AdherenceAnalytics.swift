// MARK: - AdherenceAnalytics.swift
// HealthAI 2030 - Agent 6 (Analytics) Deliverable
// Advanced medication and treatment adherence analytics system

import Foundation
import Combine
import CryptoKit

/// Comprehensive adherence analytics engine for medication and treatment compliance monitoring
public final class AdherenceAnalytics: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var currentAdherenceScore: Double = 0.0
    @Published public var adherenceTrend: AdherenceTrend = .stable
    @Published public var riskLevel: AdherenceRiskLevel = .low
    @Published public var interventionRecommendations: [AdherenceIntervention] = []
    
    // MARK: - Private Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let predictionModel: MLPredictiveModels
    private let patternRecognition: BehavioralPatternRecognition
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let adherenceThresholds = AdherenceThresholds()
    private let analysisConfig = AdherenceAnalysisConfiguration()
    
    // MARK: - Initialization
    public init(analyticsEngine: AdvancedAnalyticsEngine,
                predictionModel: MLPredictiveModels,
                patternRecognition: BehavioralPatternRecognition) {
        self.analyticsEngine = analyticsEngine
        self.predictionModel = predictionModel
        self.patternRecognition = patternRecognition
        setupRealTimeAnalytics()
    }
    
    // MARK: - Public Methods
    
    /// Analyzes medication adherence patterns for a specific patient
    public func analyzeMedicationAdherence(
        patientId: String,
        timeframe: AnalysisTimeframe = .last30Days
    ) async throws -> MedicationAdherenceAnalysis {
        let medicationData = try await fetchMedicationData(patientId: patientId, timeframe: timeframe)
        let adherenceMetrics = calculateAdherenceMetrics(from: medicationData)
        let patterns = try await identifyAdherencePatterns(from: medicationData)
        let riskFactors = assessAdherenceRiskFactors(patterns: patterns, metrics: adherenceMetrics)
        
        return MedicationAdherenceAnalysis(
            patientId: patientId,
            timeframe: timeframe,
            overallScore: adherenceMetrics.overallScore,
            medicationSpecificScores: adherenceMetrics.medicationScores,
            patterns: patterns,
            riskFactors: riskFactors,
            recommendations: generateAdherenceRecommendations(
                metrics: adherenceMetrics,
                patterns: patterns,
                riskFactors: riskFactors
            )
        )
    }
    
    /// Analyzes treatment plan adherence
    public func analyzeTreatmentAdherence(
        patientId: String,
        treatmentPlanId: String,
        timeframe: AnalysisTimeframe = .last30Days
    ) async throws -> TreatmentAdherenceAnalysis {
        let treatmentData = try await fetchTreatmentData(
            patientId: patientId,
            treatmentPlanId: treatmentPlanId,
            timeframe: timeframe
        )
        
        let adherenceComponents = analyzeTreatmentComponents(treatmentData)
        let complianceMetrics = calculateTreatmentCompliance(adherenceComponents)
        let adherenceBarriers = identifyAdherenceBarriers(treatmentData)
        
        return TreatmentAdherenceAnalysis(
            patientId: patientId,
            treatmentPlanId: treatmentPlanId,
            timeframe: timeframe,
            overallCompliance: complianceMetrics.overallCompliance,
            componentCompliance: adherenceComponents,
            barriers: adherenceBarriers,
            recommendations: generateTreatmentRecommendations(
                compliance: complianceMetrics,
                barriers: adherenceBarriers
            )
        )
    }
    
    /// Provides real-time adherence monitoring
    public func startRealTimeAdherenceMonitoring(patientId: String) -> AnyPublisher<AdherenceUpdate, Never> {
        return Timer.publish(every: analysisConfig.monitoringInterval, on: .main, in: .common)
            .autoconnect()
            .asyncMap { [weak self] _ in
                guard let self = self else { return nil }
                return try? await self.generateRealTimeAdherenceUpdate(patientId: patientId)
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    /// Predicts adherence likelihood
    public func predictAdherenceLikelihood(
        patientId: String,
        medication: MedicationInfo,
        timeframe: PredictionTimeframe = .next7Days
    ) async throws -> AdherencePrediction {
        let historicalData = try await fetchHistoricalAdherenceData(patientId: patientId)
        let patientProfile = try await fetchPatientProfile(patientId: patientId)
        let medicationComplexity = assessMedicationComplexity(medication)
        
        let features = extractPredictionFeatures(
            historicalData: historicalData,
            patientProfile: patientProfile,
            medicationComplexity: medicationComplexity
        )
        
        let prediction = try await predictionModel.predictAdherence(features: features, timeframe: timeframe)
        
        return AdherencePrediction(
            patientId: patientId,
            medication: medication,
            timeframe: timeframe,
            likelihood: prediction.likelihood,
            confidence: prediction.confidence,
            riskFactors: prediction.riskFactors,
            interventionRecommendations: generatePredictiveInterventions(prediction: prediction)
        )
    }
    
    /// Analyzes population-level adherence trends
    public func analyzePopulationAdherence(
        cohort: PatientCohort,
        timeframe: AnalysisTimeframe = .last90Days
    ) async throws -> PopulationAdherenceAnalysis {
        let cohortData = try await fetchCohortAdherenceData(cohort: cohort, timeframe: timeframe)
        let adherenceDistribution = calculateAdherenceDistribution(cohortData)
        let demographicPatterns = analyzeDemographicAdherencePatterns(cohortData)
        let medicationPatterns = analyzeMedicationAdherencePatterns(cohortData)
        
        return PopulationAdherenceAnalysis(
            cohort: cohort,
            timeframe: timeframe,
            overallAdherenceRate: adherenceDistribution.mean,
            adherenceDistribution: adherenceDistribution,
            demographicPatterns: demographicPatterns,
            medicationPatterns: medicationPatterns,
            insights: generatePopulationInsights(
                distribution: adherenceDistribution,
                demographic: demographicPatterns,
                medication: medicationPatterns
            )
        )
    }
    
    // MARK: - Private Methods
    
    private func setupRealTimeAnalytics() {
        // Configure real-time adherence monitoring
        analyticsEngine.adherenceUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.processAdherenceUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func fetchMedicationData(
        patientId: String,
        timeframe: AnalysisTimeframe
    ) async throws -> [MedicationRecord] {
        // Implementation for fetching medication data
        // This would integrate with the data pipeline
        return []
    }
    
    private func calculateAdherenceMetrics(from data: [MedicationRecord]) -> AdherenceMetrics {
        let totalDoses = data.reduce(0) { $0 + $1.prescribedDoses }
        let takenDoses = data.reduce(0) { $0 + $1.takenDoses }
        let overallScore = totalDoses > 0 ? Double(takenDoses) / Double(totalDoses) : 0.0
        
        let medicationScores = Dictionary(grouping: data, by: { $0.medicationId })
            .mapValues { records in
                let prescribed = records.reduce(0) { $0 + $1.prescribedDoses }
                let taken = records.reduce(0) { $0 + $1.takenDoses }
                return prescribed > 0 ? Double(taken) / Double(prescribed) : 0.0
            }
        
        return AdherenceMetrics(
            overallScore: overallScore,
            medicationScores: medicationScores,
            consistency: calculateConsistencyScore(data),
            timeliness: calculateTimelinessScore(data)
        )
    }
    
    private func identifyAdherencePatterns(from data: [MedicationRecord]) async throws -> [AdherencePattern] {
        return try await patternRecognition.identifyMedicationPatterns(data)
    }
    
    private func assessAdherenceRiskFactors(
        patterns: [AdherencePattern],
        metrics: AdherenceMetrics
    ) -> [AdherenceRiskFactor] {
        var riskFactors: [AdherenceRiskFactor] = []
        
        // Low overall adherence
        if metrics.overallScore < adherenceThresholds.lowAdherenceThreshold {
            riskFactors.append(.lowOverallAdherence(score: metrics.overallScore))
        }
        
        // Inconsistent timing
        if metrics.timeliness < adherenceThresholds.timelinessThreshold {
            riskFactors.append(.inconsistentTiming(score: metrics.timeliness))
        }
        
        // Pattern-based risk factors
        for pattern in patterns {
            switch pattern.type {
            case .missedDoses:
                riskFactors.append(.frequentMissedDoses(frequency: pattern.frequency))
            case .delayedDoses:
                riskFactors.append(.consistentDelays(avgDelay: pattern.averageDelay))
            case .weekendNoncompliance:
                riskFactors.append(.weekendNoncompliance)
            case .holidayNoncompliance:
                riskFactors.append(.holidayNoncompliance)
            }
        }
        
        return riskFactors
    }
    
    private func generateAdherenceRecommendations(
        metrics: AdherenceMetrics,
        patterns: [AdherencePattern],
        riskFactors: [AdherenceRiskFactor]
    ) -> [AdherenceIntervention] {
        var recommendations: [AdherenceIntervention] = []
        
        for riskFactor in riskFactors {
            switch riskFactor {
            case .lowOverallAdherence:
                recommendations.append(.medicationReview)
                recommendations.append(.simplifyRegimen)
                recommendations.append(.adherenceEducation)
                
            case .inconsistentTiming:
                recommendations.append(.medicationReminders)
                recommendations.append(.pillOrganizer)
                
            case .frequentMissedDoses:
                recommendations.append(.smartPillBottle)
                recommendations.append(.caregiverSupport)
                
            case .weekendNoncompliance, .holidayNoncompliance:
                recommendations.append(.routineStrengthening)
                recommendations.append(.travelPillKit)
                
            default:
                recommendations.append(.behavioralSupport)
            }
        }
        
        return Array(Set(recommendations)) // Remove duplicates
    }
    
    private func calculateConsistencyScore(_ data: [MedicationRecord]) -> Double {
        // Calculate adherence consistency over time
        guard !data.isEmpty else { return 0.0 }
        
        let dailyAdherence = Dictionary(grouping: data, by: { Calendar.current.startOfDay(for: $0.scheduledTime) })
            .mapValues { records in
                let prescribed = records.reduce(0) { $0 + $1.prescribedDoses }
                let taken = records.reduce(0) { $0 + $1.takenDoses }
                return prescribed > 0 ? Double(taken) / Double(prescribed) : 0.0
            }
        
        let values = Array(dailyAdherence.values)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = higher consistency
        return max(0.0, 1.0 - standardDeviation)
    }
    
    private func calculateTimelinessScore(_ data: [MedicationRecord]) -> Double {
        let timelinesScores = data.compactMap { record -> Double? in
            guard let actualTime = record.actualTime else { return nil }
            let timeDifference = abs(actualTime.timeIntervalSince(record.scheduledTime))
            let maxAcceptableDelay: TimeInterval = 3600 // 1 hour
            return max(0.0, 1.0 - (timeDifference / maxAcceptableDelay))
        }
        
        return timelinesScores.isEmpty ? 0.0 : timelinesScores.reduce(0, +) / Double(timelinesScores.count)
    }
    
    private func processAdherenceUpdate(_ update: AdherenceUpdate) {
        DispatchQueue.main.async {
            self.currentAdherenceScore = update.adherenceScore
            self.adherenceTrend = update.trend
            self.riskLevel = update.riskLevel
            
            if !update.interventionRecommendations.isEmpty {
                self.interventionRecommendations = update.interventionRecommendations
            }
        }
    }
    
    private func generateRealTimeAdherenceUpdate(patientId: String) async throws -> AdherenceUpdate {
        let recentData = try await fetchRecentMedicationData(patientId: patientId)
        let currentScore = calculateCurrentAdherenceScore(recentData)
        let trend = calculateAdherenceTrend(recentData)
        let risk = assessCurrentRiskLevel(score: currentScore, trend: trend)
        
        return AdherenceUpdate(
            patientId: patientId,
            timestamp: Date(),
            adherenceScore: currentScore,
            trend: trend,
            riskLevel: risk,
            interventionRecommendations: risk.isHigh ? generateUrgentInterventions() : []
        )
    }
    
    private func fetchRecentMedicationData(patientId: String) async throws -> [MedicationRecord] {
        // Implementation for fetching recent medication data
        return []
    }
    
    private func calculateCurrentAdherenceScore(_ data: [MedicationRecord]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        let totalPrescribed = data.reduce(0) { $0 + $1.prescribedDoses }
        let totalTaken = data.reduce(0) { $0 + $1.takenDoses }
        
        return totalPrescribed > 0 ? Double(totalTaken) / Double(totalPrescribed) : 0.0
    }
    
    private func calculateAdherenceTrend(_ data: [MedicationRecord]) -> AdherenceTrend {
        guard data.count >= 2 else { return .stable }
        
        let sortedData = data.sorted { $0.scheduledTime < $1.scheduledTime }
        let firstHalf = Array(sortedData.prefix(sortedData.count / 2))
        let secondHalf = Array(sortedData.suffix(sortedData.count / 2))
        
        let firstScore = calculateCurrentAdherenceScore(firstHalf)
        let secondScore = calculateCurrentAdherenceScore(secondHalf)
        
        let difference = secondScore - firstScore
        
        if difference > 0.05 {
            return .improving
        } else if difference < -0.05 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func assessCurrentRiskLevel(score: Double, trend: AdherenceTrend) -> AdherenceRiskLevel {
        if score < 0.6 || trend == .declining {
            return .high
        } else if score < 0.8 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func generateUrgentInterventions() -> [AdherenceIntervention] {
        return [
            .immediateContactPatient,
            .medicationReview,
            .caregiverNotification,
            .clinicianAlert
        ]
    }
}

// MARK: - Supporting Types

public enum AnalysisTimeframe {
    case last7Days
    case last30Days
    case last90Days
    case custom(start: Date, end: Date)
}

public enum PredictionTimeframe {
    case next7Days
    case next30Days
    case next90Days
}

public enum AdherenceTrend {
    case improving
    case stable
    case declining
}

public enum AdherenceRiskLevel {
    case low
    case medium
    case high
    
    var isHigh: Bool {
        return self == .high
    }
}

public enum AdherenceRiskFactor {
    case lowOverallAdherence(score: Double)
    case inconsistentTiming(score: Double)
    case frequentMissedDoses(frequency: Double)
    case consistentDelays(avgDelay: TimeInterval)
    case weekendNoncompliance
    case holidayNoncompliance
    case polypharmacyComplexity
    case sideEffectReports
}

public enum AdherenceIntervention {
    case medicationReview
    case simplifyRegimen
    case adherenceEducation
    case medicationReminders
    case pillOrganizer
    case smartPillBottle
    case caregiverSupport
    case routineStrengthening
    case travelPillKit
    case behavioralSupport
    case immediateContactPatient
    case caregiverNotification
    case clinicianAlert
}

public struct AdherenceThresholds {
    let lowAdherenceThreshold: Double = 0.8
    let timelinessThreshold: Double = 0.7
    let consistencyThreshold: Double = 0.8
}

public struct AdherenceAnalysisConfiguration {
    let monitoringInterval: TimeInterval = 300 // 5 minutes
    let patternDetectionWindow: TimeInterval = 86400 * 7 // 7 days
    let predictionAccuracyThreshold: Double = 0.85
}

public struct MedicationRecord {
    let id: String
    let patientId: String
    let medicationId: String
    let medicationName: String
    let scheduledTime: Date
    let actualTime: Date?
    let prescribedDoses: Int
    let takenDoses: Int
    let missedReason: String?
}

public struct AdherenceMetrics {
    let overallScore: Double
    let medicationScores: [String: Double]
    let consistency: Double
    let timeliness: Double
}

public struct AdherencePattern {
    let type: PatternType
    let frequency: Double
    let averageDelay: TimeInterval
    let confidence: Double
    
    enum PatternType {
        case missedDoses
        case delayedDoses
        case weekendNoncompliance
        case holidayNoncompliance
    }
}

public struct MedicationAdherenceAnalysis {
    let patientId: String
    let timeframe: AnalysisTimeframe
    let overallScore: Double
    let medicationSpecificScores: [String: Double]
    let patterns: [AdherencePattern]
    let riskFactors: [AdherenceRiskFactor]
    let recommendations: [AdherenceIntervention]
}

public struct TreatmentAdherenceAnalysis {
    let patientId: String
    let treatmentPlanId: String
    let timeframe: AnalysisTimeframe
    let overallCompliance: Double
    let componentCompliance: [TreatmentComponent]
    let barriers: [AdherenceBarrier]
    let recommendations: [AdherenceIntervention]
}

public struct TreatmentComponent {
    let type: ComponentType
    let compliance: Double
    let frequency: String
    
    enum ComponentType {
        case medication
        case exercise
        case dietaryRestriction
        case appointment
        case monitoring
    }
}

public struct AdherenceBarrier {
    let type: BarrierType
    let severity: BarrierSeverity
    let description: String
    
    enum BarrierType {
        case financial
        case cognitive
        case physical
        case social
        case behavioral
        case systematic
    }
    
    enum BarrierSeverity {
        case low
        case medium
        case high
    }
}

public struct AdherenceUpdate {
    let patientId: String
    let timestamp: Date
    let adherenceScore: Double
    let trend: AdherenceTrend
    let riskLevel: AdherenceRiskLevel
    let interventionRecommendations: [AdherenceIntervention]
}

public struct AdherencePrediction {
    let patientId: String
    let medication: MedicationInfo
    let timeframe: PredictionTimeframe
    let likelihood: Double
    let confidence: Double
    let riskFactors: [AdherenceRiskFactor]
    let interventionRecommendations: [AdherenceIntervention]
}

public struct MedicationInfo {
    let id: String
    let name: String
    let dosage: String
    let frequency: String
    let complexity: MedicationComplexity
}

public struct MedicationComplexity {
    let dosesPerDay: Int
    let requiresSpecialTiming: Bool
    let requiresFoodRestrictions: Bool
    let sideEffectProfile: String
    let interactionRisk: InteractionRisk
    
    enum InteractionRisk {
        case low
        case medium
        case high
    }
}

public struct PatientCohort {
    let id: String
    let name: String
    let criteria: [CohortCriteria]
    let patientIds: [String]
}

public struct CohortCriteria {
    let field: String
    let operator: CriteriaOperator
    let value: String
    
    enum CriteriaOperator {
        case equals
        case contains
        case greaterThan
        case lessThan
        case between
    }
}

public struct PopulationAdherenceAnalysis {
    let cohort: PatientCohort
    let timeframe: AnalysisTimeframe
    let overallAdherenceRate: Double
    let adherenceDistribution: StatisticalDistribution
    let demographicPatterns: [DemographicPattern]
    let medicationPatterns: [MedicationPattern]
    let insights: [PopulationInsight]
}

public struct StatisticalDistribution {
    let mean: Double
    let median: Double
    let standardDeviation: Double
    let quartiles: [Double]
    let outliers: [Double]
}

public struct DemographicPattern {
    let demographic: String
    let value: String
    let adherenceRate: Double
    let sampleSize: Int
    let significance: Double
}

public struct MedicationPattern {
    let medicationClass: String
    let adherenceRate: Double
    let commonBarriers: [String]
    let successFactors: [String]
}

public struct PopulationInsight {
    let type: InsightType
    let description: String
    let impact: InsightImpact
    let recommendations: [String]
    
    enum InsightType {
        case adherenceGap
        case successPattern
        case riskFactor
        case intervention
    }
    
    enum InsightImpact {
        case low
        case medium
        case high
    }
}

// MARK: - Extensions

extension Publisher {
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> Publishers.CompactMap<Self, T> {
        compactMap { value in
            Task {
                await transform(value)
            }.result.get()
        }
    }
}

extension AdherenceAnalytics {
    /// Convenience method for quick adherence assessment
    public func quickAdherenceCheck(patientId: String) async throws -> (score: Double, risk: AdherenceRiskLevel) {
        let analysis = try await analyzeMedicationAdherence(patientId: patientId, timeframe: .last7Days)
        let risk = assessCurrentRiskLevel(score: analysis.overallScore, trend: .stable)
        return (analysis.overallScore, risk)
    }
}
