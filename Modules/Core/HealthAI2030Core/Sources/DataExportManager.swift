import Foundation
import CoreData
import CloudKit
import UniformTypeIdentifiers

class DataExportManager: ObservableObject {
    static let shared = DataExportManager()
    
    // MARK: - Properties
    @Published var exportStatus: ExportStatus = .idle
    @Published var exportProgress: Double = 0.0
    @Published var exportHistory: [ExportRecord] = []
    @Published var availableDataTypes: [DataType] = []
    @Published var isExporting = false
    
    // Export configuration
    private var exportQueue = DispatchQueue(label: "com.healthai2030.export", qos: .userInitiated)
    private var exportConfiguration: ExportConfiguration?
    
    // Data sources
    private let coreDataManager = CoreDataManager.shared
    private let cloudKitContainer = CKContainer.default()
    private let privateDatabase: CKDatabase
    
    // MARK: - Initialization
    
    private init() {
        self.privateDatabase = cloudKitContainer.privateCloudDatabase
        setupDataTypes()
        loadExportHistory()
    }
    
    func initialize() {
        print("DataExportManager initializing...")
        
        // Setup export capabilities
        setupExportCapabilities()
        
        // Load available data
        loadAvailableData()
        
        // Setup export monitoring
        setupExportMonitoring()
        
        print("DataExportManager initialized successfully")
    }
    
    // MARK: - Setup
    
    private func setupDataTypes() {
        availableDataTypes = [
            DataType(
                id: "health_metrics",
                name: "Health Metrics",
                description: "Heart rate, HRV, blood pressure, oxygen saturation",
                category: .health,
                estimatedSize: "2.5 MB",
                lastUpdated: Date()
            ),
            DataType(
                id: "sleep_data",
                name: "Sleep Data",
                description: "Sleep stages, duration, quality, sleep cycles",
                category: .sleep,
                estimatedSize: "1.8 MB",
                lastUpdated: Date()
            ),
            DataType(
                id: "activity_data",
                name: "Activity Data",
                description: "Steps, calories, exercise, movement patterns",
                category: .activity,
                estimatedSize: "3.2 MB",
                lastUpdated: Date()
            ),
            DataType(
                id: "environment_data",
                name: "Environment Data",
                description: "Temperature, humidity, light levels, air quality",
                category: .environment,
                estimatedSize: "1.1 MB",
                lastUpdated: Date()
            ),
            DataType(
                id: "analytics_results",
                name: "Analytics Results",
                description: "ML insights, predictions, trend analysis",
                category: .analytics,
                estimatedSize: "4.7 MB",
                lastUpdated: Date()
            ),
            DataType(
                id: "research_data",
                name: "Research Data",
                description: "Study participation, survey responses, research metrics",
                category: .research,
                estimatedSize: "2.3 MB",
                lastUpdated: Date()
            )
        ]
    }
    
    private func setupExportCapabilities() {
        // Register supported file types
        registerFileTypes()
        
        // Setup export templates
        setupExportTemplates()
    }
    
    private func registerFileTypes() {
        // Register supported export formats
        let supportedFormats: [ExportFormat] = [.csv, .json, .sql, .xml, .pdf]
        
        for format in supportedFormats {
            registerFormat(format)
        }
    }
    
    private func registerFormat(_ format: ExportFormat) {
        // Register file type with system
        switch format {
        case .csv:
            UTType.exportedTypeDeclarations.append(UTType(filenameExtension: "csv")!)
        case .json:
            UTType.exportedTypeDeclarations.append(UTType(filenameExtension: "json")!)
        case .sql:
            UTType.exportedTypeDeclarations.append(UTType(filenameExtension: "sql")!)
        case .xml:
            UTType.exportedTypeDeclarations.append(UTType(filenameExtension: "xml")!)
        case .pdf:
            UTType.exportedTypeDeclarations.append(UTType(filenameExtension: "pdf")!)
        }
    }
    
    private func setupExportTemplates() {
        // Create export templates for different use cases
        let templates = [
            ExportTemplate(
                id: "health_summary",
                name: "Health Summary Report",
                description: "Comprehensive health data summary",
                dataTypes: ["health_metrics", "sleep_data", "activity_data"],
                format: .pdf,
                includeCharts: true,
                includeInsights: true
            ),
            ExportTemplate(
                id: "research_export",
                name: "Research Data Export",
                description: "Data export for research purposes",
                dataTypes: ["research_data", "analytics_results"],
                format: .csv,
                includeCharts: false,
                includeInsights: false
            ),
            ExportTemplate(
                id: "data_science",
                name: "Data Science Export",
                description: "Export for data science analysis",
                dataTypes: ["health_metrics", "sleep_data", "activity_data", "analytics_results"],
                format: .json,
                includeCharts: false,
                includeInsights: false
            ),
            ExportTemplate(
                id: "database_import",
                name: "Database Import",
                description: "SQL export for database import",
                dataTypes: ["health_metrics", "sleep_data", "activity_data", "environment_data"],
                format: .sql,
                includeCharts: false,
                includeInsights: false
            )
        ]
        
        // Store templates
        UserDefaults.standard.set(try? JSONEncoder().encode(templates), forKey: "ExportTemplates")
    }
    
    private func loadAvailableData() {
        // Load available data from various sources
        loadCoreData()
        loadCloudKitData()
        loadAnalyticsData()
    }
    
    private func loadCoreData() {
        // Load data from Core Data
        let context = coreDataManager.persistentContainer.viewContext
        
        // Load health metrics
        let healthMetricsRequest: NSFetchRequest<HealthMetric> = HealthMetric.fetchRequest()
        if let healthMetrics = try? context.fetch(healthMetricsRequest) {
            print("Loaded \(healthMetrics.count) health metrics from Core Data")
        }
        
        // Load sleep data
        let sleepDataRequest: NSFetchRequest<SleepData> = SleepData.fetchRequest()
        if let sleepData = try? context.fetch(sleepDataRequest) {
            print("Loaded \(sleepData.count) sleep records from Core Data")
        }
        
        // Load activity data
        let activityDataRequest: NSFetchRequest<ActivityData> = ActivityData.fetchRequest()
        if let activityData = try? context.fetch(activityDataRequest) {
            print("Loaded \(activityData.count) activity records from Core Data")
        }
    }
    
    private func loadCloudKitData() {
        // Load data from CloudKit
        let query = CKQuery(recordType: "HealthData", predicate: NSPredicate(value: true))
        
        let operation = CKQueryOperation(query: query)
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                print("Loaded CloudKit record: \(record.recordType)")
            case .failure(let error):
                print("CloudKit load error: \(error)")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    private func loadAnalyticsData() {
        // Load analytics data from MacAnalyticsEngine
        let analyticsEngine = MacAnalyticsEngine.shared
        let results = analyticsEngine.getAnalysisResults()
        print("Loaded \(results.count) analytics results")
    }
    
    private func setupExportMonitoring() {
        // Monitor export progress and status
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateExportProgress()
        }
    }
    
    // MARK: - Export Operations
    
    func exportData(configuration: ExportConfiguration) {
        guard !isExporting else {
            print("Export already in progress")
            return
        }
        
        isExporting = true
        exportStatus = .preparing
        exportProgress = 0.0
        exportConfiguration = configuration
        
        exportQueue.async { [weak self] in
            self?.performExport(configuration: configuration)
        }
    }
    
    private func performExport(configuration: ExportConfiguration) {
        DispatchQueue.main.async {
            self.exportStatus = .exporting
        }
        
        // Step 1: Prepare data
        DispatchQueue.main.async {
            self.exportProgress = 0.1
        }
        
        let data = prepareDataForExport(configuration: configuration)
        
        // Step 2: Format data
        DispatchQueue.main.async {
            self.exportProgress = 0.3
        }
        
        let formattedData = formatData(data: data, format: configuration.format)
        
        // Step 3: Generate file
        DispatchQueue.main.async {
            self.exportProgress = 0.6
        }
        
        let fileURL = generateExportFile(data: formattedData, configuration: configuration)
        
        // Step 4: Finalize export
        DispatchQueue.main.async {
            self.exportProgress = 0.9
        }
        
        finalizeExport(fileURL: fileURL, configuration: configuration)
        
        DispatchQueue.main.async {
            self.exportProgress = 1.0
            self.exportStatus = .completed
            self.isExporting = false
        }
    }
    
    private func prepareDataForExport(configuration: ExportConfiguration) -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        for dataType in configuration.dataTypes {
            switch dataType {
            case "health_metrics":
                exportData["health_metrics"] = prepareHealthMetricsData()
            case "sleep_data":
                exportData["sleep_data"] = prepareSleepData()
            case "activity_data":
                exportData["activity_data"] = prepareActivityData()
            case "environment_data":
                exportData["environment_data"] = prepareEnvironmentData()
            case "analytics_results":
                exportData["analytics_results"] = prepareAnalyticsData()
            case "research_data":
                exportData["research_data"] = prepareResearchData()
            default:
                break
            }
        }
        
        return exportData
    }
    
    private func prepareHealthMetricsData() -> [[String: Any]] {
        let context = coreDataManager.persistentContainer.viewContext
        let request: NSFetchRequest<HealthMetric> = HealthMetric.fetchRequest()
        
        guard let metrics = try? context.fetch(request) else { return [] }
        
        return metrics.map { metric in
            [
                "timestamp": metric.timestamp ?? Date(),
                "heartRate": metric.heartRate,
                "hrv": metric.hrv,
                "bloodPressure": metric.bloodPressure ?? "",
                "oxygenSaturation": metric.oxygenSaturation
            ]
        }
    }
    
    private func prepareSleepData() -> [[String: Any]] {
        let context = coreDataManager.persistentContainer.viewContext
        let request: NSFetchRequest<SleepData> = SleepData.fetchRequest()
        
        guard let sleepData = try? context.fetch(request) else { return [] }
        
        return sleepData.map { sleep in
            [
                "startTime": sleep.startTime ?? Date(),
                "endTime": sleep.endTime ?? Date(),
                "duration": sleep.duration,
                "quality": sleep.quality,
                "deepSleep": sleep.deepSleep,
                "remSleep": sleep.remSleep,
                "lightSleep": sleep.lightSleep
            ]
        }
    }
    
    private func prepareActivityData() -> [[String: Any]] {
        let context = coreDataManager.persistentContainer.viewContext
        let request: NSFetchRequest<ActivityData> = ActivityData.fetchRequest()
        
        guard let activityData = try? context.fetch(request) else { return [] }
        
        return activityData.map { activity in
            [
                "timestamp": activity.timestamp ?? Date(),
                "steps": activity.steps,
                "calories": activity.calories,
                "distance": activity.distance,
                "activeMinutes": activity.activeMinutes
            ]
        }
    }
    
    private func prepareEnvironmentData() -> [[String: Any]] {
        // Prepare environment data from EnvironmentManager
        let environmentManager = EnvironmentManager.shared
        
        return [
            [
                "timestamp": Date(),
                "temperature": environmentManager.currentTemperature,
                "humidity": environmentManager.currentHumidity,
                "lightLevel": environmentManager.currentLightLevel,
                "airQuality": environmentManager.airQualityStatus
            ]
        ]
    }
    
    private func prepareAnalyticsData() -> [[String: Any]] {
        // Prepare analytics data from MacAnalyticsEngine
        let analyticsEngine = MacAnalyticsEngine.shared
        let results = analyticsEngine.getAnalysisResults()
        
        return results.map { result in
            [
                "type": result.type.rawValue,
                "title": result.title,
                "description": result.description,
                "confidence": result.confidence,
                "timestamp": result.timestamp
            ]
        }
    }
    
    private func prepareResearchData() -> [[String: Any]] {
        // Prepare research data from ResearchKitManager
        let researchKitManager = ResearchKitManager.shared
        
        return [
            [
                "activeStudies": researchKitManager.activeStudies.count,
                "completedStudies": researchKitManager.completedStudies.count,
                "dataCollectionProgress": researchKitManager.dataCollectionProgress
            ]
        ]
    }
    
    private func formatData(data: [String: Any], format: ExportFormat) -> Data? {
        switch format {
        case .csv:
            return formatAsCSV(data: data)
        case .json:
            return formatAsJSON(data: data)
        case .sql:
            return formatAsSQL(data: data)
        case .xml:
            return formatAsXML(data: data)
        case .pdf:
            return formatAsPDF(data: data)
        }
    }
    
    private func formatAsCSV(data: [String: Any]) -> Data? {
        var csvString = ""
        
        for (dataType, records) in data {
            csvString += "=== \(dataType.uppercased()) ===\n"
            
            if let records = records as? [[String: Any]], !records.isEmpty {
                // Write headers
                let headers = Array(records[0].keys)
                csvString += headers.joined(separator: ",") + "\n"
                
                // Write data
                for record in records {
                    let values = headers.map { header in
                        String(describing: record[header] ?? "")
                    }
                    csvString += values.joined(separator: ",") + "\n"
                }
            }
            
            csvString += "\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    private func formatAsJSON(data: [String: Any]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(data)
    }
    
    private func formatAsSQL(data: [String: Any]) -> Data? {
        var sqlString = ""
        
        for (dataType, records) in data {
            let tableName = dataType.replacingOccurrences(of: "_", with: "")
            
            sqlString += "CREATE TABLE IF NOT EXISTS \(tableName) (\n"
            sqlString += "  id INTEGER PRIMARY KEY AUTOINCREMENT,\n"
            
            if let records = records as? [[String: Any]], !records.isEmpty {
                let firstRecord = records[0]
                for (key, value) in firstRecord {
                    let columnType = getSQLType(for: value)
                    sqlString += "  \(key) \(columnType),\n"
                }
            }
            
            sqlString = String(sqlString.dropLast(2)) // Remove last comma and newline
            sqlString += "\n);\n\n"
            
            // Insert data
            if let records = records as? [[String: Any]] {
                for record in records {
                    sqlString += "INSERT INTO \(tableName) ("
                    sqlString += record.keys.joined(separator: ", ")
                    sqlString += ") VALUES ("
                    
                    let values = record.values.map { value in
                        formatSQLValue(value)
                    }
                    sqlString += values.joined(separator: ", ")
                    sqlString += ");\n"
                }
            }
            
            sqlString += "\n"
        }
        
        return sqlString.data(using: .utf8)
    }
    
    private func getSQLType(for value: Any) -> String {
        switch value {
        case is Int, is Int32, is Int64:
            return "INTEGER"
        case is Double, is Float:
            return "REAL"
        case is String:
            return "TEXT"
        case is Date:
            return "DATETIME"
        case is Bool:
            return "BOOLEAN"
        default:
            return "TEXT"
        }
    }
    
    private func formatSQLValue(_ value: Any) -> String {
        switch value {
        case let string as String:
            return "'\(string.replacingOccurrences(of: "'", with: "''"))'"
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return "'\(formatter.string(from: date))'"
        case let bool as Bool:
            return bool ? "1" : "0"
        default:
            return String(describing: value)
        }
    }
    
    private func formatAsXML(data: [String: Any]) -> Data? {
        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlString += "<healthData>\n"
        
        for (dataType, records) in data {
            xmlString += "  <\(dataType)>\n"
            
            if let records = records as? [[String: Any]] {
                for record in records {
                    xmlString += "    <record>\n"
                    for (key, value) in record {
                        xmlString += "      <\(key)>\(value)</\(key)>\n"
                    }
                    xmlString += "    </record>\n"
                }
            }
            
            xmlString += "  </\(dataType)>\n"
        }
        
        xmlString += "</healthData>"
        
        return xmlString.data(using: .utf8)
    }
    
    private func formatAsPDF(data: [String: Any]) -> Data? {
        // Generate PDF report
        let pdfGenerator = PDFGenerator()
        return pdfGenerator.generateReport(data: data)
    }
    
    private func generateExportFile(data: Data?, configuration: ExportConfiguration) -> URL? {
        guard let data = data else { return nil }
        
        let fileName = "HealthAI2030_Export_\(Date().timeIntervalSince1970).\(configuration.format.fileExtension)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing export file: \(error)")
            return nil
        }
    }
    
    private func finalizeExport(fileURL: URL?, configuration: ExportConfiguration) {
        guard let fileURL = fileURL else { return }
        
        // Create export record
        let exportRecord = ExportRecord(
            id: UUID(),
            fileName: fileURL.lastPathComponent,
            fileSize: getFileSize(fileURL: fileURL),
            format: configuration.format,
            dataTypes: configuration.dataTypes,
            timestamp: Date(),
            status: .completed
        )
        
        // Add to history
        exportHistory.append(exportRecord)
        saveExportHistory()
        
        // Sync to iCloud
        syncExportRecord(exportRecord)
        
        print("Export completed: \(fileURL.lastPathComponent)")
    }
    
    private func getFileSize(fileURL: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        } catch {
            return "Unknown"
        }
    }
    
    // MARK: - Export History
    
    private func loadExportHistory() {
        if let data = UserDefaults.standard.data(forKey: "ExportHistory"),
           let history = try? JSONDecoder().decode([ExportRecord].self, from: data) {
            exportHistory = history
        }
    }
    
    private func saveExportHistory() {
        if let data = try? JSONEncoder().encode(exportHistory) {
            UserDefaults.standard.set(data, forKey: "ExportHistory")
        }
    }
    
    private func syncExportRecord(_ record: ExportRecord) {
        let exportRecord = CKRecord(recordType: "ExportRecord")
        exportRecord["id"] = record.id.uuidString
        exportRecord["fileName"] = record.fileName
        exportRecord["fileSize"] = record.fileSize
        exportRecord["format"] = record.format.rawValue
        exportRecord["dataTypes"] = record.dataTypes
        exportRecord["timestamp"] = record.timestamp
        exportRecord["status"] = record.status.rawValue
        
        let operation = CKModifyRecordsOperation(recordsToSave: [exportRecord], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if let error = error {
                print("Export record sync error: \(error)")
            } else {
                print("Export record synced to iCloud")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    // MARK: - Utility Methods
    
    private func updateExportProgress() {
        // Update export progress based on current status
        if isExporting && exportProgress < 1.0 {
            exportProgress += 0.01
        }
    }
    
    func getExportTemplates() -> [ExportTemplate] {
        if let data = UserDefaults.standard.data(forKey: "ExportTemplates"),
           let templates = try? JSONDecoder().decode([ExportTemplate].self, from: data) {
            return templates
        }
        return []
    }
    
    func deleteExportRecord(_ record: ExportRecord) {
        exportHistory.removeAll { $0.id == record.id }
        saveExportHistory()
    }
}

// MARK: - Supporting Types

enum ExportStatus: String, CaseIterable {
    case idle = "Idle"
    case preparing = "Preparing"
    case exporting = "Exporting"
    case completed = "Completed"
    case error = "Error"
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .preparing: return .orange
        case .exporting: return .blue
        case .completed: return .green
        case .error: return .red
        }
    }
}

struct DataType: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: DataCategory
    let estimatedSize: String
    let lastUpdated: Date
}

enum DataCategory: String, CaseIterable, Codable {
    case health = "Health"
    case sleep = "Sleep"
    case activity = "Activity"
    case environment = "Environment"
    case analytics = "Analytics"
    case research = "Research"
}

struct ExportConfiguration {
    let dataTypes: [String]
    let format: ExportFormat
    let timeRange: TimeRange
    let includeCharts: Bool
    let includeInsights: Bool
    let fileName: String?
}

struct ExportTemplate: Codable {
    let id: String
    let name: String
    let description: String
    let dataTypes: [String]
    let format: ExportFormat
    let includeCharts: Bool
    let includeInsights: Bool
}

struct ExportRecord: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let fileSize: String
    let format: ExportFormat
    let dataTypes: [String]
    let timestamp: Date
    let status: ExportStatus
}

enum TimeRange: String, CaseIterable {
    case day = "1 Day"
    case week = "1 Week"
    case month = "1 Month"
    case quarter = "3 Months"
    case year = "1 Year"
    case all = "All Time"
}

// MARK: - PDF Generator

class PDFGenerator {
    func generateReport(data: [String: Any]) -> Data? {
        // Generate PDF report with charts and insights
        // This would use PDFKit to create comprehensive reports
        return "PDF Report".data(using: .utf8)
    }
} 