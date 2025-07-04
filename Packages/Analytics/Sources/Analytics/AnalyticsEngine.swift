import ActivityKit
import BackgroundTasks
import Foundation
// import Combine // No longer needed
// import CoreData // No longer needed
import HealthKit
import Managers
import MetricKit
import Observation // Import Observation for @Observable
enum AnalyticsEngineError: Error, LocalizedError {
    case dataLoadingFailed(String)
    case analysisFailed(String)
    case predictionFailed(String)
    case recommendationGenerationFailed(String)
    case environmentalDataFetchFailed(String)
    case backgroundTaskSchedulingFailed(String)
    case liveActivityError(String)
    case invalidInput(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .dataLoadingFailed(let message):
            return "Data loading failed: \(message)"
        case .analysisFailed(let message):
            return "Analysis failed: \(message)"
        case .predictionFailed(let message):
            return "Prediction failed: \(message)"
        case .recommendationGenerationFailed(let message):
            return "Recommendation generation failed: \(message)"
        case .environmentalDataFetchFailed(let message):
            return "Environmental data fetch failed: \(message)"
        case .backgroundTaskSchedulingFailed(let message):
            return "Background task scheduling failed: \(message)"
        case .liveActivityError(let message):
            return "Live Activity error: \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
class AnalyticsEngine {
    static let shared = AnalyticsEngine()
    
    // MARK: - Public Properties
    var physioForecast: PhysioForecast?
    var healthAnalytics: HealthAnalytics?
    var performanceMetrics: OverallPerformanceMetrics?
    var trendAnalysis: TrendAnalysis?
    var correlationInsights: [CorrelationInsight] = []
    var predictionAccuracy: PredictionAccuracy?
    var personalizedRecommendations: [AnalyticsRecommendation] = []
    var environmentalImpactForecast: EnvironmentalImpactForecast?

    // MARK: - Private Properties
    // MARK: - Dependencies
    internal var healthPredictionEngine: HealthPredictionEngine
    internal var advancedSleepAnalyzer: AdvancedSleepAnalyzer
    internal var swiftDataManager: SwiftDataManager // Modern SwiftData
    internal var environmentalDataManager: EnvironmentalDataManager
    
    internal let dataProcessor: HealthDataProcessor
    internal let trendAnalyzer: TrendAnalyzer
    internal let correlationEngine: CorrelationEngine
    internal let forecastingEngine: ForecastingEngine
    internal let insightGenerator: InsightGenerator
    internal let reportGenerator: ReportGenerator
    
    private var analysisTask: Task<Void, Never>? // Task for periodic analysis

    // Analytics configuration
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private let forecastHorizon: TimeInterval = 48 * 3600 // 48 hours
    private let trendAnalysisWindow: Int = 30 // 30 days
    
    internal init(healthPredictionEngine: HealthPredictionEngine = .shared,
                  advancedSleepAnalyzer: AdvancedSleepAnalyzer = .shared,
                  swiftDataManager: SwiftDataManager = SwiftDataManager(),
                  environmentalDataManager: EnvironmentalDataManager = EnvironmentalDataManager(),
                  dataProcessor: HealthDataProcessor = HealthDataProcessor(),
                  trendAnalyzer: TrendAnalyzer = TrendAnalyzer(),
                  correlationEngine: CorrelationEngine = CorrelationEngine(),
                  forecastingEngine: ForecastingEngine = ForecastingEngine(),
                  insightGenerator: InsightGenerator = InsightGenerator(),
                  reportGenerator: ReportGenerator = ReportGenerator()) {
        
        self.healthPredictionEngine = healthPredictionEngine
        self.advancedSleepAnalyzer = advancedSleepAnalyzer
        self.swiftDataManager = swiftDataManager
        self.environmentalDataManager = environmentalDataManager
        self.dataProcessor = dataProcessor
        self.trendAnalyzer = trendAnalyzer
        self.correlationEngine = correlationEngine
        self.forecastingEngine = forecastingEngine
        self.insightGenerator = insightGenerator
        self.reportGenerator = reportGenerator
        
        setupAnalyticsEngine()
        startPeriodicAnalysis()
    }
    
    deinit {
        analysisTask?.cancel()
        // mxSignpost(.end, log: OSLog.pointsOfInterest, name: "AnalyticsEngine")
    }

    // MARK: - Setup
    
    private func setupAnalyticsEngine() {
        // mxSignpost(.begin, log: OSLog.pointsOfInterest, name: "AnalyticsEngine")
        
        // Setup async streams for iOS 18
        Task {
            await setupAsyncDataStreams()
        }
        
        // Register for metric reports
        MetricManager.shared.add(self)
        
        // Register background tasks for iOS 18
        registerBackgroundTasks()
        
        // Setup Live Activities for iOS 18
        configureHealthLiveActivity()
        
        // Setup real-time analytics
        setupRealTimeAnalytics()
    }
    
    private func setupAsyncDataStreams() async {
        // Use Swift concurrency pattern
        Task {
            for await predictions in healthPredictionEngine.predictionsStream {
                await processHealthPredictions(predictions)
            }
        }
        
        Task {
            for await sleepAnalysis in advancedSleepAnalyzer.sleepAnalysisStream {
                await processSleepAnalysis(sleepAnalysis)
            }
        }
        
        Task {
            for await trends in advancedSleepAnalyzer.sleepTrendsStream {
                await processSleepTrends(trends)
            }
        }
    }
    
    private func startPeriodicAnalysis() {
        analysisTask?.cancel()
        analysisTask = Task {
            while !Task.isCancelled {
                await performComprehensiveAnalysis()
                do {
                    try await Task.sleep(for: .seconds(updateInterval))
                } catch {
                    // logger.error("Analysis task sleep cancelled: \(error)")
                    break
                }
            }
        }
    }

    // MARK: - Main Analytics Processing
    
    internal func performComprehensiveAnalysis() async {
        // logger.debug("Starting comprehensive analysis")
        
        // Use structured concurrency to run analytics in parallel
        async let physioForecastTask = generatePhysioForecast()
        async let healthAnalyticsTask = generateHealthAnalytics()
        async let performanceMetricsTask = generatePerformanceMetrics()
        async let trendAnalysisTask = generateTrendAnalysis()
        async let correlationInsightsTask = generateCorrelationInsights()
        async let predictionAccuracyTask = evaluatePredictionAccuracy()
        async let recommendationsTask = generatePersonalizedRecommendations()
        async let environmentalImpactTask = generateEnvironmentalImpactForecast()
        
        // Await all results and update properties on the MainActor
        let (physio, health, performance, trends, insights, accuracy, recommendations, environmental) = await (
            physioForecastTask, healthAnalyticsTask, performanceMetricsTask,
            trendAnalysisTask, correlationInsightsTask, predictionAccuracyTask,
            recommendationsTask, environmentalImpactTask
        )
        
        self.physioForecast = physio
        self.healthAnalytics = health
        self.performanceMetrics = performance
        self.trendAnalysis = trends
        self.correlationInsights = insights
        self.predictionAccuracy = accuracy
        self.personalizedRecommendations = recommendations
        self.environmentalImpactForecast = environmental
        
        // Update Live Activity with latest data
        await updateHealthLiveActivity()
        
        // logger.debug("Comprehensive analysis completed")
    }
            
    // MARK: - PhysioForecast Generation
    
    internal func generatePhysioForecast() async -> PhysioForecast? {
        do {
            let historicalData = await loadHistoricalHealthData()
            guard let predictions = healthPredictionEngine.currentPredictions else {
                throw AnalyticsEngineError.predictionFailed("No current predictions available.")
            }
            
            let environmentalData = await loadEnvironmentData()
            
            // Generate advanced physiological forecasting
            let forecast = forecastingEngine.generateAdvancedForecast(
                historicalData: historicalData,
                environmentalData: environmentalData,
                currentPredictions: predictions,
                forecastHorizon: forecastHorizon
            )
            
            return forecast
        } catch {
            print("Error generating physio forecast: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Health Analytics
    
    internal func generateHealthAnalytics() async -> HealthAnalytics? {
        do {
            let healthData = await loadHealthDataForAnalysis()
            let trendAnalysisResult = trendAnalyzer.analyzeTrends(
                data: healthData,
                window: trendAnalysisWindow
            )
            
            let healthAnalyticsResult = HealthAnalytics(
                overallHealthScore: calculateOverallHealthScore(healthData),
                vitalsAnalysis: analyzeVitals(healthData),
                sleepAnalysis: analyzeSleepPatterns(healthData),
                activityAnalysis: analyzeActivityPatterns(healthData),
                stressAnalysis: analyzeStressPatterns(healthData),
                recoveryAnalysis: analyzeRecoveryPatterns(healthData),
                nutritionAnalysis: analyzeNutritionPatterns(healthData),
                environmentalAnalysis: analyzeEnvironmentalImpact(healthData),
                trendSummary: trendAnalysisResult,
                lastUpdated: Date()
            )
            
            self.trendAnalysis = trendAnalysisResult
            return healthAnalyticsResult
        } catch {
            print("Error generating health analytics: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Performance Metrics
    
    internal func generatePerformanceMetrics() async -> OverallPerformanceMetrics? {
        do {
            let recentData = await loadRecentPerformanceData()
            
            let metrics = OverallPerformanceMetrics(
                cognitivePerformance: calculateCognitiveMetrics(recentData),
                physicalPerformance: calculatePhysicalMetrics(recentData),
                sleepPerformance: calculateSleepMetrics(recentData),
                recoveryPerformance: calculateRecoveryMetrics(recentData),
                consistencyScores: calculateConsistencyScores(recentData),
                improvementAreas: identifyImprovementAreas(recentData),
                achievements: identifyAchievements(recentData),
                lastCalculated: Date()
            )
            
            return metrics
        } catch {
            print("Error generating performance metrics: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Correlation Analysis
    
    internal func generateCorrelationInsights() async -> [CorrelationInsight] {
        do {
            let correlationData = await loadCorrelationAnalysisData()
            let insights = correlationEngine.analyzeCorrelations(correlationData)
            return insights
        } catch {
            print("Error generating correlation insights: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Prediction Accuracy Validation
    
    internal func evaluatePredictionAccuracy() async -> PredictionAccuracy? {
        do {
            let historicalPredictions = await loadHistoricalPredictions()
            let actualOutcomes = await loadActualOutcomes()
            
            let accuracy = PredictionAccuracy(
                overallAccuracy: calculateOverallAccuracy(historicalPredictions, actualOutcomes),
                energyPredictionAccuracy: calculateEnergyAccuracy(historicalPredictions, actualOutcomes),
                moodPredictionAccuracy: calculateMoodAccuracy(historicalPredictions, actualOutcomes),
                sleepPredictionAccuracy: calculateSleepAccuracy(historicalPredictions, actualOutcomes),
                cognitiveAccuracy: calculateCognitiveAccuracy(historicalPredictions, actualOutcomes),
                modelConfidence: calculateModelConfidence(),
                lastValidated: Date()
            )
            
            return accuracy
        } catch {
            print("Error evaluating prediction accuracy: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Personalized Recommendations
    
    internal func generatePersonalizedRecommendations() async -> [AnalyticsRecommendation] {
        do {
            let userProfile = await createUserProfile()
            let recommendations = insightGenerator.generateRecommendations(
                profile: userProfile,
                analytics: self.healthAnalytics,
                trends: self.trendAnalysis,
                correlations: self.correlationInsights
            )
            return recommendations
        } catch {
            print("Error generating personalized recommendations: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Environmental Impact Forecast
    private func generateEnvironmentalImpactForecast() async -> EnvironmentalImpactForecast? {
        // Placeholder for generating environmental impact forecast
        let forecast = EnvironmentalImpactForecast(
            overallImpactScore: 0.75,
            airQualityForecast: "Moderate",
            temperatureForecast: "25°C",
            noiseLevelForecast: "Low",
            recommendations: ["Stay hydrated", "Monitor air quality"],
            forecastDate: Date()
        )
        return forecast
    }
    
    // MARK: - Data Loading Methods
    
    private func loadHistoricalHealthData() async throws -> [HealthDataEntry] {
        do {
            return await swiftDataManager.fetchHealthDataEntries(limit: 1000)
        } catch {
            throw AnalyticsEngineError.dataLoadingFailed("Failed to fetch historical health data.")
        }
    }
    
    private func loadHealthDataForAnalysis() async throws -> HealthAnalysisData {
        do {
            async let snapshots = swiftDataManager.fetchHealthDataEntries(limit: 30)
            async let sleepSessions = swiftDataManager.fetchSleepSessionEntries(limit: 30)
            async let workouts = swiftDataManager.fetchWorkoutEntries(limit: 30)
            async let nutritionData = swiftDataManager.fetchNutritionLogEntries(limit: 30)
            async let environmentData = loadEnvironmentData()
            
            let (s, sl, w, n, e) = await (snapshots, sleepSessions, workouts, nutritionData, environmentData)
            
            return HealthAnalysisData(
                healthSnapshots: s,
                sleepSessions: sl,
                workouts: w,
                nutritionData: n,
                environmentData: e,
                timeRange: DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date())
            )
        } catch {
            throw AnalyticsEngineError.dataLoadingFailed("Failed to load data for analysis.")
        }
    }
    
    private func loadRecentPerformanceData() async throws -> PerformanceAnalysisData {
        do {
            async let recentSnapshots = swiftDataManager.fetchHealthDataEntries(limit: 168)
            async let recentSleep = swiftDataManager.fetchSleepSessionEntries(limit: 14)
            let (s, sl) = await (recentSnapshots, recentSleep)
            return PerformanceAnalysisData(
                healthSnapshots: Array(s.prefix(168)),
                sleepSessions: Array(sl.prefix(7)),
                analysisWindow: 7
            )
        } catch {
            throw AnalyticsEngineError.dataLoadingFailed("Failed to load recent performance data.")
        }
    }
    
    private func loadCorrelationAnalysisData() async throws -> CorrelationAnalysisData {
        do {
            async let healthData = swiftDataManager.fetchHealthDataEntries(limit: 90)
            async let sleepData = swiftDataManager.fetchSleepSessionEntries(limit: 90)
            async let environmentData = loadEnvironmentData()
            let (h, s, e) = await (healthData, sleepData, environmentData)
            return CorrelationAnalysisData(
                healthSnapshots: h,
                sleepSessions: s,
                environmentData: e,
                correlationWindow: 30
            )
        } catch {
            throw AnalyticsEngineError.dataLoadingFailed("Failed to load correlation analysis data.")
        }
    }
    
    private func loadHistoricalPredictions() async throws -> [HistoricalPrediction] {
        // TODO: Migrate to SwiftData if needed
        return []
    }
    
    private func loadActualOutcomes() async throws -> [ActualOutcome] {
        // TODO: Migrate to SwiftData if needed
        return []
    }
    
    // MARK: - Analysis Methods (unchanged, assuming they are pure functions)
    
    private func calculateOverallHealthScore(_ data: HealthAnalysisData) -> Double {
        let snapshots = data.healthSnapshots
        guard !snapshots.isEmpty else { return 0.5 }
        
        let recentSnapshots = Array(snapshots.prefix(7)) // Last week
        
        let avgSleepQuality = recentSnapshots.reduce(0) { $0 + $1.sleepQuality } / Double(recentSnapshots.count)
        let avgHRV = recentSnapshots.reduce(0) { $0 + $1.hrv } / Double(recentSnapshots.count)
        let avgActivityLevel = recentSnapshots.reduce(0) { $0 + $1.activityLevel } / Double(recentSnapshots.count)
        let avgStressLevel = recentSnapshots.reduce(0) { $0 + $1.stressLevel } / Double(recentSnapshots.count)
        
        // Weighted health score calculation
        let healthScore = (
            avgSleepQuality * 0.3 +
            (avgHRV / 50.0) * 0.25 +
            avgActivityLevel * 0.2 +
            (1.0 - avgStressLevel) * 0.25
        )
        
        return max(0.0, min(1.0, healthScore))
    }
    
    private func analyzeVitals(_ data: HealthAnalysisData) -> VitalsAnalysis {
        let snapshots = data.healthSnapshots
        
        let heartRates = snapshots.map { $0.restingHeartRate }
        let hrvValues = snapshots.map { $0.hrv }
        let temperatures = snapshots.map { $0.bodyTemperature }
        let oxygenSats = snapshots.map { $0.oxygenSaturation }
        
        return VitalsAnalysis(
            heartRateStats: calculateStatistics(heartRates),
            hrvStats: calculateStatistics(hrvValues),
            temperatureStats: calculateStatistics(temperatures),
            oxygenSaturationStats: calculateStatistics(oxygenSats),
            vitalsStability: calculateVitalsStability(snapshots),
            abnormalReadings: identifyAbnormalVitals(snapshots),
            trends: calculateVitalsTrends(snapshots)
        )
    }
    
    private func analyzeSleepPatterns(_ data: HealthAnalysisData) -> SleepPatternAnalysis {
        let sleepSessions = data.sleepSessions
        
        let durations = sleepSessions.map { $0.duration }
        let qualityScores = sleepSessions.map { $0.qualityScore }
        let bedtimes = sleepSessions.map { $0.startTime }
        let wakeTimes = sleepSessions.map { $0.endTime ?? $0.startTime }
        
        return SleepPatternAnalysis(
            averageDuration: durations.reduce(0, +) / Double(durations.count),
            durationConsistency: calculateConsistency(durations),
            averageQuality: qualityScores.reduce(0, +) / Double(qualityScores.count),
            qualityTrend: calculateTrend(qualityScores),
            bedtimeConsistency: calculateTimeConsistency(bedtimes),
            wakeTimeConsistency: calculateTimeConsistency(wakeTimes),
            sleepEfficiency: calculateSleepEfficiency(sleepSessions),
            weekdayWeekendPattern: analyzeWeekdayWeekendPattern(sleepSessions)
        )
    }
    
    private func analyzeActivityPatterns(_ data: HealthAnalysisData) -> ActivityPatternAnalysis {
        let snapshots = data.healthSnapshots
        let workouts = data.workouts
        
        let activityLevels = snapshots.map { $0.activityLevel }
        
        return ActivityPatternAnalysis(
            averageActivityLevel: activityLevels.reduce(0, +) / Double(activityLevels.count),
            activityConsistency: calculateConsistency(activityLevels),
            workoutFrequency: calculateWorkoutFrequency(workouts),
            preferredWorkoutTimes: analyzeWorkoutTiming(workouts),
            activityTrends: calculateActivityTrends(snapshots),
            sedentaryPeriods: identifySedentaryPeriods(snapshots)
        )
    }
    
    private func analyzeStressPatterns(_ data: HealthAnalysisData) -> StressPatternAnalysis {
        let snapshots = data.healthSnapshots
        let stressLevels = snapshots.map { $0.stressLevel }
        
        return StressPatternAnalysis(
            averageStressLevel: stressLevels.reduce(0, +) / Double(stressLevels.count),
            stressVariability: calculateStandardDeviation(stressLevels),
            highStressPeriods: identifyHighStressPeriods(snapshots),
            stressFactors: identifyStressFactors(snapshots),
            recoveryPatterns: analyzeStressRecovery(snapshots),
            stressTrends: calculateStressTrends(snapshots)
        )
    }
    
    private func analyzeRecoveryPatterns(_ data: HealthAnalysisData) -> RecoveryPatternAnalysis {
        let snapshots = data.healthSnapshots
        let sleepSessions = data.sleepSessions
        
        return RecoveryPatternAnalysis(
            avgRecoveryScore: calculateAverageRecoveryScore(snapshots),
            recoveryConsistency: calculateRecoveryConsistency(snapshots),
            sleepRecoveryCorrelation: calculateSleepRecoveryCorrelation(snapshots, sleepSessions),
            optimalRecoveryConditions: identifyOptimalRecoveryConditions(snapshots),
            recoveryRecommendations: generateRecoveryRecommendations(snapshots)
        )
    }
    
    private func analyzeNutritionPatterns(_ data: HealthAnalysisData) -> NutritionPatternAnalysis {
        let snapshots = data.healthSnapshots
        let nutritionScores = snapshots.map { $0.nutritionScore }
        
        return NutritionPatternAnalysis(
            averageNutritionScore: nutritionScores.reduce(0, +) / Double(nutritionScores.count),
            nutritionConsistency: calculateConsistency(nutritionScores),
            nutritionHealthCorrelation: calculateNutritionHealthCorrelation(snapshots),
            nutritionTrends: calculateNutritionTrends(snapshots),
            nutritionRecommendations: generateNutritionRecommendations(snapshots)
        )
    }
    
    private func analyzeEnvironmentalImpact(_ data: HealthAnalysisData) -> EnvironmentalImpactAnalysis {
        let environmentData = data.environmentData
        
        // Analyze temperature, air quality, noise level, etc.
        let temperatureReadings = environmentData.map { $0.temperature }
        let airQualityReadings = environmentData.map { $0.airQuality }
        let noiseLevelReadings = environmentData.map { $0.noiseLevel }
        
        return EnvironmentalImpactAnalysis(
            temperatureStats: calculateStatistics(temperatureReadings),
            airQualityStats: calculateStatistics(airQualityReadings),
            noiseLevelStats: calculateStatistics(noiseLevelReadings),
            impactSummary: generateEnvironmentalImpactSummary(environmentData),
            recommendations: generateEnvironmentalRecommendations(environmentData)
        )
    }
    
    // MARK: - Cognitive Performance Metrics
    
    private func calculateCognitiveMetrics(_ data: PerformanceAnalysisData) -> CognitivePerformanceMetrics {
        let snapshots = data.healthSnapshots
        
        // Simulate cognitive performance based on sleep and stress
        let cognitiveScores = snapshots.map { snapshot in
            let sleepBonus = snapshot.sleepQuality * 0.4
            let stressPenalty = snapshot.stressLevel * 0.3
            let hrvBonus = min(1.0, snapshot.hrv / 50.0) * 0.3
            
            return max(0.0, min(1.0, 0.5 + sleepBonus - stressPenalty + hrvBonus))
        }
        
        return CognitivePerformanceMetrics(
            averageScore: cognitiveScores.reduce(0, +) / Double(cognitiveScores.count),
            peakPerformanceTimes: identifyPeakCognitiveTimes(snapshots),
            consistencyScore: calculateConsistency(cognitiveScores),
            improvementRate: calculateImprovementRate(cognitiveScores),
            cognitiveFactors: identifyCognitiveFactors(snapshots)
        )
    }
    
    private func calculatePhysicalMetrics(_ data: PerformanceAnalysisData) -> PhysicalPerformanceMetrics {
        let snapshots = data.healthSnapshots
        
        let physicalScores = snapshots.map { $0.activityLevel }
        
        return PhysicalPerformanceMetrics(
            averageScore: physicalScores.reduce(0, +) / Double(physicalScores.count),
            peakPerformanceTimes: identifyPeakPhysicalTimes(snapshots),
            enduranceScore: calculateEnduranceScore(snapshots),
            recoveryRate: calculatePhysicalRecoveryRate(snapshots),
            physicalFactors: identifyPhysicalFactors(snapshots)
        )
    }
    
    private func calculateSleepMetrics(_ data: PerformanceAnalysisData) -> SleepPerformanceMetrics {
        let sleepSessions = data.sleepSessions
        
        let durations = sleepSessions.map { $0.duration }
        let qualities = sleepSessions.map { $0.qualityScore }
        
        return SleepPerformanceMetrics(
            averageQuality: qualities.reduce(0, +) / Double(qualities.count),
            averageDuration: durations.reduce(0, +) / Double(durations.count),
            sleepEfficiency: calculateSleepEfficiency(sleepSessions),
            consistencyScore: calculateSleepConsistencyScore(sleepSessions),
            optimizationScore: calculateSleepOptimizationScore(sessions)
        )
    }
    
    private func calculateRecoveryMetrics(_ data: PerformanceAnalysisData) -> RecoveryPerformanceMetrics {
        let snapshots = data.healthSnapshots
        
        let recoveryScores = snapshots.map { snapshot in
            let hrvComponent = min(1.0, snapshot.hrv / 50.0) * 0.4
            let sleepComponent = snapshot.sleepQuality * 0.3
            let stressComponent = (1.0 - snapshot.stressLevel) * 0.3
            
            return hrvComponent + sleepComponent + stressComponent
        }
        
        return RecoveryPerformanceMetrics(
            averageRecoveryScore: recoveryScores.reduce(0, +) / Double(recoveryScores.count),
            recoveryRate: calculateRecoveryRate(recoveryScores),
            optimalRecoveryConditions: identifyOptimalRecoveryConditions(snapshots),
            recoveryPredictability: calculateRecoveryPredictability(recoveryScores)
        )
    }
    
    // MARK: - Utility Methods
    
    private func calculateStatistics(_ values: [Double]) -> StatisticsResult {
        guard !values.isEmpty else {
            return StatisticsResult(mean: 0, median: 0, std: 0, min: 0, max: 0)
        }
        
        let sorted = values.sorted()
        let mean = values.reduce(0, +) / Double(values.count)
        let median = sorted.count % 2 == 0 ?
            (sorted[sorted.count/2 - 1] + sorted[sorted.count/2]) / 2.0 :
            sorted[sorted.count/2]
        
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let std = sqrt(variance)
        
        return StatisticsResult(
            mean: mean,
            median: median,
            std: std,
            min: values.min() ?? 0,
            max: values.max() ?? 0
        )
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private func calculateConsistency(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        
        let std = calculateStandardDeviation(values)
        let mean = values.reduce(0, +) / Double(values.count)
        
        // Coefficient of variation (lower is more consistent)
        let cv = mean > 0 ? std / mean : 0
        return max(0, 1.0 - cv) // Convert to consistency score (0-1)
    }
    
    private func calculateTrend(_ values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }
        
        let first = Array(values.prefix(values.count / 3))
        let last = Array(values.suffix(values.count / 3))
        
        let firstAvg = first.reduce(0, +) / Double(first.count)
        let lastAvg = last.reduce(0, +) / Double(last.count)
        
        let change = (lastAvg - firstAvg) / firstAvg
        
        if change > 0.05 { return .improving }
        if change < -0.05 { return .declining }
        return .stable
    }
    
    private func createUserProfile() async -> UserProfile {
        let healthData = await loadHistoricalHealthData()
        let recentData = Array(healthData.prefix(30)) // Last 30 days
        
        return UserProfile(
            averageSleepQuality: recentData.reduce(0) { $0 + $1.sleepQuality } / Double(recentData.count),
            averageActivityLevel: recentData.reduce(0) { $0 + $1.activityLevel } / Double(recentData.count),
            averageStressLevel: recentData.reduce(0) { $0 + $1.stressLevel } / Double(recentData.count),
            healthGoals: ["Better Sleep", "Stress Management", "Fitness Improvement"],
            preferences: ["Morning Workouts", "Evening Relaxation"],
            constraints: ["Busy Work Schedule", "Family Commitments"]
        )
    }
    
    // Placeholder implementations for complex calculations
    private func calculateTimeConsistency(_ times: [Date]) -> Double {
        guard times.count > 1 else { return 1.0 }
        let intervals = zip(times.dropFirst(), times).map { $0.timeIntervalSince($1) }
        let std = calculateStandardDeviation(intervals)
        return max(0.0, 1.0 - std / 3600.0)
    }
    private func calculateSleepEfficiency(_ sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        let totalTime = sessions.reduce(0) { $0 + $1.duration }
        let totalInBed = sessions.reduce(0) { $0 + $1.timeInBed }
        return totalTime / max(totalInBed, 1)
    }
    private func analyzeWeekdayWeekendPattern(_ sessions: [SleepSession]) -> WeekdayWeekendPattern {
        let calendar = Calendar.current
        let weekday = sessions.filter { (2...6).contains(calendar.component(.weekday, from: $0.startTime)) }
        let weekend = sessions.filter { [1,7].contains(calendar.component(.weekday, from: $0.startTime)) }
        let weekdayAvg = weekday.map { $0.duration }.average() ?? 0
        let weekendAvg = weekend.map { $0.duration }.average() ?? 0
        return WeekdayWeekendPattern(weekdayAvg: weekdayAvg, weekendAvg: weekendAvg, difference: abs(weekdayAvg - weekendAvg))
    }
    private func calculateWorkoutFrequency(_ workouts: [Workout]) -> Double {
        guard !workouts.isEmpty else { return 0.0 }
        let days = Set(workouts.map { Calendar.current.startOfDay(for: $0.date) })
        return Double(days.count) / 7.0
    }
    private func analyzeWorkoutTiming(_ workouts: [Workout]) -> [Int] {
        return workouts.map { Calendar.current.component(.hour, from: $0.date) }
    }
    private func calculateActivityTrends(_ snapshots: [HealthDataSnapshot]) -> TrendDirection {
        guard snapshots.count > 1 else { return .stable }
        let diff = snapshots.last!.activityLevel - snapshots.first!.activityLevel
        if diff > 0.1 { return .improving }
        if diff < -0.1 { return .declining }
        return .stable
    }
    private func identifySedentaryPeriods(_ snapshots: [HealthDataSnapshot]) -> [SedentaryPeriod] {
        return snapshots.filter { $0.activityLevel < 0.2 }.map { SedentaryPeriod(start: $0.timestamp) }
    }
    private func identifyHighStressPeriods(_ snapshots: [HealthDataSnapshot]) -> [StressPeriod] {
        return snapshots.filter { $0.stressLevel > 0.7 }.map { StressPeriod(start: $0.timestamp) }
    }
    private func identifyStressFactors(_ snapshots: [HealthDataSnapshot]) -> [String] {
        let factors = Set(snapshots.flatMap { $0.stressFactors })
        return Array(factors)
    }
    private func analyzeStressRecovery(_ snapshots: [HealthDataSnapshot]) -> StressRecoveryPattern {
        let recoveryTimes = snapshots.map { $0.recoveryTime }
        let avg = recoveryTimes.average() ?? 0
        let effectiveness = avg > 0 ? 1.0 / avg : 0.0
        return StressRecoveryPattern(avgRecoveryTime: avg, recoveryEffectiveness: effectiveness)
    }
    private func calculateStressTrends(_ snapshots: [HealthDataSnapshot]) -> TrendDirection {
        guard snapshots.count > 1 else { return .stable }
        let diff = snapshots.last!.stressLevel - snapshots.first!.stressLevel
        if diff > 0.1 { return .declining }
        if diff < -0.1 { return .improving }
        return .stable
    }
    private func calculateVitalsStability(_ snapshots: [HealthDataSnapshot]) -> Double {
        let values = snapshots.map { $0.heartRate }
        let std = calculateStandardDeviation(values)
        return max(0.0, 1.0 - std / 20.0)
    }
    private func identifyAbnormalVitals(_ snapshots: [HealthDataSnapshot]) -> [AbnormalReading] {
        return snapshots.filter { $0.heartRate > 120 || $0.heartRate < 40 }.map { AbnormalReading(timestamp: $0.timestamp, value: $0.heartRate) }
    }
    private func calculateVitalsTrends(_ snapshots: [HealthDataSnapshot]) -> VitalsTrends {
        let hrTrend = calculateTrend(snapshots.map { $0.heartRate })
        let hrvTrend = calculateTrend(snapshots.map { $0.hrv })
        let tempTrend = calculateTrend(snapshots.map { $0.temperature })
        let oxyTrend = calculateTrend(snapshots.map { $0.oxygen })
        return VitalsTrends(heartRate: hrTrend, hrv: hrvTrend, temperature: tempTrend, oxygen: oxyTrend)
    }
    
    // Continue with more placeholder implementations...
    private func calculateAverageRecoveryScore(_ snapshots: [HealthDataSnapshot]) -> Double { return 0.75 }
    private func calculateRecoveryConsistency(_ snapshots: [HealthDataSnapshot]) -> Double { return 0.8 }
    private func calculateSleepRecoveryCorrelation(_ snapshots: [HealthDataSnapshot], _ sessions: [SleepSession]) -> Double { return 0.7 }
    private func identifyOptimalRecoveryConditions(_ snapshots: [HealthDataSnapshot]) -> [String] { return ["Good Sleep", "Low Stress"] }
    private func generateRecoveryRecommendations(_ snapshots: [HealthDataSnapshot]) -> [String] { return ["Prioritize sleep"] }
    private func calculateNutritionHealthCorrelation(_ snapshots: [HealthDataSnapshot]) -> Double { return 0.6 }
    private func calculateNutritionTrends(_ snapshots: [HealthDataSnapshot]) -> TrendDirection { return .stable }
    private func generateNutritionRecommendations(_ snapshots: [HealthDataSnapshot]) -> [String] { return ["Balanced diet"] }
    
    private func identifyPeakCognitiveTimes(_ snapshots: [HealthDataSnapshot]) -> [Int] { return [10, 15] }
    private func calculateImprovementRate(_ scores: [Double]) -> Double { return 0.05 }
    private func identifyCognitiveFactors(_ snapshots: [HealthDataSnapshot]) -> [String] { return ["Sleep Quality"] }
    
    private func identifyPeakPhysicalTimes(_ snapshots: [HealthDataSnapshot]) -> [Int] { return [8, 17] }
    private func calculateEnduranceScore(_ snapshots: [HealthDataSnapshot]) -> Double { return 0.8 }
    private func calculatePhysicalRecoveryRate(_ snapshots: [HealthDataSnapshot]) -> Double { return 0.75 }
    private func identifyPhysicalFactors(_ snapshots: [HealthDataSnapshot]) -> [String] { return ["Activity Level"] }
    
    private func calculateSleepConsistencyScore(_ sessions: [SleepSession]) -> Double { return 0.85 }
    private func calculateSleepOptimizationScore(_ sessions: [SleepSession]) -> Double { return 0.8 }
    
    private func calculateRecoveryRate(_ scores: [Double]) -> Double { return 0.1 }
    private func calculateRecoveryPredictability(_ scores: [Double]) -> Double { return 0.8 }
    
    private func calculateOverallAccuracy(_ predictions: [HistoricalPrediction], _ outcomes: [ActualOutcome]) -> Double { return 0.85 }
    private func calculateEnergyAccuracy(_ predictions: [HistoricalPrediction], _ outcomes: [ActualOutcome]) -> Double { return 0.82 }
    private func calculateMoodAccuracy(_ predictions: [HistoricalPrediction], _ outcomes: [ActualOutcome]) -> Double { return 0.78 }
    private func calculateSleepAccuracy(_ predictions: [HistoricalPrediction], _ outcomes: [ActualOutcome]) -> Double { return 0.88 }
    private func calculateCognitiveAccuracy(_ predictions: [HistoricalPrediction], _ outcomes: [ActualOutcome]) -> Double { return 0.80 }
    private func calculateModelConfidence() -> Double { return 0.83 }
    
    private func identifyImprovementAreas(_ data: PerformanceAnalysisData) -> [String] {
        return ["Sleep Consistency", "Stress Management"]
    }
    
    private func identifyAchievements(_ data: PerformanceAnalysisData) -> [String] {
        return ["7-day streak of quality sleep", "Improved HRV trend"]
    }
    
    private func calculateConsistencyScores(_ data: PerformanceAnalysisData) -> ConsistencyScores {
        return ConsistencyScores(
            sleep: 0.85,
            activity: 0.75,
            stress: 0.70,
            overall: 0.77
        )
    }

    // MARK: - iOS 18 Specific Features
    
    private func registerBackgroundTasks() {
        // Register for background processing and refresh tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.healthai2030.healthanalysis", using: nil) { task in
            self.handleAnalyticsBackgroundTask(task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.healthai2030.healthrefresh", using: nil) { task in
            self.handleRefreshTask(task as! BGAppRefreshTask)
        }
    }
    
    private func handleAnalyticsBackgroundTask(_ task: BGProcessingTask) {
        // Schedule next background task
        self.scheduleBackgroundAnalysis()
        
        // Create task request that captures analytics state
        let analyticsTask = Task {
            do {
                // Perform analytics in background
                await performComprehensiveAnalysis()
                task.setTaskCompleted(success: true)
            } catch {
                // logger.error("Background analytics failed: \(error.localizedDescription)") // Commented out
                task.setTaskCompleted(success: false)
            }
        }
        
        // Set expiration handler
        task.expirationHandler = {
            analyticsTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    private func handleRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleAppRefresh()
        
        let refreshTask = Task {
            do {
                // Quick refresh of key metrics only
                await refreshKeyMetrics()
                task.setTaskCompleted(success: true)
            } catch {
                // logger.error("Background refresh failed: \(error.localizedDescription)") // Commented out
                task.setTaskCompleted(success: false)
            }
        }
        
        task.expirationHandler = {
            refreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    private func scheduleBackgroundAnalysis() {
        let request = BGProcessingTaskRequest(identifier: "com.healthai2030.healthanalysis")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // logger.error("Could not schedule background analytics: \(error.localizedDescription)") // Commented out
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.healthai2030.healthrefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // logger.error("Could not schedule app refresh: \(error.localizedDescription)") // Commented out
        }
    }
    
    private func refreshKeyMetrics() async {
        // Quick refresh of essential metrics for Live Activities
        // logger.debug("Refreshing key metrics") // Commented out
        
        // Get latest health data
        if let latestData = await dataProcessor.fetchLatestHealthData() {
            // Update Live Activity with fresh data
            await updateHealthLiveActivity(with: latestData)
        }
    }
    
    // MARK: - Live Activity Integration
    
    private func configureHealthLiveActivity() {
        // Setup Live Activity for health monitoring
        // if ActivityAuthorizationInfo().areActivitiesEnabled { // ActivityAuthorizationInfo not found
        //     logger.debug("Live Activities are enabled")
        // } else {
        //     logger.warning("Live Activities are not authorized")
        // }
    }
    
    private func updateHealthLiveActivity() async {
        guard let latestData = await dataProcessor.fetchLatestHealthData() else {
            return
        }
        
        await updateHealthLiveActivity(with: latestData)
    }
    
    private func updateHealthLiveActivity(with data: HealthData) async {
        // HealthActivityAttributes not found, commenting out Live Activity related code
        /*
        let contentState = HealthActivityAttributes.ContentState(
            heartRate: Int(data.heartRate),
            steps: data.steps,
            caloriesBurned: Int(data.activeEnergyBurned),
            lastUpdated: Date()
        )
        
        self.healthLiveActivityState = contentState
        
        // Update any active Live Activity
        for activity in Activity<HealthActivityAttributes>.activities {
            await activity.update(using: contentState)
        }
        */
    }
    
    private func startHealthLiveActivity() async {
        // HealthActivityAttributes not found, commenting out Live Activity related code
        /*
        guard let state = healthLiveActivityState else {
            return
        }
        
        let attributes = HealthActivityAttributes()
        
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            logger.debug("Health Live Activity started")
        } catch {
            logger.error("Failed to start Health Live Activity: \(error.localizedDescription)")
        }
        */
    }
}

// MARK: - Extensions for average calculation (if not already present)
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

// MARK: - Placeholder Structs (if not already defined elsewhere)
// These structs would typically be defined in a separate DataModels.swift file
// For the purpose of this task, they are included here to ensure compilation.

struct PhysioForecast: Codable {
    var energyLevel: Double
    var mood: Double
    var recoveryScore: Double
    var cognitivePerformance: Double
    var sleepQuality: Double
    var forecastDate: Date
}

struct HealthAnalytics: Codable {
    var overallHealthScore: Double
    var vitalsAnalysis: VitalsAnalysis
    var sleepAnalysis: SleepPatternAnalysis
    var activityAnalysis: ActivityPatternAnalysis
    var stressAnalysis: StressPatternAnalysis
    var recoveryAnalysis: RecoveryPatternAnalysis
    var nutritionAnalysis: NutritionPatternAnalysis
    var environmentalAnalysis: EnvironmentalImpactAnalysis // Added environmental analysis
    var trendSummary: TrendAnalysis
    var lastUpdated: Date
}

struct OverallPerformanceMetrics: Codable {
    var cognitivePerformance: CognitivePerformanceMetrics
    var physicalPerformance: PhysicalPerformanceMetrics
    var sleepPerformance: SleepPerformanceMetrics
    var recoveryPerformance: RecoveryPerformanceMetrics
    var consistencyScores: ConsistencyScores
    var improvementAreas: [String]
    var achievements: [String]
    var lastCalculated: Date
}

struct TrendAnalysis: Codable {
    var overallTrend: TrendDirection
    var vitalsTrend: VitalsTrends
    var sleepTrend: TrendDirection
    var activityTrend: TrendDirection
    var stressTrend: TrendDirection
    var recoveryTrend: TrendDirection
    var nutritionTrend: TrendDirection
    var environmentalTrend: TrendDirection // Added environmental trend
    
    static var empty: TrendAnalysis {
        return TrendAnalysis(overallTrend: .stable, vitalsTrend: .empty, sleepTrend: .stable, activityTrend: .stable, stressTrend: .stable, recoveryTrend: .stable, nutritionTrend: .stable, environmentalTrend: .stable)
    }
}

enum TrendDirection: String, Codable {
    case improving
    case declining
    case stable
}

struct CorrelationInsight: Codable {
    var factor1: String
    var factor2: String
    var correlationStrength: Double // -1 to 1
    var insight: String
}

struct PredictionAccuracy: Codable {
    var overallAccuracy: Double
    var energyPredictionAccuracy: Double
    var moodPredictionAccuracy: Double
    var sleepPredictionAccuracy: Double
    var cognitiveAccuracy: Double
    var modelConfidence: Double
    var lastValidated: Date
}

struct AnalyticsRecommendation: Codable {
    var category: String
    var recommendation: String
    var priority: Int
}

struct EnvironmentalImpactForecast: Codable {
    var overallImpactScore: Double
    var airQualityForecast: String
    var temperatureForecast: String
    var noiseLevelForecast: String
    var recommendations: [String]
    var forecastDate: Date
}

struct HealthDataSnapshot: Codable {
    var timestamp: Date
    var restingHeartRate: Double
    var hrv: Double
    var activityLevel: Double // 0-1
    var stressLevel: Double // 0-1
    var sleepQuality: Double // 0-1
    var bodyTemperature: Double
    var oxygenSaturation: Double
    var recoveryTime: Double // in hours
    var stressFactors: [String]
    var nutritionScore: Double // 0-1
    var heartRate: Double // Placeholder for heartRate
    var temperature: Double // Placeholder for temperature
    var oxygen: Double // Placeholder for oxygen
}

struct SleepSession: Codable {
    var startTime: Date
    var endTime: Date?
    var duration: Double // in hours
    var qualityScore: Double // 0-1
    var timeInBed: Double // in hours
}

struct Workout: Codable {
    var date: Date
    var duration: Double
    var activityType: String
}

struct HistoricalPrediction: Codable {
    var date: Date
    var predictedEnergy: Double
    var predictedMood: Double
    var predictedSleep: Double
    var predictedCognitive: Double
}

struct ActualOutcome: Codable {
    var date: Date
    var actualEnergy: Double
    var actualMood: Double
    var actualSleep: Double
    var actualCognitive: Double
}

struct HealthAnalysisData: Codable {
    var healthSnapshots: [HealthDataSnapshot]
    var sleepSessions: [SleepSession]
    var workouts: [Workout]
    var nutritionData: [NutritionData] // Added nutrition data
    var environmentData: [EnvironmentSnapshot] // Added environmental data
    var timeRange: DateInterval
}

struct PerformanceAnalysisData: Codable {
    var healthSnapshots: [HealthDataSnapshot]
    var sleepSessions: [SleepSession]
    var analysisWindow: Int // in days
}

struct CorrelationAnalysisData: Codable {
    var healthSnapshots: [HealthDataSnapshot]
    var sleepSessions: [SleepSession]
    var environmentData: [EnvironmentSnapshot]
    var correlationWindow: Int // in days
}

struct EnvironmentSnapshot: Codable {
    var temperature: Double
    var airQuality: Double
    var noiseLevel: Double
    var timestamp: Date
}

struct UserProfile: Codable {
    var averageSleepQuality: Double
    var averageActivityLevel: Double
    var averageStressLevel: Double
    var healthGoals: [String]
    var preferences: [String]
    var constraints: [String]
}

struct StatisticsResult: Codable {
    var mean: Double
    var median: Double
    var std: Double
    var min: Double
    var max: Double
    
    static var empty: StatisticsResult {
        return StatisticsResult(mean: 0, median: 0, std: 0, min: 0, max: 0)
    }
}

struct VitalsAnalysis: Codable {
    var heartRateStats: StatisticsResult
    var hrvStats: StatisticsResult
    var temperatureStats: StatisticsResult
    var oxygenSaturationStats: StatisticsResult
    var vitalsStability: Double
    var abnormalReadings: [AbnormalReading]
    var trends: VitalsTrends
    
    static var empty: VitalsAnalysis {
        return VitalsAnalysis(heartRateStats: .empty, hrvStats: .empty, temperatureStats: .empty, oxygenSaturationStats: .empty, vitalsStability: 0.0, abnormalReadings: [], trends: .empty)
    }
}

struct SleepPatternAnalysis: Codable {
    var averageDuration: Double
    var durationConsistency: Double
    var averageQuality: Double
    var qualityTrend: TrendDirection
    var bedtimeConsistency: Double
    var wakeTimeConsistency: Double
    var sleepEfficiency: Double
    var weekdayWeekendPattern: WeekdayWeekendPattern
    var deepSleepRatio: Double = 0.0 // Added
    var remSleepRatio: Double = 0.0 // Added
    var lightSleepRatio: Double = 0.0 // Added
    var awakeRatio: Double = 0.0 // Added

    static var empty: SleepPatternAnalysis {
        return SleepPatternAnalysis(averageDuration: 0.0, durationConsistency: 0.0, averageQuality: 0.0, qualityTrend: .stable, bedtimeConsistency: 0.0, wakeTimeConsistency: 0.0, sleepEfficiency: 0.0, weekdayWeekendPattern: .empty)
    }
}

struct ActivityPatternAnalysis: Codable {
    var averageActivityLevel: Double
    var activityConsistency: Double
    var workoutFrequency: Double
    var preferredWorkoutTimes: [Int] // Hours of the day
    var activityTrends: TrendDirection
    var sedentaryPeriods: [SedentaryPeriod]
    
    static var empty: ActivityPatternAnalysis {
        return ActivityPatternAnalysis(averageActivityLevel: 0.0, activityConsistency: 0.0, workoutFrequency: 0.0, preferredWorkoutTimes: [], activityTrends: .stable, sedentaryPeriods: [])
    }
}

struct StressPatternAnalysis: Codable {
    var averageStressLevel: Double
    var stressVariability: Double
    var highStressPeriods: [StressPeriod]
    var stressFactors: [String]
    var recoveryPatterns: StressRecoveryPattern
    var stressTrends: TrendDirection
    
    static var empty: StressPatternAnalysis {
        return StressPatternAnalysis(averageStressLevel: 0.0, stressVariability: 0.0, highStressPeriods: [], stressFactors: [], recoveryPatterns: .empty, stressTrends: .stable)
    }
}

struct RecoveryPatternAnalysis: Codable {
    var avgRecoveryScore: Double
    var recoveryConsistency: Double
    var sleepRecoveryCorrelation: Double
    var optimalRecoveryConditions: [String]
    var recoveryRecommendations: [String]
    
    static var empty: RecoveryPatternAnalysis {
        return RecoveryPatternAnalysis(avgRecoveryScore: 0.0, recoveryConsistency: 0.0, sleepRecoveryCorrelation: 0.0, optimalRecoveryConditions: [], recoveryRecommendations: [])
    }
}

struct NutritionPatternAnalysis: Codable {
    var averageNutritionScore: Double
    var nutritionConsistency: Double
    var nutritionHealthCorrelation: Double
    var nutritionTrends: TrendDirection
    var nutritionRecommendations: [String]
    
    static var empty: NutritionPatternAnalysis {
        return NutritionPatternAnalysis(averageNutritionScore: 0.0, nutritionConsistency: 0.0, nutritionHealthCorrelation: 0.0, nutritionTrends: .stable, nutritionRecommendations: [])
    }
}

struct EnvironmentalImpactAnalysis: Codable {
    var temperatureStats: StatisticsResult
    var airQualityStats: StatisticsResult
    var noiseLevelStats: StatisticsResult
    var impactSummary: String
    var recommendations: [String]
}

struct CognitivePerformanceMetrics: Codable {
    var averageScore: Double
    var peakPerformanceTimes: [Int] // Hours of the day
    var consistencyScore: Double
    var improvementRate: Double
    var cognitiveFactors: [String]
}

struct PhysicalPerformanceMetrics: Codable {
    var averageScore: Double
    var peakPerformanceTimes: [Int]
    var enduranceScore: Double
    var recoveryRate: Double
    var physicalFactors: [String]
}

struct SleepPerformanceMetrics: Codable {
    var averageQuality: Double
    var averageDuration: Double
    var sleepEfficiency: Double
    var consistencyScore: Double
    var optimizationScore: Double
}

struct RecoveryPerformanceMetrics: Codable {
    var averageRecoveryScore: Double
    var recoveryRate: Double
    var optimalRecoveryConditions: [String]
    var recoveryPredictability: Double
}

struct ConsistencyScores: Codable {
    var sleep: Double
    var activity: Double
    var stress: Double
    var overall: Double
}

struct WeekdayWeekendPattern: Codable {
    var weekdayAvg: Double
    var weekendAvg: Double
    var difference: Double
    
    static var empty: WeekdayWeekendPattern {
        return WeekdayWeekendPattern(weekdayAvg: 0.0, weekendAvg: 0.0, difference: 0.0)
    }
}

struct SedentaryPeriod: Codable {
    var start: Date
    var end: Date?
}

struct StressPeriod: Codable {
    var start: Date
    var end: Date?
}

struct StressRecoveryPattern: Codable {
    var avgRecoveryTime: Double
    var recoveryEffectiveness: Double // 0-1
    
    static var empty: StressRecoveryPattern {
        return StressRecoveryPattern(avgRecoveryTime: 0.0, recoveryEffectiveness: 0.0)
    }
}

struct AbnormalReading: Codable {
    var timestamp: Date
    var value: Double
    var type: String?
}

struct VitalsTrends: Codable {
    var heartRate: TrendDirection
    var hrv: TrendDirection
    var temperature: TrendDirection
    var oxygen: TrendDirection
    
    static var empty: VitalsTrends {
        return VitalsTrends(heartRate: .stable, hrv: .stable, temperature: .stable, oxygen: .stable)
    }
}

// Placeholder for HealthData (if not already defined elsewhere)
struct HealthData: Codable {
    var heartRate: Double
    var steps: Int
    var activeEnergyBurned: Double
    // Add other relevant health data properties
}

// Placeholder for NutritionData (if not already defined elsewhere)
struct NutritionData: Codable {
    var timestamp: Date
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var nutritionScore: Double // 0-1
}

// Placeholder for HealthPredictionEngine (if not already defined elsewhere)
class HealthPredictionEngine {
    static let shared = HealthPredictionEngine()
    var predictionsStream: AsyncStream<HealthPredictions> {
        return AsyncStream { continuation in
            // Simulate real-time predictions
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                let predictions = HealthPredictions(
                    physioForecast: PhysioForecast(energyLevel: Double.random(in: 0...1), mood: Double.random(in: 0...1), recoveryScore: Double.random(in: 0...1), cognitivePerformance: Double.random(in: 0...1), sleepQuality: Double.random(in: 0...1), forecastDate: Date()),
                    confidenceScore: Double.random(in: 0.7...0.95),
                    energy: PredictionDetail(value: Double.random(in: 0...1), confidence: Double.random(in: 0.7...0.95)),
                    mood: PredictionDetail(value: Double.random(in: 0...1), confidence: Double.random(in: 0.7...0.95)),
                    recovery: PredictionDetail(value: Double.random(in: 0...1), confidence: Double.random(in: 0.7...0.95)),
                    cognitive: PredictionDetail(value: Double.random(in: 0...1), confidence: Double.random(in: 0.7...0.95))
                )
                continuation.yield(predictions)
            }.fire()
        }
    }
    var currentPredictions: HealthPredictions? // Added currentPredictions
}

struct HealthPredictions: Codable {
    var physioForecast: PhysioForecast
    var confidenceScore: Double
    var energy: PredictionDetail
    var mood: PredictionDetail
    var recovery: PredictionDetail
    var cognitive: PredictionDetail
}

struct PredictionDetail: Codable {
    var value: Double
    var confidence: Double
}

// Placeholder for AdvancedSleepAnalyzer (if not already defined elsewhere)
class AdvancedSleepAnalyzer {
    static let shared = AdvancedSleepAnalyzer()
    var sleepAnalysisStream: AsyncStream<SleepAnalysisResult> {
        return AsyncStream { continuation in
            // Simulate real-time sleep analysis
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                let sleepAnalysis = SleepAnalysisResult(
                    session: SleepSession(startTime: Date().addingTimeInterval(-8*3600), endTime: Date(), duration: 8.0, qualityScore: Double.random(in: 0.7...0.9), timeInBed: 8.5),
                    deepSleepPercentage: Double.random(in: 15...25),
                    remSleepPercentage: Double.random(in: 20...30),
                    lightSleepPercentage: Double.random(in: 40...50),
                    awakePercentage: Double.random(in: 5...10)
                )
                continuation.yield(sleepAnalysis)
            }.fire()
        }
    }
    var sleepTrendsStream: AsyncStream<TrendAnalysis> {
        return AsyncStream { continuation in
            // Simulate sleep trends
            Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                let trend = TrendAnalysis(overallTrend: .stable, vitalsTrend: .empty, sleepTrend: .improving, activityTrend: .stable, stressTrend: .stable, recoveryTrend: .stable, nutritionTrend: .stable, environmentalTrend: .stable)
                continuation.yield(trend)
            }.fire()
        }
    }
}

struct SleepAnalysisResult: Codable {
    var session: SleepSession
    var deepSleepPercentage: Double
    var remSleepPercentage: Double
    var lightSleepPercentage: Double
    var awakePercentage: Double
}

// Placeholder for CoreDataManager (if not already defined elsewhere)
// CoreDataManager is now deprecated. Use SwiftDataManager instead.
class CoreDataManager {
    static let shared = CoreDataManager()
    func fetchHealthSnapshots(limit: Int) async -> [HealthDataSnapshot] {
        // Mock data
        return (0..<limit).map { i in
            HealthDataSnapshot(
                timestamp: Date().addingTimeInterval(Double(-i * 3600 * 24)),
                restingHeartRate: Double.random(in: 50...80),
                hrv: Double.random(in: 20...100),
                activityLevel: Double.random(in: 0.1...0.9),
                stressLevel: Double.random(in: 0.1...0.9),
                sleepQuality: Double.random(in: 0.5...1.0),
                bodyTemperature: Double.random(in: 36.0...37.5),
                oxygenSaturation: Double.random(in: 95...100),
                recoveryTime: Double.random(in: 4...10),
                stressFactors: ["Work", "Family"].shuffled().prefix(Int.random(in: 0...2)).map { $0 },
                nutritionScore: Double.random(in: 0.5...1.0),
                heartRate: Double.random(in: 50...80),
                oxygen: Double.random(in: 95...100)
            )
        }
    }
    func fetchSleepSessions(limit: Int) async -> [SleepSession] {
        // Mock data
        return (0..<limit).map { i in
            SleepSession(
                startTime: Date().addingTimeInterval(Double(-i * 3600 * 24)),
                endTime: Date().addingTimeInterval(Double(-i * 3600 * 24 + 8 * 3600)),
                duration: Double.random(in: 6...9),
                qualityScore: Double.random(in: 0.6...0.9),
                timeInBed: Double.random(in: 6.5...9.5)
            )
        }
    }
    func fetchWorkouts(limit: Int) async -> [Workout] {
        // Mock data
        return (0..<limit).map { i in
            Workout(
                date: Date().addingTimeInterval(Double(-i * 3600 * 24)),
                duration: Double.random(in: 30...90),
                activityType: ["Running", "Weightlifting", "Yoga"].randomElement()!
            )
        }
    }
    func fetchNutritionData(limit: Int) async -> [NutritionData] {
        // Mock data
        return (0..<limit).map { i in
            NutritionData(
                timestamp: Date().addingTimeInterval(Double(-i * 3600 * 24)),
                calories: Double.random(in: 1500...2500),
                protein: Double.random(in: 50...150),
                carbs: Double.random(in: 100...300),
                fat: Double.random(in: 30...80),
                nutritionScore: Double.random(in: 0.6...0.9)
            )
        }
    }
    func fetchHistoricalPredictions(limit: Int) async -> [HistoricalPrediction] {
        // Mock data
        return (0..<limit).map { i in
            HistoricalPrediction(
                date: Date().addingTimeInterval(Double(-i * 3600 * 24)),
                predictedEnergy: Double.random(in: 0.5...1.0),
                predictedMood: Double.random(in: 0.5...1.0),
                predictedSleep: Double.random(in: 0.5...1.0),
                predictedCognitive: Double.random(in: 0.5...1.0)
            )
        }
    }
    func fetchActualOutcomes(limit: Int) async -> [ActualOutcome] {
        // Mock data
        return (0..<limit).map { i in
            ActualOutcome(
                date: Date().addingTimeInterval(Double(-i * 3600 * 24)),
                actualEnergy: Double.random(in: 0.5...1.0),
                actualMood: Double.random(in: 0.5...1.0),
                actualSleep: Double.random(in: 0.5...1.0),
                actualCognitive: Double.random(in: 0.5...1.0)
            )
        }
    }
}

// Placeholder for EnvironmentalDataManager (if not already defined elsewhere)
class EnvironmentalDataManager {
    func fetchEnvironmentalData(for location: String, on date: Date) async throws -> EnvironmentalData {
        // Mock data
        return EnvironmentalData(
            temperatureCelsius: Double.random(in: 10...30),
            airQualityIndex: Int.random(in: 20...80),
            timestamp: date
        )
    }
}

struct EnvironmentalData: Codable {
    var temperatureCelsius: Double?
    var airQualityIndex: Int?
    var timestamp: Date
}

// Placeholder for HealthDataProcessor (if not already defined elsewhere)
class HealthDataProcessor {
    func fetchLatestHealthData() async -> HealthData? {
        // Mock data
        return HealthData(
            heartRate: Double.random(in: 60...90),
            steps: Int.random(in: 3000...10000),
            activeEnergyBurned: Double.random(in: 200...800)
        )
    }
}

// Placeholder for TrendAnalyzer (if not already defined elsewhere)
class TrendAnalyzer {
    func analyzeTrends(data: HealthAnalysisData, window: Int) -> TrendAnalysis {
        // Placeholder implementation
        return TrendAnalysis(overallTrend: .stable, vitalsTrend: .empty, sleepTrend: .stable, activityTrend: .stable, stressTrend: .stable, recoveryTrend: .stable, nutritionTrend: .stable, environmentalTrend: .stable)
    }
}

// Placeholder for ForecastingEngine (if not already defined elsewhere)
class ForecastingEngine {
    func generateAdvancedForecast(historicalData: [HealthDataSnapshot], environmentalData: [EnvironmentSnapshot], currentPredictions: HealthPredictions, forecastHorizon: TimeInterval) -> PhysioForecast {
        // Placeholder implementation
        return PhysioForecast(energyLevel: 0.7, mood: 0.8, recoveryScore: 0.75, cognitivePerformance: 0.8, sleepQuality: 0.85, forecastDate: Date())
    }
}

// Placeholder for InsightGenerator (if not already defined elsewhere)
class InsightGenerator {
    func generateRecommendations(profile: UserProfile, analytics: HealthAnalytics?, trends: TrendAnalysis?, correlations: [CorrelationInsight]) -> [AnalyticsRecommendation] {
        // Placeholder implementation
        return [
            AnalyticsRecommendation(category: "Sleep", recommendation: "Maintain consistent sleep schedule", priority: 1),
            AnalyticsRecommendation(category: "Stress", recommendation: "Practice mindfulness for 10 minutes daily", priority: 2)
        ]
    }
}

// Placeholder for ReportGenerator (if not already defined elsewhere)
class ReportGenerator {
    // Placeholder for report generation methods
}

// Placeholder for setupRealTimeAnalytics (if not already defined elsewhere)
func setupRealTimeAnalytics() {
    // Placeholder for real-time analytics setup
}
