import Foundation
import Combine
import CoreData
import HealthKit

@available(iOS 17.0, *)
@available(macOS 14.0, *)

class AnalyticsEngine: ObservableObject {
    static let shared = AnalyticsEngine()
    
    // MARK: - Published Properties
    @Published var physioForecast: PhysioForecast?
    @Published var healthAnalytics: HealthAnalytics?
    @Published var performanceMetrics: OverallPerformanceMetrics?
    @Published var trendAnalysis: TrendAnalysis?
    @Published var correlationInsights: [CorrelationInsight] = []
    @Published var predictionAccuracy: PredictionAccuracy?
    @Published var personalizedRecommendations: [AnalyticsRecommendation] = []
    
    // MARK: - Private Properties
    private let healthPredictionEngine = HealthPredictionEngine.shared
    private let advancedSleepAnalyzer = AdvancedSleepAnalyzer.shared
    private let coreDataManager = CoreDataManager.shared
    
    private let dataProcessor: HealthDataProcessor
    private let trendAnalyzer: TrendAnalyzer
    private let correlationEngine: CorrelationEngine
    private let forecastingEngine: ForecastingEngine
    private let insightGenerator: InsightGenerator
    private let reportGenerator: ReportGenerator
    
    private var cancellables = Set<AnyCancellable>()
    private var analyticsTimer: Timer?
    
    // Analytics configuration
    private let updateInterval: TimeInterval = 300 // 5 minutes
    private let forecastHorizon: TimeInterval = 48 * 3600 // 48 hours
    private let trendAnalysisWindow: Int = 30 // 30 days
    
    private init() {
        self.dataProcessor = HealthDataProcessor()
        self.trendAnalyzer = TrendAnalyzer()
        self.correlationEngine = CorrelationEngine()
        self.forecastingEngine = ForecastingEngine()
        self.insightGenerator = InsightGenerator()
        self.reportGenerator = ReportGenerator()
        
        setupAnalyticsEngine()
        startPeriodicAnalysis()
    }
    
    // MARK: - Setup
    
    private func setupAnalyticsEngine() {
        // Subscribe to health prediction updates
        healthPredictionEngine.$currentPredictions
            .compactMap { $0 }
            .sink { [weak self] predictions in
                self?.processHealthPredictions(predictions)
            }
            .store(in: &cancellables)
        
        // Subscribe to sleep analysis updates
        advancedSleepAnalyzer.$currentSleepAnalysis
            .compactMap { $0 }
            .sink { [weak self] sleepAnalysis in
                self?.processSleepAnalysis(sleepAnalysis)
            }
            .store(in: &cancellables)
        
        // Subscribe to trend analysis updates
        advancedSleepAnalyzer.$sleepTrends
            .compactMap { $0 }
            .sink { [weak self] trends in
                self?.processSleepTrends(trends)
            }
            .store(in: &cancellables)

        // Setup real-time analytics
        setupRealTimeAnalytics()
    }
    
    private func startPeriodicAnalysis() {
        analyticsTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.performComprehensiveAnalysis()
        }
        
        // Perform initial analysis
        performComprehensiveAnalysis()
    }
    
    // MARK: - Main Analytics Processing
    
    private func performComprehensiveAnalysis() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Generate PhysioForecast
            self.generatePhysioForecast()
            
            // Analyze health trends
            self.analyzeHealthTrends()
            
            // Calculate performance metrics
            self.calculatePerformanceMetrics()
            
            // Generate correlations
            self.generateCorrelationInsights()
            
            // Validate prediction accuracy
            self.validatePredictionAccuracy()
            
            // Generate personalized recommendations
            self.generatePersonalizedRecommendations()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.updateAnalyticsResults()
            }
        }
    }
    
    // MARK: - PhysioForecast Generation
    
    private func generatePhysioForecast() {
        let historicalData = loadHistoricalHealthData()
        let currentPredictions = healthPredictionEngine.currentPredictions
        
        guard let predictions = currentPredictions else { return }
        
        // Generate advanced physiological forecasting
        let forecast = forecastingEngine.generateAdvancedForecast(
            historicalData: historicalData,
            currentPredictions: predictions,
            forecastHorizon: forecastHorizon
        )
        
        DispatchQueue.main.async {
            self.physioForecast = forecast
        }
    }
    
    // MARK: - Health Analytics
    
    private func analyzeHealthTrends() {
        let healthData = loadHealthDataForAnalysis()
        let trendAnalysis = trendAnalyzer.analyzeTrends(
            data: healthData,
            window: trendAnalysisWindow
        )
        
        let healthAnalytics = HealthAnalytics(
            overallHealthScore: calculateOverallHealthScore(healthData),
            vitalsAnalysis: analyzeVitals(healthData),
            sleepAnalysis: analyzeSleepPatterns(healthData),
            activityAnalysis: analyzeActivityPatterns(healthData),
            stressAnalysis: analyzeStressPatterns(healthData),
            recoveryAnalysis: analyzeRecoveryPatterns(healthData),
            nutritionAnalysis: analyzeNutritionPatterns(healthData),
            trendSummary: trendAnalysis,
            lastUpdated: Date()
        )
        
        DispatchQueue.main.async {
            self.healthAnalytics = healthAnalytics
            self.trendAnalysis = trendAnalysis
        }
    }
    
    // MARK: - Performance Metrics
    
    private func calculatePerformanceMetrics() {
        let recentData = loadRecentPerformanceData()
        
        let metrics = PerformanceMetrics(
            cognitivePerformance: calculateCognitiveMetrics(recentData),
            physicalPerformance: calculatePhysicalMetrics(recentData),
            sleepPerformance: calculateSleepMetrics(recentData),
            recoveryPerformance: calculateRecoveryMetrics(recentData),
            consistencyScores: calculateConsistencyScores(recentData),
            improvementAreas: identifyImprovementAreas(recentData),
            achievements: identifyAchievements(recentData),
            lastCalculated: Date()
        )
        
        DispatchQueue.main.async {
            self.performanceMetrics = metrics
        }
    }
    
    // MARK: - Correlation Analysis
    
    private func generateCorrelationInsights() {
        let correlationData = loadCorrelationAnalysisData()
        let insights = correlationEngine.analyzeCorrelations(correlationData)
        
        DispatchQueue.main.async {
            self.correlationInsights = insights
        }
    }
    
    // MARK: - Prediction Accuracy Validation
    
    private func validatePredictionAccuracy() {
        let historicalPredictions = loadHistoricalPredictions()
        let actualOutcomes = loadActualOutcomes()
        
        let accuracy = PredictionAccuracy(
            overallAccuracy: calculateOverallAccuracy(historicalPredictions, actualOutcomes),
            energyPredictionAccuracy: calculateEnergyAccuracy(historicalPredictions, actualOutcomes),
            moodPredictionAccuracy: calculateMoodAccuracy(historicalPredictions, actualOutcomes),
            sleepPredictionAccuracy: calculateSleepAccuracy(historicalPredictions, actualOutcomes),
            cognitiveAccuracy: calculateCognitiveAccuracy(historicalPredictions, actualOutcomes),
            modelConfidence: calculateModelConfidence(),
            lastValidated: Date()
        )
        
        DispatchQueue.main.async {
            self.predictionAccuracy = accuracy
        }
    }
    
    // MARK: - Personalized Recommendations
    
    private func generatePersonalizedRecommendations() {
        let userProfile = createUserProfile()
        let recommendations = insightGenerator.generateRecommendations(
            profile: userProfile,
            analytics: healthAnalytics,
            trends: trendAnalysis,
            correlations: correlationInsights
        )
        
        DispatchQueue.main.async {
            self.personalizedRecommendations = recommendations
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadHistoricalHealthData() -> [HealthDataSnapshot] {
        return coreDataManager.fetchHealthSnapshots(limit: 1000)
    }
    
    private func loadHealthDataForAnalysis() -> HealthAnalysisData {
        let snapshots = loadHistoricalHealthData()
        let sleepSessions = coreDataManager.fetchSleepSessions(limit: 100)
        let workouts = coreDataManager.fetchWorkouts(limit: 200)
        
        return HealthAnalysisData(
            healthSnapshots: snapshots,
            sleepSessions: sleepSessions,
            workouts: workouts,
            timeRange: DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date())
        )
    }
    
    private func loadRecentPerformanceData() -> PerformanceAnalysisData {
        let recentSnapshots = Array(loadHistoricalHealthData().prefix(168)) // Last week
        let recentSleep = Array(coreDataManager.fetchSleepSessions(limit: 14).prefix(7)) // Last week
        
        return PerformanceAnalysisData(
            healthSnapshots: recentSnapshots,
            sleepSessions: recentSleep,
            analysisWindow: 7
        )
    }
    
    private func loadCorrelationAnalysisData() -> CorrelationAnalysisData {
        let healthData = loadHistoricalHealthData()
        let sleepData = coreDataManager.fetchSleepSessions(limit: 50)
        let environmentData = loadEnvironmentData()
        
        return CorrelationAnalysisData(
            healthSnapshots: healthData,
            sleepSessions: sleepData,
            environmentData: environmentData,
            correlationWindow: 30
        )
    }
    
    private func loadEnvironmentData() -> [EnvironmentSnapshot] {
        return coreDataManager.fetchEnvironmentSnapshots(limit: 200)
    }
    
    private func loadHistoricalPredictions() -> [HistoricalPrediction] {
        return coreDataManager.fetchHistoricalPredictions(limit: 100)
    }
    
    private func loadActualOutcomes() -> [ActualOutcome] {
        return coreDataManager.fetchActualOutcomes(limit: 100)
    }
    
    // MARK: - Analysis Methods
    
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
            optimizationScore: calculateSleepOptimizationScore(sleepSessions)
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
    
    private func createUserProfile() -> UserProfile {
        let healthData = loadHistoricalHealthData()
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
    private func calculateTimeConsistency(_ times: [Date]) -> Double { return 0.8 }
    private func calculateSleepEfficiency(_ sessions: [SleepSession]) -> Double { return 0.85 }
    private func analyzeWeekdayWeekendPattern(_ sessions: [SleepSession]) -> WeekdayWeekendPattern {
        return WeekdayWeekendPattern(weekdayAvg: 8.0, weekendAvg: 8.5, difference: 0.5)
    }
    private func calculateWorkoutFrequency(_ workouts: [Workout]) -> Double { return 4.0 }
    private func analyzeWorkoutTiming(_ workouts: [Workout]) -> [Int] { return [7, 18] }
    private func calculateActivityTrends(_ snapshots: [HealthDataSnapshot]) -> TrendDirection { return .stable }
    private func identifySedentaryPeriods(_ snapshots: [HealthDataSnapshot]) -> [SedentaryPeriod] { return [] }
    private func identifyHighStressPeriods(_ snapshots: [HealthDataSnapshot]) -> [StressPeriod] { return [] }
    private func identifyStressFactors(_ snapshots: [HealthDataSnapshot]) -> [String] { return ["Work Pressure"] }
    private func analyzeStressRecovery(_ snapshots: [HealthDataSnapshot]) -> StressRecoveryPattern {
        return StressRecoveryPattern(avgRecoveryTime: 2.0, recoveryEffectiveness: 0.8)
    }
    private func calculateStressTrends(_ snapshots: [HealthDataSnapshot]) -> TrendDirection { return .stable }
    private func calculateVitalsStability(_ snapshots: [HealthDataSnapshot]) -> Double { return 0.8 }
    private func identifyAbnormalVitals(_ snapshots: [HealthDataSnapshot]) -> [AbnormalReading] { return [] }
    private func calculateVitalsTrends(_ snapshots: [HealthDataSnapshot]) -> VitalsTrends {
        return VitalsTrends(heartRate: .stable, hrv: .improving, temperature: .stable, oxygen: .stable)
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
    
    private func processHealthPredictions(_ predictions: HealthPredictions) {
        // Process new health predictions for analytics
        print("AnalyticsEngine: Processing health predictions")
    }
    
    private func processSleepAnalysis(_ sleepAnalysis: SleepAnalysisResult) {
        // Process new sleep analysis for analytics
        print("AnalyticsEngine: Processing sleep analysis")
    }
    
    private func processSleepTrends(_ trends: SleepTrendAnalysis) {
        // Process sleep trends for analytics
        print("AnalyticsEngine: Processing sleep trends")
    }
    
    private func updateAnalyticsResults() {
        // Update analytics results on main thread
        print("AnalyticsEngine: Analytics updated at \(Date())")
    }
    
    // MARK: - Public Interface
    
    func refreshAnalytics() {
        performComprehensiveAnalysis()
    }
    
    func getAnalyticsReport(timeRange: DateInterval) -> AnalyticsReport {
        return reportGenerator.generateReport(
            timeRange: timeRange,
            analytics: healthAnalytics,
            forecast: physioForecast,
            performance: performanceMetrics,
            correlations: correlationInsights
        )
    }
    
    func exportAnalyticsData(format: ExportFormat) -> Data? {
        return reportGenerator.exportData(
            analytics: healthAnalytics,
            forecast: physioForecast,
            format: format
        )
    }
}

// MARK: - Supporting Types

struct HealthAnalytics {
    let overallHealthScore: Double
    let vitalsAnalysis: VitalsAnalysis
    let sleepAnalysis: SleepPatternAnalysis
    let activityAnalysis: ActivityPatternAnalysis
    let stressAnalysis: StressPatternAnalysis
    let recoveryAnalysis: RecoveryPatternAnalysis
    let nutritionAnalysis: NutritionPatternAnalysis
    let trendSummary: TrendAnalysis
    let lastUpdated: Date
}

struct OverallPerformanceMetrics {
    let cognitivePerformance: CognitivePerformanceMetrics
    let physicalPerformance: PhysicalPerformanceMetrics
    let sleepPerformance: SleepPerformanceMetrics
    let recoveryPerformance: RecoveryPerformanceMetrics
    let consistencyScores: ConsistencyScores
    let improvementAreas: [String]
    let achievements: [String]
    let lastCalculated: Date
}

struct PredictionAccuracy {
    let overallAccuracy: Double
    let energyPredictionAccuracy: Double
    let moodPredictionAccuracy: Double
    let sleepPredictionAccuracy: Double
    let cognitiveAccuracy: Double
    let modelConfidence: Double
    let lastValidated: Date
}

struct AnalyticsRecommendation {
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
    let expectedBenefit: String
    let timeframe: String
}

enum RecommendationCategory {
    case sleep
    case activity
    case nutrition
    case stress
    case recovery
    case performance
}

struct UserProfile {
    let averageSleepQuality: Double
    let averageActivityLevel: Double
    let averageStressLevel: Double
    let healthGoals: [String]
    let preferences: [String]
    let constraints: [String]
}

// Additional supporting types would be defined here...
struct HealthAnalysisData {
    let healthSnapshots: [HealthDataSnapshot]
    let sleepSessions: [SleepSession]
    let workouts: [Workout]
    let timeRange: DateInterval
}

struct PerformanceAnalysisData {
    let healthSnapshots: [HealthDataSnapshot]
    let sleepSessions: [SleepSession]
    let analysisWindow: Int
}

struct CorrelationAnalysisData {
    let healthSnapshots: [HealthDataSnapshot]
    let sleepSessions: [SleepSession]
    let environmentData: [EnvironmentSnapshot]
    let correlationWindow: Int
}

struct VitalsAnalysis {
    let heartRateStats: StatisticsResult
    let hrvStats: StatisticsResult
    let temperatureStats: StatisticsResult
    let oxygenSaturationStats: StatisticsResult
    let vitalsStability: Double
    let abnormalReadings: [AbnormalReading]
    let trends: VitalsTrends
}

struct SleepPatternAnalysis {
    let averageDuration: Double
    let durationConsistency: Double
    let averageQuality: Double
    let qualityTrend: TrendDirection
    let bedtimeConsistency: Double
    let wakeTimeConsistency: Double
    let sleepEfficiency: Double
    let weekdayWeekendPattern: WeekdayWeekendPattern
}

struct ActivityPatternAnalysis {
    let averageActivityLevel: Double
    let activityConsistency: Double
    let workoutFrequency: Double
    let preferredWorkoutTimes: [Int]
    let activityTrends: TrendDirection
    let sedentaryPeriods: [SedentaryPeriod]
}

struct StressPatternAnalysis {
    let averageStressLevel: Double
    let stressVariability: Double
    let highStressPeriods: [StressPeriod]
    let stressFactors: [String]
    let recoveryPatterns: StressRecoveryPattern
    let stressTrends: TrendDirection
}

struct RecoveryPatternAnalysis {
    let avgRecoveryScore: Double
    let recoveryConsistency: Double
    let sleepRecoveryCorrelation: Double
    let optimalRecoveryConditions: [String]
    let recoveryRecommendations: [String]
}

struct NutritionPatternAnalysis {
    let averageNutritionScore: Double
    let nutritionConsistency: Double
    let nutritionHealthCorrelation: Double
    let nutritionTrends: TrendDirection
    let nutritionRecommendations: [String]
}

struct CognitivePerformanceMetrics {
    let averageScore: Double
    let peakPerformanceTimes: [Int]
    let consistencyScore: Double
    let improvementRate: Double
    let cognitiveFactors: [String]
}

struct PhysicalPerformanceMetrics {
    let averageScore: Double
    let peakPerformanceTimes: [Int]
    let enduranceScore: Double
    let recoveryRate: Double
    let physicalFactors: [String]
}

struct SleepPerformanceMetrics {
    let averageQuality: Double
    let averageDuration: Double
    let sleepEfficiency: Double
    let consistencyScore: Double
    let optimizationScore: Double
}

struct RecoveryPerformanceMetrics {
    let averageRecoveryScore: Double
    let recoveryRate: Double
    let optimalRecoveryConditions: [String]
    let recoveryPredictability: Double
}

struct ConsistencyScores {
    let sleep: Double
    let activity: Double
    let stress: Double
    let overall: Double
}

struct StatisticsResult {
    let mean: Double
    let median: Double
    let std: Double
    let min: Double
    let max: Double
}

// Placeholder supporting types
struct TrendAnalysis { let placeholder: String = "" }
struct CorrelationInsight { let placeholder: String = "" }
struct EnvironmentSnapshot { let placeholder: String = "" }
struct HistoricalPrediction { let placeholder: String = "" }
struct ActualOutcome { let placeholder: String = "" }
struct WeekdayWeekendPattern { let weekdayAvg: Double; let weekendAvg: Double; let difference: Double }
struct SedentaryPeriod { let placeholder: String = "" }
struct StressPeriod { let placeholder: String = "" }
struct StressRecoveryPattern { let avgRecoveryTime: Double; let recoveryEffectiveness: Double }
struct AbnormalReading { let placeholder: String = "" }
struct VitalsTrends { let heartRate: TrendDirection; let hrv: TrendDirection; let temperature: TrendDirection; let oxygen: TrendDirection }
struct AnalyticsReport { let placeholder: String = "" }

enum ExportFormat { case json, csv, pdf }

// MARK: - Supporting Types from RealTimeAnalytics.swift
import UIKit
import CoreGraphics
import QuartzCore

struct PerformanceMetrics {
    var timestamp: Date = Date()
    var frameRate: Double = 60.0
    var memoryUsage: Double = 0.0
    var cpuUsage: Double = 0.0
    var batteryLevel: Double = 100.0
    var networkUsage: Double = 0.0
    var responseTime: Double = 0.0
    var appState: AppState = .active
}

struct PerformanceAlert: Identifiable, Codable {
    let id: UUID
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let timestamp: Date
    let currentValue: Double
    let threshold: Double
}

struct PerformanceInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let timestamp: Date
    let recommendations: [String]
}

struct AnalyticsReport {
    let currentMetrics: PerformanceMetrics
    let historicalMetrics: [PerformanceMetrics]
    let alerts: [PerformanceAlert]
    let insights: [PerformanceInsight]
    let summary: AnalyticsSummary
}

struct AnalyticsSummary {
    let averageFrameRate: Double
    let averageMemoryUsage: Double
    let averageCPUUsage: Double
    let performanceScore: Double
    let totalAlerts: Int
    let totalInsights: Int
    let monitoringDuration: TimeInterval
}

struct MetricsExportData: Codable {
    let metrics: [PerformanceMetrics]
    let alerts: [PerformanceAlert]
    let insights: [PerformanceInsight]
    let exportDate: Date
}

enum AlertType: String, Codable {
    case lowFrameRate, highMemoryUsage, highCPUUsage, lowBatteryLevel, highNetworkUsage, slowResponseTime
}

enum AlertSeverity: String, Codable {
    case low, warning, critical
}

enum InsightType: String, Codable {
    case performance, memory, cpu, battery, network, optimization
}

enum InsightSeverity: String, Codable {
    case info, warning, critical
}

enum AppState: String, Codable {
    case active, background, inactive
}

// MARK: - Insight Generators

protocol InsightGenerator {
    func generateInsight(from metrics: [PerformanceMetrics]) async -> PerformanceInsight?
}

class FrameRateInsightGenerator: InsightGenerator {
    func generateInsight(from metrics: [PerformanceMetrics]) async -> PerformanceInsight? {
        guard metrics.count >= 10 else { return nil }
        
        let recentMetrics = Array(metrics.suffix(10))
        let avgFrameRate = recentMetrics.map { $0.frameRate }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgFrameRate < 55.0 {
            return PerformanceInsight(
                id: UUID(),
                type: .performance,
                title: "Frame Rate Optimization",
                description: "Average frame rate is below optimal levels",
                severity: .warning,
                timestamp: Date(),
                recommendations: [
                    "Reduce animation complexity",
                    "Optimize view rendering",
                    "Check for memory pressure"
                ]
            )
        }
        
        return nil
    }
}

class MemoryInsightGenerator: InsightGenerator {
    func generateInsight(from metrics: [PerformanceMetrics]) async -> PerformanceInsight? {
        guard metrics.count >= 10 else { return nil }
        
        let recentMetrics = Array(metrics.suffix(10))
        let avgMemoryUsage = recentMetrics.map { $0.memoryUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgMemoryUsage > 400.0 {
            return PerformanceInsight(
                id: UUID(),
                type: .memory,
                title: "Memory Optimization",
                description: "Memory usage is consistently high",
                severity: .warning,
                timestamp: Date(),
                recommendations: [
                    "Clear image caches",
                    "Release unused resources",
                    "Optimize data structures"
                ]
            )
        }
        
        return nil
    }
}

class CPUInsightGenerator: InsightGenerator {
    func generateInsight(from metrics: [PerformanceMetrics]) async -> PerformanceInsight? {
        guard metrics.count >= 10 else { return nil }
        
        let recentMetrics = Array(metrics.suffix(10))
        let avgCPUUsage = recentMetrics.map { $0.cpuUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgCPUUsage > 70.0 {
            return PerformanceInsight(
                id: UUID(),
                type: .cpu,
                title: "CPU Optimization",
                description: "CPU usage is consistently high",
                severity: .warning,
                timestamp: Date(),
                recommendations: [
                    "Optimize background tasks",
                    "Reduce computational load",
                    "Use efficient algorithms"
                ]
            )
        }
        
        return nil
    }
}

class BatteryInsightGenerator: InsightGenerator {
    func generateInsight(from metrics: [PerformanceMetrics]) async -> PerformanceInsight? {
        guard metrics.count >= 10 else { return nil }
        
        let recentMetrics = Array(metrics.suffix(10))
        let avgBatteryLevel = recentMetrics.map { $0.batteryLevel }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgBatteryLevel < 30.0 {
            return PerformanceInsight(
                id: UUID(),
                type: .battery,
                title: "Battery Optimization",
                description: "Battery level is low",
                severity: .warning,
                timestamp: Date(),
                recommendations: [
                    "Reduce background processing",
                    "Optimize network usage",
                    "Lower screen brightness"
                ]
            )
        }
        
        return nil
    }
}

class NetworkInsightGenerator: InsightGenerator {
    func generateInsight(from metrics: [PerformanceMetrics]) async -> PerformanceInsight? {
        guard metrics.count >= 10 else { return nil }
        
        let recentMetrics = Array(metrics.suffix(10))
        let avgNetworkUsage = recentMetrics.map { $0.networkUsage }.reduce(0, +) / Double(recentMetrics.count)
        
        if avgNetworkUsage > 50.0 {
            return PerformanceInsight(
                id: UUID(),
                type: .network,
                title: "Network Optimization",
                description: "Network usage is high",
                severity: .info,
                timestamp: Date(),
                recommendations: [
                    "Implement caching",
                    "Optimize API calls",
                    "Use compression"
                ]
            )
        }
        
        return nil
    }
}

// MARK: - Real-time analytics properties and methods
import UIKit
import CoreGraphics
import QuartzCore

extension AnalyticsEngine {
    // Published properties for real-time metrics
    @Published var currentMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var historicalMetrics: [PerformanceMetrics] = []
    @Published var alerts: [PerformanceAlert] = []
    @Published var insights: [PerformanceInsight] = []
    @Published var isMonitoring: Bool = false
    @Published var monitoringInterval: TimeInterval = 1.0

    // Private properties for real-time monitoring
    private var displayLink: CADisplayLink?
    private var monitoringTimer: Timer?
    private var metricsHistory: [PerformanceMetrics] = []
    private var alertThresholds: [AlertType: Double] = [:]
    private var lastAlertTime: [AlertType: Date] = [:]
    private var insightGenerators: [InsightGenerator] = []

    // Configuration for real-time monitoring
    private let maxHistorySize = 1000
    private let alertCooldown: TimeInterval = 30.0

    // Setup for real-time analytics
    private func setupRealTimeAnalytics() {
        setupDisplayLink()
        setupMonitoringTimer()
        setupPerformanceSubscriptions()
        setupAlertThresholds()
        setupInsightGenerators()
        Logger.success("Real-time analytics initialized", log: Logger.performance)
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameMetrics))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func setupMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemMetrics()
            }
        }
    }

    private func setupPerformanceSubscriptions() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleMemoryWarning()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppStateChange(.active)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppStateChange(.background)
                }
            }
            .store(in: &cancellables)
    }

    private func setupAlertThresholds() {
        alertThresholds = [
            .lowFrameRate: 55.0,
            .highMemoryUsage: 400.0, // MB
            .highCPUUsage: 80.0,
            .lowBatteryLevel: 20.0,
            .highNetworkUsage: 100.0, // MB
            .slowResponseTime: 100.0 // ms
        ]
    }

    private func setupInsightGenerators() {
        insightGenerators = [
            FrameRateInsightGenerator(),
            MemoryInsightGenerator(),
            CPUInsightGenerator(),
            BatteryInsightGenerator(),
            NetworkInsightGenerator()
        ]
    }

    // Monitoring Control
    func startMonitoring() {
        isMonitoring = true
        displayLink?.isPaused = false
        monitoringTimer?.invalidate()
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemMetrics()
            }
        }
        Logger.info("Real-time monitoring started", log: Logger.performance)
    }

    func stopMonitoring() {
        isMonitoring = false
        displayLink?.isPaused = true
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        Logger.info("Real-time monitoring stopped", log: Logger.performance)
    }

    func setMonitoringInterval(_ interval: TimeInterval) {
        monitoringInterval = interval
        monitoringTimer?.invalidate()
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemMetrics()
            }
        }
    }

    // Metrics Collection
    @objc private func updateFrameMetrics() {
        guard isMonitoring else { return }
        if let displayLink = displayLink {
            let fps = 1.0 / displayLink.duration
            currentMetrics.frameRate = fps
        }
    }

    private func updateSystemMetrics() async {
        currentMetrics.memoryUsage = getCurrentMemoryUsage()
        currentMetrics.cpuUsage = getCurrentCPUUsage()
        currentMetrics.batteryLevel = getCurrentBatteryLevel()
        currentMetrics.networkUsage = await getCurrentNetworkUsage()
        currentMetrics.responseTime = await measureResponseTime()
        currentMetrics.timestamp = Date()
        addMetricsToHistory(currentMetrics)
        await checkForAlerts()
        await generateInsights()
    }

    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_(),
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
            return min(memoryUsageMB / 1000.0, 1.0)
        }
        return 0.3
    }

    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_(),
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return Double(info.user_time.seconds) / 100.0
        }
        return 0.25
    }

    private func getCurrentBatteryLevel() -> Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        return batteryLevel >= 0 ? batteryLevel : 0.5
    }

    private func getCurrentNetworkUsage() async -> Double {
        let networkLatency = getCurrentNetworkLatency()
        let networkQuality = getCurrentNetworkQuality()
        let networkUsage = (networkLatency * 0.6 + networkQuality * 0.4)
        return networkUsage
    }

    private func getCurrentNetworkLatency() -> Double {
        // Placeholder for actual network ping test
        // Assuming Reachability is available or a custom implementation exists
        // For now, return a realistic value based on connection type
        // This requires a Reachability class or similar implementation.
        // For now, a dummy value.
        return 0.2
    }

    private func getCurrentNetworkQuality() -> Double {
        // Placeholder for actual bandwidth testing
        // For now, return a realistic value based on connection type
        // This requires a Reachability class or similar implementation.
        // For now, a dummy value.
        return 0.6
    }

    private func measureResponseTime() async -> Double {
        let startTime = Date()
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        let endTime = Date()
        return endTime.timeIntervalSince(startTime) * 1000
    }

    // History Management
    private func addMetricsToHistory(_ metrics: PerformanceMetrics) {
        metricsHistory.append(metrics)
        if metricsHistory.count > maxHistorySize {
            metricsHistory.removeFirst()
        }
        historicalMetrics = Array(metricsHistory.suffix(100))
    }

    // Alert System
    private func checkForAlerts() async {
        for (alertType, threshold) in alertThresholds {
            if shouldTriggerAlert(alertType: alertType, threshold: threshold) {
                await triggerAlert(alertType: alertType, currentValue: getCurrentValue(for: alertType))
            }
        }
    }

    private func shouldTriggerAlert(alertType: AlertType, threshold: Double) -> Bool {
        let currentValue = getCurrentValue(for: alertType)
        let lastAlert = lastAlertTime[alertType] ?? Date.distantPast
        guard Date().timeIntervalSince(lastAlert) >= alertCooldown else {
            return false
        }
        switch alertType {
        case .lowFrameRate:
            return currentValue < threshold
        case .highMemoryUsage, .highCPUUsage, .highNetworkUsage, .slowResponseTime:
            return currentValue > threshold
        case .lowBatteryLevel:
            return currentValue < threshold
        }
    }

    private func getCurrentValue(for alertType: AlertType) -> Double {
        switch alertType {
        case .lowFrameRate:
            return currentMetrics.frameRate
        case .highMemoryUsage:
            return currentMetrics.memoryUsage
        case .highCPUUsage:
            return currentMetrics.cpuUsage
        case .lowBatteryLevel:
            return currentMetrics.batteryLevel
        case .highNetworkUsage:
            return currentMetrics.networkUsage
        case .slowResponseTime:
            return currentMetrics.responseTime
        }
    }

    private func triggerAlert(alertType: AlertType, currentValue: Double) async {
        let alert = PerformanceAlert(
            id: UUID(),
            type: alertType,
            severity: getAlertSeverity(alertType: alertType, value: currentValue),
            message: getAlertMessage(alertType: alertType, value: currentValue),
            timestamp: Date(),
            currentValue: currentValue,
            threshold: alertThresholds[alertType] ?? 0.0
        )
        await MainActor.run {
            alerts.append(alert)
            lastAlertTime[alertType] = Date()
        }
        Logger.warning("Performance alert: \(alert.message)", log: Logger.performance)
    }

    private func getAlertSeverity(alertType: AlertType, value: Double) -> AlertSeverity {
        let threshold = alertThresholds[alertType] ?? 0.0
        switch alertType {
        case .lowFrameRate:
            return value < threshold * 0.8 ? .critical : .warning
        case .highMemoryUsage, .highCPUUsage:
            return value > threshold * 1.2 ? .critical : .warning
        case .lowBatteryLevel:
            return value < threshold * 0.5 ? .critical : .warning
        case .highNetworkUsage, .slowResponseTime:
            return value > threshold * 1.5 ? .critical : .warning
        }
    }

    private func getAlertMessage(alertType: AlertType, value: Double) -> String {
        switch alertType {
        case .lowFrameRate:
            return "Frame rate is low: \(String(format: "%.1f", value)) FPS"
        case .highMemoryUsage:
            return "Memory usage is high: \(String(format: "%.1f", value)) MB"
        case .highCPUUsage:
            return "CPU usage is high: \(String(format: "%.1f", value))%"
        case .lowBatteryLevel:
            return "Battery level is low: \(String(format: "%.1f", value))%"
        case .highNetworkUsage:
            return "Network usage is high: \(String(format: "%.1f", value)) MB"
        case .slowResponseTime:
            return "Response time is slow: \(String(format: "%.1f", value)) ms"
        }
    }

    // Insight Generation
    private func generateInsights() async {
        var newInsights: [PerformanceInsight] = []
        for generator in insightGenerators {
            if let insight = await generator.generateInsight(from: metricsHistory) {
                newInsights.append(insight)
            }
        }
        await MainActor.run {
            insights = newInsights
        }
    }

    // Event Handlers
    private func handleMemoryWarning() async {
        let alert = PerformanceAlert(
            id: UUID(),
            type: .highMemoryUsage,
            severity: .critical,
            message: "Memory warning received from system",
            timestamp: Date(),
            currentValue: currentMetrics.memoryUsage,
            threshold: alertThresholds[.highMemoryUsage] ?? 0.0
        )
        await MainActor.run {
            alerts.append(alert)
        }
        Logger.warning("Memory warning handled", log: Logger.performance)
    }

    private func handleAppStateChange(_ state: AppState) async {
        currentMetrics.appState = state
        Logger.info("App state changed to: \(state)", log: Logger.performance)
    }

    // Analytics Reports
    func generateAnalyticsReport() -> AnalyticsReport {
        let report = AnalyticsReport(
            currentMetrics: currentMetrics,
            historicalMetrics: historicalMetrics,
            alerts: alerts,
            insights: insights,
            summary: generateSummary()
        )
        return report
    }

    private func generateSummary() -> AnalyticsSummary {
        let avgFrameRate = historicalMetrics.map { $0.frameRate }.reduce(0, +) / Double(max(historicalMetrics.count, 1))
        let avgMemoryUsage = historicalMetrics.map { $0.memoryUsage }.reduce(0, +) / Double(max(historicalMetrics.count, 1))
        let avgCPUUsage = historicalMetrics.map { $0.cpuUsage }.reduce(0, +) / Double(max(historicalMetrics.count, 1))
        let performanceScore = calculatePerformanceScore()
        return AnalyticsSummary(
            averageFrameRate: avgFrameRate,
            averageMemoryUsage: avgMemoryUsage,
            averageCPUUsage: avgCPUUsage,
            performanceScore: performanceScore,
            totalAlerts: alerts.count,
            totalInsights: insights.count,
            monitoringDuration: Date().timeIntervalSince(historicalMetrics.first?.timestamp ?? Date())
        )
    }

    private func calculatePerformanceScore() -> Double {
        let frameRateScore = min(currentMetrics.frameRate / 60.0, 1.0) * 0.4
        let memoryScore = max(0, 1.0 - currentMetrics.memoryUsage / 1000.0) * 0.3
        let cpuScore = max(0, 1.0 - currentMetrics.cpuUsage / 100.0) * 0.3
        return frameRateScore + memoryScore + cpuScore
    }

    // Data Export
    func exportMetricsData() -> Data? {
        let exportData = MetricsExportData(
            metrics: historicalMetrics,
            alerts: alerts,
            insights: insights,
            exportDate: Date()
        )
        return try? JSONEncoder().encode(exportData)
    }

    private func calculateRealTimeMetrics() -> Double {
        let cpuUsage = getCurrentCPUUsage()
        let memoryUsage = getCurrentMemoryUsage()
        let networkLatency = getCurrentNetworkLatency()
        let performanceScore = (cpuUsage * 0.4 + memoryUsage * 0.3 + networkLatency * 0.3)
        return performanceScore
    }

    private func calculateSystemHealth() -> Double {
        let batteryLevel = getCurrentBatteryLevel()
        let thermalState = getCurrentThermalState()
        let storageSpace = getAvailableStorageSpace()
        let healthScore = (batteryLevel * 0.4 + thermalState * 0.3 + storageSpace * 0.3)
        return healthScore
    }

    private func getCurrentThermalState() -> Double {
        if #available(iOS 11.0, *) {
            let thermalState = ProcessInfo.processInfo.thermalState
            switch thermalState {
            case .nominal:
                return 1.0
            case .fair:
                return 0.8
            case .serious:
                return 0.5
            case .critical:
                return 0.2
            @unknown default:
                return 0.7
            }
        }
        return 0.8
    }

    private func getAvailableStorageSpace() -> Double {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0.5
        }
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path.path)
            let freeSpace = attributes[.systemFreeSize] as? NSNumber
            let totalSpace = attributes[.systemSize] as? NSNumber
            if let free = freeSpace?.doubleValue, let total = totalSpace?.doubleValue {
                return free / total
            }
        } catch {
            Logger.error("Failed to get storage space: \(error.localizedDescription)", log: Logger.analytics)
        }
        return 0.6
    }
}