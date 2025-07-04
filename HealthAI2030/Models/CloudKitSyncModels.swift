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
}

// MARK: - Enhanced Health Data Models with CloudKit Support

/// Syncable health data entry for unified health metrics and CloudKit sync.
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
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    public var deviceSource: String = ""
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
    // TODO: Add more health metrics and provenance fields as needed.
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
    // TODO: Add more sleep session metadata and device info.
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
    // TODO: Add model provenance and update reason fields.
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
    // TODO: Add export format options and audit fields.
}

// MARK: - CloudKit Record Extensions

// Extensions for converting models to/from CKRecord for CloudKit sync.
extension SyncableHealthDataEntry {
    var ckRecord: CKRecord {
        let record = CKRecord(recordType: "HealthDataEntry", recordID: CKRecord.ID(recordName: id.uuidString))
        record["timestamp"] = timestamp
        record["restingHeartRate"] = restingHeartRate
        record["hrv"] = hrv
        record["oxygenSaturation"] = oxygenSaturation
        record["bodyTemperature"] = bodyTemperature
        record["stressLevel"] = stressLevel
        record["moodScore"] = moodScore
        record["energyLevel"] = energyLevel
        record["activityLevel"] = activityLevel
        record["sleepQuality"] = sleepQuality
        record["nutritionScore"] = nutritionScore
        record["syncVersion"] = syncVersion
        record["deviceSource"] = deviceSource
        return record
    }
    convenience init?(from record: CKRecord) {
        guard let timestamp = record["timestamp"] as? Date,
              let restingHeartRate = record["restingHeartRate"] as? Double,
              let hrv = record["hrv"] as? Double,
              let oxygenSaturation = record["oxygenSaturation"] as? Double,
              let bodyTemperature = record["bodyTemperature"] as? Double,
              let stressLevel = record["stressLevel"] as? Double,
              let moodScore = record["moodScore"] as? Double,
              let energyLevel = record["energyLevel"] as? Double,
              let activityLevel = record["activityLevel"] as? Double,
              let sleepQuality = record["sleepQuality"] as? Double,
              let nutritionScore = record["nutritionScore"] as? Double,
              let id = UUID(uuidString: record.recordID.recordName) else {
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
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
}

extension SyncableSleepSessionEntry {
    var ckRecord: CKRecord {
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
}

extension MLModelUpdate {
    var ckRecord: CKRecord {
        let record = CKRecord(recordType: "MLModelUpdate", recordID: CKRecord.ID(recordName: id.uuidString))
        record["modelName"] = modelName
        record["modelVersion"] = modelVersion
        record["accuracy"] = accuracy
        record["trainingDate"] = trainingDate
        record["source"] = source
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
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
}

extension ExportRequest {
    var ckRecord: CKRecord {
        let record = CKRecord(recordType: "ExportRequest", recordID: CKRecord.ID(recordName: id.uuidString))
        record["requestedBy"] = requestedBy
        record["exportType"] = exportType
        record["dateRange"] = dateRange
        record["status"] = status
        record["requestDate"] = requestDate
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
}
// TODO: Add unit tests for all syncable models and CloudKit extensions.
// TODO: Document CloudKit sync strategies and error handling.