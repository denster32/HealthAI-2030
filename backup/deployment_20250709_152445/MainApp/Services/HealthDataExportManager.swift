import Foundation
import HealthKit
import Combine
import BackgroundTasks

@available(iOS 14.0, *)
class HealthDataExportManager: ObservableObject {
    static let shared = HealthDataExportManager()
    
    // MARK: - Published Properties
    @Published var currentExport: ExportProgress?
    @Published var exportHistory: [ExportResult] = []
    @Published var isExporting = false
    @Published var lastError: ExportError?
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private let fileManager = FileManager.default
    private let operationQueue = OperationQueue()
    private let backgroundQueue = DispatchQueue(label: "com.healthai2030.export", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    // Export handlers
    private lazy var jsonHandler = JSONExportHandler()
    private lazy var csvHandler = CSVExportHandler()
    private lazy var pdfHandler = PDFExportHandler()
    private lazy var appleHealthHandler = AppleHealthExportHandler()
    
    // Security managers
    private let encryptionManager = ExportEncryptionManager.shared
    private let privacyManager = ExportPrivacyManager.shared
    private let storageManager = SecureExportStorage.shared
    
    // MARK: - Initialization
    private init() {
        setupOperationQueue()
        loadExportHistory()
        registerBackgroundTasks()
    }
    
    private func setupOperationQueue() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated
    }
    
    private func loadExportHistory() {
        // Load export history from secure storage
        Task {
            let history = await storageManager.loadExportHistory()
            DispatchQueue.main.async {
                self.exportHistory = history
            }
        }
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.healthai2030.export",
            using: nil
        ) { task in
            self.handleBackgroundExport(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Public Export Methods
    
    /// Start a health data export with the specified request
    func startExport(_ request: ExportRequest) async throws -> String {
        guard !isExporting else {
            throw ExportError.exportInProgress
        }
        
        // Validate request
        try validateExportRequest(request)
        
        // Create export progress
        let exportId = UUID().uuidString
        let progress = ExportProgress(
            id: exportId,
            request: request,
            status: .preparing,
            startTime: Date(),
            progress: 0.0,
            estimatedTimeRemaining: nil
        )
        
        DispatchQueue.main.async {
            self.currentExport = progress
            self.isExporting = true
            self.lastError = nil
        }
        
        // Start export task
        currentTask = Task {
            await performExport(exportId: exportId, request: request)
        }
        
        return exportId
    }
    
    /// Cancel the current export operation
    func cancelExport() {
        currentTask?.cancel()
        
        DispatchQueue.main.async {
            if let currentExport = self.currentExport {
                var cancelledExport = currentExport
                cancelledExport.status = .cancelled
                cancelledExport.endTime = Date()
                
                let result = ExportResult(
                    id: cancelledExport.id,
                    request: cancelledExport.request,
                    status: .cancelled,
                    startTime: cancelledExport.startTime,
                    endTime: Date(),
                    filePath: nil,
                    fileSize: 0,
                    recordCount: 0,
                    error: nil
                )
                
                self.exportHistory.insert(result, at: 0)
                self.currentExport = nil
                self.isExporting = false
            }
        }
        
        // Clean up any temporary files
        Task {
            await storageManager.cleanupTemporaryFiles()
        }
    }
    
    /// Get export status by ID
    func getExportStatus(id: String) -> ExportResult? {
        return exportHistory.first { $0.id == id }
    }
    
    /// Delete an export file and its record
    func deleteExport(id: String) async throws {
        guard let exportResult = exportHistory.first(where: { $0.id == id }) else {
            throw ExportError.exportNotFound
        }
        
        // Delete file if it exists
        if let filePath = exportResult.filePath {
            try await storageManager.deleteFile(at: filePath)
        }
        
        // Remove from history
        DispatchQueue.main.async {
            self.exportHistory.removeAll { $0.id == id }
        }
        
        // Save updated history
        await storageManager.saveExportHistory(exportHistory)
    }
    
    /// Estimate export size and duration
    func estimateExport(_ request: ExportRequest) async -> ExportEstimate {
        let dataCount = await getHealthDataCount(for: request)
        let estimatedSize = calculateEstimatedSize(dataCount: dataCount, format: request.format)
        let estimatedDuration = calculateEstimatedDuration(dataCount: dataCount, format: request.format)
        
        return ExportEstimate(
            recordCount: dataCount,
            estimatedFileSize: estimatedSize,
            estimatedDuration: estimatedDuration
        )
    }
    
    // MARK: - Private Export Implementation
    
    private func performExport(exportId: String, request: ExportRequest) async {
        do {
            // Update status to in progress
            await updateExportProgress(exportId: exportId) { progress in
                progress.status = .inProgress
                progress.progress = 0.0
            }
            
            // Get health data
            let healthData = try await fetchHealthData(for: request) { progressValue in
                Task { @MainActor in
                    await self.updateExportProgress(exportId: exportId) { progress in
                        progress.progress = progressValue * 0.5 // First 50% for data fetching
                        progress.estimatedTimeRemaining = self.calculateTimeRemaining(progress: progressValue * 0.5)
                    }
                }
            }
            
            // Process data with appropriate handler
            let processedData = try await processHealthData(healthData, for: request) { progressValue in
                Task { @MainActor in
                    await self.updateExportProgress(exportId: exportId) { progress in
                        progress.progress = 0.5 + (progressValue * 0.3) // Next 30% for processing
                        progress.estimatedTimeRemaining = self.calculateTimeRemaining(progress: progress.progress)
                    }
                }
            }
            
            // Generate export file
            let filePath = try await generateExportFile(processedData, for: request) { progressValue in
                Task { @MainActor in
                    await self.updateExportProgress(exportId: exportId) { progress in
                        progress.progress = 0.8 + (progressValue * 0.2) // Final 20% for file generation
                        progress.estimatedTimeRemaining = self.calculateTimeRemaining(progress: progress.progress)
                    }
                }
            }
            
            // Complete export
            await completeExport(exportId: exportId, filePath: filePath, recordCount: healthData.count)
            
        } catch {
            await failExport(exportId: exportId, error: error)
        }
    }
    
    private func fetchHealthData(for request: ExportRequest, progressCallback: @escaping (Double) -> Void) async throws -> [HealthDataPoint] {
        var allData: [HealthDataPoint] = []
        let dataTypes = request.dataTypes.isEmpty ? HealthDataType.allCases : request.dataTypes
        
        for (index, dataType) in dataTypes.enumerated() {
            let typeData = try await fetchHealthDataForType(dataType, dateRange: request.dateRange)
            allData.append(contentsOf: typeData)
            
            let progress = Double(index + 1) / Double(dataTypes.count)
            progressCallback(progress)
        }
        
        // Apply privacy filters if enabled
        if request.privacySettings.anonymizeData {
            allData = privacyManager.anonymizeHealthData(allData)
        }
        
        if request.privacySettings.excludeSensitiveData {
            allData = privacyManager.filterSensitiveData(allData)
        }
        
        return allData
    }
    
    private func fetchHealthDataForType(_ dataType: HealthDataType, dateRange: DateRange) async throws -> [HealthDataPoint] {
        return try await withCheckedThrowingContinuation { continuation in
            let sampleType = dataType.hkSampleType
            let predicate = HKQuery.predicateForSamples(
                withStart: dateRange.startDate,
                end: dateRange.endDate,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: ExportError.healthKitError(error))
                    return
                }
                
                let dataPoints = samples?.compactMap { sample in
                    HealthDataPoint.fromHKSample(sample, dataType: dataType)
                } ?? []
                
                continuation.resume(returning: dataPoints)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func processHealthData(_ data: [HealthDataPoint], for request: ExportRequest, progressCallback: @escaping (Double) -> Void) async throws -> ProcessedHealthData {
        let processor = HealthDataProcessor()
        
        return try await processor.process(
            data: data,
            request: request,
            progressCallback: progressCallback
        )
    }
    
    private func generateExportFile(_ data: ProcessedHealthData, for request: ExportRequest, progressCallback: @escaping (Double) -> Void) async throws -> URL {
        let handler = getExportHandler(for: request.format)
        
        let tempDirectory = await storageManager.createTemporaryDirectory()
        let fileName = generateFileName(for: request)
        let filePath = tempDirectory.appendingPathComponent(fileName)
        
        try await handler.generateExport(
            data: data,
            request: request,
            outputPath: filePath,
            progressCallback: progressCallback
        )
        
        // Encrypt file if required
        if request.encryptionSettings.encryptFile {
            let encryptedPath = try await encryptionManager.encryptFile(
                at: filePath,
                password: request.encryptionSettings.password
            )
            
            // Delete unencrypted file
            try fileManager.removeItem(at: filePath)
            
            return encryptedPath
        }
        
        return filePath
    }
    
    private func getExportHandler(for format: ExportFormat) -> ExportHandler {
        switch format {
        case .json:
            return jsonHandler
        case .csv:
            return csvHandler
        case .pdf:
            return pdfHandler
        case .appleHealth:
            return appleHealthHandler
        }
    }
    
    private func generateFileName(for request: ExportRequest) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startDate = dateFormatter.string(from: request.dateRange.startDate)
        let endDate = dateFormatter.string(from: request.dateRange.endDate)
        let timestamp = DateFormatter.timestamp.string(from: Date())
        
        var fileName = "HealthAI_Export_\(startDate)_to_\(endDate)_\(timestamp)"
        
        if request.encryptionSettings.encryptFile {
            fileName += "_encrypted"
        }
        
        fileName += ".\(request.format.fileExtension)"
        
        return fileName
    }
    
    // MARK: - Progress Management
    
    @MainActor
    private func updateExportProgress(exportId: String, update: (inout ExportProgress) -> Void) {
        guard var progress = currentExport, progress.id == exportId else { return }
        
        update(&progress)
        currentExport = progress
    }
    
    private func calculateTimeRemaining(progress: Double) -> TimeInterval? {
        guard let currentExport = currentExport, progress > 0 else { return nil }
        
        let elapsed = Date().timeIntervalSince(currentExport.startTime)
        let totalEstimated = elapsed / progress
        let remaining = totalEstimated - elapsed
        
        return max(0, remaining)
    }
    
    private func completeExport(exportId: String, filePath: URL, recordCount: Int) async {
        let fileSize = (try? fileManager.attributesOfItem(atPath: filePath.path)[.size] as? Int64) ?? 0
        
        DispatchQueue.main.async {
            guard let currentExport = self.currentExport else { return }
            
            let result = ExportResult(
                id: exportId,
                request: currentExport.request,
                status: .completed,
                startTime: currentExport.startTime,
                endTime: Date(),
                filePath: filePath,
                fileSize: fileSize,
                recordCount: recordCount,
                error: nil
            )
            
            self.exportHistory.insert(result, at: 0)
            self.currentExport = nil
            self.isExporting = false
        }
        
        // Save to secure storage
        await storageManager.saveExportHistory(exportHistory)
        
        // Send notification
        await sendExportCompletionNotification(exportId: exportId)
    }
    
    private func failExport(exportId: String, error: Error) async {
        DispatchQueue.main.async {
            guard let currentExport = self.currentExport else { return }
            
            let exportError = error as? ExportError ?? ExportError.unknown(error)
            
            let result = ExportResult(
                id: exportId,
                request: currentExport.request,
                status: .failed,
                startTime: currentExport.startTime,
                endTime: Date(),
                filePath: nil,
                fileSize: 0,
                recordCount: 0,
                error: exportError
            )
            
            self.exportHistory.insert(result, at: 0)
            self.currentExport = nil
            self.isExporting = false
            self.lastError = exportError
        }
        
        // Clean up temporary files
        await storageManager.cleanupTemporaryFiles()
        
        // Save to secure storage
        await storageManager.saveExportHistory(exportHistory)
    }
    
    // MARK: - Background Export Support
    
    private func handleBackgroundExport(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Check if there's a pending export
        if let pendingExport = getPendingBackgroundExport() {
            Task {
                await performExport(exportId: pendingExport.id, request: pendingExport.request)
                task.setTaskCompleted(success: true)
            }
        } else {
            task.setTaskCompleted(success: true)
        }
    }
    
    private func getPendingBackgroundExport() -> ExportProgress? {
        // Check for exports that were interrupted and need background processing
        return exportHistory.first { $0.status == .inProgress }?.toExportProgress()
    }
    
    func scheduleBackgroundExport() {
        let request = BGProcessingTaskRequest(identifier: "com.healthai2030.export")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    // MARK: - Utility Methods
    
    private func validateExportRequest(_ request: ExportRequest) throws {
        guard request.dateRange.startDate <= request.dateRange.endDate else {
            throw ExportError.invalidDateRange
        }
        
        guard request.dateRange.endDate <= Date() else {
            throw ExportError.futureDateNotAllowed
        }
        
        let daysBetween = Calendar.current.dateComponents([.day], from: request.dateRange.startDate, to: request.dateRange.endDate).day ?? 0
        guard daysBetween <= 3650 else { // 10 years max
            throw ExportError.dateRangeTooLarge
        }
        
        if request.encryptionSettings.encryptFile && request.encryptionSettings.password.isEmpty {
            throw ExportError.encryptionPasswordRequired
        }
    }
    
    private func getHealthDataCount(for request: ExportRequest) async -> Int {
        // Estimate based on data types and date range
        let dataTypes = request.dataTypes.isEmpty ? HealthDataType.allCases : request.dataTypes
        let daysBetween = Calendar.current.dateComponents([.day], from: request.dateRange.startDate, to: request.dateRange.endDate).day ?? 0
        
        // Rough estimation: average 50 data points per type per day
        return dataTypes.count * daysBetween * 50
    }
    
    private func calculateEstimatedSize(dataCount: Int, format: ExportFormat) -> Int64 {
        let bytesPerRecord: Int64
        
        switch format {
        case .json:
            bytesPerRecord = 200 // JSON is verbose
        case .csv:
            bytesPerRecord = 100 // CSV is compact
        case .pdf:
            bytesPerRecord = 50 // PDF with compression
        case .appleHealth:
            bytesPerRecord = 150 // XML format
        }
        
        return Int64(dataCount) * bytesPerRecord
    }
    
    private func calculateEstimatedDuration(dataCount: Int, format: ExportFormat) -> TimeInterval {
        let recordsPerSecond: Double
        
        switch format {
        case .json:
            recordsPerSecond = 1000
        case .csv:
            recordsPerSecond = 2000
        case .pdf:
            recordsPerSecond = 500 // PDF generation is slower
        case .appleHealth:
            recordsPerSecond = 800
        }
        
        return Double(dataCount) / recordsPerSecond
    }
    
    private func sendExportCompletionNotification(exportId: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Health Data Export Complete"
        content.body = "Your health data export has finished successfully."
        content.sound = .default
        content.userInfo = ["exportId": exportId]
        
        let request = UNNotificationRequest(
            identifier: "export_complete_\(exportId)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmss"
        return formatter
    }()
}

extension ExportResult {
    func toExportProgress() -> ExportProgress {
        return ExportProgress(
            id: id,
            request: request,
            status: status == .completed ? .completed : .inProgress,
            startTime: startTime,
            progress: status == .completed ? 1.0 : 0.0,
            estimatedTimeRemaining: nil
        )
    }
}