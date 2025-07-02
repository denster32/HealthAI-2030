import Foundation
import ResearchKit
import HealthKit
import Combine
import CryptoKit
import CloudKit

/// Study Participation Manager
/// Advanced study enrollment and lifecycle management for clinical research participation
class StudyParticipationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var availableStudies: [ResearchStudy] = []
    @Published var enrolledStudies: [ResearchStudy] = []
    @Published var completedStudies: [ResearchStudy] = []
    @Published var studyInvitations: [StudyInvitation] = []
    @Published var participationStatus: ParticipationStatus = .inactive
    @Published var eligibilityProfile: EligibilityProfile = EligibilityProfile()
    @Published var complianceMetrics: [ComplianceMetric] = []
    
    // MARK: - Private Properties
    private var healthDataManager: HealthDataManager?
    private var researchKitManager: ResearchKitManager?
    private var dataAnonymizer: DataAnonymizer?
    private var medicalHistoryManager: MedicalHistoryManager?
    
    // Study management
    private var studyRepository: StudyRepository
    private var eligibilityEngine: EligibilityEngine
    private var enrollmentCoordinator: EnrollmentCoordinator
    private var complianceMonitor: ComplianceMonitor
    
    // Research platforms integration
    private var researchPlatformConnector: ResearchPlatformConnector
    private var studySyncManager: StudySyncManager
    
    // Privacy and consent
    private var researchConsentManager: ResearchConsentManager
    private var ethicsMonitor: EthicsMonitor
    
    // Data collection and submission
    private var dataCollectionEngine: DataCollectionEngine
    private var studyDataSubmitter: StudyDataSubmitter
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.studyRepository = StudyRepository()
        self.eligibilityEngine = EligibilityEngine()
        self.enrollmentCoordinator = EnrollmentCoordinator()
        self.complianceMonitor = ComplianceMonitor()
        self.researchPlatformConnector = ResearchPlatformConnector()
        self.studySyncManager = StudySyncManager()
        self.researchConsentManager = ResearchConsentManager()
        self.ethicsMonitor = EthicsMonitor()
        self.dataCollectionEngine = DataCollectionEngine()
        self.studyDataSubmitter = StudyDataSubmitter()
        
        setupStudyParticipationManager()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupStudyParticipationManager() {
        initializeComponents()
        setupDataSubscriptions()
        loadParticipationHistory()
        startStudyDiscovery()
        configureComplianceMonitoring()
    }
    
    private func initializeComponents() {
        healthDataManager = HealthDataManager()
        researchKitManager = ResearchKitManager()
        dataAnonymizer = DataAnonymizer()
        medicalHistoryManager = MedicalHistoryManager()
        
        setupManagerIntegration()
    }
    
    private func setupManagerIntegration() {
        // Subscribe to health data updates for eligibility assessment
        healthDataManager?.$latestHealthData
            .compactMap { $0 }
            .sink { [weak self] healthData in
                self?.updateEligibilityProfile(with: healthData)
            }
            .store(in: &cancellables)
        
        // Subscribe to study updates from research platforms
        studySyncManager.studyUpdatesPublisher
            .sink { [weak self] updates in
                self?.processStudyUpdates(updates)
            }
            .store(in: &cancellables)
        
        // Monitor compliance across all enrolled studies
        complianceMonitor.complianceUpdatesPublisher
            .sink { [weak self] metrics in
                self?.updateComplianceMetrics(metrics)
            }
            .store(in: &cancellables)
    }
    
    private func setupDataSubscriptions() {
        // Subscribe to new study availability
        studyRepository.newStudiesPublisher
            .sink { [weak self] newStudies in
                self?.evaluateStudyEligibility(for: newStudies)
            }
            .store(in: &cancellables)
        
        // Subscribe to enrollment status changes
        enrollmentCoordinator.enrollmentStatusPublisher
            .sink { [weak self] status in
                self?.handleEnrollmentStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func loadParticipationHistory() {
        Task {
            await loadStoredParticipationData()
        }
    }
    
    private func startStudyDiscovery() {
        Task {
            await discoverAvailableStudies()
        }
    }
    
    private func configureComplianceMonitoring() {
        complianceMonitor.configure(
            checkInterval: .hours(6),
            adherenceThreshold: 0.8,
            alertThreshold: 0.6
        )
    }
    
    // MARK: - Study Discovery and Eligibility
    
    func discoverStudies(criteria: StudyDiscoveryCriteria? = nil) async -> [ResearchStudy] {
        let discoveredStudies = await studyRepository.discoverStudies(matching: criteria)
        let eligibleStudies = await filterEligibleStudies(discoveredStudies)
        
        await MainActor.run {
            availableStudies = eligibleStudies
        }
        
        return eligibleStudies
    }
    
    private func discoverAvailableStudies() async {
        let studies = await discoverStudies()
        await evaluateStudyEligibility(for: studies)
    }
    
    private func filterEligibleStudies(_ studies: [ResearchStudy]) async -> [ResearchStudy] {
        var eligibleStudies: [ResearchStudy] = []
        
        for study in studies {
            let eligibility = await assessEligibility(for: study)
            if eligibility.isEligible {
                eligibleStudies.append(study)
            }
        }
        
        return eligibleStudies
    }
    
    func assessEligibility(for study: ResearchStudy) async -> EligibilityAssessment {
        let userProfile = await buildUserEligibilityProfile()
        let assessment = await eligibilityEngine.assessEligibility(
            userProfile: userProfile,
            studyCriteria: study.eligibilityCriteria
        )
        
        return assessment
    }
    
    private func buildUserEligibilityProfile() async -> UserEligibilityProfile {
        guard let healthData = await healthDataManager?.getLatestHealthData(),
              let medicalHistory = await medicalHistoryManager?.medicalProfile else {
            return UserEligibilityProfile()
        }
        
        return UserEligibilityProfile(
            age: calculateAge(from: medicalHistory.personalInfo.dateOfBirth),
            gender: medicalHistory.personalInfo.gender,
            medications: medicalHistory.medications,
            medicalConditions: medicalHistory.medicalConditions,
            allergies: medicalHistory.allergies,
            healthMetrics: HealthMetrics(from: healthData),
            deviceCapabilities: getDeviceCapabilities()
        )
    }
    
    private func evaluateStudyEligibility(for studies: [ResearchStudy]) {
        Task {
            for study in studies {
                let eligibility = await assessEligibility(for: study)
                
                if eligibility.isEligible && eligibility.matchScore > 0.8 {
                    await createStudyInvitation(for: study, eligibility: eligibility)
                }
            }
        }
    }
    
    private func createStudyInvitation(for study: ResearchStudy, eligibility: EligibilityAssessment) async {
        let invitation = StudyInvitation(
            id: UUID(),
            study: study,
            eligibilityAssessment: eligibility,
            invitedDate: Date(),
            expirationDate: Date().addingTimeInterval(2592000), // 30 days
            personalizedMessage: generatePersonalizedInvitation(for: study, eligibility: eligibility)
        )
        
        await MainActor.run {
            studyInvitations.append(invitation)
        }
        
        await notifyOfStudyInvitation(invitation)
    }
    
    private func generatePersonalizedInvitation(for study: ResearchStudy, eligibility: EligibilityAssessment) -> String {
        return """
        You've been invited to participate in \(study.title)!
        
        This study focuses on \(study.researchArea) and matches your health profile with a \(Int(eligibility.matchScore * 100))% compatibility score.
        
        Participation involves:
        • \(study.estimatedTimeCommitment)
        • \(study.participationRequirements.joined(separator: "\n• "))
        
        Your contribution could help advance medical research in \(study.researchArea).
        """
    }
    
    // MARK: - Study Enrollment
    
    func enrollInStudy(_ study: ResearchStudy, with consent: ResearchConsent) async throws -> EnrollmentResult {
        // Verify eligibility before enrollment
        let eligibility = await assessEligibility(for: study)
        guard eligibility.isEligible else {
            throw StudyParticipationError.notEligible
        }
        
        // Process research consent
        let consentResult = await researchConsentManager.processConsent(consent, for: study)
        guard consentResult.isValid else {
            throw StudyParticipationError.invalidConsent
        }
        
        // Execute enrollment
        let enrollmentRequest = EnrollmentRequest(
            studyId: study.id,
            participantProfile: await buildUserEligibilityProfile(),
            consentRecord: consentResult.consentRecord,
            enrollmentDate: Date()
        )
        
        let result = await enrollmentCoordinator.enrollParticipant(enrollmentRequest)
        
        if result.success {
            await handleSuccessfulEnrollment(study, result: result)
        }
        
        return result
    }
    
    private func handleSuccessfulEnrollment(_ study: ResearchStudy, result: EnrollmentResult) async {
        await MainActor.run {
            enrolledStudies.append(study)
            studyInvitations.removeAll { $0.study.id == study.id }
            participationStatus = .active
        }
        
        // Start data collection for the study
        await startDataCollection(for: study)
        
        // Begin compliance monitoring
        await complianceMonitor.startMonitoring(for: study)
        
        // Log successful enrollment
        await logStudyEvent(.enrollment, for: study, details: "Successfully enrolled")
    }
    
    func withdrawFromStudy(_ studyId: UUID, reason: WithdrawalReason) async throws -> WithdrawalResult {
        guard let study = enrolledStudies.first(where: { $0.id == studyId }) else {
            throw StudyParticipationError.studyNotFound
        }
        
        // Process withdrawal request
        let withdrawalRequest = WithdrawalRequest(
            studyId: studyId,
            participantId: await getCurrentParticipantId(for: study),
            reason: reason,
            withdrawalDate: Date(),
            dataRetentionPreference: .deleteAll // User preference
        )
        
        let result = await enrollmentCoordinator.withdrawParticipant(withdrawalRequest)
        
        if result.success {
            await handleSuccessfulWithdrawal(study)
        }
        
        return result
    }
    
    private func handleSuccessfulWithdrawal(_ study: ResearchStudy) async {
        await MainActor.run {
            enrolledStudies.removeAll { $0.id == study.id }
            
            if enrolledStudies.isEmpty {
                participationStatus = .inactive
            }
        }
        
        // Stop data collection
        await stopDataCollection(for: study)
        
        // Stop compliance monitoring
        await complianceMonitor.stopMonitoring(for: study)
        
        // Log withdrawal
        await logStudyEvent(.withdrawal, for: study, details: "Successfully withdrawn")
    }
    
    // MARK: - Data Collection and Submission
    
    private func startDataCollection(for study: ResearchStudy) async {
        let collectionProtocol = DataCollectionProtocol(
            studyId: study.id,
            dataTypes: study.requiredDataTypes,
            collectionFrequency: study.dataCollectionFrequency,
            anonymizationLevel: study.privacyRequirements.anonymizationLevel
        )
        
        await dataCollectionEngine.startCollection(protocol: collectionProtocol)
    }
    
    private func stopDataCollection(for study: ResearchStudy) async {
        await dataCollectionEngine.stopCollection(for: study.id)
    }
    
    func submitStudyData(for studyId: UUID) async throws -> DataSubmissionResult {
        guard let study = enrolledStudies.first(where: { $0.id == studyId }) else {
            throw StudyParticipationError.studyNotFound
        }
        
        // Collect and anonymize data
        let rawData = await dataCollectionEngine.collectData(for: study)
        let anonymizedData = await dataAnonymizer?.anonymizeForResearch(rawData, study: study)
        
        guard let finalData = anonymizedData else {
            throw StudyParticipationError.dataAnonymizationFailed
        }
        
        // Submit to research platform
        let submissionResult = await studyDataSubmitter.submitData(
            data: finalData,
            to: study,
            with: await getSubmissionMetadata(for: study)
        )
        
        await logDataSubmission(result: submissionResult, for: study)
        
        return submissionResult
    }
    
    private func getSubmissionMetadata(for study: ResearchStudy) async -> DataSubmissionMetadata {
        return DataSubmissionMetadata(
            participantId: await getCurrentParticipantId(for: study),
            submissionDate: Date(),
            dataVersion: "1.0",
            anonymizationMethod: study.privacyRequirements.anonymizationLevel.rawValue,
            integrityHash: ""
        )
    }
    
    // MARK: - Compliance Monitoring
    
    private func updateComplianceMetrics(_ metrics: [ComplianceMetric]) {
        complianceMetrics = metrics
        
        // Check for compliance issues
        let criticalIssues = metrics.filter { $0.adherenceScore < 0.6 }
        if !criticalIssues.isEmpty {
            handleComplianceIssues(criticalIssues)
        }
    }
    
    private func handleComplianceIssues(_ issues: [ComplianceMetric]) {
        Task {
            for issue in issues {
                await sendComplianceAlert(for: issue)
                await offerComplianceSupport(for: issue)
            }
        }
    }
    
    private func sendComplianceAlert(for metric: ComplianceMetric) async {
        // Send user notification about compliance
        print("Compliance alert for study: \(metric.studyId)")
    }
    
    private func offerComplianceSupport(for metric: ComplianceMetric) async {
        // Offer support resources to improve compliance
        print("Offering compliance support for study: \(metric.studyId)")
    }
    
    func getComplianceReport(for studyId: UUID) async -> ComplianceReport {
        return await complianceMonitor.generateReport(for: studyId)
    }
    
    // MARK: - Study Management
    
    private func processStudyUpdates(_ updates: [StudyUpdate]) {
        Task {
            for update in updates {
                await processStudyUpdate(update)
            }
        }
    }
    
    private func processStudyUpdate(_ update: StudyUpdate) async {
        switch update.type {
        case .protocolChange:
            await handleProtocolChange(update)
        case .studyTermination:
            await handleStudyTermination(update)
        case .eligibilityChange:
            await handleEligibilityChange(update)
        case .newRequirements:
            await handleNewRequirements(update)
        }
    }
    
    private func handleProtocolChange(_ update: StudyUpdate) async {
        // Notify participants of protocol changes
        // Request re-consent if necessary
    }
    
    private func handleStudyTermination(_ update: StudyUpdate) async {
        // Handle early study termination
        if let study = enrolledStudies.first(where: { $0.id == update.studyId }) {
            await handleSuccessfulWithdrawal(study)
        }
    }
    
    private func handleEligibilityChange(_ update: StudyUpdate) async {
        // Re-assess eligibility for ongoing studies
    }
    
    private func handleNewRequirements(_ update: StudyUpdate) async {
        // Handle new data collection requirements
    }
    
    private func handleEnrollmentStatusChange(_ status: EnrollmentStatusChange) {
        // Handle enrollment status changes
    }
    
    // MARK: - Data Management
    
    private func loadStoredParticipationData() async {
        // Load participation history from secure storage
    }
    
    private func updateEligibilityProfile(with healthData: HealthData) {
        Task {
            let updatedProfile = await buildUserEligibilityProfile()
            
            await MainActor.run {
                eligibilityProfile = EligibilityProfile(from: updatedProfile)
            }
            
            // Re-evaluate eligibility for available studies
            await evaluateStudyEligibility(for: availableStudies)
        }
    }
    
    private func getCurrentParticipantId(for study: ResearchStudy) async -> String {
        // Generate or retrieve participant ID for the study
        return "participant_\(UUID().uuidString)"
    }
    
    private func logStudyEvent(_ event: StudyEvent, for study: ResearchStudy, details: String) async {
        let logEntry = StudyEventLog(
            event: event,
            studyId: study.id,
            timestamp: Date(),
            details: details
        )
        
        // Log to research audit trail
        print("Study event logged: \(event) for study \(study.title)")
    }
    
    private func logDataSubmission(result: DataSubmissionResult, for study: ResearchStudy) async {
        await logStudyEvent(.dataSubmission, for: study, 
                          details: "Data submitted: \(result.success ? "Success" : "Failed")")
    }
    
    private func notifyOfStudyInvitation(_ invitation: StudyInvitation) async {
        // Send user notification about study invitation
        print("New study invitation: \(invitation.study.title)")
    }
    
    // MARK: - Utility Methods
    
    private func calculateAge(from dateOfBirth: Date?) -> Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        return ageComponents.year
    }
    
    private func getDeviceCapabilities() -> DeviceCapabilities {
        return DeviceCapabilities(
            coreMLSupport: true,
            healthKitSupport: true,
            researchKitSupport: true,
            sensors: ["heart_rate", "ecg", "accelerometer", "gyroscope"]
        )
    }
    
    func getParticipationSummary() -> ParticipationSummary {
        return ParticipationSummary(
            totalStudiesEnrolled: enrolledStudies.count,
            totalStudiesCompleted: completedStudies.count,
            averageComplianceScore: complianceMetrics.map(\.adherenceScore).average(),
            totalDataContributions: complianceMetrics.map(\.dataSubmissions).reduce(0, +),
            participationDuration: calculateParticipationDuration()
        )
    }
    
    private func calculateParticipationDuration() -> TimeInterval {
        // Calculate total participation duration across all studies
        return 0
    }
    
    private func cleanup() {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Data Structures

struct ResearchStudy: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let researchArea: String
    let principalInvestigator: String
    let institution: String
    let studyType: StudyType
    let phase: StudyPhase?
    let eligibilityCriteria: EligibilityCriteria
    let requiredDataTypes: [HealthDataType]
    let dataCollectionFrequency: DataCollectionFrequency
    let estimatedTimeCommitment: String
    let participationRequirements: [String]
    let privacyRequirements: PrivacyRequirements
    let compensationDetails: CompensationDetails?
    let startDate: Date
    let endDate: Date
    let maxParticipants: Int
    let currentParticipants: Int
    let status: StudyStatus
    let irbApprovalNumber: String
    let clinicalTrialsId: String?
}

struct StudyInvitation: Identifiable {
    let id: UUID
    let study: ResearchStudy
    let eligibilityAssessment: EligibilityAssessment
    let invitedDate: Date
    let expirationDate: Date
    let personalizedMessage: String
    var status: InvitationStatus = .pending
}

struct EligibilityProfile: Codable {
    var lastUpdated: Date = Date()
    var eligibilityFactors: [EligibilityFactor] = []
    
    init(from userProfile: UserEligibilityProfile) {
        self.lastUpdated = Date()
        // Convert user profile to eligibility factors
    }
    
    init() {}
}

struct UserEligibilityProfile {
    let age: Int?
    let gender: Gender
    let medications: [Medication]
    let medicalConditions: [MedicalCondition]
    let allergies: [Allergy]
    let healthMetrics: HealthMetrics
    let deviceCapabilities: DeviceCapabilities
    
    init(age: Int? = nil,
         gender: Gender = .notSpecified,
         medications: [Medication] = [],
         medicalConditions: [MedicalCondition] = [],
         allergies: [Allergy] = [],
         healthMetrics: HealthMetrics = HealthMetrics(),
         deviceCapabilities: DeviceCapabilities = DeviceCapabilities()) {
        self.age = age
        self.gender = gender
        self.medications = medications
        self.medicalConditions = medicalConditions
        self.allergies = allergies
        self.healthMetrics = healthMetrics
        self.deviceCapabilities = deviceCapabilities
    }
}

struct EligibilityAssessment {
    let isEligible: Bool
    let matchScore: Double // 0.0 to 1.0
    let eligibleCriteria: [EligibilityCriterion]
    let ineligibleCriteria: [EligibilityCriterion]
    let recommendations: [String]
    let assessmentDate: Date
}

struct ComplianceMetric {
    let studyId: UUID
    let adherenceScore: Double // 0.0 to 1.0
    let dataSubmissions: Int
    let missedSubmissions: Int
    let lastSubmissionDate: Date?
    let complianceIssues: [ComplianceIssue]
}

struct EnrollmentResult {
    let success: Bool
    let participantId: String?
    let enrollmentDate: Date?
    let error: StudyParticipationError?
}

struct WithdrawalResult {
    let success: Bool
    let withdrawalDate: Date?
    let dataRetention: DataRetentionPolicy
    let error: StudyParticipationError?
}

struct DataSubmissionResult {
    let success: Bool
    let submissionId: String?
    let submissionDate: Date?
    let dataSize: Int
    let error: StudyParticipationError?
}

struct ParticipationSummary {
    let totalStudiesEnrolled: Int
    let totalStudiesCompleted: Int
    let averageComplianceScore: Double
    let totalDataContributions: Int
    let participationDuration: TimeInterval
}

// MARK: - Supporting Classes

class StudyRepository {
    var newStudiesPublisher: AnyPublisher<[ResearchStudy], Never> {
        Just([]).eraseToAnyPublisher()
    }
    
    func discoverStudies(matching criteria: StudyDiscoveryCriteria?) async -> [ResearchStudy] {
        // Discover studies from research platforms
        return []
    }
}

class EligibilityEngine {
    func assessEligibility(userProfile: UserEligibilityProfile, studyCriteria: EligibilityCriteria) async -> EligibilityAssessment {
        // Assess user eligibility against study criteria
        return EligibilityAssessment(
            isEligible: true,
            matchScore: 0.8,
            eligibleCriteria: [],
            ineligibleCriteria: [],
            recommendations: [],
            assessmentDate: Date()
        )
    }
}

class EnrollmentCoordinator {
    var enrollmentStatusPublisher: AnyPublisher<EnrollmentStatusChange, Never> {
        Just(EnrollmentStatusChange(studyId: UUID(), status: .enrolled)).eraseToAnyPublisher()
    }
    
    func enrollParticipant(_ request: EnrollmentRequest) async -> EnrollmentResult {
        // Process enrollment with research platform
        return EnrollmentResult(success: true, participantId: "participant_123", enrollmentDate: Date(), error: nil)
    }
    
    func withdrawParticipant(_ request: WithdrawalRequest) async -> WithdrawalResult {
        // Process withdrawal with research platform
        return WithdrawalResult(success: true, withdrawalDate: Date(), dataRetention: .deleteAll, error: nil)
    }
}

class ComplianceMonitor {
    var complianceUpdatesPublisher: AnyPublisher<[ComplianceMetric], Never> {
        Just([]).eraseToAnyPublisher()
    }
    
    func configure(checkInterval: TimeInterval, adherenceThreshold: Double, alertThreshold: Double) {
        // Configure compliance monitoring
    }
    
    func startMonitoring(for study: ResearchStudy) async {
        // Start monitoring compliance for study
    }
    
    func stopMonitoring(for study: ResearchStudy) async {
        // Stop monitoring compliance for study
    }
    
    func generateReport(for studyId: UUID) async -> ComplianceReport {
        // Generate compliance report
        return ComplianceReport(studyId: studyId, overallScore: 0.8, details: [])
    }
}

class ResearchPlatformConnector {
    // Connect to external research platforms
}

class StudySyncManager {
    var studyUpdatesPublisher: AnyPublisher<[StudyUpdate], Never> {
        Just([]).eraseToAnyPublisher()
    }
}

class ResearchConsentManager {
    func processConsent(_ consent: ResearchConsent, for study: ResearchStudy) async -> ConsentResult {
        // Process and validate research consent
        return ConsentResult(isValid: true, consentRecord: ConsentRecord(consentId: UUID().uuidString, timestamp: Date()))
    }
}

class EthicsMonitor {
    // Monitor ethics compliance
}

class DataCollectionEngine {
    func startCollection(protocol: DataCollectionProtocol) async {
        // Start data collection for study
    }
    
    func stopCollection(for studyId: UUID) async {
        // Stop data collection for study
    }
    
    func collectData(for study: ResearchStudy) async -> RawResearchData {
        // Collect data for study submission
        return RawResearchData(data: [:])
    }
}

class StudyDataSubmitter {
    func submitData(data: AnonymizedResearchData, to study: ResearchStudy, with metadata: DataSubmissionMetadata) async -> DataSubmissionResult {
        // Submit data to research platform
        return DataSubmissionResult(success: true, submissionId: "submission_123", submissionDate: Date(), dataSize: 1024, error: nil)
    }
}

// MARK: - Supporting Enums and Structs

enum ParticipationStatus {
    case inactive
    case active
    case suspended
    case completed
}

enum StudyType {
    case observational
    case interventional
    case registry
    case expanded
}

enum StudyPhase: String, CaseIterable {
    case earlyPhase1 = "Early Phase 1"
    case phase1 = "Phase 1"
    case phase1Phase2 = "Phase 1/Phase 2"
    case phase2 = "Phase 2"
    case phase2Phase3 = "Phase 2/Phase 3"
    case phase3 = "Phase 3"
    case phase4 = "Phase 4"
    case notApplicable = "Not Applicable"
}

enum StudyStatus {
    case recruiting
    case active
    case suspended
    case terminated
    case completed
}

enum InvitationStatus {
    case pending
    case accepted
    case declined
    case expired
}

enum StudyEvent {
    case enrollment
    case withdrawal
    case dataSubmission
    case complianceIssue
    case protocolViolation
}

enum WithdrawalReason {
    case personalChoice
    case adverseEvent
    case protocolViolation
    case studyTermination
    case other(String)
}

enum DataRetentionPolicy {
    case retainAll
    case deletePersonalData
    case deleteAll
}

enum StudyParticipationError: Error {
    case notEligible
    case invalidConsent
    case studyNotFound
    case enrollmentFailed
    case withdrawalFailed
    case dataSubmissionFailed
    case dataAnonymizationFailed
    case networkError
}

struct StudyDiscoveryCriteria {
    let researchAreas: [String]?
    let studyTypes: [StudyType]?
    let maxTimeCommitment: TimeInterval?
    let compensationRequired: Bool?
}

struct EligibilityCriteria: Codable {
    let ageRange: ClosedRange<Int>?
    let genders: [Gender]
    let requiredConditions: [String]
    let excludedConditions: [String]
    let requiredMedications: [String]
    let excludedMedications: [String]
    let requiredDeviceCapabilities: [String]
    let minimumDataHistory: TimeInterval
}

struct EligibilityCriterion {
    let type: String
    let description: String
    let isMet: Bool
}

struct EligibilityFactor {
    let name: String
    let value: String
    let category: String
}

struct PrivacyRequirements: Codable {
    let anonymizationLevel: AnonymizationLevel
    let dataRetentionPeriod: TimeInterval
    let geographicRestrictions: [String]
    let sharingPermissions: [DataSharingPermission]
}

struct CompensationDetails: Codable {
    let type: CompensationType
    let amount: Double?
    let currency: String?
    let description: String
}

struct HealthMetrics {
    let heartRateAverage: Double?
    let bloodPressureAverage: (systolic: Double, diastolic: Double)?
    let sleepQualityAverage: Double?
    let activityLevel: String?
    
    init(from healthData: HealthData) {
        self.heartRateAverage = healthData.heartRate
        self.bloodPressureAverage = healthData.bloodPressure.map { (systolic: $0.systolic, diastolic: $0.diastolic) }
        self.sleepQualityAverage = nil // Calculate from sleep data
        self.activityLevel = "moderate" // Calculate from activity data
    }
    
    init() {
        self.heartRateAverage = nil
        self.bloodPressureAverage = nil
        self.sleepQualityAverage = nil
        self.activityLevel = nil
    }
}

struct DeviceCapabilities {
    let coreMLSupport: Bool
    let healthKitSupport: Bool
    let researchKitSupport: Bool
    let sensors: [String]
    
    init(coreMLSupport: Bool = false,
         healthKitSupport: Bool = false,
         researchKitSupport: Bool = false,
         sensors: [String] = []) {
        self.coreMLSupport = coreMLSupport
        self.healthKitSupport = healthKitSupport
        self.researchKitSupport = researchKitSupport
        self.sensors = sensors
    }
}

struct EnrollmentRequest {
    let studyId: UUID
    let participantProfile: UserEligibilityProfile
    let consentRecord: ConsentRecord
    let enrollmentDate: Date
}

struct WithdrawalRequest {
    let studyId: UUID
    let participantId: String
    let reason: WithdrawalReason
    let withdrawalDate: Date
    let dataRetentionPreference: DataRetentionPolicy
}

struct DataCollectionProtocol {
    let studyId: UUID
    let dataTypes: [HealthDataType]
    let collectionFrequency: DataCollectionFrequency
    let anonymizationLevel: AnonymizationLevel
}

struct DataSubmissionMetadata {
    let participantId: String
    let submissionDate: Date
    let dataVersion: String
    let anonymizationMethod: String
    let integrityHash: String
}

struct StudyUpdate {
    let studyId: UUID
    let type: StudyUpdateType
    let description: String
    let effectiveDate: Date
}

struct EnrollmentStatusChange {
    let studyId: UUID
    let status: EnrollmentStatus
}

struct StudyEventLog {
    let event: StudyEvent
    let studyId: UUID
    let timestamp: Date
    let details: String
}

struct ComplianceReport {
    let studyId: UUID
    let overallScore: Double
    let details: [ComplianceDetail]
}

struct ComplianceIssue {
    let type: String
    let description: String
    let severity: String
    let detectedDate: Date
}

struct ComplianceDetail {
    let category: String
    let score: Double
    let issues: [ComplianceIssue]
}

struct ResearchConsent {
    let consentVersion: String
    let agreedTerms: [String]
    let dataUsePermissions: [DataUsePermission]
    let signature: ConsentSignature
}

struct ConsentResult {
    let isValid: Bool
    let consentRecord: ConsentRecord
}

struct ConsentRecord {
    let consentId: String
    let timestamp: Date
}

struct ConsentSignature {
    let signatureData: Data
    let timestamp: Date
    let ipAddress: String?
}

struct RawResearchData {
    let data: [String: Any]
}

struct AnonymizedResearchData {
    let data: [String: Any]
    let anonymizationMetadata: AnonymizationMetadata
}

struct AnonymizationMetadata {
    let method: String
    let parameters: [String: Any]
    let timestamp: Date
}

enum HealthDataType: String, CaseIterable {
    case heartRate = "heart_rate"
    case bloodPressure = "blood_pressure"
    case ecg = "ecg"
    case sleep = "sleep"
    case activity = "activity"
    case stress = "stress"
    case mentalHealth = "mental_health"
}

enum DataCollectionFrequency {
    case realTime
    case hourly
    case daily
    case weekly
    case monthly
    case asNeeded
}

enum AnonymizationLevel: String, CaseIterable {
    case identified = "identified"
    case deidentified = "deidentified"
    case anonymous = "anonymous"
    case aggregateOnly = "aggregate_only"
}

enum DataSharingPermission: String, CaseIterable {
    case researchersOnly = "researchers_only"
    case academicInstitutions = "academic_institutions"
    case commercialPartners = "commercial_partners"
    case publicDatasets = "public_datasets"
}

enum CompensationType: String, CaseIterable {
    case none = "none"
    case monetary = "monetary"
    case giftCard = "gift_card"
    case healthInsights = "health_insights"
    case other = "other"
}

enum StudyUpdateType {
    case protocolChange
    case studyTermination
    case eligibilityChange
    case newRequirements
}

enum EnrollmentStatus {
    case enrolled
    case withdrawn
    case completed
    case suspended
}

enum DataUsePermission: String, CaseIterable {
    case researchOnly = "research_only"
    case publication = "publication"
    case commercialUse = "commercial_use"
    case sharing = "sharing"
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

extension TimeInterval {
    static func hours(_ hours: Double) -> TimeInterval {
        return hours * 3600
    }
}