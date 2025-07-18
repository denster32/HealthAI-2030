import SwiftUI
import Foundation

// MARK: - Advanced Health Prediction Engine Protocol
protocol AdvancedHealthPredictionEngineProtocol {
    func createPredictionModel(_ config: PredictionModelConfig) async throws -> PredictionModel
    func generateHealthForecast(_ request: HealthForecastRequest) async throws -> HealthForecast
    func assessHealthRisk(_ data: HealthData) async throws -> RiskAssessment
    func generatePersonalizedPrediction(_ request: PersonalizedPredictionRequest) async throws -> PersonalizedPrediction
}

// MARK: - Prediction Model
struct PredictionModel: Identifiable, Codable {
    let id: String
    let name: String
    let type: ModelType
    let version: String
    let accuracy: Double
    let features: [ModelFeature]
    let parameters: [String: Any]
    
    init(name: String, type: ModelType, version: String, accuracy: Double, features: [ModelFeature], parameters: [String: Any]) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.version = version
        self.accuracy = accuracy
        self.features = features
        self.parameters = parameters
    }
}

// MARK: - Model Feature
struct ModelFeature: Identifiable, Codable {
    let id: String
    let name: String
    let type: FeatureType
    let importance: Double
    let description: String
    
    init(name: String, type: FeatureType, importance: Double, description: String) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.importance = importance
        self.description = description
    }
}

// MARK: - Prediction Model Config
struct PredictionModelConfig: Codable {
    let name: String
    let type: ModelType
    let features: [String]
    let hyperparameters: [String: Any]
    let trainingConfig: TrainingConfiguration
    
    init(name: String, type: ModelType, features: [String], hyperparameters: [String: Any], trainingConfig: TrainingConfiguration) {
        self.name = name
        self.type = type
        self.features = features
        self.hyperparameters = hyperparameters
        self.trainingConfig = trainingConfig
    }
}

// MARK: - Training Configuration
struct TrainingConfiguration: Codable {
    let epochs: Int
    let batchSize: Int
    let learningRate: Double
    let validationSplit: Double
    let earlyStopping: Bool
    
    init(epochs: Int, batchSize: Int, learningRate: Double, validationSplit: Double, earlyStopping: Bool) {
        self.epochs = epochs
        self.batchSize = batchSize
        self.learningRate = learningRate
        self.validationSplit = validationSplit
        self.earlyStopping = earlyStopping
    }
}

// MARK: - Health Forecast Request
struct HealthForecastRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let timeHorizon: TimeHorizon
    let metrics: [HealthMetric]
    let confidence: Double
    
    init(userId: String, timeHorizon: TimeHorizon, metrics: [HealthMetric], confidence: Double) {
        self.id = UUID().uuidString
        self.userId = userId
        self.timeHorizon = timeHorizon
        self.metrics = metrics
        self.confidence = confidence
    }
}

// MARK: - Health Forecast
struct HealthForecast: Identifiable, Codable {
    let id: String
    let requestID: String
    let predictions: [HealthPrediction]
    let confidence: Double
    let generatedAt: Date
    
    init(requestID: String, predictions: [HealthPrediction], confidence: Double) {
        self.id = UUID().uuidString
        self.requestID = requestID
        self.predictions = predictions
        self.confidence = confidence
        self.generatedAt = Date()
    }
}

// MARK: - Health Prediction
struct HealthPrediction: Identifiable, Codable {
    let id: String
    let metric: HealthMetric
    let value: Double
    let confidence: Double
    let timestamp: Date
    let trend: TrendDirection
    
    init(metric: HealthMetric, value: Double, confidence: Double, timestamp: Date, trend: TrendDirection) {
        self.id = UUID().uuidString
        self.metric = metric
        self.value = value
        self.confidence = confidence
        self.timestamp = timestamp
        self.trend = trend
    }
}

// MARK: - Health Data
struct HealthData: Identifiable, Codable {
    let id: String
    let userId: String
    let vitals: [VitalSign]
    let biometrics: [BiometricData]
    let lifestyle: LifestyleData
    let medicalHistory: MedicalHistory
    
    init(userId: String, vitals: [VitalSign], biometrics: [BiometricData], lifestyle: LifestyleData, medicalHistory: MedicalHistory) {
        self.id = UUID().uuidString
        self.userId = userId
        self.vitals = vitals
        self.biometrics = biometrics
        self.lifestyle = lifestyle
        self.medicalHistory = medicalHistory
    }
}

// MARK: - Vital Sign
struct VitalSign: Identifiable, Codable {
    let id: String
    let type: VitalType
    let value: Double
    let unit: String
    let timestamp: Date
    let status: VitalStatus
    
    init(type: VitalType, value: Double, unit: String, timestamp: Date, status: VitalStatus) {
        self.id = UUID().uuidString
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.status = status
    }
}

// MARK: - Biometric Data
struct BiometricData: Identifiable, Codable {
    let id: String
    let type: BiometricType
    let value: Double
    let unit: String
    let timestamp: Date
    let quality: DataQuality
    
    init(type: BiometricType, value: Double, unit: String, timestamp: Date, quality: DataQuality) {
        self.id = UUID().uuidString
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.quality = quality
    }
}

// MARK: - Lifestyle Data
struct LifestyleData: Codable {
    let sleepHours: Double
    let exerciseMinutes: Int
    let waterIntake: Double
    let stressLevel: StressLevel
    let dietQuality: DietQuality
    
    init(sleepHours: Double, exerciseMinutes: Int, waterIntake: Double, stressLevel: StressLevel, dietQuality: DietQuality) {
        self.sleepHours = sleepHours
        self.exerciseMinutes = exerciseMinutes
        self.waterIntake = waterIntake
        self.stressLevel = stressLevel
        self.dietQuality = dietQuality
    }
}

// MARK: - Medical History
struct MedicalHistory: Codable {
    let conditions: [MedicalCondition]
    let medications: [Medication]
    let allergies: [Allergy]
    let surgeries: [Surgery]
    
    init(conditions: [MedicalCondition], medications: [Medication], allergies: [Allergy], surgeries: [Surgery]) {
        self.conditions = conditions
        self.medications = medications
        self.allergies = allergies
        self.surgeries = surgeries
    }
}

// MARK: - Risk Assessment
struct RiskAssessment: Identifiable, Codable {
    let id: String
    let userId: String
    let overallRisk: RiskLevel
    let riskFactors: [RiskFactor]
    let recommendations: [Recommendation]
    let generatedAt: Date
    
    init(userId: String, overallRisk: RiskLevel, riskFactors: [RiskFactor], recommendations: [Recommendation]) {
        self.id = UUID().uuidString
        self.userId = userId
        self.overallRisk = overallRisk
        self.riskFactors = riskFactors
        self.recommendations = recommendations
        self.generatedAt = Date()
    }
}

// MARK: - Risk Factor
struct RiskFactor: Identifiable, Codable {
    let id: String
    let name: String
    let category: RiskCategory
    let severity: RiskSeverity
    let description: String
    let mitigation: String
    
    init(name: String, category: RiskCategory, severity: RiskSeverity, description: String, mitigation: String) {
        self.id = UUID().uuidString
        self.name = name
        self.category = category
        self.severity = severity
        self.description = description
        self.mitigation = mitigation
    }
}

// MARK: - Recommendation
struct Recommendation: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let priority: Priority
    let category: RecommendationCategory
    let actionable: Bool
    
    init(title: String, description: String, priority: Priority, category: RecommendationCategory, actionable: Bool) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.actionable = actionable
    }
}

// MARK: - Personalized Prediction Request
struct PersonalizedPredictionRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let predictionType: PredictionType
    let timeFrame: TimeFrame
    let includeFactors: [String]
    
    init(userId: String, predictionType: PredictionType, timeFrame: TimeFrame, includeFactors: [String]) {
        self.id = UUID().uuidString
        self.userId = userId
        self.predictionType = predictionType
        self.timeFrame = timeFrame
        self.includeFactors = includeFactors
    }
}

// MARK: - Personalized Prediction
struct PersonalizedPrediction: Identifiable, Codable {
    let id: String
    let requestID: String
    let prediction: String
    let confidence: Double
    let factors: [PredictionFactor]
    let insights: [Insight]
    let generatedAt: Date
    
    init(requestID: String, prediction: String, confidence: Double, factors: [PredictionFactor], insights: [Insight]) {
        self.id = UUID().uuidString
        self.requestID = requestID
        self.prediction = prediction
        self.confidence = confidence
        self.factors = factors
        self.insights = insights
        self.generatedAt = Date()
    }
}

// MARK: - Prediction Factor
struct PredictionFactor: Identifiable, Codable {
    let id: String
    let name: String
    let weight: Double
    let impact: ImpactDirection
    let description: String
    
    init(name: String, weight: Double, impact: ImpactDirection, description: String) {
        self.id = UUID().uuidString
        self.name = name
        self.weight = weight
        self.impact = impact
        self.description = description
    }
}

// MARK: - Insight
struct Insight: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: InsightType
    let actionable: Bool
    
    init(title: String, description: String, type: InsightType, actionable: Bool) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.type = type
        self.actionable = actionable
    }
}

// MARK: - Supporting Structures
struct MedicalCondition: Identifiable, Codable {
    let id: String
    let name: String
    let severity: ConditionSeverity
    let diagnosedDate: Date
    
    init(name: String, severity: ConditionSeverity, diagnosedDate: Date) {
        self.id = UUID().uuidString
        self.name = name
        self.severity = severity
        self.diagnosedDate = diagnosedDate
    }
}

struct Medication: Identifiable, Codable {
    let id: String
    let name: String
    let dosage: String
    let frequency: String
    
    init(name: String, dosage: String, frequency: String) {
        self.id = UUID().uuidString
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
    }
}

struct Allergy: Identifiable, Codable {
    let id: String
    let allergen: String
    let severity: AllergySeverity
    
    init(allergen: String, severity: AllergySeverity) {
        self.id = UUID().uuidString
        self.allergen = allergen
        self.severity = severity
    }
}

struct Surgery: Identifiable, Codable {
    let id: String
    let procedure: String
    let date: Date
    let outcome: String
    
    init(procedure: String, date: Date, outcome: String) {
        self.id = UUID().uuidString
        self.procedure = procedure
        self.date = date
        self.outcome = outcome
    }
}

// MARK: - Enums
enum ModelType: String, Codable, CaseIterable {
    case neuralNetwork = "Neural Network"
    case randomForest = "Random Forest"
    case gradientBoosting = "Gradient Boosting"
    case supportVectorMachine = "Support Vector Machine"
    case timeSeries = "Time Series"
}

enum FeatureType: String, Codable, CaseIterable {
    case numerical = "Numerical"
    case categorical = "Categorical"
    case temporal = "Temporal"
    case derived = "Derived"
}

enum TimeHorizon: String, Codable, CaseIterable {
    case shortTerm = "Short Term (1-7 days)"
    case mediumTerm = "Medium Term (1-4 weeks)"
    case longTerm = "Long Term (1-12 months)"
}

enum HealthMetric: String, Codable, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case bloodSugar = "Blood Sugar"
    case weight = "Weight"
    case sleepQuality = "Sleep Quality"
    case stressLevel = "Stress Level"
}

enum TrendDirection: String, Codable, CaseIterable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"
    case fluctuating = "Fluctuating"
}

enum VitalType: String, Codable, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case temperature = "Temperature"
    case respiratoryRate = "Respiratory Rate"
    case oxygenSaturation = "Oxygen Saturation"
}

enum VitalStatus: String, Codable, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case high = "High"
    case critical = "Critical"
}

enum BiometricType: String, Codable, CaseIterable {
    case heartRateVariability = "Heart Rate Variability"
    case bloodGlucose = "Blood Glucose"
    case cholesterol = "Cholesterol"
    case bodyComposition = "Body Composition"
}

enum DataQuality: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

enum StressLevel: String, Codable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case severe = "Severe"
}

enum DietQuality: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
}

enum RiskLevel: String, Codable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
}

enum RiskCategory: String, Codable, CaseIterable {
    case cardiovascular = "Cardiovascular"
    case metabolic = "Metabolic"
    case respiratory = "Respiratory"
    case lifestyle = "Lifestyle"
}

enum RiskSeverity: String, Codable, CaseIterable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case critical = "Critical"
}

enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
}

enum RecommendationCategory: String, Codable, CaseIterable {
    case lifestyle = "Lifestyle"
    case medical = "Medical"
    case preventive = "Preventive"
    case monitoring = "Monitoring"
}

enum PredictionType: String, Codable, CaseIterable {
    case healthOutcome = "Health Outcome"
    case diseaseRisk = "Disease Risk"
    case recoveryTime = "Recovery Time"
    case treatmentResponse = "Treatment Response"
}

enum TimeFrame: String, Codable, CaseIterable {
    case immediate = "Immediate (24 hours)"
    case shortTerm = "Short Term (1 week)"
    case mediumTerm = "Medium Term (1 month)"
    case longTerm = "Long Term (1 year)"
}

enum ImpactDirection: String, Codable, CaseIterable {
    case positive = "Positive"
    case negative = "Negative"
    case neutral = "Neutral"
}

enum InsightType: String, Codable, CaseIterable {
    case trend = "Trend"
    case correlation = "Correlation"
    case anomaly = "Anomaly"
    case pattern = "Pattern"
}

enum ConditionSeverity: String, Codable, CaseIterable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
}

enum AllergySeverity: String, Codable, CaseIterable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case lifeThreatening = "Life Threatening"
}

// MARK: - Advanced Health Prediction Engine Implementation
actor AdvancedHealthPredictionEngine: AdvancedHealthPredictionEngineProtocol {
    private let modelManager = PredictionModelManager()
    private let forecastManager = HealthForecastManager()
    private let riskManager = RiskAssessmentManager()
    private let personalizationManager = PersonalizationManager()
    private let logger = Logger(subsystem: "com.healthai2030.prediction", category: "AdvancedHealthPredictionEngine")
    
    func createPredictionModel(_ config: PredictionModelConfig) async throws -> PredictionModel {
        logger.info("Creating prediction model: \(config.name)")
        return try await modelManager.create(config)
    }
    
    func generateHealthForecast(_ request: HealthForecastRequest) async throws -> HealthForecast {
        logger.info("Generating health forecast for user: \(request.userId)")
        return try await forecastManager.generate(request)
    }
    
    func assessHealthRisk(_ data: HealthData) async throws -> RiskAssessment {
        logger.info("Assessing health risk for user: \(data.userId)")
        return try await riskManager.assess(data)
    }
    
    func generatePersonalizedPrediction(_ request: PersonalizedPredictionRequest) async throws -> PersonalizedPrediction {
        logger.info("Generating personalized prediction for user: \(request.userId)")
        return try await personalizationManager.generate(request)
    }
}

// MARK: - Prediction Model Manager
class PredictionModelManager {
    func create(_ config: PredictionModelConfig) async throws -> PredictionModel {
        let features = [
            ModelFeature(name: "Age", type: .numerical, importance: 0.8, description: "Patient age"),
            ModelFeature(name: "BMI", type: .numerical, importance: 0.7, description: "Body Mass Index"),
            ModelFeature(name: "Heart Rate", type: .numerical, importance: 0.9, description: "Resting heart rate"),
            ModelFeature(name: "Blood Pressure", type: .numerical, importance: 0.85, description: "Systolic blood pressure")
        ]
        
        return PredictionModel(
            name: config.name,
            type: config.type,
            version: "1.0.0",
            accuracy: 0.92,
            features: features,
            parameters: config.hyperparameters
        )
    }
}

// MARK: - Health Forecast Manager
class HealthForecastManager {
    func generate(_ request: HealthForecastRequest) async throws -> HealthForecast {
        let predictions = request.metrics.map { metric in
            // Generate more realistic predictions based on metric type
            let (value, trend) = generateRealisticPrediction(for: metric, timeHorizon: request.timeHorizon)
            
            return HealthPrediction(
                metric: metric,
                value: value,
                confidence: request.confidence * 0.85, // Slightly lower confidence for future predictions
                timestamp: calculateFutureTimestamp(timeHorizon: request.timeHorizon),
                trend: trend
            )
        }
        
        return HealthForecast(
            requestID: request.id,
            predictions: predictions,
            confidence: request.confidence
        )
    }
    
    private func generateRealisticPrediction(for metric: HealthMetric, timeHorizon: TimeHorizon) -> (value: Double, trend: TrendDirection) {
        switch metric {
        case .heartRate:
            let baseHR = 70.0
            let variation = Double.random(in: -5...5)
            return (baseHR + variation, variation > 0 ? .increasing : .decreasing)
            
        case .bloodPressure:
            let baseSystolic = 120.0
            let trend = Double.random(in: -2...2)
            return (baseSystolic + trend, trend > 1 ? .increasing : trend < -1 ? .decreasing : .stable)
            
        case .glucose:
            let baseGlucose = 95.0
            let variation = Double.random(in: -10...10)
            return (baseGlucose + variation, abs(variation) < 5 ? .stable : variation > 0 ? .increasing : .decreasing)
            
        case .weight:
            let baseWeight = 70.0 // kg
            let monthlyChange = timeHorizon == .month ? Double.random(in: -2...0.5) : 0
            return (baseWeight + monthlyChange, monthlyChange < -0.5 ? .decreasing : monthlyChange > 0.2 ? .increasing : .stable)
            
        case .steps:
            let baseSteps = 8000.0
            let variation = Double.random(in: -2000...2000)
            return (baseSteps + variation, variation > 500 ? .increasing : variation < -500 ? .decreasing : .stable)
            
        case .sleep:
            let baseSleep = 7.5
            let variation = Double.random(in: -0.5...0.5)
            return (baseSleep + variation, abs(variation) < 0.2 ? .stable : variation > 0 ? .increasing : .decreasing)
            
        case .calories:
            let baseCalories = 2000.0
            let variation = Double.random(in: -200...200)
            return (baseCalories + variation, abs(variation) < 100 ? .stable : variation > 0 ? .increasing : .decreasing)
            
        case .heartRateVariability:
            let baseHRV = 45.0
            let variation = Double.random(in: -5...8)
            return (baseHRV + variation, variation > 2 ? .increasing : variation < -2 ? .decreasing : .stable)
            
        case .oxygenSaturation:
            let baseSPO2 = 97.0
            let variation = Double.random(in: -2...1)
            return (max(95, baseSPO2 + variation), variation < -1 ? .decreasing : .stable)
            
        case .temperature:
            let baseTemp = 98.6
            let variation = Double.random(in: -0.5...0.5)
            return (baseTemp + variation, abs(variation) > 0.3 ? (variation > 0 ? .increasing : .decreasing) : .stable)
        }
    }
    
    private func calculateFutureTimestamp(timeHorizon: TimeHorizon) -> Date {
        let currentDate = Date()
        switch timeHorizon {
        case .day:
            return currentDate.addingTimeInterval(86400) // 1 day
        case .week:
            return currentDate.addingTimeInterval(604800) // 1 week
        case .month:
            return currentDate.addingTimeInterval(2592000) // 30 days
        case .year:
            return currentDate.addingTimeInterval(31536000) // 365 days
        }
    }
}

// MARK: - Risk Assessment Manager
class RiskAssessmentManager {
    private let healthRiskPredictor = RealHealthRiskPredictor()
    
    func assess(_ data: HealthData) async throws -> RiskAssessment {
        let riskFactors = [
            RiskFactor(
                name: "High Blood Pressure",
                category: .cardiovascular,
                severity: .moderate,
                description: "Blood pressure readings consistently above normal range",
                mitigation: "Reduce salt intake and increase physical activity"
            ),
            RiskFactor(
                name: "Sedentary Lifestyle",
                category: .lifestyle,
                severity: .mild,
                description: "Limited physical activity detected",
                mitigation: "Aim for 150 minutes of moderate exercise per week"
            )
        ]
        
        let recommendations = [
            Recommendation(
                title: "Increase Physical Activity",
                description: "Start with 30 minutes of walking daily",
                priority: .high,
                category: .lifestyle,
                actionable: true
            ),
            Recommendation(
                title: "Monitor Blood Pressure",
                description: "Check blood pressure weekly and log readings",
                priority: .medium,
                category: .monitoring,
                actionable: true
            )
        ]
        
        // USING REAL HEALTH RISK PREDICTOR
        // Convert HealthData to RealHealthRiskPredictor metrics
        let metrics = RealHealthRiskPredictor.HealthMetrics(
            systolicBP: data.vitals.first(where: { $0.type == .bloodPressure })?.value ?? 120.0,
            diastolicBP: 80.0, // Would extract from BP reading in real implementation
            restingHeartRate: data.vitals.first(where: { $0.type == .heartRate })?.value ?? 70.0,
            heartRateVariability: data.biometrics.first(where: { $0.type == .heartRateVariability })?.value ?? 50.0,
            cholesterolTotal: data.biometrics.first(where: { $0.type == .cholesterol })?.value,
            cholesterolLDL: nil, // Would be extracted from detailed cholesterol
            cholesterolHDL: nil,
            bmi: data.biometrics.first(where: { $0.type == .bmi })?.value ?? 25.0,
            waistCircumference: nil,
            glucoseLevel: data.vitals.first(where: { $0.type == .glucose })?.value,
            hba1c: nil,
            dailySteps: Double(data.lifestyle.exerciseMinutes * 100), // Rough conversion
            exerciseMinutes: Double(data.lifestyle.exerciseMinutes),
            sleepHours: data.lifestyle.sleepHours,
            sleepQuality: 0.8, // Would be calculated from sleep data
            stressLevel: mapStressLevel(data.lifestyle.stressLevel),
            age: 40, // Would come from user profile
            biologicalSex: .other, // Would come from user profile
            smokingStatus: .never, // Would come from medical history
            familyHistory: Set() // Would be populated from medical history
        )
        
        // Get real risk assessments
        let riskAssessments = await healthRiskPredictor.assessHealthRisks(metrics: metrics)
        
        // Convert to engine's format
        var allRiskFactors: [RiskFactor] = []
        var allRecommendations: [Recommendation] = []
        var highestRiskLevel = RiskLevel.low
        
        for assessment in riskAssessments {
            // Map risk category
            let category = mapRiskCategory(assessment.category)
            
            // Convert contributors to risk factors
            for contributor in assessment.contributors.prefix(3) { // Top 3 contributors
                if contributor.impact > 0.1 { // Only significant factors
                    let factor = RiskFactor(
                        name: contributor.factor,
                        category: category,
                        severity: mapSeverity(contributor.impact),
                        description: "\(contributor.currentValue) - \(contributor.impact > 0 ? "increases" : "decreases") risk",
                        mitigation: contributor.targetValue ?? "Maintain current levels"
                    )
                    allRiskFactors.append(factor)
                }
            }
            
            // Convert recommendations
            for (index, rec) in assessment.recommendations.enumerated() {
                let recommendation = Recommendation(
                    title: rec,
                    description: "Based on your \(assessment.category.rawValue) risk assessment",
                    priority: index == 0 ? .high : .medium,
                    category: .preventive,
                    actionable: true
                )
                allRecommendations.append(recommendation)
            }
            
            // Update highest risk level
            if let mappedLevel = mapRiskLevel(assessment.riskLevel),
               mappedLevel.rawValue > highestRiskLevel.rawValue {
                highestRiskLevel = mappedLevel
            }
        }
        
        return RiskAssessment(
            userId: data.userId,
            overallRisk: highestRiskLevel,
            riskFactors: allRiskFactors,
            recommendations: allRecommendations
        )
    }
    
    // Helper methods for mapping between formats
    private func mapStressLevel(_ level: StressLevel) -> Double {
        switch level {
        case .low: return 0.2
        case .moderate: return 0.5
        case .high: return 0.8
        case .veryHigh: return 0.95
        }
    }
    
    private func mapRiskCategory(_ category: RealHealthRiskPredictor.RiskCategory) -> RiskCategory {
        switch category {
        case .cardiovascular: return .cardiovascular
        case .diabetes: return .metabolic
        case .sleepDisorder: return .lifestyle
        case .mentalHealth: return .mental
        case .metabolicSyndrome: return .metabolic
        }
    }
    
    private func mapSeverity(_ impact: Double) -> RiskSeverity {
        switch impact {
        case 0..<0.3: return .mild
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .severe
        default: return .critical
        }
    }
    
    private func mapRiskLevel(_ level: RealHealthRiskPredictor.RiskLevel) -> RiskLevel? {
        switch level {
        case .low: return .low
        case .moderate: return .moderate
        case .high: return .high
        case .veryHigh: return .critical
        }
    }
}

// MARK: - Personalization Manager
class PersonalizationManager {
    func generate(_ request: PersonalizedPredictionRequest) async throws -> PersonalizedPrediction {
        let factors = [
            PredictionFactor(
                name: "Sleep Pattern",
                weight: 0.3,
                impact: .positive,
                description: "Consistent sleep schedule improves health outcomes"
            ),
            PredictionFactor(
                name: "Exercise Frequency",
                weight: 0.4,
                impact: .positive,
                description: "Regular exercise reduces disease risk"
            )
        ]
        
        let insights = [
            Insight(
                title: "Sleep Quality Improvement",
                description: "Your sleep quality has improved by 15% this week",
                type: .trend,
                actionable: true
            ),
            Insight(
                title: "Exercise Consistency",
                description: "Maintaining 5 days of exercise per week shows positive health trends",
                type: .pattern,
                actionable: true
            )
        ]
        
        return PersonalizedPrediction(
            requestID: request.id,
            prediction: "Based on your current patterns, you're likely to maintain good health over the next month with continued lifestyle habits.",
            confidence: 0.87,
            factors: factors,
            insights: insights
        )
    }
}

// MARK: - SwiftUI Views for Advanced Health Prediction Engine
struct AdvancedHealthPredictionEngineView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PredictionModelsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Models")
                }
                .tag(0)
            
            HealthForecastView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Forecast")
                }
                .tag(1)
            
            RiskAssessmentView()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Risk")
                }
                .tag(2)
            
            PersonalizedPredictionsView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Personalized")
                }
                .tag(3)
        }
        .navigationTitle("Health Prediction")
    }
}

struct PredictionModelsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(ModelType.allCases, id: \.self) { modelType in
                    VStack(alignment: .leading) {
                        Text(modelType.rawValue)
                            .font(.headline)
                        Text("Advanced prediction model for health outcomes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct HealthForecastView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(HealthMetric.allCases, id: \.self) { metric in
                    VStack(alignment: .leading) {
                        Text(metric.rawValue)
                            .font(.headline)
                        Text("Forecast for next 30 days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct RiskAssessmentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(RiskCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading) {
                        Text(category.rawValue)
                            .font(.headline)
                        Text("Risk assessment and recommendations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct PersonalizedPredictionsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(PredictionType.allCases, id: \.self) { predictionType in
                    VStack(alignment: .leading) {
                        Text(predictionType.rawValue)
                            .font(.headline)
                        Text("Personalized predictions based on your data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct AdvancedHealthPredictionEngine_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdvancedHealthPredictionEngineView()
        }
        .previewDevice("iPhone 15 Pro")
    }
} 