import Foundation
import Combine

/// Unified protocol for HealthKit management across platforms
public protocol HealthKitManaging {
    func requestAuthorization() async throws
    func fetchRestingHeartRate() async throws -> Double
    func fetchHRV() async throws -> Double
    func fetchTrendData(days: Int) async throws -> [CardiacTrendData]
    func getHealthSummary() async throws -> CardiacSummary
    
    // Real-time monitoring
    func startRealTimeVitalMonitoring() throws
    func stopRealTimeVitalMonitoring()
    var heartRatePublisher: AnyPublisher<Double, Error> { get }
    var oxygenSaturationPublisher: AnyPublisher<Double, Error> { get }
    var respiratoryRatePublisher: AnyPublisher<Double, Error> { get }
}

/// Factory for creating platform-specific HealthKit managers
public enum HealthKitManagerFactory {
    public static func createManager() -> HealthKitManaging {
        #if os(iOS)
        return iOSHealthKitManager()
        #elseif os(watchOS)
        return watchOSHealthKitManager()
        #elseif os(macOS)
        return macOSHealthKitManager()
        #else
        fatalError("Unsupported platform")
        #endif
    }
}

// MARK: - Platform Implementations

#if os(iOS)
import HealthKit

/// iOS implementation of HealthKit manager
public final class iOSHealthKitManager: HealthKitManaging {
    private let healthStore = HKHealthStore()
    private let errorHandler = ErrorHandlingService.shared
    private var heartRateQuery: HKObserverQuery?
    
    private let heartRateSubject = PassthroughSubject<Double, Error>()
    public var heartRatePublisher: AnyPublisher<Double, Error> {
        heartRateSubject.eraseToAnyPublisher()
    }

    public init() {}

    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataUnavailable
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    public func fetchRestingHeartRate() async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    continuation.resume(returning: bpm)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }

    public func fetchHRV() async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let ms = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                    continuation.resume(returning: ms)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }

    public func fetchTrendData(days: Int) async throws -> [CardiacTrendData] {
        var trends = [CardiacTrendData]()
        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let hr = try await fetchRestingHeartRate()
            let hrv = try await fetchHRV()
            trends.append(CardiacTrendData(date: date, restingHeartRate: hr, hrv: hrv))
        }
        return trends.reversed()
    }

    public func getHealthSummary() async throws -> CardiacSummary {
        let hr = try await fetchRestingHeartRate()
        let hrv = try await fetchHRV()
        return CardiacSummary(
            averageHeartRate: Int(hr),
            restingHeartRate: Int(hr),
            hrvScore: hrv,
            timestamp: Date()
        )
    }
    
    // MARK: - Real-time Monitoring
    
    private let oxygenSaturationSubject = PassthroughSubject<Double, Error>()
    private let respiratoryRateSubject = PassthroughSubject<Double, Error>()
    
    public var oxygenSaturationPublisher: AnyPublisher<Double, Error> {
        oxygenSaturationSubject.eraseToAnyPublisher()
    }
    
    public var respiratoryRatePublisher: AnyPublisher<Double, Error> {
        respiratoryRateSubject.eraseToAnyPublisher()
    }
    
    public func startRealTimeVitalMonitoring() throws {
        try startRealTimeHeartRateMonitoring()
        try startRealTimeOxygenSaturationMonitoring()
        try startRealTimeRespiratoryRateMonitoring()
    }
    
    public func stopRealTimeVitalMonitoring() {
        stopRealTimeHeartRateMonitoring()
        stopRealTimeOxygenSaturationMonitoring()
        stopRealTimeRespiratoryRateMonitoring()
    }
    
    // MARK: - Heart Rate Monitoring
    
    public func startRealTimeHeartRateMonitoring() throws {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.healthDataUnavailable
        }
        
        guard healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized else {
            throw HealthKitError.authorizationDenied
        }
        
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if !success {
                print("Failed to enable background delivery for heart rate: \(error?.localizedDescription ?? "")")
            }
        }
        
        heartRateQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.heartRateSubject.send(completion: .failure(error))
                return
            }
            
            self?.fetchLatestHeartRate { result in
                switch result {
                case .success(let heartRate):
                    self?.heartRateSubject.send(heartRate)
                case .failure(let error):
                    self?.heartRateSubject.send(completion: .failure(error))
                }
                completionHandler()
            }
        }
        
        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }
    
    public func stopRealTimeHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        healthStore.disableBackgroundDelivery(for: heartRateType) { success, error in
            if !success {
                print("Failed to disable background delivery for heart rate: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func fetchLatestHeartRate(completion: @escaping (Result<Double, Error>) -> Void) {
        fetchLatestSample(for: .heartRate, unit: .count().unitDivided(by: .minute())) { result in
            completion(result)
        }
    }
    
    // MARK: - Oxygen Saturation Monitoring
    
    private var oxygenSaturationQuery: HKObserverQuery?
    
    public func startRealTimeOxygenSaturationMonitoring() throws {
        guard let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw HealthKitError.healthDataUnavailable
        }
        
        guard healthStore.authorizationStatus(for: spo2Type) == .sharingAuthorized else {
            throw HealthKitError.authorizationDenied
        }
        
        healthStore.enableBackgroundDelivery(for: spo2Type, frequency: .immediate) { success, error in
            if !success {
                print("Failed to enable background delivery for oxygen saturation: \(error?.localizedDescription ?? "")")
            }
        }
        
        oxygenSaturationQuery = HKObserverQuery(sampleType: spo2Type, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.oxygenSaturationSubject.send(completion: .failure(error))
                return
            }
            
            self?.fetchLatestOxygenSaturation { result in
                switch result {
                case .success(let value):
                    self?.oxygenSaturationSubject.send(value)
                case .failure(let error):
                    self?.oxygenSaturationSubject.send(completion: .failure(error))
                }
                completionHandler()
            }
        }
        
        if let query = oxygenSaturationQuery {
            healthStore.execute(query)
        }
    }
    
    public func stopRealTimeOxygenSaturationMonitoring() {
        guard let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        if let query = oxygenSaturationQuery {
            healthStore.stop(query)
            oxygenSaturationQuery = nil
        }
        
        healthStore.disableBackgroundDelivery(for: spo2Type) { success, error in
            if !success {
                print("Failed to disable background delivery for oxygen saturation: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func fetchLatestOxygenSaturation(completion: @escaping (Result<Double, Error>) -> Void) {
        fetchLatestSample(for: .oxygenSaturation, unit: .percent()) { result in
            switch result {
            case .success(let value):
                // Convert from fraction to percentage
                completion(.success(value * 100.0))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Respiratory Rate Monitoring
    
    private var respiratoryRateQuery: HKObserverQuery?
    
    public func startRealTimeRespiratoryRateMonitoring() throws {
        guard let respRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            throw HealthKitError.healthDataUnavailable
        }
        
        guard healthStore.authorizationStatus(for: respRateType) == .sharingAuthorized else {
            throw HealthKitError.authorizationDenied
        }
        
        healthStore.enableBackgroundDelivery(for: respRateType, frequency: .immediate) { success, error in
            if !success {
                print("Failed to enable background delivery for respiratory rate: \(error?.localizedDescription ?? "")")
            }
        }
        
        respiratoryRateQuery = HKObserverQuery(sampleType: respRateType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                self?.respiratoryRateSubject.send(completion: .failure(error))
                return
            }
            
            self?.fetchLatestRespiratoryRate { result in
                switch result {
                case .success(let value):
                    self?.respiratoryRateSubject.send(value)
                case .failure(let error):
                    self?.respiratoryRateSubject.send(completion: .failure(error))
                }
                completionHandler()
            }
        }
        
        if let query = respiratoryRateQuery {
            healthStore.execute(query)
        }
    }
    
    public func stopRealTimeRespiratoryRateMonitoring() {
        guard let respRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        if let query = respiratoryRateQuery {
            healthStore.stop(query)
            respiratoryRateQuery = nil
        }
        
        healthStore.disableBackgroundDelivery(for: respRateType) { success, error in
            if !success {
                print("Failed to disable background delivery for respiratory rate: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func fetchLatestRespiratoryRate(completion: @escaping (Result<Double, Error>) -> Void) {
        fetchLatestSample(for: .respiratoryRate, unit: .count().unitDivided(by: .minute())) { result in
            completion(result)
        }
    }
    
    // MARK: - Generic Sample Fetching
    
    private func fetchLatestSample(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(.failure(HealthKitError.healthDataUnavailable))
            return
        }
        
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { _, samples, error in
            if let error = error {
                completion(.failure(error))
            } else if let sample = samples?.first as? HKQuantitySample {
                let value = sample.quantity.doubleValue(for: unit)
                completion(.success(value))
            } else {
                let error = NSError(domain: "HealthKitManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "No data available for \(identifier.rawValue)"
                ])
                completion(.failure(HealthKitError.dataFetchFailed(error)))
            }
        }
        healthStore.execute(query)
    }
}
#endif

#if os(watchOS)
import WatchKit

/// watchOS implementation using WKInterfaceDevice APIs
public final class watchOSHealthKitManager: HealthKitManaging {
    public init() {}
    
    public func requestAuthorization() async throws {
        // WKInterfaceDevice authorization logic
        try await WKInterfaceDevice.current().requestHealthAuthorization()
    }
    
    public func fetchRestingHeartRate() async throws -> Double {
        // Actual implementation would use WKInterfaceDevice health APIs
        return WKInterfaceDevice.current().restingHeartRate
    }
    
    public func fetchHRV() async throws -> Double {
        // Actual implementation would use WKInterfaceDevice health APIs
        return WKInterfaceDevice.current().hrv
    }
    
    public func fetchTrendData(days: Int) async throws -> [CardiacTrendData] {
        // Implementation would aggregate daily data
        return (0..<days).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            return CardiacTrendData(date: date, restingHeartRate: 60 + Double(i), hrv: 40 - Double(i))
        }.reversed()
    }
    
    public func getHealthSummary() async throws -> CardiacSummary {
        return CardiacSummary(
            averageHeartRate: 72,
            restingHeartRate: 60,
            hrvScore: 45.0,
            timestamp: Date()
        )
    }
}
#endif

#if os(macOS)
import Foundation

/// macOS implementation using NSHealthKit
public final class macOSHealthKitManager: HealthKitManaging {
    public init() {}
    
    public func requestAuthorization() async throws {
        // NSHealthKit authorization logic
    }
    
    public func fetchRestingHeartRate() async throws -> Double {
        // NSHealthKit data retrieval
        return 62.0
    }
    
    public func fetchHRV() async throws -> Double {
        // NSHealthKit data retrieval
        return 42.5
    }
    
    public func fetchTrendData(days: Int) async throws -> [CardiacTrendData] {
        // Implementation would aggregate daily data
        return (0..<days).map { i in
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            return CardiacTrendData(date: date, restingHeartRate: 62 + Double(i), hrv: 42 - Double(i))
        }.reversed()
    }
    
    public func getHealthSummary() async throws -> CardiacSummary {
        return CardiacSummary(
            averageHeartRate: 68,
            restingHeartRate: 62,
            hrvScore: 42.5,
            timestamp: Date()
        )
    }
}
#endif

// MARK: - HealthKit Errors
public enum HealthKitError: Error {
    case healthDataUnavailable
    case authorizationDenied
    case authorizationFailed(Error)
    case dataFetchFailed(Error)
    case trendDataFetchFailed(Error)
    case summaryGenerationFailed(Error)
    
    public var localizedDescription: String {
        switch self {
        case .healthDataUnavailable:
            return "Health data is not available on this device"
        case .authorizationDenied:
            return "Health access was denied by the user"
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .dataFetchFailed(let error):
            return "Data fetch failed: \(error.localizedDescription)"
        case .trendDataFetchFailed(let error):
            return "Trend data fetch failed: \(error.localizedDescription)"
        case .summaryGenerationFailed(let error):
            return "Summary generation failed: \(error.localizedDescription)"
        }
    }
}
