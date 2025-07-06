
import Foundation

// MARK: - Enums

public enum HealthDataType: String, CaseIterable, Codable {
    // Vital Signs
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case respiratoryRate = "Respiratory Rate"
    case bodyTemperature = "Body Temperature"
    
    // Activity
    case steps = "Steps"
    case distance = "Distance"
    case activeEnergy = "Active Energy"
    
    // Sleep
    case sleepAnalysis = "Sleep Analysis"
    
    // Nutrition
    case dietaryEnergy = "Dietary Energy"
    case carbohydrates = "Carbohydrates"
    case protein = "Protein"
    case fat = "Fat"
    
    // Body Measurements
    case bodyMass = "Body Mass"
    case height = "Height"
    case bodyMassIndex = "Body Mass Index"
    
    // Mental Health
    case mindfulMinutes = "Mindful Minutes"
    case mood = "Mood"
    
    // Other
    case bloodGlucose = "Blood Glucose"
    case oxygenSaturation = "Oxygen Saturation"
    case hydration = "Hydration"
    case environmentalNoise = "Environmental Noise"
    case ambientLight = "Ambient Light"
    case airQuality = "Air Quality"
    case stress = "Stress"
}

public enum SharingPermission: String, Codable {
    case read = "Read"
    case write = "Write"
    case denied = "Denied"
}
