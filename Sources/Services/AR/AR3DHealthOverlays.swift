import Foundation
import ARKit
import RealityKit
import SwiftUI
import Combine
import SceneKit

/// AR 3D Health Overlays System
/// Provides immersive 3D visualizations of health data in augmented reality
@available(iOS 18.0, *)
public class AR3DHealthOverlays: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var activeOverlays: [UUID: Health3DOverlay] = [:]
    @Published public private(set) var overlayTypes: [OverlayType] = []
    @Published public private(set) var isRendering = false
    @Published public private(set) var renderQuality: RenderQuality = .high
    @Published public private(set) var lastError: String?
    
    // MARK: - Private Properties
    private var arView: ARView?
    private var sceneEntities: [UUID: Entity] = [:]
    private var animationControllers: [UUID: AnimationController] = [:]
    private let renderQueue = DispatchQueue(label: "ar.3d.rendering", qos: .userInteractive)
    private var cancellables = Set<AnyCancellable>()
    
    // Performance monitoring
    private var frameTime: TimeInterval = 0
    private var renderStats = RenderStatistics()
    
    // MARK: - Initialization
    public override init() {
        super.init()
        setupOverlayTypes()
    }
    
    // MARK: - Public Methods
    
    /// Create 3D health overlay at specified position
    public func createOverlay(type: OverlayType, at position: SIMD3<Float>, with data: HealthData) async throws -> UUID {
        let overlayId = UUID()
        
        try await renderQueue.async {
            let overlay = Health3DOverlay(
                id: overlayId,
                type: type,
                position: position,
                data: data
            )
            
            let entity = try await self.create3DEntity(for: overlay)
            self.sceneEntities[overlayId] = entity
            self.activeOverlays[overlayId] = overlay
            
            // Add to AR scene
            self.arView?.scene.addAnchor(AnchorEntity(world: position))
            self.arView?.scene.addChild(entity)
            
            // Start animations
            self.startOverlayAnimations(for: overlayId)
        }
        
        return overlayId
    }
    
    /// Update existing 3D overlay with new data
    public func updateOverlay(_ overlayId: UUID, with data: HealthData) async throws {
        guard let overlay = activeOverlays[overlayId] else {
            throw ARError(.invalidAnchor)
        }
        
        try await renderQueue.async {
            let updatedOverlay = Health3DOverlay(
                id: overlayId,
                type: overlay.type,
                position: overlay.position,
                data: data
            )
            
            self.activeOverlays[overlayId] = updatedOverlay
            
            // Update 3D entity
            if let entity = self.sceneEntities[overlayId] {
                try await self.update3DEntity(entity, with: updatedOverlay)
            }
        }
    }
    
    /// Remove 3D overlay
    public func removeOverlay(_ overlayId: UUID) async {
        await renderQueue.async {
            self.sceneEntities.removeValue(forKey: overlayId)
            self.activeOverlays.removeValue(forKey: overlayId)
            self.animationControllers.removeValue(forKey: overlayId)
        }
    }
    
    /// Set render quality
    public func setRenderQuality(_ quality: RenderQuality) {
        renderQuality = quality
        updateRenderSettings()
    }
    
    /// Get rendering statistics
    public func getRenderStatistics() -> RenderStatistics {
        return renderStats
    }
    
    // MARK: - Private Methods
    
    private func setupOverlayTypes() {
        overlayTypes = [
            .heartRate,
            .bloodPressure,
            .oxygenSaturation,
            .temperature,
            .respiratoryRate,
            .cardiovascular,
            .respiratory,
            .neurological,
            .metabolic
        ]
    }
    
    private func create3DEntity(for overlay: Health3DOverlay) async throws -> Entity {
        let entity = Entity()
        
        switch overlay.type {
        case .heartRate:
            try await createHeartRateEntity(entity, overlay: overlay)
        case .bloodPressure:
            try await createBloodPressureEntity(entity, overlay: overlay)
        case .oxygenSaturation:
            try await createOxygenSaturationEntity(entity, overlay: overlay)
        case .temperature:
            try await createTemperatureEntity(entity, overlay: overlay)
        case .respiratoryRate:
            try await createRespiratoryRateEntity(entity, overlay: overlay)
        case .cardiovascular:
            try await createCardiovascularEntity(entity, overlay: overlay)
        case .respiratory:
            try await createRespiratoryEntity(entity, overlay: overlay)
        case .neurological:
            try await createNeurologicalEntity(entity, overlay: overlay)
        case .metabolic:
            try await createMetabolicEntity(entity, overlay: overlay)
        }
        
        return entity
    }
    
    // MARK: - Entity Creation Methods
    
    private func createHeartRateEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create heart-shaped mesh
        let heartMesh = createHeartMesh()
        let heartMaterial = createPulsingMaterial(color: .red, pulseRate: overlay.data.heartRate)
        let heartComponent = ModelComponent(mesh: heartMesh, materials: [heartMaterial])
        entity.components.set(heartComponent)
        
        // Add heart rate text
        let textEntity = createTextEntity(text: "\(overlay.data.heartRate) BPM", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.2, 0)
        entity.addChild(textEntity)
        
        // Add ECG waveform
        let ecgEntity = createECGWaveformEntity(data: overlay.data)
        ecgEntity.position = SIMD3<Float>(0, -0.2, 0)
        entity.addChild(ecgEntity)
    }
    
    private func createBloodPressureEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create blood pressure visualization
        let bpMesh = createBloodPressureMesh()
        let bpMaterial = createBloodPressureMaterial(systolic: overlay.data.bloodPressure.systolic, diastolic: overlay.data.bloodPressure.diastolic)
        let bpComponent = ModelComponent(mesh: bpMesh, materials: [bpMaterial])
        entity.components.set(bpComponent)
        
        // Add BP text
        let textEntity = createTextEntity(text: "\(overlay.data.bloodPressure.systolic)/\(overlay.data.bloodPressure.diastolic)", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
    }
    
    private func createOxygenSaturationEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create oxygen saturation visualization
        let o2Mesh = createOxygenSaturationMesh()
        let o2Material = createOxygenSaturationMaterial(saturation: overlay.data.oxygenSaturation)
        let o2Component = ModelComponent(mesh: o2Mesh, materials: [o2Material])
        entity.components.set(o2Component)
        
        // Add O2 text
        let textEntity = createTextEntity(text: "\(Int(overlay.data.oxygenSaturation))%", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
    }
    
    private func createTemperatureEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create temperature visualization
        let tempMesh = createTemperatureMesh()
        let tempMaterial = createTemperatureMaterial(temperature: overlay.data.temperature)
        let tempComponent = ModelComponent(mesh: tempMesh, materials: [tempMaterial])
        entity.components.set(tempComponent)
        
        // Add temperature text
        let textEntity = createTextEntity(text: "\(overlay.data.temperature, specifier: "%.1f")°F", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
    }
    
    private func createRespiratoryRateEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create respiratory rate visualization
        let respMesh = createRespiratoryMesh()
        let respMaterial = createRespiratoryMaterial(rate: overlay.data.respiratoryRate)
        let respComponent = ModelComponent(mesh: respMesh, materials: [respMaterial])
        entity.components.set(respComponent)
        
        // Add respiratory rate text
        let textEntity = createTextEntity(text: "\(overlay.data.respiratoryRate) RPM", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
    }
    
    private func createCardiovascularEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create comprehensive cardiovascular visualization
        let cardioMesh = createCardiovascularMesh()
        let cardioMaterial = createCardiovascularMaterial(data: overlay.data)
        let cardioComponent = ModelComponent(mesh: cardioMesh, materials: [cardioMaterial])
        entity.components.set(cardioComponent)
        
        // Add cardiovascular metrics
        let metricsEntity = createCardiovascularMetricsEntity(data: overlay.data)
        metricsEntity.position = SIMD3<Float>(0, 0.3, 0)
        entity.addChild(metricsEntity)
    }
    
    private func createRespiratoryEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create respiratory system visualization
        let respMesh = createRespiratorySystemMesh()
        let respMaterial = createRespiratorySystemMaterial(data: overlay.data)
        let respComponent = ModelComponent(mesh: respMesh, materials: [respMaterial])
        entity.components.set(respComponent)
        
        // Add respiratory metrics
        let metricsEntity = createRespiratoryMetricsEntity(data: overlay.data)
        metricsEntity.position = SIMD3<Float>(0, 0.3, 0)
        entity.addChild(metricsEntity)
    }
    
    private func createNeurologicalEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create neurological system visualization
        let neuroMesh = createNeurologicalMesh()
        let neuroMaterial = createNeurologicalMaterial(data: overlay.data)
        let neuroComponent = ModelComponent(mesh: neuroMesh, materials: [neuroMaterial])
        entity.components.set(neuroComponent)
        
        // Add neurological metrics
        let metricsEntity = createNeurologicalMetricsEntity(data: overlay.data)
        metricsEntity.position = SIMD3<Float>(0, 0.3, 0)
        entity.addChild(metricsEntity)
    }
    
    private func createMetabolicEntity(_ entity: Entity, overlay: Health3DOverlay) async throws {
        // Create metabolic system visualization
        let metabMesh = createMetabolicMesh()
        let metabMaterial = createMetabolicMaterial(data: overlay.data)
        let metabComponent = ModelComponent(mesh: metabMesh, materials: [metabMaterial])
        entity.components.set(metabComponent)
        
        // Add metabolic metrics
        let metricsEntity = createMetabolicMetricsEntity(data: overlay.data)
        metricsEntity.position = SIMD3<Float>(0, 0.3, 0)
        entity.addChild(metricsEntity)
    }
    
    // MARK: - Mesh Creation Methods
    
    private func createHeartMesh() -> MeshResource {
        // Create heart-shaped mesh using custom geometry
        let heartVertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0.5, 0),    // Top point
            SIMD3<Float>(-0.3, 0.2, 0), // Left curve
            SIMD3<Float>(-0.2, -0.3, 0), // Left bottom
            SIMD3<Float>(0, -0.4, 0),   // Bottom point
            SIMD3<Float>(0.2, -0.3, 0), // Right bottom
            SIMD3<Float>(0.3, 0.2, 0),  // Right curve
        ]
        
        let heartIndices: [UInt32] = [
            0, 1, 2, 3, 4, 5, 0
        ]
        
        let descriptor = MeshDescriptor(name: "Heart")
        descriptor.positions = MeshBuffer(heartVertices)
        descriptor.primitives = .triangles(heartIndices)
        
        return try! MeshResource.generate(from: [descriptor])
    }
    
    private func createBloodPressureMesh() -> MeshResource {
        // Create blood pressure visualization mesh
        return MeshResource.generateBox(size: 0.2)
    }
    
    private func createOxygenSaturationMesh() -> MeshResource {
        // Create oxygen saturation visualization mesh
        return MeshResource.generateSphere(radius: 0.1)
    }
    
    private func createTemperatureMesh() -> MeshResource {
        // Create temperature visualization mesh
        return MeshResource.generateCylinder(height: 0.2, radius: 0.05)
    }
    
    private func createRespiratoryMesh() -> MeshResource {
        // Create respiratory rate visualization mesh
        return MeshResource.generateBox(size: 0.15)
    }
    
    private func createCardiovascularMesh() -> MeshResource {
        // Create comprehensive cardiovascular mesh
        return MeshResource.generateBox(size: 0.3)
    }
    
    private func createRespiratorySystemMesh() -> MeshResource {
        // Create respiratory system mesh
        return MeshResource.generateBox(size: 0.25)
    }
    
    private func createNeurologicalMesh() -> MeshResource {
        // Create neurological system mesh
        return MeshResource.generateSphere(radius: 0.15)
    }
    
    private func createMetabolicMesh() -> MeshResource {
        // Create metabolic system mesh
        return MeshResource.generateBox(size: 0.2)
    }
    
    // MARK: - Material Creation Methods
    
    private func createPulsingMaterial(color: UIColor, pulseRate: Int) -> Material {
        let material = SimpleMaterial(color: color, isMetallic: false)
        material.baseColor = MaterialColorParameter.color(color)
        
        // Add pulsing animation
        let pulseAnimation = AnimationResource.generate(with: pulseRate)
        material.roughness = MaterialScalarParameter.animation(pulseAnimation)
        
        return material
    }
    
    private func createBloodPressureMaterial(systolic: Int, diastolic: Int) -> Material {
        let color = getBloodPressureColor(systolic: systolic, diastolic: diastolic)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createOxygenSaturationMaterial(saturation: Double) -> Material {
        let color = getOxygenSaturationColor(saturation: saturation)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createTemperatureMaterial(temperature: Double) -> Material {
        let color = getTemperatureColor(temperature: temperature)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createRespiratoryMaterial(rate: Int) -> Material {
        let color = getRespiratoryRateColor(rate: rate)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createCardiovascularMaterial(data: HealthData) -> Material {
        let color = getCardiovascularColor(data: data)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createRespiratorySystemMaterial(data: HealthData) -> Material {
        let color = getRespiratorySystemColor(data: data)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createNeurologicalMaterial(data: HealthData) -> Material {
        let color = getNeurologicalColor(data: data)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func createMetabolicMaterial(data: HealthData) -> Material {
        let color = getMetabolicColor(data: data)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    // MARK: - Helper Methods
    
    private func createTextEntity(text: String, color: UIColor) -> Entity {
        let textMesh = MeshResource.generateText(text, extrusionDepth: 0.01, font: .systemFont(ofSize: 0.05))
        let textMaterial = SimpleMaterial(color: color, isMetallic: false)
        let textComponent = ModelComponent(mesh: textMesh, materials: [textMaterial])
        
        let textEntity = Entity()
        textEntity.components.set(textComponent)
        
        return textEntity
    }
    
    private func createECGWaveformEntity(data: HealthData) -> Entity {
        // Create ECG waveform visualization
        let ecgMesh = createECGWaveformMesh(data: data)
        let ecgMaterial = SimpleMaterial(color: .green, isMetallic: false)
        let ecgComponent = ModelComponent(mesh: ecgMesh, materials: [ecgMaterial])
        
        let ecgEntity = Entity()
        ecgEntity.components.set(ecgComponent)
        
        return ecgEntity
    }
    
    private func createECGWaveformMesh(data: HealthData) -> MeshResource {
        // Generate ECG waveform mesh based on heart rate
        let points = generateECGPoints(heartRate: data.heartRate)
        
        let descriptor = MeshDescriptor(name: "ECG")
        descriptor.positions = MeshBuffer(points)
        descriptor.primitives = .lineStrip(Array(0..<UInt32(points.count)))
        
        return try! MeshResource.generate(from: [descriptor])
    }
    
    private func generateECGPoints(heartRate: Int) -> [SIMD3<Float>] {
        // Generate ECG waveform points
        var points: [SIMD3<Float>] = []
        let cycleLength = 60.0 / Double(heartRate)
        let sampleRate = 100.0 // 100 Hz
        
        for i in 0..<Int(cycleLength * sampleRate) {
            let t = Double(i) / sampleRate
            let x = Float(t * 0.2) // Scale time
            let y = Float(sin(t * 2 * .pi * Double(heartRate) / 60.0) * 0.05) // ECG-like wave
            points.append(SIMD3<Float>(x, y, 0))
        }
        
        return points
    }
    
    // MARK: - Color Helper Methods
    
    private func getBloodPressureColor(systolic: Int, diastolic: Int) -> UIColor {
        if systolic >= 180 || diastolic >= 110 {
            return .red
        } else if systolic >= 140 || diastolic >= 90 {
            return .orange
        } else if systolic >= 120 || diastolic >= 80 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func getOxygenSaturationColor(saturation: Double) -> UIColor {
        if saturation < 90 {
            return .red
        } else if saturation < 95 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getTemperatureColor(temperature: Double) -> UIColor {
        if temperature > 100.4 {
            return .red
        } else if temperature > 99.5 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getRespiratoryRateColor(rate: Int) -> UIColor {
        if rate > 20 || rate < 12 {
            return .red
        } else if rate > 16 || rate < 14 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getCardiovascularColor(data: HealthData) -> UIColor {
        // Complex cardiovascular health assessment
        let riskScore = calculateCardiovascularRisk(data: data)
        
        if riskScore > 0.7 {
            return .red
        } else if riskScore > 0.4 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getRespiratorySystemColor(data: HealthData) -> UIColor {
        // Respiratory system health assessment
        let riskScore = calculateRespiratoryRisk(data: data)
        
        if riskScore > 0.7 {
            return .red
        } else if riskScore > 0.4 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getNeurologicalColor(data: HealthData) -> UIColor {
        // Neurological health assessment
        let riskScore = calculateNeurologicalRisk(data: data)
        
        if riskScore > 0.7 {
            return .red
        } else if riskScore > 0.4 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getMetabolicColor(data: HealthData) -> UIColor {
        // Metabolic health assessment
        let riskScore = calculateMetabolicRisk(data: data)
        
        if riskScore > 0.7 {
            return .red
        } else if riskScore > 0.4 {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Risk Calculation Methods
    
    private func calculateCardiovascularRisk(data: HealthData) -> Double {
        var risk = 0.0
        
        // Heart rate risk
        if data.heartRate > 100 || data.heartRate < 50 {
            risk += 0.3
        } else if data.heartRate > 90 || data.heartRate < 60 {
            risk += 0.1
        }
        
        // Blood pressure risk
        if data.bloodPressure.systolic >= 140 || data.bloodPressure.diastolic >= 90 {
            risk += 0.4
        } else if data.bloodPressure.systolic >= 120 || data.bloodPressure.diastolic >= 80 {
            risk += 0.2
        }
        
        return min(risk, 1.0)
    }
    
    private func calculateRespiratoryRisk(data: HealthData) -> Double {
        var risk = 0.0
        
        // Respiratory rate risk
        if data.respiratoryRate > 20 || data.respiratoryRate < 12 {
            risk += 0.4
        } else if data.respiratoryRate > 16 || data.respiratoryRate < 14 {
            risk += 0.2
        }
        
        // Oxygen saturation risk
        if data.oxygenSaturation < 90 {
            risk += 0.6
        } else if data.oxygenSaturation < 95 {
            risk += 0.3
        }
        
        return min(risk, 1.0)
    }
    
    private func calculateNeurologicalRisk(data: HealthData) -> Double {
        // Placeholder for neurological risk calculation
        // Would include cognitive metrics, brain activity, etc.
        return 0.1
    }
    
    private func calculateMetabolicRisk(data: HealthData) -> Double {
        // Placeholder for metabolic risk calculation
        // Would include glucose, cholesterol, etc.
        return 0.1
    }
    
    // MARK: - Animation Methods
    
    private func startOverlayAnimations(for overlayId: UUID) {
        guard let overlay = activeOverlays[overlayId],
              let entity = sceneEntities[overlayId] else { return }
        
        let controller = AnimationController(entity: entity, overlay: overlay)
        animationControllers[overlayId] = controller
        controller.startAnimations()
    }
    
    private func update3DEntity(_ entity: Entity, with overlay: Health3DOverlay) async throws {
        // Update entity with new data
        // This would update materials, animations, etc.
    }
    
    private func updateRenderSettings() {
        // Update render quality settings
        switch renderQuality {
        case .low:
            arView?.renderOptions.insert(.disableMotionBlur)
        case .medium:
            arView?.renderOptions.remove(.disableMotionBlur)
        case .high:
            arView?.renderOptions.remove(.disableMotionBlur)
            arView?.environment.lighting.intensityExponent = 1.0
        }
    }
    
    // MARK: - Metrics Entity Creation
    
    private func createCardiovascularMetricsEntity(data: HealthData) -> Entity {
        let metricsEntity = Entity()
        
        let heartRateText = createTextEntity(text: "HR: \(data.heartRate) BPM", color: .white)
        heartRateText.position = SIMD3<Float>(-0.1, 0.1, 0)
        metricsEntity.addChild(heartRateText)
        
        let bpText = createTextEntity(text: "BP: \(data.bloodPressure.systolic)/\(data.bloodPressure.diastolic)", color: .white)
        bpText.position = SIMD3<Float>(0.1, 0.1, 0)
        metricsEntity.addChild(bpText)
        
        return metricsEntity
    }
    
    private func createRespiratoryMetricsEntity(data: HealthData) -> Entity {
        let metricsEntity = Entity()
        
        let respText = createTextEntity(text: "RR: \(data.respiratoryRate) RPM", color: .white)
        respText.position = SIMD3<Float>(-0.1, 0.1, 0)
        metricsEntity.addChild(respText)
        
        let o2Text = createTextEntity(text: "O2: \(Int(data.oxygenSaturation))%", color: .white)
        o2Text.position = SIMD3<Float>(0.1, 0.1, 0)
        metricsEntity.addChild(o2Text)
        
        return metricsEntity
    }
    
    private func createNeurologicalMetricsEntity(data: HealthData) -> Entity {
        let metricsEntity = Entity()
        
        // Placeholder for neurological metrics
        let neuroText = createTextEntity(text: "Neuro: Normal", color: .white)
        metricsEntity.addChild(neuroText)
        
        return metricsEntity
    }
    
    private func createMetabolicMetricsEntity(data: HealthData) -> Entity {
        let metricsEntity = Entity()
        
        // Placeholder for metabolic metrics
        let metabText = createTextEntity(text: "Metabolic: Normal", color: .white)
        metricsEntity.addChild(metabText)
        
        return metricsEntity
    }
}

// MARK: - Supporting Types

@available(iOS 18.0, *)
public struct Health3DOverlay {
    public let id: UUID
    public let type: OverlayType
    public let position: SIMD3<Float>
    public let data: HealthData
    
    public init(id: UUID, type: OverlayType, position: SIMD3<Float>, data: HealthData) {
        self.id = id
        self.type = type
        self.position = position
        self.data = data
    }
}

public enum OverlayType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case oxygenSaturation = "Oxygen Saturation"
    case temperature = "Temperature"
    case respiratoryRate = "Respiratory Rate"
    case cardiovascular = "Cardiovascular"
    case respiratory = "Respiratory"
    case neurological = "Neurological"
    case metabolic = "Metabolic"
}

public enum RenderQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

public struct RenderStatistics {
    public let frameCount: Int
    public let averageFrameTime: TimeInterval
    public let renderQuality: RenderQuality
    public let activeOverlays: Int
    
    public init(frameCount: Int = 0, averageFrameTime: TimeInterval = 0, renderQuality: RenderQuality = .high, activeOverlays: Int = 0) {
        self.frameCount = frameCount
        self.averageFrameTime = averageFrameTime
        self.renderQuality = renderQuality
        self.activeOverlays = activeOverlays
    }
}

// MARK: - Animation Controller

@available(iOS 18.0, *)
private class AnimationController {
    private let entity: Entity
    private let overlay: Health3DOverlay
    private var animationTimer: Timer?
    
    init(entity: Entity, overlay: Health3DOverlay) {
        self.entity = entity
        self.overlay = overlay
    }
    
    func startAnimations() {
        // Start pulsing animation for heart rate
        if overlay.type == .heartRate {
            startPulsingAnimation()
        }
        
        // Start breathing animation for respiratory
        if overlay.type == .respiratoryRate {
            startBreathingAnimation()
        }
    }
    
    private func startPulsingAnimation() {
        let pulseRate = Double(overlay.data.heartRate) / 60.0 // Beats per second
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / pulseRate, repeats: true) { _ in
            // Scale animation
            let scale = Float(1.0 + 0.2 * sin(Date().timeIntervalSince1970 * 2 * .pi * pulseRate))
            self.entity.scale = SIMD3<Float>(scale, scale, scale)
        }
    }
    
    private func startBreathingAnimation() {
        let breathRate = Double(overlay.data.respiratoryRate) / 60.0 // Breaths per second
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / breathRate, repeats: true) { _ in
            // Breathing animation
            let scale = Float(1.0 + 0.1 * sin(Date().timeIntervalSince1970 * 2 * .pi * breathRate))
            self.entity.scale = SIMD3<Float>(scale, scale, scale)
        }
    }
    
    func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Health Data Structure

public struct HealthData {
    public let heartRate: Int
    public let bloodPressure: BloodPressure
    public let oxygenSaturation: Double
    public let temperature: Double
    public let respiratoryRate: Int
    
    public init(heartRate: Int, bloodPressure: BloodPressure, oxygenSaturation: Double, temperature: Double, respiratoryRate: Int) {
        self.heartRate = heartRate
        self.bloodPressure = bloodPressure
        self.oxygenSaturation = oxygenSaturation
        self.temperature = temperature
        self.respiratoryRate = respiratoryRate
    }
} 