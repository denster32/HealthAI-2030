import Foundation
import SwiftData

/// Protocol for CloudKit syncable models
protocol CKSyncable {
    var id: UUID { get }
    var dataType: CKSyncableDataType { get }
}

/// Enumeration for different data types in the health app
enum CKSyncableDataType: String, Codable {
    case healthMetrics = "health_metrics"
    case sleepData = "sleep_data"
    case exerciseData = "exercise_data"
    case nutritionData = "nutrition_data"
    case mentalHealthData = "mental_health_data"
    case medicationData = "medication_data"
    case vitalSigns = "vital_signs"
    case symptomLog = "symptom_log"
    case general = "general"
}