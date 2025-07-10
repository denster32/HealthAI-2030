import Foundation
import LocalAuthentication
import CryptoKit
import Combine
import os.log

/// Advanced biometric authentication engine with multi-modal biometric support
/// Provides secure, convenient, and reliable biometric authentication for healthcare data access
@available(iOS 14.0, macOS 11.0, *)
public class BiometricAuthenticationEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isAuthenticationActive: Bool = false
    @Published public var authenticationStatus: AuthenticationStatus = .idle
    @Published public var supportedBiometrics: [BiometricType] = []
    @Published public var lastAuthenticationDate: Date?
    @Published public var authenticationMetrics: AuthenticationMetrics?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "HealthAI2030", category: "BiometricAuth")
    private var cancellables = Set<AnyCancellable>()
    private let context = LAContext()
    private let secureQueue = DispatchQueue(label: "biometric.authentication", qos: .userInitiated)
    
    // Biometric components
    private var biometricProcessor: BiometricProcessor
    private var templateManager: BiometricTemplateManager
    private var securityValidator: BiometricSecurityValidator
    private var livelinessDetector: LivelinessDetector
    private var antispoofingEngine: AntispoofingEngine
    
    // Configuration
    private var authConfig: BiometricAuthConfiguration
    
    // Security features
    private var encryptionKey: SymmetricKey
    private var secureEnclave: SecureEnclaveManager
    
    // MARK: - Initialization
    public init(config: BiometricAuthConfiguration = .default) {
        self.authConfig = config
        self.biometricProcessor = BiometricProcessor(config: config)
        self.templateManager = BiometricTemplateManager(config: config)
        self.securityValidator = BiometricSecurityValidator(config: config)
        self.livelinessDetector = LivelinessDetector(config: config)
        self.antispoofingEngine = AntispoofingEngine(config: config)
        self.encryptionKey = SymmetricKey(size: .bits256)
        self.secureEnclave = SecureEnclaveManager()
        
        setupBiometricEngine()
        detectSupportedBiometrics()
        logger.info("BiometricAuthenticationEngine initialized")
    }
    
    // MARK: - Public Methods
    
    /// Authenticate user using available biometric methods
    public func authenticate(
        prompt: String = "Authenticate to access health data",
        fallbackTitle: String = "Use Passcode",
        biometricType: BiometricType? = nil
    ) -> AnyPublisher<AuthenticationResult, BiometricError> {
        
        return Future<AuthenticationResult, BiometricError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.systemError("Authentication engine unavailable")))
                return
            }
            
            self.secureQueue.async {
                self.performAuthentication(
                    prompt: prompt,
                    fallbackTitle: fallbackTitle,
                    biometricType: biometricType,
                    completion: promise
                )
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Register new biometric template
    public func registerBiometric(
        type: BiometricType,
        userId: String,
        data: BiometricData
    ) -> AnyPublisher<BiometricTemplate, BiometricError> {
        
        return Future<BiometricTemplate, BiometricError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.systemError("Authentication engine unavailable")))
                return
            }
            
            self.secureQueue.async {
                do {
                    // Validate biometric data quality
                    let qualityScore = try self.biometricProcessor.validateQuality(data)
                    guard qualityScore >= self.authConfig.minimumQualityThreshold else {
                        promise(.failure(.poorQuality(qualityScore)))
                        return
                    }
                    
                    // Perform liveliness detection
                    let isLive = try self.livelinessDetector.detectLiveliness(data)
                    guard isLive else {
                        promise(.failure(.livelinessCheckFailed))
                        return
                    }
                    
                    // Check for spoofing attempts
                    let isSpoofed = try self.antispoofingEngine.detectSpoofing(data)
                    guard !isSpoofed else {
                        promise(.failure(.spoofingDetected))
                        return
                    }
                    
                    // Extract and encrypt biometric template
                    let template = try self.biometricProcessor.extractTemplate(from: data, type: type)
                    let encryptedTemplate = try self.encryptTemplate(template)
                    
                    // Store template securely
                    let biometricTemplate = BiometricTemplate(
                        id: UUID().uuidString,
                        userId: userId,
                        type: type,
                        encryptedData: encryptedTemplate,
                        qualityScore: qualityScore,
                        creationDate: Date()
                    )
                    
                    try self.templateManager.storeTemplate(biometricTemplate)
                    
                    DispatchQueue.main.async {
                        self.logger.info("Biometric template registered for user: \(userId)")
                    }
                    
                    promise(.success(biometricTemplate))
                    
                } catch {
                    promise(.failure(.registrationFailed(error.localizedDescription)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Verify biometric against stored template
    public func verifyBiometric(
        data: BiometricData,
        userId: String,
        type: BiometricType
    ) -> AnyPublisher<VerificationResult, BiometricError> {
        
        return Future<VerificationResult, BiometricError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.systemError("Authentication engine unavailable")))
                return
            }
            
            self.secureQueue.async {
                do {
                    // Retrieve stored template
                    guard let storedTemplate = try self.templateManager.getTemplate(userId: userId, type: type) else {
                        promise(.failure(.templateNotFound))
                        return
                    }
                    
                    // Decrypt stored template
                    let decryptedTemplate = try self.decryptTemplate(storedTemplate.encryptedData)
                    
                    // Extract template from current biometric data
                    let currentTemplate = try self.biometricProcessor.extractTemplate(from: data, type: type)
                    
                    // Perform template matching
                    let matchScore = try self.biometricProcessor.matchTemplates(
                        template1: decryptedTemplate,
                        template2: currentTemplate,
                        type: type
                    )
                    
                    let isMatch = matchScore >= self.authConfig.matchThreshold
                    let confidence = min(matchScore / self.authConfig.matchThreshold, 1.0)
                    
                    let result = VerificationResult(
                        isMatch: isMatch,
                        confidence: confidence,
                        matchScore: matchScore,
                        userId: userId,
                        biometricType: type,
                        verificationDate: Date()
                    )
                    
                    // Update authentication metrics
                    self.updateMetrics(isSuccessful: isMatch, biometricType: type)
                    
                    promise(.success(result))
                    
                } catch {
                    promise(.failure(.verificationFailed(error.localizedDescription)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Remove biometric template
    public func removeBiometric(userId: String, type: BiometricType) -> AnyPublisher<Void, BiometricError> {
        return Future<Void, BiometricError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.systemError("Authentication engine unavailable")))
                return
            }
            
            self.secureQueue.async {
                do {
                    try self.templateManager.removeTemplate(userId: userId, type: type)
                    self.logger.info("Removed biometric template for user: \(userId)")
                    promise(.success(()))
                } catch {
                    promise(.failure(.templateRemovalFailed(error.localizedDescription)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Check if user has registered biometrics
    public func hasRegisteredBiometrics(userId: String) -> Bool {
        return templateManager.hasTemplates(for: userId)
    }
    
    /// Get biometric availability for device
    public func checkBiometricAvailability() -> BiometricAvailability {
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvaluate {
            switch context.biometryType {
            case .faceID:
                return BiometricAvailability(
                    isAvailable: true,
                    supportedTypes: [.faceID],
                    primaryType: .faceID,
                    error: nil
                )
            case .touchID:
                return BiometricAvailability(
                    isAvailable: true,
                    supportedTypes: [.touchID],
                    primaryType: .touchID,
                    error: nil
                )
            case .opticID:
                return BiometricAvailability(
                    isAvailable: true,
                    supportedTypes: [.opticID],
                    primaryType: .opticID,
                    error: nil
                )
            default:
                return BiometricAvailability(
                    isAvailable: false,
                    supportedTypes: [],
                    primaryType: nil,
                    error: "Unknown biometric type"
                )
            }
        } else {
            return BiometricAvailability(
                isAvailable: false,
                supportedTypes: [],
                primaryType: nil,
                error: error?.localizedDescription ?? "Biometrics not available"
            )
        }
    }
    
    /// Update authentication configuration
    public func updateConfiguration(_ config: BiometricAuthConfiguration) {
        self.authConfig = config
        self.biometricProcessor.updateConfiguration(config)
        self.templateManager.updateConfiguration(config)
        self.securityValidator.updateConfiguration(config)
        self.livelinessDetector.updateConfiguration(config)
        self.antispoofingEngine.updateConfiguration(config)
        logger.info("Biometric authentication configuration updated")
    }
    
    // MARK: - Private Methods
    
    private func setupBiometricEngine() {
        // Monitor authentication status changes
        $authenticationStatus
            .dropFirst()
            .sink { [weak self] status in
                self?.handleAuthenticationStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func detectSupportedBiometrics() {
        let availability = checkBiometricAvailability()
        DispatchQueue.main.async {
            self.supportedBiometrics = availability.supportedTypes
        }
    }
    
    private func performAuthentication(
        prompt: String,
        fallbackTitle: String,
        biometricType: BiometricType?,
        completion: @escaping (Result<AuthenticationResult, BiometricError>) -> Void
    ) {
        
        DispatchQueue.main.async {
            self.isAuthenticationActive = true
            self.authenticationStatus = .authenticating
        }
        
        // Configure authentication context
        let context = LAContext()
        context.localizedFallbackTitle = fallbackTitle
        
        // Set policy based on configuration
        let policy: LAPolicy = authConfig.allowPasscodeFallback ?
            .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics
        
        context.evaluatePolicy(policy, localizedReason: prompt) { [weak self] success, error in
            guard let self = self else {
                completion(.failure(.systemError("Authentication engine unavailable")))
                return
            }
            
            DispatchQueue.main.async {
                self.isAuthenticationActive = false
                
                if success {
                    self.authenticationStatus = .authenticated
                    self.lastAuthenticationDate = Date()
                    
                    let result = AuthenticationResult(
                        isSuccessful: true,
                        biometricType: self.getPrimaryBiometricType(),
                        authenticationDate: Date(),
                        sessionId: UUID().uuidString,
                        error: nil
                    )
                    
                    self.updateMetrics(isSuccessful: true, biometricType: result.biometricType)
                    completion(.success(result))
                    
                } else {
                    self.authenticationStatus = .failed
                    
                    let biometricError = self.mapLAError(error)
                    let result = AuthenticationResult(
                        isSuccessful: false,
                        biometricType: nil,
                        authenticationDate: Date(),
                        sessionId: nil,
                        error: biometricError.localizedDescription
                    )
                    
                    self.updateMetrics(isSuccessful: false, biometricType: nil)
                    completion(.failure(biometricError))
                }
            }
        }
    }
    
    private func encryptTemplate(_ template: BiometricTemplateData) throws -> Data {
        let templateData = try JSONEncoder().encode(template)
        let sealedBox = try AES.GCM.seal(templateData, using: encryptionKey)
        return sealedBox.combined!
    }
    
    private func decryptTemplate(_ encryptedData: Data) throws -> BiometricTemplateData {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        return try JSONDecoder().decode(BiometricTemplateData.self, from: decryptedData)
    }
    
    private func getPrimaryBiometricType() -> BiometricType? {
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return nil
        }
    }
    
    private func mapLAError(_ error: Error?) -> BiometricError {
        guard let laError = error as? LAError else {
            return .systemError("Unknown authentication error")
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .fallbackRequested
        case .biometryNotAvailable:
            return .biometricNotAvailable
        case .biometryNotEnrolled:
            return .biometricNotEnrolled
        case .biometryLockout:
            return .biometricLockout
        default:
            return .systemError(laError.localizedDescription)
        }
    }
    
    private func updateMetrics(isSuccessful: Bool, biometricType: BiometricType?) {
        var currentMetrics = authenticationMetrics ?? AuthenticationMetrics()
        
        currentMetrics.totalAttempts += 1
        if isSuccessful {
            currentMetrics.successfulAttempts += 1
        } else {
            currentMetrics.failedAttempts += 1
        }
        
        if let type = biometricType {
            currentMetrics.biometricTypeUsage[type.rawValue, default: 0] += 1
        }
        
        currentMetrics.successRate = Double(currentMetrics.successfulAttempts) / Double(currentMetrics.totalAttempts)
        currentMetrics.lastUpdated = Date()
        
        DispatchQueue.main.async {
            self.authenticationMetrics = currentMetrics
        }
    }
    
    private func handleAuthenticationStatusChange(_ status: AuthenticationStatus) {
        switch status {
        case .authenticated:
            logger.info("Biometric authentication successful")
        case .failed:
            logger.warning("Biometric authentication failed")
        default:
            break
        }
    }
}

// MARK: - Supporting Types

public enum BiometricError: LocalizedError {
    case authenticationFailed
    case userCancelled
    case fallbackRequested
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricLockout
    case poorQuality(Double)
    case livelinessCheckFailed
    case spoofingDetected
    case templateNotFound
    case registrationFailed(String)
    case verificationFailed(String)
    case templateRemovalFailed(String)
    case systemError(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .userCancelled:
            return "User cancelled authentication"
        case .fallbackRequested:
            return "User requested fallback authentication"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricNotEnrolled:
            return "No biometrics enrolled on device"
        case .biometricLockout:
            return "Biometric authentication locked out"
        case .poorQuality(let score):
            return "Poor biometric quality (score: \(score))"
        case .livelinessCheckFailed:
            return "Liveliness check failed"
        case .spoofingDetected:
            return "Potential spoofing attempt detected"
        case .templateNotFound:
            return "Biometric template not found"
        case .registrationFailed(let reason):
            return "Biometric registration failed: \(reason)"
        case .verificationFailed(let reason):
            return "Biometric verification failed: \(reason)"
        case .templateRemovalFailed(let reason):
            return "Template removal failed: \(reason)"
        case .systemError(let reason):
            return "System error: \(reason)"
        }
    }
}

public enum AuthenticationStatus: CaseIterable {
    case idle
    case authenticating
    case authenticated
    case failed
    case locked
    
    public var description: String {
        switch self {
        case .idle: return "Idle"
        case .authenticating: return "Authenticating"
        case .authenticated: return "Authenticated"
        case .failed: return "Failed"
        case .locked: return "Locked"
        }
    }
}

public enum BiometricType: String, CaseIterable {
    case faceID = "faceID"
    case touchID = "touchID"
    case opticID = "opticID"
    case voiceprint = "voiceprint"
    case iris = "iris"
    case palm = "palm"
    case behavioral = "behavioral"
    
    public var description: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .voiceprint: return "Voice Print"
        case .iris: return "Iris Scan"
        case .palm: return "Palm Print"
        case .behavioral: return "Behavioral Biometric"
        }
    }
}

// MARK: - Configuration

public struct BiometricAuthConfiguration {
    public let matchThreshold: Double
    public let minimumQualityThreshold: Double
    public let allowPasscodeFallback: Bool
    public let maxFailedAttempts: Int
    public let lockoutDuration: TimeInterval
    public let enableLivelinessDetection: Bool
    public let enableAntispoofing: Bool
    public let templateExpirationDays: Int
    
    public static let `default` = BiometricAuthConfiguration(
        matchThreshold: 0.8,
        minimumQualityThreshold: 0.7,
        allowPasscodeFallback: true,
        maxFailedAttempts: 5,
        lockoutDuration: 300, // 5 minutes
        enableLivelinessDetection: true,
        enableAntispoofing: true,
        templateExpirationDays: 90
    )
}

// MARK: - Data Structures

public struct BiometricAvailability {
    public let isAvailable: Bool
    public let supportedTypes: [BiometricType]
    public let primaryType: BiometricType?
    public let error: String?
}

public struct AuthenticationResult {
    public let isSuccessful: Bool
    public let biometricType: BiometricType?
    public let authenticationDate: Date
    public let sessionId: String?
    public let error: String?
}

public struct VerificationResult {
    public let isMatch: Bool
    public let confidence: Double
    public let matchScore: Double
    public let userId: String
    public let biometricType: BiometricType
    public let verificationDate: Date
}

public struct BiometricTemplate {
    public let id: String
    public let userId: String
    public let type: BiometricType
    public let encryptedData: Data
    public let qualityScore: Double
    public let creationDate: Date
}

public struct BiometricData {
    public let type: BiometricType
    public let rawData: Data
    public let metadata: [String: Any]
    public let captureDate: Date
    
    public init(type: BiometricType, rawData: Data, metadata: [String: Any] = [:]) {
        self.type = type
        self.rawData = rawData
        self.metadata = metadata
        self.captureDate = Date()
    }
}

public struct BiometricTemplateData: Codable {
    public let features: [Double]
    public let type: String
    public let version: String
    public let extractionDate: Date
    
    public init(features: [Double], type: BiometricType, version: String = "1.0") {
        self.features = features
        self.type = type.rawValue
        self.version = version
        self.extractionDate = Date()
    }
}

public struct AuthenticationMetrics {
    public var totalAttempts: Int = 0
    public var successfulAttempts: Int = 0
    public var failedAttempts: Int = 0
    public var successRate: Double = 0.0
    public var biometricTypeUsage: [String: Int] = [:]
    public var lastUpdated: Date = Date()
}

// MARK: - Processing Components

private class BiometricProcessor {
    private var config: BiometricAuthConfiguration
    
    init(config: BiometricAuthConfiguration) {
        self.config = config
    }
    
    func validateQuality(_ data: BiometricData) throws -> Double {
        // Simulate quality validation - in real implementation, this would analyze the biometric data
        return Double.random(in: 0.7...1.0)
    }
    
    func extractTemplate(from data: BiometricData, type: BiometricType) throws -> BiometricTemplateData {
        // Simulate template extraction - in real implementation, this would extract features
        let features = (0..<128).map { _ in Double.random(in: 0...1) }
        return BiometricTemplateData(features: features, type: type)
    }
    
    func matchTemplates(template1: BiometricTemplateData, template2: BiometricTemplateData, type: BiometricType) throws -> Double {
        // Simulate template matching - in real implementation, this would compare feature vectors
        guard template1.type == template2.type else {
            throw BiometricError.systemError("Template type mismatch")
        }
        
        // Simple cosine similarity simulation
        let similarity = Double.random(in: 0.5...1.0)
        return similarity
    }
    
    func updateConfiguration(_ config: BiometricAuthConfiguration) {
        self.config = config
    }
}

private class BiometricTemplateManager {
    private var config: BiometricAuthConfiguration
    private var templates: [String: [BiometricTemplate]] = [:]
    
    init(config: BiometricAuthConfiguration) {
        self.config = config
    }
    
    func storeTemplate(_ template: BiometricTemplate) throws {
        let userKey = "\(template.userId)-\(template.type.rawValue)"
        templates[userKey] = [template]
    }
    
    func getTemplate(userId: String, type: BiometricType) throws -> BiometricTemplate? {
        let userKey = "\(userId)-\(type.rawValue)"
        return templates[userKey]?.first
    }
    
    func removeTemplate(userId: String, type: BiometricType) throws {
        let userKey = "\(userId)-\(type.rawValue)"
        templates.removeValue(forKey: userKey)
    }
    
    func hasTemplates(for userId: String) -> Bool {
        return templates.keys.contains { $0.hasPrefix(userId) }
    }
    
    func updateConfiguration(_ config: BiometricAuthConfiguration) {
        self.config = config
    }
}

private class BiometricSecurityValidator {
    private var config: BiometricAuthConfiguration
    
    init(config: BiometricAuthConfiguration) {
        self.config = config
    }
    
    func updateConfiguration(_ config: BiometricAuthConfiguration) {
        self.config = config
    }
}

private class LivelinessDetector {
    private var config: BiometricAuthConfiguration
    
    init(config: BiometricAuthConfiguration) {
        self.config = config
    }
    
    func detectLiveliness(_ data: BiometricData) throws -> Bool {
        guard config.enableLivelinessDetection else { return true }
        // Simulate liveliness detection
        return Bool.random()
    }
    
    func updateConfiguration(_ config: BiometricAuthConfiguration) {
        self.config = config
    }
}

private class AntispoofingEngine {
    private var config: BiometricAuthConfiguration
    
    init(config: BiometricAuthConfiguration) {
        self.config = config
    }
    
    func detectSpoofing(_ data: BiometricData) throws -> Bool {
        guard config.enableAntispoofing else { return false }
        // Simulate anti-spoofing detection
        return Bool.random() && Double.random(in: 0...1) < 0.05 // 5% false positive rate
    }
    
    func updateConfiguration(_ config: BiometricAuthConfiguration) {
        self.config = config
    }
}

private class SecureEnclaveManager {
    func storeSecurely(_ data: Data, key: String) throws {
        // Implement secure enclave storage
    }
    
    func retrieveSecurely(key: String) throws -> Data? {
        // Implement secure enclave retrieval
        return nil
    }
    
    func deleteSecurely(key: String) throws {
        // Implement secure enclave deletion
    }
}
