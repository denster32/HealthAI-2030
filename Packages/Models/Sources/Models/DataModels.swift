import Foundation
import HealthKit
import CoreML

// MARK: - Sleep Stage Enum
enum SleepStage: Int, CaseIterable, Codable {
    case awake = 0
    case light = 1
    case deep = 2
    case rem = 3
    case unknown = 4
    
    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light Sleep"
        case .deep: return "Deep Sleep"
        case .rem: return "REM Sleep"
        case .unknown: return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .awake: return "red"
        case .light: return "blue"
        case .deep: return "purple"
        case .rem: return "green"
        case .unknown: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .awake: return "eye"
        case .light: return "moon"
        case .deep: return "bed.double"
        case .rem: return "brain.head.profile"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Audio Types
enum AudioType: Equatable {
    case none
    case preSleep(PreSleepAudioType)
    case sleep(SleepAudioType)
    case custom(CustomSoundscape)
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .preSleep(let type): return "Pre-Sleep: \(type.displayName)"
        case .sleep(let type): return "Sleep: \(type.displayName)"
        case .custom(let soundscape): return "Custom: \(soundscape.name)"
        }
    }
}

enum PreSleepAudioType: Equatable {
    case binauralBeats(frequency: Double)
    case whiteNoise(color: NoiseColor)
    case natureSounds(environment: NatureEnvironment)
    case guidedMeditation(style: MeditationStyle)
    case ambientMusic(genre: AmbientGenre)
    
    var displayName: String {
        switch self {
        case .binauralBeats(let freq): return "Binaural Beats (\(Int(freq))Hz)"
        case .whiteNoise(let color): return "\(color.rawValue) Noise"
        case .natureSounds(let env): return "\(env.rawValue) Sounds"
        case .guidedMeditation(let style): return "\(style.rawValue) Meditation"
        case .ambientMusic(let genre): return "\(genre.rawValue) Music"
        }
    }
}

enum SleepAudioType: Equatable {
    case deepSleep(frequency: Double)
    case continuousWhiteNoise(color: NoiseColor)
    case oceanWaves(intensity: WaveIntensity)
    case rainSounds(intensity: RainIntensity)
    case forestAmbience(timeOfDay: TimeOfDay)
    
    var displayName: String {
        switch self {
        case .deepSleep(let freq): return "Deep Sleep (\(Int(freq))Hz)"
        case .continuousWhiteNoise(let color): return "Continuous \(color.rawValue) Noise"
        case .oceanWaves(let intensity): return "Ocean Waves (\(intensity.rawValue))"
        case .rainSounds(let intensity): return "Rain Sounds (\(intensity.rawValue))"
        case .forestAmbience(let time): return "Forest (\(time.rawValue))"
        }
    }
}

enum NoiseColor: String, CaseIterable {
    case white = "White"
    case pink = "Pink"
    case brown = "Brown"
}

enum NatureEnvironment: String, CaseIterable {
    case ocean = "Ocean"
    case forest = "Forest"
    case rain = "Rain"
    case stream = "Stream"
    case wind = "Wind"
}

enum MeditationStyle: String, CaseIterable {
    case mindfulness = "Mindfulness"
    case bodyScan = "Body Scan"
    case breathing = "Breathing"
    case lovingKindness = "Loving Kindness"
    case transcendental = "Transcendental"
}

enum AmbientGenre: String, CaseIterable {
    case drone = "Drone"
    case atmospheric = "Atmospheric"
    case minimal = "Minimal"
}

enum WaveIntensity: String, CaseIterable {
    case gentle = "Gentle"
    case moderate = "Moderate"
    case strong = "Strong"
}

enum RainIntensity: String, CaseIterable {
    case gentle = "Gentle"
    case moderate = "Moderate"
    case heavy = "Heavy"
}

enum TimeOfDay: String, CaseIterable {
    case dawn = "Dawn"
    case day = "Day"
    case dusk = "Dusk"
    case night = "Night"
}

enum EQPreset: String, CaseIterable {
    case neutral = "Neutral"
    case warm = "Warm"
    case bright = "Bright"
    case sleep = "Sleep"
    case meditation = "Meditation"
    case deep = "Deep"
    case natural = "Natural"
}

// MARK: - Biometric Data
struct BiometricData: Codable {
    let timestamp: Date
    let heartRate: Double
    let heartRateVariability: Double
    let movement: Double
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let temperature: Double
    let sleepStage: SleepStage?
    
    init(
        timestamp: Date = Date(),
        heartRate: Double = 0.0,
        heartRateVariability: Double = 0.0,
        movement: Double = 0.0,
        respiratoryRate: Double = 0.0,
        oxygenSaturation: Double = 0.0,
        temperature: Double = 0.0,
        sleepStage: SleepStage? = nil
    ) {
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.heartRateVariability = heartRateVariability
        self.movement = movement
        self.respiratoryRate = respiratoryRate
        self.oxygenSaturation = oxygenSaturation
        self.temperature = temperature
        self.sleepStage = sleepStage
    }
}

// MARK: - Sleep Session
struct SleepSession: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    let sleepStage: SleepStage
    let quality: Double
    let cycleCount: Int
    var biometricData: [BiometricData] = []
    
    init(startTime: Date, endTime: Date? = nil, sleepStage: SleepStage = .awake, quality: Double = 0.0, cycleCount: Int = 0) {
        self.startTime = startTime
        self.endTime = endTime
        self.sleepStage = sleepStage
        self.quality = quality
        self.cycleCount = cycleCount
    }
    
    var duration: TimeInterval {
        return endTime?.timeIntervalSince(startTime) ?? 0
    }
}

// MARK: - Sleep Analysis
struct SleepAnalysis: Codable {
    let session: SleepSession
    let sleepStages: [SleepStage]
    let sleepQuality: Double
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let lightSleepPercentage: Double
    let awakePercentage: Double
    let recommendations: [SleepRecommendation]
    let insights: [SleepInsight]
    
    init(
        session: SleepSession,
        sleepStages: [SleepStage] = [],
        sleepQuality: Double = 0.0,
        deepSleepPercentage: Double = 0.0,
        remSleepPercentage: Double = 0.0,
        lightSleepPercentage: Double = 0.0,
        awakePercentage: Double = 0.0,
        recommendations: [SleepRecommendation] = [],
        insights: [SleepInsight] = []
    ) {
        self.session = session
        self.sleepStages = sleepStages
        self.sleepQuality = sleepQuality
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.lightSleepPercentage = lightSleepPercentage
        self.awakePercentage = awakePercentage
        self.recommendations = recommendations
        self.insights = insights
    }
}

// MARK: - Sleep Stage Prediction
struct SleepStagePrediction: Codable {
    let sleepStage: SleepStage
    let confidence: Double
    let sleepQuality: Double
    let stageProbabilities: [SleepStage: Double]
    
    init(sleepStage: SleepStage, confidence: Double, sleepQuality: Double, stageProbabilities: [SleepStage: Double] = [:]) {
        self.sleepStage = sleepStage
        self.confidence = confidence
        self.sleepQuality = sleepQuality
        self.stageProbabilities = stageProbabilities
    }
}

// MARK: - Sleep Features for ML
struct SleepFeatures: Codable {
    let heartRate: Double
    let heartRateVariability: Double
    let movement: Double
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let temperature: Double
    let timeOfDay: Double
    let previousStage: SleepStage
    
    // Advanced statistical aggregates for biometric data
    let heartRateMin: Double
    let heartRateMax: Double
    let heartRateStdDev: Double
    let hrvMin: Double
    let hrvMax: Double
    let hrvStdDev: Double
    let bloodOxygenMin: Double
    let bloodOxygenMax: Double
    let bloodOxygenStdDev: Double
    
    // Temporal patterns
    let previousStageDuration: TimeInterval // Duration of the previous sleep stage
    let heartRateChangeRate: Double // Rate of change in heart rate
    let hrvChangeRate: Double // Rate of change in HRV
    let bloodOxygenChangeRate: Double // Rate of change in blood oxygen
    
    init(
        heartRate: Double = 0.0,
        heartRateVariability: Double = 0.0,
        movement: Double = 0.0,
        respiratoryRate: Double = 0.0,
        oxygenSaturation: Double = 0.0,
        temperature: Double = 0.0,
        timeOfDay: Double = 0.0,
        previousStage: SleepStage = .awake,
        
        heartRateMin: Double = 0.0,
        heartRateMax: Double = 0.0,
        heartRateStdDev: Double = 0.0,
        hrvMin: Double = 0.0,
        hrvMax: Double = 0.0,
        hrvStdDev: Double = 0.0,
        bloodOxygenMin: Double = 0.0,
        bloodOxygenMax: Double = 0.0,
        bloodOxygenStdDev: Double = 0.0,
        
        previousStageDuration: TimeInterval = 0.0,
        heartRateChangeRate: Double = 0.0,
        hrvChangeRate: Double = 0.0,
        bloodOxygenChangeRate: Double = 0.0
    ) {
        self.heartRate = heartRate
        self.heartRateVariability = heartRateVariability
        self.movement = movement
        self.respiratoryRate = respiratoryRate
        self.oxygenSaturation = oxygenSaturation
        self.temperature = temperature
        self.timeOfDay = timeOfDay
        self.previousStage = previousStage
        
        self.heartRateMin = heartRateMin
        self.heartRateMax = heartRateMax
        self.heartRateStdDev = heartRateStdDev
        self.hrvMin = hrvMin
        self.hrvMax = hrvMax
        self.hrvStdDev = hrvStdDev
        self.bloodOxygenMin = bloodOxygenMin
        self.bloodOxygenMax = bloodOxygenMax
        self.bloodOxygenStdDev = bloodOxygenStdDev
        
        self.previousStageDuration = previousStageDuration
        self.heartRateChangeRate = heartRateChangeRate
        self.hrvChangeRate = hrvChangeRate
        self.bloodOxygenChangeRate = bloodOxygenChangeRate
    }
}

// MARK: - Sleep Recommendations
struct SleepRecommendation: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let actionable: Bool
    
    init(title: String, description: String, category: RecommendationCategory, priority: RecommendationPriority = .medium, actionable: Bool = true) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.actionable = actionable
    }
}

enum RecommendationCategory: String, CaseIterable, Codable {
    case sleepHygiene = "Sleep Hygiene"
    case environment = "Environment"
    case schedule = "Schedule"
    case health = "Health"
    case technology = "Technology"
    case lifestyle = "Lifestyle"
}

enum RecommendationPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

// MARK: - Sleep Insights
struct SleepInsight: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let insightType: InsightType
    let confidence: Double
    let date: Date
    
    init(title: String, description: String, insightType: InsightType, confidence: Double = 0.0, date: Date = Date()) {
        self.title = title
        self.description = description
        self.insightType = insightType
        self.confidence = confidence
        self.date = date
    }
}

enum InsightType: String, CaseIterable, Codable {
    case pattern = "Pattern"
    case trend = "Trend"
    case anomaly = "Anomaly"
    case improvement = "Improvement"
    case warning = "Warning"
}

// MARK: - Sleep Patterns
struct SleepPattern: Codable {
    let patternType: PatternType
    let frequency: Double
    let duration: TimeInterval
    let confidence: Double
    let description: String
    
    init(patternType: PatternType, frequency: Double, duration: TimeInterval, confidence: Double, description: String) {
        self.patternType = patternType
        self.frequency = frequency
        self.duration = duration
        self.confidence = confidence
        self.description = description
    }
}

enum PatternType: String, CaseIterable, Codable {
    case cycleLength = "Cycle Length"
    case stageDistribution = "Stage Distribution"
    case wakeTime = "Wake Time"
    case bedTime = "Bed Time"
    case sleepLatency = "Sleep Latency"
    case efficiency = "Efficiency"
}

// MARK: - User Sleep Baseline
struct UserSleepBaseline: Codable {
    let averageSleepDuration: TimeInterval
    let averageDeepSleepPercentage: Double
    let averageREMSleepPercentage: Double
    let averageSleepEfficiency: Double
    let typicalBedTime: Date
    let typicalWakeTime: Date
    let sleepLatency: TimeInterval
    let cycleLength: TimeInterval
    
    init(
        averageSleepDuration: TimeInterval = 28800, // 8 hours
        averageDeepSleepPercentage: Double = 0.2,
        averageREMSleepPercentage: Double = 0.25,
        averageSleepEfficiency: Double = 0.85,
        typicalBedTime: Date = Date(),
        typicalWakeTime: Date = Date(),
        sleepLatency: TimeInterval = 900, // 15 minutes
        cycleLength: TimeInterval = 5400 // 90 minutes
    ) {
        self.averageSleepDuration = averageSleepDuration
        self.averageDeepSleepPercentage = averageDeepSleepPercentage
        self.averageREMSleepPercentage = averageREMSleepPercentage
        self.averageSleepEfficiency = averageSleepEfficiency
        self.typicalBedTime = typicalBedTime
        self.typicalWakeTime = typicalWakeTime
        self.sleepLatency = sleepLatency
        self.cycleLength = cycleLength
    }
}

// MARK: - Sleep Data (for Core Data operations)
struct SleepData: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let quality: Double
    let stages: [SleepStage]
    
    init(id: UUID = UUID(), startTime: Date, endTime: Date, duration: TimeInterval, quality: Double, stages: [SleepStage]) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.quality = quality
        self.stages = stages
    }
}

// MARK: - Health Data Point (for Core Data operations)
struct HealthDataPoint: Codable {
    let type: HealthDataType
    let value: Double
    let timestamp: Date
    
    init(type: HealthDataType, value: Double, timestamp: Date) {
        self.type = type
        self.value = value
        self.timestamp = timestamp
    }
}

enum HealthDataType: String, CaseIterable, Codable {
    case heartRate = "heartRate"
    case hrv = "hrv"
    case oxygenSaturation = "oxygenSaturation"
    case bodyTemperature = "bodyTemperature"
    case stepCount = "stepCount"
    case activeEnergyBurned = "activeEnergyBurned"
}

// MARK: - Sleep State
struct SleepState: Codable {
    let isAsleep: Bool
    let currentStage: SleepStage
    let sleepQuality: Double
    let timeInStage: TimeInterval
    let cycleNumber: Int
    
    init(isAsleep: Bool = false, currentStage: SleepStage = .awake, sleepQuality: Double = 0.0, timeInStage: TimeInterval = 0, cycleNumber: Int = 0) {
        self.isAsleep = isAsleep
        self.currentStage = currentStage
        self.sleepQuality = sleepQuality
        self.timeInStage = timeInStage
        self.cycleNumber = cycleNumber
    }
}

// MARK: - Cycle Prediction
struct CyclePrediction: Codable {
    let cycles: [SleepCycle]
    let totalDuration: TimeInterval
    let optimalWakeTime: Date
    let confidence: Double
    
    init(cycles: [SleepCycle] = [], totalDuration: TimeInterval = 0, optimalWakeTime: Date = Date(), confidence: Double = 0.0) {
        self.cycles = cycles
        self.totalDuration = totalDuration
        self.optimalWakeTime = optimalWakeTime
        self.confidence = confidence
    }
}

struct SleepCycle: Codable {
    let number: Int
    let stages: [SleepStage]
    let duration: TimeInterval
    let quality: Double
    
    init(number: Int, stages: [SleepStage] = [], duration: TimeInterval = 0, quality: Double = 0.0) {
        self.number = number
        self.stages = stages
        self.duration = duration
        self.quality = quality
    }
}

// MARK: - Custom Soundscape
struct CustomSoundscape: Identifiable, Codable {
    let id: UUID
    var name: String
    var layers: [AudioLayer]
    var duration: TimeInterval
    var audioBuffer: Data?
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, layers: [AudioLayer] = [], duration: TimeInterval = 28800, audioBuffer: Data? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.layers = layers
        self.duration = duration
        self.audioBuffer = audioBuffer
        self.createdAt = createdAt
    }
}

struct AudioLayer: Identifiable, Codable {
    let id = UUID()
    var type: AudioLayerType
    var volume: Float
    var pan: Float
    var enabled: Bool
    var parameters: [String: Float]
    
    init(type: AudioLayerType, volume: Float = 0.5, pan: Float = 0.0, enabled: Bool = true, parameters: [String: Float] = [:]) {
        self.type = type
        self.volume = volume
        self.pan = pan
        self.enabled = enabled
        self.parameters = parameters
    }
}

enum AudioLayerType: String, CaseIterable, Codable {
    case binauralBeats = "Binaural Beats"
    case whiteNoise = "White Noise"
    case natureSounds = "Nature Sounds"
    case ambientMusic = "Ambient Music"
    case custom = "Custom"
}

// MARK: - Audio Quality
enum AudioQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// MARK: - Spatial Audio Mode
enum SpatialAudioMode: String, CaseIterable {
    case immersive = "Immersive"
    case focused = "Focused"
    case ambient = "Ambient"
    case spatial = "Spatial"
}

// MARK: - Tracking Mode
enum TrackingMode: String, CaseIterable {
    case appleWatch = "Apple Watch"
    case hybrid = "Hybrid"
    case iphoneOnly = "iPhone Only"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Watch Sync Status
enum WatchSyncStatus: String, CaseIterable {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
    case syncing = "Syncing"
    case synced = "Synced"
    case error = "Error"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - App Configuration
struct AppConfiguration: Codable {
    var isFirstLaunch: Bool = true
    var hasCompletedOnboarding: Bool = false
    var hasGrantedHealthKitPermissions: Bool = false
    var hasGrantedNotificationPermissions: Bool = false
    var preferredTrackingMode: TrackingMode = .hybrid
    var audioQuality: AudioQuality = .high
    var spatialAudioEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true
    var autoVolumeAdjustment: Bool = true
    var smartFadingEnabled: Bool = true
    var adaptiveMixingEnabled: Bool = true
    
    static let `default` = AppConfiguration()
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var sleepGoal: TimeInterval = 28800 // 8 hours
    var preferredWakeTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var preferredBedTime: Date = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    var alarmVolume: Float = 0.7
    var fadeInDuration: TimeInterval = 30
    var fadeOutDuration: TimeInterval = 60
    var preferredAudioType: PreSleepAudioType = .binauralBeats(frequency: 6.0)
    var preferredSleepAudioType: SleepAudioType = .deepSleep(frequency: 2.5)
    var reverbLevel: Float = 0.3
    var eqPreset: EQPreset = .neutral
    
    static let `default` = UserPreferences()
} 