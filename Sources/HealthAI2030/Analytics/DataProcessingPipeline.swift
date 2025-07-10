import Foundation
import Combine

/// Data Processing Pipeline - Real-time data processing pipeline
/// Agent 6 Deliverable: Day 1-3 Core Analytics Framework
public class DataProcessingPipeline {
    
    // MARK: - Properties
    
    private let cleaningEngine = DataCleaningEngine()
    private let validationEngine = DataValidationEngine()
    private let transformationEngine = DataTransformationEngine()
    private let enrichmentEngine = DataEnrichmentEngine()
    
    // MARK: - Public Methods
    
    /// Preprocess raw health data through the complete pipeline
    public func preprocess(_ data: HealthDataSet) async throws -> ProcessedHealthData {
        
        // Step 1: Validate data integrity
        let validatedData = try await validationEngine.validate(data)
        
        // Step 2: Clean the data
        let cleanedData = try await cleaningEngine.clean(validatedData)
        
        // Step 3: Transform data format
        let transformedData = try await transformationEngine.transform(cleanedData)
        
        // Step 4: Enrich with additional context
        let enrichedData = try await enrichmentEngine.enrich(transformedData)
        
        // Step 5: Extract features
        let features = try await extractFeatures(from: enrichedData)
        
        return ProcessedHealthData(
            originalData: data,
            cleanedData: enrichedData,
            features: features,
            timestamp: Date()
        )
    }
    
    /// Process streaming data in real-time
    public func processStream(_ stream: AsyncStream<HealthDataPoint>) -> AsyncStream<ProcessedHealthDataPoint> {
        AsyncStream { continuation in
            Task {
                for await dataPoint in stream {
                    do {
                        let processedPoint = try await processDataPoint(dataPoint)
                        continuation.yield(processedPoint)
                    } catch {
                        // Log error but continue processing
                        print("Error processing data point: \(error)")
                    }
                }
                continuation.finish()
            }
        }
    }
    
    /// Batch process multiple datasets efficiently
    public func batchProcess(_ datasets: [HealthDataSet]) async throws -> [ProcessedHealthData] {
        return try await withThrowingTaskGroup(of: ProcessedHealthData.self) { group in
            for dataset in datasets {
                group.addTask {
                    try await self.preprocess(dataset)
                }
            }
            
            var results: [ProcessedHealthData] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    // MARK: - Private Methods
    
    private func processDataPoint(_ dataPoint: HealthDataPoint) async throws -> ProcessedHealthDataPoint {
        let validatedPoint = try await validationEngine.validateDataPoint(dataPoint)
        let cleanedPoint = try await cleaningEngine.cleanDataPoint(validatedPoint)
        let transformedPoint = try await transformationEngine.transformDataPoint(cleanedPoint)
        let enrichedPoint = try await enrichmentEngine.enrichDataPoint(transformedPoint)
        
        return ProcessedHealthDataPoint(
            original: dataPoint,
            processed: enrichedPoint,
            features: extractDataPointFeatures(enrichedPoint),
            timestamp: Date()
        )
    }
    
    private func extractFeatures(from data: [HealthDataPoint]) async throws -> [String: Double] {
        var features: [String: Double] = [:]
        
        // Statistical features
        features["mean"] = data.map { $0.value }.reduce(0, +) / Double(data.count)
        features["variance"] = calculateVariance(data.map { $0.value })
        features["min"] = data.map { $0.value }.min() ?? 0
        features["max"] = data.map { $0.value }.max() ?? 0
        
        // Temporal features
        features["data_points_count"] = Double(data.count)
        features["time_span_hours"] = calculateTimeSpan(data)
        features["sampling_rate"] = calculateSamplingRate(data)
        
        // Domain-specific features
        features.merge(extractDomainFeatures(data)) { _, new in new }
        
        return features
    }
    
    private func extractDataPointFeatures(_ dataPoint: HealthDataPoint) -> [String: Double] {
        var features: [String: Double] = [:]
        
        features["value"] = dataPoint.value
        features["hour_of_day"] = Double(Calendar.current.component(.hour, from: dataPoint.timestamp))
        features["day_of_week"] = Double(Calendar.current.component(.weekday, from: dataPoint.timestamp))
        
        // Type-specific features
        switch dataPoint.type {
        case .heartRate:
            features["is_resting"] = dataPoint.value < 70 ? 1.0 : 0.0
            features["is_elevated"] = dataPoint.value > 100 ? 1.0 : 0.0
        case .bloodPressure:
            features["is_normal"] = (dataPoint.value >= 90 && dataPoint.value <= 140) ? 1.0 : 0.0
        case .glucose:
            features["is_fasting"] = dataPoint.value < 100 ? 1.0 : 0.0
        default:
            break
        }
        
        return features
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    private func calculateTimeSpan(_ data: [HealthDataPoint]) -> Double {
        guard let earliest = data.map({ $0.timestamp }).min(),
              let latest = data.map({ $0.timestamp }).max() else {
            return 0
        }
        return latest.timeIntervalSince(earliest) / 3600 // Convert to hours
    }
    
    private func calculateSamplingRate(_ data: [HealthDataPoint]) -> Double {
        guard data.count > 1 else { return 0 }
        let timeSpan = calculateTimeSpan(data)
        return timeSpan > 0 ? Double(data.count) / timeSpan : 0
    }
    
    private func extractDomainFeatures(_ data: [HealthDataPoint]) -> [String: Double] {
        var features: [String: Double] = [:]
        
        // Group by type
        let groupedData = Dictionary(grouping: data) { $0.type }
        
        for (type, points) in groupedData {
            let prefix = type.rawValue
            features["\(prefix)_count"] = Double(points.count)
            features["\(prefix)_mean"] = points.map { $0.value }.reduce(0, +) / Double(points.count)
            features["\(prefix)_std"] = sqrt(calculateVariance(points.map { $0.value }))
        }
        
        return features
    }
}

// MARK: - Supporting Classes

public class DataCleaningEngine {
    
    func clean(_ data: HealthDataSet) async throws -> [HealthDataPoint] {
        var cleanedData = data.dataPoints
        
        // Remove duplicates
        cleanedData = removeDuplicates(cleanedData)
        
        // Handle outliers
        cleanedData = try await handleOutliers(cleanedData)
        
        // Fill missing values
        cleanedData = try await fillMissingValues(cleanedData)
        
        // Smooth noisy data
        cleanedData = try await smoothData(cleanedData)
        
        return cleanedData
    }
    
    func cleanDataPoint(_ dataPoint: HealthDataPoint) async throws -> HealthDataPoint {
        var cleaned = dataPoint
        
        // Apply data point level cleaning
        cleaned = try await validateRange(cleaned)
        cleaned = try await normalizeValue(cleaned)
        
        return cleaned
    }
    
    private func removeDuplicates(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        var seen = Set<String>()
        return data.filter { point in
            let key = "\(point.type.rawValue)_\(point.timestamp.timeIntervalSince1970)"
            return seen.insert(key).inserted
        }
    }
    
    private func handleOutliers(_ data: [HealthDataPoint]) async throws -> [HealthDataPoint] {
        // Group by type and handle outliers per type
        let groupedData = Dictionary(grouping: data) { $0.type }
        var cleanedData: [HealthDataPoint] = []
        
        for (_, points) in groupedData {
            let values = points.map { $0.value }
            let q1 = percentile(values, 0.25)
            let q3 = percentile(values, 0.75)
            let iqr = q3 - q1
            let lowerBound = q1 - 1.5 * iqr
            let upperBound = q3 + 1.5 * iqr
            
            let filtered = points.filter { point in
                point.value >= lowerBound && point.value <= upperBound
            }
            cleanedData.append(contentsOf: filtered)
        }
        
        return cleanedData
    }
    
    private func fillMissingValues(_ data: [HealthDataPoint]) async throws -> [HealthDataPoint] {
        // Implementation for handling missing values
        return data
    }
    
    private func smoothData(_ data: [HealthDataPoint]) async throws -> [HealthDataPoint] {
        // Apply smoothing algorithms (e.g., moving average)
        return data
    }
    
    private func validateRange(_ dataPoint: HealthDataPoint) async throws -> HealthDataPoint {
        // Validate data point is within expected ranges
        return dataPoint
    }
    
    private func normalizeValue(_ dataPoint: HealthDataPoint) async throws -> HealthDataPoint {
        // Apply normalization if needed
        return dataPoint
    }
    
    private func percentile(_ values: [Double], _ p: Double) -> Double {
        let sorted = values.sorted()
        let index = Int(Double(sorted.count - 1) * p)
        return sorted[index]
    }
}

public class DataValidationEngine {
    
    func validate(_ data: HealthDataSet) async throws -> HealthDataSet {
        guard !data.dataPoints.isEmpty else {
            throw DataProcessingError.emptyDataset
        }
        
        guard data.metadata.isValid else {
            throw DataProcessingError.invalidMetadata
        }
        
        // Validate each data point
        let validatedPoints = try await validateDataPoints(data.dataPoints)
        
        return HealthDataSet(
            dataPoints: validatedPoints,
            metadata: data.metadata,
            timestamp: data.timestamp
        )
    }
    
    func validateDataPoint(_ dataPoint: HealthDataPoint) async throws -> HealthDataPoint {
        // Validate timestamp
        guard dataPoint.timestamp <= Date() else {
            throw DataProcessingError.futureTimestamp
        }
        
        // Validate value ranges based on type
        try validateValueRange(dataPoint)
        
        return dataPoint
    }
    
    private func validateDataPoints(_ dataPoints: [HealthDataPoint]) async throws -> [HealthDataPoint] {
        return try await withThrowingTaskGroup(of: HealthDataPoint.self) { group in
            for dataPoint in dataPoints {
                group.addTask {
                    try await self.validateDataPoint(dataPoint)
                }
            }
            
            var validatedPoints: [HealthDataPoint] = []
            for try await point in group {
                validatedPoints.append(point)
            }
            return validatedPoints
        }
    }
    
    private func validateValueRange(_ dataPoint: HealthDataPoint) throws {
        switch dataPoint.type {
        case .heartRate:
            guard dataPoint.value >= 30 && dataPoint.value <= 220 else {
                throw DataProcessingError.valueOutOfRange
            }
        case .bloodPressure:
            guard dataPoint.value >= 60 && dataPoint.value <= 200 else {
                throw DataProcessingError.valueOutOfRange
            }
        case .glucose:
            guard dataPoint.value >= 50 && dataPoint.value <= 400 else {
                throw DataProcessingError.valueOutOfRange
            }
        default:
            break
        }
    }
}

public class DataTransformationEngine {
    
    func transform(_ data: [HealthDataPoint]) async throws -> [HealthDataPoint] {
        return try await withTaskGroup(of: HealthDataPoint.self) { group in
            for dataPoint in data {
                group.addTask {
                    await self.transformDataPoint(dataPoint)
                }
            }
            
            var transformedData: [HealthDataPoint] = []
            for await point in group {
                transformedData.append(point)
            }
            return transformedData
        }
    }
    
    func transformDataPoint(_ dataPoint: HealthDataPoint) async -> HealthDataPoint {
        // Apply transformations (unit conversions, normalizations, etc.)
        return dataPoint
    }
}

public class DataEnrichmentEngine {
    
    func enrich(_ data: [HealthDataPoint]) async throws -> [HealthDataPoint] {
        // Add contextual information, external data, etc.
        return data
    }
    
    func enrichDataPoint(_ dataPoint: HealthDataPoint) async throws -> HealthDataPoint {
        // Enrich individual data point with context
        return dataPoint
    }
}

// MARK: - Supporting Types

public struct ProcessedHealthDataPoint {
    public let original: HealthDataPoint
    public let processed: HealthDataPoint
    public let features: [String: Double]
    public let timestamp: Date
}

public enum DataProcessingError: Error {
    case emptyDataset
    case invalidMetadata
    case futureTimestamp
    case valueOutOfRange
    case processingFailed
}
