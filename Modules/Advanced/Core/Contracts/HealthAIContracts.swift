import Foundation

// MARK: - Service Contracts

/// Contract for service initialization and lifecycle
public protocol ServiceContract {
    var serviceName: String { get }
    var version: String { get }
    var dependencies: [String] { get }
    
    func validateContract() async throws -> Bool
    func getContractDetails() -> ServiceContractDetails
}

public struct ServiceContractDetails {
    public let serviceName: String
    public let version: String
    public let dependencies: [String]
    public let capabilities: [String]
    public let requirements: [String]
    public let sla: ServiceLevelAgreement
    
    public init(serviceName: String, version: String, dependencies: [String], capabilities: [String], requirements: [String], sla: ServiceLevelAgreement) {
        self.serviceName = serviceName
        self.version = version
        self.dependencies = dependencies
        self.capabilities = capabilities
        self.requirements = requirements
        self.sla = sla
    }
}

public struct ServiceLevelAgreement {
    public let availability: Double // Percentage
    public let responseTime: TimeInterval
    public let errorRate: Double // Percentage
    public let throughput: Int // Requests per second
    
    public init(availability: Double, responseTime: TimeInterval, errorRate: Double, throughput: Int) {
        self.availability = availability
        self.responseTime = responseTime
        self.errorRate = errorRate
        self.throughput = throughput
    }
}

// MARK: - Data Contracts

/// Contract for data validation and schema compliance
public protocol DataContract {
    associatedtype DataType
    
    func validate(_ data: DataType) async throws -> ValidationResult
    func getSchema() -> DataSchema
    func transform(_ data: DataType) async throws -> DataType
}

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
    public let warnings: [ValidationWarning]
    
    public init(isValid: Bool, errors: [ValidationError] = [], warnings: [ValidationWarning] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

public struct ValidationError {
    public let field: String
    public let message: String
    public let code: String
    
    public init(field: String, message: String, code: String) {
        self.field = field
        self.message = message
        self.code = code
    }
}

public struct ValidationWarning {
    public let field: String
    public let message: String
    public let severity: WarningSeverity
    
    public init(field: String, message: String, severity: WarningSeverity) {
        self.field = field
        self.message = message
        self.severity = severity
    }
}

public enum WarningSeverity {
    case low, medium, high
}

public struct DataSchema {
    public let fields: [SchemaField]
    public let constraints: [SchemaConstraint]
    public let version: String
    
    public init(fields: [SchemaField], constraints: [SchemaConstraint], version: String) {
        self.fields = fields
        self.constraints = constraints
        self.version = version
    }
}

public struct SchemaField {
    public let name: String
    public let type: SchemaFieldType
    public let required: Bool
    public let defaultValue: Any?
    public let validation: [FieldValidation]
    
    public init(name: String, type: SchemaFieldType, required: Bool = true, defaultValue: Any? = nil, validation: [FieldValidation] = []) {
        self.name = name
        self.type = type
        self.required = required
        self.defaultValue = defaultValue
        self.validation = validation
    }
}

public enum SchemaFieldType {
    case string, integer, double, boolean, date, array, object, custom(String)
}

public struct FieldValidation {
    public let type: ValidationType
    public let parameters: [String: Any]
    
    public init(type: ValidationType, parameters: [String: Any] = [:]) {
        self.type = type
        self.parameters = parameters
    }
}

public enum ValidationType {
    case minLength(Int)
    case maxLength(Int)
    case pattern(String)
    case range(ClosedRange<Double>)
    case custom(String)
}

public struct SchemaConstraint {
    public let type: ConstraintType
    public let fields: [String]
    public let parameters: [String: Any]
    
    public init(type: ConstraintType, fields: [String], parameters: [String: Any] = [:]) {
        self.type = type
        self.fields = fields
        self.parameters = parameters
    }
}

public enum ConstraintType {
    case unique
    case required
    case foreignKey(String)
    case custom(String)
}

// MARK: - API Contracts

/// Contract for API endpoints and request/response schemas
public protocol APIContract {
    var baseURL: URL { get }
    var endpoints: [APIEndpoint] { get }
    var authentication: APIAuthentication { get }
    var rateLimiting: RateLimitingPolicy { get }
}

public struct APIEndpoint {
    public let path: String
    public let method: HTTPMethod
    public let requestSchema: DataSchema?
    public let responseSchema: DataSchema?
    public let authentication: APIAuthentication?
    public let rateLimiting: RateLimitingPolicy?
    
    public init(path: String, method: HTTPMethod, requestSchema: DataSchema? = nil, responseSchema: DataSchema? = nil, authentication: APIAuthentication? = nil, rateLimiting: RateLimitingPolicy? = nil) {
        self.path = path
        self.method = method
        self.requestSchema = requestSchema
        self.responseSchema = responseSchema
        self.authentication = authentication
        self.rateLimiting = rateLimiting
    }
}

public struct APIAuthentication {
    public let type: AuthenticationType
    public let required: Bool
    public let scopes: [String]
    
    public init(type: AuthenticationType, required: Bool = true, scopes: [String] = []) {
        self.type = type
        self.required = required
        self.scopes = scopes
    }
}

public enum AuthenticationType {
    case none
    case apiKey
    case bearer
    case oauth2
    case custom(String)
}

public struct RateLimitingPolicy {
    public let requestsPerMinute: Int
    public let requestsPerHour: Int
    public let burstLimit: Int
    
    public init(requestsPerMinute: Int, requestsPerHour: Int, burstLimit: Int) {
        self.requestsPerMinute = requestsPerMinute
        self.requestsPerHour = requestsPerHour
        self.burstLimit = burstLimit
    }
}

// MARK: - Integration Contracts

/// Contract for third-party integrations
public protocol IntegrationContract {
    var providerName: String { get }
    var version: String { get }
    var capabilities: [IntegrationCapability] { get }
    var requirements: [IntegrationRequirement] { get }
    
    func validateIntegration() async throws -> IntegrationValidationResult
    func getIntegrationStatus() async -> IntegrationStatus
}

public struct IntegrationCapability {
    public let name: String
    public let description: String
    public let parameters: [String: Any]
    
    public init(name: String, description: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public struct IntegrationRequirement {
    public let name: String
    public let type: RequirementType
    public let description: String
    public let mandatory: Bool
    
    public init(name: String, type: RequirementType, description: String, mandatory: Bool = true) {
        self.name = name
        self.type = type
        self.description = description
        self.mandatory = mandatory
    }
}

public enum RequirementType {
    case apiKey
    case endpoint
    case permission
    case configuration
    case custom(String)
}

public struct IntegrationValidationResult {
    public let isValid: Bool
    public let missingRequirements: [IntegrationRequirement]
    public let errors: [String]
    
    public init(isValid: Bool, missingRequirements: [IntegrationRequirement] = [], errors: [String] = []) {
        self.isValid = isValid
        self.missingRequirements = missingRequirements
        self.errors = errors
    }
}

public struct IntegrationStatus {
    public let isConnected: Bool
    public let lastSync: Date?
    public let errorCount: Int
    public let healthScore: Double
    
    public init(isConnected: Bool, lastSync: Date? = nil, errorCount: Int = 0, healthScore: Double = 0.0) {
        self.isConnected = isConnected
        self.lastSync = lastSync
        self.errorCount = errorCount
        self.healthScore = healthScore
    }
}

// MARK: - Performance Contracts

/// Contract for performance guarantees
public protocol PerformanceContract {
    var metrics: [PerformanceMetric] { get }
    var thresholds: [PerformanceThreshold] { get }
    
    func measurePerformance() async -> PerformanceMeasurement
    func validatePerformance() async -> PerformanceValidationResult
}

public struct PerformanceMetric {
    public let name: String
    public let unit: String
    public let description: String
    
    public init(name: String, unit: String, description: String) {
        self.name = name
        self.unit = unit
        self.description = description
    }
}

public struct PerformanceThreshold {
    public let metricName: String
    public let minValue: Double?
    public let maxValue: Double?
    public let targetValue: Double?
    
    public init(metricName: String, minValue: Double? = nil, maxValue: Double? = nil, targetValue: Double? = nil) {
        self.metricName = metricName
        self.minValue = minValue
        self.maxValue = maxValue
        self.targetValue = targetValue
    }
}

public struct PerformanceMeasurement {
    public let timestamp: Date
    public let metrics: [String: Double]
    
    public init(timestamp: Date = Date(), metrics: [String: Double]) {
        self.timestamp = timestamp
        self.metrics = metrics
    }
}

public struct PerformanceValidationResult {
    public let isCompliant: Bool
    public let violations: [PerformanceViolation]
    public let recommendations: [String]
    
    public init(isCompliant: Bool, violations: [PerformanceViolation] = [], recommendations: [String] = []) {
        self.isCompliant = isCompliant
        self.violations = violations
        self.recommendations = recommendations
    }
}

public struct PerformanceViolation {
    public let metricName: String
    public let actualValue: Double
    public let threshold: PerformanceThreshold
    public let severity: ViolationSeverity
    
    public init(metricName: String, actualValue: Double, threshold: PerformanceThreshold, severity: ViolationSeverity) {
        self.metricName = metricName
        self.actualValue = actualValue
        self.threshold = threshold
        self.severity = severity
    }
}

public enum ViolationSeverity {
    case low, medium, high, critical
} 