import Foundation
import HealthKit
import Combine
import CoreML

class PredictiveAnalyticsManager: ObservableObject {
    static let shared = PredictiveAnalyticsManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published var physioForecast: PhysioForecast = PhysioForecast()
    @Published var flowWindows: [FlowWindow] = []
    @Published var volatilityRadar: VolatilityRadar = VolatilityRadar()
    @Published var healthAlerts: [HealthAlert] = []
    @Published var dailyInsights: [HealthInsight] = []
    @Published var activeAlerts: [PrioritizedAlertWithExplanation] = []
    @Published var lastAlertTime: Date?
    
    // Analytics engine
    private var analyticsEngine: AnalyticsEngine?
    private var digitalTwin: DigitalTwinSimulator?
    
    private init() {
        setupAnalyticsEngine()
        setupDigitalTwin()
        startPredictiveAnalysis()
    }
    
    // MARK: - Setup
    
    private func setupAnalyticsEngine() {
        analyticsEngine = AnalyticsEngine()
    }
    
    private func setupDigitalTwin() {
        digitalTwin = DigitalTwinSimulator()
    }
    
    private func startPredictiveAnalysis() {
        // Start periodic predictive analysis
        Timer.publish(every: 1800, on: .main, in: .common) // Every 30 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.performPredictiveAnalysis()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - PhysioForecast Generation
    
    private func performPredictiveAnalysis() {
        generatePhysioForecast()
        detectFlowWindows()
        updateVolatilityRadar()
        generateDailyInsights()
        checkForHealthAlerts()
    }
    
    private func generatePhysioForecast() {
        // Generate next-day PhysioForecast
        let healthData = collectCurrentHealthData()
        let baselineData = loadBaselineData()
        
        let forecast = analyticsEngine?.generatePhysioForecast(
            currentData: healthData,
            baselineData: baselineData
        ) ?? PhysioForecast()
        
        DispatchQueue.main.async {
            self.physioForecast = forecast
        }
    }
    
    private func collectCurrentHealthData() -> HealthDataSnapshot {
        let healthManager = HealthDataManager.shared
        
        return HealthDataSnapshot(
            heartRate: healthManager.currentHeartRate,
            hrv: healthManager.currentHRV,
            oxygenSaturation: healthManager.currentOxygenSaturation,
            bodyTemperature: healthManager.currentBodyTemperature,
            stepCount: healthManager.stepCount,
            activeEnergyBurned: healthManager.activeEnergyBurned,
            sleepData: healthManager.sleepData,
            timestamp: Date()
        )
    }
    
    private func loadBaselineData() -> BaselineHealthData {
        // Load 3-year baseline data from Core Data
        return CoreDataManager.shared.loadBaselineHealthData()
    }
    
    // MARK: - Flow Window Detection
    
    private func detectFlowWindows() {
        let healthData = collectCurrentHealthData()
        let detectedWindows = analyticsEngine?.detectFlowWindows(healthData: healthData) ?? []
        
        DispatchQueue.main.async {
            self.flowWindows = detectedWindows
        }
    }
    
    // MARK: - Volatility Radar
    
    private func updateVolatilityRadar() {
        let healthData = collectCurrentHealthData()
        let volatility = analyticsEngine?.calculateVolatility(healthData: healthData) ?? VolatilityRadar()
        
        DispatchQueue.main.async {
            self.volatilityRadar = volatility
        }
    }
    
    // MARK: - Health Alerts
    
    private func checkForHealthAlerts() {
        print("PredictiveAnalyticsManager: Checking for health alerts.")
        
        // Collect current health data
        let healthData = collectCurrentHealthData()
        
        // Create metrics dictionary for rule evaluation
        let metrics: [String: Double] = [
            "sleep_quality": SleepOptimizationManager.shared.sleepQuality * 100,
            "heart_rate": healthData.heartRate,
            "hrv": healthData.hrv,
            "ecg_ischemia_risk": calculateIschemiaRisk(healthData: healthData),
            "af_overall_risk": calculateAFRisk(healthData: healthData),
            "qt_dynamic_risk": calculateQTRisk(healthData: healthData)
        ]
        
        // Evaluate alerts using rule engine
        let triggeredAlerts = AlertRuleEngine.shared.evaluate(metrics: metrics)
        
        // Create alert context
        let context = AlertContext(
            confidenceByMetric: [
                "sleep_quality": 0.9,
                "heart_rate": 0.95,
                "hrv": 0.9,
                "ecg_ischemia_risk": 0.8
            ],
            recentAlertCounts: [:],
            isNightTime: Calendar.current.component(.hour, from: Date()) >= 22 || Calendar.current.component(.hour, from: Date()) <= 6
        )
        
        // Prioritize alerts
        let prioritizedAlerts = AlertPrioritizer.shared.prioritize(alerts: triggeredAlerts, context: context)
        
        // Convert to health alerts and update UI
        let healthAlerts = prioritizedAlerts.map { prioritizedAlert in
            HealthAlert(
                type: mapAlertType(from: prioritizedAlert.alert.rule.metricKey),
                message: prioritizedAlert.alert.rule.description,
                severity: mapSeverity(from: prioritizedAlert.triageRank),
                timestamp: prioritizedAlert.alert.timestamp
            )
        }
        
        DispatchQueue.main.async {
            self.healthAlerts = healthAlerts
        }
        
        // Handle critical alerts
        for prioritizedAlert in prioritizedAlerts where prioritizedAlert.triageRank == .critical {
            DeepLinkManager.navigate(to: .callEMS)
        }
    }
    
    private func calculateIschemiaRisk(healthData: HealthDataSnapshot) -> Double {
        // Simplified ischemia risk calculation
        let heartRateRisk = max(0, (healthData.heartRate - 100) / 60) // Risk increases above 100 BPM
        let hrvRisk = max(0, (30 - healthData.hrv) / 30) // Risk increases below 30ms
        return min(1.0, (heartRateRisk + hrvRisk) / 2.0)
    }
    
    private func calculateAFRisk(healthData: HealthDataSnapshot) -> Double {
        // Simplified AF risk calculation
        let irregularityRisk = healthData.hrv > 100 ? 0.3 : 0.1
        let ageRisk = 0.2 // Simplified age factor
        return min(1.0, irregularityRisk + ageRisk)
    }
    
    private func calculateQTRisk(healthData: HealthDataSnapshot) -> Double {
        // Simplified QT risk calculation
        return healthData.heartRate > 120 ? 0.4 : 0.1
    }
    
    private func mapAlertType(from metricKey: String) -> AlertType {
        switch metricKey {
        case "ecg_ischemia_risk", "af_overall_risk", "qt_dynamic_risk":
            return .cardiovascular
        case "sleep_quality":
            return .sleep
        case "heart_rate", "hrv":
            return .stress
        default:
            return .cardiovascular
        }
    }
    
    private func mapSeverity(from triageRank: AlertPrioritizer.TriageRank) -> AlertSeverity {
        switch triageRank {
        case .critical:
            return .critical
        case .urgent:
            return .high
        case .advisory:
            return .medium
        case .informational:
            return .low
        }
    }
    
    // MARK: - Daily Insights
    
    private func generateDailyInsights() {
        let healthData = collectCurrentHealthData()
        let insights = analyticsEngine?.generateInsights(healthData: healthData) ?? []
        
        DispatchQueue.main.async {
            self.dailyInsights = insights
        }
    }
    
    // MARK: - Digital Twin Simulations
    
    func simulateHealthScenario(_ scenario: HealthScenario) -> HealthSimulation {
        return digitalTwin?.simulate(scenario: scenario) ?? HealthSimulation(metrics: [:], confidence: 0.0)
    }
    
    func getWhatIfAnalysis(changes: [HealthChange]) -> WhatIfAnalysis {
        let currentHealth = collectCurrentHealthData()
        return digitalTwin?.simulateChanges(currentHealth: currentHealth, changes: changes) ?? WhatIfAnalysis()
    }
    
    // MARK: - Weather Integration
    
    func updateWeatherPredictions(weatherData: WeatherData) {
        let weatherPredictions = analyticsEngine?.processWeatherData(weatherData: weatherData) ?? []
        
        // Update health predictions based on weather
        DispatchQueue.main.async {
            // Update relevant predictions
        }
    }
    
    // MARK: - Public Interface
    
    func getPhysioForecast() -> PhysioForecast {
        return physioForecast
    }
    
    func getFlowWindows() -> [FlowWindow] {
        return flowWindows
    }
    
    func getVolatilityRadar() -> VolatilityRadar {
        return volatilityRadar
    }
    
    func getHealthAlerts() -> [HealthAlert] {
        return healthAlerts
    }
    
    func getDailyInsights() -> [HealthInsight] {
        return dailyInsights
    }
    
    func refreshPredictions() {
        performPredictiveAnalysis()
    }
    
    /// Receive new metrics/insights and process alerts
    func processMetrics(_ metrics: [String: Double], confidenceByMetric: [String: Double] = [:], isNightTime: Bool = false) {
        // 1. Evaluate rules
        let triggeredAlerts = AlertRuleEngine.shared.evaluate(metrics: metrics)
        
        // 2. Build alert context
        let context = AlertContext(
            confidenceByMetric: confidenceByMetric,
            recentAlertCounts: [:],
            isNightTime: isNightTime
        )
        
        // 3. Prioritize alerts
        let prioritized = AlertPrioritizer.shared.prioritize(alerts: triggeredAlerts, context: context)
        
        // 4. Generate explanations
        let explainedAlerts = prioritized.map { prioritizedAlert in
            let explanation = XAIExplanationGenerator.shared.generateExplanation(for: prioritizedAlert.alert, context: context)
            return PrioritizedAlertWithExplanation(prioritizedAlert: prioritizedAlert, explanation: explanation)
        }
        
        // 5. Update published alerts
        activeAlerts = explainedAlerts
        lastAlertTime = Date()
        
        // 6. Update recent alert counts
        for alert in triggeredAlerts {
            recentAlertCounts[alert.rule.id, default: 0] += 1
        }
    }
    
    /// Clear all active alerts
    func clearAlerts() {
        activeAlerts = []
    }
    
    /// Get the most critical active alert
    func mostCriticalAlert() -> PrioritizedAlertWithExplanation? {
        return activeAlerts.sorted { $0.prioritizedAlert.priorityScore > $1.prioritizedAlert.priorityScore }.first
    }
}

// MARK: - Supporting Classes and Models

struct PhysioForecast {
    var energy: Double = 0.0
    var moodStability: Double = 0.0
    var cognitiveAcuity: Double = 0.0
    var musculoskeletalResilience: Double = 0.0
    var metabolicFuelRange: Double = 0.0
    var confidence: Double = 0.0
    var timestamp: Date = Date()
}

struct FlowWindow {
    let startTime: Date
    let endTime: Date
    let focusIndex: Double
    let dopamineDrive: Double
    let confidence: Double
}

struct VolatilityRadar {
    var emotionalSwingProbability: Double = 0.0
    var stressLevel: Double = 0.0
    var moodStability: Double = 0.0
    var recommendedActions: [String] = []
}

struct HealthAlert {
    let type: AlertType
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    // Add more properties like contributingFactors, suggestedActions, etc.
}

struct HealthInsight {
    let type: InsightType
    let title: String
    let description: String
    let impact: Double
    let timestamp: Date
    let actionable: Bool
}

struct HealthDataSnapshot {
    let heartRate: Double
    let hrv: Double
    let oxygenSaturation: Double
    let bodyTemperature: Double
    let stepCount: Int
    let activeEnergyBurned: Double
    let sleepData: [HKCategorySample]
    let timestamp: Date
}

struct BaselineHealthData {
    let averageHeartRate: Double
    let averageHRV: Double
    let averageSleepDuration: TimeInterval
    let averageSteps: Int
    let seasonalPatterns: [String: Double]
    let circadianPatterns: [String: Double]
}

struct HealthScenario {
    let sleepHours: Double
    let exerciseMinutes: Double
    let caffeineIntake: Double
    let stressLevel: Double
    let nutritionQuality: Double
}

struct HealthChange {
    let type: ChangeType
    let value: Double
    let description: String
}

struct WhatIfAnalysis {
    var predictedMetrics: [String: Double] = [:]
    var confidence: Double = 0.0
    var recommendations: [String] = []
}

struct WeatherData {
    let temperature: Double
    let humidity: Double
    let pressure: Double
    let pollenCount: Int
    let airQuality: Double
    let uvIndex: Double
}

enum AlertType {
    case cardiovascular
    case sleep
    case stress
    case activity
    case nutrition
    case environmental
}

enum AlertSeverity {
    case low
    case medium
    case high
    case critical
}

enum InsightType {
    case sleep
    case activity
    case nutrition
    case stress
    case recovery
    case trend
}

enum ChangeType {
    case sleep
    case exercise
    case nutrition
    case stress
    case medication
}

class AnalyticsEngine {
    func generatePhysioForecast(currentData: HealthDataSnapshot, baselineData: BaselineHealthData) -> PhysioForecast {
        // Generate PhysioForecast using ML models
        // This is a simplified implementation
        
        let energy = calculateEnergyScore(currentData: currentData, baseline: baselineData)
        let moodStability = calculateMoodStability(currentData: currentData, baseline: baselineData)
        let cognitiveAcuity = calculateCognitiveAcuity(currentData: currentData, baseline: baselineData)
        let resilience = calculateResilience(currentData: currentData, baseline: baselineData)
        let metabolicRange = calculateMetabolicRange(currentData: currentData, baseline: baselineData)
        
        return PhysioForecast(
            energy: energy,
            moodStability: moodStability,
            cognitiveAcuity: cognitiveAcuity,
            musculoskeletalResilience: resilience,
            metabolicFuelRange: metabolicRange,
            confidence: 0.85,
            timestamp: Date()
        )
    }
    
    func detectFlowWindows(healthData: HealthDataSnapshot) -> [FlowWindow] {
        // Detect optimal flow windows based on HRV and other metrics
        let focusIndex = calculateFocusIndex(healthData: healthData)
        let dopamineDrive = calculateDopamineDrive(healthData: healthData)
        
        // Simple flow window detection
        if focusIndex > 0.7 && dopamineDrive > 0.6 {
            let window = FlowWindow(
                startTime: Date(),
                endTime: Date().addingTimeInterval(5400), // 90 minutes
                focusIndex: focusIndex,
                dopamineDrive: dopamineDrive,
                confidence: 0.8
            )
            return [window]
        }
        
        return []
    }
    
    func calculateVolatility(healthData: HealthDataSnapshot) -> VolatilityRadar {
        // Calculate emotional volatility based on various factors
        let emotionalSwingProbability = calculateEmotionalSwingProbability(healthData: healthData)
        let stressLevel = calculateStressLevel(healthData: healthData)
        let moodStability = calculateMoodStability(currentData: healthData, baseline: BaselineHealthData(averageHeartRate: 70, averageHRV: 40, averageSleepDuration: 28800, averageSteps: 8000, seasonalPatterns: [:], circadianPatterns: [:]))
        
        var recommendedActions: [String] = []
        if emotionalSwingProbability > 0.6 {
            recommendedActions.append("Practice mindfulness")
            recommendedActions.append("Take a short walk")
        }
        
        return VolatilityRadar(
            emotionalSwingProbability: emotionalSwingProbability,
            stressLevel: stressLevel,
            moodStability: moodStability,
            recommendedActions: recommendedActions
        )
    }
    
    func checkForAlerts(healthData: HealthDataSnapshot) -> [HealthAlert] {
        var alerts: [HealthAlert] = []
        
        // Check for various health conditions
        if healthData.heartRate > 100 {
            alerts.append(HealthAlert(
                type: .cardiovascular,
                message: "Elevated heart rate detected",
                severity: .medium,
                timestamp: Date()
            ))
        }
        
        if healthData.hrv < 20 {
            alerts.append(HealthAlert(
                type: .stress,
                message: "Low heart rate variability detected",
                severity: .high,
                timestamp: Date()
            ))
        }
        
        return alerts
    }
    
    func generateInsights(healthData: HealthDataSnapshot) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Generate insights based on health data
        if healthData.stepCount < 5000 {
            insights.append(HealthInsight(
                type: .activity,
                title: "Low Activity Level",
                description: "You've taken fewer steps than usual today",
                impact: 0.3,
                timestamp: Date(),
                actionable: true
            ))
        }
        
        if healthData.hrv > 60 {
            insights.append(HealthInsight(
                type: .recovery,
                title: "Excellent Recovery",
                description: "Your heart rate variability indicates good recovery",
                impact: 0.8,
                timestamp: Date(),
                actionable: false
            ))
        }
        
        return insights
    }
    
    func processWeatherData(weatherData: WeatherData) -> [HealthAlert] {
        var weatherAlerts: [HealthAlert] = []
        
        // Process weather data for health implications
        if weatherData.pollenCount > 100 {
            weatherAlerts.append(HealthAlert(
                type: .environmental,
                severity: .medium,
                message: "High pollen count detected",
                timestamp: Date(),
                confidence: 0.9,
                recommendedAction: "Consider indoor activities or take allergy medication"
            ))
        }
        
        return weatherAlerts
    }
    
    // MARK: - Helper Methods
    
    private func calculateEnergyScore(currentData: HealthDataSnapshot, baseline: BaselineHealthData) -> Double {
        // Calculate energy score based on various factors
        let hrvScore = min(currentData.hrv / baseline.averageHRV, 1.0)
        let sleepScore = calculateSleepScore(currentData: currentData)
        let activityScore = min(Double(currentData.stepCount) / Double(baseline.averageSteps), 1.0)
        
        return (hrvScore + sleepScore + activityScore) / 3.0
    }
    
    private func calculateMoodStability(currentData: HealthDataSnapshot, baseline: BaselineHealthData) -> Double {
        // Calculate mood stability based on HRV and other factors
        let hrvStability = 1.0 - abs(currentData.hrv - baseline.averageHRV) / baseline.averageHRV
        return max(0.0, min(1.0, hrvStability))
    }
    
    private func calculateCognitiveAcuity(currentData: HealthDataSnapshot, baseline: BaselineHealthData) -> Double {
        // Calculate cognitive acuity based on sleep and activity
        let sleepScore = calculateSleepScore(currentData: currentData)
        let activityScore = min(Double(currentData.stepCount) / Double(baseline.averageSteps), 1.0)
        
        return (sleepScore + activityScore) / 2.0
    }
    
    private func calculateResilience(currentData: HealthDataSnapshot, baseline: BaselineHealthData) -> Double {
        // Calculate musculoskeletal resilience
        let activityScore = min(Double(currentData.stepCount) / Double(baseline.averageSteps), 1.0)
        let energyScore = currentData.activeEnergyBurned / 500.0 // Normalized to 500 calories
        
        return min(1.0, (activityScore + energyScore) / 2.0)
    }
    
    private func calculateMetabolicRange(currentData: HealthDataSnapshot, baseline: BaselineHealthData) -> Double {
        // Calculate metabolic fuel range
        let heartRateScore = 1.0 - abs(currentData.heartRate - baseline.averageHeartRate) / baseline.averageHeartRate
        let activityScore = min(Double(currentData.stepCount) / Double(baseline.averageSteps), 1.0)
        
        return max(0.0, min(1.0, (heartRateScore + activityScore) / 2.0))
    }
    
    private func calculateSleepScore(currentData: HealthDataSnapshot) -> Double {
        // Calculate sleep quality score
        let totalSleepTime = currentData.sleepData.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate)
        }
        
        let normalizedSleepTime = totalSleepTime / 28800.0 // 8 hours in seconds
        return max(0.0, min(1.0, normalizedSleepTime))
    }
    
    private func calculateFocusIndex(healthData: HealthDataSnapshot) -> Double {
        // Calculate focus index based on HRV and other metrics
        let hrvScore = min(healthData.hrv / 100.0, 1.0)
        let heartRateScore = max(0.0, 1.0 - (healthData.heartRate - 60) / 40)
        
        return (hrvScore + heartRateScore) / 2.0
    }
    
    private func calculateDopamineDrive(healthData: HealthDataSnapshot) -> Double {
        // Calculate dopamine drive based on activity and other factors
        let activityScore = min(Double(healthData.stepCount) / 10000.0, 1.0)
        let energyScore = min(healthData.activeEnergyBurned / 500.0, 1.0)
        
        return (activityScore + energyScore) / 2.0
    }
    
    private func calculateEmotionalSwingProbability(healthData: HealthDataSnapshot) -> Double {
        // Calculate probability of emotional swings
        let hrvVariability = 1.0 - min(healthData.hrv / 100.0, 1.0)
        let stressIndicator = max(0.0, (healthData.heartRate - 60) / 40)
        
        return (hrvVariability + stressIndicator) / 2.0
    }
    
    private func calculateStressLevel(healthData: HealthDataSnapshot) -> Double {
        // Calculate stress level
        let hrvStress = 1.0 - min(healthData.hrv / 100.0, 1.0)
        let heartRateStress = max(0.0, (healthData.heartRate - 60) / 40)
        
        return (hrvStress + heartRateStress) / 2.0
    }
}

class DigitalTwinSimulator {
    func simulate(scenario: HealthScenario) -> HealthSimulation {
        // Simulate health outcomes based on scenario
        var metrics: [String: Double] = [:]
        
        // Simulate energy based on sleep and exercise
        let energyImpact = scenario.sleepHours / 8.0 + scenario.exerciseMinutes / 60.0
        metrics["energy"] = min(1.0, energyImpact)
        
        // Simulate mood based on stress and exercise
        let moodImpact = (1.0 - scenario.stressLevel) + (scenario.exerciseMinutes / 120.0)
        metrics["mood"] = max(0.0, min(1.0, moodImpact))
        
        // Simulate cognitive function
        let cognitiveImpact = scenario.sleepHours / 8.0 + (1.0 - scenario.stressLevel)
        metrics["cognitive"] = min(1.0, cognitiveImpact)
        
        return HealthSimulation(metrics: metrics, confidence: 0.8)
    }
    
    func simulateChanges(currentHealth: HealthDataSnapshot, changes: [HealthChange]) -> WhatIfAnalysis {
        // Simulate what-if scenarios
        var predictedMetrics: [String: Double] = [:]
        var recommendations: [String] = []
        
        for change in changes {
            switch change.type {
            case .sleep:
                if change.value > 8.0 {
                    recommendations.append("Consider reducing sleep to 7-8 hours for optimal performance")
                } else if change.value < 6.0 {
                    recommendations.append("Increase sleep duration to 7-9 hours for better recovery")
                }
            case .exercise:
                if change.value > 60 {
                    recommendations.append("Great exercise plan! Consider adding recovery days")
                } else if change.value < 30 {
                    recommendations.append("Try to increase exercise to 30+ minutes daily")
                }
            case .nutrition:
                if change.value < 0.7 {
                    recommendations.append("Focus on balanced nutrition with more whole foods")
                }
            case .stress:
                if change.value > 0.7 {
                    recommendations.append("Consider stress management techniques like meditation")
                }
            case .medication:
                recommendations.append("Consult with healthcare provider about medication timing")
            }
        }
        
        return WhatIfAnalysis(
            predictedMetrics: predictedMetrics,
            confidence: 0.75,
            recommendations: recommendations
        )
    }
}

// MARK: - Alert Struct
struct PrioritizedAlertWithExplanation: Identifiable {
    let id = UUID()
    let prioritizedAlert: AlertPrioritizer.PrioritizedAlert
    let explanation: XAIExplanationGenerator.Explanation
} 