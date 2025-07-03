import Foundation
import HealthKit

// MARK: - Core Health Models

struct HealthMetrics: Codable {
    let heartRate: Double
    let hrv: Double
    let oxygenSaturation: Double
    let bodyTemperature: Double
    let stepCount: Int
    let activeEnergyBurned: Double
    let timestamp: Date
}

// New struct for HealthDataSnapshot, used for Core Data and CloudKit sync
struct HealthDataSnapshot: Codable {
    let heartRate: Double
    let hrv: Double
    let oxygenSaturation: Double
    let bodyTemperature: Double
    let stepCount: Int
    let activeEnergyBurned: Double
    let sleepData: [SleepDataSnapshot] // Placeholder for sleep data
    let timestamp: Date
}

// New struct for SleepDataSnapshot, used for Core Data and CloudKit sync
struct SleepDataSnapshot: Codable {
    let startDate: Date
    let endDate: Date
    let sleepStage: Int
    let timestamp: Date
}

// New struct for SleepReport, used for Core Data and CloudKit sync
struct SleepReport: Codable {
    let date: Date
    let totalSleepTime: TimeInterval
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let sleepQuality: Double
    let timestamp: Date
}

struct SleepMetrics {
    let totalSleepTime: TimeInterval
    let deepSleepTime: TimeInterval
    let remSleepTime: TimeInterval
    let lightSleepTime: TimeInterval
    let sleepEfficiency: Double
    let sleepLatency: TimeInterval
    let wakeCount: Int
    let timestamp: Date
}

struct ExerciseMetrics {
    let duration: TimeInterval
    let caloriesBurned: Double
    let averageHeartRate: Double
    let maxHeartRate: Double
    let exerciseType: String
    let timestamp: Date
}

struct NutritionMetrics {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double
    let water: Double
    let timestamp: Date
}

// MARK: - Health Status Models

struct HealthStatus {
    let overallScore: Double
    let cardiovascularHealth: Double
    let respiratoryHealth: Double
    let metabolicHealth: Double
    let musculoskeletalHealth: Double
    let mentalHealth: Double
    let timestamp: Date
}

struct HealthTrend {
    let metric: String
    let values: [Double]
    let timestamps: [Date]
    let trend: TrendDirection
    let confidence: Double
}

enum TrendDirection {
    case improving
    case declining
    case stable
    case unknown
}

// MARK: - Alert and Notification Models

struct HealthAlert {
    let id: UUID
    let type: AlertType
    let severity: AlertSeverity
    let title: String
    let message: String
    let recommendedAction: String
    let timestamp: Date
    let isRead: Bool
}

enum AlertType: String, CaseIterable {
    case cardiovascular = "cardiovascular"
    case respiratory = "respiratory"
    case metabolic = "metabolic"
    case sleep = "sleep"
    case exercise = "exercise"
    case nutrition = "nutrition"
    case environmental = "environmental"
    case general = "general"
}

enum AlertSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Goal and Achievement Models

struct HealthGoal {
    let id: UUID
    let type: GoalType
    let target: Double
    let current: Double
    let unit: String
    let deadline: Date
    let isCompleted: Bool
    let progress: Double
}

enum GoalType: String, CaseIterable {
    case steps = "steps"
    case sleep = "sleep"
    case exercise = "exercise"
    case heartRate = "heartRate"
    case weight = "weight"
    case nutrition = "nutrition"
    case meditation = "meditation"
}

struct Achievement {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let dateEarned: Date
    let category: AchievementCategory
}

enum AchievementCategory: String, CaseIterable {
    case fitness = "fitness"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case consistency = "consistency"
    case milestone = "milestone"
}

// MARK: - User Profile Models

struct UserProfile {
    let id: UUID
    let name: String
    let age: Int
    let gender: Gender
    let height: Double
    let weight: Double
    let activityLevel: ActivityLevel
    let healthConditions: [HealthCondition]
    let medications: [Medication]
    let preferences: UserPreferences
}

enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"
    case preferNotToSay = "preferNotToSay"
}

enum ActivityLevel: String, CaseIterable {
    case sedentary = "sedentary"
    case lightlyActive = "lightlyActive"
    case moderatelyActive = "moderatelyActive"
    case veryActive = "veryActive"
    case extremelyActive = "extremelyActive"
}

struct HealthCondition {
    let name: String
    let severity: String
    let diagnosedDate: Date
    let isManaged: Bool
}

struct Medication {
    let name: String
    let dosage: String
    let frequency: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
}

struct UserPreferences {
    let notificationsEnabled: Bool
    let sleepGoal: TimeInterval
    let stepGoal: Int
    let exerciseGoal: TimeInterval
    let privacyLevel: PrivacyLevel
    let dataSharing: DataSharingPreferences
}

enum PrivacyLevel: String, CaseIterable {
    case minimal = "minimal"
    case standard = "standard"
    case strict = "strict"
    case maximum = "maximum"
}

struct DataSharingPreferences {
    let shareWithHealthcare: Bool
    let shareWithResearch: Bool
    let shareWithFamily: Bool
    let shareAnonymized: Bool
}

// MARK: - Device and Sensor Models

struct DeviceInfo {
    let id: String
    let name: String
    let type: DeviceType
    let model: String
    let firmwareVersion: String
    let batteryLevel: Double
    let isConnected: Bool
    let lastSync: Date
}

enum DeviceType: String, CaseIterable {
    case iPhone = "iPhone"
    case appleWatch = "AppleWatch"
    case iPad = "iPad"
    case mac = "Mac"
    case appleTV = "AppleTV"
    case visionPro = "VisionPro"
    case thirdParty = "ThirdParty"
}

struct SensorData {
    let sensorType: SensorType
    let value: Double
    let unit: String
    let accuracy: Double
    let timestamp: Date
    let deviceId: String
}

// MARK: - Raw Sensor Sample Model
struct SensorSample: Codable, Identifiable {
    let id = UUID()
    let type: SensorType
    let value: Double
    let unit: String
    let timestamp: Date
    
    init(type: HKQuantityTypeIdentifier, value: Double, unit: String, timestamp: Date) {
        switch type {
        case .heartRate: self.type = .heartRate
        case .heartRateVariabilitySDNN: self.type = .hrv
        case .oxygenSaturation: self.type = .oxygenSaturation
        case .bodyTemperature: self.type = .bodyTemperature
        case .stepCount: self.type = .steps
        case .activeEnergyBurned: self.type = .calories
        case .walkingSpeed: self.type = .distance // Closest match for walking speed
        default: self.type = .unknown // Add a default or handle other types as needed
        }
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
    
    init(type: SensorType, value: Double, unit: String, timestamp: Date) {
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}

enum SensorType: String, CaseIterable {
    case heartRate = "heartRate"
    case hrv = "hrv"
    case oxygenSaturation = "oxygenSaturation"
    case bodyTemperature = "bodyTemperature"
    case bloodPressure = "bloodPressure"
    case glucose = "glucose"
    case steps = "steps"
    case distance = "distance"
    case calories = "calories"
    case sleep = "sleep"
    case ecg = "ecg"
    case accelerometer = "accelerometer"
    case gyroscope = "gyroscope"
    case magnetometer = "magnetometer"
    case unknown = "unknown" // Added unknown case
    case sensorSampleEntity = "sensorSampleEntity" // Added for Core Data integration
}

// MARK: - Analytics and Insights Models

struct HealthInsight {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let impact: Double
    let confidence: Double
    let timestamp: Date
    let actionable: Bool
    let actionTitle: String?
    let actionDescription: String?
}

enum InsightType: String, CaseIterable {
    case sleep = "sleep"
    case activity = "activity"
    case nutrition = "nutrition"
    case stress = "stress"
    case recovery = "recovery"
    case trend = "trend"
    case correlation = "correlation"
    case prediction = "prediction"
}

struct HealthCorrelation {
    let factor1: String
    let factor2: String
    let correlation: Double
    let significance: Double
    let sampleSize: Int
    let timestamp: Date
}

struct HealthPrediction {
    let metric: String
    let predictedValue: Double
    let confidence: Double
    let timeframe: TimeInterval
    let factors: [String]
    let timestamp: Date
}

// MARK: - Workout and Activity Models

struct WorkoutSession {
    let id: UUID
    let type: WorkoutType
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let caloriesBurned: Double
    let distance: Double?
    let averageHeartRate: Double
    let maxHeartRate: Double
    let route: [Location]?
    let notes: String?
}

enum WorkoutType: String, CaseIterable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case strength = "strength"
    case yoga = "yoga"
    case meditation = "meditation"
    case other = "other"
}

struct Location {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let timestamp: Date
    let accuracy: Double?
}

// MARK: - Sleep Analysis Models

struct SleepAnalysis {
    let id: UUID
    let date: Date
    let stages: [SleepStage]
    let totalSleepTime: TimeInterval
    let sleepEfficiency: Double
    let sleepLatency: TimeInterval
    let wakeCount: Int
    let remCount: Int
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let lightSleepPercentage: Double
    let awakePercentage: Double
}

struct SleepStage: Codable, Hashable {
    let type: SleepStageType
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let confidence: Double
}

enum SleepStageType: String, CaseIterable, Hashable {
    case awake = "awake"
    case lightSleep = "lightSleep"
    case deepSleep = "deepSleep"
    case remSleep = "remSleep"
    case unknown = "unknown"
}

// MARK: - Extensions for Codable Support

extension SleepMetrics: Codable {}
extension ExerciseMetrics: Codable {}
extension NutritionMetrics: Codable {}
extension HealthStatus: Codable {}
extension HealthTrend: Codable {}
extension HealthAlert: Codable {}
extension HealthGoal: Codable {}
extension Achievement: Codable {}
extension UserProfile: Codable {}
extension HealthCondition: Codable {}
extension Medication: Codable {}
extension UserPreferences: Codable {}
extension DataSharingPreferences: Codable {}
extension DeviceInfo: Codable {}
extension SensorData: Codable {}
extension HealthInsight: Codable {}
extension HealthCorrelation: Codable {}
extension HealthPrediction: Codable {}
extension WorkoutSession: Codable {}
extension Location: Codable {}
extension SleepAnalysis: Codable {}
extension SleepStage: Codable {}
extension SensorSample: Codable {}

// MARK: - Identifiable Conformance

extension HealthAlert: Identifiable {}
extension HealthGoal: Identifiable {}
extension Achievement: Identifiable {}
extension UserProfile: Identifiable {}
extension HealthInsight: Identifiable {}
extension WorkoutSession: Identifiable {}
extension SleepAnalysis: Identifiable {}
extension SleepStage: Identifiable {} 