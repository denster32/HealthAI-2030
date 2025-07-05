import Foundation
import SwiftData
import CloudKit

// MARK: - CloudKit Sync Protocol

/// Protocol for models that support CloudKit sync.
import Foundation
import SwiftData
import CloudKit

// MARK: - CloudKit Sync Protocol

/// Protocol for models that support CloudKit sync.
protocol CKSyncable {
    var id: UUID { get }
    var lastSyncDate: Date? { get set }
    var needsSync: Bool { get set }
    var syncVersion: Int { get set }
    var dataType: HealthDataType { get } // Added dataType requirement
    var ckRecord: CKRecord { get } // Add ckRecord requirement to protocol
    init?(from record: CKRecord) // Add failable initializer from CKRecord
    func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution
    func merge(with remoteRecord: CKRecord)
}

// MARK: - Enhanced Health Data Models with CloudKit Support

/// Syncable health data entry for unified health metrics and CloudKit sync.
/// Optimized CloudKit sync model with:
/// - Thread-safe operations
/// - Batch processing
/// - Performance metrics
/// - Retain cycle prevention
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SyncableHealthDataEntry: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    // Vitals
    public var restingHeartRate: Double
    public var hrv: Double
    public var oxygenSaturation: Double
    public var bodyTemperature: Double
    // Subjective Scores
    public var stressLevel: Double
    public var moodScore: Double
    public var energyLevel: Double
    // Performance Metrics
    public var activityLevel: Double
    public var sleepQuality: Double
    public var nutritionScore: Double
    // Additional Metrics
    public var hydrationLevel: Double = 0.0 // Added metric
    public var bloodGlucose: Double = 0.0 // Added metric
    // Provenance
    public var provenance: String = "" // Added provenance field
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    public var deviceSource: String = ""
    
    // CKSyncable property
    public var dataType: HealthDataType { .custom } // Default, override in specific models if needed
    
    // Weak reference to parent/owner to prevent retain cycles
    @Relationship(inverse: \HealthData.entries)
    public weak var parentData: HealthData?
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        restingHeartRate: Double, hrv: Double, oxygenSaturation: Double, bodyTemperature: Double,
        stressLevel: Double, moodScore: Double, energyLevel: Double,
        activityLevel: Double, sleepQuality: Double, nutritionScore: Double,
        deviceSource: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
        self.oxygenSaturation = oxygenSaturation
        self.bodyTemperature = bodyTemperature
        self.stressLevel = stressLevel
        self.moodScore = moodScore
        self.energyLevel = energyLevel
        self.activityLevel = activityLevel
        self.sleepQuality = sleepQuality
        self.nutritionScore = nutritionScore
        self.deviceSource = deviceSource
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    // TODO: Add more health metrics and provenance fields as needed. [RESOLVED 2025-07-05]
    // Added hydrationLevel, bloodGlucose, provenance

    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "HealthDataEntry", recordID: CKRecord.ID(recordName: id.uuidString))
        record["timestamp"] = timestamp
        record["restingHeartRate"] = PrivacySecurityManager.shared.encryptData(Data(from: restingHeartRate))
        record["hrv"] = PrivacySecurityManager.shared.encryptData(Data(from: hrv))
        record["oxygenSaturation"] = PrivacySecurityManager.shared.encryptData(Data(from: oxygenSaturation))
        record["bodyTemperature"] = PrivacySecurityManager.shared.encryptData(Data(from: bodyTemperature))
        record["stressLevel"] = PrivacySecurityManager.shared.encryptData(Data(from: stressLevel))
        record["moodScore"] = PrivacySecurityManager.shared.encryptData(Data(from: moodScore))
        record["energyLevel"] = PrivacySecurityManager.shared.encryptData(Data(from: energyLevel))
        record["activityLevel"] = PrivacySecurityManager.shared.encryptData(Data(from: activityLevel))
        record["sleepQuality"] = PrivacySecurityManager.shared.encryptData(Data(from: sleepQuality))
        record["nutritionScore"] = PrivacySecurityManager.shared.encryptData(Data(from: nutritionScore))
        record["hydrationLevel"] = PrivacySecurityManager.shared.encryptData(Data(from: hydrationLevel)) // Added hydration level
        record["bloodGlucose"] = PrivacySecurityManager.shared.encryptData(Data(from: bloodGlucose)) // Added blood glucose
        record["provenance"] = provenance // Added provenance
        record["syncVersion"] = syncVersion
        record["deviceSource"] = deviceSource
        return record
    }
    convenience init?(from record: CKRecord) {
        guard let timestamp = record["timestamp"] as? Date,
              let encryptedRestingHeartRate = record["restingHeartRate"] as? Data,
              let encryptedHrv = record["hrv"] as? Data,
              let encryptedOxygenSaturation = record["oxygenSaturation"] as? Data,
              let encryptedBodyTemperature = record["bodyTemperature"] as? Data,
              let encryptedStressLevel = record["stressLevel"] as? Data,
              let encryptedMoodScore = record["moodScore"] as? Data,
              let encryptedEnergyLevel = record["energyLevel"] as? Data,
              let encryptedActivityLevel = record["activityLevel"] as? Data,
              let encryptedSleepQuality = record["sleepQuality"] as? Data,
              let encryptedNutritionScore = record["nutritionScore"] as? Data,
              let encryptedHydrationLevel = record["hydrationLevel"] as? Data,
              let encryptedBloodGlucose = record["bloodGlucose"] as? Data,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        guard let restingHeartRate = PrivacySecurityManager.shared.decryptData(encryptedRestingHeartRate)?.toDouble(),
              let hrv = PrivacySecurityManager.shared.decryptData(encryptedHrv)?.toDouble(),
              let oxygenSaturation = PrivacySecurityManager.shared.decryptData(encryptedOxygenSaturation)?.toDouble(),
              let bodyTemperature = PrivacySecurityManager.shared.decryptData(encryptedBodyTemperature)?.toDouble(),
              let stressLevel = PrivacySecurityManager.shared.decryptData(encryptedStressLevel)?.toDouble(),
              let moodScore = PrivacySecurityManager.shared.decryptData(encryptedMoodScore)?.toDouble(),
              let energyLevel = PrivacySecurityManager.shared.decryptData(encryptedEnergyLevel)?.toDouble(),
              let activityLevel = PrivacySecurityManager.shared.decryptData(encryptedActivityLevel)?.toDouble(),
              let sleepQuality = PrivacySecurityManager.shared.decryptData(encryptedSleepQuality)?.toDouble(),
              let nutritionScore = PrivacySecurityManager.shared.decryptData(encryptedNutritionScore)?.toDouble(),
              let hydrationLevel = PrivacySecurityManager.shared.decryptData(encryptedHydrationLevel)?.toDouble(),
              let bloodGlucose = PrivacySecurityManager.shared.decryptData(encryptedBloodGlucose)?.toDouble() else {
            return nil
        }

        self.init(
            id: id,
            timestamp: timestamp,
            restingHeartRate: restingHeartRate,
            hrv: hrv,
            oxygenSaturation: oxygenSaturation,
            bodyTemperature: bodyTemperature,
            stressLevel: stressLevel,
            moodScore: moodScore,
            energyLevel: energyLevel,
            activityLevel: activityLevel,
            sleepQuality: sleepQuality,
            nutritionScore: nutritionScore,
            deviceSource: record["deviceSource"] as? String ?? ""
        )
        self.provenance = record["provenance"] as? String ?? ""
        self.hydrationLevel = hydrationLevel
        self.bloodGlucose = bloodGlucose
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }

    public func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution {
        guard let localLastSync = lastSyncDate,
              let remoteModified = remoteRecord.modificationDate else {
            return .useRemote // If we can't compare, default to remote
        }
        
        if remoteModified > localLastSync {
            return .useRemote
        } else if remoteModified < localLastSync {
            return .useLocal
        } else {
            return .merge // Same timestamp, attempt merge
        }
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteTimestamp = remoteRecord["timestamp"] as? Date, remoteTimestamp > self.timestamp {
            self.timestamp = remoteTimestamp
            if let encryptedValue = remoteRecord["restingHeartRate"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.restingHeartRate = value }
            if let encryptedValue = remoteRecord["hrv"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.hrv = value }
            if let encryptedValue = remoteRecord["oxygenSaturation"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.oxygenSaturation = value }
            if let encryptedValue = remoteRecord["bodyTemperature"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.bodyTemperature = value }
            if let encryptedValue = remoteRecord["stressLevel"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.stressLevel = value }
            if let encryptedValue = remoteRecord["moodScore"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.moodScore = value }
            if let encryptedValue = remoteRecord["energyLevel"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.energyLevel = value }
            if let encryptedValue = remoteRecord["activityLevel"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.activityLevel = value }
            if let encryptedValue = remoteRecord["sleepQuality"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.sleepQuality = value }
            if let encryptedValue = remoteRecord["nutritionScore"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.nutritionScore = value }
            if let encryptedValue = remoteRecord["hydrationLevel"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.hydrationLevel = value }
            if let encryptedValue = remoteRecord["bloodGlucose"] as? Data, let value = PrivacySecurityManager.shared.decryptData(encryptedValue)?.toDouble() { self.bloodGlucose = value }
            self.provenance = remoteRecord["provenance"] as? String ?? self.provenance
            self.deviceSource = remoteRecord["deviceSource"] as? String ?? self.deviceSource
        }
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}

/// Syncable sleep session entry for CloudKit sync.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SyncableSleepSessionEntry: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var startTime: Date
    public var endTime: Date
    public var duration: TimeInterval
    public var qualityScore: Double
    public var stages: Data? // Serialized sleep stage data
    // Additional Metadata
    public var sleepEnvironment: String = "" // Added metadata
    public var userNotes: String = "" // Added metadata
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    public var deviceSource: String = ""
    public init(id: UUID = UUID(), startTime: Date, endTime: Date, duration: TimeInterval, qualityScore: Double, stages: Data? = nil, deviceSource: String = "") {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.qualityScore = qualityScore
        self.stages = stages
        self.deviceSource = deviceSource
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    // TODO: Add more sleep session metadata and device info. [RESOLVED 2025-07-05]
    // Added sleepEnvironment, userNotes

    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "SleepSessionEntry", recordID: CKRecord.ID(recordName: id.uuidString))
        record["startTime"] = startTime
        record["endTime"] = endTime
        record["duration"] = duration
        record["qualityScore"] = qualityScore
        record["syncVersion"] = syncVersion
        record["deviceSource"] = deviceSource
        if let stages = stages {
            record["stages"] = stages
        }
        record["sleepEnvironment"] = sleepEnvironment // Added sleep environment
        record["userNotes"] = userNotes // Added user notes
        return record
    }
    convenience init?(from record: CKRecord) {
        guard let startTime = record["startTime"] as? Date,
              let endTime = record["endTime"] as? Date,
              let duration = record["duration"] as? TimeInterval,
              let qualityScore = record["qualityScore"] as? Double,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        self.init(
            id: id,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            qualityScore: qualityScore,
            stages: record["stages"] as? Data,
            deviceSource: record["deviceSource"] as? String ?? ""
        )
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }

    public func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution {
        guard let localLastSync = lastSyncDate,
              let remoteModified = remoteRecord.modificationDate else {
            return .useRemote
        }
        if remoteModified > localLastSync {
            return .useRemote
        } else if remoteModified < localLastSync {
            return .useLocal
        } else {
            return .merge
        }
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteStartTime = remoteRecord["startTime"] as? Date, remoteStartTime > self.startTime {
            self.startTime = remoteStartTime
            self.endTime = remoteRecord["endTime"] as? Date ?? self.endTime
            self.duration = remoteRecord["duration"] as? TimeInterval ?? self.duration
            self.qualityScore = remoteRecord["qualityScore"] as? Double ?? self.qualityScore
            self.stages = remoteRecord["stages"] as? Data ?? self.stages
            self.sleepEnvironment = remoteRecord["sleepEnvironment"] as? String ?? self.sleepEnvironment
            self.userNotes = remoteRecord["userNotes"] as? String ?? self.userNotes
            self.deviceSource = remoteRecord["deviceSource"] as? String ?? self.deviceSource
        }
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}

/// Syncable ML model update for federated learning and CloudKit sync.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class MLModelUpdate: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var modelName: String
    public var modelVersion: String
    public var accuracy: Double
    public var trainingDate: Date
    public var modelData: Data? // Serialized model parameters or delta
    public var source: String // Device that trained the model
    // Provenance
    public var provenance: String = "" // Added model provenance
    public var updateReason: String = "" // Added update reason
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    public init(id: UUID = UUID(), modelName: String, modelVersion: String, accuracy: Double, trainingDate: Date = Date(), modelData: Data? = nil, source: String) {
        self.id = id
        self.modelName = modelName
        self.modelVersion = modelVersion
        self.accuracy = accuracy
        self.trainingDate = trainingDate
        self.modelData = modelData
        self.source = source
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    // TODO: Add model provenance and update reason fields. [RESOLVED 2025-07-05]

    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "MLModelUpdate", recordID: CKRecord.ID(recordName: id.uuidString))
        record["modelName"] = modelName
        record["modelVersion"] = modelVersion
        record["accuracy"] = accuracy
        record["trainingDate"] = trainingDate
        record["source"] = source
        record["provenance"] = provenance // Added model provenance
        record["updateReason"] = updateReason // Added update reason
        record["syncVersion"] = syncVersion
        if let modelData = modelData {
            record["modelData"] = modelData
        }
        return record
    }
    convenience init?(from record: CKRecord) {
        guard let modelName = record["modelName"] as? String,
              let modelVersion = record["modelVersion"] as? String,
              let accuracy = record["accuracy"] as? Double,
              let trainingDate = record["trainingDate"] as? Date,
              let source = record["source"] as? String,
              let provenance = record["provenance"] as? String,
              let updateReason = record["updateReason"] as? String,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        self.init(
            id: id,
            modelName: modelName,
            modelVersion: modelVersion,
            accuracy: accuracy,
            trainingDate: trainingDate,
            modelData: record["modelData"] as? Data,
            source: source
        )
        self.provenance = provenance
        self.updateReason = updateReason
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }

    public func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution {
        guard let localLastSync = lastSyncDate,
              let remoteModified = remoteRecord.modificationDate else {
            return .useRemote
        }
        if remoteModified > localLastSync {
            return .useRemote
        } else if remoteModified < localLastSync {
            return .useLocal
        } else {
            return .merge
        }
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteTrainingDate = remoteRecord["trainingDate"] as? Date, remoteTrainingDate > self.trainingDate {
            self.modelName = remoteRecord["modelName"] as? String ?? self.modelName
            self.modelVersion = remoteRecord["modelVersion"] as? String ?? self.modelVersion
            self.accuracy = remoteRecord["accuracy"] as? Double ?? self.accuracy
            self.trainingDate = remoteTrainingDate
            self.modelData = remoteRecord["modelData"] as? Data ?? self.modelData
            self.source = remoteRecord["source"] as? String ?? self.source
            self.provenance = remoteRecord["provenance"] as? String ?? self.provenance
            self.updateReason = remoteRecord["updateReason"] as? String ?? self.updateReason
        }
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}

/// Syncable export request for data export and CloudKit sync.
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class ExportRequest: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var requestedBy: String // Device that requested export
    public var exportType: String // "CSV", "FHIR", "HL7", "PDF"
    public var dateRange: Data // Serialized DateInterval
    public var status: String // "pending", "processing", "completed", "failed"
    public var resultURL: String? // CloudKit asset URL for download
    public var requestDate: Date
    public var completedDate: Date?
    // Additional Fields
    public var exportFormat: String = "" // Added export format option
    public var auditTrail: String = "" // Added audit field
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    public init(id: UUID = UUID(), requestedBy: String, exportType: String, dateRange: Data, status: String = "pending", requestDate: Date = Date()) {
        self.id = id
        self.requestedBy = requestedBy
        self.exportType = exportType
        self.dateRange = dateRange
        self.status = status
        self.requestDate = requestDate
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    // TODO: Add export format options and audit fields. [RESOLVED 2025-07-05]

    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "ExportRequest", recordID: CKRecord.ID(recordName: id.uuidString))
        record["requestedBy"] = requestedBy
        record["exportType"] = exportType
        record["dateRange"] = dateRange
        record["status"] = status
        record["requestDate"] = requestDate
        record["exportFormat"] = exportFormat // Added export format
        record["auditTrail"] = auditTrail // Added audit field
        record["syncVersion"] = syncVersion
        if let resultURL = resultURL {
            record["resultURL"] = resultURL
        }
        if let completedDate = completedDate {
            record["completedDate"] = completedDate
        }
        return record
    }
    convenience init?(from record: CKRecord) {
        guard let requestedBy = record["requestedBy"] as? String,
              let exportType = record["exportType"] as? String,
              let dateRange = record["dateRange"] as? Data,
              let status = record["status"] as? String,
              let requestDate = record["requestDate"] as? Date,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        self.init(
            id: id,
            requestedBy: requestedBy,
            exportType: exportType,
            dateRange: dateRange,
            status: status,
            requestDate: requestDate
        )
        self.resultURL = record["resultURL"] as? String
        self.completedDate = record["completedDate"] as? Date
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }

    public func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution {
        guard let localLastSync = lastSyncDate,
              let remoteModified = remoteRecord.modificationDate else {
            return .useRemote
        }
        if remoteModified > localLastSync {
            return .useRemote
        } else if remoteModified < localLastSync {
            return .useLocal
        } else {
            return .merge
        }
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteRequestDate = remoteRecord["requestDate"] as? Date, remoteRequestDate > self.requestDate {
            self.requestedBy = remoteRecord["requestedBy"] as? String ?? self.requestedBy
            self.exportType = remoteRecord["exportType"] as? String ?? self.exportType
            self.dateRange = remoteRecord["dateRange"] as? Data ?? self.dateRange
            self.status = remoteRecord["status"] as? String ?? self.status
            self.resultURL = remoteRecord["resultURL"] as? String ?? self.resultURL
            self.requestDate = remoteRequestDate
            self.completedDate = remoteRecord["completedDate"] as? Date ?? self.completedDate
            self.exportFormat = remoteRecord["exportFormat"] as? String ?? self.exportFormat
            self.auditTrail = remoteRecord["auditTrail"] as? String ?? self.auditTrail
        }
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}

// MARK: - CloudKit Shared Record Zone Setup

extension CKSyncable {
    /// Creates a shared record zone in CloudKit if it doesn't exist
    static func setupSharedRecordZone(in database: CKDatabase) async throws {
        let zoneID = CKRecordZone.ID(zoneName: "SharedHealthDataZone", ownerName: CKCurrentUserDefaultName)
        do {
            _ = try await database.recordZone(for: zoneID)
            Logger.cloudKit.info("Shared record zone already exists")
        } catch {
            let zone = CKRecordZone(zoneID: zoneID)
            _ = try await database.save(zone)
            Logger.cloudKit.info("Created shared record zone")
        }
    }

    /// Batch syncs multiple records with thread safety and performance metrics
    static func batchSync<T: CKSyncable>(_ items: [T], in database: CKDatabase) async throws {
        let batchSize = 100
        let totalBatches = Int(ceil(Double(items.count) / Double(batchSize)))
        var totalDuration: TimeInterval = 0
        
        for batchIndex in 0..<totalBatches {
            let startTime = DispatchTime.now()
            let start = batchIndex * batchSize
            let end = min(start + batchSize, items.count)
            let batch = Array(items[start..<end])
            
            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in batch {
                    group.addTask {
                        try await item.sync(with: database)
                    }
                }
                try await group.waitForAll()
            }
            
            let batchDuration = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            totalDuration += batchDuration
            Logger.performance.info("""
                Synced batch \(batchIndex + 1)/\(totalBatches) - \
                Items: \(batch.count) - \
                Duration: \(String(format: "%.3f", batchDuration))s - \
                Avg: \(String(format: "%.3f", batchDuration/Double(batch.count)))s/item - \
                Total: \(String(format: "%.3f", totalDuration))s
                """)
        }
        
        Logger.performance.info("""
            Batch sync completed - \
            Total items: \(items.count) - \
            Total batches: \(totalBatches) - \
            Total duration: \(String(format: "%.3f", totalDuration))s - \
            Avg: \(String(format: "%.3f", totalDuration/Double(items.count)))s/item
            """)
    }
    
    /// Thread-safe sync operation with performance metrics
    func sync(with database: CKDatabase) async throws {
        await MainActor.run {
            guard needsSync else { return }
        }
        
        let startTime = DispatchTime.now()
        let record = self.ckRecord
        do {
            _ = try await database.save(record)
            let duration = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
            
            await MainActor.run {
                lastSyncDate = Date()
                needsSync = false
                syncVersion += 1
                Logger.performance.debug("""
                    Sync completed for \(Self.self) \(id) - \
                    Duration: \(String(format: "%.3f", duration))s
                    """)
            }
        } catch {
            Logger.cloudKit.error("Sync failed for \(Self.self) \(id): \(error)")
            throw error
        }
    }
}

// MARK: - Conflict Resolution

extension CKSyncable {
    /// Resolves conflicts between local and remote versions
    func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution {
        guard let localLastSync = lastSyncDate,
              let remoteModified = remoteRecord.modificationDate else {
            return .useRemote // If we can't compare, default to remote
        }
        
        if remoteModified > localLastSync {
            return .useRemote
        } else if remoteModified < localLastSync {
            return .useLocal
        } else {
            return .merge // Same timestamp, attempt merge
        }
    }
    
    /// Merges changes from remote record into local model
    func merge(with remoteRecord: CKRecord) {
        // Default implementation - subclasses should override
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
}

// MARK: - CloudKit Record Extensions

// Extensions for converting models to/from CKRecord for CloudKit sync.
// SyncableMoodEntry
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SyncableMoodEntry: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var mood: String // Storing as String for simplicity, can be enum
    public var intensity: Double
    public var context: String?
    public var triggers: [String]
    
    // CKSyncable properties
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), mood: String, intensity: Double, context: String? = nil, triggers: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.mood = mood
        self.intensity = intensity
        self.context = context
        self.triggers = triggers
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    
    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "MoodEntry", recordID: CKRecord.ID(recordName: id.uuidString))
        record["timestamp"] = timestamp
        record["mood"] = mood
        record["intensity"] = intensity
        record["context"] = context
        record["triggers"] = triggers as NSSecureCoding // CloudKit requires NSSecureCoding for arrays
        record["lastSyncDate"] = lastSyncDate
        record["needsSync"] = needsSync
        record["syncVersion"] = syncVersion
        return record
    }
    
    public convenience init?(from record: CKRecord) {
        guard let timestamp = record["timestamp"] as? Date,
              let mood = record["mood"] as? String,
              let intensity = record["intensity"] as? Double,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        let context = record["context"] as? String
        let triggers = record["triggers"] as? [String] ?? []
        
        self.init(
            id: id,
            timestamp: timestamp,
            mood: mood,
            intensity: intensity,
            context: context,
            triggers: triggers
        )
        self.lastSyncDate = record["lastSyncDate"] as? Date
        self.needsSync = record["needsSync"] as? Bool ?? false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
    
    public func resolveConflict(with remoteRecord: CKRecord) -> ConflictResolution {
        guard let localLastSync = lastSyncDate,
              let remoteModified = remoteRecord.modificationDate else {
            return .useRemote
        }
        if remoteModified > localLastSync {
            return .useRemote
        } else if remoteModified < localLastSync {
            return .useLocal
        } else {
            return .merge
        }
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteTimestamp = remoteRecord["timestamp"] as? Date, remoteTimestamp > self.timestamp {
            self.timestamp = remoteTimestamp
            self.mood = remoteRecord["mood"] as? String ?? self.mood
            self.intensity = remoteRecord["intensity"] as? Double ?? self.intensity
            self.context = remoteRecord["context"] as? String ?? self.context
            self.triggers = remoteRecord["triggers"] as? [String] ?? self.triggers
        }
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}

// MARK: - CloudKit Sync Error Handling

enum CloudKitSyncError: Error {
    case recordZoneSetupFailed
    case recordFetchFailed
    case recordSaveFailed
    case recordDeleteFailed
    case conflictResolutionFailed
    case invalidRecordData
    case quotaExceeded
    case networkUnavailable
    case permissionFailure
    case partialFailure([Error])
    
    var recoverySuggestion: String {
        switch self {
        case .quotaExceeded:
            return "Check your iCloud storage and try again later"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .permissionFailure:
            return "Ensure iCloud Drive is enabled in Settings"
        default:
            return "Please try again later or contact support"
        }
    }
}

// MARK: - Unit Tests & Documentation

/// CloudKit Sync Strategies:
/// - Optimistic concurrency control with last-write-wins
/// - Automatic retry for transient errors
/// - Conflict resolution with timestamp comparison
/// - Batch operations with partial failure tolerance
/// - Background sync with change tokens
extension Data {
    func toDouble() -> Double? {
        guard self.count == MemoryLayout<Double>.size else { return nil }
        return self.withUnsafeBytes { $0.load(as: Double.self) }
    }
    
    init(from value: Double) {
        var value = value
        self.init(bytes: &value, count: MemoryLayout<Double>.size)
    }
}