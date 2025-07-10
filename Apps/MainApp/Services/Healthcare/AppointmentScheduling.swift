import Foundation
import Combine
import SwiftUI

/// Appointment Scheduling System
/// Comprehensive appointment scheduling system for healthcare providers with intelligent scheduling, conflict resolution, and patient communication
@available(iOS 18.0, macOS 15.0, *)
public actor AppointmentScheduling: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var schedulingStatus: SchedulingStatus = .idle
    @Published public private(set) var currentOperation: SchedulingOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var scheduleData: ScheduleData = ScheduleData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var conflicts: [SchedulingConflict] = []
    
    // MARK: - Private Properties
    private let scheduleManager: ScheduleDataManager
    private let availabilityManager: AvailabilityManager
    private let conflictResolver: ConflictResolutionManager
    private let notificationManager: AppointmentNotificationManager
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let schedulingQueue = DispatchQueue(label: "health.appointment.scheduling", qos: .userInitiated)
    
    // Scheduling data
    private var providerSchedules: [String: ProviderSchedule] = [:]
    private var patientAppointments: [String: [Appointment]] = [:]
    private var availabilitySlots: [String: [AvailabilitySlot]] = [:]
    private var schedulingRules: [SchedulingRule] = []
    
    // MARK: - Initialization
    public init(scheduleManager: ScheduleDataManager,
                availabilityManager: AvailabilityManager,
                conflictResolver: ConflictResolutionManager,
                notificationManager: AppointmentNotificationManager,
                analyticsEngine: AnalyticsEngine) {
        self.scheduleManager = scheduleManager
        self.availabilityManager = availabilityManager
        self.conflictResolver = conflictResolver
        self.notificationManager = notificationManager
        self.analyticsEngine = analyticsEngine
        
        setupAppointmentScheduling()
        setupAvailabilityManagement()
        setupConflictResolution()
        setupNotificationSystem()
        setupSchedulingRules()
    }
    
    // MARK: - Public Methods
    
    /// Load scheduling data
    public func loadScheduleData(providerId: String, dateRange: DateRange) async throws -> ScheduleData {
        schedulingStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load provider schedules
            let providerSchedules = try await loadProviderSchedules(providerId: providerId, dateRange: dateRange)
            await updateProgress(operation: .scheduleLoading, progress: 0.2)
            
            // Load availability slots
            let availabilitySlots = try await loadAvailabilitySlots(providerId: providerId, dateRange: dateRange)
            await updateProgress(operation: .availabilityLoading, progress: 0.4)
            
            // Load patient appointments
            let patientAppointments = try await loadPatientAppointments(providerId: providerId, dateRange: dateRange)
            await updateProgress(operation: .appointmentLoading, progress: 0.6)
            
            // Load scheduling rules
            let schedulingRules = try await loadSchedulingRules(providerId: providerId)
            await updateProgress(operation: .rulesLoading, progress: 0.8)
            
            // Compile schedule data
            let scheduleData = try await compileScheduleData(
                providerSchedules: providerSchedules,
                availabilitySlots: availabilitySlots,
                patientAppointments: patientAppointments,
                schedulingRules: schedulingRules
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            schedulingStatus = .loaded
            
            // Update schedule data
            await MainActor.run {
                self.scheduleData = scheduleData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("schedule_data_loaded", properties: [
                "provider_id": providerId,
                "date_range": dateRange.description,
                "appointments_count": patientAppointments.values.flatMap { $0 }.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return scheduleData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.schedulingStatus = .error
            }
            throw error
        }
    }
    
    /// Schedule appointment
    public func scheduleAppointment(request: AppointmentRequest) async throws -> Appointment {
        schedulingStatus = .scheduling
        currentOperation = .appointmentScheduling
        progress = 0.0
        lastError = nil
        
        do {
            // Validate appointment request
            try await validateAppointmentRequest(request: request)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Check availability
            let availability = try await checkAvailability(request: request)
            await updateProgress(operation: .availabilityCheck, progress: 0.3)
            
            // Resolve conflicts
            let conflicts = try await resolveConflicts(request: request, availability: availability)
            await updateProgress(operation: .conflictResolution, progress: 0.5)
            
            // Create appointment
            let appointment = try await createAppointment(request: request, availability: availability)
            await updateProgress(operation: .appointmentCreation, progress: 0.7)
            
            // Send notifications
            try await sendNotifications(appointment: appointment)
            await updateProgress(operation: .notification, progress: 0.9)
            
            // Complete scheduling
            schedulingStatus = .scheduled
            
            // Update patient appointments
            if patientAppointments[appointment.patientId] == nil {
                patientAppointments[appointment.patientId] = []
            }
            patientAppointments[appointment.patientId]?.append(appointment)
            
            return appointment
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.schedulingStatus = .error
            }
            throw error
        }
    }
    
    /// Reschedule appointment
    public func rescheduleAppointment(appointmentId: String, newDateTime: Date) async throws -> Appointment {
        schedulingStatus = .rescheduling
        currentOperation = .appointmentRescheduling
        progress = 0.0
        lastError = nil
        
        do {
            // Find existing appointment
            let existingAppointment = try await findAppointment(appointmentId: appointmentId)
            await updateProgress(operation: .appointmentSearch, progress: 0.2)
            
            // Check new availability
            let newRequest = AppointmentRequest(
                patientId: existingAppointment.patientId,
                providerId: existingAppointment.providerId,
                appointmentType: existingAppointment.type,
                requestedDateTime: newDateTime,
                duration: existingAppointment.duration,
                reason: existingAppointment.reason,
                priority: existingAppointment.priority
            )
            
            let availability = try await checkAvailability(request: newRequest)
            await updateProgress(operation: .availabilityCheck, progress: 0.4)
            
            // Update appointment
            let updatedAppointment = try await updateAppointment(appointmentId: appointmentId, newDateTime: newDateTime)
            await updateProgress(operation: .appointmentUpdate, progress: 0.7)
            
            // Send reschedule notifications
            try await sendRescheduleNotifications(appointment: updatedAppointment)
            await updateProgress(operation: .notification, progress: 1.0)
            
            // Complete rescheduling
            schedulingStatus = .rescheduled
            
            return updatedAppointment
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.schedulingStatus = .error
            }
            throw error
        }
    }
    
    /// Cancel appointment
    public func cancelAppointment(appointmentId: String, reason: CancellationReason) async throws -> CancellationResult {
        schedulingStatus = .cancelling
        currentOperation = .appointmentCancellation
        progress = 0.0
        lastError = nil
        
        do {
            // Find appointment
            let appointment = try await findAppointment(appointmentId: appointmentId)
            await updateProgress(operation: .appointmentSearch, progress: 0.2)
            
            // Cancel appointment
            let cancellation = try await cancelAppointment(appointment: appointment, reason: reason)
            await updateProgress(operation: .cancellation, progress: 0.6)
            
            // Send cancellation notifications
            try await sendCancellationNotifications(appointment: appointment, reason: reason)
            await updateProgress(operation: .notification, progress: 0.8)
            
            // Update availability
            try await updateAvailabilityAfterCancellation(appointment: appointment)
            await updateProgress(operation: .availabilityUpdate, progress: 1.0)
            
            // Complete cancellation
            schedulingStatus = .cancelled
            
            return cancellation
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.schedulingStatus = .error
            }
            throw error
        }
    }
    
    /// Get available slots
    public func getAvailableSlots(providerId: String, dateRange: DateRange, appointmentType: AppointmentType) async throws -> [AvailabilitySlot] {
        let availabilityRequest = AvailabilityRequest(
            providerId: providerId,
            dateRange: dateRange,
            appointmentType: appointmentType,
            timestamp: Date()
        )
        
        return try await availabilityManager.getAvailableSlots(availabilityRequest)
    }
    
    /// Check scheduling conflicts
    public func checkConflicts(request: AppointmentRequest) async throws -> [SchedulingConflict] {
        let conflictRequest = ConflictCheckRequest(
            request: request,
            timestamp: Date()
        )
        
        let conflicts = try await conflictResolver.checkConflicts(conflictRequest)
        
        // Update conflicts
        await MainActor.run {
            self.conflicts = conflicts
        }
        
        return conflicts
    }
    
    /// Get scheduling status
    public func getSchedulingStatus() -> SchedulingStatus {
        return schedulingStatus
    }
    
    /// Get current conflicts
    public func getCurrentConflicts() -> [SchedulingConflict] {
        return conflicts
    }
    
    // MARK: - Private Methods
    
    private func setupAppointmentScheduling() {
        // Setup appointment scheduling
        setupScheduleManagement()
        setupAppointmentCreation()
        setupAppointmentUpdates()
        setupAppointmentCancellation()
    }
    
    private func setupAvailabilityManagement() {
        // Setup availability management
        setupAvailabilityCalculation()
        setupSlotManagement()
        setupAvailabilityUpdates()
        setupAvailabilityOptimization()
    }
    
    private func setupConflictResolution() {
        // Setup conflict resolution
        setupConflictDetection()
        setupConflictResolution()
        setupConflictPrevention()
        setupConflictReporting()
    }
    
    private func setupNotificationSystem() {
        // Setup notification system
        setupAppointmentNotifications()
        setupReminderNotifications()
        setupCancellationNotifications()
        setupRescheduleNotifications()
    }
    
    private func setupSchedulingRules() {
        // Setup scheduling rules
        setupRuleValidation()
        setupRuleApplication()
        setupRuleOptimization()
        setupRuleManagement()
    }
    
    private func loadProviderSchedules(providerId: String, dateRange: DateRange) async throws -> [ProviderSchedule] {
        // Load provider schedules
        let scheduleRequest = ProviderScheduleRequest(
            providerId: providerId,
            dateRange: dateRange,
            timestamp: Date()
        )
        
        return try await scheduleManager.loadProviderSchedules(scheduleRequest)
    }
    
    private func loadAvailabilitySlots(providerId: String, dateRange: DateRange) async throws -> [AvailabilitySlot] {
        // Load availability slots
        let availabilityRequest = AvailabilityLoadRequest(
            providerId: providerId,
            dateRange: dateRange,
            timestamp: Date()
        )
        
        return try await availabilityManager.loadAvailabilitySlots(availabilityRequest)
    }
    
    private func loadPatientAppointments(providerId: String, dateRange: DateRange) async throws -> [String: [Appointment]] {
        // Load patient appointments
        let appointmentRequest = PatientAppointmentsRequest(
            providerId: providerId,
            dateRange: dateRange,
            timestamp: Date()
        )
        
        return try await scheduleManager.loadPatientAppointments(appointmentRequest)
    }
    
    private func loadSchedulingRules(providerId: String) async throws -> [SchedulingRule] {
        // Load scheduling rules
        let rulesRequest = SchedulingRulesRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await scheduleManager.loadSchedulingRules(rulesRequest)
    }
    
    private func compileScheduleData(providerSchedules: [ProviderSchedule],
                                   availabilitySlots: [AvailabilitySlot],
                                   patientAppointments: [String: [Appointment]],
                                   schedulingRules: [SchedulingRule]) async throws -> ScheduleData {
        // Compile schedule data
        return ScheduleData(
            providerSchedules: providerSchedules,
            availabilitySlots: availabilitySlots,
            patientAppointments: patientAppointments,
            schedulingRules: schedulingRules,
            totalAppointments: patientAppointments.values.flatMap { $0 }.count,
            lastUpdated: Date()
        )
    }
    
    private func validateAppointmentRequest(request: AppointmentRequest) async throws {
        // Validate appointment request
        guard !request.patientId.isEmpty else {
            throw SchedulingError.invalidPatientId
        }
        
        guard !request.providerId.isEmpty else {
            throw SchedulingError.invalidProviderId
        }
        
        guard request.requestedDateTime > Date() else {
            throw SchedulingError.invalidDateTime
        }
        
        guard request.duration > 0 else {
            throw SchedulingError.invalidDuration
        }
    }
    
    private func checkAvailability(request: AppointmentRequest) async throws -> AvailabilitySlot {
        // Check availability
        let availabilityRequest = AvailabilityCheckRequest(
            request: request,
            timestamp: Date()
        )
        
        return try await availabilityManager.checkAvailability(availabilityRequest)
    }
    
    private func resolveConflicts(request: AppointmentRequest, availability: AvailabilitySlot) async throws -> [SchedulingConflict] {
        // Resolve conflicts
        let conflictRequest = ConflictResolutionRequest(
            request: request,
            availability: availability,
            timestamp: Date()
        )
        
        return try await conflictResolver.resolveConflicts(conflictRequest)
    }
    
    private func createAppointment(request: AppointmentRequest, availability: AvailabilitySlot) async throws -> Appointment {
        // Create appointment
        let creationRequest = AppointmentCreationRequest(
            request: request,
            availability: availability,
            timestamp: Date()
        )
        
        return try await scheduleManager.createAppointment(creationRequest)
    }
    
    private func sendNotifications(appointment: Appointment) async throws {
        // Send notifications
        let notificationRequest = AppointmentNotificationRequest(
            appointment: appointment,
            notificationType: .confirmation,
            timestamp: Date()
        )
        
        try await notificationManager.sendNotification(notificationRequest)
    }
    
    private func findAppointment(appointmentId: String) async throws -> Appointment {
        // Find appointment
        let searchRequest = AppointmentSearchRequest(
            appointmentId: appointmentId,
            timestamp: Date()
        )
        
        return try await scheduleManager.findAppointment(searchRequest)
    }
    
    private func updateAppointment(appointmentId: String, newDateTime: Date) async throws -> Appointment {
        // Update appointment
        let updateRequest = AppointmentUpdateRequest(
            appointmentId: appointmentId,
            newDateTime: newDateTime,
            timestamp: Date()
        )
        
        return try await scheduleManager.updateAppointment(updateRequest)
    }
    
    private func sendRescheduleNotifications(appointment: Appointment) async throws {
        // Send reschedule notifications
        let notificationRequest = AppointmentNotificationRequest(
            appointment: appointment,
            notificationType: .reschedule,
            timestamp: Date()
        )
        
        try await notificationManager.sendNotification(notificationRequest)
    }
    
    private func cancelAppointment(appointment: Appointment, reason: CancellationReason) async throws -> CancellationResult {
        // Cancel appointment
        let cancellationRequest = AppointmentCancellationRequest(
            appointment: appointment,
            reason: reason,
            timestamp: Date()
        )
        
        return try await scheduleManager.cancelAppointment(cancellationRequest)
    }
    
    private func sendCancellationNotifications(appointment: Appointment, reason: CancellationReason) async throws {
        // Send cancellation notifications
        let notificationRequest = CancellationNotificationRequest(
            appointment: appointment,
            reason: reason,
            timestamp: Date()
        )
        
        try await notificationManager.sendCancellationNotification(notificationRequest)
    }
    
    private func updateAvailabilityAfterCancellation(appointment: Appointment) async throws {
        // Update availability after cancellation
        let availabilityRequest = AvailabilityUpdateRequest(
            appointment: appointment,
            action: .release,
            timestamp: Date()
        )
        
        try await availabilityManager.updateAvailability(availabilityRequest)
    }
    
    private func updateProgress(operation: SchedulingOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct ScheduleData: Codable {
    public let providerSchedules: [ProviderSchedule]
    public let availabilitySlots: [AvailabilitySlot]
    public let patientAppointments: [String: [Appointment]]
    public let schedulingRules: [SchedulingRule]
    public let totalAppointments: Int
    public let lastUpdated: Date
}

public struct AppointmentRequest: Codable {
    public let patientId: String
    public let providerId: String
    public let appointmentType: AppointmentType
    public let requestedDateTime: Date
    public let duration: TimeInterval
    public let reason: String
    public let priority: AppointmentPriority
    public let notes: String?
}

public struct Appointment: Codable {
    public let appointmentId: String
    public let patientId: String
    public let providerId: String
    public let type: AppointmentType
    public let dateTime: Date
    public let duration: TimeInterval
    public let reason: String
    public let priority: AppointmentPriority
    public let status: AppointmentStatus
    public let location: String
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct ProviderSchedule: Codable {
    public let providerId: String
    public let date: Date
    public let workingHours: WorkingHours
    public let breaks: [Break]
    public let unavailableSlots: [UnavailableSlot]
    public let lastUpdated: Date
}

public struct AvailabilitySlot: Codable {
    public let slotId: String
    public let providerId: String
    public let date: Date
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let isAvailable: Bool
    public let appointmentTypes: [AppointmentType]
    public let priority: SlotPriority
}

public struct SchedulingRule: Codable {
    public let ruleId: String
    public let providerId: String
    public let ruleType: RuleType
    public let conditions: [RuleCondition]
    public let actions: [RuleAction]
    public let priority: Int
    public let isActive: Bool
    public let createdAt: Date
}

public struct SchedulingConflict: Codable {
    public let conflictId: String
    public let type: ConflictType
    public let severity: ConflictSeverity
    public let description: String
    public let affectedAppointments: [String]
    public let suggestedResolution: String?
    public let timestamp: Date
}

public struct CancellationResult: Codable {
    public let success: Bool
    public let cancellationId: String
    public let reason: CancellationReason
    public let refundAmount: Double?
    public let timestamp: Date
}

public struct WorkingHours: Codable {
    public let startTime: Date
    public let endTime: Date
    public let daysOfWeek: [DayOfWeek]
}

public struct Break: Codable {
    public let startTime: Date
    public let endTime: Date
    public let reason: String
}

public struct UnavailableSlot: Codable {
    public let startTime: Date
    public let endTime: Date
    public let reason: String
}

public struct RuleCondition: Codable {
    public let field: String
    public let operator: ConditionOperator
    public let value: String
}

public struct RuleAction: Codable {
    public let action: String
    public let parameters: [String: String]
}

public struct DateRange: Codable {
    public let startDate: Date
    public let endDate: Date
    
    public var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Enums

public enum SchedulingStatus: String, Codable, CaseIterable {
    case idle, loading, loaded, scheduling, scheduled, rescheduling, rescheduled, cancelling, cancelled, error
}

public enum SchedulingOperation: String, Codable, CaseIterable {
    case none, dataLoading, scheduleLoading, availabilityLoading, appointmentLoading, rulesLoading, compilation, appointmentScheduling, appointmentRescheduling, appointmentCancellation, validation, availabilityCheck, conflictResolution, appointmentCreation, appointmentSearch, appointmentUpdate, cancellation, notification, availabilityUpdate
}

public enum AppointmentType: String, Codable, CaseIterable {
    case consultation, followUp, procedure, test, emergency, routine, specialist
}

public enum AppointmentPriority: String, Codable, CaseIterable {
    case low, normal, high, urgent
}

public enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled, confirmed, inProgress, completed, cancelled, noShow
}

public enum DayOfWeek: String, Codable, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

public enum SlotPriority: String, Codable, CaseIterable {
    case low, normal, high, premium
}

public enum RuleType: String, Codable, CaseIterable {
    case availability, conflict, notification, optimization
}

public enum ConditionOperator: String, Codable, CaseIterable {
    case equals, notEquals, greaterThan, lessThan, contains, notContains
}

public enum ConflictType: String, Codable, CaseIterable {
    case doubleBooking, providerUnavailable, patientConflict, resourceConflict, timeConflict
}

public enum ConflictSeverity: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum CancellationReason: String, Codable, CaseIterable {
    case patientRequest, providerRequest, emergency, weather, technical, other
}

// MARK: - Errors

public enum SchedulingError: Error, LocalizedError {
    case invalidPatientId
    case invalidProviderId
    case invalidDateTime
    case invalidDuration
    case appointmentNotFound
    case slotUnavailable
    case conflictDetected
    case schedulingRuleViolation
    case notificationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidPatientId:
            return "Invalid patient ID"
        case .invalidProviderId:
            return "Invalid provider ID"
        case .invalidDateTime:
            return "Invalid date/time"
        case .invalidDuration:
            return "Invalid duration"
        case .appointmentNotFound:
            return "Appointment not found"
        case .slotUnavailable:
            return "Time slot unavailable"
        case .conflictDetected:
            return "Scheduling conflict detected"
        case .schedulingRuleViolation:
            return "Scheduling rule violation"
        case .notificationFailed:
            return "Notification failed"
        }
    }
}

// MARK: - Protocols

public protocol ScheduleDataManager {
    func loadProviderSchedules(_ request: ProviderScheduleRequest) async throws -> [ProviderSchedule]
    func loadPatientAppointments(_ request: PatientAppointmentsRequest) async throws -> [String: [Appointment]]
    func loadSchedulingRules(_ request: SchedulingRulesRequest) async throws -> [SchedulingRule]
    func createAppointment(_ request: AppointmentCreationRequest) async throws -> Appointment
    func findAppointment(_ request: AppointmentSearchRequest) async throws -> Appointment
    func updateAppointment(_ request: AppointmentUpdateRequest) async throws -> Appointment
    func cancelAppointment(_ request: AppointmentCancellationRequest) async throws -> CancellationResult
}

public protocol AvailabilityManager {
    func loadAvailabilitySlots(_ request: AvailabilityLoadRequest) async throws -> [AvailabilitySlot]
    func getAvailableSlots(_ request: AvailabilityRequest) async throws -> [AvailabilitySlot]
    func checkAvailability(_ request: AvailabilityCheckRequest) async throws -> AvailabilitySlot
    func updateAvailability(_ request: AvailabilityUpdateRequest) async throws
}

public protocol ConflictResolutionManager {
    func checkConflicts(_ request: ConflictCheckRequest) async throws -> [SchedulingConflict]
    func resolveConflicts(_ request: ConflictResolutionRequest) async throws -> [SchedulingConflict]
}

public protocol AppointmentNotificationManager {
    func sendNotification(_ request: AppointmentNotificationRequest) async throws
    func sendCancellationNotification(_ request: CancellationNotificationRequest) async throws
}

// MARK: - Supporting Types

public struct ProviderScheduleRequest: Codable {
    public let providerId: String
    public let dateRange: DateRange
    public let timestamp: Date
}

public struct AvailabilityLoadRequest: Codable {
    public let providerId: String
    public let dateRange: DateRange
    public let timestamp: Date
}

public struct PatientAppointmentsRequest: Codable {
    public let providerId: String
    public let dateRange: DateRange
    public let timestamp: Date
}

public struct SchedulingRulesRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct AvailabilityRequest: Codable {
    public let providerId: String
    public let dateRange: DateRange
    public let appointmentType: AppointmentType
    public let timestamp: Date
}

public struct AvailabilityCheckRequest: Codable {
    public let request: AppointmentRequest
    public let timestamp: Date
}

public struct AvailabilityUpdateRequest: Codable {
    public let appointment: Appointment
    public let action: AvailabilityAction
    public let timestamp: Date
}

public struct ConflictCheckRequest: Codable {
    public let request: AppointmentRequest
    public let timestamp: Date
}

public struct ConflictResolutionRequest: Codable {
    public let request: AppointmentRequest
    public let availability: AvailabilitySlot
    public let timestamp: Date
}

public struct AppointmentCreationRequest: Codable {
    public let request: AppointmentRequest
    public let availability: AvailabilitySlot
    public let timestamp: Date
}

public struct AppointmentSearchRequest: Codable {
    public let appointmentId: String
    public let timestamp: Date
}

public struct AppointmentUpdateRequest: Codable {
    public let appointmentId: String
    public let newDateTime: Date
    public let timestamp: Date
}

public struct AppointmentCancellationRequest: Codable {
    public let appointment: Appointment
    public let reason: CancellationReason
    public let timestamp: Date
}

public struct AppointmentNotificationRequest: Codable {
    public let appointment: Appointment
    public let notificationType: NotificationType
    public let timestamp: Date
}

public struct CancellationNotificationRequest: Codable {
    public let appointment: Appointment
    public let reason: CancellationReason
    public let timestamp: Date
}

public enum AvailabilityAction: String, Codable, CaseIterable {
    case reserve, release, update
}

public enum NotificationType: String, Codable, CaseIterable {
    case confirmation, reminder, reschedule, cancellation
} 