import Foundation
import ARKit
import RealityKit
import SwiftUI
import Combine
import UIKit

/// AR Gesture Controls System
/// Provides intuitive gesture-based interactions for health data in augmented reality
@available(iOS 18.0, *)
public class ARGestureControls: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isGestureRecognitionActive = false
    @Published public private(set) var currentGesture: RecognizedGesture?
    @Published public private(set) var gestureConfidence: Double = 0.0
    @Published public private(set) var availableGestures: [GestureType] = []
    @Published public private(set) var gestureStatus: GestureStatus = .inactive
    @Published public private(set) var lastError: String?
    @Published public private(set) var gestureHistory: [GestureEvent] = []
    
    // MARK: - Private Properties
    private var arSession: ARSession?
    private var arView: ARView?
    private var cancellables = Set<AnyCancellable>()
    private let gestureQueue = DispatchQueue(label: "ar.gesture.controls", qos: .userInteractive)
    
    // Gesture recognition components
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private var handTrackingSession: ARHandTrackingSession?
    private var bodyTrackingSession: ARBodyTrackingSession?
    private var faceTrackingSession: ARFaceTrackingSession?
    
    // Gesture processing
    private var gestureBuffer: [GestureData] = []
    private var gestureThresholds = GestureThresholds()
    private var gestureCallbacks: [GestureType: [GestureCallback]] = [:]
    
    // Performance monitoring
    private var gestureCount = 0
    private var recognitionAccuracy: Double = 0.0
    private var averageRecognitionTime: TimeInterval = 0.0
    
    // MARK: - Initialization
    public override init() {
        super.init()
        setupGestureSystem()
        setupGestureThresholds()
    }
    
    // MARK: - Public Methods
    
    /// Start gesture recognition
    public func startGestureRecognition() async throws {
        guard ARSession.isSupported else {
            throw ARError(.unsupportedConfiguration)
        }
        
        try await gestureQueue.async {
            self.setupARSession()
            self.setupGestureRecognizers()
            self.arSession?.run(self.createGestureConfiguration())
            self.isGestureRecognitionActive = true
            self.gestureStatus = .active
        }
    }
    
    /// Stop gesture recognition
    public func stopGestureRecognition() {
        gestureQueue.async {
            self.arSession?.pause()
            self.isGestureRecognitionActive = false
            self.gestureStatus = .inactive
            self.clearGestureRecognizers()
        }
    }
    
    /// Register gesture callback
    public func registerGestureCallback(_ gesture: GestureType, callback: @escaping GestureCallback) {
        if gestureCallbacks[gesture] == nil {
            gestureCallbacks[gesture] = []
        }
        gestureCallbacks[gesture]?.append(callback)
    }
    
    /// Unregister gesture callback
    public func unregisterGestureCallback(_ gesture: GestureType, callback: @escaping GestureCallback) {
        gestureCallbacks[gesture]?.removeAll { $0 == callback }
    }
    
    /// Enable specific gesture type
    public func enableGesture(_ gesture: GestureType) {
        availableGestures.append(gesture)
        setupGestureRecognizer(for: gesture)
    }
    
    /// Disable specific gesture type
    public func disableGesture(_ gesture: GestureType) {
        availableGestures.removeAll { $0 == gesture }
        removeGestureRecognizer(for: gesture)
    }
    
    /// Set gesture sensitivity
    public func setGestureSensitivity(_ sensitivity: GestureSensitivity) {
        updateGestureThresholds(sensitivity: sensitivity)
    }
    
    /// Get gesture statistics
    public func getGestureStatistics() -> GestureStatistics {
        return GestureStatistics(
            totalGestures: gestureCount,
            recognitionAccuracy: recognitionAccuracy,
            averageRecognitionTime: averageRecognitionTime,
            activeGestures: availableGestures.count,
            currentGesture: currentGesture?.type
        )
    }
    
    /// Clear gesture history
    public func clearGestureHistory() {
        gestureHistory.removeAll()
    }
    
    // MARK: - Private Setup Methods
    
    private func setupGestureSystem() {
        // Initialize available gestures
        availableGestures = [
            .tap,
            .doubleTap,
            .longPress,
            .swipe,
            .pinch,
            .rotation,
            .pan,
            .wave,
            .point,
            .thumbsUp,
            .thumbsDown,
            .peace,
            .ok,
            .fist,
            .openHand
        ]
        
        // Setup gesture status monitoring
        $gestureStatus
            .sink { [weak self] status in
                self?.handleGestureStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func setupGestureThresholds() {
        // Configure gesture recognition thresholds
        gestureThresholds.tap = TapThresholds(
            maxDuration: 0.3,
            maxDistance: 10.0
        )
        
        gestureThresholds.swipe = SwipeThresholds(
            minDistance: 50.0,
            maxDuration: 0.5,
            minVelocity: 300.0
        )
        
        gestureThresholds.pinch = PinchThresholds(
            minScale: 0.5,
            maxScale: 2.0,
            minDuration: 0.2
        )
        
        gestureThresholds.rotation = RotationThresholds(
            minAngle: 15.0,
            minDuration: 0.3
        )
        
        gestureThresholds.handGesture = HandGestureThresholds(
            confidenceThreshold: 0.7,
            minDuration: 0.5,
            maxDistance: 100.0
        )
    }
    
    private func setupARSession() {
        arSession = ARSession()
        arSession?.delegate = self
        
        // Configure AR view for gesture recognition
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        arView?.session = arSession
        arView?.renderOptions = [.disablePersonOcclusion]
        
        // Enable advanced features for gesture recognition
        arView?.environment.sceneUnderstanding.options = [.occlusion]
        arView?.environment.lighting.intensityExponent = 1.0
    }
    
    private func createGestureConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        configuration.isAutoFocusEnabled = true
        
        // Enable advanced features for gesture recognition
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        return configuration
    }
    
    // MARK: - Gesture Recognizer Setup
    
    private func setupGestureRecognizers() {
        // Setup UIKit gesture recognizers
        setupUIKitGestureRecognizers()
        
        // Setup AR gesture tracking
        setupARGestureTracking()
    }
    
    private func setupUIKitGestureRecognizers() {
        // Tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.numberOfTapsRequired = 1
        gestureRecognizers.append(tapGesture)
        
        // Double tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        gestureRecognizers.append(doubleTapGesture)
        
        // Long press gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.5
        gestureRecognizers.append(longPressGesture)
        
        // Swipe gesture recognizers
        let swipeDirections: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for direction in swipeDirections {
            let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
            swipeGesture.direction = direction
            gestureRecognizers.append(swipeGesture)
        }
        
        // Pinch gesture recognizer
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        gestureRecognizers.append(pinchGesture)
        
        // Rotation gesture recognizer
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        gestureRecognizers.append(rotationGesture)
        
        // Pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        gestureRecognizers.append(panGesture)
        
        // Add gesture recognizers to AR view
        gestureRecognizers.forEach { gestureRecognizer in
            arView?.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    private func setupARGestureTracking() {
        // Setup hand tracking for advanced gestures
        if ARBodyTrackingConfiguration.isSupported {
            let bodyConfig = ARBodyTrackingConfiguration()
            bodyConfig.planeDetection = [.horizontal, .vertical]
            arSession?.run(bodyConfig)
        }
        
        // Setup face tracking for facial gestures
        if ARFaceTrackingConfiguration.isSupported {
            let faceConfig = ARFaceTrackingConfiguration()
            arSession?.run(faceConfig)
        }
    }
    
    private func setupGestureRecognizer(for gesture: GestureType) {
        switch gesture {
        case .tap, .doubleTap, .longPress, .swipe, .pinch, .rotation, .pan:
            // UIKit gesture recognizers are already set up
            break
        case .wave, .point, .thumbsUp, .thumbsDown, .peace, .ok, .fist, .openHand:
            // These are handled by AR hand tracking
            setupHandGestureRecognition(for: gesture)
        }
    }
    
    private func removeGestureRecognizer(for gesture: GestureType) {
        // Remove specific gesture recognizer
        // Implementation would remove the specific recognizer
    }
    
    private func setupHandGestureRecognition(for gesture: GestureType) {
        // Setup hand gesture recognition using AR hand tracking
        // This would configure the hand tracking session for specific gestures
    }
    
    private func clearGestureRecognizers() {
        gestureRecognizers.forEach { recognizer in
            arView?.removeGestureRecognizer(recognizer)
        }
        gestureRecognizers.removeAll()
    }
    
    // MARK: - UIKit Gesture Handlers
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        let gestureData = GestureData(
            type: .tap,
            location: location,
            timestamp: Date(),
            confidence: 1.0
        )
        
        processGesture(gestureData)
    }
    
    @objc private func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        let gestureData = GestureData(
            type: .doubleTap,
            location: location,
            timestamp: Date(),
            confidence: 1.0
        )
        
        processGesture(gestureData)
    }
    
    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: arView)
        let gestureData = GestureData(
            type: .longPress,
            location: location,
            timestamp: Date(),
            confidence: 1.0
        )
        
        processGesture(gestureData)
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        let location = gesture.location(in: arView)
        let direction = convertSwipeDirection(gesture.direction)
        
        let gestureData = GestureData(
            type: .swipe,
            location: location,
            timestamp: Date(),
            confidence: 1.0,
            direction: direction
        )
        
        processGesture(gestureData)
    }
    
    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        let location = gesture.location(in: arView)
        let scale = gesture.scale
        
        let gestureData = GestureData(
            type: .pinch,
            location: location,
            timestamp: Date(),
            confidence: 1.0,
            scale: scale
        )
        
        processGesture(gestureData)
    }
    
    @objc private func handleRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        let location = gesture.location(in: arView)
        let rotation = gesture.rotation
        
        let gestureData = GestureData(
            type: .rotation,
            location: location,
            timestamp: Date(),
            confidence: 1.0,
            rotation: rotation
        )
        
        processGesture(gestureData)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: arView)
        let translation = gesture.translation(in: arView)
        let velocity = gesture.velocity(in: arView)
        
        let gestureData = GestureData(
            type: .pan,
            location: location,
            timestamp: Date(),
            confidence: 1.0,
            translation: translation,
            velocity: velocity
        )
        
        processGesture(gestureData)
    }
    
    // MARK: - Gesture Processing
    
    private func processGesture(_ gestureData: GestureData) {
        let startTime = Date()
        
        // Validate gesture against thresholds
        guard validateGesture(gestureData) else { return }
        
        // Create recognized gesture
        let recognizedGesture = RecognizedGesture(
            type: gestureData.type,
            location: gestureData.location,
            timestamp: gestureData.timestamp,
            confidence: gestureData.confidence,
            metadata: gestureData.metadata
        )
        
        // Update current gesture
        Task { @MainActor in
            self.currentGesture = recognizedGesture
            self.gestureConfidence = gestureData.confidence
            self.gestureCount += 1
        }
        
        // Add to gesture history
        let gestureEvent = GestureEvent(
            gesture: recognizedGesture,
            processingTime: Date().timeIntervalSince(startTime)
        )
        
        Task { @MainActor in
            self.gestureHistory.append(gestureEvent)
            
            // Keep history manageable
            if self.gestureHistory.count > 100 {
                self.gestureHistory.removeFirst()
            }
        }
        
        // Update recognition accuracy
        updateRecognitionAccuracy(gestureData: gestureData)
        
        // Execute gesture callbacks
        executeGestureCallbacks(gesture: recognizedGesture)
    }
    
    private func validateGesture(_ gestureData: GestureData) -> Bool {
        switch gestureData.type {
        case .tap:
            return validateTapGesture(gestureData)
        case .swipe:
            return validateSwipeGesture(gestureData)
        case .pinch:
            return validatePinchGesture(gestureData)
        case .rotation:
            return validateRotationGesture(gestureData)
        case .handGesture:
            return validateHandGesture(gestureData)
        default:
            return true
        }
    }
    
    private func validateTapGesture(_ gestureData: GestureData) -> Bool {
        // Validate tap gesture against thresholds
        return gestureData.confidence >= gestureThresholds.tap.confidenceThreshold
    }
    
    private func validateSwipeGesture(_ gestureData: GestureData) -> Bool {
        guard let velocity = gestureData.velocity else { return false }
        
        let distance = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        return distance >= gestureThresholds.swipe.minVelocity
    }
    
    private func validatePinchGesture(_ gestureData: GestureData) -> Bool {
        guard let scale = gestureData.scale else { return false }
        
        return scale >= gestureThresholds.pinch.minScale && scale <= gestureThresholds.pinch.maxScale
    }
    
    private func validateRotationGesture(_ gestureData: GestureData) -> Bool {
        guard let rotation = gestureData.rotation else { return false }
        
        return abs(rotation) >= gestureThresholds.rotation.minAngle
    }
    
    private func validateHandGesture(_ gestureData: GestureData) -> Bool {
        return gestureData.confidence >= gestureThresholds.handGesture.confidenceThreshold
    }
    
    private func updateRecognitionAccuracy(gestureData: GestureData) {
        // Update recognition accuracy based on gesture confidence
        let newAccuracy = (recognitionAccuracy * Double(gestureCount - 1) + gestureData.confidence) / Double(gestureCount)
        recognitionAccuracy = newAccuracy
    }
    
    private func executeGestureCallbacks(gesture: RecognizedGesture) {
        guard let callbacks = gestureCallbacks[gesture.type] else { return }
        
        for callback in callbacks {
            callback(gesture)
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertSwipeDirection(_ direction: UISwipeGestureRecognizer.Direction) -> SwipeDirection {
        switch direction {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        default:
            return .up
        }
    }
    
    private func updateGestureThresholds(sensitivity: GestureSensitivity) {
        switch sensitivity {
        case .low:
            gestureThresholds.tap.confidenceThreshold = 0.9
            gestureThresholds.swipe.minVelocity = 500.0
            gestureThresholds.handGesture.confidenceThreshold = 0.9
        case .medium:
            gestureThresholds.tap.confidenceThreshold = 0.7
            gestureThresholds.swipe.minVelocity = 300.0
            gestureThresholds.handGesture.confidenceThreshold = 0.7
        case .high:
            gestureThresholds.tap.confidenceThreshold = 0.5
            gestureThresholds.swipe.minVelocity = 200.0
            gestureThresholds.handGesture.confidenceThreshold = 0.5
        }
    }
    
    // MARK: - Status Management
    
    private func handleGestureStatusChange(_ status: GestureStatus) {
        // Handle gesture status changes
    }
}

// MARK: - ARSessionDelegate

@available(iOS 18.0, *)
extension ARGestureControls: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Process AR frame for advanced gesture recognition
        processARFrame(frame)
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle new AR anchors
    }
    
    public func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        // Handle removed AR anchors
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        lastError = error.localizedDescription
        gestureStatus = .error
    }
    
    // MARK: - AR Frame Processing
    
    private func processARFrame(_ frame: ARFrame) {
        // Process AR frame for hand tracking and advanced gestures
        if let bodyAnchor = frame.anchors.first(where: { $0 is ARBodyAnchor }) as? ARBodyAnchor {
            processBodyTracking(bodyAnchor)
        }
        
        if let faceAnchor = frame.anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor {
            processFaceTracking(faceAnchor)
        }
    }
    
    private func processBodyTracking(_ bodyAnchor: ARBodyAnchor) {
        // Process body tracking for gesture recognition
        // This would analyze hand positions and movements
    }
    
    private func processFaceTracking(_ faceAnchor: ARFaceAnchor) {
        // Process face tracking for facial gestures
        // This would analyze facial expressions and movements
    }
}

// MARK: - Supporting Types

@available(iOS 18.0, *)
public struct RecognizedGesture {
    public let type: GestureType
    public let location: CGPoint
    public let timestamp: Date
    public let confidence: Double
    public let metadata: [String: Any]
    
    public init(type: GestureType, location: CGPoint, timestamp: Date, confidence: Double, metadata: [String: Any] = [:]) {
        self.type = type
        self.location = location
        self.timestamp = timestamp
        self.confidence = confidence
        self.metadata = metadata
    }
}

public enum GestureType: String, CaseIterable {
    case tap = "Tap"
    case doubleTap = "Double Tap"
    case longPress = "Long Press"
    case swipe = "Swipe"
    case pinch = "Pinch"
    case rotation = "Rotation"
    case pan = "Pan"
    case wave = "Wave"
    case point = "Point"
    case thumbsUp = "Thumbs Up"
    case thumbsDown = "Thumbs Down"
    case peace = "Peace"
    case ok = "OK"
    case fist = "Fist"
    case openHand = "Open Hand"
    case handGesture = "Hand Gesture"
}

public enum GestureStatus: String, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case error = "Error"
}

public enum GestureSensitivity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

public enum SwipeDirection: String, CaseIterable {
    case up = "Up"
    case down = "Down"
    case left = "Left"
    case right = "Right"
}

public struct GestureData {
    public let type: GestureType
    public let location: CGPoint
    public let timestamp: Date
    public let confidence: Double
    public let direction: SwipeDirection?
    public let scale: CGFloat?
    public let rotation: CGFloat?
    public let translation: CGPoint?
    public let velocity: CGPoint?
    public let metadata: [String: Any]
    
    public init(type: GestureType, location: CGPoint, timestamp: Date, confidence: Double, direction: SwipeDirection? = nil, scale: CGFloat? = nil, rotation: CGFloat? = nil, translation: CGPoint? = nil, velocity: CGPoint? = nil, metadata: [String: Any] = [:]) {
        self.type = type
        self.location = location
        self.timestamp = timestamp
        self.confidence = confidence
        self.direction = direction
        self.scale = scale
        self.rotation = rotation
        self.translation = translation
        self.velocity = velocity
        self.metadata = metadata
    }
}

public struct GestureEvent {
    public let gesture: RecognizedGesture
    public let processingTime: TimeInterval
    public let timestamp: Date
    
    public init(gesture: RecognizedGesture, processingTime: TimeInterval, timestamp: Date = Date()) {
        self.gesture = gesture
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

public struct GestureStatistics {
    public let totalGestures: Int
    public let recognitionAccuracy: Double
    public let averageRecognitionTime: TimeInterval
    public let activeGestures: Int
    public let currentGesture: GestureType?
    
    public init(totalGestures: Int, recognitionAccuracy: Double, averageRecognitionTime: TimeInterval, activeGestures: Int, currentGesture: GestureType?) {
        self.totalGestures = totalGestures
        self.recognitionAccuracy = recognitionAccuracy
        self.averageRecognitionTime = averageRecognitionTime
        self.activeGestures = activeGestures
        self.currentGesture = currentGesture
    }
}

// MARK: - Gesture Thresholds

public struct GestureThresholds {
    public var tap: TapThresholds
    public var swipe: SwipeThresholds
    public var pinch: PinchThresholds
    public var rotation: RotationThresholds
    public var handGesture: HandGestureThresholds
    
    public init() {
        self.tap = TapThresholds()
        self.swipe = SwipeThresholds()
        self.pinch = PinchThresholds()
        self.rotation = RotationThresholds()
        self.handGesture = HandGestureThresholds()
    }
}

public struct TapThresholds {
    public let maxDuration: TimeInterval
    public let maxDistance: CGFloat
    public var confidenceThreshold: Double
    
    public init(maxDuration: TimeInterval = 0.3, maxDistance: CGFloat = 10.0, confidenceThreshold: Double = 0.7) {
        self.maxDuration = maxDuration
        self.maxDistance = maxDistance
        self.confidenceThreshold = confidenceThreshold
    }
}

public struct SwipeThresholds {
    public let minDistance: CGFloat
    public let maxDuration: TimeInterval
    public let minVelocity: CGFloat
    
    public init(minDistance: CGFloat = 50.0, maxDuration: TimeInterval = 0.5, minVelocity: CGFloat = 300.0) {
        self.minDistance = minDistance
        self.maxDuration = maxDuration
        self.minVelocity = minVelocity
    }
}

public struct PinchThresholds {
    public let minScale: CGFloat
    public let maxScale: CGFloat
    public let minDuration: TimeInterval
    
    public init(minScale: CGFloat = 0.5, maxScale: CGFloat = 2.0, minDuration: TimeInterval = 0.2) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.minDuration = minDuration
    }
}

public struct RotationThresholds {
    public let minAngle: CGFloat
    public let minDuration: TimeInterval
    
    public init(minAngle: CGFloat = 15.0, minDuration: TimeInterval = 0.3) {
        self.minAngle = minAngle
        self.minDuration = minDuration
    }
}

public struct HandGestureThresholds {
    public let confidenceThreshold: Double
    public let minDuration: TimeInterval
    public let maxDistance: CGFloat
    
    public init(confidenceThreshold: Double = 0.7, minDuration: TimeInterval = 0.5, maxDistance: CGFloat = 100.0) {
        self.confidenceThreshold = confidenceThreshold
        self.minDuration = minDuration
        self.maxDistance = maxDistance
    }
}

// MARK: - Gesture Callback

public typealias GestureCallback = (RecognizedGesture) -> Void 