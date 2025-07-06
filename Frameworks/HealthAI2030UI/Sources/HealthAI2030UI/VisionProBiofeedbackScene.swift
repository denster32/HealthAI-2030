import SwiftUI
import RealityKit
import AVFoundation
import HealthKit

/// Main entry for the Vision Pro Biofeedback Scene
struct VisionProBiofeedbackScene: View {
    @StateObject private var hrvAnalyzer = HRVCoherenceAnalyzer()
    @StateObject private var audioManager = AdaptiveAudioManager()
    @StateObject private var fractalRenderer = FractalRenderer()
    
    @State private var isSessionActive = false
    @State private var currentCoherence: Double = 0.0
    @State private var breathPhase: BreathPhase = .inhale
    @State private var showMetrics = false
    @State private var sessionDuration: TimeInterval = 0
    @State private var lastBreathTime = Date()
    
    private let breathCycleDuration: TimeInterval = 4.0 // 4 seconds per breath cycle
    
    enum BreathPhase {
        case inhale, exhale
        
        var duration: TimeInterval {
            switch self {
            case .inhale: return 2.0
            case .exhale: return 2.0
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background RealityKit scene
            RealityView { content in
                // Create immersive environment
                let environment = EnvironmentResource.generate(
                    lighting: .realistic(
                        with: .init(
                            sun: .init(
                                intensity: 0.5,
                                angle: .init(degrees: 45)
                            ),
                            sky: .init(
                                atmosphere: .init(
                                    density: 0.1,
                                    scattering: .init(
                                        rayleigh: .init(coefficient: 0.1),
                                        mie: .init(coefficient: 0.1)
                                    )
                                )
                            )
                        )
                    )
                )
                content.environment = environment
                
                // Add fractal entity
                let fractalEntity = fractalRenderer.createFractalEntity()
                content.add(fractalEntity)
                
            } update: { content in
                // Update fractal parameters based on HRV coherence
                if let fractalEntity = content.entities.first {
                    fractalRenderer.updateFractal(fractalEntity, coherence: currentCoherence)
                }
            }
            
            // Breath Ring Overlay
            BreathRingView(
                phase: breathPhase,
                coherence: currentCoherence,
                isActive: isSessionActive
            )
            
            // Metrics Overlay
            if showMetrics {
                MetricsOverlayView(
                    coherence: currentCoherence,
                    sessionDuration: sessionDuration,
                    breathPhase: breathPhase
                )
            }
            
            // Controls
            VStack {
                Spacer()
                
                HStack {
                    // Session Control
                    Button(action: toggleSession) {
                        Image(systemName: isSessionActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    .accessibilityLabel(isSessionActive ? "Pause Session" : "Start Session")
                    
                    Spacer()
                    
                    // Metrics Toggle
                    Button(action: { showMetrics.toggle() }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                            )
                    }
                    .accessibilityLabel("Toggle Metrics")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            cleanupSession()
        }
        .gesture(
            // Hand gesture controls
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    handleGesture(value)
                }
        )
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateSession()
        }
    }
    
    private func setupSession() {
        // Initialize HRV monitoring
        hrvAnalyzer.startMonitoring()
        
        // Setup audio
        audioManager.configureForBiofeedback()
        
        // Start fractal rendering
        fractalRenderer.startRendering()
    }
    
    private func cleanupSession() {
        hrvAnalyzer.stopMonitoring()
        audioManager.stopAudio()
        fractalRenderer.stopRendering()
    }
    
    private func toggleSession() {
        isSessionActive.toggle()
        
        if isSessionActive {
            audioManager.startAdaptiveAudio(coherence: currentCoherence)
            fractalRenderer.setActive(true)
        } else {
            audioManager.stopAudio()
            fractalRenderer.setActive(false)
        }
    }
    
    private func updateSession() {
        guard isSessionActive else { return }
        
        // Update session duration
        sessionDuration += 0.1
        
        // Update HRV coherence
        currentCoherence = hrvAnalyzer.currentCoherence
        
        // Update breath phase
        let timeSinceLastBreath = Date().timeIntervalSince(lastBreathTime)
        if timeSinceLastBreath >= breathPhase.duration {
            breathPhase = breathPhase == .inhale ? .exhale : .inhale
            lastBreathTime = Date()
        }
        
        // Update audio and visuals
        audioManager.updateCoherence(currentCoherence)
        fractalRenderer.updateCoherence(currentCoherence)
    }
    
    private func handleGesture(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.x
        let verticalAmount = value.translation.y
        
        // Horizontal swipe for session control
        if abs(horizontalAmount) > abs(verticalAmount) {
            if horizontalAmount > 50 {
                // Swipe right - start session
                if !isSessionActive {
                    toggleSession()
                }
            } else if horizontalAmount < -50 {
                // Swipe left - stop session
                if isSessionActive {
                    toggleSession()
                }
            }
        }
        
        // Vertical swipe for metrics toggle
        if abs(verticalAmount) > abs(horizontalAmount) {
            if verticalAmount < -50 {
                // Swipe up - show metrics
                showMetrics = true
            } else if verticalAmount > 50 {
                // Swipe down - hide metrics
                showMetrics = false
            }
        }
    }
}

// MARK: - RealityKit 3D Scene Placeholder
struct RealityViewRepresentable: UIViewRepresentable {
    let hrvCoherence: Double
    let visualIntensity: Double
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // Add fractal visuals using procedural mesh
        let mesh = MeshResource.generateBox(size: 0.1 + Float(hrvCoherence) * 0.2)
        let material = SimpleMaterial(color: .init(red: 0.2 + hrvCoherence, green: 0.5, blue: 1.0 - hrvCoherence, alpha: 1.0), isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = [0, 0, -0.5]
        arView.scene.anchors.append(AnchorEntity(world: .zero))
        arView.scene.anchors[0].addChild(entity)
        // Add particle system for breathing effect
        let particleSystem = ParticleEmitterComponent(
            birthRate: 100 * Float(visualIntensity + 1),
            lifetime: 2.0,
            color: .init(red: 1.0, green: 1.0 - Float(hrvCoherence), blue: Float(hrvCoherence), alpha: 0.7),
            velocity: [0, 0.1 + Float(hrvCoherence) * 0.2, 0],
            spread: 0.2 + Float(visualIntensity) * 0.1
        )
        entity.components.set(particleSystem)
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update visuals based on hrvCoherence and visualIntensity
        if let entity = uiView.scene.anchors.first?.children.first as? ModelEntity {
            let newSize = 0.1 + Float(hrvCoherence) * 0.2
            entity.model?.mesh = MeshResource.generateBox(size: newSize)
            entity.model?.materials = [SimpleMaterial(color: .init(red: 0.2 + hrvCoherence, green: 0.5, blue: 1.0 - hrvCoherence, alpha: 1.0), isMetallic: true)]
            if var particle = entity.components[ParticleEmitterComponent.self] {
                particle.birthRate = 100 * Float(visualIntensity + 1)
                particle.color = .init(red: 1.0, green: 1.0 - Float(hrvCoherence), blue: Float(hrvCoherence), alpha: 0.7)
                particle.velocity = [0, 0.1 + Float(hrvCoherence) * 0.2, 0]
                particle.spread = 0.2 + Float(visualIntensity) * 0.1
                entity.components.set(particle)
            }
        }
    }
}

// MARK: - Breath Ring View Placeholder
struct BreathRingView: View {
    let phase: VisionProBiofeedbackScene.BreathPhase
    let coherence: Double
    let isActive: Bool
    
    @State private var ringScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: coherenceColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .frame(width: 300, height: 300)
                .scaleEffect(ringScale)
                .opacity(isActive ? 0.8 : 0.3)
                .animation(.easeInOut(duration: phase.duration), value: ringScale)
            
            // Inner ring
            Circle()
                .stroke(
                    Color.white.opacity(0.6),
                    lineWidth: 4
                )
                .frame(width: 200, height: 200)
                .scaleEffect(ringScale * 0.8)
                .opacity(isActive ? 0.6 : 0.2)
                .animation(.easeInOut(duration: phase.duration), value: ringScale)
            
            // Center indicator
            Circle()
                .fill(coherenceColor)
                .frame(width: 20, height: 20)
                .scaleEffect(isActive ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
        }
        .onAppear {
            startBreathingAnimation()
        }
        .onChange(of: phase) { _ in
            startBreathingAnimation()
        }
    }
    
    private var coherenceColors: [Color] {
        switch coherence {
        case 0.0..<0.3:
            return [.red, .orange]
        case 0.3..<0.7:
            return [.orange, .yellow]
        case 0.7..<0.9:
            return [.yellow, .green]
        default:
            return [.green, .blue]
        }
    }
    
    private var coherenceColor: Color {
        switch coherence {
        case 0.0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
    
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: phase.duration)) {
            ringScale = phase == .inhale ? 1.3 : 0.8
        }
    }
}

// MARK: - Metrics Overlay Placeholder
struct MetricsOverlayView: View {
    let coherence: Double
    let sessionDuration: TimeInterval
    let breathPhase: VisionProBiofeedbackScene.BreathPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("HRV Coherence")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(Int(coherence * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(coherenceColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Session Time")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(timeString)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            // Coherence progress bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Coherence Level")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(coherenceColor)
                            .frame(width: geometry.size.width * coherence, height: 8)
                            .cornerRadius(4)
                            .animation(.easeInOut(duration: 0.5), value: coherence)
                    }
                }
                .frame(height: 8)
            }
            
            // Breath phase indicator
            HStack {
                Text("Breath Phase:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(breathPhase == .inhale ? "Inhale" : "Exhale")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 40)
        .padding(.top, 60)
    }
    
    private var coherenceColor: Color {
        switch coherence {
        case 0.0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
    
    private var timeString: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - HRV Analyzer Stub
class HRVCoherenceAnalyzer: ObservableObject {
    @Published var currentCoherence: Double = 0.0
    private var healthStore: HKHealthStore?
    private var timer: Timer?
    
    func startMonitoring() {
        // Initialize HealthKit
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            requestAuthorization()
        }
        
        // Start timer for simulated HRV data (replace with real HealthKit data)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCoherence()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func requestAuthorization() {
        guard let healthStore = healthStore else { return }
        
        var typesToRead: Set<HKObjectType> = []
        
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            typesToRead.insert(hrvType)
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRateType)
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.startHRVMonitoring()
            }
        }
    }
    
    private func startHRVMonitoring() {
        // Implementation for real HRV monitoring would go here
        // For now, we'll use simulated data
    }
    
    private func updateCoherence() {
        // Simulate HRV coherence changes
        let randomChange = Double.random(in: -0.05...0.05)
        currentCoherence = max(0.0, min(1.0, currentCoherence + randomChange))
    }
}

class FractalRenderer: ObservableObject {
    private var isRendering = false
    private var isActive = false
    private var lastCoherence: Double = 0.0
    private var fractalEntity: ModelEntity?

    func startRendering() {
        isRendering = true
    }
    func stopRendering() {
        isRendering = false
    }
    func setActive(_ active: Bool) {
        isActive = active
    }
    func createFractalEntity() -> Entity {
        // Create a Mandelbrot-like fractal mesh using RealityKit's procedural mesh
        let mesh = MeshResource.generateSphere(radius: 0.2, segments: 128)
        let material = SimpleMaterial(color: .init(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0), isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = [0, 0, -1.0]
        entity.name = "FractalEntity"
        fractalEntity = entity
        return entity
    }
    func updateFractal(_ entity: Entity, coherence: Double) {
        // Animate color and scale based on coherence
        guard let model = entity as? ModelEntity else { return }
        let color = SIMD4<Float>(Float(0.3 + 0.7 * coherence), Float(0.7 * coherence), Float(1.0 - 0.5 * coherence), 1.0)
        model.model?.materials = [SimpleMaterial(color: .init(color: color), isMetallic: true)]
        let scale = 1.0 + 0.5 * coherence
        model.transform.scale = SIMD3<Float>(repeating: Float(scale))
        // Add subtle rotation for visual interest
        let angle = Float(Date().timeIntervalSinceReferenceDate).truncatingRemainder(dividingBy: .pi * 2)
        model.transform.rotation = simd_quatf(angle: angle * Float(coherence), axis: [0, 1, 0])
        lastCoherence = coherence
    }
    func updateCoherence(_ coherence: Double) {
        // Optionally trigger additional effects based on coherence
        if let entity = fractalEntity {
            updateFractal(entity, coherence: coherence)
        }
    }
}

#Preview {
    VisionProBiofeedbackScene()
}