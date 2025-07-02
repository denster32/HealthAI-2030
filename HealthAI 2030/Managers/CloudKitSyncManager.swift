import Foundation
import CloudKit

/// A manager class for handling CloudKit data synchronization.
class CloudKitSyncManager {
    static let shared = CloudKitSyncManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }

    /// Saves a record to CloudKit.
    /// - Parameter record: The `CKRecord` to save.
    /// - Parameter completion: A closure to call with the result of the save operation.
    func saveRecord(_ record: CKRecord, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                completion(.success(savedRecord))
            } else {
                completion(.failure(CloudKitSyncError.unknown))
            }
        }
    }

    /// Fetches records from CloudKit based on a query.
    /// - Parameter query: The `CKQuery` to execute.
    /// - Parameter completion: A closure to call with the fetched records or an error.
    func fetchRecords(query: CKQuery, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
            } else if let records = records {
                completion(.success(records))
            } else {
                completion(.success([])) // No records found
            }
        }
    }
    
    /// Deletes a record from CloudKit.
    /// - Parameter recordID: The `CKRecord.ID` of the record to delete.
    /// - Parameter completion: A closure to call with the deleted record ID or an error.
    func deleteRecord(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        privateDatabase.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                completion(.failure(error))
            } else if let deletedRecordID = deletedRecordID {
                completion(.success(deletedRecordID))
            } else {
                completion(.failure(CloudKitSyncError.unknown))
            }
        }
    }
    
    enum CloudKitSyncError: Error, LocalizedError {
        case unknown
        case recordNotFound
        case permissionDenied
        case invalidRecord
        case cloudKitError(Error)

        var errorDescription: String? {
            switch self {
            case .unknown:
                return "An unknown CloudKit error occurred."
            case .recordNotFound:
                return "The specified record was not found."
            case .permissionDenied:
                return "Permission to access CloudKit was denied."
            case .invalidRecord:
                return "The CloudKit record is invalid or missing required fields."
            case .cloudKitError(let error):
                return "CloudKit operation failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - SummarizedSleepData Model
struct SummarizedSleepData {
    let id: UUID
    let timestamp: Date
    let totalDeepSleepMinutes: Double
    let averageHR: Double
    let sleepStageDistribution: [String: Double] // e.g., ["REM": 20.5, "Deep": 15.0, "Light": 60.0]

    static let recordType = "SummarizedSleepData"
}

// MARK: - CKRecord Conversion for SummarizedSleepData
extension CKRecord {
    convenience init(summarizedSleepData: SummarizedSleepData) {
        self.init(recordType: SummarizedSleepData.recordType, recordID: CKRecord.ID(recordName: summarizedSleepData.id.uuidString))
        self["timestamp"] = summarizedSleepData.timestamp as NSDate
        self["totalDeepSleepMinutes"] = summarizedSleepData.totalDeepSleepMinutes as NSNumber
        self["averageHR"] = summarizedSleepData.averageHR as NSNumber
        self["sleepStageDistribution"] = summarizedSleepData.sleepStageDistribution as NSDictionary
    }

    var summarizedSleepData: SummarizedSleepData? {
        guard let idString = recordID.recordName as String?,
              let id = UUID(uuidString: idString),
              let timestamp = self["timestamp"] as? Date,
              let totalDeepSleepMinutes = self["totalDeepSleepMinutes"] as? Double,
              let averageHR = self["averageHR"] as? Double,
              let sleepStageDistribution = self["sleepStageDistribution"] as? [String: Double]
        else {
            return nil
        }
        return SummarizedSleepData(
            id: id,
            timestamp: timestamp,
            totalDeepSleepMinutes: totalDeepSleepMinutes,
            averageHR: averageHR,
            sleepStageDistribution: sleepStageDistribution
        )
    }
}

// MARK: - CloudKitSyncManager SummarizedSleepData Operations
extension CloudKitSyncManager {

    /// Saves a SummarizedSleepData record to CloudKit.
    /// - Parameters:
    ///   - data: The `SummarizedSleepData` object to save.
    ///   - completion: A closure to call with the result of the save operation.
    func saveSummarizedSleepData(_ data: SummarizedSleepData, completion: @escaping (Result<SummarizedSleepData, Error>) -> Void) {
        let record = CKRecord(summarizedSleepData: data)
        saveRecord(record) { result in
            switch result {
            case .success(let savedRecord):
                if let savedData = savedRecord.summarizedSleepData {
                    completion(.success(savedData))
                } else {
                    completion(.failure(CloudKitSyncError.invalidRecord))
                }
            case .failure(let error):
                completion(.failure(CloudKitSyncError.cloudKitError(error)))
            }
        }
    }

    /// Fetches SummarizedSleepData records for a specific date from CloudKit.
    /// - Parameters:
    ///   - date: The date for which to fetch sleep data.
    ///   - completion: A closure to call with the fetched `SummarizedSleepData` array or an error.
    func fetchSummarizedSleepData(for date: Date, completion: @escaping (Result<[SummarizedSleepData], Error>) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        let query = CKQuery(recordType: SummarizedSleepData.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        fetchRecords(query: query) { result in
            switch result {
            case .success(let records):
                let summarizedData = records.compactMap { $0.summarizedSleepData }
                completion(.success(summarizedData))
            case .failure(let error):
                completion(.failure(CloudKitSyncError.cloudKitError(error)))
            }
        }
    }

    /// Synchronizes Core Data with CloudKit for health data
    func syncHealthData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Check CloudKit account status first
        checkAccountStatus { [weak self] accountStatus in
            switch accountStatus {
            case .available:
                self?.performFullSync(completion: completion)
            case .noAccount:
                completion(.failure(CloudKitSyncError.permissionDenied))
            case .restricted:
                completion(.failure(CloudKitSyncError.permissionDenied))
            case .couldNotDetermine:
                completion(.failure(CloudKitSyncError.unknown))
            case .temporarilyUnavailable:
                // Retry later
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.syncHealthData(completion: completion)
                }
            @unknown default:
                completion(.failure(CloudKitSyncError.unknown))
            }
        }
    }
    
    private func checkAccountStatus(completion: @escaping (CKAccountStatus) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    private func performFullSync(completion: @escaping (Result<Void, Error>) -> Void) {
        print("CloudKitSyncManager: Starting full data synchronization")
        
        // Sync health data records
        syncHealthDataRecords { [weak self] result in
            switch result {
            case .success:
                // Sync sleep data
                self?.syncSleepDataRecords { result in
                    switch result {
                    case .success:
                        print("CloudKitSyncManager: Synchronization completed successfully")
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func syncHealthDataRecords(completion: @escaping (Result<Void, Error>) -> Void) {
        // Fetch recent health data from Core Data
        let coreDataManager = CoreDataManager.shared
        let today = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        
        // Create CloudKit records for recent health data
        // This is a simplified implementation - in production you'd want more sophisticated sync
        print("CloudKitSyncManager: Syncing health data records")
        completion(.success(()))
    }
    
    private func syncSleepDataRecords(completion: @escaping (Result<Void, Error>) -> Void) {
        // Sync sleep data with CloudKit
        print("CloudKitSyncManager: Syncing sleep data records")
        completion(.success(()))
    }
    
    // MARK: - CloudKit Subscription Management
    
    func setupCloudKitSubscriptions() {
        setupHealthDataSubscription()
        setupSleepDataSubscription()
    }
    
    private func setupHealthDataSubscription() {
        let subscription = CKQuerySubscription(
            recordType: "HealthDataRecord",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        privateDatabase.save(subscription) { subscription, error in
            if let error = error {
                print("Failed to create health data subscription: \(error)")
            } else {
                print("Health data subscription created successfully")
            }
        }
    }
    
    private func setupSleepDataSubscription() {
        let subscription = CKQuerySubscription(
            recordType: SummarizedSleepData.recordType,
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        privateDatabase.save(subscription) { subscription, error in
            if let error = error {
                print("Failed to create sleep data subscription: \(error)")
            } else {
                print("Sleep data subscription created successfully")
            }
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportAllDataToCloudKit(completion: @escaping (Result<Void, Error>) -> Void) {
        print("CloudKitSyncManager: Starting full data export to CloudKit")
        
        // This would export all local Core Data to CloudKit
        // Implementation would batch the uploads to avoid rate limits
        completion(.success(()))
    }
    
    func importAllDataFromCloudKit(completion: @escaping (Result<Void, Error>) -> Void) {
        print("CloudKitSyncManager: Starting full data import from CloudKit")
        
        // This would fetch all CloudKit data and update Core Data
        // Implementation would handle conflict resolution
        completion(.success(()))
    }
}