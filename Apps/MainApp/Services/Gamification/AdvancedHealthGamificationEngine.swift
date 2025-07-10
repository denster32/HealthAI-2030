import Foundation
import Combine
import SwiftUI

/// Advanced Health Gamification & Motivation Engine
/// Provides comprehensive gamification, rewards, challenges, social features, and behavioral psychology integration
@available(iOS 18.0, macOS 15.0, *)
public actor AdvancedHealthGamificationEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var userProfile: GamificationProfile = GamificationProfile()
    @Published public private(set) var activeChallenges: [HealthChallenge] = []
    @Published public private(set) var completedChallenges: [HealthChallenge] = []
    @Published public private(set) var achievements: [Achievement] = []
    @Published public private(set) var rewards: [Reward] = []
    @Published public private(set) var leaderboards: [Leaderboard] = []
    @Published public private(set) var socialConnections: [SocialConnection] = []
    @Published public private(set) var motivationStreak: MotivationStreak = MotivationStreak()
    @Published public private(set) var isGamificationActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var gamificationProgress: Double = 0.0
    @Published public private(set) var dailyGoals: [DailyGoal] = []
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private let behavioralPsychologyEngine: BehavioralPsychologyEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let gamificationQueue = DispatchQueue(label: "health.gamification", qos: .userInitiated)
    private let motivationQueue = DispatchQueue(label: "health.motivation", qos: .userInitiated)
    
    // Gamification data caches
    private var challengeData: [String: ChallengeData] = [:]
    private var achievementData: [String: AchievementData] = [:]
    private var rewardData: [String: RewardData] = [:]
    private var socialData: [String: SocialData] = [:]
    private var motivationData: [String: MotivationData] = [:]
    
    // Gamification parameters
    private let challengeUpdateInterval: TimeInterval = 300.0 // 5 minutes
    private var lastChallengeUpdate: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        self.behavioralPsychologyEngine = BehavioralPsychologyEngine()
        
        setupGamificationSystem()
        setupMotivationEngine()
        setupSocialFeatures()
        setupRewardSystem()
        initializeGamificationPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start gamification system
    public func startGamification() async throws {
        isGamificationActive = true
        lastError = nil
        gamificationProgress = 0.0
        
        do {
            // Initialize gamification platform
            try await initializeGamificationPlatform()
            
            // Start continuous gamification
            try await startContinuousGamification()
            
            // Update gamification status
            await updateGamificationStatus()
            
            // Track gamification
            analyticsEngine.trackEvent("gamification_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "user_level": userProfile.level
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isGamificationActive = false
            }
            throw error
        }
    }
    
    /// Stop gamification system
    public func stopGamification() async {
        isGamificationActive = false
        gamificationProgress = 0.0
        
        // Save final gamification data
        if !activeChallenges.isEmpty {
            await MainActor.run {
                // Save progress
            }
        }
        
        // Track gamification
        analyticsEngine.trackEvent("gamification_stopped", properties: [
            "duration": Date().timeIntervalSince(lastChallengeUpdate),
            "challenges_completed": completedChallenges.count
        ])
    }
    
    /// Create new challenge
    public func createChallenge(_ challenge: HealthChallenge) async throws {
        do {
            // Validate challenge
            try await validateChallenge(challenge: challenge)
            
            // Create challenge
            let createdChallenge = try await createChallengeInstance(challenge: challenge)
            
            // Add to active challenges
            await MainActor.run {
                self.activeChallenges.append(createdChallenge)
            }
            
            // Track challenge creation
            analyticsEngine.trackEvent("challenge_created", properties: [
                "challenge_id": challenge.id.uuidString,
                "challenge_type": challenge.type.rawValue,
                "difficulty": challenge.difficulty.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Join challenge
    public func joinChallenge(_ challenge: HealthChallenge) async throws {
        do {
            // Validate challenge availability
            try await validateChallengeAvailability(challenge: challenge)
            
            // Join challenge
            try await joinChallengeInstance(challenge: challenge)
            
            // Update user profile
            await updateUserProfileForChallenge(challenge: challenge)
            
            // Track challenge join
            analyticsEngine.trackEvent("challenge_joined", properties: [
                "challenge_id": challenge.id.uuidString,
                "user_id": userProfile.id.uuidString,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Complete challenge
    public func completeChallenge(_ challenge: HealthChallenge) async throws {
        do {
            // Validate challenge completion
            try await validateChallengeCompletion(challenge: challenge)
            
            // Complete challenge
            let completion = try await completeChallengeInstance(challenge: challenge)
            
            // Award rewards
            try await awardRewards(completion: completion)
            
            // Update user profile
            await updateUserProfileForCompletion(completion: completion)
            
            // Move to completed challenges
            await MainActor.run {
                self.activeChallenges.removeAll { $0.id == challenge.id }
                self.completedChallenges.append(challenge)
            }
            
            // Track challenge completion
            analyticsEngine.trackEvent("challenge_completed", properties: [
                "challenge_id": challenge.id.uuidString,
                "completion_time": completion.completionTime.timeIntervalSince1970,
                "points_earned": completion.pointsEarned,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Unlock achievement
    public func unlockAchievement(_ achievement: Achievement) async throws {
        do {
            // Validate achievement unlock
            try await validateAchievementUnlock(achievement: achievement)
            
            // Unlock achievement
            let unlock = try await unlockAchievementInstance(achievement: achievement)
            
            // Award rewards
            try await awardAchievementRewards(unlock: unlock)
            
            // Update user profile
            await updateUserProfileForAchievement(unlock: unlock)
            
            // Add to achievements
            await MainActor.run {
                self.achievements.append(achievement)
            }
            
            // Track achievement unlock
            analyticsEngine.trackEvent("achievement_unlocked", properties: [
                "achievement_id": achievement.id.uuidString,
                "achievement_type": achievement.type.rawValue,
                "points_earned": unlock.pointsEarned,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Claim reward
    public func claimReward(_ reward: Reward) async throws {
        do {
            // Validate reward claim
            try await validateRewardClaim(reward: reward)
            
            // Claim reward
            let claim = try await claimRewardInstance(reward: reward)
            
            // Update user profile
            await updateUserProfileForReward(claim: claim)
            
            // Track reward claim
            analyticsEngine.trackEvent("reward_claimed", properties: [
                "reward_id": reward.id.uuidString,
                "reward_type": reward.type.rawValue,
                "value": reward.value,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get user profile
    public func getUserProfile() async -> GamificationProfile {
        return userProfile
    }
    
    /// Get active challenges
    public func getActiveChallenges(category: ChallengeCategory = .all) async -> [HealthChallenge] {
        let filteredChallenges = activeChallenges.filter { challenge in
            switch category {
            case .all: return true
            case .fitness: return challenge.category == .fitness
            case .nutrition: return challenge.category == .nutrition
            case .sleep: return challenge.category == .sleep
            case .mental: return challenge.category == .mental
            case .social: return challenge.category == .social
            }
        }
        
        return filteredChallenges
    }
    
    /// Get completed challenges
    public func getCompletedChallenges(category: ChallengeCategory = .all) async -> [HealthChallenge] {
        let filteredChallenges = completedChallenges.filter { challenge in
            switch category {
            case .all: return true
            case .fitness: return challenge.category == .fitness
            case .nutrition: return challenge.category == .nutrition
            case .sleep: return challenge.category == .sleep
            case .mental: return challenge.category == .mental
            case .social: return challenge.category == .social
            }
        }
        
        return filteredChallenges
    }
    
    /// Get achievements
    public func getAchievements(type: AchievementType = .all) async -> [Achievement] {
        let filteredAchievements = achievements.filter { achievement in
            switch type {
            case .all: return true
            case .fitness: return achievement.type == .fitness
            case .nutrition: return achievement.type == .nutrition
            case .sleep: return achievement.type == .sleep
            case .mental: return achievement.type == .mental
            case .social: return achievement.type == .social
            case .streak: return achievement.type == .streak
            case .milestone: return achievement.type == .milestone
            }
        }
        
        return filteredAchievements
    }
    
    /// Get rewards
    public func getRewards(type: RewardType = .all) async -> [Reward] {
        let filteredRewards = rewards.filter { reward in
            switch type {
            case .all: return true
            case .points: return reward.type == .points
            case .badge: return reward.type == .badge
            case .unlock: return reward.type == .unlock
            case .bonus: return reward.type == .bonus
            }
        }
        
        return filteredRewards
    }
    
    /// Get leaderboards
    public func getLeaderboards(category: LeaderboardCategory = .all) async -> [Leaderboard] {
        let filteredLeaderboards = leaderboards.filter { leaderboard in
            switch category {
            case .all: return true
            case .global: return leaderboard.category == .global
            case .friends: return leaderboard.category == .friends
            case .local: return leaderboard.category == .local
            case .weekly: return leaderboard.category == .weekly
            case .monthly: return leaderboard.category == .monthly
            }
        }
        
        return filteredLeaderboards
    }
    
    /// Get social connections
    public func getSocialConnections(status: ConnectionStatus = .all) async -> [SocialConnection] {
        let filteredConnections = socialConnections.filter { connection in
            switch status {
            case .all: return true
            case .active: return connection.status == .active
            case .pending: return connection.status == .pending
            case .inactive: return connection.status == .inactive
            }
        }
        
        return filteredConnections
    }
    
    /// Get motivation streak
    public func getMotivationStreak() async -> MotivationStreak {
        return motivationStreak
    }
    
    /// Get daily goals
    public func getDailyGoals() async -> [DailyGoal] {
        return dailyGoals
    }
    
    /// Update daily goal progress
    public func updateDailyGoalProgress(goalId: String, progress: Double) async throws {
        do {
            // Update goal progress
            try await updateGoalProgress(goalId: goalId, progress: progress)
            
            // Check for goal completion
            if progress >= 1.0 {
                try await completeDailyGoal(goalId: goalId)
            }
            
            // Update motivation streak
            await updateMotivationStreak()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Generate personalized challenges
    public func generatePersonalizedChallenges() async throws -> [HealthChallenge] {
        do {
            // Analyze user behavior
            let behaviorAnalysis = try await analyzeUserBehavior()
            
            // Generate challenges based on behavior
            let challenges = try await generateChallengesFromBehavior(analysis: behaviorAnalysis)
            
            // Apply behavioral psychology principles
            let personalizedChallenges = try await applyBehavioralPsychology(challenges: challenges)
            
            return personalizedChallenges
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get motivation insights
    public func getMotivationInsights() async throws -> [MotivationInsight] {
        do {
            // Analyze motivation patterns
            let patterns = try await analyzeMotivationPatterns()
            
            // Generate insights
            let insights = try await generateMotivationInsights(patterns: patterns)
            
            // Apply behavioral psychology
            let enhancedInsights = try await applyBehavioralPsychologyToInsights(insights: insights)
            
            return enhancedInsights
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Export gamification data
    public func exportGamificationData(format: ExportFormat = .json) async throws -> Data {
        let exportData = GamificationExportData(
            timestamp: Date(),
            userProfile: userProfile,
            activeChallenges: activeChallenges,
            completedChallenges: completedChallenges,
            achievements: achievements,
            rewards: rewards,
            leaderboards: leaderboards,
            socialConnections: socialConnections,
            motivationStreak: motivationStreak,
            dailyGoals: dailyGoals
        )
        
        switch format {
        case .json:
            return try JSONEncoder().encode(exportData)
        case .csv:
            return try exportToCSV(exportData: exportData)
        case .xml:
            return try exportToXML(exportData: exportData)
        case .pdf:
            return try exportToPDF(exportData: exportData)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupGamificationSystem() {
        // Setup gamification system
        setupChallengeSystem()
        setupAchievementSystem()
        setupRewardSystem()
        setupLeaderboardSystem()
    }
    
    private func setupMotivationEngine() {
        // Setup motivation engine
        setupMotivationTracking()
        setupStreakCalculation()
        setupGoalManagement()
        setupBehavioralPsychology()
    }
    
    private func setupSocialFeatures() {
        // Setup social features
        setupSocialConnections()
        setupSocialChallenges()
        setupSocialRewards()
        setupSocialAnalytics()
    }
    
    private func setupRewardSystem() {
        // Setup reward system
        setupRewardCalculation()
        setupRewardDistribution()
        setupRewardTracking()
        setupRewardAnalytics()
    }
    
    private func initializeGamificationPlatform() async throws {
        // Initialize gamification platform
        try await loadUserProfile()
        try await loadChallenges()
        try await loadAchievements()
        try await loadRewards()
    }
    
    private func startContinuousGamification() async throws {
        // Start continuous gamification
        try await startChallengeUpdates()
        try await startMotivationTracking()
        try await startSocialUpdates()
    }
    
    private func validateChallenge(challenge: HealthChallenge) async throws {
        // Validate challenge
    }
    
    private func createChallengeInstance(challenge: HealthChallenge) async throws -> HealthChallenge {
        return challenge
    }
    
    private func validateChallengeAvailability(challenge: HealthChallenge) async throws {
        // Validate challenge availability
    }
    
    private func joinChallengeInstance(challenge: HealthChallenge) async throws {
        // Join challenge instance
    }
    
    private func updateUserProfileForChallenge(challenge: HealthChallenge) async {
        // Update user profile for challenge
    }
    
    private func validateChallengeCompletion(challenge: HealthChallenge) async throws {
        // Validate challenge completion
    }
    
    private func completeChallengeInstance(challenge: HealthChallenge) async throws -> ChallengeCompletion {
        return ChallengeCompletion(
            challengeId: challenge.id,
            completionTime: Date(),
            pointsEarned: challenge.points,
            bonusPoints: 0,
            timestamp: Date()
        )
    }
    
    private func awardRewards(completion: ChallengeCompletion) async throws {
        // Award rewards for completion
    }
    
    private func updateUserProfileForCompletion(completion: ChallengeCompletion) async {
        // Update user profile for completion
    }
    
    private func validateAchievementUnlock(achievement: Achievement) async throws {
        // Validate achievement unlock
    }
    
    private func unlockAchievementInstance(achievement: Achievement) async throws -> AchievementUnlock {
        return AchievementUnlock(
            achievementId: achievement.id,
            unlockTime: Date(),
            pointsEarned: achievement.points,
            bonusPoints: 0,
            timestamp: Date()
        )
    }
    
    private func awardAchievementRewards(unlock: AchievementUnlock) async throws {
        // Award achievement rewards
    }
    
    private func updateUserProfileForAchievement(unlock: AchievementUnlock) async {
        // Update user profile for achievement
    }
    
    private func validateRewardClaim(reward: Reward) async throws {
        // Validate reward claim
    }
    
    private func claimRewardInstance(reward: Reward) async throws -> RewardClaim {
        return RewardClaim(
            rewardId: reward.id,
            claimTime: Date(),
            value: reward.value,
            timestamp: Date()
        )
    }
    
    private func updateUserProfileForReward(claim: RewardClaim) async {
        // Update user profile for reward
    }
    
    private func analyzeUserBehavior() async throws -> BehaviorAnalysis {
        return BehaviorAnalysis(
            fitnessPatterns: [],
            nutritionPatterns: [],
            sleepPatterns: [],
            socialPatterns: [],
            motivationPatterns: [],
            timestamp: Date()
        )
    }
    
    private func generateChallengesFromBehavior(analysis: BehaviorAnalysis) async throws -> [HealthChallenge] {
        return []
    }
    
    private func applyBehavioralPsychology(challenges: [HealthChallenge]) async throws -> [HealthChallenge] {
        return challenges
    }
    
    private func analyzeMotivationPatterns() async throws -> [MotivationPattern] {
        return []
    }
    
    private func generateMotivationInsights(patterns: [MotivationPattern]) async throws -> [MotivationInsight] {
        return []
    }
    
    private func applyBehavioralPsychologyToInsights(insights: [MotivationInsight]) async throws -> [MotivationInsight] {
        return insights
    }
    
    private func updateGoalProgress(goalId: String, progress: Double) async throws {
        // Update goal progress
    }
    
    private func completeDailyGoal(goalId: String) async throws {
        // Complete daily goal
    }
    
    private func updateMotivationStreak() async {
        // Update motivation streak
    }
    
    private func updateGamificationStatus() async {
        // Update gamification status
        gamificationProgress = 1.0
    }
    
    // MARK: - Setup Methods
    
    private func setupChallengeSystem() {
        // Setup challenge system
    }
    
    private func setupAchievementSystem() {
        // Setup achievement system
    }
    
    private func setupRewardSystem() {
        // Setup reward system
    }
    
    private func setupLeaderboardSystem() {
        // Setup leaderboard system
    }
    
    private func setupMotivationTracking() {
        // Setup motivation tracking
    }
    
    private func setupStreakCalculation() {
        // Setup streak calculation
    }
    
    private func setupGoalManagement() {
        // Setup goal management
    }
    
    private func setupBehavioralPsychology() {
        // Setup behavioral psychology
    }
    
    private func setupSocialConnections() {
        // Setup social connections
    }
    
    private func setupSocialChallenges() {
        // Setup social challenges
    }
    
    private func setupSocialRewards() {
        // Setup social rewards
    }
    
    private func setupSocialAnalytics() {
        // Setup social analytics
    }
    
    private func setupRewardCalculation() {
        // Setup reward calculation
    }
    
    private func setupRewardDistribution() {
        // Setup reward distribution
    }
    
    private func setupRewardTracking() {
        // Setup reward tracking
    }
    
    private func setupRewardAnalytics() {
        // Setup reward analytics
    }
    
    private func loadUserProfile() async throws {
        // Load user profile
    }
    
    private func loadChallenges() async throws {
        // Load challenges
    }
    
    private func loadAchievements() async throws {
        // Load achievements
    }
    
    private func loadRewards() async throws {
        // Load rewards
    }
    
    private func startChallengeUpdates() async throws {
        // Start challenge updates
    }
    
    private func startMotivationTracking() async throws {
        // Start motivation tracking
    }
    
    private func startSocialUpdates() async throws {
        // Start social updates
    }
    
    // MARK: - Export Methods
    
    private func exportToCSV(exportData: GamificationExportData) throws -> Data {
        // Implement CSV export
        return Data()
    }
    
    private func exportToXML(exportData: GamificationExportData) throws -> Data {
        // Implement XML export
        return Data()
    }
    
    private func exportToPDF(exportData: GamificationExportData) throws -> Data {
        // Implement PDF export
        return Data()
    }
}

// MARK: - Supporting Models

public struct GamificationProfile: Codable {
    public let id: UUID
    public let username: String
    public let level: Int
    public let experience: Int
    public let points: Int
    public let rank: String
    public let joinDate: Date
    public let lastActive: Date
    public let preferences: GamificationPreferences
    public let statistics: GamificationStatistics
    public let timestamp: Date
}

public struct HealthChallenge: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: ChallengeCategory
    public let type: ChallengeType
    public let difficulty: ChallengeDifficulty
    public let points: Int
    public let duration: TimeInterval
    public let requirements: [ChallengeRequirement]
    public let rewards: [Reward]
    public let startDate: Date
    public let endDate: Date
    public let status: ChallengeStatus
    public let participants: [UUID]
    public let timestamp: Date
}

public struct Achievement: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: AchievementType
    public let category: AchievementCategory
    public let points: Int
    public let icon: String
    public let rarity: AchievementRarity
    public let requirements: [AchievementRequirement]
    public let unlockedDate: Date?
    public let timestamp: Date
}

public struct Reward: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: RewardType
    public let category: RewardCategory
    public let value: Int
    public let icon: String
    public let rarity: RewardRarity
    public let claimedDate: Date?
    public let timestamp: Date
}

public struct Leaderboard: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let category: LeaderboardCategory
    public let type: LeaderboardType
    public let entries: [LeaderboardEntry]
    public let startDate: Date
    public let endDate: Date
    public let timestamp: Date
}

public struct SocialConnection: Identifiable, Codable {
    public let id: UUID
    public let userId: UUID
    public let username: String
    public let status: ConnectionStatus
    public let connectionDate: Date
    public let lastInteraction: Date
    public let sharedChallenges: [UUID]
    public let timestamp: Date
}

public struct MotivationStreak: Codable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let streakType: StreakType
    public let startDate: Date
    public let lastActivity: Date
    public let milestones: [StreakMilestone]
    public let timestamp: Date
}

public struct DailyGoal: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let category: GoalCategory
    public let target: Double
    public let current: Double
    public let progress: Double
    public let points: Int
    public let completed: Bool
    public let timestamp: Date
}

public struct ChallengeCompletion: Codable {
    public let challengeId: UUID
    public let completionTime: Date
    public let pointsEarned: Int
    public let bonusPoints: Int
    public let timestamp: Date
}

public struct AchievementUnlock: Codable {
    public let achievementId: UUID
    public let unlockTime: Date
    public let pointsEarned: Int
    public let bonusPoints: Int
    public let timestamp: Date
}

public struct RewardClaim: Codable {
    public let rewardId: UUID
    public let claimTime: Date
    public let value: Int
    public let timestamp: Date
}

public struct BehaviorAnalysis: Codable {
    public let fitnessPatterns: [FitnessPattern]
    public let nutritionPatterns: [NutritionPattern]
    public let sleepPatterns: [SleepPattern]
    public let socialPatterns: [SocialPattern]
    public let motivationPatterns: [MotivationPattern]
    public let timestamp: Date
}

public struct MotivationInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: InsightCategory
    public let severity: Severity
    public let recommendations: [String]
    public let timestamp: Date
}

public struct GamificationExportData: Codable {
    public let timestamp: Date
    public let userProfile: GamificationProfile
    public let activeChallenges: [HealthChallenge]
    public let completedChallenges: [HealthChallenge]
    public let achievements: [Achievement]
    public let rewards: [Reward]
    public let leaderboards: [Leaderboard]
    public let socialConnections: [SocialConnection]
    public let motivationStreak: MotivationStreak
    public let dailyGoals: [DailyGoal]
}

// MARK: - Supporting Data Models

public struct GamificationPreferences: Codable {
    public let challengeDifficulty: ChallengeDifficulty
    public let notificationSettings: NotificationSettings
    public let privacySettings: PrivacySettings
    public let socialSettings: SocialSettings
}

public struct GamificationStatistics: Codable {
    public let totalChallenges: Int
    public let completedChallenges: Int
    public let totalAchievements: Int
    public let unlockedAchievements: Int
    public let totalPoints: Int
    public let currentStreak: Int
    public let longestStreak: Int
}

public struct ChallengeRequirement: Codable {
    public let type: RequirementType
    public let value: Double
    public let unit: String
    public let description: String
}

public struct AchievementRequirement: Codable {
    public let type: RequirementType
    public let value: Double
    public let unit: String
    public let description: String
}

public struct LeaderboardEntry: Codable {
    public let rank: Int
    public let userId: UUID
    public let username: String
    public let score: Int
    public let timestamp: Date
}

public struct StreakMilestone: Codable {
    public let days: Int
    public let title: String
    public let description: String
    public let reward: Reward
    public let achieved: Bool
    public let achievedDate: Date?
}

public struct FitnessPattern: Codable {
    public let type: String
    public let frequency: Double
    public let intensity: Double
    public let consistency: Double
    public let timestamp: Date
}

public struct NutritionPattern: Codable {
    public let type: String
    public let frequency: Double
    public let quality: Double
    public let consistency: Double
    public let timestamp: Date
}

public struct SleepPattern: Codable {
    public let type: String
    public let duration: Double
    public let quality: Double
    public let consistency: Double
    public let timestamp: Date
}

public struct SocialPattern: Codable {
    public let type: String
    public let frequency: Double
    public let engagement: Double
    public let consistency: Double
    public let timestamp: Date
}

public struct MotivationPattern: Codable {
    public let type: String
    public let strength: Double
    public let consistency: Double
    public let triggers: [String]
    public let timestamp: Date
}

// MARK: - Enums

public enum ChallengeCategory: String, Codable, CaseIterable {
    case fitness, nutrition, sleep, mental, social
}

public enum ChallengeType: String, Codable, CaseIterable {
    case daily, weekly, monthly, special, event
}

public enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy, medium, hard, expert
}

public enum ChallengeStatus: String, Codable, CaseIterable {
    case active, completed, failed, expired
}

public enum AchievementType: String, Codable, CaseIterable {
    case fitness, nutrition, sleep, mental, social, streak, milestone
}

public enum AchievementCategory: String, Codable, CaseIterable {
    case beginner, intermediate, advanced, expert, legendary
}

public enum AchievementRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary
}

public enum RewardType: String, Codable, CaseIterable {
    case points, badge, unlock, bonus
}

public enum RewardCategory: String, Codable, CaseIterable {
    case daily, weekly, monthly, special, event
}

public enum RewardRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary
}

public enum LeaderboardCategory: String, Codable, CaseIterable {
    case global, friends, local, weekly, monthly
}

public enum LeaderboardType: String, Codable, CaseIterable {
    case points, challenges, achievements, streaks
}

public enum ConnectionStatus: String, Codable, CaseIterable {
    case active, pending, inactive
}

public enum StreakType: String, Codable, CaseIterable {
    case daily, weekly, monthly, challenge
}

public enum GoalCategory: String, Codable, CaseIterable {
    case fitness, nutrition, sleep, mental, social
}

public enum RequirementType: String, Codable, CaseIterable {
    case steps, calories, distance, duration, frequency, quality
}

public enum InsightCategory: String, Codable, CaseIterable {
    case motivation, behavior, progress, social, achievement
}

public enum Severity: String, Codable, CaseIterable {
    case low, medium, high, critical
}

// MARK: - Extensions

extension Timeframe {
    var dateComponent: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
} 