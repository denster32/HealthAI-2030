import Foundation
import SwiftData
import CloudKit

@available(iOS 18.0, macOS 15.0, *)
@Model
public final class AnalyticsInsight: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var description: String
    public var category: String
    public var confidence: Double
    public var timestamp: Date
    public var source: String // "iPhone", "Mac", "Watch"
    public var actionable: Bool
    public var data: Data? // Serialized insight data
    public var priority: Int = 0 // 0=low, 1=medium, 2=high, 3=critical
    
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    
    public init(id: UUID = UUID(), title: String, description: String, category: String, confidence: Double, timestamp: Date = Date(), source: String, actionable: Bool = false, data: Data? = nil, priority: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.confidence = confidence
        self.timestamp = timestamp
        self.source = source
        self.actionable = actionable
        self.data = data
        self.priority = priority
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
}

extension AnalyticsInsight {
    var ckRecord: CKRecord {
        let record = CKRecord(recordType: "AnalyticsInsight", recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["description"] = description
        record["category"] = category
        record["confidence"] = confidence
        record["timestamp"] = timestamp
        record["source"] = source
        record["actionable"] = actionable
        record["priority"] = priority
        record["syncVersion"] = syncVersion
        if let data = data {
            record["data"] = data
        }
        return record
    }
    
    convenience init?(from record: CKRecord) {
        guard let title = record["title"] as? String,
              let description = record["description"] as? String,
              let category = record["category"] as? String,
              let confidence = record["confidence"] as? Double,
              let timestamp = record["timestamp"] as? Date,
              let source = record["source"] as? String,
              let actionable = record["actionable"] as? Bool,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        self.init(
            id: id,
            title: title,
            description: description,
            category: category,
            confidence: confidence,
            timestamp: timestamp,
            source: source,
            actionable: actionable,
            data: record["data"] as? Data,
            priority: record["priority"] as? Int ?? 0
        )
        
        self.lastSyncDate = Date()
        self.needsSync = false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
}