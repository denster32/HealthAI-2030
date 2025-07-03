import Foundation
import HealthKit
import Combine

/// HealthDataAnalyzer: Analyzes all Apple Health data on install, prefers Mac if available
class HealthDataAnalyzer: ObservableObject {
    static let shared = HealthDataAnalyzer()
    private let healthStore = HKHealthStore()
    @Published var analysisResults: [String: Any] = [:]
    
    func analyzeAllHealthData(preferMac: Bool = false) {
        #if os(macOS)
        if preferMac {
            analyzeOnMac()
            return
        }
        #endif
        analyzeOnDevice()
    }
    
    private func analyzeOnMac() {
        // Use HealthKit on macOS Sonoma+ or iCloud Health sync
        // Fetch and analyze all available health data
        fetchAllHealthData { data in
            self.analysisResults = self.performAnalysis(on: data)
        }
    }
    
    private func analyzeOnDevice() {
        // Use HealthKit on iOS/watchOS
        fetchAllHealthData { data in
            self.analysisResults = self.performAnalysis(on: data)
        }
    }
    
    private func fetchAllHealthData(completion: @escaping ([HKSample]) -> Void) {
        // Request authorization and fetch all health samples
        let types: Set = [HKObjectType.quantityType(forIdentifier: .stepCount)!,
                          HKObjectType.quantityType(forIdentifier: .heartRate)!,
                          HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                          HKObjectType.quantityType(forIdentifier: .sleepAnalysis)!]
        healthStore.requestAuthorization(toShare: [], read: types) { success, error in
            guard success else { completion([]); return }
            let group = DispatchGroup()
            var allSamples: [HKSample] = []
            for type in types {
                group.enter()
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                    if let samples = samples {
                        allSamples.append(contentsOf: samples)
                    }
                    group.leave()
                }
                self.healthStore.execute(query)
            }
            group.notify(queue: .main) {
                completion(allSamples)
            }
        }
    }
    
    private func performAnalysis(on samples: [HKSample]) -> [String: Any] {
        // Analyze all health data: trends, anomalies, predictions, etc.
        // Production: Use ML/analytics modules
        var results: [String: Any] = [:]
        // Example: Count steps, average heart rate, etc.
        let stepSamples = samples.compactMap { $0 as? HKQuantitySample }.filter { $0.quantityType.identifier == HKQuantityTypeIdentifier.stepCount.rawValue }
        let totalSteps = stepSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .count()) }
        results["totalSteps"] = totalSteps
        // ...add more analytics...
        return results
    }
}
