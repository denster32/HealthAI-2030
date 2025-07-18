import Foundation
import Combine
import SwiftUI

/// Patient Management Tools System
/// Comprehensive patient management system for healthcare providers with patient records, care coordination, and treatment planning
@available(iOS 18.0, macOS 15.0, *)
public actor PatientManagementTools: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var managementStatus: ManagementStatus = .idle
    @Published public private(set) var currentOperation: ManagementOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var patientData: PatientManagementData = PatientManagementData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var notifications: [PatientNotification] = []
    
    // MARK: - Private Properties
    private let patientManager: PatientDataManager
    private let careCoordinator: CareCoordinationManager
    private let treatmentPlanner: TreatmentPlanningManager
    private let communicationManager: PatientCommunicationManager
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let managementQueue = DispatchQueue(label: "health.patient.management", qos: .userInitiated)
    
    // Management data
    private var activePatients: [String: PatientRecord] = [:]
    private var carePlans: [String: CarePlan] = [:]
    private var treatmentPlans: [String: TreatmentPlan] = [:]
    private var patientCommunications: [String: [PatientCommunication]] = [:]
    
    // MARK: - Initialization
    public init(patientManager: PatientDataManager,
                careCoordinator: CareCoordinationManager,
                treatmentPlanner: TreatmentPlanningManager,
                communicationManager: PatientCommunicationManager,
                analyticsEngine: AnalyticsEngine) {
        self.patientManager = patientManager
        self.careCoordinator = careCoordinator
        self.treatmentPlanner = treatmentPlanner
        self.communicationManager = communicationManager
        self.analyticsEngine = analyticsEngine
        
        setupPatientManagement()
        setupCareCoordination()
        setupTreatmentPlanning()
        setupPatientCommunication()
        setupNotificationSystem()
    }
    
    // MARK: - Public Methods
    
    /// Load patient management data
    public func loadPatientManagement(providerId: String, patientId: String? = nil) async throws -> PatientManagementData {
        managementStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load patient records
            let patientRecords = try await loadPatientRecords(providerId: providerId, patientId: patientId)
            await updateProgress(operation: .patientLoading, progress: 0.2)
            
            // Load care plans
            let carePlans = try await loadCarePlans(patientRecords: patientRecords)
            await updateProgress(operation: .carePlanLoading, progress: 0.4)
            
            // Load treatment plans
            let treatmentPlans = try await loadTreatmentPlans(patientRecords: patientRecords)
            await updateProgress(operation: .treatmentPlanLoading, progress: 0.6)
            
            // Load communications
            let communications = try await loadPatientCommunications(patientRecords: patientRecords)
            await updateProgress(operation: .communicationLoading, progress: 0.8)
            
            // Compile management data
            let managementData = try await compileManagementData(
                patientRecords: patientRecords,
                carePlans: carePlans,
                treatmentPlans: treatmentPlans,
                communications: communications
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            managementStatus = .loaded
            
            // Update patient data
            await MainActor.run {
                self.patientData = managementData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("patient_management_loaded", properties: [
                "provider_id": providerId,
                "patient_count": patientRecords.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return managementData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.managementStatus = .error
            }
            throw error
        }
    }
    
    /// Create or update patient record
    public func managePatientRecord(record: PatientRecord, operation: RecordOperation) async throws -> PatientRecord {
        managementStatus = .processing
        currentOperation = .recordManagement
        progress = 0.0
        lastError = nil
        
        do {
            // Validate patient record
            try await validatePatientRecord(record: record)
            await updateProgress(operation: .validation, progress: 0.2)
            
            // Process record operation
            let updatedRecord = try await processRecordOperation(record: record, operation: operation)
            await updateProgress(operation: .processing, progress: 0.6)
            
            // Update care coordination
            try await updateCareCoordination(record: updatedRecord)
            await updateProgress(operation: .coordination, progress: 0.8)
            
            // Complete processing
            managementStatus = .completed
            
            // Update active patients
            activePatients[updatedRecord.patientId] = updatedRecord
            
            return updatedRecord
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.managementStatus = .error
            }
            throw error
        }
    }
    
    /// Create or update care plan
    public func manageCarePlan(carePlan: CarePlan, operation: CarePlanOperation) async throws -> CarePlan {
        managementStatus = .processing
        currentOperation = .carePlanManagement
        progress = 0.0
        lastError = nil
        
        do {
            // Validate care plan
            try await validateCarePlan(carePlan: carePlan)
            await updateProgress(operation: .validation, progress: 0.2)
            
            // Process care plan operation
            let updatedCarePlan = try await processCarePlanOperation(carePlan: carePlan, operation: operation)
            await updateProgress(operation: .processing, progress: 0.6)
            
            // Update treatment coordination
            try await updateTreatmentCoordination(carePlan: updatedCarePlan)
            await updateProgress(operation: .coordination, progress: 0.8)
            
            // Complete processing
            managementStatus = .completed
            
            // Update care plans
            carePlans[updatedCarePlan.carePlanId] = updatedCarePlan
            
            return updatedCarePlan
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.managementStatus = .error
            }
            throw error
        }
    }
    
    /// Create or update treatment plan
    public func manageTreatmentPlan(treatmentPlan: TreatmentPlan, operation: TreatmentPlanOperation) async throws -> TreatmentPlan {
        managementStatus = .processing
        currentOperation = .treatmentPlanManagement
        progress = 0.0
        lastError = nil
        
        do {
            // Validate treatment plan
            try await validateTreatmentPlan(treatmentPlan: treatmentPlan)
            await updateProgress(operation: .validation, progress: 0.2)
            
            // Process treatment plan operation
            let updatedTreatmentPlan = try await processTreatmentPlanOperation(treatmentPlan: treatmentPlan, operation: operation)
            await updateProgress(operation: .processing, progress: 0.6)
            
            // Update patient communication
            try await updatePatientCommunication(treatmentPlan: updatedTreatmentPlan)
            await updateProgress(operation: .communication, progress: 0.8)
            
            // Complete processing
            managementStatus = .completed
            
            // Update treatment plans
            treatmentPlans[updatedTreatmentPlan.treatmentPlanId] = updatedTreatmentPlan
            
            return updatedTreatmentPlan
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.managementStatus = .error
            }
            throw error
        }
    }
    
    /// Send patient communication
    public func sendPatientCommunication(communication: PatientCommunication) async throws -> CommunicationResult {
        managementStatus = .processing
        currentOperation = .communication
        progress = 0.0
        lastError = nil
        
        do {
            // Validate communication
            try await validateCommunication(communication: communication)
            await updateProgress(operation: .validation, progress: 0.2)
            
            // Send communication
            let result = try await sendCommunication(communication: communication)
            await updateProgress(operation: .sending, progress: 0.6)
            
            // Update communication history
            try await updateCommunicationHistory(communication: communication, result: result)
            await updateProgress(operation: .history, progress: 0.8)
            
            // Complete processing
            managementStatus = .completed
            
            return result
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.managementStatus = .error
            }
            throw error
        }
    }
    
    /// Get patient notifications
    public func getPatientNotifications(patientId: String) async throws -> [PatientNotification] {
        let notificationRequest = NotificationRequest(
            patientId: patientId,
            timestamp: Date()
        )
        
        let notifications = try await communicationManager.getNotifications(notificationRequest)
        
        // Update notifications
        await MainActor.run {
            self.notifications = notifications
        }
        
        return notifications
    }
    
    /// Get management status
    public func getManagementStatus() -> ManagementStatus {
        return managementStatus
    }
    
    /// Get current notifications
    public func getCurrentNotifications() -> [PatientNotification] {
        return notifications
    }
    
    // MARK: - Private Methods
    
    private func setupPatientManagement() {
        // Setup patient management
        setupPatientRecords()
        setupPatientSearch()
        setupPatientValidation()
        setupPatientUpdates()
    }
    
    private func setupCareCoordination() {
        // Setup care coordination
        setupCarePlans()
        setupCareTeam()
        setupCareGoals()
        setupCareProgress()
    }
    
    private func setupTreatmentPlanning() {
        // Setup treatment planning
        setupTreatmentPlans()
        setupTreatmentSchedules()
        setupTreatmentMonitoring()
        setupTreatmentOutcomes()
    }
    
    private func setupPatientCommunication() {
        // Setup patient communication
        setupCommunicationChannels()
        setupMessageTemplates()
        setupCommunicationHistory()
        setupCommunicationAnalytics()
    }
    
    private func setupNotificationSystem() {
        // Setup notification system
        setupNotificationTypes()
        setupNotificationDelivery()
        setupNotificationPreferences()
        setupNotificationTracking()
    }
    
    private func loadPatientRecords(providerId: String, patientId: String?) async throws -> [PatientRecord] {
        // Load patient records
        let recordsRequest = PatientRecordsRequest(
            providerId: providerId,
            patientId: patientId,
            timestamp: Date()
        )
        
        return try await patientManager.loadPatientRecords(recordsRequest)
    }
    
    private func loadCarePlans(patientRecords: [PatientRecord]) async throws -> [CarePlan] {
        // Load care plans
        let carePlansRequest = CarePlansRequest(
            patientIds: patientRecords.map { $0.patientId },
            timestamp: Date()
        )
        
        return try await careCoordinator.loadCarePlans(carePlansRequest)
    }
    
    private func loadTreatmentPlans(patientRecords: [PatientRecord]) async throws -> [TreatmentPlan] {
        // Load treatment plans
        let treatmentPlansRequest = TreatmentPlansRequest(
            patientIds: patientRecords.map { $0.patientId },
            timestamp: Date()
        )
        
        return try await treatmentPlanner.loadTreatmentPlans(treatmentPlansRequest)
    }
    
    private func loadPatientCommunications(patientRecords: [PatientRecord]) async throws -> [String: [PatientCommunication]] {
        // Load patient communications
        let communicationsRequest = CommunicationsRequest(
            patientIds: patientRecords.map { $0.patientId },
            timestamp: Date()
        )
        
        return try await communicationManager.loadCommunications(communicationsRequest)
    }
    
    private func compileManagementData(patientRecords: [PatientRecord],
                                     carePlans: [CarePlan],
                                     treatmentPlans: [TreatmentPlan],
                                     communications: [String: [PatientCommunication]]) async throws -> PatientManagementData {
        // Compile management data
        return PatientManagementData(
            patientRecords: patientRecords,
            carePlans: carePlans,
            treatmentPlans: treatmentPlans,
            communications: communications,
            totalPatients: patientRecords.count,
            lastUpdated: Date()
        )
    }
    
    private func validatePatientRecord(record: PatientRecord) async throws {
        // Validate patient record
        guard !record.patientId.isEmpty else {
            throw ManagementError.invalidPatientId
        }
        
        guard !record.firstName.isEmpty && !record.lastName.isEmpty else {
            throw ManagementError.invalidPatientName
        }
        
        guard record.dateOfBirth < Date() else {
            throw ManagementError.invalidDateOfBirth
        }
    }
    
    private func processRecordOperation(record: PatientRecord, operation: RecordOperation) async throws -> PatientRecord {
        // Process record operation
        let operationRequest = RecordOperationRequest(
            record: record,
            operation: operation,
            timestamp: Date()
        )
        
        return try await patientManager.processRecordOperation(operationRequest)
    }
    
    private func updateCareCoordination(record: PatientRecord) async throws {
        // Update care coordination
        let coordinationRequest = CareCoordinationRequest(
            patientId: record.patientId,
            record: record,
            timestamp: Date()
        )
        
        try await careCoordinator.updateCoordination(coordinationRequest)
    }
    
    private func validateCarePlan(carePlan: CarePlan) async throws {
        // Validate care plan
        guard !carePlan.carePlanId.isEmpty else {
            throw ManagementError.invalidCarePlanId
        }
        
        guard !carePlan.patientId.isEmpty else {
            throw ManagementError.invalidPatientId
        }
        
        guard !carePlan.goals.isEmpty else {
            throw ManagementError.invalidCareGoals
        }
    }
    
    private func processCarePlanOperation(carePlan: CarePlan, operation: CarePlanOperation) async throws -> CarePlan {
        // Process care plan operation
        let operationRequest = CarePlanOperationRequest(
            carePlan: carePlan,
            operation: operation,
            timestamp: Date()
        )
        
        return try await careCoordinator.processCarePlanOperation(operationRequest)
    }
    
    private func updateTreatmentCoordination(carePlan: CarePlan) async throws {
        // Update treatment coordination
        let coordinationRequest = TreatmentCoordinationRequest(
            carePlanId: carePlan.carePlanId,
            carePlan: carePlan,
            timestamp: Date()
        )
        
        try await treatmentPlanner.updateCoordination(coordinationRequest)
    }
    
    private func validateTreatmentPlan(treatmentPlan: TreatmentPlan) async throws {
        // Validate treatment plan
        guard !treatmentPlan.treatmentPlanId.isEmpty else {
            throw ManagementError.invalidTreatmentPlanId
        }
        
        guard !treatmentPlan.patientId.isEmpty else {
            throw ManagementError.invalidPatientId
        }
        
        guard !treatmentPlan.treatments.isEmpty else {
            throw ManagementError.invalidTreatments
        }
    }
    
    private func processTreatmentPlanOperation(treatmentPlan: TreatmentPlan, operation: TreatmentPlanOperation) async throws -> TreatmentPlan {
        // Process treatment plan operation
        let operationRequest = TreatmentPlanOperationRequest(
            treatmentPlan: treatmentPlan,
            operation: operation,
            timestamp: Date()
        )
        
        return try await treatmentPlanner.processTreatmentPlanOperation(operationRequest)
    }
    
    private func updatePatientCommunication(treatmentPlan: TreatmentPlan) async throws {
        // Update patient communication
        let communicationRequest = PatientCommunicationRequest(
            patientId: treatmentPlan.patientId,
            treatmentPlan: treatmentPlan,
            timestamp: Date()
        )
        
        try await communicationManager.updateCommunication(communicationRequest)
    }
    
    private func validateCommunication(communication: PatientCommunication) async throws {
        // Validate communication
        guard !communication.patientId.isEmpty else {
            throw ManagementError.invalidPatientId
        }
        
        guard !communication.message.isEmpty else {
            throw ManagementError.invalidMessage
        }
        
        guard communication.type.isValid else {
            throw ManagementError.invalidCommunicationType
        }
    }
    
    private func sendCommunication(communication: PatientCommunication) async throws -> CommunicationResult {
        // Send communication
        let sendRequest = SendCommunicationRequest(
            communication: communication,
            timestamp: Date()
        )
        
        return try await communicationManager.sendCommunication(sendRequest)
    }
    
    private func updateCommunicationHistory(communication: PatientCommunication, result: CommunicationResult) async throws {
        // Update communication history
        let historyRequest = CommunicationHistoryRequest(
            communication: communication,
            result: result,
            timestamp: Date()
        )
        
        try await communicationManager.updateHistory(historyRequest)
    }
    
    private func updateProgress(operation: ManagementOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct PatientManagementData: Codable {
    public let patientRecords: [PatientRecord]
    public let carePlans: [CarePlan]
    public let treatmentPlans: [TreatmentPlan]
    public let communications: [String: [PatientCommunication]]
    public let totalPatients: Int
    public let lastUpdated: Date
}

public struct PatientRecord: Codable {
    public let patientId: String
    public let firstName: String
    public let lastName: String
    public let dateOfBirth: Date
    public let gender: Gender
    public let contactInfo: ContactInfo
    public let medicalHistory: MedicalHistory
    public let currentMedications: [Medication]
    public let allergies: [Allergy]
    public let insuranceInfo: InsuranceInfo
    public let emergencyContact: EmergencyContact
    public let lastUpdated: Date
}

public struct CarePlan: Codable {
    public let carePlanId: String
    public let patientId: String
    public let providerId: String
    public let goals: [CareGoal]
    public let interventions: [Intervention]
    public let progress: CareProgress
    public let startDate: Date
    public let endDate: Date?
    public let status: CarePlanStatus
    public let lastUpdated: Date
}

public struct TreatmentPlan: Codable {
    public let treatmentPlanId: String
    public let patientId: String
    public let providerId: String
    public let diagnosis: [Diagnosis]
    public let treatments: [Treatment]
    public let schedule: TreatmentSchedule
    public let outcomes: TreatmentOutcomes
    public let startDate: Date
    public let endDate: Date?
    public let status: TreatmentPlanStatus
    public let lastUpdated: Date
}

public struct PatientCommunication: Codable {
    public let communicationId: String
    public let patientId: String
    public let providerId: String
    public let type: CommunicationType
    public let message: String
    public let attachments: [Attachment]
    public let scheduledDate: Date?
    public let sentDate: Date?
    public let status: CommunicationStatus
    public let timestamp: Date
}

public struct PatientNotification: Codable {
    public let notificationId: String
    public let patientId: String
    public let type: NotificationType
    public let title: String
    public let message: String
    public let priority: Priority
    public let isRead: Bool
    public let timestamp: Date
}

public struct CommunicationResult: Codable {
    public let success: Bool
    public let messageId: String?
    public let deliveryStatus: DeliveryStatus
    public let timestamp: Date
}

public struct ContactInfo: Codable {
    public let phone: String
    public let email: String
    public let address: Address
}

public struct Address: Codable {
    public let street: String
    public let city: String
    public let state: String
    public let zipCode: String
    public let country: String
}

public struct MedicalHistory: Codable {
    public let conditions: [MedicalCondition]
    public let surgeries: [Surgery]
    public let familyHistory: [FamilyHistory]
    public let lifestyle: Lifestyle
}

public struct CareGoal: Codable {
    public let goalId: String
    public let description: String
    public let targetDate: Date
    public let status: GoalStatus
    public let progress: Double
}

public struct Intervention: Codable {
    public let interventionId: String
    public let type: InterventionType
    public let description: String
    public let frequency: String
    public let duration: String
    public let status: InterventionStatus
}

public struct CareProgress: Codable {
    public let overallProgress: Double
    public let goalProgress: [String: Double]
    public let lastAssessment: Date
    public let nextAssessment: Date
}

public struct Diagnosis: Codable {
    public let diagnosisId: String
    public let condition: String
    public let icd10Code: String
    public let severity: Severity
    public let dateDiagnosed: Date
}

public struct Treatment: Codable {
    public let treatmentId: String
    public let type: TreatmentType
    public let description: String
    public let dosage: String?
    public let frequency: String
    public let duration: String
    public let status: TreatmentStatus
}

public struct TreatmentSchedule: Codable {
    public let appointments: [Appointment]
    public let medications: [MedicationSchedule]
    public let procedures: [ProcedureSchedule]
    public let followUps: [FollowUp]
}

public struct TreatmentOutcomes: Codable {
    public let effectiveness: Effectiveness
    public let sideEffects: [SideEffect]
    public let patientReportedOutcomes: [PatientReportedOutcome]
    public let clinicalOutcomes: [ClinicalOutcome]
}

public struct Attachment: Codable {
    public let attachmentId: String
    public let fileName: String
    public let fileType: String
    public let fileSize: Int
    public let url: URL
}

// MARK: - Enums

public enum ManagementStatus: String, Codable, CaseIterable {
    case idle, loading, processing, completed, error
}

public enum ManagementOperation: String, Codable, CaseIterable {
    case none, dataLoading, patientLoading, carePlanLoading, treatmentPlanLoading, communicationLoading, compilation, recordManagement, carePlanManagement, treatmentPlanManagement, communication, validation, processing, coordination, sending, history
}

public enum RecordOperation: String, Codable, CaseIterable {
    case create, update, archive, restore
}

public enum CarePlanOperation: String, Codable, CaseIterable {
    case create, update, complete, cancel
}

public enum TreatmentPlanOperation: String, Codable, CaseIterable {
    case create, update, complete, cancel
}

public enum Gender: String, Codable, CaseIterable {
    case male, female, other, preferNotToSay
}

public enum CarePlanStatus: String, Codable, CaseIterable {
    case active, completed, cancelled, onHold
}

public enum TreatmentPlanStatus: String, Codable, CaseIterable {
    case active, completed, cancelled, onHold
}

public enum CommunicationType: String, Codable, CaseIterable {
    case message, appointment, medication, test, result, reminder
    
    public var isValid: Bool {
        return true
    }
}

public enum CommunicationStatus: String, Codable, CaseIterable {
    case draft, scheduled, sent, delivered, read, failed
}

public enum NotificationType: String, Codable, CaseIterable {
    case appointment, medication, test, result, reminder, alert
}

public enum Priority: String, Codable, CaseIterable {
    case low, medium, high, urgent
}

public enum DeliveryStatus: String, Codable, CaseIterable {
    case pending, sent, delivered, read, failed
}

public enum GoalStatus: String, Codable, CaseIterable {
    case notStarted, inProgress, completed, cancelled
}

public enum InterventionType: String, Codable, CaseIterable {
    case medication, therapy, exercise, diet, monitoring, education
}

public enum InterventionStatus: String, Codable, CaseIterable {
    case planned, active, completed, cancelled
}

public enum Severity: String, Codable, CaseIterable {
    case mild, moderate, severe, critical
}

public enum TreatmentType: String, Codable, CaseIterable {
    case medication, surgery, therapy, procedure, monitoring
}

public enum TreatmentStatus: String, Codable, CaseIterable {
    case planned, active, completed, cancelled
}

public enum Effectiveness: String, Codable, CaseIterable {
    case excellent, good, fair, poor, unknown
}

// MARK: - Errors

public enum ManagementError: Error, LocalizedError {
    case invalidPatientId
    case invalidPatientName
    case invalidDateOfBirth
    case invalidCarePlanId
    case invalidCareGoals
    case invalidTreatmentPlanId
    case invalidTreatments
    case invalidMessage
    case invalidCommunicationType
    case patientNotFound
    case carePlanNotFound
    case treatmentPlanNotFound
    case communicationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidPatientId:
            return "Invalid patient ID"
        case .invalidPatientName:
            return "Invalid patient name"
        case .invalidDateOfBirth:
            return "Invalid date of birth"
        case .invalidCarePlanId:
            return "Invalid care plan ID"
        case .invalidCareGoals:
            return "Invalid care goals"
        case .invalidTreatmentPlanId:
            return "Invalid treatment plan ID"
        case .invalidTreatments:
            return "Invalid treatments"
        case .invalidMessage:
            return "Invalid message"
        case .invalidCommunicationType:
            return "Invalid communication type"
        case .patientNotFound:
            return "Patient not found"
        case .carePlanNotFound:
            return "Care plan not found"
        case .treatmentPlanNotFound:
            return "Treatment plan not found"
        case .communicationFailed:
            return "Communication failed"
        }
    }
}

// MARK: - Protocols

public protocol PatientDataManager {
    func loadPatientRecords(_ request: PatientRecordsRequest) async throws -> [PatientRecord]
    func processRecordOperation(_ request: RecordOperationRequest) async throws -> PatientRecord
}

public protocol CareCoordinationManager {
    func loadCarePlans(_ request: CarePlansRequest) async throws -> [CarePlan]
    func processCarePlanOperation(_ request: CarePlanOperationRequest) async throws -> CarePlan
    func updateCoordination(_ request: CareCoordinationRequest) async throws
}

public protocol TreatmentPlanningManager {
    func loadTreatmentPlans(_ request: TreatmentPlansRequest) async throws -> [TreatmentPlan]
    func processTreatmentPlanOperation(_ request: TreatmentPlanOperationRequest) async throws -> TreatmentPlan
    func updateCoordination(_ request: TreatmentCoordinationRequest) async throws
}

public protocol PatientCommunicationManager {
    func loadCommunications(_ request: CommunicationsRequest) async throws -> [String: [PatientCommunication]]
    func sendCommunication(_ request: SendCommunicationRequest) async throws -> CommunicationResult
    func updateCommunication(_ request: PatientCommunicationRequest) async throws
    func updateHistory(_ request: CommunicationHistoryRequest) async throws
    func getNotifications(_ request: NotificationRequest) async throws -> [PatientNotification]
}

// MARK: - Supporting Types

public struct PatientRecordsRequest: Codable {
    public let providerId: String
    public let patientId: String?
    public let timestamp: Date
}

public struct RecordOperationRequest: Codable {
    public let record: PatientRecord
    public let operation: RecordOperation
    public let timestamp: Date
}

public struct CarePlansRequest: Codable {
    public let patientIds: [String]
    public let timestamp: Date
}

public struct CarePlanOperationRequest: Codable {
    public let carePlan: CarePlan
    public let operation: CarePlanOperation
    public let timestamp: Date
}

public struct CareCoordinationRequest: Codable {
    public let patientId: String
    public let record: PatientRecord
    public let timestamp: Date
}

public struct TreatmentPlansRequest: Codable {
    public let patientIds: [String]
    public let timestamp: Date
}

public struct TreatmentPlanOperationRequest: Codable {
    public let treatmentPlan: TreatmentPlan
    public let operation: TreatmentPlanOperation
    public let timestamp: Date
}

public struct TreatmentCoordinationRequest: Codable {
    public let carePlanId: String
    public let carePlan: CarePlan
    public let timestamp: Date
}

public struct CommunicationsRequest: Codable {
    public let patientIds: [String]
    public let timestamp: Date
}

public struct SendCommunicationRequest: Codable {
    public let communication: PatientCommunication
    public let timestamp: Date
}

public struct PatientCommunicationRequest: Codable {
    public let patientId: String
    public let treatmentPlan: TreatmentPlan
    public let timestamp: Date
}

public struct CommunicationHistoryRequest: Codable {
    public let communication: PatientCommunication
    public let result: CommunicationResult
    public let timestamp: Date
}

public struct NotificationRequest: Codable {
    public let patientId: String
    public let timestamp: Date
}

// Additional supporting types
public struct MedicalCondition: Codable {
    public let condition: String
    public let diagnosisDate: Date
    public let status: ConditionStatus
}

public struct Surgery: Codable {
    public let procedure: String
    public let date: Date
    public let surgeon: String
    public let hospital: String
}

public struct FamilyHistory: Codable {
    public let relationship: String
    public let condition: String
    public let age: Int?
}

public struct Lifestyle: Codable {
    public let smoking: SmokingStatus
    public let alcohol: AlcoholConsumption
    public let exercise: ExerciseFrequency
    public let diet: DietType
}

public struct InsuranceInfo: Codable {
    public let provider: String
    public let policyNumber: String
    public let groupNumber: String?
    public let effectiveDate: Date
    public let expirationDate: Date?
}

public struct EmergencyContact: Codable {
    public let name: String
    public let relationship: String
    public let phone: String
    public let email: String?
}

public struct Medication: Codable {
    public let name: String
    public let dosage: String
    public let frequency: String
    public let startDate: Date
    public let endDate: Date?
    public let prescribedBy: String
}

public struct Allergy: Codable {
    public let allergen: String
    public let severity: AllergySeverity
    public let reaction: String
}

public struct Appointment: Codable {
    public let appointmentId: String
    public let date: Date
    public let type: AppointmentType
    public let provider: String
    public let location: String
    public let status: AppointmentStatus
}

public struct MedicationSchedule: Codable {
    public let medication: Medication
    public let schedule: String
    public let reminders: [Date]
}

public struct ProcedureSchedule: Codable {
    public let procedure: String
    public let date: Date
    public let provider: String
    public let location: String
}

public struct FollowUp: Codable {
    public let date: Date
    public let type: FollowUpType
    public let provider: String
}

public struct SideEffect: Codable {
    public let effect: String
    public let severity: SideEffectSeverity
    public let onsetDate: Date
}

public struct PatientReportedOutcome: Codable {
    public let measure: String
    public let value: Double
    public let date: Date
}

public struct ClinicalOutcome: Codable {
    public let measure: String
    public let value: Double
    public let date: Date
    public let normalRange: String?
}

public enum ConditionStatus: String, Codable, CaseIterable {
    case active, resolved, chronic, managed
}

public enum SmokingStatus: String, Codable, CaseIterable {
    case never, former, current, unknown
}

public enum AlcoholConsumption: String, Codable, CaseIterable {
    case none, occasional, moderate, heavy, unknown
}

public enum ExerciseFrequency: String, Codable, CaseIterable {
    case never, rarely, sometimes, often, daily
}

public enum DietType: String, Codable, CaseIterable {
    case standard, vegetarian, vegan, glutenFree, dairyFree, other
}

public enum AllergySeverity: String, Codable, CaseIterable {
    case mild, moderate, severe, lifeThreatening
}

public enum AppointmentType: String, Codable, CaseIterable {
    case consultation, followUp, procedure, test, emergency
}

public enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled, confirmed, completed, cancelled, noShow
}

public enum FollowUpType: String, Codable, CaseIterable {
    case routine, urgent, specialist, test
}

public enum SideEffectSeverity: String, Codable, CaseIterable {
    case mild, moderate, severe, lifeThreatening
} 