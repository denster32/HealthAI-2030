import Foundation
import Combine
import SwiftUI

/// Provider Patient Communication System
/// Comprehensive communication system for healthcare providers and patients with secure messaging, video calls, and file sharing
@available(iOS 18.0, macOS 15.0, *)
public actor ProviderPatientCommunication: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var communicationStatus: CommunicationStatus = .idle
    @Published public private(set) var currentOperation: CommunicationOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var communicationData: CommunicationData = CommunicationData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var notifications: [CommunicationNotification] = []
    
    // MARK: - Private Properties
    private let messageManager: SecureMessageManager
    private let videoCallManager: VideoCallManager
    private let fileManager: SecureFileManager
    private let notificationManager: CommunicationNotificationManager
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let communicationQueue = DispatchQueue(label: "health.communication", qos: .userInitiated)
    
    // Communication data
    private var activeConversations: [String: Conversation] = [:]
    private var messageHistory: [String: [SecureMessage]] = [:]
    private var fileAttachments: [String: [SecureFile]] = [:]
    private var videoCallSessions: [String: VideoCallSession] = [:]
    
    // MARK: - Initialization
    public init(messageManager: SecureMessageManager,
                videoCallManager: VideoCallManager,
                fileManager: SecureFileManager,
                notificationManager: CommunicationNotificationManager,
                analyticsEngine: AnalyticsEngine) {
        self.messageManager = messageManager
        self.videoCallManager = videoCallManager
        self.fileManager = fileManager
        self.notificationManager = notificationManager
        self.analyticsEngine = analyticsEngine
        
        setupSecureCommunication()
        setupMessageHandling()
        setupVideoCalling()
        setupFileSharing()
        setupNotificationSystem()
    }
    
    // MARK: - Public Methods
    
    /// Load communication data
    public func loadCommunicationData(providerId: String, patientId: String? = nil) async throws -> CommunicationData {
        communicationStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load conversations
            let conversations = try await loadConversations(providerId: providerId, patientId: patientId)
            await updateProgress(operation: .conversationLoading, progress: 0.2)
            
            // Load message history
            let messageHistory = try await loadMessageHistory(conversations: conversations)
            await updateProgress(operation: .messageLoading, progress: 0.4)
            
            // Load file attachments
            let fileAttachments = try await loadFileAttachments(conversations: conversations)
            await updateProgress(operation: .fileLoading, progress: 0.6)
            
            // Load video call sessions
            let videoCallSessions = try await loadVideoCallSessions(conversations: conversations)
            await updateProgress(operation: .videoLoading, progress: 0.8)
            
            // Compile communication data
            let communicationData = try await compileCommunicationData(
                conversations: conversations,
                messageHistory: messageHistory,
                fileAttachments: fileAttachments,
                videoCallSessions: videoCallSessions
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            communicationStatus = .loaded
            
            // Update communication data
            await MainActor.run {
                self.communicationData = communicationData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("communication_data_loaded", properties: [
                "provider_id": providerId,
                "patient_id": patientId ?? "all",
                "conversations_count": conversations.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return communicationData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.communicationStatus = .error
            }
            throw error
        }
    }
    
    /// Send secure message
    public func sendSecureMessage(message: SecureMessage) async throws -> MessageResult {
        communicationStatus = .sending
        currentOperation = .messageSending
        progress = 0.0
        lastError = nil
        
        do {
            // Validate message
            try await validateMessage(message: message)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Encrypt message
            let encryptedMessage = try await encryptMessage(message: message)
            await updateProgress(operation: .encryption, progress: 0.3)
            
            // Send message
            let result = try await sendMessage(encryptedMessage: encryptedMessage)
            await updateProgress(operation: .sending, progress: 0.6)
            
            // Update message history
            try await updateMessageHistory(message: message, result: result)
            await updateProgress(operation: .history, progress: 0.8)
            
            // Send notification
            try await sendMessageNotification(message: message, result: result)
            await updateProgress(operation: .notification, progress: 1.0)
            
            // Complete sending
            communicationStatus = .sent
            
            return result
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.communicationStatus = .error
            }
            throw error
        }
    }
    
    /// Start video call
    public func startVideoCall(request: VideoCallRequest) async throws -> VideoCallSession {
        communicationStatus = .connecting
        currentOperation = .videoCallStarting
        progress = 0.0
        lastError = nil
        
        do {
            // Validate video call request
            try await validateVideoCallRequest(request: request)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Initialize video call
            let session = try await initializeVideoCall(request: request)
            await updateProgress(operation: .initialization, progress: 0.3)
            
            // Connect participants
            try await connectParticipants(session: session)
            await updateProgress(operation: .connection, progress: 0.6)
            
            // Start recording (if enabled)
            if request.enableRecording {
                try await startRecording(session: session)
            }
            await updateProgress(operation: .recording, progress: 0.8)
            
            // Complete connection
            communicationStatus = .connected
            
            // Store video call session
            videoCallSessions[session.sessionId] = session
            
            return session
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.communicationStatus = .error
            }
            throw error
        }
    }
    
    /// End video call
    public func endVideoCall(sessionId: String) async throws -> VideoCallResult {
        communicationStatus = .disconnecting
        currentOperation = .videoCallEnding
        progress = 0.0
        lastError = nil
        
        do {
            // Find session
            guard let session = videoCallSessions[sessionId] else {
                throw CommunicationError.sessionNotFound
            }
            
            // Stop recording
            if session.isRecording {
                try await stopRecording(session: session)
            }
            await updateProgress(operation: .recordingStop, progress: 0.3)
            
            // Disconnect participants
            try await disconnectParticipants(session: session)
            await updateProgress(operation: .disconnection, progress: 0.6)
            
            // End session
            let result = try await endSession(session: session)
            await updateProgress(operation: .sessionEnd, progress: 0.8)
            
            // Clean up session
            videoCallSessions.removeValue(forKey: sessionId)
            await updateProgress(operation: .cleanup, progress: 1.0)
            
            // Complete disconnection
            communicationStatus = .disconnected
            
            return result
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.communicationStatus = .error
            }
            throw error
        }
    }
    
    /// Share secure file
    public func shareSecureFile(file: SecureFile, recipients: [String]) async throws -> FileShareResult {
        communicationStatus = .sharing
        currentOperation = .fileSharing
        progress = 0.0
        lastError = nil
        
        do {
            // Validate file
            try await validateFile(file: file)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Encrypt file
            let encryptedFile = try await encryptFile(file: file)
            await updateProgress(operation: .encryption, progress: 0.3)
            
            // Upload file
            let uploadResult = try await uploadFile(encryptedFile: encryptedFile)
            await updateProgress(operation: .upload, progress: 0.5)
            
            // Share with recipients
            let shareResult = try await shareWithRecipients(file: uploadResult, recipients: recipients)
            await updateProgress(operation: .sharing, progress: 0.8)
            
            // Send notifications
            try await sendFileShareNotifications(file: file, recipients: recipients)
            await updateProgress(operation: .notification, progress: 1.0)
            
            // Complete sharing
            communicationStatus = .shared
            
            return shareResult
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.communicationStatus = .error
            }
            throw error
        }
    }
    
    /// Get communication notifications
    public func getCommunicationNotifications(userId: String) async throws -> [CommunicationNotification] {
        let notificationRequest = CommunicationNotificationRequest(
            userId: userId,
            timestamp: Date()
        )
        
        let notifications = try await notificationManager.getNotifications(notificationRequest)
        
        // Update notifications
        await MainActor.run {
            self.notifications = notifications
        }
        
        return notifications
    }
    
    /// Get communication status
    public func getCommunicationStatus() -> CommunicationStatus {
        return communicationStatus
    }
    
    /// Get current notifications
    public func getCurrentNotifications() -> [CommunicationNotification] {
        return notifications
    }
    
    // MARK: - Private Methods
    
    private func setupSecureCommunication() {
        // Setup secure communication
        setupEncryption()
        setupAuthentication()
        setupAuthorization()
        setupAuditTrail()
    }
    
    private func setupMessageHandling() {
        // Setup message handling
        setupMessageValidation()
        setupMessageEncryption()
        setupMessageDelivery()
        setupMessageHistory()
    }
    
    private func setupVideoCalling() {
        // Setup video calling
        setupVideoCallInitialization()
        setupVideoCallConnection()
        setupVideoCallRecording()
        setupVideoCallQuality()
    }
    
    private func setupFileSharing() {
        // Setup file sharing
        setupFileValidation()
        setupFileEncryption()
        setupFileUpload()
        setupFileSharing()
    }
    
    private func setupNotificationSystem() {
        // Setup notification system
        setupMessageNotifications()
        setupVideoCallNotifications()
        setupFileShareNotifications()
        setupNotificationDelivery()
    }
    
    private func loadConversations(providerId: String, patientId: String?) async throws -> [Conversation] {
        // Load conversations
        let conversationRequest = ConversationRequest(
            providerId: providerId,
            patientId: patientId,
            timestamp: Date()
        )
        
        return try await messageManager.loadConversations(conversationRequest)
    }
    
    private func loadMessageHistory(conversations: [Conversation]) async throws -> [String: [SecureMessage]] {
        // Load message history
        let historyRequest = MessageHistoryRequest(
            conversationIds: conversations.map { $0.conversationId },
            timestamp: Date()
        )
        
        return try await messageManager.loadMessageHistory(historyRequest)
    }
    
    private func loadFileAttachments(conversations: [Conversation]) async throws -> [String: [SecureFile]] {
        // Load file attachments
        let fileRequest = FileAttachmentsRequest(
            conversationIds: conversations.map { $0.conversationId },
            timestamp: Date()
        )
        
        return try await fileManager.loadFileAttachments(fileRequest)
    }
    
    private func loadVideoCallSessions(conversations: [Conversation]) async throws -> [String: VideoCallSession] {
        // Load video call sessions
        let sessionRequest = VideoCallSessionsRequest(
            conversationIds: conversations.map { $0.conversationId },
            timestamp: Date()
        )
        
        return try await videoCallManager.loadVideoCallSessions(sessionRequest)
    }
    
    private func compileCommunicationData(conversations: [Conversation],
                                        messageHistory: [String: [SecureMessage]],
                                        fileAttachments: [String: [SecureFile]],
                                        videoCallSessions: [String: VideoCallSession]) async throws -> CommunicationData {
        // Compile communication data
        return CommunicationData(
            conversations: conversations,
            messageHistory: messageHistory,
            fileAttachments: fileAttachments,
            videoCallSessions: videoCallSessions,
            totalMessages: messageHistory.values.flatMap { $0 }.count,
            lastUpdated: Date()
        )
    }
    
    private func validateMessage(message: SecureMessage) async throws {
        // Validate message
        guard !message.senderId.isEmpty else {
            throw CommunicationError.invalidSenderId
        }
        
        guard !message.recipientId.isEmpty else {
            throw CommunicationError.invalidRecipientId
        }
        
        guard !message.content.isEmpty else {
            throw CommunicationError.emptyMessage
        }
        
        guard message.type.isValid else {
            throw CommunicationError.invalidMessageType
        }
    }
    
    private func encryptMessage(message: SecureMessage) async throws -> EncryptedMessage {
        // Encrypt message
        let encryptionRequest = MessageEncryptionRequest(
            message: message,
            timestamp: Date()
        )
        
        return try await messageManager.encryptMessage(encryptionRequest)
    }
    
    private func sendMessage(encryptedMessage: EncryptedMessage) async throws -> MessageResult {
        // Send message
        let sendRequest = MessageSendRequest(
            encryptedMessage: encryptedMessage,
            timestamp: Date()
        )
        
        return try await messageManager.sendMessage(sendRequest)
    }
    
    private func updateMessageHistory(message: SecureMessage, result: MessageResult) async throws {
        // Update message history
        let historyRequest = MessageHistoryUpdateRequest(
            message: message,
            result: result,
            timestamp: Date()
        )
        
        try await messageManager.updateMessageHistory(historyRequest)
    }
    
    private func sendMessageNotification(message: SecureMessage, result: MessageResult) async throws {
        // Send message notification
        let notificationRequest = MessageNotificationRequest(
            message: message,
            result: result,
            timestamp: Date()
        )
        
        try await notificationManager.sendMessageNotification(notificationRequest)
    }
    
    private func validateVideoCallRequest(request: VideoCallRequest) async throws {
        // Validate video call request
        guard !request.initiatorId.isEmpty else {
            throw CommunicationError.invalidInitiatorId
        }
        
        guard !request.participantIds.isEmpty else {
            throw CommunicationError.invalidParticipantIds
        }
        
        guard request.duration > 0 else {
            throw CommunicationError.invalidDuration
        }
    }
    
    private func initializeVideoCall(request: VideoCallRequest) async throws -> VideoCallSession {
        // Initialize video call
        let initRequest = VideoCallInitRequest(
            request: request,
            timestamp: Date()
        )
        
        return try await videoCallManager.initializeVideoCall(initRequest)
    }
    
    private func connectParticipants(session: VideoCallSession) async throws {
        // Connect participants
        let connectionRequest = ParticipantConnectionRequest(
            session: session,
            timestamp: Date()
        )
        
        try await videoCallManager.connectParticipants(connectionRequest)
    }
    
    private func startRecording(session: VideoCallSession) async throws {
        // Start recording
        let recordingRequest = RecordingStartRequest(
            session: session,
            timestamp: Date()
        )
        
        try await videoCallManager.startRecording(recordingRequest)
    }
    
    private func stopRecording(session: VideoCallSession) async throws {
        // Stop recording
        let recordingRequest = RecordingStopRequest(
            session: session,
            timestamp: Date()
        )
        
        try await videoCallManager.stopRecording(recordingRequest)
    }
    
    private func disconnectParticipants(session: VideoCallSession) async throws {
        // Disconnect participants
        let disconnectionRequest = ParticipantDisconnectionRequest(
            session: session,
            timestamp: Date()
        )
        
        try await videoCallManager.disconnectParticipants(disconnectionRequest)
    }
    
    private func endSession(session: VideoCallSession) async throws -> VideoCallResult {
        // End session
        let endRequest = VideoCallEndRequest(
            session: session,
            timestamp: Date()
        )
        
        return try await videoCallManager.endSession(endRequest)
    }
    
    private func validateFile(file: SecureFile) async throws {
        // Validate file
        guard !file.fileName.isEmpty else {
            throw CommunicationError.invalidFileName
        }
        
        guard file.fileSize > 0 else {
            throw CommunicationError.invalidFileSize
        }
        
        guard file.fileType.isValid else {
            throw CommunicationError.invalidFileType
        }
    }
    
    private func encryptFile(file: SecureFile) async throws -> EncryptedFile {
        // Encrypt file
        let encryptionRequest = FileEncryptionRequest(
            file: file,
            timestamp: Date()
        )
        
        return try await fileManager.encryptFile(encryptionRequest)
    }
    
    private func uploadFile(encryptedFile: EncryptedFile) async throws -> UploadResult {
        // Upload file
        let uploadRequest = FileUploadRequest(
            encryptedFile: encryptedFile,
            timestamp: Date()
        )
        
        return try await fileManager.uploadFile(uploadRequest)
    }
    
    private func shareWithRecipients(file: UploadResult, recipients: [String]) async throws -> FileShareResult {
        // Share with recipients
        let shareRequest = FileShareRequest(
            file: file,
            recipients: recipients,
            timestamp: Date()
        )
        
        return try await fileManager.shareWithRecipients(shareRequest)
    }
    
    private func sendFileShareNotifications(file: SecureFile, recipients: [String]) async throws {
        // Send file share notifications
        let notificationRequest = FileShareNotificationRequest(
            file: file,
            recipients: recipients,
            timestamp: Date()
        )
        
        try await notificationManager.sendFileShareNotification(notificationRequest)
    }
    
    private func updateProgress(operation: CommunicationOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct CommunicationData: Codable {
    public let conversations: [Conversation]
    public let messageHistory: [String: [SecureMessage]]
    public let fileAttachments: [String: [SecureFile]]
    public let videoCallSessions: [String: VideoCallSession]
    public let totalMessages: Int
    public let lastUpdated: Date
}

public struct SecureMessage: Codable {
    public let messageId: String
    public let conversationId: String
    public let senderId: String
    public let recipientId: String
    public let content: String
    public let type: MessageType
    public let attachments: [String]
    public let timestamp: Date
    public let status: MessageStatus
    public let isEncrypted: Bool
}

public struct Conversation: Codable {
    public let conversationId: String
    public let participants: [String]
    public let title: String
    public let type: ConversationType
    public let lastMessage: SecureMessage?
    public let unreadCount: Int
    public let createdAt: Date
    public let updatedAt: Date
}

public struct VideoCallSession: Codable {
    public let sessionId: String
    public let conversationId: String
    public let initiatorId: String
    public let participants: [String]
    public let startTime: Date
    public let endTime: Date?
    public let duration: TimeInterval
    public let status: VideoCallStatus
    public let isRecording: Bool
    public let recordingUrl: URL?
    public let quality: VideoQuality
}

public struct SecureFile: Codable {
    public let fileId: String
    public let fileName: String
    public let fileType: FileType
    public let fileSize: Int
    public let url: URL
    public let checksum: String
    public let uploadedBy: String
    public let uploadedAt: Date
    public let isEncrypted: Bool
    public let accessPermissions: [String]
}

public struct CommunicationNotification: Codable {
    public let notificationId: String
    public let userId: String
    public let type: NotificationType
    public let title: String
    public let message: String
    public let data: [String: String]
    public let isRead: Bool
    public let timestamp: Date
}

public struct MessageResult: Codable {
    public let success: Bool
    public let messageId: String
    public let deliveryStatus: DeliveryStatus
    public let timestamp: Date
}

public struct VideoCallRequest: Codable {
    public let initiatorId: String
    public let participantIds: [String]
    public let duration: TimeInterval
    public let enableRecording: Bool
    public let quality: VideoQuality
    public let title: String?
}

public struct VideoCallResult: Codable {
    public let sessionId: String
    public let duration: TimeInterval
    public let participants: [String]
    public let recordingUrl: URL?
    public let quality: VideoQuality
    public let timestamp: Date
}

public struct FileShareResult: Codable {
    public let success: Bool
    public let fileId: String
    public let shareId: String
    public let recipients: [String]
    public let accessUrl: URL?
    public let timestamp: Date
}

public struct EncryptedMessage: Codable {
    public let messageId: String
    public let encryptedContent: Data
    public let encryptionKey: String
    public let timestamp: Date
}

public struct EncryptedFile: Codable {
    public let fileId: String
    public let encryptedData: Data
    public let encryptionKey: String
    public let timestamp: Date
}

public struct UploadResult: Codable {
    public let fileId: String
    public let url: URL
    public let size: Int
    public let checksum: String
    public let timestamp: Date
}

// MARK: - Enums

public enum CommunicationStatus: String, Codable, CaseIterable {
    case idle, loading, loaded, sending, sent, connecting, connected, disconnecting, disconnected, sharing, shared, error
}

public enum CommunicationOperation: String, Codable, CaseIterable {
    case none, dataLoading, conversationLoading, messageLoading, fileLoading, videoLoading, compilation, messageSending, videoCallStarting, videoCallEnding, fileSharing, validation, encryption, sending, history, notification, initialization, connection, recording, recordingStop, disconnection, sessionEnd, cleanup, upload, sharing
}

public enum MessageType: String, Codable, CaseIterable {
    case text, image, video, audio, document, location, appointment, medication, test, result
    
    public var isValid: Bool {
        return true
    }
}

public enum MessageStatus: String, Codable, CaseIterable {
    case sent, delivered, read, failed
}

public enum ConversationType: String, Codable, CaseIterable {
    case direct, group, appointment, consultation
}

public enum VideoCallStatus: String, Codable, CaseIterable {
    case connecting, connected, disconnected, failed, ended
}

public enum VideoQuality: String, Codable, CaseIterable {
    case low, medium, high, ultra
}

public enum FileType: String, Codable, CaseIterable {
    case image, video, audio, document, pdf, spreadsheet, presentation
    
    public var isValid: Bool {
        return true
    }
}

public enum NotificationType: String, Codable, CaseIterable {
    case message, videoCall, fileShare, appointment, reminder
}

public enum DeliveryStatus: String, Codable, CaseIterable {
    case pending, sent, delivered, read, failed
}

// MARK: - Errors

public enum CommunicationError: Error, LocalizedError {
    case invalidSenderId
    case invalidRecipientId
    case emptyMessage
    case invalidMessageType
    case invalidInitiatorId
    case invalidParticipantIds
    case invalidDuration
    case invalidFileName
    case invalidFileSize
    case invalidFileType
    case sessionNotFound
    case encryptionFailed
    case decryptionFailed
    case uploadFailed
    case downloadFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidSenderId:
            return "Invalid sender ID"
        case .invalidRecipientId:
            return "Invalid recipient ID"
        case .emptyMessage:
            return "Message is empty"
        case .invalidMessageType:
            return "Invalid message type"
        case .invalidInitiatorId:
            return "Invalid initiator ID"
        case .invalidParticipantIds:
            return "Invalid participant IDs"
        case .invalidDuration:
            return "Invalid duration"
        case .invalidFileName:
            return "Invalid file name"
        case .invalidFileSize:
            return "Invalid file size"
        case .invalidFileType:
            return "Invalid file type"
        case .sessionNotFound:
            return "Session not found"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .uploadFailed:
            return "File upload failed"
        case .downloadFailed:
            return "File download failed"
        }
    }
}

// MARK: - Protocols

public protocol SecureMessageManager {
    func loadConversations(_ request: ConversationRequest) async throws -> [Conversation]
    func loadMessageHistory(_ request: MessageHistoryRequest) async throws -> [String: [SecureMessage]]
    func encryptMessage(_ request: MessageEncryptionRequest) async throws -> EncryptedMessage
    func sendMessage(_ request: MessageSendRequest) async throws -> MessageResult
    func updateMessageHistory(_ request: MessageHistoryUpdateRequest) async throws
}

public protocol VideoCallManager {
    func loadVideoCallSessions(_ request: VideoCallSessionsRequest) async throws -> [String: VideoCallSession]
    func initializeVideoCall(_ request: VideoCallInitRequest) async throws -> VideoCallSession
    func connectParticipants(_ request: ParticipantConnectionRequest) async throws
    func startRecording(_ request: RecordingStartRequest) async throws
    func stopRecording(_ request: RecordingStopRequest) async throws
    func disconnectParticipants(_ request: ParticipantDisconnectionRequest) async throws
    func endSession(_ request: VideoCallEndRequest) async throws -> VideoCallResult
}

public protocol SecureFileManager {
    func loadFileAttachments(_ request: FileAttachmentsRequest) async throws -> [String: [SecureFile]]
    func encryptFile(_ request: FileEncryptionRequest) async throws -> EncryptedFile
    func uploadFile(_ request: FileUploadRequest) async throws -> UploadResult
    func shareWithRecipients(_ request: FileShareRequest) async throws -> FileShareResult
}

public protocol CommunicationNotificationManager {
    func getNotifications(_ request: CommunicationNotificationRequest) async throws -> [CommunicationNotification]
    func sendMessageNotification(_ request: MessageNotificationRequest) async throws
    func sendFileShareNotification(_ request: FileShareNotificationRequest) async throws
}

// MARK: - Supporting Types

public struct ConversationRequest: Codable {
    public let providerId: String
    public let patientId: String?
    public let timestamp: Date
}

public struct MessageHistoryRequest: Codable {
    public let conversationIds: [String]
    public let timestamp: Date
}

public struct MessageEncryptionRequest: Codable {
    public let message: SecureMessage
    public let timestamp: Date
}

public struct MessageSendRequest: Codable {
    public let encryptedMessage: EncryptedMessage
    public let timestamp: Date
}

public struct MessageHistoryUpdateRequest: Codable {
    public let message: SecureMessage
    public let result: MessageResult
    public let timestamp: Date
}

public struct VideoCallSessionsRequest: Codable {
    public let conversationIds: [String]
    public let timestamp: Date
}

public struct VideoCallInitRequest: Codable {
    public let request: VideoCallRequest
    public let timestamp: Date
}

public struct ParticipantConnectionRequest: Codable {
    public let session: VideoCallSession
    public let timestamp: Date
}

public struct RecordingStartRequest: Codable {
    public let session: VideoCallSession
    public let timestamp: Date
}

public struct RecordingStopRequest: Codable {
    public let session: VideoCallSession
    public let timestamp: Date
}

public struct ParticipantDisconnectionRequest: Codable {
    public let session: VideoCallSession
    public let timestamp: Date
}

public struct VideoCallEndRequest: Codable {
    public let session: VideoCallSession
    public let timestamp: Date
}

public struct FileAttachmentsRequest: Codable {
    public let conversationIds: [String]
    public let timestamp: Date
}

public struct FileEncryptionRequest: Codable {
    public let file: SecureFile
    public let timestamp: Date
}

public struct FileUploadRequest: Codable {
    public let encryptedFile: EncryptedFile
    public let timestamp: Date
}

public struct FileShareRequest: Codable {
    public let file: UploadResult
    public let recipients: [String]
    public let timestamp: Date
}

public struct CommunicationNotificationRequest: Codable {
    public let userId: String
    public let timestamp: Date
}

public struct MessageNotificationRequest: Codable {
    public let message: SecureMessage
    public let result: MessageResult
    public let timestamp: Date
}

public struct FileShareNotificationRequest: Codable {
    public let file: SecureFile
    public let recipients: [String]
    public let timestamp: Date
} 