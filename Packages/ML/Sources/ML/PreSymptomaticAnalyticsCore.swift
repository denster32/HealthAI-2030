import Foundation
import os.log

/// PreSymptomaticAnalyticsCore - Designed to detect subtle, complex patterns in DigitalTwin data
/// that are predictive of future health conditions long before clinical symptoms appear.
class PreSymptomaticAnalyticsCore {
    
    /// Analyzes the DigitalTwin for early indicators of potential health issues.
    /// - Parameter twin: The DigitalTwin to analyze.
    /// - Returns: An array of `HealthPrediction` objects, indicating potential future health concerns.
    func analyzeForPreSymptomaticIndicators(for twin: DigitalTwin) -> [HealthPrediction] {
        Logger.info("Analyzing Digital Twin for pre-symptomatic indicators...", log: Logger.dataManager)
        
        var predictions: [HealthPrediction] = []
        
        // MARK: - Example: Early Cardiovascular Risk Detection
        // This is a simplified example. Real-world models would be much more complex,
        // involving advanced ML algorithms trained on large datasets.
        
        // Check for subtle, sustained changes in resting heart rate and HRV
        if let latestHR = twin.biometricData.restingHeartRate.last,
           let latestHRV = twin.biometricData.heartRateVariability.last {
            
            let historicalAvgHR = twin.biometricData.restingHeartRate.average()
            let historicalAvgHRV = twin.biometricData.heartRateVariability.average()
            
            // Example rule: Sustained increase in resting HR and decrease in HRV
            if historicalAvgHR > 0 && historicalAvgHRV > 0 { // Ensure data exists
                let hrChange = (latestHR - historicalAvgHR) / historicalAvgHR
                let hrvChange = (latestHRV - historicalAvgHRV) / historicalAvgHRV
                
                if hrChange > 0.10 && hrvChange < -0.10 { // 10% increase in HR, 10% decrease in HRV
                    predictions.append(
                        HealthPrediction(
                            type: .cardiovascularRisk,
                            description: "Subtle, sustained changes in heart rate and HRV suggest potential early cardiovascular strain. Consider lifestyle adjustments.",
                            confidence: 0.75,
                            severity: .medium,
                            predictedOnset: Date().addingTimeInterval(365 * 24 * 3600) // ~1 year
                        )
                    )
                }
            }
        }
        
        // MARK: - Example: Early Sleep Disorder Indicators
        // Look for patterns in sleep duration variability or oxygen saturation drops
        if let latestSleepDuration = twin.lifestyleData.averageSleepDuration.last { // Assuming averageSleepDuration is an array now
            let historicalAvgSleepDuration = twin.lifestyleData.averageSleepDuration.average()
            
            if historicalAvgSleepDuration > 0 {
                let sleepDurationVariability = abs(latestSleepDuration - historicalAvgSleepDuration) / historicalAvgSleepDuration
                
                if sleepDurationVariability > 0.20 { // High variability in sleep duration
                    predictions.append(
                        HealthPrediction(
                            type: .sleepDisorderRisk,
                            description: "Significant variability in sleep duration detected. This could be an early indicator of a developing sleep disorder.",
                            confidence: 0.60,
                            severity: .low,
                            predictedOnset: Date().addingTimeInterval(180 * 24 * 3600) // ~6 months
                        )
                    )
                }
            }
        }
        
        // Check for micro-drops in blood oxygen saturation (requires more granular data than current BiometricProfile)
        // This would typically involve analyzing raw SpO2 time series data.
        // For now, a placeholder:
        if let minSpO2 = twin.biometricData.bloodOxygenSaturation.min(), minSpO2 < 90 {
             predictions.append(
                HealthPrediction(
                    type: .sleepApneaRisk,
                    description: "Detected instances of low blood oxygen saturation. This may indicate early signs of sleep-disordered breathing.",
                    confidence: 0.80,
                    severity: .medium,
                    predictedOnset: Date().addingTimeInterval(90 * 24 * 3600) // ~3 months
                )
            )
        }

        Logger.success("Pre-symptomatic analysis completed. Found \(predictions.count) predictions.", log: Logger.dataManager)
        return predictions
    }
    
    /// Generates a detailed explanation for each health prediction.
    /// - Parameter predictions: The array of `HealthPrediction` objects to explain.
    /// - Returns: A dictionary mapping each prediction type to its explanation.
    func generatePredictionExplanations(for predictions: [HealthPrediction]) -> [HealthPredictionType: String] {
        var explanations: [HealthPredictionType: String] = [:]

        for prediction in predictions {
            switch prediction.type {
            case .cardiovascularRisk:
                explanations[prediction.type] = "This prediction is based on sustained increases in resting heart rate and decreases in heart rate variability, which are early indicators of cardiovascular strain."
            case .sleepDisorderRisk:
                explanations[prediction.type] = "This prediction is based on significant variability in sleep duration, which can indicate potential sleep disorders."
            case .sleepApneaRisk:
                explanations[prediction.type] = "This prediction is based on detected instances of low blood oxygen saturation, which may indicate sleep-disordered breathing."
            // Add more cases as needed for other prediction types
            default:
                explanations[prediction.type] = "No detailed explanation available for this prediction type."
            }
        }

        return explanations
    }
}

// MARK: - Supporting Data Structures for Health Predictions

/// Represents a potential future health prediction.
struct HealthPrediction {
    let type: HealthPredictionType
    let description: String
    let confidence: Double // 0.0 - 1.0
    let severity: HealthPredictionSeverity
    let predictedOnset: Date // Estimated date of clinical onset if no intervention
}

/// Categorizes the type of health prediction.
enum HealthPredictionType: String, Codable {
    case cardiovascularRisk = "Cardiovascular Risk"
    case metabolicDisorderRisk = "Metabolic Disorder Risk"
    case sleepDisorderRisk = "Sleep Disorder Risk"
    case mentalHealthRisk = "Mental Health Risk"
    case infectiousDiseaseRisk = "Infectious Disease Risk"
    case sleepApneaRisk = "Sleep Apnea Risk"
    // Add more types as needed
}

/// Indicates the severity of the predicted health issue.
enum HealthPredictionSeverity: String, Codable {
    case low
    case medium
    case high
    case critical
}

// MARK: - Helper Extensions
extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0.0 }
        return self.reduce(0, +) / Double(self.count)
    }
}

// NOTE: To make `averageSleepDuration` an array in `LifestyleProfile`,
// you would need to modify the `LifestyleProfile` struct in `DigitalTwin.swift`.
// For this example, we're assuming it's an array for demonstration purposes.