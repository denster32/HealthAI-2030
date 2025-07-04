import Foundation
import HealthKit
import os.log

/// DataFusionEngine - Responsible for integrating multimodal health data into a unified DigitalTwin model.
class DataFusionEngine {
    
    private let dataManager: DataManager
    
    init(dataManager: DataManager = .shared) {
        self.dataManager = dataManager
    }
    
    /// Fuses various data sources to create or update a DigitalTwin.
    /// This method orchestrates the collection and integration of biometric, lifestyle,
    /// environmental, genomic, and clinical data into a comprehensive DigitalTwin object.
    func fuseDataIntoDigitalTwin() async throws {
        Logger.info("Starting data fusion for Digital Twin...", log: Logger.dataManager)
        
        // 1. Collect Biometric Data
        let biometricProfile = try await collectBiometricData()
        
        // 2. Collect Lifestyle Data
        let lifestyleProfile = try await collectLifestyleData()
        
        // 3. Collect Environmental Data
        let environmentalProfile = try await collectEnvironmentalData()
        
        // 4. Collect Genomic Data (Placeholder - requires user input/integration with external services)
        let genomicProfile: GenomicProfile? = nil // For now, assume no genomic data
        
        // 5. Collect Clinical Data (Placeholder - requires user input/integration with EHR systems)
        let clinicalProfile: ClinicalProfile? = nil // For now, assume no clinical data
        
        // 6. Assemble the Digital Twin
        let newTwin = DigitalTwin(
            biometricData: biometricProfile,
            genomicData: genomicProfile,
            clinicalData: clinicalProfile,
            lifestyleData: lifestyleProfile,
            environmentalContext: environmentalProfile
        )
        
        // 7. Update and save the Digital Twin via DataManager
        await MainActor.run {
            self.dataManager.digitalTwin = newTwin
        }
        dataManager.saveDigitalTwin()
        
        Logger.success("Digital Twin data fusion completed successfully.", log: Logger.dataManager)
        
        // Log the explanation for transparency
        let explanation = generateFusionExplanation()
        Logger.info(explanation, log: Logger.dataManager)
    }
    
    /// Provides an explanation of the data fusion process for the Digital Twin.
    /// This method generates a user-friendly summary of the data sources and their contributions.
    func generateFusionExplanation() -> String {
        var explanation = "Digital Twin Data Fusion Summary:\n"
        explanation += "\n1. Biometric Data:\n"
        explanation += "   - Heart Rate: Aggregated over the last 6 months.\n"
        explanation += "   - HRV: Aggregated over the last 6 months.\n"
        explanation += "   - Blood Oxygen: Aggregated over the last 6 months.\n"
        explanation += "\n2. Lifestyle Data:\n"
        explanation += "   - Sleep Duration: Average calculated from historical sleep data.\n"
        explanation += "   - Exercise: Placeholder value of 150 minutes per week.\n"
        explanation += "\n3. Environmental Data:\n"
        explanation += "   - Air Quality Index: Placeholder value of 45.\n"
        explanation += "   - Pollen Count: Placeholder value of 30.\n"
        explanation += "\n4. Genomic Data: Not available.\n"
        explanation += "\n5. Clinical Data: Not available.\n"
        explanation += "\nThis summary provides insights into how your Digital Twin is constructed."
        return explanation
    }
    
    // MARK: - Private Data Collection Methods
    
    private func collectBiometricData() async throws -> BiometricProfile {
        // This would involve querying HealthKit for a wider range of historical biometric data
        // and performing aggregation/analysis. For now, we'll use simplified data.
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) ?? endDate // Last 6 months
        
        // Fetch heart rate data
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateSamples = try await dataManager.healthStore.samples(of: heartRateType, predicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)) as? [HKQuantitySample] ?? []
        let heartRates = heartRateSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
        
        // Fetch HRV data
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvSamples = try await dataManager.healthStore.samples(of: hrvType, predicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)) as? [HKQuantitySample] ?? []
        let hrvs = hrvSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "ms")) }
        
        // Fetch Blood Oxygen data
        let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        let oxygenSamples = try await dataManager.healthStore.samples(of: oxygenType, predicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)) as? [HKQuantitySample] ?? []
        let bloodOxygens = oxygenSamples.map { $0.quantity.doubleValue(for: HKUnit.percent()) * 100 }
        
        return BiometricProfile(
            heartRateVariability: hrvs,
            restingHeartRate: heartRates,
            bloodOxygenSaturation: bloodOxygens
        )
    }
    
    private func collectLifestyleData() async throws -> LifestyleProfile {
        // This would involve querying HealthKit for activity, nutrition, and sleep data.
        // For now, we'll use simplified data based on existing sleep history.
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        
        let sleepSamples = try await dataManager.fetchHistoricalSleepData(from: startDate, to: endDate)
        let totalSleepDuration = sleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let averageSleepDuration = sleepSamples.isEmpty ? 0.0 : totalSleepDuration / Double(sleepSamples.count)
        
        // Placeholder for actual exercise minutes
        let weeklyExerciseMinutes = 150 // Target for moderate exercise
        
        return LifestyleProfile(
            averageSleepDuration: averageSleepDuration,
            weeklyExerciseMinutes: weeklyExerciseMinutes
        )
    }
    
    private func collectEnvironmentalData() async throws -> EnvironmentalProfile {
        // This would involve integrating with external environmental APIs.
        // For now, use placeholder data.
        return EnvironmentalProfile(
            airQualityIndex: 45, // Example AQI
            pollenCount: 30 // Example pollen count
        )
    }
}

// MARK: - DataManager Extension for HealthStore Access
// This extension allows DataFusionEngine to access healthStore from DataManager
extension DataManager {
    var healthStore: HKHealthStore {
        // Assuming healthStore is accessible or can be passed
        // For this example, we'll make it accessible for DataFusionEngine
        return HKHealthStore() // Re-initialize or expose existing one if private
    }
    
    // Expose fetchHistoricalSleepData for DataFusionEngine
    func fetchHistoricalSleepData(from startDate: Date, to endDate: Date) async throws -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw DataError.unsupportedDataType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await healthStore.samples(of: sleepType, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
}