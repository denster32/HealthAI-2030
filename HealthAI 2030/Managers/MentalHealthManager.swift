import Foundation
import HealthKit
import CoreML
import Combine
import SwiftUI

/// Mental Health Manager for iOS 18+ mental health features
/// Integrates mindfulness, mental state tracking, and mood analysis
@MainActor
class MentalHealthManager: ObservableObject {
    static let shared = MentalHealthManager()
    
    // MARK: - Published Properties
    @Published var mindfulnessSessions: [MindfulSession] = []
    @Published var mentalStateRecords: [MentalStateRecord] = []
    @Published var moodChanges: [MoodChange] = []
    @Published var currentMentalState: MentalState = .neutral
    @Published var mentalHealthScore: Double = 0.0
    @Published var stressLevel: StressLevel = .low
    @Published var anxietyLevel: AnxietyLevel = .low
    @Published var depressionRisk: DepressionRisk = .low
    
    // MARK: - Mental Health Insights
    @Published var mentalHealthInsights: [MentalHealthInsight] = []
    @Published var mindfulnessRecommendations: [MindfulnessRecommendation] = []
    @Published var moodTrends: [MoodTrend] = []
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    private let mentalHealthAnalyzer = MentalHealthAnalyzer()
    private let moodAnalyzer = MoodAnalyzer()
    private let stressAnalyzer = StressAnalyzer()
    
    // MARK: - Configuration
    private let mindfulnessGoal: TimeInterval = 10 * 60 // 10 minutes daily
    private let mentalStateUpdateInterval: TimeInterval = 300 // 5 minutes
    private let moodCheckInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - iOS 18+ HealthKit Types
    private let mentalHealthTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
        HKObjectType.categoryType(forIdentifier: .mindfulMinutes)!,
        HKObjectType.categoryType(forIdentifier: .mentalState)!,
        HKObjectType.categoryType(forIdentifier: .moodChanges)!
    ]
    
    private init() {
        setupMentalHealthManager()
        startMentalHealthMonitoring()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupMentalHealthManager() {
        requestMentalHealthPermissions()
        setupMentalHealthObservers()
        setupMentalHealthAnalysis()
    }
    
    private func requestMentalHealthPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available for mental health tracking")
            return
        }
        
        let typesToRead: Set<HKObjectType> = mentalHealthTypes
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.categoryType(forIdentifier: .mentalState)!,
            HKObjectType.categoryType(forIdentifier: .moodChanges)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    print("Mental health permissions granted")
                    self?.startMentalHealthDataCollection()
                } else {
                    print("Mental health permissions denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func setupMentalHealthObservers() {
        // Setup observers for mental health data changes
        setupMindfulnessObserver()
        setupMentalStateObserver()
        setupMoodObserver()
    }
    
    private func setupMentalHealthAnalysis() {
        // Initialize mental health analysis components
        mentalHealthAnalyzer.delegate = self
        moodAnalyzer.delegate = self
        stressAnalyzer.delegate = self
    }
    
    // MARK: - Mental Health Data Collection
    
    private func startMentalHealthDataCollection() {
        fetchMindfulnessSessions()
        fetchMentalStateRecords()
        fetchMoodChanges()
        
        // Start periodic mental health analysis
        startPeriodicAnalysis()
    }
    
    private func setupMindfulnessObserver() {
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let query = HKObserverQuery(sampleType: mindfulSessionType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchMindfulnessSessions()
            completion()
        }
        
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: mindfulSessionType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for mindfulness: \(error)")
            }
        }
    }
    
    private func setupMentalStateObserver() {
        guard let mentalStateType = HKObjectType.categoryType(forIdentifier: .mentalState) else { return }
        
        let query = HKObserverQuery(sampleType: mentalStateType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchMentalStateRecords()
            completion()
        }
        
        healthStore.execute(query)
    }
    
    private func setupMoodObserver() {
        guard let moodChangesType = HKObjectType.categoryType(forIdentifier: .moodChanges) else { return }
        
        let query = HKObserverQuery(sampleType: moodChangesType, predicate: nil) { [weak self] query, completion, error in
            self?.fetchMoodChanges()
            completion()
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Data Fetching
    
    private func fetchMindfulnessSessions() {
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: mindfulSessionType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKCategorySample] {
                    self?.mindfulnessSessions = samples.compactMap { MindfulSession(from: $0) }
                    self?.analyzeMindfulnessTrends()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchMentalStateRecords() {
        guard let mentalStateType = HKObjectType.categoryType(forIdentifier: .mentalState) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: mentalStateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKCategorySample] {
                    self?.mentalStateRecords = samples.compactMap { MentalStateRecord(from: $0) }
                    self?.analyzeMentalStateTrends()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchMoodChanges() {
        guard let moodChangesType = HKObjectType.categoryType(forIdentifier: .moodChanges) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-7 * 24 * 3600), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: moodChangesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            DispatchQueue.main.async {
                if let samples = samples as? [HKCategorySample] {
                    self?.moodChanges = samples.compactMap { MoodChange(from: $0) }
                    self?.analyzeMoodTrends()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Mental Health Tracking
    
    func startMindfulnessSession(type: MindfulnessType) async {
        let session = MindfulSession(
            startDate: Date(),
            type: type,
            duration: 0,
            isActive: true
        )
        
        await saveMindfulSession(session)
        
        // Start session timer
        startMindfulnessTimer(session: session)
    }
    
    func endMindfulnessSession() async {
        guard let activeSession = mindfulnessSessions.first(where: { $0.isActive }) else { return }
        
        let endDate = Date()
        let duration = endDate.timeIntervalSince(activeSession.startDate)
        
        let completedSession = MindfulSession(
            startDate: activeSession.startDate,
            type: activeSession.type,
            duration: duration,
            isActive: false
        )
        
        await updateMindfulSession(completedSession)
        
        // Analyze session impact
        await analyzeMindfulnessImpact(completedSession)
    }
    
    func recordMentalState(_ state: MentalState, intensity: Double = 0.5) async {
        let record = MentalStateRecord(
            timestamp: Date(),
            state: state,
            intensity: intensity,
            context: getCurrentContext()
        )
        
        await saveMentalStateRecord(record)
        
        // Update current mental state
        currentMentalState = state
        
        // Analyze mental state change
        await analyzeMentalStateChange(record)
    }
    
    func recordMoodChange(_ mood: Mood, intensity: Double = 0.5, trigger: String? = nil) async {
        let moodChange = MoodChange(
            timestamp: Date(),
            mood: mood,
            intensity: intensity,
            trigger: trigger,
            context: getCurrentContext()
        )
        
        await saveMoodChange(moodChange)
        
        // Analyze mood change
        await analyzeMoodChange(moodChange)
    }
    
    // MARK: - Analysis and Insights
    
    private func startPeriodicAnalysis() {
        Timer.publish(every: mentalStateUpdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performMentalHealthAnalysis()
            }
            .store(in: &cancellables)
    }
    
    private func performMentalHealthAnalysis() {
        Task {
            await analyzeMentalHealthScore()
            await analyzeStressLevel()
            await analyzeAnxietyLevel()
            await analyzeDepressionRisk()
            await generateMentalHealthInsights()
            await generateMindfulnessRecommendations()
        }
    }
    
    private func analyzeMentalHealthScore() async {
        let score = await mentalHealthAnalyzer.calculateMentalHealthScore(
            mindfulnessSessions: mindfulnessSessions,
            mentalStateRecords: mentalStateRecords,
            moodChanges: moodChanges
        )
        
        await MainActor.run {
            mentalHealthScore = score
        }
    }
    
    private func analyzeStressLevel() async {
        let stressLevel = await stressAnalyzer.analyzeStressLevel(
            mentalStateRecords: mentalStateRecords,
            moodChanges: moodChanges,
            mindfulnessSessions: mindfulnessSessions
        )
        
        await MainActor.run {
            self.stressLevel = stressLevel
        }
    }
    
    private func analyzeAnxietyLevel() async {
        let anxietyLevel = await mentalHealthAnalyzer.analyzeAnxietyLevel(
            mentalStateRecords: mentalStateRecords,
            moodChanges: moodChanges
        )
        
        await MainActor.run {
            self.anxietyLevel = anxietyLevel
        }
    }
    
    private func analyzeDepressionRisk() async {
        let depressionRisk = await mentalHealthAnalyzer.analyzeDepressionRisk(
            mentalStateRecords: mentalStateRecords,
            moodChanges: moodChanges,
            mindfulnessSessions: mindfulnessSessions
        )
        
        await MainActor.run {
            self.depressionRisk = depressionRisk
        }
    }
    
    private func generateMentalHealthInsights() async {
        let insights = await mentalHealthAnalyzer.generateInsights(
            mentalStateRecords: mentalStateRecords,
            moodChanges: moodChanges,
            mindfulnessSessions: mindfulnessSessions
        )
        
        await MainActor.run {
            mentalHealthInsights = insights
        }
    }
    
    private func generateMindfulnessRecommendations() async {
        let recommendations = await mentalHealthAnalyzer.generateMindfulnessRecommendations(
            currentMentalState: currentMentalState,
            stressLevel: stressLevel,
            mindfulnessSessions: mindfulnessSessions
        )
        
        await MainActor.run {
            mindfulnessRecommendations = recommendations
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentContext() -> MentalHealthContext {
        return MentalHealthContext(
            timeOfDay: Calendar.current.component(.hour, from: Date()),
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            location: "Unknown", // Would integrate with location services
            activity: "Unknown", // Would integrate with activity tracking
            socialContext: "Unknown" // Would integrate with social data
        )
    }
    
    private func startMindfulnessTimer(session: MindfulSession) {
        // Start timer for active mindfulness session
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // Update session duration
                self?.updateActiveMindfulnessSession()
            }
            .store(in: &cancellables)
    }
    
    private func updateActiveMindfulnessSession() {
        // Update active mindfulness session duration
        // This would be implemented to track real-time session progress
    }
    
    // MARK: - HealthKit Data Saving
    
    private func saveMindfulSession(_ session: MindfulSession) async {
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let sample = HKCategorySample(
            type: mindfulSessionType,
            value: session.type.rawValue,
            start: session.startDate,
            end: session.startDate.addingTimeInterval(session.duration),
            metadata: [
                "duration": session.duration,
                "type": session.type.rawValue,
                "isActive": session.isActive
            ]
        )
        
        do {
            try await healthStore.save(sample)
            print("Mindful session saved to HealthKit")
        } catch {
            print("Failed to save mindful session: \(error)")
        }
    }
    
    private func updateMindfulSession(_ session: MindfulSession) async {
        // Update existing mindful session
        await saveMindfulSession(session)
    }
    
    private func saveMentalStateRecord(_ record: MentalStateRecord) async {
        guard let mentalStateType = HKObjectType.categoryType(forIdentifier: .mentalState) else { return }
        
        let sample = HKCategorySample(
            type: mentalStateType,
            value: record.state.rawValue,
            start: record.timestamp,
            end: record.timestamp,
            metadata: [
                "intensity": record.intensity,
                "context": record.context.description
            ]
        )
        
        do {
            try await healthStore.save(sample)
            print("Mental state record saved to HealthKit")
        } catch {
            print("Failed to save mental state record: \(error)")
        }
    }
    
    private func saveMoodChange(_ moodChange: MoodChange) async {
        guard let moodChangesType = HKObjectType.categoryType(forIdentifier: .moodChanges) else { return }
        
        let sample = HKCategorySample(
            type: moodChangesType,
            value: moodChange.mood.rawValue,
            start: moodChange.timestamp,
            end: moodChange.timestamp,
            metadata: [
                "intensity": moodChange.intensity,
                "trigger": moodChange.trigger ?? "Unknown",
                "context": moodChange.context.description
            ]
        )
        
        do {
            try await healthStore.save(sample)
            print("Mood change saved to HealthKit")
        } catch {
            print("Failed to save mood change: \(error)")
        }
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeMindfulnessTrends() {
        // Analyze mindfulness session trends
        let totalSessions = mindfulnessSessions.count
        let totalDuration = mindfulnessSessions.reduce(0) { $0 + $1.duration }
        let averageDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        
        // Generate insights based on trends
        if totalSessions < 3 {
            mentalHealthInsights.append(MentalHealthInsight(
                type: .mindfulness,
                title: "Start Your Mindfulness Journey",
                description: "Begin with short 5-minute sessions to build a consistent practice.",
                severity: .info,
                timestamp: Date()
            ))
        }
    }
    
    private func analyzeMentalStateTrends() {
        // Analyze mental state trends over time
        let recentStates = mentalStateRecords.prefix(10)
        let negativeStates = recentStates.filter { $0.state.isNegative }
        let negativePercentage = Double(negativeStates.count) / Double(recentStates.count)
        
        if negativePercentage > 0.7 {
            mentalHealthInsights.append(MentalHealthInsight(
                type: .mentalState,
                title: "Mental State Alert",
                description: "You've been experiencing more negative mental states recently. Consider reaching out for support.",
                severity: .warning,
                timestamp: Date()
            ))
        }
    }
    
    private func analyzeMoodTrends() {
        // Analyze mood trends over time
        let recentMoods = moodChanges.prefix(20)
        let negativeMoods = recentMoods.filter { $0.mood.isNegative }
        let negativePercentage = Double(negativeMoods.count) / Double(recentMoods.count)
        
        if negativePercentage > 0.6 {
            mentalHealthInsights.append(MentalHealthInsight(
                type: .mood,
                title: "Mood Pattern Detected",
                description: "Your mood has been trending negative. Consider activities that typically improve your mood.",
                severity: .info,
                timestamp: Date()
            ))
        }
    }
    
    private func analyzeMindfulnessImpact(_ session: MindfulSession) async {
        // Analyze the impact of mindfulness session on mental state
        let preSessionState = mentalStateRecords.first { $0.timestamp < session.startDate }
        let postSessionState = mentalStateRecords.first { $0.timestamp > session.startDate }
        
        if let pre = preSessionState, let post = postSessionState {
            let improvement = post.state.positiveValue - pre.state.positiveValue
            
            if improvement > 0.3 {
                mentalHealthInsights.append(MentalHealthInsight(
                    type: .mindfulness,
                    title: "Mindfulness Impact",
                    description: "Your mindfulness session had a positive impact on your mental state.",
                    severity: .positive,
                    timestamp: Date()
                ))
            }
        }
    }
    
    private func analyzeMentalStateChange(_ record: MentalStateRecord) async {
        // Analyze mental state change and generate insights
        let previousState = mentalStateRecords.first { $0.timestamp < record.timestamp }
        
        if let previous = previousState {
            let change = record.state.positiveValue - previous.state.positiveValue
            
            if change < -0.5 {
                mentalHealthInsights.append(MentalHealthInsight(
                    type: .mentalState,
                    title: "Mental State Change",
                    description: "Your mental state has changed significantly. Consider what might be causing this.",
                    severity: .info,
                    timestamp: Date()
                ))
            }
        }
    }
    
    private func analyzeMoodChange(_ moodChange: MoodChange) async {
        // Analyze mood change and generate insights
        let previousMood = moodChanges.first { $0.timestamp < moodChange.timestamp }
        
        if let previous = previousMood {
            let change = moodChange.mood.positiveValue - previous.mood.positiveValue
            
            if change < -0.5 {
                mentalHealthInsights.append(MentalHealthInsight(
                    type: .mood,
                    title: "Mood Change",
                    description: "Your mood has changed significantly. Consider what triggered this change.",
                    severity: .info,
                    timestamp: Date()
                ))
            }
        }
    }
}

// MARK: - Supporting Types

struct MindfulSession {
    let startDate: Date
    let type: MindfulnessType
    let duration: TimeInterval
    let isActive: Bool
    
    init(startDate: Date, type: MindfulnessType, duration: TimeInterval, isActive: Bool) {
        self.startDate = startDate
        self.type = type
        self.duration = duration
        self.isActive = isActive
    }
    
    init?(from sample: HKCategorySample) {
        guard let typeRawValue = sample.metadata?["type"] as? Int,
              let mindfulnessType = MindfulnessType(rawValue: typeRawValue) else { return nil }
        
        self.startDate = sample.startDate
        self.type = mindfulnessType
        self.duration = sample.metadata?["duration"] as? TimeInterval ?? 0
        self.isActive = sample.metadata?["isActive"] as? Bool ?? false
    }
}

enum MindfulnessType: Int, CaseIterable {
    case meditation = 0
    case breathing = 1
    case bodyScan = 2
    case lovingKindness = 3
    case walking = 4
    
    var displayName: String {
        switch self {
        case .meditation: return "Meditation"
        case .breathing: return "Breathing Exercise"
        case .bodyScan: return "Body Scan"
        case .lovingKindness: return "Loving Kindness"
        case .walking: return "Walking Meditation"
        }
    }
}

struct MentalStateRecord {
    let timestamp: Date
    let state: MentalState
    let intensity: Double
    let context: MentalHealthContext
    
    init(timestamp: Date, state: MentalState, intensity: Double, context: MentalHealthContext) {
        self.timestamp = timestamp
        self.state = state
        self.intensity = intensity
        self.context = context
    }
    
    init?(from sample: HKCategorySample) {
        guard let stateRawValue = sample.metadata?["intensity"] as? Int,
              let mentalState = MentalState(rawValue: stateRawValue) else { return nil }
        
        self.timestamp = sample.startDate
        self.state = mentalState
        self.intensity = sample.metadata?["intensity"] as? Double ?? 0.5
        self.context = MentalHealthContext() // Simplified for now
    }
}

enum MentalState: Int, CaseIterable {
    case veryNegative = 0
    case negative = 1
    case neutral = 2
    case positive = 3
    case veryPositive = 4
    
    var displayName: String {
        switch self {
        case .veryNegative: return "Very Negative"
        case .negative: return "Negative"
        case .neutral: return "Neutral"
        case .positive: return "Positive"
        case .veryPositive: return "Very Positive"
        }
    }
    
    var isNegative: Bool {
        return self == .veryNegative || self == .negative
    }
    
    var positiveValue: Double {
        return Double(rawValue) / 4.0
    }
}

struct MoodChange {
    let timestamp: Date
    let mood: Mood
    let intensity: Double
    let trigger: String?
    let context: MentalHealthContext
    
    init(timestamp: Date, mood: Mood, intensity: Double, trigger: String?, context: MentalHealthContext) {
        self.timestamp = timestamp
        self.mood = mood
        self.intensity = intensity
        self.trigger = trigger
        self.context = context
    }
    
    init?(from sample: HKCategorySample) {
        guard let moodRawValue = sample.metadata?["intensity"] as? Int,
              let mood = Mood(rawValue: moodRawValue) else { return nil }
        
        self.timestamp = sample.startDate
        self.mood = mood
        self.intensity = sample.metadata?["intensity"] as? Double ?? 0.5
        self.trigger = sample.metadata?["trigger"] as? String
        self.context = MentalHealthContext() // Simplified for now
    }
}

enum Mood: Int, CaseIterable {
    case verySad = 0
    case sad = 1
    case neutral = 2
    case happy = 3
    case veryHappy = 4
    
    var displayName: String {
        switch self {
        case .verySad: return "Very Sad"
        case .sad: return "Sad"
        case .neutral: return "Neutral"
        case .happy: return "Happy"
        case .veryHappy: return "Very Happy"
        }
    }
    
    var isNegative: Bool {
        return self == .verySad || self == .sad
    }
    
    var positiveValue: Double {
        return Double(rawValue) / 4.0
    }
}

struct MentalHealthContext {
    let timeOfDay: Int
    let dayOfWeek: Int
    let location: String
    let activity: String
    let socialContext: String
    
    init(timeOfDay: Int = 0, dayOfWeek: Int = 1, location: String = "Unknown", activity: String = "Unknown", socialContext: String = "Unknown") {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.location = location
        self.activity = activity
        self.socialContext = socialContext
    }
    
    var description: String {
        return "Time: \(timeOfDay), Day: \(dayOfWeek), Location: \(location), Activity: \(activity), Social: \(socialContext)"
    }
}

enum StressLevel {
    case low
    case moderate
    case high
    case severe
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

enum AnxietyLevel {
    case low
    case moderate
    case high
    case severe
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

enum DepressionRisk {
    case low
    case moderate
    case high
    case severe
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

struct MentalHealthInsight {
    let type: InsightType
    let title: String
    let description: String
    let severity: InsightSeverity
    let timestamp: Date
    
    enum InsightType {
        case mindfulness
        case mentalState
        case mood
        case stress
        case anxiety
        case depression
    }
    
    enum InsightSeverity {
        case positive
        case info
        case warning
        case critical
    }
}

struct MindfulnessRecommendation {
    let type: MindfulnessType
    let duration: TimeInterval
    let reason: String
    let priority: Priority
    
    enum Priority {
        case low
        case medium
        case high
    }
}

struct MoodTrend {
    let period: String
    let averageMood: Double
    let trend: TrendDirection
    let timestamp: Date
    
    enum TrendDirection {
        case improving
        case stable
        case declining
    }
}

// MARK: - Analysis Components (Placeholder Classes)

class MentalHealthAnalyzer {
    weak var delegate: MentalHealthManager?
    
    func calculateMentalHealthScore(mindfulnessSessions: [MindfulSession], mentalStateRecords: [MentalStateRecord], moodChanges: [MoodChange]) async -> Double {
        // Calculate comprehensive mental health score
        let mindfulnessScore = calculateMindfulnessScore(mindfulnessSessions)
        let mentalStateScore = calculateMentalStateScore(mentalStateRecords)
        let moodScore = calculateMoodScore(moodChanges)
        
        return (mindfulnessScore + mentalStateScore + moodScore) / 3.0
    }
    
    func analyzeAnxietyLevel(mentalStateRecords: [MentalStateRecord], moodChanges: [MoodChange]) async -> AnxietyLevel {
        // Analyze anxiety level based on mental state and mood patterns
        return .low // Placeholder
    }
    
    func analyzeDepressionRisk(mentalStateRecords: [MentalStateRecord], moodChanges: [MoodChange], mindfulnessSessions: [MindfulSession]) async -> DepressionRisk {
        // Analyze depression risk based on patterns
        return .low // Placeholder
    }
    
    func generateInsights(mentalStateRecords: [MentalStateRecord], moodChanges: [MoodChange], mindfulnessSessions: [MindfulSession]) async -> [MentalHealthInsight] {
        // Generate mental health insights
        return [] // Placeholder
    }
    
    func generateMindfulnessRecommendations(currentMentalState: MentalState, stressLevel: StressLevel, mindfulnessSessions: [MindfulSession]) async -> [MindfulnessRecommendation] {
        // Generate personalized mindfulness recommendations
        return [] // Placeholder
    }
    
    private func calculateMindfulnessScore(_ sessions: [MindfulSession]) -> Double {
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let dailyGoal = 10 * 60 // 10 minutes
        return min(totalDuration / dailyGoal, 1.0)
    }
    
    private func calculateMentalStateScore(_ records: [MentalStateRecord]) -> Double {
        guard !records.isEmpty else { return 0.5 }
        let averagePositiveValue = records.reduce(0) { $0 + $1.state.positiveValue } / Double(records.count)
        return averagePositiveValue
    }
    
    private func calculateMoodScore(_ changes: [MoodChange]) -> Double {
        guard !changes.isEmpty else { return 0.5 }
        let averagePositiveValue = changes.reduce(0) { $0 + $1.mood.positiveValue } / Double(changes.count)
        return averagePositiveValue
    }
}

class MoodAnalyzer {
    weak var delegate: MentalHealthManager?
    
    func analyzeMoodPatterns(_ changes: [MoodChange]) async -> [MoodTrend] {
        // Analyze mood patterns and trends
        return [] // Placeholder
    }
}

class StressAnalyzer {
    weak var delegate: MentalHealthManager?
    
    func analyzeStressLevel(mentalStateRecords: [MentalStateRecord], moodChanges: [MoodChange], mindfulnessSessions: [MindfulSession]) async -> StressLevel {
        // Analyze stress level based on mental state, mood, and mindfulness patterns
        return .low // Placeholder
    }
} 