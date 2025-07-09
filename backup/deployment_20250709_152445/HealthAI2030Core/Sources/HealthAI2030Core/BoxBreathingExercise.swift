import SwiftUI
#if os(iOS)
import WatchConnectivity
#endif
import AVFoundation
import HealthKit
import Combine

@available(tvOS 17.0, *)
@MainActor
class BoxBreathingExercise: NSObject, ObservableObject {
    static let shared = BoxBreathingExercise()
    
    // MARK: - Published Properties
    @Published var isActive = false
    @Published var currentPhase: BreathingPhase = .inhale
    @Published var phaseProgress: Double = 0.0
    @Published var sessionDuration: TimeInterval = 0
    @Published var completedCycles: Int = 0
    @Published var targetCycles: Int = 10
    @Published var breathingRate: Double = 4.0 // seconds per phase
    @Published var sessionStartTime: Date?
    
    // MARK: - Watch Integration
    @Published var watchConnected = false
    @Published var watchHeartRate: Double = 0
    @Published var watchHRV: Double = 0
    @Published var watchStressLevel: Double = 0
    @Published var hapticFeedbackEnabled = true
    
    // MARK: - Visual Effects
    @Published var visualStyle: BreathingVisualStyle = .circle
    @Published var backgroundStyle: BackgroundStyle = .cosmic
    @Published var colorTheme: ColorTheme = .calming
    @Published var particleEffects = true
    @Published var ambientLighting = true
    
    // MARK: - Audio Integration
    @Published var guidedAudioEnabled = true
    @Published var backgroundMusic = true
    @Published var voiceGuidance = true
    @Published var musicVolume: Float = 0.3
    @Published var voiceVolume: Float = 0.7
    
    // MARK: - Health Data
    @Published var preSessionData: HealthMetrics?
    @Published var postSessionData: HealthMetrics?
    @Published var sessionHealthData: [HealthDataPoint] = []
    @Published var stressReduction: Double = 0
    @Published var relaxationScore: Double = 0
    
    // MARK: - Private Properties
    private var phaseTimer: Timer?
    private var sessionTimer: Timer?
    private var healthTimer: Timer?
    private var audioEngine: BreathingAudioEngine?
    private var healthDataManager = HealthDataManager.shared
    private var wcSession: WCSession?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Breathing Animation
    private var animationTimer: Timer?
    private let animationFPS: Double = 60
    private var currentAnimationFrame: Int = 0
    private let maxAnimationFrames: Int = 240 // 4 seconds at 60fps
    
    private override init() {
        super.init()
        setupBoxBreathingExercise()
    }
    
    // MARK: - Setup
    
    private func setupBoxBreathingExercise() {
        setupWatchConnectivity()
        setupAudioEngine()
        setupHealthDataCollection()
        Logger.info("BoxBreathingExercise initialized for Apple TV", log: Logger.relaxation)
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            Logger.warning("WatchConnectivity not supported", log: Logger.relaxation)
            return
        }
        
        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
        
        // Monitor watch connectivity
        wcSession?.publisher(for: \.isReachable)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReachable in
                self?.watchConnected = isReachable
                if isReachable {
                    self?.syncWithWatch()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAudioEngine() {
        audioEngine = BreathingAudioEngine()
        audioEngine?.delegate = self
    }
    
    private func setupHealthDataCollection() {
        healthDataManager.requestPermissions { [weak self] success in
            if success {
                Logger.info("Health data permissions granted for breathing exercise", log: Logger.relaxation)
            } else {
                Logger.warning("Health data permissions denied", log: Logger.relaxation)
            }
        }
    }
    
    // MARK: - Session Management
    
    func startBreathingSession(cycles: Int = 10, rate: Double = 4.0) {
        guard !isActive else { return }
        
        targetCycles = cycles
        breathingRate = rate
        completedCycles = 0
        sessionDuration = 0
        phaseProgress = 0.0
        currentPhase = .inhale
        sessionStartTime = Date()
        isActive = true
        
        // Collect pre-session health metrics
        collectPreSessionData()
        
        // Start audio guidance
        if guidedAudioEnabled {
            audioEngine?.startGuidedBreathing(rate: rate, theme: colorTheme)
        }
        
        // Notify watch to start session
        sendBreathingSessionToWatch(action: .start, cycles: cycles, rate: rate)
        
        // Start breathing phases
        startBreathingPhases()
        
        // Start session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }
        
        // Start health data monitoring
        startHealthDataMonitoring()
        
        Logger.info("Box breathing session started: \(cycles) cycles at \(rate)s per phase", log: Logger.relaxation)
    }
    
    func pauseBreathingSession() {
        guard isActive else { return }
        
        phaseTimer?.invalidate()
        animationTimer?.invalidate()
        audioEngine?.pauseGuidance()
        sendBreathingSessionToWatch(action: .pause)
        
        Logger.info("Box breathing session paused", log: Logger.relaxation)
    }
    
    func resumeBreathingSession() {
        guard isActive else { return }
        
        startBreathingPhases()
        audioEngine?.resumeGuidance()
        sendBreathingSessionToWatch(action: .resume)
        
        Logger.info("Box breathing session resumed", log: Logger.relaxation)
    }
    
    func stopBreathingSession() {
        guard isActive else { return }
        
        isActive = false
        phaseTimer?.invalidate()
        sessionTimer?.invalidate()
        healthTimer?.invalidate()
        animationTimer?.invalidate()
        
        // Collect post-session health metrics
        collectPostSessionData()
        
        // Stop audio
        audioEngine?.stopGuidance()
        
        // Notify watch to stop session
        sendBreathingSessionToWatch(action: .stop)
        
        // Calculate session results
        calculateSessionResults()
        
        Logger.info("Box breathing session completed: \(completedCycles) cycles in \(String(format: "%.1f", sessionDuration))s", log: Logger.relaxation)
    }
    
    // MARK: - Breathing Phases
    
    private func startBreathingPhases() {
        startBreathingPhase()
        startAnimationTimer()
    }
    
    private func startBreathingPhase() {
        phaseProgress = 0.0
        currentAnimationFrame = 0
        
        // Send phase update to watch
        sendPhaseUpdateToWatch()
        
        // Start phase timer
        phaseTimer = Timer.scheduledTimer(withTimeInterval: breathingRate, repeats: false) { [weak self] _ in
            self?.advanceToNextPhase()
        }
        
        // Play phase audio cue
        if voiceGuidance {
            audioEngine?.playPhaseGuidance(phase: currentPhase)
        }
        
        // Trigger watch haptic feedback
        if hapticFeedbackEnabled {
            sendHapticFeedbackToWatch(phase: currentPhase)
        }
    }
    
    private func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / animationFPS, repeats: true) { [weak self] _ in
            self?.updateAnimation()
        }
    }
    
    private func updateAnimation() {
        guard isActive else { return }
        
        currentAnimationFrame += 1
        phaseProgress = Double(currentAnimationFrame) / Double(maxAnimationFrames)
        
        if currentAnimationFrame >= maxAnimationFrames {
            currentAnimationFrame = 0
        }
    }
    
    private func advanceToNextPhase() {
        switch currentPhase {
        case .inhale:
            currentPhase = .hold1
        case .hold1:
            currentPhase = .exhale
        case .exhale:
            currentPhase = .hold2
        case .hold2:
            currentPhase = .inhale
            completedCycles += 1
            
            // Check if session is complete
            if completedCycles >= targetCycles {
                stopBreathingSession()
                return
            }
        }
        
        startBreathingPhase()
    }
    
    private func updateSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - Watch Communication
    
    private func syncWithWatch() {
        guard let session = wcSession, session.isReachable else { return }
        
        let message: [String: Any] = [
            "action": "sync",
            "isActive": isActive,
            "currentPhase": currentPhase.rawValue,
            "targetCycles": targetCycles,
            "completedCycles": completedCycles,
            "breathingRate": breathingRate,
            "hapticEnabled": hapticFeedbackEnabled
        ]
        
        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async { [weak self] in
                self?.handleWatchReply(reply)
            }
        }, errorHandler: { error in
            Logger.error("Failed to sync with watch: \(error.localizedDescription)", log: Logger.relaxation)
        })
    }
    
    private func sendBreathingSessionToWatch(action: WatchAction, cycles: Int? = nil, rate: Double? = nil) {
        guard let session = wcSession, session.isReachable else { return }
        
        var message: [String: Any] = [
            "action": action.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let cycles = cycles {
            message["cycles"] = cycles
        }
        
        if let rate = rate {
            message["rate"] = rate
        }
        
        session.sendMessage(message, replyHandler: nil) { error in
            Logger.error("Failed to send session update to watch: \(error.localizedDescription)", log: Logger.relaxation)
        }
    }
    
    private func sendPhaseUpdateToWatch() {
        guard let session = wcSession, session.isReachable else { return }
        
        let message: [String: Any] = [
            "action": "phaseUpdate",
            "phase": currentPhase.rawValue,
            "progress": phaseProgress,
            "cycleCount": completedCycles,
            "targetCycles": targetCycles,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            Logger.error("Failed to send phase update to watch: \(error.localizedDescription)", log: Logger.relaxation)
        }
    }
    
    private func sendHapticFeedbackToWatch(phase: BreathingPhase) {
        guard let session = wcSession, session.isReachable else { return }
        
        let message: [String: Any] = [
            "action": "haptic",
            "phase": phase.rawValue,
            "intensity": phase.hapticIntensity
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            Logger.error("Failed to send haptic feedback to watch: \(error.localizedDescription)", log: Logger.relaxation)
        }
    }
    
    private func handleWatchReply(_ reply: [String: Any]) {
        if let heartRate = reply["heartRate"] as? Double {
            watchHeartRate = heartRate
        }
        
        if let hrv = reply["hrv"] as? Double {
            watchHRV = hrv
        }
        
        if let stress = reply["stressLevel"] as? Double {
            watchStressLevel = stress
        }
        
        // Record health data point
        let healthPoint = HealthDataPoint(
            timestamp: Date(),
            heartRate: watchHeartRate,
            hrv: watchHRV,
            stressLevel: watchStressLevel,
            breathingPhase: currentPhase
        )
        sessionHealthData.append(healthPoint)
    }
    
    // MARK: - Health Data Collection
    
    private func startHealthDataMonitoring() {
        healthTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.requestWatchHealthData()
        }
    }
    
    private func requestWatchHealthData() {
        guard let session = wcSession, session.isReachable else { return }
        
        let message: [String: Any] = [
            "action": "getHealthData",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleWatchReply(reply)
            }
        }, errorHandler: { error in
            Logger.error("Failed to request health data from watch: \(error.localizedDescription)", log: Logger.relaxation)
        })
    }
    
    private func collectPreSessionData() {
        Task {
            let heartRate = await healthDataManager.getCurrentHeartRate()
            let hrv = await healthDataManager.getCurrentHRV()
            let stress = calculateCurrentStressLevel(heartRate: heartRate, hrv: hrv)
            
            await MainActor.run {
                preSessionData = HealthMetrics(
                    heartRate: heartRate,
                    hrv: hrv,
                    stressLevel: stress,
                    timestamp: Date()
                )
            }
        }
    }
    
    private func collectPostSessionData() {
        Task {
            // Wait a moment for metrics to stabilize
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            let heartRate = await healthDataManager.getCurrentHeartRate()
            let hrv = await healthDataManager.getCurrentHRV()
            let stress = calculateCurrentStressLevel(heartRate: heartRate, hrv: hrv)
            
            await MainActor.run {
                postSessionData = HealthMetrics(
                    heartRate: heartRate,
                    hrv: hrv,
                    stressLevel: stress,
                    timestamp: Date()
                )
            }
        }
    }
    
    private func calculateCurrentStressLevel(heartRate: Double, hrv: Double) -> Double {
        // Simplified stress calculation based on heart rate and HRV
        let normalizedHR = max(0, min(1, (heartRate - 60) / 40))
        let normalizedHRV = max(0, min(1, hrv / 100))
        return normalizedHR * 0.7 + (1 - normalizedHRV) * 0.3
    }
    
    private func calculateSessionResults() {
        guard let preData = preSessionData,
              let postData = postSessionData else { return }
        
        // Calculate stress reduction
        stressReduction = max(0, preData.stressLevel - postData.stressLevel)
        
        // Calculate relaxation score based on multiple factors
        let hrvImprovement = (postData.hrv - preData.hrv) / preData.hrv
        let heartRateReduction = (preData.heartRate - postData.heartRate) / preData.heartRate
        let sessionCompletion = Double(completedCycles) / Double(targetCycles)
        
        relaxationScore = max(0, min(1, 
            stressReduction * 0.4 + 
            max(0, hrvImprovement) * 0.3 + 
            max(0, heartRateReduction) * 0.2 + 
            sessionCompletion * 0.1
        ))
        
        // Save session data to HealthKit
        saveSessionToHealthKit()
        
        // Post completion notification
        NotificationCenter.default.post(name: .breathingSessionCompleted, object: nil)
    }
    
    private func saveSessionToHealthKit() {
        guard let startTime = sessionStartTime else { return }
        
        let endTime = Date()
        let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let mindfulnessSample = HKCategorySample(
            type: mindfulnessType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startTime,
            end: endTime,
            metadata: [
                "type": "Box Breathing",
                "cycles": completedCycles,
                "targetCycles": targetCycles,
                "breathingRate": breathingRate,
                "stressReduction": stressReduction,
                "relaxationScore": relaxationScore
            ]
        )
        
        healthDataManager.healthStore.save(mindfulnessSample) { success, error in
            if success {
                Logger.info("Box breathing session saved to HealthKit", log: Logger.relaxation)
            } else {
                Logger.error("Failed to save session to HealthKit: \(error?.localizedDescription ?? "Unknown error")", log: Logger.relaxation)
            }
        }
    }
    
    // MARK: - Visual Configuration
    
    func setVisualStyle(_ style: BreathingVisualStyle) {
        visualStyle = style
    }
    
    func setBackgroundStyle(_ style: BackgroundStyle) {
        backgroundStyle = style
    }
    
    func setColorTheme(_ theme: ColorTheme) {
        colorTheme = theme
        audioEngine?.updateTheme(theme)
    }
    
    // MARK: - Audio Configuration
    
    func setAudioConfiguration(guided: Bool, background: Bool, voice: Bool) {
        guidedAudioEnabled = guided
        backgroundMusic = background
        voiceGuidance = voice
        
        audioEngine?.updateConfiguration(
            guidedEnabled: guided,
            backgroundEnabled: background,
            voiceEnabled: voice
        )
    }
    
    func setAudioVolumes(music: Float, voice: Float) {
        musicVolume = music
        voiceVolume = voice
        
        audioEngine?.setVolumes(music: music, voice: voice)
    }
}

// MARK: - WCSessionDelegate

extension BoxBreathingExercise: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.watchConnected = activationState == .activated
            if activationState == .activated {
                Logger.info("Watch connectivity activated for breathing exercise", log: Logger.relaxation)
                self?.syncWithWatch()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.handleWatchMessage(message, replyHandler: replyHandler)
        }
    }
    
    private func handleWatchMessage(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let action = message["action"] as? String else {
            replyHandler(["error": "Invalid action"])
            return
        }
        
        switch action {
        case "requestSessionData":
            let reply: [String: Any] = [
                "isActive": isActive,
                "currentPhase": currentPhase.rawValue,
                "phaseProgress": phaseProgress,
                "completedCycles": completedCycles,
                "targetCycles": targetCycles,
                "sessionDuration": sessionDuration
            ]
            replyHandler(reply)
            
        case "healthData":
            handleWatchReply(message)
            replyHandler(["received": true])
            
        default:
            replyHandler(["error": "Unknown action"])
        }
    }
}

// MARK: - BreathingAudioEngineDelegate

extension BoxBreathingExercise: BreathingAudioEngineDelegate {
    func audioEngineDidFinishPhaseGuidance() {
        // Handle audio completion if needed
    }
    
    func audioEngineDidEncounterError(_ error: Error) {
        Logger.error("Breathing audio engine error: \(error.localizedDescription)", log: Logger.relaxation)
    }
}

// MARK: - Supporting Types

enum BreathingPhase: String, CaseIterable {
    case inhale = "inhale"
    case hold1 = "hold1"
    case exhale = "exhale"
    case hold2 = "hold2"
    
    var displayName: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold1: return "Hold"
        case .exhale: return "Breathe Out"
        case .hold2: return "Hold"
        }
    }
    
    var hapticIntensity: Double {
        switch self {
        case .inhale: return 0.8
        case .hold1: return 0.3
        case .exhale: return 0.6
        case .hold2: return 0.2
        }
    }
    
    var visualScale: Double {
        switch self {
        case .inhale: return 1.0
        case .hold1: return 1.0
        case .exhale: return 0.3
        case .hold2: return 0.3
        }
    }
}

enum BreathingVisualStyle: String, CaseIterable {
    case circle = "circle"
    case mandala = "mandala"
    case flower = "flower"
    case geometric = "geometric"
    
    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .mandala: return "Mandala"
        case .flower: return "Flower"
        case .geometric: return "Geometric"
        }
    }
}

enum BackgroundStyle: String, CaseIterable {
    case cosmic = "cosmic"
    case ocean = "ocean"
    case forest = "forest"
    case abstract = "abstract"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .cosmic: return "Cosmic"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .abstract: return "Abstract"
        case .minimal: return "Minimal"
        }
    }
}

enum ColorTheme: String, CaseIterable {
    case calming = "calming"
    case energizing = "energizing"
    case natural = "natural"
    case sunset = "sunset"
    case aurora = "aurora"
    
    var displayName: String {
        switch self {
        case .calming: return "Calming Blues"
        case .energizing: return "Energizing Orange"
        case .natural: return "Natural Green"
        case .sunset: return "Sunset Pink"
        case .aurora: return "Aurora Purple"
        }
    }
    
    var primaryColors: [Color] {
        switch self {
        case .calming: return [.blue, .cyan, .indigo]
        case .energizing: return [.orange, .yellow, .red]
        case .natural: return [.green, .mint, .teal]
        case .sunset: return [.pink, .orange, .purple]
        case .aurora: return [.purple, .blue, .green]
        }
    }
}

enum WatchAction: String {
    case start = "start"
    case pause = "pause"
    case resume = "resume"
    case stop = "stop"
    case sync = "sync"
}

struct HealthMetrics {
    let heartRate: Double
    let hrv: Double
    let stressLevel: Double
    let timestamp: Date
}

struct HealthDataPoint {
    let timestamp: Date
    let heartRate: Double
    let hrv: Double
    let stressLevel: Double
    let breathingPhase: BreathingPhase
}

// MARK: - Audio Engine

class BreathingAudioEngine: ObservableObject {
    weak var delegate: BreathingAudioEngineDelegate?
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var reverbNode: AVAudioUnitReverb?
    private var synthesizerNode: AVAudioUnitSampler?
    
    private var guidanceTimer: Timer?
    private var backgroundPlayer: AVAudioPlayer?
    private var generatedAudioBuffer: AVAudioPCMBuffer?
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        reverbNode = AVAudioUnitReverb()
        synthesizerNode = AVAudioUnitSampler()
        
        guard let engine = audioEngine,
              let player = playerNode,
              let reverb = reverbNode,
              let synth = synthesizerNode else { return }
        
        // Configure reverb
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 30
        
        // Connect audio nodes
        engine.attach(player)
        engine.attach(reverb)
        engine.attach(synth)
        
        engine.connect(player, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)
        engine.connect(synth, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
            Logger.info("Breathing audio engine started", log: Logger.relaxation)
        } catch {
            Logger.error("Failed to start breathing audio engine: \(error.localizedDescription)", log: Logger.relaxation)
        }
    }
    
    func startGuidedBreathing(rate: Double, theme: ColorTheme) {
        // Start background music based on theme
        playBackgroundMusic(for: theme)
    }
    
    func playPhaseGuidance(phase: BreathingPhase) {
        // Play gentle tone for phase transitions
        playPhaseTransitionSound(for: phase)
    }
    
    func pauseGuidance() {
        backgroundPlayer?.pause()
        guidanceTimer?.invalidate()
    }
    
    func resumeGuidance() {
        backgroundPlayer?.play()
    }
    
    func stopGuidance() {
        backgroundPlayer?.stop()
        guidanceTimer?.invalidate()
        audioEngine?.stop()
    }
    
    func updateTheme(_ theme: ColorTheme) {
        // Update audio theme without interrupting current playback
        if backgroundPlayer?.isPlaying == true {
            // Fade out current music and start new theme
            fadeOutAndPlayNewTheme(theme)
        }
    }
    
    func updateConfiguration(guidedEnabled: Bool, backgroundEnabled: Bool, voiceEnabled: Bool) {
        // Update audio configuration
        if !backgroundEnabled {
            backgroundPlayer?.stop()
        } else if backgroundPlayer?.isPlaying != true {
            // Restart background music if it was stopped
            playBackgroundMusic(for: .calming) // Default theme
        }
    }
    
    func setVolumes(music: Float, voice: Float) {
        backgroundPlayer?.volume = music
        playerNode?.volume = voice
    }
    
    private func playBackgroundMusic(for theme: ColorTheme) {
        let musicFile = getBackgroundMusicFile(for: theme)
        
        guard let url = Bundle.main.url(forResource: musicFile, withExtension: "mp3") else {
            Logger.warning("Background music file not found: \(musicFile), generating fallback audio", log: Logger.relaxation)
            generateFallbackBackgroundMusic(for: theme)
            return
        }
        
        do {
            backgroundPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundPlayer?.volume = 0.3
            backgroundPlayer?.play()
        } catch {
            Logger.error("Failed to play background music: \(error.localizedDescription), generating fallback", log: Logger.relaxation)
            generateFallbackBackgroundMusic(for: theme)
        }
    }
    
    private func generateFallbackBackgroundMusic(for theme: ColorTheme) {
        // Generate ambient audio using the existing audio generation system
        Task {
            let duration: TimeInterval = 300.0 // 5 minutes
            let buffer = await generateThemeAmbientAudio(theme: theme, duration: duration)
            
            await MainActor.run {
                self.generatedAudioBuffer = buffer
                self.playGeneratedAudio()
            }
        }
    }
    
    private func generateThemeAmbientAudio(theme: ColorTheme, duration: TimeInterval) async -> AVAudioPCMBuffer {
        let sampleRate: Double = 48000.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return createEmptyBuffer()
        }
        
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return buffer
        }
        
        // Generate theme-specific ambient audio
        switch theme {
        case .calming:
            generateCalmingAmbient(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount), sampleRate: sampleRate)
        case .energizing:
            generateEnergizingAmbient(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount), sampleRate: sampleRate)
        case .natural:
            generateNaturalAmbient(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount), sampleRate: sampleRate)
        case .sunset:
            generateSunsetAmbient(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount), sampleRate: sampleRate)
        case .aurora:
            generateAuroraAmbient(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount), sampleRate: sampleRate)
        }
        
        return buffer
    }
    
    private func generateCalmingAmbient(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Calming: Gentle ocean-like waves with soft tones
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Low frequency wave base
            let waveFreq = 0.3 + 0.2 * sin(time * 0.1)
            leftSample += sin(2.0 * .pi * waveFreq * time) * 0.4
            rightSample += sin(2.0 * .pi * waveFreq * time + 0.1) * 0.4
            
            // Mid frequency gentle tones
            let toneFreq = 120.0 + 20.0 * sin(time * 0.05)
            leftSample += sin(2.0 * .pi * toneFreq * time) * 0.2
            rightSample += sin(2.0 * .pi * toneFreq * time + 0.2) * 0.2
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.3
            rightChannel[i] = Float(rightSample) * 0.3
        }
    }
    
    private func generateEnergizingAmbient(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Energizing: Upbeat ambient with higher frequencies
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Base frequency (gentle but uplifting)
            let baseFreq = 180.0 + 30.0 * sin(time * 0.1)
            leftSample += sin(2.0 * .pi * baseFreq * time) * 0.3
            rightSample += sin(2.0 * .pi * baseFreq * time + 0.1) * 0.3
            
            // Harmonic layer
            let harmonicFreq = baseFreq * 2.0
            leftSample += sin(2.0 * .pi * harmonicFreq * time) * 0.2
            rightSample += sin(2.0 * .pi * harmonicFreq * time + 0.2) * 0.2
            
            // Rhythmic modulation
            let rhythmMod = 1.0 + 0.3 * sin(2.0 * .pi * 0.5 * time)
            leftSample *= rhythmMod
            rightSample *= rhythmMod
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.4
            rightChannel[i] = Float(rightSample) * 0.4
        }
    }
    
    private func generateNaturalAmbient(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Natural: Forest-like sounds with wind
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Wind through trees
            let windFreq = 0.5 + 0.3 * sin(time * 0.2)
            leftSample += sin(2.0 * .pi * windFreq * time) * 0.3
            rightSample += sin(2.0 * .pi * windFreq * time + 0.2) * 0.3
            
            // Natural tones
            let naturalFreq = 140.0 + 25.0 * sin(time * 0.08)
            leftSample += sin(2.0 * .pi * naturalFreq * time) * 0.25
            rightSample += sin(2.0 * .pi * naturalFreq * time + 0.15) * 0.25
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.35
            rightChannel[i] = Float(rightSample) * 0.35
        }
    }
    
    private func generateSunsetAmbient(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Sunset: Warm, fire-like ambient
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Warm base frequency
            let warmFreq = 80.0 + 15.0 * sin(time * 0.08)
            leftSample += sin(2.0 * .pi * warmFreq * time) * 0.4
            rightSample += sin(2.0 * .pi * warmFreq * time + 0.15) * 0.4
            
            // Warm harmonic layer
            let warmHarmonic = warmFreq * 1.5
            leftSample += sin(2.0 * .pi * warmHarmonic * time) * 0.3
            rightSample += sin(2.0 * .pi * warmHarmonic * time + 0.2) * 0.3
            
            // Gentle modulation
            let modFreq = 0.3 + 0.1 * sin(time * 0.2)
            let modulation = 1.0 + 0.2 * sin(2.0 * .pi * modFreq * time)
            leftSample *= modulation
            rightSample *= modulation
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.35
            rightChannel[i] = Float(rightSample) * 0.35
        }
    }
    
    private func generateAuroraAmbient(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Aurora: Ethereal, cosmic ambient
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Ethereal base frequency
            let etherealFreq = 180.0 + 30.0 * sin(time * 0.06)
            leftSample += sin(2.0 * .pi * etherealFreq * time) * 0.4
            rightSample += sin(2.0 * .pi * etherealFreq * time + 0.2) * 0.4
            
            // Floating harmonics
            let harmonic1 = etherealFreq * 2.0
            let harmonic2 = etherealFreq * 3.0
            leftSample += sin(2.0 * .pi * harmonic1 * time) * 0.2
            rightSample += sin(2.0 * .pi * harmonic1 * time + 0.1) * 0.2
            leftSample += sin(2.0 * .pi * harmonic2 * time) * 0.1
            rightSample += sin(2.0 * .pi * harmonic2 * time + 0.3) * 0.1
            
            // Gentle modulation
            let modFreq = 0.2 + 0.1 * sin(time * 0.15)
            let modulation = 1.0 + 0.15 * sin(2.0 * .pi * modFreq * time)
            leftSample *= modulation
            rightSample *= modulation
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.35
            rightChannel[i] = Float(rightSample) * 0.35
        }
    }
    
    private func playGeneratedAudio() {
        guard let buffer = generatedAudioBuffer,
              let player = playerNode else { return }
        
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()
    }
    
    private func fadeOutAndPlayNewTheme(_ theme: ColorTheme) {
        // Fade out current music over 2 seconds
        let fadeOutDuration: TimeInterval = 2.0
        let fadeOutSteps = 20
        let fadeOutInterval = fadeOutDuration / Double(fadeOutSteps)
        
        var currentVolume = backgroundPlayer?.volume ?? 0.3
        let volumeStep = currentVolume / Float(fadeOutSteps)
        
        Timer.scheduledTimer(withTimeInterval: fadeOutInterval, repeats: true) { timer in
            currentVolume -= volumeStep
            self.backgroundPlayer?.volume = max(0, currentVolume)
            
            if currentVolume <= 0 {
                timer.invalidate()
                self.backgroundPlayer?.stop()
                self.playBackgroundMusic(for: theme)
            }
        }
    }
    
    private func playPhaseTransitionSound(for phase: BreathingPhase) {
        // Generate or play appropriate sound for phase transition
        let frequency: Float = phase == .inhale ? 440.0 : 220.0
        generateTone(frequency: frequency, duration: 0.2)
    }
    
    private func generateTone(frequency: Float, duration: TimeInterval) {
        // Generate a simple sine wave tone
        guard let synth = synthesizerNode else { return }
        
        // Trigger note on synthesizer
        synth.startNote(UInt8(69), withVelocity: 64, onChannel: 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            synth.stopNote(UInt8(69), onChannel: 0)
        }
    }
    
    private func getBackgroundMusicFile(for theme: ColorTheme) -> String {
        switch theme {
        case .calming: return "calming_ambient"
        case .energizing: return "energizing_ambient"
        case .natural: return "natural_ambient"
        case .sunset: return "sunset_ambient"
        case .aurora: return "aurora_ambient"
        }
    }
    
    private func calculateSmoothEnvelope(frame: Int, totalFrames: Int, time: Double) -> Double {
        let fadeInDuration = 10.0 // 10 second fade in
        let fadeOutDuration = 10.0 // 10 second fade out
        let fadeInFrames = Int(fadeInDuration * 48000.0)
        let fadeOutFrames = Int(fadeOutDuration * 48000.0)
        
        let fadeInEnvelope = frame < fadeInFrames ? Double(frame) / Double(fadeInFrames) : 1.0
        let fadeOutEnvelope = frame > (totalFrames - fadeOutFrames) ? 
            Double(totalFrames - frame) / Double(fadeOutFrames) : 1.0
        
        // Natural variation
        let naturalVariation = 1.0 + 0.05 * sin(2.0 * .pi * 0.02 * time)
        
        return fadeInEnvelope * fadeOutEnvelope * naturalVariation
    }
    
    private func createEmptyBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000.0, channels: 2)!
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
    }
}

protocol BreathingAudioEngineDelegate: AnyObject {
    func audioEngineDidFinishPhaseGuidance()
    func audioEngineDidEncounterError(_ error: Error)
}