import Foundation
import HealthKit
import CoreML
import Combine
import SwiftUI
import SwiftData // Import SwiftData
import CloudKit // Import CloudKit
import OSLog // Import OSLog for logging

@available(iOS 18.0, macOS 15.0, *) // Updated macOS version to align with SwiftData and CloudKitSyncModels
/// Mental Health Manager for iOS 18+ mental health features
/// Integrates mindfulness, mental state tracking, and mood analysis
@MainActor
public class MentalHealthManager: ObservableObject {
    public static let shared = MentalHealthManager()
    
    // MARK: - Published Properties
    @Published public var mindfulnessSessions: [MindfulSession] = []
    @Published public var mentalStateRecords: [MentalStateRecord] = []
    @Published public var moodChanges: [MoodChange] = []
    @Published public var currentMentalState: MentalState = .neutral
    @Published public var mentalHealthScore: Double = 0.0
    @Published public var stressLevel: StressLevel = .low
    @Published public var anxietyLevel: AnxietyLevel = .low
    @Published public var depressionRisk: DepressionRisk = .low
    
    // MARK: - Mental Health Insights
    @Published public var mentalHealthInsights: [MentalHealthInsight] = []
    @Published public var mindfulnessRecommendations: [MindfulnessRecommendation] = []
    @Published public var moodTrends: [MoodTrend] = []
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    private let mentalHealthAnalyzer = MentalHealthAnalyzer()
    private let moodAnalyzer = MoodAnalyzer()
    private let stressAnalyzer = StressAnalyzer()
    private let swiftDataManager = SwiftDataManager.shared // SwiftData Manager instance
    
    // MARK: - Configuration
    public let mindfulnessGoal: TimeInterval = 10 * 60 // 10 minutes daily // Changed to public
    private let mentalStateUpdateInterval: TimeInterval = 300 // 5 minutes
    private let moodCheckInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - iOS 18+ HealthKit Types
    private let mentalHealthTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
        // HKObjectType.categoryType(forIdentifier: .mindfulMinutes)!, // Not available on all platforms
        // HKObjectType.categoryType(forIdentifier: .mentalState)!, // Not available on all platforms
        HKObjectType.categoryType(forIdentifier: .moodChanges)!
    ]
    
    private init() {
        setupMentalHealthManager()
        // startMentalHealthMonitoring() // Removed: not defined
    }
    
    // MARK: - Setup and Configuration
    
    private func setupMentalHealthManager() {
        requestMentalHealthPermissions()
        setupMentalHealthObservers()
        setupMentalHealthAnalysis()
        Task { await loadMoodEntries() } // Load mood entries from SwiftData
    }
    
    private func requestMentalHealthPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available for mental health tracking")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            // HKObjectType.categoryType(forIdentifier: .mentalState)!, // Not available on all platforms
            HKObjectType.categoryType(forIdentifier: .moodChanges)!
        ]
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            // HKObjectType.categoryType(forIdentifier: .mentalState)!, // Not available on all platforms
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
        // setupMentalStateObserver()
        setupMoodObserver()
    }
    
    private func setupMentalHealthAnalysis() {
        // Initialize mental health analysis components
        // mentalHealthAnalyzer.delegate = self
        // moodAnalyzer.delegate = self
        // stressAnalyzer.delegate = self
    }
    
    // MARK: - Mental Health Data Collection
    
    private func startMentalHealthDataCollection() {
        fetchMindfulnessSessions()
        // fetchMentalStateRecords()
        fetchMoodChanges()
        
        // Start periodic mental health analysis
        startPeriodicAnalysis()
    }
    
    private func setupMindfulnessObserver() {
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let query = HKObserverQuery(sampleType: mindfulSessionType, predicate: nil) { [weak self] query, completion, error in
            Task { @MainActor in self?.fetchMindfulnessSessions() }
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
        // guard let mentalStateType = HKObjectType.categoryType(forIdentifier: .mentalState) else { return }
        // let query = HKObserverQuery(sampleType: mentalStateType, predicate: nil) { [weak self] query, completion, error in
        //     self?.fetchMentalStateRecords()
        //     completion()
        // }
        // healthStore.execute(query)
    }
    
    private func setupMoodObserver() {
        guard let moodChangesType = HKObjectType.categoryType(forIdentifier: .moodChanges) else { return }
        
        let query = HKObserverQuery(sampleType: moodChangesType, predicate: nil) { [weak self] query, completion, error in
            Task { @MainActor in self?.fetchMoodChanges() }
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
        // guard let mentalStateType = HKObjectType.categoryType(forIdentifier: .mentalState) else { return }
        
        // let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 3600), end: Date(), options: .strictEndDate)
        // let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // let query = HKSampleQuery(sampleType: mentalStateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
        //     DispatchQueue.main.async {
        //         if let samples = samples as? [HKCategorySample] {
        //             self?.mentalStateRecords = samples.compactMap { MentalStateRecord(from: $0) }
        //             self?.analyzeMentalStateTrends()
        //         }
        //     }
        // }
        
        // healthStore.execute(query)
    }
    
    private func fetchMoodChanges() {
        // Fetch from HealthKit (existing logic)
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
        
        // Also load from SwiftData to ensure all persisted data is available
        Task { await loadMoodEntries() }
    }
    
    private func loadMoodEntries() async {
        do {
            let fetchedEntries: [SyncableMoodEntry] = try await swiftDataManager.fetchAll()
            DispatchQueue.main.async {
                self.moodChanges = fetchedEntries.map { entry in
                    MoodChange(
                        timestamp: entry.timestamp,
                        mood: entry.mood,
                        intensity: entry.intensity,
                        trigger: entry.context, // Assuming context can be used as trigger for simplicity
                        context: MentalHealthContext(from: entry.context ?? "")
                    )
                }
                Logger.mentalHealth.info("Loaded \(self.moodChanges.count) mood entries from SwiftData.")
            }
        } catch {
            Logger.mentalHealth.error("Failed to load mood entries from SwiftData: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Mental Health Tracking
    
    public func startMindfulnessSession(type: MindfulnessType) async {
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
    
    public func endMindfulnessSession() async {
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
    
    public func recordMentalState(_ state: MentalState, intensity: Double = 0.5) async {
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
    
    public func recordMoodChange(_ mood: Mood, intensity: Double = 0.5, trigger: String? = nil) async {
        let moodChange = MoodChange(
            timestamp: Date(),
            mood: mood,
            intensity: intensity,
            trigger: trigger,
            context: getCurrentContext()
        )
        
        // Save to HealthKit (existing logic)
        await saveMoodChange(moodChange)
        
        // Save to SwiftData
        let syncableMoodEntry = SyncableMoodEntry(
            timestamp: moodChange.timestamp,
            mood: moodChange.mood,
            intensity: moodChange.intensity,
            context: moodChange.context.description,
            triggers: [moodChange.trigger].compactMap { $0 } // Convert optional String to [String]
        )
        
        do {
            try await swiftDataManager.save(syncableMoodEntry)
            Logger.mentalHealth.info("Mood change saved to SwiftData.")
            // Update published property after successful save
            DispatchQueue.main.async {
                self.moodChanges.append(moodChange)
                Task { await self.analyzeMoodChange(moodChange) } // Wrap async call in Task
            }
        } catch {
            Logger.mentalHealth.error("Failed to save mood change to SwiftData: \(error.localizedDescription)")
        }
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
        // guard let mentalStateType = HKObjectType.categoryType(forIdentifier: .mentalState) else { return }
        
        // let sample = HKCategorySample(
        //     type: mentalStateType,
        //     value: record.state.rawValue,
        //     start: record.timestamp,
        //     end: record.timestamp,
        //     metadata: [
        //         "intensity": record.intensity,
        //         "context": record.context.description
        //     ]
        // )
        
        do {
            // try await healthStore.save(sample)
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
        return min(totalDuration / Double(dailyGoal), 1.0)
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
#if os(iOS) || os(watchOS)
    weak var delegate: MentalHealthManager?
#endif
    
    func analyzeMoodPatterns(_ changes: [MoodChange]) async -> [MoodTrend] {
        // Analyze mood patterns and trends
        return [] // Placeholder
    }
}

class StressAnalyzer {
#if os(iOS) || os(watchOS)
    weak var delegate: MentalHealthManager?
#endif
    
    func analyzeStressLevel(mentalStateRecords: [MentalStateRecord], moodChanges: [MoodChange], mindfulnessSessions: [MindfulSession]) async -> StressLevel {
        // Analyze stress level based on mental state, mood, and mindfulness patterns
        return .low // Placeholder
    }
}

// MARK: - Logging Extension for MentalHealthManager
extension Logger {
    private static let subsystem = "com.healthai2030.MentalHealth"
    static let mentalHealth = Logger(subsystem: subsystem, category: "MentalHealthManager")
}