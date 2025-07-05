import Foundation
import SwiftUI
import Combine

// MARK: - Core HealthAI Protocols

/// Base protocol for all HealthAI services
public protocol HealthAIServiceProtocol: AnyObject, Sendable {
    var serviceIdentifier: String { get }
    var isActive: Bool { get }
    
    func initialize() async throws
    func shutdown() async throws
    func healthCheck() async -> ServiceHealthStatus
}

/// Protocol for data processing services
public protocol DataProcessorProtocol: HealthAIServiceProtocol {
    associatedtype InputType
    associatedtype OutputType
    
    func process(_ input: InputType) async throws -> OutputType
    func validate(_ input: InputType) async throws -> Bool
}

/// Protocol for AI/ML prediction services
public protocol PredictionServiceProtocol: HealthAIServiceProtocol {
    associatedtype PredictionInput
    associatedtype PredictionOutput
    
    func predict(_ input: PredictionInput) async throws -> PredictionOutput
    func train(with data: [PredictionInput]) async throws
    func evaluate(accuracy: [PredictionInput]) async throws -> PredictionAccuracy
}

/// Protocol for analytics services
public protocol AnalyticsServiceProtocol: HealthAIServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent) async throws
    func generateReport(for period: DateInterval) async throws -> AnalyticsReport
    func getInsights() async throws -> [AnalyticsInsight]
}

// MARK: - Data Management Protocols

/// Protocol for data storage and retrieval
public protocol DataStorageProtocol: HealthAIServiceProtocol {
    associatedtype DataType
    
    func store(_ data: DataType) async throws
    func retrieve(id: String) async throws -> DataType?
    func delete(id: String) async throws
    func query(filter: DataFilter) async throws -> [DataType]
}

/// Protocol for data synchronization
public protocol DataSyncProtocol: HealthAIServiceProtocol {
    func sync() async throws
    func resolveConflicts() async throws
    func getSyncStatus() async -> SyncStatus
}

// MARK: - UI and Presentation Protocols

/// Protocol for view models
public protocol ViewModelProtocol: ObservableObject, Sendable {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func load() async throws
    func refresh() async throws
}

/// Protocol for adaptive UI components
public protocol AdaptiveUIProtocol {
    func adaptToDevice(_ device: DeviceType) -> AnyView
    func adaptToAccessibility(_ accessibility: AccessibilitySettings) -> AnyView
}

// MARK: - Integration Protocols

/// Protocol for external API integration
public protocol APIIntegrationProtocol: HealthAIServiceProtocol {
    func authenticate() async throws -> AuthToken
    func makeRequest<T: Codable>(_ request: APIRequest) async throws -> T
    func handleError(_ error: APIError) async throws
}

/// Protocol for device integration
public protocol DeviceIntegrationProtocol: HealthAIServiceProtocol {
    func connect(to device: DeviceInfo) async throws
    func disconnect(from device: DeviceInfo) async throws
    func getConnectedDevices() async -> [DeviceInfo]
}

// MARK: - Performance and Monitoring Protocols

/// Protocol for performance monitoring
public protocol PerformanceMonitorProtocol: HealthAIServiceProtocol {
    func startMonitoring() async throws
    func stopMonitoring() async throws
    func getMetrics() async -> PerformanceMetrics
}

/// Protocol for error handling and logging
public protocol ErrorHandlerProtocol: HealthAIServiceProtocol {
    func handleError(_ error: Error, context: ErrorContext) async throws
    func logError(_ error: Error, level: LogLevel) async throws
}

// MARK: - Supporting Types

public struct ServiceHealthStatus {
    public let isHealthy: Bool
    public let lastCheck: Date
    public let responseTime: TimeInterval
    public let errorCount: Int
    
    public init(isHealthy: Bool, lastCheck: Date, responseTime: TimeInterval, errorCount: Int) {
        self.isHealthy = isHealthy
        self.lastCheck = lastCheck
        self.responseTime = responseTime
        self.errorCount = errorCount
    }
}

public struct PredictionAccuracy {
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    
    public init(accuracy: Double, precision: Double, recall: Double, f1Score: Double) {
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
    }
}

public struct AnalyticsEvent {
    public let name: String
    public let timestamp: Date
    public let properties: [String: Any]
    
    public init(name: String, timestamp: Date = Date(), properties: [String: Any] = [:]) {
        self.name = name
        self.timestamp = timestamp
        self.properties = properties
    }
}

public struct AnalyticsReport {
    public let period: DateInterval
    public let metrics: [String: Double]
    public let insights: [AnalyticsInsight]
    
    public init(period: DateInterval, metrics: [String: Double], insights: [AnalyticsInsight]) {
        self.period = period
        self.metrics = metrics
        self.insights = insights
    }
}

public struct AnalyticsInsight {
    public let title: String
    public let description: String
    public let confidence: Double
    public let actionable: Bool
    
    public init(title: String, description: String, confidence: Double, actionable: Bool) {
        self.title = title
        self.description = description
        self.confidence = confidence
        self.actionable = actionable
    }
}

public struct DataFilter {
    public let field: String
    public let operator: FilterOperator
    public let value: Any
    
    public init(field: String, operator: FilterOperator, value: Any) {
        self.field = field
        self.operator = `operator`
        self.value = value
    }
}

public enum FilterOperator {
    case equals, notEquals, greaterThan, lessThan, contains, startsWith
}

public struct SyncStatus {
    public let lastSync: Date
    public let pendingChanges: Int
    public let conflicts: Int
    public let isSyncing: Bool
    
    public init(lastSync: Date, pendingChanges: Int, conflicts: Int, isSyncing: Bool) {
        self.lastSync = lastSync
        self.pendingChanges = pendingChanges
        self.conflicts = conflicts
        self.isSyncing = isSyncing
    }
}

public enum DeviceType {
    case iPhone, iPad, Mac, AppleWatch, AppleTV
}

public struct AccessibilitySettings {
    public let isVoiceOverEnabled: Bool
    public let isReduceMotionEnabled: Bool
    public let isHighContrastEnabled: Bool
    public let fontSize: FontSize
    
    public init(isVoiceOverEnabled: Bool, isReduceMotionEnabled: Bool, isHighContrastEnabled: Bool, fontSize: FontSize) {
        self.isVoiceOverEnabled = isVoiceOverEnabled
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.isHighContrastEnabled = isHighContrastEnabled
        self.fontSize = fontSize
    }
}

public enum FontSize {
    case small, medium, large, extraLarge
}

public struct AuthToken {
    public let token: String
    public let expiresAt: Date
    public let refreshToken: String?
    
    public init(token: String, expiresAt: Date, refreshToken: String? = nil) {
        self.token = token
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }
}

public struct APIRequest {
    public let method: HTTPMethod
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    
    public init(method: HTTPMethod, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

public enum APIError: Error {
    case networkError(Error)
    case invalidResponse
    case authenticationFailed
    case rateLimited
    case serverError(Int)
}

public struct DeviceInfo {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let isConnected: Bool
    
    public init(id: String, name: String, type: DeviceType, isConnected: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.isConnected = isConnected
    }
}

public struct PerformanceMetrics {
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let responseTime: TimeInterval
    public let throughput: Double
    
    public init(cpuUsage: Double, memoryUsage: Double, responseTime: TimeInterval, throughput: Double) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.responseTime = responseTime
        self.throughput = throughput
    }
}

public struct ErrorContext {
    public let component: String
    public let action: String
    public let userInfo: [String: Any]
    
    public init(component: String, action: String, userInfo: [String: Any] = [:]) {
        self.component = component
        self.action = action
        self.userInfo = userInfo
    }
}

public enum LogLevel: String, CaseIterable {
    case debug, info, warning, error, critical
} 