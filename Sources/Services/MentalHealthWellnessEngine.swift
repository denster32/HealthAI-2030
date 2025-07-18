import Foundation
import SwiftUI
import Combine
import CoreML
import HealthKit

/// Advanced Mental Health & Wellness Engine
/// Provides comprehensive mental health monitoring, AI-powered interventions,
/// wellness optimization, and crisis intervention features
@MainActor
final class MentalHealthWellnessEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var mentalHealthData: MentalHealthData = MentalHealthData()
    @Published var moodHistory: [MoodEntry] = []
    @Published var stressLevels: [StressLevel] = []
    @Published var wellnessScore: Double = 0.0
    @Published var aiInterventions: [WellnessIntervention] = []
    @Published var crisisAlerts: [CrisisAlert] = []
    @Published var wellnessRecommendations: [WellnessRecommendation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let healthDataManager: HealthDataManager
    private let mlModelManager: MLModelManager
    private let notificationManager: NotificationManager
    private let crisisInterventionManager: CrisisInterventionManager
    
    // MARK: - Initialization
    
    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, notificationManager: NotificationManager, crisisInterventionManager: CrisisInterventionManager) {
        self.healthDataManager = healthDataManager
        self.mlModelManager = mlModelManager
        self.notificationManager = notificationManager
        self.crisisInterventionManager = crisisInterventionManager
        
        setupSubscriptions()
        loadMentalHealthData()
    }
    
    // MARK: - Setup
    
    /// Setup data subscriptions
    private func setupSubscriptions() {
        // Monitor health data changes for mental health correlations
        healthDataManager.healthDataPublisher
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMentalHealthCorrelations()
            }
            .store(in: &cancellables)
        
        // Monitor sleep data for mental health impact
        healthDataManager.sleepDataPublisher
            .sink { [weak self] _ in
                self?.analyzeSleepMentalHealthImpact()
            }
            .store(in: &cancellables)
        
        // Monitor activity data for stress correlation
        healthDataManager.activityDataPublisher
            .sink { [weak self] _ in
                self?.analyzeActivityStressCorrelation()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mental Health Monitoring
    
    /// Load mental health data from persistent storage
    private func loadMentalHealthData() {
        Task {
            do {
                let data = try await MentalHealthPersistenceManager.shared.loadMentalHealthData()
                await MainActor.run {
                    self.mentalHealthData = data
                    self.moodHistory = data.moodHistory
                    self.stressLevels = data.stressLevels
                    self.updateWellnessScore()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load mental health data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Record mood entry
    func recordMoodEntry(_ entry: MoodEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Add to mood history
            await MainActor.run {
                moodHistory.append(entry)
                mentalHealthData.moodHistory = moodHistory
            }
            
            // Save to persistent storage
            try await MentalHealthPersistenceManager.shared.saveMoodEntry(entry)
            
            // Analyze mood patterns
            await analyzeMoodPatterns()
            
            // Generate wellness recommendations
            await generateWellnessRecommendations()
            
            // Check for crisis indicators
            await checkCrisisIndicators()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to record mood entry: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Record stress level
    func recordStressLevel(_ stressLevel: StressLevel) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Add to stress levels
            await MainActor.run {
                stressLevels.append(stressLevel)
                mentalHealthData.stressLevels = stressLevels
            }
            
            // Save to persistent storage
            try await MentalHealthPersistenceManager.shared.saveStressLevel(stressLevel)
            
            // Analyze stress patterns
            await analyzeStressPatterns()
            
            // Generate stress management interventions
            await generateStressInterventions()
            
            // Check for crisis indicators
            await checkCrisisIndicators()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to record stress level: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Update mental health correlations with physical health data
    private func updateMentalHealthCorrelations() async {
        do {
            let healthData = await healthDataManager.getHealthData(for: .week)
            let correlations = try await mlModelManager.analyzeMentalHealthCorrelations(
                mentalHealthData: mentalHealthData,
                healthData: healthData
            )
            
            await MainActor.run {
                mentalHealthData.healthCorrelations = correlations
            }
            
            // Update wellness score based on correlations
            await updateWellnessScore()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update mental health correlations: \(error.localizedDescription)"
            }
        }
    }
    
    /// Analyze sleep impact on mental health
    private func analyzeSleepMentalHealthImpact() async {
        do {
            let sleepData = await healthDataManager.getSleepData(for: .week)
            let impact = try await mlModelManager.analyzeSleepMentalHealthImpact(
                sleepData: sleepData,
                mentalHealthData: mentalHealthData
            )
            
            await MainActor.run {
                mentalHealthData.sleepImpact = impact
            }
            
            // Generate sleep-related wellness recommendations
            await generateSleepWellnessRecommendations()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to analyze sleep impact: \(error.localizedDescription)"
            }
        }
    }
    
    /// Analyze activity stress correlation
    private func analyzeActivityStressCorrelation() async {
        do {
            let activityData = await healthDataManager.getActivityData(for: .week)
            let correlation = try await mlModelManager.analyzeActivityStressCorrelation(
                activityData: activityData,
                stressLevels: stressLevels
            )
            
            await MainActor.run {
                mentalHealthData.activityStressCorrelation = correlation
            }
            
            // Generate activity-based stress management recommendations
            await generateActivityStressRecommendations()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to analyze activity stress correlation: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - AI-Powered Interventions
    
    /// Generate AI-powered wellness interventions
    private func generateWellnessRecommendations() async {
        do {
            let recommendations = try await mlModelManager.generateWellnessRecommendations(
                mentalHealthData: mentalHealthData,
                moodHistory: moodHistory,
                stressLevels: stressLevels
            )
            
            await MainActor.run {
                self.wellnessRecommendations = recommendations
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate wellness recommendations: \(error.localizedDescription)"
            }
        }
    }
    
    /// Generate stress management interventions
    private func generateStressInterventions() async {
        do {
            let interventions = try await mlModelManager.generateStressInterventions(
                stressLevels: stressLevels,
                mentalHealthData: mentalHealthData
            )
            
            await MainActor.run {
                self.aiInterventions = interventions
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate stress interventions: \(error.localizedDescription)"
            }
        }
    }
    
    /// Generate sleep wellness recommendations
    private func generateSleepWellnessRecommendations() async {
        do {
            let recommendations = try await mlModelManager.generateSleepWellnessRecommendations(
                sleepData: await healthDataManager.getSleepData(for: .week),
                mentalHealthData: mentalHealthData
            )
            
            await MainActor.run {
                // Merge with existing recommendations
                self.wellnessRecommendations.append(contentsOf: recommendations)
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate sleep recommendations: \(error.localizedDescription)"
            }
        }
    }
    
    /// Generate activity-based stress recommendations
    private func generateActivityStressRecommendations() async {
        do {
            let recommendations = try await mlModelManager.generateActivityStressRecommendations(
                activityData: await healthDataManager.getActivityData(for: .week),
                stressLevels: stressLevels
            )
            
            await MainActor.run {
                // Merge with existing recommendations
                self.wellnessRecommendations.append(contentsOf: recommendations)
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate activity recommendations: \(error.localizedDescription)"
            }
        }
    }
    
    /// Apply wellness intervention
    func applyIntervention(_ intervention: WellnessIntervention) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Apply the intervention
            try await applyWellnessIntervention(intervention)
            
            // Track intervention usage
            await trackInterventionUsage(intervention)
            
            // Schedule follow-up assessment
            await scheduleFollowUpAssessment(for: intervention)
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to apply intervention: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Wellness Optimization
    
    /// Update wellness score based on current data
    private func updateWellnessScore() async {
        let score = calculateWellnessScore()
        
        await MainActor.run {
            self.wellnessScore = score
        }
        
        // Generate wellness insights
        await generateWellnessInsights()
    }
    
    /// Calculate comprehensive wellness score
    private func calculateWellnessScore() -> Double {
        var score = 0.0
        var factors = 0
        
        // Mood factor (30% weight)
        if let averageMood = calculateAverageMood() {
            score += averageMood * 0.3
            factors += 1
        }
        
        // Stress factor (25% weight)
        if let averageStress = calculateAverageStress() {
            score += (1.0 - averageStress) * 0.25 // Invert stress (lower is better)
            factors += 1
        }
        
        // Sleep quality factor (20% weight)
        if let sleepQuality = mentalHealthData.sleepImpact?.qualityScore {
            score += sleepQuality * 0.2
            factors += 1
        }
        
        // Activity factor (15% weight)
        if let activityScore = mentalHealthData.activityStressCorrelation?.activityScore {
            score += activityScore * 0.15
            factors += 1
        }
        
        // Social connection factor (10% weight)
        if let socialScore = mentalHealthData.socialConnectionScore {
            score += socialScore * 0.1
            factors += 1
        }
        
        return factors > 0 ? score : 0.0
    }
    
    /// Calculate average mood from recent entries
    private func calculateAverageMood() -> Double? {
        let recentMoods = moodHistory.suffix(7) // Last 7 days
        guard !recentMoods.isEmpty else { return nil }
        
        let totalMood = recentMoods.reduce(0.0) { $0 + $1.moodScore }
        return totalMood / Double(recentMoods.count)
    }
    
    /// Calculate average stress from recent entries
    private func calculateAverageStress() -> Double? {
        let recentStress = stressLevels.suffix(7) // Last 7 days
        guard !recentStress.isEmpty else { return nil }
        
        let totalStress = recentStress.reduce(0.0) { $0 + $1.stressLevel }
        return totalStress / Double(recentStress.count)
    }
    
    /// Generate wellness insights
    private func generateWellnessInsights() async {
        do {
            let insights = try await mlModelManager.generateWellnessInsights(
                wellnessScore: wellnessScore,
                mentalHealthData: mentalHealthData
            )
            
            await MainActor.run {
                mentalHealthData.wellnessInsights = insights
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate wellness insights: \(error.localizedDescription)"
            }
        }
    }
    
    /// Analyze mood patterns
    private func analyzeMoodPatterns() async {
        do {
            let patterns = try await mlModelManager.analyzeMoodPatterns(moodHistory: moodHistory)
            
            await MainActor.run {
                mentalHealthData.moodPatterns = patterns
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to analyze mood patterns: \(error.localizedDescription)"
            }
        }
    }
    
    /// Analyze stress patterns
    private func analyzeStressPatterns() async {
        do {
            let patterns = try await mlModelManager.analyzeStressPatterns(stressLevels: stressLevels)
            
            await MainActor.run {
                mentalHealthData.stressPatterns = patterns
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to analyze stress patterns: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Crisis Intervention
    
    /// Check for crisis indicators
    private func checkCrisisIndicators() async {
        do {
            let indicators = try await crisisInterventionManager.checkCrisisIndicators(
                mentalHealthData: mentalHealthData,
                moodHistory: moodHistory,
                stressLevels: stressLevels
            )
            
            await MainActor.run {
                // Update crisis alerts
                self.crisisAlerts = indicators.map { indicator in
                    CrisisAlert(
                        id: UUID().uuidString,
                        type: indicator.type,
                        severity: indicator.severity,
                        message: indicator.message,
                        timestamp: Date(),
                        isActive: true
                    )
                }
            }
            
            // Handle critical crisis indicators
            for indicator in indicators where indicator.severity == .critical {
                await handleCriticalCrisis(indicator)
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to check crisis indicators: \(error.localizedDescription)"
            }
        }
    }
    
    /// Handle critical crisis situation
    private func handleCriticalCrisis(_ indicator: CrisisIndicator) async {
        // Immediate crisis intervention
        await crisisInterventionManager.activateCrisisProtocol(for: indicator)
        
        // Send emergency notifications
        await sendEmergencyNotifications(for: indicator)
        
        // Contact emergency services if needed
        if indicator.requiresEmergencyContact {
            await contactEmergencyServices(for: indicator)
        }
    }
    
    /// Send emergency notifications
    private func sendEmergencyNotifications(for indicator: CrisisIndicator) async {
        let notification = EmergencyNotification(
            title: "Mental Health Alert",
            body: indicator.message,
            category: .crisisAlert,
            userInfo: ["crisisType": indicator.type.rawValue, "severity": indicator.severity.rawValue]
        )
        
        await notificationManager.sendEmergencyNotification(notification)
    }
    
    /// Contact emergency services
    private func contactEmergencyServices(for indicator: CrisisIndicator) async {
        // Implementation for contacting emergency services
        // This would integrate with local emergency services APIs
    }
    
    // MARK: - Intervention Application
    
    /// Apply wellness intervention
    private func applyWellnessIntervention(_ intervention: WellnessIntervention) async throws {
        switch intervention.type {
        case .meditation:
            try await applyMeditationIntervention(intervention)
        case .breathing:
            try await applyBreathingIntervention(intervention)
        case .cbt:
            try await applyCBTIntervention(intervention)
        case .mindfulness:
            try await applyMindfulnessIntervention(intervention)
        case .social:
            try await applySocialIntervention(intervention)
        case .activity:
            try await applyActivityIntervention(intervention)
        }
    }
    
    /// Apply meditation intervention
    private func applyMeditationIntervention(_ intervention: WellnessIntervention) async throws {
        // Start guided meditation session
        try await MeditationManager.shared.startSession(
            duration: intervention.duration,
            type: intervention.meditationType ?? .mindfulness
        )
    }
    
    /// Apply breathing intervention
    private func applyBreathingIntervention(_ intervention: WellnessIntervention) async throws {
        // Start breathing exercise
        try await BreathingManager.shared.startExercise(
            pattern: intervention.breathingPattern ?? .boxBreathing,
            duration: intervention.duration
        )
    }
    
    /// Apply CBT intervention
    private func applyCBTIntervention(_ intervention: WellnessIntervention) async throws {
        // Start CBT session
        try await CBTManager.shared.startSession(
            technique: intervention.cbtTechnique ?? .thoughtReframing,
            duration: intervention.duration
        )
    }
    
    /// Apply mindfulness intervention
    private func applyMindfulnessIntervention(_ intervention: WellnessIntervention) async throws {
        // Start mindfulness practice
        try await MindfulnessManager.shared.startPractice(
            type: intervention.mindfulnessType ?? .bodyScan,
            duration: intervention.duration
        )
    }
    
    /// Apply social intervention
    private func applySocialIntervention(_ intervention: WellnessIntervention) async throws {
        // Connect with support network
        try await SocialSupportManager.shared.connectWithSupport(
            type: intervention.socialType ?? .friend,
            duration: intervention.duration
        )
    }
    
    /// Apply activity intervention
    private func applyActivityIntervention(_ intervention: WellnessIntervention) async throws {
        // Start physical activity
        try await ActivityManager.shared.startActivity(
            type: intervention.activityType ?? .walking,
            duration: intervention.duration,
            intensity: intervention.intensity ?? .moderate
        )
    }
    
    // MARK: - Tracking and Assessment
    
    /// Track intervention usage
    private func trackInterventionUsage(_ intervention: WellnessIntervention) async {
        let usage = InterventionUsage(
            interventionId: intervention.id,
            appliedAt: Date(),
            duration: intervention.duration,
            effectiveness: nil // Will be assessed later
        )
        
        try? await MentalHealthPersistenceManager.shared.saveInterventionUsage(usage)
    }
    
    /// Schedule follow-up assessment
    private func scheduleFollowUpAssessment(for intervention: WellnessIntervention) async {
        let assessment = FollowUpAssessment(
            interventionId: intervention.id,
            scheduledAt: Date().addingTimeInterval(intervention.duration + 3600), // 1 hour after intervention
            type: .effectiveness,
            isCompleted: false
        )
        
        try? await MentalHealthPersistenceManager.shared.saveFollowUpAssessment(assessment)
    }
}

// MARK: - Supporting Types

/// Mental health data structure
struct MentalHealthData: Codable {
    var moodHistory: [MoodEntry] = []
    var stressLevels: [StressLevel] = []
    var healthCorrelations: HealthCorrelations?
    var sleepImpact: SleepMentalHealthImpact?
    var activityStressCorrelation: ActivityStressCorrelation?
    var moodPatterns: MoodPatterns?
    var stressPatterns: StressPatterns?
    var wellnessInsights: WellnessInsights?
    var socialConnectionScore: Double?
    var lastUpdated: Date = Date()
}

/// Mood entry
struct MoodEntry: Identifiable, Codable {
    let id: String
    let moodScore: Double // 0.0 to 1.0
    let moodType: MoodType
    let notes: String?
    let timestamp: Date
    let factors: [MoodFactor]
}

/// Mood types
enum MoodType: String, CaseIterable, Codable {
    case veryHappy = "very_happy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case verySad = "very_sad"
    case anxious = "anxious"
    case stressed = "stressed"
    case angry = "angry"
    case excited = "excited"
    case calm = "calm"
    
    var displayName: String {
        switch self {
        case .veryHappy: return "Very Happy"
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .verySad: return "Very Sad"
        case .anxious: return "Anxious"
        case .stressed: return "Stressed"
        case .angry: return "Angry"
        case .excited: return "Excited"
        case .calm: return "Calm"
        }
    }
}

/// Mood factors
enum MoodFactor: String, CaseIterable, Codable {
    case sleep = "sleep"
    case exercise = "exercise"
    case social = "social"
    case work = "work"
    case health = "health"
    case weather = "weather"
    case food = "food"
    case stress = "stress"
    case medication = "medication"
    case other = "other"
}

/// Stress level entry
struct StressLevel: Identifiable, Codable {
    let id: String
    let stressLevel: Double // 0.0 to 1.0
    let stressType: StressType
    let notes: String?
    let timestamp: Date
    let triggers: [StressTrigger]
}

/// Stress types
enum StressType: String, CaseIterable, Codable {
    case work = "work"
    case personal = "personal"
    case health = "health"
    case financial = "financial"
    case social = "social"
    case environmental = "environmental"
    case physical = "physical"
    case emotional = "emotional"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .personal: return "Personal"
        case .health: return "Health"
        case .financial: return "Financial"
        case .social: return "Social"
        case .environmental: return "Environmental"
        case .physical: return "Physical"
        case .emotional: return "Emotional"
        }
    }
}

/// Stress triggers
enum StressTrigger: String, CaseIterable, Codable {
    case deadline = "deadline"
    case conflict = "conflict"
    case uncertainty = "uncertainty"
    case overload = "overload"
    case change = "change"
    case noise = "noise"
    case crowds = "crowds"
    case illness = "illness"
    case pain = "pain"
    case other = "other"
}

/// Health correlations
struct HealthCorrelations: Codable {
    let moodHeartRateCorrelation: Double
    let stressSleepCorrelation: Double
    let activityMoodCorrelation: Double
    let overallCorrelation: Double
}

/// Sleep mental health impact
struct SleepMentalHealthImpact: Codable {
    let qualityScore: Double
    let moodImpact: Double
    let stressImpact: Double
    let cognitiveImpact: Double
    let recommendations: [String]
}

/// Activity stress correlation
struct ActivityStressCorrelation: Codable {
    let activityScore: Double
    let stressReduction: Double
    let optimalActivityLevel: Double
    let recommendations: [String]
}

/// Mood patterns
struct MoodPatterns: Codable {
    let dailyPattern: [Double]
    let weeklyPattern: [Double]
    let seasonalPattern: [Double]
    let triggers: [String: Double]
}

/// Stress patterns
struct StressPatterns: Codable {
    let dailyPattern: [Double]
    let weeklyPattern: [Double]
    let triggers: [String: Double]
    let copingStrategies: [String: Double]
}

/// Wellness insights
struct WellnessInsights: Codable {
    let trends: [String]
    let recommendations: [String]
    let riskFactors: [String]
    let protectiveFactors: [String]
}

/// Wellness intervention
struct WellnessIntervention: Identifiable, Codable {
    let id: String
    let type: InterventionType
    let title: String
    let description: String
    let duration: TimeInterval
    let confidence: Double
    let meditationType: MeditationType?
    let breathingPattern: BreathingPattern?
    let cbtTechnique: CBTTechnique?
    let mindfulnessType: MindfulnessType?
    let socialType: SocialType?
    let activityType: ActivityType?
    let intensity: ActivityIntensity?
}

/// Intervention types
enum InterventionType: String, CaseIterable, Codable {
    case meditation = "meditation"
    case breathing = "breathing"
    case cbt = "cbt"
    case mindfulness = "mindfulness"
    case social = "social"
    case activity = "activity"
}

/// Meditation types
enum MeditationType: String, CaseIterable, Codable {
    case mindfulness = "mindfulness"
    case lovingKindness = "loving_kindness"
    case bodyScan = "body_scan"
    case transcendental = "transcendental"
    case zen = "zen"
    case vipassana = "vipassana"
}

/// Breathing patterns
enum BreathingPattern: String, CaseIterable, Codable {
    case boxBreathing = "box_breathing"
    case fourSevenEight = "four_seven_eight"
    case diaphragmatic = "diaphragmatic"
    case alternateNostril = "alternate_nostril"
    case coherent = "coherent"
}

/// CBT techniques
enum CBTTechnique: String, CaseIterable, Codable {
    case thoughtReframing = "thought_reframing"
    case cognitiveRestructuring = "cognitive_restructuring"
    case behavioralActivation = "behavioral_activation"
    case exposure = "exposure"
    case problemSolving = "problem_solving"
}

/// Mindfulness types
enum MindfulnessType: String, CaseIterable, Codable {
    case bodyScan = "body_scan"
    case breathAwareness = "breath_awareness"
    case walking = "walking"
    case eating = "eating"
    case lovingKindness = "loving_kindness"
}

/// Social types
enum SocialType: String, CaseIterable, Codable {
    case friend = "friend"
    case family = "family"
    case supportGroup = "support_group"
    case therapist = "therapist"
    case community = "community"
}

/// Activity types
enum ActivityType: String, CaseIterable, Codable {
    case walking = "walking"
    case running = "running"
    case yoga = "yoga"
    case swimming = "swimming"
    case cycling = "cycling"
    case dancing = "dancing"
}

/// Activity intensity
enum ActivityIntensity: String, CaseIterable, Codable {
    case light = "light"
    case moderate = "moderate"
    case vigorous = "vigorous"
}

/// Wellness recommendation
struct WellnessRecommendation: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let confidence: Double
    let estimatedImpact: Double
}

/// Recommendation categories
enum RecommendationCategory: String, CaseIterable, Codable {
    case sleep = "sleep"
    case exercise = "exercise"
    case nutrition = "nutrition"
    case social = "social"
    case stress = "stress"
    case mindfulness = "mindfulness"
    case therapy = "therapy"
    case lifestyle = "lifestyle"
}

/// Recommendation priorities
enum RecommendationPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Crisis alert
struct CrisisAlert: Identifiable, Codable {
    let id: String
    let type: CrisisType
    let severity: CrisisSeverity
    let message: String
    let timestamp: Date
    var isActive: Bool
}

/// Crisis types
enum CrisisType: String, CaseIterable, Codable {
    case suicidalThoughts = "suicidal_thoughts"
    case severeDepression = "severe_depression"
    case panicAttack = "panic_attack"
    case severeAnxiety = "severe_anxiety"
    case selfHarm = "self_harm"
    case substanceAbuse = "substance_abuse"
    case psychosis = "psychosis"
    case mania = "mania"
}

/// Crisis severity
enum CrisisSeverity: String, CaseIterable, Codable {
    case mild = "mild"
    case moderate = "moderate"
    case severe = "severe"
    case critical = "critical"
}

/// Crisis indicator
struct CrisisIndicator: Codable {
    let type: CrisisType
    let severity: CrisisSeverity
    let message: String
    let requiresEmergencyContact: Bool
}

/// Intervention usage
struct InterventionUsage: Codable {
    let interventionId: String
    let appliedAt: Date
    let duration: TimeInterval
    let effectiveness: Double?
}

/// Follow-up assessment
struct FollowUpAssessment: Codable {
    let interventionId: String
    let scheduledAt: Date
    let type: AssessmentType
    var isCompleted: Bool
}

/// Assessment types
enum AssessmentType: String, CaseIterable, Codable {
    case effectiveness = "effectiveness"
    case satisfaction = "satisfaction"
    case adherence = "adherence"
    case sideEffects = "side_effects"
}

/// Emergency notification
struct EmergencyNotification: Codable {
    let title: String
    let body: String
    let category: NotificationCategory
    let userInfo: [String: Any]
}

/// Notification categories
enum NotificationCategory: String, CaseIterable, Codable {
    case crisisAlert = "crisis_alert"
    case wellnessReminder = "wellness_reminder"
    case interventionComplete = "intervention_complete"
    case assessmentDue = "assessment_due"
}

// MARK: - Manager Extensions

extension MLModelManager {
    func analyzeMentalHealthCorrelations(mentalHealthData: MentalHealthData, healthData: HealthData) async throws -> HealthCorrelations {
        // Implementation for analyzing mental health correlations
        return HealthCorrelations(
            moodHeartRateCorrelation: 0.0,
            stressSleepCorrelation: 0.0,
            activityMoodCorrelation: 0.0,
            overallCorrelation: 0.0
        )
    }
    
    func analyzeSleepMentalHealthImpact(sleepData: SleepData, mentalHealthData: MentalHealthData) async throws -> SleepMentalHealthImpact {
        // Implementation for analyzing sleep impact
        return SleepMentalHealthImpact(
            qualityScore: 0.0,
            moodImpact: 0.0,
            stressImpact: 0.0,
            cognitiveImpact: 0.0,
            recommendations: []
        )
    }
    
    func analyzeActivityStressCorrelation(activityData: ActivityData, stressLevels: [StressLevel]) async throws -> ActivityStressCorrelation {
        // Implementation for analyzing activity stress correlation
        return ActivityStressCorrelation(
            activityScore: 0.0,
            stressReduction: 0.0,
            optimalActivityLevel: 0.0,
            recommendations: []
        )
    }
    
    func generateWellnessRecommendations(mentalHealthData: MentalHealthData, moodHistory: [MoodEntry], stressLevels: [StressLevel]) async throws -> [WellnessRecommendation] {
        // Implementation for generating wellness recommendations
        return []
    }
    
    func generateStressInterventions(stressLevels: [StressLevel], mentalHealthData: MentalHealthData) async throws -> [WellnessIntervention] {
        // Implementation for generating stress interventions
        return []
    }
    
    func generateSleepWellnessRecommendations(sleepData: SleepData, mentalHealthData: MentalHealthData) async throws -> [WellnessRecommendation] {
        // Implementation for generating sleep recommendations
        return []
    }
    
    func generateActivityStressRecommendations(activityData: ActivityData, stressLevels: [StressLevel]) async throws -> [WellnessRecommendation] {
        // Implementation for generating activity recommendations
        return []
    }
    
    func generateWellnessInsights(wellnessScore: Double, mentalHealthData: MentalHealthData) async throws -> WellnessInsights {
        // Implementation for generating wellness insights
        return WellnessInsights(trends: [], recommendations: [], riskFactors: [], protectiveFactors: [])
    }
    
    func analyzeMoodPatterns(moodHistory: [MoodEntry]) async throws -> MoodPatterns {
        // Implementation for analyzing mood patterns
        return MoodPatterns(dailyPattern: [], weeklyPattern: [], seasonalPattern: [], triggers: [:])
    }
    
    func analyzeStressPatterns(stressLevels: [StressLevel]) async throws -> StressPatterns {
        // Implementation for analyzing stress patterns
        return StressPatterns(dailyPattern: [], weeklyPattern: [], triggers: [:], copingStrategies: [:])
    }
}

extension CrisisInterventionManager {
    func checkCrisisIndicators(mentalHealthData: MentalHealthData, moodHistory: [MoodEntry], stressLevels: [StressLevel]) async throws -> [CrisisIndicator] {
        // Implementation for checking crisis indicators
        return []
    }
    
    func activateCrisisProtocol(for indicator: CrisisIndicator) async {
        // Implementation for activating crisis protocol
    }
}

extension MentalHealthPersistenceManager {
    static let shared = MentalHealthPersistenceManager()
    
    func loadMentalHealthData() async throws -> MentalHealthData {
        // Implementation for loading mental health data
        return MentalHealthData()
    }
    
    func saveMoodEntry(_ entry: MoodEntry) async throws {
        // Implementation for saving mood entry
    }
    
    func saveStressLevel(_ stressLevel: StressLevel) async throws {
        // Implementation for saving stress level
    }
    
    func saveInterventionUsage(_ usage: InterventionUsage) async throws {
        // Implementation for saving intervention usage
    }
    
    func saveFollowUpAssessment(_ assessment: FollowUpAssessment) async throws {
        // Implementation for saving follow-up assessment
    }
}

// MARK: - Manager Classes

class MeditationManager {
    static let shared = MeditationManager()
    
    func startSession(duration: TimeInterval, type: MeditationType) async throws {
        // Implementation for starting meditation session
    }
}

class BreathingManager {
    static let shared = BreathingManager()
    
    func startExercise(pattern: BreathingPattern, duration: TimeInterval) async throws {
        // Implementation for starting breathing exercise
    }
}

class CBTManager {
    static let shared = CBTManager()
    
    func startSession(technique: CBTTechnique, duration: TimeInterval) async throws {
        // Implementation for starting CBT session
    }
}

class MindfulnessManager {
    static let shared = MindfulnessManager()
    
    func startPractice(type: MindfulnessType, duration: TimeInterval) async throws {
        // Implementation for starting mindfulness practice
    }
}

class SocialSupportManager {
    static let shared = SocialSupportManager()
    
    func connectWithSupport(type: SocialType, duration: TimeInterval) async throws {
        // Implementation for connecting with support
    }
}

class ActivityManager {
    static let shared = ActivityManager()
    
    func startActivity(type: ActivityType, duration: TimeInterval, intensity: ActivityIntensity) async throws {
        // Implementation for starting activity
    }
}

class NotificationManager {
    func sendEmergencyNotification(_ notification: EmergencyNotification) async {
        // Implementation for sending emergency notification
    }
}

// MARK: - Supporting Data Types

struct HealthData {
    let steps: Int
    let sleepHours: Double
    let heartRate: Int
    let weight: Double
    let exerciseMinutes: Int
    let timestamp: Date
}

struct SleepData {
    let averageSleepHours: Double
    let sleepQuality: Double
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let sleepEfficiency: Double
}

struct ActivityData {
    let averageSteps: Double
    let exerciseMinutes: Double
    let activeCalories: Double
    let totalCalories: Double
}

extension HealthDataManager {
    var sleepDataPublisher: AnyPublisher<SleepData, Never> {
        Just(SleepData(averageSleepHours: 0, sleepQuality: 0, deepSleepPercentage: 0, remSleepPercentage: 0, sleepEfficiency: 0)).eraseToAnyPublisher()
    }
    
    var activityDataPublisher: AnyPublisher<ActivityData, Never> {
        Just(ActivityData(averageSteps: 0, exerciseMinutes: 0, activeCalories: 0, totalCalories: 0)).eraseToAnyPublisher()
    }
    
    func getSleepData(for period: HealthDataPeriod) async -> SleepData {
        return SleepData(averageSleepHours: 0, sleepQuality: 0, deepSleepPercentage: 0, remSleepPercentage: 0, sleepEfficiency: 0)
    }
    
    func getActivityData(for period: HealthDataPeriod) async -> ActivityData {
        return ActivityData(averageSteps: 0, exerciseMinutes: 0, activeCalories: 0, totalCalories: 0)
    }
}

enum HealthDataPeriod {
    case day, week, month, year
} 