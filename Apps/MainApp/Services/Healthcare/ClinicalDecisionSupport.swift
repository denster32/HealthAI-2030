import Foundation
import Combine
import SwiftUI

/// Clinical Decision Support System
/// Advanced clinical decision support system with AI-powered recommendations, evidence-based guidelines, and real-time clinical insights
@available(iOS 18.0, macOS 15.0, *)
public actor ClinicalDecisionSupport: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var supportStatus: SupportStatus = .idle
    @Published public private(set) var currentOperation: SupportOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var supportData: ClinicalSupportData = ClinicalSupportData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var alerts: [ClinicalAlert] = []
    
    // MARK: - Private Properties
    private let decisionEngine: ClinicalDecisionEngine
    private let guidelineManager: ClinicalGuidelineManager
    private let evidenceManager: EvidenceBasedManager
    private let riskAssessmentManager: RiskAssessmentManager
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let supportQueue = DispatchQueue(label: "health.clinical.support", qos: .userInitiated)
    
    // Support data
    private var activeCases: [String: ClinicalCase] = [:]
    private var decisionHistory: [ClinicalDecision] = []
    private var guidelines: [ClinicalGuideline] = []
    private var evidenceBase: [EvidenceItem] = []
    
    // MARK: - Initialization
    public init(decisionEngine: ClinicalDecisionEngine,
                guidelineManager: ClinicalGuidelineManager,
                evidenceManager: EvidenceBasedManager,
                riskAssessmentManager: RiskAssessmentManager,
                analyticsEngine: AnalyticsEngine) {
        self.decisionEngine = decisionEngine
        self.guidelineManager = guidelineManager
        self.evidenceManager = evidenceManager
        self.riskAssessmentManager = riskAssessmentManager
        self.analyticsEngine = analyticsEngine
        
        setupClinicalSupport()
        setupDecisionEngine()
        setupGuidelineManagement()
        setupEvidenceBase()
        setupRiskAssessment()
    }
    
    // MARK: - Public Methods
    
    /// Load clinical support data
    public func loadClinicalSupportData(providerId: String, specialty: MedicalSpecialty) async throws -> ClinicalSupportData {
        supportStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load clinical guidelines
            let guidelines = try await loadClinicalGuidelines(specialty: specialty)
            await updateProgress(operation: .guidelineLoading, progress: 0.2)
            
            // Load evidence base
            let evidenceBase = try await loadEvidenceBase(specialty: specialty)
            await updateProgress(operation: .evidenceLoading, progress: 0.4)
            
            // Load decision history
            let decisionHistory = try await loadDecisionHistory(providerId: providerId)
            await updateProgress(operation: .historyLoading, progress: 0.6)
            
            // Load active cases
            let activeCases = try await loadActiveCases(providerId: providerId)
            await updateProgress(operation: .caseLoading, progress: 0.8)
            
            // Compile support data
            let supportData = try await compileSupportData(
                guidelines: guidelines,
                evidenceBase: evidenceBase,
                decisionHistory: decisionHistory,
                activeCases: activeCases
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            supportStatus = .loaded
            
            // Update support data
            await MainActor.run {
                self.supportData = supportData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("clinical_support_loaded", properties: [
                "provider_id": providerId,
                "specialty": specialty.rawValue,
                "guidelines_count": guidelines.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return supportData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.supportStatus = .error
            }
            throw error
        }
    }
    
    /// Generate clinical decision support
    public func generateClinicalDecision(caseData: ClinicalCase) async throws -> ClinicalDecision {
        supportStatus = .processing
        currentOperation = .decisionGeneration
        progress = 0.0
        lastError = nil
        
        do {
            // Validate case data
            try await validateCaseData(caseData: caseData)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Analyze patient data
            let patientAnalysis = try await analyzePatientData(caseData: caseData)
            await updateProgress(operation: .patientAnalysis, progress: 0.3)
            
            // Assess clinical risks
            let riskAssessment = try await assessClinicalRisks(caseData: caseData)
            await updateProgress(operation: .riskAssessment, progress: 0.5)
            
            // Generate recommendations
            let recommendations = try await generateRecommendations(
                caseData: caseData,
                patientAnalysis: patientAnalysis,
                riskAssessment: riskAssessment
            )
            await updateProgress(operation: .recommendationGeneration, progress: 0.7)
            
            // Create clinical decision
            let decision = try await createClinicalDecision(
                caseData: caseData,
                recommendations: recommendations,
                riskAssessment: riskAssessment
            )
            await updateProgress(operation: .decisionCreation, progress: 0.9)
            
            // Complete processing
            supportStatus = .completed
            
            // Store decision
            decisionHistory.append(decision)
            
            return decision
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.supportStatus = .error
            }
            throw error
        }
    }
    
    /// Get evidence-based recommendations
    public func getEvidenceBasedRecommendations(condition: String, patientProfile: PatientProfile) async throws -> [EvidenceRecommendation] {
        supportStatus = .processing
        currentOperation = .evidenceSearch
        progress = 0.0
        lastError = nil
        
        do {
            // Search evidence base
            let evidenceItems = try await searchEvidenceBase(condition: condition)
            await updateProgress(operation: .evidenceSearch, progress: 0.3)
            
            // Filter by patient profile
            let filteredEvidence = try await filterEvidenceByProfile(evidenceItems: evidenceItems, patientProfile: patientProfile)
            await updateProgress(operation: .evidenceFiltering, progress: 0.6)
            
            // Generate recommendations
            let recommendations = try await generateEvidenceRecommendations(evidenceItems: filteredEvidence)
            await updateProgress(operation: .recommendationGeneration, progress: 1.0)
            
            // Complete processing
            supportStatus = .completed
            
            return recommendations
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.supportStatus = .error
            }
            throw error
        }
    }
    
    /// Assess clinical risks
    public func assessClinicalRisks(patientData: PatientData, condition: String) async throws -> RiskAssessment {
        let riskRequest = RiskAssessmentRequest(
            patientData: patientData,
            condition: condition,
            timestamp: Date()
        )
        
        return try await riskAssessmentManager.assessRisks(riskRequest)
    }
    
    /// Get clinical guidelines
    public func getClinicalGuidelines(specialty: MedicalSpecialty, condition: String? = nil) async throws -> [ClinicalGuideline] {
        let guidelineRequest = GuidelineRequest(
            specialty: specialty,
            condition: condition,
            timestamp: Date()
        )
        
        return try await guidelineManager.getGuidelines(guidelineRequest)
    }
    
    /// Update clinical decision
    public func updateClinicalDecision(decisionId: String, updates: DecisionUpdates) async throws -> ClinicalDecision {
        supportStatus = .updating
        currentOperation = .decisionUpdate
        progress = 0.0
        lastError = nil
        
        do {
            // Find existing decision
            guard let existingDecision = decisionHistory.first(where: { $0.decisionId == decisionId }) else {
                throw ClinicalError.decisionNotFound
            }
            
            // Validate updates
            try await validateDecisionUpdates(updates: updates)
            await updateProgress(operation: .validation, progress: 0.3)
            
            // Apply updates
            let updatedDecision = try await applyDecisionUpdates(decision: existingDecision, updates: updates)
            await updateProgress(operation: .updateApplication, progress: 0.7)
            
            // Update decision history
            if let index = decisionHistory.firstIndex(where: { $0.decisionId == decisionId }) {
                decisionHistory[index] = updatedDecision
            }
            
            await updateProgress(operation: .historyUpdate, progress: 1.0)
            
            // Complete update
            supportStatus = .updated
            
            return updatedDecision
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.supportStatus = .error
            }
            throw error
        }
    }
    
    /// Get support status
    public func getSupportStatus() -> SupportStatus {
        return supportStatus
    }
    
    /// Get current alerts
    public func getCurrentAlerts() -> [ClinicalAlert] {
        return alerts
    }
    
    // MARK: - Private Methods
    
    private func setupClinicalSupport() {
        // Setup clinical support
        setupCaseManagement()
        setupDecisionTracking()
        setupAlertSystem()
        setupQualityAssurance()
    }
    
    private func setupDecisionEngine() {
        // Setup decision engine
        setupRuleEngine()
        setupMachineLearning()
        setupKnowledgeBase()
        setupInferenceEngine()
    }
    
    private func setupGuidelineManagement() {
        // Setup guideline management
        setupGuidelineValidation()
        setupGuidelineUpdates()
        setupGuidelineCompliance()
        setupGuidelineAnalytics()
    }
    
    private func setupEvidenceBase() {
        // Setup evidence base
        setupEvidenceValidation()
        setupEvidenceUpdates()
        setupEvidenceSearch()
        setupEvidenceQuality()
    }
    
    private func setupRiskAssessment() {
        // Setup risk assessment
        setupRiskModels()
        setupRiskCalculation()
        setupRiskMonitoring()
        setupRiskReporting()
    }
    
    private func loadClinicalGuidelines(specialty: MedicalSpecialty) async throws -> [ClinicalGuideline] {
        // Load clinical guidelines
        let guidelineRequest = GuidelineLoadRequest(
            specialty: specialty,
            timestamp: Date()
        )
        
        return try await guidelineManager.loadGuidelines(guidelineRequest)
    }
    
    private func loadEvidenceBase(specialty: MedicalSpecialty) async throws -> [EvidenceItem] {
        // Load evidence base
        let evidenceRequest = EvidenceLoadRequest(
            specialty: specialty,
            timestamp: Date()
        )
        
        return try await evidenceManager.loadEvidenceBase(evidenceRequest)
    }
    
    private func loadDecisionHistory(providerId: String) async throws -> [ClinicalDecision] {
        // Load decision history
        let historyRequest = DecisionHistoryRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await decisionEngine.loadDecisionHistory(historyRequest)
    }
    
    private func loadActiveCases(providerId: String) async throws -> [ClinicalCase] {
        // Load active cases
        let caseRequest = ActiveCasesRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await decisionEngine.loadActiveCases(caseRequest)
    }
    
    private func compileSupportData(guidelines: [ClinicalGuideline],
                                  evidenceBase: [EvidenceItem],
                                  decisionHistory: [ClinicalDecision],
                                  activeCases: [ClinicalCase]) async throws -> ClinicalSupportData {
        // Compile support data
        return ClinicalSupportData(
            guidelines: guidelines,
            evidenceBase: evidenceBase,
            decisionHistory: decisionHistory,
            activeCases: activeCases,
            totalGuidelines: guidelines.count,
            lastUpdated: Date()
        )
    }
    
    private func validateCaseData(caseData: ClinicalCase) async throws {
        // Validate case data
        guard !caseData.patientId.isEmpty else {
            throw ClinicalError.invalidPatientId
        }
        
        guard !caseData.providerId.isEmpty else {
            throw ClinicalError.invalidProviderId
        }
        
        guard !caseData.symptoms.isEmpty else {
            throw ClinicalError.invalidSymptoms
        }
        
        guard caseData.severity.isValid else {
            throw ClinicalError.invalidSeverity
        }
    }
    
    private func analyzePatientData(caseData: ClinicalCase) async throws -> PatientAnalysis {
        // Analyze patient data
        let analysisRequest = PatientAnalysisRequest(
            caseData: caseData,
            timestamp: Date()
        )
        
        return try await decisionEngine.analyzePatientData(analysisRequest)
    }
    
    private func assessClinicalRisks(caseData: ClinicalCase) async throws -> RiskAssessment {
        // Assess clinical risks
        let riskRequest = ClinicalRiskRequest(
            caseData: caseData,
            timestamp: Date()
        )
        
        return try await riskAssessmentManager.assessClinicalRisks(riskRequest)
    }
    
    private func generateRecommendations(caseData: ClinicalCase,
                                       patientAnalysis: PatientAnalysis,
                                       riskAssessment: RiskAssessment) async throws -> [ClinicalRecommendation] {
        // Generate recommendations
        let recommendationRequest = RecommendationRequest(
            caseData: caseData,
            patientAnalysis: patientAnalysis,
            riskAssessment: riskAssessment,
            timestamp: Date()
        )
        
        return try await decisionEngine.generateRecommendations(recommendationRequest)
    }
    
    private func createClinicalDecision(caseData: ClinicalCase,
                                      recommendations: [ClinicalRecommendation],
                                      riskAssessment: RiskAssessment) async throws -> ClinicalDecision {
        // Create clinical decision
        let decisionRequest = DecisionCreationRequest(
            caseData: caseData,
            recommendations: recommendations,
            riskAssessment: riskAssessment,
            timestamp: Date()
        )
        
        return try await decisionEngine.createDecision(decisionRequest)
    }
    
    private func searchEvidenceBase(condition: String) async throws -> [EvidenceItem] {
        // Search evidence base
        let searchRequest = EvidenceSearchRequest(
            condition: condition,
            timestamp: Date()
        )
        
        return try await evidenceManager.searchEvidence(searchRequest)
    }
    
    private func filterEvidenceByProfile(evidenceItems: [EvidenceItem], patientProfile: PatientProfile) async throws -> [EvidenceItem] {
        // Filter evidence by profile
        let filterRequest = EvidenceFilterRequest(
            evidenceItems: evidenceItems,
            patientProfile: patientProfile,
            timestamp: Date()
        )
        
        return try await evidenceManager.filterEvidence(filterRequest)
    }
    
    private func generateEvidenceRecommendations(evidenceItems: [EvidenceItem]) async throws -> [EvidenceRecommendation] {
        // Generate evidence recommendations
        let recommendationRequest = EvidenceRecommendationRequest(
            evidenceItems: evidenceItems,
            timestamp: Date()
        )
        
        return try await evidenceManager.generateRecommendations(recommendationRequest)
    }
    
    private func validateDecisionUpdates(updates: DecisionUpdates) async throws {
        // Validate decision updates
        guard !updates.recommendations.isEmpty else {
            throw ClinicalError.invalidRecommendations
        }
        
        guard updates.confidence >= 0 && updates.confidence <= 1 else {
            throw ClinicalError.invalidConfidence
        }
    }
    
    private func applyDecisionUpdates(decision: ClinicalDecision, updates: DecisionUpdates) async throws -> ClinicalDecision {
        // Apply decision updates
        let updateRequest = DecisionUpdateRequest(
            decision: decision,
            updates: updates,
            timestamp: Date()
        )
        
        return try await decisionEngine.updateDecision(updateRequest)
    }
    
    private func updateProgress(operation: SupportOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct ClinicalSupportData: Codable {
    public let guidelines: [ClinicalGuideline]
    public let evidenceBase: [EvidenceItem]
    public let decisionHistory: [ClinicalDecision]
    public let activeCases: [ClinicalCase]
    public let totalGuidelines: Int
    public let lastUpdated: Date
}

public struct ClinicalCase: Codable {
    public let caseId: String
    public let patientId: String
    public let providerId: String
    public let specialty: MedicalSpecialty
    public let symptoms: [String]
    public let vitalSigns: VitalSigns
    public let labResults: [LabResult]
    public let medicalHistory: MedicalHistory
    public let medications: [Medication]
    public let allergies: [Allergy]
    public let severity: CaseSeverity
    public let urgency: Urgency
    public let createdAt: Date
    public let updatedAt: Date
}

public struct ClinicalDecision: Codable {
    public let decisionId: String
    public let caseId: String
    public let providerId: String
    public let recommendations: [ClinicalRecommendation]
    public let confidence: Double
    public let evidence: [EvidenceReference]
    public let riskFactors: [RiskFactor]
    public let alternatives: [ClinicalAlternative]
    public let decisionDate: Date
    public let status: DecisionStatus
}

public struct ClinicalGuideline: Codable {
    public let guidelineId: String
    public let title: String
    public let specialty: MedicalSpecialty
    public let condition: String
    public let recommendations: [GuidelineRecommendation]
    public let evidenceLevel: EvidenceLevel
    public let lastUpdated: Date
    public let version: String
    public let source: String
}

public struct EvidenceItem: Codable {
    public let evidenceId: String
    public let title: String
    public let type: EvidenceType
    public let condition: String
    public let findings: String
    public let conclusion: String
    public let evidenceLevel: EvidenceLevel
    public let publicationDate: Date
    public let source: String
    public let doi: String?
}

public struct ClinicalRecommendation: Codable {
    public let recommendationId: String
    public let type: RecommendationType
    public let description: String
    public let priority: Priority
    public let evidence: [EvidenceReference]
    public let contraindications: [String]
    public let monitoring: [MonitoringRequirement]
    public let followUp: FollowUpPlan
}

public struct RiskAssessment: Codable {
    public let assessmentId: String
    public let patientId: String
    public let riskFactors: [RiskFactor]
    public let riskScore: Double
    public let riskLevel: RiskLevel
    public let recommendations: [RiskRecommendation]
    public let assessmentDate: Date
}

public struct PatientProfile: Codable {
    public let age: Int
    public let gender: Gender
    public let comorbidities: [String]
    public let medications: [String]
    public let allergies: [String]
    public let lifestyle: Lifestyle
}

public struct EvidenceRecommendation: Codable {
    public let recommendationId: String
    public let evidence: EvidenceItem
    public let applicability: Double
    public let strength: RecommendationStrength
    public let clinicalImpact: ClinicalImpact
    public let implementationNotes: String
}

public struct DecisionUpdates: Codable {
    public let recommendations: [ClinicalRecommendation]
    public let confidence: Double
    public let reasoning: String
    public let updatedBy: String
}

public struct VitalSigns: Codable {
    public let heartRate: Double?
    public let bloodPressure: BloodPressure?
    public let temperature: Double?
    public let respiratoryRate: Double?
    public let oxygenSaturation: Double?
    public let weight: Double?
    public let height: Double?
}

public struct BloodPressure: Codable {
    public let systolic: Double
    public let diastolic: Double
}

public struct EvidenceReference: Codable {
    public let evidenceId: String
    public let relevance: Double
    public let citation: String
}

public struct RiskFactor: Codable {
    public let factor: String
    public let severity: RiskSeverity
    public let modifiable: Bool
    public let impact: Double
}

public struct ClinicalAlternative: Codable {
    public let alternativeId: String
    public let description: String
    public let pros: [String]
    public let cons: [String]
    public let evidence: [EvidenceReference]
}

public struct GuidelineRecommendation: Codable {
    public let recommendationId: String
    public let description: String
    public let strength: RecommendationStrength
    public let evidenceLevel: EvidenceLevel
    public let conditions: [String]
}

public struct MonitoringRequirement: Codable {
    public let parameter: String
    public let frequency: String
    public let duration: String
    public let threshold: String?
}

public struct FollowUpPlan: Codable {
    public let timeline: String
    public let assessments: [String]
    public let criteria: [String]
}

public struct RiskRecommendation: Codable {
    public let recommendationId: String
    public let description: String
    public let priority: Priority
    public let timeline: String
}

// MARK: - Enums

public enum SupportStatus: String, Codable, CaseIterable {
    case idle, loading, loaded, processing, completed, updating, updated, error
}

public enum SupportOperation: String, Codable, CaseIterable {
    case none, dataLoading, guidelineLoading, evidenceLoading, historyLoading, caseLoading, compilation, decisionGeneration, evidenceSearch, decisionUpdate, validation, patientAnalysis, riskAssessment, recommendationGeneration, decisionCreation, evidenceSearch, evidenceFiltering, updateApplication, historyUpdate
}

public enum MedicalSpecialty: String, Codable, CaseIterable {
    case cardiology, neurology, oncology, pediatrics, psychiatry, surgery, emergency, internal, family, obstetrics, gynecology, dermatology, ophthalmology, orthopedics, radiology
}

public enum CaseSeverity: String, Codable, CaseIterable {
    case mild, moderate, severe, critical
    
    public var isValid: Bool {
        return true
    }
}

public enum Urgency: String, Codable, CaseIterable {
    case routine, urgent, emergency
}

public enum DecisionStatus: String, Codable, CaseIterable {
    case pending, active, completed, cancelled, revised
}

public enum EvidenceType: String, Codable, CaseIterable {
    case randomizedTrial, observational, systematicReview, caseStudy, expertOpinion
}

public enum EvidenceLevel: String, Codable, CaseIterable {
    case level1, level2, level3, level4, level5
}

public enum RecommendationType: String, Codable, CaseIterable {
    case diagnostic, therapeutic, monitoring, preventive, referral
}

public enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum RiskLevel: String, Codable, CaseIterable {
    case low, moderate, high, veryHigh
}

public enum RiskSeverity: String, Codable, CaseIterable {
    case mild, moderate, severe, critical
}

public enum RecommendationStrength: String, Codable, CaseIterable {
    case strong, moderate, weak, conditional
}

public enum ClinicalImpact: String, Codable, CaseIterable {
    case high, medium, low, minimal
}

public enum Gender: String, Codable, CaseIterable {
    case male, female, other, preferNotToSay
}

public enum Lifestyle: Codable {
    case sedentary, lightlyActive, moderatelyActive, veryActive, extremelyActive
}

// MARK: - Errors

public enum ClinicalError: Error, LocalizedError {
    case invalidPatientId
    case invalidProviderId
    case invalidSymptoms
    case invalidSeverity
    case invalidRecommendations
    case invalidConfidence
    case decisionNotFound
    case guidelineNotFound
    case evidenceNotFound
    case analysisFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidPatientId:
            return "Invalid patient ID"
        case .invalidProviderId:
            return "Invalid provider ID"
        case .invalidSymptoms:
            return "Invalid symptoms"
        case .invalidSeverity:
            return "Invalid severity level"
        case .invalidRecommendations:
            return "Invalid recommendations"
        case .invalidConfidence:
            return "Invalid confidence level"
        case .decisionNotFound:
            return "Clinical decision not found"
        case .guidelineNotFound:
            return "Clinical guideline not found"
        case .evidenceNotFound:
            return "Evidence not found"
        case .analysisFailed:
            return "Clinical analysis failed"
        }
    }
}

// MARK: - Protocols

public protocol ClinicalDecisionEngine {
    func loadDecisionHistory(_ request: DecisionHistoryRequest) async throws -> [ClinicalDecision]
    func loadActiveCases(_ request: ActiveCasesRequest) async throws -> [ClinicalCase]
    func analyzePatientData(_ request: PatientAnalysisRequest) async throws -> PatientAnalysis
    func generateRecommendations(_ request: RecommendationRequest) async throws -> [ClinicalRecommendation]
    func createDecision(_ request: DecisionCreationRequest) async throws -> ClinicalDecision
    func updateDecision(_ request: DecisionUpdateRequest) async throws -> ClinicalDecision
}

public protocol ClinicalGuidelineManager {
    func loadGuidelines(_ request: GuidelineLoadRequest) async throws -> [ClinicalGuideline]
    func getGuidelines(_ request: GuidelineRequest) async throws -> [ClinicalGuideline]
}

public protocol EvidenceBasedManager {
    func loadEvidenceBase(_ request: EvidenceLoadRequest) async throws -> [EvidenceItem]
    func searchEvidence(_ request: EvidenceSearchRequest) async throws -> [EvidenceItem]
    func filterEvidence(_ request: EvidenceFilterRequest) async throws -> [EvidenceItem]
    func generateRecommendations(_ request: EvidenceRecommendationRequest) async throws -> [EvidenceRecommendation]
}

public protocol RiskAssessmentManager {
    func assessRisks(_ request: RiskAssessmentRequest) async throws -> RiskAssessment
    func assessClinicalRisks(_ request: ClinicalRiskRequest) async throws -> RiskAssessment
}

// MARK: - Supporting Types

public struct DecisionHistoryRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct ActiveCasesRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct PatientAnalysisRequest: Codable {
    public let caseData: ClinicalCase
    public let timestamp: Date
}

public struct RecommendationRequest: Codable {
    public let caseData: ClinicalCase
    public let patientAnalysis: PatientAnalysis
    public let riskAssessment: RiskAssessment
    public let timestamp: Date
}

public struct DecisionCreationRequest: Codable {
    public let caseData: ClinicalCase
    public let recommendations: [ClinicalRecommendation]
    public let riskAssessment: RiskAssessment
    public let timestamp: Date
}

public struct DecisionUpdateRequest: Codable {
    public let decision: ClinicalDecision
    public let updates: DecisionUpdates
    public let timestamp: Date
}

public struct GuidelineLoadRequest: Codable {
    public let specialty: MedicalSpecialty
    public let timestamp: Date
}

public struct GuidelineRequest: Codable {
    public let specialty: MedicalSpecialty
    public let condition: String?
    public let timestamp: Date
}

public struct EvidenceLoadRequest: Codable {
    public let specialty: MedicalSpecialty
    public let timestamp: Date
}

public struct EvidenceSearchRequest: Codable {
    public let condition: String
    public let timestamp: Date
}

public struct EvidenceFilterRequest: Codable {
    public let evidenceItems: [EvidenceItem]
    public let patientProfile: PatientProfile
    public let timestamp: Date
}

public struct EvidenceRecommendationRequest: Codable {
    public let evidenceItems: [EvidenceItem]
    public let timestamp: Date
}

public struct RiskAssessmentRequest: Codable {
    public let patientData: PatientData
    public let condition: String
    public let timestamp: Date
}

public struct ClinicalRiskRequest: Codable {
    public let caseData: ClinicalCase
    public let timestamp: Date
}

public struct PatientAnalysis: Codable {
    public let analysisId: String
    public let patientId: String
    public let findings: [AnalysisFinding]
    public let patterns: [Pattern]
    public let insights: [Insight]
    public let timestamp: Date
}

public struct AnalysisFinding: Codable {
    public let finding: String
    public let significance: Double
    public let category: String
}

public struct Pattern: Codable {
    public let pattern: String
    public let confidence: Double
    public let description: String
}

public struct Insight: Codable {
    public let insight: String
    public let type: InsightType
    public let priority: Priority
}

public enum InsightType: String, Codable, CaseIterable {
    case clinical, diagnostic, therapeutic, preventive
}

public struct PatientData: Codable {
    public let patientId: String
    public let demographics: Demographics
    public let vitals: VitalSigns
    public let history: MedicalHistory
    public let currentMedications: [Medication]
}

public struct Demographics: Codable {
    public let age: Int
    public let gender: Gender
    public let ethnicity: String?
    public let location: String?
}

public struct MedicalHistory: Codable {
    public let conditions: [MedicalCondition]
    public let surgeries: [Surgery]
    public let familyHistory: [FamilyHistory]
    public let lifestyle: Lifestyle
}

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

public enum ConditionStatus: String, Codable, CaseIterable {
    case active, resolved, chronic, managed
} 