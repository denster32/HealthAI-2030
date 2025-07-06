import Foundation
import CryptoKit

// MARK: - Export Privacy Manager

@available(iOS 14.0, *)
class ExportPrivacyManager {
    static let shared = ExportPrivacyManager()
    
    // MARK: - Privacy Configuration
    
    struct PrivacyConfiguration {
        let anonymizePersonalInfo: Bool
        let excludeSensitiveDataTypes: Bool
        let removeLocationData: Bool
        let removeDeviceIdentifiers: Bool
        let removeSourceApplications: Bool
        let hashIdentifiers: Bool
        let minimumAggregationPeriod: TimeInterval?
        let noiseLevel: NoiseLevel
        let retentionPolicy: RetentionPolicy
        
        static let `default` = PrivacyConfiguration(
            anonymizePersonalInfo: false,
            excludeSensitiveDataTypes: false,
            removeLocationData: false,
            removeDeviceIdentifiers: false,
            removeSourceApplications: false,
            hashIdentifiers: false,
            minimumAggregationPeriod: nil,
            noiseLevel: .none,
            retentionPolicy: .keepAll
        )
        
        static let fullyAnonymous = PrivacyConfiguration(
            anonymizePersonalInfo: true,
            excludeSensitiveDataTypes: true,
            removeLocationData: true,
            removeDeviceIdentifiers: true,
            removeSourceApplications: true,
            hashIdentifiers: true,
            minimumAggregationPeriod: 3600, // 1 hour aggregation
            noiseLevel: .medium,
            retentionPolicy: .last90Days
        )
    }
    
    enum NoiseLevel: String, CaseIterable {
        case none = "None"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var variancePercentage: Double {
            switch self {
            case .none: return 0.0
            case .low: return 0.01   // 1%
            case .medium: return 0.03 // 3%
            case .high: return 0.05   // 5%
            }
        }
    }
    
    enum RetentionPolicy: String, CaseIterable {
        case keepAll = "Keep All Data"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case lastYear = "Last Year"
        
        var timeInterval: TimeInterval? {
            switch self {
            case .keepAll: return nil
            case .last30Days: return 30 * 24 * 3600
            case .last90Days: return 90 * 24 * 3600
            case .lastYear: return 365 * 24 * 3600
            }
        }
    }
    
    // MARK: - Sensitive Data Types
    
    private let sensitiveDataTypes: Set<HealthDataType> = [
        .medicalRecords,
        .immunizations,
        .allergies,
        .medications,
        .mood,
        .anxiety,
        .depression,
        .mindfulSession
    ]
    
    private let personalIdentifiers = [
        "HKMetadataKeyDeviceSerialNumber",
        "HKMetadataKeyDeviceName",
        "HKMetadataKeyDeviceManufacturerName",
        "HKMetadataKeyExternalUUID",
        "HKMetadataKeyUserMotionContext",
        "HKMetadataKeyLocationCoordinate"
    ]
    
    // MARK: - Private Properties
    
    private let anonymizationSeed: String
    private let hasher = SHA256()
    
    // MARK: - Initialization
    
    private init() {
        // Generate a consistent seed for anonymization within this session
        self.anonymizationSeed = UUID().uuidString
    }
    
    // MARK: - Public Privacy Methods
    
    /// Apply privacy settings to health data
    func applyPrivacySettings(
        to data: [HealthDataPoint],
        configuration: PrivacyConfiguration
    ) -> [HealthDataPoint] {
        var processedData = data
        
        // Apply retention policy first
        if let retentionInterval = configuration.retentionPolicy.timeInterval {
            processedData = applyRetentionPolicy(to: processedData, interval: retentionInterval)
        }
        
        // Exclude sensitive data types
        if configuration.excludeSensitiveDataTypes {
            processedData = excludeSensitiveData(processedData)
        }
        
        // Apply anonymization
        if configuration.anonymizePersonalInfo {
            processedData = anonymizePersonalInformation(processedData)
        }
        
        // Remove location data
        if configuration.removeLocationData {
            processedData = removeLocationData(processedData)
        }
        
        // Remove device identifiers
        if configuration.removeDeviceIdentifiers {
            processedData = removeDeviceIdentifiers(processedData)
        }
        
        // Remove source applications
        if configuration.removeSourceApplications {
            processedData = removeSourceApplications(processedData)
        }
        
        // Hash identifiers
        if configuration.hashIdentifiers {
            processedData = hashIdentifiers(processedData)
        }
        
        // Apply data aggregation
        if let aggregationPeriod = configuration.minimumAggregationPeriod {
            processedData = aggregateData(processedData, period: aggregationPeriod)
        }
        
        // Add statistical noise
        if configuration.noiseLevel != .none {
            processedData = addStatisticalNoise(to: processedData, level: configuration.noiseLevel)
        }
        
        return processedData
    }
    
    /// Create anonymized version of health data using the standard privacy settings
    func anonymizeHealthData(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return applyPrivacySettings(to: data, configuration: .fullyAnonymous)
    }
    
    /// Filter out sensitive health data types
    func filterSensitiveData(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return excludeSensitiveData(data)
    }
    
    /// Validate privacy configuration for compliance
    func validatePrivacyConfiguration(_ configuration: PrivacyConfiguration) -> PrivacyValidationResult {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check for HIPAA compliance indicators
        if !configuration.anonymizePersonalInfo {
            issues.append("Personal information is not anonymized")
            recommendations.append("Enable personal information anonymization for HIPAA compliance")
        }
        
        if !configuration.excludeSensitiveDataTypes {
            recommendations.append("Consider excluding sensitive data types for enhanced privacy")
        }
        
        if configuration.noiseLevel == .none && configuration.anonymizePersonalInfo {
            recommendations.append("Adding statistical noise can improve anonymization quality")
        }
        
        let complianceLevel = calculateComplianceLevel(configuration)
        
        return PrivacyValidationResult(
            isCompliant: issues.isEmpty,
            complianceLevel: complianceLevel,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    // MARK: - Private Anonymization Methods
    
    private func applyRetentionPolicy(to data: [HealthDataPoint], interval: TimeInterval) -> [HealthDataPoint] {
        let cutoffDate = Date().addingTimeInterval(-interval)
        return data.filter { $0.startDate >= cutoffDate }
    }
    
    private func excludeSensitiveData(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.filter { !sensitiveDataTypes.contains($0.dataType) }
    }
    
    private func anonymizePersonalInformation(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { dataPoint in
            let anonymizedId = generateAnonymizedId(from: dataPoint.id)
            let anonymizedSource = anonymizeSource(dataPoint.source)
            let filteredMetadata = filterPersonalMetadata(dataPoint.metadata)
            
            return HealthDataPoint(
                id: anonymizedId,
                dataType: dataPoint.dataType,
                value: dataPoint.value,
                unit: dataPoint.unit,
                startDate: dataPoint.startDate,
                endDate: dataPoint.endDate,
                source: anonymizedSource,
                device: nil, // Remove device information
                metadata: filteredMetadata
            )
        }
    }
    
    private func removeLocationData(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { dataPoint in
            let filteredMetadata = dataPoint.metadata.filter { key, _ in
                !key.localizedCaseInsensitiveContains("location") &&
                !key.localizedCaseInsensitiveContains("coordinate") &&
                !key.localizedCaseInsensitiveContains("altitude")
            }
            
            return HealthDataPoint(
                id: dataPoint.id,
                dataType: dataPoint.dataType,
                value: dataPoint.value,
                unit: dataPoint.unit,
                startDate: dataPoint.startDate,
                endDate: dataPoint.endDate,
                source: dataPoint.source,
                device: dataPoint.device,
                metadata: filteredMetadata
            )
        }
    }
    
    private func removeDeviceIdentifiers(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { dataPoint in
            let filteredMetadata = dataPoint.metadata.filter { key, _ in
                !personalIdentifiers.contains(key)
            }
            
            let anonymizedDevice = dataPoint.device?.components(separatedBy: " ").first ?? "Unknown Device"
            
            return HealthDataPoint(
                id: dataPoint.id,
                dataType: dataPoint.dataType,
                value: dataPoint.value,
                unit: dataPoint.unit,
                startDate: dataPoint.startDate,
                endDate: dataPoint.endDate,
                source: dataPoint.source,
                device: anonymizedDevice,
                metadata: filteredMetadata
            )
        }
    }
    
    private func removeSourceApplications(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { dataPoint in
            let genericSource = categorizeSource(dataPoint.source)
            
            return HealthDataPoint(
                id: dataPoint.id,
                dataType: dataPoint.dataType,
                value: dataPoint.value,
                unit: dataPoint.unit,
                startDate: dataPoint.startDate,
                endDate: dataPoint.endDate,
                source: genericSource,
                device: dataPoint.device,
                metadata: dataPoint.metadata
            )
        }
    }
    
    private func hashIdentifiers(_ data: [HealthDataPoint]) -> [HealthDataPoint] {
        return data.map { dataPoint in
            let hashedId = hashString(dataPoint.id)
            
            return HealthDataPoint(
                id: hashedId,
                dataType: dataPoint.dataType,
                value: dataPoint.value,
                unit: dataPoint.unit,
                startDate: dataPoint.startDate,
                endDate: dataPoint.endDate,
                source: dataPoint.source,
                device: dataPoint.device,
                metadata: dataPoint.metadata
            )
        }
    }
    
    private func aggregateData(_ data: [HealthDataPoint], period: TimeInterval) -> [HealthDataPoint] {
        let groupedData = Dictionary(grouping: data) { dataPoint in
            let timeSlot = floor(dataPoint.startDate.timeIntervalSince1970 / period) * period
            return "\(dataPoint.dataType.rawValue)_\(timeSlot)"
        }
        
        return groupedData.compactMap { _, points in
            guard !points.isEmpty else { return nil }
            
            let firstPoint = points[0]
            let aggregatedValue = points.map { $0.value }.reduce(0, +) / Double(points.count)
            let startDate = points.map { $0.startDate }.min() ?? firstPoint.startDate
            let endDate = points.map { $0.endDate }.max() ?? firstPoint.endDate
            
            return HealthDataPoint(
                id: UUID().uuidString,
                dataType: firstPoint.dataType,
                value: aggregatedValue,
                unit: firstPoint.unit,
                startDate: startDate,
                endDate: endDate,
                source: "Aggregated Data",
                device: nil,
                metadata: ["aggregated_count": "\(points.count)"]
            )
        }
    }
    
    private func addStatisticalNoise(to data: [HealthDataPoint], level: NoiseLevel) -> [HealthDataPoint] {
        let variance = level.variancePercentage
        
        return data.map { dataPoint in
            let noiseFactor = 1.0 + Double.random(in: -variance...variance)
            let noisyValue = max(0, dataPoint.value * noiseFactor) // Ensure non-negative values
            
            return HealthDataPoint(
                id: dataPoint.id,
                dataType: dataPoint.dataType,
                value: noisyValue,
                unit: dataPoint.unit,
                startDate: dataPoint.startDate,
                endDate: dataPoint.endDate,
                source: dataPoint.source,
                device: dataPoint.device,
                metadata: dataPoint.metadata
            )
        }
    }
    
    // MARK: - Utility Methods
    
    private func generateAnonymizedId(from originalId: String) -> String {
        return hashString(originalId + anonymizationSeed).prefix(16).description
    }
    
    private func anonymizeSource(_ source: String) -> String {
        return categorizeSource(source) + " (Anonymized)"
    }
    
    private func categorizeSource(_ source: String) -> String {
        let lowercaseSource = source.lowercased()
        
        if lowercaseSource.contains("health") || lowercaseSource.contains("apple") {
            return "System Health App"
        } else if lowercaseSource.contains("watch") {
            return "Wearable Device"
        } else if lowercaseSource.contains("fitness") || lowercaseSource.contains("workout") {
            return "Fitness App"
        } else if lowercaseSource.contains("medical") || lowercaseSource.contains("doctor") {
            return "Medical App"
        } else {
            return "Third-party App"
        }
    }
    
    private func filterPersonalMetadata(_ metadata: [String: String]) -> [String: String] {
        return metadata.filter { key, _ in
            !personalIdentifiers.contains(key) &&
            !key.localizedCaseInsensitiveContains("name") &&
            !key.localizedCaseInsensitiveContains("id") &&
            !key.localizedCaseInsensitiveContains("serial")
        }
    }
    
    private func hashString(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func calculateComplianceLevel(_ configuration: PrivacyConfiguration) -> PrivacyComplianceLevel {
        var score = 0
        
        if configuration.anonymizePersonalInfo { score += 3 }
        if configuration.excludeSensitiveDataTypes { score += 2 }
        if configuration.removeLocationData { score += 2 }
        if configuration.removeDeviceIdentifiers { score += 2 }
        if configuration.hashIdentifiers { score += 1 }
        if configuration.noiseLevel != .none { score += 1 }
        if configuration.retentionPolicy != .keepAll { score += 1 }
        
        switch score {
        case 0...3: return .basic
        case 4...7: return .enhanced
        case 8...10: return .strict
        default: return .maximum
        }
    }
    
    // MARK: - Privacy Validation
    
    struct PrivacyValidationResult {
        let isCompliant: Bool
        let complianceLevel: PrivacyComplianceLevel
        let issues: [String]
        let recommendations: [String]
    }
    
    enum PrivacyComplianceLevel: String, CaseIterable {
        case basic = "Basic"
        case enhanced = "Enhanced"
        case strict = "Strict"
        case maximum = "Maximum"
        
        var description: String {
            switch self {
            case .basic:
                return "Basic privacy protections applied"
            case .enhanced:
                return "Enhanced privacy with anonymization"
            case .strict:
                return "Strict privacy with comprehensive protection"
            case .maximum:
                return "Maximum privacy with full anonymization"
            }
        }
        
        var color: String {
            switch self {
            case .basic: return "orange"
            case .enhanced: return "blue"
            case .strict: return "green"
            case .maximum: return "purple"
            }
        }
    }
    
    // MARK: - Privacy Metrics
    
    func calculatePrivacyMetrics(for data: [HealthDataPoint], configuration: PrivacyConfiguration) -> PrivacyMetrics {
        let originalCount = data.count
        let processedData = applyPrivacySettings(to: data, configuration: configuration)
        let processedCount = processedData.count
        
        let retentionRate = originalCount > 0 ? Double(processedCount) / Double(originalCount) : 0
        let anonymizationRate = configuration.anonymizePersonalInfo ? 1.0 : 0.0
        let sensitiveDataRemovalRate = configuration.excludeSensitiveDataTypes ? 1.0 : 0.0
        
        return PrivacyMetrics(
            originalRecordCount: originalCount,
            processedRecordCount: processedCount,
            retentionRate: retentionRate,
            anonymizationRate: anonymizationRate,
            sensitiveDataRemovalRate: sensitiveDataRemovalRate,
            complianceLevel: calculateComplianceLevel(configuration)
        )
    }
    
    struct PrivacyMetrics {
        let originalRecordCount: Int
        let processedRecordCount: Int
        let retentionRate: Double
        let anonymizationRate: Double
        let sensitiveDataRemovalRate: Double
        let complianceLevel: PrivacyComplianceLevel
        
        var recordsRemoved: Int {
            return originalRecordCount - processedRecordCount
        }
        
        var retentionPercentage: Int {
            return Int(retentionRate * 100)
        }
    }
}

// MARK: - Privacy Extensions

@available(iOS 14.0, *)
extension ExportPrivacySettings {
    /// Convert to privacy manager configuration
    func toPrivacyConfiguration() -> ExportPrivacyManager.PrivacyConfiguration {
        return ExportPrivacyManager.PrivacyConfiguration(
            anonymizePersonalInfo: anonymizeData,
            excludeSensitiveDataTypes: excludeSensitiveData,
            removeLocationData: anonymizeData, // Implied by anonymization
            removeDeviceIdentifiers: !includeDeviceInfo,
            removeSourceApplications: anonymizeData,
            hashIdentifiers: anonymizeData,
            minimumAggregationPeriod: nil,
            noiseLevel: anonymizeData ? .low : .none,
            retentionPolicy: .keepAll
        )
    }
    
    /// Create privacy settings from configuration
    static func from(configuration: ExportPrivacyManager.PrivacyConfiguration) -> ExportPrivacySettings {
        return ExportPrivacySettings(
            anonymizeData: configuration.anonymizePersonalInfo,
            excludeSensitiveData: configuration.excludeSensitiveDataTypes,
            includeMetadata: !configuration.anonymizePersonalInfo,
            includeDeviceInfo: !configuration.removeDeviceIdentifiers
        )
    }
}

@available(iOS 14.0, *)
extension HealthDataPoint {
    /// Check if data point contains sensitive information
    var containsSensitiveInformation: Bool {
        let sensitiveTypes: Set<HealthDataType> = [
            .medicalRecords, .immunizations, .allergies, .medications,
            .mood, .anxiety, .depression, .mindfulSession
        ]
        return sensitiveTypes.contains(dataType)
    }
    
    /// Check if data point contains personal identifiers
    var containsPersonalIdentifiers: Bool {
        let personalKeys = [
            "HKMetadataKeyDeviceSerialNumber",
            "HKMetadataKeyExternalUUID",
            "HKMetadataKeyUserMotionContext"
        ]
        
        return metadata.keys.contains { key in
            personalKeys.contains(key) ||
            key.localizedCaseInsensitiveContains("name") ||
            key.localizedCaseInsensitiveContains("id")
        }
    }
}