import SwiftUI
import CloudKit
import Combine
import Network
#if os(iOS) || os(watchOS) || os(tvOS)
import WatchConnectivity
#endif

@available(tvOS 18.0, *)
public class CrossDeviceSyncManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var connectedDevices: [ConnectedDevice] = []
    @Published public var lastSyncTime: Date?
    @Published public var syncProgress: Double = 0.0
    @Published public var pendingSyncItems: Int = 0
    @Published public var syncConflicts: [SyncConflict] = []
    @Published public var networkStatus: NetworkStatus = .unknown
    
    // MARK: - Private Properties
    
    private let cloudKitContainer: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    private var syncCoordinator: SyncCoordinator
    private var conflictResolver: ConflictResolver
    private var dataTransformer: DataTransformer
    private var encryptionManager: SyncEncryptionManager
    private var networkMonitor: NWPathMonitor
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var prioritySyncQueue: OperationQueue
    private var backgroundSyncQueue: OperationQueue
    
    // Data sync queues
    private var pendingHealthData: [HealthDataSyncItem] = []
    private var pendingUserPreferences: [UserPreferencesSyncItem] = []
    private var pendingSessionData: [SessionDataSyncItem] = []
    private var pendingInsights: [InsightsSyncItem] = []
    
    // Device discovery
    private var deviceDiscoveryService: DeviceDiscoveryService
    private var nearbyDevices: [NearbyDevice] = []
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    private var session: WCSession?
    private var isReachable: Bool = false
    private var pendingData: [String: Any] = [:]
    #endif
    
    // MARK: - Initialization
    
    override init() {
        cloudKitContainer = CKContainer.default()
        privateDatabase = cloudKitContainer.privateCloudDatabase
        publicDatabase = cloudKitContainer.publicCloudDatabase
        sharedDatabase = cloudKitContainer.sharedCloudDatabase
        
        syncCoordinator = SyncCoordinator()
        conflictResolver = ConflictResolver()
        dataTransformer = DataTransformer()
        encryptionManager = SyncEncryptionManager()
        networkMonitor = NWPathMonitor()
        deviceDiscoveryService = DeviceDiscoveryService()
        
        prioritySyncQueue = OperationQueue()
        prioritySyncQueue.name = "PrioritySyncQueue"
        prioritySyncQueue.maxConcurrentOperationCount = 1
        
        backgroundSyncQueue = OperationQueue()
        backgroundSyncQueue.name = "BackgroundSyncQueue"
        backgroundSyncQueue.maxConcurrentOperationCount = 3
        
        super.init()
        
        setupCloudKitSubscriptions()
        setupNetworkMonitoring()
        setupDeviceDiscovery()
        startSyncCoordination()
        
        #if os(iOS) || os(watchOS) || os(tvOS)
        if WCSession.isSupported() {
            self.session = WCSession.default
            self.session?.delegate = self
            self.session?.activate()
        }
        #endif
    }
    
    // MARK: - Setup Methods
    
    private func setupCloudKitSubscriptions() {
        Task {
            await createCloudKitSubscriptions()
        }
    }
    
    private func createCloudKitSubscriptions() async {
        do {
            // Health data subscription
            let healthDataSubscription = CKQuerySubscription(
                recordType: "HealthData",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
            )
            healthDataSubscription.notificationInfo = createNotificationInfo(for: "HealthData")
            
            // User preferences subscription
            let preferencesSubscription = CKQuerySubscription(
                recordType: "UserPreferences",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            preferencesSubscription.notificationInfo = createNotificationInfo(for: "UserPreferences")
            
            // Session data subscription
            let sessionSubscription = CKQuerySubscription(
                recordType: "SessionData",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            sessionSubscription.notificationInfo = createNotificationInfo(for: "SessionData")
            
            // Save subscriptions
            try await privateDatabase.save(healthDataSubscription)
            try await privateDatabase.save(preferencesSubscription)
            try await privateDatabase.save(sessionSubscription)
            
            print("CloudKit subscriptions created successfully")
        } catch {
            print("Failed to create CloudKit subscriptions: \(error)")
        }
    }
    
    private func createNotificationInfo(for recordType: String) -> CKSubscription.NotificationInfo {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.category = "HEALTH_DATA_SYNC"
        return notificationInfo
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkStatusChange(path)
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func setupDeviceDiscovery() {
        deviceDiscoveryService.discoveredDevicesPublisher
            .sink { [weak self] devices in
                self?.handleDiscoveredDevices(devices)
            }
            .store(in: &cancellables)
        
        deviceDiscoveryService.startDiscovery()
    }
    
    private func startSyncCoordination() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicSync()
            }
        }
        
        // Immediate sync on startup
        Task {
            await performInitialSync()
        }
    }
    
    // MARK: - Network Handling
    
    private func handleNetworkStatusChange(_ path: NWPath) {
        let newStatus: NetworkStatus
        
        if path.status == .satisfied {
            if path.isExpensive {
                newStatus = .cellular
            } else {
                newStatus = .wifi
            }
        } else {
            newStatus = .offline
        }
        
        if newStatus != networkStatus {
            networkStatus = newStatus
            handleNetworkStatusTransition(from: networkStatus, to: newStatus)
        }
    }
    
    private func handleNetworkStatusTransition(from oldStatus: NetworkStatus, to newStatus: NetworkStatus) {
        switch newStatus {
        case .wifi:
            // High-bandwidth sync
            Task {
                await performHighBandwidthSync()
            }
            
        case .cellular:
            // Conservative sync - only critical data
            Task {
                await performCriticalDataSync()
            }
            
        case .offline:
            // Queue data for later sync
            syncStatus = .offline
            
        case .unknown:
            break
        }
    }
    
    // MARK: - Device Discovery
    
    private func handleDiscoveredDevices(_ devices: [NearbyDevice]) {
        nearbyDevices = devices
        
        // Update connected devices list
        connectedDevices = devices.compactMap { nearbyDevice in
            ConnectedDevice(
                id: nearbyDevice.identifier,
                name: nearbyDevice.name,
                type: nearbyDevice.deviceType,
                isNearby: true,
                lastSeen: Date(),
                capabilities: nearbyDevice.capabilities
            )
        }
    }
    
    // MARK: - Sync Operations
    
    private func performInitialSync() async {
        await updateSyncStatus(.syncing)
        
        do {
            // Fetch account status
            let accountStatus = try await cloudKitContainer.accountStatus()
            guard accountStatus == .available else {
                await updateSyncStatus(.error("iCloud account not available"))
                return
            }
            
            // Perform initial data fetch
            await fetchAllCloudData()
            await resolveAnyPendingConflicts()
            
            lastSyncTime = Date()
            await updateSyncStatus(.completed)
            
        } catch {
            await updateSyncStatus(.error(error.localizedDescription))
        }
    }
    
    private func performPeriodicSync() async {
        guard networkStatus != .offline else { return }
        
        await syncPendingData()
        await fetchUpdatedCloudData()
        await syncWithNearbyDevices()
    }
    
    private func performHighBandwidthSync() async {
        await updateSyncStatus(.syncing)
        
        // Sync all pending data
        await syncHealthData()
        await syncUserPreferences()
        await syncSessionData()
        await syncInsightsData()
        await syncMediaAssets()
        
        await updateSyncStatus(.completed)
    }
    
    private func performCriticalDataSync() async {
        await updateSyncStatus(.syncing)
        
        // Only sync critical, small data
        await syncCriticalHealthData()
        await syncUserPreferences()
        
        await updateSyncStatus(.completed)
    }
    
    // MARK: - Data Synchronization
    
    func syncHealthData() async {
        let operation = HealthDataSyncOperation(
            pendingItems: pendingHealthData,
            database: privateDatabase,
            encryptionManager: encryptionManager
        )
        
        prioritySyncQueue.addOperation(operation)
        
        await operation.completionPublisher.sink { [weak self] result in
            switch result {
            case .success(let syncedCount):
                self?.pendingHealthData.removeFirst(syncedCount)
                self?.updatePendingCount()
                
            case .failure(let error):
                print("Health data sync failed: \(error)")
            }
        }.store(in: &cancellables)
    }
    
    func syncUserPreferences() async {
        let operation = UserPreferencesSyncOperation(
            pendingItems: pendingUserPreferences,
            database: privateDatabase,
            encryptionManager: encryptionManager
        )
        
        backgroundSyncQueue.addOperation(operation)
        
        await operation.completionPublisher.sink { [weak self] result in
            switch result {
            case .success(let syncedCount):
                self?.pendingUserPreferences.removeFirst(syncedCount)
                self?.updatePendingCount()
                
            case .failure(let error):
                print("User preferences sync failed: \(error)")
            }
        }.store(in: &cancellables)
    }
    
    func syncSessionData() async {
        let operation = SessionDataSyncOperation(
            pendingItems: pendingSessionData,
            database: privateDatabase,
            encryptionManager: encryptionManager
        )
        
        backgroundSyncQueue.addOperation(operation)
        
        await operation.completionPublisher.sink { [weak self] result in
            switch result {
            case .success(let syncedCount):
                self?.pendingSessionData.removeFirst(syncedCount)
                self?.updatePendingCount()
                
            case .failure(let error):
                print("Session data sync failed: \(error)")
            }
        }.store(in: &cancellables)
    }
    
    func syncInsightsData() async {
        let operation = InsightsSyncOperation(
            pendingItems: pendingInsights,
            database: privateDatabase,
            encryptionManager: encryptionManager
        )
        
        backgroundSyncQueue.addOperation(operation)
        
        await operation.completionPublisher.sink { [weak self] result in
            switch result {
            case .success(let syncedCount):
                self?.pendingInsights.removeFirst(syncedCount)
                self?.updatePendingCount()
                
            case .failure(let error):
                print("Insights sync failed: \(error)")
            }
        }.store(in: &cancellables)
    }
    
    private func syncMediaAssets() async {
        // Sync larger media files when on WiFi
        // Implementation would handle fractal visualizations, audio files, etc.
    }
    
    private func syncCriticalHealthData() async {
        // Only sync the most recent, critical health data
        let criticalItems = pendingHealthData.filter { $0.priority == .critical }
        
        let operation = HealthDataSyncOperation(
            pendingItems: criticalItems,
            database: privateDatabase,
            encryptionManager: encryptionManager
        )
        
        prioritySyncQueue.addOperation(operation)
    }
    
    // MARK: - Data Fetching
    
    private func fetchAllCloudData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchCloudHealthData() }
            group.addTask { await self.fetchCloudUserPreferences() }
            group.addTask { await self.fetchCloudSessionData() }
            group.addTask { await self.fetchCloudInsights() }
        }
    }
    
    private func fetchUpdatedCloudData() async {
        guard let lastSync = lastSyncTime else {
            await fetchAllCloudData()
            return
        }
        
        // Fetch only data modified since last sync
        await fetchCloudDataModifiedSince(lastSync)
    }
    
    private func fetchCloudHealthData() async {
        do {
            let query = CKQuery(recordType: "HealthData", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
            
            let result = try await privateDatabase.records(matching: query)
            let healthDataItems = result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return parseHealthDataRecord(record)
                case .failure(let error):
                    print("Failed to fetch health data record: \(error)")
                    return nil
                }
            }
            
            await processIncomingHealthData(healthDataItems)
            
        } catch {
            print("Failed to fetch cloud health data: \(error)")
        }
    }
    
    private func fetchCloudUserPreferences() async {
        do {
            let query = CKQuery(recordType: "UserPreferences", predicate: NSPredicate(value: true))
            
            let result = try await privateDatabase.records(matching: query)
            let preferencesItems = result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return parseUserPreferencesRecord(record)
                case .failure(let error):
                    print("Failed to fetch preferences record: \(error)")
                    return nil
                }
            }
            
            await processIncomingUserPreferences(preferencesItems)
            
        } catch {
            print("Failed to fetch cloud user preferences: \(error)")
        }
    }
    
    private func fetchCloudSessionData() async {
        do {
            let query = CKQuery(recordType: "SessionData", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let result = try await privateDatabase.records(matching: query)
            let sessionItems = result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return parseSessionDataRecord(record)
                case .failure(let error):
                    print("Failed to fetch session data record: \(error)")
                    return nil
                }
            }
            
            await processIncomingSessionData(sessionItems)
            
        } catch {
            print("Failed to fetch cloud session data: \(error)")
        }
    }
    
    private func fetchCloudInsights() async {
        do {
            let query = CKQuery(recordType: "HealthInsights", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let result = try await privateDatabase.records(matching: query)
            let insightItems = result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return parseInsightsRecord(record)
                case .failure(let error):
                    print("Failed to fetch insights record: \(error)")
                    return nil
                }
            }
            
            await processIncomingInsights(insightItems)
            
        } catch {
            print("Failed to fetch cloud insights: \(error)")
        }
    }
    
    private func fetchCloudDataModifiedSince(_ date: Date) async {
        let predicate = NSPredicate(format: "modificationDate > %@", date as NSDate)
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchCloudHealthDataWithPredicate(predicate) }
            group.addTask { await self.fetchCloudUserPreferencesWithPredicate(predicate) }
            group.addTask { await self.fetchCloudSessionDataWithPredicate(predicate) }
            group.addTask { await self.fetchCloudInsightsWithPredicate(predicate) }
        }
    }
    
    private func fetchCloudHealthDataWithPredicate(_ predicate: NSPredicate) async {
        // Implementation similar to fetchCloudHealthData but with predicate
    }
    
    private func fetchCloudUserPreferencesWithPredicate(_ predicate: NSPredicate) async {
        // Implementation similar to fetchCloudUserPreferences but with predicate
    }
    
    private func fetchCloudSessionDataWithPredicate(_ predicate: NSPredicate) async {
        // Implementation similar to fetchCloudSessionData but with predicate
    }
    
    private func fetchCloudInsightsWithPredicate(_ predicate: NSPredicate) async {
        // Implementation similar to fetchCloudInsights but with predicate
    }
    
    // MARK: - Nearby Device Sync
    
    private func syncWithNearbyDevices() async {
        for device in nearbyDevices {
            if device.capabilities.contains(.healthDataSync) {
                await syncHealthDataWithDevice(device)
            }
            
            if device.capabilities.contains(.sessionDataSync) {
                await syncSessionDataWithDevice(device)
            }
            
            if device.capabilities.contains(.realTimeSync) {
                await establishRealTimeSyncWithDevice(device)
            }
        }
    }
    
    private func syncHealthDataWithDevice(_ device: NearbyDevice) async {
        // Direct device-to-device health data sync
        let syncRequest = DeviceSyncRequest(
            deviceId: device.identifier,
            dataType: .healthData,
            timestamp: Date()
        )
        
        do {
            let response = try await deviceDiscoveryService.sendSyncRequest(syncRequest, to: device)
            await processDeviceSyncResponse(response, from: device)
        } catch {
            print("Failed to sync health data with device \(device.name): \(error)")
        }
    }
    
    private func syncSessionDataWithDevice(_ device: NearbyDevice) async {
        // Direct device-to-device session data sync
        let syncRequest = DeviceSyncRequest(
            deviceId: device.identifier,
            dataType: .sessionData,
            timestamp: Date()
        )
        
        do {
            let response = try await deviceDiscoveryService.sendSyncRequest(syncRequest, to: device)
            await processDeviceSyncResponse(response, from: device)
        } catch {
            print("Failed to sync session data with device \(device.name): \(error)")
        }
    }
    
    private func establishRealTimeSyncWithDevice(_ device: NearbyDevice) async {
        // Establish real-time sync connection for live activities
        await deviceDiscoveryService.establishRealTimeConnection(with: device)
    }
    
    // MARK: - Data Processing
    
    private func processIncomingHealthData(_ items: [HealthDataSyncItem]) async {
        for item in items {
            // Check for conflicts
            if let conflict = await detectHealthDataConflict(item) {
                syncConflicts.append(conflict)
            } else {
                await applyHealthDataUpdate(item)
            }
        }
    }
    
    private func processIncomingUserPreferences(_ items: [UserPreferencesSyncItem]) async {
        for item in items {
            if let conflict = await detectUserPreferencesConflict(item) {
                syncConflicts.append(conflict)
            } else {
                await applyUserPreferencesUpdate(item)
            }
        }
    }
    
    private func processIncomingSessionData(_ items: [SessionDataSyncItem]) async {
        for item in items {
            if let conflict = await detectSessionDataConflict(item) {
                syncConflicts.append(conflict)
            } else {
                await applySessionDataUpdate(item)
            }
        }
    }
    
    private func processIncomingInsights(_ items: [InsightsSyncItem]) async {
        for item in items {
            // Insights typically don't have conflicts as they're derived data
            await applyInsightsUpdate(item)
        }
    }
    
    private func processDeviceSyncResponse(_ response: DeviceSyncResponse, from device: NearbyDevice) async {
        switch response.dataType {
        case .healthData:
            if let healthItems = response.data as? [HealthDataSyncItem] {
                await processIncomingHealthData(healthItems)
            }
            
        case .sessionData:
            if let sessionItems = response.data as? [SessionDataSyncItem] {
                await processIncomingSessionData(sessionItems)
            }
            
        case .userPreferences:
            if let preferencesItems = response.data as? [UserPreferencesSyncItem] {
                await processIncomingUserPreferences(preferencesItems)
            }
            
        case .insights:
            if let insightItems = response.data as? [InsightsSyncItem] {
                await processIncomingInsights(insightItems)
            }
        }
    }
    
    // MARK: - Conflict Detection & Resolution
    
    private func detectHealthDataConflict(_ item: HealthDataSyncItem) async -> SyncConflict? {
        // Check if local data conflicts with incoming data
        if let localItem = await getLocalHealthDataItem(for: item.id) {
            if localItem.modificationDate > item.modificationDate && localItem.data != item.data {
                return SyncConflict(
                    id: UUID(),
                    type: .healthData,
                    localItem: localItem,
                    remoteItem: item,
                    conflictReason: .simultaneousModification
                )
            }
        }
        return nil
    }
    
    private func detectUserPreferencesConflict(_ item: UserPreferencesSyncItem) async -> SyncConflict? {
        if let localItem = await getLocalUserPreferencesItem(for: item.id) {
            if localItem.modificationDate > item.modificationDate && localItem.preferences != item.preferences {
                return SyncConflict(
                    id: UUID(),
                    type: .userPreferences,
                    localItem: localItem,
                    remoteItem: item,
                    conflictReason: .simultaneousModification
                )
            }
        }
        return nil
    }
    
    private func detectSessionDataConflict(_ item: SessionDataSyncItem) async -> SyncConflict? {
        if let localItem = await getLocalSessionDataItem(for: item.id) {
            if localItem.modificationDate > item.modificationDate && localItem.sessionData != item.sessionData {
                return SyncConflict(
                    id: UUID(),
                    type: .sessionData,
                    localItem: localItem,
                    remoteItem: item,
                    conflictReason: .simultaneousModification
                )
            }
        }
        return nil
    }
    
    private func resolveAnyPendingConflicts() async {
        for conflict in syncConflicts {
            let resolution = await conflictResolver.resolve(conflict)
            await applyConflictResolution(resolution)
        }
        
        syncConflicts.removeAll()
    }
    
    private func applyConflictResolution(_ resolution: ConflictResolution) async {
        switch resolution.strategy {
        case .useLocal:
            // Keep local version, update cloud
            await syncResolvedItem(resolution.resolvedItem)
            
        case .useRemote:
            // Use remote version, update local
            await applyResolvedUpdate(resolution.resolvedItem)
            
        case .merge:
            // Apply merged version to both local and cloud
            await applyResolvedUpdate(resolution.resolvedItem)
            await syncResolvedItem(resolution.resolvedItem)
            
        case .manual:
            // Escalate to user for manual resolution
            // Would present UI for user to choose
            break
        }
    }
    
    // MARK: - Data Application
    
    private func applyHealthDataUpdate(_ item: HealthDataSyncItem) async {
        // Apply health data update to local storage
        NotificationCenter.default.post(
            name: .healthDataSyncUpdate,
            object: nil,
            userInfo: ["item": item]
        )
    }
    
    private func applyUserPreferencesUpdate(_ item: UserPreferencesSyncItem) async {
        // Apply user preferences update to local storage
        NotificationCenter.default.post(
            name: .userPreferencesSyncUpdate,
            object: nil,
            userInfo: ["item": item]
        )
    }
    
    private func applySessionDataUpdate(_ item: SessionDataSyncItem) async {
        // Apply session data update to local storage
        NotificationCenter.default.post(
            name: .sessionDataSyncUpdate,
            object: nil,
            userInfo: ["item": item]
        )
    }
    
    private func applyInsightsUpdate(_ item: InsightsSyncItem) async {
        // Apply insights update to local storage
        NotificationCenter.default.post(
            name: .insightsSyncUpdate,
            object: nil,
            userInfo: ["item": item]
        )
    }
    
    private func applyResolvedUpdate(_ item: Any) async {
        // Apply resolved conflict update
    }
    
    private func syncResolvedItem(_ item: Any) async {
        // Sync resolved item back to cloud
    }
    
    // MARK: - Record Parsing
    
    private func parseHealthDataRecord(_ record: CKRecord) -> HealthDataSyncItem? {
        guard let encryptedData = record["encryptedData"] as? Data,
              let deviceId = record["deviceId"] as? String,
              let dataType = record["dataType"] as? String else {
            return nil
        }
        
        return HealthDataSyncItem(
            id: record.recordID.recordName,
            deviceId: deviceId,
            dataType: dataType,
            encryptedData: encryptedData,
            creationDate: record.creationDate ?? Date(),
            modificationDate: record.modificationDate ?? Date(),
            priority: .normal
        )
    }
    
    private func parseUserPreferencesRecord(_ record: CKRecord) -> UserPreferencesSyncItem? {
        guard let encryptedPreferences = record["encryptedPreferences"] as? Data,
              let deviceId = record["deviceId"] as? String else {
            return nil
        }
        
        return UserPreferencesSyncItem(
            id: record.recordID.recordName,
            deviceId: deviceId,
            encryptedPreferences: encryptedPreferences,
            creationDate: record.creationDate ?? Date(),
            modificationDate: record.modificationDate ?? Date()
        )
    }
    
    private func parseSessionDataRecord(_ record: CKRecord) -> SessionDataSyncItem? {
        guard let encryptedSessionData = record["encryptedSessionData"] as? Data,
              let deviceId = record["deviceId"] as? String,
              let sessionType = record["sessionType"] as? String else {
            return nil
        }
        
        return SessionDataSyncItem(
            id: record.recordID.recordName,
            deviceId: deviceId,
            sessionType: sessionType,
            encryptedSessionData: encryptedSessionData,
            creationDate: record.creationDate ?? Date(),
            modificationDate: record.modificationDate ?? Date()
        )
    }
    
    private func parseInsightsRecord(_ record: CKRecord) -> InsightsSyncItem? {
        guard let encryptedInsights = record["encryptedInsights"] as? Data,
              let deviceId = record["deviceId"] as? String,
              let insightType = record["insightType"] as? String else {
            return nil
        }
        
        return InsightsSyncItem(
            id: record.recordID.recordName,
            deviceId: deviceId,
            insightType: insightType,
            encryptedInsights: encryptedInsights,
            creationDate: record.creationDate ?? Date(),
            modificationDate: record.modificationDate ?? Date()
        )
    }
    
    // MARK: - Utility Methods
    
    private func updateSyncStatus(_ status: SyncStatus) async {
        DispatchQueue.main.async {
            self.syncStatus = status
        }
    }
    
    private func updatePendingCount() {
        let totalPending = pendingHealthData.count + pendingUserPreferences.count + pendingSessionData.count + pendingInsights.count
        
        DispatchQueue.main.async {
            self.pendingSyncItems = totalPending
        }
    }
    
    // MARK: - Data Retrieval (Placeholders)
    
    private func getLocalHealthDataItem(for id: String) async -> HealthDataSyncItem? {
        // Retrieve local health data item
        return nil
    }
    
    private func getLocalUserPreferencesItem(for id: String) async -> UserPreferencesSyncItem? {
        // Retrieve local user preferences item
        return nil
    }
    
    private func getLocalSessionDataItem(for id: String) async -> SessionDataSyncItem? {
        // Retrieve local session data item
        return nil
    }
    
    // MARK: - Public Interface
    
    func queueHealthDataForSync(_ data: Any, priority: SyncPriority = .normal) {
        // Convert data to sync item and queue
        // Implementation would depend on data format
    }
    
    func queueUserPreferencesForSync(_ preferences: Any) {
        // Convert preferences to sync item and queue
    }
    
    func queueSessionDataForSync(_ sessionData: Any) {
        // Convert session data to sync item and queue
    }
    
    func queueInsightsForSync(_ insights: Any) {
        // Convert insights to sync item and queue
    }
    
    func forceSyncNow() async {
        await performPeriodicSync()
    }
    
    func resolveSyncConflict(_ conflictId: UUID, resolution: ConflictResolutionStrategy) async {
        guard let conflict = syncConflicts.first(where: { $0.id == conflictId }) else { return }
        
        let resolution = ConflictResolution(
            conflictId: conflictId,
            strategy: resolution,
            resolvedItem: conflict.localItem // Or merge logic
        )
        
        await applyConflictResolution(resolution)
        syncConflicts.removeAll { $0.id == conflictId }
    }
    
    func pauseSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func resumeSync() {
        startSyncCoordination()
    }
    
    // MARK: - Cleanup
    
    deinit {
        syncTimer?.invalidate()
        networkMonitor.cancel()
        deviceDiscoveryService.stopDiscovery()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

public enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case offline
    case error(String)
    
    public static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.completed, .completed), (.offline, .offline):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

enum NetworkStatus {
    case wifi
    case cellular
    case offline
    case unknown
}

public enum SyncPriority {
    case critical
    case high
    case normal
    case low
}

public enum SyncDataType {
    case healthData
    case userPreferences
    case sessionData
    case insights
}

public enum ConflictReason {
    case simultaneousModification
    case versionMismatch
    case dataCorruption
    case deviceTimeDrift
}

public enum ConflictResolutionStrategy {
    case useLocal
    case useRemote
    case merge
    case manual
}

struct ConnectedDevice: Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    let isNearby: Bool
    let lastSeen: Date
    let capabilities: Set<DeviceCapability>
}

enum DeviceType {
    case iPhone
    case iPad
    case appleWatch
    case appleTV
    case mac
    case unknown
}

enum DeviceCapability {
    case healthDataSync
    case sessionDataSync
    case realTimeSync
    case biometricData
    case mediaSync
}

struct NearbyDevice {
    let identifier: String
    let name: String
    let deviceType: DeviceType
    let capabilities: Set<DeviceCapability>
}

public struct SyncConflict: Identifiable {
    public let id: UUID
    public let type: SyncDataType
    public let localItem: Any
    public let remoteItem: Any
    public let conflictReason: ConflictReason
}

struct ConflictResolution {
    let conflictId: UUID
    let strategy: ConflictResolutionStrategy
    let resolvedItem: Any
}

// MARK: - Sync Items

protocol SyncItem {
    var id: String { get }
    var deviceId: String { get }
    var creationDate: Date { get }
    var modificationDate: Date { get }
}

public struct HealthDataSyncItem: SyncItem {
    public let id: String
    public let deviceId: String
    public let dataType: String
    public let encryptedData: Data
    public let creationDate: Date
    public let modificationDate: Date
    public let priority: SyncPriority
    
    // Computed properties for conflict detection
    public var data: Data { encryptedData }
}

struct UserPreferencesSyncItem: SyncItem {
    let id: String
    let deviceId: String
    let encryptedPreferences: Data
    let creationDate: Date
    let modificationDate: Date
    
    var preferences: Data { encryptedPreferences }
}

struct SessionDataSyncItem: SyncItem {
    let id: String
    let deviceId: String
    let sessionType: String
    let encryptedSessionData: Data
    let creationDate: Date
    let modificationDate: Date
    
    var sessionData: Data { encryptedSessionData }
}

struct InsightsSyncItem: SyncItem {
    let id: String
    let deviceId: String
    let insightType: String
    let encryptedInsights: Data
    let creationDate: Date
    let modificationDate: Date
}

// MARK: - Device Communication

struct DeviceSyncRequest {
    let deviceId: String
    let dataType: SyncDataType
    let timestamp: Date
}

struct DeviceSyncResponse {
    let deviceId: String
    let dataType: SyncDataType
    let data: Any
    let timestamp: Date
}

// MARK: - Supporting Services

class SyncCoordinator {
    func coordinateSync() async {
        // Coordinate sync operations across devices
    }
}

class ConflictResolver {
    func resolve(_ conflict: SyncConflict) async -> ConflictResolution {
        // Implement conflict resolution logic
        // For now, default to using remote version
        return ConflictResolution(
            conflictId: conflict.id,
            strategy: .useRemote,
            resolvedItem: conflict.remoteItem
        )
    }
}

class DataTransformer {
    func transform(_ data: Any, for device: DeviceType) -> Any {
        // Transform data for device-specific formats
        return data
    }
}

class SyncEncryptionManager {
    func encrypt(_ data: Data) -> Data {
        // Encrypt data for sync
        return data // Placeholder
    }
    
    func decrypt(_ data: Data) -> Data? {
        // Decrypt data from sync
        return data // Placeholder
    }
}

class DeviceDiscoveryService: ObservableObject {
    @Published var discoveredDevices: [NearbyDevice] = []
    
    lazy var discoveredDevicesPublisher: AnyPublisher<[NearbyDevice], Never> = {
        $discoveredDevices.eraseToAnyPublisher()
    }()
    
    func startDiscovery() {
        // Start device discovery using Bonjour/Multipeer Connectivity
        // Simulate discovering devices
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.simulateDeviceDiscovery()
        }
    }
    
    func stopDiscovery() {
        // Stop device discovery
    }
    
    func sendSyncRequest(_ request: DeviceSyncRequest, to device: NearbyDevice) async throws -> DeviceSyncResponse {
        // Send sync request to nearby device
        // Return mock response for now
        return DeviceSyncResponse(
            deviceId: device.identifier,
            dataType: request.dataType,
            data: [],
            timestamp: Date()
        )
    }
    
    func establishRealTimeConnection(with device: NearbyDevice) async {
        // Establish real-time connection for live sync
    }
    
    private func simulateDeviceDiscovery() {
        let mockDevices = [
            NearbyDevice(
                identifier: "iphone-1",
                name: "John's iPhone",
                deviceType: .iPhone,
                capabilities: [.healthDataSync, .sessionDataSync, .realTimeSync, .biometricData]
            ),
            NearbyDevice(
                identifier: "ipad-1",
                name: "Living Room iPad",
                deviceType: .iPad,
                capabilities: [.sessionDataSync, .mediaSync]
            ),
            NearbyDevice(
                identifier: "watch-1",
                name: "Apple Watch",
                deviceType: .appleWatch,
                capabilities: [.healthDataSync, .biometricData, .realTimeSync]
            )
        ]
        
        discoveredDevices = mockDevices
    }
}

// MARK: - Sync Operations

class HealthDataSyncOperation: Operation {
    let pendingItems: [HealthDataSyncItem]
    let database: CKDatabase
    let encryptionManager: SyncEncryptionManager
    
    lazy var completionPublisher = PassthroughSubject<Result<Int, Error>, Never>()
    
    init(pendingItems: [HealthDataSyncItem], database: CKDatabase, encryptionManager: SyncEncryptionManager) {
        self.pendingItems = pendingItems
        self.database = database
        self.encryptionManager = encryptionManager
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        Task {
            do {
                let syncedCount = try await syncHealthData()
                completionPublisher.send(.success(syncedCount))
            } catch {
                completionPublisher.send(.failure(error))
            }
        }
    }
    
    private func syncHealthData() async throws -> Int {
        var syncedCount = 0
        
        for item in pendingItems {
            guard !isCancelled else { break }
            
            let record = CKRecord(recordType: "HealthData", recordID: CKRecord.ID(recordName: item.id))
            record["deviceId"] = item.deviceId
            record["dataType"] = item.dataType
            record["encryptedData"] = item.encryptedData
            record["creationDate"] = item.creationDate
            record["modificationDate"] = item.modificationDate
            
            do {
                _ = try await database.save(record)
                syncedCount += 1
            } catch {
                print("Failed to sync health data item \(item.id): \(error)")
            }
        }
        
        return syncedCount
    }
}

class UserPreferencesSyncOperation: Operation {
    let pendingItems: [UserPreferencesSyncItem]
    let database: CKDatabase
    let encryptionManager: SyncEncryptionManager
    
    lazy var completionPublisher = PassthroughSubject<Result<Int, Error>, Never>()
    
    init(pendingItems: [UserPreferencesSyncItem], database: CKDatabase, encryptionManager: SyncEncryptionManager) {
        self.pendingItems = pendingItems
        self.database = database
        self.encryptionManager = encryptionManager
        super.init()
    }
    
    override func main() {
        Task {
            do {
                let syncedCount = try await syncUserPreferences()
                completionPublisher.send(.success(syncedCount))
            } catch {
                completionPublisher.send(.failure(error))
            }
        }
    }
    
    private func syncUserPreferences() async throws -> Int {
        var syncedCount = 0
        
        for item in pendingItems {
            guard !isCancelled else { break }
            
            let record = CKRecord(recordType: "UserPreferences", recordID: CKRecord.ID(recordName: item.id))
            record["deviceId"] = item.deviceId
            record["encryptedPreferences"] = item.encryptedPreferences
            record["creationDate"] = item.creationDate
            record["modificationDate"] = item.modificationDate
            
            do {
                _ = try await database.save(record)
                syncedCount += 1
            } catch {
                print("Failed to sync user preferences item \(item.id): \(error)")
            }
        }
        
        return syncedCount
    }
}

class SessionDataSyncOperation: Operation {
    let pendingItems: [SessionDataSyncItem]
    let database: CKDatabase
    let encryptionManager: SyncEncryptionManager
    
    lazy var completionPublisher = PassthroughSubject<Result<Int, Error>, Never>()
    
    init(pendingItems: [SessionDataSyncItem], database: CKDatabase, encryptionManager: SyncEncryptionManager) {
        self.pendingItems = pendingItems
        self.database = database
        self.encryptionManager = encryptionManager
        super.init()
    }
    
    override func main() {
        Task {
            do {
                let syncedCount = try await syncSessionData()
                completionPublisher.send(.success(syncedCount))
            } catch {
                completionPublisher.send(.failure(error))
            }
        }
    }
    
    private func syncSessionData() async throws -> Int {
        var syncedCount = 0
        
        for item in pendingItems {
            guard !isCancelled else { break }
            
            let record = CKRecord(recordType: "SessionData", recordID: CKRecord.ID(recordName: item.id))
            record["deviceId"] = item.deviceId
            record["sessionType"] = item.sessionType
            record["encryptedSessionData"] = item.encryptedSessionData
            record["creationDate"] = item.creationDate
            record["modificationDate"] = item.modificationDate
            
            do {
                _ = try await database.save(record)
                syncedCount += 1
            } catch {
                print("Failed to sync session data item \(item.id): \(error)")
            }
        }
        
        return syncedCount
    }
}

class InsightsSyncOperation: Operation {
    let pendingItems: [InsightsSyncItem]
    let database: CKDatabase
    let encryptionManager: SyncEncryptionManager
    
    lazy var completionPublisher = PassthroughSubject<Result<Int, Error>, Never>()
    
    init(pendingItems: [InsightsSyncItem], database: CKDatabase, encryptionManager: SyncEncryptionManager) {
        self.pendingItems = pendingItems
        self.database = database
        self.encryptionManager = encryptionManager
        super.init()
    }
    
    override func main() {
        Task {
            do {
                let syncedCount = try await syncInsights()
                completionPublisher.send(.success(syncedCount))
            } catch {
                completionPublisher.send(.failure(error))
            }
        }
    }
    
    private func syncInsights() async throws -> Int {
        var syncedCount = 0
        
        for item in pendingItems {
            guard !isCancelled else { break }
            
            let record = CKRecord(recordType: "HealthInsights", recordID: CKRecord.ID(recordName: item.id))
            record["deviceId"] = item.deviceId
            record["insightType"] = item.insightType
            record["encryptedInsights"] = item.encryptedInsights
            record["creationDate"] = item.creationDate
            record["modificationDate"] = item.modificationDate
            
            do {
                _ = try await database.save(record)
                syncedCount += 1
            } catch {
                print("Failed to sync insights item \(item.id): \(error)")
            }
        }
        
        return syncedCount
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let healthDataSyncUpdate = Notification.Name("healthDataSyncUpdate")
    static let userPreferencesSyncUpdate = Notification.Name("userPreferencesSyncUpdate")
    static let sessionDataSyncUpdate = Notification.Name("sessionDataSyncUpdate")
    static let insightsSyncUpdate = Notification.Name("insightsSyncUpdate")
}

// MARK: - SwiftUI Views

@available(tvOS 18.0, *)
struct CrossDeviceSyncView: View {
    @StateObject private var syncManager = CrossDeviceSyncManager()
    @State private var showingConflictResolution = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("Cross-Device Sync")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Seamless health data synchronization across all your Apple devices")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Sync Status
                        SyncStatusSection(syncManager: syncManager)
                        
                        // Connected Devices
                        ConnectedDevicesSection(syncManager: syncManager)
                        
                        // Sync Progress
                        SyncProgressSection(syncManager: syncManager)
                        
                        // Network Status
                        NetworkStatusSection(syncManager: syncManager)
                        
                        // Conflicts (if any)
                        if !syncManager.syncConflicts.isEmpty {
                            ConflictResolutionSection(syncManager: syncManager)
                        }
                    }
                }
                
                // Sync Controls
                HStack(spacing: 20) {
                    Button("Sync Now") {
                        Task {
                            await syncManager.forceSyncNow()
                        }
                    }
                    .buttonStyle(SyncButtonStyle(color: .blue))
                    
                    Button(syncManager.syncStatus == .syncing ? "Pause" : "Resume") {
                        if syncManager.syncStatus == .syncing {
                            syncManager.pauseSync()
                        } else {
                            syncManager.resumeSync()
                        }
                    }
                    .buttonStyle(SyncButtonStyle(color: .gray))
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingConflictResolution) {
            ConflictResolutionView(syncManager: syncManager)
        }
    }
}

struct SyncStatusSection: View {
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sync Status")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: syncStatusIcon)
                    .foregroundColor(syncStatusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(syncStatusText)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let lastSync = syncManager.lastSyncTime {
                        Text("Last sync: \(formatDate(lastSync))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Never synced")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if syncManager.pendingSyncItems > 0 {
                    VStack {
                        Text("\(syncManager.pendingSyncItems)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Pending")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var syncStatusIcon: String {
        switch syncManager.syncStatus {
        case .idle: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .offline: return "wifi.slash"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncManager.syncStatus {
        case .idle: return .gray
        case .syncing: return .blue
        case .completed: return .green
        case .offline: return .orange
        case .error: return .red
        }
    }
    
    private var syncStatusText: String {
        switch syncManager.syncStatus {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .completed: return "Up to date"
        case .offline: return "Offline"
        case .error(let message): return "Error: \(message)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ConnectedDevicesSection: View {
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Connected Devices (\(syncManager.connectedDevices.count))")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if syncManager.connectedDevices.isEmpty {
                Text("No devices found nearby")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(syncManager.connectedDevices) { device in
                        DeviceCard(device: device)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct DeviceCard: View {
    let device: ConnectedDevice
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: deviceIcon)
                    .foregroundColor(device.isNearby ? .green : .gray)
                    .font(.title2)
                
                Spacer()
                
                Circle()
                    .fill(device.isNearby ? .green : .gray)
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(device.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(device.type.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Last seen: \(formatTime(device.lastSeen))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Capabilities
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(device.capabilities), id: \.self) { capability in
                        Text(capability.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var deviceIcon: String {
        switch device.type {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .appleWatch: return "applewatch"
        case .appleTV: return "appletv"
        case .mac: return "desktopcomputer"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SyncProgressSection: View {
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sync Progress")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if syncManager.syncStatus == .syncing {
                VStack(spacing: 10) {
                    ProgressView(value: syncManager.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("\(Int(syncManager.syncProgress * 100))% Complete")
                        .font(.body)
                        .foregroundColor(.white)
                }
            } else {
                Text("No sync in progress")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct NetworkStatusSection: View {
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Network Status")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: networkIcon)
                    .foregroundColor(networkColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(networkStatusText)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(networkDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var networkIcon: String {
        switch syncManager.networkStatus {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .offline: return "wifi.slash"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private var networkColor: Color {
        switch syncManager.networkStatus {
        case .wifi: return .green
        case .cellular: return .orange
        case .offline: return .red
        case .unknown: return .gray
        }
    }
    
    private var networkStatusText: String {
        switch syncManager.networkStatus {
        case .wifi: return "Wi-Fi Connected"
        case .cellular: return "Cellular Connected"
        case .offline: return "Offline"
        case .unknown: return "Unknown"
        }
    }
    
    private var networkDescription: String {
        switch syncManager.networkStatus {
        case .wifi: return "Full sync capability available"
        case .cellular: return "Limited sync to conserve data"
        case .offline: return "Sync will resume when connected"
        case .unknown: return "Checking network status..."
        }
    }
}

struct ConflictResolutionSection: View {
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Sync Conflicts (\(syncManager.syncConflicts.count))")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
            }
            
            Text("Some data conflicts require your attention")
                .font(.body)
                .foregroundColor(.gray)
            
            Button("Resolve Conflicts") {
                // Show conflict resolution UI
            }
            .buttonStyle(SyncButtonStyle(color: .orange))
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ConflictResolutionView: View {
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Resolve Sync Conflicts")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Choose how to resolve data conflicts between devices")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            ForEach(syncManager.syncConflicts) { conflict in
                ConflictCard(conflict: conflict, syncManager: syncManager)
            }
            
            Spacer()
            
            Button("Close") {
                // Dismiss view
            }
            .buttonStyle(SyncButtonStyle(color: .gray))
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

struct ConflictCard: View {
    let conflict: SyncConflict
    @ObservedObject var syncManager: CrossDeviceSyncManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Data Conflict")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(conflict.type.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text("This data was modified on multiple devices simultaneously.")
                .font(.body)
                .foregroundColor(.gray)
            
            HStack(spacing: 15) {
                Button("Use Local") {
                    Task {
                        await syncManager.resolveSyncConflict(conflict.id, resolution: .useLocal)
                    }
                }
                .buttonStyle(ConflictButtonStyle(color: .blue))
                
                Button("Use Remote") {
                    Task {
                        await syncManager.resolveSyncConflict(conflict.id, resolution: .useRemote)
                    }
                }
                .buttonStyle(ConflictButtonStyle(color: .green))
                
                Button("Merge") {
                    Task {
                        await syncManager.resolveSyncConflict(conflict.id, resolution: .merge)
                    }
                }
                .buttonStyle(ConflictButtonStyle(color: .purple))
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SyncButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.semibold)
            .frame(width: 200, height: 50)
            .background(color)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ConflictButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.body)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension DeviceType {
    var displayName: String {
        switch self {
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .appleWatch: return "Apple Watch"
        case .appleTV: return "Apple TV"
        case .mac: return "Mac"
        case .unknown: return "Unknown Device"
        }
    }
}

extension DeviceCapability {
    var displayName: String {
        switch self {
        case .healthDataSync: return "Health"
        case .sessionDataSync: return "Sessions"
        case .realTimeSync: return "Real-time"
        case .biometricData: return "Biometrics"
        case .mediaSync: return "Media"
        }
    }
}

extension SyncDataType {
    var displayName: String {
        switch self {
        case .healthData: return "Health Data"
        case .userPreferences: return "Preferences"
        case .sessionData: return "Session Data"
        case .insights: return "Insights"
        }
    }
}

#Preview {
    CrossDeviceSyncView()
}

#if os(iOS) || os(watchOS) || os(tvOS)
extension CrossDeviceSyncManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        isReachable = session.isReachable
        if isReachable, !pendingData.isEmpty {
            Task {
                do {
                    let success = try await sendHealthData(pendingData)
                    if success {
                        pendingData = [:]
                    }
                } catch {
                    print("Error sending pending data: \(error)")
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle received data
        pendingData = message
        print("Received data from paired device: \(message)")
    }
}
#endif