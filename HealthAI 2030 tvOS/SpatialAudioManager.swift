import SwiftUI
import AVFoundation
import Spatial
import HealthKit

@available(tvOS 18.0, *)
class SpatialAudioManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isAudioZoneActive: Bool = false
    @Published var currentBiofeedbackSession: BiofeedbackSession?
    @Published var spatialAudioNodes: [SpatialAudioNode] = []
    @Published var heartRateAdaptiveIntensity: Float = 0.5
    @Published var breathingRateAdaptiveIntensity: Float = 0.5
    
    private var audioEngine: AVAudioEngine
    private var spatialMixer: AVAudioMixerNode
    private var biofeedbackProcessor: BiofeedbackAudioProcessor
    private var heartRateObserver: HeartRateObserver?
    private var breathingPatternObserver: BreathingPatternObserver?
    
    // MARK: - Initialization
    
    override init() {
        audioEngine = AVAudioEngine()
        spatialMixer = AVAudioMixerNode()
        biofeedbackProcessor = BiofeedbackAudioProcessor()
        
        super.init()
        setupAudioEngine()
        setupBiofeedbackObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupAudioEngine() {
        audioEngine.attach(spatialMixer)
        audioEngine.connect(spatialMixer, to: audioEngine.outputNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func setupBiofeedbackObservers() {
        heartRateObserver = HeartRateObserver { [weak self] heartRate in
            self?.adaptAudioToHeartRate(heartRate)
        }
        
        breathingPatternObserver = BreathingPatternObserver { [weak self] breathingRate in
            self?.adaptAudioToBreathingPattern(breathingRate)
        }
    }
    
    // MARK: - Spatial Audio Zone Management
    
    func startSpatialAudioZone(with session: BiofeedbackSession) {
        currentBiofeedbackSession = session
        isAudioZoneActive = true
        
        createSpatialAudioNodes(for: session)
        startBiofeedbackMonitoring()
        
        Task {
            await setupSpatialAudioEnvironment()
        }
    }
    
    func stopSpatialAudioZone() {
        isAudioZoneActive = false
        currentBiofeedbackSession = nil
        
        stopBiofeedbackMonitoring()
        clearSpatialAudioNodes()
    }
    
    private func createSpatialAudioNodes(for session: BiofeedbackSession) {
        spatialAudioNodes = []
        
        for zone in session.audioZones {
            let node = SpatialAudioNode(
                id: zone.id,
                position: zone.position,
                audioSource: zone.audioSource,
                intensityRange: zone.intensityRange,
                biofeedbackType: zone.biofeedbackType
            )
            spatialAudioNodes.append(node)
        }
    }
    
    private func setupSpatialAudioEnvironment() async {
        guard let session = currentBiofeedbackSession else { return }
        
        for node in spatialAudioNodes {
            await createSpatialAudioNode(node)
        }
    }
    
    private func createSpatialAudioNode(_ node: SpatialAudioNode) async {
        guard let audioFile = await loadAudioFile(from: node.audioSource) else { return }
        
        let playerNode = AVAudioPlayerNode()
        let spatialNode = AVAudioMixerNode()
        
        audioEngine.attach(playerNode)
        audioEngine.attach(spatialNode)
        
        audioEngine.connect(playerNode, to: spatialNode, format: audioFile.processingFormat)
        audioEngine.connect(spatialNode, to: spatialMixer, format: nil)
        
        configureSpatialPosition(for: spatialNode, at: node.position)
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
        playerNode.play()
        
        node.playerNode = playerNode
        node.spatialNode = spatialNode
    }
    
    private func configureSpatialPosition(for node: AVAudioMixerNode, at position: SpatialPosition) {
        let spatialMixerFormat = node.outputFormat(forBus: 0)
        
        if let spatialFormat = AVAudioFormat(standardFormatWithSampleRate: spatialMixerFormat.sampleRate, channels: 2) {
            let spatialUnit = AVAudioUnitSpatialMixer()
            audioEngine.attach(spatialUnit)
            
            spatialUnit.sourceMode = .ambient
            spatialUnit.distanceAttenuationParameters.maximumDistance = 100
            spatialUnit.distanceAttenuationParameters.referenceDistance = 1
            
            spatialUnit.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
            spatialUnit.sourcePosition = AVAudio3DPoint(x: position.x, y: position.y, z: position.z)
        }
    }
    
    // MARK: - Biofeedback Adaptation
    
    private func adaptAudioToHeartRate(_ heartRate: Double) {
        let normalizedHeartRate = normalizeHeartRate(heartRate)
        heartRateAdaptiveIntensity = Float(normalizedHeartRate)
        
        updateSpatialAudioIntensity(for: .heartRate, intensity: heartRateAdaptiveIntensity)
    }
    
    private func adaptAudioToBreathingPattern(_ breathingRate: Double) {
        let normalizedBreathingRate = normalizeBreathingRate(breathingRate)
        breathingRateAdaptiveIntensity = Float(normalizedBreathingRate)
        
        updateSpatialAudioIntensity(for: .breathing, intensity: breathingRateAdaptiveIntensity)
    }
    
    private func updateSpatialAudioIntensity(for biofeedbackType: BiofeedbackType, intensity: Float) {
        for node in spatialAudioNodes where node.biofeedbackType == biofeedbackType {
            let adjustedIntensity = node.intensityRange.lowerBound + (intensity * (node.intensityRange.upperBound - node.intensityRange.lowerBound))
            node.spatialNode?.outputVolume = adjustedIntensity
        }
    }
    
    // MARK: - Biofeedback Monitoring
    
    private func startBiofeedbackMonitoring() {
        heartRateObserver?.startMonitoring()
        breathingPatternObserver?.startMonitoring()
    }
    
    private func stopBiofeedbackMonitoring() {
        heartRateObserver?.stopMonitoring()
        breathingPatternObserver?.stopMonitoring()
    }
    
    // MARK: - Utility Methods
    
    private func normalizeHeartRate(_ heartRate: Double) -> Double {
        let minHeartRate = 60.0
        let maxHeartRate = 100.0
        return min(max((heartRate - minHeartRate) / (maxHeartRate - minHeartRate), 0.0), 1.0)
    }
    
    private func normalizeBreathingRate(_ breathingRate: Double) -> Double {
        let minBreathingRate = 12.0
        let maxBreathingRate = 20.0
        return min(max((breathingRate - minBreathingRate) / (maxBreathingRate - minBreathingRate), 0.0), 1.0)
    }
    
    private func loadAudioFile(from source: AudioSource) async -> AVAudioFile? {
        guard let url = Bundle.main.url(forResource: source.fileName, withExtension: source.fileExtension) else {
            return nil
        }
        
        do {
            return try AVAudioFile(forReading: url)
        } catch {
            print("Failed to load audio file: \(error)")
            return nil
        }
    }
    
    private func clearSpatialAudioNodes() {
        for node in spatialAudioNodes {
            node.playerNode?.stop()
            if let playerNode = node.playerNode {
                audioEngine.detach(playerNode)
            }
            if let spatialNode = node.spatialNode {
                audioEngine.detach(spatialNode)
            }
        }
        spatialAudioNodes.removeAll()
    }
}

// MARK: - Supporting Types

struct BiofeedbackSession {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let audioZones: [AudioZone]
    let sessionType: SessionType
    
    enum SessionType {
        case meditation
        case breathingExercise
        case stressRelief
        case sleepPreparation
    }
}

struct AudioZone {
    let id: UUID
    let position: SpatialPosition
    let audioSource: AudioSource
    let intensityRange: ClosedRange<Float>
    let biofeedbackType: BiofeedbackType
}

struct SpatialPosition {
    let x: Float
    let y: Float
    let z: Float
}

struct AudioSource {
    let fileName: String
    let fileExtension: String
    let category: AudioCategory
    
    enum AudioCategory {
        case nature
        case ambient
        case binaural
        case frequency
    }
}

enum BiofeedbackType {
    case heartRate
    case breathing
    case stress
    case coherence
}

class SpatialAudioNode: ObservableObject {
    let id: UUID
    let position: SpatialPosition
    let audioSource: AudioSource
    let intensityRange: ClosedRange<Float>
    let biofeedbackType: BiofeedbackType
    
    var playerNode: AVAudioPlayerNode?
    var spatialNode: AVAudioMixerNode?
    
    init(id: UUID, position: SpatialPosition, audioSource: AudioSource, intensityRange: ClosedRange<Float>, biofeedbackType: BiofeedbackType) {
        self.id = id
        self.position = position
        self.audioSource = audioSource
        self.intensityRange = intensityRange
        self.biofeedbackType = biofeedbackType
    }
}

// MARK: - Biofeedback Observers

class HeartRateObserver {
    private let callback: (Double) -> Void
    private var isMonitoring = false
    
    init(callback: @escaping (Double) -> Void) {
        self.callback = callback
    }
    
    func startMonitoring() {
        isMonitoring = true
        simulateHeartRateData()
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    private func simulateHeartRateData() {
        guard isMonitoring else { return }
        
        let heartRate = Double.random(in: 60...100)
        callback(heartRate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.simulateHeartRateData()
        }
    }
}

class BreathingPatternObserver {
    private let callback: (Double) -> Void
    private var isMonitoring = false
    
    init(callback: @escaping (Double) -> Void) {
        self.callback = callback
    }
    
    func startMonitoring() {
        isMonitoring = true
        simulateBreathingData()
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    private func simulateBreathingData() {
        guard isMonitoring else { return }
        
        let breathingRate = Double.random(in: 12...20)
        callback(breathingRate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.simulateBreathingData()
        }
    }
}

class BiofeedbackAudioProcessor {
    func processAudioForBiofeedback(_ audioBuffer: AVAudioPCMBuffer, with parameters: BiofeedbackParameters) -> AVAudioPCMBuffer {
        return audioBuffer
    }
}

struct BiofeedbackParameters {
    let heartRate: Double
    let breathingRate: Double
    let stressLevel: Double
    let coherenceLevel: Double
}