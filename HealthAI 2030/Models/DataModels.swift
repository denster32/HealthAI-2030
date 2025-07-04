import Foundation
import SwiftData

/// Represents a type of health data (e.g., sleep, steps, heart rate).
public enum HealthDataType: String, Codable, CaseIterable, Identifiable {
    public var id: String { self.rawValue }
    case sleepHours = "Sleep Hours"
    case steps = "Steps"
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case spo2 = "SpO2"
    case ecg = "ECG"
    case temperature = "Temperature"
    case genomicData = "Genomic Data"
    case clinicalRecord = "Clinical Record"
    case nutrition = "Nutrition"
    case exercise = "Exercise"
    case medicationAdherence = "Medication Adherence"
    case environmentalAirQuality = "Environmental Air Quality"
    case environmentalPollen = "Environmental Pollen"
    case environmentalUVIndex = "Environmental UV Index"
    case custom = "Custom Data" // For user-defined or future data types
    // TODO: Add more health data types as needed.
}

/// Represents a user's health data entry for analytics and the Digital Health Twin.
///
/// - Stores both numerical and string-based health data, with optional metadata.
/// - TODO: Add validation, provenance, and support for complex data types.
@Model
public class HealthDataEntry: Identifiable {
    public var id: UUID
    public var timestamp: Date
    public var dataType: HealthDataType
    public var value: Double // Generic value for numerical data
    public var stringValue: String? // For non-numerical data like genomic or clinical records
    public var unit: String? // e.g., "hours", "steps", "bpm", "mg/dL"
    public var source: String? // e.g., "HealthKit", "Manual Input", "23andMe"
    public var metadata: Data? // For storing additional structured metadata (e.g., JSON)

    public init(id: UUID = UUID(), timestamp: Date, dataType: HealthDataType, value: Double, stringValue: String? = nil, unit: String? = nil, source: String? = nil, metadata: Data? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.value = value
        self.stringValue = stringValue
        self.unit = unit
        self.source = source
        self.metadata = metadata
    }
    // TODO: Add computed properties for formatted display and analytics.
}
// TODO: Add unit tests for HealthDataEntry and HealthDataType.
