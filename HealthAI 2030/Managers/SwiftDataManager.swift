import Foundation
import SwiftData
import CloudKit
import OSLog
import Analytics

/// Manages all SwiftData storage, retrieval, and sync operations for the app.
///
/// - Handles unified health data, analytics, ML model updates, and export requests.
/// - Integrates with CloudKit for sync and OSLog for diagnostics.
/// - TODO: Add more granular error handling and test coverage.
@available(iOS 18.0, macOS 15.0, *)
public class SwiftDataManager: ObservableObject {
    /// Shared singleton instance for global access.
    public static let shared = SwiftDataManager()

    /// The main SwiftData model container.
    public var modelContainer: ModelContainer?

    private init() {
        do {
            modelContainer = try ModelContainer(for:
                HealthDataEntry.self, // New unified health data model
                AnalyticsInsight.self,
                MLModelUpdate.self,
                ExportRequest.self
            )
        } catch {
            Logger.swiftData.error("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    /// Ensures the shared instance is created and container is set up.
    public func initialize() {
        // This function is called to ensure the shared instance is created and container is set up.
        // The actual initialization logic is in the private init.
        Logger.swiftData.info("SwiftDataManager initialized.")
    }

    /// Saves a persistent model to the main context.
    public func save<T: PersistentModel>(_ model: T) async throws {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for saving.")
            throw SwiftDataError.contextUnavailable
        }
        context.insert(model)
        do {
            try context.save()
            Logger.swiftData.info("Saved \(String(describing: T.self)) with ID \(model.id)")
        } catch {
            Logger.swiftData.error("Failed to save \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetches persistent models matching the given predicate and sort descriptors.
    public func fetch<T: PersistentModel>(predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) async throws -> [T] {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for fetching.")
            throw SwiftDataError.contextUnavailable
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: sortBy)
        do {
            let results = try context.fetch(descriptor)
            Logger.swiftData.info("Fetched \(results.count) records of type \(String(describing: T.self))")
            return results
        } catch {
            Logger.swiftData.error("Failed to fetch \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Deletes a persistent model from the main context.
    public func delete<T: PersistentModel>(_ model: T) async throws {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for deleting.")
            throw SwiftDataError.contextUnavailable
        }
        context.delete(model)
        do {
            try context.save()
            Logger.swiftData.info("Deleted \(String(describing: T.self)) with ID \(model.id)")
        } catch {
            Logger.swiftData.error("Failed to delete \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Updates a persistent model in the main context.
    ///
    /// - Note: In SwiftData, modifying an existing model object within a context automatically stages the changes.
    public func update<T: PersistentModel>(_ model: T) async throws {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for updating.")
            throw SwiftDataError.contextUnavailable
        }
        // In SwiftData, modifying an existing model object within a context automatically stages the changes.
        // No explicit 'update' method is usually needed, just ensure the object is in the context and save.
        do {
            try context.save()
            Logger.swiftData.info("Updated \(String(describing: T.self)) with ID \(model.id)")
        } catch {
            Logger.swiftData.error("Failed to update \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetches a model by ID or creates it if not found.
    public func fetchOrCreate<T: PersistentModel & CKSyncable>(id: UUID, createBlock: () -> T) async throws -> T {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for fetchOrCreate.")
            throw SwiftDataError.contextUnavailable
        }
        let predicate = #Predicate<T> { $0.id == id }
        let descriptor = FetchDescriptor(predicate: predicate)
        do {
            if let existing = try context.fetch(descriptor).first {
                Logger.swiftData.info("Fetched existing \(String(describing: T.self)) with ID \(id)")
                return existing
            } else {
                let newModel = createBlock()
                context.insert(newModel)
                try context.save()
                Logger.swiftData.info("Created and saved new \(String(describing: T.self)) with ID \(id)")
                return newModel
            }
        } catch {
            Logger.swiftData.error("Failed to fetch or create \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetches all models of a given type.
    public func fetchAll<T: PersistentModel>() async throws -> [T] {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for fetchAll.")
            throw SwiftDataError.contextUnavailable
        }
        let descriptor = FetchDescriptor<T>()
        do {
            let results = try context.fetch(descriptor)
            Logger.swiftData.info("Fetched all \(results.count) records of type \(String(describing: T.self))")
            return results
        } catch {
            Logger.swiftData.error("Failed to fetch all \(String(describing: T.self)): \(error.localizedDescription)")
            throw error
        }
    }

    /// Deletes all models of a given type.
    public func deleteAll<T: PersistentModel>(_ modelType: T.Type) async throws {
        guard let context = modelContainer?.mainContext else {
            Logger.swiftData.error("Failed to get main context for deleteAll.")
            throw SwiftDataError.contextUnavailable
        }
        do {
            try context.delete(model: modelType)
            try context.save()
            Logger.swiftData.info("Deleted all records of type \(String(describing: modelType))")
        } catch {
            Logger.swiftData.error("Failed to delete all records of type \(String(describing: modelType)): \(error.localizedDescription)")
            throw error
        }
    }
}

/// Errors for SwiftDataManager operations.
public enum SwiftDataError: Error {
    case contextUnavailable
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
}
// TODO: Add unit tests for SwiftDataManager.
// TODO: Document model requirements and sync strategies.
