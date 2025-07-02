import Foundation
import HealthKit

// MARK: - SleepFeatures Struct
/// A structured set of features extracted from raw sensor data for sleep staging.
struct SleepFeatures: Codable, Hashable {
    // Heart Rate Variability (HRV) metrics
    let rmssd: Double
    let sdnn: Double
    
    // Heart Rate features
    let heartRateAverage: Double
    let heartRateVariability: Double // Standard deviation of heart rate
    
    // SpO2 features
    let spo2Average: Double
    let spo2Variability: Double // Standard deviation of SpO2
    
    // Accelerometer-derived movement features
    let activityCount: Double // Sum of magnitudes of accelerometer data
    let sleepWakeDetection: Double // A simple heuristic (e.g., 0 for sleep, 1 for wake)
    
    // Wrist Temperature features
    let wristTemperatureAverage: Double
    let wristTemperatureGradient: Double // Change in temperature over time
    
    // Timestamp for the feature window
    let timestamp: Date
}

class SleepFeatureExtractor {
    // This class will be responsible for extracting features from raw sensor data
    // for sleep staging.

    /// Extracts features from a collection of raw sensor samples.
    /// - Parameter sensorSamples: An array of `SensorSample` objects.
    /// - Returns: A `SleepFeatures` object containing the extracted features.
    func extractFeatures(from sensorSamples: [SensorSample]) -> SleepFeatures {
        // Filter samples by type
        let heartRateSamples = sensorSamples.filter { $0.type == .heartRate }
        let hrvSamples = sensorSamples.filter { $0.type == .hrv }
        let spo2Samples = sensorSamples.filter { $0.type == .oxygenSaturation }
        let temperatureSamples = sensorSamples.filter { $0.type == .bodyTemperature }
        let accelerometerSamples = sensorSamples.filter { $0.type == .accelerometer }
        
        // Extract values
        let heartRates = heartRateSamples.map { $0.value }
        let hrvs = hrvSamples.map { $0.value }
        let oxygenSaturations = spo2Samples.map { $0.value }
        let bodyTemperatures = temperatureSamples.map { $0.value }
        
        // Feature Calculation
        let rmssd = calculateRMSSD(from: heartRateSamples)
        let sdnn = calculateSDNN(from: heartRateSamples)
        
        let heartRateAvg = calculateAverage(heartRates) ?? 0.0
        let heartRateStdDev = calculateStandardDeviation(heartRates) ?? 0.0
        
        let spo2Avg = calculateAverage(oxygenSaturations) ?? 0.0
        let spo2StdDev = calculateStandardDeviation(oxygenSaturations) ?? 0.0
        
        let activityCount = calculateActivityCount(from: accelerometerSamples)
        let sleepWake = detectSleepWake(from: accelerometerSamples)
        
        let wristTempAvg = calculateAverage(bodyTemperatures) ?? 0.0
        let wristTempGradient = calculateWristTemperatureGradient(from: temperatureSamples)
        
        // Use the timestamp of the last sample as the feature timestamp, or current date if no samples
        let featureTimestamp = sensorSamples.last?.timestamp ?? Date()
        
        return SleepFeatures(
            rmssd: rmssd,
            sdnn: sdnn,
            heartRateAverage: heartRateAvg,
            heartRateVariability: heartRateStdDev,
            spo2Average: spo2Avg,
            spo2Variability: spo2StdDev,
            activityCount: activityCount,
            sleepWakeDetection: sleepWake,
            wristTemperatureAverage: wristTempAvg,
            wristTemperatureGradient: wristTempGradient,
            timestamp: featureTimestamp
        )
    }

    // MARK: - Helper Functions for Feature Calculation
    
    private func calculateAverage(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func calculateStandardDeviation(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let mean = calculateAverage(values)!
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    /// Calculates RMSSD (Root Mean Square of Successive Differences) from heart rate samples.
    /// RMSSD is a time-domain HRV parameter.
    /// - Parameter heartRateSamples: An array of `SensorSample` objects of type `.heartRate`.
    /// - Returns: The calculated RMSSD value.
    private func calculateRMSSD(from heartRateSamples: [SensorSample]) -> Double {
        guard heartRateSamples.count > 1 else { return 0.0 }
        
        // Assuming heartRateSamples are ordered by timestamp and represent R-R intervals or can be converted
        // For simplicity, if raw heart rate is given, we'd need to derive R-R intervals first.
        // If actual R-R intervals are not available, this calculation would be more complex.
        
        let rrIntervals: [Double] = heartRateSamples.map { 60.0 / $0.value } // Convert BPM to RR in seconds
        
        guard rrIntervals.count > 1 else { return 0.0 }
        
        var squaredDifferences: [Double] = []
        for i in 0..<(rrIntervals.count - 1) {
            let diff = rrIntervals[i+1] - rrIntervals[i]
            squaredDifferences.append(pow(diff, 2))
        }
        
        guard !squaredDifferences.isEmpty else { return 0.0 }
        
        let meanSquaredDifference = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
        return sqrt(meanSquaredDifference)
    }
    
    /// Calculates SDNN (Standard Deviation of Normal-to-Normal intervals) from heart rate samples.
    /// SDNN is a time-domain HRV parameter.
    /// - Parameter heartRateSamples: An array of `SensorSample` objects of type `.heartRate`.
    /// - Returns: The calculated SDNN value.
    private func calculateSDNN(from heartRateSamples: [SensorSample]) -> Double {
        guard heartRateSamples.count > 1 else { return 0.0 }
        
        let rrIntervals: [Double] = heartRateSamples.map { 60.0 / $0.value } // Convert BPM to RR in seconds
        
        return calculateStandardDeviation(rrIntervals) ?? 0.0
    }
    
    /// Calculates activity count from accelerometer data.
    /// This is a simplified approach, summing the magnitudes of acceleration vectors.
    /// - Parameter accelerometerSamples: An array of `SensorSample` objects of type `.accelerometer`.
    /// - Returns: The total activity count.
    private func calculateActivityCount(from accelerometerSamples: [SensorSample]) -> Double {
        // Assuming accelerometer samples might come as a single value representing magnitude,
        // or we might need to combine x, y, z if they were separate samples.
        // For this implementation, we'll assume the 'value' is already a magnitude or a proxy.
        // In a real scenario, accelerometer data would likely be a struct with x, y, z components.
        
        // If SensorSample.value for accelerometer is a combined magnitude, sum them up.
        // If it's just one axis, this will be less accurate.
        return accelerometerSamples.map { abs($0.value) }.reduce(0, +)
    }
    
    /// Performs a simple sleep/wake detection based on accelerometer data.
    /// A low activity count suggests sleep (0.0), high suggests wake (1.0).
    /// This is a heuristic and would typically involve more sophisticated algorithms.
    /// - Parameter accelerometerSamples: An array of `SensorSample` objects of type `.accelerometer`.
    /// - Returns: 0.0 for sleep, 1.0 for wake.
    private func detectSleepWake(from accelerometerSamples: [SensorSample]) -> Double {
        let activityThreshold: Double = 5.0 // Example threshold, needs tuning
        let totalActivity = calculateActivityCount(from: accelerometerSamples)
        
        return totalActivity > activityThreshold ? 1.0 : 0.0 // 1.0 for wake, 0.0 for sleep
    }
    
    /// Calculates wrist temperature micro-gradients.
    /// This is a simplified approach, looking at the difference between the last and first temperature readings.
    /// A more advanced approach would involve analyzing trends over smaller windows.
    /// - Parameter temperatureSamples: An array of `SensorSample` objects of type `.bodyTemperature`.
    /// - Returns: The temperature gradient.
    private func calculateWristTemperatureGradient(from temperatureSamples: [SensorSample]) -> Double {
        guard let firstTemp = temperatureSamples.first?.value,
              let lastTemp = temperatureSamples.last?.value else {
            return 0.0
        }
        return lastTemp - firstTemp
    }
}