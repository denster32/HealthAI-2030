import Foundation
import CloudKit
import SwiftData
import Combine
import OSLog // Import OSLog for logging
import HealthKit // Import HealthKit for HealthDataType

// MARK: - UnifiedCloudKitSyncManager
/// Manages real-time cross-device synchronization using CloudKit for various health data models.
/// This manager handles CloudKit container setup, record operations (save, fetch, delete),
/// subscriptions for real-time updates, conflict resolution, and basic network monitoring.
@available(iOS 18.0, macOS 15.0, *)
public class UnifiedCloudKitSyncManager: ObservableObject {
    public static let shared = UnifiedCloudKitSyncManager()

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    private var currentChangeToken: CKServerChangeToken?
    private let defaults = UserDefaults.standard
    private let changeTokenKey = "cloudKitPrivateChangeToken"
    
    private let privacySecurityManager = PrivacySecurityManager.shared
    private let logger = Logger(subsystem: "com.healthai2030.UnifiedCloudKitSyncManager", category: "CloudKitSync")

    // Publishers for sync status and errors
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncError: CloudKitSyncError?
    @Published public var networkStatus: NetworkStatus = .unknown

    private var swiftDataManager: SwiftDataManager

    private init() {
        self.container = CKContainer(identifier: "iCloud.com.healthai2030")
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
        self.swiftDataManager = SwiftDataManager.shared
        
        // Load last change token
        if let tokenData = defaults.data(forKey: changeTokenKey) {
            self.currentChangeToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
        }

        setupSubscriptions()
        startNetworkMonitoring()
    }

    // MARK: - CloudKit Setup
    
    /// Sets up the necessary CloudKit record zones.
    public func setupCloudKit() async {
        do {
            try await CKSyncable.setupSharedRecordZone(in: privateDatabase)
            logger.info("CloudKit setup complete.")
        } catch {
            logger.error("Failed to set up CloudKit: \(error.localizedDescription)")
            await MainActor.run {
                self.lastSyncError = .recordZoneSetupFailed
            }
        }
    }

    // MARK: - Data Synchronization Operations

    /// Saves a CKSyncable item to CloudKit.
    public func save<T: CKSyncable & PersistentModel>(_ item: T) async {
        await MainActor.run { self.isSyncing = true }
        
        // Enforce privacy settings before saving
        if !privacySecurityManager.isSharingAllowed(for: item.dataType) {
            privacySecurityManager.auditDataAccess(action: "CloudKit Sync Denied (Save)", dataType: item.dataType, details: "CloudKit save denied due to privacy settings for \(String(describing: T.self)) with ID \(item.id)")
            await MainActor.run {
                self.lastSyncError = .privacyDenied(item.dataType.rawValue)
                self.isSyncing = false
            }
            return
        }
        
        do {
            try await item.sync(with: privateDatabase)
            logger.info("Successfully synced \(T.self) with ID: \(item.id)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Sync (Save)", dataType: item.dataType, details: "Successfully synced \(String(describing: T.self)) with ID \(item.id)")
        } catch {
            logger.error("Failed to save \(T.self) with ID \(item.id): \(error.localizedDescription)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Sync Failed (Save)", dataType: item.dataType, details: "Failed to sync \(String(describing: T.self)) with ID \(item.id): \(error.localizedDescription)")
            await MainActor.run {
                self.lastSyncError = CloudKitSyncError.recordSaveFailed
            }
        }
        await MainActor.run { self.isSyncing = false }
    }

    /// Fetches CKSyncable items from CloudKit.
    public func fetch<T: CKSyncable & PersistentModel>(recordType: String, modelContext: ModelContext) async -> [T] {
        await MainActor.run { self.isSyncing = true }
        var fetchedItems: [T] = []
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query)
            for (_, record) in results {
                if let item = T(from: record) {
                    // Enforce privacy settings before processing fetched data
                    if !privacySecurityManager.isSharingAllowed(for: item.dataType) {
                        privacySecurityManager.auditDataAccess(action: "CloudKit Sync Denied (Fetch)", dataType: item.dataType, details: "CloudKit fetch denied due to privacy settings for \(String(describing: T.self)) with ID \(item.id)")
                        continue // Skip this item if sharing is not allowed
                    }
                    
                    // Conflict resolution: compare with local version if exists
                    if let existingItem = try? modelContext.fetch(FetchDescriptor<T>(predicate: #Predicate { $0.id == item.id })).first {
                        switch existingItem.resolveConflict(with: record) {
                        case .useLocal:
                            logger.info("Conflict: Using local version for \(T.self) \(item.id)")
                            privacySecurityManager.auditDataAccess(action: "CloudKit Sync (Conflict - Use Local)", dataType: item.dataType, details: "Conflict resolved using local version for \(String(describing: T.self)) with ID \(item.id)")
                            // Do nothing, local version is preferred
                        case .useRemote:
                            logger.info("Conflict: Using remote version for \(T.self) \(item.id)")
                            privacySecurityManager.auditDataAccess(action: "CloudKit Sync (Conflict - Use Remote)", dataType: item.dataType, details: "Conflict resolved using remote version for \(String(describing: T.self)) with ID \(item.id)")
                            modelContext.delete(existingItem) // Delete local to replace with remote
                            modelContext.insert(item)
                            fetchedItems.append(item)
                        case .merge:
                            logger.info("Conflict: Merging versions for \(T.self) \(item.id)")
                            privacySecurityManager.auditDataAccess(action: "CloudKit Sync (Conflict - Merge)", dataType: item.dataType, details: "Conflict resolved by merging versions for \(String(describing: T.self)) with ID \(item.id)")
                            existingItem.merge(with: record)
                            fetchedItems.append(existingItem)
                        }
                    } else {
                        modelContext.insert(item)
                        fetchedItems.append(item)
                        privacySecurityManager.auditDataAccess(action: "CloudKit Sync (New Record)", dataType: item.dataType, details: "Inserted new record from CloudKit for \(String(describing: T.self)) with ID \(item.id)")
                    }
                }
            }
            logger.info("Successfully fetched \(fetchedItems.count) \(recordType) records.")
        } catch {
            logger.error("Failed to fetch \(recordType) records: \(error.localizedDescription)")
            await MainActor.run {
                self.lastSyncError = CloudKitSyncError.recordFetchFailed
            }
        }
        await MainActor.run { self.isSyncing = false }
        return fetchedItems
    }

    /// Deletes a CKSyncable item from CloudKit.
    public func delete<T: CKSyncable & PersistentModel>(_ item: T) async {
        await MainActor.run { self.isSyncing = true }
        
        // Enforce privacy settings before deleting
        if !privacySecurityManager.isSharingAllowed(for: item.dataType) {
            privacySecurityManager.auditDataAccess(action: "CloudKit Sync Denied (Delete)", dataType: item.dataType, details: "CloudKit delete denied due to privacy settings for \(String(describing: T.self)) with ID \(item.id)")
            await MainActor.run {
                self.lastSyncError = .privacyDenied(item.dataType.rawValue)
                self.isSyncing = false
            }
            return
        }
        
        let recordID = CKRecord.ID(recordName: item.id.uuidString)
        do {
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            logger.info("Successfully deleted \(T.self) with ID: \(item.id)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Sync (Delete)", dataType: item.dataType, details: "Successfully deleted \(String(describing: T.self)) with ID \(item.id) from CloudKit")
        } catch {
            logger.error("Failed to delete \(T.self) with ID \(item.id): \(error.localizedDescription)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Sync Failed (Delete)", dataType: item.dataType, details: "Failed to delete \(String(describing: T.self)) with ID \(item.id) from CloudKit: \(error.localizedDescription)")
            await MainActor.run {
                self.lastSyncError = CloudKitSyncError.recordDeleteFailed
            }
        }
        await MainActor.run { self.isSyncing = false }
    }
    
    /// Performs a full sync, pushing local changes and pulling remote changes.
    public func performFullSync(modelContext: ModelContext) async {
        await MainActor.run { self.isSyncing = true }
        logger.info("Starting full CloudKit sync...")
        privacySecurityManager.auditDataAccess(action: "CloudKit Full Sync Start", dataType: .custom, details: "Initiating full CloudKit synchronization.")
        
        do {
            // 1. Push local changes
            try await pushLocalChanges(modelContext: modelContext)
            
            // 2. Pull remote changes
            try await pullRemoteChanges(modelContext: modelContext)
            
            logger.info("Full CloudKit sync completed successfully.")
            privacySecurityManager.auditDataAccess(action: "CloudKit Full Sync Complete", dataType: .custom, details: "Full CloudKit synchronization completed successfully.")
            await MainActor.run { self.lastSyncError = nil }
        } catch {
            logger.error("Full CloudKit sync failed: \(error.localizedDescription)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Full Sync Failed", dataType: .custom, details: "Full CloudKit synchronization failed: \(error.localizedDescription)")
            await MainActor.run {
                self.lastSyncError = CloudKitSyncError.other(error.localizedDescription)
            }
        }
        await MainActor.run { self.isSyncing = false }
    }
    
    private func pushLocalChanges(modelContext: ModelContext) async throws {
        logger.info("Pushing local changes...")
        
        let healthEntriesToSync = try modelContext.fetch(FetchDescriptor<SyncableHealthDataEntry>(predicate: #Predicate { $0.needsSync == true }))
        let filteredHealthEntries = healthEntriesToSync.filter { privacySecurityManager.isSharingAllowed(for: $0.dataType) }
        if !filteredHealthEntries.isEmpty {
            try await CKSyncable.batchSync(filteredHealthEntries, in: privateDatabase)
            privacySecurityManager.auditDataAccess(action: "CloudKit Push", dataType: .custom, details: "Pushed \(filteredHealthEntries.count) HealthDataEntry records.")
        }
        
        let sleepEntriesToSync = try modelContext.fetch(FetchDescriptor<SyncableSleepSessionEntry>(predicate: #Predicate { $0.needsSync == true }))
        let filteredSleepEntries = sleepEntriesToSync.filter { privacySecurityManager.isSharingAllowed(for: $0.dataType) }
        if !filteredSleepEntries.isEmpty {
            try await CKSyncable.batchSync(filteredSleepEntries, in: privateDatabase)
            privacySecurityManager.auditDataAccess(action: "CloudKit Push", dataType: .sleep, details: "Pushed \(filteredSleepEntries.count) SleepSessionEntry records.")
        }
        
        let cardiacDescriptor = FetchDescriptor<SyncableCardiacEvent>(predicate: #Predicate { $0.needsSync == true })
        let cardiacEventsToSync = try modelContext.fetch(cardiacDescriptor)
        let filteredCardiacEvents = cardiacEventsToSync.filter { privacySecurityManager.isSharingAllowed(for: .biometric) } // Assuming CardiacEvent is biometric
        if !filteredCardiacEvents.isEmpty {
            try await CKSyncable.batchSync(filteredCardiacEvents, in: privateDatabase)
            privacySecurityManager.auditDataAccess(action: "CloudKit Push", dataType: .biometric, details: "Pushed \(filteredCardiacEvents.count) CardiacEvent records.")
        }
        
        let moodDescriptor = FetchDescriptor<SyncableMoodEntry>(predicate: #Predicate { $0.needsSync == true })
        let moodEntriesToSync = try modelContext.fetch(moodDescriptor)
        let filteredMoodEntries = moodEntriesToSync.filter { privacySecurityManager.isSharingAllowed(for: $0.dataType) }
        if !filteredMoodEntries.isEmpty {
            try await CKSyncable.batchSync(filteredMoodEntries, in: privateDatabase)
            privacySecurityManager.auditDataAccess(action: "CloudKit Push", dataType: .mentalHealth, details: "Pushed \(filteredMoodEntries.count) MoodEntry records.")
        }
        
        // Add similar filtering for MLModelUpdate and ExportRequest
        let mlModelUpdatesToSync = try modelContext.fetch(FetchDescriptor<MLModelUpdate>(predicate: #Predicate { $0.needsSync == true }))
        let filteredMLModelUpdates = mlModelUpdatesToSync.filter { privacySecurityManager.isSharingAllowed(for: $0.dataType) }
        if !filteredMLModelUpdates.isEmpty {
            try await CKSyncable.batchSync(filteredMLModelUpdates, in: privateDatabase)
            privacySecurityManager.auditDataAccess(action: "CloudKit Push", dataType: .custom, details: "Pushed \(filteredMLModelUpdates.count) MLModelUpdate records.")
        }
        
        let exportRequestsToSync = try modelContext.fetch(FetchDescriptor<ExportRequest>(predicate: #Predicate { $0.needsSync == true }))
        let filteredExportRequests = exportRequestsToSync.filter { privacySecurityManager.isSharingAllowed(for: $0.dataType) }
        if !filteredExportRequests.isEmpty {
            try await CKSyncable.batchSync(filteredExportRequests, in: privateDatabase)
            privacySecurityManager.auditDataAccess(action: "CloudKit Push", dataType: .custom, details: "Pushed \(filteredExportRequests.count) ExportRequest records.")
        }
        
        logger.info("Local changes pushed.")
    }
    
    private func pullRemoteChanges(modelContext: ModelContext) async throws {
        logger.info("Pulling remote changes...")
        privacySecurityManager.auditDataAccess(action: "CloudKit Pull Start", dataType: .custom, details: "Initiating pull for remote CloudKit changes.")
        
        let zoneID = CKRecordZone.ID(zoneName: "SharedHealthDataZone", ownerName: CKCurrentUserDefaultName)
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = currentChangeToken
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: [zoneID: options])
        
        operation.fetchAllChanges = true
        
        operation.recordChangedBlock = { record in
            Task { @MainActor in
                self.logger.debug("Record changed: \(record.recordID.recordName)")
                await self.handleRemoteRecordChange(record, modelContext: modelContext)
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            Task { @MainActor in
                self.logger.debug("Record deleted: \(recordID.recordName) of type \(recordType)")
                await self.handleRemoteRecordDeletion(recordID, recordType: recordType, modelContext: modelContext)
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { zoneId, serverChangeToken, _ in
            self.currentChangeToken = serverChangeToken
            self.saveChangeToken()
        }
        
        operation.recordZoneFetchCompletionBlock = { zoneId, serverChangeToken, _, _, error in
            if let error = error {
                self.logger.error("Failed to fetch changes for zone \(zoneId.zoneName): \(error.localizedDescription)")
                Task { @MainActor in
                    self.lastSyncError = CloudKitSyncError.recordFetchFailed
                }
            } else {
                self.currentChangeToken = serverChangeToken
                self.saveChangeToken()
                self.logger.info("Finished fetching changes for zone \(zoneId.zoneName)")
            }
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            if let error = error {
                self.logger.error("Fetch record zone changes operation failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self.lastSyncError = CloudKitSyncError.recordFetchFailed
                }
            } else {
                self.logger.info("Remote changes pulled.")
                self.privacySecurityManager.auditDataAccess(action: "CloudKit Pull Complete", dataType: .custom, details: "Remote CloudKit changes pulled successfully.")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    private func handleRemoteRecordChange(_ record: CKRecord, modelContext: ModelContext) async {
        // Attempt to create a CKSyncable item from the record
        // The CKSyncable init?(from record: CKRecord) now handles decryption
        var item: (any CKSyncable & PersistentModel)?
        
        switch record.recordType {
        case "HealthDataEntry":
            item = SyncableHealthDataEntry(from: record)
        case "SleepSessionEntry":
            item = SyncableSleepSessionEntry(from: record)
        case "CardiacEvent":
            // Assuming CardiacEvent is also CKSyncable and PersistentModel
            // item = SyncableCardiacEvent(from: record)
            logger.warning("CardiacEvent handling not fully implemented for CloudKit sync.")
            return
        case "MoodEntry":
            item = SyncableMoodEntry(from: record)
        case "MLModelUpdate":
            item = MLModelUpdate(from: record)
        case "ExportRequest":
            item = ExportRequest(from: record)
        default:
            logger.warning("Unknown record type received: \(record.recordType)")
            return
        }
        
        guard let syncableItem = item else {
            logger.error("Failed to create syncable item from record: \(record.recordID.recordName) of type \(record.recordType)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Pull Failed (Invalid Record)", dataType: .custom, details: "Failed to process invalid record from CloudKit: \(record.recordID.recordName)")
            return
        }
        
        // Enforce privacy settings before upserting
        if !privacySecurityManager.isSharingAllowed(for: syncableItem.dataType) {
            privacySecurityManager.auditDataAccess(action: "CloudKit Pull Denied (Privacy)", dataType: syncableItem.dataType, details: "Remote record processing denied due to privacy settings for \(record.recordType) with ID \(syncableItem.id)")
            return
        }
        
        await upsert(syncableItem, modelContext: modelContext)
    }
    
    private func handleRemoteRecordDeletion(_ recordID: CKRecord.ID, recordType: String, modelContext: ModelContext) async {
        guard let uuid = UUID(uuidString: recordID.recordName) else { return }
        
        // Determine the model type and check privacy settings before deleting locally
        var dataType: HealthDataType = .custom // Default to custom if type is unknown or not directly mapped
        var modelToDelete: (any PersistentModel & CKSyncable)?
        
        switch recordType {
        case "HealthDataEntry":
            if let existing = try? modelContext.fetch(FetchDescriptor<SyncableHealthDataEntry>(predicate: #Predicate { $0.id == uuid })).first {
                modelToDelete = existing
                dataType = existing.dataType
            }
        case "SleepSessionEntry":
            if let existing = try? modelContext.fetch(FetchDescriptor<SyncableSleepSessionEntry>(predicate: #Predicate { $0.id == uuid })).first {
                modelToDelete = existing
                dataType = existing.dataType
            }
        case "CardiacEvent":
            // Assuming CardiacEvent is also CKSyncable and PersistentModel
            // if let existing = try? modelContext.fetch(FetchDescriptor<SyncableCardiacEvent>(predicate: #Predicate { $0.id == uuid })).first {
            //     modelToDelete = existing
            //     dataType = .biometric
            // }
            logger.warning("CardiacEvent deletion handling not fully implemented for CloudKit sync.")
            return
        case "MoodEntry":
            if let existing = try? modelContext.fetch(FetchDescriptor<SyncableMoodEntry>(predicate: #Predicate { $0.id == uuid })).first {
                modelToDelete = existing
                dataType = existing.dataType
            }
        case "MLModelUpdate":
            if let existing = try? modelContext.fetch(FetchDescriptor<MLModelUpdate>(predicate: #Predicate { $0.id == uuid })).first {
                modelToDelete = existing
                dataType = existing.dataType
            }
        case "ExportRequest":
            if let existing = try? modelContext.fetch(FetchDescriptor<ExportRequest>(predicate: #Predicate { $0.id == uuid })).first {
                modelToDelete = existing
                dataType = existing.dataType
            }
        default:
            logger.warning("Unknown record type for deletion: \(recordType)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Delete Failed (Unknown Type)", dataType: .custom, details: "Attempted to delete unknown record type from CloudKit: \(recordType) with ID \(uuid)")
            return
        }
        
        guard let finalModelToDelete = modelToDelete else {
            logger.info("Local record not found for deletion: \(uuid) of type \(recordType)")
            return
        }
        
        if !privacySecurityManager.isSharingAllowed(for: dataType) {
            privacySecurityManager.auditDataAccess(action: "CloudKit Delete Denied (Privacy)", dataType: dataType, details: "Local deletion denied due to privacy settings for \(recordType) with ID \(uuid)")
            return
        }
        
        modelContext.delete(finalModelToDelete)
        logger.info("Deleted local \(recordType): \(uuid)")
        privacySecurityManager.auditDataAccess(action: "CloudKit Delete", dataType: dataType, details: "Successfully deleted local \(recordType) with ID \(uuid) from CloudKit instruction.")
    }
    
    private func upsert<T: CKSyncable & PersistentModel>(_ remoteItem: T, modelContext: ModelContext) async {
        do {
            if let existingItem = try modelContext.fetch(FetchDescriptor<T>(predicate: #Predicate { $0.id == remoteItem.id })).first {
                switch existingItem.resolveConflict(with: remoteItem.ckRecord) {
                case .useLocal:
                    logger.info("Conflict: Local version preferred for \(T.self) \(remoteItem.id). Skipping remote update.")
                    privacySecurityManager.auditDataAccess(action: "CloudKit Upsert (Conflict - Use Local)", dataType: remoteItem.dataType, details: "Conflict resolved using local version for \(String(describing: T.self)) with ID \(remoteItem.id)")
                    // Mark local as needing sync if it's newer
                    if existingItem.lastSyncDate ?? .distantPast > remoteItem.lastSyncDate ?? .distantPast {
                        existingItem.needsSync = true
                    }
                case .useRemote:
                    logger.info("Conflict: Remote version preferred for \(T.self) \(remoteItem.id). Updating local.")
                    privacySecurityManager.auditDataAccess(action: "CloudKit Upsert (Conflict - Use Remote)", dataType: remoteItem.dataType, details: "Conflict resolved using remote version for \(String(describing: T.self)) with ID \(remoteItem.id)")
                    modelContext.delete(existingItem)
                    modelContext.insert(remoteItem)
                case .merge:
                    logger.info("Conflict: Merging versions for \(T.self) \(remoteItem.id).")
                    privacySecurityManager.auditDataAccess(action: "CloudKit Upsert (Conflict - Merge)", dataType: remoteItem.dataType, details: "Conflict resolved by merging versions for \(String(describing: T.self)) with ID \(remoteItem.id)")
                    existingItem.merge(with: remoteItem.ckRecord)
                }
            } else {
                logger.info("Inserting new remote \(T.self) with ID: \(remoteItem.id)")
                privacySecurityManager.auditDataAccess(action: "CloudKit Upsert (New Record)", dataType: remoteItem.dataType, details: "Inserting new remote record for \(String(describing: T.self)) with ID \(remoteItem.id)")
                modelContext.insert(remoteItem)
            }
            try modelContext.save()
        } catch {
            logger.error("Failed to upsert \(T.self) \(remoteItem.id): \(error.localizedDescription)")
            privacySecurityManager.auditDataAccess(action: "CloudKit Upsert Failed", dataType: remoteItem.dataType, details: "Failed to upsert \(String(describing: T.self)) with ID \(remoteItem.id): \(error.localizedDescription)")
            await MainActor.run {
                self.lastSyncError = .conflictResolutionFailed
            }
        }
    }

    // MARK: - Subscriptions for Real-time Updates

    /// Sets up CloudKit subscriptions for real-time data changes.
    private func setupSubscriptions() {
        // Subscription for HealthData changes
        let healthDataSubscription = CKQuerySubscription(recordType: "HealthData", query: CKQuery(recordType: "HealthData", predicate: NSPredicate(value: true)), options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        let healthDataNotificationInfo = CKSubscription.NotificationInfo()
        healthDataNotificationInfo.shouldSendContentAvailable = true
        healthDataSubscription.notificationInfo = healthDataNotificationInfo
        privateDatabase.save(healthDataSubscription) { _, error in
            if let error = error {
                print("Error setting up HealthData subscription: \(error)")
            }
        }

        // Subscription for DigitalTwin changes
        let digitalTwinSubscription = CKQuerySubscription(recordType: "DigitalTwin", query: CKQuery(recordType: "DigitalTwin", predicate: NSPredicate(value: true)), options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        let digitalTwinNotificationInfo = CKSubscription.NotificationInfo()
        digitalTwinNotificationInfo.shouldSendContentAvailable = true
        digitalTwinSubscription.notificationInfo = digitalTwinNotificationInfo
        privateDatabase.save(digitalTwinSubscription) { _, error in
            if let error = error {
                print("Error setting up DigitalTwin subscription: \(error)")
            }
        }
    }
    
    // MARK: - Device Discovery and Network Monitoring
    
    /// Basic network monitoring (can be expanded with Network.framework)
    private func startNetworkMonitoring() {
        // Placeholder for network monitoring. In a real app, use Network.framework.
        // For now, simulate a change after a delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.networkStatus = .connected
            self.logger.info("Network status: Connected (simulated)")
            self.privacySecurityManager.auditDataAccess(action: "Network Status Change", dataType: .custom, details: "Network status changed to Connected (simulated).")
        }
    }
    
    public enum NetworkStatus {
        case unknown, connected, disconnected
    }

    // MARK: - Change Token Management
    
    private func saveChangeToken() {
        if let token = currentChangeToken {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                defaults.set(data, forKey: changeTokenKey)
                logger.info("CloudKit change token saved.")
            } catch {
                logger.error("Failed to archive change token: \(error.localizedDescription)")
                privacySecurityManager.auditDataAccess(action: "CloudKit Change Token Save Failed", dataType: .custom, details: "Failed to save CloudKit change token: \(error.localizedDescription)")
            }
        } else {
            defaults.removeObject(forKey: changeTokenKey)
            logger.info("CloudKit change token removed.")
        }
    }
}

// MARK: - Logger Placeholder
// In a real app, replace with a proper logging framework.
// This struct is a placeholder and should be replaced by a robust logging solution.
// For the purpose of this task, we will keep it as is, but in a production environment,
// it would be integrated with a proper logging framework like OSLog or a third-party solution.
struct Logger {
    static let cloudKit = CloudKitLogger()
    static let performance = PerformanceLogger()
    
    struct CloudKitLogger {
        func info(_ message: String) { print("☁️ CloudKit: \(message)") }
        func debug(_ message: String) { print("☁️ CloudKit Debug: \(message)") }
        func error(_ message: String) { print("☁️ CloudKit Error: \(message)") }
        func warning(_ message: String) { print("☁️ CloudKit Warning: \(message)") }
    }
    
    struct PerformanceLogger {
        func info(_ message: String) { print("⚡️ Performance: \(message)") }
        func debug(_ message: String) { print("⚡️ Performance Debug: \(message)") }
    }
}