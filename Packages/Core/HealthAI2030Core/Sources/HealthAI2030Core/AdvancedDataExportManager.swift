import Foundation
import CloudKit
import SwiftData
import UniformTypeIdentifiers
import OSLog

// MARK: - Export Types

@available(macOS 15.0, *)
public enum ExportType: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    case xml = "XML"
    case pdf = "PDF"
    case fhir = "FHIR"
    case hl7 = "HL7"
}

@available(macOS 15.0, *)
public struct ExportRequest: Identifiable {
    public let id = UUID()
    public let exportType: String
    public let requestDate: Date
    public let userId: UUID
    
    public init(exportType: String, requestDate: Date, userId: UUID) {
        self.exportType = exportType
        self.requestDate = requestDate
        self.userId = userId
    }
}

// MARK: - Syncable Model Types

@Model
final class SyncableHealthDataEntry: CKSyncable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var dataType: CKSyncableDataType
    var value: Double?
    var metadata: [String: String]?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), dataType: CKSyncableDataType = .general, value: Double? = nil, metadata: [String: String]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.value = value
        self.metadata = metadata
    }
}

@Model
final class SyncableSleepSessionEntry: CKSyncable {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date
    var dataType: CKSyncableDataType = .sleepData
    var sleepQuality: Double?
    var stages: [String: Double]?
    
    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date = Date(), sleepQuality: Double? = nil, stages: [String: Double]? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.sleepQuality = sleepQuality
        self.stages = stages
    }
}

@Model
final class AnalyticsInsight: CKSyncable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var dataType: CKSyncableDataType = .general
    var insightType: String
    var content: String
    var significance: Double
    
    init(id: UUID = UUID(), timestamp: Date = Date(), insightType: String = "", content: String = "", significance: Double = 0.0) {
        self.id = id
        self.timestamp = timestamp
        self.insightType = insightType
        self.content = content
        self.significance = significance
    }
}

@Model
final class MLModelUpdate: CKSyncable {
    @Attribute(.unique) var id: UUID
    var trainingDate: Date
    var dataType: CKSyncableDataType = .general
    var modelName: String
    var accuracy: Double
    var version: String
    
    init(id: UUID = UUID(), trainingDate: Date = Date(), modelName: String = "", accuracy: Double = 0.0, version: String = "1.0") {
        self.id = id
        self.trainingDate = trainingDate
        self.modelName = modelName
        self.accuracy = accuracy
        self.version = version
    }
}

@available(macOS 15.0, *)
@MainActor
public class AdvancedDataExportManager: ObservableObject {
    public static let shared = AdvancedDataExportManager()
    
    // MARK: - Properties
    @Published public var exportStatus: DataExportStatus = .idle
    @Published public var exportProgress: Double = 0.0
    @Published public var currentExportType: ExportType?
    @Published public var availableExports: [CompletedExport] = []
    @Published public var pendingRequests: [ExportRequest] = []
    
    private let logger = Logger()
    private let cloudSyncManager = UnifiedCloudKitSyncManager.shared
    private let exportQueue = DispatchQueue(label: "com.healthai2030.export", qos: .background)
    
    // Export processors
    private let csvProcessor = CSVExportProcessor()
    private let fhirProcessor = FHIRExportProcessor()
    private let hl7Processor = HL7ExportProcessor()
    private let pdfProcessor = PDFExportProcessor()
    
    // MARK: - Public Interface
    
    public func exportData(
        type: ExportType,
        dateRange: DateInterval,
        includeRawData: Bool = true,
        includeAnalytics: Bool = true,
        includeInsights: Bool = true
    ) async throws -> URL {
        
        guard exportStatus != .exporting else {
            throw ExportError.exportInProgress
        }
        
        exportStatus = .exporting
        currentExportType = type
        exportProgress = 0.0
        
        defer {
            exportStatus = .idle
            currentExportType = nil
            exportProgress = 0.0
        }
        
        do {
            logger.info("Starting export: \(type.rawValue)")
            
            // Gather data
            exportProgress = 0.1
            let exportData = try await gatherExportData(
                dateRange: dateRange,
                includeRawData: includeRawData,
                includeAnalytics: includeAnalytics,
                includeInsights: includeInsights
            )
            
            exportProgress = 0.4
            
            // Process data based on type
            let exportURL = try await processExport(
                data: exportData,
                type: type,
                dateRange: dateRange
            )
            
            exportProgress = 0.8
            
            // Save export record
            let completedExport = CompletedExport(
                id: UUID(),
                type: type,
                dateRange: dateRange,
                fileURL: exportURL,
                createdDate: Date(),
                fileSize: try getFileSize(url: exportURL)
            )
            
            availableExports.append(completedExport)
            exportProgress = 1.0
            
            logger.info("Export completed: \(exportURL.lastPathComponent)")
            return exportURL
            
        } catch {
            logger.error("Export failed: \(error.localizedDescription)")
            exportStatus = .error
            throw error
        }
    }
    
    public func processExportRequest(_ request: ExportRequest) async {
        guard let exportType = ExportType(rawValue: request.exportType) else {
            logger.error("Invalid export type: \(request.exportType)")
            return
        }
        
        do {
            let dateRange = try JSONDecoder().decode(DateInterval.self, from: request.dateRange)
            let exportURL = try await exportData(
                type: exportType,
                dateRange: dateRange,
                includeRawData: true,
                includeAnalytics: true,
                includeInsights: true
            )
            
            // Update request status and upload to CloudKit
            request.status = "completed"
            request.completedDate = Date()
            request.resultURL = exportURL.absoluteString
            request.needsSync = true
            
            // Sync the updated request
            guard let modelContext = try? ModelContext(ModelContainer.shared) else {
                logger.error("Could not get model context for export request update")
                return
            }
            
            try await cloudSyncManager.syncRecord(request, modelContext: modelContext)
            
            logger.info("Export request processed successfully")
            
        } catch {
            logger.error("Failed to process export request: \(error.localizedDescription)")
            request.status = "failed"
            request.needsSync = true
        }
    }
    
    public func monitorExportRequests() async {
        logger.info("Starting export request monitoring")
        
        while true {
            do {
                guard let modelContext = try? ModelContext(ModelContainer.shared) else {
                    logger.error("Could not get model context for monitoring")
                    continue
                }
                
                let descriptor = FetchDescriptor<ExportRequest>(
                    predicate: #Predicate { $0.status == "pending" }
                )
                
                let pendingRequests = try modelContext.fetch(descriptor)
                
                for request in pendingRequests {
                    await processExportRequest(request)
                }
                
                // Wait 30 seconds before checking again
                try await Task.sleep(nanoseconds: 30_000_000_000)
                
            } catch {
                logger.error("Error monitoring export requests: \(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Wait 1 minute on error
            }
        }
    }
    
    // MARK: - Data Gathering
    
    private func gatherExportData(
        dateRange: DateInterval,
        includeRawData: Bool,
        includeAnalytics: Bool,
        includeInsights: Bool
    ) async throws -> ExportDataSet {
        
        guard let modelContext = try? ModelContext(ModelContainer.shared) else {
            throw ExportError.dataContextUnavailable
        }
        
        var exportData = ExportDataSet()
        
        if includeRawData {
            // Gather health data entries
            let healthDataDescriptor = FetchDescriptor<SyncableHealthDataEntry>(
                predicate: #Predicate { entry in
                    entry.timestamp >= dateRange.start && entry.timestamp <= dateRange.end
                }
            )
            exportData.healthDataEntries = try modelContext.fetch(healthDataDescriptor)
            
            // Gather sleep session entries
            let sleepDescriptor = FetchDescriptor<SyncableSleepSessionEntry>(
                predicate: #Predicate { session in
                    session.startTime >= dateRange.start && session.endTime <= dateRange.end
                }
            )
            exportData.sleepSessions = try modelContext.fetch(sleepDescriptor)
        }
        
        if includeAnalytics {
            // Gather analytics insights
            let insightsDescriptor = FetchDescriptor<AnalyticsInsight>(
                predicate: #Predicate { insight in
                    insight.timestamp >= dateRange.start && insight.timestamp <= dateRange.end
                }
            )
            exportData.analyticsInsights = try modelContext.fetch(insightsDescriptor)
        }
        
        if includeInsights {
            // Gather ML model updates
            let modelsDescriptor = FetchDescriptor<MLModelUpdate>(
                predicate: #Predicate { update in
                    update.trainingDate >= dateRange.start && update.trainingDate <= dateRange.end
                }
            )
            exportData.modelUpdates = try modelContext.fetch(modelsDescriptor)
        }
        
        logger.info("Gathered export data: \(exportData.healthDataEntries.count) health entries, \(exportData.sleepSessions.count) sleep sessions, \(exportData.analyticsInsights.count) insights")
        
        return exportData
    }
    
    // MARK: - Export Processing
    
    private func processExport(
        data: ExportDataSet,
        type: ExportType,
        dateRange: DateInterval
    ) async throws -> URL {
        
        return try await withCheckedThrowingContinuation { continuation in
            exportQueue.async { [weak self] in
                do {
                    let url = try self?.generateExport(data: data, type: type, dateRange: dateRange)
                    continuation.resume(returning: url!)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func generateExport(
        data: ExportDataSet,
        type: ExportType,
        dateRange: DateInterval
    ) throws -> URL {
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "HealthAI_Export_\(type.rawValue)_\(timestamp)"
        
        switch type {
        case .csv:
            return try csvProcessor.generateCSVExport(data: data, filename: filename)
        case .fhir:
            return try fhirProcessor.generateFHIRExport(data: data, filename: filename)
        case .hl7:
            return try hl7Processor.generateHL7Export(data: data, filename: filename)
        case .pdf:
            return try pdfProcessor.generatePDFExport(data: data, filename: filename, dateRange: dateRange)
        }
    }
    
    // MARK: - Utility Methods
    
    private func getFileSize(url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    public func getAvailableExports() -> [CompletedExport] {
        return availableExports.sorted { $0.createdDate > $1.createdDate }
    }
    
    public func deleteExport(_ exportId: UUID) {
        if let index = availableExports.firstIndex(where: { $0.id == exportId }) {
            let export = availableExports[index]
            
            // Delete file
            try? FileManager.default.removeItem(at: export.fileURL)
            
            // Remove from list
            availableExports.remove(at: index)
            
            logger.info("Deleted export: \(export.fileURL.lastPathComponent)")
        }
    }
}

// MARK: - Export Processors

private class CSVExportProcessor {
    func generateCSVExport(data: ExportDataSet, filename: String) throws -> URL {
        let url = getExportURL(filename: "\(filename).csv")
        var csvContent = ""
        
        // Health Data CSV
        if !data.healthDataEntries.isEmpty {
            csvContent += "Health Data\n"
            csvContent += "ID,Timestamp,Resting Heart Rate,HRV,Oxygen Saturation,Body Temperature,Stress Level,Mood Score,Energy Level,Activity Level,Sleep Quality,Nutrition Score,Device Source\n"
            
            for entry in data.healthDataEntries {
                csvContent += "\(entry.id),\(entry.timestamp),\(entry.restingHeartRate),\(entry.hrv),\(entry.oxygenSaturation),\(entry.bodyTemperature),\(entry.stressLevel),\(entry.moodScore),\(entry.energyLevel),\(entry.activityLevel),\(entry.sleepQuality),\(entry.nutritionScore),\(entry.deviceSource)\n"
            }
            csvContent += "\n"
        }
        
        // Sleep Sessions CSV
        if !data.sleepSessions.isEmpty {
            csvContent += "Sleep Sessions\n"
            csvContent += "ID,Start Time,End Time,Duration,Quality Score,Device Source\n"
            
            for session in data.sleepSessions {
                csvContent += "\(session.id),\(session.startTime),\(session.endTime),\(session.duration),\(session.qualityScore),\(session.deviceSource)\n"
            }
            csvContent += "\n"
        }
        
        // Analytics Insights CSV
        if !data.analyticsInsights.isEmpty {
            csvContent += "Analytics Insights\n"
            csvContent += "ID,Title,Description,Category,Confidence,Timestamp,Source,Actionable,Priority\n"
            
            for insight in data.analyticsInsights {
                csvContent += "\(insight.id),\"\(insight.title)\",\"\(insight.description)\",\(insight.category),\(insight.confidence),\(insight.timestamp),\(insight.source),\(insight.actionable),\(insight.priority)\n"
            }
        }
        
        try csvContent.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func getExportURL(filename: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("HealthAI_Exports")
        
        try? FileManager.default.createDirectory(at: exportsPath, withIntermediateDirectories: true)
        
        return exportsPath.appendingPathComponent(filename)
    }
}

private class FHIRExportProcessor {
    func generateFHIRExport(data: ExportDataSet, filename: String) throws -> URL {
        let url = getExportURL(filename: "\(filename).json")
        
        // Create FHIR Bundle
        var fhirBundle: [String: Any] = [
            "resourceType": "Bundle",
            "id": UUID().uuidString,
            "type": "collection",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "entry": []
        ]
        
        var entries: [[String: Any]] = []
        
        // Convert health data to FHIR Observations
        for entry in data.healthDataEntries {
            let observation: [String: Any] = [
                "resourceType": "Observation",
                "id": entry.id.uuidString,
                "status": "final",
                "category": [
                    [
                        "coding": [
                            [
                                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                "code": "vital-signs",
                                "display": "Vital Signs"
                            ]
                        ]
                    ]
                ],
                "code": [
                    "coding": [
                        [
                            "system": "http://loinc.org",
                            "code": "85354-9",
                            "display": "Blood pressure panel with all children optional"
                        ]
                    ]
                ],
                "effectiveDateTime": ISO8601DateFormatter().string(from: entry.timestamp),
                "component": [
                    createFHIRComponent("8867-4", "Heart rate", entry.restingHeartRate, "beats/min"),
                    createFHIRComponent("80404-7", "Heart rate variability", entry.hrv, "ms"),
                    createFHIRComponent("2708-6", "Oxygen saturation", entry.oxygenSaturation, "%"),
                    createFHIRComponent("8310-5", "Body temperature", entry.bodyTemperature, "Cel")
                ]
            ]
            
            entries.append(["resource": observation])
        }
        
        // Convert sleep sessions to FHIR Observations
        for session in data.sleepSessions {
            let sleepObservation: [String: Any] = [
                "resourceType": "Observation",
                "id": session.id.uuidString,
                "status": "final",
                "category": [
                    [
                        "coding": [
                            [
                                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                                "code": "activity",
                                "display": "Activity"
                            ]
                        ]
                    ]
                ],
                "code": [
                    "coding": [
                        [
                            "system": "http://loinc.org",
                            "code": "93832-4",
                            "display": "Sleep quality"
                        ]
                    ]
                ],
                "effectivePeriod": [
                    "start": ISO8601DateFormatter().string(from: session.startTime),
                    "end": ISO8601DateFormatter().string(from: session.endTime)
                ],
                "valueQuantity": [
                    "value": session.qualityScore,
                    "unit": "score",
                    "system": "http://unitsofmeasure.org"
                ]
            ]
            
            entries.append(["resource": sleepObservation])
        }
        
        fhirBundle["entry"] = entries
        
        let jsonData = try JSONSerialization.data(withJSONObject: fhirBundle, options: .prettyPrinted)
        try jsonData.write(to: url)
        
        return url
    }
    
    private func createFHIRComponent(_ code: String, _ display: String, _ value: Double, _ unit: String) -> [String: Any] {
        return [
            "code": [
                "coding": [
                    [
                        "system": "http://loinc.org",
                        "code": code,
                        "display": display
                    ]
                ]
            ],
            "valueQuantity": [
                "value": value,
                "unit": unit,
                "system": "http://unitsofmeasure.org"
            ]
        ]
    }
    
    private func getExportURL(filename: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("HealthAI_Exports")
        
        try? FileManager.default.createDirectory(at: exportsPath, withIntermediateDirectories: true)
        
        return exportsPath.appendingPathComponent(filename)
    }
}

private class HL7ExportProcessor {
    func generateHL7Export(data: ExportDataSet, filename: String) throws -> URL {
        let url = getExportURL(filename: "\(filename).hl7")
        var hl7Content = ""
        
        // HL7 v2.x format
        let timestamp = DateFormatter.hl7.string(from: Date())
        
        // MSH (Message Header)
        hl7Content += "MSH|^~\\&|HealthAI|HealthAI2030|RECEIVER|RECEIVER|\(timestamp)||ORU^R01|MSG001|P|2.5\r"
        
        // PID (Patient Identification)
        hl7Content += "PID|1||PATIENT001^^^HealthAI||DOE^JOHN||19800101|M\r"
        
        var observationCounter = 1
        
        // OBX segments for health data
        for entry in data.healthDataEntries {
            let entryTimestamp = DateFormatter.hl7.string(from: entry.timestamp)
            
            hl7Content += "OBR|\(observationCounter)|||VITALS^Vital Signs|||\(entryTimestamp)\r"
            hl7Content += "OBX|\(observationCounter)|NM|HR^Heart Rate|||\(entry.restingHeartRate)|BPM||||F\r"
            hl7Content += "OBX|\(observationCounter + 1)|NM|HRV^Heart Rate Variability|||\(entry.hrv)|MS||||F\r"
            hl7Content += "OBX|\(observationCounter + 2)|NM|SPO2^Oxygen Saturation|||\(entry.oxygenSaturation)|%||||F\r"
            hl7Content += "OBX|\(observationCounter + 3)|NM|TEMP^Body Temperature|||\(entry.bodyTemperature)|C||||F\r"
            
            observationCounter += 4
        }
        
        // OBX segments for sleep data
        for session in data.sleepSessions {
            let sessionTimestamp = DateFormatter.hl7.string(from: session.startTime)
            
            hl7Content += "OBR|\(observationCounter)|||SLEEP^Sleep Analysis|||\(sessionTimestamp)\r"
            hl7Content += "OBX|\(observationCounter)|NM|SLEEP_QUALITY^Sleep Quality|||\(session.qualityScore)|SCORE||||F\r"
            hl7Content += "OBX|\(observationCounter + 1)|NM|SLEEP_DURATION^Sleep Duration|||\(session.duration)|SEC||||F\r"
            
            observationCounter += 2
        }
        
        try hl7Content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func getExportURL(filename: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("HealthAI_Exports")
        
        try? FileManager.default.createDirectory(at: exportsPath, withIntermediateDirectories: true)
        
        return exportsPath.appendingPathComponent(filename)
    }
}

private class PDFExportProcessor {
    func generatePDFExport(data: ExportDataSet, filename: String, dateRange: DateInterval) throws -> URL {
        let url = getExportURL(filename: "\(filename).pdf")
        
        // For now, create a simple text-based PDF representation
        // In a real implementation, you would use Core Graphics or a PDF library
        
        var pdfContent = "HealthAI 2030 - Health Data Export Report\n"
        pdfContent += "Generated: \(DateFormatter.readable.string(from: Date()))\n"
        pdfContent += "Date Range: \(DateFormatter.readable.string(from: dateRange.start)) - \(DateFormatter.readable.string(from: dateRange.end))\n\n"
        
        // Summary statistics
        pdfContent += "SUMMARY\n"
        pdfContent += "========\n"
        pdfContent += "Health Data Entries: \(data.healthDataEntries.count)\n"
        pdfContent += "Sleep Sessions: \(data.sleepSessions.count)\n"
        pdfContent += "Analytics Insights: \(data.analyticsInsights.count)\n"
        pdfContent += "ML Model Updates: \(data.modelUpdates.count)\n\n"
        
        if !data.healthDataEntries.isEmpty {
            pdfContent += "HEALTH DATA TRENDS\n"
            pdfContent += "==================\n"
            
            let avgHeartRate = data.healthDataEntries.map(\.restingHeartRate).reduce(0, +) / Double(data.healthDataEntries.count)
            let avgHRV = data.healthDataEntries.map(\.hrv).reduce(0, +) / Double(data.healthDataEntries.count)
            let avgStress = data.healthDataEntries.map(\.stressLevel).reduce(0, +) / Double(data.healthDataEntries.count)
            
            pdfContent += "Average Resting Heart Rate: \(String(format: "%.1f", avgHeartRate)) BPM\n"
            pdfContent += "Average HRV: \(String(format: "%.1f", avgHRV)) ms\n"
            pdfContent += "Average Stress Level: \(String(format: "%.1f", avgStress))\n\n"
        }
        
        if !data.sleepSessions.isEmpty {
            pdfContent += "SLEEP ANALYSIS\n"
            pdfContent += "==============\n"
            
            let avgSleepDuration = data.sleepSessions.map(\.duration).reduce(0, +) / Double(data.sleepSessions.count)
            let avgSleepQuality = data.sleepSessions.map(\.qualityScore).reduce(0, +) / Double(data.sleepSessions.count)
            
            pdfContent += "Average Sleep Duration: \(String(format: "%.1f", avgSleepDuration / 3600)) hours\n"
            pdfContent += "Average Sleep Quality: \(String(format: "%.2f", avgSleepQuality))\n\n"
        }
        
        if !data.analyticsInsights.isEmpty {
            pdfContent += "KEY INSIGHTS\n"
            pdfContent += "============\n"
            
            let highConfidenceInsights = data.analyticsInsights.filter { $0.confidence > 0.8 }
            for insight in highConfidenceInsights.prefix(5) {
                pdfContent += "• \(insight.title) (Confidence: \(String(format: "%.0f", insight.confidence * 100))%)\n"
                pdfContent += "  \(insight.description)\n\n"
            }
        }
        
        // For a real PDF, you would use PDFKit or Core Graphics
        // This is a simplified text representation
        try pdfContent.write(to: url, atomically: true, encoding: .utf8)
        
        return url
    }
    
    private func getExportURL(filename: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("HealthAI_Exports")
        
        try? FileManager.default.createDirectory(at: exportsPath, withIntermediateDirectories: true)
        
        return exportsPath.appendingPathComponent(filename)
    }
}

// MARK: - Supporting Types

public enum DataExportStatus: String, CaseIterable {
    case idle = "Idle"
    case exporting = "Exporting"
    case completed = "Completed"
    case error = "Error"
}

public enum ExportError: LocalizedError {
    case exportInProgress
    case dataContextUnavailable
    case invalidExportType
    case fileCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .exportInProgress:
            return "Export already in progress"
        case .dataContextUnavailable:
            return "Data context unavailable"
        case .invalidExportType:
            return "Invalid export type"
        case .fileCreationFailed:
            return "Failed to create export file"
        }
    }
}

public struct ExportDataSet {
    var healthDataEntries: [SyncableHealthDataEntry] = []
    var sleepSessions: [SyncableSleepSessionEntry] = []
    var analyticsInsights: [AnalyticsInsight] = []
    var modelUpdates: [MLModelUpdate] = []
}

public struct CompletedExport: Identifiable {
    public let id: UUID
    public let type: ExportType
    public let dateRange: DateInterval
    public let fileURL: URL
    public let createdDate: Date
    public let fileSize: Int64
}

// MARK: - Date Formatter Extensions

private extension DateFormatter {
    static let hl7: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()
    
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}