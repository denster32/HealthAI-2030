import Foundation
import ARKit
import RealityKit
import SwiftUI
import Combine
import HealthKit

/// AR Health Monitoring System
/// Provides real-time health monitoring displays in augmented reality
@available(iOS 18.0, *)
public class ARHealthMonitoring: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isMonitoringActive = false
    @Published public private(set) var currentVitals: VitalSigns?
    @Published public private(set) var healthAlerts: [HealthAlert] = []
    @Published public private(set) var monitoringStatus: MonitoringStatus = .inactive
    @Published public private(set) var lastUpdate: Date?
    @Published public private(set) var monitoringQuality: MonitoringQuality = .unknown
    @Published public private(set) var activeMonitors: [MonitorType: Bool] = [:]
    
    // MARK: - Private Properties
    private var arSession: ARSession?
    private var arView: ARView?
    private let healthStore = HKHealthStore()
    private let healthDataManager: HealthDataManager
    private var cancellables = Set<AnyCancellable>()
    private let monitoringQueue = DispatchQueue(label: "ar.health.monitoring", qos: .userInteractive)
    
    // Monitoring components
    private var vitalSignsEntities: [UUID: Entity] = [:]
    private var alertEntities: [UUID: Entity] = [:]
    private var trendEntities: [UUID: Entity] = [:]
    private var monitoringAnchors: [UUID: ARAnchor] = [:]
    
    // Data buffers for trend analysis
    private var heartRateBuffer: [Double] = []
    private var bloodPressureBuffer: [BloodPressure] = []
    private var oxygenBuffer: [Double] = []
    private var temperatureBuffer: [Double] = []
    private var respiratoryBuffer: [Double] = []
    
    // Alert thresholds
    private let alertThresholds = AlertThresholds()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager) {
        self.healthDataManager = healthDataManager
        super.init()
        setupMonitoring()
        setupAlertThresholds()
    }
    
    // MARK: - Public Methods
    
    /// Start AR health monitoring
    public func startMonitoring() async throws {
        guard ARSession.isSupported else {
            throw ARError(.unsupportedConfiguration)
        }
        
        try await monitoringQueue.async {
            self.setupARSession()
            self.arSession?.run(self.createMonitoringConfiguration())
            self.isMonitoringActive = true
            self.monitoringStatus = .active
        }
    }
    
    /// Stop AR health monitoring
    public func stopMonitoring() {
        monitoringQueue.async {
            self.arSession?.pause()
            self.isMonitoringActive = false
            self.monitoringStatus = .inactive
            self.clearAllDisplays()
        }
    }
    
    /// Enable specific monitor type
    public func enableMonitor(_ type: MonitorType) async {
        await monitoringQueue.async {
            self.activeMonitors[type] = true
            self.createMonitorDisplay(for: type)
        }
    }
    
    /// Disable specific monitor type
    public func disableMonitor(_ type: MonitorType) async {
        await monitoringQueue.async {
            self.activeMonitors[type] = false
            self.removeMonitorDisplay(for: type)
        }
    }
    
    /// Display vital signs at specified position
    public func displayVitalSigns(_ vitals: VitalSigns, at position: SIMD3<Float>) async throws -> UUID {
        let monitorId = UUID()
        
        try await monitoringQueue.async {
            let anchor = VitalSignsAnchor(vitals: vitals, position: position)
            self.arSession?.add(anchor: anchor)
            self.monitoringAnchors[monitorId] = anchor
            
            let entity = try await self.createVitalSignsEntity(vitals: vitals)
            self.vitalSignsEntities[monitorId] = entity
            
            // Add to AR scene
            self.arView?.scene.addAnchor(AnchorEntity(anchor: anchor))
            self.arView?.scene.addChild(entity)
        }
        
        return monitorId
    }
    
    /// Update vital signs display
    public func updateVitalSigns(_ vitals: VitalSigns, for monitorId: UUID) async throws {
        guard let anchor = monitoringAnchors[monitorId] as? VitalSignsAnchor else {
            throw ARError(.invalidAnchor)
        }
        
        try await monitoringQueue.async {
            anchor.updateVitals(vitals)
            
            if let entity = self.vitalSignsEntities[monitorId] {
                try await self.updateVitalSignsEntity(entity, with: vitals)
            }
            
            // Check for alerts
            self.checkForAlerts(vitals: vitals)
            
            // Update trends
            self.updateTrendAnalysis(vitals: vitals)
        }
    }
    
    /// Get monitoring statistics
    public func getMonitoringStatistics() -> MonitoringStatistics {
        return MonitoringStatistics(
            activeMonitors: activeMonitors.filter { $0.value }.count,
            totalAlerts: healthAlerts.count,
            monitoringQuality: monitoringQuality,
            lastUpdate: lastUpdate,
            dataPointsCollected: heartRateBuffer.count
        )
    }
    
    /// Clear all monitoring displays
    public func clearAllDisplays() {
        monitoringQueue.async {
            self.monitoringAnchors.values.forEach { anchor in
                self.arSession?.remove(anchor: anchor)
            }
            self.monitoringAnchors.removeAll()
            self.vitalSignsEntities.removeAll()
            self.alertEntities.removeAll()
            self.trendEntities.removeAll()
        }
    }
    
    // MARK: - Private Setup Methods
    
    private func setupMonitoring() {
        // Initialize monitor types
        MonitorType.allCases.forEach { type in
            activeMonitors[type] = false
        }
        
        // Setup health data monitoring
        healthDataManager.healthDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] healthData in
                self?.processHealthDataUpdate(healthData)
            }
            .store(in: &cancellables)
        
        // Setup monitoring status updates
        $monitoringStatus
            .sink { [weak self] status in
                self?.handleMonitoringStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func setupAlertThresholds() {
        // Configure alert thresholds for different vital signs
        alertThresholds.heartRate = HeartRateThresholds(
            low: 50,
            high: 100,
            criticalLow: 40,
            criticalHigh: 120
        )
        
        alertThresholds.bloodPressure = BloodPressureThresholds(
            systolicLow: 90,
            systolicHigh: 140,
            diastolicLow: 60,
            diastolicHigh: 90,
            criticalSystolicLow: 80,
            criticalSystolicHigh: 180,
            criticalDiastolicLow: 50,
            criticalDiastolicHigh: 110
        )
        
        alertThresholds.oxygenSaturation = OxygenThresholds(
            low: 95,
            critical: 90
        )
        
        alertThresholds.temperature = TemperatureThresholds(
            low: 97.0,
            high: 99.5,
            criticalLow: 95.0,
            criticalHigh: 100.4
        )
        
        alertThresholds.respiratoryRate = RespiratoryThresholds(
            low: 12,
            high: 20,
            criticalLow: 8,
            criticalHigh: 25
        )
    }
    
    private func setupARSession() {
        arSession = ARSession()
        arSession?.delegate = self
        
        // Configure AR view for monitoring
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView?.session = arSession
        arView?.renderOptions = [.disablePersonOcclusion]
        
        // Enable advanced features for monitoring
        arView?.environment.sceneUnderstanding.options = [.occlusion]
        arView?.environment.lighting.intensityExponent = 1.2
    }
    
    private func createMonitoringConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        configuration.isAutoFocusEnabled = true
        
        // Enable advanced features for health monitoring
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
            let vitals = VitalSigns(
                heartRate: healthData.heartRate,
                bloodPressure: healthData.bloodPressure,
                oxygenSaturation: healthData.oxygenSaturation,
                temperature: healthData.temperature,
                respiratoryRate: healthData.respiratoryRate,
                timestamp: Date()
            )
            
            await updateCurrentVitals(vitals)
            
            // Update existing displays
            for (monitorId, _) in monitoringAnchors {
                try? await updateVitalSigns(vitals, for: monitorId)
            }
        }
    }
    
    private func updateCurrentVitals(_ vitals: VitalSigns) async {
        await MainActor.run {
            self.currentVitals = vitals
            self.lastUpdate = vitals.timestamp
        }
        
        // Update data buffers
        updateDataBuffers(vitals: vitals)
    }
    
    private func updateDataBuffers(vitals: VitalSigns) {
        // Update circular buffers for trend analysis
        heartRateBuffer.append(Double(vitals.heartRate))
        bloodPressureBuffer.append(vitals.bloodPressure)
        oxygenBuffer.append(vitals.oxygenSaturation)
        temperatureBuffer.append(vitals.temperature)
        respiratoryBuffer.append(Double(vitals.respiratoryRate))
        
        // Keep buffer size manageable
        let maxBufferSize = 100
        if heartRateBuffer.count > maxBufferSize {
            heartRateBuffer.removeFirst()
            bloodPressureBuffer.removeFirst()
            oxygenBuffer.removeFirst()
            temperatureBuffer.removeFirst()
            respiratoryBuffer.removeFirst()
        }
    }
    
    // MARK: - Entity Creation Methods
    
    private func createVitalSignsEntity(vitals: VitalSigns) async throws -> Entity {
        let entity = Entity()
        
        // Create main vital signs display
        let mainDisplay = createMainVitalSignsDisplay(vitals: vitals)
        entity.addChild(mainDisplay)
        
        // Create trend indicators
        let trendDisplay = createTrendDisplay(vitals: vitals)
        trendDisplay.position = SIMD3<Float>(0, -0.3, 0)
        entity.addChild(trendDisplay)
        
        // Create alert indicators if needed
        if hasAlerts(vitals: vitals) {
            let alertDisplay = createAlertDisplay(vitals: vitals)
            alertDisplay.position = SIMD3<Float>(0, 0.3, 0)
            entity.addChild(alertDisplay)
        }
        
        return entity
    }
    
    private func createMainVitalSignsDisplay(vitals: VitalSigns) -> Entity {
        let displayEntity = Entity()
        
        // Heart rate display
        let hrEntity = createHeartRateDisplay(heartRate: vitals.heartRate)
        hrEntity.position = SIMD3<Float>(-0.2, 0.1, 0)
        displayEntity.addChild(hrEntity)
        
        // Blood pressure display
        let bpEntity = createBloodPressureDisplay(bloodPressure: vitals.bloodPressure)
        bpEntity.position = SIMD3<Float>(0, 0.1, 0)
        displayEntity.addChild(bpEntity)
        
        // Oxygen saturation display
        let o2Entity = createOxygenDisplay(oxygen: vitals.oxygenSaturation)
        o2Entity.position = SIMD3<Float>(0.2, 0.1, 0)
        displayEntity.addChild(o2Entity)
        
        // Temperature display
        let tempEntity = createTemperatureDisplay(temperature: vitals.temperature)
        tempEntity.position = SIMD3<Float>(-0.1, -0.1, 0)
        displayEntity.addChild(tempEntity)
        
        // Respiratory rate display
        let respEntity = createRespiratoryDisplay(respiratoryRate: vitals.respiratoryRate)
        respEntity.position = SIMD3<Float>(0.1, -0.1, 0)
        displayEntity.addChild(respEntity)
        
        return displayEntity
    }
    
    private func createHeartRateDisplay(heartRate: Int) -> Entity {
        let entity = Entity()
        
        // Create heart icon
        let heartMesh = createHeartMesh()
        let heartColor = getHeartRateColor(heartRate: heartRate)
        let heartMaterial = SimpleMaterial(color: heartColor, isMetallic: false)
        let heartComponent = ModelComponent(mesh: heartMesh, materials: [heartMaterial])
        entity.components.set(heartComponent)
        
        // Add heart rate text
        let textEntity = createTextEntity(text: "\(heartRate)", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
        
        // Add BPM label
        let labelEntity = createTextEntity(text: "BPM", color: .gray)
        labelEntity.position = SIMD3<Float>(0, -0.15, 0)
        entity.addChild(labelEntity)
        
        return entity
    }
    
    private func createBloodPressureDisplay(bloodPressure: BloodPressure) -> Entity {
        let entity = Entity()
        
        // Create BP visualization
        let bpMesh = createBloodPressureMesh()
        let bpColor = getBloodPressureColor(bloodPressure: bloodPressure)
        let bpMaterial = SimpleMaterial(color: bpColor, isMetallic: false)
        let bpComponent = ModelComponent(mesh: bpMesh, materials: [bpMaterial])
        entity.components.set(bpComponent)
        
        // Add BP text
        let textEntity = createTextEntity(text: "\(bloodPressure.systolic)/\(bloodPressure.diastolic)", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
        
        // Add mmHg label
        let labelEntity = createTextEntity(text: "mmHg", color: .gray)
        labelEntity.position = SIMD3<Float>(0, -0.15, 0)
        entity.addChild(labelEntity)
        
        return entity
    }
    
    private func createOxygenDisplay(oxygen: Double) -> Entity {
        let entity = Entity()
        
        // Create oxygen visualization
        let o2Mesh = createOxygenMesh()
        let o2Color = getOxygenColor(oxygen: oxygen)
        let o2Material = SimpleMaterial(color: o2Color, isMetallic: false)
        let o2Component = ModelComponent(mesh: o2Mesh, materials: [o2Material])
        entity.components.set(o2Component)
        
        // Add oxygen text
        let textEntity = createTextEntity(text: "\(Int(oxygen))%", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
        
        // Add O2 label
        let labelEntity = createTextEntity(text: "O2", color: .gray)
        labelEntity.position = SIMD3<Float>(0, -0.15, 0)
        entity.addChild(labelEntity)
        
        return entity
    }
    
    private func createTemperatureDisplay(temperature: Double) -> Entity {
        let entity = Entity()
        
        // Create temperature visualization
        let tempMesh = createTemperatureMesh()
        let tempColor = getTemperatureColor(temperature: temperature)
        let tempMaterial = SimpleMaterial(color: tempColor, isMetallic: false)
        let tempComponent = ModelComponent(mesh: tempMesh, materials: [tempMaterial])
        entity.components.set(tempComponent)
        
        // Add temperature text
        let textEntity = createTextEntity(text: "\(temperature, specifier: "%.1f")°", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
        
        // Add F label
        let labelEntity = createTextEntity(text: "F", color: .gray)
        labelEntity.position = SIMD3<Float>(0, -0.15, 0)
        entity.addChild(labelEntity)
        
        return entity
    }
    
    private func createRespiratoryDisplay(respiratoryRate: Int) -> Entity {
        let entity = Entity()
        
        // Create respiratory visualization
        let respMesh = createRespiratoryMesh()
        let respColor = getRespiratoryColor(respiratoryRate: respiratoryRate)
        let respMaterial = SimpleMaterial(color: respColor, isMetallic: false)
        let respComponent = ModelComponent(mesh: respMesh, materials: [respMaterial])
        entity.components.set(respComponent)
        
        // Add respiratory rate text
        let textEntity = createTextEntity(text: "\(respiratoryRate)", color: .white)
        textEntity.position = SIMD3<Float>(0, 0.15, 0)
        entity.addChild(textEntity)
        
        // Add RPM label
        let labelEntity = createTextEntity(text: "RPM", color: .gray)
        labelEntity.position = SIMD3<Float>(0, -0.15, 0)
        entity.addChild(labelEntity)
        
        return entity
    }
    
    private func createTrendDisplay(vitals: VitalSigns) -> Entity {
        let entity = Entity()
        
        // Create trend indicators based on historical data
        let trends = calculateTrends(vitals: vitals)
        
        for (index, trend) in trends.enumerated() {
            let trendEntity = createTrendIndicator(trend: trend)
            trendEntity.position = SIMD3<Float>(Float(index - 2) * 0.1, 0, 0)
            entity.addChild(trendEntity)
        }
        
        return entity
    }
    
    private func createAlertDisplay(vitals: VitalSigns) -> Entity {
        let entity = Entity()
        
        // Create alert indicators
        let alerts = getActiveAlerts(vitals: vitals)
        
        for (index, alert) in alerts.enumerated() {
            let alertEntity = createAlertIndicator(alert: alert)
            alertEntity.position = SIMD3<Float>(Float(index - alerts.count/2) * 0.15, 0, 0)
            entity.addChild(alertEntity)
        }
        
        return entity
    }
    
    // MARK: - Helper Methods
    
    private func createTextEntity(text: String, color: UIColor) -> Entity {
        let textMesh = MeshResource.generateText(text, extrusionDepth: 0.01, font: .systemFont(ofSize: 0.03))
        let textMaterial = SimpleMaterial(color: color, isMetallic: false)
        let textComponent = ModelComponent(mesh: textMesh, materials: [textMaterial])
        
        let textEntity = Entity()
        textEntity.components.set(textComponent)
        
        return textEntity
    }
    
    private func createHeartMesh() -> MeshResource {
        // Create heart-shaped mesh
        let heartVertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0.3, 0),
            SIMD3<Float>(-0.2, 0.1, 0),
            SIMD3<Float>(-0.1, -0.2, 0),
            SIMD3<Float>(0, -0.25, 0),
            SIMD3<Float>(0.1, -0.2, 0),
            SIMD3<Float>(0.2, 0.1, 0),
        ]
        
        let heartIndices: [UInt32] = [0, 1, 2, 3, 4, 5, 0]
        
        let descriptor = MeshDescriptor(name: "Heart")
        descriptor.positions = MeshBuffer(heartVertices)
        descriptor.primitives = .triangles(heartIndices)
        
        return try! MeshResource.generate(from: [descriptor])
    }
    
    private func createBloodPressureMesh() -> MeshResource {
        return MeshResource.generateBox(size: 0.1)
    }
    
    private func createOxygenMesh() -> MeshResource {
        return MeshResource.generateSphere(radius: 0.05)
    }
    
    private func createTemperatureMesh() -> MeshResource {
        return MeshResource.generateCylinder(height: 0.1, radius: 0.03)
    }
    
    private func createRespiratoryMesh() -> MeshResource {
        return MeshResource.generateBox(size: 0.08)
    }
    
    // MARK: - Color Helper Methods
    
    private func getHeartRateColor(heartRate: Int) -> UIColor {
        if heartRate > 100 || heartRate < 50 {
            return .red
        } else if heartRate > 90 || heartRate < 60 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getBloodPressureColor(bloodPressure: BloodPressure) -> UIColor {
        if bloodPressure.systolic >= 140 || bloodPressure.diastolic >= 90 {
            return .red
        } else if bloodPressure.systolic >= 120 || bloodPressure.diastolic >= 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getOxygenColor(oxygen: Double) -> UIColor {
        if oxygen < 90 {
            return .red
        } else if oxygen < 95 {
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
    
    private func getRespiratoryColor(respiratoryRate: Int) -> UIColor {
        if respiratoryRate > 20 || respiratoryRate < 12 {
            return .red
        } else if respiratoryRate > 16 || respiratoryRate < 14 {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Alert Methods
    
    private func checkForAlerts(vitals: VitalSigns) {
        let alerts = generateAlerts(vitals: vitals)
        
        Task { @MainActor in
            self.healthAlerts = alerts
        }
    }
    
    private func generateAlerts(vitals: VitalSigns) -> [HealthAlert] {
        var alerts: [HealthAlert] = []
        
        // Heart rate alerts
        if vitals.heartRate > alertThresholds.heartRate.criticalHigh {
            alerts.append(HealthAlert(type: .heartRate, severity: .critical, message: "Critical high heart rate: \(vitals.heartRate) BPM"))
        } else if vitals.heartRate > alertThresholds.heartRate.high {
            alerts.append(HealthAlert(type: .heartRate, severity: .warning, message: "Elevated heart rate: \(vitals.heartRate) BPM"))
        } else if vitals.heartRate < alertThresholds.heartRate.criticalLow {
            alerts.append(HealthAlert(type: .heartRate, severity: .critical, message: "Critical low heart rate: \(vitals.heartRate) BPM"))
        } else if vitals.heartRate < alertThresholds.heartRate.low {
            alerts.append(HealthAlert(type: .heartRate, severity: .warning, message: "Low heart rate: \(vitals.heartRate) BPM"))
        }
        
        // Blood pressure alerts
        if vitals.bloodPressure.systolic > alertThresholds.bloodPressure.criticalSystolicHigh {
            alerts.append(HealthAlert(type: .bloodPressure, severity: .critical, message: "Critical high blood pressure: \(vitals.bloodPressure.systolic)/\(vitals.bloodPressure.diastolic)"))
        } else if vitals.bloodPressure.systolic > alertThresholds.bloodPressure.systolicHigh {
            alerts.append(HealthAlert(type: .bloodPressure, severity: .warning, message: "Elevated blood pressure: \(vitals.bloodPressure.systolic)/\(vitals.bloodPressure.diastolic)"))
        }
        
        // Oxygen saturation alerts
        if vitals.oxygenSaturation < alertThresholds.oxygenSaturation.critical {
            alerts.append(HealthAlert(type: .oxygenSaturation, severity: .critical, message: "Critical low oxygen saturation: \(Int(vitals.oxygenSaturation))%"))
        } else if vitals.oxygenSaturation < alertThresholds.oxygenSaturation.low {
            alerts.append(HealthAlert(type: .oxygenSaturation, severity: .warning, message: "Low oxygen saturation: \(Int(vitals.oxygenSaturation))%"))
        }
        
        // Temperature alerts
        if vitals.temperature > alertThresholds.temperature.criticalHigh {
            alerts.append(HealthAlert(type: .temperature, severity: .critical, message: "Critical high temperature: \(vitals.temperature, specifier: "%.1f")°F"))
        } else if vitals.temperature > alertThresholds.temperature.high {
            alerts.append(HealthAlert(type: .temperature, severity: .warning, message: "Elevated temperature: \(vitals.temperature, specifier: "%.1f")°F"))
        }
        
        // Respiratory rate alerts
        if vitals.respiratoryRate > alertThresholds.respiratoryRate.criticalHigh {
            alerts.append(HealthAlert(type: .respiratoryRate, severity: .critical, message: "Critical high respiratory rate: \(vitals.respiratoryRate) RPM"))
        } else if vitals.respiratoryRate > alertThresholds.respiratoryRate.high {
            alerts.append(HealthAlert(type: .respiratoryRate, severity: .warning, message: "Elevated respiratory rate: \(vitals.respiratoryRate) RPM"))
        }
        
        return alerts
    }
    
    private func hasAlerts(vitals: VitalSigns) -> Bool {
        return !generateAlerts(vitals: vitals).isEmpty
    }
    
    private func getActiveAlerts(vitals: VitalSigns) -> [HealthAlert] {
        return generateAlerts(vitals: vitals)
    }
    
    // MARK: - Trend Analysis
    
    private func updateTrendAnalysis(vitals: VitalSigns) {
        // Update trend analysis based on historical data
        // This would calculate trends and update trend displays
    }
    
    private func calculateTrends(vitals: VitalSigns) -> [TrendDirection] {
        // Calculate trends based on historical data
        var trends: [TrendDirection] = []
        
        if heartRateBuffer.count >= 5 {
            let recentHR = Array(heartRateBuffer.suffix(5))
            let trend = calculateTrend(values: recentHR)
            trends.append(trend)
        }
        
        if oxygenBuffer.count >= 5 {
            let recentO2 = Array(oxygenBuffer.suffix(5))
            let trend = calculateTrend(values: recentO2)
            trends.append(trend)
        }
        
        return trends
    }
    
    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let difference = secondAvg - firstAvg
        let threshold = 0.05 * firstAvg // 5% threshold
        
        if difference > threshold {
            return .increasing
        } else if difference < -threshold {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func createTrendIndicator(trend: TrendDirection) -> Entity {
        let entity = Entity()
        
        let color: UIColor
        let symbol: String
        
        switch trend {
        case .increasing:
            color = .red
            symbol = "↑"
        case .decreasing:
            color = .green
            symbol = "↓"
        case .stable:
            color = .blue
            symbol = "→"
        }
        
        let textEntity = createTextEntity(text: symbol, color: color)
        entity.addChild(textEntity)
        
        return entity
    }
    
    private func createAlertIndicator(alert: HealthAlert) -> Entity {
        let entity = Entity()
        
        let color: UIColor
        switch alert.severity {
        case .critical:
            color = .red
        case .warning:
            color = .orange
        }
        
        // Create alert icon
        let alertMesh = MeshResource.generateSphere(radius: 0.02)
        let alertMaterial = SimpleMaterial(color: color, isMetallic: false)
        let alertComponent = ModelComponent(mesh: alertMesh, materials: [alertMaterial])
        entity.components.set(alertComponent)
        
        return entity
    }
    
    // MARK: - Monitor Management
    
    private func createMonitorDisplay(for type: MonitorType) {
        // Create specific monitor display based on type
        switch type {
        case .heartRate:
            createHeartRateMonitor()
        case .bloodPressure:
            createBloodPressureMonitor()
        case .oxygenSaturation:
            createOxygenMonitor()
        case .temperature:
            createTemperatureMonitor()
        case .respiratoryRate:
            createRespiratoryMonitor()
        case .comprehensive:
            createComprehensiveMonitor()
        }
    }
    
    private func removeMonitorDisplay(for type: MonitorType) {
        // Remove specific monitor display
        // Implementation would remove entities and anchors for the specific monitor type
    }
    
    // MARK: - Monitor Creation Methods
    
    private func createHeartRateMonitor() {
        // Create heart rate specific monitoring display
    }
    
    private func createBloodPressureMonitor() {
        // Create blood pressure specific monitoring display
    }
    
    private func createOxygenMonitor() {
        // Create oxygen saturation specific monitoring display
    }
    
    private func createTemperatureMonitor() {
        // Create temperature specific monitoring display
    }
    
    private func createRespiratoryMonitor() {
        // Create respiratory rate specific monitoring display
    }
    
    private func createComprehensiveMonitor() {
        // Create comprehensive monitoring display
    }
    
    // MARK: - Entity Update Methods
    
    private func updateVitalSignsEntity(_ entity: Entity, with vitals: VitalSigns) async throws {
        // Update entity with new vital signs data
        // This would update materials, text, animations, etc.
    }
    
    // MARK: - Status Management
    
    private func handleMonitoringStatusChange(_ status: MonitoringStatus) {
        switch status {
        case .active:
            monitoringQuality = .excellent
        case .inactive:
            monitoringQuality = .unknown
        case .error:
            monitoringQuality = .poor
        }
    }
}

// MARK: - ARSessionDelegate

@available(iOS 18.0, *)
extension ARHealthMonitoring: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update monitoring based on AR frame
        // This could include position tracking, lighting analysis, etc.
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle new monitoring anchors
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        // Handle removed monitoring anchors
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        lastError = error.localizedDescription
        monitoringStatus = .error
    }
}

// MARK: - Supporting Types

@available(iOS 18.0, *)
public struct VitalSigns {
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

public enum MonitorType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case oxygenSaturation = "Oxygen Saturation"
    case temperature = "Temperature"
    case respiratoryRate = "Respiratory Rate"
    case comprehensive = "Comprehensive"
}

public enum MonitoringStatus: String, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case error = "Error"
}

public enum MonitoringQuality: String, CaseIterable {
    case unknown = "Unknown"
    case poor = "Poor"
    case fair = "Fair"
    case good = "Good"
    case excellent = "Excellent"
}

public enum TrendDirection: String, CaseIterable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"
}

public struct HealthAlert {
    public let type: AlertType
    public let severity: AlertSeverity
    public let message: String
    public let timestamp: Date
    
    public init(type: AlertType, severity: AlertSeverity, message: String, timestamp: Date = Date()) {
        self.type = type
        self.severity = severity
        self.message = message
        self.timestamp = timestamp
    }
}

public enum AlertType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case oxygenSaturation = "Oxygen Saturation"
    case temperature = "Temperature"
    case respiratoryRate = "Respiratory Rate"
}

public enum AlertSeverity: String, CaseIterable {
    case warning = "Warning"
    case critical = "Critical"
}

public struct MonitoringStatistics {
    public let activeMonitors: Int
    public let totalAlerts: Int
    public let monitoringQuality: MonitoringQuality
    public let lastUpdate: Date?
    public let dataPointsCollected: Int
    
    public init(activeMonitors: Int, totalAlerts: Int, monitoringQuality: MonitoringQuality, lastUpdate: Date?, dataPointsCollected: Int) {
        self.activeMonitors = activeMonitors
        self.totalAlerts = totalAlerts
        self.monitoringQuality = monitoringQuality
        self.lastUpdate = lastUpdate
        self.dataPointsCollected = dataPointsCollected
    }
}

// MARK: - Alert Thresholds

public struct AlertThresholds {
    public var heartRate: HeartRateThresholds
    public var bloodPressure: BloodPressureThresholds
    public var oxygenSaturation: OxygenThresholds
    public var temperature: TemperatureThresholds
    public var respiratoryRate: RespiratoryThresholds
    
    public init() {
        self.heartRate = HeartRateThresholds()
        self.bloodPressure = BloodPressureThresholds()
        self.oxygenSaturation = OxygenThresholds()
        self.temperature = TemperatureThresholds()
        self.respiratoryRate = RespiratoryThresholds()
    }
}

public struct HeartRateThresholds {
    public let low: Int
    public let high: Int
    public let criticalLow: Int
    public let criticalHigh: Int
    
    public init(low: Int = 60, high: Int = 100, criticalLow: Int = 50, criticalHigh: Int = 120) {
        self.low = low
        self.high = high
        self.criticalLow = criticalLow
        self.criticalHigh = criticalHigh
    }
}

public struct BloodPressureThresholds {
    public let systolicLow: Int
    public let systolicHigh: Int
    public let diastolicLow: Int
    public let diastolicHigh: Int
    public let criticalSystolicLow: Int
    public let criticalSystolicHigh: Int
    public let criticalDiastolicLow: Int
    public let criticalDiastolicHigh: Int
    
    public init(systolicLow: Int = 90, systolicHigh: Int = 140, diastolicLow: Int = 60, diastolicHigh: Int = 90, criticalSystolicLow: Int = 80, criticalSystolicHigh: Int = 180, criticalDiastolicLow: Int = 50, criticalDiastolicHigh: Int = 110) {
        self.systolicLow = systolicLow
        self.systolicHigh = systolicHigh
        self.diastolicLow = diastolicLow
        self.diastolicHigh = diastolicHigh
        self.criticalSystolicLow = criticalSystolicLow
        self.criticalSystolicHigh = criticalSystolicHigh
        self.criticalDiastolicLow = criticalDiastolicLow
        self.criticalDiastolicHigh = criticalDiastolicHigh
    }
}

public struct OxygenThresholds {
    public let low: Double
    public let critical: Double
    
    public init(low: Double = 95, critical: Double = 90) {
        self.low = low
        self.critical = critical
    }
}

public struct TemperatureThresholds {
    public let low: Double
    public let high: Double
    public let criticalLow: Double
    public let criticalHigh: Double
    
    public init(low: Double = 97.0, high: Double = 99.5, criticalLow: Double = 95.0, criticalHigh: Double = 100.4) {
        self.low = low
        self.high = high
        self.criticalLow = criticalLow
        self.criticalHigh = criticalHigh
    }
}

public struct RespiratoryThresholds {
    public let low: Int
    public let high: Int
    public let criticalLow: Int
    public let criticalHigh: Int
    
    public init(low: Int = 12, high: Int = 20, criticalLow: Int = 8, criticalHigh: Int = 25) {
        self.low = low
        self.high = high
        self.criticalLow = criticalLow
        self.criticalHigh = criticalHigh
    }
}

// MARK: - Custom AR Anchor

@available(iOS 18.0, *)
public class VitalSignsAnchor: ARAnchor {
    public var vitals: VitalSigns
    
    public init(vitals: VitalSigns, position: SIMD3<Float>) {
        self.vitals = vitals
        super.init(name: "VitalSigns", transform: simd_float4x4(position: position))
    }
    
    public func updateVitals(_ newVitals: VitalSigns) {
        self.vitals = newVitals
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 