import Foundation
import HealthKit

/// Represents comprehensive health data for a user, including metrics from HealthKit and derived analytics.
///
/// - Stores basic, activity, sleep, environmental, and mental health metrics.
/// - Provides initializers for direct input or HealthKit sample arrays.
/// - Includes utility methods for sleep preparation and quality scoring.
/// - TODO: Add provenance, error handling, and support for additional metrics.
public class HealthData {
    // MARK: - Basic Health Metrics
    public var heartRate: Double
    public var heartRateVariability: Double
    public var oxygenSaturation: Double
    public var respiratoryRate: Double
    public var bodyTemperature: Double
    public var bloodPressure: (systolic: Double, diastolic: Double)
    
    // MARK: - Activity Metrics
    public var steps: Int
    public var activeEnergyBurned: Double
    public var standHours: Int
    public var exerciseMinutes: Int
    
    // MARK: - Sleep Metrics
    public var sleepHours: Double
    public var deepSleepPercentage: Double
    public var remSleepPercentage: Double
    public var sleepQualityScore: Double
    public var isPreparingForSleep: Bool
    
    // MARK: - Environmental Metrics
    public var environmentalNoise: Double
    public var ambientLightLevel: Double
    public var airQuality: Double
    
    // MARK: - Mental Health Metrics
    public var stressLevel: Double
    public var mindfulnessMinutes: Int
    public var moodScore: Double
    
    // MARK: - Timestamps
    public var lastUpdated: Date
    public var dataCollectionPeriod: (start: Date, end: Date)
    public var provenance: String? // Source of the data (e.g., "HealthKit", "Manual Input", "Third-Party API")
    public var deviceSource: String? // Device that collected the data (e.g., "iPhone", "Apple Watch", "Smart Ring")
    public var errors: [HealthDataError] = [] // Errors encountered during data collection or processing

    // MARK: - Initialization

    /// Default initializer with all health metrics.
    public init(
        heartRate: Double = 0,
        heartRateVariability: Double = 0,
        oxygenSaturation: Double = 0,
        respiratoryRate: Double = 0,
        bodyTemperature: Double = 0,
        bloodPressure: (systolic: Double, diastolic: Double) = (0, 0),
        steps: Int = 0,
        activeEnergyBurned: Double = 0,
        standHours: Int = 0,
        exerciseMinutes: Int = 0,
        sleepHours: Double = 0,
        deepSleepPercentage: Double = 0,
        remSleepPercentage: Double = 0,
        sleepQualityScore: Double = 0,
        isPreparingForSleep: Bool = false,
        environmentalNoise: Double = 0,
        ambientLightLevel: Double = 0,
        airQuality: Double = 0,
        stressLevel: Double = 0,
        mindfulnessMinutes: Int = 0,
        moodScore: Double = 0,
        lastUpdated: Date = Date(),
        dataCollectionPeriod: (start: Date, end: Date) = (Date().addingTimeInterval(-86400), Date()),
        provenance: String? = nil,
        deviceSource: String? = nil
    ) {
        self.heartRate = heartRate
        self.heartRateVariability = heartRateVariability
        self.oxygenSaturation = oxygenSaturation
        self.respiratoryRate = respiratoryRate
        self.bodyTemperature = bodyTemperature
        self.bloodPressure = bloodPressure
        self.steps = steps
        self.activeEnergyBurned = activeEnergyBurned
        self.standHours = standHours
        self.exerciseMinutes = exerciseMinutes
        self.sleepHours = sleepHours
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.sleepQualityScore = sleepQualityScore
        self.isPreparingForSleep = isPreparingForSleep
        self.environmentalNoise = environmentalNoise
        self.ambientLightLevel = ambientLightLevel
        self.airQuality = airQuality
        self.stressLevel = stressLevel
        self.mindfulnessMinutes = mindfulnessMinutes
        self.moodScore = moodScore
        self.lastUpdated = lastUpdated
        self.dataCollectionPeriod = dataCollectionPeriod
        self.provenance = provenance
        self.deviceSource = deviceSource
    }

    /// Convenience initializer from HealthKit samples.
    public convenience init(from samples: [HKSample], deviceSource: String? = nil) {
        self.init(deviceSource: deviceSource, provenance: "HealthKit")

        // Process HealthKit samples to populate health data
        for sample in samples {
            if let quantitySample = sample as? HKQuantitySample {
                self.processQuantitySample(quantitySample)
            } else if let categorySample = sample as? HKCategorySample {
                self.processCategorySample(categorySample)
            }
        }

        self.lastUpdated = Date()
        self.validateData()
    }

    // MARK: - HealthKit Sample Processing

    /// Process a quantity sample from HealthKit.
    private func processQuantitySample(_ sample: HKQuantitySample) {
        let quantityType = sample.quantityType

        do {
            if quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                self.heartRate = try sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            } else if quantityType.identifier == HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue {
                self.heartRateVariability = try sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            } else if quantityType.identifier == HKQuantityTypeIdentifier.oxygenSaturation.rawValue {
                self.oxygenSaturation = try sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            } else if quantityType.identifier == HKQuantityTypeIdentifier.respiratoryRate.rawValue {
                self.respiratoryRate = try sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            } else if quantityType.identifier == HKQuantityTypeIdentifier.bodyTemperature.rawValue {
                self.bodyTemperature = try sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
            } else if quantityType.identifier == HKQuantityTypeIdentifier.stepCount.rawValue {
                self.steps += Int(try sample.quantity.doubleValue(for: HKUnit.count()))
            } else if quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                self.activeEnergyBurned += try sample.quantity.doubleValue(for: HKUnit.kilocalorie())
            } else if quantityType.identifier == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue {
                self.bloodPressure.systolic = try sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            } else if quantityType.identifier == HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue {
                self.bloodPressure.diastolic = try sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            }
        } catch {
            self.errors.append(.healthKitProcessingError(sample.quantityType.identifier, error.localizedDescription))
        }
    }

    /// Process a category sample from HealthKit.
    private func processCategorySample(_ sample: HKCategorySample) {
        let categoryType = sample.categoryType

        if categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
            // Calculate sleep duration
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // in hours
            self.sleepHours += duration

            // Determine sleep stage
            let value = sample.value
            if value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                self.deepSleepPercentage += (duration / self.sleepHours) * 100
            } else if value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                self.remSleepPercentage += (duration / self.sleepHours) * 100
            }
        } else if categoryType.identifier == HKCategoryTypeIdentifier.mindfulSession.rawValue {
            let duration = Int(sample.endDate.timeIntervalSince(sample.startDate) / 60) // in minutes
            self.mindfulnessMinutes += duration
        }
    }

    // MARK: - Utility Methods

    /// Determines if the user is in a pre-sleep state based on time and biometrics.
    public func updateSleepPreparationStatus() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        // Consider it pre-sleep time if:
        // 1. It's evening (after 8 PM)
        // 2. Heart rate is decreasing
        // 3. Activity level is low

        let isEveningTime = hour >= 20 // After 8 PM
        let isHeartRateCalming = heartRate < 70 // Example threshold
        let isLowActivity = steps < 500 // Low step count in recent period

        isPreparingForSleep = isEveningTime && isHeartRateCalming && isLowActivity
    }

    /// Calculates a sleep quality score based on sleep metrics.
    public func calculateSleepQualityScore() {
        guard sleepHours > 0 else {
            sleepQualityScore = 0
            return
        }

        // Factors that contribute to sleep quality:
        // 1. Total sleep duration (optimal around 7-8 hours)
        // 2. Percentage of deep sleep (optimal around 20-25%)
        // 3. Percentage of REM sleep (optimal around 20-25%)

        let durationScore = min(1.0, sleepHours / 8.0) * 0.4 // 40% weight
        let deepSleepScore = min(1.0, deepSleepPercentage / 25.0) * 0.3 // 30% weight
        let remSleepScore = min(1.0, remSleepPercentage / 25.0) * 0.3 // 30% weight

        sleepQualityScore = (durationScore + deepSleepScore + remSleepScore) * 100
    }

    /// Validates the collected health data for consistency and completeness.
    public func validateData() {
        errors.removeAll()

        if heartRate <= 0 {
            errors.append(.invalidMetric("heartRate", "Heart rate must be positive."))
        }
        if oxygenSaturation <= 0 || oxygenSaturation > 100 {
            errors.append(.invalidMetric("oxygenSaturation", "Oxygen saturation must be between 0 and 100."))
        }
        if sleepHours < 0 {
            errors.append(.invalidMetric("sleepHours", "Sleep hours cannot be negative."))
        }
        // Add more validation rules for other metrics
    }

    /// Returns true if there are no errors in the health data.
    public var isValid: Bool {
        return errors.isEmpty
    }
}

// MARK: - Supporting Types

public enum HealthDataError: Error, LocalizedError, Identifiable {
    public var id: String {
        switch self {
        case .healthKitProcessingError(let type, _): return "healthKitProcessingError_\(type)"
        case .invalidMetric(let metric, _): return "invalidMetric_\(metric)"
        case .missingData(let metric): return "missingData_\(metric)"
        case .other(let message): return "other_\(message.hashValue)"
        }
    }

    case healthKitProcessingError(String, String) // (dataTypeIdentifier, errorMessage)
    case invalidMetric(String, String) // (metricName, validationMessage)
    case missingData(String) // (metricName)
    case other(String)

    public var errorDescription: String? {
        switch self {
        case .healthKitProcessingError(let type, let message):
            return "HealthKit processing error for \(type): \(message)"
        case .invalidMetric(let metric, let message):
            return "Invalid metric \(metric): \(message)"
        case .missingData(let metric):
            return "Missing required data for \(metric)"
        case .other(let message):
            return "Health data error: \(message)"
        }
    }
}