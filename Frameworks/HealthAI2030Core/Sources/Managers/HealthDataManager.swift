import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import Foundation
import HealthKit
import CoreData

protocol HealthDataManaging {
    func saveHealthData(_ data: CoreHealthDataModel) async throws
    func fetchHealthData(startDate: Date, endDate: Date, dataType: CoreHealthDataModel.HealthDataType) async throws -> [CoreHealthDataModel]
    func deleteHealthData(_ id: UUID) async throws
}

class HealthDataManager: HealthDataManaging {
    static let shared = HealthDataManager()
    
    private let healthKitStore: HKHealthStore?
    private let coreDataStack: CoreDataStack
    private let cloudKitSyncManager: CloudKitSyncManaging?
    
    init(healthKitStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil,
         coreDataStack: CoreDataStack = .shared,
         cloudKitSyncManager: CloudKitSyncManaging? = nil) {
        self.healthKitStore = healthKitStore
        self.coreDataStack = coreDataStack
        self.cloudKitSyncManager = cloudKitSyncManager
    }
    
    func saveHealthData(_ data: CoreHealthDataModel) async throws {
        // Save to CoreData
        try await coreDataStack.saveHealthData(data)
        
        // Save to HealthKit if available and appropriate
        if let hkSample = data.toHealthKitSample() {
            try await healthKitStore?.save(hkSample)
        }
        
        // Sync to CloudKit
        try await cloudKitSyncManager?.syncHealthData(data)
    }
    
    func fetchHealthData(startDate: Date, endDate: Date, dataType: CoreHealthDataModel.HealthDataType) async throws -> [CoreHealthDataModel] {
        // First try to fetch from CoreData
        let coreDataResults = try await coreDataStack.fetchHealthData(startDate: startDate, endDate: endDate, dataType: dataType)
        
        // If no results, try HealthKit
        if coreDataResults.isEmpty, let hkResults = try await fetchFromHealthKit(startDate: startDate, endDate: endDate, dataType: dataType) {
            return hkResults
        }
        
        return coreDataResults
    }
    
    func deleteHealthData(_ id: UUID) async throws {
        try await coreDataStack.deleteHealthData(id)
        try await cloudKitSyncManager?.deleteHealthData(id)
    }
    
    private func fetchFromHealthKit(startDate: Date, endDate: Date, dataType: CoreHealthDataModel.HealthDataType) async throws -> [CoreHealthDataModel]? {
        guard let hkType = dataType.healthKitType else { return nil }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: hkType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let results = samples?.compactMap { CoreHealthDataModel(from: $0) } ?? []
                continuation.resume(returning: results)
            }
            
            healthKitStore?.execute(query)
        }
    }
}

// MARK: - HealthKit Integration
extension CoreHealthDataModel {
    init?(from sample: HKSample) {
        // Conversion logic from HKSample to CoreHealthDataModel
        // Implementation details omitted for brevity
        return nil
    }
    
    func toHealthKitSample() -> HKSample? {
        // Conversion logic to appropriate HKSample type
        // Implementation details omitted for brevity
        return nil
    }
}

extension CoreHealthDataModel.HealthDataType {
    var healthKitType: HKSampleType? {
        switch self {
        case .heartRate: return HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .sleepAnalysis: return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        // Other mappings...
        default: return nil
        }
    }
}