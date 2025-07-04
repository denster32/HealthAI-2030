import Foundation
import SwiftUI
import CloudKit
import SwiftData
import OSLog
import Combine

@available(macOS 15.0, *)
@MainActor
public class MacHealthAICoordinator: ObservableObject {
    public static let shared = MacHealthAICoordinator()
    
    // MARK: - Published Properties
    @Published public var isActive: Bool = false
    @Published public var systemStatus: SystemStatus = .initializing
    @Published public var connectedDevices: [ConnectedDevice] = []
    @Published public var processingQueue: [ProcessingTask] = []
    @Published public var recentExports: [CompletedExport] = []
    @Published public var systemHealth: SystemHealth = SystemHealth()
    
    // Core managers
    private let analyticsEngine = EnhancedMacAnalyticsEngine.shared
    private let exportManager = AdvancedDataExportManager.shared
    private let syncManager = UnifiedCloudKitSyncManager.shared
    private let logger = Logger(subsystem: "com.HealthAI2030.Mac", category: "Coordinator")
    
    // Coordination tasks
    private var statusUpdateTimer: Timer?
    private var deviceMonitoringTask: Task<Void, Never>?
    private var analyticsCoordinationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupCoordination()
    }
    
    private func setupCoordination() {
        logger.info("Setting up Mac Health AI Coordinator")
        
        // Bind to engine status updates
        analyticsEngine.$processingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateSystemStatus(from: status)
            }
            .store(in: &cancellables)
        
        // Bind to sync manager updates
        syncManager.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateSyncStatus(from: status)
            }
            .store(in: &cancellables)
        
        // Bind to export manager updates
        exportManager.$availableExports
            .receive(on: DispatchQueue.main)
            .sink { [weak self] exports in
                self?.recentExports = Array(exports.suffix(10))
            }
            .store(in: &cancellables)
        
        startCoordination()
    }
    
    // MARK: - Coordination Control
    
    public func startCoordination() async {
        guard !isActive else { return }
        
        logger.info("Starting Mac Health AI coordination")
        isActive = true
        systemStatus = .starting
        
        // Start all coordination tasks
        startStatusMonitoring()
        startDeviceMonitoring()
        startAnalyticsCoordination()
        
        // Wait a moment for everything to initialize
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        systemStatus = .active
        logger.info("Mac Health AI coordination active")
    }
    
    public func stopCoordination() {
        logger.info("Stopping Mac Health AI coordination")
        
        isActive = false
        systemStatus = .stopping
        
        // Cancel all tasks
        statusUpdateTimer?.invalidate()
        deviceMonitoringTask?.cancel()
        analyticsCoordinationTask?.cancel()
        
        systemStatus = .inactive
        logger.info("Mac Health AI coordination stopped")
    }
    
    // MARK: - Status Monitoring
    
    private func startStatusMonitoring() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateSystemHealth()
            }
        }
    }
    
    private func updateSystemHealth() async {
        let processInfo = ProcessInfo.processInfo
        
        systemHealth = SystemHealth(
            cpuUsage: getCurrentCPUUsage(),
            memoryUsage: getMemoryUsage(),
            diskUsage: getDiskUsage(),
            networkStatus: getNetworkStatus(),
            thermalState: processInfo.thermalState,
            powerState: processInfo.isLowPowerModeEnabled ? .lowPower : .normal,
            lastUpdated: Date()
        )
        
        // Update processing queue
        updateProcessingQueue()
    }
    
    private func updateProcessingQueue() {
        processingQueue = [
            ProcessingTask(
                id: UUID(),
                type: .analytics,
                status: .running,
                progress: analyticsEngine.progress,
                description: analyticsEngine.currentJob.isEmpty ? "Idle" : analyticsEngine.currentJob,
                startTime: Date(),
                estimatedCompletion: Date().addingTimeInterval(300)
            )
        ]
        
        // Add queued analytics jobs
        for (index, job) in analyticsEngine.queuedJobs.enumerated() {
            processingQueue.append(ProcessingTask(
                id: job.id,
                type: .analytics,
                status: .queued,
                progress: 0.0,
                description: job.type.displayName,
                startTime: job.scheduledTime,
                estimatedCompletion: job.scheduledTime.addingTimeInterval(TimeInterval(index + 1) * 300)
            ))
        }
    }
    
    // MARK: - Device Monitoring
    
    private func startDeviceMonitoring() {
        deviceMonitoringTask = Task { [weak self] in
            await self?.monitorConnectedDevices()
        }
    }
    
    private func monitorConnectedDevices() async {
        while !Task.isCancelled {
            do {
                let devices = await detectConnectedDevices()
                
                await MainActor.run { [weak self] in
                    self?.connectedDevices = devices
                }
                
                // Check every 60 seconds
                try await Task.sleep(nanoseconds: 60_000_000_000)
                
            } catch {
                logger.error("Device monitoring error: \(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: 120_000_000_000)
            }
        }
    }
    
    private func detectConnectedDevices() async -> [ConnectedDevice] {
        // In a real implementation, this would check CloudKit for recent sync activity
        // and determine which devices are actively syncing data
        
        var devices: [ConnectedDevice] = []
        
        // Check for iPhone activity
        if let lastSync = syncManager.lastSyncDate,
           Date().timeIntervalSince(lastSync) < 3600 { // Active within last hour
            devices.append(ConnectedDevice(
                id: "iphone-primary",
                name: "iPhone",
                type: .iPhone,
                status: .connected,
                lastSeen: lastSync,
                dataTypes: [.healthData, .sleepData, .insights],
                batteryLevel: nil
            ))
        }
        
        // Check for Apple Watch activity
        if let lastSync = syncManager.lastSyncDate,
           Date().timeIntervalSince(lastSync) < 1800 { // Active within last 30 minutes
            devices.append(ConnectedDevice(
                id: "watch-primary",
                name: "Apple Watch",
                type: .appleWatch,
                status: .connected,
                lastSeen: lastSync,
                dataTypes: [.healthData, .workoutData],
                batteryLevel: nil
            ))
        }
        
        return devices
    }
    
    // MARK: - Analytics Coordination
    
    private func startAnalyticsCoordination() {
        analyticsCoordinationTask = Task { [weak self] in
            await self?.coordinateAnalytics()
        }
    }
    
    private func coordinateAnalytics() async {
        while !Task.isCancelled {
            do {
                // Check for new analytics requests from mobile devices
                await processAnalyticsRequests()
                
                // Check for export requests
                await processExportRequests()
                
                // Wait 2 minutes before next check
                try await Task.sleep(nanoseconds: 120_000_000_000)
                
            } catch {
                logger.error("Analytics coordination error: \(error.localizedDescription)")
                try? await Task.sleep(nanoseconds: 300_000_000_000)
            }
        }
    }
    
    private func processAnalyticsRequests() async {
        // Check for analytics insights that are actually requests from mobile devices
        guard let modelContext = try? ModelContext(ModelContainer.shared) else { return }
        
        let descriptor = FetchDescriptor<AnalyticsInsight>(
            predicate: #Predicate { insight in
                insight.category == "Request" && insight.source != "Mac"
            }
        )
        
        do {
            let requests = try modelContext.fetch(descriptor)
            
            for request in requests {
                logger.info("Processing analytics request: \(request.title)")
                
                // Parse request and trigger appropriate analysis
                if request.title.contains("Mac Analytics Request") {
                    try await analyticsEngine.processOffloadedData(from: request.source)
                }
                
                // Mark request as processed by updating it
                request.source = "Mac"
                request.needsSync = true
                try modelContext.save()
            }
        } catch {
            logger.error("Failed to process analytics requests: \(error.localizedDescription)")
        }
    }
    
    private func processExportRequests() async {
        // This is handled by the export manager's monitoring system
        // We just need to ensure it's running
        if exportManager.exportStatus == .idle {
            // Export manager is ready for new requests
        }
    }
    
    // MARK: - Public Interface
    
    public func triggerManualSync() async {
        logger.info("Manual sync triggered from Mac")
        await syncManager.startSync()
    }
    
    public func triggerAnalysis(types: [AnalyticsType] = [], for deviceSource: String = "Manual") async throws {
        logger.info("Manual analysis triggered for \(deviceSource)")
        try await analyticsEngine.triggerManualAnalysis(for: deviceSource, analysisTypes: types)
    }
    
    public func exportData(format: ExportType = .csv, dateRange: DateInterval? = nil) async throws -> URL {
        let range = dateRange ?? DateInterval(
            start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            end: Date()
        )
        
        return try await exportManager.exportData(
            type: format,
            dateRange: range,
            includeRawData: true,
            includeAnalytics: true,
            includeInsights: true
        )
    }
    
    public func getSystemReport() -> SystemReport {
        return SystemReport(
            coordinator: self,
            analytics: analyticsEngine,
            export: exportManager,
            sync: syncManager
        )
    }
    
    // MARK: - Status Updates
    
    private func updateSystemStatus(from analyticsStatus: AnalyticsProcessingStatus) {
        switch analyticsStatus {
        case .processing:
            if systemStatus == .active {
                systemStatus = .processing
            }
        case .idle:
            if systemStatus == .processing {
                systemStatus = .active
            }
        case .suspended:
            systemStatus = .throttled
        case .error:
            systemStatus = .error
        }
    }
    
    private func updateSyncStatus(from syncStatus: SyncStatus) {
        // Sync status updates can influence overall system status
        if syncStatus == .error && systemStatus != .error {
            systemStatus = .warning
        }
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentCPUUsage() -> Double {
        // Simplified CPU usage calculation
        return 0.25 // Placeholder
    }
    
    private func getMemoryUsage() -> Double {
        let processInfo = ProcessInfo.processInfo
        return 0.4 // Placeholder
    }
    
    private func getDiskUsage() -> Double {
        return 0.6 // Placeholder
    }
    
    private func getNetworkStatus() -> NetworkStatus {
        return .connected // Placeholder
    }
    
    deinit {
        stopCoordination()
    }
}

// MARK: - Supporting Types

public enum SystemStatus: String, CaseIterable {
    case initializing = "Initializing"
    case starting = "Starting"
    case active = "Active"
    case processing = "Processing"
    case throttled = "Throttled"
    case warning = "Warning"
    case error = "Error"
    case stopping = "Stopping"
    case inactive = "Inactive"
    
    var color: Color {
        switch self {
        case .initializing, .starting, .stopping:
            return .orange
        case .active:
            return .green
        case .processing:
            return .blue
        case .throttled:
            return .yellow
        case .warning:
            return .orange
        case .error:
            return .red
        case .inactive:
            return .gray
        }
    }
}

public struct ConnectedDevice: Identifiable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let status: DeviceStatus
    public let lastSeen: Date
    public let dataTypes: [DataType]
    public let batteryLevel: Double?
    
    public enum DeviceType: String, CaseIterable {
        case iPhone = "iPhone"
        case appleWatch = "Apple Watch"
        case iPad = "iPad"
        case unknown = "Unknown"
        
        var icon: String {
            switch self {
            case .iPhone: return "iphone"
            case .appleWatch: return "applewatch"
            case .iPad: return "ipad"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    public enum DeviceStatus: String, CaseIterable {
        case connected = "Connected"
        case syncing = "Syncing"
        case disconnected = "Disconnected"
        case offline = "Offline"
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .syncing: return .blue
            case .disconnected: return .orange
            case .offline: return .gray
            }
        }
    }
    
    public enum DataType: String, CaseIterable {
        case healthData = "Health Data"
        case sleepData = "Sleep Data"
        case workoutData = "Workout Data"
        case insights = "AI Insights"
        case analytics = "Analytics"
    }
}

public struct ProcessingTask: Identifiable {
    public let id: UUID
    public let type: TaskType
    public let status: TaskStatus
    public let progress: Double
    public let description: String
    public let startTime: Date
    public let estimatedCompletion: Date
    
    public enum TaskType: String, CaseIterable {
        case analytics = "Analytics"
        case export = "Export"
        case sync = "Sync"
        case modelTraining = "Model Training"
    }
    
    public enum TaskStatus: String, CaseIterable {
        case queued = "Queued"
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
        
        var color: Color {
            switch self {
            case .queued: return .orange
            case .running: return .blue
            case .completed: return .green
            case .failed: return .red
            case .cancelled: return .gray
            }
        }
    }
}

public struct SystemHealth {
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let diskUsage: Double
    public let networkStatus: NetworkStatus
    public let thermalState: ProcessInfo.ThermalState
    public let powerState: PowerState
    public let lastUpdated: Date
    
    public init() {
        self.cpuUsage = 0.0
        self.memoryUsage = 0.0
        self.diskUsage = 0.0
        self.networkStatus = .disconnected
        self.thermalState = .nominal
        self.powerState = .normal
        self.lastUpdated = Date()
    }
    
    public init(cpuUsage: Double, memoryUsage: Double, diskUsage: Double, networkStatus: NetworkStatus, thermalState: ProcessInfo.ThermalState, powerState: PowerState, lastUpdated: Date) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.networkStatus = networkStatus
        self.thermalState = thermalState
        self.powerState = powerState
        self.lastUpdated = lastUpdated
    }
    
    public enum NetworkStatus: String, CaseIterable {
        case connected = "Connected"
        case limited = "Limited"
        case disconnected = "Disconnected"
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .limited: return .orange
            case .disconnected: return .red
            }
        }
    }
    
    public enum PowerState: String, CaseIterable {
        case normal = "Normal"
        case lowPower = "Low Power"
        case charging = "Charging"
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .lowPower: return .orange
            case .charging: return .blue
            }
        }
    }
}

public struct SystemReport {
    public let timestamp: Date = Date()
    public let systemStatus: SystemStatus
    public let connectedDevices: Int
    public let processingTasks: Int
    public let systemHealth: SystemHealth
    public let analyticsInfo: [String: Any]
    public let syncInfo: [String: Any]
    public let exportInfo: [String: Any]
    
    public init(coordinator: MacHealthAICoordinator, analytics: EnhancedMacAnalyticsEngine, export: AdvancedDataExportManager, sync: UnifiedCloudKitSyncManager) {
        self.systemStatus = coordinator.systemStatus
        self.connectedDevices = coordinator.connectedDevices.count
        self.processingTasks = coordinator.processingQueue.count
        self.systemHealth = coordinator.systemHealth
        self.analyticsInfo = analytics.getSystemInfo()
        self.syncInfo = [
            "status": sync.syncStatus.rawValue,
            "lastSync": sync.lastSyncDate?.description ?? "Never",
            "pendingSync": sync.pendingSyncCount,
            "networkAvailable": sync.isNetworkAvailable
        ]
        self.exportInfo = [
            "status": export.exportStatus.rawValue,
            "availableExports": export.availableExports.count,
            "pendingRequests": export.pendingRequests.count
        ]
    }
}