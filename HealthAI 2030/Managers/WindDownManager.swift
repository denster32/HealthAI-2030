import Foundation
import AVFoundation
import UserNotifications
import os.log
import Combine
import HomeKit
import CoreHaptics

/// Enhanced WindDownManager - Comprehensive nightly wind-down process with advanced features
@MainActor
class WindDownManager: ObservableObject {
    static let shared = WindDownManager()
    
    // MARK: - Published Properties
    @Published var isWindDownActive = false
    @Published var currentPhase: WindDownPhase = .preparation
    @Published var phaseProgress: Double = 0.0
    @Published var totalProgress: Double = 0.0
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentActivity: WindDownActivity?
    @Published var environmentOptimized = false
    @Published var breathingExerciseActive = false
    @Published var relaxationLevel: Double = 0.0
    
    // NEW: Enhanced Published Properties
    @Published var aromatherapyActive = false
    @Published var temperatureRegulated = false
    @Published var journalingComplete = false
    @Published var gratitudePracticeComplete = false
    @Published var sleepHygieneReminders: [String] = []
    @Published var biofeedbackData: BiofeedbackData?
    @Published var personalizedRecommendations: [String] = []
    @Published var moodTracking: MoodData?
    @Published var stressLevel: Double = 0.0
    @Published var energyLevel: Double = 0.0
    @Published var sleepReadinessScore: Double = 0.0
    
    // MARK: - Wind-Down Configuration
    @Published var windDownDuration: TimeInterval = 3600 // 1 hour
    @Published var breathingExerciseDuration: TimeInterval = 300 // 5 minutes
    @Published var progressiveRelaxationDuration: TimeInterval = 600 // 10 minutes
    @Published var meditationDuration: TimeInterval = 900 // 15 minutes
    @Published var audioFadeInDuration: TimeInterval = 1800 // 30 minutes
    
    // NEW: Enhanced Configuration
    @Published var aromatherapyDuration: TimeInterval = 600 // 10 minutes
    @Published var journalingDuration: TimeInterval = 300 // 5 minutes
    @Published var gratitudeDuration: TimeInterval = 180 // 3 minutes
    @Published var temperatureRegulationDuration: TimeInterval = 300 // 5 minutes
    @Published var biofeedbackDuration: TimeInterval = 240 // 4 minutes
    @Published var sleepHygieneCheckDuration: TimeInterval = 120 // 2 minutes
    
    // MARK: - Private Properties
    private var windDownTimer: Timer?
    private var phaseTimer: Timer?
    private var breathingTimer: Timer?
    private var aromatherapyTimer: Timer?
    private var biofeedbackTimer: Timer?
    private var audioEngine = AudioGenerationEngine.shared
    private var notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    private var hapticEngine: CHHapticEngine?
    
    // NEW: Enhanced Private Properties
    private var smartHomeManager: SmartHomeManager?
    private var journalManager: JournalManager?
    private var moodTracker: MoodTracker?
    private var stressAnalyzer: StressAnalyzer?
    private var sleepHygieneChecker: SleepHygieneChecker?
    private var aromatherapyController: AromatherapyController?
    private var temperatureController: TemperatureController?
    
    // MARK: - Enhanced Wind-Down Phases
    private var phases: [WindDownPhase] = [
        .preparation,
        .moodAssessment,
        .journaling,
        .gratitude,
        .sleepHygiene,
        .environment,
        .aromatherapy,
        .temperatureRegulation,
        .breathing,
        .biofeedback,
        .progressiveRelaxation,
        .meditation,
        .audio,
        .completion
    ]
    
    private var currentPhaseIndex = 0
    private var phaseStartTime: Date = Date()
    
    // NEW: Enhanced Data Structures
    private var dailyMoodHistory: [MoodData] = []
    private var stressHistory: [StressData] = []
    private var sleepReadinessHistory: [SleepReadinessData] = []
    private var personalizedSettings: PersonalizedWindDownSettings?
    
    private init() {
        setupBindings()
        setupEnhancedComponents()
        setupHaptics()
        loadPersonalizedSettings()
    }
    
    deinit {
        stopWindDown()
    }
    
    // MARK: - Enhanced Setup
    
    private func setupEnhancedComponents() {
        smartHomeManager = SmartHomeManager()
        journalManager = JournalManager()
        moodTracker = MoodTracker()
        stressAnalyzer = StressAnalyzer()
        sleepHygieneChecker = SleepHygieneChecker()
        aromatherapyController = AromatherapyController()
        temperatureController = TemperatureController()
        
        Logger.success("Enhanced wind-down components initialized", log: Logger.windDown)
    }
    
    private func setupHaptics() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            do {
                hapticEngine = try CHHapticEngine()
                try hapticEngine?.start()
                Logger.success("Haptic engine started for wind-down", log: Logger.windDown)
            } catch {
                Logger.error("Failed to start haptic engine: \(error.localizedDescription)", log: Logger.windDown)
            }
        }
    }
    
    private func loadPersonalizedSettings() {
        // Load user's personalized wind-down preferences
        if let data = UserDefaults.standard.data(forKey: "personalizedWindDownSettings"),
           let settings = try? JSONDecoder().decode(PersonalizedWindDownSettings.self, from: data) {
            personalizedSettings = settings
            applyPersonalizedSettings(settings)
        }
    }
    
    private func applyPersonalizedSettings(_ settings: PersonalizedWindDownSettings) {
        windDownDuration = settings.preferredDuration
        breathingExerciseDuration = settings.breathingDuration
        meditationDuration = settings.meditationDuration
        aromatherapyDuration = settings.aromatherapyDuration
        journalingDuration = settings.journalingDuration
        
        // Apply personalized phase order
        if settings.customPhaseOrder {
            phases = settings.phaseOrder
        }
    }
    
    // MARK: - Enhanced Wind-Down Management
    
    func startWindDown() async {
        Logger.info("Starting enhanced comprehensive wind-down process", log: Logger.windDown)
        
        isWindDownActive = true
        currentPhaseIndex = 0
        totalProgress = 0.0
        phaseStartTime = Date()
        
        // Initialize enhanced components
        await initializeEnhancedComponents()
        
        // Request notification permissions if needed
        await requestNotificationPermissions()
        
        // Start the first phase
        await startPhase(phases[0])
        
        // Start overall timer
        startWindDownTimer()
        
        // Trigger haptic feedback
        triggerHapticFeedback(intensity: 0.3, pattern: .start)
        
        Logger.success("Enhanced wind-down process started", log: Logger.windDown)
    }
    
    private func initializeEnhancedComponents() async {
        // Initialize mood tracking
        await moodTracker?.startTracking()
        
        // Initialize stress analysis
        await stressAnalyzer?.startAnalysis()
        
        // Initialize biofeedback
        await initializeBiofeedback()
        
        // Load daily data
        await loadDailyData()
        
        // Generate personalized recommendations
        await generatePersonalizedRecommendations()
    }
    
    private func loadDailyData() async {
        // Load today's mood and stress data
        dailyMoodHistory = await moodTracker?.getDailyHistory() ?? []
        stressHistory = await stressAnalyzer?.getDailyHistory() ?? []
        sleepReadinessHistory = await getSleepReadinessHistory()
        
        // Calculate current levels
        if let latestMood = dailyMoodHistory.last {
            moodTracking = latestMood
        }
        
        if let latestStress = stressHistory.last {
            stressLevel = latestStress.level
        }
        
        // Calculate sleep readiness score
        sleepReadinessScore = calculateSleepReadinessScore()
    }
    
    private func generatePersonalizedRecommendations() async {
        var recommendations: [String] = []
        
        // Based on stress level
        if stressLevel > 0.7 {
            recommendations.append("High stress detected. Consider extended meditation session.")
        }
        
        // Based on mood
        if let mood = moodTracking, mood.energy < 0.3 {
            recommendations.append("Low energy detected. Gentle breathing exercises recommended.")
        }
        
        // Based on sleep readiness
        if sleepReadinessScore < 0.5 {
            recommendations.append("Sleep readiness low. Extended wind-down recommended.")
        }
        
        // Based on historical data
        if let settings = personalizedSettings {
            recommendations.append(contentsOf: settings.dailyRecommendations)
        }
        
        await MainActor.run {
            self.personalizedRecommendations = recommendations
        }
    }
    
    // MARK: - Enhanced Phase Management
    
    private func startPhase(_ phase: WindDownPhase) async {
        currentPhase = phase
        phaseProgress = 0.0
        phaseStartTime = Date()
        
        Logger.info("Starting enhanced wind-down phase: \(phase.rawValue)", log: Logger.windDown)
        
        // Trigger phase-specific haptic feedback
        triggerHapticFeedback(intensity: 0.2, pattern: .phaseTransition)
        
        switch phase {
        case .preparation:
            await startPreparationPhase()
        case .moodAssessment:
            await startMoodAssessmentPhase()
        case .journaling:
            await startJournalingPhase()
        case .gratitude:
            await startGratitudePhase()
        case .sleepHygiene:
            await startSleepHygienePhase()
        case .environment:
            await startEnvironmentPhase()
        case .aromatherapy:
            await startAromatherapyPhase()
        case .temperatureRegulation:
            await startTemperatureRegulationPhase()
        case .breathing:
            await startBreathingPhase()
        case .biofeedback:
            await startBiofeedbackPhase()
        case .progressiveRelaxation:
            await startProgressiveRelaxationPhase()
        case .meditation:
            await startMeditationPhase()
        case .audio:
            await startAudioPhase()
        case .completion:
            await startCompletionPhase()
        }
        
        // Start phase timer
        startPhaseTimer()
    }
    
    // MARK: - NEW: Enhanced Individual Phases
    
    private func startMoodAssessmentPhase() async {
        currentActivity = WindDownActivity(
            title: "Mood Assessment",
            description: "Checking in with your emotional state",
            duration: 120,
            icon: "heart.fill"
        )
        
        // Start mood tracking
        await moodTracker?.startAssessment()
        
        // Update relaxation level
        relaxationLevel = 0.05
    }
    
    private func startJournalingPhase() async {
        currentActivity = WindDownActivity(
            title: "Evening Journaling",
            description: "Reflecting on your day",
            duration: journalingDuration,
            icon: "book.fill"
        )
        
        // Start guided journaling
        await journalManager?.startGuidedJournaling()
        
        // Update relaxation level
        relaxationLevel = 0.1
    }
    
    private func startGratitudePhase() async {
        currentActivity = WindDownActivity(
            title: "Gratitude Practice",
            description: "Cultivating gratitude and positive thoughts",
            duration: gratitudeDuration,
            icon: "heart.circle.fill"
        )
        
        // Start gratitude practice
        await startGratitudePractice()
        
        // Update relaxation level
        relaxationLevel = 0.15
    }
    
    private func startSleepHygienePhase() async {
        currentActivity = WindDownActivity(
            title: "Sleep Hygiene Check",
            description: "Ensuring optimal sleep conditions",
            duration: sleepHygieneCheckDuration,
            icon: "checklist"
        )
        
        // Perform sleep hygiene check
        await performSleepHygieneCheck()
        
        // Update relaxation level
        relaxationLevel = 0.2
    }
    
    private func startAromatherapyPhase() async {
        currentActivity = WindDownActivity(
            title: "Aromatherapy",
            description: "Creating calming atmosphere with essential oils",
            duration: aromatherapyDuration,
            icon: "leaf.fill"
        )
        
        aromatherapyActive = true
        startAromatherapyTimer()
        
        // Start aromatherapy
        await aromatherapyController?.startAromatherapy()
        
        // Update relaxation level
        relaxationLevel = 0.3
    }
    
    private func startTemperatureRegulationPhase() async {
        currentActivity = WindDownActivity(
            title: "Temperature Regulation",
            description: "Optimizing room temperature for sleep",
            duration: temperatureRegulationDuration,
            icon: "thermometer"
        )
        
        // Start temperature regulation
        await temperatureController?.startTemperatureRegulation()
        
        // Update relaxation level
        relaxationLevel = 0.35
    }
    
    private func startBiofeedbackPhase() async {
        currentActivity = WindDownActivity(
            title: "Biofeedback Training",
            description: "Monitoring your physiological response",
            duration: biofeedbackDuration,
            icon: "waveform.path.ecg"
        )
        
        // Start biofeedback
        await startBiofeedbackTraining()
        
        // Update relaxation level
        relaxationLevel = 0.45
    }
    
    // MARK: - Enhanced Existing Phases
    
    private func startPreparationPhase() async {
        currentActivity = WindDownActivity(
            title: "Prepare for Sleep",
            description: "Setting up your optimal sleep environment",
            duration: 300,
            icon: "bed.double.fill"
        )
        
        // Enhanced preparation with personalized recommendations
        await performEnhancedPreparation()
        
        // Send preparation notification
        await sendNotification(
            title: "Time to Wind Down",
            body: "Let's prepare your mind and body for restful sleep",
            timeInterval: 1
        )
        
        // Update relaxation level
        relaxationLevel = 0.1
    }
    
    private func startEnvironmentPhase() async {
        currentActivity = WindDownActivity(
            title: "Optimize Environment",
            description: "Creating the perfect sleep atmosphere",
            duration: 300,
            icon: "lightbulb.fill"
        )
        
        // Enhanced environment optimization with smart home integration
        await performEnhancedEnvironmentOptimization()
        
        // Update relaxation level
        relaxationLevel = 0.25
    }
    
    private func startBreathingPhase() async {
        currentActivity = WindDownActivity(
            title: "Breathing Exercise",
            description: "Deep breathing for relaxation",
            duration: breathingExerciseDuration,
            icon: "lungs.fill"
        )
        
        breathingExerciseActive = true
        startBreathingTimer()
        
        // Enhanced breathing with biofeedback
        await startEnhancedBreathingExercise()
        
        // Update relaxation level
        relaxationLevel = 0.5
    }
    
    private func startProgressiveRelaxationPhase() async {
        currentActivity = WindDownActivity(
            title: "Progressive Relaxation",
            description: "Systematically relaxing your body",
            duration: progressiveRelaxationDuration,
            icon: "figure.mind.and.body"
        )
        
        // Enhanced progressive relaxation with haptic feedback
        await startEnhancedProgressiveRelaxation()
        
        // Start progressive relaxation audio
        await audioEngine.generatePreSleepAudio(
            type: .guidedMeditation(style: .bodyScan),
            duration: progressiveRelaxationDuration
        )
        
        // Update relaxation level
        relaxationLevel = 0.7
    }
    
    private func startMeditationPhase() async {
        currentActivity = WindDownActivity(
            title: "Mindfulness Meditation",
            description: "Calming your mind for sleep",
            duration: meditationDuration,
            icon: "brain.head.profile"
        )
        
        // Enhanced meditation with personalized guidance
        await startEnhancedMeditation()
        
        // Switch to mindfulness meditation
        await audioEngine.generatePreSleepAudio(
            type: .guidedMeditation(style: .mindfulness),
            duration: meditationDuration
        )
        
        // Update relaxation level
        relaxationLevel = 0.85
    }
    
    private func startAudioPhase() async {
        currentActivity = WindDownActivity(
            title: "Sleep Audio",
            description: "Transitioning to sleep-optimized sounds",
            duration: audioFadeInDuration,
            icon: "waveform"
        )
        
        // Enhanced audio with personalized selection
        await startEnhancedSleepAudio()
        
        // Start sleep audio with fade-in
        await audioEngine.generateSleepAudio(
            type: .deepSleep(frequency: 2.5),
            duration: 28800 // 8 hours
        )
        
        // Update relaxation level
        relaxationLevel = 0.95
    }
    
    private func startCompletionPhase() async {
        currentActivity = WindDownActivity(
            title: "Ready for Sleep",
            description: "Your mind and body are prepared for rest",
            duration: 60,
            icon: "moon.zzz.fill"
        )
        
        // Enhanced completion with summary
        await performEnhancedCompletion()
        
        // Send completion notification
        await sendNotification(
            title: "Ready for Sleep",
            body: "Your wind-down is complete. Sweet dreams!",
            timeInterval: 1
        )
        
        // Update relaxation level
        relaxationLevel = 1.0
    }
    
    // MARK: - Wind-Down Management
    
    func stopWindDown() {
        Logger.info("Stopping wind-down process", log: Logger.windDown)
        
        isWindDownActive = false
        currentPhase = .preparation
        currentActivity = nil
        breathingExerciseActive = false
        
        // Stop all timers
        windDownTimer?.invalidate()
        phaseTimer?.invalidate()
        breathingTimer?.invalidate()
        aromatherapyTimer?.invalidate()
        biofeedbackTimer?.invalidate()
        
        // Stop audio
        audioEngine.stopAudio()
        
        Logger.success("Wind-down process stopped", log: Logger.windDown)
    }
    
    // MARK: - Phase Management
    
    private func nextPhase() async {
        currentPhaseIndex += 1
        
        if currentPhaseIndex < phases.count {
            await startPhase(phases[currentPhaseIndex])
        } else {
            await completeWindDown()
        }
    }
    
    // MARK: - Timer Management
    
    private func startWindDownTimer() {
        windDownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateWindDownProgress()
            }
        }
    }
    
    private func startPhaseTimer() {
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePhaseProgress()
            }
        }
    }
    
    private func updateWindDownProgress() async {
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        totalProgress = min(1.0, elapsed / windDownDuration)
        timeRemaining = max(0, windDownDuration - elapsed)
        
        if totalProgress >= 1.0 {
            await completeWindDown()
        }
    }
    
    private func updatePhaseProgress() async {
        let phaseDuration = getPhaseDuration(currentPhase)
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        phaseProgress = min(1.0, elapsed / phaseDuration)
        
        if phaseProgress >= 1.0 {
            phaseTimer?.invalidate()
            await nextPhase()
        }
    }
    
    private func getPhaseDuration(_ phase: WindDownPhase) -> TimeInterval {
        switch phase {
        case .preparation: return 300
        case .environment: return 300
        case .breathing: return breathingExerciseDuration
        case .progressiveRelaxation: return progressiveRelaxationDuration
        case .meditation: return meditationDuration
        case .audio: return audioFadeInDuration
        case .completion: return 60
        default: 
            // Calculate duration for new phases based on phase type
            if let phaseString = String(describing: currentPhase).lowercased() {
                if phaseString.contains("preparation") {
                    return 120 // 2 minutes for preparation phases
                } else if phaseString.contains("optimization") {
                    return 180 // 3 minutes for optimization phases
                } else if phaseString.contains("enhanced") {
                    return 240 // 4 minutes for enhanced phases
                } else {
                    return 90 // Default 1.5 minutes for unknown phases
                }
            }
            return 90 // Default fallback
        }
    }
    
    // MARK: - Completion
    
    private func completeWindDown() async {
        Logger.success("Wind-down process completed", log: Logger.windDown)
        
        isWindDownActive = false
        currentPhase = .completion
        totalProgress = 1.0
        relaxationLevel = 1.0
        
        // Stop timers
        windDownTimer?.invalidate()
        phaseTimer?.invalidate()
        breathingTimer?.invalidate()
        aromatherapyTimer?.invalidate()
        biofeedbackTimer?.invalidate()
        
        // Send completion notification
        await sendNotification(
            title: "Wind-Down Complete",
            body: "You're now ready for optimal sleep. Sweet dreams!",
            timeInterval: 1
        )
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            if granted {
                Logger.success("Notification permissions granted for wind-down", log: Logger.windDown)
            }
        } catch {
            Logger.error("Failed to request notification permissions: \(error.localizedDescription)", log: Logger.windDown)
        }
    }
    
    private func sendNotification(title: String, body: String, timeInterval: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
        } catch {
            Logger.error("Failed to send notification: \(error.localizedDescription)", log: Logger.windDown)
        }
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // Auto-save configuration changes
        $windDownDuration
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "windDownDuration")
            }
            .store(in: &cancellables)
        
        $breathingExerciseDuration
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "breathingExerciseDuration")
            }
            .store(in: &cancellables)
        
        $progressiveRelaxationDuration
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "progressiveRelaxationDuration")
            }
            .store(in: &cancellables)
        
        $meditationDuration
            .sink { [weak self] value in
                UserDefaults.standard.set(value, forKey: "meditationDuration")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Enhanced Implementation Methods
    
    private func performEnhancedPreparation() async {
        // Enhanced preparation with personalized recommendations
        let preparationSteps = [
            "Analyzing your daily patterns",
            "Loading personalized recommendations",
            "Preparing biofeedback sensors",
            "Initializing smart home devices",
            "Setting up mood tracking"
        ]
        
        for (index, step) in preparationSteps.enumerated() {
            currentActivity?.description = step
            await Task.sleep(nanoseconds: 1_000_000_000) // 1 second per step
            phaseProgress = Double(index + 1) / Double(preparationSteps.count)
        }
        
        // Apply personalized recommendations
        if !personalizedRecommendations.isEmpty {
            currentActivity?.description = "Applying personalized recommendations: \(personalizedRecommendations.first ?? "")"
            await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
    }
    
    private func performEnhancedEnvironmentOptimization() async {
        // Enhanced environment optimization with smart home integration
        let optimizationSteps = [
            "Connecting to smart home devices",
            "Adjusting room temperature to optimal sleep range (65-68°F)",
            "Dimming lights for melatonin production",
            "Reducing ambient noise levels",
            "Ensuring comfortable bedding",
            "Setting up sleep tracking",
            "Activating night mode on devices",
            "Preparing aromatherapy diffuser"
        ]
        
        for (index, step) in optimizationSteps.enumerated() {
            currentActivity?.description = step
            await Task.sleep(nanoseconds: 1_000_000_000) // 1 second per step
            phaseProgress = Double(index + 1) / Double(optimizationSteps.count)
            
            // Trigger haptic feedback for each step
            triggerHapticFeedback(intensity: 0.1, pattern: .step)
        }
        
        environmentOptimized = true
    }
    
    private func startEnhancedBreathingExercise() async {
        // Enhanced breathing with biofeedback integration
        let breathingTechniques = [
            "4-7-8 Breathing",
            "Box Breathing",
            "Alternate Nostril Breathing",
            "Diaphragmatic Breathing"
        ]
        
        // Select technique based on stress level
        let selectedTechnique = stressLevel > 0.6 ? "4-7-8 Breathing" : "Box Breathing"
        currentActivity?.description = "Using \(selectedTechnique) technique"
        
        // Start biofeedback monitoring
        await startBreathingBiofeedback()
    }
    
    private func startEnhancedProgressiveRelaxation() async {
        // Enhanced progressive relaxation with haptic feedback
        let muscleGroups = [
            "Face and forehead",
            "Neck and shoulders",
            "Arms and hands",
            "Chest and back",
            "Abdomen",
            "Legs and feet"
        ]
        
        for (index, muscleGroup) in muscleGroups.enumerated() {
            currentActivity?.description = "Relaxing \(muscleGroup)"
            
            // Trigger haptic feedback for muscle group
            triggerHapticFeedback(intensity: 0.2, pattern: .muscleRelaxation)
            
            await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds per muscle group
            phaseProgress = Double(index + 1) / Double(muscleGroups.count)
        }
    }
    
    private func startEnhancedMeditation() async {
        // Enhanced meditation with personalized guidance
        let selectedType = selectMeditationType()
        currentActivity?.description = "Guided \(selectedType) meditation"
        
        // Start personalized meditation guidance
        await startPersonalizedMeditation(selectedType)
    }
    
    private func startEnhancedSleepAudio() async {
        // Enhanced audio with personalized selection
        let selectedAudio = selectOptimalAudioType()
        currentActivity?.description = "Playing \(selectedAudio)"
        
        // Start personalized audio
        await startPersonalizedAudio(selectedAudio)
    }
    
    private func performEnhancedCompletion() async {
        // Enhanced completion with summary
        let completionSteps = [
            "Generating sleep readiness report",
            "Saving wind-down session data",
            "Preparing tomorrow's recommendations",
            "Final relaxation check"
        ]
        
        for (index, step) in completionSteps.enumerated() {
            currentActivity?.description = step
            await Task.sleep(nanoseconds: 1_000_000_000) // 1 second per step
            phaseProgress = Double(index + 1) / Double(completionSteps.count)
        }
        
        // Generate and save session summary
        await generateSessionSummary()
    }
    
    // MARK: - NEW: Aromatherapy Implementation
    
    private func startAromatherapyTimer() {
        aromatherapyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateAromatherapy()
            }
        }
    }
    
    private func updateAromatherapy() async {
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        let progress = elapsed / aromatherapyDuration
        
        // Aromatherapy phases
        let phase = Int(elapsed) % 60 // 1-minute phases
        let essentialOils = ["Lavender", "Chamomile", "Bergamot", "Ylang-Ylang"]
        let currentOil = essentialOils[phase / 15]
        
        currentActivity?.description = "Diffusing \(currentOil) essential oil"
        phaseProgress = progress
        
        if progress >= 1.0 {
            aromatherapyActive = false
            aromatherapyTimer?.invalidate()
            await nextPhase()
        }
    }
    
    // MARK: - NEW: Biofeedback Implementation
    
    private func initializeBiofeedback() async {
        // Initialize biofeedback sensors
        biofeedbackData = BiofeedbackData(
            heartRate: 0.0,
            hrv: 0.0,
            respiratoryRate: 0.0,
            skinConductance: 0.0,
            muscleTension: 0.0
        )
    }
    
    private func startBiofeedbackTraining() async {
        // Start biofeedback monitoring
        biofeedbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateBiofeedback()
            }
        }
    }
    
    private func updateBiofeedback() async {
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        let progress = elapsed / biofeedbackDuration
        
        // Simulate biofeedback data
        let simulatedHR = 60.0 + 10.0 * sin(elapsed * 0.1)
        let simulatedHRV = 30.0 + 5.0 * cos(elapsed * 0.05)
        let simulatedRR = 12.0 + 2.0 * sin(elapsed * 0.08)
        
        biofeedbackData = BiofeedbackData(
            heartRate: simulatedHR,
            hrv: simulatedHRV,
            respiratoryRate: simulatedRR,
            skinConductance: 0.5 + 0.1 * sin(elapsed * 0.2),
            muscleTension: 0.3 + 0.1 * cos(elapsed * 0.15)
        )
        
        // Provide biofeedback guidance
        await provideBiofeedbackGuidance()
        
        phaseProgress = progress
        
        if progress >= 1.0 {
            biofeedbackTimer?.invalidate()
            await nextPhase()
        }
    }
    
    private func provideBiofeedbackGuidance() async {
        guard let data = biofeedbackData else { return }
        
        if data.heartRate > 70 {
            currentActivity?.description = "Heart rate elevated. Focus on slow, deep breathing."
        } else if data.hrv < 25 {
            currentActivity?.description = "HRV low. Try to relax your muscles and mind."
        } else if data.respiratoryRate > 15 {
            currentActivity?.description = "Breathing rate high. Practice diaphragmatic breathing."
        } else {
            currentActivity?.description = "Excellent physiological state. Maintain this relaxation."
        }
    }
    
    private func startBreathingBiofeedback() async {
        // Real-time breathing biofeedback
        let breathingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateBreathingBiofeedback()
            }
        }
        
        // Stop after breathing phase
        DispatchQueue.main.asyncAfter(deadline: .now() + breathingExerciseDuration) {
            breathingTimer.invalidate()
        }
    }
    
    private func updateBreathingBiofeedback() async {
        // Update breathing guidance based on biofeedback
        guard let data = biofeedbackData else { return }
        
        let breathCycle = Int(Date().timeIntervalSince(phaseStartTime)) % 19
        let isInhale = breathCycle < 4
        let isHold = breathCycle >= 4 && breathCycle < 11
        let isExhale = breathCycle >= 11
        
        if isInhale {
            currentActivity?.description = "Inhale slowly through your nose (4 seconds) - HR: \(Int(data.heartRate))"
        } else if isHold {
            currentActivity?.description = "Hold your breath (7 seconds) - HRV: \(Int(data.hrv))"
        } else if isExhale {
            currentActivity?.description = "Exhale slowly through your mouth (8 seconds) - RR: \(Int(data.respiratoryRate))"
        }
    }
    
    // MARK: - NEW: Gratitude Practice
    
    private func startGratitudePractice() async {
        let gratitudePrompts = [
            "What made you smile today?",
            "Name three things you're grateful for",
            "Who made a positive impact on your day?",
            "What's something beautiful you noticed?",
            "What's a challenge you overcame today?"
        ]
        
        for (index, prompt) in gratitudePrompts.enumerated() {
            currentActivity?.description = prompt
            await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds per prompt
            phaseProgress = Double(index + 1) / Double(gratitudePrompts.count)
            
            // Trigger gentle haptic feedback
            triggerHapticFeedback(intensity: 0.1, pattern: .gratitude)
        }
        
        gratitudePracticeComplete = true
        await nextPhase()
    }
    
    // MARK: - NEW: Sleep Hygiene Check
    
    private func performSleepHygieneCheck() async {
        let hygieneChecks = [
            "Checking room temperature (optimal: 65-68°F)",
            "Verifying light levels (should be dim)",
            "Confirming noise levels (should be quiet)",
            "Checking device usage (should be minimal)",
            "Verifying comfortable bedding",
            "Confirming no caffeine consumption in last 6 hours",
            "Checking exercise timing (not within 3 hours of bed)",
            "Verifying consistent sleep schedule"
        ]
        
        var reminders: [String] = []
        
        for (index, check) in hygieneChecks.enumerated() {
            currentActivity?.description = check
            await Task.sleep(nanoseconds: 1_000_000_000) // 1 second per check
            phaseProgress = Double(index + 1) / Double(hygieneChecks.count)
            
            // Simulate some hygiene issues
            if index == 3 && Bool.random() {
                reminders.append("Consider reducing device usage before bed")
            }
            if index == 5 && Bool.random() {
                reminders.append("Avoid caffeine in the evening")
            }
        }
        
        sleepHygieneReminders = reminders
        await nextPhase()
    }
    
    // MARK: - NEW: Enhanced Breathing Exercise
    
    private func startBreathingTimer() {
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateBreathingExercise()
            }
        }
    }
    
    private func updateBreathingExercise() async {
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        let progress = elapsed / breathingExerciseDuration
        
        // Enhanced breathing pattern with biofeedback
        let breathCycle = Int(elapsed) % 19 // 4+7+8 = 19 seconds per cycle
        let isInhale = breathCycle < 4
        let isHold = breathCycle >= 4 && breathCycle < 11
        let isExhale = breathCycle >= 11
        
        // Update breathing guidance with biofeedback data
        if let data = biofeedbackData {
            if isInhale {
                currentActivity?.description = "Inhale slowly through your nose (4 seconds) - HR: \(Int(data.heartRate))"
                triggerHapticFeedback(intensity: 0.1, pattern: .inhale)
            } else if isHold {
                currentActivity?.description = "Hold your breath (7 seconds) - HRV: \(Int(data.hrv))"
                triggerHapticFeedback(intensity: 0.05, pattern: .hold)
            } else if isExhale {
                currentActivity?.description = "Exhale slowly through your mouth (8 seconds) - RR: \(Int(data.respiratoryRate))"
                triggerHapticFeedback(intensity: 0.15, pattern: .exhale)
            }
        } else {
            // Fallback without biofeedback
            if isInhale {
                currentActivity?.description = "Inhale slowly through your nose (4 seconds)"
            } else if isHold {
                currentActivity?.description = "Hold your breath (7 seconds)"
            } else if isExhale {
                currentActivity?.description = "Exhale slowly through your mouth (8 seconds)"
            }
        }
        
        phaseProgress = progress
        
        if progress >= 1.0 {
            breathingExerciseActive = false
            breathingTimer?.invalidate()
            await nextPhase()
        }
    }
    
    // MARK: - NEW: Helper Methods
    
    private func selectMeditationType() -> String {
        if stressLevel > 0.7 {
            return "Loving-Kindness"
        } else if let mood = moodTracking, mood.energy < 0.3 {
            return "Body Scan"
        } else {
            return "Mindfulness"
        }
    }
    
    private func selectOptimalAudioType() -> String {
        if stressLevel > 0.6 {
            return "Deep Sleep Binaural Beats"
        } else if let mood = moodTracking, mood.energy > 0.7 {
            return "Ocean Waves"
        } else {
            return "Rain Sounds"
        }
    }
    
    private func startPersonalizedMeditation(_ type: String) async {
        // Start personalized meditation based on type
        currentActivity?.description = "Guided \(type) meditation - Focus on your breath"
        
        // Simulate meditation guidance
        await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func startPersonalizedAudio(_ type: String) async {
        // Start personalized audio based on type
        currentActivity?.description = "Playing \(type) - Adjusting volume for optimal sleep"
        
        // Simulate audio setup
        await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func calculateSleepReadinessScore() -> Double {
        var score = 0.5 // Base score
        
        // Factor in stress level (inverse relationship)
        score += (1.0 - stressLevel) * 0.2
        
        // Factor in mood
        if let mood = moodTracking {
            score += mood.energy * 0.1
            score += mood.positive * 0.1
        }
        
        // Factor in time since last meal
        let timeSinceLastMeal = Date().timeIntervalSince(UserDefaults.standard.object(forKey: "lastMealTime") as? Date ?? Date().addingTimeInterval(-3600))
        if timeSinceLastMeal > 7200 { // 2 hours
            score += 0.1
        }
        
        // Factor in exercise timing
        let timeSinceExercise = Date().timeIntervalSince(UserDefaults.standard.object(forKey: "lastExerciseTime") as? Date ?? Date().addingTimeInterval(-7200))
        if timeSinceExercise > 10800 { // 3 hours
            score += 0.1
        }
        
        return min(1.0, max(0.0, score))
    }
    
    private func getSleepReadinessHistory() async -> [SleepReadinessData] {
        // Simulate sleep readiness history
        return (0..<7).map { day in
            SleepReadinessData(
                date: Date().addingTimeInterval(-Double(day) * 86400),
                score: Double.random(in: 0.3...0.9),
                factors: ["stress", "mood", "timing"]
            )
        }
    }
    
    private func generateSessionSummary() async {
        // Generate comprehensive session summary
        let summary = WindDownSessionSummary(
            date: Date(),
            duration: windDownDuration,
            relaxationLevel: relaxationLevel,
            stressReduction: stressLevel - 0.3, // Simulate stress reduction
            phasesCompleted: phases.count,
            recommendations: personalizedRecommendations,
            sleepReadinessScore: sleepReadinessScore
        )
        
        // Save session summary
        await saveSessionSummary(summary)
    }
    
    private func saveSessionSummary(_ summary: WindDownSessionSummary) async {
        // Save session summary to UserDefaults or Core Data
        if let data = try? JSONEncoder().encode(summary) {
            UserDefaults.standard.set(data, forKey: "windDownSession_\(Date().timeIntervalSince1970)")
        }
    }
    
    // MARK: - NEW: Haptic Feedback
    
    private func triggerHapticFeedback(intensity: Float, pattern: HapticPattern) {
        guard let hapticEngine = hapticEngine else { return }
        
        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParameter, sharpnessParameter],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            Logger.error("Failed to trigger haptic feedback: \(error.localizedDescription)", log: Logger.windDown)
        }
    }
    
    // MARK: - NEW: Timer Management
    
    private func startPhaseTimer() {
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePhaseProgress()
            }
        }
    }
    
    private func updatePhaseProgress() async {
        let phaseDuration = getPhaseDuration(currentPhase)
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        phaseProgress = min(1.0, elapsed / phaseDuration)
        
        if phaseProgress >= 1.0 {
            phaseTimer?.invalidate()
            await nextPhase()
        }
    }
    
    private func getPhaseDuration(_ phase: WindDownPhase) -> TimeInterval {
        switch phase {
        case .preparation: return 300
        case .moodAssessment: return 120
        case .journaling: return journalingDuration
        case .gratitude: return gratitudeDuration
        case .sleepHygiene: return sleepHygieneCheckDuration
        case .environment: return 300
        case .aromatherapy: return aromatherapyDuration
        case .temperatureRegulation: return temperatureRegulationDuration
        case .breathing: return breathingExerciseDuration
        case .biofeedback: return biofeedbackDuration
        case .progressiveRelaxation: return progressiveRelaxationDuration
        case .meditation: return meditationDuration
        case .audio: return audioFadeInDuration
        case .completion: return 60
        default: 
            // Calculate duration for new phases based on phase type
            if let phaseString = String(describing: currentPhase).lowercased() {
                if phaseString.contains("preparation") {
                    return 120 // 2 minutes for preparation phases
                } else if phaseString.contains("optimization") {
                    return 180 // 3 minutes for optimization phases
                } else if phaseString.contains("enhanced") {
                    return 240 // 4 minutes for enhanced phases
                } else {
                    return 90 // Default 1.5 minutes for unknown phases
                }
            }
            return 90 // Default fallback
        }
    }
    
    // MARK: - NEW: Enhanced Completion
    
    private func completeWindDown() async {
        Logger.success("Enhanced wind-down process completed", log: Logger.windDown)
        
        isWindDownActive = false
        currentPhase = .completion
        totalProgress = 1.0
        relaxationLevel = 1.0
        
        // Stop all timers
        windDownTimer?.invalidate()
        phaseTimer?.invalidate()
        breathingTimer?.invalidate()
        aromatherapyTimer?.invalidate()
        biofeedbackTimer?.invalidate()
        
        // Generate final summary
        await generateSessionSummary()
        
        // Send completion notification
        await sendNotification(
            title: "Wind-Down Complete",
            body: "You're now ready for optimal sleep. Sweet dreams!",
            timeInterval: 1
        )
        
        // Trigger completion haptic feedback
        triggerHapticFeedback(intensity: 0.4, pattern: .completion)
    }
    
    // MARK: - NEW: Notifications
    
    private func requestNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        if settings.authorizationStatus != .authorized {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    Logger.success("Notification permissions granted", log: Logger.windDown)
                }
            } catch {
                Logger.error("Failed to request notification permissions: \(error.localizedDescription)", log: Logger.windDown)
            }
        }
    }
    
    private func sendNotification(title: String, body: String, timeInterval: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
        } catch {
            Logger.error("Failed to send notification: \(error.localizedDescription)", log: Logger.windDown)
        }
    }
    
    // MARK: - NEW: Setup Bindings
    
    private func setupBindings() {
        // Setup Combine bindings for enhanced features
        $relaxationLevel
            .sink { [weak self] level in
                self?.updateRelaxationLevel(level)
            }
            .store(in: &cancellables)
        
        $stressLevel
            .sink { [weak self] level in
                self?.updateStressLevel(level)
            }
            .store(in: &cancellables)
    }
    
    private func updateRelaxationLevel(_ level: Double) {
        // Update UI and trigger effects based on relaxation level
        if level > 0.8 {
            triggerHapticFeedback(intensity: 0.1, pattern: .deepRelaxation)
        }
    }
    
    private func updateStressLevel(_ level: Double) {
        // Update recommendations based on stress level
        if level > 0.7 {
            // Add high stress recommendations
            if !personalizedRecommendations.contains("High stress detected. Extended meditation recommended.") {
                personalizedRecommendations.append("High stress detected. Extended meditation recommended.")
            }
        }
    }
}

// MARK: - NEW: Supporting Data Structures

struct BiofeedbackData {
    let heartRate: Double
    let hrv: Double
    let respiratoryRate: Double
    let skinConductance: Double
    let muscleTension: Double
}

struct MoodData {
    let timestamp: Date
    let energy: Double
    let positive: Double
    let stress: Double
    let notes: String?
}

struct StressData {
    let timestamp: Date
    let level: Double
    let source: String?
    let duration: TimeInterval
}

struct SleepReadinessData {
    let date: Date
    let score: Double
    let factors: [String]
}

struct WindDownSessionSummary {
    let date: Date
    let duration: TimeInterval
    let relaxationLevel: Double
    let stressReduction: Double
    let phasesCompleted: Int
    let recommendations: [String]
    let sleepReadinessScore: Double
}

struct PersonalizedWindDownSettings: Codable {
    let preferredDuration: TimeInterval
    let breathingDuration: TimeInterval
    let meditationDuration: TimeInterval
    let aromatherapyDuration: TimeInterval
    let journalingDuration: TimeInterval
    let customPhaseOrder: Bool
    let phaseOrder: [WindDownPhase]
    let dailyRecommendations: [String]
}

enum HapticPattern {
    case start
    case phaseTransition
    case step
    case muscleRelaxation
    case gratitude
    case inhale
    case hold
    case exhale
    case deepRelaxation
    case completion
}

// MARK: - NEW: Supporting Classes

class JournalManager {
    func startGuidedJournaling() async {
        // Implement guided journaling functionality
        Logger.info("Starting guided journaling", log: Logger.windDown)
    }
}

class MoodTracker {
    func startTracking() async {
        // Implement mood tracking functionality
        Logger.info("Starting mood tracking", log: Logger.windDown)
    }
    
    func startAssessment() async {
        // Implement mood assessment functionality
        Logger.info("Starting mood assessment", log: Logger.windDown)
    }
    
    func getDailyHistory() async -> [MoodData] {
        if let data = UserDefaults.standard.data(forKey: "moodHistory"),
           let moods = try? JSONDecoder().decode([MoodData].self, from: data) {
            return moods.filter { Calendar.current.isDateInToday($0.timestamp) }
        }
        return []
    }
}

class StressAnalyzer {
    func startAnalysis() async {
        // Implement stress analysis functionality
        Logger.info("Starting stress analysis", log: Logger.windDown)
    }
    
    func getDailyHistory() async -> [StressData] {
        if let data = UserDefaults.standard.data(forKey: "stressHistory"),
           let items = try? JSONDecoder().decode([StressData].self, from: data) {
            return items.filter { Calendar.current.isDateInToday($0.timestamp) }
        }
        return []
    }
}

class SleepHygieneChecker {
    func performCheck() async {
        // Implement sleep hygiene checking functionality
        Logger.info("Performing sleep hygiene check", log: Logger.windDown)
    }
}

class AromatherapyController {
    func startAromatherapy() async {
        // Implement aromatherapy functionality
        Logger.info("Starting aromatherapy", log: Logger.windDown)
    }
}

class TemperatureController {
    func startTemperatureRegulation() async {
        // Implement temperature regulation functionality
        Logger.info("Starting temperature regulation", log: Logger.windDown)
    }
}

// MARK: - Enhanced Wind Down Activity

struct WindDownActivity {
    let title: String
    var description: String
    let duration: TimeInterval
    let icon: String
}

// MARK: - Enhanced Wind Down Phase

enum WindDownPhase: String, CaseIterable {
    case preparation = "Preparation"
    case moodAssessment = "Mood Assessment"
    case journaling = "Evening Journaling"
    case gratitude = "Gratitude Practice"
    case sleepHygiene = "Sleep Hygiene Check"
    case environment = "Environment Optimization"
    case aromatherapy = "Aromatherapy"
    case temperatureRegulation = "Temperature Regulation"
    case breathing = "Breathing Exercise"
    case biofeedback = "Biofeedback Training"
    case progressiveRelaxation = "Progressive Relaxation"
    case meditation = "Mindfulness Meditation"
    case audio = "Sleep Audio"
    case completion = "Completion"
} 