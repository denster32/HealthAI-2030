import Foundation

/// Level 1: Root telemetry error categories
public enum TelemetryError: String, CaseIterable {
    case prediction = "PREDICTION"
    case data = "DATA"
    case model = "MODEL"
    case system = "SYSTEM"
    
    /// Generates a dynamic error code with format: [CATEGORY]-[SUBCATEGORY]-[SPECIFIC]
    public func generateErrorCode(subCategory: String, specific: String) -> String {
        return "\(rawValue)-\(subCategory)-\(specific)"
    }
}

/// Level 2: Prediction error subcategories
public enum PredictionError: String, CaseIterable {
    case featureExtraction = "FEATURE_EXTRACTION"
    case scoreCalculation = "SCORE_CALCULATION"
    case postProcessing = "POST_PROCESSING"
    case modelLoading = "MODEL_LOADING"
    case unknown = "UNKNOWN"
    
    /// Generates a dynamic error code for prediction errors
    public func generateErrorCode(specific: String) -> String {
        return TelemetryError.prediction.generateErrorCode(
            subCategory: rawValue,
            specific: specific
        )
    }
}

/// Level 2: Data error subcategories
public enum DataError: String, CaseIterable {
    case missing = "MISSING_DATA"
    case invalid = "INVALID_DATA"
    case corrupted = "CORRUPTED_DATA"
    case stale = "STALE_DATA"
}

/// Level 2: Model error subcategories
public enum ModelError: String, CaseIterable {
    case versionMismatch = "VERSION_MISMATCH"
    case formatError = "FORMAT_ERROR"
    case performanceDegradation = "PERFORMANCE_DEGRADATION"
    case drift = "MODEL_DRIFT"
}

/// Level 2: System error subcategories
public enum SystemError: String, CaseIterable {
    case memory = "MEMORY_ERROR"
    case cpu = "CPU_ERROR"
    case network = "NETWORK_ERROR"
    case storage = "STORAGE_ERROR"
}

/// Contextual metadata for error reporting
public struct ErrorContext {
    public let timestamp: Date
    public let code: String
    public let message: String
    public let severity: SeverityLevel
    public let metadata: [String: Any]
    public let stackTrace: String?
    
    public enum SeverityLevel: Int {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
    }
    
    public init(
        code: String,
        message: String,
        severity: SeverityLevel = .medium,
        metadata: [String: Any] = [:],
        stackTrace: String? = nil
    ) {
        self.timestamp = Date()
        self.code = code
        self.message = message
        self.severity = severity
        self.metadata = metadata
        self.stackTrace = stackTrace
    }
}