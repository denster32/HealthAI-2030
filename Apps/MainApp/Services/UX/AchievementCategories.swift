import Foundation
import SwiftUI
import Combine

/// Health Achievement Categories System
/// Provides comprehensive achievement categories, progression paths, and unlocking mechanisms
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class AchievementCategories: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var achievementCategories: [AchievementCategory] = []
    @Published public private(set) var userAchievements: [UserAchievement] = []
    @Published public private(set) var progressionPaths: [ProgressionPath] = []
    @Published public private(set) var achievementInsights: [AchievementInsight] = []
    @Published public private(set) var isAchievementActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var achievementProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private var cancellables = Set<AnyCancellable>()
    private let achievementQueue = DispatchQueue(label: "health.achievements", qos: .userInitiated)
    
    // Achievement data caches
    private var categoryData: [String: CategoryData] = [:]
    private var achievementData: [String: AchievementData] = [:]
    private var progressionData: [String: ProgressionData] = [:]
    
    // Achievement parameters
    private let achievementUpdateInterval: TimeInterval = 300.0 // 5 minutes
    private var lastAchievementUpdate: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupAchievementSystem()
        setupCategoryManagement()
        setupProgressionTracking()
        initializeAchievementPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start achievement system
    public func startAchievementSystem() async throws {
        isAchievementActive = true
        lastError = nil
        achievementProgress = 0.0
        
        do {
            // Initialize achievement platform
            try await initializeAchievementPlatform()
            
            // Start continuous achievement tracking
            try await startContinuousAchievementTracking()
            
            // Update achievement status
            await updateAchievementStatus()
            
            // Track achievement start
            analyticsEngine.trackEvent("achievement_system_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "total_categories": achievementCategories.count
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isAchievementActive = false
            }
            throw error
        }
    }
    
    /// Stop achievement system
    public func stopAchievementSystem() async {
        await MainActor.run {
            self.isAchievementActive = false
        }
        
        // Track achievement stop
        analyticsEngine.trackEvent("achievement_system_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(lastAchievementUpdate)
        ])
    }
    
    /// Get achievement categories
    public func getAchievementCategories() async -> [AchievementCategory] {
        do {
            // Load achievement categories
            let categories = try await loadAchievementCategories()
            
            await MainActor.run {
                self.achievementCategories = categories
            }
            
            return categories
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get user achievements
    public func getUserAchievements() async -> [UserAchievement] {
        do {
            // Load user achievements
            let achievements = try await loadUserAchievements()
            
            await MainActor.run {
                self.userAchievements = achievements
            }
            
            return achievements
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get progression paths
    public func getProgressionPaths() async -> [ProgressionPath] {
        do {
            // Load progression paths
            let paths = try await loadProgressionPaths()
            
            await MainActor.run {
                self.progressionPaths = paths
            }
            
            return paths
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Check achievement progress
    public func checkAchievementProgress(achievementId: UUID) async throws -> AchievementProgress {
        do {
            // Get achievement
            guard let achievement = await getAchievement(achievementId: achievementId) else {
                throw AchievementError.achievementNotFound(achievementId.uuidString)
            }
            
            // Calculate progress
            let progress = try await calculateAchievementProgress(achievement: achievement)
            
            // Check for completion
            if progress.isCompleted && !progress.wasPreviouslyCompleted {
                try await unlockAchievement(achievement: achievement)
            }
            
            return progress
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Unlock achievement
    public func unlockAchievement(achievement: Achievement) async throws {
        do {
            // Validate achievement unlock
            try await validateAchievementUnlock(achievement: achievement)
            
            // Create user achievement
            let userAchievement = UserAchievement(
                id: UUID(),
                achievementId: achievement.id,
                unlockedAt: Date(),
                progress: 1.0,
                isCompleted: true,
                timestamp: Date()
            )
            
            // Add to user achievements
            await MainActor.run {
                self.userAchievements.append(userAchievement)
            }
            
            // Track achievement unlock
            await trackAchievementUnlock(achievement: achievement)
            
            // Update progression paths
            await updateProgressionPaths(achievement: achievement)
            
            // Generate insights
            await generateAchievementInsights()
            
            // Update achievement progress
            await updateAchievementProgress()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get achievement insights
    public func getAchievementInsights() async -> [AchievementInsight] {
        do {
            // Analyze achievement patterns
            let patterns = try await analyzeAchievementPatterns()
            
            // Generate insights
            let insights = try await generateInsightsFromPatterns(patterns: patterns)
            
            await MainActor.run {
                self.achievementInsights = insights
            }
            
            return insights
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get category progress
    public func getCategoryProgress(categoryId: UUID) async -> CategoryProgress {
        do {
            // Get category
            guard let category = await getCategory(categoryId: categoryId) else {
                return CategoryProgress()
            }
            
            // Calculate category progress
            let progress = try await calculateCategoryProgress(category: category)
            
            return progress
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return CategoryProgress()
        }
    }
    
    /// Get progression path progress
    public func getProgressionPathProgress(pathId: UUID) async -> ProgressionPathProgress {
        do {
            // Get progression path
            guard let path = await getProgressionPath(pathId: pathId) else {
                return ProgressionPathProgress()
            }
            
            // Calculate path progress
            let progress = try await calculateProgressionPathProgress(path: path)
            
            return progress
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return ProgressionPathProgress()
        }
    }
    
    /// Export achievement data
    public func exportAchievementData(format: ExportFormat = .json) async throws -> Data {
        do {
            let exportData = AchievementExportData(
                achievementCategories: achievementCategories,
                userAchievements: userAchievements,
                progressionPaths: progressionPaths,
                achievementInsights: achievementInsights,
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
    
    private func setupAchievementSystem() {
        // Setup achievement system
        setupCategoryManagement()
        setupAchievementTracking()
        setupProgressionManagement()
        setupInsightGeneration()
    }
    
    private func setupCategoryManagement() {
        // Setup category management
        setupCategoryCreation()
        setupCategoryValidation()
        setupCategoryAnalytics()
        setupCategoryOptimization()
    }
    
    private func setupProgressionTracking() {
        // Setup progression tracking
        setupProgressionCalculation()
        setupProgressionValidation()
        setupProgressionAnalytics()
        setupProgressionOptimization()
    }
    
    private func initializeAchievementPlatform() async throws {
        // Initialize achievement platform
        try await loadAchievementData()
        try await setupAchievementCategories()
        try await initializeProgressionPaths()
    }
    
    private func startContinuousAchievementTracking() async throws {
        // Start continuous achievement tracking
        try await startAchievementUpdates()
        try await startProgressionUpdates()
        try await startInsightUpdates()
    }
    
    private func loadAchievementCategories() async throws -> [AchievementCategory] {
        // Load achievement categories
        let categories = [
            AchievementCategory(
                id: UUID(),
                name: "Fitness Master",
                description: "Achieve fitness milestones and build strength",
                icon: "figure.run",
                color: .blue,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Health Guardian",
                description: "Maintain optimal health and wellness",
                icon: "heart.fill",
                color: .red,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Sleep Champion",
                description: "Improve sleep quality and establish healthy sleep habits",
                icon: "bed.double.fill",
                color: .purple,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Nutrition Expert",
                description: "Make healthy food choices and maintain balanced nutrition",
                icon: "leaf.fill",
                color: .green,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Mindfulness Master",
                description: "Develop mental wellness and stress management skills",
                icon: "brain.head.profile",
                color: .orange,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Social Wellness",
                description: "Build meaningful connections and support networks",
                icon: "person.2.fill",
                color: .pink,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Consistency King",
                description: "Maintain consistent healthy habits over time",
                icon: "calendar.badge.clock",
                color: .yellow,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            ),
            AchievementCategory(
                id: UUID(),
                name: "Goal Crusher",
                description: "Set and achieve meaningful health goals",
                icon: "target",
                color: .indigo,
                achievements: [],
                progressionPath: nil,
                timestamp: Date()
            )
        ]
        
        return categories
    }
    
    private func loadUserAchievements() async throws -> [UserAchievement] {
        // Load user achievements
        return []
    }
    
    private func loadProgressionPaths() async throws -> [ProgressionPath] {
        // Load progression paths
        let paths = [
            ProgressionPath(
                id: UUID(),
                name: "Fitness Journey",
                description: "Progressive fitness milestones",
                stages: [
                    ProgressionStage(
                        id: UUID(),
                        name: "Beginner",
                        description: "Start your fitness journey",
                        requiredAchievements: 3,
                        rewards: [Reward(type: .points, value: 100)],
                        timestamp: Date()
                    ),
                    ProgressionStage(
                        id: UUID(),
                        name: "Intermediate",
                        description: "Build strength and endurance",
                        requiredAchievements: 7,
                        rewards: [Reward(type: .badge, value: 1)],
                        timestamp: Date()
                    ),
                    ProgressionStage(
                        id: UUID(),
                        name: "Advanced",
                        description: "Achieve peak fitness",
                        requiredAchievements: 12,
                        rewards: [Reward(type: .title, value: 1)],
                        timestamp: Date()
                    )
                ],
                timestamp: Date()
            ),
            ProgressionPath(
                id: UUID(),
                name: "Health Mastery",
                description: "Comprehensive health improvement",
                stages: [
                    ProgressionStage(
                        id: UUID(),
                        name: "Health Aware",
                        description: "Become aware of your health",
                        requiredAchievements: 5,
                        rewards: [Reward(type: .points, value: 200)],
                        timestamp: Date()
                    ),
                    ProgressionStage(
                        id: UUID(),
                        name: "Health Conscious",
                        description: "Make conscious health decisions",
                        requiredAchievements: 10,
                        rewards: [Reward(type: .badge, value: 1)],
                        timestamp: Date()
                    ),
                    ProgressionStage(
                        id: UUID(),
                        name: "Health Master",
                        description: "Master your health and wellness",
                        requiredAchievements: 15,
                        rewards: [Reward(type: .title, value: 1)],
                        timestamp: Date()
                    )
                ],
                timestamp: Date()
            )
        ]
        
        return paths
    }
    
    private func getAchievement(achievementId: UUID) async -> Achievement? {
        // Get achievement by ID
        return nil // Placeholder
    }
    
    private func calculateAchievementProgress(achievement: Achievement) async throws -> AchievementProgress {
        // Calculate achievement progress
        return AchievementProgress(
            achievementId: achievement.id,
            currentProgress: 0.5,
            targetProgress: 1.0,
            isCompleted: false,
            wasPreviouslyCompleted: false,
            timestamp: Date()
        )
    }
    
    private func validateAchievementUnlock(achievement: Achievement) async throws {
        // Validate achievement unlock
        let progress = try await calculateAchievementProgress(achievement: achievement)
        
        guard progress.isCompleted else {
            throw AchievementError.achievementNotCompleted(achievement.id.uuidString)
        }
        
        // Check if already unlocked
        let isAlreadyUnlocked = userAchievements.contains { userAchievement in
            userAchievement.achievementId == achievement.id && userAchievement.isCompleted
        }
        
        guard !isAlreadyUnlocked else {
            throw AchievementError.achievementAlreadyUnlocked(achievement.id.uuidString)
        }
    }
    
    private func trackAchievementUnlock(achievement: Achievement) async {
        // Track achievement unlock
        analyticsEngine.trackEvent("achievement_unlocked", properties: [
            "achievement_id": achievement.id.uuidString,
            "achievement_name": achievement.name,
            "category": achievement.category.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func updateProgressionPaths(achievement: Achievement) async {
        // Update progression paths
        for path in progressionPaths {
            await updateProgressionPath(path: path, achievement: achievement)
        }
    }
    
    private func generateAchievementInsights() async {
        // Generate achievement insights
        let patterns = await analyzeAchievementPatterns()
        let insights = await generateInsightsFromPatterns(patterns: patterns)
        
        await MainActor.run {
            self.achievementInsights = insights
        }
    }
    
    private func updateAchievementProgress() async {
        // Update achievement progress
        let progress = await calculateOverallAchievementProgress()
        await MainActor.run {
            self.achievementProgress = progress
        }
    }
    
    private func analyzeAchievementPatterns() async throws -> AchievementPatterns {
        // Analyze achievement patterns
        let patterns = await analyzeUnlockPatterns()
        let metrics = await calculateAchievementMetrics()
        
        return AchievementPatterns(
            patterns: patterns,
            metrics: metrics,
            timestamp: Date()
        )
    }
    
    private func generateInsightsFromPatterns(patterns: AchievementPatterns) async throws -> [AchievementInsight] {
        // Generate insights from patterns
        var insights: [AchievementInsight] = []
        
        // Most unlocked category insight
        if let topCategory = patterns.metrics.mostUnlockedCategories.first {
            insights.append(AchievementInsight(
                id: UUID(),
                title: "Category Champion",
                description: "You've unlocked the most achievements in \(topCategory.category.displayName)",
                type: .category,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        // Streak insight
        if patterns.metrics.currentStreak > 3 {
            insights.append(AchievementInsight(
                id: UUID(),
                title: "Achievement Streak",
                description: "You're on a \(patterns.metrics.currentStreak)-day achievement streak!",
                type: .streak,
                priority: .high,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func getCategory(categoryId: UUID) async -> AchievementCategory? {
        // Get category by ID
        return achievementCategories.first { $0.id == categoryId }
    }
    
    private func calculateCategoryProgress(category: AchievementCategory) async throws -> CategoryProgress {
        // Calculate category progress
        let categoryAchievements = await getCategoryAchievements(category: category)
        let unlockedAchievements = await getUnlockedAchievements(category: category)
        
        let progress = Double(unlockedAchievements.count) / Double(categoryAchievements.count)
        
        return CategoryProgress(
            categoryId: category.id,
            totalAchievements: categoryAchievements.count,
            unlockedAchievements: unlockedAchievements.count,
            progress: progress,
            timestamp: Date()
        )
    }
    
    private func getProgressionPath(pathId: UUID) async -> ProgressionPath? {
        // Get progression path by ID
        return progressionPaths.first { $0.id == pathId }
    }
    
    private func calculateProgressionPathProgress(path: ProgressionPath) async throws -> ProgressionPathProgress {
        // Calculate progression path progress
        let currentStage = await getCurrentStage(path: path)
        let completedStages = await getCompletedStages(path: path)
        
        let progress = Double(completedStages.count) / Double(path.stages.count)
        
        return ProgressionPathProgress(
            pathId: path.id,
            currentStage: currentStage,
            completedStages: completedStages.count,
            totalStages: path.stages.count,
            progress: progress,
            timestamp: Date()
        )
    }
    
    private func updateAchievementStatus() async {
        // Update achievement status
        lastAchievementUpdate = Date()
    }
    
    private func loadAchievementData() async throws {
        // Load achievement data
        try await loadCategoryData()
        try await loadAchievementData()
        try await loadProgressionData()
    }
    
    private func setupAchievementCategories() async throws {
        // Setup achievement categories
        try await setupCategoryCreation()
        try await setupCategoryValidation()
        try await setupCategoryAnalytics()
    }
    
    private func initializeProgressionPaths() async throws {
        // Initialize progression paths
        try await setupProgressionCalculation()
        try await setupProgressionValidation()
        try await setupProgressionAnalytics()
    }
    
    private func startAchievementUpdates() async throws {
        // Start achievement updates
        try await startCategoryUpdates()
        try await startAchievementTracking()
        try await startAnalyticsUpdates()
    }
    
    private func startProgressionUpdates() async throws {
        // Start progression updates
        try await startProgressionCalculation()
        try await startProgressionValidation()
        try await startProgressionAnalytics()
    }
    
    private func startInsightUpdates() async throws {
        // Start insight updates
        try await startPatternAnalysis()
        try await startInsightGeneration()
        try await startInsightOptimization()
    }
    
    private func updateProgressionPath(path: ProgressionPath, achievement: Achievement) async {
        // Update progression path
    }
    
    private func analyzeUnlockPatterns() async throws -> [UnlockPattern] {
        // Analyze unlock patterns
        return []
    }
    
    private func calculateAchievementMetrics() async throws -> AchievementMetrics {
        // Calculate achievement metrics
        return AchievementMetrics(
            totalUnlocked: userAchievements.filter { $0.isCompleted }.count,
            totalAvailable: achievementCategories.reduce(0) { $0 + $1.achievements.count },
            currentStreak: 0,
            longestStreak: 0,
            mostUnlockedCategories: [],
            timestamp: Date()
        )
    }
    
    private func calculateOverallAchievementProgress() async -> Double {
        // Calculate overall achievement progress
        let totalUnlocked = userAchievements.filter { $0.isCompleted }.count
        let totalAvailable = achievementCategories.reduce(0) { $0 + $1.achievements.count }
        
        return totalAvailable > 0 ? Double(totalUnlocked) / Double(totalAvailable) : 0.0
    }
    
    private func getCategoryAchievements(category: AchievementCategory) async -> [Achievement] {
        // Get category achievements
        return []
    }
    
    private func getUnlockedAchievements(category: AchievementCategory) async -> [Achievement] {
        // Get unlocked achievements for category
        return []
    }
    
    private func getCurrentStage(path: ProgressionPath) async -> ProgressionStage? {
        // Get current stage
        return nil
    }
    
    private func getCompletedStages(path: ProgressionPath) async -> [ProgressionStage] {
        // Get completed stages
        return []
    }
    
    private func loadCategoryData() async throws {
        // Load category data
    }
    
    private func loadAchievementData() async throws {
        // Load achievement data
    }
    
    private func loadProgressionData() async throws {
        // Load progression data
    }
    
    private func setupCategoryCreation() async throws {
        // Setup category creation
    }
    
    private func setupCategoryValidation() async throws {
        // Setup category validation
    }
    
    private func setupCategoryAnalytics() async throws {
        // Setup category analytics
    }
    
    private func setupProgressionCalculation() async throws {
        // Setup progression calculation
    }
    
    private func setupProgressionValidation() async throws {
        // Setup progression validation
    }
    
    private func setupProgressionAnalytics() async throws {
        // Setup progression analytics
    }
    
    private func startCategoryUpdates() async throws {
        // Start category updates
    }
    
    private func startAchievementTracking() async throws {
        // Start achievement tracking
    }
    
    private func startAnalyticsUpdates() async throws {
        // Start analytics updates
    }
    
    private func startProgressionCalculation() async throws {
        // Start progression calculation
    }
    
    private func startProgressionValidation() async throws {
        // Start progression validation
    }
    
    private func startProgressionAnalytics() async throws {
        // Start progression analytics
    }
    
    private func startPatternAnalysis() async throws {
        // Start pattern analysis
    }
    
    private func startInsightGeneration() async throws {
        // Start insight generation
    }
    
    private func startInsightOptimization() async throws {
        // Start insight optimization
    }
    
    private func exportToCSV(data: AchievementExportData) async throws -> Data {
        // Export to CSV
        return Data()
    }
    
    private func exportToXML(data: AchievementExportData) async throws -> Data {
        // Export to XML
        return Data()
    }
}

// MARK: - Data Models

public struct AchievementCategory: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let icon: String
    public let color: Color
    public let achievements: [Achievement]
    public let progressionPath: ProgressionPath?
    public let timestamp: Date
}

public struct Achievement: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let category: AchievementCategoryType
    public let type: AchievementType
    public let difficulty: AchievementDifficulty
    public let requirements: [AchievementRequirement]
    public let rewards: [Reward]
    public let icon: String
    public let timestamp: Date
}

public struct UserAchievement: Identifiable, Codable {
    public let id: UUID
    public let achievementId: UUID
    public let unlockedAt: Date
    public let progress: Double
    public let isCompleted: Bool
    public let timestamp: Date
}

public struct ProgressionPath: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let stages: [ProgressionStage]
    public let timestamp: Date
}

public struct ProgressionStage: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let requiredAchievements: Int
    public let rewards: [Reward]
    public let timestamp: Date
}

public struct AchievementInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct AchievementExportData: Codable {
    public let achievementCategories: [AchievementCategory]
    public let userAchievements: [UserAchievement]
    public let progressionPaths: [ProgressionPath]
    public let achievementInsights: [AchievementInsight]
    public let timestamp: Date
}

public struct AchievementProgress: Codable {
    public let achievementId: UUID
    public let currentProgress: Double
    public let targetProgress: Double
    public let isCompleted: Bool
    public let wasPreviouslyCompleted: Bool
    public let timestamp: Date
}

public struct CategoryProgress: Codable {
    public let categoryId: UUID
    public let totalAchievements: Int
    public let unlockedAchievements: Int
    public let progress: Double
    public let timestamp: Date
    
    public init() {
        self.categoryId = UUID()
        self.totalAchievements = 0
        self.unlockedAchievements = 0
        self.progress = 0.0
        self.timestamp = Date()
    }
}

public struct ProgressionPathProgress: Codable {
    public let pathId: UUID
    public let currentStage: ProgressionStage?
    public let completedStages: Int
    public let totalStages: Int
    public let progress: Double
    public let timestamp: Date
    
    public init() {
        self.pathId = UUID()
        self.currentStage = nil
        self.completedStages = 0
        self.totalStages = 0
        self.progress = 0.0
        self.timestamp = Date()
    }
}

public struct Reward: Codable {
    public let type: RewardType
    public let value: Int
    public let description: String?
    
    public init(type: RewardType, value: Int, description: String? = nil) {
        self.type = type
        self.value = value
        self.description = description
    }
}

public enum AchievementCategoryType: String, Codable {
    case fitness = "fitness"
    case health = "health"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case social = "social"
    case consistency = "consistency"
    case goals = "goals"
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .health: return "Health"
        case .sleep: return "Sleep"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .social: return "Social"
        case .consistency: return "Consistency"
        case .goals: return "Goals"
        }
    }
}

public enum AchievementType: String, Codable {
    case milestone = "milestone"
    case streak = "streak"
    case challenge = "challenge"
    case collection = "collection"
    case mastery = "mastery"
}

public enum AchievementDifficulty: String, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
}

public struct AchievementRequirement: Codable {
    public let type: RequirementType
    public let value: Double
    public let description: String
}

public enum RequirementType: String, Codable {
    case steps = "steps"
    case workouts = "workouts"
    case sleepHours = "sleep_hours"
    case waterIntake = "water_intake"
    case meditationMinutes = "meditation_minutes"
    case socialConnections = "social_connections"
    case consecutiveDays = "consecutive_days"
}

public enum RewardType: String, Codable {
    case points = "points"
    case badge = "badge"
    case title = "title"
    case unlock = "unlock"
    case bonus = "bonus"
}

public enum InsightType: String, Codable {
    case category = "category"
    case streak = "streak"
    case milestone = "milestone"
    case progress = "progress"
}

public enum InsightPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum ExportFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public enum AchievementError: Error, LocalizedError {
    case achievementNotFound(String)
    case achievementNotCompleted(String)
    case achievementAlreadyUnlocked(String)
    case invalidRequirement(String)
    
    public var errorDescription: String? {
        switch self {
        case .achievementNotFound(let id):
            return "Achievement not found: \(id)"
        case .achievementNotCompleted(let id):
            return "Achievement not completed: \(id)"
        case .achievementAlreadyUnlocked(let id):
            return "Achievement already unlocked: \(id)"
        case .invalidRequirement(let requirement):
            return "Invalid requirement: \(requirement)"
        }
    }
}

// MARK: - Supporting Structures

public struct AchievementPatterns: Codable {
    public let patterns: [UnlockPattern]
    public let metrics: AchievementMetrics
    public let timestamp: Date
}

public struct UnlockPattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct AchievementMetrics: Codable {
    public let totalUnlocked: Int
    public let totalAvailable: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let mostUnlockedCategories: [CategoryUnlockCount]
    public let timestamp: Date
}

public struct CategoryUnlockCount: Codable {
    public let category: AchievementCategoryType
    public let unlockCount: Int
}

public struct CategoryData: Codable {
    public let categories: [AchievementCategory]
    public let analytics: CategoryAnalytics
}

public struct AchievementData: Codable {
    public let achievements: [Achievement]
    public let userAchievements: [UserAchievement]
    public let analytics: AchievementAnalytics
}

public struct ProgressionData: Codable {
    public let paths: [ProgressionPath]
    public let progress: [ProgressionPathProgress]
    public let analytics: ProgressionAnalytics
}

public struct CategoryAnalytics: Codable {
    public let totalCategories: Int
    public let averageAchievementsPerCategory: Double
    public let mostPopularCategory: AchievementCategoryType
}

public struct AchievementAnalytics: Codable {
    public let totalAchievements: Int
    public let totalUnlocked: Int
    public let averageDifficulty: AchievementDifficulty
}

public struct ProgressionAnalytics: Codable {
    public let totalPaths: Int
    public let averageStagesPerPath: Double
    public let mostCompletedPath: UUID
}

// MARK: - Color Extension
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        self = .blue // Default color
    }
    
    public func encode(to encoder: Encoder) throws {
        // Encode color as string
    }
} 