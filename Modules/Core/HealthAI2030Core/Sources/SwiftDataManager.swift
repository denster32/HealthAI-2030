import Foundation
import SwiftData
import CloudKit
import OSLog
import Analytics
import HealthKit
import os

/// Manages all SwiftData storage, retrieval, and sync operations for the app.
///
/// ## Model Requirements
/// - All models must conform to `PersistentModel` and `CKSyncable` protocols
/// - Models must have a UUID `id` property for CloudKit sync
/// - Models should implement conflict resolution in `resolveConflict(with:)`
///
/// ## CloudKit Sync Behavior
/// - Sync happens automatically in background
/// - Conflicts are resolved using timestamp comparison
/// - Sync status can be checked via `CKSyncable.syncStatus`
///
/// ## Error Handling
/// - All operations throw `SwiftDataError` on failure
/// - Context availability is checked before operations
/// - Errors are logged via OSLog
///
/// ## Supported Operations
/// - CRUD operations for all model types
/// - Batch fetch/delete operations
/// - CloudKit sync integration
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class SwiftDataManager: ObservableObject {
    /// Shared singleton instance for global access.
    public static let shared = SwiftDataManager()

    /// The main SwiftData model container.
    public var modelContainer: ModelContainer?
    
    private let privacySecurityManager = PrivacySecurityManager.shared
    private let logger = Logger(subsystem: "com.healthai2030.SwiftDataManager", category: "SwiftData")
    private let errorHandler = ErrorHandlingService.shared

    private init() {
        do {
            let schema = Schema([
                HealthDataEntry.self,
                AnalyticsInsight.self,
                MLModelUpdate.self,
                ExportRequest.self,
                SyncableMoodEntry.self,
                SyncableCardiacEvent.self,
                SyncableSleepQuickAction.self,
                SyncableHealthDataEntry.self, // Added for CloudKit sync
                SyncableSleepSessionEntry.self, // Added for CloudKit sync
                HealthData.self,
                DigitalTwin.self
            ])
            
            // Migration configuration
            let migrationPlan = SchemaMigrationPlan(
                from: Schema([LegacyCoreDataModel.self]), // For CoreData migration
                to: schema,
                stages: [
                    .lightweight, // Automatic lightweight migration
                    .custom({ context in
                        // Custom migration logic for complex cases
                        try migrateCoreDataEntities(to: context)
                    })
                ]
            )
            
            let config = ModelConfiguration(
                schema: schema,
                migrationPlan: migrationPlan,
                cloudKitContainerIdentifier: "iCloud.com.healthai2030",
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: config)
            if let container = modelContainer {
                self.modelContext = ModelContext(container)
            }
        } catch {
            logger.error("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    /// Migrates CoreData entities to SwiftData
    private func migrateCoreDataEntities(to context: ModelContext) throws {
        // 1. Fetch legacy CoreData entities
        let legacyEntities = try CoreDataManager.shared.fetchAllLegacyEntities()
        
        // 2. Convert to SwiftData models
        for legacyEntity in legacyEntities {
            let newEntity = HealthDataEntry(
                id: legacyEntity.id,
                timestamp: legacyEntity.timestamp,
                dataType: legacyEntity.dataType,
                value: legacyEntity.value,
                stringValue: legacyEntity.stringValue,
                unit: legacyEntity.unit,
                source: legacyEntity.source,
                deviceSource: legacyEntity.deviceSource,
                provenance: legacyEntity.provenance,
                metadata: legacyEntity.metadata,
                isValidated: legacyEntity.isValidated,
                validationErrors: legacyEntity.validationErrors
            )
            context.insert(newEntity)
        }
        
        // 3. Save migrated data
        try context.save()
    }

    /// Provides access to the main model context for data operations
    var context: ModelContext? {
        return modelContext
    }

    /// Saves changes to the model context
    func saveContext() throws {
        guard let context = modelContext else {
            throw SwiftDataError.noContextAvailable
        }
        try context.save()
    }

    /// Fetches HealthData entries for a specific data type
    func fetchHealthData(forDataType type: String) throws -> [HealthData] {
        guard let context = modelContext else {
            throw SwiftDataError.noContextAvailable
        }
        return fetchHealthData(forDataType: type, in: context)
    }

    /// Adds a new HealthData entry and saves it
    func addHealthData(dataType: String, value: Double, unit: String? = nil, source: String? = nil) throws {
        guard let context = modelContext else {
            throw SwiftDataError.noContextAvailable
        }
        let newEntry = HealthData(timestamp: Date(), dataType: dataType, value: value, unit: unit, source: source)
        context.insert(newEntry)
        try saveContext()
    }

    /// Fetches DigitalTwin for a specific user ID
    func fetchDigitalTwin(forUserID userID: String) throws -> DigitalTwin? {
        guard let context = modelContext else {
            throw SwiftDataError.noContextAvailable
        }
        return fetchDigitalTwin(forUserID: userID, in: context)
    }

    /// Adds or updates a DigitalTwin for a user
    func updateDigitalTwin(userID: String, healthProfile: Data? = nil, predictiveModelVersion: String = "1.0") throws {
        guard let context = modelContext else {
            throw SwiftDataError.noContextAvailable
        }
        if let existingTwin = try fetchDigitalTwin(forUserID: userID) {
            existingTwin.lastUpdated = Date()
            existingTwin.healthProfile = healthProfile ?? existingTwin.healthProfile
            existingTwin.predictiveModelVersion = predictiveModelVersion
        } else {
            let newTwin = DigitalTwin(userID: userID, healthProfile: healthProfile, predictiveModelVersion: predictiveModelVersion)
            context.insert(newTwin)
        }
        try saveContext()
    }

    /// Ensures the shared instance is created and container is set up.
    public func initialize() async throws {
        // Check HealthKit permissions
        try await checkHealthKitPermissions()
        
        // Setup CloudKit shared zone
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        try await SyncableHealthDataEntry.setupSharedRecordZone(in: database)
        
        logger.info("SwiftDataManager initialized with HealthKit permissions and CloudKit setup.")
    }
    
    /// Checks and requests HealthKit permissions
    private func checkHealthKitPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw SwiftDataError.healthKitUnavailable
        }
        
        let healthStore = HKHealthStore()
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            logger.info("HealthKit permissions granted")
        } catch {
            logger.error("HealthKit permission error: \(error.localizedDescription)")
            throw SwiftDataError.healthKitPermissionDenied
        }
    }

    /// Saves a persistent model using a background context.
    public func save<T: PersistentModel & CKSyncable>(_ model: T) async throws {
        guard let container = modelContainer else {
            logger.error("Failed to get model container for saving.")
            throw SwiftDataError.contextUnavailable
        }
        
        // Enforce privacy settings before saving
        if !privacySecurityManager.isSharingAllowed(for: model.dataType) {
            privacySecurityManager.auditDataAccess(action: "Save Denied", dataType: model.dataType, details: "Data save denied due to privacy settings for \(String(describing: T.self)) with ID \(model.id)")
            throw SwiftDataError.privacyDenied(model.dataType.rawValue)
        }
        
        let startTime = DispatchTime.now()
        let context = ModelContext(container)
        
        await context.perform {
            do {
                context.insert(model)
                try context.save()
                let duration = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
                self.logger.info("Saved \(String(describing: T.self)) in \(duration)ms")
                self.privacySecurityManager.auditDataAccess(action: "Save", dataType: model.dataType, details: "Successfully saved \(String(describing: T.self)) with ID \(model.id)")
            } catch {
                self.logger.error("Failed to save \(String(describing: T.self)): \(error.localizedDescription)")
                self.privacySecurityManager.auditDataAccess(action: "Save Failed", dataType: model.dataType, details: "Failed to save \(String(describing: T.self)) with ID \(model.id): \(error.localizedDescription)")
                throw error
            }
        }
    }

    /// Fetches persistent models using a background context with optimized batch size.
    public func fetch<T: PersistentModel & CKSyncable>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        batchSize: Int = 100
    ) async throws -> [T] {
        guard let container = modelContainer else {
            logger.error("Failed to get model container for fetching.")
            throw SwiftDataError.contextUnavailable
        }
        
        let startTime = DispatchTime.now()
        let context = ModelContext(container)
        var results = [T]()
        
        await context.perform {
            do {
                var descriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)
                descriptor.fetchLimit = batchSize
                descriptor.propertiesToFetch = [\.id] // Only fetch IDs first
                
                let ids = try context.fetchIdentifiers(descriptor)
                results = try ids.compactMap { id in
                    if let model = try context.existingModel(with: id) as? T {
                        // Enforce privacy settings before returning fetched data
                        if self.privacySecurityManager.isSharingAllowed(for: model.dataType) {
                            self.privacySecurityManager.auditDataAccess(action: "Fetch", dataType: model.dataType, details: "Successfully fetched \(String(describing: T.self)) with ID \(model.id)")
                            return model
                        } else {
                            self.privacySecurityManager.auditDataAccess(action: "Fetch Denied", dataType: model.dataType, details: "Data fetch denied due to privacy settings for \(String(describing: T.self)) with ID \(model.id)")
                            return nil // Do not return data if sharing is not allowed
                        }
                    }
                    return nil
                }
                
                let duration = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
                self.logger.info("Fetched \(results.count) \(String(describing: T.self)) in \(duration)ms")
            } catch {
                self.logger.error("Failed to fetch \(String(describing: T.self)): \(error.localizedDescription)")
                throw error
            }
        }
        
        return results
    }

    /// Deletes a persistent model using a background context.
    public func delete<T: PersistentModel & CKSyncable>(_ model: T) async throws {
        guard let container = modelContainer else {
            logger.error("Failed to get model container for deleting.")
            throw SwiftDataError.contextUnavailable
        }
        
        // Enforce privacy settings before deleting
        if !privacySecurityManager.isSharingAllowed(for: model.dataType) {
            privacySecurityManager.auditDataAccess(action: "Delete Denied", dataType: model.dataType, details: "Data delete denied due to privacy settings for \(String(describing: T.self)) with ID \(model.id)")
            throw SwiftDataError.privacyDenied(model.dataType.rawValue)
        }
        
        let startTime = DispatchTime.now()
        let context = ModelContext(container)
        
        await context.perform {
            do {
                context.delete(model)
                try context.save()
                let duration = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
                self.logger.info("Deleted \(String(describing: T.self)) in \(duration)ms")
                self.privacySecurityManager.auditDataAccess(action: "Delete", dataType: model.dataType, details: "Successfully deleted \(String(describing: T.self)) with ID \(model.id)")
            } catch {
                self.logger.error("Failed to delete \(String(describing: T.self)): \(error.localizedDescription)")
                self.privacySecurityManager.auditDataAccess(action: "Delete Failed", dataType: model.dataType, details: "Failed to delete \(String(describing: T.self)) with ID \(model.id): \(error.localizedDescription)")
                throw error
            }
        }
    }

    /// Updates a persistent model in the main context.
    ///
    /// - Note: In SwiftData, modifying an existing model object within a context automatically stages the changes.
    public func update<T: PersistentModel & CKSyncable>(_ model: T) async throws {
        guard let context = modelContainer?.mainContext else {
            logger.error("Failed to get main context for updating.")
            throw SwiftDataError.contextUnavailable
        }
        
        // Enforce privacy settings before updating
        if !privacySecurityManager.isSharingAllowed(for: model.dataType) {
            privacySecurityManager.auditDataAccess(action: "Update Denied", dataType: model.dataType, details: "Data update denied due to privacy settings for \(String(describing: T.self)) with ID \(model.id)")
            throw SwiftDataError.privacyDenied(model.dataType.rawValue)
        }
        
        // In SwiftData, modifying an existing model object within a context automatically stages the changes.
        // No explicit 'update' method is usually needed, just ensure the object is in the context and save.
        do {
            try context.save()
            logger.info("Updated \(String(describing: T.self)) with ID \(model.id)")
            privacySecurityManager.auditDataAccess(action: "Update", dataType: model.dataType, details: "Successfully updated \(String(describing: T.self)) with ID \(model.id)")
        } catch {
            logger.error("Failed to update \(String(describing: T.self)): \(error.localizedDescription)")
            privacySecurityManager.auditDataAccess(action: "Update Failed", dataType: model.dataType, details: "Failed to update \(String(describing: T.self)) with ID \(model.id): \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetches a model by ID or creates it if not found.
    public func fetchOrCreate<T: PersistentModel & CKSyncable>(id: UUID, createBlock: () -> T) async throws -> T {
        guard let context = modelContainer?.mainContext else {
            logger.error("Failed to get main context for fetchOrCreate.")
            throw SwiftDataError.contextUnavailable
        }
        let predicate = #Predicate<T> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        do {
            if let existing = try context.fetch(descriptor).first {
                // Enforce privacy settings before returning fetched data
                if privacySecurityManager.isSharingAllowed(for: existing.dataType) {
                    logger.info("Fetched existing \(String(describing: T.self)) with ID \(id)")
                    privacySecurityManager.auditDataAccess(action: "FetchOrCreate (Fetched)", dataType: existing.dataType, details: "Successfully fetched existing \(String(describing: T.self)) with ID \(id)")
                    return existing
                } else {
                    privacySecurityManager.auditDataAccess(action: "FetchOrCreate (Fetch Denied)", dataType: existing.dataType, details: "Data fetch denied due to privacy settings for existing \(String(describing: T.self)) with ID \(id)")
                    throw SwiftDataError.privacyDenied(existing.dataType.rawValue)
                }
            } else {
                let newModel = createBlock()
                // Enforce privacy settings before saving new data
                if !privacySecurityManager.isSharingAllowed(for: newModel.dataType) {
                    privacySecurityManager.auditDataAccess(action: "FetchOrCreate (Create Denied)", dataType: newModel.dataType, details: "Data creation denied due to privacy settings for new \(String(describing: T.self)) with ID \(newModel.id)")
                    throw SwiftDataError.privacyDenied(newModel.dataType.rawValue)
                }
                context.insert(newModel)
                try context.save()
                logger.info("Created and saved new \(String(describing: T.self)) with ID \(id)")
                privacySecurityManager.auditDataAccess(action: "FetchOrCreate (Created)", dataType: newModel.dataType, details: "Successfully created and saved new \(String(describing: T.self)) with ID \(newModel.id)")
                return newModel
            }
        } catch {
            logger.error("Failed to fetch or create \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetches all models of a given type.
    public func fetchAll<T: PersistentModel & CKSyncable>() async throws -> [T] {
        guard let context = modelContainer?.mainContext else {
            logger.error("Failed to get main context for fetchAll.")
            throw SwiftDataError.contextUnavailable
        }
        let descriptor = FetchDescriptor<T>()
        do {
            let allResults = try context.fetch(descriptor)
            let filteredResults = allResults.filter { model in
                if privacySecurityManager.isSharingAllowed(for: model.dataType) {
                    privacySecurityManager.auditDataAccess(action: "FetchAll", dataType: model.dataType, details: "Successfully fetched \(String(describing: T.self)) with ID \(model.id)")
                    return true
                } else {
                    privacySecurityManager.auditDataAccess(action: "FetchAll Denied", dataType: model.dataType, details: "Data fetch denied due to privacy settings for \(String(describing: T.self)) with ID \(model.id)")
                    return false
                }
            }
            logger.info("Fetched all \(filteredResults.count) records of type \(String(describing: T.self)) (filtered from \(allResults.count))")
            return filteredResults
        } catch {
            logger.error("Failed to fetch all \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Deletes all models of a given type.
    public func deleteAll<T: PersistentModel & CKSyncable>(_ modelType: T.Type) async throws {
        guard let context = modelContainer?.mainContext else {
            logger.error("Failed to get main context for deleteAll.")
            throw SwiftDataError.contextUnavailable
        }
        do {
            // Fetch all models of the type to apply privacy checks individually
            let modelsToDelete = try context.fetch(FetchDescriptor<T>())
            for model in modelsToDelete {
                if !privacySecurityManager.isSharingAllowed(for: model.dataType) {
                    privacySecurityManager.auditDataAccess(action: "DeleteAll Denied", dataType: model.dataType, details: "Data delete denied due to privacy settings for \(String(describing: T.self)) with ID \(model.id)")
                    // Optionally, you could skip this item or throw a specific error
                    continue
                }
                context.delete(model)
                privacySecurityManager.auditDataAccess(action: "DeleteAll", dataType: model.dataType, details: "Successfully marked \(String(describing: T.self)) with ID \(model.id) for deletion")
            }
            try context.save()
            logger.info("Deleted all records of type \(String(describing: modelType)) (after privacy checks)")
        } catch {
            logger.error("Failed to delete all records of type \(String(describing: modelType)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Configure the manager with a model context
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - User Profile Operations
    
    /// Create a new user profile
    func createUserProfile(_ profile: UserProfile) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            modelContext.insert(profile)
            try modelContext.save()
            logger.info("User profile created: \(profile.email)")
        } catch {
            let dataError = DataError.createFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to create user profile")
            throw dataError
        }
    }
    
    /// Fetch user profile by ID
    func fetchUserProfile(id: UUID) async throws -> UserProfile? {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            let request = FetchDescriptor<UserProfile>(
                predicate: #Predicate<UserProfile> { $0.id == id }
            )
            let profiles = try modelContext.fetch(request)
            return profiles.first
        } catch {
            let dataError = DataError.fetchFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to retrieve user profile")
            throw dataError
        }
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: UserProfile) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            profile.lastUpdated = Date()
            try modelContext.save()
            logger.info("User profile updated: \(profile.email)")
        } catch {
            let dataError = DataError.updateFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to update user profile")
            throw dataError
        }
    }
    
    /// Delete user profile
    func deleteUserProfile(_ profile: UserProfile) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            modelContext.delete(profile)
            try modelContext.save()
            logger.info("User profile deleted: \(profile.email)")
        } catch {
            let dataError = DataError.deleteFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to delete user profile")
            throw dataError
        }
    }
    
    // MARK: - Health Data Operations
    
    /// Create health data entry
    func createHealthData(_ healthData: HealthData) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            modelContext.insert(healthData)
            try modelContext.save()
            logger.info("Health data created: \(healthData.dataType)")
        } catch {
            let dataError = DataError.createFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to save health data")
            throw dataError
        }
    }
    
    /// Fetch health data for a user
    func fetchHealthData(for userID: UUID, dataType: String? = nil) async throws -> [HealthData] {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            var predicate: Predicate<HealthData>
            if let dataType = dataType {
                predicate = #Predicate<HealthData> { 
                    $0.userProfile?.id == userID && $0.dataType == dataType 
                }
            } else {
                predicate = #Predicate<HealthData> { $0.userProfile?.id == userID }
            }
            
            let request = FetchDescriptor<HealthData>(
                predicate: predicate,
                sortBy: [SortDescriptor(\HealthData.timestamp, order: .reverse)]
            )
            return try modelContext.fetch(request)
        } catch {
            let dataError = DataError.fetchFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to retrieve health data")
            throw dataError
        }
    }
    
    /// Update health data entry
    func updateHealthData(_ healthData: HealthData) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            healthData.lastUpdated = Date()
            try modelContext.save()
            logger.info("Health data updated: \(healthData.dataType)")
        } catch {
            let dataError = DataError.updateFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to update health data")
            throw dataError
        }
    }
    
    /// Delete health data entry
    func deleteHealthData(_ healthData: HealthData) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            modelContext.delete(healthData)
            try modelContext.save()
            logger.info("Health data deleted: \(healthData.dataType)")
        } catch {
            let dataError = DataError.deleteFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to delete health data")
            throw dataError
        }
    }
    
    // MARK: - Digital Twin Operations
    
    /// Create digital twin
    func createDigitalTwin(_ digitalTwin: DigitalTwin) async throws {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            modelContext.insert(digitalTwin)
            try modelContext.save()
            logger.info("Digital twin created for user: \(digitalTwin.userID)")
        } catch {
            let dataError = DataError.createFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to create digital twin")
            throw dataError
        }
    }
    
    /// Fetch digital twin for user
    func fetchDigitalTwin(for userID: String) async throws -> DigitalTwin? {
        guard let modelContext = modelContext else {
            let error = DataError.modelContextNotConfigured
            errorHandler.handle(error, userMessage: "Data system not properly configured")
            throw error
        }
        
        do {
            let request = FetchDescriptor<DigitalTwin>(
                predicate: #Predicate<DigitalTwin> { $0.userID == userID }
            )
            let twins = try modelContext.fetch(request)
            return twins.first
        } catch {
            let dataError = DataError.fetchFailed(error)
            errorHandler.handle(dataError, userMessage: "Failed to retrieve digital twin")
            throw dataError
        }
    }
}

/// Errors for SwiftDataManager operations.
public enum SwiftDataError: Error {
    case contextUnavailable
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case migrationFailed(String)
    case healthKitUnavailable
    case healthKitPermissionDenied
    case cloudKitSyncError(CloudKitSyncError)
    case privacyDenied(String) // New error for privacy enforcement
    case noContextAvailable
    
    var recoverySuggestion: String {
        switch self {
        case .healthKitUnavailable:
            return "HealthKit is not available on this device"
        case .healthKitPermissionDenied:
            return "Please enable HealthKit permissions in Settings"
        case .cloudKitSyncError(let ckError):
            return ckError.recoverySuggestion
        case .privacyDenied(let dataType):
            return "Access to \(dataType) data is denied by privacy settings. Please adjust your privacy preferences."
        case .noContextAvailable:
            return "No valid context available for this operation"
        default:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Data Errors
enum DataError: Int, AppError {
    case modelContextNotConfigured = 3001
    case createFailed = 3002
    case fetchFailed = 3003
    case updateFailed = 3004
    case deleteFailed = 3005
    case validationFailed = 3006
    
    var errorDescription: String? {
        switch self {
        case .modelContextNotConfigured:
            return "SwiftData model context not configured"
        case .createFailed(let error):
            return "Failed to create data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .validationFailed(let error):
            return "Data validation failed: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelContextNotConfigured:
            return "Ensure the app is properly initialized"
        case .createFailed:
            return "Check your data and try again"
        case .fetchFailed:
            return "Check your connection and try again"
        case .updateFailed:
            return "Ensure the data is valid and try again"
        case .deleteFailed:
            return "Check if the data is still available and try again"
        case .validationFailed:
            return "Check your input data and try again"
        }
    }
    
    var errorCode: Int { rawValue }
    var domain: String { "com.HealthAI2030.SwiftData" }
    static var errorDomain: String { "com.HealthAI2030.SwiftData" }
}
