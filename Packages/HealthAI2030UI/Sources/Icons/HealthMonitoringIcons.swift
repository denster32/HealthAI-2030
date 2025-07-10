import SwiftUI

// MARK: - Health Monitoring Icons
/// Comprehensive health monitoring icons for HealthAI 2030
/// Provides vital signs, biometric measurements, and health tracking icons
public struct HealthMonitoringIcons {
    
    // MARK: - Vital Signs Icons
    
    /// Heart rate monitoring icons
    public struct HeartRate {
        public static let heart = "heart.fill"
        public static let heartRate = "heart.circle.fill"
        public static let heartRateMonitor = "heart.circle"
        public static let heartRateGraph = "chart.line.uptrend.xyaxis"
        public static let heartRateAlert = "heart.slash.fill"
        public static let heartRateNormal = "heart.fill"
        public static let heartRateHigh = "heart.circle.fill"
        public static let heartRateLow = "heart.slash.circle.fill"
        public static let heartRateIrregular = "heart.circle"
        public static let heartRateTrend = "chart.xyaxis.line"
    }
    
    /// Blood pressure monitoring icons
    public struct BloodPressure {
        public static let bloodPressure = "drop.fill"
        public static let systolic = "drop.circle.fill"
        public static let diastolic = "drop.circle"
        public static let bloodPressureMonitor = "drop.degreesign"
        public static let bloodPressureHigh = "drop.fill"
        public static let bloodPressureLow = "drop.slash.fill"
        public static let bloodPressureNormal = "drop.circle.fill"
        public static let bloodPressureAlert = "exclamationmark.triangle.fill"
        public static let bloodPressureTrend = "chart.line.uptrend.xyaxis"
        public static let bloodPressureHistory = "clock.arrow.circlepath"
    }
    
    /// Temperature monitoring icons
    public struct Temperature {
        public static let temperature = "thermometer"
        public static let temperatureHigh = "thermometer.sun.fill"
        public static let temperatureLow = "thermometer.snowflake"
        public static let temperatureNormal = "thermometer"
        public static let temperatureFever = "thermometer.sun"
        public static let temperatureBody = "thermometer.medium"
        public static let temperatureTrend = "chart.line.uptrend.xyaxis"
        public static let temperatureAlert = "exclamationmark.triangle.fill"
        public static let temperatureHistory = "clock.arrow.circlepath"
        public static let temperatureMonitor = "thermometer.medium"
    }
    
    /// Oxygen saturation monitoring icons
    public struct Oxygen {
        public static let oxygenSaturation = "lungs.fill"
        public static let oxygenLevel = "lungs.circle.fill"
        public static let oxygenLow = "lungs.slash.fill"
        public static let oxygenNormal = "lungs.fill"
        public static let oxygenAlert = "exclamationmark.triangle.fill"
        public static let oxygenTrend = "chart.line.uptrend.xyaxis"
        public static let oxygenMonitor = "lungs.circle"
        public static let oxygenHistory = "clock.arrow.circlepath"
        public static let oxygenPulse = "waveform.path.ecg"
        public static let oxygenFlow = "wind"
    }
    
    // MARK: - Sleep Monitoring Icons
    
    /// Sleep tracking icons
    public struct Sleep {
        public static let sleep = "bed.double.fill"
        public static let sleepDeep = "bed.double.fill"
        public static let sleepLight = "bed.double"
        public static let sleepREM = "bed.double.fill"
        public static let sleepAwake = "bed.double"
        public static let sleepDuration = "clock.fill"
        public static let sleepQuality = "star.fill"
        public static let sleepTrend = "chart.line.uptrend.xyaxis"
        public static let sleepHistory = "clock.arrow.circlepath"
        public static let sleepScore = "chart.bar.fill"
    }
    
    /// Sleep stage icons
    public struct SleepStages {
        public static let stage1 = "bed.double"
        public static let stage2 = "bed.double.fill"
        public static let stage3 = "bed.double.fill"
        public static let stage4 = "bed.double.fill"
        public static let rem = "bed.double.fill"
        public static let awake = "bed.double"
        public static let deepSleep = "bed.double.fill"
        public static let lightSleep = "bed.double"
        public static let sleepCycle = "arrow.clockwise"
        public static let sleepPattern = "waveform.path.ecg"
    }
    
    // MARK: - Activity Monitoring Icons
    
    /// Physical activity icons
    public struct Activity {
        public static let steps = "figure.walk"
        public static let distance = "figure.walk.circle.fill"
        public static let calories = "flame.fill"
        public static let activeMinutes = "clock.fill"
        public static let exercise = "figure.run"
        public static let workout = "dumbbell.fill"
        public static let activityGoal = "target"
        public static let activityTrend = "chart.line.uptrend.xyaxis"
        public static let activityHistory = "clock.arrow.circlepath"
        public static let activityScore = "chart.bar.fill"
    }
    
    /// Exercise type icons
    public struct Exercise {
        public static let cardio = "heart.circle.fill"
        public static let strength = "dumbbell.fill"
        public static let flexibility = "figure.flexibility"
        public static let balance = "figure.mind.and.body"
        public static let yoga = "figure.mind.and.body"
        public static let swimming = "figure.pool.swim"
        public static let cycling = "bicycle"
        public static let running = "figure.run"
        public static let walking = "figure.walk"
        public static let hiking = "figure.hiking"
    }
    
    // MARK: - Nutrition Monitoring Icons
    
    /// Nutrition tracking icons
    public struct Nutrition {
        public static let food = "fork.knife"
        public static let water = "drop.fill"
        public static let calories = "flame.fill"
        public static let protein = "leaf.fill"
        public static let carbs = "circle.fill"
        public static let fat = "circle.fill"
        public static let fiber = "leaf"
        public static let vitamins = "pills.fill"
        public static let minerals = "circle.fill"
        public static let nutritionGoal = "target"
    }
    
    /// Food category icons
    public struct FoodCategories {
        public static let fruits = "leaf.fill"
        public static let vegetables = "leaf"
        public static let grains = "circle.fill"
        public static let protein = "dumbbell.fill"
        public static let dairy = "drop.fill"
        public static let fats = "circle.fill"
        public static let beverages = "cup.and.saucer.fill"
        public static let snacks = "circle.fill"
        public static let supplements = "pills.fill"
        public static let water = "drop.fill"
    }
    
    // MARK: - Mental Health Monitoring Icons
    
    /// Mental health tracking icons
    public struct MentalHealth {
        public static let mood = "face.smiling"
        public static let stress = "brain.head.profile"
        public static let anxiety = "brain.head.profile"
        public static let depression = "brain.head.profile"
        public static let mindfulness = "brain.head.profile"
        public static let meditation = "brain.head.profile"
        public static let sleep = "bed.double.fill"
        public static let energy = "bolt.fill"
        public static let focus = "target"
        public static let mentalHealthScore = "chart.bar.fill"
    }
    
    /// Mood tracking icons
    public struct Mood {
        public static let happy = "face.smiling.fill"
        public static let sad = "face.dashed"
        public static let angry = "face.dashed"
        public static let anxious = "face.dashed"
        public static let calm = "face.smiling"
        public static let excited = "face.smiling.fill"
        public static let tired = "face.dashed"
        public static let stressed = "face.dashed"
        public static let relaxed = "face.smiling"
        public static let moodTrend = "chart.line.uptrend.xyaxis"
    }
    
    // MARK: - Biometric Monitoring Icons
    
    /// Biometric measurement icons
    public struct Biometrics {
        public static let weight = "scalemass.fill"
        public static let bmi = "chart.bar.fill"
        public static let bodyFat = "circle.fill"
        public static let muscleMass = "dumbbell.fill"
        public static let boneDensity = "circle.fill"
        public static let hydration = "drop.fill"
        public static let bodyComposition = "chart.pie.fill"
        public static let biometricTrend = "chart.line.uptrend.xyaxis"
        public static let biometricHistory = "clock.arrow.circlepath"
        public static let biometricGoal = "target"
    }
    
    /// Body measurement icons
    public struct BodyMeasurements {
        public static let height = "ruler.fill"
        public static let waist = "circle.fill"
        public static let chest = "circle.fill"
        public static let arms = "circle.fill"
        public static let legs = "circle.fill"
        public static let neck = "circle.fill"
        public static let hips = "circle.fill"
        public static let bodyFat = "circle.fill"
        public static let muscleMass = "dumbbell.fill"
        public static let measurements = "ruler"
    }
    
    // MARK: - Health Trend Icons
    
    /// Trend analysis icons
    public struct Trends {
        public static let improving = "arrow.up.circle.fill"
        public static let declining = "arrow.down.circle.fill"
        public static let stable = "minus.circle.fill"
        public static let fluctuating = "arrow.up.arrow.down.circle.fill"
        public static let trendUp = "chart.line.uptrend.xyaxis"
        public static let trendDown = "chart.line.downtrend.xyaxis"
        public static let trendStable = "chart.line.xyaxis"
        public static let trendAlert = "exclamationmark.triangle.fill"
        public static let trendHistory = "clock.arrow.circlepath"
        public static let trendPrediction = "chart.line.uptrend.xyaxis"
    }
    
    /// Alert and notification icons
    public struct Alerts {
        public static let critical = "exclamationmark.triangle.fill"
        public static let warning = "exclamationmark.triangle"
        public static let info = "info.circle.fill"
        public static let success = "checkmark.circle.fill"
        public static let error = "xmark.circle.fill"
        public static let alert = "bell.fill"
        public static let notification = "bell"
        public static let reminder = "clock.fill"
        public static let emergency = "exclamationmark.triangle.fill"
        public static let attention = "eye.fill"
    }
}

// MARK: - Health Monitoring Icon Extensions
public extension HealthMonitoringIcons {
    
    /// Get icon for health metric type
    static func iconForMetric(_ metric: HealthMetricType) -> String {
        switch metric {
        case .heartRate:
            return HeartRate.heartRate
        case .bloodPressure:
            return BloodPressure.bloodPressure
        case .temperature:
            return Temperature.temperature
        case .oxygen:
            return Oxygen.oxygenSaturation
        case .sleep:
            return Sleep.sleep
        case .activity:
            return Activity.steps
        case .nutrition:
            return Nutrition.food
        case .mentalHealth:
            return MentalHealth.mood
        }
    }
    
    /// Get icon for trend direction
    static func iconForTrend(_ direction: TrendDirection) -> String {
        switch direction {
        case .improving:
            return Trends.improving
        case .declining:
            return Trends.declining
        case .stable:
            return Trends.stable
        case .critical:
            return Alerts.critical
        }
    }
    
    /// Get icon for alert level
    static func iconForAlertLevel(_ level: AlertLevel) -> String {
        switch level {
        case .critical:
            return Alerts.critical
        case .warning:
            return Alerts.warning
        case .info:
            return Alerts.info
        case .success:
            return Alerts.success
        }
    }
}

// MARK: - Supporting Enums
public enum AlertLevel {
    case critical
    case warning
    case info
    case success
} 