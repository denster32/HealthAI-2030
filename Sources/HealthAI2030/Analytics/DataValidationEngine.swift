import Foundation
import Combine
import CryptoKit

/// Advanced data validation engine for HealthAI 2030
/// Provides comprehensive data validation rules and real-time validation processing
public class DataValidationEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var validationResults: [String: ValidationResult] = [:]
    @Published private(set) var validationMetrics: ValidationMetrics = ValidationMetrics()
    @Published private(set) var isValidating: Bool = false
    
    // MARK: - Core Components
    private let validationRuleEngine: ValidationRuleEngine
    private let constraintValidator: ConstraintValidator
    private let schemaValidator: SchemaValidator
    private let businessRuleValidator: BusinessRuleValidator
    private let qualityScorer: QualityScorer
    
    // MARK: - Configuration
    private let validationConfig: ValidationConfiguration
    private let performanceMonitor: ValidationPerformanceMonitor
    
    // MARK: - Initialization
    public init(config: ValidationConfiguration = .default) {
        self.validationConfig = config
        self.validationRuleEngine = ValidationRuleEngine(config: config.ruleEngineConfig)
        self.constraintValidator = ConstraintValidator(config: config.constraintConfig)
        self.schemaValidator = SchemaValidator(config: config.schemaConfig)
        self.businessRuleValidator = BusinessRuleValidator(config: config.businessRuleConfig)
        self.qualityScorer = QualityScorer(config: config.qualityScoringConfig)
        self.performanceMonitor = ValidationPerformanceMonitor()
        
        setupValidationPipeline()
    }
    
    // MARK: - Core Validation Methods
    
    /// Validates a single data record
    public func validateRecord<T: Codable>(_ record: T, 
                                         schema: DataSchema,
                                         rules: [ValidationRule] = []) async throws -> ValidationResult {
        let startTime = Date()
        defer { performanceMonitor.recordValidation(duration: Date().timeIntervalSince(startTime)) }
        
        let context = ValidationContext(
            record: record,
            schema: schema,
            rules: rules,
            timestamp: Date()
        )
        
        // Schema validation
        let schemaResult = try await schemaValidator.validate(record, against: schema)
        
        // Constraint validation
        let constraintResult = try await constraintValidator.validate(record, constraints: schema.constraints)
        
        // Business rule validation
        let businessRuleResult = try await businessRuleValidator.validate(record, rules: rules)
        
        // Custom validation rules
        let customRuleResult = try await validationRuleEngine.validate(record, context: context)
        
        // Quality scoring
        let qualityScore = try await qualityScorer.calculateScore(record, context: context)
        
        let result = ValidationResult(
            recordId: extractRecordId(record),
            isValid: schemaResult.isValid && constraintResult.isValid && businessRuleResult.isValid && customRuleResult.isValid,
            qualityScore: qualityScore,
            schemaValidation: schemaResult,
            constraintValidation: constraintResult,
            businessRuleValidation: businessRuleResult,
            customRuleValidation: customRuleResult,
            timestamp: Date(),
            validationDuration: Date().timeIntervalSince(startTime)
        )
        
        await updateValidationMetrics(result)
        return result
    }
    
    /// Validates a batch of data records
    public func validateBatch<T: Codable>(_ records: [T],
                                        schema: DataSchema,
                                        rules: [ValidationRule] = []) async throws -> BatchValidationResult {
        let startTime = Date()
        isValidating = true
        defer { isValidating = false }
        
        let results = try await withThrowingTaskGroup(of: ValidationResult.self) { group in
            var validationResults: [ValidationResult] = []
            
            for (index, record) in records.enumerated() {
                group.addTask {
                    try await self.validateRecord(record, schema: schema, rules: rules)
                }
                
                // Batch processing with concurrency control
                if index % validationConfig.maxConcurrentValidations == 0 {
                    for try await result in group {
                        validationResults.append(result)
                    }
                }
            }
            
            // Collect remaining results
            for try await result in group {
                validationResults.append(result)
            }
            
            return validationResults
        }
        
        let batchResult = BatchValidationResult(
            batchId: UUID().uuidString,
            totalRecords: records.count,
            validRecords: results.filter { $0.isValid }.count,
            invalidRecords: results.filter { !$0.isValid }.count,
            averageQualityScore: results.map { $0.qualityScore }.reduce(0, +) / Double(results.count),
            results: results,
            processingDuration: Date().timeIntervalSince(startTime),
            timestamp: Date()
        )
        
        await updateBatchMetrics(batchResult)
        return batchResult
    }
    
    /// Real-time streaming validation
    public func validateStream<T: Codable>(_ stream: AsyncThrowingStream<T, Error>,
                                         schema: DataSchema,
                                         rules: [ValidationRule] = []) -> AsyncThrowingStream<ValidationResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await record in stream {
                        let result = try await validateRecord(record, schema: schema, rules: rules)
                        continuation.yield(result)
                        
                        // Update real-time metrics
                        await updateStreamingMetrics(result)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Validation Rules Management
    
    public func addValidationRule(_ rule: ValidationRule) {
        validationRuleEngine.addRule(rule)
    }
    
    public func removeValidationRule(id: String) {
        validationRuleEngine.removeRule(id: id)
    }
    
    public func updateValidationRule(_ rule: ValidationRule) {
        validationRuleEngine.updateRule(rule)
    }
    
    // MARK: - Schema Management
    
    public func registerSchema(_ schema: DataSchema) {
        schemaValidator.registerSchema(schema)
    }
    
    public func updateSchema(_ schema: DataSchema) {
        schemaValidator.updateSchema(schema)
    }
    
    // MARK: - Private Methods
    
    private func setupValidationPipeline() {
        // Configure validation pipeline with performance optimization
        validationRuleEngine.delegate = self
        constraintValidator.delegate = self
        schemaValidator.delegate = self
        businessRuleValidator.delegate = self
    }
    
    private func extractRecordId<T: Codable>(_ record: T) -> String {
        // Extract record ID based on common patterns
        let mirror = Mirror(reflecting: record)
        
        for child in mirror.children {
            if let label = child.label, 
               (label.lowercased().contains("id") || label.lowercased() == "identifier") {
                return String(describing: child.value)
            }
        }
        
        return UUID().uuidString
    }
    
    @MainActor
    private func updateValidationMetrics(_ result: ValidationResult) {
        validationMetrics.totalValidations += 1
        
        if result.isValid {
            validationMetrics.successfulValidations += 1
        } else {
            validationMetrics.failedValidations += 1
        }
        
        validationMetrics.averageQualityScore = 
            (validationMetrics.averageQualityScore * Double(validationMetrics.totalValidations - 1) + result.qualityScore) / 
            Double(validationMetrics.totalValidations)
        
        validationMetrics.averageValidationTime = 
            (validationMetrics.averageValidationTime * Double(validationMetrics.totalValidations - 1) + result.validationDuration) / 
            Double(validationMetrics.totalValidations)
        
        validationResults[result.recordId] = result
    }
    
    @MainActor
    private func updateBatchMetrics(_ result: BatchValidationResult) {
        validationMetrics.totalBatches += 1
        validationMetrics.totalValidations += result.totalRecords
        validationMetrics.successfulValidations += result.validRecords
        validationMetrics.failedValidations += result.invalidRecords
        
        let newAverageQuality = 
            (validationMetrics.averageQualityScore * Double(validationMetrics.totalValidations - result.totalRecords) + 
             result.averageQualityScore * Double(result.totalRecords)) / 
            Double(validationMetrics.totalValidations)
        
        validationMetrics.averageQualityScore = newAverageQuality
    }
    
    @MainActor
    private func updateStreamingMetrics(_ result: ValidationResult) {
        validationMetrics.streamingValidations += 1
        validationMetrics.totalValidations += 1
        
        if result.isValid {
            validationMetrics.successfulValidations += 1
        } else {
            validationMetrics.failedValidations += 1
        }
    }
}

// MARK: - Supporting Types

public struct ValidationResult {
    public let recordId: String
    public let isValid: Bool
    public let qualityScore: Double
    public let schemaValidation: SchemaValidationResult
    public let constraintValidation: ConstraintValidationResult
    public let businessRuleValidation: BusinessRuleValidationResult
    public let customRuleValidation: CustomRuleValidationResult
    public let timestamp: Date
    public let validationDuration: TimeInterval
    
    public var errors: [ValidationError] {
        var errors: [ValidationError] = []
        errors.append(contentsOf: schemaValidation.errors)
        errors.append(contentsOf: constraintValidation.errors)
        errors.append(contentsOf: businessRuleValidation.errors)
        errors.append(contentsOf: customRuleValidation.errors)
        return errors
    }
    
    public var warnings: [ValidationWarning] {
        var warnings: [ValidationWarning] = []
        warnings.append(contentsOf: schemaValidation.warnings)
        warnings.append(contentsOf: constraintValidation.warnings)
        warnings.append(contentsOf: businessRuleValidation.warnings)
        warnings.append(contentsOf: customRuleValidation.warnings)
        return warnings
    }
}

public struct BatchValidationResult {
    public let batchId: String
    public let totalRecords: Int
    public let validRecords: Int
    public let invalidRecords: Int
    public let averageQualityScore: Double
    public let results: [ValidationResult]
    public let processingDuration: TimeInterval
    public let timestamp: Date
    
    public var successRate: Double {
        return totalRecords > 0 ? Double(validRecords) / Double(totalRecords) : 0.0
    }
    
    public var failureRate: Double {
        return totalRecords > 0 ? Double(invalidRecords) / Double(totalRecords) : 0.0
    }
}

public struct ValidationMetrics {
    public var totalValidations: Int = 0
    public var successfulValidations: Int = 0
    public var failedValidations: Int = 0
    public var streamingValidations: Int = 0
    public var totalBatches: Int = 0
    public var averageQualityScore: Double = 0.0
    public var averageValidationTime: TimeInterval = 0.0
    
    public var successRate: Double {
        return totalValidations > 0 ? Double(successfulValidations) / Double(totalValidations) : 0.0
    }
    
    public var failureRate: Double {
        return totalValidations > 0 ? Double(failedValidations) / Double(totalValidations) : 0.0
    }
}

public struct ValidationConfiguration {
    public let maxConcurrentValidations: Int
    public let ruleEngineConfig: RuleEngineConfiguration
    public let constraintConfig: ConstraintConfiguration
    public let schemaConfig: SchemaConfiguration
    public let businessRuleConfig: BusinessRuleConfiguration
    public let qualityScoringConfig: QualityScoringConfiguration
    
    public static let `default` = ValidationConfiguration(
        maxConcurrentValidations: 10,
        ruleEngineConfig: .default,
        constraintConfig: .default,
        schemaConfig: .default,
        businessRuleConfig: .default,
        qualityScoringConfig: .default
    )
}

// MARK: - Validation Components

private class ValidationRuleEngine {
    private var rules: [String: ValidationRule] = [:]
    private let config: RuleEngineConfiguration
    weak var delegate: DataValidationEngine?
    
    init(config: RuleEngineConfiguration) {
        self.config = config
    }
    
    func validate<T: Codable>(_ record: T, context: ValidationContext) async throws -> CustomRuleValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        for rule in rules.values {
            let result = try await rule.validate(record, context: context)
            errors.append(contentsOf: result.errors)
            warnings.append(contentsOf: result.warnings)
        }
        
        return CustomRuleValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    func addRule(_ rule: ValidationRule) {
        rules[rule.id] = rule
    }
    
    func removeRule(id: String) {
        rules.removeValue(forKey: id)
    }
    
    func updateRule(_ rule: ValidationRule) {
        rules[rule.id] = rule
    }
}

// MARK: - Supporting Protocol Conformances

extension DataValidationEngine: ValidationEngineDelegate {
    public func validationDidStart() {
        DispatchQueue.main.async {
            self.isValidating = true
        }
    }
    
    public func validationDidComplete() {
        DispatchQueue.main.async {
            self.isValidating = false
        }
    }
}
