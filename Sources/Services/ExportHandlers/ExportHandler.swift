import Foundation

// MARK: - Export Handler Protocol

@available(iOS 14.0, *)
protocol ExportHandler {
    /// Generate an export file for the given data and request
    func generateExport(
        data: ProcessedHealthData,
        request: ExportRequest,
        outputPath: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws
    
    /// Get the file extension for this export format
    var fileExtension: String { get }
    
    /// Get the MIME type for this export format
    var mimeType: String { get }
    
    /// Validate that the data is suitable for this export format
    func validateData(_ data: ProcessedHealthData) throws
    
    /// Estimate the file size for the given data
    func estimateFileSize(_ data: ProcessedHealthData) -> Int64
}

// MARK: - Health Data Processor

@available(iOS 14.0, *)
class HealthDataProcessor {
    
    func process(
        data: [HealthDataPoint],
        request: ExportRequest,
        progressCallback: @escaping (Double) -> Void
    ) async throws -> ProcessedHealthData {
        
        // Filter data by selected data types if specified
        let filteredData = filterDataByTypes(data, request: request)
        progressCallback(0.2)
        
        // Apply privacy settings
        let privacyFilteredData = try await applyPrivacySettings(filteredData, settings: request.privacySettings)
        progressCallback(0.5)
        
        // Sort data by date
        let sortedData = privacyFilteredData.sorted { $0.startDate < $1.startDate }
        progressCallback(0.7)
        
        // Generate summary
        let summary = generateSummary(sortedData, dateRange: request.dateRange)
        progressCallback(0.9)
        
        // Generate metadata
        let metadata = ExportMetadata(
            exportId: request.id,
            exportFormat: request.format,
            privacySettings: request.privacySettings
        )
        progressCallback(1.0)
        
        return ProcessedHealthData(
            dataPoints: sortedData,
            summary: summary,
            metadata: metadata
        )
    }
    
    private func filterDataByTypes(_ data: [HealthDataPoint], request: ExportRequest) -> [HealthDataPoint] {
        if request.dataTypes.isEmpty {
            return data // All data types
        }
        
        return data.filter { request.dataTypes.contains($0.dataType) }
    }
    
    private func applyPrivacySettings(_ data: [HealthDataPoint], settings: ExportPrivacySettings) async throws -> [HealthDataPoint] {
        var processedData = data
        
        if settings.excludeSensitiveData {
            processedData = excludeSensitiveData(processedData)
        }
        
        if settings.anonymizeData {
            processedData = anonymizeData(processedData)
        }
        
        if !settings.includeMetadata {
            processedData = removeMetadata(processedData)
        }
        
        if !settings.includeDeviceInfo {
            processedData = removeDeviceInfo(processedData)
        }
        
        return processedData
    }
    
    private func excludeSensitiveData(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        // Define sensitive data types
        let sensitiveTypes: Set<HealthDataType> = [
            .medicalRecords,
            .immunizations,
            .allergies,
            .medications,
            .mood,
            .anxiety,
            .depression
        ]
        
        return data.filter { !sensitiveTypes.contains($0.dataType) }
    }
    
    private func anonymizeData(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { point in
            var anonymizedPoint = point
            // Remove identifying information
            anonymizedPoint = HealthDataPoint(
                id: UUID().uuidString, // New anonymous ID
                dataType: point.dataType,
                value: point.value,
                unit: point.unit,
                startDate: point.startDate,
                endDate: point.endDate,
                source: "Anonymous", // Anonymize source
                device: nil, // Remove device info
                metadata: [:] // Remove metadata
            )
            return anonymizedPoint
        }
    }
    
    private func removeMetadata(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { point in
            HealthDataPoint(
                id: point.id,
                dataType: point.dataType,
                value: point.value,
                unit: point.unit,
                startDate: point.startDate,
                endDate: point.endDate,
                source: point.source,
                device: point.device,
                metadata: [:] // Remove metadata
            )
        }
    }
    
    private func removeDeviceInfo(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { point in
            HealthDataPoint(
                id: point.id,
                dataType: point.dataType,
                value: point.value,
                unit: point.unit,
                startDate: point.startDate,
                endDate: point.endDate,
                source: point.source,
                device: nil, // Remove device info
                metadata: point.metadata
            )
        }
    }
    
    private func generateSummary(_ data: [HealthDataPoint], dateRange: DateRange) -> HealthDataSummary {
        return HealthDataSummary(dataPoints: data, dateRange: dateRange)
    }
}

// MARK: - Base Export Handler

@available(iOS 14.0, *)
class BaseExportHandler: ExportHandler {
    
    var fileExtension: String {
        return "dat"
    }
    
    var mimeType: String {
        return "application/octet-stream"
    }
    
    func generateExport(
        data: ProcessedHealthData,
        request: ExportRequest,
        outputPath: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws {
        // Basic implementation to be overridden by subclasses
        let placeholderData = "Export data placeholder".data(using: .utf8)!
        try placeholderData.write(to: outputPath)
        progressCallback(1.0)
    }
    
    func validateData(_ data: ProcessedHealthData) throws {
        guard !data.dataPoints.isEmpty else {
            throw ExportError.unknown(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data to export"]))
        }
    }
    
    func estimateFileSize(_ data: ProcessedHealthData) -> Int64 {
        // Base estimate: 200 bytes per data point
        return Int64(data.dataPoints.count * 200)
    }
    
    // MARK: - Helper Methods
    
    protected func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    protected func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    protected func formatValue(_ value: Double, decimalPlaces: Int = 2) -> String {
        return String(format: "%.\(decimalPlaces)f", value)
    }
    
    protected func sanitizeForCSV(_ string: String) -> String {
        // Escape quotes and wrap in quotes if contains comma, newline, or quote
        let needsQuoting = string.contains(",") || string.contains("\n") || string.contains("\"")
        if needsQuoting {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
    
    protected func createProgressTracker(totalSteps: Int, callback: @escaping (Double) -> Void) -> (Int) -> Void {
        return { currentStep in
            let progress = Double(currentStep) / Double(totalSteps)
            callback(min(1.0, max(0.0, progress)))
        }
    }
    
    protected func writeDataToFile(_ data: Data, at url: URL) throws {
        try data.write(to: url)
    }
    
    protected func writeStringToFile(_ string: String, at url: URL) throws {
        guard let data = string.data(using: .utf8) else {
            throw ExportError.unknown(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode string as UTF-8"]))
        }
        try writeDataToFile(data, at: url)
    }
}

// MARK: - Export Error Extensions

extension ExportError {
    static func invalidFormat(_ format: ExportFormat) -> ExportError {
        return .unknown(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid export format: \(format.rawValue)"]))
    }
    
    static func dataProcessingError(_ message: String) -> ExportError {
        return .unknown(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data processing error: \(message)"]))
    }
    
    static func fileGenerationError(_ message: String) -> ExportError {
        return .fileSystemError(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "File generation error: \(message)"]))
    }
}