import Foundation
import ARKit
import RealityKit
import SwiftUI
import Combine
import HealthKit

/// AR Health Data Visualization System
/// Provides real-time health data visualization in augmented reality
@available(iOS 18.0, *)
public class ARHealthDataVisualization: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isARSessionActive = false
    @Published public private(set) var currentHealthData: HealthDataOverlay?
    @Published public private(set) var arSessionState: ARSession.State = .notRunning
    @Published public private(set) var trackingState: ARCamera.TrackingState = .notAvailable
    @Published public private(set) var lastError: ARError?
    @Published public private(set) var availableHealthMetrics: [HealthMetricType] = []
    @Published public private(set) var visualizationQuality: VisualizationQuality = .unknown
    
    // MARK: - Private Properties
    private var arSession: ARSession?
    private var arView: ARView?
    private let healthStore = HKHealthStore()
    private let healthDataManager: HealthDataManager
    private var cancellables = Set<AnyCancellable>()
    private let arQueue = DispatchQueue(label: "ar.health.visualization", qos: .userInteractive)
    
    // AR Scene Management
    private var healthDataEntities: [UUID: Entity] = [:]
    private var anchorEntities: [UUID: ARAnchor] = [:]
    private var healthDataAnchors: [UUID: HealthDataAnchor] = [:]
    
    // Performance Monitoring
    private var frameCount = 0
    private var lastFrameTime: TimeInterval = 0
    private var averageFPS: Double = 0
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager) {
        self.healthDataManager = healthDataManager
        super.init()
        setupARSession()
        setupHealthDataMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start AR session for health data visualization
    public func startARSession() async throws {
        guard ARSession.isSupported else {
            throw ARError(.unsupportedConfiguration)
        }
        
        try await arQueue.async {
            self.setupARSession()
            self.arSession?.run(self.createARConfiguration())
            self.isARSessionActive = true
        }
    }
    
    /// Stop AR session
    public func stopARSession() {
        arQueue.async {
            self.arSession?.pause()
            self.isARSessionActive = false
            self.clearHealthDataOverlays()
        }
    }
    
    /// Display health data overlay at specified world position
    public func displayHealthData(_ data: HealthDataOverlay, at position: SIMD3<Float>) async throws {
        try await arQueue.async {
            let anchor = HealthDataAnchor(data: data, position: position)
            self.arSession?.add(anchor: anchor)
            self.healthDataAnchors[anchor.identifier] = anchor
        }
    }
    
    /// Update existing health data overlay
    public func updateHealthData(_ data: HealthDataOverlay, for anchorId: UUID) async throws {
        try await arQueue.async {
            guard let anchor = self.healthDataAnchors[anchorId] else {
                throw ARError(.invalidAnchor)
            }
            
            anchor.updateData(data)
            self.updateVisualization(for: anchor)
        }
    }
    
    /// Clear all health data overlays
    public func clearHealthDataOverlays() {
        arQueue.async {
            self.healthDataAnchors.values.forEach { anchor in
                self.arSession?.remove(anchor: anchor)
            }
            self.healthDataAnchors.removeAll()
            self.healthDataEntities.removeAll()
        }
    }
    
    /// Get current AR session statistics
    public func getSessionStatistics() -> ARSessionStatistics {
        return ARSessionStatistics(
            frameCount: frameCount,
            averageFPS: averageFPS,
            trackingQuality: trackingState.description,
            activeAnchors: healthDataAnchors.count,
            visualizationQuality: visualizationQuality
        )
    }
    
    // MARK: - Private Setup Methods
    
    private func setupARSession() {
        arSession = ARSession()
        arSession?.delegate = self
        
        // Configure AR view
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView?.session = arSession
        arView?.renderOptions = [.disablePersonOcclusion, .disableMotionBlur]
        
        // Enable advanced features
        arView?.environment.sceneUnderstanding.options = [.occlusion, .physics]
        arView?.environment.lighting.intensityExponent = 1.0
    }
    
    private func setupHealthDataMonitoring() {
        // Monitor health data changes
        healthDataManager.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.processHealthDataUpdate(healthData)
            }
            .store(in: &cancellables)
        
        // Monitor AR session state
        $arSessionState
            .sink { [weak self] state in
                self?.handleARSessionStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func createARConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        configuration.isAutoFocusEnabled = true
        
        // Enable advanced features for health visualization
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        return configuration
    }
    
    // MARK: - Health Data Processing
    
    private func processHealthDataUpdate(_ healthData: HealthData) {
        Task {
            let overlay = HealthDataOverlay(
                heartRate: healthData.heartRate,
                bloodPressure: healthData.bloodPressure,
                oxygenSaturation: healthData.oxygenSaturation,
                temperature: healthData.temperature,
                respiratoryRate: healthData.respiratoryRate,
                timestamp: Date()
            )
            
            await updateCurrentHealthData(overlay)
        }
    }
    
    private func updateCurrentHealthData(_ overlay: HealthDataOverlay) async {
        await MainActor.run {
            self.currentHealthData = overlay
        }
        
        // Update existing visualizations
        for (anchorId, _) in healthDataAnchors {
            try? await updateHealthData(overlay, for: anchorId)
        }
    }
    
    // MARK: - Visualization Management
    
    private func updateVisualization(for anchor: HealthDataAnchor) {
        guard let entity = healthDataEntities[anchor.identifier] else { return }
        
        // Update entity with new health data
        if let healthEntity = entity as? HealthDataEntity {
            healthEntity.updateData(anchor.data)
        }
    }
    
    private func createHealthDataEntity(for data: HealthDataOverlay) -> Entity {
        let entity = HealthDataEntity(data: data)
        
        // Add visual components
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        entity.components.set(modelComponent)
        
        // Add text display
        let textEntity = createTextEntity(for: data)
        entity.addChild(textEntity)
        
        return entity
    }
    
    private func createTextEntity(for data: HealthDataOverlay) -> Entity {
        let text = "HR: \(data.heartRate) BPM\nBP: \(data.bloodPressure.systolic)/\(data.bloodPressure.diastolic)"
        let textMesh = MeshResource.generateText(text, extrusionDepth: 0.01, font: .systemFont(ofSize: 0.05))
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textComponent = ModelComponent(mesh: textMesh, materials: [textMaterial])
        
        let textEntity = Entity()
        textEntity.components.set(textComponent)
        textEntity.position = SIMD3<Float>(0, 0.1, 0)
        
        return textEntity
    }
    
    // MARK: - Session State Management
    
    private func handleARSessionStateChange(_ state: ARSession.State) {
        switch state {
        case .running:
            visualizationQuality = .excellent
        case .paused:
            visualizationQuality = .poor
        case .interrupted:
            visualizationQuality = .unknown
        case .notRunning:
            visualizationQuality = .unknown
        @unknown default:
            visualizationQuality = .unknown
        }
    }
}

// MARK: - ARSessionDelegate

@available(iOS 18.0, *)
extension ARHealthDataVisualization: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update tracking state
        trackingState = frame.camera.trackingState
        
        // Performance monitoring
        frameCount += 1
        let currentTime = frame.timestamp
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            averageFPS = 1.0 / deltaTime
        }
        lastFrameTime = currentTime
        
        // Process health data updates
        if let healthData = currentHealthData {
            processRealTimeHealthData(healthData, frame: frame)
        }
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let healthAnchor = anchor as? HealthDataAnchor {
                let entity = createHealthDataEntity(for: healthAnchor.data)
                healthDataEntities[anchor.identifier] = entity
                
                // Add entity to scene
                arView?.scene.addAnchor(AnchorEntity(anchor: anchor))
            }
        }
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            healthDataEntities.removeValue(forKey: anchor.identifier)
            healthDataAnchors.removeValue(forKey: anchor.identifier)
        }
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        lastError = error as? ARError
        isARSessionActive = false
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        arSessionState = .interrupted
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        arSessionState = .running
    }
    
    // MARK: - Real-time Processing
    
    private func processRealTimeHealthData(_ data: HealthDataOverlay, frame: ARFrame) {
        // Process health data in real-time
        // This could include anomaly detection, trend analysis, etc.
        
        // Update visualization based on health data severity
        let severity = calculateHealthDataSeverity(data)
        updateVisualizationIntensity(severity)
    }
    
    private func calculateHealthDataSeverity(_ data: HealthDataOverlay) -> HealthDataSeverity {
        // Simple severity calculation based on heart rate
        if data.heartRate > 100 || data.heartRate < 50 {
            return .critical
        } else if data.heartRate > 90 || data.heartRate < 60 {
            return .warning
        } else {
            return .normal
        }
    }
    
    private func updateVisualizationIntensity(_ severity: HealthDataSeverity) {
        // Update visualization colors and intensity based on severity
        let color: UIColor
        let intensity: Float
        
        switch severity {
        case .normal:
            color = .green
            intensity = 0.5
        case .warning:
            color = .yellow
            intensity = 0.7
        case .critical:
            color = .red
            intensity = 1.0
        }
        
        // Update entity materials
        for entity in healthDataEntities.values {
            if let healthEntity = entity as? HealthDataEntity {
                healthEntity.updateSeverity(severity, color: color, intensity: intensity)
            }
        }
    }
}

// MARK: - Supporting Types

@available(iOS 18.0, *)
public struct HealthDataOverlay {
    public let heartRate: Int
    public let bloodPressure: BloodPressure
    public let oxygenSaturation: Double
    public let temperature: Double
    public let respiratoryRate: Int
    public let timestamp: Date
    
    public init(heartRate: Int, bloodPressure: BloodPressure, oxygenSaturation: Double, temperature: Double, respiratoryRate: Int, timestamp: Date) {
        self.heartRate = heartRate
        self.bloodPressure = bloodPressure
        self.oxygenSaturation = oxygenSaturation
        self.temperature = temperature
        self.respiratoryRate = respiratoryRate
        self.timestamp = timestamp
    }
}

public struct BloodPressure {
    public let systolic: Int
    public let diastolic: Int
    
    public init(systolic: Int, diastolic: Int) {
        self.systolic = systolic
        self.diastolic = diastolic
    }
}

public enum HealthMetricType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case oxygenSaturation = "Oxygen Saturation"
    case temperature = "Temperature"
    case respiratoryRate = "Respiratory Rate"
    case steps = "Steps"
    case sleep = "Sleep"
    case calories = "Calories"
}

public enum VisualizationQuality: String, CaseIterable {
    case unknown = "Unknown"
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
}

public enum HealthDataSeverity: String, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
}

public struct ARSessionStatistics {
    public let frameCount: Int
    public let averageFPS: Double
    public let trackingQuality: String
    public let activeAnchors: Int
    public let visualizationQuality: VisualizationQuality
    
    public init(frameCount: Int, averageFPS: Double, trackingQuality: String, activeAnchors: Int, visualizationQuality: VisualizationQuality) {
        self.frameCount = frameCount
        self.averageFPS = averageFPS
        self.trackingQuality = trackingQuality
        self.activeAnchors = activeAnchors
        self.visualizationQuality = visualizationQuality
    }
}

// MARK: - Custom AR Anchor

@available(iOS 18.0, *)
public class HealthDataAnchor: ARAnchor {
    public var data: HealthDataOverlay
    
    public init(data: HealthDataOverlay, position: SIMD3<Float>) {
        self.data = data
        super.init(name: "HealthData", transform: simd_float4x4(position: position))
    }
    
    public func updateData(_ newData: HealthDataOverlay) {
        self.data = newData
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Custom Entity

@available(iOS 18.0, *)
public class HealthDataEntity: Entity {
    public var data: HealthDataOverlay
    
    public init(data: HealthDataOverlay) {
        self.data = data
        super.init()
    }
    
    public func updateData(_ newData: HealthDataOverlay) {
        self.data = newData
        // Update visual representation
        updateVisualRepresentation()
    }
    
    public func updateSeverity(_ severity: HealthDataSeverity, color: UIColor, intensity: Float) {
        // Update material properties based on severity
        if let modelComponent = components[ModelComponent.self] {
            let newMaterial = SimpleMaterial(color: color, isMetallic: false)
            modelComponent.materials = [newMaterial]
        }
    }
    
    private func updateVisualRepresentation() {
        // Update text and visual elements based on new data
        // This would update the text entity with new health values
    }
}

// MARK: - Extensions

extension ARCamera.TrackingState {
    var description: String {
        switch self {
        case .notAvailable:
            return "Not Available"
        case .limited(let reason):
            switch reason {
            case .initializing:
                return "Initializing"
            case .excessiveMotion:
                return "Excessive Motion"
            case .insufficientFeatures:
                return "Insufficient Features"
            case .relocalizing:
                return "Relocalizing"
            @unknown default:
                return "Limited"
            }
        case .normal:
            return "Normal"
        }
    }
} 