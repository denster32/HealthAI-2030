import Foundation
import HealthAI2030Core
import BiometricProcessing
import HRVAnalysis
import BiometricSecurity
import AsyncAlgorithms

/// Thread-safe biometric fusion engine with actor isolation for multi-modal authentication and health monitoring
@globalActor
public actor BiometricFusionActor {
    public static let shared = BiometricFusionActor()
    
    private var biometricSources: [BiometricSource] = []
    private var fusionState: BiometricFusionState
    private var authenticationEngine: AuthenticationEngine
    private var securityManager: BiometricSecurityManager
    private var continuousMonitoring: ContinuousMonitoringEngine
    
    private init() {
        self.fusionState = BiometricFusionState()
        self.authenticationEngine = AuthenticationEngine()
        self.securityManager = BiometricSecurityManager()
        self.continuousMonitoring = ContinuousMonitoringEngine()
        
        initializeBiometricSources()
        startContinuousMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Register a new biometric source for fusion
    public func registerBiometricSource(_ source: BiometricSource) async throws {
        // Validate source security and capabilities
        try await securityManager.validateSource(source)
        
        // Add to fusion pipeline
        biometricSources.append(source)
        
        // Initialize source-specific processing
        await initializeSourceProcessing(source)
    }
    
    /// Perform multi-modal biometric authentication
    public func authenticate(challenge: AuthenticationChallenge) async throws -> AuthenticationResult {
        // Collect biometric data from available sources
        let biometricData = try await collectBiometricData(for: challenge)
        
        // Perform fusion and authentication
        let result = await authenticationEngine.authenticate(
            data: biometricData,
            challenge: challenge,
            fusionState: fusionState
        )
        
        // Update security state
        await securityManager.updateAuthenticationState(result)
        
        return result
    }
    
    /// Get current biometric template for health monitoring
    public func getCurrentBiometricTemplate() async -> BiometricTemplate {
        return await fusionState.generateTemplate()
    }
    
    /// Start continuous health monitoring session
    public func startHealthMonitoring() async throws {
        try await continuousMonitoring.startSession(
            sources: biometricSources,
            fusionState: fusionState
        )
    }
    
    /// Stop continuous monitoring
    public func stopHealthMonitoring() async {
        await continuousMonitoring.stopSession()
    }
    
    /// Get real-time health insights from biometric fusion
    public func getHealthInsights() async -> [BiometricHealthInsight] {
        return await fusionState.generateHealthInsights()
    }
    
    /// Update biometric data for continuous learning
    public func updateBiometricData(_ data: BiometricData) async throws {
        // Security validation
        try await securityManager.validateBiometricData(data)
        
        // Update fusion state
        await fusionState.updateWithBiometric(data)
        
        // Trigger any necessary alerts or notifications
        await evaluateHealthAlerts(data)
    }
    
    /// Get biometric security status
    public func getSecurityStatus() async -> BiometricSecurityStatus {
        return await securityManager.getCurrentStatus()
    }
    
    // MARK: - Private Implementation
    
    private func initializeBiometricSources() {
        // Initialize default sources available on the platform
        #if os(iOS) || os(watchOS)
        biometricSources.append(contentsOf: [
            FaceIDSource(),
            TouchIDSource(),
            HeartRateSource(),
            VoiceSource(),
            GaitSource(),
            MotionSource()
        ])
        #elseif os(macOS)
        biometricSources.append(contentsOf: [
            TouchIDSource(),
            VoiceSource(),
            MotionSource()
        ])
        #elseif os(visionOS)
        biometricSources.append(contentsOf: [
            EyeTrackingSource(),
            VoiceSource(),
            HandTrackingSource(),
            GazePatternSource()
        ])
        #endif
    }
    
    private func startContinuousMonitoring() {
        Task {
            await continuousMonitoring.startBackgroundProcessing { [weak self] insights in
                guard let self = self else { return }
                await self.processContinuousInsights(insights)
            }
        }
    }
    
    private func initializeSourceProcessing(_ source: BiometricSource) async {
        await source.initialize()
        
        // Set up processing pipeline for this source
        Task {
            let stream = await source.getDataStream()
            
            for await data in stream {
                do {
                    try await updateBiometricData(data)
                } catch {
                    print("Error processing biometric data from \(source.type): \(error)")
                }
            }
        }
    }
    
    private func collectBiometricData(for challenge: AuthenticationChallenge) async throws -> [BiometricData] {
        var collectedData: [BiometricData] = []
        
        // Collect data from all available sources
        await withTaskGroup(of: BiometricData?.self) { group in
            for source in biometricSources {
                group.addTask {
                    do {
                        return try await source.collectData(for: challenge)
                    } catch {
                        print("Failed to collect data from \(source.type): \(error)")
                        return nil
                    }
                }
            }
            
            for await data in group {
                if let data = data {
                    collectedData.append(data)
                }
            }
        }
        
        guard !collectedData.isEmpty else {
            throw BiometricFusionError.noDataAvailable
        }
        
        return collectedData
    }
    
    private func evaluateHealthAlerts(_ data: BiometricData) async {
        // Check for health anomalies that require immediate attention
        let anomalies = await detectHealthAnomalies(data)
        
        for anomaly in anomalies {
            if anomaly.severity >= .high {
                await triggerHealthAlert(anomaly)
            }
        }
    }
    
    private func detectHealthAnomalies(_ data: BiometricData) async -> [HealthAnomaly] {
        var anomalies: [HealthAnomaly] = []
        
        switch data.type {
        case .heartRate:
            if let hrAnomaly = await detectHeartRateAnomaly(data) {
                anomalies.append(hrAnomaly)
            }
            
        case .heartRateVariability:
            if let hrvAnomaly = await detectHRVAnomaly(data) {
                anomalies.append(hrvAnomaly)
            }
            
        case .oxygenSaturation:
            if let spo2Anomaly = await detectOxygenAnomaly(data) {
                anomalies.append(spo2Anomaly)
            }
            
        case .bloodPressure:
            if let bpAnomaly = await detectBloodPressureAnomaly(data) {
                anomalies.append(bpAnomaly)
            }
            
        default:
            break
        }
        
        return anomalies
    }
    
    private func detectHeartRateAnomaly(_ data: BiometricData) async -> HealthAnomaly? {
        guard let heartRate = data.value else { return nil }
        
        // Get user's baseline from fusion state
        let baseline = await fusionState.getBaselineHeartRate()
        
        // Detect significant deviations
        if heartRate > 150 || heartRate < 40 {
            return HealthAnomaly(
                type: .cardiovascular,
                severity: .critical,
                description: "Heart rate critically outside normal range: \(Int(heartRate)) bpm",
                timestamp: data.timestamp,
                value: heartRate
            )
        } else if abs(heartRate - baseline) > baseline * 0.3 {
            return HealthAnomaly(
                type: .cardiovascular,
                severity: .medium,
                description: "Heart rate significantly different from baseline",
                timestamp: data.timestamp,
                value: heartRate
            )
        }
        
        return nil
    }
    
    private func detectHRVAnomaly(_ data: BiometricData) async -> HealthAnomaly? {
        guard let hrv = data.value else { return nil }
        
        let baseline = await fusionState.getBaselineHRV()
        
        // Low HRV can indicate stress or health issues
        if hrv < 10 {
            return HealthAnomaly(
                type: .stress,
                severity: .high,
                description: "Very low heart rate variability detected: \(Int(hrv)) ms",
                timestamp: data.timestamp,
                value: hrv
            )
        } else if hrv < baseline * 0.5 {
            return HealthAnomaly(
                type: .stress,
                severity: .medium,
                description: "Heart rate variability significantly below baseline",
                timestamp: data.timestamp,
                value: hrv
            )
        }
        
        return nil
    }
    
    private func detectOxygenAnomaly(_ data: BiometricData) async -> HealthAnomaly? {
        guard let spo2 = data.value else { return nil }
        
        if spo2 < 90 {
            return HealthAnomaly(
                type: .respiratory,
                severity: .critical,
                description: "Low blood oxygen saturation: \(Int(spo2))%",
                timestamp: data.timestamp,
                value: spo2
            )
        } else if spo2 < 95 {
            return HealthAnomaly(
                type: .respiratory,
                severity: .medium,
                description: "Blood oxygen saturation below normal range",
                timestamp: data.timestamp,
                value: spo2
            )
        }
        
        return nil
    }
    
    private func detectBloodPressureAnomaly(_ data: BiometricData) async -> HealthAnomaly? {
        guard let systolic = data.value,
              let diastolic = data.additionalValues?["diastolic"] else { return nil }
        
        // Check for hypertensive crisis
        if systolic > 180 || diastolic > 120 {
            return HealthAnomaly(
                type: .cardiovascular,
                severity: .critical,
                description: "Hypertensive crisis: \(Int(systolic))/\(Int(diastolic)) mmHg",
                timestamp: data.timestamp,
                value: systolic
            )
        }
        
        // Check for severe hypertension
        if systolic > 160 || diastolic > 100 {
            return HealthAnomaly(
                type: .cardiovascular,
                severity: .high,
                description: "Severe hypertension detected",
                timestamp: data.timestamp,
                value: systolic
            )
        }
        
        return nil
    }
    
    private func triggerHealthAlert(_ anomaly: HealthAnomaly) async {
        // This would integrate with the notification system
        print("HEALTH ALERT: \(anomaly.description)")
        
        // Could trigger emergency protocols for critical anomalies
        if anomaly.severity == .critical {
            await handleCriticalHealthEvent(anomaly)
        }
    }
    
    private func handleCriticalHealthEvent(_ anomaly: HealthAnomaly) async {
        // Implementation would handle emergency protocols
        // Such as contacting emergency services, alerting emergency contacts, etc.
        print("CRITICAL HEALTH EVENT DETECTED: \(anomaly.description)")
    }
    
    private func processContinuousInsights(_ insights: [BiometricHealthInsight]) async {
        // Process insights from continuous monitoring
        await fusionState.incorporateInsights(insights)
        
        // Update health trends and predictions
        for insight in insights {
            if insight.actionRequired {
                await handleActionableInsight(insight)
            }
        }
    }
    
    private func handleActionableInsight(_ insight: BiometricHealthInsight) async {
        // Handle insights that require user action or notification
        print("Actionable health insight: \(insight.description)")
    }
}

// MARK: - Supporting Types

public struct AuthenticationChallenge: Sendable {
    public let id: UUID
    public let requiredSources: Set<BiometricType>
    public let securityLevel: SecurityLevel
    public let timeout: TimeInterval
    public let timestamp: Date
    
    public enum SecurityLevel: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
    }
}

public struct AuthenticationResult: Sendable {
    public let success: Bool
    public let confidence: Double
    public let authenticatedSources: Set<BiometricType>
    public let failedSources: Set<BiometricType>
    public let timestamp: Date
    public let sessionToken: String?
    public let additionalVerificationRequired: Bool
}

public struct BiometricTemplate: Sendable {
    public let id: UUID
    public let userId: String
    public let biometricTypes: Set<BiometricType>
    public let features: [String: [Double]]
    public let confidence: Double
    public let createdAt: Date
    public let expiresAt: Date
}

public struct BiometricHealthInsight: Sendable {
    public let type: InsightType
    public let description: String
    public let confidence: Double
    public let actionRequired: Bool
    public let relatedBiometrics: Set<BiometricType>
    public let timestamp: Date
    
    public enum InsightType: Sendable {
        case trendDetection
        case anomalyAlert
        case healthRecommendation
        case riskAssessment
    }
}

public struct BiometricData: Sendable {
    public let id: UUID
    public let type: BiometricType
    public let value: Double?
    public let rawData: Data?
    public let additionalValues: [String: Double]?
    public let quality: DataQuality
    public let source: String
    public let timestamp: Date
    
    public enum DataQuality: Sendable {
        case excellent
        case good
        case fair
        case poor
    }
}

public enum BiometricType: String, Sendable, CaseIterable {
    case faceID = "face_id"
    case touchID = "touch_id"
    case heartRate = "heart_rate"
    case heartRateVariability = "hrv"
    case voice = "voice"
    case gait = "gait"
    case motion = "motion"
    case oxygenSaturation = "spo2"
    case bloodPressure = "blood_pressure"
    case eyeTracking = "eye_tracking"
    case handTracking = "hand_tracking"
    case gazePattern = "gaze_pattern"
}

public struct BiometricSecurityStatus: Sendable {
    public let overallSecurity: SecurityLevel
    public let activeSources: Set<BiometricType>
    public let compromisedSources: Set<BiometricType>
    public let lastSecurityCheck: Date
    public let threatLevel: ThreatLevel
    
    public enum SecurityLevel: Sendable {
        case secure
        case moderate
        case vulnerable
        case compromised
    }
    
    public enum ThreatLevel: Sendable {
        case none
        case low
        case medium
        case high
        case critical
    }
}

public struct HealthAnomaly: Sendable {
    public enum AnomalyType: Sendable {
        case cardiovascular
        case respiratory
        case neurological
        case stress
        case fatigue
    }
    
    public enum Severity: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
    }
    
    public let type: AnomalyType
    public let severity: Severity
    public let description: String
    public let timestamp: Date
    public let value: Double
}

// MARK: - Error Types

public enum BiometricFusionError: Error, Sendable {
    case noDataAvailable
    case authenticationFailed
    case securityValidationFailed
    case sourceNotAvailable(BiometricType)
    case dataCorrupted
    case timeout
}

// MARK: - Protocol Definitions

public protocol BiometricSource: Sendable {
    var type: BiometricType { get }
    var isAvailable: Bool { get async }
    
    func initialize() async
    func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData
    func getDataStream() async -> AsyncStream<BiometricData>
}

// MARK: - Concrete Source Implementations

public class FaceIDSource: BiometricSource {
    public let type = BiometricType.faceID
    
    public var isAvailable: Bool {
        get async {
            // Check if Face ID is available on device
            return true // Simplified
        }
    }
    
    public func initialize() async {
        // Initialize Face ID system
    }
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        // Collect Face ID data
        return BiometricData(
            id: UUID(),
            type: .faceID,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .excellent,
            source: "FaceID",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            // Implement continuous Face ID monitoring
            continuation.finish()
        }
    }
}

public class TouchIDSource: BiometricSource {
    public let type = BiometricType.touchID
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .touchID,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .excellent,
            source: "TouchID",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

public class HeartRateSource: BiometricSource {
    public let type = BiometricType.heartRate
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        // Simulate heart rate data
        let heartRate = Double.random(in: 60...100)
        
        return BiometricData(
            id: UUID(),
            type: .heartRate,
            value: heartRate,
            rawData: nil,
            additionalValues: nil,
            quality: .good,
            source: "HealthKit",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            Task {
                while !Task.isCancelled {
                    let data = try? await collectData(for: AuthenticationChallenge(
                        id: UUID(),
                        requiredSources: [.heartRate],
                        securityLevel: .low,
                        timeout: 30,
                        timestamp: Date()
                    ))
                    
                    if let data = data {
                        continuation.yield(data)
                    }
                    
                    try? await Task.sleep(for: .seconds(1))
                }
                continuation.finish()
            }
        }
    }
}

public class VoiceSource: BiometricSource {
    public let type = BiometricType.voice
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .voice,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .good,
            source: "Microphone",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

public class GaitSource: BiometricSource {
    public let type = BiometricType.gait
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .gait,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .fair,
            source: "Accelerometer",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

public class MotionSource: BiometricSource {
    public let type = BiometricType.motion
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .motion,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .good,
            source: "CoreMotion",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

// visionOS-specific sources
public class EyeTrackingSource: BiometricSource {
    public let type = BiometricType.eyeTracking
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .eyeTracking,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .excellent,
            source: "RealityKit",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

public class HandTrackingSource: BiometricSource {
    public let type = BiometricType.handTracking
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .handTracking,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .excellent,
            source: "ARKit",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}

public class GazePatternSource: BiometricSource {
    public let type = BiometricType.gazePattern
    
    public var isAvailable: Bool {
        get async { true }
    }
    
    public func initialize() async {}
    
    public func collectData(for challenge: AuthenticationChallenge) async throws -> BiometricData {
        return BiometricData(
            id: UUID(),
            type: .gazePattern,
            value: nil,
            rawData: Data(),
            additionalValues: nil,
            quality: .good,
            source: "EyeTracking",
            timestamp: Date()
        )
    }
    
    public func getDataStream() async -> AsyncStream<BiometricData> {
        return AsyncStream { continuation in
            continuation.finish()
        }
    }
}