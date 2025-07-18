import Foundation
import AWSS3
import CommonCrypto

/// Handles secure upload of telemetry data to both API and S3
public final class TelemetryUploadManager {
    private let config: TelemetryConfig
    private let urlSession: URLSession
    private let s3TransferUtility: AWSS3TransferUtility
    
    private let maxRetryCount = 3
    private let retryDelay: TimeInterval = 5.0
    
    public init(config: TelemetryConfig) {
        self.config = config
        
        // Configure URLSession with enhanced security settings
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.tlsMinimumSupportedProtocolVersion = .TLSv13
        sessionConfig.httpAdditionalHeaders = [
            "Authorization": "Bearer \(getSecureAPIKey())",
            "Content-Type": "application/json",
            "User-Agent": "HealthAI2030/1.0",
            "X-Request-ID": UUID().uuidString
        ]
        
        // Enable certificate pinning
        sessionConfig.urlCache = nil
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.urlSession = URLSession(configuration: sessionConfig)
        
        // Configure AWS S3 with secure credentials
        let credentialsProvider = AWSStaticCredentialsProvider(
            accessKey: getSecureAWSKey(),
            secretKey: getSecureAWSSecret()
        )
        let configuration = AWSServiceConfiguration(
            region: config.awsRegion,
            credentialsProvider: credentialsProvider
        )
        AWSS3TransferUtility.register(
            with: configuration!,
            forKey: "TelemetryUpload"
        )
        self.s3TransferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: "TelemetryUpload")!
    }
    
    // MARK: - Secure Credential Management
    
    private func getSecureAPIKey() -> String {
        // Get API key from secure storage
        if let apiKey = SecretsManager.shared.getSecret(named: "TELEMETRY_API_KEY") {
            return apiKey
        }
        
        // Fallback to environment variable
        if let envKey = ProcessInfo.processInfo.environment["TELEMETRY_API_KEY"] {
            return envKey
        }
        
        // Log security event for missing credentials
        logSecurityEvent("Missing telemetry API key", severity: .error)
        return ""
    }
    
    private func getSecureAWSKey() -> String {
        // Get AWS access key from secure storage
        if let awsKey = SecretsManager.shared.getSecret(named: "AWS_ACCESS_KEY_ID") {
            return awsKey
        }
        
        // Fallback to environment variable
        if let envKey = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"] {
            return envKey
        }
        
        logSecurityEvent("Missing AWS access key", severity: .error)
        return ""
    }
    
    private func getSecureAWSSecret() -> String {
        // Get AWS secret key from secure storage
        if let awsSecret = SecretsManager.shared.getSecret(named: "AWS_SECRET_ACCESS_KEY") {
            return awsSecret
        }
        
        // Fallback to environment variable
        if let envSecret = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"] {
            return envSecret
        }
        
        logSecurityEvent("Missing AWS secret key", severity: .error)
        return ""
    }
    
    private func logSecurityEvent(_ message: String, severity: SecuritySeverity) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] SECURITY [\(severity.rawValue)]: \(message)"
        
        // Log to console
        print(logMessage)
        
        // Log to security audit system
        // TODO: Integrate with centralized logging system
    }
    
    private enum SecuritySeverity: String {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    /// Upload telemetry events batch
    /// - Parameters:
    ///   - events: Array of telemetry events
    ///   - completion: Completion handler with result
    public func upload(events: [TelemetryEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        print("[TelemetryUpload] Starting upload of \(events.count) events")
        // First try API upload
        uploadToAPI(events: events, retryCount: 0) { [weak self] apiResult in
            switch apiResult {
            case .success:
                print("[TelemetryUpload] API upload succeeded")
                completion(.success(()))
            case .failure(let apiError):
                // Fallback to S3 if API fails
                print("[TelemetryUpload] API upload failed, falling back to S3: \(apiError)")
                self?.uploadToS3(events: events, retryCount: 0) { s3Result in
                    switch s3Result {
                    case .success:
                        print("[TelemetryUpload] S3 upload succeeded")
                        completion(.success(()))
                    case .failure(let s3Error):
                        let combinedError = TelemetryUploadError.combined(
                            apiError: apiError,
                            s3Error: s3Error
                        )
                        print("[TelemetryUpload] Both API and S3 upload failed: \(combinedError)")
                        completion(.failure(combinedError))
                    }
                }
            }
        }
    }
    
    private func uploadToAPI(events: [TelemetryEvent], retryCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard retryCount < maxRetryCount else {
            completion(.failure(TelemetryUploadError.maxRetriesExceeded))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(events)
            var request = URLRequest(url: config.apiEndpoint)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            
            let task = urlSession.dataTask(with: request) { _, response, error in
                if let error = error {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.uploadToAPI(events: events, retryCount: retryCount + 1, completion: completion)
                    }
                } else if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.uploadToAPI(events: events, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    completion(.success(()))
                }
            }
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    private func uploadToS3(events: [TelemetryEvent], retryCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard retryCount < maxRetryCount else {
            completion(.failure(TelemetryUploadError.maxRetriesExceeded))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(events)
            let fileName = "telemetry-\(Date().timeIntervalSince1970)-\(UUID().uuidString).json"
            let expression = AWSS3TransferUtilityUploadExpression()
            
            s3TransferUtility.uploadData(
                jsonData,
                bucket: config.s3Bucket,
                key: fileName,
                contentType: "application/json",
                expression: expression
            ) { _, error in
                if let error = error {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.uploadToS3(events: events, retryCount: retryCount + 1, completion: completion)
                    }
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}

public enum TelemetryUploadError: Error {
    case maxRetriesExceeded
    case combined(apiError: Error, s3Error: Error)
    
    public var localizedDescription: String {
        switch self {
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .combined(let apiError, let s3Error):
            return "API Error: \(apiError.localizedDescription). S3 Error: \(s3Error.localizedDescription)"
        }
    }
}