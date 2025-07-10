import Foundation
import SwiftUI
import Combine

/// Health Activity Points System
/// Provides comprehensive point calculation, multipliers, bonuses, and health data integration
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class HealthActivityPoints: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentPoints: Int = 0
    @Published public private(set) var totalPoints: Int = 0
    @Published public private(set) var dailyPoints: Int = 0
    @Published public private(set) var weeklyPoints: Int = 0
    @Published public private(set) var monthlyPoints: Int = 0
    @Published public private(set) var pointHistory: [PointEntry] = []
    @Published public private(set) var multipliers: [PointMultiplier] = []
    @Published public private(set) var bonuses: [PointBonus] = []
    @Published public private(set) var pointGoals: [PointGoal] = []
    @Published public private(set) var isPointsActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var pointsProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private var cancellables = Set<AnyCancellable>()
    private let pointsQueue = DispatchQueue(label: "health.points", qos: .userInitiated)
    
    // Points data caches
    private var pointsData: [String: PointsData] = [:]
    private var multiplierData: [String: MultiplierData] = [:]
    private var bonusData: [String: BonusData] = [:]
    
    // Points parameters
    private let pointsUpdateInterval: TimeInterval = 300.0 // 5 minutes
    private var lastPointsUpdate: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupPointsSystem()
        setupMultiplierSystem()
        setupBonusSystem()
        initializePointsPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start points system
    public func startPointsSystem() async throws {
        isPointsActive = true
        lastError = nil
        pointsProgress = 0.0
        
        do {
            // Initialize points platform
            try await initializePointsPlatform()
            
            // Start continuous points tracking
            try await startContinuousPointsTracking()
            
            // Update points status
            await updatePointsStatus()
            
            // Track points start
            analyticsEngine.trackEvent("points_system_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "current_points": currentPoints
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isPointsActive = false
            }
            throw error
        }
    }
    
    /// Stop points system
    public func stopPointsSystem() async {
        await MainActor.run {
            self.isPointsActive = false
        }
        
        // Track points stop
        analyticsEngine.trackEvent("points_system_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(lastPointsUpdate)
        ])
    }
    
    /// Award points for activity
    public func awardPoints(activity: HealthActivity, points: Int, context: PointContext? = nil) async throws {
        do {
            // Validate points award
            try await validatePointsAward(activity: activity, points: points)
            
            // Calculate final points with multipliers
            let finalPoints = try await calculateFinalPoints(activity: activity, basePoints: points, context: context)
            
            // Create point entry
            let entry = PointEntry(
                id: UUID(),
                activity: activity,
                basePoints: points,
                finalPoints: finalPoints,
                multipliers: getActiveMultipliers(),
                bonuses: getActiveBonuses(),
                context: context,
                timestamp: Date()
            )
            
            // Update points state
            await MainActor.run {
                self.pointHistory.append(entry)
                self.currentPoints += finalPoints
                self.totalPoints += finalPoints
                self.dailyPoints += finalPoints
                self.weeklyPoints += finalPoints
                self.monthlyPoints += finalPoints
            }
            
            // Track points award
            await trackPointsAward(entry: entry)
            
            // Update point goals
            await updatePointGoals()
            
            // Generate point insights
            await generatePointInsights()
            
            // Update points progress
            await updatePointsProgress()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get point history
    public func getPointHistory(limit: Int = 50) async -> [PointEntry] {
        let history = pointHistory.suffix(limit)
        return Array(history)
    }
    
    /// Get point analytics
    public func getPointAnalytics() async -> PointAnalytics {
        do {
            // Calculate point metrics
            let metrics = try await calculatePointMetrics()
            
            // Analyze point patterns
            let patterns = try await analyzePointPatterns()
            
            // Generate insights
            let insights = try await generatePointInsights(metrics: metrics, patterns: patterns)
            
            let analytics = PointAnalytics(
                totalPoints: metrics.totalPoints,
                averageDailyPoints: metrics.averageDailyPoints,
                pointTrends: metrics.pointTrends,
                pointPatterns: patterns,
                insights: insights,
                timestamp: Date()
            )
            
            return analytics
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return PointAnalytics()
        }
    }
    
    /// Get active multipliers
    public func getActiveMultipliers() async -> [PointMultiplier] {
        do {
            // Get current multipliers
            let multipliers = try await loadActiveMultipliers()
            
            await MainActor.run {
                self.multipliers = multipliers
            }
            
            return multipliers
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get active bonuses
    public func getActiveBonuses() async -> [PointBonus] {
        do {
            // Get current bonuses
            let bonuses = try await loadActiveBonuses()
            
            await MainActor.run {
                self.bonuses = bonuses
            }
            
            return bonuses
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Set point goal
    public func setPointGoal(_ goal: PointGoal) async throws {
        do {
            // Validate point goal
            try await validatePointGoal(goal)
            
            // Add or update goal
            await MainActor.run {
                if let index = self.pointGoals.firstIndex(where: { $0.id == goal.id }) {
                    self.pointGoals[index] = goal
                } else {
                    self.pointGoals.append(goal)
                }
            }
            
            // Track goal setting
            await trackPointGoal(goal: goal)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get point goals
    public func getPointGoals() async -> [PointGoal] {
        return pointGoals
    }
    
    /// Check goal progress
    public func checkGoalProgress(goalId: UUID) async -> GoalProgress {
        do {
            // Get goal
            guard let goal = pointGoals.first(where: { $0.id == goalId }) else {
                return GoalProgress()
            }
            
            // Calculate progress
            let progress = try await calculateGoalProgress(goal: goal)
            
            return progress
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return GoalProgress()
        }
    }
    
    /// Export points data
    public func exportPointsData(format: ExportFormat = .json) async throws -> Data {
        do {
            let exportData = PointsExportData(
                currentPoints: currentPoints,
                totalPoints: totalPoints,
                pointHistory: pointHistory,
                multipliers: multipliers,
                bonuses: bonuses,
                pointGoals: pointGoals,
                timestamp: Date()
            )
            
            switch format {
            case .json:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try encoder.encode(exportData)
                
            case .csv:
                return try await exportToCSV(data: exportData)
                
            case .xml:
                return try await exportToXML(data: exportData)
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupPointsSystem() {
        // Setup points system
        setupPointCalculation()
        setupPointTracking()
        setupPointAnalytics()
        setupPointOptimization()
    }
    
    private func setupMultiplierSystem() {
        // Setup multiplier system
        setupMultiplierCalculation()
        setupMultiplierTracking()
        setupMultiplierAnalytics()
        setupMultiplierOptimization()
    }
    
    private func setupBonusSystem() {
        // Setup bonus system
        setupBonusCalculation()
        setupBonusTracking()
        setupBonusAnalytics()
        setupBonusOptimization()
    }
    
    private func initializePointsPlatform() async throws {
        // Initialize points platform
        try await loadPointsData()
        try await setupPointCalculation()
        try await initializeMultiplierSystem()
    }
    
    private func startContinuousPointsTracking() async throws {
        // Start continuous points tracking
        try await startPointUpdates()
        try await startMultiplierUpdates()
        try await startBonusUpdates()
    }
    
    private func validatePointsAward(activity: HealthActivity, points: Int) async throws {
        // Validate points award
        guard points > 0 else {
            throw PointsError.invalidPointsAmount(points)
        }
        
        guard activity.isValid else {
            throw PointsError.invalidActivity(activity.id.uuidString)
        }
    }
    
    private func calculateFinalPoints(activity: HealthActivity, basePoints: Int, context: PointContext?) async throws -> Int {
        // Calculate final points with multipliers and bonuses
        var finalPoints = basePoints
        
        // Apply multipliers
        let activeMultipliers = await getActiveMultipliers()
        for multiplier in activeMultipliers {
            if multiplier.isApplicable(to: activity) {
                finalPoints = Int(Double(finalPoints) * multiplier.multiplier)
            }
        }
        
        // Apply bonuses
        let activeBonuses = await getActiveBonuses()
        for bonus in activeBonuses {
            if bonus.isApplicable(to: activity) {
                finalPoints += bonus.bonusPoints
            }
        }
        
        return finalPoints
    }
    
    private func trackPointsAward(entry: PointEntry) async {
        // Track points award
        analyticsEngine.trackEvent("points_awarded", properties: [
            "activity_id": entry.activity.id.uuidString,
            "activity_type": entry.activity.type.rawValue,
            "base_points": entry.basePoints,
            "final_points": entry.finalPoints,
            "multipliers_count": entry.multipliers.count,
            "bonuses_count": entry.bonuses.count,
            "timestamp": entry.timestamp.timeIntervalSince1970
        ])
    }
    
    private func updatePointGoals() async {
        // Update point goals
        for goal in pointGoals {
            let progress = await checkGoalProgress(goalId: goal.id)
            if progress.isCompleted && !progress.wasPreviouslyCompleted {
                await completePointGoal(goal: goal)
            }
        }
    }
    
    private func generatePointInsights() async {
        // Generate point insights
        let analytics = await getPointAnalytics()
        let insights = analytics.insights
        
        // Track insights
        for insight in insights {
            analyticsEngine.trackEvent("point_insight_generated", properties: [
                "insight_id": insight.id.uuidString,
                "insight_type": insight.type.rawValue,
                "insight_priority": insight.priority.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }
    
    private func updatePointsProgress() async {
        // Update points progress
        let progress = await calculateOverallPointsProgress()
        await MainActor.run {
            self.pointsProgress = progress
        }
    }
    
    private func calculatePointMetrics() async throws -> PointMetrics {
        // Calculate point metrics
        let totalPoints = self.totalPoints
        let averageDailyPoints = calculateAverageDailyPoints()
        let pointTrends = calculatePointTrends()
        
        return PointMetrics(
            totalPoints: totalPoints,
            averageDailyPoints: averageDailyPoints,
            pointTrends: pointTrends,
            timestamp: Date()
        )
    }
    
    private func analyzePointPatterns() async throws -> PointPatterns {
        // Analyze point patterns
        let patterns = await analyzeEarningPatterns()
        let trends = await analyzeTrendPatterns()
        
        return PointPatterns(
            patterns: patterns,
            trends: trends,
            timestamp: Date()
        )
    }
    
    private func generatePointInsights(metrics: PointMetrics, patterns: PointPatterns) async throws -> [PointInsight] {
        // Generate point insights
        var insights: [PointInsight] = []
        
        // High earning day insight
        if metrics.averageDailyPoints > 100 {
            insights.append(PointInsight(
                id: UUID(),
                title: "High Performer",
                description: "You're earning an average of \(Int(metrics.averageDailyPoints)) points per day!",
                type: .performance,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        // Streak insight
        if let streak = patterns.trends.currentStreak, streak > 3 {
            insights.append(PointInsight(
                id: UUID(),
                title: "Consistent Earner",
                description: "You're on a \(streak)-day point earning streak!",
                type: .streak,
                priority: .high,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func loadActiveMultipliers() async throws -> [PointMultiplier] {
        // Load active multipliers
        let multipliers = [
            PointMultiplier(
                id: UUID(),
                name: "Weekend Bonus",
                description: "2x points on weekends",
                multiplier: 2.0,
                type: .weekend,
                isActive: Calendar.current.isDateInWeekend(Date()),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 2),
                timestamp: Date()
            ),
            PointMultiplier(
                id: UUID(),
                name: "Morning Boost",
                description: "1.5x points for morning activities",
                multiplier: 1.5,
                type: .timeOfDay,
                isActive: isMorningTime(),
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600 * 4),
                timestamp: Date()
            ),
            PointMultiplier(
                id: UUID(),
                name: "Streak Multiplier",
                description: "1.2x points for maintaining streaks",
                multiplier: 1.2,
                type: .streak,
                isActive: hasActiveStreak(),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400),
                timestamp: Date()
            )
        ]
        
        return multipliers.filter { $0.isActive }
    }
    
    private func loadActiveBonuses() async throws -> [PointBonus] {
        // Load active bonuses
        let bonuses = [
            PointBonus(
                id: UUID(),
                name: "First Activity",
                description: "50 bonus points for first activity of the day",
                bonusPoints: 50,
                type: .firstActivity,
                isActive: isFirstActivityOfDay(),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400),
                timestamp: Date()
            ),
            PointBonus(
                id: UUID(),
                name: "Goal Achievement",
                description: "100 bonus points for achieving daily goals",
                bonusPoints: 100,
                type: .goalAchievement,
                isActive: hasAchievedDailyGoals(),
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400),
                timestamp: Date()
            ),
            PointBonus(
                id: UUID(),
                name: "Social Activity",
                description: "25 bonus points for social health activities",
                bonusPoints: 25,
                type: .socialActivity,
                isActive: true,
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400),
                timestamp: Date()
            )
        ]
        
        return bonuses.filter { $0.isActive }
    }
    
    private func validatePointGoal(_ goal: PointGoal) async throws {
        // Validate point goal
        guard goal.targetPoints > 0 else {
            throw PointsError.invalidGoalTarget(goal.targetPoints)
        }
        
        guard goal.deadline > Date() else {
            throw PointsError.invalidGoalDeadline(goal.deadline)
        }
    }
    
    private func trackPointGoal(goal: PointGoal) async {
        // Track point goal
        analyticsEngine.trackEvent("point_goal_set", properties: [
            "goal_id": goal.id.uuidString,
            "goal_name": goal.name,
            "target_points": goal.targetPoints,
            "deadline": goal.deadline.timeIntervalSince1970,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func calculateGoalProgress(goal: PointGoal) async throws -> GoalProgress {
        // Calculate goal progress
        let currentPoints = self.currentPoints
        let progress = Double(currentPoints) / Double(goal.targetPoints)
        let isCompleted = progress >= 1.0
        
        return GoalProgress(
            goalId: goal.id,
            currentPoints: currentPoints,
            targetPoints: goal.targetPoints,
            progress: progress,
            isCompleted: isCompleted,
            wasPreviouslyCompleted: false,
            timestamp: Date()
        )
    }
    
    private func completePointGoal(goal: PointGoal) async {
        // Complete point goal
        analyticsEngine.trackEvent("point_goal_completed", properties: [
            "goal_id": goal.id.uuidString,
            "goal_name": goal.name,
            "target_points": goal.targetPoints,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func updatePointsStatus() async {
        // Update points status
        lastPointsUpdate = Date()
    }
    
    private func loadPointsData() async throws {
        // Load points data
        try await loadPointHistory()
        try await loadMultiplierData()
        try await loadBonusData()
    }
    
    private func setupPointCalculation() async throws {
        // Setup point calculation
        try await setupBasePointCalculation()
        try await setupMultiplierCalculation()
        try await setupBonusCalculation()
    }
    
    private func initializeMultiplierSystem() async throws {
        // Initialize multiplier system
        try await setupMultiplierTracking()
        try await setupMultiplierValidation()
        try await setupMultiplierAnalytics()
    }
    
    private func startPointUpdates() async throws {
        // Start point updates
        try await startPointCalculation()
        try await startPointTracking()
        try await startPointAnalytics()
    }
    
    private func startMultiplierUpdates() async throws {
        // Start multiplier updates
        try await startMultiplierCalculation()
        try await startMultiplierTracking()
        try await startMultiplierAnalytics()
    }
    
    private func startBonusUpdates() async throws {
        // Start bonus updates
        try await startBonusCalculation()
        try await startBonusTracking()
        try await startBonusAnalytics()
    }
    
    private func calculateAverageDailyPoints() -> Double {
        // Calculate average daily points
        let recentEntries = pointHistory.suffix(7)
        let totalPoints = recentEntries.reduce(0) { $0 + $1.finalPoints }
        return recentEntries.isEmpty ? 0.0 : Double(totalPoints) / Double(recentEntries.count)
    }
    
    private func calculatePointTrends() -> [PointTrend] {
        // Calculate point trends
        return []
    }
    
    private func analyzeEarningPatterns() async throws -> [EarningPattern] {
        // Analyze earning patterns
        return []
    }
    
    private func analyzeTrendPatterns() async throws -> PointTrends {
        // Analyze trend patterns
        return PointTrends(
            currentStreak: 0,
            longestStreak: 0,
            averageDailyPoints: 0.0,
            timestamp: Date()
        )
    }
    
    private func calculateOverallPointsProgress() async -> Double {
        // Calculate overall points progress
        let totalGoals = pointGoals.count
        let completedGoals = pointGoals.filter { goal in
            let progress = try? await calculateGoalProgress(goal: goal)
            return progress?.isCompleted ?? false
        }.count
        
        return totalGoals > 0 ? Double(completedGoals) / Double(totalGoals) : 0.0
    }
    
    private func isMorningTime() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour <= 10
    }
    
    private func hasActiveStreak() -> Bool {
        // Check for active streak
        return true // Placeholder
    }
    
    private func isFirstActivityOfDay() -> Bool {
        // Check if this is first activity of day
        let todayEntries = pointHistory.filter { entry in
            Calendar.current.isDate(entry.timestamp, inSameDayAs: Date())
        }
        return todayEntries.isEmpty
    }
    
    private func hasAchievedDailyGoals() -> Bool {
        // Check if daily goals achieved
        return true // Placeholder
    }
    
    private func loadPointHistory() async throws {
        // Load point history
    }
    
    private func loadMultiplierData() async throws {
        // Load multiplier data
    }
    
    private func loadBonusData() async throws {
        // Load bonus data
    }
    
    private func setupBasePointCalculation() async throws {
        // Setup base point calculation
    }
    
    private func setupMultiplierCalculation() async throws {
        // Setup multiplier calculation
    }
    
    private func setupBonusCalculation() async throws {
        // Setup bonus calculation
    }
    
    private func setupMultiplierTracking() async throws {
        // Setup multiplier tracking
    }
    
    private func setupMultiplierValidation() async throws {
        // Setup multiplier validation
    }
    
    private func setupMultiplierAnalytics() async throws {
        // Setup multiplier analytics
    }
    
    private func startPointCalculation() async throws {
        // Start point calculation
    }
    
    private func startPointTracking() async throws {
        // Start point tracking
    }
    
    private func startPointAnalytics() async throws {
        // Start point analytics
    }
    
    private func startMultiplierCalculation() async throws {
        // Start multiplier calculation
    }
    
    private func startMultiplierTracking() async throws {
        // Start multiplier tracking
    }
    
    private func startMultiplierAnalytics() async throws {
        // Start multiplier analytics
    }
    
    private func startBonusCalculation() async throws {
        // Start bonus calculation
    }
    
    private func startBonusTracking() async throws {
        // Start bonus tracking
    }
    
    private func startBonusAnalytics() async throws {
        // Start bonus analytics
    }
    
    private func exportToCSV(data: PointsExportData) async throws -> Data {
        // Export to CSV
        return Data()
    }
    
    private func exportToXML(data: PointsExportData) async throws -> Data {
        // Export to XML
        return Data()
    }
}

// MARK: - Data Models

public struct PointEntry: Identifiable, Codable {
    public let id: UUID
    public let activity: HealthActivity
    public let basePoints: Int
    public let finalPoints: Int
    public let multipliers: [PointMultiplier]
    public let bonuses: [PointBonus]
    public let context: PointContext?
    public let timestamp: Date
}

public struct PointMultiplier: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let multiplier: Double
    public let type: MultiplierType
    public let isActive: Bool
    public let startDate: Date
    public let endDate: Date
    public let timestamp: Date
    
    func isApplicable(to activity: HealthActivity) -> Bool {
        switch type {
        case .weekend:
            return Calendar.current.isDateInWeekend(Date())
        case .timeOfDay:
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= 6 && hour <= 10
        case .streak:
            return true // Placeholder
        case .activity:
            return true // Placeholder
        }
    }
}

public struct PointBonus: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let bonusPoints: Int
    public let type: BonusType
    public let isActive: Bool
    public let startDate: Date
    public let endDate: Date
    public let timestamp: Date
    
    func isApplicable(to activity: HealthActivity) -> Bool {
        switch type {
        case .firstActivity:
            return true // Placeholder
        case .goalAchievement:
            return true // Placeholder
        case .socialActivity:
            return activity.type == .social
        case .streak:
            return true // Placeholder
        }
    }
}

public struct PointGoal: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let targetPoints: Int
    public let deadline: Date
    public let category: GoalCategory
    public let isActive: Bool
    public let timestamp: Date
}

public struct PointAnalytics: Codable {
    public let totalPoints: Int
    public let averageDailyPoints: Double
    public let pointTrends: [PointTrend]
    public let pointPatterns: PointPatterns
    public let insights: [PointInsight]
    public let timestamp: Date
    
    public init() {
        self.totalPoints = 0
        self.averageDailyPoints = 0.0
        self.pointTrends = []
        self.pointPatterns = PointPatterns()
        self.insights = []
        self.timestamp = Date()
    }
}

public struct PointsExportData: Codable {
    public let currentPoints: Int
    public let totalPoints: Int
    public let pointHistory: [PointEntry]
    public let multipliers: [PointMultiplier]
    public let bonuses: [PointBonus]
    public let pointGoals: [PointGoal]
    public let timestamp: Date
}

public struct HealthActivity: Identifiable, Codable {
    public let id: UUID
    public let type: ActivityType
    public let name: String
    public let description: String
    public let duration: TimeInterval
    public let intensity: ActivityIntensity
    public let timestamp: Date
    
    var isValid: Bool {
        return !name.isEmpty && duration > 0
    }
}

public struct PointContext: Codable {
    public let timeOfDay: TimeOfDay
    public let healthStatus: HealthStatus
    public let userActivity: [String]
    public let deviceType: DeviceType
}

public struct GoalProgress: Codable {
    public let goalId: UUID
    public let currentPoints: Int
    public let targetPoints: Int
    public let progress: Double
    public let isCompleted: Bool
    public let wasPreviouslyCompleted: Bool
    public let timestamp: Date
    
    public init() {
        self.goalId = UUID()
        self.currentPoints = 0
        self.targetPoints = 0
        self.progress = 0.0
        self.isCompleted = false
        self.wasPreviouslyCompleted = false
        self.timestamp = Date()
    }
}

public struct PointMetrics: Codable {
    public let totalPoints: Int
    public let averageDailyPoints: Double
    public let pointTrends: [PointTrend]
    public let timestamp: Date
}

public struct PointPatterns: Codable {
    public let patterns: [EarningPattern]
    public let trends: PointTrends
    public let timestamp: Date
    
    public init() {
        self.patterns = []
        self.trends = PointTrends()
        self.timestamp = Date()
    }
}

public struct PointInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct PointTrend: Codable {
    public let date: Date
    public let points: Int
    public let trend: TrendDirection
}

public struct EarningPattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct PointTrends: Codable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let averageDailyPoints: Double
    public let timestamp: Date
    
    public init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.averageDailyPoints = 0.0
        self.timestamp = Date()
    }
}

public enum MultiplierType: String, Codable {
    case weekend = "weekend"
    case timeOfDay = "time_of_day"
    case streak = "streak"
    case activity = "activity"
}

public enum BonusType: String, Codable {
    case firstActivity = "first_activity"
    case goalAchievement = "goal_achievement"
    case socialActivity = "social_activity"
    case streak = "streak"
}

public enum ActivityType: String, Codable {
    case fitness = "fitness"
    case health = "health"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case social = "social"
    case consistency = "consistency"
    case goals = "goals"
}

public enum ActivityIntensity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case extreme = "extreme"
}

public enum GoalCategory: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case custom = "custom"
}

public enum TrendDirection: String, Codable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
}

public enum InsightType: String, Codable {
    case performance = "performance"
    case streak = "streak"
    case goal = "goal"
    case pattern = "pattern"
}

public enum InsightPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum TimeOfDay: String, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

public enum HealthStatus: String, Codable {
    case critical = "critical"
    case poor = "poor"
    case normal = "normal"
    case good = "good"
    case excellent = "excellent"
}

public enum DeviceType: String, Codable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case mac = "mac"
    case watch = "watch"
    case tv = "tv"
}

public enum ExportFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public enum PointsError: Error, LocalizedError {
    case invalidPointsAmount(Int)
    case invalidActivity(String)
    case invalidGoalTarget(Int)
    case invalidGoalDeadline(Date)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPointsAmount(let amount):
            return "Invalid points amount: \(amount)"
        case .invalidActivity(let id):
            return "Invalid activity: \(id)"
        case .invalidGoalTarget(let target):
            return "Invalid goal target: \(target)"
        case .invalidGoalDeadline(let deadline):
            return "Invalid goal deadline: \(deadline)"
        }
    }
}

// MARK: - Supporting Structures

public struct PointsData: Codable {
    public let points: [PointEntry]
    public let analytics: PointsAnalytics
}

public struct MultiplierData: Codable {
    public let multipliers: [PointMultiplier]
    public let analytics: MultiplierAnalytics
}

public struct BonusData: Codable {
    public let bonuses: [PointBonus]
    public let analytics: BonusAnalytics
}

public struct PointsAnalytics: Codable {
    public let totalPoints: Int
    public let averageDailyPoints: Double
    public let mostEarnedActivity: ActivityType
}

public struct MultiplierAnalytics: Codable {
    public let totalMultipliers: Int
    public let averageMultiplier: Double
    public let mostUsedMultiplier: MultiplierType
}

public struct BonusAnalytics: Codable {
    public let totalBonuses: Int
    public let averageBonus: Double
    public let mostUsedBonus: BonusType
} 