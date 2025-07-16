import HealthAI2030Core
import Foundation
import HealthKit
import CoreData
import SwiftData
import CloudKit
import OSLog

/// Protocol for health data management operations
protocol HealthDataManaging {
    func saveHealthData(_ data: CoreHealthDataModel) async throws
    func fetchHealthData(startDate: Date, endDate: Date, dataType: CoreHealthDataModel.HealthDataType) async throws -> [CoreHealthDataModel]
    func deleteHealthData(_ id: UUID) async throws
    func updateHealthData(_ data: CoreHealthDataModel) async throws
}

/// Modern HealthDataManager using SwiftData for persistence and CloudKit for sync
/// Implements dependency injection pattern for better testability and modularity
@available(iOS 18.0, macOS 15.0, *)
@MainActor
class HealthDataManager: HealthDataManaging, ObservableObject {
    
    // MARK: - Dependencies (Dependency Injection)
    private let swiftDataManager: SwiftDataManager
    private let healthKitStore: HKHealthStore?
    private let cloudKitSyncManager: UnifiedCloudKitSyncManager
    private let privacySecurityManager: PrivacySecurityManager
    private let logger: Logger
    
    // MARK: - Published Properties
    @Published var isInitialized: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: CloudKitSyncStatus = .notStarted
    
    // MARK: - Initialization
    
    /// Initialize with dependency injection for better testability
    init(
        swiftDataManager: SwiftDataManager = .shared,
        healthKitStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil,
        cloudKitSyncManager: UnifiedCloudKitSyncManager = .shared,
        privacySecurityManager: PrivacySecurityManager = .shared
    ) {
        self.swiftDataManager = swiftDataManager
        self.healthKitStore = healthKitStore
        self.cloudKitSyncManager = cloudKitSyncManager
        self.privacySecurityManager = privacySecurityManager
        self.logger = Logger(subsystem: "com.healthai2030.HealthDataManager", category: "HealthData")
        
        Task {
            await initialize()
        }
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        logger.info("Initializing HealthDataManager...")
        
        do {
            // Initialize SwiftData manager
            guard swiftDataManager.modelContainer != nil else {
                throw HealthDataError.swiftDataNotAvailable
            }
            
            // Setup CloudKit sync
            await cloudKitSyncManager.setupCloudKit()
            
            // Request HealthKit permissions if available
            if let healthKitStore = healthKitStore {
                await requestHealthKitPermissions(store: healthKitStore)
            }
            
            isInitialized = true
            logger.info("HealthDataManager initialized successfully")
            
        } catch {
            logger.error("Failed to initialize HealthDataManager: \(error.localizedDescription)")
            throw HealthDataError.initializationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - HealthKit Permissions
    
    private func requestHealthKitPermissions(store: HKHealthStore) async {
        let healthKitTypes: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await store.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes)
            logger.info("HealthKit permissions granted")
        } catch {
            logger.warning("HealthKit permissions not granted: \(error.localizedDescription)")
        }
    }
    
    // MARK: - HealthDataManaging Implementation
    
    func saveHealthData(_ data: CoreHealthDataModel) async throws {
        guard isInitialized else {
            throw HealthDataError.notInitialized
        }
        
        logger.info("Saving health data: \(data.dataType.rawValue)")
        
        do {
            // Convert to SwiftData model
            let healthDataEntry = HealthDataEntry(
                timestamp: data.timestamp,
                dataType: data.dataType.rawValue,
                value: data.metricValue,
                stringValue: nil,
                source: data.sourceDevice,
                privacyConsentGiven: true
            )
            
            // Save to SwiftData
            try await swiftDataManager.save(healthDataEntry)
            
            // Save to HealthKit if available and appropriate
            if let hkSample = data.toHealthKitSample() {
                try await healthKitStore?.save(hkSample)
                logger.debug("Saved to HealthKit: \(data.dataType.rawValue)")
            }
            
            // Sync to CloudKit
            try await cloudKitSyncManager.upsert(healthDataEntry)
            
            logger.info("Successfully saved health data: \(data.dataType.rawValue)")
            
        } catch {
            logger.error("Failed to save health data: \(error.localizedDescription)")
            throw HealthDataError.saveFailed(error.localizedDescription)
        }
    }
    
    func fetchHealthData(startDate: Date, endDate: Date, dataType: CoreHealthDataModel.HealthDataType) async throws -> [CoreHealthDataModel] {
        guard isInitialized else {
            throw HealthDataError.notInitialized
        }
        
        logger.info("Fetching health data: \(dataType.rawValue) from \(startDate) to \(endDate)")
        
        do {
            // Create predicate for date range and data type
            let predicate = #Predicate<HealthDataEntry> { entry in
                entry.timestamp >= startDate && entry.timestamp <= endDate && entry.dataType == dataType.rawValue
            }
            
            // Fetch from SwiftData
            let swiftDataResults = try await swiftDataManager.fetch(
                HealthDataEntry.self,
                predicate: predicate,
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            // Convert to CoreHealthDataModel
            let results = swiftDataResults.compactMap { entry -> CoreHealthDataModel? in
                guard let dataType = CoreHealthDataModel.HealthDataType(rawValue: entry.dataType) else {
                    return nil
                }
                
                return CoreHealthDataModel(
                    id: entry.id,
                    timestamp: entry.timestamp,
                    sourceDevice: entry.source,
                    dataType: dataType,
                    metricValue: entry.value ?? 0.0,
                    unit: getUnitForDataType(dataType), // Add unit support
                    metadata: nil
                )
            }
            
            // If no results from SwiftData, try HealthKit
            if results.isEmpty, let hkResults = try await fetchFromHealthKit(startDate: startDate, endDate: endDate, dataType: dataType) {
                logger.info("Fetched \(hkResults.count) records from HealthKit")
                return hkResults
            }
            
            logger.info("Fetched \(results.count) records from SwiftData")
            return results
            
        } catch {
            logger.error("Failed to fetch health data: \(error.localizedDescription)")
            throw HealthDataError.fetchFailed(error.localizedDescription)
        }
    }
    
    func deleteHealthData(_ id: UUID) async throws {
        guard isInitialized else {
            throw HealthDataError.notInitialized
        }
        
        logger.info("Deleting health data with ID: \(id)")
        
        do {
            // Find the entry to delete
            let predicate = #Predicate<HealthDataEntry> { entry in
                entry.id == id
            }
            
            let entries = try await swiftDataManager.fetch(HealthDataEntry.self, predicate: predicate)
            
            guard let entryToDelete = entries.first else {
                throw HealthDataError.recordNotFound
            }
            
            // Delete from SwiftData
            try await swiftDataManager.delete(entryToDelete)
            
            // Delete from CloudKit
            try await cloudKitSyncManager.delete(entryToDelete)
            
            logger.info("Successfully deleted health data with ID: \(id)")
            
        } catch {
            logger.error("Failed to delete health data: \(error.localizedDescription)")
            throw HealthDataError.deleteFailed(error.localizedDescription)
        }
    }
    
    func updateHealthData(_ data: CoreHealthDataModel) async throws {
        guard isInitialized else {
            throw HealthDataError.notInitialized
        }
        
        logger.info("Updating health data: \(data.dataType.rawValue)")
        
        do {
            // Find existing entry
            let predicate = #Predicate<HealthDataEntry> { entry in
                entry.id == data.id
            }
            
            let entries = try await swiftDataManager.fetch(HealthDataEntry.self, predicate: predicate)
            
            guard let existingEntry = entries.first else {
                throw HealthDataError.recordNotFound
            }
            
            // Update entry
            existingEntry.timestamp = data.timestamp
            existingEntry.dataType = data.dataType.rawValue
            existingEntry.value = data.metricValue
            existingEntry.source = data.sourceDevice
            
            // Save changes
            try await swiftDataManager.update(existingEntry)
            
            // Sync to CloudKit
            try await cloudKitSyncManager.upsert(existingEntry)
            
            logger.info("Successfully updated health data: \(data.dataType.rawValue)")
            
        } catch {
            logger.error("Failed to update health data: \(error.localizedDescription)")
            throw HealthDataError.updateFailed(error.localizedDescription)
        }
    }
    
    // MARK: - HealthKit Integration
    
    private func fetchFromHealthKit(startDate: Date, endDate: Date, dataType: CoreHealthDataModel.HealthDataType) async throws -> [CoreHealthDataModel]? {
        guard let healthKitStore = healthKitStore,
              let hkType = dataType.healthKitType else { 
            return nil 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hkType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let results = samples?.compactMap { CoreHealthDataModel(from: $0) } ?? []
                continuation.resume(returning: results)
            }
            
            healthKitStore.execute(query)
        }
    }
    
    // MARK: - Unit Support
    
    private func getUnitForDataType(_ dataType: CoreHealthDataModel.HealthDataType) -> String {
        switch dataType {
        case .heartRate:
            return "BPM"
        case .sleepAnalysis:
            return "hours"
        case .respiratoryRate:
            return "breaths/min"
        case .bloodOxygen:
            return "%"
        case .bloodPressure:
            return "mmHg"
        case .activity:
            return "steps"
        case .nutrition:
            return "calories"
        case .cognitive:
            return "minutes"
        }
    }
    
    private func getHealthKitUnit(for dataType: CoreHealthDataModel.HealthDataType) -> HKUnit {
        switch dataType {
        case .heartRate:
            return .count().unitDivided(by: .minute())
        case .sleepAnalysis:
            return .hour()
        case .respiratoryRate:
            return .count().unitDivided(by: .minute())
        case .bloodOxygen:
            return .percent()
        case .bloodPressure:
            return .millimeterOfMercury()
        case .activity:
            return .count()
        case .nutrition:
            return .kilocalorie()
        case .cognitive:
            return .minute()
        }
    }
    
    private func convertValue(_ value: Double, from sourceUnit: String, to targetUnit: String) -> Double {
        // Convert between different units if needed
        switch (sourceUnit, targetUnit) {
        case ("BPM", "beats/min"):
            return value // Same unit, different representation
        case ("hours", "minutes"):
            return value * 60
        case ("minutes", "hours"):
            return value / 60
        case ("calories", "kcal"):
            return value // Same unit, different representation
        default:
            return value // No conversion needed or not supported
        }
    }
    
    private func validateUnit(_ unit: String, for dataType: CoreHealthDataModel.HealthDataType) -> Bool {
        let expectedUnit = getUnitForDataType(dataType)
        return unit == expectedUnit || isCompatibleUnit(unit, expectedUnit: expectedUnit)
    }
    
    private func isCompatibleUnit(_ unit: String, expectedUnit: String) -> Bool {
        // Check if units are compatible (e.g., "BPM" and "beats/min")
        let compatibleUnits: [String: [String]] = [
            "BPM": ["beats/min", "BPM"],
            "hours": ["hours", "hrs", "h"],
            "minutes": ["minutes", "mins", "min"],
            "calories": ["calories", "kcal", "Cal"],
            "steps": ["steps", "count"],
            "%": ["%", "percent"]
        ]
        
        return compatibleUnits[expectedUnit]?.contains(unit) ?? false
    }
}

// MARK: - HealthKit Integration Extensions

extension CoreHealthDataModel {
    init?(from sample: HKSample) {
        // Extract data from HKSample based on type
        switch sample {
        case let quantitySample as HKQuantitySample:
            let value = quantitySample.quantity.doubleValue(for: .count())
            self = CoreHealthDataModel(
                id: UUID(),
                timestamp: quantitySample.startDate,
                sourceDevice: quantitySample.device?.name ?? "Unknown",
                dataType: .heartRate, // Default, should be mapped properly
                metricValue: value,
                unit: quantitySample.unit.unitString,
                metadata: nil
            )
        case let categorySample as HKCategorySample:
            self = CoreHealthDataModel(
                id: UUID(),
                timestamp: categorySample.startDate,
                sourceDevice: categorySample.device?.name ?? "Unknown",
                dataType: .sleepAnalysis, // Default, should be mapped properly
                metricValue: Double(categorySample.value),
                unit: "",
                metadata: nil
            )
        default:
            return nil
        }
    }
    
    func toHealthKitSample() -> HKSample? {
        // Convert to appropriate HKSample type
        switch dataType {
        case .heartRate:
            let quantity = HKQuantity(unit: .count(), doubleValue: metricValue)
            return HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                quantity: quantity,
                start: timestamp,
                end: timestamp,
                device: nil,
                metadata: metadata
            )
        case .sleepAnalysis:
            return HKCategorySample(
                type: HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
                value: Int(metricValue),
                start: timestamp,
                end: timestamp,
                device: nil,
                metadata: metadata
            )
        default:
            return nil
        }
    }
}

extension CoreHealthDataModel.HealthDataType {
    var healthKitType: HKSampleType? {
        switch self {
        case .heartRate:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)
        case .sleepAnalysis:
            return HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        case .respiratoryRate:
            return HKQuantityType.quantityType(forIdentifier: .respiratoryRate)
        case .bloodOxygen:
            return HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
        case .bloodPressure:
            return HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)
        case .activity:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .nutrition:
            return HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)
        case .cognitive:
            return HKCategoryType.categoryType(forIdentifier: .mindfulSession)
        }
    }
}

// MARK: - Error Types

enum HealthDataError: Error, LocalizedError {
    case notInitialized
    case swiftDataNotAvailable
    case initializationFailed(String)
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case updateFailed(String)
    case recordNotFound
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "HealthDataManager not initialized"
        case .swiftDataNotAvailable:
            return "SwiftData not available"
        case .initializationFailed(let message):
            return "Initialization failed: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .recordNotFound:
            return "Record not found"
        }
    }
}