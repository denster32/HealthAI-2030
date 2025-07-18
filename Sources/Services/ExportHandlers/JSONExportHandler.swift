import Foundation

// MARK: - JSON Export Handler

@available(iOS 14.0, *)
class JSONExportHandler: BaseExportHandler {
    
    override var fileExtension: String {
        return "json"
    }
    
    override var mimeType: String {
        return "application/json"
    }
    
    override func generateExport(
        data: ProcessedHealthData,
        request: ExportRequest,
        outputPath: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws {
        
        try validateData(data)
        
        let updateProgress = createProgressTracker(totalSteps: 5, callback: progressCallback)
        
        // Step 1: Create JSON structure
        updateProgress(1)
        let jsonStructure = try createJSONStructure(data: data, request: request)
        
        // Step 2: Convert to JSON Data
        updateProgress(2)
        let jsonData = try encodeToJSON(jsonStructure)
        
        // Step 3: Apply formatting if requested
        updateProgress(3)
        let formattedData = try applyJSONFormatting(jsonData, request: request)
        
        // Step 4: Apply compression if requested
        updateProgress(4)
        let finalData = try applyCompressionIfNeeded(formattedData, request: request)
        
        // Step 5: Write to file
        updateProgress(5)
        try writeDataToFile(finalData, at: outputPath)
    }
    
    override func estimateFileSize(_ data: ProcessedHealthData) -> Int64 {
        // JSON is verbose: ~300 bytes per data point + metadata
        let dataPointsSize = Int64(data.dataPoints.count * 300)
        let metadataSize: Int64 = 5000 // Estimated metadata size
        return dataPointsSize + metadataSize
    }
    
    // MARK: - JSON Structure Creation
    
    private func createJSONStructure(data: ProcessedHealthData, request: ExportRequest) throws -> [String: Any] {
        return [
            "exportInfo": createExportInfo(data.metadata, request: request),
            "summary": createSummarySection(data.summary),
            "healthData": createHealthDataSection(data.dataPoints),
            "dataTypes": createDataTypesSection(data.dataPoints),
            "statistics": createStatisticsSection(data.dataPoints)
        ]
    }
    
    private func createExportInfo(_ metadata: ExportMetadata, request: ExportRequest) -> [String: Any] {
        return [
            "exportId": metadata.exportId,
            "exportDate": formatDate(metadata.exportDate),
            "appVersion": metadata.appVersion,
            "osVersion": metadata.osVersion,
            "deviceModel": metadata.deviceModel,
            "generatedBy": metadata.generatedBy,
            "format": metadata.exportFormat.rawValue,
            "dateRange": [
                "startDate": formatDate(request.dateRange.startDate),
                "endDate": formatDate(request.dateRange.endDate),
                "duration": request.dateRange.duration,
                "dayCount": request.dateRange.dayCount
            ],
            "privacySettings": [
                "anonymizeData": metadata.privacySettings.anonymizeData,
                "excludeSensitiveData": metadata.privacySettings.excludeSensitiveData,
                "includeMetadata": metadata.privacySettings.includeMetadata,
                "includeDeviceInfo": metadata.privacySettings.includeDeviceInfo
            ],
            "requestedDataTypes": request.dataTypes.map { $0.rawValue },
            "customOptions": request.customOptions
        ]
    }
    
    private func createSummarySection(_ summary: HealthDataSummary) -> [String: Any] {
        return [
            "totalRecords": summary.totalRecords,
            "dateRange": [
                "startDate": formatDate(summary.dateRange.startDate),
                "endDate": formatDate(summary.dateRange.endDate)
            ],
            "dataTypeBreakdown": summary.dataTypeBreakdown.mapKeys { $0.rawValue },
            "sourceBreakdown": summary.sourceBreakdown
        ]
    }
    
    private func createHealthDataSection(_ dataPoints: [HealthDataPoint]) -> [[String: Any]] {
        return dataPoints.map { dataPoint in
            var pointData: [String: Any] = [
                "id": dataPoint.id,
                "dataType": dataPoint.dataType.rawValue,
                "value": dataPoint.value,
                "unit": dataPoint.unit,
                "startDate": formatDate(dataPoint.startDate),
                "endDate": formatDate(dataPoint.endDate),
                "source": dataPoint.source
            ]
            
            if let device = dataPoint.device {
                pointData["device"] = device
            }
            
            if !dataPoint.metadata.isEmpty {
                pointData["metadata"] = dataPoint.metadata
            }
            
            return pointData
        }
    }
    
    private func createDataTypesSection(_ dataPoints: [HealthDataPoint]) -> [[String: Any]] {
        let uniqueDataTypes = Set(dataPoints.map { $0.dataType })
        
        return uniqueDataTypes.map { dataType in
            let typePoints = dataPoints.filter { $0.dataType == dataType }
            
            return [
                "type": dataType.rawValue,
                "category": dataType.category.rawValue,
                "unit": dataType.unit,
                "count": typePoints.count,
                "dateRange": [
                    "earliest": typePoints.map { $0.startDate }.min().map(formatDate) ?? "",
                    "latest": typePoints.map { $0.endDate }.max().map(formatDate) ?? ""
                ],
                "valueRange": [
                    "minimum": typePoints.map { $0.value }.min() ?? 0,
                    "maximum": typePoints.map { $0.value }.max() ?? 0,
                    "average": typePoints.isEmpty ? 0 : typePoints.map { $0.value }.reduce(0, +) / Double(typePoints.count)
                ]
            ]
        }.sorted { ($0["type"] as? String ?? "") < ($1["type"] as? String ?? "") }
    }
    
    private func createStatisticsSection(_ dataPoints: [HealthDataPoint]) -> [String: Any] {
        let groupedByCategory = Dictionary(grouping: dataPoints) { $0.dataType.category }
        
        var categoryStats: [String: Any] = [:]
        
        for (category, points) in groupedByCategory {
            categoryStats[category.rawValue] = [
                "count": points.count,
                "dataTypes": Set(points.map { $0.dataType.rawValue }).count,
                "dateRange": [
                    "earliest": points.map { $0.startDate }.min().map(formatDate) ?? "",
                    "latest": points.map { $0.endDate }.max().map(formatDate) ?? ""
                ]
            ]
        }
        
        return [
            "totalDataPoints": dataPoints.count,
            "uniqueDataTypes": Set(dataPoints.map { $0.dataType }).count,
            "uniqueSources": Set(dataPoints.map { $0.source }).count,
            "categoryBreakdown": categoryStats,
            "dailyAverages": calculateDailyAverages(dataPoints)
        ]
    }
    
    private func calculateDailyAverages(_ dataPoints: [HealthDataPoint]) -> [String: Any] {
        guard !dataPoints.isEmpty else { return [:] }
        
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: dataPoints) { dataPoint in
            calendar.startOfDay(for: dataPoint.startDate)
        }
        
        let dayCount = groupedByDay.keys.count
        guard dayCount > 0 else { return [:] }
        
        return [
            "dataPointsPerDay": Double(dataPoints.count) / Double(dayCount),
            "activeDays": dayCount,
            "dataTypesByDay": Dictionary(grouping: groupedByDay) { _, points in
                Set(points.map { $0.dataType }).count
            }.values.reduce(0, +) / dayCount
        ]
    }
    
    // MARK: - JSON Processing
    
    private func encodeToJSON(_ structure: [String: Any]) throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: structure, options: [])
        } catch {
            throw ExportError.dataProcessingError("Failed to encode JSON: \(error.localizedDescription)")
        }
    }
    
    private func applyJSONFormatting(_ data: Data, request: ExportRequest) throws -> Data {
        // Check if pretty printing is requested
        let shouldPrettyPrint = request.customOptions["prettyPrint"] == "true"
        
        if shouldPrettyPrint {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                return try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            } catch {
                throw ExportError.dataProcessingError("Failed to format JSON: \(error.localizedDescription)")
            }
        }
        
        return data
    }
    
    private func applyCompressionIfNeeded(_ data: Data, request: ExportRequest) throws -> Data {
        // JSON supports compression
        let shouldCompress = request.customOptions["compress"] == "true"
        
        if shouldCompress && data.count > 1024 * 1024 { // Only compress files > 1MB
            return try compressData(data)
        }
        
        return data
    }
    
    private func compressData(_ data: Data) throws -> Data {
        do {
            return try (data as NSData).compressed(using: .zlib) as Data
        } catch {
            throw ExportError.dataProcessingError("Failed to compress JSON data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Dictionary Extensions

private extension Dictionary where Key == HealthDataType, Value == Int {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: self.map { (transform($0.key), $0.value) })
    }
}

// MARK: - JSON Export Options

extension ExportRequest {
    /// Get JSON-specific export options
    var jsonExportOptions: JSONExportOptions {
        return JSONExportOptions(
            prettyPrint: customOptions["prettyPrint"] == "true",
            compress: customOptions["compress"] == "true",
            includeStatistics: customOptions["includeStatistics"] != "false",
            includeMetadata: privacySettings.includeMetadata
        )
    }
}

struct JSONExportOptions {
    let prettyPrint: Bool
    let compress: Bool
    let includeStatistics: Bool
    let includeMetadata: Bool
    
    init(prettyPrint: Bool = false, compress: Bool = false, includeStatistics: Bool = true, includeMetadata: Bool = true) {
        self.prettyPrint = prettyPrint
        self.compress = compress
        self.includeStatistics = includeStatistics
        self.includeMetadata = includeMetadata
    }
}