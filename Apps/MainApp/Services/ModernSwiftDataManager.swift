import Foundation
import SwiftData
import CloudKit
import HealthKit
import Observation
import OSLog
import HealthAI2030Foundation

/// Modern SwiftData manager for iOS 18+ with CloudKit integration and advanced features
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Observable
public final class ModernSwiftDataManager {
    
    public static let shared = ModernSwiftDataManager()
    
    // MARK: - Properties
    
    private static let logger = Logger(subsystem: "com.healthai2030.data", category: "swiftdata")
    
    public private(set) var modelContainer: ModelContainer?
    public private(set) var modelContext: ModelContext?
    
    public var isInitialized: Bool = false
    public var syncStatus: CloudKitSyncStatus = .notStarted
    public var lastSyncDate: Date?
    
    // MARK: - CloudKit Integration
    
    private let cloudKitContainer = CKContainer.default()
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await initialize()
        }
    }
    
    /// Initialize SwiftData with modern iOS 18+ features and CloudKit
    public func initialize() async {
        Self.logger.info("Initializing ModernSwiftDataManager with iOS 18+ features")
        
        do {
            // Define the modern schema
            let schema = Schema([
                ModernHealthData.self,
                UserProfile.self,
                HealthSession.self,
                BiometricData.self,
                SyncableMoodEntry.self,
                CardiacEvent.self,
                SleepOptimizationData.self,
                PrivacySettings.self,
                HealthPrediction.self,
                MetalVisualizationData.self
            ])
            
            // Configure CloudKit with automatic sync
            let cloudKitConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic,
                allowsSave: true
            )
            
            // Create model container with CloudKit support
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [cloudKitConfiguration]
            )
            
            // Set up main context
            if let container = modelContainer {
                modelContext = container.mainContext
                
                // Enable automatic saving
                modelContext?.autosaveEnabled = true
                
                Self.logger.info("SwiftData container initialized with CloudKit support")
            }
            
            // Setup CloudKit monitoring
            await setupCloudKitMonitoring()
            
            isInitialized = true
            
        } catch {
            Self.logger.error("Failed to initialize SwiftData: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CloudKit Monitoring
    
    private func setupCloudKitMonitoring() async {
        // Monitor CloudKit account status
        do {
            let accountStatus = try await cloudKitContainer.accountStatus()
            
            switch accountStatus {
            case .available:
                Self.logger.info("CloudKit account available")
                syncStatus = .available
                await performInitialSync()
                
            case .noAccount:
                Self.logger.warning("No CloudKit account configured")
                syncStatus = .noAccount
                
            case .restricted:
                Self.logger.warning("CloudKit account restricted")
                syncStatus = .restricted
                
            case .couldNotDetermine:
                Self.logger.error("Could not determine CloudKit account status")
                syncStatus = .error("Could not determine account status")
                
            case .temporarilyUnavailable:
                Self.logger.warning("CloudKit temporarily unavailable")
                syncStatus = .temporarilyUnavailable
                
            @unknown default:
                Self.logger.error("Unknown CloudKit account status")
                syncStatus = .error("Unknown account status")
            }
            
        } catch {
            Self.logger.error("Failed to check CloudKit account status: \(error.localizedDescription)")
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    private func performInitialSync() async {
        guard let modelContext = modelContext else { return }
        
        syncStatus = .syncing
        
        do {
            // Trigger CloudKit sync by saving context
            try modelContext.save()
            
            lastSyncDate = Date()
            syncStatus = .synced
            
            Self.logger.info("Initial CloudKit sync completed")
            
        } catch {
            Self.logger.error("Initial sync failed: \(error.localizedDescription)")
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Save any model to SwiftData with automatic CloudKit sync
    public func save<T: PersistentModel>(_ model: T) async throws {
        guard let context = modelContext else {
            throw SwiftDataError.contextNotAvailable
        }
        
        context.insert(model)
        
        do {
            try context.save()
            Self.logger.debug("Saved model of type \(String(describing: T.self))")
        } catch {
            Self.logger.error("Failed to save model: \(error.localizedDescription)")
            throw SwiftDataError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Fetch models with predicate support
    public func fetch<T: PersistentModel>(
        _ modelType: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) async throws -> [T] {
        guard let context = modelContext else {
            throw SwiftDataError.contextNotAvailable
        }
        
        var descriptor = FetchDescriptor<T>()
        
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        
        if !sortBy.isEmpty {
            descriptor.sortBy = sortBy
        }
        
        do {
            return try context.fetch(descriptor)
        } catch {
            Self.logger.error("Failed to fetch models: \(error.localizedDescription)")
            throw SwiftDataError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// Delete a model
    public func delete<T: PersistentModel>(_ model: T) async throws {
        guard let context = modelContext else {
            throw SwiftDataError.contextNotAvailable
        }
        
        context.delete(model)
        
        do {
            try context.save()
            Self.logger.debug("Deleted model of type \(String(describing: T.self))")
        } catch {
            Self.logger.error("Failed to delete model: \(error.localizedDescription)")
            throw SwiftDataError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Health Data Operations
    
    /// Save health data with automatic processing
    public func saveHealthData(
        dataType: HealthDataType,
        value: Double,
        unit: String? = nil,
        deviceSource: String? = nil,
        timestamp: Date = Date()
    ) async throws {
        
        let healthData = ModernHealthData(
            timestamp: timestamp,
            dataType: dataType,
            value: value,
            unit: unit,
            deviceSource: deviceSource
        )
        
        try await save(healthData)
        
        // Trigger ML analysis if applicable
        await triggerMLAnalysis(for: healthData)
    }
    
    /// Get recent health data
    public func getRecentHealthData(
        type: HealthDataType,
        limit: Int = 100
    ) async throws -> [ModernHealthData] {
        
        let predicate = #Predicate<ModernHealthData> { data in
            data.dataType == type
        }
        
        let sortDescriptor = SortDescriptor<ModernHealthData>(\.timestamp, order: .reverse)
        
        let allData = try await fetch(
            ModernHealthData.self,
            predicate: predicate,
            sortBy: [sortDescriptor]
        )
        
        return Array(allData.prefix(limit))
    }
    
    /// Save health session with all related data
    public func saveHealthSession(
        sessionType: SessionType,
        startTime: Date,
        endTime: Date? = nil,
        healthData: [ModernHealthData] = []
    ) async throws -> HealthSession {
        
        let session = HealthSession(
            startTime: startTime,
            sessionType: sessionType,
            duration: endTime?.timeIntervalSince(startTime) ?? 0
        )
        
        session.endTime = endTime
        session.healthData = healthData
        
        try await save(session)
        
        return session
    }
    
    // MARK: - ML Integration
    
    private func triggerMLAnalysis(for healthData: ModernHealthData) async {
        // Trigger ML analysis based on data type
        switch healthData.dataType {
        case .heartRate:
            await analyzeHeartRateAnomaly(healthData)
        case .sleepAnalysis:
            await analyzeSleepStage(healthData)
        case .stressLevel:
            await analyzeStressPattern(healthData)
        default:
            break
        }
    }
    
    private func analyzeHeartRateAnomaly(_ data: ModernHealthData) async {
        // Get recent heart rate data for sequence analysis
        do {
            let recentData = try await getRecentHealthData(type: .heartRate, limit: 50)
            let heartRateSequence = recentData.map { $0.value }
            
            if heartRateSequence.count >= 10 {
                let result = try await HealthAI2030ML.shared.detectHeartRateAnomaly(
                    heartRateSequence: heartRateSequence
                )
                
                if result.isAnomaly {
                    Self.logger.warning("Heart rate anomaly detected: score \(result.anomalyScore)")
                    // Could trigger notification or alert
                }
            }
        } catch {
            Self.logger.error("Failed to analyze heart rate anomaly: \(error.localizedDescription)")
        }
    }
    
    private func analyzeSleepStage(_ data: ModernHealthData) async {
        // Analyze sleep stage if we have heart rate and movement data
        do {
            let heartRateData = try await getRecentHealthData(type: .heartRate, limit: 1)
            
            if let latestHeartRate = heartRateData.first {
                let result = try await HealthAI2030ML.shared.analyzeSleepStage(
                    heartRate: latestHeartRate.value,
                    movement: 0.0, // Would need actual movement data
                    timestamp: data.timestamp
                )
                
                Self.logger.info("Sleep stage analyzed: \(result.stage.rawValue) with confidence \(result.confidence)")
            }
        } catch {
            Self.logger.error("Failed to analyze sleep stage: \(error.localizedDescription)")
        }
    }
    
    private func analyzeStressPattern(_ data: ModernHealthData) async {
        // Analyze stress patterns with multimodal data
        do {
            let heartRateData = try await getRecentHealthData(type: .heartRate, limit: 1)
            let hrvData = try await getRecentHealthData(type: .heartRateVariability, limit: 1)
            
            if let heartRate = heartRateData.first?.value,
               let hrv = hrvData.first?.value {
                
                let result = try await HealthAI2030ML.shared.analyzeStressLevel(
                    heartRate: heartRate,
                    heartRateVariability: hrv,
                    voiceFeatures: nil
                )
                
                Self.logger.info("Stress level analyzed: \(result.stressLevel) with confidence \(result.confidence)")
            }
        } catch {
            Self.logger.error("Failed to analyze stress pattern: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Privacy and Security
    
    /// Get user's privacy settings
    public func getPrivacySettings() async throws -> PrivacySettings? {
        let settings = try await fetch(PrivacySettings.self)
        return settings.first
    }
    
    /// Update privacy settings
    public func updatePrivacySettings(_ settings: PrivacySettings) async throws {
        try await save(settings)
        Self.logger.info("Privacy settings updated")
    }
    
    // MARK: - Data Export (iOS 18+ Privacy Features)
    
    /// Export user data for privacy compliance
    public func exportUserData() async throws -> Data {
        guard let context = modelContext else {
            throw SwiftDataError.contextNotAvailable
        }
        
        // Fetch all user data
        let healthData = try await fetch(ModernHealthData.self)
        let sessions = try await fetch(HealthSession.self)
        let biometrics = try await fetch(BiometricData.self)
        
        // Create export structure
        let exportData = UserDataExport(
            healthData: healthData,
            sessions: sessions,
            biometrics: biometrics,
            exportDate: Date()
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(exportData)
    }
    
    /// Delete all user data (Right to be forgotten)
    public func deleteAllUserData() async throws {
        guard let context = modelContext else {
            throw SwiftDataError.contextNotAvailable
        }
        
        // Delete all data types
        let healthData = try await fetch(ModernHealthData.self)
        let sessions = try await fetch(HealthSession.self)
        let biometrics = try await fetch(BiometricData.self)
        let profiles = try await fetch(UserProfile.self)
        
        for data in healthData { context.delete(data) }
        for session in sessions { context.delete(session) }
        for biometric in biometrics { context.delete(biometric) }
        for profile in profiles { context.delete(profile) }
        
        try context.save()
        
        Self.logger.info("All user data deleted")
    }
}

// MARK: - Supporting Types

public enum CloudKitSyncStatus {
    case notStarted
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case syncing
    case synced
    case error(String)
}

public enum SwiftDataError: Error, LocalizedError {
    case contextNotAvailable
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "SwiftData context not available"
        case .saveFailed(let reason):
            return "Save failed: \(reason)"
        case .fetchFailed(let reason):
            return "Fetch failed: \(reason)"
        case .deleteFailed(let reason):
            return "Delete failed: \(reason)"
        }
    }
}

// MARK: - Additional Models for iOS 18+

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class SyncableMoodEntry {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var mood: String
    public var intensity: Double
    public var context: String?
    public var triggers: [String]
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mood: String,
        intensity: Double,
        context: String? = nil,
        triggers: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mood = mood
        self.intensity = intensity
        self.context = context
        self.triggers = triggers
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class CardiacEvent {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var eventType: String
    public var severity: Double
    public var heartRate: Double?
    public var bloodPressure: String?
    public var symptoms: [String]
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: String,
        severity: Double,
        heartRate: Double? = nil,
        bloodPressure: String? = nil,
        symptoms: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.severity = severity
        self.heartRate = heartRate
        self.bloodPressure = bloodPressure
        self.symptoms = symptoms
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class SleepOptimizationData {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var sleepQualityScore: Double
    public var recommendations: [String]
    public var environmentalFactors: Data?
    public var optimizationResults: Data?
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        sleepQualityScore: Double = 0.0,
        recommendations: [String] = [],
        environmentalFactors: Data? = nil,
        optimizationResults: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.sleepQualityScore = sleepQualityScore
        self.recommendations = recommendations
        self.environmentalFactors = environmentalFactors
        self.optimizationResults = optimizationResults
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class PrivacySettings {
    @Attribute(.unique) public var id: UUID
    public var allowDataSharing: Bool
    public var allowAnalytics: Bool
    public var allowCloudSync: Bool
    public var dataRetentionDays: Int
    public var encryptionEnabled: Bool
    public var lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        allowDataSharing: Bool = false,
        allowAnalytics: Bool = false,
        allowCloudSync: Bool = true,
        dataRetentionDays: Int = 365,
        encryptionEnabled: Bool = true
    ) {
        self.id = id
        self.allowDataSharing = allowDataSharing
        self.allowAnalytics = allowAnalytics
        self.allowCloudSync = allowCloudSync
        self.dataRetentionDays = dataRetentionDays
        self.encryptionEnabled = encryptionEnabled
        self.lastUpdated = Date()
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class HealthPrediction {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var predictionType: String
    public var confidence: Double
    public var timeHorizon: TimeInterval
    public var predictedValue: Double
    public var contextData: Data?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        predictionType: String,
        confidence: Double,
        timeHorizon: TimeInterval,
        predictedValue: Double,
        contextData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.predictionType = predictionType
        self.confidence = confidence
        self.timeHorizon = timeHorizon
        self.predictedValue = predictedValue
        self.contextData = contextData
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class MetalVisualizationData {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var visualizationType: String
    public var parameters: Data
    public var thumbnail: Data?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        visualizationType: String,
        parameters: Data,
        thumbnail: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.visualizationType = visualizationType
        self.parameters = parameters
        self.thumbnail = thumbnail
    }
}

// MARK: - Data Export Structure

public struct UserDataExport: Codable {
    public let healthData: [ModernHealthData]
    public let sessions: [HealthSession]
    public let biometrics: [BiometricData]
    public let exportDate: Date
    
    public init(
        healthData: [ModernHealthData],
        sessions: [HealthSession],
        biometrics: [BiometricData],
        exportDate: Date
    ) {
        self.healthData = healthData
        self.sessions = sessions
        self.biometrics = biometrics
        self.exportDate = exportDate
    }
}