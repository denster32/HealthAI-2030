import Foundation
import CryptoKit
import Combine

/// Blockchain Data Sharing
/// Implements secure and controlled health data sharing using blockchain technology
/// Part of Agent 5's Month 2 Week 1-2 deliverables
@available(iOS 17.0, *)
public class BlockchainDataSharing: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var activeSharingAgreements: [DataSharingAgreement] = []
    @Published public var pendingRequests: [SharingRequest] = []
    @Published public var sharedDataRecords: [SharedDataRecord] = []
    @Published public var accessLogs: [AccessLog] = []
    
    // MARK: - Private Properties
    private var consentManager: ConsentManager?
    private var accessControl: AccessControl?
    private var dataEncryption: DataEncryption?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Data Sharing Types
    public struct DataSharingAgreement: Identifiable, Codable {
        public let id = UUID()
        public let agreementHash: String
        public let patientId: String
        public let recipientId: String
        public let dataTypes: [DataType]
        public let permissions: [Permission]
        public let startDate: Date
        public let endDate: Date?
        public let isActive: Bool
        public let signature: String
        public let blockNumber: UInt64
        
        public enum DataType: String, Codable, CaseIterable {
            case vitalSigns = "vital_signs"
            case medications = "medications"
            case diagnoses = "diagnoses"
            case labResults = "lab_results"
            case imaging = "imaging"
            case procedures = "procedures"
            case allergies = "allergies"
            case immunizations = "immunizations"
            case notes = "notes"
            case emergency = "emergency"
        }
        
        public enum Permission: String, Codable, CaseIterable {
            case read = "read"
            case write = "write"
            case share = "share"
            case delete = "delete"
            case emergency = "emergency"
        }
    }
    
    public struct SharingRequest: Identifiable, Codable {
        public let id = UUID()
        public let requestHash: String
        public let requesterId: String
        public let patientId: String
        public let requestedDataTypes: [DataSharingAgreement.DataType]
        public let requestedPermissions: [DataSharingAgreement.Permission]
        public let purpose: String
        public let urgency: Urgency
        public let timestamp: Date
        public let status: RequestStatus
        public let responseDate: Date?
        public let responseReason: String?
        
        public enum Urgency: String, Codable, CaseIterable {
            case routine = "routine"
            case urgent = "urgent"
            case emergency = "emergency"
        }
        
        public enum RequestStatus: String, Codable, CaseIterable {
            case pending = "pending"
            case approved = "approved"
            case denied = "denied"
            case expired = "expired"
            case cancelled = "cancelled"
        }
    }
    
    public struct SharedDataRecord: Identifiable, Codable {
        public let id = UUID()
        public let recordHash: String
        public let agreementId: String
        public let dataType: DataSharingAgreement.DataType
        public let encryptedData: String
        public let accessKey: String
        public let timestamp: Date
        public let accessedBy: String
        public let accessCount: Int
        public let lastAccessed: Date
    }
    
    public struct AccessLog: Identifiable, Codable {
        public let id = UUID()
        public let timestamp: Date
        public let userId: String
        public let action: AccessAction
        public let dataType: DataSharingAgreement.DataType?
        public let recordHash: String?
        public let ipAddress: String?
        public let deviceInfo: String?
        public let success: Bool
        public let reason: String?
        
        public enum AccessAction: String, Codable, CaseIterable {
            case view = "view"
            case download = "download"
            case share = "share"
            case modify = "modify"
            case delete = "delete"
            case request = "request"
            case approve = "approve"
            case deny = "deny"
        }
    }
    
    public struct ConsentManager {
        public let consentRecords: [String: ConsentRecord]
        public let consentTemplates: [ConsentTemplate]
        public let revocationList: [String]
        
        public struct ConsentRecord: Codable {
            public let patientId: String
            public let consentType: String
            public let grantedAt: Date
            public let revokedAt: Date?
            public let signature: String
        }
        
        public struct ConsentTemplate: Codable {
            public let templateId: String
            public let title: String
            public let description: String
            public let dataTypes: [DataSharingAgreement.DataType]
            public let permissions: [DataSharingAgreement.Permission]
            public let duration: TimeInterval
        }
    }
    
    public struct AccessControl {
        public let accessPolicies: [AccessPolicy]
        public let roleDefinitions: [RoleDefinition]
        public let permissionMatrix: [String: [String]]
        
        public struct AccessPolicy: Codable {
            public let policyId: String
            public let name: String
            public let rules: [AccessRule]
            public let priority: Int
        }
        
        public struct AccessRule: Codable {
            public let condition: String
            public let action: String
            public let effect: String
        }
        
        public struct RoleDefinition: Codable {
            public let roleId: String
            public let name: String
            public let permissions: [DataSharingAgreement.Permission]
            public let dataTypes: [DataSharingAgreement.DataType]
        }
    }
    
    public struct DataEncryption {
        public let encryptionAlgorithm: String
        public let keyManagement: KeyManagement
        public let encryptionLayers: [EncryptionLayer]
        
        public struct KeyManagement: Codable {
            public let keyRotationPeriod: TimeInterval
            public let keyStorage: String
            public let keyBackup: String
        }
        
        public struct EncryptionLayer: Codable {
            public let layerId: String
            public let algorithm: String
            public let keySize: Int
            public let purpose: String
        }
    }
    
    // MARK: - Initialization
    public init() {
        setupConsentManager()
        setupAccessControl()
        setupDataEncryption()
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Create a data sharing agreement
    public func createSharingAgreement(
        patientId: String,
        recipientId: String,
        dataTypes: [DataSharingAgreement.DataType],
        permissions: [DataSharingAgreement.Permission],
        duration: TimeInterval
    ) async throws -> DataSharingAgreement {
        // Validate consent
        try await validateConsent(patientId: patientId, dataTypes: dataTypes)
        
        // Create agreement
        let agreement = DataSharingAgreement(
            agreementHash: "",
            patientId: patientId,
            recipientId: recipientId,
            dataTypes: dataTypes,
            permissions: permissions,
            startDate: Date(),
            endDate: duration > 0 ? Date().addingTimeInterval(duration) : nil,
            isActive: true,
            signature: "",
            blockNumber: 0
        )
        
        // Sign agreement
        let signedAgreement = try await signAgreement(agreement)
        
        // Store on blockchain
        let storedAgreement = try await storeAgreementOnBlockchain(signedAgreement)
        
        // Add to active agreements
        activeSharingAgreements.append(storedAgreement)
        
        return storedAgreement
    }
    
    /// Request data sharing
    public func requestDataSharing(
        requesterId: String,
        patientId: String,
        dataTypes: [DataSharingAgreement.DataType],
        permissions: [DataSharingAgreement.Permission],
        purpose: String,
        urgency: SharingRequest.Urgency
    ) async throws -> SharingRequest {
        // Create request
        let request = SharingRequest(
            requestHash: "",
            requesterId: requesterId,
            patientId: patientId,
            requestedDataTypes: dataTypes,
            requestedPermissions: permissions,
            purpose: purpose,
            urgency: urgency,
            timestamp: Date(),
            status: .pending,
            responseDate: nil,
            responseReason: nil
        )
        
        // Validate request
        try await validateSharingRequest(request)
        
        // Store request
        let storedRequest = try await storeRequestOnBlockchain(request)
        
        // Add to pending requests
        pendingRequests.append(storedRequest)
        
        // Log access
        logAccess(
            userId: requesterId,
            action: .request,
            dataType: nil,
            recordHash: nil,
            success: true
        )
        
        return storedRequest
    }
    
    /// Approve sharing request
    public func approveSharingRequest(_ requestId: String, reason: String? = nil) async throws {
        guard let requestIndex = pendingRequests.firstIndex(where: { $0.id.uuidString == requestId }) else {
            throw DataSharingError.requestNotFound
        }
        
        var request = pendingRequests[requestIndex]
        request.status = .approved
        request.responseDate = Date()
        request.responseReason = reason
        
        // Create sharing agreement
        let agreement = try await createSharingAgreement(
            patientId: request.patientId,
            recipientId: request.requesterId,
            dataTypes: request.requestedDataTypes,
            permissions: request.requestedPermissions,
            duration: 0 // Permanent agreement
        )
        
        // Update request
        pendingRequests[requestIndex] = request
        
        // Log access
        logAccess(
            userId: "patient_\(request.patientId)",
            action: .approve,
            dataType: nil,
            recordHash: nil,
            success: true
        )
    }
    
    /// Deny sharing request
    public func denySharingRequest(_ requestId: String, reason: String) async throws {
        guard let requestIndex = pendingRequests.firstIndex(where: { $0.id.uuidString == requestId }) else {
            throw DataSharingError.requestNotFound
        }
        
        var request = pendingRequests[requestIndex]
        request.status = .denied
        request.responseDate = Date()
        request.responseReason = reason
        
        // Update request
        pendingRequests[requestIndex] = request
        
        // Log access
        logAccess(
            userId: "patient_\(request.patientId)",
            action: .deny,
            dataType: nil,
            recordHash: nil,
            success: true
        )
    }
    
    /// Share health data
    public func shareHealthData(
        agreementId: String,
        dataType: DataSharingAgreement.DataType,
        data: [String: Any]
    ) async throws -> SharedDataRecord {
        guard let agreement = activeSharingAgreements.first(where: { $0.id.uuidString == agreementId }) else {
            throw DataSharingError.agreementNotFound
        }
        
        // Validate permissions
        try validateDataSharingPermissions(agreement, dataType: dataType)
        
        // Encrypt data
        let encryptedData = try await encryptData(data)
        
        // Create shared record
        let record = SharedDataRecord(
            recordHash: "",
            agreementId: agreementId,
            dataType: dataType,
            encryptedData: encryptedData,
            accessKey: "",
            timestamp: Date(),
            accessedBy: agreement.recipientId,
            accessCount: 0,
            lastAccessed: Date()
        )
        
        // Store on blockchain
        let storedRecord = try await storeSharedRecordOnBlockchain(record)
        
        // Add to shared records
        sharedDataRecords.append(storedRecord)
        
        // Log access
        logAccess(
            userId: agreement.recipientId,
            action: .view,
            dataType: dataType,
            recordHash: storedRecord.recordHash,
            success: true
        )
        
        return storedRecord
    }
    
    /// Revoke sharing agreement
    public func revokeSharingAgreement(_ agreementId: String) async throws {
        guard let agreementIndex = activeSharingAgreements.firstIndex(where: { $0.id.uuidString == agreementId }) else {
            throw DataSharingError.agreementNotFound
        }
        
        var agreement = activeSharingAgreements[agreementIndex]
        agreement.isActive = false
        
        // Update on blockchain
        try await updateAgreementOnBlockchain(agreement)
        
        // Update local state
        activeSharingAgreements[agreementIndex] = agreement
        
        // Log access
        logAccess(
            userId: "patient_\(agreement.patientId)",
            action: .delete,
            dataType: nil,
            recordHash: nil,
            success: true
        )
    }
    
    /// Get sharing analytics
    public func getSharingAnalytics() -> [String: Any] {
        let totalAgreements = activeSharingAgreements.count
        let activeAgreements = activeSharingAgreements.filter { $0.isActive }.count
        let pendingRequests = self.pendingRequests.filter { $0.status == .pending }.count
        let totalSharedRecords = sharedDataRecords.count
        let totalAccessLogs = accessLogs.count
        
        return [
            "totalAgreements": totalAgreements,
            "activeAgreements": activeAgreements,
            "pendingRequests": pendingRequests,
            "totalSharedRecords": totalSharedRecords,
            "totalAccessLogs": totalAccessLogs,
            "sharingActivity": getSharingActivity()
        ]
    }
    
    // MARK: - Private Methods
    
    private func setupConsentManager() {
        consentManager = ConsentManager(
            consentRecords: [:],
            consentTemplates: [
                ConsentManager.ConsentTemplate(
                    templateId: "general_health",
                    title: "General Health Data Sharing",
                    description: "Allow sharing of general health information",
                    dataTypes: [.vitalSigns, .medications, .diagnoses],
                    permissions: [.read],
                    duration: 365 * 24 * 3600 // 1 year
                ),
                ConsentManager.ConsentTemplate(
                    templateId: "emergency_access",
                    title: "Emergency Data Access",
                    description: "Allow emergency access to critical health data",
                    dataTypes: [.emergency, .allergies, .medications],
                    permissions: [.read, .emergency],
                    duration: 0 // Permanent
                )
            ],
            revocationList: []
        )
    }
    
    private func setupAccessControl() {
        accessControl = AccessControl(
            accessPolicies: [
                AccessControl.AccessPolicy(
                    policyId: "patient_control",
                    name: "Patient Data Control",
                    rules: [
                        AccessControl.AccessRule(
                            condition: "patient_consent_required",
                            action: "allow",
                            effect: "permit"
                        )
                    ],
                    priority: 1
                )
            ],
            roleDefinitions: [
                AccessControl.RoleDefinition(
                    roleId: "healthcare_provider",
                    name: "Healthcare Provider",
                    permissions: [.read, .write],
                    dataTypes: [.vitalSigns, .medications, .diagnoses, .labResults]
                ),
                AccessControl.RoleDefinition(
                    roleId: "researcher",
                    name: "Researcher",
                    permissions: [.read],
                    dataTypes: [.vitalSigns, .labResults]
                )
            ],
            permissionMatrix: [:]
        )
    }
    
    private func setupDataEncryption() {
        dataEncryption = DataEncryption(
            encryptionAlgorithm: "AES-256-GCM",
            keyManagement: DataEncryption.KeyManagement(
                keyRotationPeriod: 30 * 24 * 3600, // 30 days
                keyStorage: "hardware_security_module",
                keyBackup: "encrypted_backup"
            ),
            encryptionLayers: [
                DataEncryption.EncryptionLayer(
                    layerId: "transport",
                    algorithm: "TLS_1_3",
                    keySize: 256,
                    purpose: "transport_security"
                ),
                DataEncryption.EncryptionLayer(
                    layerId: "storage",
                    algorithm: "AES_256_GCM",
                    keySize: 256,
                    purpose: "data_at_rest"
                )
            ]
        )
    }
    
    private func validateConsent(patientId: String, dataTypes: [DataSharingAgreement.DataType]) async throws {
        // Implementation for consent validation
        // This would check if patient has given consent for the requested data types
    }
    
    private func signAgreement(_ agreement: DataSharingAgreement) async throws -> DataSharingAgreement {
        // Implementation for agreement signing
        // This would create a cryptographic signature for the agreement
        return agreement
    }
    
    private func storeAgreementOnBlockchain(_ agreement: DataSharingAgreement) async throws -> DataSharingAgreement {
        // Implementation for storing agreement on blockchain
        // This would create a blockchain transaction with the agreement data
        return agreement
    }
    
    private func validateSharingRequest(_ request: SharingRequest) async throws {
        // Implementation for request validation
        // This would validate the request parameters and permissions
    }
    
    private func storeRequestOnBlockchain(_ request: SharingRequest) async throws -> SharingRequest {
        // Implementation for storing request on blockchain
        // This would create a blockchain transaction with the request data
        return request
    }
    
    private func validateDataSharingPermissions(_ agreement: DataSharingAgreement, dataType: DataSharingAgreement.DataType) throws {
        // Implementation for permission validation
        // This would check if the agreement allows sharing the specific data type
    }
    
    private func encryptData(_ data: [String: Any]) async throws -> String {
        // Implementation for data encryption
        // This would encrypt the data using the configured encryption layers
        return "encrypted_data"
    }
    
    private func storeSharedRecordOnBlockchain(_ record: SharedDataRecord) async throws -> SharedDataRecord {
        // Implementation for storing shared record on blockchain
        // This would create a blockchain transaction with the encrypted data
        return record
    }
    
    private func updateAgreementOnBlockchain(_ agreement: DataSharingAgreement) async throws {
        // Implementation for updating agreement on blockchain
        // This would create a blockchain transaction to update the agreement status
    }
    
    private func logAccess(
        userId: String,
        action: AccessLog.AccessAction,
        dataType: DataSharingAgreement.DataType?,
        recordHash: String?,
        success: Bool
    ) {
        let log = AccessLog(
            timestamp: Date(),
            userId: userId,
            action: action,
            dataType: dataType,
            recordHash: recordHash,
            ipAddress: nil,
            deviceInfo: nil,
            success: success,
            reason: nil
        )
        
        accessLogs.append(log)
    }
    
    private func getSharingActivity() -> [String: Int] {
        // Implementation for sharing activity analysis
        // This would analyze access logs to determine sharing patterns
        return [:]
    }
    
    private func setupBindings() {
        // Implementation for setting up reactive bindings
    }
}

// MARK: - Extensions

@available(iOS 17.0, *)
extension BlockchainDataSharing {
    
    /// Data sharing error types
    public enum DataSharingError: Error, LocalizedError {
        case agreementNotFound
        case requestNotFound
        case consentRequired
        case insufficientPermissions
        case encryptionFailed
        case blockchainError
        case validationFailed
        case accessDenied
        
        public var errorDescription: String? {
            switch self {
            case .agreementNotFound:
                return "Data sharing agreement not found"
            case .requestNotFound:
                return "Sharing request not found"
            case .consentRequired:
                return "Patient consent required for data sharing"
            case .insufficientPermissions:
                return "Insufficient permissions for data sharing"
            case .encryptionFailed:
                return "Data encryption failed"
            case .blockchainError:
                return "Blockchain operation failed"
            case .validationFailed:
                return "Data validation failed"
            case .accessDenied:
                return "Access denied to requested data"
            }
        }
    }
    
    /// Export sharing data for analysis
    public func exportSharingData() -> Data? {
        // Implementation for data export
        return nil
    }
    
    /// Get privacy compliance report
    public func getPrivacyComplianceReport() -> [String: Any] {
        // Implementation for privacy compliance reporting
        return [:]
    }
} 