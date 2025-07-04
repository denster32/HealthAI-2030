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
    
    // Oxygen Saturation features
    let oxygenSaturation: Double
    let oxygenSaturationVariability: Double // Standard deviation of Oxygen Saturation
    
    // Accelerometer-derived movement features
    let activityCount: Double // Sum of magnitudes of accelerometer data
    let sleepWakeDetection: Double // A simple heuristic (e.g., 0 for sleep, 1 for wake)
    
    // Wrist Temperature features
    let wristTemperatureAverage: Double
    let wristTemperatureGradient: Double // Change in temperature over time
    
    // Timestamp for the feature window
    let timestamp: Date
}

/// SleepFeatureExtractor extracts features from raw sleep tracking data for ML models.
public struct SleepFeatureExtractor {
    /// Extracts features from a sequence of sleep data points.
    /// - Parameter data: The raw sleep data points.
    /// - Returns: An array of extracted features.
    public static func extractFeatures(from data: [SleepDataPoint]) -> [Double] {
        guard !data.isEmpty else { return [] }

        // Heart Rate values
        let hrValues = data.filter { $0.type == "heartRate" }.map { $0.value }
        // RMSSD & SDNN calculation based on HR to RR intervals
        let rrIntervals = hrValues.map { 60.0 / $0 }
        let diffs = zip(rrIntervals, rrIntervals.dropFirst()).map { $1 - $0 }
        let rmssd = sqrt(diffs.map { $0 * $0 }.reduce(0, +) / Double(max(diffs.count, 1)))
        let sdnn = {
            guard !rrIntervals.isEmpty else { return 0.0 }
            let mean = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
            let varSum = rrIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rrIntervals.count)
            return sqrt(varSum)
        }()

        // Averages and variabilities
        func avg(_ arr: [Double]) -> Double { arr.isEmpty ? 0.0 : arr.reduce(0, +) / Double(arr.count) }
        func stddev(_ arr: [Double]) -> Double { guard !arr.isEmpty else { return 0.0 }; let m = avg(arr); return sqrt(arr.map { pow($0 - m, 2) }.reduce(0, +) / Double(arr.count)) }

        let hrAvg = avg(hrValues)
        let hrVar = stddev(hrValues)

        let spo2Values = data.filter { $0.type == "oxygenSaturation" }.map { $0.value }
        let spo2Avg = avg(spo2Values)
        let spo2Var = stddev(spo2Values)

        let tempValues = data.filter { $0.type == "bodyTemperature" }.map { $0.value }
        let tempAvg = avg(tempValues)
        let tempGradient = (tempValues.last ?? 0.0) - (tempValues.first ?? 0.0)

        let accelValues = data.filter { $0.type == "accelerometer" }.map { $0.value }
        let activityCount = accelValues.reduce(0, +)
        let sleepWake = activityCount > 5.0 ? 1.0 : 0.0

        return [rmssd, sdnn, hrAvg, hrVar, spo2Avg, spo2Var, activityCount, sleepWake, tempAvg, tempGradient]
    }
}

/// Represents a single sleep data point for feature extraction.
public struct SleepDataPoint {
    /// The timestamp of the data point.
    public let timestamp: Date
    /// The measured value (e.g., heart rate, movement).
    public let value: Double
    /// The type of measurement (e.g., heartRate, movement, temperature).
    public let type: String
    public init(timestamp: Date, value: Double, type: String) {
        self.timestamp = timestamp
        self.value = value
        self.type = type
    }
}

class SleepFeatureExtractorImpl {
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
        
        let oxygenSaturationAvg = calculateAverage(oxygenSaturations) ?? 0.0
        let oxygenSaturationStdDev = calculateStandardDeviation(oxygenSaturations) ?? 0.0
        
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
            oxygenSaturation: oxygenSaturationAvg,
            oxygenSaturationVariability: oxygenSaturationStdDev,
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
        guard let mean = calculateAverage(values) else { return nil }
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
        // Calculate activity count from accelerometer data (3D vector magnitude)
        return accelerometerSamples.map { sample -> Double in
            guard let x = sample.x, let y = sample.y, let z = sample.z else {
                return 0.0 // Handle missing accelerometer components
            }
            return sqrt(x * x + y * y + z * z)
        }.reduce(0, +)
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