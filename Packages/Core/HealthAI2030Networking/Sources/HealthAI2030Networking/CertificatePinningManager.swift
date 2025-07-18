import Foundation
import Security
import CryptoKit
import os.log

/// Advanced Certificate Pinning Manager for HealthAI 2030
/// Provides robust protection against man-in-the-middle attacks
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
public class CertificatePinningManager: NSObject {
    
    // MARK: - Configuration
    
    public struct PinningConfiguration {
        public let pinnedCertificates: [String: [Data]]  // Domain -> Certificate data
        public let pinnedPublicKeys: [String: [Data]]    // Domain -> Public key hashes
        public let allowInvalidCertificates: Bool        // For development only
        public let validationMode: ValidationMode
        
        public enum ValidationMode {
            case certificate    // Pin entire certificate
            case publicKey      // Pin public key only (recommended)
            case both          // Validate both certificate and public key
        }
        
        public init(
            pinnedCertificates: [String: [Data]] = [:],
            pinnedPublicKeys: [String: [Data]] = [:],
            allowInvalidCertificates: Bool = false,
            validationMode: ValidationMode = .publicKey
        ) {
            self.pinnedCertificates = pinnedCertificates
            self.pinnedPublicKeys = pinnedPublicKeys
            self.allowInvalidCertificates = allowInvalidCertificates
            self.validationMode = validationMode
        }
        
        /// Default configuration for HealthAI 2030 production environment
        public static let `default` = PinningConfiguration(
            pinnedPublicKeys: [
                // Add your production server public key hashes here
                "api.healthai2030.com": [
                    // SHA-256 hash of public key (example)
                    Data(SHA256.hash(data: "REPLACE_WITH_ACTUAL_PUBLIC_KEY".data(using: .utf8)!))
                ],
                "secure.healthai2030.com": [
                    // Backup/secondary server public key
                    Data(SHA256.hash(data: "REPLACE_WITH_BACKUP_PUBLIC_KEY".data(using: .utf8)!))
                ]
            ],
            allowInvalidCertificates: false,
            validationMode: .publicKey
        )
        
        /// Development configuration (less restrictive)
        public static let development = PinningConfiguration(
            pinnedPublicKeys: [:],
            allowInvalidCertificates: true,
            validationMode: .publicKey
        )
    }
    
    // MARK: - Properties
    
    private let configuration: PinningConfiguration
    private let logger = Logger(subsystem: "com.healthai.networking", category: "CertificatePinning")
    
    public static let shared = CertificatePinningManager(configuration: .default)
    
    // MARK: - Initialization
    
    public init(configuration: PinningConfiguration) {
        self.configuration = configuration
        super.init()
        logger.info("Certificate pinning initialized with \(configuration.validationMode) validation")
    }
    
    // MARK: - Public Methods
    
    /// Validate certificate for given domain
    public func validateCertificate(
        for domain: String,
        serverTrust: SecTrust,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Task {
            let isValid = await performCertificateValidation(
                domain: domain,
                serverTrust: serverTrust
            )
            completionHandler(isValid)
        }
    }
    
    /// Get URLSessionDelegate for certificate pinning
    public func urlSessionDelegate() -> URLSessionDelegate {
        return CertificatePinningURLSessionDelegate(pinningManager: self)
    }
    
    /// Create URLSession with certificate pinning
    public func createPinnedURLSession() -> URLSession {
        let delegate = urlSessionDelegate()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    // MARK: - Certificate Validation
    
    private func performCertificateValidation(
        domain: String,
        serverTrust: SecTrust
    ) async -> Bool {
        
        logger.debug("Validating certificate for domain: \(domain)")
        
        // Step 1: Standard system validation
        guard await validateSystemTrust(serverTrust) else {
            if configuration.allowInvalidCertificates {
                logger.warning("System trust validation failed, but allowing for development")
            } else {
                logger.error("System trust validation failed for \(domain)")
                return false
            }
        }
        
        // Step 2: Certificate pinning validation
        switch configuration.validationMode {
        case .certificate:
            return await validatePinnedCertificates(domain: domain, serverTrust: serverTrust)
        case .publicKey:
            return await validatePinnedPublicKeys(domain: domain, serverTrust: serverTrust)
        case .both:
            let certValid = await validatePinnedCertificates(domain: domain, serverTrust: serverTrust)
            let keyValid = await validatePinnedPublicKeys(domain: domain, serverTrust: serverTrust)
            return certValid && keyValid
        }
    }
    
    private func validateSystemTrust(_ serverTrust: SecTrust) async -> Bool {
        var trustResult: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &trustResult)
        
        guard status == errSecSuccess else {
            logger.error("SecTrustEvaluate failed with status: \(status)")
            return false
        }
        
        switch trustResult {
        case .unspecified, .proceed:
            return true
        case .deny, .fatalTrustFailure, .otherError, .recoverableTrustFailure:
            logger.error("Trust evaluation failed: \(trustResult)")
            return false
        case .invalid:
            logger.error("Trust evaluation returned invalid result")
            return false
        @unknown default:
            logger.error("Unknown trust evaluation result: \(trustResult)")
            return false
        }
    }
    
    private func validatePinnedCertificates(
        domain: String,
        serverTrust: SecTrust
    ) async -> Bool {
        
        guard let pinnedCerts = configuration.pinnedCertificates[domain] else {
            logger.debug("No pinned certificates for domain: \(domain)")
            return true // No pinning configured for this domain
        }
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            let certificateData = SecCertificateCopyData(certificate)
            let serverCertData = CFDataGetBytePtr(certificateData)
            let serverCertLength = CFDataGetLength(certificateData)
            let serverCertBytes = Data(bytes: serverCertData!, count: serverCertLength)
            
            // Check if server certificate matches any pinned certificate
            for pinnedCert in pinnedCerts {
                if serverCertBytes == pinnedCert {
                    logger.info("Certificate pinning validation successful for \(domain)")
                    return true
                }
            }
        }
        
        logger.error("Certificate pinning validation failed for \(domain)")
        return false
    }
    
    private func validatePinnedPublicKeys(
        domain: String,
        serverTrust: SecTrust
    ) async -> Bool {
        
        guard let pinnedKeys = configuration.pinnedPublicKeys[domain] else {
            logger.debug("No pinned public keys for domain: \(domain)")
            return true // No pinning configured for this domain
        }
        
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i),
                  let publicKey = SecCertificateCopyKey(certificate) else {
                continue
            }
            
            guard let publicKeyData = extractPublicKeyData(from: publicKey) else {
                continue
            }
            
            let publicKeyHash = Data(SHA256.hash(data: publicKeyData))
            
            // Check if public key hash matches any pinned key
            for pinnedKey in pinnedKeys {
                if publicKeyHash == pinnedKey {
                    logger.info("Public key pinning validation successful for \(domain)")
                    return true
                }
            }
        }
        
        logger.error("Public key pinning validation failed for \(domain)")
        return false
    }
    
    private func extractPublicKeyData(from publicKey: SecKey) -> Data? {
        var error: Unmanaged<CFError>?
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            if let error = error?.takeRetainedValue() {
                logger.error("Failed to extract public key data: \(CFErrorCopyDescription(error))")
            }
            return nil
        }
        
        return Data(referencing: publicKeyData)
    }
    
    // MARK: - Utility Methods
    
    /// Extract public key hash from certificate for pinning configuration
    public static func extractPublicKeyHash(from certificateData: Data) -> Data? {
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData),
              let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }
        
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            return nil
        }
        
        let keyData = Data(referencing: publicKeyData)
        return Data(SHA256.hash(data: keyData))
    }
    
    /// Load certificate from bundle
    public static func loadCertificate(named fileName: String, in bundle: Bundle = .main) -> Data? {
        guard let certPath = bundle.path(forResource: fileName, ofType: "cer"),
              let certData = NSData(contentsOfFile: certPath) else {
            return nil
        }
        return Data(referencing: certData)
    }
    
    /// Generate pinning configuration from certificates in bundle
    public static func generatePinningConfiguration(
        certificates: [String: String], // Domain -> Certificate filename
        bundle: Bundle = .main
    ) -> PinningConfiguration? {
        
        var pinnedKeys: [String: [Data]] = [:]
        
        for (domain, certFilename) in certificates {
            guard let certData = loadCertificate(named: certFilename, in: bundle),
                  let keyHash = extractPublicKeyHash(from: certData) else {
                continue
            }
            pinnedKeys[domain] = [keyHash]
        }
        
        guard !pinnedKeys.isEmpty else {
            return nil
        }
        
        return PinningConfiguration(
            pinnedPublicKeys: pinnedKeys,
            validationMode: .publicKey
        )
    }
}

// MARK: - URLSessionDelegate Implementation

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
private class CertificatePinningURLSessionDelegate: NSObject, URLSessionDelegate {
    
    private let pinningManager: CertificatePinningManager
    private let logger = Logger(subsystem: "com.healthai.networking", category: "URLSessionDelegate")
    
    init(pinningManager: CertificatePinningManager) {
        self.pinningManager = pinningManager
        super.init()
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            logger.error("No server trust in authentication challenge")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let domain = challenge.protectionSpace.host
        logger.debug("Received authentication challenge for domain: \(domain)")
        
        pinningManager.validateCertificate(for: domain, serverTrust: serverTrust) { isValid in
            if isValid {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                self.logger.error("Certificate validation failed for \(domain)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}

// MARK: - Networking Extensions

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
extension URLSession {
    
    /// Create URLSession with certificate pinning for HealthAI 2030
    public static func healthAIPinnedSession(
        configuration: CertificatePinningManager.PinningConfiguration = .default
    ) -> URLSession {
        let pinningManager = CertificatePinningManager(configuration: configuration)
        return pinningManager.createPinnedURLSession()
    }
}

// MARK: - Security Policies

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
public extension CertificatePinningManager {
    
    /// Security policy for different environments
    enum SecurityPolicy {
        case production     // Strict certificate pinning
        case staging        // Moderate security for testing
        case development    // Relaxed for development
        
        var configuration: PinningConfiguration {
            switch self {
            case .production:
                return .default
            case .staging:
                return PinningConfiguration(
                    pinnedPublicKeys: [
                        "staging.healthai2030.com": [
                            Data(SHA256.hash(data: "STAGING_PUBLIC_KEY".data(using: .utf8)!))
                        ]
                    ],
                    allowInvalidCertificates: false,
                    validationMode: .publicKey
                )
            case .development:
                return .development
            }
        }
    }
    
    /// Create pinning manager with predefined security policy
    static func create(for policy: SecurityPolicy) -> CertificatePinningManager {
        return CertificatePinningManager(configuration: policy.configuration)
    }
}

// MARK: - Error Types

public enum CertificatePinningError: LocalizedError {
    case validationFailed(domain: String)
    case invalidCertificate
    case publicKeyExtractionFailed
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .validationFailed(let domain):
            return "Certificate pinning validation failed for domain: \(domain)"
        case .invalidCertificate:
            return "Invalid certificate provided"
        case .publicKeyExtractionFailed:
            return "Failed to extract public key from certificate"
        case .configurationError(let message):
            return "Certificate pinning configuration error: \(message)"
        }
    }
}