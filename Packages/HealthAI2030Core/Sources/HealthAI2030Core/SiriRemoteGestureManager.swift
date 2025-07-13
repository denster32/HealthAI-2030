import SwiftUI
import GameController
#if canImport(UIKit)
import UIKit
#endif

@available(tvOS 18.0, *)
class SiriRemoteGestureManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isGestureActive = false
    @Published var currentGesture: RemoteGesture?
    @Published var gestureIntensity: Float = 0.0
    @Published var spatialPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    @Published var rotationAngle: Float = 0.0
    @Published var isHealthDataNavigationActive = false
    
    // MARK: - Private Properties
    
    private var remoteController: GCMicroGamepad?
    private var motionManager: CMMotionManager?
    private var lastTouchPosition: CGPoint = .zero
    private var touchStartTime: TimeInterval = 0
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private weak var targetView: UIView?
    
    // Health data navigation
    private var healthDataLayers: [HealthDataLayer] = []
    private var currentLayerIndex = 0
    private var zoomLevel: Float = 1.0
    private var panOffset: SIMD2<Float> = SIMD2<Float>(0, 0)
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupRemoteController()
        setupMotionManager()
        setupHealthDataLayers()
    }
    
    // MARK: - Setup Methods
    
    private func setupRemoteController() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )
        
        // Check if controller is already connected
        if let controller = GCController.controllers().first {
            configureController(controller)
        }
    }
    
    private func setupMotionManager() {
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0/60.0
        
        if motionManager?.isDeviceMotionAvailable == true {
            motionManager?.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion else { return }
                self?.processMotionData(motion)
            }
        }
    }
    
    private func setupHealthDataLayers() {
        healthDataLayers = [
            HealthDataLayer(
                id: "heart-rate",
                name: "Heart Rate",
                icon: "heart.fill",
                color: .red,
                dataType: .heartRate,
                visualizationType: .line
            ),
            HealthDataLayer(
                id: "hrv",
                name: "Heart Rate Variability",
                icon: "waveform.path.ecg",
                color: .green,
                dataType: .hrv,
                visualizationType: .area
            ),
            HealthDataLayer(
                id: "sleep",
                name: "Sleep Quality",
                icon: "bed.double.fill",
                color: .blue,
                dataType: .sleep,
                visualizationType: .bar
            ),
            HealthDataLayer(
                id: "activity",
                name: "Daily Activity",
                icon: "figure.walk",
                color: .orange,
                dataType: .activity,
                visualizationType: .scatter
            ),
            HealthDataLayer(
                id: "stress",
                name: "Stress Level",
                icon: "brain.head.profile",
                color: .purple,
                dataType: .stress,
                visualizationType: .heatmap
            )
        ]
    }
    
    // MARK: - Controller Configuration
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        configureController(controller)
    }
    
    @objc private func controllerDidDisconnect(_ notification: Notification) {
        remoteController = nil
    }
    
    private func configureController(_ controller: GCController) {
        remoteController = controller.microGamepad
        
        // Configure button handlers
        remoteController?.buttonA.pressedChangedHandler = { [weak self] (button, value, pressed) in
            self?.handleButtonPress(.buttonA, pressed: pressed)
        }
        
        remoteController?.buttonX.pressedChangedHandler = { [weak self] (button, value, pressed) in
            self?.handleButtonPress(.buttonX, pressed: pressed)
        }
        
        // Configure touchpad handlers
        remoteController?.dpad.valueChangedHandler = { [weak self] (dpad, xValue, yValue) in
            self?.handleTouchpadInput(x: xValue, y: yValue)
        }
        
        // Configure touch surface
        if let touchSurface = remoteController?.dpad as? GCControllerDirectionPad {
            touchSurface.valueChangedHandler = { [weak self] (dpad, x, y) in
                self?.handleSpatialNavigation(x: x, y: y)
            }
        }
    }
    
    // MARK: - Gesture Recognition
    
    func attachToView(_ view: UIView) {
        targetView = view
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        guard let view = targetView else { return }
        
        // Pan gesture for data navigation
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(panGesture)
        gestureRecognizers.append(panGesture)
        
        // Tap gesture for layer selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(tapGesture)
        gestureRecognizers.append(tapGesture)
        
        // Swipe gestures for layer switching
        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeUpGesture.direction = .up
        swipeUpGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(swipeUpGesture)
        gestureRecognizers.append(swipeUpGesture)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeDownGesture.direction = .down
        swipeDownGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        view.addGestureRecognizer(swipeDownGesture)
        gestureRecognizers.append(swipeDownGesture)
        
        // Pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
        gestureRecognizers.append(pinchGesture)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let velocity = gesture.velocity(in: gesture.view)
        
        switch gesture.state {
        case .began:
            currentGesture = .pan
            isGestureActive = true
            
        case .changed:
            let normalizedTranslation = SIMD2<Float>(
                Float(translation.x) / 1000.0,
                Float(translation.y) / 1000.0
            )
            panOffset += normalizedTranslation
            
            gestureIntensity = min(Float(sqrt(velocity.x * velocity.x + velocity.y * velocity.y)) / 1000.0, 1.0)
            
            // Update spatial position for health data navigation
            spatialPosition = SIMD3<Float>(panOffset.x, panOffset.y, 0)
            
        case .ended, .cancelled:
            isGestureActive = false
            currentGesture = nil
            
        default:
            break
        }
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        
        if gesture.state == .ended {
            currentGesture = .tap
            
            // Toggle health data navigation
            isHealthDataNavigationActive.toggle()
            
            // Select health data layer based on tap location
            selectHealthDataLayer(at: location)
        }
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        currentGesture = .swipe
        
        switch gesture.direction {
        case .up:
            navigateToNextLayer()
        case .down:
            navigateToPreviousLayer()
        default:
            break
        }
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            currentGesture = .pinch
            isGestureActive = true
            
        case .changed:
            let scale = Float(gesture.scale)
            zoomLevel *= scale
            zoomLevel = max(0.1, min(zoomLevel, 5.0))
            
            gestureIntensity = abs(scale - 1.0)
            
            gesture.scale = 1.0
            
        case .ended, .cancelled:
            isGestureActive = false
            currentGesture = nil
            
        default:
            break
        }
    }
    
    // MARK: - Button Handlers
    
    private func handleButtonPress(_ button: RemoteButton, pressed: Bool) {
        guard pressed else { return }
        
        switch button {
        case .buttonA:
            toggleHealthDataNavigation()
        case .buttonX:
            resetNavigation()
        }
    }
    
    private func handleTouchpadInput(x: Float, y: Float) {
        // Map touchpad input to spatial navigation
        let sensitivity: Float = 2.0
        let deltaX = x * sensitivity
        let deltaY = y * sensitivity
        
        panOffset += SIMD2<Float>(deltaX, deltaY)
        spatialPosition = SIMD3<Float>(panOffset.x, panOffset.y, 0)
        
        // Update rotation based on circular motion
        let angle = atan2(y, x)
        rotationAngle = angle
    }
    
    private func handleSpatialNavigation(x: Float, y: Float) {
        // Advanced spatial navigation for health data
        let magnitude = sqrt(x * x + y * y)
        let angle = atan2(y, x)
        
        // Convert to 3D spatial coordinates
        spatialPosition = SIMD3<Float>(
            x * zoomLevel,
            y * zoomLevel,
            magnitude * 0.5
        )
        
        rotationAngle = angle
        gestureIntensity = magnitude
    }
    
    // MARK: - Motion Processing
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let attitude = motion.attitude
        let acceleration = motion.userAcceleration
        
        // Use device motion for subtle spatial adjustments
        let motionInfluence: Float = 0.1
        let motionOffset = SIMD3<Float>(
            Float(acceleration.x) * motionInfluence,
            Float(acceleration.y) * motionInfluence,
            Float(acceleration.z) * motionInfluence
        )
        
        spatialPosition += motionOffset
        
        // Update rotation from device attitude
        rotationAngle = Float(attitude.roll)
    }
    
    // MARK: - Health Data Navigation
    
    private func selectHealthDataLayer(at location: CGPoint) {
        guard let view = targetView else { return }
        
        // Calculate which layer was tapped based on location
        let viewHeight = view.bounds.height
        let layerHeight = viewHeight / CGFloat(healthDataLayers.count)
        let selectedIndex = Int(location.y / layerHeight)
        
        if selectedIndex >= 0 && selectedIndex < healthDataLayers.count {
            currentLayerIndex = selectedIndex
            
            // Trigger haptic feedback
            triggerHapticFeedback(.selection)
        }
    }
    
    private func navigateToNextLayer() {
        currentLayerIndex = (currentLayerIndex + 1) % healthDataLayers.count
        triggerHapticFeedback(.navigation)
    }
    
    private func navigateToPreviousLayer() {
        currentLayerIndex = (currentLayerIndex - 1 + healthDataLayers.count) % healthDataLayers.count
        triggerHapticFeedback(.navigation)
    }
    
    private func toggleHealthDataNavigation() {
        isHealthDataNavigationActive.toggle()
        triggerHapticFeedback(.action)
    }
    
    private func resetNavigation() {
        panOffset = SIMD2<Float>(0, 0)
        spatialPosition = SIMD3<Float>(0, 0, 0)
        zoomLevel = 1.0
        rotationAngle = 0.0
        currentLayerIndex = 0
        triggerHapticFeedback(.reset)
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHapticFeedback(_ type: HapticFeedbackType) {
        // Since tvOS doesn't have haptic feedback, we'll use audio feedback
        // or trigger feedback on paired devices
        NotificationCenter.default.post(
            name: .hapticFeedbackRequested,
            object: nil,
            userInfo: ["type": type]
        )
    }
    
    // MARK: - Public Interface
    
    func getCurrentLayer() -> HealthDataLayer? {
        guard currentLayerIndex < healthDataLayers.count else { return nil }
        return healthDataLayers[currentLayerIndex]
    }
    
    func getZoomLevel() -> Float {
        return zoomLevel
    }
    
    func getPanOffset() -> SIMD2<Float> {
        return panOffset
    }
    
    func getRotationAngle() -> Float {
        return rotationAngle
    }
    
    func getAllLayers() -> [HealthDataLayer] {
        return healthDataLayers
    }
    
    // MARK: - Cleanup
    
    deinit {
        motionManager?.stopDeviceMotionUpdates()
        NotificationCenter.default.removeObserver(self)
        
        // Remove gesture recognizers
        gestureRecognizers.forEach { recognizer in
            targetView?.removeGestureRecognizer(recognizer)
        }
    }
}

// MARK: - Supporting Types

enum RemoteGesture {
    case tap
    case pan
    case swipe
    case pinch
    case rotate
    case longPress
}

enum RemoteButton {
    case buttonA
    case buttonX
}

enum HapticFeedbackType {
    case selection
    case navigation
    case action
    case reset
}

struct HealthDataLayer {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let dataType: HealthDataType
    let visualizationType: VisualizationType
}

enum HealthDataType {
    case heartRate
    case hrv
    case sleep
    case activity
    case stress
    case bloodPressure
    case oxygenSaturation
    case temperature
}

enum VisualizationType {
    case line
    case area
    case bar
    case scatter
    case heatmap
    case threeDimensional
}

// MARK: - Extensions

extension Notification.Name {
    static let hapticFeedbackRequested = Notification.Name("hapticFeedbackRequested")
}

// MARK: - SwiftUI Integration

@available(tvOS 18.0, *)
struct SpatialHealthDataNavigationView: View {
    @StateObject private var gestureManager = SiriRemoteGestureManager()
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Health Data Layers
            if gestureManager.isHealthDataNavigationActive {
                HealthDataLayersView(gestureManager: gestureManager)
            } else {
                NavigationInstructionsView()
            }
            
            // Gesture Overlay
            GestureOverlayView(gestureManager: gestureManager)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        viewSize = geometry.size
                    }
            }
        )
        .onAppear {
            // Attach gesture manager to the view
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                gestureManager.attachToView(window.rootViewController?.view ?? UIView())
            }
        }
    }
}

struct HealthDataLayersView: View {
    @ObservedObject var gestureManager: SiriRemoteGestureManager
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(gestureManager.getAllLayers().enumerated()), id: \.offset) { index, layer in
                HealthDataLayerView(
                    layer: layer,
                    isSelected: index == gestureManager.currentLayerIndex,
                    gestureManager: gestureManager
                )
                .frame(maxHeight: .infinity)
            }
        }
        .padding()
    }
}

struct HealthDataLayerView: View {
    let layer: HealthDataLayer
    let isSelected: Bool
    @ObservedObject var gestureManager: SiriRemoteGestureManager
    
    var body: some View {
        HStack {
            // Layer Icon
            Image(systemName: layer.icon)
                .font(.title)
                .foregroundColor(layer.color)
                .frame(width: 60)
            
            // Layer Info
            VStack(alignment: .leading, spacing: 8) {
                Text(layer.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(layer.dataType.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Visualization Preview
            VisualizationPreview(
                type: layer.visualizationType,
                color: layer.color,
                intensity: gestureManager.gestureIntensity
            )
            .frame(width: 100, height: 60)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ? layer.color.opacity(0.2) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? layer.color : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .transform3D(
            .init(
                m11: 1, m12: 0, m13: 0, m14: 0,
                m21: 0, m22: 1, m23: 0, m24: 0,
                m31: 0, m32: 0, m33: 1, m34: 0,
                m41: gestureManager.spatialPosition.x * 10,
                m42: gestureManager.spatialPosition.y * 10,
                m43: gestureManager.spatialPosition.z * 10,
                m44: 1
            )
        )
    }
}

struct VisualizationPreview: View {
    let type: VisualizationType
    let color: Color
    let intensity: Float
    
    var body: some View {
        switch type {
        case .line:
            Path { path in
                path.move(to: CGPoint(x: 0, y: 30))
                path.addLine(to: CGPoint(x: 100, y: 30 - CGFloat(intensity) * 20))
            }
            .stroke(color, lineWidth: 2)
            
        case .area:
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
                .frame(height: 30 + CGFloat(intensity) * 20)
            
        case .bar:
            HStack(spacing: 2) {
                ForEach(0..<5) { _ in
                    Rectangle()
                        .fill(color)
                        .frame(width: 8, height: 20 + CGFloat(intensity) * 30)
                }
            }
            
        case .scatter:
            ZStack {
                ForEach(0..<8) { _ in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(
                            x: CGFloat.random(in: 10...90),
                            y: CGFloat.random(in: 10...50)
                        )
                }
            }
            
        case .heatmap:
            Rectangle()
                .fill(RadialGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.1)]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                ))
            
        case .threeDimensional:
            Rectangle()
                .fill(color)
                .rotation3DEffect(.degrees(Double(intensity) * 45), axis: (x: 1, y: 1, z: 0))
        }
    }
}

struct NavigationInstructionsView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Spatial Health Data Navigation")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                InstructionRow(
                    icon: "hand.tap",
                    title: "Tap to Activate",
                    description: "Tap the touchpad to enter navigation mode"
                )
                
                InstructionRow(
                    icon: "hand.draw",
                    title: "Pan to Navigate",
                    description: "Move your finger to explore health data layers"
                )
                
                InstructionRow(
                    icon: "arrow.up.arrow.down",
                    title: "Swipe to Switch",
                    description: "Swipe up/down to change data layers"
                )
                
                InstructionRow(
                    icon: "magnifyingglass",
                    title: "Pinch to Zoom",
                    description: "Pinch to zoom in/out of data visualizations"
                )
            }
        }
        .padding()
    }
}

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.cyan)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GestureOverlayView: View {
    @ObservedObject var gestureManager: SiriRemoteGestureManager
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 10) {
                    if gestureManager.isGestureActive {
                        HStack {
                            Image(systemName: gestureIcon)
                                .font(.title2)
                                .foregroundColor(.cyan)
                            
                            Text(gestureText)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    }
                    
                    if gestureManager.isHealthDataNavigationActive {
                        VStack(spacing: 5) {
                            Text("Layer: \(gestureManager.getCurrentLayer()?.name ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Text("Zoom: \(String(format: "%.1fx", gestureManager.getZoomLevel()))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var gestureIcon: String {
        switch gestureManager.currentGesture {
        case .tap: return "hand.tap"
        case .pan: return "hand.draw"
        case .swipe: return "arrow.up.arrow.down"
        case .pinch: return "magnifyingglass"
        case .rotate: return "arrow.clockwise"
        case .longPress: return "hand.point.up"
        case .none: return ""
        }
    }
    
    private var gestureText: String {
        switch gestureManager.currentGesture {
        case .tap: return "Tap"
        case .pan: return "Pan"
        case .swipe: return "Swipe"
        case .pinch: return "Pinch"
        case .rotate: return "Rotate"
        case .longPress: return "Long Press"
        case .none: return ""
        }
    }
}

// MARK: - Extensions

extension HealthDataType {
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .hrv: return "Heart Rate Variability"
        case .sleep: return "Sleep Quality"
        case .activity: return "Daily Activity"
        case .stress: return "Stress Level"
        case .bloodPressure: return "Blood Pressure"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .temperature: return "Body Temperature"
        }
    }
}

#Preview {
    SpatialHealthDataNavigationView()
}