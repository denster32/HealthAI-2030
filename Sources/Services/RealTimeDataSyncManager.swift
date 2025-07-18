import Foundation
import Combine
import Network
import CloudKit

/// Comprehensive real-time data synchronization manager for HealthAI 2030
/// Handles multi-device sync, conflict resolution, offline mode, and cloud integration
@MainActor
public class RealTimeDataSyncManager: ObservableObject {
    public static let shared = RealTimeDataSyncManager()
    
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var lastSyncDate: Date?
    @Published public var syncProgress: Double = 0.0
    @Published public var pendingChanges: [SyncChange] = []
    @Published public var conflicts: [SyncConflict] = []
    @Published public var connectedDevices: [ConnectedDevice] = []
    @Published public var networkStatus: NetworkStatus = .unknown
    
    private var syncQueue: [SyncOperation] = []
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor: NWPathMonitor?
    private var cloudKitContainer: CKContainer?
    private var syncTimer: Timer?
    
    // MARK: - Status Enums
    
    public enum SyncStatus: String, CaseIterable {
        case idle = "Idle"
        case syncing = "Syncing"
        case paused = "Paused"
        case error = "Error"
        case offline = "Offline"
        case conflict = "Conflict"
        
        public var color: String {
            switch self {
            case .idle: return "gray"
            case .syncing: return "blue"
            case .paused: return "orange"
            case .error: return "red"
            case .offline: return "yellow"
            case .conflict: return "purple"
            }
        }
    }
    
    public enum NetworkStatus: String, CaseIterable {
        case unknown = "Unknown"
        case connected = "Connected"
        case disconnected = "Disconnected"
        case wifi = "WiFi"
        case cellular = "Cellular"
        
        public var isConnected: Bool {
            switch self {
            case .connected, .wifi, .cellular: return true
            case .unknown, .disconnected: return false
            }
        }
    }
    
    public enum SyncPriority: String, CaseIterable {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        case critical = "Critical"
        
        public var delay: TimeInterval {
            switch self {
            case .low: return 300 // 5 minutes
            case .normal: return 60 // 1 minute
            case .high: return 10 // 10 seconds
            case .critical: return 0 // Immediate
            }
        }
    }
    
    // MARK: - Data Models
    
    public struct SyncChange: Identifiable, Codable {
        public let id = UUID()
        public let entityType: String
        public let entityId: String
        public let operation: SyncOperationType
        public let data: Data
        public let timestamp: Date
        public let deviceId: String
        public let priority: SyncPriority
        public let isResolved: Bool
        
        public init(
            entityType: String,
            entityId: String,
            operation: SyncOperationType,
            data: Data,
            deviceId: String,
            priority: SyncPriority = .normal
        ) {
            self.entityType = entityType
            self.entityId = entityId
            self.operation = operation
            self.data = data
            self.timestamp = Date()
            self.deviceId = deviceId
            self.priority = priority
            self.isResolved = false
        }
    }
    
    public enum SyncOperationType: String, CaseIterable, Codable {
        case create = "Create"
        case update = "Update"
        case delete = "Delete"
        case merge = "Merge"
        
        public var description: String {
            switch self {
            case .create: return "Create new record"
            case .update: return "Update existing record"
            case .delete: return "Delete record"
            case .merge: return "Merge conflicting changes"
            }
        }
    }
    
    public struct SyncConflict: Identifiable, Codable {
        public let id = UUID()
        public let entityType: String
        public let entityId: String
        public let localChange: SyncChange
        public let remoteChange: SyncChange
        public let conflictType: ConflictType
        public let timestamp: Date
        public let isResolved: Bool
        public let resolution: ConflictResolution?
        
        public init(
            entityType: String,
            entityId: String,
            localChange: SyncChange,
            remoteChange: SyncChange,
            conflictType: ConflictType
        ) {
            self.entityType = entityType
            self.entityId = entityId
            self.localChange = localChange
            self.remoteChange = remoteChange
            self.conflictType = conflictType
            self.timestamp = Date()
            self.isResolved = false
            self.resolution = nil
        }
    }
    
    public enum ConflictType: String, CaseIterable, Codable {
        case simultaneousEdit = "Simultaneous Edit"
        case deletionConflict = "Deletion Conflict"
        case dataMismatch = "Data Mismatch"
        case versionConflict = "Version Conflict"
        
        public var description: String {
            switch self {
            case .simultaneousEdit: return "Multiple devices edited the same record"
            case .deletionConflict: return "One device deleted while another updated"
            case .dataMismatch: return "Data structure or format mismatch"
            case .versionConflict: return "Version numbers don't match"
            }
        }
    }
    
    public enum ConflictResolution: String, CaseIterable, Codable {
        case useLocal = "Use Local"
        case useRemote = "Use Remote"
        case merge = "Merge"
        case manual = "Manual"
        
        public var description: String {
            switch self {
            case .useLocal: return "Keep local changes"
            case .useRemote: return "Accept remote changes"
            case .merge: return "Combine both changes"
            case .manual: return "Resolve manually"
            }
        }
    }
    
    public struct ConnectedDevice: Identifiable, Codable {
        public let id = UUID()
        public let deviceId: String
        public let deviceName: String
        public let deviceType: DeviceType
        public let lastSeen: Date
        public let isOnline: Bool
        public let syncStatus: SyncStatus
        
        public init(
            deviceId: String,
            deviceName: String,
            deviceType: DeviceType,
            lastSeen: Date = Date(),
            isOnline: Bool = true,
            syncStatus: SyncStatus = .idle
        ) {
            self.deviceId = deviceId
            self.deviceName = deviceName
            self.deviceType = deviceType
            self.lastSeen = lastSeen
            self.isOnline = isOnline
            self.syncStatus = syncStatus
        }
    }
    
    public enum DeviceType: String, CaseIterable, Codable {
        case iPhone = "iPhone"
        case iPad = "iPad"
        case mac = "Mac"
        case appleWatch = "Apple Watch"
        case appleTV = "Apple TV"
        case unknown = "Unknown"
        
        public var icon: String {
            switch self {
            case .iPhone: return "iphone"
            case .iPad: return "ipad"
            case .mac: return "laptopcomputer"
            case .appleWatch: return "applewatch"
            case .appleTV: return "appletv"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    private struct SyncOperation {
        let change: SyncChange
        let retryCount: Int
        let nextRetry: Date?
    }
    
    // MARK: - Public Methods
    
    /// Initialize the sync manager
    public func initialize() async {
        await setupNetworkMonitoring()
        await setupCloudKit()
        await loadPendingChanges()
        await startPeriodicSync()
        
        // Register for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    /// Start a sync operation
    public func startSync(priority: SyncPriority = .normal) async {
        guard networkStatus.isConnected else {
            syncStatus = .offline
            return
        }
        
        guard syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            try await performSync()
            syncStatus = .idle
            lastSyncDate = Date()
            syncProgress = 1.0
        } catch {
            syncStatus = .error
            print("Sync failed: \(error)")
        }
    }
    
    /// Add a change to the sync queue
    public func queueChange(
        entityType: String,
        entityId: String,
        operation: SyncOperationType,
        data: Data,
        priority: SyncPriority = .normal
    ) async {
        let deviceId = getCurrentDeviceId()
        let change = SyncChange(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            data: data,
            deviceId: deviceId,
            priority: priority
        )
        
        pendingChanges.append(change)
        await savePendingChanges()
        
        // Start sync if priority is high or critical
        if priority == .high || priority == .critical {
            await startSync(priority: priority)
        }
    }
    
    /// Resolve a sync conflict
    public func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async {
        guard let index = conflicts.firstIndex(where: { $0.id == conflict.id }) else { return }
        
        var updatedConflict = conflict
        updatedConflict.isResolved = true
        updatedConflict.resolution = resolution
        
        conflicts[index] = updatedConflict
        
        // Apply resolution
        switch resolution {
        case .useLocal:
            await applyLocalChange(conflict.localChange)
        case .useRemote:
            await applyRemoteChange(conflict.remoteChange)
        case .merge:
            await mergeChanges(conflict.localChange, conflict.remoteChange)
        case .manual:
            // Manual resolution - user will handle
            break
        }
        
        await saveConflicts()
    }
    
    /// Get sync statistics
    public func getSyncStatistics() -> SyncStatistics {
        let totalChanges = pendingChanges.count
        let resolvedChanges = pendingChanges.filter { $0.isResolved }.count
        let totalConflicts = conflicts.count
        let resolvedConflicts = conflicts.filter { $0.isResolved }.count
        let connectedDeviceCount = connectedDevices.filter { $0.isOnline }.count
        
        return SyncStatistics(
            totalChanges: totalChanges,
            resolvedChanges: resolvedChanges,
            pendingChanges: totalChanges - resolvedChanges,
            totalConflicts: totalConflicts,
            resolvedConflicts: resolvedConflicts,
            pendingConflicts: totalConflicts - resolvedConflicts,
            connectedDevices: connectedDeviceCount,
            lastSyncDate: lastSyncDate,
            syncStatus: syncStatus,
            networkStatus: networkStatus
        )
    }
    
    /// Export sync data for debugging
    public func exportSyncData() -> Data? {
        let exportData = SyncExportData(
            syncStatus: syncStatus,
            lastSyncDate: lastSyncDate,
            pendingChanges: pendingChanges,
            conflicts: conflicts,
            connectedDevices: connectedDevices,
            networkStatus: networkStatus,
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    /// Pause sync operations
    public func pauseSync() {
        syncStatus = .paused
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// Resume sync operations
    public func resumeSync() async {
        syncStatus = .idle
        await startPeriodicSync()
        await startSync()
    }
    
    /// Clear all pending changes (use with caution)
    public func clearPendingChanges() async {
        pendingChanges.removeAll()
        await savePendingChanges()
    }
    
    /// Clear all conflicts (use with caution)
    public func clearConflicts() async {
        conflicts.removeAll()
        await saveConflicts()
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() async {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkStatus(path)
            }
        }
        networkMonitor?.start(queue: DispatchQueue.global())
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        switch path.status {
        case .satisfied:
            if path.usesInterfaceType(.wifi) {
                networkStatus = .wifi
            } else if path.usesInterfaceType(.cellular) {
                networkStatus = .cellular
            } else {
                networkStatus = .connected
            }
        case .unsatisfied:
            networkStatus = .disconnected
        case .requiresConnection:
            networkStatus = .unknown
        @unknown default:
            networkStatus = .unknown
        }
        
        // Auto-resume sync when network becomes available
        if networkStatus.isConnected && syncStatus == .offline {
            Task {
                await startSync()
            }
        }
    }
    
    private func setupCloudKit() async {
        cloudKitContainer = CKContainer.default()
        
        // Check CloudKit availability
        do {
            let status = try await cloudKitContainer?.accountStatus()
            if status == .available {
                print("CloudKit is available")
            } else {
                print("CloudKit is not available: \(status?.rawValue ?? -1)")
            }
        } catch {
            print("CloudKit setup failed: \(error)")
        }
    }
    
    private func performSync() async throws {
        let totalChanges = pendingChanges.count
        var processedChanges = 0
        
        for change in pendingChanges {
            do {
                try await processChange(change)
                processedChanges += 1
                syncProgress = Double(processedChanges) / Double(totalChanges)
                
                // Small delay to prevent overwhelming the system
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } catch {
                print("Failed to process change: \(error)")
                // Continue with other changes
            }
        }
        
        // Update device list
        await updateConnectedDevices()
    }
    
    private func processChange(_ change: SyncChange) async throws {
        // Check for conflicts
        if let conflict = await detectConflict(for: change) {
            conflicts.append(conflict)
            await saveConflicts()
            return
        }
        
        // Apply change based on operation type
        switch change.operation {
        case .create:
            try await createRecord(change)
        case .update:
            try await updateRecord(change)
        case .delete:
            try await deleteRecord(change)
        case .merge:
            try await mergeRecord(change)
        }
        
        // Mark change as resolved
        if let index = pendingChanges.firstIndex(where: { $0.id == change.id }) {
            var updatedChange = change
            updatedChange.isResolved = true
            pendingChanges[index] = updatedChange
        }
    }
    
    private func detectConflict(for change: SyncChange) async -> SyncConflict? {
        // Check if there's a conflicting change for the same entity
        let conflictingChanges = pendingChanges.filter { 
            $0.entityId == change.entityId && 
            $0.entityType == change.entityType && 
            $0.id != change.id &&
            $0.timestamp > change.timestamp - 300 // Within 5 minutes
        }
        
        guard let conflictingChange = conflictingChanges.first else { return nil }
        
        let conflictType: ConflictType
        if change.operation == .delete && conflictingChange.operation == .update {
            conflictType = .deletionConflict
        } else if change.operation == .update && conflictingChange.operation == .update {
            conflictType = .simultaneousEdit
        } else {
            conflictType = .dataMismatch
        }
        
        return SyncConflict(
            entityType: change.entityType,
            entityId: change.entityId,
            localChange: change,
            remoteChange: conflictingChange,
            conflictType: conflictType
        )
    }
    
    private func createRecord(_ change: SyncChange) async throws {
        // Implementation for creating a new record
        // This would typically involve CloudKit or other backend service
        print("Creating record: \(change.entityId)")
    }
    
    private func updateRecord(_ change: SyncChange) async throws {
        // Implementation for updating an existing record
        print("Updating record: \(change.entityId)")
    }
    
    private func deleteRecord(_ change: SyncChange) async throws {
        // Implementation for deleting a record
        print("Deleting record: \(change.entityId)")
    }
    
    private func mergeRecord(_ change: SyncChange) async throws {
        // Implementation for merging records
        print("Merging record: \(change.entityId)")
    }
    
    private func applyLocalChange(_ change: SyncChange) async {
        // Apply local change and remove from pending
        if let index = pendingChanges.firstIndex(where: { $0.id == change.id }) {
            var updatedChange = change
            updatedChange.isResolved = true
            pendingChanges[index] = updatedChange
        }
    }
    
    private func applyRemoteChange(_ change: SyncChange) async {
        // Apply remote change and remove from pending
        if let index = pendingChanges.firstIndex(where: { $0.id == change.id }) {
            pendingChanges.remove(at: index)
        }
    }
    
    private func mergeChanges(_ localChange: SyncChange, _ remoteChange: SyncChange) async {
        // Implementation for merging changes
        // This would combine both changes and create a new merged change
        print("Merging changes for: \(localChange.entityId)")
    }
    
    private func updateConnectedDevices() async {
        // Update list of connected devices
        // This would typically involve CloudKit or other backend service
        let currentDevice = ConnectedDevice(
            deviceId: getCurrentDeviceId(),
            deviceName: getCurrentDeviceName(),
            deviceType: getCurrentDeviceType(),
            lastSeen: Date(),
            isOnline: true,
            syncStatus: syncStatus
        )
        
        if let index = connectedDevices.firstIndex(where: { $0.deviceId == currentDevice.deviceId }) {
            connectedDevices[index] = currentDevice
        } else {
            connectedDevices.append(currentDevice)
        }
    }
    
    private func startPeriodicSync() async {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 5 minutes
            Task {
                await self.startSync(priority: .normal)
            }
        }
    }
    
    private func loadPendingChanges() async {
        // Load pending changes from persistent storage
        // This would typically involve Core Data or UserDefaults
    }
    
    private func savePendingChanges() async {
        // Save pending changes to persistent storage
        // This would typically involve Core Data or UserDefaults
    }
    
    private func saveConflicts() async {
        // Save conflicts to persistent storage
        // This would typically involve Core Data or UserDefaults
    }
    
    private func getCurrentDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    private func getCurrentDeviceName() -> String {
        return UIDevice.current.name
    }
    
    private func getCurrentDeviceType() -> DeviceType {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        case .tv:
            return .appleTV
        case .mac:
            return .mac
        case .watch:
            return .appleWatch
        default:
            return .unknown
        }
    }
    
    @objc private func appDidBecomeActive() {
        Task {
            await startSync(priority: .high)
        }
    }
    
    @objc private func appWillResignActive() {
        // Ensure all pending changes are saved
        Task {
            await savePendingChanges()
        }
    }
}

// MARK: - Supporting Structures

public struct SyncStatistics: Codable {
    public let totalChanges: Int
    public let resolvedChanges: Int
    public let pendingChanges: Int
    public let totalConflicts: Int
    public let resolvedConflicts: Int
    public let pendingConflicts: Int
    public let connectedDevices: Int
    public let lastSyncDate: Date?
    public let syncStatus: RealTimeDataSyncManager.SyncStatus
    public let networkStatus: RealTimeDataSyncManager.NetworkStatus
    
    public var syncProgress: Double {
        guard totalChanges > 0 else { return 1.0 }
        return Double(resolvedChanges) / Double(totalChanges)
    }
    
    public var conflictResolutionRate: Double {
        guard totalConflicts > 0 else { return 1.0 }
        return Double(resolvedConflicts) / Double(totalConflicts)
    }
}

private struct SyncExportData: Codable {
    let syncStatus: RealTimeDataSyncManager.SyncStatus
    let lastSyncDate: Date?
    let pendingChanges: [RealTimeDataSyncManager.SyncChange]
    let conflicts: [RealTimeDataSyncManager.SyncConflict]
    let connectedDevices: [RealTimeDataSyncManager.ConnectedDevice]
    let networkStatus: RealTimeDataSyncManager.NetworkStatus
    let exportDate: Date
} 