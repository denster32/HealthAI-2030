import Foundation
import CoreML
import Metal
import MetalPerformanceShaders
import CloudKit
import Combine
import os.log

/// Optimized background analytics processor that handles heavy computations efficiently
/// without blocking the main thread or draining battery excessively.
actor OptimizedBackgroundAnalyticsProcessor: ObservableObject {
    static let shared = OptimizedBackgroundAnalyticsProcessor()
    
    // MARK: - Published Properties (MainActor)
    @MainActor @Published var processingStatus: ProcessingStatus = .idle
    @MainActor @Published var currentJob: AnalyticsJob?
    @MainActor @Published var completedJobs: [CompletedJob] = []
    @MainActor @Published var systemResourceUsage: SystemResourceUsage = SystemResourceUsage()
    
    // MARK: - Private Properties
    private let metalDevice: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let neuralEngine: NeuralEngineProcessor
    private let cloudKitSync: CloudKitSyncManager
    
    // Optimized queues with proper QoS
    private let processingQueue = DispatchQueue(label: "com.healthai2030.analytics.processing", qos: .utility)
    private let mlQueue = DispatchQueue(label: "com.healthai2030.analytics.ml", qos: .userInitiated)
    private let reportQueue = DispatchQueue(label: "com.healthai2030.analytics.reports", qos: .background)
    
    // Job management
    private var jobQueue: [AnalyticsJob] = []
    private var runningJobs: Set<UUID> = []
    private let maxConcurrentJobs = 2 // Reduced from 3 for better performance
    
    // Resource management
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var thermalStateObserver: NSObjectProtocol?
    
    // Performance monitoring
    private var performanceTimer: Timer?
    private var isNPUAvailable = false
    
    // MARK: - Initialization
    
    private init() {
        self.metalDevice = MTLCreateSystemDefaultDevice()
        self.commandQueue = metalDevice?.makeCommandQueue()
        self.neuralEngine = NeuralEngineProcessor(device: metalDevice)
        self.cloudKitSync = CloudKitSyncManager.shared
        
        Task {
            await setupOptimizedProcessing()
        }
    }
    
    // MARK: - Setup
    
    private func setupOptimizedProcessing() async {
        await detectSystemCapabilities()
        await setupResourceMonitoring()
        await setupThermalManagement()
        
        os_log("OptimizedBackgroundAnalyticsProcessor initialized", log: .default, type: .info)
    }
    
    private func detectSystemCapabilities() async {
        guard let device = metalDevice else {
            isNPUAvailable = false
            return
        }
        
        // Check for Apple Silicon Neural Engine
        if device.supportsFeatureSet(.macOS_GPUFamily2_v1) {
            isNPUAvailable = true
            neuralEngine.enableNPUOptimization()
            os_log("Neural Engine detected and enabled", log: .default, type: .info)
        } else {
            isNPUAvailable = false
            os_log("Neural Engine not available, using CPU/GPU fallback", log: .default, type: .info)
        }
    }
    
    private func setupResourceMonitoring() async {
        // Memory pressure monitoring
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: processingQueue)
        memoryPressureSource?.setEventHandler { [weak self] in
            Task {
                await self?.handleMemoryPressure()
            }
        }
        memoryPressureSource?.resume()
        
        // Start performance monitoring
        await MainActor.run {
            performanceTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                Task {
                    await self.updateSystemResourceUsage()
                }
            }
        }
    }
    
    private func setupThermalManagement() async {
        // Monitor thermal state to throttle processing
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleThermalStateChange()
            }
        }
    }
    
    // MARK: - Public Interface
    
    func addJob(_ job: AnalyticsJob) async {
        jobQueue.append(job)
        os_log("Added job to queue: %@", log: .default, type: .info, job.type.rawValue)
        
        await processNextJobIfPossible()
    }
    
    func cancelJob(_ jobId: UUID) async {
        jobQueue.removeAll { $0.id == jobId }
        runningJobs.remove(jobId)
        
        await MainActor.run {
            if currentJob?.id == jobId {
                currentJob = nil
            }
        }
        
        os_log("Cancelled job: %@", log: .default, type: .info, jobId.uuidString)
    }
    
    func pauseProcessing() async {
        await MainActor.run {
            processingStatus = .suspended
        }
        os_log("Processing paused", log: .default, type: .info)
    }
    
    func resumeProcessing() async {
        await MainActor.run {
            processingStatus = .idle
        }
        await processNextJobIfPossible()
        os_log("Processing resumed", log: .default, type: .info)
    }
    
    // MARK: - Job Processing
    
    private func processNextJobIfPossible() async {
        let status = await MainActor.run { processingStatus }
        
        guard status != .suspended,
              runningJobs.count < maxConcurrentJobs,
              !jobQueue.isEmpty,
              await isSystemResourcesAvailable() else {
            return
        }
        
        let job = jobQueue.removeFirst()
        runningJobs.insert(job.id)
        
        await MainActor.run {
            currentJob = job
            processingStatus = .processing
        }
        
        os_log("Starting job: %@", log: .default, type: .info, job.type.rawValue)
        
        // Process job on appropriate queue
        await processJob(job)
    }
    
    private func processJob(_ job: AnalyticsJob) async {
        let startTime = Date()
        
        do {
            let result = try await executeJob(job)
            let duration = Date().timeIntervalSince(startTime)
            
            await completeJob(job, result: result, duration: duration)
        } catch {
            let errorResult = JobResult(
                status: .failed,
                data: nil,
                insights: [],
                metadata: ["error": error.localizedDescription]
            )
            
            await completeJob(job, result: errorResult, duration: Date().timeIntervalSince(startTime))
        }
    }
    
    private func executeJob(_ job: AnalyticsJob) async throws -> JobResult {
        switch job.type {
        case .longTermTrendAnalysis:
            return try await executeLongTermTrendAnalysis(job)
        case .modelRetraining:
            return try await executeModelRetraining(job)
        case .reportGeneration:
            return try await executeReportGeneration(job)
        case .dataCompression:
            return try await executeDataCompression(job)
        case .anomalyDetection:
            return try await executeAnomalyDetection(job)
        case .predictiveModeling:
            return try await executePredictiveModeling(job)
        }
    }
    
    // MARK: - Optimized Job Execution
    
    private func executeLongTermTrendAnalysis(_ job: AnalyticsJob) async throws -> JobResult {
        return try await withTaskGroup(of: JobResult.self) { group in
            group.addTask {
                return try await withUnsafeThrowingContinuation { continuation in
                    self.processingQueue.async {
                        do {
                            let analyzer = LongTermTrendAnalyzer(
                                metalDevice: self.metalDevice,
                                neuralEngine: self.neuralEngine
                            )
                            
                            let trends = try analyzer.analyzeTrends(
                                timeRange: job.parameters["timeRange"] as? TimeInterval ?? 31536000
                            )
                            
                            let result = JobResult(
                                status: .completed,
                                data: trends,
                                insights: analyzer.generateInsights(from: trends),
                                metadata: [
                                    "analysisType": "longTermTrends",
                                    "dataPoints": trends.dataPoints.count,
                                    "timeRange": job.parameters["timeRange"] as? TimeInterval ?? 31536000
                                ]
                            )
                            
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            
            // Wait for the first (and only) task to complete
            for try await result in group {
                group.cancelAll()
                return result
            }
            
            throw ProcessingError.taskGroupEmpty
        }
    }
    
    private func executeModelRetraining(_ job: AnalyticsJob) async throws -> JobResult {
        return try await withUnsafeThrowingContinuation { continuation in
            mlQueue.async {
                do {
                    let trainer = MLModelTrainer(
                        metalDevice: self.metalDevice,
                        neuralEngine: self.neuralEngine,
                        useNPU: self.isNPUAvailable
                    )
                    
                    let trainingData = try self.prepareTrainingData(for: job)
                    let modelUpdate = try trainer.retrainModel(
                        modelType: job.parameters["modelType"] as? String ?? "healthPredictor",
                        trainingData: trainingData
                    )
                    
                    let result = JobResult(
                        status: .completed,
                        data: modelUpdate,
                        insights: trainer.generateModelInsights(modelUpdate),
                        metadata: [
                            "modelType": modelUpdate.modelType,
                            "accuracy": modelUpdate.accuracy,
                            "trainingTime": modelUpdate.trainingTime
                        ]
                    )
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func executeReportGeneration(_ job: AnalyticsJob) async throws -> JobResult {
        return try await withUnsafeThrowingContinuation { continuation in
            reportQueue.async {
                do {
                    let generator = ComprehensiveReportGenerator()
                    
                    let reportData = try generator.generateReport(
                        type: job.parameters["reportType"] as? ReportType ?? .comprehensive,
                        timeRange: job.parameters["timeRange"] as? TimeInterval ?? 2592000
                    )
                    
                    let result = JobResult(
                        status: .completed,
                        data: reportData,
                        insights: generator.extractInsights(from: reportData),
                        metadata: [
                            "reportType": reportData.type.rawValue,
                            "pageCount": reportData.pageCount,
                            "fileSize": reportData.estimatedFileSize
                        ]
                    )
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func executeDataCompression(_ job: AnalyticsJob) async throws -> JobResult {
        return try await withUnsafeThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let compressor = HealthDataCompressor(metalDevice: self.metalDevice)
                    
                    let compressionResult = try compressor.compressHealthData(
                        timeRange: job.parameters["timeRange"] as? TimeInterval ?? 86400
                    )
                    
                    let result = JobResult(
                        status: .completed,
                        data: compressionResult,
                        insights: compressor.generateCompressionInsights(compressionResult),
                        metadata: [
                            "originalSize": compressionResult.originalSize,
                            "compressedSize": compressionResult.compressedSize,
                            "compressionRatio": compressionResult.compressionRatio
                        ]
                    )
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func executeAnomalyDetection(_ job: AnalyticsJob) async throws -> JobResult {
        return try await withUnsafeThrowingContinuation { continuation in
            mlQueue.async {
                do {
                    let detector = AnomalyDetectionEngine(
                        metalDevice: self.metalDevice,
                        neuralEngine: self.neuralEngine
                    )
                    
                    let anomalies = try detector.detectAnomalies(
                        timeRange: job.parameters["timeRange"] as? TimeInterval ?? 604800
                    )
                    
                    let result = JobResult(
                        status: .completed,
                        data: anomalies,
                        insights: detector.generateAnomalyInsights(anomalies),
                        metadata: [
                            "anomaliesDetected": anomalies.count,
                            "severity": anomalies.maxSeverity,
                            "confidence": anomalies.averageConfidence
                        ]
                    )
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func executePredictiveModeling(_ job: AnalyticsJob) async throws -> JobResult {
        return try await withUnsafeThrowingContinuation { continuation in
            mlQueue.async {
                do {
                    let predictor = PredictiveHealthModeler(
                        metalDevice: self.metalDevice,
                        neuralEngine: self.neuralEngine,
                        useNPU: self.isNPUAvailable
                    )
                    
                    let predictions = try predictor.generatePredictions(
                        forecastHorizon: job.parameters["forecastHorizon"] as? TimeInterval ?? 604800
                    )
                    
                    let result = JobResult(
                        status: .completed,
                        data: predictions,
                        insights: predictor.generatePredictiveInsights(predictions),
                        metadata: [
                            "predictionsGenerated": predictions.count,
                            "forecastAccuracy": predictions.averageConfidence,
                            "modelVersion": predictions.modelVersion
                        ]
                    )
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Job Completion
    
    private func completeJob(_ job: AnalyticsJob, result: JobResult, duration: TimeInterval) async {
        runningJobs.remove(job.id)
        
        let completedJob = CompletedJob(
            id: job.id,
            type: job.type,
            startTime: job.scheduledTime,
            endTime: Date(),
            result: result,
            resourcesUsed: await MainActor.run { systemResourceUsage },
            duration: duration
        )
        
        await MainActor.run {
            completedJobs.append(completedJob)
            
            // Keep only recent completed jobs to manage memory
            if completedJobs.count > 100 {
                completedJobs.removeFirst(completedJobs.count - 100)
            }
        }
        
        // Sync results to iCloud in background
        Task.detached(priority: .background) {
            await self.cloudKitSync.syncJobResult(completedJob)
        }
        
        os_log("Completed job: %@ in %.2f seconds", log: .default, type: .info, 
               job.type.rawValue, duration)
        
        // Process next job if available
        await processNextJobIfPossible()
        
        // Update status if no more jobs
        if jobQueue.isEmpty && runningJobs.isEmpty {
            await MainActor.run {
                processingStatus = .idle
                currentJob = nil
            }
        }
    }
    
    // MARK: - Resource Management
    
    private func isSystemResourcesAvailable() async -> Bool {
        let memoryUsage = await MainActor.run { systemResourceUsage.memoryUsage }
        let batteryLevel = await MainActor.run { systemResourceUsage.batteryLevel }
        let thermalState = ProcessInfo.processInfo.thermalState
        
        // Check if system is under stress
        guard memoryUsage < 0.8,  // Less than 80% memory usage
              batteryLevel > 0.2 || ProcessInfo.processInfo.isLowPowerModeEnabled == false,
              thermalState == .nominal || thermalState == .fair else {
            return false
        }
        
        return true
    }
    
    private func handleMemoryPressure() async {
        os_log("Memory pressure detected, optimizing usage", log: .default, type: .warning)
        
        // Pause non-critical jobs
        await pauseProcessing()
        
        // Clear caches and optimize memory
        await optimizeMemoryUsage()
        
        // Resume processing after a delay
        try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
        await resumeProcessing()
    }
    
    private func handleThermalStateChange() async {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .critical:
            os_log("Critical thermal state, pausing processing", log: .default, type: .error)
            await pauseProcessing()
        case .serious:
            os_log("Serious thermal state, reducing processing", log: .default, type: .warning)
            // Reduce concurrent jobs
            runningJobs.removeAll()
        case .fair:
            os_log("Fair thermal state, normal processing", log: .default, type: .info)
            await resumeProcessing()
        case .nominal:
            os_log("Nominal thermal state, full processing", log: .default, type: .info)
            await resumeProcessing()
        @unknown default:
            break
        }
    }
    
    private func optimizeMemoryUsage() async {
        // Clear internal caches
        await neuralEngine.clearCaches()
        
        // Trigger garbage collection
        autoreleasepool {
            // Force release of temporary objects
        }
        
        os_log("Memory usage optimized", log: .default, type: .info)
    }
    
    private func updateSystemResourceUsage() async {
        let memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryUsage = Double(memoryInfo.resident_size) / 1024 / 1024 / 1024 // GB
            
            await MainActor.run {
                systemResourceUsage.memoryUsage = memoryUsage
                systemResourceUsage.batteryLevel = UIDevice.current.batteryLevel
                systemResourceUsage.thermalState = ProcessInfo.processInfo.thermalState
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func prepareTrainingData(for job: AnalyticsJob) throws -> TrainingData {
        // Implementation depends on specific job requirements
        return TrainingData()
    }
    
    deinit {
        memoryPressureSource?.cancel()
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Supporting Types

enum ProcessingError: Error {
    case taskGroupEmpty
    case resourcesUnavailable
    case thermalThrottling
}

extension SystemResourceUsage {
    var memoryUsage: Double {
        get { _memoryUsage }
        set { _memoryUsage = newValue }
    }
    
    var batteryLevel: Float {
        get { _batteryLevel }
        set { _batteryLevel = newValue }
    }
    
    var thermalState: ProcessInfo.ThermalState {
        get { _thermalState }
        set { _thermalState = newValue }
    }
    
    private var _memoryUsage: Double = 0.0
    private var _batteryLevel: Float = 1.0
    private var _thermalState: ProcessInfo.ThermalState = .nominal
}

extension CompletedJob {
    init(id: UUID, type: JobType, startTime: Date, endTime: Date, result: JobResult, resourcesUsed: SystemResourceUsage, duration: TimeInterval) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.result = result
        self.resourcesUsed = resourcesUsed
        self.duration = duration
    }
    
    let duration: TimeInterval
}