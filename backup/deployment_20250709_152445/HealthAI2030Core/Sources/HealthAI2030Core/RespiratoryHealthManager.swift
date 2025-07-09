import Foundation
import Combine
import HealthKit
import os

@MainActor
public class RespiratoryHealthManager: ObservableObject {
    public static let shared = RespiratoryHealthManager()
    @Published public var respiratoryMetrics: [RespiratoryMetrics] = []
    @Published public var breathingSessions: [BreathingSession] = []
    @Published public var analytics: RespiratoryAnalytics = RespiratoryAnalytics()
    @Published public var errors: [Error] = []
    
    private let logger = Logger(subsystem: "com.healthai.respiratory", category: "health")
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "BreathingSessions"
    private let analyticsKey = "RespiratoryAnalytics"
    
    private init() {
        loadStoredData()
        fetchRespiratoryData()
    }
    
    private func loadStoredData() {
        // Load breathing sessions
        if let data = userDefaults.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([BreathingSession].self, from: data) {
            breathingSessions = decodedSessions
        }
        
        // Load analytics
        if let data = userDefaults.data(forKey: analyticsKey),
           let decodedAnalytics = try? JSONDecoder().decode(RespiratoryAnalytics.self, from: data) {
            analytics = decodedAnalytics
        }
    }
    
    private func saveData() {
        // Save breathing sessions
        if let encoded = try? JSONEncoder().encode(breathingSessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
        
        // Save analytics
        if let encoded = try? JSONEncoder().encode(analytics) {
            userDefaults.set(encoded, forKey: analyticsKey)
        }
    }
    
    public func fetchRespiratoryData() {
        Task {
            let oxygenSaturationType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
            let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!

            let oxygenSamples = await fetchSamples(for: oxygenSaturationType)
            let rateSamples = await fetchSamples(for: respiratoryRateType)

            let combinedMetrics = combineSamples(oxygenSamples: oxygenSamples, rateSamples: rateSamples)
            DispatchQueue.main.async {
                self.respiratoryMetrics = combinedMetrics
            }
        }
    }
    
    private func fetchSamples(for type: HKQuantityType) async -> [HKQuantitySample] {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    self.errors.append(error)
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            HKHealthStore().execute(query)
        }
    }

    private func combineSamples(oxygenSamples: [HKQuantitySample], rateSamples: [HKQuantitySample]) -> [RespiratoryMetrics] {
        // This is a simplified combination logic. A real implementation would need to be more sophisticated.
        let allSamples = (oxygenSamples + rateSamples).sorted(by: { $0.startDate < $1.startDate })
        var metrics: [RespiratoryMetrics] = []

        for sample in allSamples {
            metrics.append(RespiratoryMetrics(
                id: UUID(),
                date: sample.startDate,
                oxygenSaturation: (sample.quantityType.identifier == HKQuantityTypeIdentifier.oxygenSaturation.rawValue) ? sample.quantity.doubleValue(for: .percent()) * 100 : nil,
                respiratoryRate: (sample.quantityType.identifier == HKQuantityTypeIdentifier.respiratoryRate.rawValue) ? sample.quantity.doubleValue(for: HKUnit(from: "count/min")) : nil,
                inhaledAirQuality: nil // Placeholder
            ))
        }
        return metrics
    }

    public func logBreathingSession(_ session: BreathingSession) {
        // Log the session
        logger.info("Breathing session logged: \(session.id), duration: \(session.actualDuration ?? 0)s, pattern: \(session.pattern)")
        
        // Add to sessions array
        breathingSessions.append(session)
        
        // Update analytics
        updateAnalytics(with: session)
        
        // Save data
        saveData()
        
        // Log to HealthKit if available
        logToHealthKit(session)
    }
    
    private func updateAnalytics(with session: BreathingSession) {
        // Update session count
        analytics.totalSessions += 1
        
        // Update total duration
        if let duration = session.actualDuration {
            analytics.totalDuration += duration
            analytics.averageSessionDuration = analytics.totalDuration / Double(analytics.totalSessions)
        }
        
        // Update pattern usage
        analytics.patternUsage[session.pattern, default: 0] += 1
        
        // Update daily stats
        let today = Calendar.current.startOfDay(for: Date())
        analytics.dailyStats[today, default: DailyStats()].sessionCount += 1
        if let duration = session.actualDuration {
            analytics.dailyStats[today, default: DailyStats()].totalDuration += duration
        }
        
        // Update weekly stats
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? today
        analytics.weeklyStats[weekStart, default: WeeklyStats()].sessionCount += 1
        if let duration = session.actualDuration {
            analytics.weeklyStats[weekStart, default: WeeklyStats()].totalDuration += duration
        }
        
        // Update streak
        updateStreak()
        
        // Update goals
        updateGoals(with: session)
    }
    
    private func updateStreak() {
        let sortedSessions = breathingSessions.sorted { $0.startTime < $1.startTime }
        var currentStreak = 0
        var lastDate: Date?
        
        for session in sortedSessions.reversed() {
            let sessionDate = Calendar.current.startOfDay(for: session.startTime)
            
            if let last = lastDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: sessionDate, to: last).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else {
                    break
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = sessionDate
        }
        
        analytics.currentStreak = currentStreak
        analytics.longestStreak = max(analytics.longestStreak, currentStreak)
    }
    
    private func updateGoals(with session: BreathingSession) {
        // Update daily goal progress
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = breathingSessions.filter { 
            Calendar.current.isDate($0.startTime, inSameDayAs: today)
        }
        
        analytics.dailyGoalProgress = min(1.0, Double(todaySessions.count) / analytics.dailyGoal)
        
        // Update weekly goal progress
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? today
        let weekSessions = breathingSessions.filter { 
            $0.startTime >= weekStart
        }
        
        analytics.weeklyGoalProgress = min(1.0, Double(weekSessions.count) / analytics.weeklyGoal)
    }
    
    private func logToHealthKit(_ session: BreathingSession) {
        // Log breathing session to HealthKit for health tracking
        guard let duration = session.actualDuration else { return }
        
        let workout = HKWorkout(
            activityType: .mindAndBody,
            start: session.startTime,
            end: session.endTime ?? session.startTime.addingTimeInterval(duration),
            duration: duration,
            totalEnergyBurned: nil,
            totalDistance: nil,
            device: HKDevice.local(),
            metadata: [
                HKMetadataKeyWorkoutBrandName: "HealthAI 2030",
                HKMetadataKeyIndoorWorkout: true,
                "breathing_pattern": session.pattern
            ]
        )
        
        HKHealthStore().save(workout) { success, error in
            if let error = error {
                self.logger.error("Failed to save breathing session to HealthKit: \(error.localizedDescription)")
            } else {
                self.logger.info("Successfully saved breathing session to HealthKit")
            }
        }
    }
    
    public func getAnalyticsReport() -> String {
        return """
        Respiratory Health Analytics Report
        
        Total Sessions: \(analytics.totalSessions)
        Total Duration: \(String(format: "%.1f", analytics.totalDuration / 60)) minutes
        Average Session Duration: \(String(format: "%.1f", analytics.averageSessionDuration / 60)) minutes
        Current Streak: \(analytics.currentStreak) days
        Longest Streak: \(analytics.longestStreak) days
        Daily Goal Progress: \(String(format: "%.1f", analytics.dailyGoalProgress * 100))%
        Weekly Goal Progress: \(String(format: "%.1f", analytics.weeklyGoalProgress * 100))%
        
        Most Used Pattern: \(analytics.patternUsage.max(by: { $0.value < $1.value })?.key ?? "Unknown")
        """
    }
}

public struct RespiratoryMetrics: Codable, Identifiable {
    public let id: UUID
    public let date: Date
    public let oxygenSaturation: Double?
    public let respiratoryRate: Double?
    public let inhaledAirQuality: Double?
}

public struct RespiratoryAnalytics: Codable {
    public var totalSessions: Int = 0
    public var totalDuration: TimeInterval = 0
    public var averageSessionDuration: TimeInterval = 0
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var dailyGoal: Int = 3
    public var weeklyGoal: Int = 21
    public var dailyGoalProgress: Double = 0
    public var weeklyGoalProgress: Double = 0
    public var patternUsage: [String: Int] = [:]
    public var dailyStats: [Date: DailyStats] = [:]
    public var weeklyStats: [Date: WeeklyStats] = [:]
}

public struct DailyStats: Codable {
    public var sessionCount: Int = 0
    public var totalDuration: TimeInterval = 0
}

public struct WeeklyStats: Codable {
    public var sessionCount: Int = 0
    public var totalDuration: TimeInterval = 0
}
