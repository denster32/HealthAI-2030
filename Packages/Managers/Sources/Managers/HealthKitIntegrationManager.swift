import Foundation
import HealthKit
import Combine
import os.log

@available(iOS 17.0, macOS 14.0, *)
class HealthKitIntegrationManager: ObservableObject {
    private let logger = Logger(subsystem: "com.healthai.2030", category: "HealthKitIntegration")
    static let shared = HealthKitIntegrationManager()
    private let healthStore = HKHealthStore()

    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isDataAvailable: Bool = false
    @Published var lastDataUpdate: Date?
    @Published var dataQualityScore: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private var retryCount: Int = 0
    private let maxRetryAttempts = 3

    // Publishers for data streams
    let sleepAnalysisPublisher = PassthroughSubject<[HKCategorySample], Never>()
    let heartRatePublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let hrvPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let respiratoryRatePublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let stepCountPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let oxygenSaturationPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let workoutPublisher = PassthroughSubject<[HKWorkout], Never>()
    let bodyTemperaturePublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let activeEnergyPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let restingEnergyPublisher = PassthroughSubject<[HKQuantitySample], Never>()
    let bloodPressurePublisher = PassthroughSubject<[HKCorrelation], Never>()
    let mindfulnessPublisher = PassthroughSubject<[HKCategorySample], Never>()
    let audioExposurePublisher = PassthroughSubject<[HKQuantitySample], Never>()
    
    // Error and status publishers
    let errorPublisher = PassthroughSubject<HealthKitError, Never>()
    let statusPublisher = PassthroughSubject<DataCollectionStatus, Never>()

    private var sleepAnchor: HKQueryAnchor?
    private var heartRateAnchor: HKQueryAnchor?
    private var hrvAnchor: HKQueryAnchor?
    private var respiratoryAnchor: HKQueryAnchor?
    private var stepCountAnchor: HKQueryAnchor?
    private var oxygenAnchor: HKQueryAnchor?
    private var workoutAnchor: HKQueryAnchor?
    private var bodyTemperatureAnchor: HKQueryAnchor?
    private var activeEnergyAnchor: HKQueryAnchor?
    private var restingEnergyAnchor: HKQueryAnchor?
    private var bloodPressureAnchor: HKQueryAnchor?
    private var mindfulnessAnchor: HKQueryAnchor?
    private var audioExposureAnchor: HKQueryAnchor?
    
    private var activeQueries: Set<HKQuery> = []
    private var dataQualityMetrics: [String: Double] = [:]

    private init() {
        checkHealthDataAvailability()
        setupDataQualityMonitoring()
    }

    /// Request authorization for HealthKit data types
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }

        let typesToRead: Set<HKObjectType> = [
            // Sleep & Recovery
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            
            // Cardiovascular
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.correlationType(forIdentifier: .bloodPressure)!,
            
            // Activity & Energy
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.workoutType(),
            
            // Body Metrics
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            
            // Environmental
            HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!,
            HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure)!,
            
            // iOS 18+ Health Features
            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
            HKObjectType.quantityType(forIdentifier: .walkingStepLength)!,
            HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage)!,
            HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage)!,
            HKObjectType.quantityType(forIdentifier: .stairAscentSpeed)!,
            HKObjectType.quantityType(forIdentifier: .stairDescentSpeed)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.error("HealthKit authorization failed: \(error.localizedDescription)")
                    self.errorPublisher.send(.authorizationFailed(error))
                    completion(false, error)
                    return
                }
                
                self.authorizationStatus = success ? .sharingAuthorized : .sharingDenied
                self.isDataAvailable = success
                
                if success {
                    self.logger.info("HealthKit authorization granted")
                    self.statusPublisher.send(.authorized)
                    self.startDataQualityAssessment()
                } else {
                    self.logger.warning("HealthKit authorization denied")
                    self.statusPublisher.send(.denied)
                }
                
                completion(success, error)
            }
        }
    }

    /// Start all observers with error handling and retry logic
    func startAllObservers() {
        guard authorizationStatus == .sharingAuthorized else {
            logger.warning("Attempted to start observers without authorization")
            errorPublisher.send(.notAuthorized)
            return
        }
        
        logger.info("Starting all HealthKit observers")
        statusPublisher.send(.collecting)
        
        // Core health metrics
        startObservingSleepAnalysis()
        startObservingHeartRate()
        startObservingHRV()
        startObservingRespiratoryRate()
        startObservingStepCount()
        startObservingOxygenSaturation()
        startObservingWorkouts()
        
        // Extended health metrics
        startObservingBodyTemperature()
        startObservingActiveEnergy()
        startObservingRestingEnergy()
        startObservingBloodPressure()
        startObservingMindfulness()
        startObservingAudioExposure()
        
        // Start periodic data quality assessment
        startPeriodicDataQualityCheck()
    }
    
    /// Stop all observers and clean up resources
    func stopAllObservers() {
        logger.info("Stopping all HealthKit observers")
        
        activeQueries.forEach { query in
            healthStore.stop(query)
        }
        activeQueries.removeAll()
        
        cancellables.removeAll()
        statusPublisher.send(.stopped)
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

    // MARK: - Additional Observer Methods
    
    private func startObservingBodyTemperature() {
        startObservingQuantityType(.bodyTemperature, publisher: bodyTemperaturePublisher, anchor: &bodyTemperatureAnchor)
    }
    
    private func startObservingActiveEnergy() {
        startObservingQuantityType(.activeEnergyBurned, publisher: activeEnergyPublisher, anchor: &activeEnergyAnchor)
    }
    
    private func startObservingRestingEnergy() {
        startObservingQuantityType(.basalEnergyBurned, publisher: restingEnergyPublisher, anchor: &restingEnergyAnchor)
    }
    
    private func startObservingMindfulness() {
        guard let sampleType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: mindfulnessAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            self?.handleCategorySamples(samples as? [HKCategorySample], error: error, publisher: self?.mindfulnessPublisher, anchor: &self?.mindfulnessAnchor, newAnchor: newAnchor)
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            self?.handleCategorySamples(samples as? [HKCategorySample], error: error, publisher: self?.mindfulnessPublisher, anchor: &self?.mindfulnessAnchor, newAnchor: newAnchor)
        }
        executeQuery(query)
    }
    
    private func startObservingAudioExposure() {
        startObservingQuantityType(.environmentalAudioExposure, publisher: audioExposurePublisher, anchor: &audioExposureAnchor)
    }
    
    private func startObservingBloodPressure() {
        guard let correlationType = HKObjectType.correlationType(forIdentifier: .bloodPressure) else { return }
        let query = HKAnchoredObjectQuery(type: correlationType, predicate: nil, anchor: bloodPressureAnchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            self?.handleCorrelationSamples(samples as? [HKCorrelation], error: error, publisher: self?.bloodPressurePublisher, anchor: &self?.bloodPressureAnchor, newAnchor: newAnchor)
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            self?.handleCorrelationSamples(samples as? [HKCorrelation], error: error, publisher: self?.bloodPressurePublisher, anchor: &self?.bloodPressureAnchor, newAnchor: newAnchor)
        }
        executeQuery(query)
    }
    
    // MARK: - Helper Methods
    
    private func startObservingQuantityType(_ identifier: HKQuantityTypeIdentifier, publisher: PassthroughSubject<[HKQuantitySample], Never>, anchor: inout HKQueryAnchor?) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: identifier) else { return }
        let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: anchor, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, error in
            self?.handleQuantitySamples(samples as? [HKQuantitySample], error: error, publisher: publisher, anchor: &anchor, newAnchor: newAnchor)
        }
        query.updateHandler = { [weak self] _, samples, _, newAnchor, error in
            self?.handleQuantitySamples(samples as? [HKQuantitySample], error: error, publisher: publisher, anchor: &anchor, newAnchor: newAnchor)
        }
        executeQuery(query)
    }
    
    private func handleQuantitySamples(_ samples: [HKQuantitySample]?, error: Error?, publisher: PassthroughSubject<[HKQuantitySample], Never>, anchor: inout HKQueryAnchor?, newAnchor: HKQueryAnchor?) {
        if let error = error {
            logger.error("HealthKit query error: \(error.localizedDescription)")
            errorPublisher.send(.queryFailed(error))
            return
        }
        
        guard let samples = samples, !samples.isEmpty else { return }
        
        publisher.send(samples)
        anchor = newAnchor
        updateDataQualityMetrics(for: samples)
        lastDataUpdate = Date()
    }
    
    private func handleCategorySamples(_ samples: [HKCategorySample]?, error: Error?, publisher: PassthroughSubject<[HKCategorySample], Never>?, anchor: inout HKQueryAnchor?, newAnchor: HKQueryAnchor?) {
        if let error = error {
            logger.error("HealthKit category query error: \(error.localizedDescription)")
            errorPublisher.send(.queryFailed(error))
            return
        }
        
        guard let samples = samples, !samples.isEmpty, let publisher = publisher else { return }
        
        publisher.send(samples)
        anchor = newAnchor
        lastDataUpdate = Date()
    }
    
    private func handleCorrelationSamples(_ samples: [HKCorrelation]?, error: Error?, publisher: PassthroughSubject<[HKCorrelation], Never>?, anchor: inout HKQueryAnchor?, newAnchor: HKQueryAnchor?) {
        if let error = error {
            logger.error("HealthKit correlation query error: \(error.localizedDescription)")
            errorPublisher.send(.queryFailed(error))
            return
        }
        
        guard let samples = samples, !samples.isEmpty, let publisher = publisher else { return }
        
        publisher.send(samples)
        anchor = newAnchor
        lastDataUpdate = Date()
    }
    
    private func executeQuery(_ query: HKQuery) {
        activeQueries.insert(query)
        healthStore.execute(query)
    }
    
    private func checkHealthDataAvailability() {
        isDataAvailable = HKHealthStore.isHealthDataAvailable()
        if !isDataAvailable {
            logger.warning("HealthKit data not available on this device")
            errorPublisher.send(.notAvailable)
        }
    }
    
    private func setupDataQualityMonitoring() {
        Timer.publish(every: 300, on: .main, in: .default) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.assessDataQuality()
            }
            .store(in: &cancellables)
    }
    
    private func startDataQualityAssessment() {
        assessDataQuality()
    }
    
    private func startPeriodicDataQualityCheck() {
        Timer.publish(every: 3600, on: .main, in: .default) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                self?.performDataQualityCheck()
            }
            .store(in: &cancellables)
    }
    
    private func updateDataQualityMetrics(for samples: [HKQuantitySample]) {
        let sampleType = samples.first?.quantityType.identifier ?? ""
        let completeness = calculateCompleteness(for: samples)
        dataQualityMetrics[sampleType] = completeness
        
        // Update overall data quality score
        let averageQuality = dataQualityMetrics.values.reduce(0, +) / Double(dataQualityMetrics.count)
        dataQualityScore = averageQuality
    }
    
    private func calculateCompleteness(for samples: [HKQuantitySample]) -> Double {
        guard !samples.isEmpty else { return 0.0 }
        
        let now = Date()
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let recentSamples = samples.filter { $0.startDate >= dayAgo }
        
        return min(1.0, Double(recentSamples.count) / 100.0) // Normalize to 0-1 based on expected sample count
    }
    
    private func assessDataQuality() {
        let overall = dataQualityMetrics.values.reduce(0, +) / Double(max(dataQualityMetrics.count, 1))
        dataQualityScore = overall
        
        if overall < 0.3 {
            logger.warning("Low data quality detected: \(overall)")
            errorPublisher.send(.lowDataQuality)
        }
    }
    
    private func performDataQualityCheck() {
        guard let lastUpdate = lastDataUpdate else {
            logger.warning("No recent data updates detected")
            errorPublisher.send(.noRecentData)
            return
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceUpdate > 7200 { // 2 hours
            logger.warning("Data appears stale, last update: \(lastUpdate)")
            errorPublisher.send(.staleData)
        }
    }
    
    // MARK: - Public API Methods
    
    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    func fetchLatestSample<T: HKSample>(for type: HKSampleType, completion: @escaping (T?, Error?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            completion(samples?.first as? T, error)
        }
        healthStore.execute(query)
    }
    
    func fetchSamples<T: HKSample>(for type: HKSampleType, from startDate: Date, to endDate: Date, completion: @escaping ([T]?, Error?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            completion(samples as? [T], error)
        }
        healthStore.execute(query)
    }
    
    // MARK: - Error Types and Status
    
    enum HealthKitError: Error {
        case notAvailable
        case notAuthorized
        case authorizationFailed(Error)
        case queryFailed(Error)
        case lowDataQuality
        case noRecentData
        case staleData
        
        var localizedDescription: String {
            switch self {
            case .notAvailable:
                return "HealthKit is not available on this device"
            case .notAuthorized:
                return "HealthKit access not authorized"
            case .authorizationFailed(let error):
                return "Authorization failed: \(error.localizedDescription)"
            case .queryFailed(let error):
                return "Query failed: \(error.localizedDescription)"
            case .lowDataQuality:
                return "Data quality is below acceptable threshold"
            case .noRecentData:
                return "No recent data updates detected"
            case .staleData:
                return "Data appears to be stale"
            }
        }
    }
    
    enum DataCollectionStatus {
        case notStarted
        case authorized
        case denied
        case collecting
        case stopped
        case error(HealthKitError)
    }
}
