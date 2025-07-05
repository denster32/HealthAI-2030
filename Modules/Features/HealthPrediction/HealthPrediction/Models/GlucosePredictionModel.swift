import Foundation
import MLX
import SwiftData

/// Glucose prediction model using MLX for diabetes management
public class GlucosePredictionModel: ObservableObject {
    public static let shared = GlucosePredictionModel()
    
    @Published public var isModelLoaded = false
    @Published public var predictionInProgress = false
    
    private var model: MLXModel?
    private let modelURL = Bundle.main.url(forResource: "glucose_prediction_model", withExtension: "mlx")
    private let analytics = DeepHealthAnalytics.shared
    
    private init() {
        loadModel()
    }
    
    /// Load the MLX model
    private func loadModel() {
        guard let modelURL = modelURL else {
            print("Glucose prediction model not found")
            return
        }
        
        Task {
            do {
                model = try MLXModel.load(from: modelURL)
                await MainActor.run {
                    isModelLoaded = true
                }
                analytics.logEvent("glucose_model_loaded", parameters: ["success": true])
            } catch {
                print("Failed to load glucose prediction model: \(error)")
                analytics.logEvent("glucose_model_load_failed", parameters: ["error": error.localizedDescription])
            }
        }
    }
    
    /// Predict glucose levels for the next few hours
    public func predictGlucose(
        healthData: [HealthData],
        userProfile: UserProfile?,
        timeHorizon: TimeHorizon = .twoHours
    ) async -> GlucosePrediction {
        guard isModelLoaded, let model = model else {
            return GlucosePrediction(
                predictions: [],
                confidence: 0,
                trends: [],
                alerts: [],
                error: "Model not loaded"
            )
        }
        
        await MainActor.run {
            predictionInProgress = true
        }
        
        defer {
            Task { @MainActor in
                predictionInProgress = false
            }
        }
        
        do {
            // Prepare input features
            let features = prepareFeatures(healthData: healthData, userProfile: userProfile, timeHorizon: timeHorizon)
            
            // Run prediction
            let prediction = try await runPrediction(model: model, features: features, timeHorizon: timeHorizon)
            
            // Analyze trends and generate alerts
            let analysis = analyzeGlucoseTrends(predictions: prediction.predictions, userProfile: userProfile)
            
            let result = GlucosePrediction(
                predictions: prediction.predictions,
                confidence: prediction.confidence,
                trends: analysis.trends,
                alerts: analysis.alerts,
                error: nil
            )
            
            analytics.logEvent("glucose_prediction_completed", parameters: [
                "time_horizon": timeHorizon.rawValue,
                "confidence": prediction.confidence,
                "prediction_count": prediction.predictions.count
            ])
            
            return result
            
        } catch {
            analytics.logEvent("glucose_prediction_failed", parameters: [
                "error": error.localizedDescription
            ])
            
            return GlucosePrediction(
                predictions: [],
                confidence: 0,
                trends: [],
                alerts: [],
                error: error.localizedDescription
            )
        }
    }
    
    /// Prepare input features for the model
    private func prepareFeatures(
        healthData: [HealthData],
        userProfile: UserProfile?,
        timeHorizon: TimeHorizon
    ) -> [String: MLXArray] {
        let recentData = healthData.suffix(48) // Last 48 hours
        
        // Current time features
        let now = Date()
        let calendar = Calendar.current
        let hourOfDay = Double(calendar.component(.hour, from: now))
        let dayOfWeek = Double(calendar.component(.weekday, from: now))
        
        // Recent glucose readings (if available)
        let recentGlucose = recentData.compactMap { $0.glucoseLevel }
        let currentGlucose = recentGlucose.last ?? 100.0
        let glucoseTrend = calculateTrend(recentGlucose)
        
        // Activity and exercise features
        let recentActivity = recentData.compactMap { $0.activityLevel }
        let avgActivity = recentActivity.reduce(0, +) / max(recentActivity.count, 1)
        let activityTrend = calculateTrend(recentActivity)
        
        // Sleep features
        let recentSleep = recentData.compactMap { $0.sleepDuration }
        let avgSleep = recentSleep.reduce(0, +) / max(recentSleep.count, 1)
        let sleepQuality = recentData.compactMap { $0.sleepScore }.reduce(0, +) / max(recentData.count, 1)
        
        // Stress and heart rate features
        let recentStress = recentData.compactMap { $0.stressLevel }
        let avgStress = recentStress.reduce(0, +) / max(recentStress.count, 1)
        let recentHR = recentData.compactMap { $0.heartRate }
        let avgHR = recentHR.reduce(0, +) / max(recentHR.count, 1)
        
        // Meal timing features (simulated - in real app would come from meal logging)
        let lastMealTime = calculateLastMealTime(now: now)
        let mealType = determineMealType(hour: hourOfDay)
        
        // User profile features
        let hasDiabetes = userProfile?.hasDiabetes ?? false ? 1.0 : 0.0
        let diabetesType = userProfile?.diabetesType == "type1" ? 1.0 : 0.0
        let insulinSensitivity = userProfile?.insulinSensitivity ?? 1.0
        let carbRatio = userProfile?.carbRatio ?? 15.0
        
        // Create feature array
        let features: [Float] = [
            Float(currentGlucose),
            Float(glucoseTrend),
            Float(avgActivity),
            Float(activityTrend),
            Float(avgSleep),
            Float(sleepQuality),
            Float(avgStress),
            Float(avgHR),
            Float(hourOfDay),
            Float(dayOfWeek),
            Float(lastMealTime),
            Float(mealType),
            Float(hasDiabetes),
            Float(diabetesType),
            Float(insulinSensitivity),
            Float(carbRatio),
            Float(timeHorizon.hours)
        ]
        
        return [
            "features": MLXArray(features).reshaped([1, features.count])
        ]
    }
    
    /// Run prediction using MLX model
    private func runPrediction(
        model: MLXModel,
        features: [String: MLXArray],
        timeHorizon: TimeHorizon
    ) async throws -> (predictions: [GlucosePredictionPoint], confidence: Double) {
        let outputs = try model.predict(features)
        
        guard let predictionsArray = outputs["predictions"] as? MLXArray,
              let confidenceArray = outputs["confidence"] as? MLXArray else {
            throw PredictionError.invalidOutput
        }
        
        let confidence = Double(confidenceArray.item() as! Float)
        
        // Convert predictions array to prediction points
        let predictions = try createPredictionPoints(
            from: predictionsArray,
            timeHorizon: timeHorizon
        )
        
        return (predictions, confidence)
    }
    
    /// Create prediction points from model output
    private func createPredictionPoints(
        from predictionsArray: MLXArray,
        timeHorizon: TimeHorizon
    ) throws -> [GlucosePredictionPoint] {
        let predictions = Array(predictionsArray.flattened()) as! [Float]
        let now = Date()
        let intervalMinutes = timeHorizon.minutes / predictions.count
        
        return predictions.enumerated().map { index, glucose in
            let timestamp = now.addingTimeInterval(TimeInterval(index * intervalMinutes * 60))
            return GlucosePredictionPoint(
                timestamp: timestamp,
                glucoseLevel: Double(glucose),
                confidence: 0.85 // Default confidence for individual points
            )
        }
    }
    
    /// Analyze glucose trends and generate alerts
    private func analyzeGlucoseTrends(
        predictions: [GlucosePredictionPoint],
        userProfile: UserProfile?
    ) -> (trends: [GlucoseTrend], alerts: [GlucoseAlert]) {
        var trends: [GlucoseTrend] = []
        var alerts: [GlucoseAlert] = []
        
        guard predictions.count >= 2 else {
            return (trends, alerts)
        }
        
        // Calculate overall trend
        let firstGlucose = predictions.first!.glucoseLevel
        let lastGlucose = predictions.last!.glucoseLevel
        let trendDirection: TrendDirection
        
        if lastGlucose > firstGlucose + 20 {
            trendDirection = .rising
        } else if lastGlucose < firstGlucose - 20 {
            trendDirection = .falling
        } else {
            trendDirection = .stable
        }
        
        trends.append(GlucoseTrend(
            direction: trendDirection,
            magnitude: abs(lastGlucose - firstGlucose),
            timeRange: predictions.first!.timestamp...predictions.last!.timestamp
        ))
        
        // Check for critical levels
        for prediction in predictions {
            if prediction.glucoseLevel > 300 {
                alerts.append(GlucoseAlert(
                    type: .highGlucose,
                    severity: .critical,
                    message: "Glucose predicted to reach dangerously high levels",
                    timestamp: prediction.timestamp,
                    glucoseLevel: prediction.glucoseLevel
                ))
            } else if prediction.glucoseLevel > 250 {
                alerts.append(GlucoseAlert(
                    type: .highGlucose,
                    severity: .warning,
                    message: "Glucose predicted to be elevated",
                    timestamp: prediction.timestamp,
                    glucoseLevel: prediction.glucoseLevel
                ))
            } else if prediction.glucoseLevel < 70 {
                alerts.append(GlucoseAlert(
                    type: .lowGlucose,
                    severity: .critical,
                    message: "Glucose predicted to drop to dangerous levels",
                    timestamp: prediction.timestamp,
                    glucoseLevel: prediction.glucoseLevel
                ))
            } else if prediction.glucoseLevel < 80 {
                alerts.append(GlucoseAlert(
                    type: .lowGlucose,
                    severity: .warning,
                    message: "Glucose predicted to be low",
                    timestamp: prediction.timestamp,
                    glucoseLevel: prediction.glucoseLevel
                ))
            }
        }
        
        // Check for rapid changes
        for i in 1..<predictions.count {
            let change = predictions[i].glucoseLevel - predictions[i-1].glucoseLevel
            let timeDiff = predictions[i].timestamp.timeIntervalSince(predictions[i-1].timestamp) / 60 // minutes
            
            if abs(change) > 50 && timeDiff < 60 {
                alerts.append(GlucoseAlert(
                    type: .rapidChange,
                    severity: .warning,
                    message: "Rapid glucose change predicted",
                    timestamp: predictions[i].timestamp,
                    glucoseLevel: predictions[i].glucoseLevel
                ))
            }
        }
        
        return (trends, alerts)
    }
    
    /// Calculate trend from a series of values
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let first = values.first!
        let last = values.last!
        return last - first
    }
    
    /// Calculate time since last meal (simulated)
    private func calculateLastMealTime(now: Date) -> Double {
        // In a real app, this would come from meal logging
        // For now, simulate based on time of day
        let hour = Calendar.current.component(.hour, from: now)
        
        switch hour {
        case 6..<10: return 2.0 // Breakfast 2 hours ago
        case 10..<14: return 4.0 // Lunch 4 hours ago
        case 14..<18: return 6.0 // Snack 6 hours ago
        case 18..<22: return 8.0 // Dinner 8 hours ago
        default: return 12.0 // No recent meal
        }
    }
    
    /// Determine meal type based on hour
    private func determineMealType(hour: Double) -> Double {
        switch hour {
        case 6..<10: return 1.0 // Breakfast
        case 10..<14: return 2.0 // Lunch
        case 14..<18: return 3.0 // Snack
        case 18..<22: return 4.0 // Dinner
        default: return 0.0 // No meal
        }
    }
}

// MARK: - Data Models

public struct GlucosePrediction {
    public let predictions: [GlucosePredictionPoint]
    public let confidence: Double
    public let trends: [GlucoseTrend]
    public let alerts: [GlucoseAlert]
    public let error: String?
    
    public init(predictions: [GlucosePredictionPoint], confidence: Double, trends: [GlucoseTrend], alerts: [GlucoseAlert], error: String?) {
        self.predictions = predictions
        self.confidence = confidence
        self.trends = trends
        self.alerts = alerts
        self.error = error
    }
}

public struct GlucosePredictionPoint {
    public let timestamp: Date
    public let glucoseLevel: Double
    public let confidence: Double
    
    public init(timestamp: Date, glucoseLevel: Double, confidence: Double) {
        self.timestamp = timestamp
        self.glucoseLevel = glucoseLevel
        self.confidence = confidence
    }
}

public struct GlucoseTrend {
    public let direction: TrendDirection
    public let magnitude: Double
    public let timeRange: ClosedRange<Date>
    
    public init(direction: TrendDirection, magnitude: Double, timeRange: ClosedRange<Date>) {
        self.direction = direction
        self.magnitude = magnitude
        self.timeRange = timeRange
    }
}

public enum TrendDirection: String, CaseIterable {
    case rising = "Rising"
    case falling = "Falling"
    case stable = "Stable"
}

public struct GlucoseAlert {
    public let type: AlertType
    public let severity: AlertSeverity
    public let message: String
    public let timestamp: Date
    public let glucoseLevel: Double
    
    public init(type: AlertType, severity: AlertSeverity, message: String, timestamp: Date, glucoseLevel: Double) {
        self.type = type
        self.severity = severity
        self.message = message
        self.timestamp = timestamp
        self.glucoseLevel = glucoseLevel
    }
}

public enum AlertType: String, CaseIterable {
    case highGlucose = "High Glucose"
    case lowGlucose = "Low Glucose"
    case rapidChange = "Rapid Change"
    case trendWarning = "Trend Warning"
}

public enum AlertSeverity: String, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
    
    public var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

public enum TimeHorizon: String, CaseIterable {
    case oneHour = "1 Hour"
    case twoHours = "2 Hours"
    case fourHours = "4 Hours"
    case sixHours = "6 Hours"
    
    public var hours: Int {
        switch self {
        case .oneHour: return 1
        case .twoHours: return 2
        case .fourHours: return 4
        case .sixHours: return 6
        }
    }
    
    public var minutes: Int {
        return hours * 60
    }
} 