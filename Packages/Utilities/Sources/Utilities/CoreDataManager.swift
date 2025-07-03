import Foundation
import CoreData
import HealthKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HealthAI2030")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved Core Data error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData(olderThan days: Int) {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            print("Failed to calculate cutoff date for data cleanup.")
            return
        }
        
        // Clean up health data
        let healthDataRequest: NSFetchRequest<NSFetchRequestResult> = HealthDataEntity.fetchRequest()
        healthDataRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        let healthDataDeleteRequest = NSBatchDeleteRequest(fetchRequest: healthDataRequest)
        
        do {
            try context.execute(healthDataDeleteRequest)
            saveContext()
            print("Cleaned up data older than \(days) days")
        } catch {
            print("Failed to cleanup old data: \(error)")
        }
    }
    
    // MARK: - Baseline Data Helper
    
    func loadBaselineHealthData() -> BaselineHealthData {
        // Return default baseline data for now
        return BaselineHealthData(
            averageHeartRate: 70.0,
            averageHRV: 40.0,
            averageSleepDuration: 28800.0, // 8 hours
            averageSteps: 8000,
            seasonalPatterns: [:],
            circadianPatterns: [:]
        )
    }
    
    // MARK: - Sensor Data Management
    
    func saveSensorSamples(_ samples: [SensorSample]) {
        guard !samples.isEmpty else { return }
        
        let context = persistentContainer.viewContext
        
        for sample in samples {
            // Create a simple dictionary representation for Core Data
            let entity = NSEntityDescription.entity(forEntityName: "SensorDataEntity", in: context)
            if let entity = entity {
                let sensorData = NSManagedObject(entity: entity, insertInto: context)
                sensorData.setValue(sample.type.rawValue, forKey: "type")
                sensorData.setValue(sample.value, forKey: "value")
                sensorData.setValue(sample.unit, forKey: "unit")
                sensorData.setValue(sample.timestamp, forKey: "timestamp")
            }
        }
        
        saveContext()
    }
    
    func fetchRecentSensorData(limit: Int = 1000) -> [SensorSample] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SensorDataEntity")
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { object in
                guard let typeString = object.value(forKey: "type") as? String,
                      let type = SensorType(rawValue: typeString),
                      let value = object.value(forKey: "value") as? Double,
                      let unit = object.value(forKey: "unit") as? String,
                      let timestamp = object.value(forKey: "timestamp") as? Date else {
                    return nil
                }
                
                return SensorSample(type: type, value: value, unit: unit, timestamp: timestamp)
            }
        } catch {
            print("Failed to fetch sensor data: \(error)")
            return []
        }
    }
}