import Foundation

/// Types of health metrics that can be tracked and analyzed
public enum MetricType: String, CaseIterable, Codable {
    case heartRate = "heart_rate"
    case bloodPressure = "blood_pressure"
    case bloodOxygen = "blood_oxygen"
    case bodyTemperature = "body_temperature"
    case sleepDuration = "sleep_duration"
    case sleepQuality = "sleep_quality"
    case stepCount = "step_count"
    case caloriesBurned = "calories_burned"
    case waterIntake = "water_intake"
    case weight = "weight"
    case glucose = "glucose"
    case stressLevel = "stress_level"
    case moodScore = "mood_score"
    case exerciseMinutes = "exercise_minutes"
    case respiratoryRate = "respiratory_rate"
    case vo2Max = "vo2_max"
    case restingHeartRate = "resting_heart_rate"
    case heartRateVariability = "heart_rate_variability"
    case mentalHealthScore = "mental_health_score"
    case cognitiveFunctionScore = "cognitive_function_score"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .bloodPressure: return "Blood Pressure"
        case .bloodOxygen: return "Blood Oxygen"
        case .bodyTemperature: return "Body Temperature"
        case .sleepDuration: return "Sleep Duration"
        case .sleepQuality: return "Sleep Quality"
        case .stepCount: return "Step Count"
        case .caloriesBurned: return "Calories Burned"
        case .waterIntake: return "Water Intake"
        case .weight: return "Weight"
        case .glucose: return "Glucose"
        case .stressLevel: return "Stress Level"
        case .moodScore: return "Mood Score"
        case .exerciseMinutes: return "Exercise Minutes"
        case .respiratoryRate: return "Respiratory Rate"
        case .vo2Max: return "VO2 Max"
        case .restingHeartRate: return "Resting Heart Rate"
        case .heartRateVariability: return "Heart Rate Variability"
        case .mentalHealthScore: return "Mental Health Score"
        case .cognitiveFunctionScore: return "Cognitive Function Score"
        }
    }
    
    /// Unit of measurement
    public var unit: String {
        switch self {
        case .heartRate, .restingHeartRate: return "bpm"
        case .bloodPressure: return "mmHg"
        case .bloodOxygen: return "%"
        case .bodyTemperature: return "°F"
        case .sleepDuration, .exerciseMinutes: return "minutes"
        case .sleepQuality, .stressLevel, .moodScore, .mentalHealthScore, .cognitiveFunctionScore: return "score"
        case .stepCount: return "steps"
        case .caloriesBurned: return "calories"
        case .waterIntake: return "oz"
        case .weight: return "lbs"
        case .glucose: return "mg/dL"
        case .respiratoryRate: return "breaths/min"
        case .vo2Max: return "mL/kg/min"
        case .heartRateVariability: return "ms"
        }
    }
    
    /// Normal range for the metric
    public var normalRange: ClosedRange<Double> {
        switch self {
        case .heartRate: return 60...100
        case .bloodPressure: return 90...140  // Systolic
        case .bloodOxygen: return 95...100
        case .bodyTemperature: return 97...99.5
        case .sleepDuration: return 420...540  // 7-9 hours in minutes
        case .sleepQuality: return 70...100
        case .stepCount: return 8000...12000
        case .caloriesBurned: return 1800...2500
        case .waterIntake: return 64...100
        case .weight: return 100...200  // Approximate healthy range
        case .glucose: return 70...140
        case .stressLevel: return 0...30  // Lower is better
        case .moodScore: return 70...100
        case .exerciseMinutes: return 150...300  // Weekly recommendation
        case .respiratoryRate: return 12...20
        case .vo2Max: return 35...60
        case .restingHeartRate: return 60...100
        case .heartRateVariability: return 20...50
        case .mentalHealthScore: return 70...100
        case .cognitiveFunctionScore: return 70...100
        }
    }
}

/// A health metric data point
public struct HealthMetric: Codable, Identifiable, Hashable {
    public let id: UUID
    public let type: MetricType
    public let value: Double
    public let timestamp: Date
    public let source: String
    public let deviceId: String?
    public let accuracy: Double
    public let metadata: [String: String]
    
    public init(
        type: MetricType,
        value: Double,
        timestamp: Date = Date(),
        source: String = "HealthAI2030",
        deviceId: String? = nil,
        accuracy: Double = 1.0,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.timestamp = timestamp
        self.source = source
        self.deviceId = deviceId
        self.accuracy = accuracy
        self.metadata = metadata
    }
    
    /// Whether the metric value is within normal range
    public var isNormal: Bool {
        type.normalRange.contains(value)
    }
    
    /// Severity level based on deviation from normal range
    public var severityLevel: SeverityLevel {
        let range = type.normalRange
        if range.contains(value) {
            return .normal
        } else if value < range.lowerBound {
            let deviation = (range.lowerBound - value) / range.lowerBound
            return deviation > 0.2 ? .critical : .warning
        } else {
            let deviation = (value - range.upperBound) / range.upperBound
            return deviation > 0.2 ? .critical : .warning
        }
    }
}

/// Severity levels for health metrics
public enum SeverityLevel: String, Codable, CaseIterable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
    
    public var color: String {
        switch self {
        case .normal: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

/// Comprehensive analytics for a metric type
public struct MetricAnalytics: Codable {
    public let metricType: MetricType
    public let statistics: MetricStatistics
    public let trends: [Trend]
    public let anomalies: [Anomaly]
    public let predictions: [TrendPrediction]
    public let correlations: [MetricCorrelation]
    public let lastUpdated: Date
    
    public init(
        metricType: MetricType,
        statistics: MetricStatistics,
        trends: [Trend] = [],
        anomalies: [Anomaly] = [],
        predictions: [TrendPrediction] = [],
        correlations: [MetricCorrelation] = [],
        lastUpdated: Date = Date()
    ) {
        self.metricType = metricType
        self.statistics = statistics
        self.trends = trends
        self.anomalies = anomalies
        self.predictions = predictions
        self.correlations = correlations
        self.lastUpdated = lastUpdated
    }
}

/// Statistical summary of metric data
public struct MetricStatistics: Codable {
    public let mean: Double
    public let median: Double
    public let standardDeviation: Double
    public let minimum: Double
    public let maximum: Double
    public let count: Int
    public let variance: Double
    public let skewness: Double
    public let kurtosis: Double
    
    public init(
        mean: Double,
        median: Double,
        standardDeviation: Double,
        minimum: Double,
        maximum: Double,
        count: Int,
        variance: Double,
        skewness: Double,
        kurtosis: Double
    ) {
        self.mean = mean
        self.median = median
        self.standardDeviation = standardDeviation
        self.minimum = minimum
        self.maximum = maximum
        self.count = count
        self.variance = variance
        self.skewness = skewness
        self.kurtosis = kurtosis
    }
}

/// Trend information for a metric
public struct Trend: Codable, Identifiable {
    public let id: UUID
    public let direction: TrendDirection
    public let strength: Double  // 0.0 to 1.0
    public let duration: TimeInterval
    public let confidence: Double  // 0.0 to 1.0
    public let startDate: Date
    public let endDate: Date
    public let description: String
    
    public init(
        direction: TrendDirection,
        strength: Double,
        duration: TimeInterval,
        confidence: Double,
        startDate: Date,
        endDate: Date,
        description: String
    ) {
        self.id = UUID()
        self.direction = direction
        self.strength = strength
        self.duration = duration
        self.confidence = confidence
        self.startDate = startDate
        self.endDate = endDate
        self.description = description
    }
}

/// Direction of a trend
public enum TrendDirection: String, Codable, CaseIterable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
    case volatile = "volatile"
    
    public var displayName: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        case .volatile: return "Volatile"
        }
    }
    
    public var symbol: String {
        switch self {
        case .increasing: return "↗"
        case .decreasing: return "↘"
        case .stable: return "→"
        case .volatile: return "↕"
        }
    }
}

/// Anomaly detection result
public struct Anomaly: Codable, Identifiable {
    public let id: UUID
    public let metricType: MetricType
    public let value: Double
    public let timestamp: Date
    public let anomalyScore: Double  // 0.0 to 1.0, higher is more anomalous
    public let description: String
    public let severity: SeverityLevel
    public let possibleCauses: [String]
    
    public init(
        metricType: MetricType,
        value: Double,
        timestamp: Date,
        anomalyScore: Double,
        description: String,
        severity: SeverityLevel,
        possibleCauses: [String] = []
    ) {
        self.id = UUID()
        self.metricType = metricType
        self.value = value
        self.timestamp = timestamp
        self.anomalyScore = anomalyScore
        self.description = description
        self.severity = severity
        self.possibleCauses = possibleCauses
    }
}

/// Future trend prediction
public struct TrendPrediction: Codable, Identifiable {
    public let id: UUID
    public let metricType: MetricType
    public let predictedValue: Double
    public let predictionDate: Date
    public let confidence: Double  // 0.0 to 1.0
    public let predictionRange: ClosedRange<Double>
    public let model: String
    public let factors: [String]
    
    public init(
        metricType: MetricType,
        predictedValue: Double,
        predictionDate: Date,
        confidence: Double,
        predictionRange: ClosedRange<Double>,
        model: String,
        factors: [String] = []
    ) {
        self.id = UUID()
        self.metricType = metricType
        self.predictedValue = predictedValue
        self.predictionDate = predictionDate
        self.confidence = confidence
        self.predictionRange = predictionRange
        self.model = model
        self.factors = factors
    }
}

/// Correlation between two metrics
public struct MetricCorrelation: Codable, Identifiable {
    public let id: UUID
    public let primaryMetric: MetricType
    public let secondaryMetric: MetricType
    public let correlation: Double  // -1.0 to 1.0
    public let pValue: Double
    public let strength: CorrelationStrength
    public let description: String
    
    public init(
        primaryMetric: MetricType,
        secondaryMetric: MetricType,
        correlation: Double,
        pValue: Double,
        description: String
    ) {
        self.id = UUID()
        self.primaryMetric = primaryMetric
        self.secondaryMetric = secondaryMetric
        self.correlation = correlation
        self.pValue = pValue
        self.strength = CorrelationStrength.from(correlation: abs(correlation))
        self.description = description
    }
}

/// Strength of correlation
public enum CorrelationStrength: String, Codable, CaseIterable {
    case none = "none"          // 0.0 - 0.1
    case weak = "weak"          // 0.1 - 0.3
    case moderate = "moderate"  // 0.3 - 0.7
    case strong = "strong"      // 0.7 - 0.9
    case veryStrong = "very_strong"  // 0.9 - 1.0
    
    public static func from(correlation: Double) -> CorrelationStrength {
        let abs = Swift.abs(correlation)
        if abs >= 0.9 { return .veryStrong }
        if abs >= 0.7 { return .strong }
        if abs >= 0.3 { return .moderate }
        if abs >= 0.1 { return .weak }
        return .none
    }
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .weak: return "Weak"
        case .moderate: return "Moderate"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
}