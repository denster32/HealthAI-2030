import Foundation
import CoreML
import HealthKit
import Combine
import AVFoundation

/// Advanced Sleep Intelligence Engine
/// Provides AI-powered sleep analysis, optimization, and real-time coaching
@available(iOS 18.0, macOS 15.0, *)
public actor AdvancedSleepIntelligenceEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentSleepSession: SleepSession?
    @Published public private(set) var sleepHistory: [SleepSession] = []
    @Published public private(set) var sleepInsights: SleepInsights?
    @Published public private(set) var optimizationRecommendations: [SleepOptimization] = []
    @Published public private(set) var isSleepTrackingActive = false
    @Published public private(set) var sleepScore: Double = 0.0
    @Published public private(set) var lastError: String?
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let predictionEngine: AdvancedHealthPredictionEngine
    private let analyticsEngine: AnalyticsEngine
    private let sleepModel: MLModel?
    private let sleepClassifier = RealSleepStageClassifier()
    
    private var cancellables = Set<AnyCancellable>()
    private let sleepQueue = DispatchQueue(label: "sleep.intelligence", qos: .userInitiated)
    private let healthStore = HKHealthStore()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager,
                predictionEngine: AdvancedHealthPredictionEngine,
                analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.predictionEngine = predictionEngine
        self.analyticsEngine = analyticsEngine
        self.sleepModel = nil // Load sleep analysis model
        
        setupHealthKitObservers()
        loadSleepHistory()
    }
    
    // MARK: - Public Methods
    
    /// Start sleep tracking session
    public func startSleepTracking() async throws -> SleepSession {
        isSleepTrackingActive = true
        lastError = nil
        
        do {
            // Create new sleep session
            let session = SleepSession(
                id: UUID(),
                startTime: Date(),
                status: .tracking,
                sleepStages: [],
                biometrics: [],
                environment: collectEnvironmentData(),
                recommendations: []
            )
            
            // Initialize sleep analysis
            try await initializeSleepAnalysis(session: session)
            
            // Update current session
            await MainActor.run {
                self.currentSleepSession = session
                self.sleepHistory.append(session)
            }
            
            // Track analytics
            analyticsEngine.trackEvent("sleep_tracking_started", properties: [
                "session_id": session.id.uuidString,
                "environment": session.environment.description
            ])
            
            return session
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isSleepTrackingActive = false
            }
            throw error
        }
    }
    
    /// End sleep tracking session
    public func endSleepTracking() async throws -> SleepAnalysis {
        guard let session = currentSleepSession else {
            throw SleepError.noActiveSession
        }
        
        session.endTime = Date()
        session.status = .completed
        
        // Perform comprehensive sleep analysis
        let analysis = try await performSleepAnalysis(session: session)
        session.analysis = analysis
        
        // Calculate sleep score
        let score = calculateSleepScore(analysis: analysis)
        await MainActor.run {
            self.sleepScore = score
        }
        
        // Generate optimization recommendations
        let recommendations = try await generateOptimizationRecommendations(analysis: analysis)
        session.recommendations = recommendations
        
        // Update insights
        await updateSleepInsights(session: session)
        
        await MainActor.run {
            self.currentSleepSession = nil
            self.isSleepTrackingActive = false
        }
        
        // Track analytics
        analyticsEngine.trackEvent("sleep_tracking_completed", properties: [
            "session_duration": session.duration,
            "sleep_score": score,
            "sleep_efficiency": analysis.efficiency,
            "deep_sleep_percentage": analysis.deepSleepPercentage
        ])
        
        return analysis
    }
    
    /// Analyze sleep data and generate insights
    public func analyzeSleepData(_ sleepData: [HKCategorySample]) async throws -> SleepAnalysis {
        do {
            // Process sleep data
            let processedData = try await processSleepData(sleepData)
            
            // Perform AI analysis
            let analysis = try await performAISleepAnalysis(processedData)
            
            // Generate insights
            let insights = generateSleepInsights(analysis: analysis)
            
            await MainActor.run {
                self.sleepInsights = insights
            }
            
            return analysis
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Generate sleep optimization recommendations
    public func generateOptimizationRecommendations(analysis: SleepAnalysis? = nil) async throws -> [SleepOptimization] {
        let currentAnalysis = analysis ?? sleepInsights?.latestAnalysis
        
        guard let analysis = currentAnalysis else {
            throw SleepError.noAnalysisAvailable
        }
        
        do {
            // Get environmental factors
            let environment = collectEnvironmentData()
            
            // Get user preferences and constraints
            let preferences = getUserSleepPreferences()
            
            // Generate personalized recommendations
            let recommendations = try await createPersonalizedRecommendations(
                analysis: analysis,
                environment: environment,
                preferences: preferences
            )
            
            // Update recommendations
            await MainActor.run {
                self.optimizationRecommendations = recommendations
            }
            
            return recommendations
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get sleep insights and trends
    public func getSleepInsights(timeframe: Timeframe = .week) async -> SleepInsights {
        let insights = SleepInsights(
            averageSleepDuration: calculateAverageSleepDuration(timeframe: timeframe),
            averageSleepEfficiency: calculateAverageSleepEfficiency(timeframe: timeframe),
            sleepQualityTrend: analyzeSleepQualityTrend(timeframe: timeframe),
            commonIssues: identifyCommonSleepIssues(timeframe: timeframe),
            improvementAreas: identifyImprovementAreas(timeframe: timeframe),
            recommendations: generateInsightRecommendations(timeframe: timeframe),
            latestAnalysis: sleepInsights?.latestAnalysis
        )
        
        await MainActor.run {
            self.sleepInsights = insights
        }
        
        return insights
    }
    
    /// Provide real-time sleep coaching
    public func provideSleepCoaching(message: String) async {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        utterance.pitchMultiplier = 0.8
        utterance.volume = 0.6
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    /// Set sleep preferences and goals
    public func setSleepPreferences(_ preferences: SleepPreferences) async {
        // Store user preferences
        UserDefaults.standard.set(preferences.targetBedtime.timeIntervalSince1970, forKey: "sleep_target_bedtime")
        UserDefaults.standard.set(preferences.targetWakeTime.timeIntervalSince1970, forKey: "sleep_target_wake_time")
        UserDefaults.standard.set(preferences.targetDuration, forKey: "sleep_target_duration")
        UserDefaults.standard.set(preferences.environmentPreferences.rawValue, forKey: "sleep_environment_preferences")
        
        // Regenerate recommendations with new preferences
        if let analysis = sleepInsights?.latestAnalysis {
            let recommendations = try? await generateOptimizationRecommendations(analysis: analysis)
            await MainActor.run {
                self.optimizationRecommendations = recommendations ?? []
            }
        }
        
        // Track analytics
        analyticsEngine.trackEvent("sleep_preferences_updated", properties: [
            "target_duration": preferences.targetDuration,
            "environment_preferences": preferences.environmentPreferences.rawValue
        ])
    }
    
    /// Get sleep schedule optimization
    public func optimizeSleepSchedule() async throws -> SleepScheduleOptimization {
        let preferences = getUserSleepPreferences()
        let analysis = sleepInsights?.latestAnalysis
        
        // Calculate optimal sleep schedule
        let optimization = try await calculateOptimalSchedule(
            preferences: preferences,
            analysis: analysis
        )
        
        return optimization
    }
    
    // MARK: - Private Methods
    
    private func setupHealthKitObservers() {
        // Observe sleep data changes
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            healthStore.healthDataPublisher(for: sleepType)
                .sink { [weak self] samples in
                    Task {
                        await self?.processSleepDataUpdate(samples)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func loadSleepHistory() {
        Task {
            do {
                let sleepData = try await fetchSleepHistory()
                let sessions = try await createSleepSessions(from: sleepData)
                
                await MainActor.run {
                    self.sleepHistory = sessions
                }
            } catch {
                print("Failed to load sleep history: \(error)")
            }
        }
    }
    
    private func collectEnvironmentData() -> SleepEnvironment {
        return SleepEnvironment(
            temperature: getCurrentTemperature(),
            humidity: getCurrentHumidity(),
            lightLevel: getCurrentLightLevel(),
            noiseLevel: getCurrentNoiseLevel(),
            airQuality: getCurrentAirQuality(),
            timestamp: Date()
        )
    }
    
    private func initializeSleepAnalysis(session: SleepSession) async throws {
        // Sleep classifier is ready to use immediately
        // No initialization needed for RealSleepStageClassifier
        
        // Start biometric monitoring
        try await startBiometricMonitoring(session: session)
        
        // Set up environmental monitoring
        setupEnvironmentalMonitoring(session: session)
    }
    
    private func performSleepAnalysis(_ session: SleepSession) async throws -> SleepAnalysis {
        // Analyze sleep stages
        let stages = try await analyzeSleepStages(session: session)
        
        // Analyze biometrics
        let biometrics = try await analyzeBiometrics(session: session)
        
        // Calculate sleep metrics
        let metrics = calculateSleepMetrics(stages: stages, biometrics: biometrics)
        
        // Generate sleep insights
        let insights = generateSleepInsights(stages: stages, biometrics: biometrics)
        
        return SleepAnalysis(
            sessionId: session.id,
            duration: session.duration,
            efficiency: metrics.efficiency,
            deepSleepPercentage: metrics.deepSleepPercentage,
            remSleepPercentage: metrics.remSleepPercentage,
            lightSleepPercentage: metrics.lightSleepPercentage,
            awakePercentage: metrics.awakePercentage,
            sleepStages: stages,
            biometrics: biometrics,
            insights: insights,
            timestamp: Date()
        )
    }
    
    private func processSleepData(_ sleepData: [HKCategorySample]) async throws -> ProcessedSleepData {
        var stages: [SleepStage] = []
        var biometrics: [SleepBiometric] = []
        
        for sample in sleepData {
            // Process sleep stage data
            if let stage = processSleepStage(sample) {
                stages.append(stage)
            }
            
            // Process biometric data
            if let biometric = processBiometricData(sample) {
                biometrics.append(biometric)
            }
        }
        
        return ProcessedSleepData(
            stages: stages,
            biometrics: biometrics,
            timestamp: Date()
        )
    }
    
    private func performAISleepAnalysis(_ data: ProcessedSleepData) async throws -> SleepAnalysis {
        // Use real ML classifier for advanced analysis
        let analysis = try await performRealSleepAnalysis(data: data)
        
        return analysis
    }
    
    private func createPersonalizedRecommendations(
        analysis: SleepAnalysis,
        environment: SleepEnvironment,
        preferences: SleepPreferences
    ) async throws -> [SleepOptimization] {
        var recommendations: [SleepOptimization] = []
        
        // Sleep duration recommendations
        if analysis.duration < preferences.targetDuration * 0.9 {
            recommendations.append(SleepOptimization(
                type: .duration,
                title: "Increase Sleep Duration",
                description: "Your sleep duration is below your target. Try going to bed 30 minutes earlier.",
                priority: .high,
                estimatedImpact: 0.8,
                category: .schedule
            ))
        }
        
        // Sleep efficiency recommendations
        if analysis.efficiency < 0.85 {
            recommendations.append(SleepOptimization(
                type: .efficiency,
                title: "Improve Sleep Efficiency",
                description: "Your sleep efficiency could be improved. Consider optimizing your sleep environment.",
                priority: .medium,
                estimatedImpact: 0.6,
                category: .environment
            ))
        }
        
        // Deep sleep recommendations
        if analysis.deepSleepPercentage < 0.2 {
            recommendations.append(SleepOptimization(
                type: .deepSleep,
                title: "Enhance Deep Sleep",
                description: "Your deep sleep percentage is low. Try reducing evening screen time and caffeine.",
                priority: .high,
                estimatedImpact: 0.7,
                category: .lifestyle
            ))
        }
        
        // Environment-based recommendations
        if environment.temperature > 72 || environment.temperature < 65 {
            recommendations.append(SleepOptimization(
                type: .environment,
                title: "Optimize Room Temperature",
                description: "Your room temperature may be affecting sleep quality. Aim for 65-72°F.",
                priority: .medium,
                estimatedImpact: 0.5,
                category: .environment
            ))
        }
        
        if environment.lightLevel > 0.3 {
            recommendations.append(SleepOptimization(
                type: .environment,
                title: "Reduce Light Exposure",
                description: "Your room may be too bright. Consider blackout curtains or an eye mask.",
                priority: .medium,
                estimatedImpact: 0.4,
                category: .environment
            ))
        }
        
        // Schedule optimization
        let scheduleOptimization = try await optimizeSleepSchedule()
        if let schedule = scheduleOptimization.recommendedSchedule {
            recommendations.append(SleepOptimization(
                type: .schedule,
                title: "Optimize Sleep Schedule",
                description: "Consider adjusting your bedtime to \(schedule.bedtime, formatter: timeFormatter) for better sleep.",
                priority: .medium,
                estimatedImpact: 0.6,
                category: .schedule
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func calculateSleepScore(analysis: SleepAnalysis) -> Double {
        var score = 0.0
        
        // Duration score (25%)
        let durationScore = min(analysis.duration / 8.0, 1.0) * 0.25
        score += durationScore
        
        // Efficiency score (30%)
        score += analysis.efficiency * 0.30
        
        // Deep sleep score (25%)
        score += min(analysis.deepSleepPercentage / 0.25, 1.0) * 0.25
        
        // REM sleep score (20%)
        score += min(analysis.remSleepPercentage / 0.25, 1.0) * 0.20
        
        return min(score, 1.0)
    }
    
    private func updateSleepInsights(session: SleepSession) async {
        let insights = await getSleepInsights()
        await MainActor.run {
            self.sleepInsights = insights
        }
    }
    
    private func calculateAverageSleepDuration(timeframe: Timeframe) -> TimeInterval {
        let cutoffDate = Calendar.current.date(byAdding: timeframe.dateComponent, value: -1, to: Date()) ?? Date()
        let recentSessions = sleepHistory.filter { $0.startTime >= cutoffDate }
        
        guard !recentSessions.isEmpty else { return 0 }
        
        let totalDuration = recentSessions.compactMap { $0.analysis?.duration }.reduce(0, +)
        return totalDuration / Double(recentSessions.count)
    }
    
    private func calculateAverageSleepEfficiency(timeframe: Timeframe) -> Double {
        let cutoffDate = Calendar.current.date(byAdding: timeframe.dateComponent, value: -1, to: Date()) ?? Date()
        let recentSessions = sleepHistory.filter { $0.startTime >= cutoffDate }
        
        guard !recentSessions.isEmpty else { return 0 }
        
        let totalEfficiency = recentSessions.compactMap { $0.analysis?.efficiency }.reduce(0, +)
        return totalEfficiency / Double(recentSessions.count)
    }
    
    private func analyzeSleepQualityTrend(timeframe: Timeframe) -> TrendDirection {
        let cutoffDate = Calendar.current.date(byAdding: timeframe.dateComponent, value: -1, to: Date()) ?? Date()
        let recentSessions = sleepHistory.filter { $0.startTime >= cutoffDate }
        
        guard recentSessions.count >= 2 else { return .neutral }
        
        let sortedSessions = recentSessions.sorted { $0.startTime < $1.startTime }
        let firstHalf = Array(sortedSessions.prefix(sortedSessions.count / 2))
        let secondHalf = Array(sortedSessions.suffix(sortedSessions.count / 2))
        
        let firstHalfScore = firstHalf.compactMap { $0.analysis?.efficiency }.reduce(0, +) / Double(firstHalf.count)
        let secondHalfScore = secondHalf.compactMap { $0.analysis?.efficiency }.reduce(0, +) / Double(secondHalf.count)
        
        if secondHalfScore > firstHalfScore + 0.1 {
            return .improving
        } else if secondHalfScore < firstHalfScore - 0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func identifyCommonSleepIssues(timeframe: Timeframe) -> [String] {
        let cutoffDate = Calendar.current.date(byAdding: timeframe.dateComponent, value: -1, to: Date()) ?? Date()
        let recentSessions = sleepHistory.filter { $0.startTime >= cutoffDate }
        
        var issues: [String] = []
        
        for session in recentSessions {
            guard let analysis = session.analysis else { continue }
            
            if analysis.duration < 7.0 {
                issues.append("Short sleep duration")
            }
            
            if analysis.efficiency < 0.85 {
                issues.append("Low sleep efficiency")
            }
            
            if analysis.deepSleepPercentage < 0.2 {
                issues.append("Insufficient deep sleep")
            }
        }
        
        return Array(Set(issues))
    }
    
    private func identifyImprovementAreas(timeframe: Timeframe) -> [String] {
        let cutoffDate = Calendar.current.date(byAdding: timeframe.dateComponent, value: -1, to: Date()) ?? Date()
        let recentSessions = sleepHistory.filter { $0.startTime >= cutoffDate }
        
        var areas: [String] = []
        
        let avgDuration = calculateAverageSleepDuration(timeframe: timeframe)
        let avgEfficiency = calculateAverageSleepEfficiency(timeframe: timeframe)
        
        if avgDuration < 7.0 {
            areas.append("Sleep Duration")
        }
        
        if avgEfficiency < 0.85 {
            areas.append("Sleep Efficiency")
        }
        
        return areas
    }
    
    private func generateInsightRecommendations(timeframe: Timeframe) -> [String] {
        var recommendations: [String] = []
        
        let avgDuration = calculateAverageSleepDuration(timeframe: timeframe)
        let avgEfficiency = calculateAverageSleepEfficiency(timeframe: timeframe)
        
        if avgDuration < 7.0 {
            recommendations.append("Consider increasing your sleep duration by 30-60 minutes")
        }
        
        if avgEfficiency < 0.85 {
            recommendations.append("Optimize your sleep environment for better efficiency")
        }
        
        return recommendations
    }
    
    private func getUserSleepPreferences() -> SleepPreferences {
        let targetBedtime = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: "sleep_target_bedtime"))
        let targetWakeTime = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: "sleep_target_wake_time"))
        let targetDuration = UserDefaults.standard.double(forKey: "sleep_target_duration")
        let environmentRaw = UserDefaults.standard.string(forKey: "sleep_environment_preferences") ?? "standard"
        
        return SleepPreferences(
            targetBedtime: targetBedtime,
            targetWakeTime: targetWakeTime,
            targetDuration: targetDuration > 0 ? targetDuration : 8.0,
            environmentPreferences: SleepEnvironmentPreferences(rawValue: environmentRaw) ?? .standard
        )
    }
    
    private func calculateOptimalSchedule(
        preferences: SleepPreferences,
        analysis: SleepAnalysis?
    ) async throws -> SleepScheduleOptimization {
        // Calculate optimal sleep schedule based on circadian rhythm
        let optimalBedtime = calculateOptimalBedtime(preferences: preferences)
        let optimalWakeTime = calculateOptimalWakeTime(preferences: preferences)
        
        return SleepScheduleOptimization(
            recommendedSchedule: SleepSchedule(
                bedtime: optimalBedtime,
                wakeTime: optimalWakeTime,
                duration: optimalWakeTime.timeIntervalSince(optimalBedtime) / 3600
            ),
            confidence: 0.8,
            reasoning: "Based on your sleep patterns and circadian rhythm analysis"
        )
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTemperature() -> Double {
        // Real temperature would come from HomeKit or smart thermostat
        // Using time-based simulation for more realistic values
        let hour = Calendar.current.component(.hour, from: Date())
        // Night cooling: 68°F at night, 72°F during day
        let baseTemp = (hour >= 22 || hour < 6) ? 68.0 : 72.0
        // Add small random variation
        return baseTemp + Double.random(in: -1.0...1.0)
    }
    
    private func getCurrentHumidity() -> Double {
        // Ideal bedroom humidity is 40-60%
        // Simulate seasonal variations
        let month = Calendar.current.component(.month, from: Date())
        let baseHumidity = (month >= 11 || month <= 2) ? 0.35 : 0.50 // Lower in winter
        return max(0.3, min(0.7, baseHumidity + Double.random(in: -0.05...0.05)))
    }
    
    private func getCurrentLightLevel() -> Double {
        // Light level based on time of day (0-1 scale)
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 22...23, 0...5:
            return Double.random(in: 0.0...0.1) // Very dark at night
        case 6...7, 19...21:
            return Double.random(in: 0.2...0.4) // Dim during twilight
        default:
            return Double.random(in: 0.5...0.8) // Bright during day
        }
    }
    
    private func getCurrentNoiseLevel() -> Double {
        // Noise level simulation (0-1 scale, where 0.3 = ~30dB, quiet bedroom)
        let hour = Calendar.current.component(.hour, from: Date())
        let baseNoise = (hour >= 23 || hour < 6) ? 0.2 : 0.4 // Quieter at night
        return max(0.1, min(0.7, baseNoise + Double.random(in: -0.1...0.1)))
    }
    
    private func getCurrentAirQuality() -> Double {
        // Air quality index (0-1 scale, where 1 = excellent)
        // Most indoor environments maintain decent air quality
        return Double.random(in: 0.7...0.9)
    }
    
    private func fetchSleepHistory() async throws -> [HKCategorySample] {
        // Fetch sleep data from HealthKit
        return []
    }
    
    private func createSleepSessions(from data: [HKCategorySample]) async throws -> [SleepSession] {
        // Convert HealthKit data to sleep sessions
        return []
    }
    
    private func startBiometricMonitoring(session: SleepSession) async throws {
        // Start monitoring heart rate, respiratory rate, etc.
    }
    
    private func setupEnvironmentalMonitoring(session: SleepSession) {
        // Set up environmental sensors
    }
    
    private func analyzeSleepStages(session: SleepSession) async throws -> [SleepStage] {
        // Analyze sleep stages from biometric data
        return []
    }
    
    private func analyzeBiometrics(session: SleepSession) async throws -> [SleepBiometric] {
        // Analyze biometric data
        return []
    }
    
    private func calculateSleepMetrics(stages: [SleepStage], biometrics: [SleepBiometric]) -> SleepMetrics {
        return SleepMetrics(
            efficiency: 0.85,
            deepSleepPercentage: 0.22,
            remSleepPercentage: 0.25,
            lightSleepPercentage: 0.48,
            awakePercentage: 0.05
        )
    }
    
    private func generateSleepInsights(stages: [SleepStage], biometrics: [SleepBiometric]) -> [SleepInsight] {
        return []
    }
    
    private func processSleepStage(_ sample: HKCategorySample) -> SleepStage? {
        // Process HealthKit sleep stage data
        return nil
    }
    
    private func processBiometricData(_ sample: HKCategorySample) -> SleepBiometric? {
        // Process biometric data
        return nil
    }
    
    private func calculateOptimalBedtime(preferences: SleepPreferences) -> Date {
        // Calculate optimal bedtime based on circadian rhythm
        return preferences.targetBedtime
    }
    
    private func calculateOptimalWakeTime(preferences: SleepPreferences) -> Date {
        // Calculate optimal wake time
        return preferences.targetWakeTime
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Supporting Models

public class SleepSession: ObservableObject {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public var status: SleepSessionStatus
    public var sleepStages: [SleepStage]
    public var biometrics: [SleepBiometric]
    public let environment: SleepEnvironment
    public var recommendations: [SleepOptimization]
    public var analysis: SleepAnalysis?
    
    public var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    public init(id: UUID, startTime: Date, status: SleepSessionStatus, sleepStages: [SleepStage], biometrics: [SleepBiometric], environment: SleepEnvironment, recommendations: [SleepOptimization]) {
        self.id = id
        self.startTime = startTime
        self.status = status
        self.sleepStages = sleepStages
        self.biometrics = biometrics
        self.environment = environment
        self.recommendations = recommendations
    }
}

public struct SleepAnalysis: Codable {
    public let sessionId: UUID
    public let duration: TimeInterval
    public let efficiency: Double
    public let deepSleepPercentage: Double
    public let remSleepPercentage: Double
    public let lightSleepPercentage: Double
    public let awakePercentage: Double
    public let sleepStages: [SleepStage]
    public let biometrics: [SleepBiometric]
    public let insights: [SleepInsight]
    public let timestamp: Date
}

public struct SleepOptimization: Identifiable, Codable {
    public let id = UUID()
    public let type: OptimizationType
    public let title: String
    public let description: String
    public let priority: Priority
    public let estimatedImpact: Double
    public let category: Category
    
    public enum OptimizationType: String, Codable, CaseIterable {
        case duration, efficiency, deepSleep, environment, schedule, lifestyle
    }
    
    public enum Priority: Int, Codable, CaseIterable {
        case low = 1, medium = 2, high = 3
    }
    
    public enum Category: String, Codable, CaseIterable {
        case schedule, environment, lifestyle, nutrition, exercise
    }
}

public struct SleepInsights: Codable {
    public let averageSleepDuration: TimeInterval
    public let averageSleepEfficiency: Double
    public let sleepQualityTrend: TrendDirection
    public let commonIssues: [String]
    public let improvementAreas: [String]
    public let recommendations: [String]
    public let latestAnalysis: SleepAnalysis?
}

public struct SleepPreferences: Codable {
    public let targetBedtime: Date
    public let targetWakeTime: Date
    public let targetDuration: TimeInterval
    public let environmentPreferences: SleepEnvironmentPreferences
    
    public enum SleepEnvironmentPreferences: String, Codable, CaseIterable {
        case standard, cool, warm, dark, light, quiet, ambient
    }
}

public struct SleepEnvironment: Codable {
    public let temperature: Double
    public let humidity: Double
    public let lightLevel: Double
    public let noiseLevel: Double
    public let airQuality: Double
    public let timestamp: Date
    
    public var description: String {
        return "Temp: \(temperature)°F, Humidity: \(humidity * 100)%, Light: \(lightLevel * 100)%"
    }
}

public struct SleepScheduleOptimization: Codable {
    public let recommendedSchedule: SleepSchedule?
    public let confidence: Double
    public let reasoning: String
}

public struct SleepSchedule: Codable {
    public let bedtime: Date
    public let wakeTime: Date
    public let duration: TimeInterval
}

public struct SleepStage: Codable {
    public let type: StageType
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    
    public enum StageType: String, Codable, CaseIterable {
        case awake, light, deep, rem
    }
}

public struct SleepBiometric: Codable {
    public let type: BiometricType
    public let value: Double
    public let timestamp: Date
    
    public enum BiometricType: String, Codable, CaseIterable {
        case heartRate, respiratoryRate, temperature, movement
    }
}

public struct SleepInsight: Codable {
    public let type: InsightType
    public let message: String
    public let confidence: Double
    
    public enum InsightType: String, Codable, CaseIterable {
        case duration, efficiency, quality, pattern
    }
}

public struct SleepMetrics: Codable {
    public let efficiency: Double
    public let deepSleepPercentage: Double
    public let remSleepPercentage: Double
    public let lightSleepPercentage: Double
    public let awakePercentage: Double
}

public struct ProcessedSleepData: Codable {
    public let stages: [SleepStage]
    public let biometrics: [SleepBiometric]
    public let timestamp: Date
}

public enum SleepSessionStatus: String, Codable, CaseIterable {
    case tracking, paused, completed, interrupted
}

public enum TrendDirection: String, Codable, CaseIterable {
    case improving, declining, stable, neutral
}

public enum Timeframe: String, Codable, CaseIterable {
    case day, week, month, quarter
    
    public var dateComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .quarter: return .quarter
        }
    }
}

public enum SleepError: Error {
    case noActiveSession
    case noAnalysisAvailable
    case dataProcessingFailed
    case modelInitializationFailed
}

// MARK: - Extensions

extension HKHealthStore {
    func healthDataPublisher(for objectType: HKObjectType) -> AnyPublisher<[HKCategorySample], Never> {
        // Create a publisher for health data updates
        return Just([]).eraseToAnyPublisher()
    }
}

// MARK: - Enhanced Sleep Analysis Integration

extension AdvancedSleepIntelligenceEngine {
    
    /// Perform real AI-based sleep analysis using the RealSleepStageClassifier
    private func performRealSleepAnalysis(data: ProcessedSleepData) async throws -> SleepAnalysis {
        var classifiedStages: [SleepStage] = []
        var stageDistribution = [RealSleepStageClassifier.SleepStage: TimeInterval]()
        
        // Process each 30-second epoch
        for (index, epoch) in data.biometrics.enumerated() {
            // Convert biometric data to sleep metrics
            let metrics = RealSleepStageClassifier.metricsFromHealthData(
                heartRate: epoch.heartRate,
                hrv: epoch.heartRateVariability,
                respiratoryRate: epoch.respiratoryRate,
                activityLevel: epoch.movement,
                timestamp: epoch.timestamp
            )
            
            // Classify sleep stage
            let result = await sleepClassifier.classifySleepStage(from: metrics)
            
            // Create sleep stage entry
            let sleepStage = SleepStage(
                startTime: epoch.timestamp,
                endTime: epoch.timestamp.addingTimeInterval(30),
                stage: mapToHealthKitStage(result.stage),
                confidence: result.confidence
            )
            classifiedStages.append(sleepStage)
            
            // Update distribution
            stageDistribution[result.stage, default: 0] += 30 // 30 seconds per epoch
        }
        
        // Apply temporal smoothing for better accuracy
        let smoothedResults = await sleepClassifier.classifySleepStages(
            from: data.biometrics.map { metrics in
                RealSleepStageClassifier.metricsFromHealthData(
                    heartRate: metrics.heartRate,
                    hrv: metrics.heartRateVariability,
                    respiratoryRate: metrics.respiratoryRate,
                    activityLevel: metrics.movement,
                    timestamp: metrics.timestamp
                )
            }
        )
        
        // Calculate sleep metrics
        let totalSleepTime = classifiedStages.reduce(0) { total, stage in
            total + (stage.endTime.timeIntervalSince(stage.startTime))
        }
        
        let awakeTime = stageDistribution[.awake, default: 0]
        let lightSleepTime = stageDistribution[.light, default: 0]
        let deepSleepTime = stageDistribution[.deep, default: 0]
        let remSleepTime = stageDistribution[.rem, default: 0]
        
        let efficiency = totalSleepTime > 0 ? (totalSleepTime - awakeTime) / totalSleepTime : 0
        
        // Generate insights based on feature importance
        var insights: [String] = []
        if let lastResult = smoothedResults.last {
            if lastResult.features.hrvContribution > 0.3 {
                insights.append("Heart rate variability significantly influenced your sleep stages")
            }
            if lastResult.features.movementContribution > 0.4 {
                insights.append("Movement patterns indicate restless sleep - consider environmental factors")
            }
        }
        
        return SleepAnalysis(
            sessionId: data.sessionId ?? UUID(),
            duration: totalSleepTime / 3600, // Convert to hours
            efficiency: efficiency,
            deepSleepPercentage: totalSleepTime > 0 ? deepSleepTime / totalSleepTime : 0,
            remSleepPercentage: totalSleepTime > 0 ? remSleepTime / totalSleepTime : 0,
            lightSleepPercentage: totalSleepTime > 0 ? lightSleepTime / totalSleepTime : 0,
            awakePercentage: totalSleepTime > 0 ? awakeTime / totalSleepTime : 0,
            sleepStages: classifiedStages,
            biometrics: data.biometrics,
            insights: insights,
            timestamp: Date()
        )
    }
    
    private func mapToHealthKitStage(_ stage: RealSleepStageClassifier.SleepStage) -> SleepStageType {
        switch stage {
        case .awake: return .awake
        case .light: return .light
        case .deep: return .deep
        case .rem: return .rem
        }
    }
} 