import Foundation
import HealthAI2030Core
import HealthMetrics
import AsyncAlgorithms

/// Advanced environmental health monitoring and optimization engine
@globalActor
public actor EnvironmentalHealthEngine {
    public static let shared = EnvironmentalHealthEngine()
    
    private var environmentalSensors: [EnvironmentalSensor] = []
    private var currentEnvironment: EnvironmentalState?
    private var healthImpactModel: HealthImpactModel
    private var optimizationRules: [EnvironmentalRule] = []
    private var historicalData: [EnvironmentalReading] = []
    private var alertSubscribers: [EnvironmentalAlertSubscriber] = []
    
    private init() {
        self.healthImpactModel = HealthImpactModel()
        setupDefaultOptimizationRules()
        startEnvironmentalMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Register environmental sensors for monitoring
    public func registerSensor(_ sensor: EnvironmentalSensor) async {
        environmentalSensors.append(sensor)
        await sensor.startMonitoring()
    }
    
    /// Get current environmental health assessment
    public func getCurrentEnvironmentalHealth() async -> EnvironmentalHealthAssessment {
        guard let environment = currentEnvironment else {
            return EnvironmentalHealthAssessment.unknown()
        }
        
        let healthImpact = await healthImpactModel.assessHealthImpact(environment)
        let recommendations = await generateEnvironmentalRecommendations(environment, healthImpact)
        let airQualityIndex = calculateAirQualityIndex(environment)
        let comfortIndex = calculateComfortIndex(environment)
        
        return EnvironmentalHealthAssessment(
            overallScore: healthImpact.overallScore,
            airQualityIndex: airQualityIndex,
            comfortIndex: comfortIndex,
            healthImpacts: healthImpact.impacts,
            recommendations: recommendations,
            timestamp: Date(),
            environment: environment
        )
    }
    
    /// Monitor specific health condition against environmental factors
    public func monitorCondition(
        _ condition: HealthCondition,
        triggers: [EnvironmentalTrigger]
    ) async {
        let monitor = ConditionMonitor(
            condition: condition,
            triggers: triggers,
            alertCallback: { [weak self] alert in
                Task { await self?.handleEnvironmentalAlert(alert) }
            }
        )
        
        await monitor.startMonitoring(currentEnvironment)
    }
    
    /// Optimize environment for specific health goals
    public func optimizeForHealthGoal(_ goal: HealthGoal) async -> [EnvironmentalOptimization] {
        guard let environment = currentEnvironment else { return [] }
        
        var optimizations: [EnvironmentalOptimization] = []
        
        switch goal.type {
        case .sleepQuality:
            optimizations.append(contentsOf: await optimizeForSleep(environment))
        case .stressReduction:
            optimizations.append(contentsOf: await optimizeForStressReduction(environment))
        case .heartHealth:
            optimizations.append(contentsOf: await optimizeForCardiovascularHealth(environment))
        case .nutrition:
            optimizations.append(contentsOf: await optimizeForNutrition(environment))
        default:
            optimizations.append(contentsOf: await optimizeForGeneralWellness(environment))
        }
        
        return optimizations.sorted { $0.priority > $1.priority }
    }
    
    /// Subscribe to environmental health alerts
    public func subscribeToAlerts(_ subscriber: EnvironmentalAlertSubscriber) async {
        alertSubscribers.append(subscriber)
    }
    
    /// Get environmental health trends over time
    public func getHealthTrends(period: TimePeriod) async -> EnvironmentalHealthTrends {
        let startDate = Date().addingTimeInterval(-period.timeInterval)
        let periodData = historicalData.filter { $0.timestamp >= startDate }
        
        return EnvironmentalHealthTrends(
            period: period,
            airQualityTrend: calculateAirQualityTrend(periodData),
            temperatureTrend: calculateTemperatureTrend(periodData),
            humidityTrend: calculateHumidityTrend(periodData),
            noiseTrend: calculateNoiseTrend(periodData),
            lightExposureTrend: calculateLightExposureTrend(periodData),
            healthImpactCorrelations: await calculateHealthCorrelations(periodData)
        )
    }
    
    /// Predict environmental health impact for next period
    public func predictEnvironmentalImpact(
        forecast: WeatherForecast,
        timeframe: TimeInterval
    ) async -> EnvironmentalHealthForecast {
        let predictedEnvironment = await generateEnvironmentalForecast(forecast, timeframe)
        let predictedImpact = await healthImpactModel.predictHealthImpact(predictedEnvironment)
        
        return EnvironmentalHealthForecast(
            timeframe: timeframe,
            predictedEnvironment: predictedEnvironment,
            predictedHealthImpact: predictedImpact,
            recommendedPreparations: await generatePreparationRecommendations(predictedImpact),
            confidence: calculatePredictionConfidence(forecast)
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupDefaultOptimizationRules() {
        optimizationRules = [
            // Air Quality Rules
            EnvironmentalRule(
                trigger: .airQualityBelow(threshold: 50),
                action: .activateAirPurifier(intensity: .high),
                priority: .high,
                healthImpact: "Poor air quality affects respiratory health and cognitive function"
            ),
            
            // Temperature Rules
            EnvironmentalRule(
                trigger: .temperatureOutsideRange(min: 18, max: 24),
                action: .adjustThermostat(targetTemperature: 21),
                priority: .medium,
                healthImpact: "Optimal temperature range supports sleep quality and comfort"
            ),
            
            // Humidity Rules
            EnvironmentalRule(
                trigger: .humidityOutsideRange(min: 40, max: 60),
                action: .adjustHumidifier(targetHumidity: 50),
                priority: .medium,
                healthImpact: "Proper humidity levels prevent respiratory irritation"
            ),
            
            // Light Rules
            EnvironmentalRule(
                trigger: .lightLevelTooHigh(threshold: 500, timeRange: 22...6),
                action: .dimLights(intensity: 0.1),
                priority: .high,
                healthImpact: "Bright light before bedtime disrupts circadian rhythm"
            ),
            
            // Noise Rules
            EnvironmentalRule(
                trigger: .noiseLevelTooHigh(threshold: 40, timeRange: 22...7),
                action: .activateWhiteNoise(volume: 0.3),
                priority: .medium,
                healthImpact: "Excessive noise impacts sleep quality and stress levels"
            )
        ]
    }
    
    private func startEnvironmentalMonitoring() {
        Task {
            // Create async stream for sensor data aggregation
            let sensorStreams = environmentalSensors.map { sensor in
                sensor.dataStream
            }
            
            // Combine all sensor streams
            for await readings in combineLatest(sensorStreams) {
                let environmentalState = aggregateReadings(readings)
                await updateEnvironmentalState(environmentalState)
            }
        }
    }
    
    private func updateEnvironmentalState(_ state: EnvironmentalState) async {
        currentEnvironment = state
        
        // Store historical data
        let reading = EnvironmentalReading(
            timestamp: Date(),
            state: state
        )
        historicalData.append(reading)
        
        // Keep only recent data
        if historicalData.count > 10000 {
            historicalData.removeFirst(1000)
        }
        
        // Check optimization rules
        await checkOptimizationRules(state)
        
        // Assess health impact
        let healthImpact = await healthImpactModel.assessHealthImpact(state)
        await notifyHealthImpactChange(healthImpact)
    }
    
    private func checkOptimizationRules(_ state: EnvironmentalState) async {
        for rule in optimizationRules {
            if await rule.shouldTrigger(state) {
                let optimization = EnvironmentalOptimization(
                    rule: rule,
                    currentState: state,
                    recommendedAction: rule.action,
                    priority: rule.priority,
                    expectedHealthImprovement: rule.expectedImprovement
                )
                
                await executeOptimization(optimization)
            }
        }
    }
    
    private func executeOptimization(_ optimization: EnvironmentalOptimization) async {
        // Notify subscribers about optimization
        let alert = EnvironmentalAlert(
            type: .optimizationRecommended,
            message: "Environmental optimization recommended: \(optimization.recommendedAction)",
            priority: optimization.priority,
            optimization: optimization
        )
        
        await notifyAlertSubscribers(alert)
    }
    
    private func optimizeForSleep(_ environment: EnvironmentalState) async -> [EnvironmentalOptimization] {
        var optimizations: [EnvironmentalOptimization] = []
        
        // Temperature optimization for sleep
        if environment.temperature > 22 || environment.temperature < 16 {
            optimizations.append(EnvironmentalOptimization(
                type: .temperatureControl,
                description: "Optimize bedroom temperature for sleep (16-19°C)",
                targetValue: 18.0,
                currentValue: environment.temperature,
                priority: 0.9,
                expectedImprovement: "Better sleep onset and deeper sleep stages"
            ))
        }
        
        // Light optimization for sleep
        if environment.lightLevel > 50 {
            optimizations.append(EnvironmentalOptimization(
                type: .lightControl,
                description: "Reduce light levels for optimal melatonin production",
                targetValue: 1.0,
                currentValue: environment.lightLevel,
                priority: 0.95,
                expectedImprovement: "Enhanced natural melatonin production"
            ))
        }
        
        // Noise optimization for sleep
        if environment.noiseLevel > 30 {
            optimizations.append(EnvironmentalOptimization(
                type: .noiseControl,
                description: "Reduce noise levels or add white noise masking",
                targetValue: 25.0,
                currentValue: environment.noiseLevel,
                priority: 0.8,
                expectedImprovement: "Reduced sleep disruptions and better sleep continuity"
            ))
        }
        
        return optimizations
    }
    
    private func optimizeForStressReduction(_ environment: EnvironmentalState) async -> [EnvironmentalOptimization] {
        var optimizations: [EnvironmentalOptimization] = []
        
        // Air quality for stress
        if environment.airQuality < 70 {
            optimizations.append(EnvironmentalOptimization(
                type: .airQualityControl,
                description: "Improve air quality to reduce stress and enhance cognitive function",
                targetValue: 85.0,
                currentValue: environment.airQuality,
                priority: 0.85,
                expectedImprovement: "Reduced stress hormones and improved mental clarity"
            ))
        }
        
        // Natural light for mood
        if environment.naturalLightExposure < 0.3 {
            optimizations.append(EnvironmentalOptimization(
                type: .lightTherapy,
                description: "Increase natural light exposure to boost mood and reduce stress",
                targetValue: 0.7,
                currentValue: environment.naturalLightExposure,
                priority: 0.8,
                expectedImprovement: "Enhanced serotonin production and mood regulation"
            ))
        }
        
        return optimizations
    }
    
    private func optimizeForCardiovascularHealth(_ environment: EnvironmentalState) async -> [EnvironmentalOptimization] {
        var optimizations: [EnvironmentalOptimization] = []
        
        // Air quality for cardiovascular health
        if environment.airQuality < 80 {
            optimizations.append(EnvironmentalOptimization(
                type: .airQualityControl,
                description: "Improve air quality to support cardiovascular health",
                targetValue: 90.0,
                currentValue: environment.airQuality,
                priority: 0.9,
                expectedImprovement: "Reduced cardiovascular stress and inflammation"
            ))
        }
        
        // Temperature regulation for heart health
        if environment.temperature > 25 {
            optimizations.append(EnvironmentalOptimization(
                type: .temperatureControl,
                description: "Moderate temperature to reduce cardiovascular strain",
                targetValue: 22.0,
                currentValue: environment.temperature,
                priority: 0.7,
                expectedImprovement: "Reduced heart rate and blood pressure"
            ))
        }
        
        return optimizations
    }
    
    private func optimizeForNutrition(_ environment: EnvironmentalState) async -> [EnvironmentalOptimization] {
        var optimizations: [EnvironmentalOptimization] = []
        
        // Kitchen air quality for food safety
        if environment.kitchenAirQuality < 75 {
            optimizations.append(EnvironmentalOptimization(
                type: .airQualityControl,
                description: "Improve kitchen air quality for food safety and appetite",
                targetValue: 85.0,
                currentValue: environment.kitchenAirQuality,
                priority: 0.7,
                expectedImprovement: "Better food preservation and enhanced appetite"
            ))
        }
        
        return optimizations
    }
    
    private func optimizeForGeneralWellness(_ environment: EnvironmentalState) async -> [EnvironmentalOptimization] {
        var optimizations: [EnvironmentalOptimization] = []
        
        // Overall comfort optimization
        let comfortScore = calculateComfortIndex(environment)
        if comfortScore < 0.7 {
            optimizations.append(EnvironmentalOptimization(
                type: .generalComfort,
                description: "Optimize overall environmental comfort",
                targetValue: 0.85,
                currentValue: comfortScore,
                priority: 0.6,
                expectedImprovement: "Enhanced overall wellbeing and comfort"
            ))
        }
        
        return optimizations
    }
    
    private func generateEnvironmentalRecommendations(
        _ environment: EnvironmentalState,
        _ healthImpact: HealthImpact
    ) async -> [EnvironmentalRecommendation] {
        var recommendations: [EnvironmentalRecommendation] = []
        
        for impact in healthImpact.impacts {
            if impact.severity > 0.3 {
                let recommendation = await generateRecommendationForImpact(impact, environment)
                recommendations.append(recommendation)
            }
        }
        
        return recommendations.sorted { $0.priority > $1.priority }
    }
    
    private func generateRecommendationForImpact(
        _ impact: HealthImpactFactor,
        _ environment: EnvironmentalState
    ) async -> EnvironmentalRecommendation {
        switch impact.factor {
        case .airQuality:
            return EnvironmentalRecommendation(
                title: "Improve Air Quality",
                description: "Current air quality may affect respiratory health and cognitive function",
                actions: ["Activate air purifier", "Open windows for ventilation", "Check HVAC filters"],
                priority: impact.severity,
                expectedBenefit: "Improved breathing and mental clarity"
            )
            
        case .temperature:
            return EnvironmentalRecommendation(
                title: "Adjust Temperature",
                description: "Temperature is outside optimal comfort range",
                actions: ["Adjust thermostat", "Use fans or heating", "Check insulation"],
                priority: impact.severity,
                expectedBenefit: "Enhanced comfort and energy efficiency"
            )
            
        case .humidity:
            return EnvironmentalRecommendation(
                title: "Control Humidity",
                description: "Humidity levels may affect comfort and health",
                actions: ["Use humidifier/dehumidifier", "Improve ventilation", "Check for leaks"],
                priority: impact.severity,
                expectedBenefit: "Reduced respiratory irritation and improved comfort"
            )
            
        case .noise:
            return EnvironmentalRecommendation(
                title: "Reduce Noise Pollution",
                description: "High noise levels can increase stress and disrupt sleep",
                actions: ["Use noise-canceling devices", "Add soft furnishings", "Close windows"],
                priority: impact.severity,
                expectedBenefit: "Reduced stress and better sleep quality"
            )
            
        case .light:
            return EnvironmentalRecommendation(
                title: "Optimize Lighting",
                description: "Lighting conditions may affect circadian rhythm and mood",
                actions: ["Adjust brightness", "Use warmer lights in evening", "Increase natural light"],
                priority: impact.severity,
                expectedBenefit: "Better sleep patterns and improved mood"
            )
        }
    }
    
    private func calculateAirQualityIndex(_ environment: EnvironmentalState) -> Double {
        // Simplified AQI calculation
        let pm25Factor = max(0, min(1, (50 - environment.pm25) / 50))
        let vocFactor = max(0, min(1, (500 - environment.volatileOrganicCompounds) / 500))
        let co2Factor = max(0, min(1, (1000 - environment.co2Level) / 1000))
        
        return (pm25Factor + vocFactor + co2Factor) / 3.0
    }
    
    private func calculateComfortIndex(_ environment: EnvironmentalState) -> Double {
        let tempComfort = calculateTemperatureComfort(environment.temperature)
        let humidityComfort = calculateHumidityComfort(environment.humidity)
        let noiseComfort = calculateNoiseComfort(environment.noiseLevel)
        let lightComfort = calculateLightComfort(environment.lightLevel)
        
        return (tempComfort + humidityComfort + noiseComfort + lightComfort) / 4.0
    }
    
    private func calculateTemperatureComfort(_ temperature: Double) -> Double {
        let optimal = 21.0
        let deviation = abs(temperature - optimal)
        return max(0, 1 - deviation / 10)
    }
    
    private func calculateHumidityComfort(_ humidity: Double) -> Double {
        let optimal = 50.0
        let deviation = abs(humidity - optimal)
        return max(0, 1 - deviation / 30)
    }
    
    private func calculateNoiseComfort(_ noiseLevel: Double) -> Double {
        return max(0, min(1, (60 - noiseLevel) / 60))
    }
    
    private func calculateLightComfort(_ lightLevel: Double) -> Double {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isNight = currentHour >= 22 || currentHour <= 6
        
        if isNight {
            return max(0, min(1, (50 - lightLevel) / 50))
        } else {
            return max(0, min(1, lightLevel / 500))
        }
    }
    
    private func aggregateReadings(_ readings: [SensorReading]) -> EnvironmentalState {
        // Aggregate multiple sensor readings into environmental state
        var temperature = 0.0
        var humidity = 0.0
        var airQuality = 0.0
        var lightLevel = 0.0
        var noiseLevel = 0.0
        
        var count = 0
        
        for reading in readings {
            switch reading.type {
            case .temperature:
                temperature += reading.value
            case .humidity:
                humidity += reading.value
            case .airQuality:
                airQuality += reading.value
            case .lightLevel:
                lightLevel += reading.value
            case .noiseLevel:
                noiseLevel += reading.value
            default:
                continue
            }
            count += 1
        }
        
        let divisor = max(1, count)
        
        return EnvironmentalState(
            temperature: temperature / Double(divisor),
            humidity: humidity / Double(divisor),
            airQuality: airQuality / Double(divisor),
            lightLevel: lightLevel / Double(divisor),
            noiseLevel: noiseLevel / Double(divisor),
            pm25: 15.0, // Would be read from PM2.5 sensor
            volatileOrganicCompounds: 200.0, // Would be read from VOC sensor
            co2Level: 400.0, // Would be read from CO2 sensor
            naturalLightExposure: 0.5, // Calculated from light sensors
            kitchenAirQuality: airQuality / Double(divisor),
            timestamp: Date()
        )
    }
    
    private func handleEnvironmentalAlert(_ alert: EnvironmentalAlert) async {
        await notifyAlertSubscribers(alert)
    }
    
    private func notifyHealthImpactChange(_ healthImpact: HealthImpact) async {
        if healthImpact.overallScore < 0.5 {
            let alert = EnvironmentalAlert(
                type: .healthImpactDetected,
                message: "Environmental factors may be impacting your health",
                priority: .high,
                healthImpact: healthImpact
            )
            await notifyAlertSubscribers(alert)
        }
    }
    
    private func notifyAlertSubscribers(_ alert: EnvironmentalAlert) async {
        for subscriber in alertSubscribers {
            await subscriber.handleAlert(alert)
        }
    }
    
    // MARK: - Trend Analysis Helper Methods
    
    private func calculateAirQualityTrend(_ data: [EnvironmentalReading]) -> Trend {
        let values = data.map { $0.state.airQuality }
        return calculateTrend(values)
    }
    
    private func calculateTemperatureTrend(_ data: [EnvironmentalReading]) -> Trend {
        let values = data.map { $0.state.temperature }
        return calculateTrend(values)
    }
    
    private func calculateHumidityTrend(_ data: [EnvironmentalReading]) -> Trend {
        let values = data.map { $0.state.humidity }
        return calculateTrend(values)
    }
    
    private func calculateNoiseTrend(_ data: [EnvironmentalReading]) -> Trend {
        let values = data.map { $0.state.noiseLevel }
        return calculateTrend(values)
    }
    
    private func calculateLightExposureTrend(_ data: [EnvironmentalReading]) -> Trend {
        let values = data.map { $0.state.naturalLightExposure }
        return calculateTrend(values)
    }
    
    private func calculateTrend(_ values: [Double]) -> Trend {
        guard values.count >= 2 else { return Trend(direction: .stable, magnitude: 0.0) }
        
        let recent = values.suffix(values.count / 3)
        let earlier = values.prefix(values.count / 3)
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.reduce(0, +) / Double(earlier.count)
        
        let change = recentAvg - earlierAvg
        let magnitude = abs(change) / earlierAvg
        
        let direction: TrendDirection
        if magnitude < 0.05 {
            direction = .stable
        } else if change > 0 {
            direction = .increasing
        } else {
            direction = .decreasing
        }
        
        return Trend(direction: direction, magnitude: magnitude)
    }
    
    private func calculateHealthCorrelations(_ data: [EnvironmentalReading]) async -> [HealthCorrelation] {
        // Simplified correlation analysis
        // In production, this would use more sophisticated statistical methods
        return [
            HealthCorrelation(
                factor: "Air Quality",
                healthMetric: "Respiratory Function",
                correlation: 0.7,
                significance: 0.95
            ),
            HealthCorrelation(
                factor: "Temperature",
                healthMetric: "Sleep Quality",
                correlation: -0.6,
                significance: 0.85
            )
        ]
    }
    
    private func generateEnvironmentalForecast(
        _ forecast: WeatherForecast,
        _ timeframe: TimeInterval
    ) async -> [EnvironmentalState] {
        // Generate predicted environmental states based on weather forecast
        // This is a simplified implementation
        return []
    }
    
    private func generatePreparationRecommendations(
        _ predictedImpact: HealthImpact
    ) async -> [String] {
        var recommendations: [String] = []
        
        for impact in predictedImpact.impacts {
            if impact.severity > 0.4 {
                switch impact.factor {
                case .airQuality:
                    recommendations.append("Pre-filter air and close windows")
                case .temperature:
                    recommendations.append("Adjust thermostat settings in advance")
                case .humidity:
                    recommendations.append("Prepare humidifier/dehumidifier")
                default:
                    break
                }
            }
        }
        
        return recommendations
    }
    
    private func calculatePredictionConfidence(_ forecast: WeatherForecast) -> Double {
        // Simplified confidence calculation based on forecast reliability
        return 0.8
    }
}

// MARK: - Supporting Types

public struct EnvironmentalState: Sendable {
    public let temperature: Double // Celsius
    public let humidity: Double // Percentage
    public let airQuality: Double // 0-100 index
    public let lightLevel: Double // Lux
    public let noiseLevel: Double // Decibels
    public let pm25: Double // μg/m³
    public let volatileOrganicCompounds: Double // ppb
    public let co2Level: Double // ppm
    public let naturalLightExposure: Double // 0-1 ratio
    public let kitchenAirQuality: Double // 0-100 index
    public let timestamp: Date
}

public struct EnvironmentalHealthAssessment: Sendable {
    public let overallScore: Double
    public let airQualityIndex: Double
    public let comfortIndex: Double
    public let healthImpacts: [HealthImpactFactor]
    public let recommendations: [EnvironmentalRecommendation]
    public let timestamp: Date
    public let environment: EnvironmentalState
    
    public static func unknown() -> EnvironmentalHealthAssessment {
        return EnvironmentalHealthAssessment(
            overallScore: 0.0,
            airQualityIndex: 0.0,
            comfortIndex: 0.0,
            healthImpacts: [],
            recommendations: [],
            timestamp: Date(),
            environment: EnvironmentalState(
                temperature: 0, humidity: 0, airQuality: 0, lightLevel: 0,
                noiseLevel: 0, pm25: 0, volatileOrganicCompounds: 0,
                co2Level: 0, naturalLightExposure: 0, kitchenAirQuality: 0,
                timestamp: Date()
            )
        )
    }
}

public struct EnvironmentalRecommendation: Sendable {
    public let title: String
    public let description: String
    public let actions: [String]
    public let priority: Double
    public let expectedBenefit: String
}

public struct EnvironmentalOptimization: Sendable {
    public let type: OptimizationType
    public let description: String
    public let targetValue: Double
    public let currentValue: Double
    public let priority: Double
    public let expectedImprovement: String
    
    public enum OptimizationType: Sendable {
        case temperatureControl
        case humidityControl
        case airQualityControl
        case lightControl
        case noiseControl
        case lightTherapy
        case generalComfort
    }
    
    // Legacy initializer for backward compatibility
    public init(
        rule: EnvironmentalRule,
        currentState: EnvironmentalState,
        recommendedAction: EnvironmentalAction,
        priority: Priority,
        expectedHealthImprovement: String
    ) {
        self.type = .generalComfort
        self.description = "Environmental optimization based on rule: \(rule.healthImpact)"
        self.targetValue = 1.0
        self.currentValue = 0.5
        self.priority = priority.rawValue
        self.expectedImprovement = expectedHealthImprovement
    }
}

public enum TimePeriod: Sendable {
    case hour
    case day
    case week
    case month
    
    public var timeInterval: TimeInterval {
        switch self {
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2592000
        }
    }
}

public struct EnvironmentalHealthTrends: Sendable {
    public let period: TimePeriod
    public let airQualityTrend: Trend
    public let temperatureTrend: Trend
    public let humidityTrend: Trend
    public let noiseTrend: Trend
    public let lightExposureTrend: Trend
    public let healthImpactCorrelations: [HealthCorrelation]
}

public struct Trend: Sendable {
    public let direction: TrendDirection
    public let magnitude: Double
}

public enum TrendDirection: Sendable {
    case increasing
    case decreasing
    case stable
}

public struct HealthCorrelation: Sendable {
    public let factor: String
    public let healthMetric: String
    public let correlation: Double // -1 to 1
    public let significance: Double // 0 to 1
}

public struct EnvironmentalHealthForecast: Sendable {
    public let timeframe: TimeInterval
    public let predictedEnvironment: [EnvironmentalState]
    public let predictedHealthImpact: HealthImpact
    public let recommendedPreparations: [String]
    public let confidence: Double
}

public struct WeatherForecast: Sendable {
    public let temperature: Double
    public let humidity: Double
    public let airPressure: Double
    public let windSpeed: Double
    public let precipitation: Double
}

// MARK: - Health Impact Model

private actor HealthImpactModel {
    func assessHealthImpact(_ environment: EnvironmentalState) async -> HealthImpact {
        var impacts: [HealthImpactFactor] = []
        
        // Air quality impact
        if environment.airQuality < 50 {
            impacts.append(HealthImpactFactor(
                factor: .airQuality,
                severity: (50 - environment.airQuality) / 50,
                description: "Poor air quality may affect respiratory health"
            ))
        }
        
        // Temperature impact
        let tempDeviation = abs(environment.temperature - 21) / 21
        if tempDeviation > 0.2 {
            impacts.append(HealthImpactFactor(
                factor: .temperature,
                severity: tempDeviation,
                description: "Temperature outside comfort zone may affect sleep and productivity"
            ))
        }
        
        // Humidity impact
        let humidityDeviation = abs(environment.humidity - 50) / 50
        if humidityDeviation > 0.3 {
            impacts.append(HealthImpactFactor(
                factor: .humidity,
                severity: humidityDeviation,
                description: "Humidity levels may cause discomfort and respiratory issues"
            ))
        }
        
        // Noise impact
        if environment.noiseLevel > 50 {
            impacts.append(HealthImpactFactor(
                factor: .noise,
                severity: (environment.noiseLevel - 50) / 50,
                description: "High noise levels may increase stress and disrupt sleep"
            ))
        }
        
        // Light impact (context-dependent)
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isNight = currentHour >= 22 || currentHour <= 6
        
        if isNight && environment.lightLevel > 50 {
            impacts.append(HealthImpactFactor(
                factor: .light,
                severity: environment.lightLevel / 100,
                description: "Bright light exposure may disrupt circadian rhythm"
            ))
        }
        
        let overallScore = impacts.isEmpty ? 1.0 : 1.0 - (impacts.map({\.severity}).reduce(0, +) / Double(impacts.count))
        
        return HealthImpact(
            overallScore: max(0, overallScore),
            impacts: impacts
        )
    }
    
    func predictHealthImpact(_ predictedEnvironments: [EnvironmentalState]) async -> HealthImpact {
        // Simplified prediction based on worst-case scenario
        var worstImpact = HealthImpact(overallScore: 1.0, impacts: [])
        
        for environment in predictedEnvironments {
            let impact = await assessHealthImpact(environment)
            if impact.overallScore < worstImpact.overallScore {
                worstImpact = impact
            }
        }
        
        return worstImpact
    }
}

public struct HealthImpact: Sendable {
    public let overallScore: Double
    public let impacts: [HealthImpactFactor]
}

public struct HealthImpactFactor: Sendable {
    public let factor: EnvironmentalFactor
    public let severity: Double // 0-1
    public let description: String
}

public enum EnvironmentalFactor: Sendable {
    case airQuality
    case temperature
    case humidity
    case noise
    case light
}

// MARK: - Environmental Rules and Actions

public struct EnvironmentalRule: Sendable {
    public let trigger: EnvironmentalTrigger
    public let action: EnvironmentalAction
    public let priority: Priority
    public let healthImpact: String
    public let expectedImprovement: String
    
    public init(
        trigger: EnvironmentalTrigger,
        action: EnvironmentalAction,
        priority: Priority,
        healthImpact: String
    ) {
        self.trigger = trigger
        self.action = action
        self.priority = priority
        self.healthImpact = healthImpact
        self.expectedImprovement = "Improved environmental conditions"
    }
    
    func shouldTrigger(_ state: EnvironmentalState) async -> Bool {
        return trigger.evaluate(state)
    }
}

public enum EnvironmentalTrigger: Sendable {
    case airQualityBelow(threshold: Double)
    case temperatureOutsideRange(min: Double, max: Double)
    case humidityOutsideRange(min: Double, max: Double)
    case lightLevelTooHigh(threshold: Double, timeRange: ClosedRange<Int>)
    case noiseLevelTooHigh(threshold: Double, timeRange: ClosedRange<Int>)
    
    func evaluate(_ state: EnvironmentalState) -> Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch self {
        case .airQualityBelow(let threshold):
            return state.airQuality < threshold
        case .temperatureOutsideRange(let min, let max):
            return state.temperature < min || state.temperature > max
        case .humidityOutsideRange(let min, let max):
            return state.humidity < min || state.humidity > max
        case .lightLevelTooHigh(let threshold, let timeRange):
            return state.lightLevel > threshold && timeRange.contains(currentHour)
        case .noiseLevelTooHigh(let threshold, let timeRange):
            return state.noiseLevel > threshold && timeRange.contains(currentHour)
        }
    }
}

public enum EnvironmentalAction: Sendable {
    case activateAirPurifier(intensity: Intensity)
    case adjustThermostat(targetTemperature: Double)
    case adjustHumidifier(targetHumidity: Double)
    case dimLights(intensity: Double)
    case activateWhiteNoise(volume: Double)
    
    public enum Intensity: Double, Sendable {
        case low = 0.3
        case medium = 0.6
        case high = 0.9
    }
}

public enum Priority: Double, Sendable {
    case low = 0.3
    case medium = 0.6
    case high = 0.9
    
    public var rawValue: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }
}

// MARK: - Sensor and Monitoring Types

public protocol EnvironmentalSensor: Sendable {
    var dataStream: AsyncStream<SensorReading> { get }
    func startMonitoring() async
    func stopMonitoring() async
}

public struct SensorReading: Sendable {
    public let type: SensorType
    public let value: Double
    public let timestamp: Date
    public let location: String?
}

public enum SensorType: Sendable {
    case temperature
    case humidity
    case airQuality
    case lightLevel
    case noiseLevel
    case pm25
    case voc
    case co2
}

public struct EnvironmentalReading: Sendable {
    public let timestamp: Date
    public let state: EnvironmentalState
}

public protocol EnvironmentalAlertSubscriber: Sendable {
    func handleAlert(_ alert: EnvironmentalAlert) async
}

public struct EnvironmentalAlert: Sendable {
    public let type: AlertType
    public let message: String
    public let priority: Priority
    public let timestamp: Date
    public let optimization: EnvironmentalOptimization?
    public let healthImpact: HealthImpact?
    
    public init(
        type: AlertType,
        message: String,
        priority: Priority,
        optimization: EnvironmentalOptimization? = nil,
        healthImpact: HealthImpact? = nil
    ) {
        self.type = type
        self.message = message
        self.priority = priority
        self.timestamp = Date()
        self.optimization = optimization
        self.healthImpact = healthImpact
    }
    
    public enum AlertType: Sendable {
        case healthImpactDetected
        case optimizationRecommended
        case sensorFailure
        case emergencyCondition
    }
}

// MARK: - Health Condition Monitoring

public enum HealthCondition: Sendable {
    case asthma
    case allergies
    case heartDisease
    case sleepDisorders
    case migraine
    case arthritis
}

public struct EnvironmentalTrigger: Sendable {
    public let condition: HealthCondition
    public let factor: EnvironmentalFactor
    public let threshold: Double
    public let direction: TriggerDirection
    
    public enum TriggerDirection: Sendable {
        case above
        case below
    }
}

private actor ConditionMonitor {
    private let condition: HealthCondition
    private let triggers: [EnvironmentalTrigger]
    private let alertCallback: (EnvironmentalAlert) -> Void
    
    init(
        condition: HealthCondition,
        triggers: [EnvironmentalTrigger],
        alertCallback: @escaping (EnvironmentalAlert) -> Void
    ) {
        self.condition = condition
        self.triggers = triggers
        self.alertCallback = alertCallback
    }
    
    func startMonitoring(_ environment: EnvironmentalState?) async {
        // Monitor environmental changes for condition triggers
        guard let environment = environment else { return }
        
        for trigger in triggers {
            if evaluateTrigger(trigger, environment) {
                let alert = EnvironmentalAlert(
                    type: .healthImpactDetected,
                    message: "Environmental trigger detected for \(condition)",
                    priority: .high
                )
                alertCallback(alert)
            }
        }
    }
    
    private func evaluateTrigger(_ trigger: EnvironmentalTrigger, _ environment: EnvironmentalState) -> Bool {
        let value: Double
        
        switch trigger.factor {
        case .airQuality: value = environment.airQuality
        case .temperature: value = environment.temperature
        case .humidity: value = environment.humidity
        case .noise: value = environment.noiseLevel
        case .light: value = environment.lightLevel
        }
        
        switch trigger.direction {
        case .above: return value > trigger.threshold
        case .below: return value < trigger.threshold
        }
    }
}

// MARK: - Helper Functions

private func combineLatest<T>(_ streams: [AsyncStream<T>]) -> AsyncStream<[T]> {
    // Simplified implementation - in production would use proper combineLatest
    return AsyncStream { continuation in
        Task {
            // This is a simplified placeholder
            continuation.finish()
        }
    }
}
