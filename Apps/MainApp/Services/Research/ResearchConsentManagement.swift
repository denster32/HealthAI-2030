import Foundation
import SwiftUI
import HealthKit

/// Protocol defining the requirements for research consent management
protocol ResearchConsentProtocol {
    func requestConsent(for study: ResearchStudy) async throws -> ConsentResult
    func revokeConsent(for studyID: String) async throws -> ConsentResult
    func getConsentStatus(for studyID: String) async -> ConsentStatus
    func listActiveConsents() async -> [ConsentRecord]
}

/// Structure representing a research study
struct ResearchStudy: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let institution: String
    let durationDays: Int
    let dataTypes: [HKObjectType]
    let startDate: Date
    let endDate: Date?
    let termsURL: URL?
    let privacyPolicyURL: URL?
    
    init(id: String, title: String, description: String, institution: String, durationDays: Int, dataTypes: [HKObjectType], startDate: Date, endDate: Date? = nil, termsURL: URL? = nil, privacyPolicyURL: URL? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.institution = institution
        self.durationDays = durationDays
        self.dataTypes = dataTypes
        self.startDate = startDate
        self.endDate = endDate
        self.termsURL = termsURL
        self.privacyPolicyURL = privacyPolicyURL
    }
}

/// Structure representing a consent result
struct ConsentResult: Codable {
    let studyID: String
    let status: ConsentStatus
    let timestamp: Date
    let errorMessage: String?
    
    init(studyID: String, status: ConsentStatus, timestamp: Date = Date(), errorMessage: String? = nil) {
        self.studyID = studyID
        self.status = status
        self.timestamp = timestamp
        self.errorMessage = errorMessage
    }
}

/// Structure representing a consent record
struct ConsentRecord: Identifiable, Codable {
    let id: String
    let studyID: String
    let studyTitle: String
    let institution: String
    let consentDate: Date
    let expiryDate: Date?
    let dataTypes: [String]
    let status: ConsentStatus
    
    init(studyID: String, studyTitle: String, institution: String, consentDate: Date, expiryDate: Date?, dataTypes: [String], status: ConsentStatus) {
        self.id = UUID().uuidString
        self.studyID = studyID
        self.studyTitle = studyTitle
        self.institution = institution
        self.consentDate = consentDate
        self.expiryDate = expiryDate
        self.dataTypes = dataTypes
        self.status = status
    }
}

/// Enum representing consent status
enum ConsentStatus: String, Codable {
    case active
    case revoked
    case expired
    case pending
    case declined
}

/// Actor responsible for managing research consent
actor ResearchConsentManagement: ResearchConsentProtocol {
    private let store: ConsentStore
    private let notificationManager: ConsentNotificationManager
    private let logger: Logger
    private let healthStore: HKHealthStore
    
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.store = ConsentStore()
        self.notificationManager = ConsentNotificationManager()
        self.logger = Logger(subsystem: "com.healthai2030.research", category: "ConsentManagement")
        self.healthStore = healthStore
    }
    
    /// Requests consent for a research study
    /// - Parameter study: The research study to request consent for
    /// - Returns: ConsentResult indicating the outcome
    func requestConsent(for study: ResearchStudy) async throws -> ConsentResult {
        logger.info("Requesting consent for study: \(study.title)")
        
        // Check if consent already exists
        let existingStatus = await getConsentStatus(for: study.id)
        if existingStatus == .active {
            logger.warning("Consent already active for study: \(study.title)")
            return ConsentResult(studyID: study.id, status: .active, errorMessage: "Consent already granted")
        }
        
        // Request HealthKit authorization for required data types if needed
        let dataTypesToShare = Set(study.dataTypes)
        try await requestHealthKitAuthorization(for: dataTypesToShare)
        
        // Present consent UI (simulated here as an async operation)
        let userDecision = await presentConsentUI(for: study)
        
        guard userDecision else {
            logger.info("User declined consent for study: \(study.title)")
            let result = ConsentResult(studyID: study.id, status: .declined)
            await store.saveConsentResult(result)
            return result
        }
        
        // Record consent
        let expiryDate = Calendar.current.date(byAdding: .day, value: study.durationDays, to: Date())
        let dataTypeIdentifiers = study.dataTypes.map { $0.identifier }
        let consentRecord = ConsentRecord(
            studyID: study.id,
            studyTitle: study.title,
            institution: study.institution,
            consentDate: Date(),
            expiryDate: expiryDate,
            dataTypes: dataTypeIdentifiers,
            status: .active
        )
        
        await store.saveConsentRecord(consentRecord)
        
        // Notify user of active consent
        await notificationManager.scheduleConsentNotification(
            title: "Research Consent Granted",
            body: "You have granted consent for \(study.title) by \(study.institution)",
            studyID: study.id
        )
        
        logger.info("Consent granted for study: \(study.title)")
        return ConsentResult(studyID: study.id, status: .active)
    }
    
    /// Revokes consent for a research study
    /// - Parameter studyID: The ID of the study to revoke consent for
    /// - Returns: ConsentResult indicating the outcome
    func revokeConsent(for studyID: String) async throws -> ConsentResult {
        logger.info("Revoking consent for study ID: \(studyID)")
        
        let currentStatus = await getConsentStatus(for: studyID)
        guard currentStatus == .active else {
            logger.warning("Cannot revoke consent - current status is \(currentStatus.rawValue) for study ID: \(studyID)")
            return ConsentResult(
                studyID: studyID,
                status: currentStatus,
                errorMessage: "Consent cannot be revoked - current status is \(currentStatus.rawValue)"
            )
        }
        
        // Update consent record
        if var record = await store.getConsentRecord(for: studyID) {
            record.status = .revoked
            await store.saveConsentRecord(record)
        }
        
        // Notify user of revocation
        await notificationManager.scheduleConsentNotification(
            title: "Research Consent Revoked",
            body: "You have revoked consent for study ID: \(studyID)",
            studyID: studyID
        )
        
        logger.info("Consent revoked for study ID: \(studyID)")
        return ConsentResult(studyID: studyID, status: .revoked)
    }
    
    /// Gets the consent status for a specific study
    /// - Parameter studyID: The ID of the study to check
    /// - Returns: ConsentStatus for the study
    func getConsentStatus(for studyID: String) async -> ConsentStatus {
        if let record = await store.getConsentRecord(for: studyID) {
            // Check if consent has expired
            if let expiryDate = record.expiryDate, expiryDate < Date() {
                var updatedRecord = record
                updatedRecord.status = .expired
                await store.saveConsentRecord(updatedRecord)
                return .expired
            }
            return record.status
        }
        return .pending
    }
    
    /// Lists all active consent records
    /// - Returns: Array of ConsentRecord objects
    func listActiveConsents() async -> [ConsentRecord] {
        let allRecords = await store.getAllConsentRecords()
        let activeRecords = allRecords.filter { $0.status == .active }
        
        // Check for expired consents
        var updatedRecords = activeRecords
        for (index, record) in activeRecords.enumerated() {
            if let expiryDate = record.expiryDate, expiryDate < Date() {
                var expiredRecord = record
                expiredRecord.status = .expired
                updatedRecords[index] = expiredRecord
                await store.saveConsentRecord(expiredRecord)
            }
        }
        
        return updatedRecords.filter { $0.status == .active }
    }
    
    /// Requests HealthKit authorization for specific data types
    private func requestHealthKitAuthorization(for dataTypes: Set<HKObjectType>) async throws {
        logger.info("Requesting HealthKit authorization for \(dataTypes.count) data types")
        
        let typesToRead = dataTypes
        let typesToShare = dataTypes.compactMap { $0 as? HKSampleType }
        
        do {
            try await healthStore.requestAuthorization(toShare: Set(typesToShare), read: typesToRead)
            logger.info("HealthKit authorization granted for requested data types")
        } catch {
            logger.error("HealthKit authorization failed: \(error)")
            throw ConsentError.healthKitAuthorizationFailed(error.localizedDescription)
        }
    }
    
    /// Presents consent UI to the user (simulated)
    private func presentConsentUI(for study: ResearchStudy) async -> Bool {
        // In a real implementation, this would present a SwiftUI view
        // with study details and consent options
        logger.info("Presenting consent UI for study: \(study.title)")
        
        // Simulate user interaction (for demonstration, assume consent is granted)
        // In practice, this would await user input
        return true
    }
}

/// Class managing storage of consent records
class ConsentStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.consentStore")
    private var consentRecords: [String: ConsentRecord] = [:]
    private let userDefaults = UserDefaults.standard
    private let consentRecordsKey = "ResearchConsentRecords"
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.research", category: "ConsentStore")
        loadRecordsFromStorage()
    }
    
    /// Saves a consent record
    func saveConsentRecord(_ record: ConsentRecord) async {
        storageQueue.sync {
            consentRecords[record.studyID] = record
            saveRecordsToStorage()
            logger.info("Saved consent record for study: \(record.studyTitle)")
        }
    }
    
    /// Saves a consent result
    func saveConsentResult(_ result: ConsentResult) async {
        // Implementation could log or store result details
        logger.info("Saved consent result for study ID \(result.studyID): \(result.status.rawValue)")
    }
    
    /// Retrieves a consent record for a specific study
    func getConsentRecord(for studyID: String) async -> ConsentRecord? {
        var record: ConsentRecord?
        storageQueue.sync {
            record = consentRecords[studyID]
        }
        return record
    }
    
    /// Retrieves all consent records
    func getAllConsentRecords() async -> [ConsentRecord] {
        var records: [ConsentRecord] = []
        storageQueue.sync {
            records = Array(consentRecords.values)
        }
        return records
    }
    
    /// Loads records from persistent storage
    private func loadRecordsFromStorage() {
        guard let data = userDefaults.data(forKey: consentRecordsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            let recordsArray = try decoder.decode([ConsentRecord].self, from: data)
            consentRecords = Dictionary(uniqueKeysWithValues: recordsArray.map { ($0.studyID, $0) })
            logger.info("Loaded \(recordsArray.count) consent records from storage")
        } catch {
            logger.error("Failed to load consent records: \(error)")
        }
    }
    
    /// Saves records to persistent storage
    private func saveRecordsToStorage() {
        do {
            let encoder = JSONEncoder()
            let recordsArray = Array(consentRecords.values)
            let data = try encoder.encode(recordsArray)
            userDefaults.set(data, forKey: consentRecordsKey)
            logger.info("Saved \(recordsArray.count) consent records to storage")
        } catch {
            logger.error("Failed to save consent records: \(error)")
        }
    }
}

/// Class managing notifications related to consent
class ConsentNotificationManager {
    private let logger: Logger
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.research", category: "ConsentNotifications")
    }
    
    /// Schedules a notification about consent status
    func scheduleConsentNotification(title: String, body: String, studyID: String) async {
        logger.info("Scheduling notification for study ID: \(studyID)")
        
        // In a real implementation, this would use UNUserNotificationCenter
        // to schedule a local notification with the provided title and body
        
        // Simulate scheduling
        logger.info("Notification scheduled: \(title) - \(body)")
    }
    
    /// Schedules reminders for expiring consents
    func scheduleExpiryReminders(for records: [ConsentRecord]) async {
        let expiringSoon = records.filter { record in
            guard let expiryDate = record.expiryDate else { return false }
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
            return daysUntilExpiry <= 7 && daysUntilExpiry > 0
        }
        
        for record in expiringSoon {
            await scheduleConsentNotification(
                title: "Research Consent Expiring Soon",
                body: "Your consent for \(record.studyTitle) will expire on \(record.expiryDate?.formatted() ?? "soon").",
                studyID: record.studyID
            )
        }
    }
}

/// Custom error types for consent management
enum ConsentError: Error {
    case alreadyConsented
    case invalidStudyData(String)
    case storageError(Error)
    case healthKitAuthorizationFailed(String)
    case userCancelled
}

extension ResearchConsentManagement {
    /// Configuration for consent management
    struct Configuration {
        let reminderDaysBeforeExpiry: Int
        let maxConcurrentStudies: Int
        let consentVersion: String
        
        static let `default` = Configuration(
            reminderDaysBeforeExpiry: 7,
            maxConcurrentStudies: 5,
            consentVersion: "1.0.0"
        )
    }
    
    /// Validates a research study before requesting consent
    func validateStudy(_ study: ResearchStudy) throws {
        guard !study.id.isEmpty else {
            throw ConsentError.invalidStudyData("Study ID cannot be empty")
        }
        guard !study.title.isEmpty else {
            throw ConsentError.invalidStudyData("Study title cannot be empty")
        }
        guard !study.institution.isEmpty else {
            throw ConsentError.invalidStudyData("Institution name cannot be empty")
        }
        guard !study.dataTypes.isEmpty else {
            throw ConsentError.invalidStudyData("Study must specify data types")
        }
        guard study.durationDays > 0 else {
            throw ConsentError.invalidStudyData("Study duration must be greater than 0 days")
        }
    }
} 