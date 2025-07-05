import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import Foundation
import HealthKit

/// Centralized health data schema for cross-feature compatibility
struct CoreHealthDataModel: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let sourceDevice: String
    let dataType: HealthDataType
    let metricValue: Double
    let unit: String
    let metadata: [String: String]?
    
    /// Health data categories with FHIR R4 mapping
    enum HealthDataType: String, Codable, CaseIterable {
        case heartRate = "HEART_RATE"
        case sleepAnalysis = "SLEEP_ANALYSIS"
        case respiratoryRate = "RESPIRATORY_RATE"
        case bloodOxygen = "BLOOD_OXYGEN"
        case bloodPressure = "BLOOD_PRESSURE"
        case activity = "PHYSICAL_ACTIVITY"
        case nutrition = "NUTRITION"
        case cognitive = "COGNITIVE_STATE"
        
        /// Maps to FHIR R4 Observation codes
        var fhirCode: String {
            switch self {
            case .heartRate: return "8867-4"
            case .sleepAnalysis: return "248263006"
            case .respiratoryRate: return "9279-1"
            case .bloodOxygen: return "2708-6"
            case .bloodPressure: return "85354-9"
            case .activity: return "68130003"
            case .nutrition: return "226234005"
            case .cognitive: return "363679005"
            }
        }
    }
}

/// Wrapper for CoreHealthDataModel with processing metadata
struct HealthDataContainer {
    let rawData: CoreHealthDataModel
    let derivedMetrics: [String: Double]?
    let dataQuality: DataQualityRating
    let lastUpdated: Date
    
    enum DataQualityRating: Int, Codable {
        case low = 0, medium, high
    }
}