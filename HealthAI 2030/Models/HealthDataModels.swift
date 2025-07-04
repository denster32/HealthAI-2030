import Foundation
import SwiftData

// MARK: - Main Health Data Model

/// Unified health data entry for vitals, subjective scores, and performance metrics.
///
/// - Used for analytics, reporting, and sync.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class HealthDataEntry {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var deviceSource: String // e.g., "iPhone", "Apple Watch", "Smart Ring"
    public var provenance: String // e.g., "HealthKit API", "User Input", "Third-Party Integration"
    public var isValidated: Bool // Indicates if data has passed validation checks
    public var validationErrors: [String]? // Stores any validation errors

    // Vitals
    public var restingHeartRate: Double
    public var hrv: Double
    public var oxygenSaturation: Double
    public var bodyTemperature: Double
    public var respiratoryRate: Double // Added
    public var bloodPressureSystolic: Double // Added
    public var bloodPressureDiastolic: Double // Added
    public var bloodGlucose: Double // Added
    public var weight: Double // Added
    public var height: Double // Added
    public var bodyMassIndex: Double // Added
    public var bodyFatPercentage: Double // Added

    // Subjective Scores
    public var stressLevel: Double
    public var moodScore: Double
    public var energyLevel: Double
    public var painLevel: Double // Added
    public var symptomSeverity: Double // Added

    // Activity Metrics
    public var steps: Int // Added
    public var activeEnergyBurned: Double // Added
    public var exerciseMinutes: Int // Added
    public var workoutDuration: TimeInterval // Added
    public var caloriesBurned: Double // Added
    public var distance: Double // Added

    // Sleep Metrics
    public var sleepDuration: TimeInterval // Added
    public var deepSleepDuration: TimeInterval // Added
    public var remSleepDuration: TimeInterval // Added
    public var awakeDuration: TimeInterval // Added
    public var sleepEfficiency: Double // Added
    public var sleepQualityScore: Double // Renamed from sleepQuality

    // Nutrition Metrics
    public var caloriesConsumed: Double // Added
    public var proteinIntake: Double // Added
    public var carbIntake: Double // Added
    public var fatIntake: Double // Added
    public var waterIntake: Double // Added

    // Environmental Metrics
    public var environmentalNoise: Double // Added
    public var ambientLightLevel: Double // Added
    public var airQuality: Double // Added
    public var uvIndex: Double // Added
    public var pollenCount: Double // Added

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        deviceSource: String,
        provenance: String,
        isValidated: Bool = true,
        validationErrors: [String]? = nil,
        restingHeartRate: Double, hrv: Double, oxygenSaturation: Double, bodyTemperature: Double, respiratoryRate: Double, bloodPressureSystolic: Double, bloodPressureDiastolic: Double, bloodGlucose: Double, weight: Double, height: Double, bodyMassIndex: Double, bodyFatPercentage: Double,
        stressLevel: Double, moodScore: Double, energyLevel: Double, painLevel: Double, symptomSeverity: Double,
        steps: Int, activeEnergyBurned: Double, exerciseMinutes: Int, workoutDuration: TimeInterval, caloriesBurned: Double, distance: Double,
        sleepDuration: TimeInterval, deepSleepDuration: TimeInterval, remSleepDuration: TimeInterval, awakeDuration: TimeInterval, sleepEfficiency: Double, sleepQualityScore: Double,
        caloriesConsumed: Double, proteinIntake: Double, carbIntake: Double, fatIntake: Double, waterIntake: Double,
        environmentalNoise: Double, ambientLightLevel: Double, airQuality: Double, uvIndex: Double, pollenCount: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.deviceSource = deviceSource
        self.provenance = provenance
        self.isValidated = isValidated
        self.validationErrors = validationErrors
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.oxygenSaturation = oxygenSaturation
        self.bodyTemperature = bodyTemperature
        self.respiratoryRate = respiratoryRate
        self.bloodPressureSystolic = bloodPressureSystolic
        self.bloodPressureDiastolic = bloodPressureDiastolic
        self.bloodGlucose = bloodGlucose
        self.weight = weight
        self.height = height
        self.bodyMassIndex = bodyMassIndex
        self.bodyFatPercentage = bodyFatPercentage
        self.stressLevel = stressLevel
        self.moodScore = moodScore
        self.energyLevel = energyLevel
        self.painLevel = painLevel
        self.symptomSeverity = symptomSeverity
        self.steps = steps
        self.activeEnergyBurned = activeEnergyBurned
        self.exerciseMinutes = exerciseMinutes
        self.workoutDuration = workoutDuration
        self.caloriesBurned = caloriesBurned
        self.distance = distance
        self.sleepDuration = sleepDuration
        self.deepSleepDuration = deepSleepDuration
        self.remSleepDuration = remSleepDuration
        self.awakeDuration = awakeDuration
        self.sleepEfficiency = sleepEfficiency
        self.sleepQualityScore = sleepQualityScore
        self.caloriesConsumed = caloriesConsumed
        self.proteinIntake = proteinIntake
        self.carbIntake = carbIntake
        self.fatIntake = fatIntake
        self.waterIntake = waterIntake
        self.environmentalNoise = environmentalNoise
        self.ambientLightLevel = ambientLightLevel
        self.airQuality = airQuality
        self.uvIndex = uvIndex
        self.pollenCount = pollenCount
    }

    // Computed properties for analytics and display.
    public var age: Int? {
        // Placeholder for age calculation, requires user's birth date
        return nil
    }

    public var bmiCategory: String {
        guard bodyMassIndex > 0 else { return "N/A" }
        if bodyMassIndex < 18.5 { return "Underweight" }
        if bodyMassIndex < 24.9 { return "Normal weight" }
        if bodyMassIndex < 29.9 { return "Overweight" }
        return "Obese"
    }

    public var heartRateZone: String {
        guard restingHeartRate > 0 else { return "N/A" }
        if restingHeartRate < 60 { return "Athletic/Excellent" }
        if restingHeartRate < 80 { return "Normal" }
        return "Elevated"
    }

    public var sleepEfficiencyPercentage: String {
        guard sleepDuration > 0 else { return "N/A" }
        return String(format: "%.1f%%", sleepEfficiency * 100)
    }

    // Basic validation method
    public func validate() {
        var errors: [String] = []

        if restingHeartRate <= 0 { errors.append("Resting heart rate must be positive.") }
        if oxygenSaturation < 70 || oxygenSaturation > 100 { errors.append("Oxygen saturation must be between 70-100%.") }
        if sleepDuration < 0 { errors.append("Sleep duration cannot be negative.") }
        if caloriesConsumed < 0 { errors.append("Calories consumed cannot be negative.") }
        if steps < 0 { errors.append("Steps cannot be negative.") }

        isValidated = errors.isEmpty
        validationErrors = errors.isEmpty ? nil : errors
    }
}

// MARK: - Sleep Session Model

/// Sleep session entry for storing session timing and quality.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SleepSessionEntry {
    @Attribute(.unique) public var id: UUID
    public var startTime: Date
    public var endTime: Date
    public var duration: TimeInterval
    public var qualityScore: Double // 0-1 scale
    
    public init(id: UUID = UUID(), startTime: Date, endTime: Date, duration: TimeInterval, qualityScore: Double) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.qualityScore = qualityScore
    }
    // TODO: Add sleep stage breakdown and device info.
}

// MARK: - Workout Session Model

/// Workout session entry for storing workout details and metrics.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class WorkoutEntry {
    @Attribute(.unique) public var id: UUID
    public var startTime: Date
    public var endTime: Date
    public var workoutType: String
    public var energyBurned: Double // in calories
    public var averageHeartRate: Double
    
    public init(id: UUID = UUID(), startTime: Date, endTime: Date, workoutType: String, energyBurned: Double, averageHeartRate: Double) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.workoutType = workoutType
        self.energyBurned = energyBurned
        self.averageHeartRate = averageHeartRate
    }
    // TODO: Add GPS, intensity, and device info.
}

// MARK: - Nutrition Log Model

/// Nutrition log entry for storing macronutrient and calorie intake.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class NutritionLogEntry {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var calories: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    
    public init(id: UUID = UUID(), timestamp: Date, calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.id = id
        self.timestamp = timestamp
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    // TODO: Add micronutrients and meal type.
}
// TODO: Add unit tests for all health data models.
