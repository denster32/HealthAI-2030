import Foundation
import CloudKit
import SwiftData
import Combine
import OSLog
import Utilities

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class UnifiedCloudKitSyncManager: ObservableObject {
    public static let shared = UnifiedCloudKitSyncManager()
    
    // MARK: - Properties
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var lastSyncDate: Date?
    @Published public var pendingSyncCount: Int = 0
    @Published public var errorMessage: String?
    @Published public var isNetworkAvailable: Bool = true
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private let logger = Logger(subsystem: "com.HealthAI2030.Sync", category: "CloudKit")
    private let qaLogger = SyncQALogger.shared
    
    // Background processing
    private let syncQueue = DispatchQueue(label: "com.healthai2030.sync", qos: .utility)
    private let conflictResolutionQueue = DispatchQueue(label: "com.healthai2030.conflict-resolution", qos: .userInitiated)
    
    // Sync coordination
    private var syncTimer: Timer?
    private var backgroundSyncToken: CKServerChangeToken?
    private var subscriptionIDs: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    
    // Rate limiting
    private var lastSyncAttempt: Date = Date.distantPast
    private let minimumSyncInterval: TimeInterval = 30 // 30 seconds
    private var retryAttempts: Int = 0
    private let maxRetryAttempts: Int = 3
    
    // MARK: - Initialization
    
    private init() {
        let containerIdentifier = "iCloud.com.healthai2030.HealthAI2030"
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        
        setupNotifications()
        setupBackgroundSync()
        checkCloudKitAvailability()
    }
    
    // MARK: - Public Interface
    
    public func startSync() async {
        guard syncStatus != .syncing else {
            logger.info("Sync already in progress")
            return
        }
        
        guard Date().timeIntervalSince(lastSyncAttempt) >= minimumSyncInterval else {
            logger.info("Sync rate limited")
            return
        }
        
        await performFullSync()
    }
    
    public func syncRecord<T: CKSyncable>(_ record: T, modelContext: ModelContext) async throws {
        guard let ckRecord = createCKRecord(from: record) else {
            throw SyncError.invalidRecord
        }
        
        do {
            let savedRecord = try await privateDatabase.save(ckRecord)
            await updateLocalRecord(record, with: savedRecord, modelContext: modelContext)
            logger.info("Successfully synced individual record: \(record.id)")
        } catch {
            logger.error("Failed to sync individual record: \(error.localizedDescription)")
            throw SyncError.cloudKitError(error)
        }
    }
    
    public func requestExport(type: ExportType, dateRange: DateInterval, deviceSource: String, modelContext: ModelContext) async throws {
        let dateRangeData = try JSONEncoder().encode(dateRange)
        let exportRequest = ExportRequest(
            requestedBy: deviceSource,
            exportType: type.rawValue,
            dateRange: dateRangeData
        )
        
        modelContext.insert(exportRequest)
        try modelContext.save()
        
        try await syncRecord(exportRequest, modelContext: modelContext)
        logger.info("Export request created: \(type.rawValue)")
    }
    
    // MARK: - Sync Operations
    
    private func performFullSync() async {
        syncStatus = .syncing
        lastSyncAttempt = Date()
        let startTime = Date()
        
        qaLogger.logSyncStart(recordType: "All", recordCount: pendingSyncCount, deviceSource: getCurrentDeviceSource())
        
        do {
            // Check CloudKit availability
            let accountStatus = try await container.accountStatus()
            guard accountStatus == .available else {
                throw SyncError.accountUnavailable(accountStatus)
            }
            
            qaLogger.logCloudKitEvent(operation: "accountStatus", recordType: "Account", success: true)
            
            // Perform bidirectional sync
            try await performPushSync()
            try await performPullSync()
            
            // Update sync metadata
            lastSyncDate = Date()
            retryAttempts = 0
            syncStatus = .completed
            
            let duration = Date().timeIntervalSince(startTime)
            qaLogger.logSyncSuccess(recordType: "All", recordCount: pendingSyncCount, duration: duration)
            logger.info("Full sync completed successfully")
            
        } catch {
            qaLogger.logSyncError(recordType: "All", error: error)
            handleSyncError(error)
        }
    }
    
    private func performPushSync() async throws {
        logger.info("Starting push sync")
        
        // Get SwiftData context
        guard let modelContext = try? ModelContext(ModelContainer.shared) else {
            throw SyncError.dataContextUnavailable
        }
        
        // Push health data entries
        try await pushHealthDataEntries(modelContext: modelContext)
        
        // Push sleep session entries
        try await pushSleepSessionEntries(modelContext: modelContext)
        
        // Push analytics insights
        try await pushAnalyticsInsights(modelContext: modelContext)
        
        // Push ML model updates
        try await pushMLModelUpdates(modelContext: modelContext)
        
        // Push export requests
        try await pushExportRequests(modelContext: modelContext)
        
        logger.info("Push sync completed")
    }
    
    private func performPullSync() async throws {
        logger.info("Starting pull sync")
        
        // Get SwiftData context
        guard let modelContext = try? ModelContext(ModelContainer.shared) else {
            throw SyncError.dataContextUnavailable
        }
        
        // Pull and process each record type
        try await pullAndProcessRecords(recordType: "HealthDataEntry", modelContext: modelContext) { record in
            return SyncableHealthDataEntry(from: record)
        }
        
        try await pullAndProcessRecords(recordType: "SleepSessionEntry", modelContext: modelContext) { record in
            return SyncableSleepSessionEntry(from: record)
        }
        
        try await pullAndProcessRecords(recordType: "AnalyticsInsight", modelContext: modelContext) { record in
            return AnalyticsInsight(from: record)
        }
        
        try await pullAndProcessRecords(recordType: "MLModelUpdate", modelContext: modelContext) { record in
            return MLModelUpdate(from: record)
        }
        
        try await pullAndProcessRecords(recordType: "ExportRequest", modelContext: modelContext) { record in
            return ExportRequest(from: record)
        }
        
        logger.info("Pull sync completed")
    }
    
    // MARK: - Push Operations
    
    private func pushHealthDataEntries(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<SyncableHealthDataEntry>(
            predicate: #Predicate { $0.needsSync == true }
        )
        
        let entries = try modelContext.fetch(descriptor)
        
        for entry in entries {
            let ckRecord = entry.ckRecord
            do {
                let savedRecord = try await privateDatabase.save(ckRecord)
                entry.lastSyncDate = Date()
                entry.needsSync = false
                entry.syncVersion = savedRecord["syncVersion"] as? Int ?? entry.syncVersion
            } catch {
                logger.error("Failed to push health data entry: \(error.localizedDescription)")
                // Continue with other entries
            }
        }
        
        try modelContext.save()
    }
    
    private func pushSleepSessionEntries(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<SyncableSleepSessionEntry>(
            predicate: #Predicate { $0.needsSync == true }
        )
        
        let entries = try modelContext.fetch(descriptor)
        
        for entry in entries {
            let ckRecord = entry.ckRecord
            do {
                let savedRecord = try await privateDatabase.save(ckRecord)
                entry.lastSyncDate = Date()
                entry.needsSync = false
                entry.syncVersion = savedRecord["syncVersion"] as? Int ?? entry.syncVersion
            } catch {
                logger.error("Failed to push sleep session entry: \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
    }
    
    private func pushAnalyticsInsights(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<AnalyticsInsight>(
            predicate: #Predicate { $0.needsSync == true }
        )
        
        let insights = try modelContext.fetch(descriptor)
        
        for insight in insights {
            let ckRecord = insight.ckRecord
            do {
                let savedRecord = try await privateDatabase.save(ckRecord)
                insight.lastSyncDate = Date()
                insight.needsSync = false
                insight.syncVersion = savedRecord["syncVersion"] as? Int ?? insight.syncVersion
            } catch {
                logger.error("Failed to push analytics insight: \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
    }
    
    private func pushMLModelUpdates(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<MLModelUpdate>(
            predicate: #Predicate { $0.needsSync == true }
        )
        
        let updates = try modelContext.fetch(descriptor)
        
        for update in updates {
            let ckRecord = update.ckRecord
            do {
                let savedRecord = try await privateDatabase.save(ckRecord)
                update.lastSyncDate = Date()
                update.needsSync = false
                update.syncVersion = savedRecord["syncVersion"] as? Int ?? update.syncVersion
            } catch {
                logger.error("Failed to push ML model update: \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
    }
    
    private func pushExportRequests(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<ExportRequest>(
            predicate: #Predicate { $0.needsSync == true }
        )
        
        let requests = try modelContext.fetch(descriptor)
        
        for request in requests {
            let ckRecord = request.ckRecord
            do {
                let savedRecord = try await privateDatabase.save(ckRecord)
                request.lastSyncDate = Date()
                request.needsSync = false
                request.syncVersion = savedRecord["syncVersion"] as? Int ?? request.syncVersion
            } catch {
                logger.error("Failed to push export request: \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Pull Operations
    
    private func pullAndProcessRecords<T: CKSyncable>(
        recordType: String,
        modelContext: ModelContext,
        createModel: (CKRecord) -> T?
    ) async throws {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let model = createModel(record) {
                    await processIncomingRecord(model, record: record, modelContext: modelContext)
                }
            case .failure(let error):
                logger.error("Failed to fetch record: \(error.localizedDescription)")
            }
        }
    }
    
    private func processIncomingRecord<T: CKSyncable>(_ model: T, record: CKRecord, modelContext: ModelContext) async {
        // Check if local record exists
        if let existingModel = await findLocalRecord(id: model.id, type: T.self, modelContext: modelContext) {
            // Conflict resolution
            await resolveConflict(local: existingModel, remote: model, record: record, modelContext: modelContext)
        } else {
            // Insert new record
            modelContext.insert(model)
            do {
                try modelContext.save()
                logger.info("Inserted new record from CloudKit: \(model.id)")
            } catch {
                logger.error("Failed to insert new record: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict<T: CKSyncable>(
        local: T,
        remote: T,
        record: CKRecord,
        modelContext: ModelContext
    ) async {
        conflictResolutionQueue.async { [weak self] in
            Task { @MainActor in
                await self?.performConflictResolution(local: local, remote: remote, record: record, modelContext: modelContext)
            }
        }
    }
    
    private func performConflictResolution<T: CKSyncable>(
        local: T,
        remote: T,
        record: CKRecord,
        modelContext: ModelContext
    ) async {
        // Use timestamp-based resolution: most recent wins
        let localTimestamp = local.lastSyncDate ?? Date.distantPast
        let remoteTimestamp = record.modificationDate ?? Date.distantPast
        
        if remoteTimestamp > localTimestamp {
            // Remote wins - update local
            copyRemoteToLocal(from: remote, to: local)
            local.lastSyncDate = Date()
            local.needsSync = false
            
            do {
                try modelContext.save()
                logger.info("Conflict resolved: remote wins for record \(local.id)")
            } catch {
                logger.error("Failed to resolve conflict: \(error.localizedDescription)")
            }
        } else {
            // Local wins - push to remote
            local.needsSync = true
            logger.info("Conflict resolved: local wins for record \(local.id)")
        }
    }
    
    // MARK: - Background Sync
    
    private func setupBackgroundSync() {
        // Setup periodic sync every 15 minutes
        syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performBackgroundSync()
            }
        }
        
        // Setup CloudKit subscriptions
        Task {
            await setupCloudKitSubscriptions()
        }
    }
    
    private func performBackgroundSync() async {
        guard syncStatus == .idle else { return }
        
        logger.info("Performing background sync")
        await performFullSync()
    }
    
    private func setupCloudKitSubscriptions() async {
        let recordTypes = ["HealthDataEntry", "SleepSessionEntry", "AnalyticsInsight", "MLModelUpdate", "ExportRequest"]
        
        for recordType in recordTypes {
            do {
                let subscription = CKQuerySubscription(
                    recordType: recordType,
                    predicate: NSPredicate(value: true),
                    subscriptionID: "\(recordType)Subscription",
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
                )
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                _ = try await privateDatabase.save(subscription)
                subscriptionIDs.insert(subscription.subscriptionID)
                
                logger.info("Created subscription for \(recordType)")
            } catch {
                logger.error("Failed to create subscription for \(recordType): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteNotification),
            name: Notification.Name("CKRemoteNotificationReceived"),
            object: nil
        )
        
        // Network monitoring
        // TODO: Implement proper network monitoring
        isNetworkAvailable = true
    }
    
    @objc private func handleRemoteNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let _ = userInfo["ck"] as? [String: Any] else {
            return
        }
        
        logger.info("Received CloudKit remote notification")
        Task { @MainActor in
            await performFullSync()
        }
    }
    
    // MARK: - Error Handling
    
    private func handleSyncError(_ error: Error) {
        retryAttempts += 1
        syncStatus = .error
        errorMessage = error.localizedDescription
        
        logger.error("Sync error: \(error.localizedDescription)")
        
        // Implement exponential backoff
        if retryAttempts <= maxRetryAttempts {
            let delay = Double(retryAttempts * retryAttempts) * 5.0 // 5, 20, 45 seconds
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.performFullSync()
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func checkCloudKitAvailability() {
        Task {
            do {
                let status = try await container.accountStatus()
                logger.info("CloudKit account status: \(status.rawValue)")
            } catch {
                logger.error("Failed to check CloudKit availability: \(error.localizedDescription)")
            }
        }
    }
    
    private func createCKRecord<T: CKSyncable>(from model: T) -> CKRecord? {
        if let healthData = model as? SyncableHealthDataEntry {
            return healthData.ckRecord
        } else if let sleepSession = model as? SyncableSleepSessionEntry {
            return sleepSession.ckRecord
        } else if let insight = model as? AnalyticsInsight {
            return insight.ckRecord
        } else if let modelUpdate = model as? MLModelUpdate {
            return modelUpdate.ckRecord
        } else if let exportRequest = model as? ExportRequest {
            return exportRequest.ckRecord
        }
        return nil
    }
    
    private func updateLocalRecord<T: CKSyncable>(_ record: T, with ckRecord: CKRecord, modelContext: ModelContext) async {
        record.lastSyncDate = Date()
        record.needsSync = false
        record.syncVersion = ckRecord["syncVersion"] as? Int ?? record.syncVersion
        
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to update local record after sync: \(error.localizedDescription)")
        }
    }
    
    private func findLocalRecord<T: CKSyncable>(id: UUID, type: T.Type, modelContext: ModelContext) async -> T? {
        do {
            if type == SyncableHealthDataEntry.self {
                let descriptor = FetchDescriptor<SyncableHealthDataEntry>(
                    predicate: #Predicate { $0.id == id }
                )
                let results = try modelContext.fetch(descriptor)
                return results.first as? T
            } else if type == SyncableSleepSessionEntry.self {
                let descriptor = FetchDescriptor<SyncableSleepSessionEntry>(
                    predicate: #Predicate { $0.id == id }
                )
                let results = try modelContext.fetch(descriptor)
                return results.first as? T
            } else if type == AnalyticsInsight.self {
                let descriptor = FetchDescriptor<AnalyticsInsight>(
                    predicate: #Predicate { $0.id == id }
                )
                let results = try modelContext.fetch(descriptor)
                return results.first as? T
            } else if type == MLModelUpdate.self {
                let descriptor = FetchDescriptor<MLModelUpdate>(
                    predicate: #Predicate { $0.id == id }
                )
                let results = try modelContext.fetch(descriptor)
                return results.first as? T
            } else if type == ExportRequest.self {
                let descriptor = FetchDescriptor<ExportRequest>(
                    predicate: #Predicate { $0.id == id }
                )
                let results = try modelContext.fetch(descriptor)
                return results.first as? T
            }
        } catch {
            logger.error("Failed to find local record: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func copyRemoteToLocal<T: CKSyncable>(from remote: T, to local: T) {
        if let remoteHealth = remote as? SyncableHealthDataEntry,
           let localHealth = local as? SyncableHealthDataEntry {
            localHealth.restingHeartRate = remoteHealth.restingHeartRate
            localHealth.hrv = remoteHealth.hrv
            localHealth.oxygenSaturation = remoteHealth.oxygenSaturation
            localHealth.bodyTemperature = remoteHealth.bodyTemperature
            localHealth.stressLevel = remoteHealth.stressLevel
            localHealth.moodScore = remoteHealth.moodScore
            localHealth.energyLevel = remoteHealth.energyLevel
            localHealth.activityLevel = remoteHealth.activityLevel
            localHealth.sleepQuality = remoteHealth.sleepQuality
            localHealth.nutritionScore = remoteHealth.nutritionScore
            localHealth.deviceSource = remoteHealth.deviceSource
            localHealth.syncVersion = remoteHealth.syncVersion
        } else if let remoteSleep = remote as? SyncableSleepSessionEntry,
                  let localSleep = local as? SyncableSleepSessionEntry {
            localSleep.startTime = remoteSleep.startTime
            localSleep.endTime = remoteSleep.endTime
            localSleep.duration = remoteSleep.duration
            localSleep.qualityScore = remoteSleep.qualityScore
            localSleep.stages = remoteSleep.stages
            localSleep.deviceSource = remoteSleep.deviceSource
            localSleep.syncVersion = remoteSleep.syncVersion
        } else if let remoteInsight = remote as? AnalyticsInsight,
                  let localInsight = local as? AnalyticsInsight {
            localInsight.title = remoteInsight.title
            localInsight.description = remoteInsight.description
            localInsight.category = remoteInsight.category
            localInsight.confidence = remoteInsight.confidence
            localInsight.source = remoteInsight.source
            localInsight.actionable = remoteInsight.actionable
            localInsight.data = remoteInsight.data
            localInsight.priority = remoteInsight.priority
            localInsight.syncVersion = remoteInsight.syncVersion
        } else if let remoteModel = remote as? MLModelUpdate,
                  let localModel = local as? MLModelUpdate {
            localModel.modelName = remoteModel.modelName
            localModel.modelVersion = remoteModel.modelVersion
            localModel.accuracy = remoteModel.accuracy
            localModel.trainingDate = remoteModel.trainingDate
            localModel.modelData = remoteModel.modelData
            localModel.source = remoteModel.source
            localModel.syncVersion = remoteModel.syncVersion
        } else if let remoteExport = remote as? ExportRequest,
                  let localExport = local as? ExportRequest {
            localExport.requestedBy = remoteExport.requestedBy
            localExport.exportType = remoteExport.exportType
            localExport.dateRange = remoteExport.dateRange
            localExport.status = remoteExport.status
            localExport.resultURL = remoteExport.resultURL
            localExport.requestDate = remoteExport.requestDate
            localExport.completedDate = remoteExport.completedDate
            localExport.syncVersion = remoteExport.syncVersion
        }
    }
    
    private func getCurrentDeviceSource() -> String {
        #if os(macOS)
        return "Mac"
        #elseif os(iOS)
        return "iPhone"
        #elseif os(watchOS)
        return "Apple Watch"
        #else
        return "Unknown"
        #endif
    }
}

// MARK: - Supporting Types

public enum SyncStatus: String, CaseIterable {
    case idle = "Idle"
    case syncing = "Syncing"
    case completed = "Completed"
    case error = "Error"
}

public enum SyncError: LocalizedError {
    case invalidRecord
    case accountUnavailable(CKAccountStatus)
    case dataContextUnavailable
    case cloudKitError(Error)
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidRecord:
            return "Invalid record format"
        case .accountUnavailable(let status):
            return "CloudKit account unavailable: \(status)"
        case .dataContextUnavailable:
            return "SwiftData context unavailable"
        case .cloudKitError(let error):
            return "CloudKit error: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

public enum ExportType: String, CaseIterable {
    case csv = "CSV"
    case fhir = "FHIR"
    case hl7 = "HL7"
    case pdf = "PDF"
}

// MARK: - ModelContainer Extension

extension ModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            SyncableHealthDataEntry.self,
            SyncableSleepSessionEntry.self,
            AnalyticsInsight.self,
            MLModelUpdate.self,
            ExportRequest.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}