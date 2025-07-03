import Foundation
import CoreMotion
import HealthKit
import Combine
import CoreML
import UserNotifications
import CoreLocation

/// Advanced Fall Detection System
/// Machine learning-powered fall detection with motion sensor fusion and contextual analysis
class FallDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var fallDetectionStatus: FallDetectionStatus = .monitoring
    @Published var activeFallAlerts: [FallAlert] = []
    @Published var isFallDetectionEnabled = false
    @Published var lastFallCheck: Date?
    @Published var fallRiskLevel: FallRiskLevel = .low
    @Published var fallDetectionSensitivity: FallSensitivity = .medium
    
    // MARK: - Private Properties
    private var motionManager: CMMotionManager?
    private var healthDataManager: HealthDataManager?
    private var emergencyAlertManager: EmergencyAlertManager?
    private var locationManager: CLLocationManager?
    
    // Motion data processing
    private var accelerometerData: [CMAccelerometerData] = []
    private var gyroscopeData: [CMGyroData] = []
    private var deviceMotionData: [CMDeviceMotion] = []
    private let maxDataSamples = 100
    
    // Fall detection ML model
    private var fallDetectionModel: MLModel?
    private var fallPredictionModel: MLModel?
    
    // Fall analysis parameters
    private var fallThresholds: FallThresholds = FallThresholds()
    private var fallHistory: [FallEvent] = []
    private var falsePositiveHistory: [FalsePositiveEvent] = []
    
    // Real-time monitoring
    private var motionUpdateTimer: Timer?
    private var fallAnalysisTimer: Timer?
    private var motionDataQueue: OperationQueue
    
    // Emergency response
    private var fallResponseProtocol: FallResponseProtocol = FallResponseProtocol()
    private var pendingFallAlert: FallAlert?
    private var fallConfirmationTimer: Timer?
    private let fallConfirmationDelay: TimeInterval = 15.0 // 15 seconds to cancel
    
    // Context analysis
    private var activityContext: ActivityContext = .unknown
    private var environmentContext: EnvironmentContext = .unknown
    private var userBehaviorPattern: UserBehaviorPattern = UserBehaviorPattern()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        motionDataQueue = OperationQueue()
        motionDataQueue.maxConcurrentOperationCount = 1
        motionDataQueue.qualityOfService = .userInteractive
        
        setupFallDetector()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupFallDetector() {
        initializeComponents()
        loadFallDetectionModels()
        configureFallThresholds()
        setupMotionMonitoring()
    }
    
    private func initializeComponents() {
        motionManager = CMMotionManager()
        healthDataManager = HealthDataManager()
        emergencyAlertManager = EmergencyAlertManager()
        locationManager = CLLocationManager()
        
        setupLocationManager()
        setupDataSubscriptions()
    }
    
    private func setupLocationManager() {
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setupDataSubscriptions() {
        healthDataManager?.$latestHealthData
            .compactMap { $0 }
            .sink { [weak self] healthData in
                self?.updateFallRiskAssessment(with: healthData)
            }
            .store(in: &cancellables)
    }
    
    private func loadFallDetectionModels() {
        // Load pre-trained fall detection models
        Task {
            await loadMLModels()
        }
    }
    
    private func loadMLModels() async {
        // In a real implementation, these would be actual ML models
        // For now, we'll use placeholder implementations
        print("Loading fall detection ML models...")
    }
    
    private func configureFallThresholds() {
        fallThresholds = FallThresholds(
            accelerationThreshold: 2.5, // g-force
            gyroscopeThreshold: 3.0, // rad/s
            impactThreshold: 4.0, // g-force
            freefall: 0.3, // g-force
            postFallMovement: 0.5, // g-force
            motionVarianceThreshold: 1.5,
            orientationChangeThreshold: 60.0 // degrees
        )
    }
    
    private func setupMotionMonitoring() {
        guard let motionManager = motionManager else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1 // 10 Hz
        motionManager.gyroUpdateInterval = 0.1 // 10 Hz
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 Hz
    }
    
    // MARK: - Fall Detection Control
    
    func startFallDetection() {
        guard !isFallDetectionEnabled else { return }
        
        isFallDetectionEnabled = true
        fallDetectionStatus = .monitoring
        
        startMotionUpdates()
        startFallAnalysis()
        
        print("Fall detection started")
    }
    
    func stopFallDetection() {
        isFallDetectionEnabled = false
        fallDetectionStatus = .inactive
        
        stopMotionUpdates()
        stopFallAnalysis()
        
        print("Fall detection stopped")
    }
    
    private func startMotionUpdates() {
        guard let motionManager = motionManager else { return }
        
        // Start accelerometer updates
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: motionDataQueue) { [weak self] data, error in
                guard let data = data else { return }
                self?.processAccelerometerData(data)
            }
        }
        
        // Start gyroscope updates
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: motionDataQueue) { [weak self] data, error in
                guard let data = data else { return }
                self?.processGyroscopeData(data)
            }
        }
        
        // Start device motion updates
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: motionDataQueue) { [weak self] data, error in
                guard let data = data else { return }
                self?.processDeviceMotionData(data)
            }
        }
    }
    
    private func stopMotionUpdates() {
        motionManager?.stopAccelerometerUpdates()
        motionManager?.stopGyroUpdates()
        motionManager?.stopDeviceMotionUpdates()
    }
    
    private func startFallAnalysis() {
        fallAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.performFallAnalysis()
        }
    }
    
    private func stopFallAnalysis() {
        fallAnalysisTimer?.invalidate()
        fallAnalysisTimer = nil
    }
    
    // MARK: - Motion Data Processing
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        accelerometerData.append(data)
        
        if accelerometerData.count > maxDataSamples {
            accelerometerData.removeFirst()
        }
        
        // Real-time fall detection check
        checkForImmediateFallIndicators(data)
    }
    
    private func processGyroscopeData(_ data: CMGyroData) {
        gyroscopeData.append(data)
        
        if gyroscopeData.count > maxDataSamples {
            gyroscopeData.removeFirst()
        }
    }
    
    private func processDeviceMotionData(_ data: CMDeviceMotion) {
        deviceMotionData.append(data)
        
        if deviceMotionData.count > maxDataSamples {
            deviceMotionData.removeFirst()
        }
        
        // Update activity context
        updateActivityContext(from: data)
    }
    
    private func checkForImmediateFallIndicators(_ data: CMAccelerometerData) {
        let acceleration = sqrt(pow(data.acceleration.x, 2) + 
                               pow(data.acceleration.y, 2) + 
                               pow(data.acceleration.z, 2))
        
        // Check for impact threshold
        if acceleration > fallThresholds.impactThreshold {
            Task {
                await handlePotentialFallEvent(acceleration: acceleration, timestamp: data.timestamp)
            }
        }
        
        // Check for freefall
        if acceleration < fallThresholds.freefall {
            Task {
                await handleFreefallEvent(acceleration: acceleration, timestamp: data.timestamp)
            }
        }
    }
    
    // MARK: - Fall Analysis
    
    private func performFallAnalysis() {
        Task {
            await analyzeFallProbability()
        }
    }
    
    private func analyzeFallProbability() async {
        guard accelerometerData.count >= 10 && gyroscopeData.count >= 10 else { return }
        
        lastFallCheck = Date()
        
        let fallProbability = await calculateFallProbability()
        
        if fallProbability > getSensitivityThreshold() {
            await handlePotentialFall(probability: fallProbability)
        }
    }
    
    private func calculateFallProbability() async -> Double {
        // Advanced fall detection algorithm combining multiple factors
        
        let accelerationAnalysis = analyzeAccelerationPatterns()
        let rotationAnalysis = analyzeRotationPatterns()
        let motionVarianceAnalysis = analyzeMotionVariance()
        let orientationAnalysis = analyzeOrientationChanges()
        let contextualAnalysis = analyzeContextualFactors()
        
        // Weighted combination of analysis results
        let fallProbability = (
            accelerationAnalysis * 0.3 +
            rotationAnalysis * 0.25 +
            motionVarianceAnalysis * 0.2 +
            orientationAnalysis * 0.15 +
            contextualAnalysis * 0.1
        )
        
        return min(max(fallProbability, 0.0), 1.0)
    }
    
    private func analyzeAccelerationPatterns() -> Double {
        guard accelerometerData.count >= 10 else { return 0.0 }
        
        let recentData = Array(accelerometerData.suffix(10))
        var maxAcceleration = 0.0
        var minAcceleration = Double.infinity
        
        for data in recentData {
            let magnitude = sqrt(pow(data.acceleration.x, 2) + 
                               pow(data.acceleration.y, 2) + 
                               pow(data.acceleration.z, 2))
            maxAcceleration = max(maxAcceleration, magnitude)
            minAcceleration = min(minAcceleration, magnitude)
        }
        
        // Look for impact followed by stillness pattern
        let impactScore = maxAcceleration > fallThresholds.impactThreshold ? 0.8 : 0.0
        let stillnessScore = minAcceleration < fallThresholds.postFallMovement ? 0.6 : 0.0
        
        return (impactScore + stillnessScore) / 2.0
    }
    
    private func analyzeRotationPatterns() -> Double {
        guard gyroscopeData.count >= 10 else { return 0.0 }
        
        let recentData = Array(gyroscopeData.suffix(10))
        var maxRotation = 0.0
        
        for data in recentData {
            let magnitude = sqrt(pow(data.rotationRate.x, 2) + 
                               pow(data.rotationRate.y, 2) + 
                               pow(data.rotationRate.z, 2))
            maxRotation = max(maxRotation, magnitude)
        }
        
        return maxRotation > fallThresholds.gyroscopeThreshold ? 0.7 : 0.0
    }
    
    private func analyzeMotionVariance() -> Double {
        guard accelerometerData.count >= 20 else { return 0.0 }
        
        let recentData = Array(accelerometerData.suffix(20))
        let magnitudes = recentData.map { data in
            sqrt(pow(data.acceleration.x, 2) + 
                 pow(data.acceleration.y, 2) + 
                 pow(data.acceleration.z, 2))
        }
        
        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let variance = magnitudes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(magnitudes.count)
        
        return variance > fallThresholds.motionVarianceThreshold ? 0.6 : 0.0
    }
    
    private func analyzeOrientationChanges() -> Double {
        guard deviceMotionData.count >= 5 else { return 0.0 }
        
        let recentData = Array(deviceMotionData.suffix(5))
        guard let firstAttitude = recentData.first?.attitude,
              let lastAttitude = recentData.last?.attitude else { return 0.0 }
        
        let pitchChange = abs(lastAttitude.pitch - firstAttitude.pitch) * 180 / .pi
        let rollChange = abs(lastAttitude.roll - firstAttitude.roll) * 180 / .pi
        
        let maxChange = max(pitchChange, rollChange)
        
        return maxChange > fallThresholds.orientationChangeThreshold ? 0.5 : 0.0
    }
    
    private func analyzeContextualFactors() -> Double {
        var contextScore = 0.0
        
        // Activity context
        switch activityContext {
        case .walking, .running:
            contextScore += 0.3
        case .stationary:
            contextScore += 0.1
        case .unknown:
            contextScore += 0.2
        }
        
        // Fall risk level
        switch fallRiskLevel {
        case .high, .critical:
            contextScore += 0.4
        case .medium:
            contextScore += 0.2
        case .low:
            contextScore += 0.1
        }
        
        return min(contextScore, 1.0)
    }
    
    private func getSensitivityThreshold() -> Double {
        switch fallDetectionSensitivity {
        case .low:
            return 0.8
        case .medium:
            return 0.6
        case .high:
            return 0.4
        }
    }
    
    // MARK: - Fall Event Handling
    
    private func handlePotentialFallEvent(acceleration: Double, timestamp: TimeInterval) async {
        let fallEvent = FallEvent(
            type: .impact,
            severity: .high,
            acceleration: acceleration,
            timestamp: Date(timeIntervalSinceReferenceDate: timestamp),
            confidence: 0.8,
            location: await getCurrentLocation()
        )
        
        await triggerFallAlert(for: fallEvent)
    }
    
    private func handleFreefallEvent(acceleration: Double, timestamp: TimeInterval) async {
        let fallEvent = FallEvent(
            type: .freefall,
            severity: .medium,
            acceleration: acceleration,
            timestamp: Date(timeIntervalSinceReferenceDate: timestamp),
            confidence: 0.6,
            location: await getCurrentLocation()
        )
        
        await triggerFallAlert(for: fallEvent)
    }
    
    private func handlePotentialFall(probability: Double) async {
        let fallEvent = FallEvent(
            type: .gradualFall,
            severity: .medium,
            acceleration: 0.0,
            timestamp: Date(),
            confidence: probability,
            location: await getCurrentLocation()
        )
        
        await triggerFallAlert(for: fallEvent)
    }
    
    private func triggerFallAlert(for event: FallEvent) async {
        fallHistory.append(event)
        
        let alert = FallAlert(
            id: UUID(),
            event: event,
            timestamp: Date(),
            status: .pending,
            responseLevel: determineFallResponseLevel(for: event)
        )
        
        await MainActor.run {
            activeFallAlerts.append(alert)
            fallDetectionStatus = .fallDetected
            pendingFallAlert = alert
        }
        
        // Start confirmation timer
        startFallConfirmationTimer(for: alert)
        
        // Show immediate alert to user
        await showFallAlert(alert)
    }
    
    private func determineFallResponseLevel(for event: FallEvent) -> FallResponseLevel {
        if event.confidence > 0.8 || event.severity == .critical {
            return .immediate
        } else if event.confidence > 0.6 || event.severity == .high {
            return .urgent
        } else {
            return .monitoring
        }
    }
    
    private func startFallConfirmationTimer(for alert: FallAlert) {
        fallConfirmationTimer?.invalidate()
        
        fallConfirmationTimer = Timer.scheduledTimer(withTimeInterval: fallConfirmationDelay, repeats: false) { [weak self] _ in
            Task {
                await self?.confirmFallAlert(alert)
            }
        }
    }
    
    private func confirmFallAlert(_ alert: FallAlert) async {
        // If user hasn't cancelled, proceed with emergency response
        guard pendingFallAlert?.id == alert.id else { return }
        
        await executeFallEmergencyResponse(alert)
        
        await MainActor.run {
            pendingFallAlert = nil
        }
    }
    
    private func executeFallEmergencyResponse(_ alert: FallAlert) async {
        switch alert.responseLevel {
        case .immediate:
            await executeImmediateFallResponse(alert)
        case .urgent:
            await executeUrgentFallResponse(alert)
        case .monitoring:
            await executeMonitoringFallResponse(alert)
        }
    }
    
    private func executeImmediateFallResponse(_ alert: FallAlert) async {
        // Call emergency services
        await callEmergencyServices(for: alert)
        
        // Notify emergency contacts with location
        await notifyEmergencyContacts(for: alert, priority: .critical)
        
        // Send medical data
        await transmitMedicalData(for: alert)
        
        // Continue monitoring for movement
        await enhancePostFallMonitoring()
    }
    
    private func executeUrgentFallResponse(_ alert: FallAlert) async {
        // Notify emergency contacts
        await notifyEmergencyContacts(for: alert, priority: .high)
        
        // Prepare for emergency services
        await prepareEmergencyData(for: alert)
        
        // Show urgent notification
        await showUrgentFallNotification(alert)
    }
    
    private func executeMonitoringFallResponse(_ alert: FallAlert) async {
        // Enhanced monitoring
        await enhancePostFallMonitoring()
        
        // Log event
        await logFallEvent(alert)
    }
    
    // MARK: - Emergency Response
    
    private func callEmergencyServices(for alert: FallAlert) async {
        let location = alert.event.location
        
        print("🚨 CALLING EMERGENCY SERVICES - Fall Detected")
        print("Fall Type: \(alert.event.type)")
        print("Confidence: \(alert.event.confidence)")
        if let location = location {
            print("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        
        // In real implementation, would integrate with emergency services API
    }
    
    private func notifyEmergencyContacts(for alert: FallAlert, priority: NotificationPriority) async {
        var message = "Fall detected"
        if let location = alert.event.location {
            message += " at location: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
        
        emergencyAlertManager?.notifyEmergencyContacts(
            message: message,
            priority: priority,
            location: alert.event.location
        )
    }
    
    private func transmitMedicalData(for alert: FallAlert) async {
        // Transmit relevant medical data for emergency response
    }
    
    private func prepareEmergencyData(for alert: FallAlert) async {
        // Prepare emergency data package
    }
    
    private func enhancePostFallMonitoring() async {
        // Increase monitoring sensitivity after fall
        fallDetectionSensitivity = .high
        
        // Schedule return to normal sensitivity
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in // 5 minutes
            self?.fallDetectionSensitivity = .medium
        }
    }
    
    private func logFallEvent(_ alert: FallAlert) async {
        // Log fall event for analysis
    }
    
    // MARK: - User Interface
    
    private func showFallAlert(_ alert: FallAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Fall Detected"
        content.body = "Tap to cancel emergency response within \(Int(fallConfirmationDelay)) seconds"
        content.sound = .critical
        content.categoryIdentifier = "FALL_DETECTED"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func showUrgentFallNotification(_ alert: FallAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Fall Emergency"
        content.body = "Emergency contacts have been notified. Seeking immediate assistance."
        content.sound = .default
        content.categoryIdentifier = "FALL_EMERGENCY"
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString + "_urgent",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    func cancelFallAlert(_ alertId: UUID) {
        fallConfirmationTimer?.invalidate()
        
        activeFallAlerts.removeAll { $0.id == alertId }
        
        if activeFallAlerts.isEmpty {
            fallDetectionStatus = .monitoring
            pendingFallAlert = nil
        }
        
        // Record as false positive for learning
        recordFalsePositive(alertId: alertId)
    }
    
    private func recordFalsePositive(alertId: UUID) {
        let falsePositive = FalsePositiveEvent(
            alertId: alertId,
            timestamp: Date(),
            context: activityContext,
            environment: environmentContext
        )
        
        falsePositiveHistory.append(falsePositive)
        
        // Adjust sensitivity based on false positives
        adjustSensitivityBasedOnHistory()
    }
    
    private func adjustSensitivityBasedOnHistory() {
        let recentFalsePositives = falsePositiveHistory.filter { 
            Date().timeIntervalSince($0.timestamp) < 86400 // Last 24 hours
        }
        
        if recentFalsePositives.count > 3 {
            fallDetectionSensitivity = .low
        } else if recentFalsePositives.count > 1 {
            fallDetectionSensitivity = .medium
        }
    }
    
    // MARK: - Context Analysis
    
    private func updateActivityContext(from motion: CMDeviceMotion) {
        let userAcceleration = motion.userAcceleration
        let magnitude = sqrt(pow(userAcceleration.x, 2) + 
                            pow(userAcceleration.y, 2) + 
                            pow(userAcceleration.z, 2))
        
        if magnitude < 0.1 {
            activityContext = .stationary
        } else if magnitude < 0.5 {
            activityContext = .walking
        } else {
            activityContext = .running
        }
    }
    
    private func updateFallRiskAssessment(with healthData: HealthData) {
        // Update fall risk based on health metrics
        var riskScore = 0.0
        
        // Age factor (if available)
        // Balance and gait factors
        // Medication effects
        // Recent health issues
        
        let newRiskLevel: FallRiskLevel
        switch riskScore {
        case 0..<0.3:
            newRiskLevel = .low
        case 0.3..<0.6:
            newRiskLevel = .medium
        case 0.6..<0.8:
            newRiskLevel = .high
        default:
            newRiskLevel = .critical
        }
        
        fallRiskLevel = newRiskLevel
    }
    
    private func getCurrentLocation() async -> CLLocation? {
        return locationManager?.location
    }
    
    // MARK: - Utility Methods
    
    func getFallHistory() -> [FallEvent] {
        return fallHistory
    }
    
    func getFalsePositiveHistory() -> [FalsePositiveEvent] {
        return falsePositiveHistory
    }
    
    func updateSensitivity(_ sensitivity: FallSensitivity) {
        fallDetectionSensitivity = sensitivity
    }
    
    private func cleanup() {
        stopFallDetection()
        fallConfirmationTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate

extension FallDetector: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates for context
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
}

// MARK: - Supporting Data Structures

struct FallThresholds {
    let accelerationThreshold: Double
    let gyroscopeThreshold: Double
    let impactThreshold: Double
    let freefall: Double
    let postFallMovement: Double
    let motionVarianceThreshold: Double
    let orientationChangeThreshold: Double
    
    init(accelerationThreshold: Double = 2.5,
         gyroscopeThreshold: Double = 3.0,
         impactThreshold: Double = 4.0,
         freefall: Double = 0.3,
         postFallMovement: Double = 0.5,
         motionVarianceThreshold: Double = 1.5,
         orientationChangeThreshold: Double = 60.0) {
        self.accelerationThreshold = accelerationThreshold
        self.gyroscopeThreshold = gyroscopeThreshold
        self.impactThreshold = impactThreshold
        self.freefall = freefall
        self.postFallMovement = postFallMovement
        self.motionVarianceThreshold = motionVarianceThreshold
        self.orientationChangeThreshold = orientationChangeThreshold
    }
}

struct FallEvent {
    let type: FallType
    let severity: FallSeverity
    let acceleration: Double
    let timestamp: Date
    let confidence: Double
    let location: CLLocation?
}

struct FallAlert {
    let id: UUID
    let event: FallEvent
    let timestamp: Date
    let status: FallAlertStatus
    let responseLevel: FallResponseLevel
}

struct FalsePositiveEvent {
    let alertId: UUID
    let timestamp: Date
    let context: ActivityContext
    let environment: EnvironmentContext
}

struct FallResponseProtocol {
    let immediateResponseTypes: [FallType]
    let urgentResponseTypes: [FallType]
    let monitoringTypes: [FallType]
    
    init(immediateResponseTypes: [FallType] = [.impact, .hardFall],
         urgentResponseTypes: [FallType] = [.gradualFall, .freefall],
         monitoringTypes: [FallType] = [.nearFall]) {
        self.immediateResponseTypes = immediateResponseTypes
        self.urgentResponseTypes = urgentResponseTypes
        self.monitoringTypes = monitoringTypes
    }
}

struct UserBehaviorPattern {
    var typicalMovementPatterns: [MovementPattern] = []
    var dailyActivityLevel: ActivityLevel = .moderate
    var fallRiskFactors: [FallRiskFactor] = []
    
    init() {}
}

enum FallDetectionStatus {
    case inactive
    case monitoring
    case fallDetected
    case emergencyActive
}

enum FallType {
    case impact
    case freefall
    case gradualFall
    case hardFall
    case nearFall
}

enum FallSeverity {
    case low
    case medium
    case high
    case critical
}

enum FallAlertStatus {
    case pending
    case confirmed
    case cancelled
    case resolved
}

enum FallResponseLevel {
    case immediate
    case urgent
    case monitoring
}

enum FallRiskLevel {
    case low
    case medium
    case high
    case critical
}

enum FallSensitivity {
    case low
    case medium
    case high
}

enum ActivityContext {
    case stationary
    case walking
    case running
    case unknown
}

enum EnvironmentContext {
    case indoor
    case outdoor
    case stairs
    case unknown
}

enum ActivityLevel {
    case low
    case moderate
    case high
}

enum MovementPattern {
    case regular
    case irregular
    case declining
}

enum FallRiskFactor {
    case age
    case medication
    case balance
    case gait
    case vision
    case cognition
}