import Foundation
import HealthKit
import Combine

@available(iOS 17.0, macOS 14.0, *)
class HealthKitIntegrationManager: ObservableObject {
    static let shared = HealthKitIntegrationManager()
    private let healthStore = HKHealthStore()

    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined

    // Publishers for data streams
    let sleepAnalysisPublisher = PassthroughSubject<[HKCategorySample], Never>()
    let heartRatePublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let hrvPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let respiratoryRatePublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let stepCountPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let oxygenSaturationPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let workoutPublisher = PassthroughSubject<[HKWorkout], Never>()

    private var sleepAnchor: HKQueryAnchor?
    private var heartRateAnchor: HKQueryAnchor?
    private var hrvAnchor: HKQueryAnchor?
    private var respiratoryAnchor: HKQueryAnchor?
    private var stepCountAnchor: HKQueryAnchor?
    private var oxygenAnchor: HKQueryAnchor?
    private var workoutAnchor: HKQueryAnchor?

    private init() {}

    /// Request authorization for HealthKit data types
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
            // add additional types as needed
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.authorizationStatus = success ? .sharingAuthorized : .sharingDenied
            }
            completion(success, error)
        }
    }

    /// Start all observers
    func startAllObservers() {
        startObservingSleepAnalysis()
        startObservingHeartRate()
        startObservingHRV()
        startObservingRespiratoryRate()
        startObservingStepCount()
        startObservingOxygenSaturation()
        startObservingWorkouts()
    }

    /// Fetch historical sleep analysis for the past `daysBack` days (default 90)
    func fetchHistoricalSleepAnalysis(daysBack: Int = 90,
                                      completion: @escaping ([HKCategorySample]?, Error?) -> Void) {
        guard authorizationStatus == .sharingAuthorized else {
            completion(nil, HealthKitError.notAuthorized)
            return
        }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -daysBack, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        let query = HKSampleQuery(sampleType: sampleType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, results, error in
            completion(results as? [HKCategorySample], error)
        }
        healthStore.execute(query)
    }

    /// Start streaming updates for sleep analysis samples
    func startObservingSleepAnalysis() {
        let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let query = HKAnchoredObjectQuery(type: sampleType,
                                          predicate: nil,
                                          anchor: sleepAnchor,
                                          limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            guard let self = self, let samples = samples as? [HKCategorySample] else { return }
            self.sleepAnalysisPublisher.send(samples)
            self.sleepAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKCategorySample] else { return }
            self.sleepAnalysisPublisher.send(samples)
            self.sleepAnchor = newAnchor
        }
        healthStore.execute(query)
    }
    
    /// Start streaming updates for heart rate
    func startObservingHeartRate() {
        let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: heartRateAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.heartRatePublisher.send(samples)
            self.heartRateAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.heartRatePublisher.send(samples)
            self.heartRateAnchor = newAnchor
        }
        healthStore.execute(query)
    }
    
    /// Start streaming updates for HRV
    func startObservingHRV() {
        let sampleType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: hrvAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.hrvPublisher.send(samples)
            self.hrvAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.hrvPublisher.send(samples)
            self.hrvAnchor = newAnchor
        }
        healthStore.execute(query)
    }
    
    /// Start streaming updates for respiratory rate
    func startObservingRespiratoryRate() {
        let sampleType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: respiratoryAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.respiratoryRatePublisher.send(samples)
            self.respiratoryAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.respiratoryRatePublisher.send(samples)
            self.respiratoryAnchor = newAnchor
        }
        healthStore.execute(query)
    }
    
    /// Start streaming updates for step count
    func startObservingStepCount() {
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: stepCountAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.stepCountPublisher.send(samples)
            self.stepCountAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.stepCountPublisher.send(samples)
            self.stepCountAnchor = newAnchor
        }
        healthStore.execute(query)
    }
    
    /// Start streaming updates for oxygen saturation
    func startObservingOxygenSaturation() {
        let sampleType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: oxygenAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.oxygenSaturationPublisher.send(samples)
            self.oxygenAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKQuantitySample] else { return }
            self.oxygenSaturationPublisher.send(samples)
            self.oxygenAnchor = newAnchor
        }
        healthStore.execute(query)
    }
    
    /// Start streaming updates for workouts
    func startObservingWorkouts() {
        let sampleType = HKObjectType.workoutType()
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: workoutAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKWorkout] else { return }
            self.workoutPublisher.send(samples)
            self.workoutAnchor = newAnchor
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, _ in
            guard let self = self, let samples = samples as? [HKWorkout] else { return }
            self.workoutPublisher.send(samples)
            self.workoutAnchor = newAnchor
        }
        healthStore.execute(query)
    }

    /// Error types for HealthKit operations
    enum HealthKitError: Error {
        case notAvailable
        case notAuthorized
    }
}
