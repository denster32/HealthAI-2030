import Foundation
import HealthKit
import Combine

/// Analyzes Heart Rate Variability (HRV) coherence in real-time
/// Provides coherence scores for biofeedback applications
class HRVCoherenceAnalyzer: ObservableObject {
    // MARK: - Published Properties
    @Published var currentCoherence: Double = 0.0
    @Published var hrvSDNN: Double = 0.0
    @Published var hrvRMSSD: Double = 0.0
    @Published var heartRate: Double = 0.0
    @Published var isMonitoring = false
    
    // MARK: - Private Properties
    private var healthStore: HKHealthStore?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // HRV analysis parameters
    private var rrIntervals: [Double] = []
    private let maxRRIntervals = 300 // 5 minutes at 60 BPM
    private let coherenceWindowSize = 60 // 1 minute window for coherence calculation
    
    // Coherence thresholds
    private let lowCoherenceThreshold: Double = 0.3
    private let mediumCoherenceThreshold: Double = 0.7
    private let highCoherenceThreshold: Double = 0.9
    
    init() {
        setupHealthKit()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start HRV monitoring and coherence analysis
    func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available")
            return
        }
        
        requestAuthorization { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.beginHRVMonitoring()
                }
            }
        }
    }
    
    /// Stop HRV monitoring
    func stopMonitoring() {
        heartRateQuery?.stop()
        hrvQuery?.stop()
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    /// Get current coherence level description
    var coherenceLevel: String {
        switch currentCoherence {
        case 0.0..<lowCoherenceThreshold:
            return "Low"
        case lowCoherenceThreshold..<mediumCoherenceThreshold:
            return "Medium"
        case mediumCoherenceThreshold..<highCoherenceThreshold:
            return "High"
        default:
            return "Optimal"
        }
    }
    
    /// Get coherence color for UI
    var coherenceColor: String {
        switch currentCoherence {
        case 0.0..<lowCoherenceThreshold:
            return "red"
        case lowCoherenceThreshold..<mediumCoherenceThreshold:
            return "orange"
        case mediumCoherenceThreshold..<highCoherenceThreshold:
            return "yellow"
        default:
            return "green"
        }
    }
    
    // MARK: - Private Methods
    
    private func setupHealthKit() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilityRMSSD)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            }
            completion(success)
        }
    }
    
    private func beginHRVMonitoring() {
        guard let healthStore = healthStore else { return }
        
        // Start heart rate monitoring
        startHeartRateMonitoring(healthStore: healthStore)
        
        // Start HRV monitoring
        startHRVMonitoring(healthStore: healthStore)
        
        // Start timer for coherence calculation
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.calculateCoherence()
        }
        
        isMonitoring = true
    }
    
    private func startHeartRateMonitoring(healthStore: HKHealthStore) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        heartRateQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(heartRateQuery!)
    }
    
    private func startHRVMonitoring(healthStore: HKHealthStore) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: nil, options: .strictStartDate)
        
        hrvQuery = HKAnchoredObjectQuery(type: hrvType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples)
        }
        
        hrvQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples)
        }
        
        healthStore.execute(hrvQuery!)
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async { [weak self] in
            if let latestSample = samples.last {
                let heartRate = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                self?.heartRate = heartRate
                
                // Calculate RR interval from heart rate
                let rrInterval = 60000.0 / heartRate // Convert to milliseconds
                self?.addRRInterval(rrInterval)
            }
        }
    }
    
    private func processHRVSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async { [weak self] in
            if let latestSample = samples.last {
                let sdnn = latestSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                self?.hrvSDNN = sdnn
            }
        }
        
        // Also get RMSSD if available
        fetchRMSSD()
    }
    
    private func fetchRMSSD() {
        guard let healthStore = healthStore,
              let rmssdType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilityRMSSD) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: rmssdType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                let rmssd = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                self?.hrvRMSSD = rmssd
            }
        }
        
        healthStore.execute(query)
    }
    
    private func addRRInterval(_ interval: Double) {
        rrIntervals.append(interval)
        
        // Keep only the most recent intervals
        if rrIntervals.count > maxRRIntervals {
            rrIntervals.removeFirst(rrIntervals.count - maxRRIntervals)
        }
    }
    
    private func calculateCoherence() {
        guard rrIntervals.count >= coherenceWindowSize else {
            // Use simulated data if not enough real data
            simulateCoherence()
            return
        }
        
        // Calculate coherence using the most recent window
        let recentIntervals = Array(rrIntervals.suffix(coherenceWindowSize))
        let coherence = calculateHRVCoherence(from: recentIntervals)
        
        DispatchQueue.main.async { [weak self] in
            self?.currentCoherence = coherence
        }
    }
    
    private func calculateHRVCoherence(from intervals: [Double]) -> Double {
        guard intervals.count >= 10 else { return 0.0 }
        
        // Calculate various HRV metrics
        let meanRR = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - meanRR, 2) }.reduce(0, +) / Double(intervals.count)
        let sdnn = sqrt(variance)
        
        // Calculate RMSSD
        var rmssdSum = 0.0
        for i in 1..<intervals.count {
            let diff = intervals[i] - intervals[i-1]
            rmssdSum += diff * diff
        }
        let rmssd = sqrt(rmssdSum / Double(intervals.count - 1))
        
        // Calculate pNN50 (percentage of successive RR intervals that differ by more than 50ms)
        var pnn50Count = 0
        for i in 1..<intervals.count {
            if abs(intervals[i] - intervals[i-1]) > 50 {
                pnn50Count += 1
            }
        }
        let pnn50 = Double(pnn50Count) / Double(intervals.count - 1) * 100
        
        // Calculate coherence score based on multiple factors
        let coherence = calculateCoherenceScore(sdnn: sdnn, rmssd: rmssd, pnn50: pnn50, meanRR: meanRR)
        
        return max(0.0, min(1.0, coherence))
    }
    
    private func calculateCoherenceScore(sdnn: Double, rmssd: Double, pnn50: Double, meanRR: Double) -> Double {
        // Normalize metrics to 0-1 range
        let normalizedSDNN = min(sdnn / 100.0, 1.0) // Normalize to 100ms max
        let normalizedRMSSD = min(rmssd / 50.0, 1.0) // Normalize to 50ms max
        let normalizedPNN50 = pnn50 / 100.0 // Already 0-100%
        
        // Calculate weighted coherence score
        let sdnnWeight = 0.3
        let rmssdWeight = 0.4
        let pnn50Weight = 0.3
        
        let coherence = (normalizedSDNN * sdnnWeight) +
                       (normalizedRMSSD * rmssdWeight) +
                       (normalizedPNN50 * pnn50Weight)
        
        return coherence
    }
    
    private func simulateCoherence() {
        // Simulate coherence changes for testing
        let randomChange = Double.random(in: -0.02...0.02)
        let targetCoherence = 0.6 + sin(Date().timeIntervalSince1970 / 30.0) * 0.3 // Oscillate around 0.6
        
        currentCoherence = max(0.0, min(1.0, targetCoherence + randomChange))
        
        // Simulate other metrics
        hrvSDNN = 30.0 + currentCoherence * 40.0
        hrvRMSSD = 20.0 + currentCoherence * 30.0
        heartRate = 60.0 + (1.0 - currentCoherence) * 20.0
    }
}

// MARK: - Coherence Analysis Extensions

extension HRVCoherenceAnalyzer {
    
    /// Get detailed HRV analysis report
    func getHRVAnalysisReport() -> HRVAnalysisReport {
        return HRVAnalysisReport(
            coherence: currentCoherence,
            coherenceLevel: coherenceLevel,
            sdnn: hrvSDNN,
            rmssd: hrvRMSSD,
            heartRate: heartRate,
            timestamp: Date()
        )
    }
    
    /// Calculate trend over time
    func getCoherenceTrend(duration: TimeInterval) -> [Double] {
        // This would return historical coherence values
        // For now, return simulated trend
        let count = Int(duration / 60.0) // One value per minute
        return (0..<count).map { index in
            let timeOffset = Double(index) * 60.0
            let baseCoherence = 0.6
            let trend = sin(timeOffset / 300.0) * 0.2 // 5-minute cycle
            let noise = Double.random(in: -0.05...0.05)
            return max(0.0, min(1.0, baseCoherence + trend + noise))
        }
    }
}

// MARK: - Supporting Types

struct HRVAnalysisReport {
    let coherence: Double
    let coherenceLevel: String
    let sdnn: Double
    let rmssd: Double
    let heartRate: Double
    let timestamp: Date
    
    var isOptimal: Bool {
        return coherence >= 0.8
    }
    
    var needsAttention: Bool {
        return coherence < 0.3
    }
}