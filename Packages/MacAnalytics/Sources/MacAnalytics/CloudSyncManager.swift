import Foundation
import CloudKit

public class CloudSyncManager {
    private let container = CKContainer(identifier: "iCloud.com.yourorg.HealthAI")
    private let database = CKContainer(identifier: "iCloud.com.yourorg.HealthAI").privateCloudDatabase

    public init() {}

    /// Pull raw metrics records from CloudKit
    public func pullRawMetrics() async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "RawMetric", predicate: predicate)
        let (matchResults, _) = try await database.records(matching: query)
        return matchResults.compactMap { try? $0.1.get() }
    }

    /// Pull anomaly records within date range
    public func pullAnomalyRecords(for dateRange: DateInterval) async throws -> [CKRecord] {
        let start = dateRange.start
        let end = dateRange.end
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as CVarArg, end as CVarArg)
        let query = CKQuery(recordType: "AnomalyRecord", predicate: predicate)
        let (matchResults, _) = try await database.records(matching: query)
        return matchResults.compactMap { try? $0.1.get() }
    }

    /// Push results or aggregated records back to CloudKit
    public func pushResults(_ records: [CKRecord]) async throws {
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.isAtomic = false
        try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
            database.add(operation)
        }
    }
}
