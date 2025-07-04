import Foundation
import SwiftData

// MARK: - Main Health Data Model

/// Unified health data entry for vitals, subjective scores, and performance metrics.
///
/// - Used for analytics, reporting, and sync.
/// - TODO: Add provenance, device source, and additional metrics.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class HealthDataEntry {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    
    // Vitals
    public var restingHeartRate: Double
    public var hrv: Double
    public var oxygenSaturation: Double
    public var bodyTemperature: Double
    
    // Subjective Scores
    public var stressLevel: Double
    public var moodScore: Double
    public var energyLevel: Double
    
    // Performance Metrics
    public var activityLevel: Double
    public var sleepQuality: Double
    public var nutritionScore: Double
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        restingHeartRate: Double, hrv: Double, oxygenSaturation: Double, bodyTemperature: Double,
        stressLevel: Double, moodScore: Double, energyLevel: Double,
        activityLevel: Double, sleepQuality: Double, nutritionScore: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.oxygenSaturation = oxygenSaturation
        self.bodyTemperature = bodyTemperature
        self.stressLevel = stressLevel
        self.moodScore = moodScore
        self.energyLevel = energyLevel
        self.activityLevel = activityLevel
        self.sleepQuality = sleepQuality
        self.nutritionScore = nutritionScore
    }
    // TODO: Add computed properties for analytics and display.
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
