import Foundation
import Combine
import os.log

/// Comprehensive rate limiting manager for HealthAI-2030
/// Implements rate limiting for authentication attempts and security-sensitive operations
@MainActor
public class RateLimitingManager: ObservableObject {
    public static let shared = RateLimitingManager()
    
    @Published private(set) var rateLimits: [String: RateLimit] = [:]
    @Published private(set) var blockedIPs: [String: BlockedIP] = [:]
    @Published private(set) var rateLimitViolations: [RateLimitViolation] = []
    @Published private(set) var isEnabled = true
    
    private let logger = Logger(subsystem: "com.healthai.security", category: "RateLimiting")
    private let securityQueue = DispatchQueue(label: "com.healthai.rate-limiting", qos: .userInitiated)
    private var cleanupTimer: Timer?
    
    // MARK: - Rate Limiting Configuration
    
    /// Rate limit configuration
    public struct RateLimit: Codable {
        public let identifier: String
        public let maxRequests: Int
        public let timeWindow: TimeInterval
        public let action: RateLimitAction
        public let description: String
        
        public init(identifier: String, maxRequests: Int, timeWindow: TimeInterval, action: RateLimitAction, description: String) {
            self.identifier = identifier
            self.maxRequests = maxRequests
            self.timeWindow = timeWindow
            self.action = action
            self.description = description
        }
    }
    
    /// Rate limit action
    public enum RateLimitAction: String, CaseIterable, Codable {
        case block = "block"
        case delay = "delay"
        case challenge = "challenge"
        case log = "log"
    }
    
    /// Rate limit entry
    private struct RateLimitEntry: Codable {
        let timestamp: Date
        let count: Int
    }
    
    /// Blocked IP information
    public struct BlockedIP: Identifiable, Codable {
        public let id = UUID()
        public let ipAddress: String
        public let reason: String
        public let blockedAt: Date
        public let expiresAt: Date
        public let violationCount: Int
        
        public var isExpired: Bool {
            return Date() > expiresAt
        }
    }
    
    /// Rate limit violation
    public struct RateLimitViolation: Identifiable, Codable {
        public let id = UUID()
        public let identifier: String
        public let ipAddress: String
        public let userAgent: String?
        public let timestamp: Date
        public let requestCount: Int
        public let maxAllowed: Int
        public let action: RateLimitAction
        public let metadata: [String: String]
    }
    
    private init() {
        setupDefaultRateLimits()
        startCleanupTimer()
    }
    
    // MARK: - Rate Limiting Setup
    
    /// Setup default rate limits
    private func setupDefaultRateLimits() {
        // Authentication rate limits
        addRateLimit(RateLimit(
            identifier: "auth_login",
            maxRequests: 5,
            timeWindow: 300, // 5 minutes
            action: .block,
            description: "Login attempts per IP"
        ))
        
        addRateLimit(RateLimit(
            identifier: "auth_password_reset",
            maxRequests: 3,
            timeWindow: 3600, // 1 hour
            action: .delay,
            description: "Password reset requests per IP"
        ))
        
        addRateLimit(RateLimit(
            identifier: "auth_mfa",
            maxRequests: 10,
            timeWindow: 300, // 5 minutes
            action: .challenge,
            description: "MFA attempts per user"
        ))
        
        // API rate limits
        addRateLimit(RateLimit(
            identifier: "api_general",
            maxRequests: 100,
            timeWindow: 60, // 1 minute
            action: .delay,
            description: "General API requests per IP"
        ))
        
        addRateLimit(RateLimit(
            identifier: "api_sensitive",
            maxRequests: 20,
            timeWindow: 300, // 5 minutes
            action: .challenge,
            description: "Sensitive API requests per IP"
        ))
        
        // File upload rate limits
        addRateLimit(RateLimit(
            identifier: "file_upload",
            maxRequests: 10,
            timeWindow: 3600, // 1 hour
            action: .delay,
            description: "File uploads per IP"
        ))
        
        // Data export rate limits
        addRateLimit(RateLimit(
            identifier: "data_export",
            maxRequests: 5,
            timeWindow: 86400, // 24 hours
            action: .challenge,
            description: "Data export requests per user"
        ))
    }
    
    /// Add rate limit configuration
    public func addRateLimit(_ rateLimit: RateLimit) {
        rateLimits[rateLimit.identifier] = rateLimit
        logger.info("Added rate limit: \(rateLimit.identifier) - \(rateLimit.description)")
    }
    
    /// Get rate limit configuration
    public func getRateLimitConfig(identifier: String) -> RateLimit? {
        return rateLimits[identifier]
    }
    
    /// Remove rate limit configuration
    public func removeRateLimit(for identifier: String) {
        rateLimits.removeValue(forKey: identifier)
        logger.info("Removed rate limit: \(identifier)")
    }
    
    // MARK: - Rate Limiting Logic
    
    /// Check if request is allowed
    public func checkRateLimit(identifier: String, ipAddress: String, userAgent: String? = nil) -> RateLimitResult {
        guard isEnabled else {
            return RateLimitResult(allowed: true, action: .log, delay: 0, reason: "Rate limiting disabled")
        }
        
        // Check if IP is blocked
        if isIPBlocked(ipAddress) {
            return RateLimitResult(allowed: false, action: .block, delay: 0, reason: "IP address is blocked")
        }
        
        // Get rate limit configuration
        guard let rateLimit = rateLimits[identifier] else {
            return RateLimitResult(allowed: true, action: .log, delay: 0, reason: "No rate limit configured")
        }
        
        // Check current request count
        let currentCount = getCurrentRequestCount(identifier: identifier, ipAddress: ipAddress)
        
        if currentCount >= rateLimit.maxRequests {
            // Rate limit exceeded
            let violation = RateLimitViolation(
                identifier: identifier,
                ipAddress: ipAddress,
                userAgent: userAgent,
                timestamp: Date(),
                requestCount: currentCount,
                maxAllowed: rateLimit.maxRequests,
                action: rateLimit.action,
                metadata: ["timeWindow": "\(rateLimit.timeWindow)"]
            )
            
            rateLimitViolations.append(violation)
            
            // Handle rate limit action
            switch rateLimit.action {
            case .block:
                blockIP(ipAddress, reason: "Rate limit exceeded for \(identifier)")
                return RateLimitResult(allowed: false, action: .block, delay: 0, reason: "Rate limit exceeded")
                
            case .delay:
                let delay = calculateDelay(currentCount: currentCount, maxRequests: rateLimit.maxRequests)
                return RateLimitResult(allowed: true, action: .delay, delay: delay, reason: "Rate limit exceeded, applying delay")
                
            case .challenge:
                return RateLimitResult(allowed: true, action: .challenge, delay: 0, reason: "Rate limit exceeded, challenge required")
                
            case .log:
                return RateLimitResult(allowed: true, action: .log, delay: 0, reason: "Rate limit exceeded, logging only")
            }
        }
        
        // Increment request count
        incrementRequestCount(identifier: identifier, ipAddress: ipAddress)
        
        return RateLimitResult(allowed: true, action: .log, delay: 0, reason: "Request allowed")
    }
    
    /// Rate limit result
    public struct RateLimitResult {
        public let allowed: Bool
        public let action: RateLimitAction
        public let delay: TimeInterval
        public let reason: String
    }
    
    // MARK: - Request Tracking
    
    /// Get current request count for identifier and IP
    private func getCurrentRequestCount(identifier: String, ipAddress: String) -> Int {
        let key = "\(identifier):\(ipAddress)"
        guard let entry = getRateLimitEntry(for: key) else {
            return 0
        }
        
        // Check if entry is still within time window
        let timeWindow = rateLimits[identifier]?.timeWindow ?? 60
        if Date().timeIntervalSince(entry.timestamp) > timeWindow {
            return 0
        }
        
        return entry.count
    }
    
    /// Increment request count for identifier and IP
    private func incrementRequestCount(identifier: String, ipAddress: String) {
        let key = "\(identifier):\(ipAddress)"
        let currentCount = getCurrentRequestCount(identifier: identifier, ipAddress: ipAddress)
        
        let entry = RateLimitEntry(timestamp: Date(), count: currentCount + 1)
        saveRateLimitEntry(entry, for: key)
    }
    
    /// Get rate limit entry from storage
    private func getRateLimitEntry(for key: String) -> RateLimitEntry? {
        guard let data = UserDefaults.standard.data(forKey: "rate_limit_\(key)") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(RateLimitEntry.self, from: data)
    }
    
    /// Save rate limit entry to storage
    private func saveRateLimitEntry(_ entry: RateLimitEntry, for key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(entry) {
            UserDefaults.standard.set(data, forKey: "rate_limit_\(key)")
        }
    }
    
    // MARK: - IP Blocking
    
    /// Check if IP is blocked
    private func isIPBlocked(_ ipAddress: String) -> Bool {
        guard let blockedIP = blockedIPs[ipAddress] else {
            return false
        }
        
        if blockedIP.isExpired {
            // Remove expired block
            blockedIPs.removeValue(forKey: ipAddress)
            return false
        }
        
        return true
    }
    
    /// Block IP address
    private func blockIP(_ ipAddress: String, reason: String) {
        let blockedIP = BlockedIP(
            ipAddress: ipAddress,
            reason: reason,
            blockedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600), // 1 hour
            violationCount: 1
        )
        
        blockedIPs[ipAddress] = blockedIP
        logger.warning("Blocked IP address: \(ipAddress) - Reason: \(reason)")
    }
    
    /// Unblock IP address
    public func unblockIP(_ ipAddress: String) {
        blockedIPs.removeValue(forKey: ipAddress)
        logger.info("Unblocked IP address: \(ipAddress)")
    }
    
    /// Get blocked IPs
    public func getBlockedIPs() -> [BlockedIP] {
        return Array(blockedIPs.values)
    }
    
    // MARK: - Utility Methods
    
    /// Calculate delay based on current count
    private func calculateDelay(currentCount: Int, maxRequests: Int) -> TimeInterval {
        let excess = currentCount - maxRequests
        return TimeInterval(excess * 2) // 2 seconds per excess request
    }
    
    /// Start cleanup timer
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupExpiredEntries()
        }
    }
    
    /// Cleanup expired entries
    private func cleanupExpiredEntries() {
        // Cleanup expired IP blocks
        let expiredIPs = blockedIPs.filter { $0.value.isExpired }
        for (ip, _) in expiredIPs {
            blockedIPs.removeValue(forKey: ip)
        }
        
        // Cleanup old rate limit entries
        let now = Date()
        for (key, _) in UserDefaults.standard.dictionaryRepresentation() {
            if key.hasPrefix("rate_limit_") {
                if let entry = getRateLimitEntry(for: String(key.dropFirst(12))) {
                    let timeWindow = 3600 // Default 1 hour
                    if now.timeIntervalSince(entry.timestamp) > timeWindow {
                        UserDefaults.standard.removeObject(forKey: key)
                    }
                }
            }
        }
        
        logger.info("Cleaned up expired rate limiting entries")
    }
    
    // MARK: - Monitoring and Reporting
    
    /// Get rate limiting statistics
    public func getRateLimitingStatistics() -> RateLimitingStatistics {
        let totalViolations = rateLimitViolations.count
        let recentViolations = rateLimitViolations.filter { 
            $0.timestamp.timeIntervalSinceNow > -3600 // Last hour
        }.count
        
        let violationTypes = Dictionary(grouping: rateLimitViolations, by: { $0.identifier })
            .mapValues { $0.count }
        
        return RateLimitingStatistics(
            totalViolations: totalViolations,
            recentViolations: recentViolations,
            violationTypes: violationTypes,
            blockedIPs: Array(blockedIPs.values),
            activeRateLimits: Array(rateLimits.values)
        )
    }
    
    /// Clear rate limit violations
    public func clearRateLimitViolations() {
        rateLimitViolations.removeAll()
        logger.info("Cleared rate limit violations")
    }
    
    /// Enable/disable rate limiting
    public func setRateLimitingEnabled(_ enabled: Bool) {
        isEnabled = enabled
        logger.info("Rate limiting \(enabled ? "enabled" : "disabled")")
    }
    
    /// Reset rate limits for identifier and IP
    public func resetRateLimit(identifier: String, ipAddress: String) {
        let key = "\(identifier):\(ipAddress)"
        UserDefaults.standard.removeObject(forKey: "rate_limit_\(key)")
        logger.info("Reset rate limit for \(identifier):\(ipAddress)")
    }
}

// MARK: - Supporting Types

public struct RateLimitingStatistics: Codable {
    public let totalViolations: Int
    public let recentViolations: Int
    public let violationTypes: [String: Int]
    public let blockedIPs: [RateLimitingManager.BlockedIP]
    public let activeRateLimits: [RateLimitingManager.RateLimit]
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