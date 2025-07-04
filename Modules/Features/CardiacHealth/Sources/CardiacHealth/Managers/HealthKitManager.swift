#if os(iOS)
import Foundation
import HealthKit

@available(iOS 13.0, *)
/// Manages HealthKit authorization and data fetching for cardiac metrics.
open class HealthKitManager { // Changed to 'open'
    public static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    public init() {} // Made init public for mocking

    /// Requests authorization to read heart rate and HRV data.
    open func requestAuthorization() async throws { // Changed to 'open'
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HKError(.errorHealthDataUnavailable)
        }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]
        try await withCheckedThrowingContinuation(of: Void.self) { continuation in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: HKError(.errorAuthorizationDenied))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Fetches the most recent resting heart rate sample (beats per minute).
    open func fetchRestingHeartRate() async throws -> Double { // Changed to 'open'
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return try await withCheckedThrowingContinuation(of: Double.self) { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    continuation.resume(returning: bpm)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetches average SDNN (HRV) from the most recent sample.
    open func fetchHRV() async throws -> Double { // Changed to 'open'
        let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return try await withCheckedThrowingContinuation(of: Double.self) { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let ms = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    continuation.resume(returning: ms)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetches trend data for the past N days.
    open func fetchTrendData(days: Int) async throws -> CardiacTrendData { // Changed to 'open'
        var trends = [CardiacTrendData]()
        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let hr = try await fetchRestingHeartRate()
            let hrv = try await fetchHRV()
            let trend = CardiacTrendData(date: date, restingHeartRate: hr, hrv: hrv)
            trends.append(trend)
        }
        return trends.reversed()
    }

    /// Constructs a summary from the latest heart rate and HRV samples.
    open func getHealthSummary() async throws -> CardiacSummary { // Changed to 'open'
        let hr = try await fetchRestingHeartRate()
        let hrv = try await fetchHRV()
        // Blood pressure unavailable from HealthKit directly; placeholder
        // Assuming CardiacSummary now takes averageHeartRate, restingHeartRate, hrvScore, timestamp
        return CardiacSummary(averageHeartRate: Int(hr), restingHeartRate: Int(hr), hrvScore: hrv, timestamp: Date())
    }
}
#endif
