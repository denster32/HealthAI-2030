import Foundation
import Combine
import SwiftUI

/// Clinical Documentation System
/// Advanced clinical documentation system with intelligent templates, voice-to-text, and automated documentation workflows
@available(iOS 18.0, macOS 15.0, *)
public actor ClinicalDocumentation: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var documentationStatus: DocumentationStatus = .idle
    @Published public private(set) var currentOperation: DocumentationOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var documentationData: DocumentationData = DocumentationData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var notifications: [DocumentationNotification] = []
    
    // MARK: - Private Properties
    private let documentManager: DocumentManager
    private let templateManager: TemplateManager
    private let voiceManager: VoiceToTextManager
    private let workflowManager: DocumentationWorkflowManager
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let documentationQueue = DispatchQueue(label: "health.clinical.documentation", qos: .userInitiated)
    
    // Documentation data
    private var activeDocuments: [String: ClinicalDocument] = [:]
    private var documentTemplates: [DocumentTemplate] = []
    private var voiceRecordings: [VoiceRecording] = []
    private var documentWorkflows: [DocumentWorkflow] = []
    
    // MARK: - Initialization
    public init(documentManager: DocumentManager,
                templateManager: TemplateManager,
                voiceManager: VoiceToTextManager,
                workflowManager: DocumentationWorkflowManager,
                analyticsEngine: AnalyticsEngine) {
        self.documentManager = documentManager
        self.templateManager = templateManager
        self.voiceManager = voiceManager
        self.workflowManager = workflowManager
        self.analyticsEngine = analyticsEngine
        
        setupClinicalDocumentation()
        setupTemplateManagement()
        setupVoiceToText()
        setupWorkflowManagement()
        setupNotificationSystem()
    }
    
    // MARK: - Public Methods
    
    /// Load documentation data
    public func loadDocumentationData(providerId: String, department: Department) async throws -> DocumentationData {
        documentationStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load active documents
            let activeDocuments = try await loadActiveDocuments(providerId: providerId, department: department)
            await updateProgress(operation: .documentLoading, progress: 0.2)
            
            // Load document templates
            let documentTemplates = try await loadDocumentTemplates(department: department)
            await updateProgress(operation: .templateLoading, progress: 0.4)
            
            // Load voice recordings
            let voiceRecordings = try await loadVoiceRecordings(providerId: providerId)
            await updateProgress(operation: .voiceLoading, progress: 0.6)
            
            // Load document workflows
            let documentWorkflows = try await loadDocumentWorkflows(department: department)
            await updateProgress(operation: .workflowLoading, progress: 0.8)
            
            // Compile documentation data
            let documentationData = try await compileDocumentationData(
                activeDocuments: activeDocuments,
                documentTemplates: documentTemplates,
                voiceRecordings: voiceRecordings,
                documentWorkflows: documentWorkflows
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            documentationStatus = .loaded
            
            // Update documentation data
            await MainActor.run {
                self.documentationData = documentationData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("documentation_data_loaded", properties: [
                "provider_id": providerId,
                "department": department.rawValue,
                "documents_count": activeDocuments.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return documentationData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.documentationStatus = .error
            }
            throw error
        }
    }
    
    /// Create clinical document
    public func createClinicalDocument(template: DocumentTemplate, data: DocumentData) async throws -> ClinicalDocument {
        documentationStatus = .creating
        currentOperation = .documentCreation
        progress = 0.0
        lastError = nil
        
        do {
            // Validate template
            try await validateTemplate(template: template)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Initialize document
            let document = try await initializeDocument(template: template, data: data)
            await updateProgress(operation: .initialization, progress: 0.3)
            
            // Populate content
            let populatedDocument = try await populateContent(document: document, data: data)
            await updateProgress(operation: .contentPopulation, progress: 0.5)
            
            // Apply formatting
            let formattedDocument = try await applyFormatting(document: populatedDocument)
            await updateProgress(operation: .formatting, progress: 0.7)
            
            // Finalize document
            let finalizedDocument = try await finalizeDocument(document: formattedDocument)
            await updateProgress(operation: .finalization, progress: 0.9)
            
            // Complete creation
            documentationStatus = .created
            
            // Store document
            activeDocuments[finalizedDocument.documentId] = finalizedDocument
            
            return finalizedDocument
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.documentationStatus = .error
            }
            throw error
        }
    }
    
    /// Start voice recording
    public func startVoiceRecording(recordingData: VoiceRecordingData) async throws -> VoiceRecording {
        documentationStatus = .recording
        currentOperation = .voiceRecording
        progress = 0.0
        lastError = nil
        
        do {
            // Validate recording data
            try await validateRecordingData(recordingData: recordingData)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Initialize recording
            let recording = try await initializeRecording(recordingData: recordingData)
            await updateProgress(operation: .initialization, progress: 0.3)
            
            // Start recording
            let activeRecording = try await startRecording(recording: recording)
            await updateProgress(operation: .recordingStart, progress: 0.6)
            
            // Monitor recording
            try await monitorRecording(recording: activeRecording)
            await updateProgress(operation: .monitoring, progress: 1.0)
            
            // Complete recording
            documentationStatus = .recorded
            
            // Store recording
            voiceRecordings.append(activeRecording)
            
            return activeRecording
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.documentationStatus = .error
            }
            throw error
        }
    }
    
    /// Convert voice to text
    public func convertVoiceToText(recordingId: String) async throws -> VoiceToTextResult {
        documentationStatus = .converting
        currentOperation = .voiceToText
        progress = 0.0
        lastError = nil
        
        do {
            // Find recording
            guard let recording = voiceRecordings.first(where: { $0.recordingId == recordingId }) else {
                throw DocumentationError.recordingNotFound
            }
            
            // Validate recording
            try await validateRecording(recording: recording)
            await updateProgress(operation: .validation, progress: 0.2)
            
            // Process audio
            let processedAudio = try await processAudio(recording: recording)
            await updateProgress(operation: .audioProcessing, progress: 0.4)
            
            // Convert to text
            let textResult = try await convertToText(processedAudio: processedAudio)
            await updateProgress(operation: .textConversion, progress: 0.7)
            
            // Format text
            let formattedText = try await formatText(textResult: textResult)
            await updateProgress(operation: .textFormatting, progress: 1.0)
            
            // Complete conversion
            documentationStatus = .converted
            
            return formattedText
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.documentationStatus = .error
            }
            throw error
        }
    }
    
    /// Update clinical document
    public func updateClinicalDocument(documentId: String, updates: DocumentUpdates) async throws -> ClinicalDocument {
        documentationStatus = .updating
        currentOperation = .documentUpdate
        progress = 0.0
        lastError = nil
        
        do {
            // Find document
            guard let document = activeDocuments[documentId] else {
                throw DocumentationError.documentNotFound
            }
            
            // Validate updates
            try await validateDocumentUpdates(updates: updates)
            await updateProgress(operation: .validation, progress: 0.3)
            
            // Apply updates
            let updatedDocument = try await applyDocumentUpdates(document: document, updates: updates)
            await updateProgress(operation: .updateApplication, progress: 0.7)
            
            // Update document
            activeDocuments[documentId] = updatedDocument
            await updateProgress(operation: .storage, progress: 1.0)
            
            // Complete update
            documentationStatus = .updated
            
            return updatedDocument
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.documentationStatus = .error
            }
            throw error
        }
    }
    
    /// Get document templates
    public func getDocumentTemplates(department: Department, documentType: DocumentType) async throws -> [DocumentTemplate] {
        let templateRequest = TemplateRequest(
            department: department,
            documentType: documentType,
            timestamp: Date()
        )
        
        return try await templateManager.getTemplates(templateRequest)
    }
    
    /// Get documentation status
    public func getDocumentationStatus() -> DocumentationStatus {
        return documentationStatus
    }
    
    /// Get current notifications
    public func getCurrentNotifications() -> [DocumentationNotification] {
        return notifications
    }
    
    // MARK: - Private Methods
    
    private func setupClinicalDocumentation() {
        // Setup clinical documentation
        setupDocumentManagement()
        setupContentManagement()
        setupVersionControl()
        setupCollaboration()
    }
    
    private func setupTemplateManagement() {
        // Setup template management
        setupTemplateCreation()
        setupTemplateCustomization()
        setupTemplateVersioning()
        setupTemplateSharing()
    }
    
    private func setupVoiceToText() {
        // Setup voice to text
        setupAudioProcessing()
        setupSpeechRecognition()
        setupTextFormatting()
        setupAccuracyImprovement()
    }
    
    private func setupWorkflowManagement() {
        // Setup workflow management
        setupWorkflowCreation()
        setupWorkflowExecution()
        setupWorkflowMonitoring()
        setupWorkflowOptimization()
    }
    
    private func setupNotificationSystem() {
        // Setup notification system
        setupDocumentNotifications()
        setupVoiceNotifications()
        setupWorkflowNotifications()
        setupCollaborationNotifications()
    }
    
    private func loadActiveDocuments(providerId: String, department: Department) async throws -> [ClinicalDocument] {
        // Load active documents
        let documentRequest = ActiveDocumentsRequest(
            providerId: providerId,
            department: department,
            timestamp: Date()
        )
        
        return try await documentManager.loadActiveDocuments(documentRequest)
    }
    
    private func loadDocumentTemplates(department: Department) async throws -> [DocumentTemplate] {
        // Load document templates
        let templateRequest = DocumentTemplatesRequest(
            department: department,
            timestamp: Date()
        )
        
        return try await templateManager.loadDocumentTemplates(templateRequest)
    }
    
    private func loadVoiceRecordings(providerId: String) async throws -> [VoiceRecording] {
        // Load voice recordings
        let voiceRequest = VoiceRecordingsRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await voiceManager.loadVoiceRecordings(voiceRequest)
    }
    
    private func loadDocumentWorkflows(department: Department) async throws -> [DocumentWorkflow] {
        // Load document workflows
        let workflowRequest = DocumentWorkflowsRequest(
            department: department,
            timestamp: Date()
        )
        
        return try await workflowManager.loadDocumentWorkflows(workflowRequest)
    }
    
    private func compileDocumentationData(activeDocuments: [ClinicalDocument],
                                        documentTemplates: [DocumentTemplate],
                                        voiceRecordings: [VoiceRecording],
                                        documentWorkflows: [DocumentWorkflow]) async throws -> DocumentationData {
        // Compile documentation data
        return DocumentationData(
            activeDocuments: activeDocuments,
            documentTemplates: documentTemplates,
            voiceRecordings: voiceRecordings,
            documentWorkflows: documentWorkflows,
            totalDocuments: activeDocuments.count,
            lastUpdated: Date()
        )
    }
    
    private func validateTemplate(template: DocumentTemplate) async throws {
        // Validate template
        guard !template.templateId.isEmpty else {
            throw DocumentationError.invalidTemplateId
        }
        
        guard !template.sections.isEmpty else {
            throw DocumentationError.invalidTemplateSections
        }
        
        guard template.department.isValid else {
            throw DocumentationError.invalidDepartment
        }
    }
    
    private func initializeDocument(template: DocumentTemplate, data: DocumentData) async throws -> ClinicalDocument {
        // Initialize document
        let initRequest = DocumentInitRequest(
            template: template,
            data: data,
            timestamp: Date()
        )
        
        return try await documentManager.initializeDocument(initRequest)
    }
    
    private func populateContent(document: ClinicalDocument, data: DocumentData) async throws -> ClinicalDocument {
        // Populate content
        let populateRequest = ContentPopulationRequest(
            document: document,
            data: data,
            timestamp: Date()
        )
        
        return try await documentManager.populateContent(populateRequest)
    }
    
    private func applyFormatting(document: ClinicalDocument) async throws -> ClinicalDocument {
        // Apply formatting
        let formatRequest = FormattingRequest(
            document: document,
            timestamp: Date()
        )
        
        return try await documentManager.applyFormatting(formatRequest)
    }
    
    private func finalizeDocument(document: ClinicalDocument) async throws -> ClinicalDocument {
        // Finalize document
        let finalizeRequest = DocumentFinalizationRequest(
            document: document,
            timestamp: Date()
        )
        
        return try await documentManager.finalizeDocument(finalizeRequest)
    }
    
    private func validateRecordingData(recordingData: VoiceRecordingData) async throws {
        // Validate recording data
        guard !recordingData.providerId.isEmpty else {
            throw DocumentationError.invalidProviderId
        }
        
        guard !recordingData.documentType.rawValue.isEmpty else {
            throw DocumentationError.invalidDocumentType
        }
    }
    
    private func initializeRecording(recordingData: VoiceRecordingData) async throws -> VoiceRecording {
        // Initialize recording
        let initRequest = RecordingInitRequest(
            recordingData: recordingData,
            timestamp: Date()
        )
        
        return try await voiceManager.initializeRecording(initRequest)
    }
    
    private func startRecording(recording: VoiceRecording) async throws -> VoiceRecording {
        // Start recording
        let startRequest = RecordingStartRequest(
            recording: recording,
            timestamp: Date()
        )
        
        return try await voiceManager.startRecording(startRequest)
    }
    
    private func monitorRecording(recording: VoiceRecording) async throws {
        // Monitor recording
        let monitorRequest = RecordingMonitorRequest(
            recording: recording,
            timestamp: Date()
        )
        
        try await voiceManager.monitorRecording(monitorRequest)
    }
    
    private func validateRecording(recording: VoiceRecording) async throws {
        // Validate recording
        guard recording.status == .completed else {
            throw DocumentationError.recordingNotCompleted
        }
        
        guard !recording.audioData.isEmpty else {
            throw DocumentationError.invalidAudioData
        }
    }
    
    private func processAudio(recording: VoiceRecording) async throws -> ProcessedAudio {
        // Process audio
        let processRequest = AudioProcessingRequest(
            recording: recording,
            timestamp: Date()
        )
        
        return try await voiceManager.processAudio(processRequest)
    }
    
    private func convertToText(processedAudio: ProcessedAudio) async throws -> VoiceToTextResult {
        // Convert to text
        let convertRequest = TextConversionRequest(
            processedAudio: processedAudio,
            timestamp: Date()
        )
        
        return try await voiceManager.convertToText(convertRequest)
    }
    
    private func formatText(textResult: VoiceToTextResult) async throws -> VoiceToTextResult {
        // Format text
        let formatRequest = TextFormattingRequest(
            textResult: textResult,
            timestamp: Date()
        )
        
        return try await voiceManager.formatText(formatRequest)
    }
    
    private func validateDocumentUpdates(updates: DocumentUpdates) async throws {
        // Validate document updates
        guard !updates.content.isEmpty else {
            throw DocumentationError.invalidContent
        }
        
        guard updates.version > 0 else {
            throw DocumentationError.invalidVersion
        }
    }
    
    private func applyDocumentUpdates(document: ClinicalDocument, updates: DocumentUpdates) async throws -> ClinicalDocument {
        // Apply document updates
        let updateRequest = DocumentUpdateRequest(
            document: document,
            updates: updates,
            timestamp: Date()
        )
        
        return try await documentManager.applyDocumentUpdates(updateRequest)
    }
    
    private func updateProgress(operation: DocumentationOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct DocumentationData: Codable {
    public let activeDocuments: [ClinicalDocument]
    public let documentTemplates: [DocumentTemplate]
    public let voiceRecordings: [VoiceRecording]
    public let documentWorkflows: [DocumentWorkflow]
    public let totalDocuments: Int
    public let lastUpdated: Date
}

public struct ClinicalDocument: Codable {
    public let documentId: String
    public let templateId: String
    public let title: String
    public let documentType: DocumentType
    public let department: Department
    public let providerId: String
    public let patientId: String?
    public let sections: [DocumentSection]
    public let content: DocumentContent
    public let metadata: DocumentMetadata
    public let status: DocumentStatus
    public let version: Int
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?
}

public struct DocumentTemplate: Codable {
    public let templateId: String
    public let name: String
    public let description: String
    public let documentType: DocumentType
    public let department: Department
    public let sections: [TemplateSection]
    public let fields: [TemplateField]
    public let version: String
    public let isActive: Bool
    public let createdAt: Date
}

public struct VoiceRecording: Codable {
    public let recordingId: String
    public let providerId: String
    public let documentType: DocumentType
    public let audioData: Data
    public let duration: TimeInterval
    public let quality: AudioQuality
    public let status: RecordingStatus
    public let transcript: String?
    public let createdAt: Date
    public let completedAt: Date?
}

public struct DocumentWorkflow: Codable {
    public let workflowId: String
    public let name: String
    public let description: String
    public let documentType: DocumentType
    public let department: Department
    public let steps: [WorkflowStep]
    public let approvals: [ApprovalStep]
    public let isActive: Bool
    public let createdAt: Date
}

public struct DocumentData: Codable {
    public let patientId: String?
    public let providerId: String
    public let department: Department
    public let documentType: DocumentType
    public let customData: [String: String]
    public let attachments: [String]
}

public struct DocumentUpdates: Codable {
    public let content: [String: String]
    public let version: Int
    public let updatedBy: String
    public let changes: [DocumentChange]
    public let timestamp: Date
}

public struct VoiceRecordingData: Codable {
    public let providerId: String
    public let documentType: DocumentType
    public let department: Department
    public let patientId: String?
    public let quality: AudioQuality
    public let duration: TimeInterval?
}

public struct VoiceToTextResult: Codable {
    public let resultId: String
    public let recordingId: String
    public let transcript: String
    public let confidence: Double
    public let segments: [TextSegment]
    public let formatting: TextFormatting
    public let timestamp: Date
}

public struct DocumentationNotification: Codable {
    public let notificationId: String
    public let type: NotificationType
    public let message: String
    public let documentId: String?
    public let recordingId: String?
    public let priority: Priority
    public let isRead: Bool
    public let timestamp: Date
}

public struct DocumentSection: Codable {
    public let sectionId: String
    public let name: String
    public let type: SectionType
    public let content: String
    public let fields: [DocumentField]
    public let isRequired: Bool
    public let isCompleted: Bool
}

public struct DocumentContent: Codable {
    public let contentId: String
    public let sections: [DocumentSection]
    public let attachments: [Attachment]
    public let references: [Reference]
    public let version: Int
    public let lastModified: Date
}

public struct DocumentMetadata: Codable {
    public let author: String
    public let department: Department
    public let documentType: DocumentType
    public let patientId: String?
    public let encounterId: String?
    public let tags: [String]
    public let keywords: [String]
    public let language: String
    public let confidentiality: ConfidentialityLevel
}

public struct TemplateSection: Codable {
    public let sectionId: String
    public let name: String
    public let type: SectionType
    public let description: String
    public let fields: [TemplateField]
    public let isRequired: Bool
    public let order: Int
}

public struct TemplateField: Codable {
    public let fieldId: String
    public let name: String
    public let type: FieldType
    public let description: String
    public let isRequired: Bool
    public let defaultValue: String?
    public let validation: [String]
    public let options: [String]?
}

public struct WorkflowStep: Codable {
    public let stepId: String
    public let name: String
    public let type: StepType
    public let description: String
    public let assignedTo: String?
    public let isRequired: Bool
    public let order: Int
    public let estimatedDuration: TimeInterval
}

public struct ApprovalStep: Codable {
    public let approvalId: String
    public let stepId: String
    public let approver: String
    public let role: String
    public let isRequired: Bool
    public let order: Int
}

public struct DocumentField: Codable {
    public let fieldId: String
    public let name: String
    public let type: FieldType
    public let value: String
    public let isRequired: Bool
    public let validation: [String]
}

public struct Attachment: Codable {
    public let attachmentId: String
    public let name: String
    public let type: AttachmentType
    public let url: String
    public let size: Int64
    public let uploadedAt: Date
}

public struct Reference: Codable {
    public let referenceId: String
    public let type: ReferenceType
    public let title: String
    public let url: String
    public let citation: String
}

public struct TextSegment: Codable {
    public let segmentId: String
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let confidence: Double
    public let speaker: String?
}

public struct TextFormatting: Codable {
    public let paragraphs: [Paragraph]
    public let sentences: [Sentence]
    public let punctuation: Bool
    public let capitalization: Bool
    public let formatting: Bool
}

public struct Paragraph: Codable {
    public let paragraphId: String
    public let text: String
    public let sentences: [String]
    public let order: Int
}

public struct Sentence: Codable {
    public let sentenceId: String
    public let text: String
    public let confidence: Double
    public let order: Int
}

public struct DocumentChange: Codable {
    public let changeId: String
    public let type: ChangeType
    public let field: String
    public let oldValue: String?
    public let newValue: String?
    public let timestamp: Date
}

public struct ProcessedAudio: Codable {
    public let processedId: String
    public let recordingId: String
    public let audioData: Data
    public let format: AudioFormat
    public let quality: AudioQuality
    public let duration: TimeInterval
    public let timestamp: Date
}

// MARK: - Enums

public enum DocumentationStatus: String, Codable, CaseIterable {
    case idle, loading, loaded, creating, created, recording, recorded, converting, converted, updating, updated, error
}

public enum DocumentationOperation: String, Codable, CaseIterable {
    case none, dataLoading, documentLoading, templateLoading, voiceLoading, workflowLoading, compilation, documentCreation, voiceRecording, voiceToText, documentUpdate, validation, initialization, contentPopulation, formatting, finalization, recordingStart, monitoring, audioProcessing, textConversion, textFormatting, updateApplication, storage
}

public enum DocumentType: String, Codable, CaseIterable {
    case progressNote, dischargeSummary, consultation, procedure, assessment, plan, order, result, referral, prescription
    
    public var isValid: Bool {
        return true
    }
}

public enum DocumentStatus: String, Codable, CaseIterable {
    case draft, inProgress, completed, reviewed, approved, archived
}

public enum SectionType: String, Codable, CaseIterable {
    case header, body, conclusion, assessment, plan, orders, results, attachments
}

public enum FieldType: String, Codable, CaseIterable {
    case text, textarea, number, date, select, multiselect, checkbox, radio, file
}

public enum StepType: String, Codable, CaseIterable {
    case creation, review, approval, completion, distribution
}

public enum RecordingStatus: String, Codable, CaseIterable {
    case recording, paused, completed, failed, cancelled
}

public enum AudioQuality: String, Codable, CaseIterable {
    case low, medium, high, excellent
}

public enum AudioFormat: String, Codable, CaseIterable {
    case wav, mp3, m4a, aac, flac
}

public enum AttachmentType: String, Codable, CaseIterable {
    case image, document, video, audio, data
}

public enum ReferenceType: String, Codable, CaseIterable {
    case article, book, guideline, protocol, standard
}

public enum ChangeType: String, Codable, CaseIterable {
    case added, modified, deleted, moved
}

public enum ConfidentialityLevel: String, Codable, CaseIterable {
    case public, internal, confidential, restricted
}

public enum NotificationType: String, Codable, CaseIterable {
    case document, voice, workflow, collaboration, approval
}

public enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum Department: String, Codable, CaseIterable {
    case emergency, cardiology, neurology, oncology, pediatrics, psychiatry, surgery, internal, family, obstetrics, gynecology, dermatology, ophthalmology, orthopedics, radiology, laboratory, pharmacy, administration
    
    public var isValid: Bool {
        return true
    }
}

// MARK: - Errors

public enum DocumentationError: Error, LocalizedError {
    case invalidTemplateId
    case invalidTemplateSections
    case invalidDepartment
    case invalidProviderId
    case invalidDocumentType
    case invalidContent
    case invalidVersion
    case recordingNotCompleted
    case invalidAudioData
    case documentNotFound
    case recordingNotFound
    case templateNotFound
    case workflowNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidTemplateId:
            return "Invalid template ID"
        case .invalidTemplateSections:
            return "Invalid template sections"
        case .invalidDepartment:
            return "Invalid department"
        case .invalidProviderId:
            return "Invalid provider ID"
        case .invalidDocumentType:
            return "Invalid document type"
        case .invalidContent:
            return "Invalid content"
        case .invalidVersion:
            return "Invalid version"
        case .recordingNotCompleted:
            return "Recording not completed"
        case .invalidAudioData:
            return "Invalid audio data"
        case .documentNotFound:
            return "Document not found"
        case .recordingNotFound:
            return "Recording not found"
        case .templateNotFound:
            return "Template not found"
        case .workflowNotFound:
            return "Workflow not found"
        }
    }
}

// MARK: - Protocols

public protocol DocumentManager {
    func loadActiveDocuments(_ request: ActiveDocumentsRequest) async throws -> [ClinicalDocument]
    func initializeDocument(_ request: DocumentInitRequest) async throws -> ClinicalDocument
    func populateContent(_ request: ContentPopulationRequest) async throws -> ClinicalDocument
    func applyFormatting(_ request: FormattingRequest) async throws -> ClinicalDocument
    func finalizeDocument(_ request: DocumentFinalizationRequest) async throws -> ClinicalDocument
    func applyDocumentUpdates(_ request: DocumentUpdateRequest) async throws -> ClinicalDocument
}

public protocol TemplateManager {
    func loadDocumentTemplates(_ request: DocumentTemplatesRequest) async throws -> [DocumentTemplate]
    func getTemplates(_ request: TemplateRequest) async throws -> [DocumentTemplate]
}

public protocol VoiceToTextManager {
    func loadVoiceRecordings(_ request: VoiceRecordingsRequest) async throws -> [VoiceRecording]
    func initializeRecording(_ request: RecordingInitRequest) async throws -> VoiceRecording
    func startRecording(_ request: RecordingStartRequest) async throws -> VoiceRecording
    func monitorRecording(_ request: RecordingMonitorRequest) async throws
    func processAudio(_ request: AudioProcessingRequest) async throws -> ProcessedAudio
    func convertToText(_ request: TextConversionRequest) async throws -> VoiceToTextResult
    func formatText(_ request: TextFormattingRequest) async throws -> VoiceToTextResult
}

public protocol DocumentationWorkflowManager {
    func loadDocumentWorkflows(_ request: DocumentWorkflowsRequest) async throws -> [DocumentWorkflow]
}

// MARK: - Supporting Types

public struct ActiveDocumentsRequest: Codable {
    public let providerId: String
    public let department: Department
    public let timestamp: Date
}

public struct DocumentTemplatesRequest: Codable {
    public let department: Department
    public let timestamp: Date
}

public struct VoiceRecordingsRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct DocumentWorkflowsRequest: Codable {
    public let department: Department
    public let timestamp: Date
}

public struct DocumentInitRequest: Codable {
    public let template: DocumentTemplate
    public let data: DocumentData
    public let timestamp: Date
}

public struct ContentPopulationRequest: Codable {
    public let document: ClinicalDocument
    public let data: DocumentData
    public let timestamp: Date
}

public struct FormattingRequest: Codable {
    public let document: ClinicalDocument
    public let timestamp: Date
}

public struct DocumentFinalizationRequest: Codable {
    public let document: ClinicalDocument
    public let timestamp: Date
}

public struct DocumentUpdateRequest: Codable {
    public let document: ClinicalDocument
    public let updates: DocumentUpdates
    public let timestamp: Date
}

public struct TemplateRequest: Codable {
    public let department: Department
    public let documentType: DocumentType
    public let timestamp: Date
}

public struct RecordingInitRequest: Codable {
    public let recordingData: VoiceRecordingData
    public let timestamp: Date
}

public struct RecordingStartRequest: Codable {
    public let recording: VoiceRecording
    public let timestamp: Date
}

public struct RecordingMonitorRequest: Codable {
    public let recording: VoiceRecording
    public let timestamp: Date
}

public struct AudioProcessingRequest: Codable {
    public let recording: VoiceRecording
    public let timestamp: Date
}

public struct TextConversionRequest: Codable {
    public let processedAudio: ProcessedAudio
    public let timestamp: Date
}

public struct TextFormattingRequest: Codable {
    public let textResult: VoiceToTextResult
    public let timestamp: Date
} 