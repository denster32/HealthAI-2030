import Foundation
import SwiftUI

/// Protocol defining the requirements for developer sandbox environment management
protocol DeveloperSandboxProtocol {
    func createSandbox(for developer: Developer) async throws -> SandboxEnvironment
    func provisionTestData(for sandboxID: String) async throws -> TestDataProvision
    func simulateAPIResponses(for sandboxID: String, endpoint: String) async throws -> SimulatedResponse
    func monitorSandboxUsage(for sandboxID: String) async throws -> SandboxUsageMetrics
    func cleanupSandbox(for sandboxID: String) async throws -> CleanupResult
}

/// Structure representing a developer
struct Developer: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let organization: String
    let apiKey: String
    let sandboxAccess: Bool
    let createdAt: Date
    let lastActive: Date?
    
    init(name: String, email: String, organization: String, apiKey: String, sandboxAccess: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.email = email
        self.organization = organization
        self.apiKey = apiKey
        self.sandboxAccess = sandboxAccess
        self.createdAt = Date()
        self.lastActive = nil
    }
}

/// Structure representing a sandbox environment
struct SandboxEnvironment: Codable, Identifiable {
    let id: String
    let developerID: String
    let name: String
    let status: SandboxStatus
    let createdAt: Date
    let expiresAt: Date
    let configuration: SandboxConfiguration
    let endpoints: [SandboxEndpoint]
    let testData: TestDataProvision?
    
    init(developerID: String, name: String, configuration: SandboxConfiguration) {
        self.id = UUID().uuidString
        self.developerID = developerID
        self.name = name
        self.status = .creating
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        self.configuration = configuration
        self.endpoints = []
        self.testData = nil
    }
}

/// Structure representing sandbox configuration
struct SandboxConfiguration: Codable {
    let apiVersion: String
    let enabledEndpoints: [String]
    let rateLimit: RateLimitConfiguration
    let dataRetention: DataRetentionConfiguration
    let securitySettings: SecurityConfiguration
    
    init(apiVersion: String = "v1", enabledEndpoints: [String] = [], rateLimit: RateLimitConfiguration = RateLimitConfiguration(), dataRetention: DataRetentionConfiguration = DataRetentionConfiguration(), securitySettings: SecurityConfiguration = SecurityConfiguration()) {
        self.apiVersion = apiVersion
        self.enabledEndpoints = enabledEndpoints
        self.rateLimit = rateLimit
        self.dataRetention = dataRetention
        self.securitySettings = securitySettings
    }
}

/// Structure representing rate limit configuration
struct RateLimitConfiguration: Codable {
    let requestsPerMinute: Int
    let requestsPerHour: Int
    let burstLimit: Int
    
    init(requestsPerMinute: Int = 60, requestsPerHour: Int = 1000, burstLimit: Int = 10) {
        self.requestsPerMinute = requestsPerMinute
        self.requestsPerHour = requestsPerHour
        self.burstLimit = burstLimit
    }
}

/// Structure representing data retention configuration
struct DataRetentionConfiguration: Codable {
    let retentionDays: Int
    let autoCleanup: Bool
    let backupEnabled: Bool
    
    init(retentionDays: Int = 7, autoCleanup: Bool = true, backupEnabled: Bool = false) {
        self.retentionDays = retentionDays
        self.autoCleanup = autoCleanup
        self.backupEnabled = backupEnabled
    }
}

/// Structure representing security configuration
struct SecurityConfiguration: Codable {
    let sslRequired: Bool
    let apiKeyValidation: Bool
    let ipWhitelist: [String]
    let auditLogging: Bool
    
    init(sslRequired: Bool = true, apiKeyValidation: Bool = true, ipWhitelist: [String] = [], auditLogging: Bool = true) {
        self.sslRequired = sslRequired
        self.apiKeyValidation = apiKeyValidation
        self.ipWhitelist = ipWhitelist
        self.auditLogging = auditLogging
    }
}

/// Structure representing a sandbox endpoint
struct SandboxEndpoint: Codable, Identifiable {
    let id: String
    let path: String
    let method: HTTPMethod
    let description: String
    let responseTemplate: String
    let status: EndpointStatus
    
    init(path: String, method: HTTPMethod, description: String, responseTemplate: String, status: EndpointStatus = .active) {
        self.id = UUID().uuidString
        self.path = path
        self.method = method
        self.description = description
        self.responseTemplate = responseTemplate
        self.status = status
    }
}

/// Structure representing test data provision
struct TestDataProvision: Codable, Identifiable {
    let id: String
    let sandboxID: String
    let dataTypes: [String]
    let recordCount: Int
    let createdAt: Date
    let lastUpdated: Date
    
    init(sandboxID: String, dataTypes: [String], recordCount: Int) {
        self.id = UUID().uuidString
        self.sandboxID = sandboxID
        self.dataTypes = dataTypes
        self.recordCount = recordCount
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
}

/// Structure representing a simulated response
struct SimulatedResponse: Codable, Identifiable {
    let id: String
    let sandboxID: String
    let endpoint: String
    let method: HTTPMethod
    let statusCode: Int
    let headers: [String: String]
    let body: String
    let latency: TimeInterval
    let timestamp: Date
    
    init(sandboxID: String, endpoint: String, method: HTTPMethod, statusCode: Int, headers: [String: String] = [:], body: String, latency: TimeInterval = 0.1) {
        self.id = UUID().uuidString
        self.sandboxID = sandboxID
        self.endpoint = endpoint
        self.method = method
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.latency = latency
        self.timestamp = Date()
    }
}

/// Structure representing sandbox usage metrics
struct SandboxUsageMetrics: Codable, Identifiable {
    let id: String
    let sandboxID: String
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let averageResponseTime: TimeInterval
    let mostUsedEndpoints: [EndpointUsage]
    let dataUsage: DataUsageMetrics
    let lastActivity: Date
    
    init(sandboxID: String, totalRequests: Int, successfulRequests: Int, failedRequests: Int, averageResponseTime: TimeInterval, mostUsedEndpoints: [EndpointUsage], dataUsage: DataUsageMetrics, lastActivity: Date) {
        self.id = UUID().uuidString
        self.sandboxID = sandboxID
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageResponseTime = averageResponseTime
        self.mostUsedEndpoints = mostUsedEndpoints
        self.dataUsage = dataUsage
        self.lastActivity = lastActivity
    }
}

/// Structure representing endpoint usage
struct EndpointUsage: Codable, Identifiable {
    let id: String
    let endpoint: String
    let method: HTTPMethod
    let requestCount: Int
    let averageResponseTime: TimeInterval
    
    init(endpoint: String, method: HTTPMethod, requestCount: Int, averageResponseTime: TimeInterval) {
        self.id = UUID().uuidString
        self.endpoint = endpoint
        self.method = method
        self.requestCount = requestCount
        self.averageResponseTime = averageResponseTime
    }
}

/// Structure representing data usage metrics
struct DataUsageMetrics: Codable {
    let totalRecords: Int
    let storageUsed: Int64
    let dataTypes: [String: Int]
    
    init(totalRecords: Int, storageUsed: Int64, dataTypes: [String: Int]) {
        self.totalRecords = totalRecords
        self.storageUsed = storageUsed
        self.dataTypes = dataTypes
    }
}

/// Structure representing cleanup result
struct CleanupResult: Codable {
    let sandboxID: String
    let status: CleanupStatus
    let recordsDeleted: Int
    let storageFreed: Int64
    let cleanupTime: Date
    
    init(sandboxID: String, status: CleanupStatus, recordsDeleted: Int, storageFreed: Int64) {
        self.sandboxID = sandboxID
        self.status = status
        self.recordsDeleted = recordsDeleted
        self.storageFreed = storageFreed
        self.cleanupTime = Date()
    }
}

/// Enum representing sandbox status
enum SandboxStatus: String, Codable, CaseIterable {
    case creating = "Creating"
    case active = "Active"
    case suspended = "Suspended"
    case expired = "Expired"
    case deleted = "Deleted"
}

/// Enum representing endpoint status
enum EndpointStatus: String, Codable, CaseIterable {
    case active = "Active"
    case disabled = "Disabled"
    case maintenance = "Maintenance"
}

/// Enum representing cleanup status
enum CleanupStatus: String, Codable, CaseIterable {
    case success = "Success"
    case partial = "Partial"
    case failed = "Failed"
}

/// Actor responsible for managing developer sandbox environments
actor DeveloperSandboxEnvironment: DeveloperSandboxProtocol {
    private let sandboxStore: SandboxStore
    private let testDataGenerator: TestDataGenerator
    private let responseSimulator: ResponseSimulator
    private let usageMonitor: UsageMonitor
    private let logger: Logger
    
    init() {
        self.sandboxStore = SandboxStore()
        self.testDataGenerator = TestDataGenerator()
        self.responseSimulator = ResponseSimulator()
        self.usageMonitor = UsageMonitor()
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "SandboxEnvironment")
    }
    
    /// Creates a new sandbox environment for a developer
    /// - Parameter developer: The developer to create sandbox for
    /// - Returns: SandboxEnvironment object
    func createSandbox(for developer: Developer) async throws -> SandboxEnvironment {
        logger.info("Creating sandbox environment for developer: \(developer.name)")
        
        // Verify developer has sandbox access
        guard developer.sandboxAccess else {
            throw SandboxError.accessDenied("Developer does not have sandbox access")
        }
        
        // Create sandbox configuration
        let configuration = SandboxConfiguration(
            enabledEndpoints: [
                "/api/v1/health",
                "/api/v1/analytics",
                "/api/v1/research",
                "/api/v1/integrations"
            ]
        )
        
        // Create sandbox environment
        var sandbox = SandboxEnvironment(
            developerID: developer.id,
            name: "Sandbox for \(developer.name)",
            configuration: configuration
        )
        
        // Provision endpoints
        sandbox.endpoints = try await provisionEndpoints(for: configuration)
        
        // Update status to active
        sandbox.status = .active
        
        // Store sandbox
        await sandboxStore.saveSandbox(sandbox)
        
        logger.info("Created sandbox environment with ID: \(sandbox.id) for developer: \(developer.name)")
        return sandbox
    }
    
    /// Provisions test data for a sandbox
    /// - Parameter sandboxID: ID of the sandbox to provision data for
    /// - Returns: TestDataProvision object
    func provisionTestData(for sandboxID: String) async throws -> TestDataProvision {
        logger.info("Provisioning test data for sandbox ID: \(sandboxID)")
        
        guard let sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        // Generate test data based on enabled endpoints
        let dataTypes = sandbox.configuration.enabledEndpoints.map { endpoint in
            endpoint.replacingOccurrences(of: "/api/v1/", with: "")
        }
        
        let testData = TestDataProvision(
            sandboxID: sandboxID,
            dataTypes: dataTypes,
            recordCount: 1000
        )
        
        // Generate actual test data
        try await testDataGenerator.generateTestData(for: testData)
        
        // Update sandbox with test data
        var updatedSandbox = sandbox
        updatedSandbox.testData = testData
        await sandboxStore.saveSandbox(updatedSandbox)
        
        logger.info("Provisioned test data for sandbox ID: \(sandboxID)")
        return testData
    }
    
    /// Simulates API responses for a sandbox endpoint
    /// - Parameters:
    ///   - sandboxID: ID of the sandbox
    ///   - endpoint: The endpoint to simulate
    /// - Returns: SimulatedResponse object
    func simulateAPIResponses(for sandboxID: String, endpoint: String) async throws -> SimulatedResponse {
        logger.info("Simulating API response for sandbox ID: \(sandboxID), endpoint: \(endpoint)")
        
        guard let sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        guard let sandboxEndpoint = sandbox.endpoints.first(where: { $0.path == endpoint }) else {
            throw SandboxError.endpointNotFound(endpoint)
        }
        
        // Generate simulated response
        let response = try await responseSimulator.generateResponse(
            for: sandboxEndpoint,
            sandboxID: sandboxID
        )
        
        // Record usage
        await usageMonitor.recordRequest(
            sandboxID: sandboxID,
            endpoint: endpoint,
            method: sandboxEndpoint.method,
            responseTime: response.latency
        )
        
        logger.info("Generated simulated response for endpoint: \(endpoint)")
        return response
    }
    
    /// Monitors usage metrics for a sandbox
    /// - Parameter sandboxID: ID of the sandbox to monitor
    /// - Returns: SandboxUsageMetrics object
    func monitorSandboxUsage(for sandboxID: String) async throws -> SandboxUsageMetrics {
        logger.info("Monitoring usage for sandbox ID: \(sandboxID)")
        
        guard let sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        // Get usage metrics
        let metrics = await usageMonitor.getUsageMetrics(for: sandboxID)
        
        // Get data usage
        let dataUsage = await testDataGenerator.getDataUsageMetrics(for: sandboxID)
        
        let usageMetrics = SandboxUsageMetrics(
            sandboxID: sandboxID,
            totalRequests: metrics.totalRequests,
            successfulRequests: metrics.successfulRequests,
            failedRequests: metrics.failedRequests,
            averageResponseTime: metrics.averageResponseTime,
            mostUsedEndpoints: metrics.mostUsedEndpoints,
            dataUsage: dataUsage,
            lastActivity: metrics.lastActivity
        )
        
        logger.info("Retrieved usage metrics for sandbox ID: \(sandboxID)")
        return usageMetrics
    }
    
    /// Cleans up a sandbox environment
    /// - Parameter sandboxID: ID of the sandbox to cleanup
    /// - Returns: CleanupResult object
    func cleanupSandbox(for sandboxID: String) async throws -> CleanupResult {
        logger.info("Cleaning up sandbox ID: \(sandboxID)")
        
        guard let sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        // Clean up test data
        let recordsDeleted = await testDataGenerator.cleanupTestData(for: sandboxID)
        
        // Clean up usage metrics
        await usageMonitor.cleanupMetrics(for: sandboxID)
        
        // Update sandbox status
        var updatedSandbox = sandbox
        updatedSandbox.status = .deleted
        await sandboxStore.saveSandbox(updatedSandbox)
        
        let cleanupResult = CleanupResult(
            sandboxID: sandboxID,
            status: .success,
            recordsDeleted: recordsDeleted,
            storageFreed: 0 // Would calculate actual storage freed in real implementation
        )
        
        logger.info("Cleaned up sandbox ID: \(sandboxID), deleted \(recordsDeleted) records")
        return cleanupResult
    }
    
    /// Provisions endpoints for a sandbox configuration
    private func provisionEndpoints(for configuration: SandboxConfiguration) async throws -> [SandboxEndpoint] {
        var endpoints: [SandboxEndpoint] = []
        
        for endpointPath in configuration.enabledEndpoints {
            let endpoint = SandboxEndpoint(
                path: endpointPath,
                method: .GET,
                description: "Sandbox endpoint for \(endpointPath)",
                responseTemplate: generateResponseTemplate(for: endpointPath)
            )
            endpoints.append(endpoint)
        }
        
        return endpoints
    }
    
    /// Generates response template for an endpoint
    private func generateResponseTemplate(for endpoint: String) -> String {
        switch endpoint {
        case "/api/v1/health":
            return """
            {
                "status": "success",
                "data": {
                    "heart_rate": 75,
                    "steps": 8500,
                    "sleep_hours": 7.5
                }
            }
            """
        case "/api/v1/analytics":
            return """
            {
                "status": "success",
                "analytics": {
                    "total_records": 1000,
                    "processed": true
                }
            }
            """
        default:
            return """
            {
                "status": "success",
                "message": "Sandbox response for \(endpoint)"
            }
            """
        }
    }
}

/// Class managing sandbox storage
class SandboxStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.sandboxstore")
    private var sandboxes: [String: SandboxEnvironment] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "SandboxStore")
    }
    
    /// Saves a sandbox environment
    func saveSandbox(_ sandbox: SandboxEnvironment) async {
        storageQueue.sync {
            sandboxes[sandbox.id] = sandbox
            logger.info("Saved sandbox ID: \(sandbox.id)")
        }
    }
    
    /// Gets a sandbox by ID
    func getSandbox(byID id: String) async -> SandboxEnvironment? {
        var sandbox: SandboxEnvironment?
        storageQueue.sync {
            sandbox = sandboxes[id]
        }
        return sandbox
    }
    
    /// Gets all sandboxes for a developer
    func getSandboxes(for developerID: String) async -> [SandboxEnvironment] {
        var developerSandboxes: [SandboxEnvironment] = []
        storageQueue.sync {
            developerSandboxes = sandboxes.values.filter { $0.developerID == developerID }
        }
        return developerSandboxes
    }
    
    /// Deletes a sandbox
    func deleteSandbox(byID id: String) async {
        storageQueue.sync {
            sandboxes.removeValue(forKey: id)
            logger.info("Deleted sandbox ID: \(id)")
        }
    }
}

/// Class managing test data generation
class TestDataGenerator {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.testdatagenerator")
    private var testData: [String: [String: Any]] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "TestDataGenerator")
    }
    
    /// Generates test data for a provision
    func generateTestData(for provision: TestDataProvision) async throws {
        logger.info("Generating test data for sandbox ID: \(provision.sandboxID)")
        
        var sandboxData: [String: Any] = [:]
        
        for dataType in provision.dataTypes {
            let data = generateDataForType(dataType, count: provision.recordCount)
            sandboxData[dataType] = data
        }
        
        storageQueue.sync {
            testData[provision.sandboxID] = sandboxData
        }
        
        logger.info("Generated test data for sandbox ID: \(provision.sandboxID)")
    }
    
    /// Gets data usage metrics for a sandbox
    func getDataUsageMetrics(for sandboxID: String) async -> DataUsageMetrics {
        var totalRecords = 0
        var dataTypes: [String: Int] = [:]
        
        storageQueue.sync {
            if let sandboxData = testData[sandboxID] {
                for (dataType, data) in sandboxData {
                    if let records = data as? [[String: Any]] {
                        dataTypes[dataType] = records.count
                        totalRecords += records.count
                    }
                }
            }
        }
        
        return DataUsageMetrics(
            totalRecords: totalRecords,
            storageUsed: Int64(totalRecords * 100), // Approximate storage usage
            dataTypes: dataTypes
        )
    }
    
    /// Cleans up test data for a sandbox
    func cleanupTestData(for sandboxID: String) async -> Int {
        var recordsDeleted = 0
        
        storageQueue.sync {
            if let sandboxData = testData[sandboxID] {
                for (_, data) in sandboxData {
                    if let records = data as? [[String: Any]] {
                        recordsDeleted += records.count
                    }
                }
                testData.removeValue(forKey: sandboxID)
            }
        }
        
        logger.info("Cleaned up test data for sandbox ID: \(sandboxID), deleted \(recordsDeleted) records")
        return recordsDeleted
    }
    
    /// Generates data for a specific type
    private func generateDataForType(_ dataType: String, count: Int) -> [[String: Any]] {
        var data: [[String: Any]] = []
        
        for i in 0..<count {
            var record: [String: Any] = ["id": "\(dataType)_\(i)"]
            
            switch dataType {
            case "health":
                record["heart_rate"] = Int.random(in: 60...100)
                record["steps"] = Int.random(in: 0...15000)
                record["sleep_hours"] = Double.random(in: 5.0...9.0)
            case "analytics":
                record["event_type"] = ["page_view", "button_click", "form_submit"].randomElement()
                record["timestamp"] = Date().addingTimeInterval(Double.random(in: -86400*30...0))
            case "research":
                record["study_id"] = "study_\(Int.random(in: 1...10))"
                record["participant_id"] = "participant_\(Int.random(in: 1...100))"
            default:
                record["value"] = "sample_data_\(i)"
            }
            
            data.append(record)
        }
        
        return data
    }
}

/// Class managing response simulation
class ResponseSimulator {
    private let logger: Logger
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "ResponseSimulator")
    }
    
    /// Generates a simulated response for an endpoint
    func generateResponse(for endpoint: SandboxEndpoint, sandboxID: String) async throws -> SimulatedResponse {
        logger.info("Generating simulated response for endpoint: \(endpoint.path)")
        
        // Add some realistic latency
        let latency = Double.random(in: 0.05...0.5)
        
        // Generate response body based on template
        let responseBody = generateResponseBody(from: endpoint.responseTemplate)
        
        let response = SimulatedResponse(
            sandboxID: sandboxID,
            endpoint: endpoint.path,
            method: endpoint.method,
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: responseBody,
            latency: latency
        )
        
        return response
    }
    
    /// Generates response body from template
    private func generateResponseBody(from template: String) -> String {
        // In a real implementation, this would parse the template and inject dynamic values
        return template
    }
}

/// Class managing usage monitoring
class UsageMonitor {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.usagemonitor")
    private var usageData: [String: [UsageRecord]] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "UsageMonitor")
    }
    
    /// Records a request
    func recordRequest(sandboxID: String, endpoint: String, method: HTTPMethod, responseTime: TimeInterval) async {
        let record = UsageRecord(
            sandboxID: sandboxID,
            endpoint: endpoint,
            method: method,
            responseTime: responseTime,
            timestamp: Date()
        )
        
        storageQueue.sync {
            if usageData[sandboxID] == nil {
                usageData[sandboxID] = []
            }
            usageData[sandboxID]?.append(record)
        }
    }
    
    /// Gets usage metrics for a sandbox
    func getUsageMetrics(for sandboxID: String) async -> UsageMetrics {
        var metrics: UsageMetrics?
        
        storageQueue.sync {
            guard let records = usageData[sandboxID] else {
                metrics = UsageMetrics(
                    totalRequests: 0,
                    successfulRequests: 0,
                    failedRequests: 0,
                    averageResponseTime: 0,
                    mostUsedEndpoints: [],
                    lastActivity: Date()
                )
                return
            }
            
            let totalRequests = records.count
            let successfulRequests = records.count // Assume all successful for sandbox
            let failedRequests = 0
            let averageResponseTime = records.map { $0.responseTime }.reduce(0, +) / Double(records.count)
            
            // Calculate most used endpoints
            let endpointUsage = Dictionary(grouping: records, by: { $0.endpoint })
                .map { endpoint, records in
                    EndpointUsage(
                        endpoint: endpoint,
                        method: records.first?.method ?? .GET,
                        requestCount: records.count,
                        averageResponseTime: records.map { $0.responseTime }.reduce(0, +) / Double(records.count)
                    )
                }
                .sorted { $0.requestCount > $1.requestCount }
            
            metrics = UsageMetrics(
                totalRequests: totalRequests,
                successfulRequests: successfulRequests,
                failedRequests: failedRequests,
                averageResponseTime: averageResponseTime,
                mostUsedEndpoints: Array(endpointUsage.prefix(5)),
                lastActivity: records.last?.timestamp ?? Date()
            )
        }
        
        return metrics ?? UsageMetrics(
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            averageResponseTime: 0,
            mostUsedEndpoints: [],
            lastActivity: Date()
        )
    }
    
    /// Cleans up metrics for a sandbox
    func cleanupMetrics(for sandboxID: String) async {
        storageQueue.sync {
            usageData.removeValue(forKey: sandboxID)
            logger.info("Cleaned up usage metrics for sandbox ID: \(sandboxID)")
        }
    }
}

/// Structure representing usage record
struct UsageRecord: Codable {
    let sandboxID: String
    let endpoint: String
    let method: HTTPMethod
    let responseTime: TimeInterval
    let timestamp: Date
}

/// Structure representing usage metrics
struct UsageMetrics: Codable {
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let averageResponseTime: TimeInterval
    let mostUsedEndpoints: [EndpointUsage]
    let lastActivity: Date
}

/// Custom error types for sandbox operations
enum SandboxError: Error {
    case accessDenied(String)
    case sandboxNotFound
    case endpointNotFound(String)
    case quotaExceeded
    case invalidConfiguration(String)
}

extension DeveloperSandboxEnvironment {
    /// Configuration for sandbox environment
    struct Configuration {
        let maxSandboxesPerDeveloper: Int
        let sandboxLifetimeDays: Int
        let maxTestDataRecords: Int
        let enableAutoCleanup: Bool
        
        static let `default` = Configuration(
            maxSandboxesPerDeveloper: 3,
            sandboxLifetimeDays: 30,
            maxTestDataRecords: 10000,
            enableAutoCleanup: true
        )
    }
    
    /// Extends sandbox lifetime
    func extendSandboxLifetime(for sandboxID: String, additionalDays: Int) async throws {
        guard var sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        sandbox.expiresAt = Calendar.current.date(byAdding: .day, value: additionalDays, to: sandbox.expiresAt) ?? sandbox.expiresAt
        await sandboxStore.saveSandbox(sandbox)
        
        logger.info("Extended sandbox lifetime for ID: \(sandboxID) by \(additionalDays) days")
    }
    
    /// Suspends a sandbox
    func suspendSandbox(for sandboxID: String) async throws {
        guard var sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        sandbox.status = .suspended
        await sandboxStore.saveSandbox(sandbox)
        
        logger.info("Suspended sandbox ID: \(sandboxID)")
    }
    
    /// Reactivates a suspended sandbox
    func reactivateSandbox(for sandboxID: String) async throws {
        guard var sandbox = await sandboxStore.getSandbox(byID: sandboxID) else {
            throw SandboxError.sandboxNotFound
        }
        
        sandbox.status = .active
        await sandboxStore.saveSandbox(sandbox)
        
        logger.info("Reactivated sandbox ID: \(sandboxID)")
    }
} 