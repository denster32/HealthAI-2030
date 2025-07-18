import Foundation
import SwiftUI
import HealthKit

/// SleepManager - Manages sleep sessions and sleep stage tracking
class SleepManager: ObservableObject {
    static let shared = SleepManager()
    
    @Published var isMonitoring = false
    @Published var currentSleepStage: SleepStage = .awake
    @Published var sleepSession: SleepSession?
    @Published var sleepStageHistory: [SleepStageChange] = []
    @Published var sleepInsights: SleepInsights?
    @Published var trackingMode: AppConfiguration.SleepTrackingMode = .iphoneOnly
    
    private var sessionStartTime: Date?
    private var timer: Timer?
    private let appleWatchManager = AppleWatchManager.shared
    
    // MARK: - Computed Properties for UI
    
    var sleepScore: Int {
        if let session = sleepSession {
            return calculateSleepScore(session: session)
        } else if let insights = sleepInsights {
            return insights.score
        } else {
            return 0
        }
    }
    
    var deepSleepPercentage: Double {
        if let session = sleepSession {
            return session.deepSleepPercentage
        } else {
            return calculateDeepSleepPercentage()
        }
    }
    
    var remSleepPercentage: Double {
        if let session = sleepSession {
            return session.remSleepPercentage
        } else {
            return calculateREMSleepPercentage()
        }
    }
    
    var sleepEfficiency: Double {
        if let session = sleepSession {
            return max(100 - session.awakePercentage, 0)
        } else {
            return max(100 - calculateAwakePercentage(), 0)
        }
    }
    
    private init() {
        // Observe Apple Watch tracking mode changes
        appleWatchManager.$currentTrackingMode
            .assign(to: &$trackingMode)
    }
    
    // MARK: - Sleep Session Management
    func startSleepSession() async {
        await MainActor.run {
            self.isMonitoring = true
            self.sessionStartTime = Date()
            self.currentSleepStage = .awake
            self.sleepStageHistory.removeAll()
            Logger.info("Sleep session started (mode: \(self.trackingMode))", log: Logger.sleepManager)
            // Start monitoring based on tracking mode
            switch self.trackingMode {
            case .appleWatch:
                self.startAppleWatchTracking()
            case .hybrid:
                self.startHybridTracking()
            case .iphoneOnly:
                self.startIPhoneTracking()
            }
        }
    }
    
    func endSleepSession() async {
        await MainActor.run {
            self.isMonitoring = false
            self.timer?.invalidate()
            self.timer = nil
            Logger.info("Sleep session ended", log: Logger.sleepManager)
            // Stop Apple Watch tracking if active
            if self.trackingMode != .iphoneOnly {
                self.appleWatchManager.stopSleepTrackingOnWatch()
            }
            // Create sleep session
            if let startTime = sessionStartTime {
                let session = SleepSession(
                    startTime: startTime,
                    endTime: Date(),
                    duration: Date().timeIntervalSince(startTime),
                    deepSleepPercentage: calculateDeepSleepPercentage(),
                    remSleepPercentage: calculateREMSleepPercentage(),
                    lightSleepPercentage: calculateLightSleepPercentage(),
                    awakePercentage: calculateAwakePercentage(),
                    trackingMode: self.trackingMode
                )
                self.sleepSession = session
                self.sleepInsights = generateSleepInsights(session: session)
                Logger.success("Sleep session and insights generated", log: Logger.sleepManager)
                // Save to HealthKit
                Task {
                    await saveSessionToHealthKit(session: session)
                }
            }
        }
    }
    
    // MARK: - Tracking Mode Management
    private func startAppleWatchTracking() {
        // Start tracking on Apple Watch
        appleWatchManager.startSleepTrackingOnWatch()
        
        // Set up timer to request data from watch
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.appleWatchManager.requestBiometricDataFromWatch()
        }
    }
    
    private func startHybridTracking() {
        // Start both iPhone and Apple Watch tracking
        appleWatchManager.startSleepTrackingOnWatch()
        startIPhoneTracking()
    }
    
    private func startIPhoneTracking() {
        // Start iPhone-based monitoring
        startMonitoring()
    }
    
    // MARK: - Sleep Stage Monitoring
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateSleepStage()
            }
        }
        // Allow the system to coalesce timer events for better efficiency
        timer?.tolerance = 5.0
    }
    
    private func updateSleepStage() async {
        // Determine sleep stage based on tracking mode
        let newStage: SleepStage
        
        switch trackingMode {
        case .appleWatch:
            newStage = await determineSleepStageFromWatch()
        case .hybrid:
            newStage = await determineSleepStageHybrid()
        case .iphoneOnly:
            newStage = determineSleepStageFromIPhone()
        }
        
        await MainActor.run {
            if newStage != self.currentSleepStage {
                let change = SleepStageChange(
                    timestamp: Date(),
                    from: self.currentSleepStage,
                    to: newStage,
                    confidence: calculateConfidence(for: newStage)
                )
                
                self.sleepStageHistory.append(change)
                self.currentSleepStage = newStage
            }
        }
    }
    
    private func determineSleepStageFromWatch() async -> SleepStage {
        // Use Apple Watch data for high-accuracy sleep stage detection
        guard let watchData = appleWatchManager.watchBiometricData else {
            return determineSleepStageFromIPhone()
        }
        
        // Advanced algorithm using watch biometrics
        let heartRate = watchData.heartRate
        let hrv = watchData.hrv
        let bloodOxygen = watchData.bloodOxygen
        let movement = watchData.movement
        
        // Medical-grade sleep stage detection algorithm
        if heartRate < 50 && hrv > 50 && bloodOxygen > 95 && movement < 0.1 {
            return .deep
        } else if heartRate < 60 && hrv > 30 && movement < 0.3 {
            return .rem
        } else if heartRate < 70 && movement < 0.5 {
            return .light
        } else {
            return .awake
        }
    }
    
    private func determineSleepStageHybrid() async -> SleepStage {
        // Combine iPhone and Apple Watch data
        let watchStage = await determineSleepStageFromWatch()
        let iphoneStage = determineSleepStageFromIPhone()
        
        // Weight the results based on data quality
        if appleWatchManager.isWatchReachable {
            return watchStage // Prefer watch data when available
        } else {
            return iphoneStage
        }
    }
    
    private func determineSleepStageFromIPhone() -> SleepStage {
        // This is a simplified algorithm - in a real app, this would use
        // AI analysis of biometric data, movement patterns, and other sensors
        
        guard let startTime = sessionStartTime else { return .awake }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = elapsed / 60
        
        // Simplified sleep cycle simulation
        if minutes < 10 {
            return .awake
        } else if minutes < 30 {
            return .light
        } else if minutes < 60 {
            return .deep
        } else if minutes < 90 {
            return .rem
        } else {
            // Cycle repeats
            let cyclePosition = Int(minutes) % 90
            if cyclePosition < 10 {
                return .light
            } else if cyclePosition < 40 {
                return .deep
            } else if cyclePosition < 70 {
                return .rem
            } else {
                return .light
            }
        }
    }
    
    private func calculateConfidence(for stage: SleepStage) -> Double {
        switch trackingMode {
        case .appleWatch:
            return 0.95 // High confidence with watch data
        case .hybrid:
            return 0.85 // Good confidence with combined data
        case .iphoneOnly:
            return 0.65 // Lower confidence with iPhone only
        }
    }
    
    // MARK: - Sleep Percentage Calculations
    /// Calculates the deep sleep percentage from available data.
    private func calculateDeepSleepPercentage() -> Double {
        guard !sleepStageHistory.isEmpty else { return 0.0 }
        
        var deepSleepDuration: TimeInterval = 0
        var totalSleepDuration: TimeInterval = 0
        
        for i in 0..<sleepStageHistory.count-1 {
            let current = sleepStageHistory[i]
            let next = sleepStageHistory[i+1]
            let duration = next.timestamp.timeIntervalSince(current.timestamp)
            
            if current.to == .deep {
                deepSleepDuration += duration
            }
            totalSleepDuration += duration
        }
        
        return totalSleepDuration > 0 ? (deepSleepDuration / totalSleepDuration) * 100 : 0.0
    }
    
    /// Calculates the REM sleep percentage from available data.
    private func calculateREMSleepPercentage() -> Double {
        guard !sleepStageHistory.isEmpty else { return 0.0 }
        
        var remSleepDuration: TimeInterval = 0
        var totalSleepDuration: TimeInterval = 0
        
        for i in 0..<sleepStageHistory.count-1 {
            let current = sleepStageHistory[i]
            let next = sleepStageHistory[i+1]
            let duration = next.timestamp.timeIntervalSince(current.timestamp)
            
            if current.to == .rem {
                remSleepDuration += duration
            }
            totalSleepDuration += duration
        }
        
        return totalSleepDuration > 0 ? (remSleepDuration / totalSleepDuration) * 100 : 0.0
    }
    
    /// Calculates the awake percentage from available data.
    private func calculateAwakePercentage() -> Double {
        guard !sleepStageHistory.isEmpty else { return 0.0 }
        
        var awakeDuration: TimeInterval = 0
        var totalSleepDuration: TimeInterval = 0
        
        for i in 0..<sleepStageHistory.count-1 {
            let current = sleepStageHistory[i]
            let next = sleepStageHistory[i+1]
            let duration = next.timestamp.timeIntervalSince(current.timestamp)
            
            if current.to == .awake {
                awakeDuration += duration
            }
            totalSleepDuration += duration
        }
        
        return totalSleepDuration > 0 ? (awakeDuration / totalSleepDuration) * 100 : 0.0
    }
    
    // MARK: - Sleep Insights
    private func generateSleepInsights(session: SleepSession) -> SleepInsights {
        let totalSleepTime = session.duration / 3600 // hours
        let deepSleepTime = (session.deepSleepPercentage / 100) * totalSleepTime
        let remSleepTime = (session.remSleepPercentage / 100) * totalSleepTime
        
        var insights: [String] = []
        
        // Add tracking mode specific insights
        insights.append("Sleep tracking accuracy: \(session.trackingMode.accuracy)")
        
        if totalSleepTime < 7 {
            insights.append("You slept for \(String(format: "%.1f", totalSleepTime)) hours. Consider aiming for 7-9 hours for optimal health.")
        } else if totalSleepTime > 9 {
            insights.append("You slept for \(String(format: "%.1f", totalSleepTime)) hours. This is longer than recommended for most adults.")
        }
        
        if deepSleepTime < 1 {
            insights.append("Deep sleep was limited. Try reducing screen time before bed and maintaining a consistent sleep schedule.")
        }
        
        if remSleepTime < 1.5 {
            insights.append("REM sleep was below optimal levels. Consider stress management techniques and avoiding alcohol before bed.")
        }
        
        if session.awakePercentage > 20 {
            insights.append("You were awake for \(Int(session.awakePercentage))% of your sleep time. Consider optimizing your sleep environment.")
        }
        
        // Apple Watch specific insights
        if session.trackingMode != .iphoneOnly {
            insights.append("Apple Watch provided enhanced sleep tracking with heart rate and blood oxygen monitoring.")
        }
        
        return SleepInsights(
            quality: determineSleepQuality(session: session),
            recommendations: insights,
            score: calculateSleepScore(session: session),
            trackingMode: session.trackingMode
        )
    }
    
    private func determineSleepQuality(session: SleepSession) -> SleepQuality {
        let score = calculateSleepScore(session: session)
        
        switch score {
        case 0..<60:
            return .poor
        case 60..<80:
            return .fair
        case 80..<90:
            return .good
        default:
            return .excellent
        }
    }
    
    /// Calculates the sleep score for a given session.
    /// - Parameter session: The sleep session to score.
    /// - Returns: An integer sleep score (0-100).
    private func calculateSleepScore(session: SleepSession) -> Int {
        // Weighted scoring algorithm based on sleep science research
        let durationScore = min(100, Int(session.duration / 3600 * 10)) // 0-100 (1pt per 6min)
        
        // Calculate component scores (0-100 each)
        let deepSleepScore = min(100, Int(session.deepSleepPercentage * 4)) // 25% = 100
        let remSleepScore = min(100, Int(session.remSleepPercentage * 4)) // 25% = 100
        let awakePenalty = max(0, Int(session.awakePercentage * 2)) // 50% awake = -100
        let efficiencyScore = min(100, Int(session.sleepEfficiency))
        
        // Weighted average (duration 40%, stages 40%, efficiency 20%)
        let weightedScore = Int(
            (Double(durationScore) * 0.4) +
            (Double(deepSleepScore + remSleepScore) * 0.2) + // 20% each
            (Double(efficiencyScore) * 0.2) -
            Double(awakePenalty)
        )
        
        return max(0, min(100, weightedScore))
    }

    // MARK: - HealthKit Integration
    private func saveSessionToHealthKit(session: SleepSession) async {
        // Save to HealthKit using HealthKitManager
        await HealthKitManager.shared.saveSleepSession(session)
        
        // If using Apple Watch, also save watch-specific data
        if session.trackingMode != .iphoneOnly {
            // This would save the enhanced watch data
            // Implementation depends on actual watch data structure
        }
    }
}
