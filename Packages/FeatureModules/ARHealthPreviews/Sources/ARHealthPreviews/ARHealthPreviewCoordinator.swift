import SwiftUI
import RealityKit
import ARKit
import HealthAI2030Core
import RealityHealthKit
import SpatialHealthAnalytics

#if os(iOS) || os(iPadOS) || os(visionOS)

/// Coordinator for immersive AR health previews and spatial health analytics
@MainActor
public class ARHealthPreviewCoordinator: ObservableObject {
    public static let shared = ARHealthPreviewCoordinator()
    
    @Published public private(set) var isARAvailable = false
    @Published public private(set) var currentPreview: ARHealthPreview?
    @Published public private(set) var spatialAnchors: [SpatialHealthAnchor] = []
    @Published public private(set) var realTimeHealthData: [HealthMetric] = []
    
    private var arSession: ARSession?
    private var realityEngine: RealityHealthEngine
    private var spatialAnalytics: SpatialHealthAnalyticEngine
    private var healthDataProcessor: ARHealthDataProcessor
    
    public enum ARHealthPreview: String, CaseIterable {
        case cardiovascularFlow = "cardiovascular_flow"
        case respiratoryVisualization = "respiratory_visualization"
        case stressHeatmap = "stress_heatmap"
        case sleepQualityField = "sleep_quality_field"
        case biometricAura = "biometric_aura"
        case healthTrendTimeline = "health_trend_timeline"
        case bodySystemsOverlay = "body_systems_overlay"
        
        public var displayName: String {
            switch self {
            case .cardiovascularFlow: return "Cardiovascular Flow"
            case .respiratoryVisualization: return "Respiratory Patterns"
            case .stressHeatmap: return "Stress Heatmap"
            case .sleepQualityField: return "Sleep Quality Field"
            case .biometricAura: return "Biometric Aura"
            case .healthTrendTimeline: return "Health Trends"
            case .bodySystemsOverlay: return "Body Systems"
            }
        }
    }
    
    private init() {
        self.realityEngine = RealityHealthEngine()
        self.spatialAnalytics = SpatialHealthAnalyticEngine()
        self.healthDataProcessor = ARHealthDataProcessor()
        
        checkARAvailability()
        setupHealthDataStreaming()
    }
    
    // MARK: - Public Interface
    
    /// Start AR health preview session
    public func startARPreview(_ preview: ARHealthPreview, in view: ARView) async throws {
        guard isARAvailable else {
            throw ARHealthError.arNotAvailable
        }
        
        // Initialize AR session
        try await initializeARSession(view)
        
        // Configure preview-specific AR experience
        try await configurePreview(preview, in: view)
        
        currentPreview = preview
        
        // Start real-time health data visualization
        await startHealthVisualization(preview, in: view)
    }
    
    /// Stop current AR preview
    public func stopARPreview() async {
        currentPreview = nil
        spatialAnchors.removeAll()
        
        await realityEngine.stopAllVisualizations()
        await spatialAnalytics.reset()
        
        arSession?.pause()
    }
    
    /// Place a spatial health anchor at current location
    public func placeSpatialAnchor(_ anchorType: SpatialHealthAnchor.AnchorType) async throws {
        guard let arSession = arSession else {
            throw ARHealthError.sessionNotActive
        }
        
        // Get current camera transform
        guard let frame = arSession.currentFrame else {
            throw ARHealthError.noARFrame
        }
        
        let transform = frame.camera.transform
        let anchor = SpatialHealthAnchor(
            type: anchorType,
            transform: transform,
            timestamp: Date(),
            healthSnapshot: await captureHealthSnapshot()
        )
        
        spatialAnchors.append(anchor)
        
        // Visualize anchor in AR
        await realityEngine.visualizeAnchor(anchor)
    }
    
    /// Get spatial health insights for current location
    public func getSpatialHealthInsights() async -> [SpatialHealthInsight] {
        return await spatialAnalytics.generateInsights(
            anchors: spatialAnchors,
            currentHealthData: realTimeHealthData
        )
    }
    
    /// Capture current health state as AR snapshot
    public func captureHealthSnapshot() async -> HealthSnapshot {
        return await healthDataProcessor.captureSnapshot(realTimeHealthData)
    }
    
    // MARK: - AR Configuration
    
    private func checkARAvailability() {
        #if os(iOS) || os(iPadOS)
        isARAvailable = ARWorldTrackingConfiguration.isSupported
        #elseif os(visionOS)
        isARAvailable = true // visionOS has native spatial computing
        #else
        isARAvailable = false
        #endif
    }
    
    private func initializeARSession(_ arView: ARView) async throws {
        #if os(iOS) || os(iPadOS)
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.horizontal, .vertical]
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arView.session.run(configuration)
        self.arSession = arView.session
        
        #elseif os(visionOS)
        // visionOS uses different AR initialization
        let configuration = ARKitSession()
        try await configuration.run([
            .worldTracking,
            .handTracking,
            .sceneReconstruction(.mesh)
        ])
        #endif
        
        // Set up Reality engine with AR session
        await realityEngine.configure(arSession: arSession)
    }
    
    private func configurePreview(_ preview: ARHealthPreview, in arView: ARView) async throws {
        switch preview {
        case .cardiovascularFlow:
            await configureCardiovascularFlow(arView)
        case .respiratoryVisualization:
            await configureRespiratoryVisualization(arView)
        case .stressHeatmap:
            await configureStressHeatmap(arView)
        case .sleepQualityField:
            await configureSleepQualityField(arView)
        case .biometricAura:
            await configureBiometricAura(arView)
        case .healthTrendTimeline:
            await configureHealthTrendTimeline(arView)
        case .bodySystemsOverlay:
            await configureBodySystemsOverlay(arView)
        }
    }
    
    // MARK: - Preview Configurations
    
    private func configureCardiovascularFlow(_ arView: ARView) async {
        // Create flowing particle system representing blood flow
        let flowSystem = await realityEngine.createCardiovascularFlow()
        arView.scene.addAnchor(flowSystem)
        
        // Set up heart rate responsive animations
        await realityEngine.linkToHeartRate(flowSystem)
    }
    
    private func configureRespiratoryVisualization(_ arView: ARView) async {
        // Create breathing visualization with expanding spheres
        let breathingViz = await realityEngine.createRespiratoryVisualization()
        arView.scene.addAnchor(breathingViz)
        
        // Sync with respiratory rate
        await realityEngine.linkToRespiratoryRate(breathingViz)
    }
    
    private func configureStressHeatmap(_ arView: ARView) async {
        // Create color-changing environment based on stress levels
        let heatmap = await realityEngine.createStressHeatmap()
        arView.scene.addAnchor(heatmap)
        
        // Link to stress level data
        await realityEngine.linkToStressLevel(heatmap)
    }
    
    private func configureSleepQualityField(_ arView: ARView) async {
        // Create ambient field visualization for sleep quality
        let sleepField = await realityEngine.createSleepQualityField()
        arView.scene.addAnchor(sleepField)
        
        // Link to sleep quality metrics
        await realityEngine.linkToSleepQuality(sleepField)
    }
    
    private func configureBiometricAura(_ arView: ARView) async {
        // Create aura effect around user based on biometric data
        let aura = await realityEngine.createBiometricAura()
        arView.scene.addAnchor(aura)
        
        // Link to multiple biometric streams
        await realityEngine.linkToMultipleBiometrics(aura)
    }
    
    private func configureHealthTrendTimeline(_ arView: ARView) async {
        // Create temporal visualization of health trends
        let timeline = await realityEngine.createHealthTrendTimeline()
        arView.scene.addAnchor(timeline)
        
        // Load historical health data
        await realityEngine.loadHealthHistory(timeline)
    }
    
    private func configureBodySystemsOverlay(_ arView: ARView) async {
        // Create anatomical overlay with system status
        let bodyOverlay = await realityEngine.createBodySystemsOverlay()
        arView.scene.addAnchor(bodyOverlay)
        
        // Link to comprehensive health data
        await realityEngine.linkToBodySystems(bodyOverlay)
    }
    
    // MARK: - Health Data Streaming
    
    private func setupHealthDataStreaming() {
        Task {
            // Subscribe to real-time health metrics
            let heartRateStream = await SensorDataActor.shared.subscribe(to: .heartRate)
            let hrvStream = await SensorDataActor.shared.subscribe(to: .heartRateVariability)
            let stressStream = await SensorDataActor.shared.subscribe(to: .stressLevel)
            
            // Merge streams for real-time processing
            for await metric in merge(heartRateStream, hrvStream, stressStream) {
                await updateRealTimeHealthData(metric)
            }
        }
    }
    
    private func startHealthVisualization(_ preview: ARHealthPreview, in arView: ARView) async {
        await realityEngine.startRealTimeVisualization(
            preview: preview,
            healthDataStream: AsyncStream { continuation in
                Task {
                    for metric in realTimeHealthData {
                        continuation.yield(metric)
                    }
                }
            }
        )
    }
    
    private func updateRealTimeHealthData(_ metric: HealthMetric) async {
        // Update real-time data array
        realTimeHealthData.append(metric)
        
        // Maintain rolling window of recent data
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        realTimeHealthData.removeAll { $0.timestamp < fiveMinutesAgo }
        
        // Update AR visualization
        await realityEngine.updateVisualization(with: metric)
        
        // Update spatial analytics
        await spatialAnalytics.processMetric(metric, at: getCurrentLocation())
    }
    
    private func getCurrentLocation() -> simd_float4x4? {
        return arSession?.currentFrame?.camera.transform
    }
    
    // MARK: - Helper Functions
    
    private func merge<T: Sendable>(_ streams: AsyncStream<T>...) -> AsyncStream<T> {
        return AsyncStream { continuation in
            for stream in streams {
                Task {
                    for await element in stream {
                        continuation.yield(element)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

public struct SpatialHealthAnchor: Identifiable, Sendable {
    public let id = UUID()
    public let type: AnchorType
    public let transform: simd_float4x4
    public let timestamp: Date
    public let healthSnapshot: HealthSnapshot
    
    public enum AnchorType: String, CaseIterable, Sendable {
        case workout = "workout"
        case meditation = "meditation"
        case sleep = "sleep"
        case stress = "stress"
        case recovery = "recovery"
        case peak = "peak_performance"
        
        public var displayName: String {
            switch self {
            case .workout: return "Workout"
            case .meditation: return "Meditation"
            case .sleep: return "Sleep"
            case .stress: return "Stress Event"
            case .recovery: return "Recovery"
            case .peak: return "Peak Performance"
            }
        }
        
        public var systemImage: String {
            switch self {
            case .workout: return "figure.run"
            case .meditation: return "leaf.fill"
            case .sleep: return "bed.double.fill"
            case .stress: return "exclamationmark.triangle.fill"
            case .recovery: return "heart.circle.fill"
            case .peak: return "star.fill"
            }
        }
    }
}

public struct HealthSnapshot: Sendable {
    public let timestamp: Date
    public let heartRate: Double?
    public let heartRateVariability: Double?
    public let stressLevel: Double?
    public let energyLevel: Double?
    public let mood: Double?
    public let location: String?
    public let activity: String?
    public let environmentalFactors: EnvironmentalSnapshot
    
    public var summary: String {
        var components: [String] = []
        
        if let hr = heartRate {
            components.append("HR: \(Int(hr)) bpm")
        }
        if let stress = stressLevel {
            components.append("Stress: \(Int(stress * 10))/10")
        }
        if let energy = energyLevel {
            components.append("Energy: \(Int(energy * 100))%")
        }
        
        return components.joined(separator: " • ")
    }
}

public struct EnvironmentalSnapshot: Sendable {
    public let lightLevel: Double
    public let noiseLevel: Double
    public let temperature: Double
    public let airQuality: Double?
    public let humidity: Double
    
    public init(
        lightLevel: Double = 0,
        noiseLevel: Double = 0,
        temperature: Double = 20,
        airQuality: Double? = nil,
        humidity: Double = 50
    ) {
        self.lightLevel = lightLevel
        self.noiseLevel = noiseLevel
        self.temperature = temperature
        self.airQuality = airQuality
        self.humidity = humidity
    }
}

public struct SpatialHealthInsight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let location: simd_float4x4
    public let relevantAnchors: [UUID]
    public let confidence: Double
    public let actionItems: [String]
    public let timestamp: Date
    
    public var priority: Priority {
        if confidence > 0.8 && title.contains("stress") {
            return .high
        } else if confidence > 0.7 {
            return .medium
        } else {
            return .low
        }
    }
    
    public enum Priority: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
    }
}

// MARK: - AR Health Views

public struct ARHealthPreviewView: View {
    @StateObject private var coordinator = ARHealthPreviewCoordinator.shared
    @State private var selectedPreview: ARHealthPreviewCoordinator.ARHealthPreview?
    @State private var showingPreviewSelection = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if coordinator.isARAvailable {
                ARViewContainer(
                    preview: selectedPreview,
                    coordinator: coordinator
                )
                .ignoresSafeArea()
                
                // AR Controls Overlay
                VStack {
                    Spacer()
                    
                    ARControlsPanel(
                        selectedPreview: $selectedPreview,
                        showingSelection: $showingPreviewSelection,
                        coordinator: coordinator
                    )
                    .padding()
                }
                
            } else {
                ARUnavailableView()
            }
        }
        .sheet(isPresented: $showingPreviewSelection) {
            PreviewSelectionView(
                selectedPreview: $selectedPreview,
                coordinator: coordinator
            )
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let preview: ARHealthPreviewCoordinator.ARHealthPreview?
    let coordinator: ARHealthPreviewCoordinator
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let preview = preview {
            Task {
                try? await coordinator.startARPreview(preview, in: uiView)
            }
        }
    }
}

struct ARControlsPanel: View {
    @Binding var selectedPreview: ARHealthPreviewCoordinator.ARHealthPreview?
    @Binding var showingSelection: Bool
    let coordinator: ARHealthPreviewCoordinator
    
    var body: some View {
        HStack(spacing: 16) {
            // Preview selection button
            Button(action: { showingSelection = true }) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // Current preview indicator
            if let preview = selectedPreview {
                Text(preview.displayName)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            
            Spacer()
            
            // Anchor placement button
            Button(action: placeAnchor) {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // Stop preview button
            if selectedPreview != nil {
                Button(action: stopPreview) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
    }
    
    private func placeAnchor() {
        Task {
            try? await coordinator.placeSpatialAnchor(.workout)
        }
    }
    
    private func stopPreview() {
        Task {
            await coordinator.stopARPreview()
            selectedPreview = nil
        }
    }
}

struct PreviewSelectionView: View {
    @Binding var selectedPreview: ARHealthPreviewCoordinator.ARHealthPreview?
    let coordinator: ARHealthPreviewCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(ARHealthPreviewCoordinator.ARHealthPreview.allCases, id: \.self) { preview in
                PreviewSelectionRow(
                    preview: preview,
                    isSelected: selectedPreview == preview
                ) {
                    selectedPreview = preview
                    dismiss()
                }
            }
            .navigationTitle("AR Health Previews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PreviewSelectionRow: View {
    let preview: ARHealthPreviewCoordinator.ARHealthPreview
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: previewIcon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(preview.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(previewDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var previewIcon: String {
        switch preview {
        case .cardiovascularFlow: return "heart.circle.fill"
        case .respiratoryVisualization: return "lungs.fill"
        case .stressHeatmap: return "thermometer"
        case .sleepQualityField: return "bed.double.fill"
        case .biometricAura: return "person.circle.fill"
        case .healthTrendTimeline: return "chart.line.uptrend.xyaxis"
        case .bodySystemsOverlay: return "figure.stand"
        }
    }
    
    private var previewDescription: String {
        switch preview {
        case .cardiovascularFlow: return "Visualize blood flow and heart activity"
        case .respiratoryVisualization: return "See breathing patterns in real-time"
        case .stressHeatmap: return "Environmental stress level mapping"
        case .sleepQualityField: return "Ambient sleep quality visualization"
        case .biometricAura: return "Personal health aura based on vitals"
        case .healthTrendTimeline: return "Historical health data timeline"
        case .bodySystemsOverlay: return "Anatomical system status overlay"
        }
    }
}

struct ARUnavailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("AR Not Available")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Augmented Reality is not supported on this device or is currently unavailable.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Error Types

public enum ARHealthError: Error, LocalizedError, Sendable {
    case arNotAvailable
    case sessionNotActive
    case noARFrame
    case configurationFailed(String)
    case visualizationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .arNotAvailable:
            return "Augmented Reality is not available on this device"
        case .sessionNotActive:
            return "AR session is not currently active"
        case .noARFrame:
            return "No AR frame available for anchor placement"
        case .configurationFailed(let message):
            return "AR configuration failed: \(message)"
        case .visualizationError(let message):
            return "Visualization error: \(message)"
        }
    }
}

#endif