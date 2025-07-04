import WatchKit
import HealthKit
import WatchConnectivity
import Foundation
import OSLog
import Observation

@available(watchOS 11.0, *)
@Observable
class WatchSessionManager {
    static let shared = WatchSessionManager()
    
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private var healthKitObservers: [HKObserverQuery] = []
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private let logger = Logger(subsystem: "com.healthai2030.watch", category: "session")
    
    // Observable properties for SwiftUI
    var currentHeartRate: Double = 0
    var currentHRV: Double = 0
    var currentSleepStage: SleepStage = .unknown
    var isMonitoring: Bool = false
    var isSleepSessionActive: Bool = false
    var sessionDuration: TimeInterval = 0
    
    // Health data storage
    private var healthDataBuffer: [HealthDataPoint] = []
    private let dataBufferSize = 100
    
    // Session management
    private var sessionStartTime: Date?
    private var sessionTimer: Timer?
    
    private init() {}
    
    // MARK: - Health Monitoring
    
    func startHealthMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        setupHealthKitObservers()
        startSessionTimer()
        
        print("Health monitoring started on Watch")
    }
    
    func stopHealthMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        stopHealthKitObservers()
        stopSessionTimer()
        
        print("Health monitoring stopped on Watch")
    }
    
    func setupHealthKitObservers() {
        setupHeartRateObserver()
        setupHRVObserver()
        setupSleepObserver()
    }
    
    private func setupHeartRateObserver() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchLatestHeartRate()
            completion()
        }
        
        healthStore.execute(query)
        healthKitObservers.append(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if success {
                print("Background heart rate delivery enabled on Watch")
            }
        }
    }
    
    private func setupHRVObserver() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchLatestHRV()
            completion()
        }
        
        healthStore.execute(query)
        healthKitObservers.append(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if success {
                print("Background HRV delivery enabled on Watch")
            }
        }
    }
    
    private func setupSleepObserver() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchLatestSleepData()
            completion()
        }
        
        healthStore.execute(query)
        healthKitObservers.append(query)
    }
    
    private func stopHealthKitObservers() {
        for query in healthKitObservers {
            healthStore.stop(query)
        }
        healthKitObservers.removeAll()
    }
    
    // MARK: - Data Fetching
    
    private func fetchLatestHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self?.currentHeartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self?.addHealthDataPoint(type: .heartRate, value: self?.currentHeartRate ?? 0)
                self?.sendHealthDataToiPhone()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHRV() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self?.currentHRV = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                self?.addHealthDataPoint(type: .hrv, value: self?.currentHRV ?? 0)
                self?.sendHealthDataToiPhone()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKCategorySample else { return }
            
            DispatchQueue.main.async {
                self?.currentSleepStage = self?.determineSleepStage(from: sample) ?? .unknown
                self?.sendHealthDataToiPhone()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func determineSleepStage(from sample: HKCategorySample) -> SleepStage {
        switch sample.value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return .awake
        case HKCategoryValueSleepAnalysis.asleep.rawValue:
            return .lightSleep
        default:
            return .unknown
        }
    }
    
    // MARK: - Sleep Session Management
    
    func startSleepSession() {
        guard !isSleepSessionActive else { return }
        
        isSleepSessionActive = true
        sessionStartTime = Date()
        startSessionTimer()
        
        // Start workout session for continuous monitoring
        startWorkoutSession()
        
        // Send notification to iPhone
        sendMessageToiPhone(command: "sleepSessionStarted", data: [:])
        
        print("Sleep session started on Watch")
    }
    
    func stopSleepSession() {
        guard isSleepSessionActive else { return }
        
        isSleepSessionActive = false
        stopSessionTimer()
        
        // Stop workout session
        stopWorkoutSession()
        
        // Send session summary to iPhone
        let sessionData = getSessionSummary()
        sendMessageToiPhone(command: "sleepSessionEnded", data: sessionData)
        
        print("Sleep session stopped on Watch")
    }
    
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .sleepAnalysis
        configuration.locationType = .indoor
        
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, configuration: configuration)
            
            workoutSession = session
            workoutBuilder = builder
            
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("Failed to begin workout collection: \(error)")
                }
            }
        } catch {
            print("Failed to create workout session: \(error)")
        }
    }
    
    private func stopWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("Failed to end workout collection: \(error)")
            }
        }
        
        workoutSession = nil
        workoutBuilder = nil
    }
    
    // MARK: - Session Timer
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func updateSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Background Health Check
    
    func performBackgroundHealthCheck(completion: @escaping () -> Void) {
        fetchLatestHeartRate()
        fetchLatestHRV()
        fetchLatestSleepData()
        
        // Send data to iPhone
        sendHealthDataToiPhone()
        
        completion()
    }
    
    // MARK: - Data Management
    
    private func addHealthDataPoint(type: HealthDataType, value: Double) {
        let dataPoint = HealthDataPoint(type: type, value: value, timestamp: Date())
        healthDataBuffer.append(dataPoint)
        
        // Keep buffer size manageable
        if healthDataBuffer.count > dataBufferSize {
            healthDataBuffer.removeFirst()
        }
    }
    
    private func getSessionSummary() -> [String: Any] {
        let duration = sessionDuration
        let averageHeartRate = healthDataBuffer.filter { $0.type == .heartRate }.map { $0.value }.reduce(0, +) / Double(max(1, healthDataBuffer.filter { $0.type == .heartRate }.count))
        let averageHRV = healthDataBuffer.filter { $0.type == .hrv }.map { $0.value }.reduce(0, +) / Double(max(1, healthDataBuffer.filter { $0.type == .hrv }.count))
        
        return [
            "duration": duration,
            "averageHeartRate": averageHeartRate,
            "averageHRV": averageHRV,
            "dataPoints": healthDataBuffer.count
        ]
    }
    
    // MARK: - iPhone Communication
    
    private func sendHealthDataToiPhone() {
        let healthData: [String: Any] = [
            "heartRate": currentHeartRate,
            "hrv": currentHRV,
            "sleepStage": currentSleepStage.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        sendMessageToiPhone(command: "healthDataUpdate", data: healthData)
    }
    
    private func sendMessageToiPhone(command: String, data: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        var message = data
        message["command"] = command
        message["source"] = "watch"
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message to iPhone: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    func getCurrentHealthStatus() -> [String: Any] {
        return [
            "heartRate": currentHeartRate,
            "hrv": currentHRV,
            "sleepStage": currentSleepStage.rawValue,
            "isMonitoring": isMonitoring,
            "isSleepSessionActive": isSleepSessionActive,
            "sessionDuration": sessionDuration
        ]
    }
    
    func getCurrentSleepStage() -> [String: Any] {
        return [
            "sleepStage": currentSleepStage.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    func updateAudioVolume(_ volume: Float) {
        // This would integrate with audio playback if implemented
        print("Audio volume updated to: \(volume)")
    }
}

// MARK: - Supporting Types

enum HealthDataType {
    case heartRate
    case hrv
    case oxygenSaturation
    case bodyTemperature
}

struct HealthDataPoint {
    let type: HealthDataType
    let value: Double
    let timestamp: Date
}

enum SleepStage: String, CaseIterable {
    case awake = "awake"
    case lightSleep = "lightSleep"
    case deepSleep = "deepSleep"
    case remSleep = "remSleep"
    case unknown = "unknown"
} 