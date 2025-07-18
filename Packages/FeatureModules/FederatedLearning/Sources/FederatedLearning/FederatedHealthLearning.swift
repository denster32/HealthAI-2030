import Foundation
import HealthAI2030Core
import PrivacyPreservingML
import FederatedCoordination
import HealthMetrics
import CoreML
import OSLog

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
extension OSLog {
    static let federatedLearning = OSLog(subsystem: "com.healthai2030.federated", category: "learning")
}

/// Advanced federated learning system for privacy-preserving health AI
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
@globalActor
public actor FederatedHealthLearning {
    public static let shared = FederatedHealthLearning()
    
    private var isParticipating = false
    private var localModel: LocalHealthModel
    private var privacyEngine: PrivacyPreservingMLEngine
    private var coordinationClient: FederatedCoordinationClient
    private var aggregationEngine: ModelAggregationEngine
    private var privacyBudget: PrivacyBudget
    private var mlModelSession: MLModelSession?
    private var logger = OSLog.federatedLearning
    
    public struct LearningConfiguration {
        public let participationLevel: ParticipationLevel
        public let privacyLevel: PrivacyLevel
        public let contributionTypes: Set<ContributionType>
        public let learningObjectives: Set<LearningObjective>
        public let maxRounds: Int
        public let minimumAccuracy: Double
        
        public enum ParticipationLevel: String, Sendable {
            case observer = "observer"           // Receive updates only
            case contributor = "contributor"     // Contribute data and receive updates
            case validator = "validator"         // Validate models and contribute data
            case coordinator = "coordinator"     // Help coordinate learning rounds
        }
        
        public enum PrivacyLevel: String, Sendable {
            case maximum = "maximum"     // Highest privacy, some utility loss
            case high = "high"          // High privacy with good utility
            case medium = "medium"      // Balanced privacy and utility
            case standard = "standard"  // Standard differential privacy
        }
        
        public enum ContributionType: String, CaseIterable, Sendable {
            case heartRatePatterns = "heart_rate_patterns"
            case sleepAnalytics = "sleep_analytics"
            case activityInsights = "activity_insights"
            case stressIndicators = "stress_indicators"
            case nutritionPatterns = "nutrition_patterns"
            case generalWellness = "general_wellness"
        }
        
        public enum LearningObjective: String, CaseIterable, Sendable {
            case anomalyDetection = "anomaly_detection"
            case healthPrediction = "health_prediction"
            case personalizedRecommendations = "personalized_recommendations"
            case populationHealthInsights = "population_health_insights"
            case earlyWarningSystem = "early_warning_system"
            case treatmentOptimization = "treatment_optimization"
        }
    }
    
    private init() {
        self.localModel = LocalHealthModel()
        self.privacyEngine = PrivacyPreservingMLEngine()
        self.coordinationClient = FederatedCoordinationClient()
        self.aggregationEngine = ModelAggregationEngine()
        self.privacyBudget = PrivacyBudget()
    }
    
    // MARK: - Public Interface
    
    /// Join federated learning network
    public func joinFederatedLearning(configuration: LearningConfiguration) async throws {
        guard !isParticipating else {
            throw FederatedLearningError.alreadyParticipating
        }
        
        // Initialize privacy budget based on configuration
        await privacyBudget.initialize(level: configuration.privacyLevel)
        
        // Configure local model for specified objectives
        try await localModel.configure(
            objectives: configuration.learningObjectives,
            contributionTypes: configuration.contributionTypes
        )
        
        // Set up privacy-preserving mechanisms
        await privacyEngine.configure(
            privacyLevel: configuration.privacyLevel,
            contributionTypes: configuration.contributionTypes
        )
        
        // Connect to coordination server
        try await coordinationClient.connect(
            participationLevel: configuration.participationLevel,
            capabilities: getDeviceCapabilities()
        )
        
        isParticipating = true
        
        // Start federated learning rounds
        await startLearningProcess(configuration)
    }
    
    /// Leave federated learning network
    public func leaveFederatedLearning() async {
        guard isParticipating else { return }
        
        // Gracefully disconnect from coordination
        await coordinationClient.disconnect()
        
        // Save local model improvements
        await localModel.persistImprovements()
        
        isParticipating = false
    }
    
    /// Contribute health data to federated learning
    public func contributeHealthData(_ metrics: [HealthMetric]) async throws {
        guard isParticipating else {
            throw FederatedLearningError.notParticipating
        }
        
        // Check privacy budget
        guard await privacyBudget.canContribute() else {
            throw FederatedLearningError.privacyBudgetExhausted
        }
        
        // Apply privacy-preserving transformations
        let privatizedData = await privacyEngine.privatizeHealthData(metrics)
        
        // Update local model
        await localModel.updateWithData(privatizedData)
        
        // Consume privacy budget
        await privacyBudget.consume(for: metrics)
    }
    
    /// Get current federated learning status
    public func getFederatedLearningStatus() async -> FederatedLearningStatus {
        return FederatedLearningStatus(
            isParticipating: isParticipating,
            currentRound: await coordinationClient.getCurrentRound(),
            modelAccuracy: await localModel.getCurrentAccuracy(),
            privacyBudgetRemaining: await privacyBudget.getRemainingBudget(),
            contributionsToday: await getContributionsToday(),
            globalParticipants: await coordinationClient.getParticipantCount(),
            lastUpdate: await localModel.getLastUpdateTime()
        )
    }
    
    /// Get personalized insights from federated model
    public func getPersonalizedInsights() async -> [FederatedInsight] {
        guard isParticipating else { return [] }
        
        return await localModel.generatePersonalizedInsights()
    }
    
    /// Get population health insights (aggregated)
    public func getPopulationInsights() async -> [PopulationInsight] {
        guard isParticipating else { return [] }
        
        return await coordinationClient.getPopulationInsights()
    }
    
    // MARK: - Private Implementation
    
    private func startLearningProcess(_ configuration: LearningConfiguration) async {
        Task {
            var roundCount = 0
            
            while isParticipating && roundCount < configuration.maxRounds {
                do {
                    // Wait for coordination signal to start new round
                    await coordinationClient.waitForRoundStart()
                    
                    // Participate in federated learning round
                    try await participateInLearningRound(configuration)
                    
                    roundCount += 1
                    
                    // Check if minimum accuracy reached
                    let currentAccuracy = await localModel.getCurrentAccuracy()
                    if currentAccuracy >= configuration.minimumAccuracy {
                        print("Minimum accuracy reached: \(currentAccuracy)")
                        break
                    }
                    
                } catch {
                    print("Error in federated learning round: \(error)")
                    
                    // Exponential backoff before retry
                    let backoffTime = min(pow(2.0, Double(roundCount)), 300) // Max 5 minutes
                    try? await Task.sleep(for: .seconds(backoffTime))
                }
            }
        }
    }
    
    private func participateInLearningRound(_ configuration: LearningConfiguration) async throws {
        // Phase 1: Local training
        let localUpdate = try await performLocalTraining()
        
        // Phase 2: Privacy-preserving aggregation preparation
        let privatizedUpdate = await privacyEngine.privatizeModelUpdate(localUpdate)
        
        // Phase 3: Send update to coordination server
        try await coordinationClient.submitModelUpdate(privatizedUpdate)
        
        // Phase 4: Wait for global aggregation
        let globalUpdate = try await coordinationClient.waitForGlobalUpdate()
        
        // Phase 5: Apply global update to local model
        await localModel.applyGlobalUpdate(globalUpdate)
        
        // Phase 6: Validate update quality
        let validationScore = await validateModelUpdate(globalUpdate)
        try await coordinationClient.submitValidationScore(validationScore)
    }
    
    private func performLocalTraining() async throws -> ModelUpdate {
        // Get recent health data for training
        let recentData = await getRecentHealthData()
        
        guard !recentData.isEmpty else {
            os_log("Insufficient data for local training", log: logger, type: .error)
            throw FederatedLearningError.insufficientData
        }
        
        os_log("Starting local training with %d data points", log: logger, type: .info, recentData.count)
        
        // Initialize MLModelSession for enhanced training
        if mlModelSession == nil {
            mlModelSession = try await createMLModelSession()
        }
        
        // Perform local model training with CoreML improvements
        return try await localModel.trainLocalModelWithSession(data: recentData, session: mlModelSession)
    }
    
    @available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
    private func createMLModelSession() async throws -> MLModelSession {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        configuration.allowLowPrecisionAccumulationOnGPU = true
        
        return try MLModelSession(configuration: configuration)
    }
    
    private func validateModelUpdate(_ update: GlobalModelUpdate) async -> ValidationScore {
        // Validate the global model update on local data
        let testData = await getValidationData()
        
        return await localModel.validateUpdate(update, on: testData)
    }
    
    private func getRecentHealthData() async -> [PrivatizedHealthData] {
        // Get health data from last 7 days for training
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        
        // This would integrate with MetricsAnalyticsEngine
        // For now, return empty array
        return []
    }
    
    private func getValidationData() async -> [PrivatizedHealthData] {
        // Get separate validation dataset
        return await getRecentHealthData() // Simplified
    }
    
    private func getContributionsToday() async -> Int {
        // Count contributions made today
        return await privacyBudget.getContributionsToday()
    }
    
    private func getDeviceCapabilities() -> DeviceCapabilities {
        return DeviceCapabilities(
            computePower: .high, // Would assess actual device capabilities
            memoryAvailable: .high,
            networkQuality: .good,
            batteryLevel: .sufficient
        )
    }
}

// MARK: - Supporting Types

public struct FederatedLearningStatus: Sendable {
    public let isParticipating: Bool
    public let currentRound: Int
    public let modelAccuracy: Double
    public let privacyBudgetRemaining: Double
    public let contributionsToday: Int
    public let globalParticipants: Int
    public let lastUpdate: Date?
}

public struct FederatedInsight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let confidence: Double
    public let category: Category
    public let personalizationScore: Double // How personalized this insight is
    public let globalRelevance: Double // How relevant to global population
    
    public enum Category: String, Sendable {
        case healthPrediction = "health_prediction"
        case riskAssessment = "risk_assessment"
        case behaviorInsight = "behavior_insight"
        case treatmentRecommendation = "treatment_recommendation"
        case populationComparison = "population_comparison"
    }
}

public struct PopulationInsight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let populationSize: Int
    public let confidence: Double
    public let category: Category
    public let geographicScope: GeographicScope
    public let demographicFilters: [String]
    
    public enum Category: String, Sendable {
        case epidemiological = "epidemiological"
        case behavioral = "behavioral"
        case environmental = "environmental"
        case seasonal = "seasonal"
        case intervention = "intervention"
    }
    
    public enum GeographicScope: String, Sendable {
        case local = "local"
        case regional = "regional"
        case national = "national"
        case global = "global"
    }
}

public struct DeviceCapabilities: Sendable {
    public let computePower: ComputePower
    public let memoryAvailable: MemoryLevel
    public let networkQuality: NetworkQuality
    public let batteryLevel: BatteryLevel
    
    public enum ComputePower: String, Sendable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case very_high = "very_high"
    }
    
    public enum MemoryLevel: String, Sendable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
    
    public enum NetworkQuality: String, Sendable {
        case poor = "poor"
        case fair = "fair"
        case good = "good"
        case excellent = "excellent"
    }
    
    public enum BatteryLevel: String, Sendable {
        case critical = "critical"
        case low = "low"
        case sufficient = "sufficient"
        case high = "high"
    }
}

// MARK: - Model Types

public struct ModelUpdate: Sendable {
    public let updateId: UUID
    public let modelWeights: [String: [Float]]
    public let gradients: [String: [Float]]
    public let metadata: UpdateMetadata
    public let contributionQuality: Double
}

public struct GlobalModelUpdate: Sendable {
    public let roundNumber: Int
    public let aggregatedWeights: [String: [Float]]
    public let participantCount: Int
    public let convergenceScore: Double
    public let qualityMetrics: QualityMetrics
}

public struct UpdateMetadata: Sendable {
    public let dataSize: Int
    public let epochs: Int
    public let learningRate: Double
    public let privacyEpsilon: Double
    public let timestamp: Date
}

public struct QualityMetrics: Sendable {
    public let accuracy: Double
    public let loss: Double
    public let convergence: Double
    public let stability: Double
}

public struct ValidationScore: Sendable {
    public let accuracy: Double
    public let loss: Double
    public let consistency: Double
    public let improvements: [String]
    public let concerns: [String]
}

// MARK: - Privacy Types

public struct PrivatizedHealthData: Sendable {
    public let originalType: MetricType
    public let anonymizedValues: [Double]
    public let noiseLevel: Double
    public let aggregationLevel: AggregationLevel
    public let timestamp: Date
    
    public enum AggregationLevel: String, Sendable {
        case individual = "individual"     // Single data point with noise
        case hourly = "hourly"            // Hourly aggregates
        case daily = "daily"              // Daily aggregates
        case weekly = "weekly"            // Weekly aggregates
    }
}

// MARK: - Error Types

public enum FederatedLearningError: Error, LocalizedError, Sendable {
    case alreadyParticipating
    case notParticipating
    case privacyBudgetExhausted
    case insufficientData
    case coordinationFailure(String)
    case modelTrainingFailed(String)
    case privacyViolation
    case networkTimeout
    
    public var errorDescription: String? {
        switch self {
        case .alreadyParticipating:
            return "Already participating in federated learning"
        case .notParticipating:
            return "Not currently participating in federated learning"
        case .privacyBudgetExhausted:
            return "Privacy budget exhausted for today"
        case .insufficientData:
            return "Insufficient data for model training"
        case .coordinationFailure(let message):
            return "Coordination failure: \(message)"
        case .modelTrainingFailed(let message):
            return "Model training failed: \(message)"
        case .privacyViolation:
            return "Operation would violate privacy constraints"
        case .networkTimeout:
            return "Network operation timed out"
        }
    }
}

// MARK: - Federated Learning Views

public struct FederatedLearningView: View {
    @StateObject private var federatedLearning = FederatedHealthLearning.shared
    @State private var learningStatus: FederatedLearningStatus?
    @State private var showingConfiguration = false
    @State private var currentConfiguration: FederatedHealthLearning.LearningConfiguration?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let status = learningStatus {
                    if status.isParticipating {
                        // Active participation view
                        ParticipationStatusView(status: status)
                        
                        // Insights section
                        InsightsSection()
                        
                        // Privacy section
                        PrivacyStatusView(status: status)
                        
                        // Controls
                        Button("Leave Network") {
                            leaveNetwork()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.red)
                        
                    } else {
                        // Not participating view
                        WelcomeToFederatedLearningView(
                            onJoin: { showingConfiguration = true }
                        )
                    }
                    
                } else {
                    ProgressView("Loading...")
                }
            }
            .padding()
            .navigationTitle("Federated Learning")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await refreshStatus()
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            FederatedLearningConfigurationView(
                onConfigure: { configuration in
                    joinNetwork(with: configuration)
                }
            )
        }
        .onAppear {
            Task {
                await refreshStatus()
            }
        }
    }
    
    private func refreshStatus() async {
        learningStatus = await federatedLearning.getFederatedLearningStatus()
    }
    
    private func joinNetwork(with configuration: FederatedHealthLearning.LearningConfiguration) {
        Task {
            do {
                try await federatedLearning.joinFederatedLearning(configuration: configuration)
                await refreshStatus()
            } catch {
                print("Failed to join federated learning: \(error)")
            }
        }
    }
    
    private func leaveNetwork() {
        Task {
            await federatedLearning.leaveFederatedLearning()
            await refreshStatus()
        }
    }
}

struct ParticipationStatusView: View {
    let status: FederatedLearningStatus
    
    var body: some View {
        VStack(spacing: 16) {
            // Status indicator
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.green)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Active in Network")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    Text("\(status.globalParticipants) participants worldwide")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Metrics grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "Model Accuracy",
                    value: "\(Int(status.modelAccuracy * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Current Round",
                    value: "\(status.currentRound)",
                    icon: "arrow.clockwise.circle.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Today's Contributions",
                    value: "\(status.contributionsToday)",
                    icon: "chart.bar.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Privacy Budget",
                    value: "\(Int(status.privacyBudgetRemaining * 100))%",
                    icon: "lock.circle.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightsSection: View {
    @State private var personalizedInsights: [FederatedInsight] = []
    @State private var populationInsights: [PopulationInsight] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
            
            if !personalizedInsights.isEmpty || !populationInsights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(personalizedInsights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("Insights will appear as the model learns from your data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct PrivacyStatusView: View {
    let status: FederatedLearningStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.purple)
                
                Text("Privacy Protection")
                    .font(.headline)
                
                Spacer()
                
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2), in: Capsule())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your data is protected using differential privacy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ProgressView(value: status.privacyBudgetRemaining) {
                    Text("Privacy Budget: \(Int(status.privacyBudgetRemaining * 100))% remaining")
                        .font(.caption2)
                }
                .progressViewStyle(.linear)
                .tint(.purple)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct WelcomeToFederatedLearningView: View {
    let onJoin: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Federated Learning")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Join a global health AI network")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Privacy-First",
                    description: "Your data never leaves your device"
                )
                
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "Smarter AI",
                    description: "Contribute to better health predictions"
                )
                
                FeatureRow(
                    icon: "globe",
                    title: "Global Impact",
                    description: "Help improve health for everyone"
                )
            }
            
            Button("Join Network") {
                onJoin()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InsightCard: View {
    let insight: FederatedInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(insight.title)
                .font(.headline)
                .multilineTextAlignment(.leading)
            
            Text(insight.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding()
        .frame(width: 200)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var categoryIcon: String {
        switch insight.category {
        case .healthPrediction: return "crystal.ball.fill"
        case .riskAssessment: return "exclamationmark.triangle.fill"
        case .behaviorInsight: return "brain.head.profile"
        case .treatmentRecommendation: return "cross.case.fill"
        case .populationComparison: return "chart.bar.fill"
        }
    }
}

struct FederatedLearningConfigurationView: View {
    let onConfigure: (FederatedHealthLearning.LearningConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var participationLevel: FederatedHealthLearning.LearningConfiguration.ParticipationLevel = .contributor
    @State private var privacyLevel: FederatedHealthLearning.LearningConfiguration.PrivacyLevel = .high
    @State private var selectedContributions: Set<FederatedHealthLearning.LearningConfiguration.ContributionType> = [.generalWellness]
    @State private var selectedObjectives: Set<FederatedHealthLearning.LearningConfiguration.LearningObjective> = [.healthPrediction]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Participation") {
                    Picker("Level", selection: $participationLevel) {
                        Text("Observer").tag(FederatedHealthLearning.LearningConfiguration.ParticipationLevel.observer)
                        Text("Contributor").tag(FederatedHealthLearning.LearningConfiguration.ParticipationLevel.contributor)
                        Text("Validator").tag(FederatedHealthLearning.LearningConfiguration.ParticipationLevel.validator)
                    }
                }
                
                Section("Privacy") {
                    Picker("Privacy Level", selection: $privacyLevel) {
                        Text("Maximum").tag(FederatedHealthLearning.LearningConfiguration.PrivacyLevel.maximum)
                        Text("High").tag(FederatedHealthLearning.LearningConfiguration.PrivacyLevel.high)
                        Text("Medium").tag(FederatedHealthLearning.LearningConfiguration.PrivacyLevel.medium)
                        Text("Standard").tag(FederatedHealthLearning.LearningConfiguration.PrivacyLevel.standard)
                    }
                }
                
                Section("Data Contributions") {
                    ForEach(FederatedHealthLearning.LearningConfiguration.ContributionType.allCases, id: \.self) { type in
                        MultipleSelectionRow(
                            title: type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                            isSelected: selectedContributions.contains(type)
                        ) {
                            if selectedContributions.contains(type) {
                                selectedContributions.remove(type)
                            } else {
                                selectedContributions.insert(type)
                            }
                        }
                    }
                }
                
                Section("Learning Objectives") {
                    ForEach(FederatedHealthLearning.LearningConfiguration.LearningObjective.allCases, id: \.self) { objective in
                        MultipleSelectionRow(
                            title: objective.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                            isSelected: selectedObjectives.contains(objective)
                        ) {
                            if selectedObjectives.contains(objective) {
                                selectedObjectives.remove(objective)
                            } else {
                                selectedObjectives.insert(objective)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Configure Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Join") {
                        let configuration = FederatedHealthLearning.LearningConfiguration(
                            participationLevel: participationLevel,
                            privacyLevel: privacyLevel,
                            contributionTypes: selectedContributions,
                            learningObjectives: selectedObjectives,
                            maxRounds: 100,
                            minimumAccuracy: 0.85
                        )
                        onConfigure(configuration)
                        dismiss()
                    }
                    .disabled(selectedContributions.isEmpty || selectedObjectives.isEmpty)
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}