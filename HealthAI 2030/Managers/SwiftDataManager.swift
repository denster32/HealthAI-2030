import Foundation
import SwiftData
import OSLog

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class SwiftDataManager {
    private let modelContainer: ModelContainer
    private let logger = Logger(subsystem: "com.HealthAI2030.Data", category: "SwiftDataManager")

    public init() {
        do {
            let schema = Schema([
                HealthDataEntry.self,
                SleepSessionEntry.self,
                WorkoutEntry.self,
                NutritionLogEntry.self,
                SyncableHealthDataEntry.self,
                SyncableSleepSessionEntry.self,
                AnalyticsInsight.self,
                MLModelUpdate.self,
                ExportRequest.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("SwiftData container initialized successfully.")
        } catch {
            logger.critical("Failed to initialize SwiftData container: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Fetch Operations

    public func fetchHealthDataEntries(limit: Int? = nil) async -> [HealthDataEntry] {
        let descriptor = FetchDescriptor<HealthDataEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        do {
            let entries = try modelContainer.mainContext.fetch(descriptor)
            logger.debug("Fetched \(entries.count) health data entries.")
            return entries
        } catch {
            logger.error("Failed to fetch health data entries: \(error.localizedDescription)")
            return []
        }
    }

    public func fetchSleepSessionEntries(limit: Int? = nil) async -> [SleepSessionEntry] {
        let descriptor = FetchDescriptor<SleepSessionEntry>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            let entries = try modelContainer.mainContext.fetch(descriptor)
            logger.debug("Fetched \(entries.count) sleep session entries.")
            return entries
        } catch {
            logger.error("Failed to fetch sleep session entries: \(error.localizedDescription)")
            return []
        }
    }

    public func fetchWorkoutEntries(limit: Int? = nil) async -> [WorkoutEntry] {
        let descriptor = FetchDescriptor<WorkoutEntry>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            let entries = try modelContainer.mainContext.fetch(descriptor)
            logger.debug("Fetched \(entries.count) workout entries.")
            return entries
        } catch {
            logger.error("Failed to fetch workout entries: \(error.localizedDescription)")
            return []
        }
    }

    public func fetchNutritionLogEntries(limit: Int? = nil) async -> [NutritionLogEntry] {
        let descriptor = FetchDescriptor<NutritionLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            let entries = try modelContainer.mainContext.fetch(descriptor)
            logger.debug("Fetched \(entries.count) nutrition log entries.")
            return entries
        } catch {
            logger.error("Failed to fetch nutrition log entries: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Add Operations

    public func addHealthDataEntry(_ entry: HealthDataEntry) async {
        modelContainer.mainContext.insert(entry)
        await saveContext()
        logger.debug("Added new health data entry.")
    }

    public func addSleepSessionEntry(_ entry: SleepSessionEntry) async {
        modelContainer.mainContext.insert(entry)
        await saveContext()
        logger.debug("Added new sleep session entry.")
    }

    public func addWorkoutEntry(_ entry: WorkoutEntry) async {
        modelContainer.mainContext.insert(entry)
        await saveContext()
        logger.debug("Added new workout entry.")
    }

    public func addNutritionLogEntry(_ entry: NutritionLogEntry) async {
        modelContainer.mainContext.insert(entry)
        await saveContext()
        logger.debug("Added new nutrition log entry.")
    }

    // MARK: - Save Context

    private func saveContext() async {
        do {
            try modelContainer.mainContext.save()
        } catch {
            logger.error("Failed to save SwiftData context: \(error.localizedDescription)")
        }
    }
}
