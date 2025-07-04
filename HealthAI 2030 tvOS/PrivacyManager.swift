import SwiftUI
import Foundation
import CryptoKit
import CloudKit

@available(tvOS 18.0, *)
class PrivacyManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var privacySettings: PrivacySettings = PrivacySettings()
    @Published var dataProcessingConsent: DataProcessingConsent = DataProcessingConsent()
    @Published var encryptionStatus: EncryptionStatus = EncryptionStatus()
    @Published var dataRetentionSettings: DataRetentionSettings = DataRetentionSettings()
    @Published var sharingPermissions: SharingPermissions = SharingPermissions()
    
    // MARK: - Private Properties
    
    private let keychain = KeychainManager()
    private let encryptionService = BiometricDataEncryption()
    private let auditLogger = PrivacyAuditLogger()
    private let dataMinimizer = DataMinimizationService()
    
    // Data processing tracking
    private var dataAccessLog: [DataAccessEvent] = []
    private var consentHistory: [ConsentEvent] = []
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        loadPrivacySettings()
        setupPrivacyCompliance()
    }
    
    // MARK: - Setup Methods
    
    private func loadPrivacySettings() {
        // Load saved privacy settings
        if let savedSettings = UserDefaults.standard.data(forKey: "PrivacySettings") {
            do {
                privacySettings = try JSONDecoder().decode(PrivacySettings.self, from: savedSettings)
            } catch {
                print("Failed to load privacy settings: \(error)")
                privacySettings = PrivacySettings()
            }
        }
        
        // Load consent history
        loadConsentHistory()
        
        // Load data retention settings
        loadDataRetentionSettings()
    }
    
    private func setupPrivacyCompliance() {
        // Initialize encryption
        encryptionService.initializeEncryption()
        
        // Setup data retention monitoring
        setupDataRetentionMonitoring()
        
        // Setup privacy audit logging
        auditLogger.startAuditLogging()
    }
    
    // MARK: - Consent Management
    
    func requestDataProcessingConsent(for dataType: BiometricDataType) async -> Bool {
        let consentRequest = ConsentRequest(
            dataType: dataType,
            purpose: dataType.primaryPurpose,
            timestamp: Date()
        )
        
        // Present consent UI and wait for user response
        let userConsent = await presentConsentUI(for: consentRequest)
        
        if userConsent {
            // Record consent
            recordConsent(for: dataType, granted: true)
            
            // Update privacy settings
            updateConsentSettings(for: dataType, granted: true)
        } else {
            // Record consent denial
            recordConsent(for: dataType, granted: false)
        }
        
        return userConsent
    }
    
    func revokeConsent(for dataType: BiometricDataType) {
        // Record consent revocation
        recordConsent(for: dataType, granted: false)
        
        // Update privacy settings
        updateConsentSettings(for: dataType, granted: false)
        
        // Delete associated data
        Task {
            await deleteDataForType(dataType)
        }
        
        // Log revocation
        auditLogger.logConsentRevocation(dataType: dataType)
    }
    
    private func recordConsent(for dataType: BiometricDataType, granted: Bool) {
        let consentEvent = ConsentEvent(
            dataType: dataType,
            consentGranted: granted,
            timestamp: Date(),
            version: "3.0"
        )
        
        consentHistory.append(consentEvent)
        saveConsentHistory()
        
        // Update consent status
        switch dataType {
        case .heartRate:
            dataProcessingConsent.heartRateConsent = granted
        case .hrv:
            dataProcessingConsent.hrvConsent = granted
        case .stressLevel:
            dataProcessingConsent.stressConsent = granted
        case .sleepData:
            dataProcessingConsent.sleepConsent = granted
        case .activityData:
            dataProcessingConsent.activityConsent = granted
        case .biometricAnalytics:
            dataProcessingConsent.analyticsConsent = granted
        }
        
        savePrivacySettings()
    }
    
    private func updateConsentSettings(for dataType: BiometricDataType, granted: Bool) {
        switch dataType {
        case .heartRate:
            privacySettings.allowHeartRateCollection = granted
        case .hrv:
            privacySettings.allowHRVCollection = granted
        case .stressLevel:
            privacySettings.allowStressCollection = granted
        case .sleepData:
            privacySettings.allowSleepCollection = granted
        case .activityData:
            privacySettings.allowActivityCollection = granted
        case .biometricAnalytics:
            privacySettings.allowAnalytics = granted
        }
        
        savePrivacySettings()
    }
    
    // MARK: - Data Encryption
    
    func encryptBiometricData<T: Codable>(_ data: T, dataType: BiometricDataType) async -> EncryptedBiometricData? {
        guard hasConsent(for: dataType) else {
            auditLogger.logUnauthorizedDataAccess(dataType: dataType)
            return nil
        }
        
        // Log data access
        logDataAccess(dataType: dataType, operation: .encrypt)
        
        return await encryptionService.encrypt(data, for: dataType)
    }
    
    func decryptBiometricData<T: Codable>(_ encryptedData: EncryptedBiometricData, as type: T.Type) async -> T? {
        guard hasConsent(for: encryptedData.dataType) else {
            auditLogger.logUnauthorizedDataAccess(dataType: encryptedData.dataType)
            return nil
        }
        
        // Log data access
        logDataAccess(dataType: encryptedData.dataType, operation: .decrypt)
        
        return await encryptionService.decrypt(encryptedData, as: type)
    }
    
    // MARK: - Data Sharing
    
    func requestDataSharingPermission(for purpose: DataSharingPurpose) async -> Bool {
        // Check if permission already granted
        if hasDataSharingPermission(for: purpose) {
            return true
        }
        
        // Request permission from user
        let permission = await presentDataSharingConsentUI(for: purpose)
        
        if permission {
            grantDataSharingPermission(for: purpose)
        }
        
        auditLogger.logDataSharingRequest(purpose: purpose, granted: permission)
        
        return permission
    }
    
    func shareEncryptedData(_ data: EncryptedBiometricData, for purpose: DataSharingPurpose) async -> Bool {
        guard hasDataSharingPermission(for: purpose) else {
            auditLogger.logUnauthorizedDataSharing(purpose: purpose)
            return false
        }
        
        // Apply data minimization
        let minimizedData = await dataMinimizer.minimizeData(data, for: purpose)
        
        // Log data sharing
        auditLogger.logDataSharing(dataType: data.dataType, purpose: purpose)
        
        // Perform the actual sharing (implementation depends on the specific sharing mechanism)
        return await performDataSharing(minimizedData, for: purpose)
    }
    
    // MARK: - Data Retention
    
    func setupDataRetentionMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.performDataRetentionCleanup()
        }
    }
    
    private func performDataRetentionCleanup() {
        Task {
            for dataType in BiometricDataType.allCases {
                await cleanupExpiredData(for: dataType)
            }
        }
    }
    
    private func cleanupExpiredData(for dataType: BiometricDataType) async {
        let retentionPeriod = dataRetentionSettings.retentionPeriod(for: dataType)
        let cutoffDate = Date().addingTimeInterval(-retentionPeriod)
        
        // Delete data older than retention period
        await deleteDataOlderThan(cutoffDate, for: dataType)
        
        auditLogger.logDataRetentionCleanup(dataType: dataType, cutoffDate: cutoffDate)
    }
    
    // MARK: - Privacy Controls
    
    func enableDataMinimization(for dataType: BiometricDataType) {
        privacySettings.enableDataMinimization(for: dataType)
        savePrivacySettings()
        
        auditLogger.logPrivacySettingChange(setting: "DataMinimization", dataType: dataType, enabled: true)
    }
    
    func setDataRetentionPeriod(_ period: TimeInterval, for dataType: BiometricDataType) {
        dataRetentionSettings.setRetentionPeriod(period, for: dataType)
        saveDataRetentionSettings()
        
        auditLogger.logRetentionPeriodChange(dataType: dataType, newPeriod: period)
    }
    
    func enableOnDeviceProcessingOnly(for dataType: BiometricDataType) {
        privacySettings.enableOnDeviceOnly(for: dataType)
        savePrivacySettings()
        
        auditLogger.logPrivacySettingChange(setting: "OnDeviceOnly", dataType: dataType, enabled: true)
    }
    
    // MARK: - Compliance Verification
    
    func verifyPrivacyCompliance() -> PrivacyComplianceReport {
        var report = PrivacyComplianceReport()
        
        // Check consent validity
        report.consentCompliance = verifyConsentCompliance()
        
        // Check data minimization
        report.dataMinimizationCompliance = verifyDataMinimizationCompliance()
        
        // Check encryption status
        report.encryptionCompliance = verifyEncryptionCompliance()
        
        // Check data retention
        report.dataRetentionCompliance = verifyDataRetentionCompliance()
        
        // Check audit logging
        report.auditLoggingCompliance = verifyAuditLoggingCompliance()
        
        return report
    }
    
    // MARK: - Data Access Logging
    
    private func logDataAccess(dataType: BiometricDataType, operation: DataOperation) {
        let accessEvent = DataAccessEvent(
            dataType: dataType,
            operation: operation,
            timestamp: Date(),
            purpose: operation.purpose
        )
        
        dataAccessLog.append(accessEvent)
        
        // Keep only recent access events
        if dataAccessLog.count > 1000 {
            dataAccessLog.removeFirst(dataAccessLog.count - 1000)
        }
        
        auditLogger.logDataAccess(event: accessEvent)
    }
    
    // MARK: - Helper Methods
    
    private func hasConsent(for dataType: BiometricDataType) -> Bool {
        switch dataType {
        case .heartRate:
            return dataProcessingConsent.heartRateConsent
        case .hrv:
            return dataProcessingConsent.hrvConsent
        case .stressLevel:
            return dataProcessingConsent.stressConsent
        case .sleepData:
            return dataProcessingConsent.sleepConsent
        case .activityData:
            return dataProcessingConsent.activityConsent
        case .biometricAnalytics:
            return dataProcessingConsent.analyticsConsent
        }
    }
    
    private func hasDataSharingPermission(for purpose: DataSharingPurpose) -> Bool {
        switch purpose {
        case .groupSessions:
            return sharingPermissions.allowGroupSharing
        case .healthResearch:
            return sharingPermissions.allowResearchSharing
        case .crossDeviceSync:
            return sharingPermissions.allowCrossDeviceSync
        case .emergencyServices:
            return sharingPermissions.allowEmergencySharing
        }
    }
    
    private func grantDataSharingPermission(for purpose: DataSharingPurpose) {
        switch purpose {
        case .groupSessions:
            sharingPermissions.allowGroupSharing = true
        case .healthResearch:
            sharingPermissions.allowResearchSharing = true
        case .crossDeviceSync:
            sharingPermissions.allowCrossDeviceSync = true
        case .emergencyServices:
            sharingPermissions.allowEmergencySharing = true
        }
        
        saveSharingPermissions()
    }
    
    // MARK: - Persistence
    
    private func savePrivacySettings() {
        do {
            let data = try JSONEncoder().encode(privacySettings)
            UserDefaults.standard.set(data, forKey: "PrivacySettings")
        } catch {
            print("Failed to save privacy settings: \(error)")
        }
    }
    
    private func saveConsentHistory() {
        do {
            let data = try JSONEncoder().encode(consentHistory)
            UserDefaults.standard.set(data, forKey: "ConsentHistory")
        } catch {
            print("Failed to save consent history: \(error)")
        }
    }
    
    private func loadConsentHistory() {
        if let data = UserDefaults.standard.data(forKey: "ConsentHistory") {
            do {
                consentHistory = try JSONDecoder().decode([ConsentEvent].self, from: data)
            } catch {
                print("Failed to load consent history: \(error)")
            }
        }
    }
    
    private func saveDataRetentionSettings() {
        do {
            let data = try JSONEncoder().encode(dataRetentionSettings)
            UserDefaults.standard.set(data, forKey: "DataRetentionSettings")
        } catch {
            print("Failed to save data retention settings: \(error)")
        }
    }
    
    private func loadDataRetentionSettings() {
        if let data = UserDefaults.standard.data(forKey: "DataRetentionSettings") {
            do {
                dataRetentionSettings = try JSONDecoder().decode(DataRetentionSettings.self, from: data)
            } catch {
                print("Failed to load data retention settings: \(error)")
            }
        }
    }
    
    private func saveSharingPermissions() {
        do {
            let data = try JSONEncoder().encode(sharingPermissions)
            UserDefaults.standard.set(data, forKey: "SharingPermissions")
        } catch {
            print("Failed to save sharing permissions: \(error)")
        }
    }
    
    // MARK: - UI Presentation (Placeholders)
    
    private func presentConsentUI(for request: ConsentRequest) async -> Bool {
        // This would present a detailed consent UI
        // For now, return a simulated response
        return true
    }
    
    private func presentDataSharingConsentUI(for purpose: DataSharingPurpose) async -> Bool {
        // This would present a data sharing consent UI
        // For now, return a simulated response
        return true
    }
    
    // MARK: - Data Operations (Placeholders)
    
    private func deleteDataForType(_ dataType: BiometricDataType) async {
        // Implementation would delete all data of the specified type
        auditLogger.logDataDeletion(dataType: dataType)
    }
    
    private func deleteDataOlderThan(_ date: Date, for dataType: BiometricDataType) async {
        // Implementation would delete data older than the specified date
        auditLogger.logDataRetentionCleanup(dataType: dataType, cutoffDate: date)
    }
    
    private func performDataSharing(_ data: EncryptedBiometricData, for purpose: DataSharingPurpose) async -> Bool {
        // Implementation would perform the actual data sharing
        return true
    }
    
    // MARK: - Compliance Verification Methods
    
    private func verifyConsentCompliance() -> Bool {
        // Verify that all data collection has valid consent
        return true // Simplified for example
    }
    
    private func verifyDataMinimizationCompliance() -> Bool {
        // Verify that data minimization is properly implemented
        return true // Simplified for example
    }
    
    private func verifyEncryptionCompliance() -> Bool {
        // Verify that all sensitive data is encrypted
        return encryptionService.isEncryptionEnabled()
    }
    
    private func verifyDataRetentionCompliance() -> Bool {
        // Verify that data retention policies are being followed
        return true // Simplified for example
    }
    
    private func verifyAuditLoggingCompliance() -> Bool {
        // Verify that audit logging is functioning
        return auditLogger.isLoggingEnabled()
    }
}

// MARK: - Supporting Types

enum BiometricDataType: String, CaseIterable, Codable {
    case heartRate = "heartRate"
    case hrv = "hrv"
    case stressLevel = "stressLevel"
    case sleepData = "sleepData"
    case activityData = "activityData"
    case biometricAnalytics = "biometricAnalytics"
    
    var primaryPurpose: String {
        switch self {
        case .heartRate: return "Real-time heart rate monitoring for health insights"
        case .hrv: return "Heart rate variability analysis for stress and recovery tracking"
        case .stressLevel: return "Stress level monitoring for wellness recommendations"
        case .sleepData: return "Sleep quality analysis for better rest optimization"
        case .activityData: return "Physical activity tracking for fitness goals"
        case .biometricAnalytics: return "Aggregated health analytics for personalized insights"
        }
    }
}

enum DataSharingPurpose: String, CaseIterable, Codable {
    case groupSessions = "groupSessions"
    case healthResearch = "healthResearch"
    case crossDeviceSync = "crossDeviceSync"
    case emergencyServices = "emergencyServices"
}

enum DataOperation: String, Codable {
    case collect = "collect"
    case process = "process"
    case store = "store"
    case encrypt = "encrypt"
    case decrypt = "decrypt"
    case share = "share"
    case delete = "delete"
    
    var purpose: String {
        switch self {
        case .collect: return "Data collection for health monitoring"
        case .process: return "Data processing for health insights"
        case .store: return "Data storage for historical analysis"
        case .encrypt: return "Data encryption for security"
        case .decrypt: return "Data decryption for processing"
        case .share: return "Data sharing for specified purposes"
        case .delete: return "Data deletion for privacy compliance"
        }
    }
}

struct PrivacySettings: Codable {
    var allowHeartRateCollection: Bool = false
    var allowHRVCollection: Bool = false
    var allowStressCollection: Bool = false
    var allowSleepCollection: Bool = false
    var allowActivityCollection: Bool = false
    var allowAnalytics: Bool = false
    var enableDataMinimizationForHeartRate: Bool = true
    var enableDataMinimizationForHRV: Bool = true
    var enableDataMinimizationForStress: Bool = true
    var enableOnDeviceOnlyForHeartRate: Bool = false
    var enableOnDeviceOnlyForHRV: Bool = false
    var enableOnDeviceOnlyForStress: Bool = false
    
    mutating func enableDataMinimization(for dataType: BiometricDataType) {
        switch dataType {
        case .heartRate:
            enableDataMinimizationForHeartRate = true
        case .hrv:
            enableDataMinimizationForHRV = true
        case .stressLevel:
            enableDataMinimizationForStress = true
        default:
            break
        }
    }
    
    mutating func enableOnDeviceOnly(for dataType: BiometricDataType) {
        switch dataType {
        case .heartRate:
            enableOnDeviceOnlyForHeartRate = true
        case .hrv:
            enableOnDeviceOnlyForHRV = true
        case .stressLevel:
            enableOnDeviceOnlyForStress = true
        default:
            break
        }
    }
}

struct DataProcessingConsent: Codable {
    var heartRateConsent: Bool = false
    var hrvConsent: Bool = false
    var stressConsent: Bool = false
    var sleepConsent: Bool = false
    var activityConsent: Bool = false
    var analyticsConsent: Bool = false
}

struct EncryptionStatus: Codable {
    var isEnabled: Bool = true
    var encryptionMethod: String = "AES-256-GCM"
    var keyRotationEnabled: Bool = true
    var lastKeyRotation: Date = Date()
}

struct DataRetentionSettings: Codable {
    var heartRateRetentionDays: Int = 365
    var hrvRetentionDays: Int = 365
    var stressRetentionDays: Int = 90
    var sleepRetentionDays: Int = 730
    var activityRetentionDays: Int = 365
    var analyticsRetentionDays: Int = 30
    
    func retentionPeriod(for dataType: BiometricDataType) -> TimeInterval {
        let days: Int
        switch dataType {
        case .heartRate: days = heartRateRetentionDays
        case .hrv: days = hrvRetentionDays
        case .stressLevel: days = stressRetentionDays
        case .sleepData: days = sleepRetentionDays
        case .activityData: days = activityRetentionDays
        case .biometricAnalytics: days = analyticsRetentionDays
        }
        return TimeInterval(days * 24 * 60 * 60)
    }
    
    mutating func setRetentionPeriod(_ period: TimeInterval, for dataType: BiometricDataType) {
        let days = Int(period / (24 * 60 * 60))
        switch dataType {
        case .heartRate: heartRateRetentionDays = days
        case .hrv: hrvRetentionDays = days
        case .stressLevel: stressRetentionDays = days
        case .sleepData: sleepRetentionDays = days
        case .activityData: activityRetentionDays = days
        case .biometricAnalytics: analyticsRetentionDays = days
        }
    }
}

struct SharingPermissions: Codable {
    var allowGroupSharing: Bool = false
    var allowResearchSharing: Bool = false
    var allowCrossDeviceSync: Bool = false
    var allowEmergencySharing: Bool = true // Default to true for emergency scenarios
}

struct ConsentRequest {
    let dataType: BiometricDataType
    let purpose: String
    let timestamp: Date
}

struct ConsentEvent: Codable {
    let dataType: BiometricDataType
    let consentGranted: Bool
    let timestamp: Date
    let version: String
}

struct DataAccessEvent: Codable {
    let dataType: BiometricDataType
    let operation: DataOperation
    let timestamp: Date
    let purpose: String
}

struct EncryptedBiometricData: Codable {
    let dataType: BiometricDataType
    let encryptedData: Data
    let encryptionMetadata: EncryptionMetadata
    let timestamp: Date
}

struct EncryptionMetadata: Codable {
    let algorithm: String
    let keyIdentifier: String
    let nonce: Data
    let authenticationTag: Data
}

struct PrivacyComplianceReport {
    var consentCompliance: Bool = false
    var dataMinimizationCompliance: Bool = false
    var encryptionCompliance: Bool = false
    var dataRetentionCompliance: Bool = false
    var auditLoggingCompliance: Bool = false
    
    var overallCompliance: Bool {
        return consentCompliance && dataMinimizationCompliance && encryptionCompliance && dataRetentionCompliance && auditLoggingCompliance
    }
}

// MARK: - Supporting Services

class KeychainManager {
    func store(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    func retrieve(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}

class BiometricDataEncryption {
    private var encryptionKey: SymmetricKey?
    
    func initializeEncryption() {
        // Generate or retrieve encryption key
        if let keyData = retrieveEncryptionKey() {
            encryptionKey = SymmetricKey(data: keyData)
        } else {
            encryptionKey = SymmetricKey(size: .bits256)
            storeEncryptionKey()
        }
    }
    
    func encrypt<T: Codable>(_ data: T, for dataType: BiometricDataType) async -> EncryptedBiometricData? {
        guard let key = encryptionKey else { return nil }
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(jsonData, using: key, nonce: nonce)
            
            let metadata = EncryptionMetadata(
                algorithm: "AES-256-GCM",
                keyIdentifier: "main-key-v1",
                nonce: Data(nonce),
                authenticationTag: sealedBox.tag
            )
            
            return EncryptedBiometricData(
                dataType: dataType,
                encryptedData: sealedBox.ciphertext,
                encryptionMetadata: metadata,
                timestamp: Date()
            )
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decrypt<T: Codable>(_ encryptedData: EncryptedBiometricData, as type: T.Type) async -> T? {
        guard let key = encryptionKey else { return nil }
        
        do {
            let nonce = try AES.GCM.Nonce(data: encryptedData.encryptionMetadata.nonce)
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: encryptedData.encryptedData,
                tag: encryptedData.encryptionMetadata.authenticationTag
            )
            
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return try JSONDecoder().decode(type, from: decryptedData)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    func isEncryptionEnabled() -> Bool {
        return encryptionKey != nil
    }
    
    private func storeEncryptionKey() {
        guard let key = encryptionKey else { return }
        let keychain = KeychainManager()
        _ = keychain.store(key: "BiometricEncryptionKey", data: key.withUnsafeBytes { Data($0) })
    }
    
    private func retrieveEncryptionKey() -> Data? {
        let keychain = KeychainManager()
        return keychain.retrieve(key: "BiometricEncryptionKey")
    }
}

class PrivacyAuditLogger {
    private var isEnabled = true
    private var auditLog: [AuditLogEntry] = []
    
    func startAuditLogging() {
        isEnabled = true
    }
    
    func stopAuditLogging() {
        isEnabled = false
    }
    
    func isLoggingEnabled() -> Bool {
        return isEnabled
    }
    
    func logDataAccess(event: DataAccessEvent) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .dataAccess,
            description: "Data access: \(event.operation.rawValue) for \(event.dataType.rawValue)",
            timestamp: event.timestamp,
            metadata: ["operation": event.operation.rawValue, "dataType": event.dataType.rawValue]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logConsentRevocation(dataType: BiometricDataType) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .consentRevocation,
            description: "Consent revoked for \(dataType.rawValue)",
            timestamp: Date(),
            metadata: ["dataType": dataType.rawValue]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logDataSharing(dataType: BiometricDataType, purpose: DataSharingPurpose) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .dataSharing,
            description: "Data shared: \(dataType.rawValue) for \(purpose.rawValue)",
            timestamp: Date(),
            metadata: ["dataType": dataType.rawValue, "purpose": purpose.rawValue]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logUnauthorizedDataAccess(dataType: BiometricDataType) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .unauthorizedAccess,
            description: "Unauthorized access attempt for \(dataType.rawValue)",
            timestamp: Date(),
            metadata: ["dataType": dataType.rawValue]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logUnauthorizedDataSharing(purpose: DataSharingPurpose) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .unauthorizedSharing,
            description: "Unauthorized sharing attempt for \(purpose.rawValue)",
            timestamp: Date(),
            metadata: ["purpose": purpose.rawValue]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logDataSharingRequest(purpose: DataSharingPurpose, granted: Bool) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .dataSharingRequest,
            description: "Data sharing request for \(purpose.rawValue): \(granted ? "granted" : "denied")",
            timestamp: Date(),
            metadata: ["purpose": purpose.rawValue, "granted": String(granted)]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logDataDeletion(dataType: BiometricDataType) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .dataDeletion,
            description: "Data deleted for \(dataType.rawValue)",
            timestamp: Date(),
            metadata: ["dataType": dataType.rawValue]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logDataRetentionCleanup(dataType: BiometricDataType, cutoffDate: Date) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .dataRetentionCleanup,
            description: "Data retention cleanup for \(dataType.rawValue)",
            timestamp: Date(),
            metadata: ["dataType": dataType.rawValue, "cutoffDate": ISO8601DateFormatter().string(from: cutoffDate)]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logPrivacySettingChange(setting: String, dataType: BiometricDataType, enabled: Bool) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .privacySettingChange,
            description: "Privacy setting changed: \(setting) for \(dataType.rawValue) = \(enabled)",
            timestamp: Date(),
            metadata: ["setting": setting, "dataType": dataType.rawValue, "enabled": String(enabled)]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    func logRetentionPeriodChange(dataType: BiometricDataType, newPeriod: TimeInterval) {
        guard isEnabled else { return }
        
        let entry = AuditLogEntry(
            eventType: .retentionPeriodChange,
            description: "Retention period changed for \(dataType.rawValue) to \(Int(newPeriod / 86400)) days",
            timestamp: Date(),
            metadata: ["dataType": dataType.rawValue, "newPeriodDays": String(Int(newPeriod / 86400))]
        )
        
        auditLog.append(entry)
        saveAuditLog()
    }
    
    private func saveAuditLog() {
        // Keep only recent entries
        if auditLog.count > 10000 {
            auditLog.removeFirst(auditLog.count - 10000)
        }
        
        // In a production app, this would be saved securely
        do {
            let data = try JSONEncoder().encode(auditLog)
            UserDefaults.standard.set(data, forKey: "PrivacyAuditLog")
        } catch {
            print("Failed to save audit log: \(error)")
        }
    }
}

struct AuditLogEntry: Codable {
    let eventType: AuditEventType
    let description: String
    let timestamp: Date
    let metadata: [String: String]
}

enum AuditEventType: String, Codable {
    case dataAccess = "dataAccess"
    case consentRevocation = "consentRevocation"
    case dataSharing = "dataSharing"
    case unauthorizedAccess = "unauthorizedAccess"
    case unauthorizedSharing = "unauthorizedSharing"
    case dataSharingRequest = "dataSharingRequest"
    case dataDeletion = "dataDeletion"
    case dataRetentionCleanup = "dataRetentionCleanup"
    case privacySettingChange = "privacySettingChange"
    case retentionPeriodChange = "retentionPeriodChange"
}

class DataMinimizationService {
    func minimizeData(_ data: EncryptedBiometricData, for purpose: DataSharingPurpose) async -> EncryptedBiometricData {
        // Apply data minimization based on the sharing purpose
        // This would remove unnecessary fields and reduce precision
        return data // Simplified for example
    }
}

// MARK: - SwiftUI Privacy Settings View

@available(tvOS 18.0, *)
struct PrivacySettingsView: View {
    @StateObject private var privacyManager = PrivacyManager()
    @State private var showingComplianceReport = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("Privacy & Data Protection")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Control how your biometric data is collected, processed, and shared")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Data Collection Consent
                        DataCollectionConsentSection(privacyManager: privacyManager)
                        
                        // Data Sharing Permissions
                        DataSharingPermissionsSection(privacyManager: privacyManager)
                        
                        // Data Retention Settings
                        DataRetentionSection(privacyManager: privacyManager)
                        
                        // Privacy Controls
                        PrivacyControlsSection(privacyManager: privacyManager)
                    }
                }
                
                // Compliance Report Button
                Button("View Compliance Report") {
                    showingComplianceReport = true
                }
                .buttonStyle(PrivacyButtonStyle(color: .blue))
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingComplianceReport) {
            ComplianceReportView(privacyManager: privacyManager)
        }
    }
}

struct DataCollectionConsentSection: View {
    @ObservedObject var privacyManager: PrivacyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Data Collection Consent")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ConsentToggleRow(
                    title: "Heart Rate",
                    description: "Monitor heart rate for health insights",
                    isEnabled: privacyManager.dataProcessingConsent.heartRateConsent
                ) {
                    if privacyManager.dataProcessingConsent.heartRateConsent {
                        privacyManager.revokeConsent(for: .heartRate)
                    } else {
                        Task {
                            _ = await privacyManager.requestDataProcessingConsent(for: .heartRate)
                        }
                    }
                }
                
                ConsentToggleRow(
                    title: "Heart Rate Variability",
                    description: "Analyze HRV for stress and recovery tracking",
                    isEnabled: privacyManager.dataProcessingConsent.hrvConsent
                ) {
                    if privacyManager.dataProcessingConsent.hrvConsent {
                        privacyManager.revokeConsent(for: .hrv)
                    } else {
                        Task {
                            _ = await privacyManager.requestDataProcessingConsent(for: .hrv)
                        }
                    }
                }
                
                ConsentToggleRow(
                    title: "Stress Level",
                    description: "Monitor stress for wellness recommendations",
                    isEnabled: privacyManager.dataProcessingConsent.stressConsent
                ) {
                    if privacyManager.dataProcessingConsent.stressConsent {
                        privacyManager.revokeConsent(for: .stressLevel)
                    } else {
                        Task {
                            _ = await privacyManager.requestDataProcessingConsent(for: .stressLevel)
                        }
                    }
                }
                
                ConsentToggleRow(
                    title: "Sleep Data",
                    description: "Analyze sleep quality for better rest",
                    isEnabled: privacyManager.dataProcessingConsent.sleepConsent
                ) {
                    if privacyManager.dataProcessingConsent.sleepConsent {
                        privacyManager.revokeConsent(for: .sleepData)
                    } else {
                        Task {
                            _ = await privacyManager.requestDataProcessingConsent(for: .sleepData)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct DataSharingPermissionsSection: View {
    @ObservedObject var privacyManager: PrivacyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Data Sharing Permissions")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SharingToggleRow(
                    title: "Group Sessions",
                    description: "Share biometrics during group activities",
                    isEnabled: privacyManager.sharingPermissions.allowGroupSharing
                ) {
                    Task {
                        _ = await privacyManager.requestDataSharingPermission(for: .groupSessions)
                    }
                }
                
                SharingToggleRow(
                    title: "Cross-Device Sync",
                    description: "Sync data across your Apple devices",
                    isEnabled: privacyManager.sharingPermissions.allowCrossDeviceSync
                ) {
                    Task {
                        _ = await privacyManager.requestDataSharingPermission(for: .crossDeviceSync)
                    }
                }
                
                SharingToggleRow(
                    title: "Health Research",
                    description: "Contribute to health research studies",
                    isEnabled: privacyManager.sharingPermissions.allowResearchSharing
                ) {
                    Task {
                        _ = await privacyManager.requestDataSharingPermission(for: .healthResearch)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct DataRetentionSection: View {
    @ObservedObject var privacyManager: PrivacyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Data Retention")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                RetentionRow(
                    title: "Heart Rate Data",
                    currentPeriod: privacyManager.dataRetentionSettings.heartRateRetentionDays
                ) { newPeriod in
                    privacyManager.setDataRetentionPeriod(TimeInterval(newPeriod * 24 * 60 * 60), for: .heartRate)
                }
                
                RetentionRow(
                    title: "HRV Data",
                    currentPeriod: privacyManager.dataRetentionSettings.hrvRetentionDays
                ) { newPeriod in
                    privacyManager.setDataRetentionPeriod(TimeInterval(newPeriod * 24 * 60 * 60), for: .hrv)
                }
                
                RetentionRow(
                    title: "Stress Data",
                    currentPeriod: privacyManager.dataRetentionSettings.stressRetentionDays
                ) { newPeriod in
                    privacyManager.setDataRetentionPeriod(TimeInterval(newPeriod * 24 * 60 * 60), for: .stressLevel)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct PrivacyControlsSection: View {
    @ObservedObject var privacyManager: PrivacyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Privacy Controls")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PrivacyControlRow(
                    title: "Data Minimization",
                    description: "Reduce data precision when possible",
                    isEnabled: privacyManager.privacySettings.enableDataMinimizationForHeartRate
                ) {
                    privacyManager.enableDataMinimization(for: .heartRate)
                }
                
                PrivacyControlRow(
                    title: "On-Device Processing",
                    description: "Process data locally when possible",
                    isEnabled: privacyManager.privacySettings.enableOnDeviceOnlyForHeartRate
                ) {
                    privacyManager.enableOnDeviceProcessingOnly(for: .heartRate)
                }
                
                PrivacyControlRow(
                    title: "Encryption Status",
                    description: "All data encrypted with AES-256",
                    isEnabled: privacyManager.encryptionStatus.isEnabled
                ) {
                    // Encryption is always enabled
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ConsentToggleRow: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .toggleStyle(PrivacyToggleStyle(color: isEnabled ? .green : .gray))
                .onTapGesture {
                    onToggle()
                }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct SharingToggleRow: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isEnabled))
                .toggleStyle(PrivacyToggleStyle(color: isEnabled ? .blue : .gray))
                .onTapGesture {
                    onToggle()
                }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct RetentionRow: View {
    let title: String
    let currentPeriod: Int
    let onPeriodChange: (Int) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Current: \(currentPeriod) days")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Menu("\(currentPeriod) days") {
                Button("30 days") { onPeriodChange(30) }
                Button("90 days") { onPeriodChange(90) }
                Button("180 days") { onPeriodChange(180) }
                Button("365 days") { onPeriodChange(365) }
                Button("730 days") { onPeriodChange(730) }
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct PrivacyControlRow: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .red)
                .font(.title2)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ComplianceReportView: View {
    @ObservedObject var privacyManager: PrivacyManager
    @State private var complianceReport: PrivacyComplianceReport?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Privacy Compliance Report")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let report = complianceReport {
                VStack(spacing: 15) {
                    ComplianceRow(title: "Consent Compliance", isCompliant: report.consentCompliance)
                    ComplianceRow(title: "Data Minimization", isCompliant: report.dataMinimizationCompliance)
                    ComplianceRow(title: "Encryption", isCompliant: report.encryptionCompliance)
                    ComplianceRow(title: "Data Retention", isCompliant: report.dataRetentionCompliance)
                    ComplianceRow(title: "Audit Logging", isCompliant: report.auditLoggingCompliance)
                    
                    Divider()
                    
                    HStack {
                        Text("Overall Compliance")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: report.overallCompliance ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(report.overallCompliance ? .green : .red)
                            .font(.title)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            }
            
            Spacer()
            
            Button("Close") {
                // Dismiss view
            }
            .buttonStyle(PrivacyButtonStyle(color: .gray))
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .onAppear {
            complianceReport = privacyManager.verifyPrivacyCompliance()
        }
    }
}

struct ComplianceRow: View {
    let title: String
    let isCompliant: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: isCompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isCompliant ? .green : .red)
                .font(.title3)
        }
    }
}

struct PrivacyToggleStyle: ToggleStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(configuration.isOn ? color : Color.gray)
            .frame(width: 50, height: 30)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            )
    }
}

struct PrivacyButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.semibold)
            .frame(width: 200, height: 50)
            .background(color)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    PrivacySettingsView()
}