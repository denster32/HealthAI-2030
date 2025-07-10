import Foundation
import Combine

/// Comprehensive data quality management system for healthcare analytics
public class DataQualityManager {
    
    // MARK: - Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let configManager: AnalyticsConfiguration
    private let errorHandler: AnalyticsErrorHandling
    private let performanceMonitor: AnalyticsPerformanceMonitor
    
    // MARK: - Quality Metrics
    public enum QualityMetric {
        case completeness
        case accuracy
        case consistency
        case validity
        case uniqueness
        case timeliness
        case integrity
        case conformity
    }
    
    // MARK: - Data Structures
    public struct DataQualityReport {
        let overallScore: Double
        let metricScores: [QualityMetric: Double]
        let issues: [DataQualityIssue]
        let recommendations: [QualityRecommendation]
        let timestamp: Date
        let datasetInfo: DatasetInfo
    }
    
    public struct DataQualityIssue {
        let type: QualityIssueType
        let severity: IssueSeverity
        let description: String
        let affectedFields: [String]
        let affectedRecords: [Int]
        let suggestedAction: String
        let estimatedImpact: Double
    }
    
    public enum QualityIssueType {
        case missingValues
        case duplicateRecords
        case outliers
        case inconsistentFormat
        case invalidValues
        case dataTypeErrors
        case referentialIntegrity
        case businessRuleViolation
        case temporalInconsistency
    }
    
    public enum IssueSeverity {
        case low
        case medium
        case high
        case critical
    }
    
    public struct QualityRecommendation {
        let priority: RecommendationPriority
        let action: String
        let description: String
        let estimatedEffort: String
        let expectedImprovement: Double
        let relatedIssues: [QualityIssueType]
    }
    
    public enum RecommendationPriority {
        case low
        case medium
        case high
        case urgent
    }
    
    public struct DatasetInfo {
        let name: String
        let recordCount: Int
        let fieldCount: Int
        let lastUpdated: Date
        let sourceSystem: String
        let dataTypes: [String: String]
    }
    
    public struct QualityRule {
        let name: String
        let description: String
        let fieldName: String
        let ruleType: QualityRuleType
        let parameters: [String: Any]
        let severity: IssueSeverity
        let isActive: Bool
    }
    
    public enum QualityRuleType {
        case notNull
        case range(min: Double, max: Double)
        case regex(pattern: String)
        case enumeration(values: [String])
        case uniqueness
        case referentialIntegrity(table: String, field: String)
        case businessRule(expression: String)
        case temporalLogic(expression: String)
    }
    
    public struct CleaningOperation {
        let operationType: CleaningOperationType
        let fieldName: String
        let parameters: [String: Any]
        let affectedRecords: [Int]
        let confidence: Double
    }
    
    public enum CleaningOperationType {
        case fillMissing(strategy: MissingValueStrategy)
        case removeDuplicates
        case correctOutliers(method: OutlierCorrectionMethod)
        case standardizeFormat
        case validateAndCorrect
        case removeInvalidRecords
    }
    
    public enum MissingValueStrategy {
        case mean
        case median
        case mode
        case forward_fill
        case backward_fill
        case interpolation
        case ml_imputation
        case domain_specific
    }
    
    public enum OutlierCorrectionMethod {
        case cap_at_percentile(percentile: Double)
        case z_score_clipping(threshold: Double)
        case iqr_method
        case isolation_forest
        case domain_validation
    }
    
    // MARK: - Quality Rules Storage
    private var qualityRules: [String: [QualityRule]] = [:]
    private var qualityHistory: [DataQualityReport] = []
    
    // MARK: - Initialization
    public init(analyticsEngine: AdvancedAnalyticsEngine,
                configManager: AnalyticsConfiguration,
                errorHandler: AnalyticsErrorHandling,
                performanceMonitor: AnalyticsPerformanceMonitor) {
        self.analyticsEngine = analyticsEngine
        self.configManager = configManager
        self.errorHandler = errorHandler
        self.performanceMonitor = performanceMonitor
        
        setupDefaultQualityRules()
    }
    
    // MARK: - Public Methods
    
    /// Perform comprehensive data quality assessment
    public func assessDataQuality(
        data: [String: [Any]],
        datasetName: String,
        sourceSystem: String = "Unknown"
    ) async throws -> DataQualityReport {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("data_quality_assessment", value: executionTime)
        }
        
        do {
            guard !data.isEmpty else {
                throw AnalyticsError.invalidInput("Data cannot be empty")
            }
            
            let recordCount = data.values.first?.count ?? 0
            let fieldCount = data.keys.count
            
            // Validate data consistency
            guard data.values.allSatisfy({ $0.count == recordCount }) else {
                throw AnalyticsError.invalidInput("All fields must have the same number of records")
            }
            
            let datasetInfo = DatasetInfo(
                name: datasetName,
                recordCount: recordCount,
                fieldCount: fieldCount,
                lastUpdated: Date(),
                sourceSystem: sourceSystem,
                dataTypes: detectDataTypes(data: data)
            )
            
            // Calculate quality metrics
            var metricScores: [QualityMetric: Double] = [:]
            var allIssues: [DataQualityIssue] = []
            
            // Completeness assessment
            let (completenessScore, completenessIssues) = assessCompleteness(data: data)
            metricScores[.completeness] = completenessScore
            allIssues.append(contentsOf: completenessIssues)
            
            // Accuracy assessment
            let (accuracyScore, accuracyIssues) = try await assessAccuracy(data: data, datasetName: datasetName)
            metricScores[.accuracy] = accuracyScore
            allIssues.append(contentsOf: accuracyIssues)
            
            // Consistency assessment
            let (consistencyScore, consistencyIssues) = assessConsistency(data: data)
            metricScores[.consistency] = consistencyScore
            allIssues.append(contentsOf: consistencyIssues)
            
            // Validity assessment
            let (validityScore, validityIssues) = try assessValidity(data: data, datasetName: datasetName)
            metricScores[.validity] = validityScore
            allIssues.append(contentsOf: validityIssues)
            
            // Uniqueness assessment
            let (uniquenessScore, uniquenessIssues) = assessUniqueness(data: data)
            metricScores[.uniqueness] = uniquenessScore
            allIssues.append(contentsOf: uniquenessIssues)
            
            // Timeliness assessment
            let (timelinessScore, timelinessIssues) = assessTimeliness(data: data)
            metricScores[.timeliness] = timelinessScore
            allIssues.append(contentsOf: timelinessIssues)
            
            // Integrity assessment
            let (integrityScore, integrityIssues) = assessIntegrity(data: data)
            metricScores[.integrity] = integrityScore
            allIssues.append(contentsOf: integrityIssues)
            
            // Conformity assessment
            let (conformityScore, conformityIssues) = assessConformity(data: data, datasetName: datasetName)
            metricScores[.conformity] = conformityScore
            allIssues.append(contentsOf: conformityIssues)
            
            // Calculate overall score
            let overallScore = calculateOverallScore(metricScores: metricScores)
            
            // Generate recommendations
            let recommendations = generateRecommendations(issues: allIssues, metricScores: metricScores)
            
            let report = DataQualityReport(
                overallScore: overallScore,
                metricScores: metricScores,
                issues: allIssues,
                recommendations: recommendations,
                timestamp: Date(),
                datasetInfo: datasetInfo
            )
            
            // Store in history
            qualityHistory.append(report)
            
            return report
            
        } catch {
            await errorHandler.handleError(error, context: "DataQualityManager.assessDataQuality")
            throw error
        }
    }
    
    /// Clean data based on quality assessment
    public func cleanData(
        data: [String: [Any]],
        qualityReport: DataQualityReport,
        cleaningStrategy: CleaningStrategy = .automatic
    ) async throws -> ([String: [Any]], [CleaningOperation]) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("data_cleaning", value: executionTime)
        }
        
        do {
            var cleanedData = data
            var appliedOperations: [CleaningOperation] = []
            
            // Sort issues by severity and impact
            let sortedIssues = qualityReport.issues.sorted { issue1, issue2 in
                let severity1 = severityToInt(issue1.severity)
                let severity2 = severityToInt(issue2.severity)
                
                if severity1 != severity2 {
                    return severity1 > severity2
                }
                return issue1.estimatedImpact > issue2.estimatedImpact
            }
            
            // Apply cleaning operations based on issues
            for issue in sortedIssues {
                let operations = try await generateCleaningOperations(
                    issue: issue,
                    data: cleanedData,
                    strategy: cleaningStrategy
                )
                
                for operation in operations {
                    let (updatedData, success) = try await applyCleaningOperation(
                        operation: operation,
                        data: cleanedData
                    )
                    
                    if success {
                        cleanedData = updatedData
                        appliedOperations.append(operation)
                    }
                }
            }
            
            return (cleanedData, appliedOperations)
            
        } catch {
            await errorHandler.handleError(error, context: "DataQualityManager.cleanData")
            throw error
        }
    }
    
    /// Add custom quality rule
    public func addQualityRule(
        datasetName: String,
        rule: QualityRule
    ) async throws {
        
        do {
            if qualityRules[datasetName] == nil {
                qualityRules[datasetName] = []
            }
            
            qualityRules[datasetName]?.append(rule)
            
        } catch {
            await errorHandler.handleError(error, context: "DataQualityManager.addQualityRule")
            throw error
        }
    }
    
    /// Monitor data quality over time
    public func monitorQualityTrends(
        datasetName: String,
        timeRange: DateInterval? = nil
    ) async throws -> QualityTrendAnalysis {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("quality_trend_analysis", value: executionTime)
        }
        
        do {
            let filteredHistory = qualityHistory.filter { report in
                report.datasetInfo.name == datasetName &&
                (timeRange?.contains(report.timestamp) ?? true)
            }.sorted { $0.timestamp < $1.timestamp }
            
            guard !filteredHistory.isEmpty else {
                throw AnalyticsError.insufficientData("No quality history found for dataset")
            }
            
            let trendAnalysis = analyzeTrends(history: filteredHistory)
            
            return trendAnalysis
            
        } catch {
            await errorHandler.handleError(error, context: "DataQualityManager.monitorQualityTrends")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultQualityRules() {
        // Healthcare-specific quality rules
        let healthcareRules = [
            QualityRule(
                name: "Patient ID Not Null",
                description: "Patient ID must not be null or empty",
                fieldName: "patient_id",
                ruleType: .notNull,
                parameters: [:],
                severity: .critical,
                isActive: true
            ),
            QualityRule(
                name: "Age Range",
                description: "Patient age must be between 0 and 150",
                fieldName: "age",
                ruleType: .range(min: 0, max: 150),
                parameters: ["min": 0, "max": 150],
                severity: .high,
                isActive: true
            ),
            QualityRule(
                name: "Blood Pressure Range",
                description: "Blood pressure must be within reasonable medical ranges",
                fieldName: "blood_pressure_systolic",
                ruleType: .range(min: 60, max: 300),
                parameters: ["min": 60, "max": 300],
                severity: .medium,
                isActive: true
            ),
            QualityRule(
                name: "Heart Rate Range",
                description: "Heart rate must be between 30 and 220 BPM",
                fieldName: "heart_rate",
                ruleType: .range(min: 30, max: 220),
                parameters: ["min": 30, "max": 220],
                severity: .medium,
                isActive: true
            )
        ]
        
        qualityRules["healthcare_data"] = healthcareRules
    }
    
    private func detectDataTypes(data: [String: [Any]]) -> [String: String] {
        var dataTypes: [String: String] = [:]
        
        for (fieldName, values) in data {
            guard !values.isEmpty else {
                dataTypes[fieldName] = "unknown"
                continue
            }
            
            let sampleValue = values.first { $0 is NSNull == false }
            
            switch sampleValue {
            case is String:
                dataTypes[fieldName] = "string"
            case is Int, is Int64, is Int32:
                dataTypes[fieldName] = "integer"
            case is Double, is Float:
                dataTypes[fieldName] = "double"
            case is Bool:
                dataTypes[fieldName] = "boolean"
            case is Date:
                dataTypes[fieldName] = "date"
            default:
                dataTypes[fieldName] = "unknown"
            }
        }
        
        return dataTypes
    }
    
    private func assessCompleteness(data: [String: [Any]]) -> (Double, [DataQualityIssue]) {
        var totalValues = 0
        var missingValues = 0
        var issues: [DataQualityIssue] = []
        
        for (fieldName, values) in data {
            totalValues += values.count
            let fieldMissingCount = values.filter { value in
                if let stringValue = value as? String {
                    return stringValue.isEmpty || stringValue.lowercased() == "null"
                }
                return value is NSNull
            }.count
            
            missingValues += fieldMissingCount
            
            if fieldMissingCount > 0 {
                let missingPercentage = Double(fieldMissingCount) / Double(values.count) * 100
                let severity: IssueSeverity
                
                if missingPercentage > 50 {
                    severity = .critical
                } else if missingPercentage > 25 {
                    severity = .high
                } else if missingPercentage > 10 {
                    severity = .medium
                } else {
                    severity = .low
                }
                
                let issue = DataQualityIssue(
                    type: .missingValues,
                    severity: severity,
                    description: "\(missingPercentage.rounded(toPlaces: 2))% missing values in \(fieldName)",
                    affectedFields: [fieldName],
                    affectedRecords: [],
                    suggestedAction: "Implement missing value imputation strategy",
                    estimatedImpact: missingPercentage / 100.0
                )
                
                issues.append(issue)
            }
        }
        
        let completenessScore = totalValues > 0 ? Double(totalValues - missingValues) / Double(totalValues) : 0.0
        
        return (completenessScore, issues)
    }
    
    private func assessAccuracy(data: [String: [Any]], datasetName: String) async -> (Double, [DataQualityIssue]) {
        var accuracyScore = 1.0
        var issues: [DataQualityIssue] = []
        
        // Check against quality rules
        if let rules = qualityRules[datasetName] {
            for rule in rules where rule.isActive {
                if let fieldValues = data[rule.fieldName] {
                    let (ruleScore, ruleIssues) = evaluateQualityRule(rule: rule, values: fieldValues)
                    accuracyScore = min(accuracyScore, ruleScore)
                    issues.append(contentsOf: ruleIssues)
                }
            }
        }
        
        // Detect statistical outliers
        for (fieldName, values) in data {
            if let numericValues = convertToNumeric(values: values) {
                let outliers = detectOutliers(values: numericValues)
                
                if !outliers.isEmpty {
                    let outlierPercentage = Double(outliers.count) / Double(numericValues.count) * 100
                    
                    if outlierPercentage > 5 {
                        let severity: IssueSeverity = outlierPercentage > 15 ? .high : .medium
                        
                        let issue = DataQualityIssue(
                            type: .outliers,
                            severity: severity,
                            description: "\(outliers.count) outliers detected in \(fieldName) (\(outlierPercentage.rounded(toPlaces: 2))%)",
                            affectedFields: [fieldName],
                            affectedRecords: outliers,
                            suggestedAction: "Review and validate outlier values",
                            estimatedImpact: outlierPercentage / 100.0
                        )
                        
                        issues.append(issue)
                    }
                }
            }
        }
        
        return (accuracyScore, issues)
    }
    
    private func assessConsistency(data: [String: [Any]]) -> (Double, [DataQualityIssue]) {
        var consistencyScore = 1.0
        var issues: [DataQualityIssue] = []
        
        // Check format consistency for string fields
        for (fieldName, values) in data {
            if let stringValues = values.compactMap({ $0 as? String }) {
                let formatConsistency = checkFormatConsistency(values: stringValues)
                consistencyScore = min(consistencyScore, formatConsistency.score)
                
                if formatConsistency.score < 0.8 {
                    let issue = DataQualityIssue(
                        type: .inconsistentFormat,
                        severity: .medium,
                        description: "Inconsistent format detected in \(fieldName)",
                        affectedFields: [fieldName],
                        affectedRecords: formatConsistency.inconsistentIndices,
                        suggestedAction: "Standardize data format",
                        estimatedImpact: 1.0 - formatConsistency.score
                    )
                    
                    issues.append(issue)
                }
            }
        }
        
        return (consistencyScore, issues)
    }
    
    private func assessValidity(data: [String: [Any]], datasetName: String) throws -> (Double, [DataQualityIssue]) {
        var validityScore = 1.0
        var issues: [DataQualityIssue] = []
        
        // Validate against data type constraints
        for (fieldName, values) in data {
            let (typeValidityScore, typeIssues) = validateDataTypes(fieldName: fieldName, values: values)
            validityScore = min(validityScore, typeValidityScore)
            issues.append(contentsOf: typeIssues)
        }
        
        // Validate against business rules
        if let rules = qualityRules[datasetName] {
            for rule in rules where rule.isActive {
                if let fieldValues = data[rule.fieldName] {
                    let (ruleScore, ruleIssues) = evaluateQualityRule(rule: rule, values: fieldValues)
                    validityScore = min(validityScore, ruleScore)
                    issues.append(contentsOf: ruleIssues)
                }
            }
        }
        
        return (validityScore, issues)
    }
    
    private func assessUniqueness(data: [String: [Any]]) -> (Double, [DataQualityIssue]) {
        var uniquenessScore = 1.0
        var issues: [DataQualityIssue] = []
        
        for (fieldName, values) in data {
            let stringValues = values.map { String(describing: $0) }
            let uniqueValues = Set(stringValues)
            let duplicateCount = stringValues.count - uniqueValues.count
            
            if duplicateCount > 0 {
                let duplicatePercentage = Double(duplicateCount) / Double(stringValues.count) * 100
                let fieldUniquenesScore = Double(uniqueValues.count) / Double(stringValues.count)
                uniquenessScore = min(uniquenessScore, fieldUniquenesScore)
                
                let severity: IssueSeverity
                if duplicatePercentage > 20 {
                    severity = .high
                } else if duplicatePercentage > 10 {
                    severity = .medium
                } else {
                    severity = .low
                }
                
                let issue = DataQualityIssue(
                    type: .duplicateRecords,
                    severity: severity,
                    description: "\(duplicateCount) duplicate values in \(fieldName) (\(duplicatePercentage.rounded(toPlaces: 2))%)",
                    affectedFields: [fieldName],
                    affectedRecords: [],
                    suggestedAction: "Remove or consolidate duplicate records",
                    estimatedImpact: duplicatePercentage / 100.0
                )
                
                issues.append(issue)
            }
        }
        
        return (uniquenessScore, issues)
    }
    
    private func assessTimeliness(data: [String: [Any]]) -> (Double, [DataQualityIssue]) {
        var timelinessScore = 1.0
        var issues: [DataQualityIssue] = []
        
        // Look for date/timestamp fields
        for (fieldName, values) in data {
            if fieldName.lowercased().contains("date") || fieldName.lowercased().contains("time") {
                if let dateValues = convertToDate(values: values) {
                    let (score, timeIssues) = analyzeTemporalConsistency(fieldName: fieldName, dates: dateValues)
                    timelinessScore = min(timelinessScore, score)
                    issues.append(contentsOf: timeIssues)
                }
            }
        }
        
        return (timelinessScore, issues)
    }
    
    private func assessIntegrity(data: [String: [Any]]) -> (Double, [DataQualityIssue]) {
        var integrityScore = 1.0
        var issues: [DataQualityIssue] = []
        
        // Check for referential integrity issues
        // This is a simplified check - in practice, you'd have actual foreign key relationships
        
        if let patientIds = data["patient_id"],
           let visitIds = data["visit_id"] {
            
            let patientIdStrings = patientIds.compactMap { $0 as? String }
            let visitIdStrings = visitIds.compactMap { $0 as? String }
            
            // Check if all visit IDs have corresponding patient IDs (simplified logic)
            let orphanedVisits = visitIdStrings.enumerated().filter { index, visitId in
                // Simplified: assume visit ID contains patient ID
                !patientIdStrings.contains { visitId.contains($0) }
            }
            
            if !orphanedVisits.isEmpty {
                let issue = DataQualityIssue(
                    type: .referentialIntegrity,
                    severity: .high,
                    description: "\(orphanedVisits.count) orphaned visit records without valid patient references",
                    affectedFields: ["visit_id", "patient_id"],
                    affectedRecords: orphanedVisits.map { $0.0 },
                    suggestedAction: "Validate and correct referential integrity",
                    estimatedImpact: Double(orphanedVisits.count) / Double(visitIdStrings.count)
                )
                
                issues.append(issue)
                integrityScore = 1.0 - issue.estimatedImpact
            }
        }
        
        return (integrityScore, issues)
    }
    
    private func assessConformity(data: [String: [Any]], datasetName: String) -> (Double, [DataQualityIssue]) {
        var conformityScore = 1.0
        var issues: [DataQualityIssue] = []
        
        // Check conformity to expected schema/standards
        let expectedHealthcareFields = ["patient_id", "age", "gender", "diagnosis", "treatment"]
        let actualFields = Set(data.keys)
        let expectedFields = Set(expectedHealthcareFields)
        
        let missingFields = expectedFields.subtracting(actualFields)
        let extraFields = actualFields.subtracting(expectedFields)
        
        if !missingFields.isEmpty {
            let issue = DataQualityIssue(
                type: .businessRuleViolation,
                severity: .medium,
                description: "Missing expected healthcare fields: \(missingFields.joined(separator: ", "))",
                affectedFields: Array(missingFields),
                affectedRecords: [],
                suggestedAction: "Add missing required fields or update schema",
                estimatedImpact: Double(missingFields.count) / Double(expectedFields.count)
            )
            
            issues.append(issue)
            conformityScore -= issue.estimatedImpact
        }
        
        return (max(0, conformityScore), issues)
    }
    
    // MARK: - Helper Methods
    
    private func calculateOverallScore(metricScores: [QualityMetric: Double]) -> Double {
        let weights: [QualityMetric: Double] = [
            .completeness: 0.2,
            .accuracy: 0.25,
            .consistency: 0.15,
            .validity: 0.2,
            .uniqueness: 0.05,
            .timeliness: 0.05,
            .integrity: 0.05,
            .conformity: 0.05
        ]
        
        var weightedSum = 0.0
        var totalWeight = 0.0
        
        for (metric, score) in metricScores {
            if let weight = weights[metric] {
                weightedSum += score * weight
                totalWeight += weight
            }
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0.0
    }
    
    private func generateRecommendations(
        issues: [DataQualityIssue],
        metricScores: [QualityMetric: Double]
    ) -> [QualityRecommendation] {
        
        var recommendations: [QualityRecommendation] = []
        
        // Generate recommendations based on issues
        let criticalIssues = issues.filter { $0.severity == .critical }
        if !criticalIssues.isEmpty {
            recommendations.append(QualityRecommendation(
                priority: .urgent,
                action: "Address Critical Data Quality Issues",
                description: "Resolve \(criticalIssues.count) critical issues that significantly impact data reliability",
                estimatedEffort: "High",
                expectedImprovement: 0.3,
                relatedIssues: criticalIssues.map { $0.type }
            ))
        }
        
        // Completeness recommendations
        if let completenessScore = metricScores[.completeness], completenessScore < 0.8 {
            recommendations.append(QualityRecommendation(
                priority: .high,
                action: "Implement Missing Value Strategy",
                description: "Develop comprehensive strategy for handling missing values",
                estimatedEffort: "Medium",
                expectedImprovement: 0.2,
                relatedIssues: [.missingValues]
            ))
        }
        
        // Accuracy recommendations
        if let accuracyScore = metricScores[.accuracy], accuracyScore < 0.9 {
            recommendations.append(QualityRecommendation(
                priority: .high,
                action: "Enhance Data Validation",
                description: "Implement stricter validation rules and outlier detection",
                estimatedEffort: "Medium",
                expectedImprovement: 0.15,
                relatedIssues: [.outliers, .invalidValues]
            ))
        }
        
        return recommendations
    }
    
    private func convertToNumeric(values: [Any]) -> [Double]? {
        let numericValues = values.compactMap { value -> Double? in
            if let doubleValue = value as? Double {
                return doubleValue
            } else if let intValue = value as? Int {
                return Double(intValue)
            } else if let stringValue = value as? String {
                return Double(stringValue)
            }
            return nil
        }
        
        return numericValues.isEmpty ? nil : numericValues
    }
    
    private func detectOutliers(values: [Double]) -> [Int] {
        guard values.count >= 4 else { return [] }
        
        let sortedValues = values.sorted()
        let q1Index = sortedValues.count / 4
        let q3Index = 3 * sortedValues.count / 4
        
        let q1 = sortedValues[q1Index]
        let q3 = sortedValues[q3Index]
        let iqr = q3 - q1
        
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        return values.enumerated().compactMap { index, value in
            (value < lowerBound || value > upperBound) ? index : nil
        }
    }
    
    private func checkFormatConsistency(values: [String]) -> (score: Double, inconsistentIndices: [Int]) {
        guard !values.isEmpty else { return (1.0, []) }
        
        // Simple format consistency check based on pattern similarity
        let patterns = values.map { value in
            value.replacingOccurrences(of: "\\d", with: "D", options: .regularExpression)
                 .replacingOccurrences(of: "[A-Za-z]", with: "L", options: .regularExpression)
        }
        
        let patternCounts = Dictionary(grouping: patterns.enumerated(), by: { $0.1 })
        let mostCommonPattern = patternCounts.max(by: { $0.value.count < $1.value.count })?.key ?? ""
        
        let inconsistentIndices = patterns.enumerated().compactMap { index, pattern in
            pattern != mostCommonPattern ? index : nil
        }
        
        let consistencyScore = Double(patterns.count - inconsistentIndices.count) / Double(patterns.count)
        
        return (consistencyScore, inconsistentIndices)
    }
    
    private func validateDataTypes(fieldName: String, values: [Any]) -> (Double, [DataQualityIssue]) {
        var validCount = 0
        var issues: [DataQualityIssue] = []
        
        // Determine expected type based on field name
        let expectedType = inferExpectedType(fieldName: fieldName)
        
        for (index, value) in values.enumerated() {
            if isValidType(value: value, expectedType: expectedType) {
                validCount += 1
            }
        }
        
        let validityScore = Double(validCount) / Double(values.count)
        
        if validityScore < 1.0 {
            let invalidCount = values.count - validCount
            let severity: IssueSeverity = validityScore < 0.5 ? .high : .medium
            
            let issue = DataQualityIssue(
                type: .dataTypeErrors,
                severity: severity,
                description: "\(invalidCount) values in \(fieldName) have incorrect data type",
                affectedFields: [fieldName],
                affectedRecords: [],
                suggestedAction: "Convert or validate data types",
                estimatedImpact: 1.0 - validityScore
            )
            
            issues.append(issue)
        }
        
        return (validityScore, issues)
    }
    
    private func evaluateQualityRule(rule: QualityRule, values: [Any]) -> (Double, [DataQualityIssue]) {
        var validCount = 0
        var issues: [DataQualityIssue] = []
        
        for value in values {
            if evaluateRuleForValue(rule: rule, value: value) {
                validCount += 1
            }
        }
        
        let ruleScore = Double(validCount) / Double(values.count)
        
        if ruleScore < 1.0 {
            let violationCount = values.count - validCount
            
            let issue = DataQualityIssue(
                type: .businessRuleViolation,
                severity: rule.severity,
                description: "\(violationCount) values violate rule: \(rule.description)",
                affectedFields: [rule.fieldName],
                affectedRecords: [],
                suggestedAction: "Review and correct rule violations",
                estimatedImpact: 1.0 - ruleScore
            )
            
            issues.append(issue)
        }
        
        return (ruleScore, issues)
    }
    
    private func convertToDate(values: [Any]) -> [Date]? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dates = values.compactMap { value -> Date? in
            if let date = value as? Date {
                return date
            } else if let stringValue = value as? String {
                return dateFormatter.date(from: stringValue)
            }
            return nil
        }
        
        return dates.isEmpty ? nil : dates
    }
    
    private func analyzeTemporalConsistency(fieldName: String, dates: [Date]) -> (Double, [DataQualityIssue]) {
        var score = 1.0
        var issues: [DataQualityIssue] = []
        
        // Check for future dates (assuming current context)
        let futureDates = dates.filter { $0 > Date() }
        if !futureDates.isEmpty {
            let issue = DataQualityIssue(
                type: .temporalInconsistency,
                severity: .medium,
                description: "\(futureDates.count) future dates found in \(fieldName)",
                affectedFields: [fieldName],
                affectedRecords: [],
                suggestedAction: "Validate and correct future dates",
                estimatedImpact: Double(futureDates.count) / Double(dates.count)
            )
            
            issues.append(issue)
            score -= issue.estimatedImpact
        }
        
        return (max(0, score), issues)
    }
    
    private func inferExpectedType(fieldName: String) -> String {
        let lowercaseField = fieldName.lowercased()
        
        if lowercaseField.contains("id") {
            return "string"
        } else if lowercaseField.contains("age") || lowercaseField.contains("count") {
            return "integer"
        } else if lowercaseField.contains("rate") || lowercaseField.contains("pressure") || lowercaseField.contains("temperature") {
            return "double"
        } else if lowercaseField.contains("date") || lowercaseField.contains("time") {
            return "date"
        } else if lowercaseField.contains("active") || lowercaseField.contains("enabled") {
            return "boolean"
        }
        
        return "string"
    }
    
    private func isValidType(value: Any, expectedType: String) -> Bool {
        switch expectedType {
        case "string":
            return value is String
        case "integer":
            return value is Int || value is Int64 || value is Int32
        case "double":
            return value is Double || value is Float || value is Int
        case "boolean":
            return value is Bool
        case "date":
            return value is Date
        default:
            return true
        }
    }
    
    private func evaluateRuleForValue(rule: QualityRule, value: Any) -> Bool {
        switch rule.ruleType {
        case .notNull:
            if let stringValue = value as? String {
                return !stringValue.isEmpty && stringValue.lowercased() != "null"
            }
            return !(value is NSNull)
            
        case .range(let min, let max):
            if let numericValue = convertToNumeric(values: [value])?.first {
                return numericValue >= min && numericValue <= max
            }
            return false
            
        case .regex(let pattern):
            if let stringValue = value as? String {
                return stringValue.range(of: pattern, options: .regularExpression) != nil
            }
            return false
            
        case .enumeration(let validValues):
            let stringValue = String(describing: value)
            return validValues.contains(stringValue)
            
        case .uniqueness:
            // This would need to be evaluated at the dataset level
            return true
            
        case .referentialIntegrity(_, _):
            // This would need cross-table validation
            return true
            
        case .businessRule(_):
            // Would need expression evaluation
            return true
            
        case .temporalLogic(_):
            // Would need temporal expression evaluation
            return true
        }
    }
    
    private func severityToInt(_ severity: IssueSeverity) -> Int {
        switch severity {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Supporting Types

public enum CleaningStrategy {
    case automatic
    case conservative
    case aggressive
    case custom([CleaningOperationType])
}

public struct QualityTrendAnalysis {
    let overallTrend: TrendDirection
    let metricTrends: [QualityMetric: TrendDirection]
    let trendStrength: Double
    let predictions: [QualityMetric: Double]
    let recommendations: [String]
}

public enum TrendDirection {
    case improving
    case declining
    case stable
    case volatile
}

// MARK: - Data Cleaning Implementation

extension DataQualityManager {
    
    private func generateCleaningOperations(
        issue: DataQualityIssue,
        data: [String: [Any]],
        strategy: CleaningStrategy
    ) async throws -> [CleaningOperation] {
        
        var operations: [CleaningOperation] = []
        
        switch issue.type {
        case .missingValues:
            for fieldName in issue.affectedFields {
                let operation = CleaningOperation(
                    operationType: .fillMissing(strategy: .mean),
                    fieldName: fieldName,
                    parameters: ["strategy": "mean"],
                    affectedRecords: [],
                    confidence: 0.8
                )
                operations.append(operation)
            }
            
        case .duplicateRecords:
            for fieldName in issue.affectedFields {
                let operation = CleaningOperation(
                    operationType: .removeDuplicates,
                    fieldName: fieldName,
                    parameters: [:],
                    affectedRecords: [],
                    confidence: 0.9
                )
                operations.append(operation)
            }
            
        case .outliers:
            for fieldName in issue.affectedFields {
                let operation = CleaningOperation(
                    operationType: .correctOutliers(method: .iqr_method),
                    fieldName: fieldName,
                    parameters: ["method": "iqr"],
                    affectedRecords: issue.affectedRecords,
                    confidence: 0.7
                )
                operations.append(operation)
            }
            
        default:
            break
        }
        
        return operations
    }
    
    private func applyCleaningOperation(
        operation: CleaningOperation,
        data: [String: [Any]]
    ) async throws -> ([String: [Any]], Bool) {
        
        var cleanedData = data
        
        guard let fieldValues = data[operation.fieldName] else {
            return (data, false)
        }
        
        switch operation.operationType {
        case .fillMissing(let strategy):
            let cleanedValues = try fillMissingValues(values: fieldValues, strategy: strategy)
            cleanedData[operation.fieldName] = cleanedValues
            return (cleanedData, true)
            
        case .removeDuplicates:
            let cleanedValues = removeDuplicateValues(values: fieldValues)
            cleanedData[operation.fieldName] = cleanedValues
            return (cleanedData, true)
            
        case .correctOutliers(let method):
            if let numericValues = convertToNumeric(values: fieldValues) {
                let cleanedNumericValues = correctOutliers(values: numericValues, method: method)
                cleanedData[operation.fieldName] = cleanedNumericValues.map { $0 as Any }
                return (cleanedData, true)
            }
            return (data, false)
            
        default:
            return (data, false)
        }
    }
    
    private func fillMissingValues(values: [Any], strategy: MissingValueStrategy) throws -> [Any] {
        var cleanedValues = values
        
        switch strategy {
        case .mean:
            if let numericValues = convertToNumeric(values: values) {
                let mean = numericValues.reduce(0, +) / Double(numericValues.count)
                for i in 0..<cleanedValues.count {
                    if isMissingValue(cleanedValues[i]) {
                        cleanedValues[i] = mean
                    }
                }
            }
            
        case .median:
            if let numericValues = convertToNumeric(values: values) {
                let sortedValues = numericValues.sorted()
                let median = sortedValues[sortedValues.count / 2]
                for i in 0..<cleanedValues.count {
                    if isMissingValue(cleanedValues[i]) {
                        cleanedValues[i] = median
                    }
                }
            }
            
        case .mode:
            let nonMissingValues = values.filter { !isMissingValue($0) }
            let valueCounts = Dictionary(grouping: nonMissingValues) { String(describing: $0) }
            let mode = valueCounts.max(by: { $0.value.count < $1.value.count })?.value.first
            
            if let modeValue = mode {
                for i in 0..<cleanedValues.count {
                    if isMissingValue(cleanedValues[i]) {
                        cleanedValues[i] = modeValue
                    }
                }
            }
            
        default:
            // For other strategies, implement as needed
            break
        }
        
        return cleanedValues
    }
    
    private func removeDuplicateValues(values: [Any]) -> [Any] {
        var uniqueValues: [Any] = []
        var seenValues: Set<String> = []
        
        for value in values {
            let stringValue = String(describing: value)
            if !seenValues.contains(stringValue) {
                uniqueValues.append(value)
                seenValues.insert(stringValue)
            }
        }
        
        return uniqueValues
    }
    
    private func correctOutliers(values: [Double], method: OutlierCorrectionMethod) -> [Double] {
        var correctedValues = values
        
        switch method {
        case .iqr_method:
            let sortedValues = values.sorted()
            let q1 = sortedValues[sortedValues.count / 4]
            let q3 = sortedValues[3 * sortedValues.count / 4]
            let iqr = q3 - q1
            
            let lowerBound = q1 - 1.5 * iqr
            let upperBound = q3 + 1.5 * iqr
            
            for i in 0..<correctedValues.count {
                if correctedValues[i] < lowerBound {
                    correctedValues[i] = lowerBound
                } else if correctedValues[i] > upperBound {
                    correctedValues[i] = upperBound
                }
            }
            
        case .cap_at_percentile(let percentile):
            let sortedValues = values.sorted()
            let percentileIndex = Int(Double(sortedValues.count) * percentile / 100.0)
            let cap = sortedValues[min(percentileIndex, sortedValues.count - 1)]
            
            for i in 0..<correctedValues.count {
                if correctedValues[i] > cap {
                    correctedValues[i] = cap
                }
            }
            
        default:
            break
        }
        
        return correctedValues
    }
    
    private func isMissingValue(_ value: Any) -> Bool {
        if let stringValue = value as? String {
            return stringValue.isEmpty || stringValue.lowercased() == "null"
        }
        return value is NSNull
    }
    
    private func analyzeTrends(history: [DataQualityReport]) -> QualityTrendAnalysis {
        // Simplified trend analysis
        let overallScores = history.map { $0.overallScore }
        let trend = calculateTrendDirection(values: overallScores)
        
        var metricTrends: [QualityMetric: TrendDirection] = [:]
        for metric in QualityMetric.allCases {
            let metricScores = history.compactMap { $0.metricScores[metric] }
            metricTrends[metric] = calculateTrendDirection(values: metricScores)
        }
        
        return QualityTrendAnalysis(
            overallTrend: trend,
            metricTrends: metricTrends,
            trendStrength: 0.8,
            predictions: [:],
            recommendations: []
        )
    }
    
    private func calculateTrendDirection(values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let improvement = secondAvg - firstAvg
        
        if abs(improvement) < 0.05 {
            return .stable
        } else if improvement > 0 {
            return .improving
        } else {
            return .declining
        }
    }
}

// MARK: - QualityMetric CaseIterable

extension DataQualityManager.QualityMetric: CaseIterable {
    public static var allCases: [DataQualityManager.QualityMetric] {
        return [
            .completeness, .accuracy, .consistency, .validity,
            .uniqueness, .timeliness, .integrity, .conformity
        ]
    }
}

// MARK: - Double Extension

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
