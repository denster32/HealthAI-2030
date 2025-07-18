import Foundation

// MARK: - CSV Export Handler

@available(iOS 14.0, *)
class CSVExportHandler: BaseExportHandler {
    
    override var fileExtension: String {
        return "csv"
    }
    
    override var mimeType: String {
        return "text/csv"
    }
    
    override func generateExport(
        data: ProcessedHealthData,
        request: ExportRequest,
        outputPath: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws {
        
        try validateData(data)
        
        let updateProgress = createProgressTracker(totalSteps: 4, callback: progressCallback)
        
        // Step 1: Determine CSV format
        updateProgress(1)
        let csvFormat = determinCSVFormat(request: request)
        
        // Step 2: Generate CSV content
        updateProgress(2)
        let csvContent = try generateCSVContent(data: data, format: csvFormat, request: request)
        
        // Step 3: Apply formatting options
        updateProgress(3)
        let formattedContent = applyCSVFormatting(csvContent, request: request)
        
        // Step 4: Write to file
        updateProgress(4)
        try writeStringToFile(formattedContent, at: outputPath)
    }
    
    override func estimateFileSize(_ data: ProcessedHealthData) -> Int64 {
        // CSV is compact: ~120 bytes per data point + headers
        let dataPointsSize = Int64(data.dataPoints.count * 120)
        let headerSize: Int64 = 500 // Estimated header size
        return dataPointsSize + headerSize
    }
    
    // MARK: - CSV Format Types
    
    private enum CSVFormat {
        case standard           // One row per data point
        case grouped           // Group by data type
        case summary           // Summary statistics only
        case detailed          // Include all metadata
    }
    
    private func determinCSVFormat(request: ExportRequest) -> CSVFormat {
        switch request.customOptions["csvFormat"] {
        case "grouped":
            return .grouped
        case "summary":
            return .summary
        case "detailed":
            return .detailed
        default:
            return .standard
        }
    }
    
    // MARK: - CSV Content Generation
    
    private func generateCSVContent(data: ProcessedHealthData, format: CSVFormat, request: ExportRequest) throws -> String {
        switch format {
        case .standard:
            return try generateStandardCSV(data: data, request: request)
        case .grouped:
            return try generateGroupedCSV(data: data, request: request)
        case .summary:
            return try generateSummaryCSV(data: data, request: request)
        case .detailed:
            return try generateDetailedCSV(data: data, request: request)
        }
    }
    
    // MARK: - Standard CSV Format
    
    private func generateStandardCSV(data: ProcessedHealthData, request: ExportRequest) throws -> String {
        var csvContent = ""
        
        // Add header comment with export info
        csvContent += generateHeaderComment(data.metadata, request: request)
        
        // CSV Headers
        let headers = [
            "Data Type",
            "Category",
            "Value",
            "Unit",
            "Start Date",
            "End Date",
            "Source",
            "Device"
        ]
        
        csvContent += headers.map(sanitizeForCSV).joined(separator: ",") + "\n"
        
        // Data rows
        for dataPoint in data.dataPoints {
            let row = [
                sanitizeForCSV(dataPoint.dataType.rawValue),
                sanitizeForCSV(dataPoint.dataType.category.rawValue),
                formatValue(dataPoint.value),
                sanitizeForCSV(dataPoint.unit),
                sanitizeForCSV(formatDateForCSV(dataPoint.startDate)),
                sanitizeForCSV(formatDateForCSV(dataPoint.endDate)),
                sanitizeForCSV(dataPoint.source),
                sanitizeForCSV(dataPoint.device ?? "")
            ]
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    // MARK: - Grouped CSV Format
    
    private func generateGroupedCSV(data: ProcessedHealthData, request: ExportRequest) throws -> String {
        var csvContent = ""
        
        // Add header comment
        csvContent += generateHeaderComment(data.metadata, request: request)
        
        // Group data by type
        let groupedData = Dictionary(grouping: data.dataPoints) { $0.dataType }
        
        for (dataType, points) in groupedData.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            // Section header
            csvContent += "\n# \(dataType.rawValue) (\(dataType.category.rawValue))\n"
            
            // Headers for this data type
            let headers = [
                "Date",
                "Value",
                "Unit",
                "Source",
                "Device"
            ]
            
            csvContent += headers.map(sanitizeForCSV).joined(separator: ",") + "\n"
            
            // Data rows for this type
            for point in points.sorted(by: { $0.startDate < $1.startDate }) {
                let row = [
                    sanitizeForCSV(formatDateForCSV(point.startDate)),
                    formatValue(point.value),
                    sanitizeForCSV(point.unit),
                    sanitizeForCSV(point.source),
                    sanitizeForCSV(point.device ?? "")
                ]
                
                csvContent += row.joined(separator: ",") + "\n"
            }
        }
        
        return csvContent
    }
    
    // MARK: - Summary CSV Format
    
    private func generateSummaryCSV(data: ProcessedHealthData, request: ExportRequest) throws -> String {
        var csvContent = ""
        
        // Add header comment
        csvContent += generateHeaderComment(data.metadata, request: request)
        
        // Summary headers
        let headers = [
            "Data Type",
            "Category",
            "Unit",
            "Count",
            "Average",
            "Minimum",
            "Maximum",
            "First Date",
            "Last Date"
        ]
        
        csvContent += headers.map(sanitizeForCSV).joined(separator: ",") + "\n"
        
        // Group and summarize data
        let groupedData = Dictionary(grouping: data.dataPoints) { $0.dataType }
        
        for (dataType, points) in groupedData.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let values = points.map { $0.value }
            let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            let minimum = values.min() ?? 0
            let maximum = values.max() ?? 0
            let firstDate = points.map { $0.startDate }.min() ?? Date()
            let lastDate = points.map { $0.endDate }.max() ?? Date()
            
            let row = [
                sanitizeForCSV(dataType.rawValue),
                sanitizeForCSV(dataType.category.rawValue),
                sanitizeForCSV(dataType.unit),
                String(points.count),
                formatValue(average),
                formatValue(minimum),
                formatValue(maximum),
                sanitizeForCSV(formatDateForCSV(firstDate)),
                sanitizeForCSV(formatDateForCSV(lastDate))
            ]
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    // MARK: - Detailed CSV Format
    
    private func generateDetailedCSV(data: ProcessedHealthData, request: ExportRequest) throws -> String {
        var csvContent = ""
        
        // Add header comment
        csvContent += generateHeaderComment(data.metadata, request: request)
        
        // Detailed headers (including metadata)
        let baseHeaders = [
            "ID",
            "Data Type",
            "Category",
            "Value",
            "Unit",
            "Start Date",
            "End Date",
            "Source",
            "Device"
        ]
        
        // Collect all unique metadata keys
        let allMetadataKeys = Set(data.dataPoints.flatMap { $0.metadata.keys }).sorted()
        let headers = baseHeaders + allMetadataKeys.map { "Metadata: \($0)" }
        
        csvContent += headers.map(sanitizeForCSV).joined(separator: ",") + "\n"
        
        // Data rows with metadata
        for dataPoint in data.dataPoints {
            var row = [
                sanitizeForCSV(dataPoint.id),
                sanitizeForCSV(dataPoint.dataType.rawValue),
                sanitizeForCSV(dataPoint.dataType.category.rawValue),
                formatValue(dataPoint.value),
                sanitizeForCSV(dataPoint.unit),
                sanitizeForCSV(formatDateForCSV(dataPoint.startDate)),
                sanitizeForCSV(formatDateForCSV(dataPoint.endDate)),
                sanitizeForCSV(dataPoint.source),
                sanitizeForCSV(dataPoint.device ?? "")
            ]
            
            // Add metadata values
            for key in allMetadataKeys {
                let value = dataPoint.metadata[key] ?? ""
                row.append(sanitizeForCSV(value))
            }
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    // MARK: - Helper Methods
    
    private func generateHeaderComment(_ metadata: ExportMetadata, request: ExportRequest) -> String {
        var comment = ""
        comment += "# HealthAI 2030 Health Data Export\n"
        comment += "# Export ID: \(metadata.exportId)\n"
        comment += "# Generated: \(formatDateForDisplay(metadata.exportDate))\n"
        comment += "# App Version: \(metadata.appVersion)\n"
        comment += "# Date Range: \(formatDateForDisplay(request.dateRange.startDate)) to \(formatDateForDisplay(request.dateRange.endDate))\n"
        comment += "# Total Records: \(request.dataTypes.isEmpty ? "All Data Types" : "\(request.dataTypes.count) Data Types")\n"
        comment += "\n"
        return comment
    }
    
    private func formatDateForCSV(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    private func applyCSVFormatting(_ content: String, request: ExportRequest) -> String {
        // Apply any CSV-specific formatting options
        var formattedContent = content
        
        // Custom delimiter
        if let delimiter = request.customOptions["csvDelimiter"], delimiter != "," {
            formattedContent = formattedContent.replacingOccurrences(of: ",", with: delimiter)
        }
        
        // Line ending format
        let lineEnding = request.customOptions["lineEnding"] ?? "\n"
        if lineEnding != "\n" {
            formattedContent = formattedContent.replacingOccurrences(of: "\n", with: lineEnding)
        }
        
        return formattedContent
    }
}

// MARK: - CSV Export Options

extension ExportRequest {
    /// Get CSV-specific export options
    var csvExportOptions: CSVExportOptions {
        return CSVExportOptions(
            format: customOptions["csvFormat"] ?? "standard",
            delimiter: customOptions["csvDelimiter"] ?? ",",
            lineEnding: customOptions["lineEnding"] ?? "\n",
            includeHeaders: customOptions["includeHeaders"] != "false",
            includeComments: customOptions["includeComments"] != "false"
        )
    }
}

struct CSVExportOptions {
    let format: String
    let delimiter: String
    let lineEnding: String
    let includeHeaders: Bool
    let includeComments: Bool
    
    init(format: String = "standard", delimiter: String = ",", lineEnding: String = "\n", includeHeaders: Bool = true, includeComments: Bool = true) {
        self.format = format
        self.delimiter = delimiter
        self.lineEnding = lineEnding
        self.includeHeaders = includeHeaders
        self.includeComments = includeComments
    }
}