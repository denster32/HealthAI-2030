import Foundation
import Security
import Network
import CryptoKit

/// Comprehensive certificate pinning manager for HealthAI-2030
/// Implements certificate pinning for all network requests to prevent MITM attacks
@MainActor
public class CertificatePinningManager: ObservableObject {
    public static let shared = CertificatePinningManager()
    
    @Published private(set) var isPinningEnabled = true
    @Published private(set) var pinnedCertificates: [String: [Data]] = [:]
    @Published private(set) var pinningFailures: [PinningFailure] = []
    @Published private(set) var lastPinningCheck: Date = Date()
    
    private let logger = Logger(subsystem: "com.healthai.security", category: "CertificatePinning")
    private let securityQueue = DispatchQueue(label: "com.healthai.certificate-pinning", qos: .userInitiated)
    
    // MARK: - Certificate Pinning Configuration
    
    /// Certificate pinning configuration
    public struct PinningConfig {
        public let hostname: String
        public let certificates: [Data]
        public let backupCertificates: [Data]
        public let enforcePinning: Bool
        public let maxAge: TimeInterval
        
        public init(hostname: String, certificates: [Data], backupCertificates: [Data] = [], enforcePinning: Bool = true, maxAge: TimeInterval = 86400 * 30) {
            self.hostname = hostname
            self.certificates = certificates
            self.backupCertificates = backupCertificates
            self.enforcePinning = enforcePinning
            self.maxAge = maxAge
        }
    }
    
    /// Certificate pinning failure
    public struct PinningFailure: Identifiable, Codable {
        public let id = UUID()
        public let hostname: String
        public let reason: FailureReason
        public let timestamp: Date
        public let certificateData: Data?
        public let expectedHashes: [String]
        public let actualHashes: [String]
        
        public enum FailureReason: String, CaseIterable, Codable {
            case noCertificate = "no_certificate"
            case invalidCertificate = "invalid_certificate"
            case hashMismatch = "hash_mismatch"
            case expiredCertificate = "expired_certificate"
            case untrustedCertificate = "untrusted_certificate"
            case networkError = "network_error"
        }
    }
    
    private init() {
        setupDefaultPinning()
        loadPinnedCertificates()
    }
    
    // MARK: - Certificate Pinning Setup
    
    /// Setup default certificate pinning for known endpoints
    private func setupDefaultPinning() {
        // HealthAI API endpoints
        let healthAIEndpoints = [
            "api.healthai2030.com",
            "auth.healthai2030.com",
            "telemetry.healthai2030.com",
            "analytics.healthai2030.com"
        ]
        
        for endpoint in healthAIEndpoints {
            addPinningConfig(PinningConfig(
                hostname: endpoint,
                certificates: getDefaultCertificates(for: endpoint),
                enforcePinning: true
            ))
        }
        
        // AWS endpoints
        let awsEndpoints = [
            "s3.amazonaws.com",
            "secretsmanager.amazonaws.com",
            "cognito-idp.amazonaws.com"
        ]
        
        for endpoint in awsEndpoints {
            addPinningConfig(PinningConfig(
                hostname: endpoint,
                certificates: getAWSCertificates(for: endpoint),
                enforcePinning: true
            ))
        }
    }
    
    /// Add certificate pinning configuration
    public func addPinningConfig(_ config: PinningConfig) {
        pinnedCertificates[config.hostname] = config.certificates
        
        logger.info("Added certificate pinning for hostname: \(config.hostname)")
        
        // Save to persistent storage
        savePinnedCertificates()
    }
    
    /// Remove certificate pinning for hostname
    public func removePinningConfig(for hostname: String) {
        pinnedCertificates.removeValue(forKey: hostname)
        
        logger.info("Removed certificate pinning for hostname: \(hostname)")
        
        // Save to persistent storage
        savePinnedCertificates()
    }
    
    // MARK: - Certificate Validation
    
    /// Validate certificate for hostname
    public func validateCertificate(_ certificate: SecCertificate, for hostname: String) -> Bool {
        guard let pinnedCerts = pinnedCertificates[hostname] else {
            logger.warning("No pinned certificates found for hostname: \(hostname)")
            return false
        }
        
        let certificateData = SecCertificateCopyData(certificate) as Data
        let certificateHash = SHA256.hash(data: certificateData).description
        
        // Check if certificate hash matches any pinned certificate
        for pinnedCert in pinnedCerts {
            let pinnedHash = SHA256.hash(data: pinnedCert).description
            if certificateHash == pinnedHash {
                logger.info("Certificate validation successful for hostname: \(hostname)")
                return true
            }
        }
        
        // Log failure
        let failure = PinningFailure(
            hostname: hostname,
            reason: .hashMismatch,
            timestamp: Date(),
            certificateData: certificateData,
            expectedHashes: pinnedCerts.map { SHA256.hash(data: $0).description },
            actualHashes: [certificateHash]
        )
        
        pinningFailures.append(failure)
        logger.error("Certificate validation failed for hostname: \(hostname)")
        
        return false
    }
    
    /// Validate certificate chain
    public func validateCertificateChain(_ certificates: [SecCertificate], for hostname: String) -> Bool {
        guard !certificates.isEmpty else {
            logger.error("Empty certificate chain for hostname: \(hostname)")
            return false
        }
        
        // Validate the leaf certificate (first in chain)
        let leafCertificate = certificates[0]
        return validateCertificate(leafCertificate, for: hostname)
    }
    
    // MARK: - URLSession Delegate Integration
    
    /// Create URLSession with certificate pinning
    public func createURLSession(with configuration: URLSessionConfiguration) -> URLSession {
        let delegate = CertificatePinningURLSessionDelegate(pinningManager: self)
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    /// URLSession delegate for certificate pinning
    private class CertificatePinningURLSessionDelegate: NSObject, URLSessionDelegate {
        private let pinningManager: CertificatePinningManager
        
        init(pinningManager: CertificatePinningManager) {
            self.pinningManager = pinningManager
        }
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let serverTrust = challenge.protectionSpace.serverTrust,
                  let hostname = challenge.protectionSpace.host else {
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            
            // Check if pinning is enabled for this hostname
            guard pinningManager.isPinningEnabled,
                  pinningManager.pinnedCertificates[hostname] != nil else {
                // No pinning configured, use default validation
                completionHandler(.performDefaultHandling, nil)
                return
            }
            
            // Get certificate chain
            let certificateCount = SecTrustGetCertificateCount(serverTrust)
            var certificates: [SecCertificate] = []
            
            for i in 0..<certificateCount {
                if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) {
                    certificates.append(certificate)
                }
            }
            
            // Validate certificate chain
            if pinningManager.validateCertificateChain(certificates, for: hostname) {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                pinningManager.logger.error("Certificate pinning failed for hostname: \(hostname)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
    
    // MARK: - Certificate Management
    
    /// Get default certificates for hostname
    private func getDefaultCertificates(for hostname: String) -> [Data] {
        // In production, these would be the actual certificate data
        // For now, we'll use placeholder certificates
        return []
    }
    
    /// Get AWS certificates for hostname
    private func getAWSCertificates(for hostname: String) -> [Data] {
        // In production, these would be the actual AWS certificate data
        // For now, we'll use placeholder certificates
        return []
    }
    
    /// Update certificates for hostname
    public func updateCertificates(_ certificates: [Data], for hostname: String) {
        pinnedCertificates[hostname] = certificates
        savePinnedCertificates()
        
        logger.info("Updated certificates for hostname: \(hostname)")
    }
    
    /// Rotate certificates
    public func rotateCertificates() {
        // Implement certificate rotation logic
        logger.info("Certificate rotation initiated")
        
        // Clear old certificates
        pinnedCertificates.removeAll()
        
        // Reload certificates
        setupDefaultPinning()
        
        logger.info("Certificate rotation completed")
    }
    
    // MARK: - Persistence
    
    /// Save pinned certificates to persistent storage
    private func savePinnedCertificates() {
        // Save to UserDefaults or secure storage
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(pinnedCertificates) {
            UserDefaults.standard.set(data, forKey: "com.healthai.pinned-certificates")
        }
    }
    
    /// Load pinned certificates from persistent storage
    private func loadPinnedCertificates() {
        guard let data = UserDefaults.standard.data(forKey: "com.healthai.pinned-certificates") else {
            return
        }
        
        let decoder = JSONDecoder()
        if let certificates = try? decoder.decode([String: [Data]].self, from: data) {
            pinnedCertificates = certificates
        }
    }
    
    // MARK: - Monitoring and Reporting
    
    /// Get pinning statistics
    public func getPinningStatistics() -> PinningStatistics {
        let totalFailures = pinningFailures.count
        let recentFailures = pinningFailures.filter { 
            $0.timestamp.timeIntervalSinceNow > -86400 // Last 24 hours
        }.count
        
        let failureReasons = Dictionary(grouping: pinningFailures, by: { $0.reason })
            .mapValues { $0.count }
        
        return PinningStatistics(
            totalFailures: totalFailures,
            recentFailures: recentFailures,
            failureReasons: failureReasons,
            pinnedHostnames: Array(pinnedCertificates.keys),
            lastCheck: lastPinningCheck
        )
    }
    
    /// Clear pinning failures
    public func clearPinningFailures() {
        pinningFailures.removeAll()
        logger.info("Cleared pinning failures")
    }
    
    /// Enable/disable certificate pinning
    public func setPinningEnabled(_ enabled: Bool) {
        isPinningEnabled = enabled
        logger.info("Certificate pinning \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - Supporting Types

public struct PinningStatistics: Codable {
    public let totalFailures: Int
    public let recentFailures: Int
    public let failureReasons: [CertificatePinningManager.PinningFailure.FailureReason: Int]
    public let pinnedHostnames: [String]
    public let lastCheck: Date
}

// MARK: - Logger Extension

private extension Logger {
    func info(_ message: String) {
        self.log(level: .info, "\(message)")
    }
    
    func warning(_ message: String) {
        self.log(level: .warning, "\(message)")
    }
    
    func error(_ message: String) {
        self.log(level: .error, "\(message)")
    }
} 