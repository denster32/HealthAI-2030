import Foundation
import os.log

/// API versioning strategy and endpoint management
public struct APIVersioningManager {
    private let logger = Logger(subsystem: "com.healthai.networking", category: "APIVersioning")
    
    public static let shared = APIVersioningManager()
    
    private init() {}
    
    // MARK: - API Endpoints Configuration
    
    /// Base URLs for different environments
    public enum Environment: String, CaseIterable {
        case development = "https://api-dev.healthai2030.com"
        case staging = "https://api-staging.healthai2030.com"
        case production = "https://api.healthai2030.com"
        
        public var baseURL: URL {
            return URL(string: rawValue)!
        }
    }
    
    /// API versions supported by the app
    public enum APIVersion: String, CaseIterable {
        case v1 = "v1"
        case v2 = "v2"
        case v3 = "v3"
        
        public var versionString: String {
            return rawValue
        }
        
        public var headerValue: String {
            return "application/vnd.healthai.\(rawValue)+json"
        }
    }
    
    /// API endpoints with their versions and paths
    public struct APIEndpoint {
        public let path: String
        public let version: APIVersion
        public let method: HTTPMethod
        public let description: String
        public let deprecated: Bool
        
        public init(path: String, version: APIVersion, method: HTTPMethod, description: String, deprecated: Bool = false) {
            self.path = path
            self.version = version
            self.method = method
            self.description = description
            self.deprecated = deprecated
        }
        
        public var fullPath: String {
            return "/\(version.rawValue)\(path)"
        }
    }
    
    /// HTTP methods
    public enum HTTPMethod: String, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
    
    // MARK: - API Endpoints Registry
    
    /// All available API endpoints
    public var allEndpoints: [APIEndpoint] {
        return [
            // Health Data Endpoints
            APIEndpoint(path: "/health/records", version: .v1, method: .get, description: "Get user health records"),
            APIEndpoint(path: "/health/records", version: .v1, method: .post, description: "Create health record"),
            APIEndpoint(path: "/health/records/{id}", version: .v1, method: .put, description: "Update health record"),
            APIEndpoint(path: "/health/records/{id}", version: .v1, method: .delete, description: "Delete health record"),
            
            // Enhanced Health Data Endpoints (v2)
            APIEndpoint(path: "/health/records", version: .v2, method: .get, description: "Get user health records with enhanced metadata"),
            APIEndpoint(path: "/health/records", version: .v2, method: .post, description: "Create health record with validation"),
            APIEndpoint(path: "/health/records/{id}", version: .v2, method: .put, description: "Update health record with conflict resolution"),
            APIEndpoint(path: "/health/records/{id}", version: .v2, method: .delete, description: "Delete health record with cascade options"),
            
            // Sleep Tracking Endpoints
            APIEndpoint(path: "/sleep/sessions", version: .v1, method: .get, description: "Get sleep sessions"),
            APIEndpoint(path: "/sleep/sessions", version: .v1, method: .post, description: "Create sleep session"),
            APIEndpoint(path: "/sleep/analysis", version: .v1, method: .post, description: "Analyze sleep data"),
            
            // Enhanced Sleep Endpoints (v2)
            APIEndpoint(path: "/sleep/sessions", version: .v2, method: .get, description: "Get sleep sessions with detailed metrics"),
            APIEndpoint(path: "/sleep/sessions", version: .v2, method: .post, description: "Create sleep session with AI analysis"),
            APIEndpoint(path: "/sleep/analysis", version: .v2, method: .post, description: "Advanced sleep analysis with ML insights"),
            
            // Mental Health Endpoints
            APIEndpoint(path: "/mental-health/mood", version: .v1, method: .get, description: "Get mood tracking data"),
            APIEndpoint(path: "/mental-health/mood", version: .v1, method: .post, description: "Log mood entry"),
            APIEndpoint(path: "/mental-health/stress", version: .v1, method: .get, description: "Get stress levels"),
            APIEndpoint(path: "/mental-health/stress", version: .v1, method: .post, description: "Log stress level"),
            
            // Enhanced Mental Health Endpoints (v2)
            APIEndpoint(path: "/mental-health/mood", version: .v2, method: .get, description: "Get mood tracking with trends and patterns"),
            APIEndpoint(path: "/mental-health/mood", version: .v2, method: .post, description: "Log mood entry with context"),
            APIEndpoint(path: "/mental-health/stress", version: .v2, method: .get, description: "Get stress levels with interventions"),
            APIEndpoint(path: "/mental-health/stress", version: .v2, method: .post, description: "Log stress level with triggers"),
            
            // AI/ML Model Endpoints
            APIEndpoint(path: "/ml/models", version: .v1, method: .get, description: "Get available ML models"),
            APIEndpoint(path: "/ml/models/{id}", version: .v1, method: .get, description: "Get specific ML model"),
            APIEndpoint(path: "/ml/predictions", version: .v1, method: .post, description: "Get health predictions"),
            
            // Enhanced ML Endpoints (v2)
            APIEndpoint(path: "/ml/models", version: .v2, method: .get, description: "Get ML models with performance metrics"),
            APIEndpoint(path: "/ml/models/{id}", version: .v2, method: .get, description: "Get ML model with version history"),
            APIEndpoint(path: "/ml/predictions", version: .v2, method: .post, description: "Get predictions with confidence scores"),
            APIEndpoint(path: "/ml/explanations", version: .v2, method: .post, description: "Get AI explanations for predictions"),
            
            // Quantum Health Endpoints (v3)
            APIEndpoint(path: "/quantum/simulations", version: .v3, method: .post, description: "Run quantum health simulations"),
            APIEndpoint(path: "/quantum/results", version: .v3, method: .get, description: "Get quantum simulation results"),
            APIEndpoint(path: "/quantum/optimization", version: .v3, method: .post, description: "Optimize health parameters using quantum algorithms"),
            
            // User Management Endpoints
            APIEndpoint(path: "/users/profile", version: .v1, method: .get, description: "Get user profile"),
            APIEndpoint(path: "/users/profile", version: .v1, method: .put, description: "Update user profile"),
            APIEndpoint(path: "/users/settings", version: .v1, method: .get, description: "Get user settings"),
            APIEndpoint(path: "/users/settings", version: .v1, method: .put, description: "Update user settings"),
            
            // Enhanced User Endpoints (v2)
            APIEndpoint(path: "/users/profile", version: .v2, method: .get, description: "Get user profile with preferences"),
            APIEndpoint(path: "/users/profile", version: .v2, method: .put, description: "Update user profile with validation"),
            APIEndpoint(path: "/users/settings", version: .v2, method: .get, description: "Get user settings with categories"),
            APIEndpoint(path: "/users/settings", version: .v2, method: .put, description: "Update user settings with conflict resolution"),
            
            // Authentication Endpoints
            APIEndpoint(path: "/auth/login", version: .v1, method: .post, description: "User login"),
            APIEndpoint(path: "/auth/logout", version: .v1, method: .post, description: "User logout"),
            APIEndpoint(path: "/auth/refresh", version: .v1, method: .post, description: "Refresh authentication token"),
            
            // Enhanced Auth Endpoints (v2)
            APIEndpoint(path: "/auth/login", version: .v2, method: .post, description: "User login with 2FA support"),
            APIEndpoint(path: "/auth/logout", version: .v2, method: .post, description: "User logout with device management"),
            APIEndpoint(path: "/auth/refresh", version: .v2, method: .post, description: "Refresh token with security validation"),
            
            // Telemetry Endpoints
            APIEndpoint(path: "/telemetry/events", version: .v1, method: .post, description: "Upload telemetry events"),
            APIEndpoint(path: "/telemetry/analytics", version: .v1, method: .get, description: "Get telemetry analytics"),
            
            // Enhanced Telemetry Endpoints (v2)
            APIEndpoint(path: "/telemetry/events", version: .v2, method: .post, description: "Upload telemetry events with batching"),
            APIEndpoint(path: "/telemetry/analytics", version: .v2, method: .get, description: "Get telemetry analytics with insights"),
            
            // Support and Feedback Endpoints
            APIEndpoint(path: "/support/feedback", version: .v1, method: .post, description: "Submit feedback"),
            APIEndpoint(path: "/support/tickets", version: .v1, method: .get, description: "Get support tickets"),
            APIEndpoint(path: "/support/tickets", version: .v1, method: .post, description: "Create support ticket"),
            
            // Enhanced Support Endpoints (v2)
            APIEndpoint(path: "/support/feedback", version: .v2, method: .post, description: "Submit feedback with categorization"),
            APIEndpoint(path: "/support/tickets", version: .v2, method: .get, description: "Get support tickets with status tracking"),
            APIEndpoint(path: "/support/tickets", version: .v2, method: .post, description: "Create support ticket with priority"),
            
            // Deprecated endpoints (marked for removal)
            APIEndpoint(path: "/legacy/health", version: .v1, method: .get, description: "Legacy health endpoint", deprecated: true),
            APIEndpoint(path: "/legacy/sleep", version: .v1, method: .get, description: "Legacy sleep endpoint", deprecated: true)
        ]
    }
    
    // MARK: - API Versioning Strategy
    
    /// Current API version used by the app
    public var currentAPIVersion: APIVersion {
        return .v2 // Default to v2 for most endpoints
    }
    
    /// Minimum supported API version
    public var minimumSupportedVersion: APIVersion {
        return .v1
    }
    
    /// Get the appropriate API version for a specific endpoint
    public func getAPIVersion(for endpoint: APIEndpoint) -> APIVersion {
        // Use the endpoint's specified version, or fall back to current version
        return endpoint.version
    }
    
    /// Check if an API version is supported
    public func isVersionSupported(_ version: APIVersion) -> Bool {
        return APIVersion.allCases.contains(version) && 
               version.rawValue >= minimumSupportedVersion.rawValue
    }
    
    /// Get endpoints for a specific version
    public func getEndpoints(for version: APIVersion) -> [APIEndpoint] {
        return allEndpoints.filter { $0.version == version }
    }
    
    /// Get deprecated endpoints
    public func getDeprecatedEndpoints() -> [APIEndpoint] {
        return allEndpoints.filter { $0.deprecated }
    }
    
    // MARK: - URL Construction
    
    /// Build a complete URL for an endpoint
    public func buildURL(for endpoint: APIEndpoint, environment: Environment = .production) -> URL {
        let baseURL = environment.baseURL
        let fullPath = endpoint.fullPath
        return baseURL.appendingPathComponent(fullPath)
    }
    
    /// Build a complete URL with path parameters
    public func buildURL(for endpoint: APIEndpoint, pathParameters: [String: String], environment: Environment = .production) -> URL {
        var path = endpoint.fullPath
        
        // Replace path parameters
        for (key, value) in pathParameters {
            path = path.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        let baseURL = environment.baseURL
        return baseURL.appendingPathComponent(path)
    }
    
    // MARK: - Backward Compatibility
    
    /// Check if an endpoint has a newer version available
    public func hasNewerVersion(for endpoint: APIEndpoint) -> Bool {
        let newerVersions = APIVersion.allCases.filter { $0.rawValue > endpoint.version.rawValue }
        return !newerVersions.isEmpty
    }
    
    /// Get the latest version of an endpoint
    public func getLatestVersion(for path: String) -> APIVersion? {
        let endpoints = allEndpoints.filter { $0.path == path }
        return endpoints.map { $0.version }.max { $0.rawValue < $1.rawValue }
    }
    
    /// Migrate an endpoint to a newer version
    public func migrateEndpoint(_ endpoint: APIEndpoint, to version: APIVersion) -> APIEndpoint? {
        guard isVersionSupported(version) else {
            logger.warning("Attempted to migrate to unsupported version: \(version.rawValue)")
            return nil
        }
        
        // Check if the target version exists for this path
        let targetEndpoint = allEndpoints.first { $0.path == endpoint.path && $0.version == version }
        return targetEndpoint
    }
    
    // MARK: - Version Headers
    
    /// Get headers for API versioning
    public func getVersionHeaders(for endpoint: APIEndpoint) -> [String: String] {
        var headers: [String: String] = [:]
        
        // Add API version header
        headers["API-Version"] = endpoint.version.versionString
        
        // Add Accept header for version-specific content
        headers["Accept"] = endpoint.version.headerValue
        
        // Add Content-Type header for requests with body
        if endpoint.method != .get {
            headers["Content-Type"] = endpoint.version.headerValue
        }
        
        return headers
    }
    
    // MARK: - Validation
    
    /// Validate that an endpoint exists and is supported
    public func validateEndpoint(_ endpoint: APIEndpoint) -> Bool {
        return allEndpoints.contains { $0.path == endpoint.path && $0.version == endpoint.version }
    }
    
    /// Check if an endpoint is deprecated
    public func isEndpointDeprecated(_ endpoint: APIEndpoint) -> Bool {
        return endpoint.deprecated
    }
    
    // MARK: - Documentation
    
    /// Generate API documentation
    public func generateAPIDocumentation() -> String {
        var documentation = "# HealthAI 2030 API Documentation\n\n"
        
        // Group endpoints by version
        for version in APIVersion.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            let endpoints = getEndpoints(for: version)
            if !endpoints.isEmpty {
                documentation += "## API Version \(version.rawValue.uppercased())\n\n"
                
                for endpoint in endpoints.sorted(by: { $0.path < $1.path }) {
                    let deprecatedFlag = endpoint.deprecated ? " (DEPRECATED)" : ""
                    documentation += "### \(endpoint.method.rawValue) \(endpoint.fullPath)\(deprecatedFlag)\n"
                    documentation += "\(endpoint.description)\n\n"
                }
            }
        }
        
        return documentation
    }
    
    /// Export endpoints as JSON for external tools
    public func exportEndpointsAsJSON() -> Data? {
        let endpointsData = allEndpoints.map { endpoint in
            [
                "path": endpoint.path,
                "version": endpoint.version.rawValue,
                "method": endpoint.method.rawValue,
                "description": endpoint.description,
                "deprecated": endpoint.deprecated,
                "fullPath": endpoint.fullPath
            ]
        }
        
        return try? JSONSerialization.data(withJSONObject: endpointsData, options: .prettyPrinted)
    }
} 