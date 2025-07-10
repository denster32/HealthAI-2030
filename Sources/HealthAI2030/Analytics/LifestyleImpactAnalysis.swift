// MARK: - LifestyleImpactAnalysis.swift
// HealthAI 2030 - Agent 6 (Analytics) Deliverable
// Comprehensive lifestyle impact analysis and health behavior correlation system

import Foundation
import Combine
import HealthKit

/// Advanced lifestyle impact analysis engine for correlating lifestyle factors with health outcomes
public final class LifestyleImpactAnalysis: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var currentLifestyleScore: Double = 0.0
    @Published public var impactFactors: [LifestyleImpactFactor] = []
    @Published public var healthCorrelations: [HealthCorrelation] = []
    @Published public var behaviorRecommendations: [BehaviorRecommendation] = []
    
    // MARK: - Private Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let mlModels: MLPredictiveModels
    private let behaviorRecognition: BehavioralPatternRecognition
    private let healthDataManager: HealthDataManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let analysisConfig = LifestyleAnalysisConfiguration()
    private let correlationThresholds = CorrelationThresholds()
    
    // MARK: - Initialization
    public init(analyticsEngine: AdvancedAnalyticsEngine,
                mlModels: MLPredictiveModels,
                behaviorRecognition: BehavioralPatternRecognition,
                healthDataManager: HealthDataManager) {
        self.analyticsEngine = analyticsEngine
        self.mlModels = mlModels
        self.behaviorRecognition = behaviorRecognition
        self.healthDataManager = healthDataManager
        setupRealTimeAnalysis()
    }
    
    // MARK: - Public Methods
    
    /// Comprehensive lifestyle impact analysis for a patient
    public func analyzeLifestyleImpact(
        patientId: String,
        timeframe: AnalysisTimeframe = .last90Days
    ) async throws -> LifestyleImpactAnalysis {
        let lifestyleData = try await fetchLifestyleData(patientId: patientId, timeframe: timeframe)
        let healthOutcomes = try await fetchHealthOutcomes(patientId: patientId, timeframe: timeframe)
        
        let impactFactors = try await analyzeImpactFactors(
            lifestyleData: lifestyleData,
            healthOutcomes: healthOutcomes
        )
        
        let correlations = calculateHealthCorrelations(
            lifestyle: lifestyleData,
            health: healthOutcomes
        )
        
        let behaviorInsights = try await generateBehaviorInsights(
            impactFactors: impactFactors,
            correlations: correlations
        )
        
        return LifestyleImpactAnalysis(
            patientId: patientId,
            timeframe: timeframe,
            overallLifestyleScore: calculateOverallLifestyleScore(impactFactors),
            impactFactors: impactFactors,
            healthCorrelations: correlations,
            behaviorInsights: behaviorInsights,
            recommendations: generateLifestyleRecommendations(
                factors: impactFactors,
                correlations: correlations,
                insights: behaviorInsights
            )
        )
    }
    
    /// Analyzes nutrition impact on health outcomes
    public func analyzeNutritionImpact(
        patientId: String,
        timeframe: AnalysisTimeframe = .last60Days
    ) async throws -> NutritionImpactAnalysis {
        let nutritionData = try await fetchNutritionData(patientId: patientId, timeframe: timeframe)
        let metabolicMarkers = try await fetchMetabolicMarkers(patientId: patientId, timeframe: timeframe)
        
        let nutritionalPatterns = try await identifyNutritionalPatterns(nutritionData)
        let metabolicCorrelations = calculateMetabolicCorrelations(nutritionData, metabolicMarkers)
        let nutritionalQuality = assessNutritionalQuality(nutritionData)
        
        return NutritionImpactAnalysis(
            patientId: patientId,
            timeframe: timeframe,
            nutritionalScore: nutritionalQuality.overallScore,
            macronutrientBalance: nutritionalQuality.macroBalance,
            micronutrientStatus: nutritionalQuality.microStatus,
            dietaryPatterns: nutritionalPatterns,
            metabolicImpact: metabolicCorrelations,
            recommendations: generateNutritionRecommendations(
                quality: nutritionalQuality,
                patterns: nutritionalPatterns,
                correlations: metabolicCorrelations
            )
        )
    }
    
    /// Analyzes physical activity impact on health
    public func analyzeActivityImpact(
        patientId: String,
        timeframe: AnalysisTimeframe = .last60Days
    ) async throws -> ActivityImpactAnalysis {
        let activityData = try await fetchActivityData(patientId: patientId, timeframe: timeframe)
        let fitnessMetrics = try await fetchFitnessMetrics(patientId: patientId, timeframe: timeframe)
        let healthMarkers = try await fetchHealthMarkers(patientId: patientId, timeframe: timeframe)
        
        let activityPatterns = try await analyzeActivityPatterns(activityData)
        let fitnessProgression = calculateFitnessProgression(fitnessMetrics)
        let healthCorrelations = correlateActivityWithHealth(activityData, healthMarkers)
        
        return ActivityImpactAnalysis(
            patientId: patientId,
            timeframe: timeframe,
            activityScore: calculateActivityScore(activityData),
            activityPatterns: activityPatterns,
            fitnessProgression: fitnessProgression,
            healthCorrelations: healthCorrelations,
            recommendations: generateActivityRecommendations(
                patterns: activityPatterns,
                progression: fitnessProgression,
                correlations: healthCorrelations
            )
        )
    }
    
    /// Analyzes sleep impact on health outcomes
    public func analyzeSleepImpact(
        patientId: String,
        timeframe: AnalysisTimeframe = .last60Days
    ) async throws -> SleepImpactAnalysis {
        let sleepData = try await fetchSleepData(patientId: patientId, timeframe: timeframe)
        let cognitiveMetrics = try await fetchCognitiveMetrics(patientId: patientId, timeframe: timeframe)
        let moodData = try await fetchMoodData(patientId: patientId, timeframe: timeframe)
        
        let sleepQuality = assessSleepQuality(sleepData)
        let sleepPatterns = try await identifySleepPatterns(sleepData)
        let cognitiveImpact = correlateSleepWithCognition(sleepData, cognitiveMetrics)
        let moodImpact = correlateSleepWithMood(sleepData, moodData)
        
        return SleepImpactAnalysis(
            patientId: patientId,
            timeframe: timeframe,
            sleepQualityScore: sleepQuality.overallScore,
            sleepEfficiency: sleepQuality.efficiency,
            sleepPatterns: sleepPatterns,
            cognitiveImpact: cognitiveImpact,
            moodImpact: moodImpact,
            recommendations: generateSleepRecommendations(
                quality: sleepQuality,
                patterns: sleepPatterns,
                cognitiveImpact: cognitiveImpact,
                moodImpact: moodImpact
            )
        )
    }
    
    /// Analyzes stress impact on health outcomes
    public func analyzeStressImpact(
        patientId: String,
        timeframe: AnalysisTimeframe = .last60Days
    ) async throws -> StressImpactAnalysis {
        let stressData = try await fetchStressData(patientId: patientId, timeframe: timeframe)
        let physiologicalMarkers = try await fetchPhysiologicalMarkers(patientId: patientId, timeframe: timeframe)
        let behaviorChanges = try await identifyStressRelatedBehaviorChanges(patientId: patientId, timeframe: timeframe)
        
        let stressPatterns = try await analyzeStressPatterns(stressData)
        let physiologicalImpact = correlateStressWithPhysiology(stressData, physiologicalMarkers)
        let behavioralImpact = correlateStressWithBehavior(stressData, behaviorChanges)
        
        return StressImpactAnalysis(
            patientId: patientId,
            timeframe: timeframe,
            overallStressLevel: calculateOverallStressLevel(stressData),
            stressPatterns: stressPatterns,
            physiologicalImpact: physiologicalImpact,
            behavioralImpact: behavioralImpact,
            recommendations: generateStressManagementRecommendations(
                patterns: stressPatterns,
                physiological: physiologicalImpact,
                behavioral: behavioralImpact
            )
        )
    }
    
    /// Generates personalized lifestyle optimization plan
    public func generateLifestyleOptimizationPlan(
        patientId: String,
        goals: [HealthGoal],
        timeframe: OptimizationTimeframe = .next90Days
    ) async throws -> LifestyleOptimizationPlan {
        let currentLifestyle = try await analyzeLifestyleImpact(patientId: patientId)
        let nutritionAnalysis = try await analyzeNutritionImpact(patientId: patientId)
        let activityAnalysis = try await analyzeActivityImpact(patientId: patientId)
        let sleepAnalysis = try await analyzeSleepImpact(patientId: patientId)
        let stressAnalysis = try await analyzeStressImpact(patientId: patientId)
        
        let optimizationOpportunities = identifyOptimizationOpportunities(
            lifestyle: currentLifestyle,
            nutrition: nutritionAnalysis,
            activity: activityAnalysis,
            sleep: sleepAnalysis,
            stress: stressAnalysis,
            goals: goals
        )
        
        let prioritizedInterventions = prioritizeInterventions(
            opportunities: optimizationOpportunities,
            goals: goals
        )
        
        return LifestyleOptimizationPlan(
            patientId: patientId,
            goals: goals,
            timeframe: timeframe,
            currentBaseline: LifestyleBaseline(
                lifestyle: currentLifestyle,
                nutrition: nutritionAnalysis,
                activity: activityAnalysis,
                sleep: sleepAnalysis,
                stress: stressAnalysis
            ),
            optimizationOpportunities: optimizationOpportunities,
            prioritizedInterventions: prioritizedInterventions,
            expectedOutcomes: predictOptimizationOutcomes(
                interventions: prioritizedInterventions,
                baseline: currentLifestyle,
                timeframe: timeframe
            ),
            milestones: generateOptimizationMilestones(
                interventions: prioritizedInterventions,
                timeframe: timeframe
            )
        )
    }
    
    /// Provides real-time lifestyle monitoring
    public func startRealTimeLifestyleMonitoring(patientId: String) -> AnyPublisher<LifestyleUpdate, Never> {
        return Timer.publish(every: analysisConfig.monitoringInterval, on: .main, in: .common)
            .autoconnect()
            .asyncMap { [weak self] _ in
                guard let self = self else { return nil }
                return try? await self.generateRealTimeLifestyleUpdate(patientId: patientId)
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func setupRealTimeAnalysis() {
        // Configure real-time lifestyle monitoring
        healthDataManager.lifestyleUpdatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.processLifestyleUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func fetchLifestyleData(
        patientId: String,
        timeframe: AnalysisTimeframe
    ) async throws -> LifestyleData {
        // Aggregate lifestyle data from multiple sources
        let nutrition = try await fetchNutritionData(patientId: patientId, timeframe: timeframe)
        let activity = try await fetchActivityData(patientId: patientId, timeframe: timeframe)
        let sleep = try await fetchSleepData(patientId: patientId, timeframe: timeframe)
        let stress = try await fetchStressData(patientId: patientId, timeframe: timeframe)
        let social = try await fetchSocialFactors(patientId: patientId, timeframe: timeframe)
        let environmental = try await fetchEnvironmentalFactors(patientId: patientId, timeframe: timeframe)
        
        return LifestyleData(
            nutrition: nutrition,
            activity: activity,
            sleep: sleep,
            stress: stress,
            social: social,
            environmental: environmental
        )
    }
    
    private func analyzeImpactFactors(
        lifestyleData: LifestyleData,
        healthOutcomes: [HealthOutcome]
    ) async throws -> [LifestyleImpactFactor] {
        var impactFactors: [LifestyleImpactFactor] = []
        
        // Nutrition impact
        let nutritionImpact = try await calculateNutritionImpact(
            nutrition: lifestyleData.nutrition,
            outcomes: healthOutcomes
        )
        impactFactors.append(contentsOf: nutritionImpact)
        
        // Activity impact
        let activityImpact = try await calculateActivityImpact(
            activity: lifestyleData.activity,
            outcomes: healthOutcomes
        )
        impactFactors.append(contentsOf: activityImpact)
        
        // Sleep impact
        let sleepImpact = try await calculateSleepImpact(
            sleep: lifestyleData.sleep,
            outcomes: healthOutcomes
        )
        impactFactors.append(contentsOf: sleepImpact)
        
        // Stress impact
        let stressImpact = try await calculateStressImpact(
            stress: lifestyleData.stress,
            outcomes: healthOutcomes
        )
        impactFactors.append(contentsOf: stressImpact)
        
        return impactFactors.sorted { $0.impactMagnitude > $1.impactMagnitude }
    }
    
    private func calculateHealthCorrelations(
        lifestyle: LifestyleData,
        health: [HealthOutcome]
    ) -> [HealthCorrelation] {
        var correlations: [HealthCorrelation] = []
        
        for outcome in health {
            // Calculate correlations with each lifestyle factor
            let nutritionCorrelation = calculateCorrelation(
                lifestyle.nutrition.qualityScore,
                outcome.value
            )
            
            let activityCorrelation = calculateCorrelation(
                lifestyle.activity.totalMinutes,
                outcome.value
            )
            
            let sleepCorrelation = calculateCorrelation(
                lifestyle.sleep.qualityScore,
                outcome.value
            )
            
            let stressCorrelation = calculateCorrelation(
                lifestyle.stress.averageLevel,
                outcome.value
            )
            
            // Only include significant correlations
            if abs(nutritionCorrelation) > correlationThresholds.significanceThreshold {
                correlations.append(HealthCorrelation(
                    lifestyleFactor: .nutrition,
                    healthOutcome: outcome.type,
                    correlation: nutritionCorrelation,
                    significance: calculateSignificance(nutritionCorrelation),
                    confidence: calculateConfidence(nutritionCorrelation)
                ))
            }
            
            if abs(activityCorrelation) > correlationThresholds.significanceThreshold {
                correlations.append(HealthCorrelation(
                    lifestyleFactor: .physicalActivity,
                    healthOutcome: outcome.type,
                    correlation: activityCorrelation,
                    significance: calculateSignificance(activityCorrelation),
                    confidence: calculateConfidence(activityCorrelation)
                ))
            }
            
            if abs(sleepCorrelation) > correlationThresholds.significanceThreshold {
                correlations.append(HealthCorrelation(
                    lifestyleFactor: .sleep,
                    healthOutcome: outcome.type,
                    correlation: sleepCorrelation,
                    significance: calculateSignificance(sleepCorrelation),
                    confidence: calculateConfidence(sleepCorrelation)
                ))
            }
            
            if abs(stressCorrelation) > correlationThresholds.significanceThreshold {
                correlations.append(HealthCorrelation(
                    lifestyleFactor: .stress,
                    healthOutcome: outcome.type,
                    correlation: stressCorrelation,
                    significance: calculateSignificance(stressCorrelation),
                    confidence: calculateConfidence(stressCorrelation)
                ))
            }
        }
        
        return correlations.sorted { $0.significance > $1.significance }
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0.0
    }
    
    private func calculateSignificance(_ correlation: Double) -> Double {
        return abs(correlation)
    }
    
    private func calculateConfidence(_ correlation: Double) -> Double {
        // Simplified confidence calculation
        return min(0.99, abs(correlation) * 1.2)
    }
    
    private func generateBehaviorInsights(
        impactFactors: [LifestyleImpactFactor],
        correlations: [HealthCorrelation]
    ) async throws -> [BehaviorInsight] {
        var insights: [BehaviorInsight] = []
        
        // Identify behavioral patterns from impact factors
        for factor in impactFactors.prefix(5) { // Top 5 impact factors
            if let insight = try await generateInsightForFactor(factor, correlations: correlations) {
                insights.append(insight)
            }
        }
        
        // Identify synergistic effects
        let synergisticInsights = try await identifySynergisticEffects(
            factors: impactFactors,
            correlations: correlations
        )
        insights.append(contentsOf: synergisticInsights)
        
        return insights
    }
    
    private func generateInsightForFactor(
        _ factor: LifestyleImpactFactor,
        correlations: [HealthCorrelation]
    ) async throws -> BehaviorInsight? {
        let relatedCorrelations = correlations.filter { $0.lifestyleFactor == factor.category }
        
        guard !relatedCorrelations.isEmpty else { return nil }
        
        let averageCorrelation = relatedCorrelations.map { $0.correlation }.reduce(0, +) / Double(relatedCorrelations.count)
        
        return BehaviorInsight(
            type: .impactFactor,
            category: factor.category,
            description: generateInsightDescription(factor: factor, correlation: averageCorrelation),
            impact: factor.impactMagnitude,
            confidence: factor.confidence,
            recommendations: generateFactorRecommendations(factor)
        )
    }
    
    private func generateInsightDescription(factor: LifestyleImpactFactor, correlation: Double) -> String {
        let direction = correlation > 0 ? "positively" : "negatively"
        let strength = abs(correlation) > 0.7 ? "strongly" : abs(correlation) > 0.4 ? "moderately" : "weakly"
        
        return "\(factor.category.rawValue) \(strength) \(direction) impacts your \(factor.relatedHealthOutcome)"
    }
    
    private func generateFactorRecommendations(_ factor: LifestyleImpactFactor) -> [String] {
        switch factor.category {
        case .nutrition:
            return [
                "Consider consulting with a nutritionist",
                "Track your food intake for better insights",
                "Focus on whole foods and balanced meals"
            ]
        case .physicalActivity:
            return [
                "Gradually increase your activity level",
                "Choose activities you enjoy",
                "Set realistic and achievable goals"
            ]
        case .sleep:
            return [
                "Maintain a consistent sleep schedule",
                "Create a relaxing bedtime routine",
                "Optimize your sleep environment"
            ]
        case .stress:
            return [
                "Practice stress reduction techniques",
                "Consider mindfulness or meditation",
                "Identify and address stress triggers"
            ]
        default:
            return ["Monitor this factor and consider professional guidance"]
        }
    }
    
    private func processLifestyleUpdate(_ update: LifestyleUpdateData) {
        DispatchQueue.main.async {
            // Update published properties based on real-time data
            self.currentLifestyleScore = update.overallScore
            
            if !update.newImpactFactors.isEmpty {
                self.impactFactors = update.newImpactFactors
            }
            
            if !update.newCorrelations.isEmpty {
                self.healthCorrelations = update.newCorrelations
            }
        }
    }
    
    // Additional helper methods would be implemented here...
    
    private func generateRealTimeLifestyleUpdate(patientId: String) async throws -> LifestyleUpdate {
        let recentData = try await fetchRecentLifestyleData(patientId: patientId)
        let currentScore = calculateCurrentLifestyleScore(recentData)
        let alertFactors = identifyAlertingFactors(recentData)
        
        return LifestyleUpdate(
            patientId: patientId,
            timestamp: Date(),
            overallScore: currentScore,
            alertingFactors: alertFactors,
            recommendations: generateImmediateRecommendations(alertFactors)
        )
    }
    
    private func fetchRecentLifestyleData(patientId: String) async throws -> LifestyleData {
        // Implementation for fetching recent lifestyle data
        // This would integrate with real-time data streams
        return LifestyleData(
            nutrition: NutritionData(qualityScore: [], dailyIntake: []),
            activity: ActivityData(totalMinutes: [], intensityDistribution: []),
            sleep: SleepData(qualityScore: [], duration: []),
            stress: StressData(averageLevel: [], peakEvents: []),
            social: SocialFactors(socialEngagement: 0.0, supportNetwork: 0.0),
            environmental: EnvironmentalFactors(airQuality: 0.0, noiseLevel: 0.0)
        )
    }
    
    private func calculateCurrentLifestyleScore(_ data: LifestyleData) -> Double {
        let nutritionWeight = 0.3
        let activityWeight = 0.25
        let sleepWeight = 0.25
        let stressWeight = 0.2
        
        let nutritionScore = data.nutrition.qualityScore.last ?? 0.0
        let activityScore = normalizeActivityScore(data.activity.totalMinutes.last ?? 0.0)
        let sleepScore = data.sleep.qualityScore.last ?? 0.0
        let stressScore = 1.0 - (data.stress.averageLevel.last ?? 0.0) // Invert stress (lower is better)
        
        return nutritionScore * nutritionWeight +
               activityScore * activityWeight +
               sleepScore * sleepWeight +
               stressScore * stressWeight
    }
    
    private func normalizeActivityScore(_ minutes: Double) -> Double {
        let targetMinutes = 150.0 // WHO recommendation per week / 7
        let dailyTarget = targetMinutes / 7.0
        return min(1.0, minutes / dailyTarget)
    }
    
    private func identifyAlertingFactors(_ data: LifestyleData) -> [AlertingFactor] {
        var factors: [AlertingFactor] = []
        
        // Check for concerning patterns
        if let lastNutritionScore = data.nutrition.qualityScore.last,
           lastNutritionScore < 0.4 {
            factors.append(.lowNutritionQuality(score: lastNutritionScore))
        }
        
        if let lastActivityMinutes = data.activity.totalMinutes.last,
           lastActivityMinutes < 20 { // Less than 20 minutes of activity
            factors.append(.insufficientActivity(minutes: lastActivityMinutes))
        }
        
        if let lastSleepScore = data.sleep.qualityScore.last,
           lastSleepScore < 0.5 {
            factors.append(.poorSleepQuality(score: lastSleepScore))
        }
        
        if let lastStressLevel = data.stress.averageLevel.last,
           lastStressLevel > 0.7 {
            factors.append(.highStressLevel(level: lastStressLevel))
        }
        
        return factors
    }
    
    private func generateImmediateRecommendations(_ factors: [AlertingFactor]) -> [String] {
        var recommendations: [String] = []
        
        for factor in factors {
            switch factor {
            case .lowNutritionQuality:
                recommendations.append("Consider planning your next meal with more whole foods")
            case .insufficientActivity:
                recommendations.append("Take a 10-minute walk to boost your activity level")
            case .poorSleepQuality:
                recommendations.append("Consider a relaxing activity before bedtime tonight")
            case .highStressLevel:
                recommendations.append("Try a 5-minute breathing exercise to reduce stress")
            }
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public enum LifestyleFactor: String, CaseIterable {
    case nutrition
    case physicalActivity
    case sleep
    case stress
    case social
    case environmental
}

public enum OptimizationTimeframe {
    case next30Days
    case next90Days
    case next6Months
    case next1Year
}

public struct LifestyleAnalysisConfiguration {
    let monitoringInterval: TimeInterval = 3600 // 1 hour
    let correlationAnalysisWindow: TimeInterval = 86400 * 30 // 30 days
    let significanceThreshold: Double = 0.3
}

public struct CorrelationThresholds {
    let significanceThreshold: Double = 0.3
    let strongCorrelationThreshold: Double = 0.7
    let moderateCorrelationThreshold: Double = 0.4
}

// Core data structures
public struct LifestyleData {
    let nutrition: NutritionData
    let activity: ActivityData
    let sleep: SleepData
    let stress: StressData
    let social: SocialFactors
    let environmental: EnvironmentalFactors
}

public struct NutritionData {
    let qualityScore: [Double]
    let dailyIntake: [DailyNutritionIntake]
}

public struct DailyNutritionIntake {
    let date: Date
    let calories: Double
    let macronutrients: Macronutrients
    let micronutrients: [String: Double]
    let hydration: Double
}

public struct Macronutrients {
    let carbohydrates: Double
    let protein: Double
    let fat: Double
    let fiber: Double
}

public struct ActivityData {
    let totalMinutes: [Double]
    let intensityDistribution: [ActivityIntensity]
}

public struct ActivityIntensity {
    let date: Date
    let light: Double
    let moderate: Double
    let vigorous: Double
}

public struct SleepData {
    let qualityScore: [Double]
    let duration: [Double]
}

public struct StressData {
    let averageLevel: [Double]
    let peakEvents: [StressEvent]
}

public struct StressEvent {
    let timestamp: Date
    let intensity: Double
    let duration: TimeInterval
    let triggers: [String]
}

public struct SocialFactors {
    let socialEngagement: Double
    let supportNetwork: Double
}

public struct EnvironmentalFactors {
    let airQuality: Double
    let noiseLevel: Double
}

public struct LifestyleImpactFactor {
    let category: LifestyleFactor
    let name: String
    let impactMagnitude: Double
    let direction: ImpactDirection
    let confidence: Double
    let relatedHealthOutcome: String
    
    enum ImpactDirection {
        case positive
        case negative
        case neutral
    }
}

public struct HealthCorrelation {
    let lifestyleFactor: LifestyleFactor
    let healthOutcome: HealthOutcomeType
    let correlation: Double
    let significance: Double
    let confidence: Double
}

public enum HealthOutcomeType: String {
    case bloodPressure
    case heartRate
    case bloodGlucose
    case weight
    case mood
    case energy
    case cognitiveFunction
    case sleepQuality
    case painLevel
}

public struct HealthOutcome {
    let type: HealthOutcomeType
    let value: [Double]
    let timestamps: [Date]
}

public struct BehaviorInsight {
    let type: InsightType
    let category: LifestyleFactor
    let description: String
    let impact: Double
    let confidence: Double
    let recommendations: [String]
    
    enum InsightType {
        case impactFactor
        case behaviorPattern
        case synergisticEffect
        case riskFactor
    }
}

// Analysis result structures
public struct LifestyleImpactAnalysis {
    let patientId: String
    let timeframe: AnalysisTimeframe
    let overallLifestyleScore: Double
    let impactFactors: [LifestyleImpactFactor]
    let healthCorrelations: [HealthCorrelation]
    let behaviorInsights: [BehaviorInsight]
    let recommendations: [BehaviorRecommendation]
}

public struct BehaviorRecommendation {
    let category: LifestyleFactor
    let priority: RecommendationPriority
    let description: String
    let actionSteps: [String]
    let expectedImpact: Double
    let timeframe: String
    
    enum RecommendationPriority {
        case high
        case medium
        case low
    }
}

// Specialized analysis types
public struct NutritionImpactAnalysis {
    let patientId: String
    let timeframe: AnalysisTimeframe
    let nutritionalScore: Double
    let macronutrientBalance: MacronutrientBalance
    let micronutrientStatus: MicronutrientStatus
    let dietaryPatterns: [DietaryPattern]
    let metabolicImpact: [MetabolicCorrelation]
    let recommendations: [NutritionRecommendation]
}

public struct MacronutrientBalance {
    let carbPercentage: Double
    let proteinPercentage: Double
    let fatPercentage: Double
    let fiberIntake: Double
    let isBalanced: Bool
}

public struct MicronutrientStatus {
    let vitamins: [String: NutrientStatus]
    let minerals: [String: NutrientStatus]
    let overallStatus: NutrientStatus
}

public enum NutrientStatus {
    case deficient
    case adequate
    case optimal
    case excessive
}

public struct DietaryPattern {
    let name: String
    let adherence: Double
    let healthImpact: Double
    let recommendations: [String]
}

public struct MetabolicCorrelation {
    let nutrient: String
    let metabolicMarker: String
    let correlation: Double
    let significance: Double
}

public struct NutritionRecommendation {
    let type: NutritionRecommendationType
    let description: String
    let targetNutrient: String?
    let quantitativeTarget: Double?
    let timeframe: String
    
    enum NutritionRecommendationType {
        case increaseNutrient
        case decreaseNutrient
        case balanceMacros
        case improveTiming
        case addSupplement
    }
}

public struct ActivityImpactAnalysis {
    let patientId: String
    let timeframe: AnalysisTimeframe
    let activityScore: Double
    let activityPatterns: [ActivityPattern]
    let fitnessProgression: FitnessProgression
    let healthCorrelations: [ActivityHealthCorrelation]
    let recommendations: [ActivityRecommendation]
}

public struct ActivityPattern {
    let type: ActivityPatternType
    let frequency: Double
    let consistency: Double
    let healthImpact: Double
    
    enum ActivityPatternType {
        case consistentDaily
        case weekendWarrior
        case sporadic
        case sedentary
    }
}

public struct FitnessProgression {
    let cardioEndurance: ProgressionTrend
    let strength: ProgressionTrend
    let flexibility: ProgressionTrend
    let overallFitness: ProgressionTrend
}

public struct ProgressionTrend {
    let direction: TrendDirection
    let rate: Double
    let confidence: Double
    
    enum TrendDirection {
        case improving
        case stable
        case declining
    }
}

public struct ActivityHealthCorrelation {
    let activityType: String
    let healthMetric: String
    let correlation: Double
    let significance: Double
}

public struct ActivityRecommendation {
    let type: ActivityRecommendationType
    let description: String
    let targetMinutes: Int?
    let intensity: ActivityIntensityLevel?
    let frequency: String
    
    enum ActivityRecommendationType {
        case increaseCardio
        case addStrength
        case improveFlexibility
        case increaseConsistency
        case reduceIntensity
    }
    
    enum ActivityIntensityLevel {
        case light
        case moderate
        case vigorous
    }
}

public struct SleepImpactAnalysis {
    let patientId: String
    let timeframe: AnalysisTimeframe
    let sleepQualityScore: Double
    let sleepEfficiency: Double
    let sleepPatterns: [SleepPattern]
    let cognitiveImpact: CognitiveImpactAssessment
    let moodImpact: MoodImpactAssessment
    let recommendations: [SleepRecommendation]
}

public struct SleepPattern {
    let type: SleepPatternType
    let frequency: Double
    let impact: Double
    
    enum SleepPatternType {
        case regularSchedule
        case irregularBedtime
        case frequentAwakenings
        case shortSleep
        case longSleep
    }
}

public struct CognitiveImpactAssessment {
    let attentionImpact: Double
    let memoryImpact: Double
    let executiveFunctionImpact: Double
    let overallCognitiveImpact: Double
}

public struct MoodImpactAssessment {
    let moodStability: Double
    let stressResilience: Double
    let emotionalRegulation: Double
    let overallMoodImpact: Double
}

public struct SleepRecommendation {
    let type: SleepRecommendationType
    let description: String
    let implementation: String
    let expectedImprovement: Double
    
    enum SleepRecommendationType {
        case improveSchedule
        case optimizeEnvironment
        case enhanceBedtimeRoutine
        case addressSleepDisorders
        case manageCaffeine
    }
}

public struct StressImpactAnalysis {
    let patientId: String
    let timeframe: AnalysisTimeframe
    let overallStressLevel: Double
    let stressPatterns: [StressPattern]
    let physiologicalImpact: PhysiologicalStressImpact
    let behavioralImpact: BehavioralStressImpact
    let recommendations: [StressManagementRecommendation]
}

public struct StressPattern {
    let type: StressPatternType
    let frequency: Double
    let intensity: Double
    let triggers: [String]
    
    enum StressPatternType {
        case chronicStress
        case acuteStressEvents
        case workRelatedStress
        case relationshipStress
        case financialStress
    }
}

public struct PhysiologicalStressImpact {
    let cardiovascularImpact: Double
    let immuneSystemImpact: Double
    let digestiveImpact: Double
    let sleepImpact: Double
}

public struct BehavioralStressImpact {
    let eatingBehaviorChanges: Double
    let activityLevelChanges: Double
    let socialWithdrawal: Double
    let copingBehaviors: [String]
}

public struct StressManagementRecommendation {
    let type: StressManagementType
    let description: String
    let techniques: [String]
    let expectedEffectiveness: Double
    
    enum StressManagementType {
        case relaxationTechniques
        case cognitiveStrategies
        case lifestyleModifications
        case socialSupport
        case professionalHelp
    }
}

// Optimization and planning types
public struct LifestyleOptimizationPlan {
    let patientId: String
    let goals: [HealthGoal]
    let timeframe: OptimizationTimeframe
    let currentBaseline: LifestyleBaseline
    let optimizationOpportunities: [OptimizationOpportunity]
    let prioritizedInterventions: [LifestyleIntervention]
    let expectedOutcomes: [ExpectedOutcome]
    let milestones: [OptimizationMilestone]
}

public struct HealthGoal {
    let id: String
    let category: LifestyleFactor
    let description: String
    let targetValue: Double
    let currentValue: Double
    let priority: GoalPriority
    let timeframe: String
    
    enum GoalPriority {
        case high
        case medium
        case low
    }
}

public struct LifestyleBaseline {
    let lifestyle: LifestyleImpactAnalysis
    let nutrition: NutritionImpactAnalysis
    let activity: ActivityImpactAnalysis
    let sleep: SleepImpactAnalysis
    let stress: StressImpactAnalysis
}

public struct OptimizationOpportunity {
    let area: LifestyleFactor
    let currentScore: Double
    let potentialImprovement: Double
    let difficulty: ImprovementDifficulty
    let expectedTimeframe: String
    
    enum ImprovementDifficulty {
        case easy
        case moderate
        case challenging
    }
}

public struct LifestyleIntervention {
    let id: String
    let category: LifestyleFactor
    let name: String
    let description: String
    let actionSteps: [InterventionStep]
    let expectedImpact: Double
    let difficulty: ImprovementDifficulty
    let timeframe: String
    let prerequisites: [String]
}

public struct InterventionStep {
    let order: Int
    let description: String
    let duration: String
    let resources: [String]
    let successCriteria: [String]
}

public struct ExpectedOutcome {
    let area: LifestyleFactor
    let currentValue: Double
    let expectedValue: Double
    let confidence: Double
    let timeframe: String
}

public struct OptimizationMilestone {
    let id: String
    let week: Int
    let goals: [String]
    let successMetrics: [String]
    let checkpointActivities: [String]
}

// Real-time monitoring types
public struct LifestyleUpdate {
    let patientId: String
    let timestamp: Date
    let overallScore: Double
    let alertingFactors: [AlertingFactor]
    let recommendations: [String]
}

public enum AlertingFactor {
    case lowNutritionQuality(score: Double)
    case insufficientActivity(minutes: Double)
    case poorSleepQuality(score: Double)
    case highStressLevel(level: Double)
}

public struct LifestyleUpdateData {
    let overallScore: Double
    let newImpactFactors: [LifestyleImpactFactor]
    let newCorrelations: [HealthCorrelation]
}

// Health data management protocol
public protocol HealthDataManager {
    var lifestyleUpdatesPublisher: AnyPublisher<LifestyleUpdateData, Never> { get }
    
    func fetchNutritionData(patientId: String, timeframe: AnalysisTimeframe) async throws -> NutritionData
    func fetchActivityData(patientId: String, timeframe: AnalysisTimeframe) async throws -> ActivityData
    func fetchSleepData(patientId: String, timeframe: AnalysisTimeframe) async throws -> SleepData
    func fetchStressData(patientId: String, timeframe: AnalysisTimeframe) async throws -> StressData
    func fetchSocialFactors(patientId: String, timeframe: AnalysisTimeframe) async throws -> SocialFactors
    func fetchEnvironmentalFactors(patientId: String, timeframe: AnalysisTimeframe) async throws -> EnvironmentalFactors
    func fetchHealthOutcomes(patientId: String, timeframe: AnalysisTimeframe) async throws -> [HealthOutcome]
}

// Extensions for enhanced functionality
extension LifestyleImpactAnalysis {
    /// Quick assessment method for lifestyle impact
    public func quickAssessment() -> (score: Double, topFactors: [String], urgentRecommendations: [String]) {
        let topFactors = Array(impactFactors.prefix(3)).map { $0.name }
        let urgentRecommendations = recommendations
            .filter { $0.priority == .high }
            .map { $0.description }
        
        return (overallLifestyleScore, topFactors, urgentRecommendations)
    }
}

extension Publisher {
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> Publishers.CompactMap<Self, T> {
        compactMap { value in
            Task {
                await transform(value)
            }.result.get()
        }
    }
}
