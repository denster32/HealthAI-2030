import SwiftUI
import CoreML

/// Federated Learning Dashboard View
/// Provides comprehensive interface for monitoring and managing federated learning training, privacy settings, and model performance
struct FederatedLearningDashboardView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var federatedLearningManager: FederatedLearningManager
    
    // MARK: - State Properties
    @State private var selectedTab = 0
    @State private var showingConfiguration = false
    @State private var showingPrivacySettings = false
    @State private var showingTrainingDetails = false
    @State private var isParticipating = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Federated learning status header
                federatedStatusHeader
                
                // Tab selector
                tabSelector
                
                // Tab content
                TabView(selection: $selectedTab) {
                    trainingStatusTab
                        .tag(0)
                    
                    privacyManagementTab
                        .tag(1)
                    
                    modelPerformanceTab
                        .tag(2)
                    
                    federatedStatsTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Federated Learning")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    federatedSettingsButton
                }
            }
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
        .sheet(isPresented: $showingConfiguration) {
            FederatedConfigurationView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingTrainingDetails) {
            TrainingDetailsView()
        }
    }
    
    // MARK: - Header Views
    
    private var federatedStatusHeader: some View {
        VStack(spacing: 16) {
            // Current federated learning status
            VStack(spacing: 8) {
                HStack {
                    Text("Federated Learning Status")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    FederatedStatusIndicator(status: federatedLearningManager.trainingStatus)
                }
                
                // Status details
                HStack(spacing: 16) {
                    FederatedMetricView(
                        title: "Rounds",
                        value: "\(federatedLearningManager.federatedStats.roundsParticipated)",
                        color: .blue
                    )
                    
                    FederatedMetricView(
                        title: "Accuracy",
                        value: String(format: "%.1f%%", federatedLearningManager.modelAccuracy * 100),
                        color: federatedLearningManager.modelAccuracy > 0.8 ? .green : .orange
                    )
                    
                    FederatedMetricView(
                        title: "Privacy Budget",
                        value: String(format: "%.1f", federatedLearningManager.federatedStats.currentPrivacyBudget),
                        color: federatedLearningManager.federatedStats.currentPrivacyBudget > 0.5 ? .green : .red
                    )
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Quick actions
            HStack(spacing: 12) {
                Button(action: toggleParticipation) {
                    HStack {
                        Image(systemName: isParticipating ? "pause.fill" : "play.fill")
                        Text(isParticipating ? "Stop Training" : "Start Training")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isParticipating ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: { showingConfiguration = true }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Configure")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Text(tabTitle(for: index))
                                .font(.caption)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Content Views
    
    private var trainingStatusTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Training progress
                if federatedLearningManager.isTraining {
                    TrainingProgressCard(
                        progress: federatedLearningManager.trainingProgress,
                        status: federatedLearningManager.trainingStatus,
                        currentRound: federatedLearningManager.currentRound,
                        totalRounds: federatedLearningManager.totalRounds
                    )
                } else {
                    TrainingStatusCard(
                        status: federatedLearningManager.trainingStatus,
                        canParticipate: federatedLearningManager.canParticipateInFederatedLearning()
                    )
                }
                
                // Participation eligibility
                ParticipationEligibilityCard(
                    canParticipate: federatedLearningManager.canParticipateInFederatedLearning(),
                    stats: federatedLearningManager.federatedStats
                )
                
                // Training configuration
                TrainingConfigurationCard(
                    config: federatedLearningManager.getFederatedConfig()
                )
                
                // Recent training rounds
                RecentTrainingRoundsCard(
                    rounds: federatedLearningManager.getTrainingHistory().suffix(5)
                )
            }
            .padding()
        }
    }
    
    private var privacyManagementTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Privacy budget status
                PrivacyBudgetCard(
                    budgetStatus: federatedLearningManager.getPrivacyBudgetStatus()
                )
                
                // Privacy settings
                PrivacySettingsCard(
                    config: federatedLearningManager.getFederatedConfig()
                )
                
                // Privacy controls
                PrivacyControlsCard(
                    onResetBudget: {
                        federatedLearningManager.resetPrivacyBudget()
                    }
                )
                
                // Privacy statistics
                PrivacyStatisticsCard(
                    stats: federatedLearningManager.federatedStats
                )
            }
            .padding()
        }
    }
    
    private var modelPerformanceTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current model performance
                ModelPerformanceCard(
                    accuracy: federatedLearningManager.modelAccuracy,
                    trainingHistory: federatedLearningManager.getTrainingHistory()
                )
                
                // Model comparison
                ModelComparisonCard(
                    localModel: federatedLearningManager.federatedStats,
                    globalModel: federatedLearningManager.federatedStats
                )
                
                // Performance trends
                PerformanceTrendsCard(
                    roundStats: federatedLearningManager.federatedStats.roundStats
                )
                
                // Model export/import
                ModelManagementCard(
                    onExport: {
                        Task {
                            try? await federatedLearningManager.exportModel()
                        }
                    }
                )
            }
            .padding()
        }
    }
    
    private var federatedStatsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Overall statistics
                OverallStatsCard(
                    stats: federatedLearningManager.federatedStats
                )
                
                // Round-by-round statistics
                RoundStatsCard(
                    roundStats: federatedLearningManager.federatedStats.roundStats
                )
                
                // Data processing statistics
                DataProcessingCard(
                    stats: federatedLearningManager.federatedStats
                )
                
                // Privacy budget usage
                PrivacyBudgetUsageCard(
                    stats: federatedLearningManager.federatedStats
                )
            }
            .padding()
        }
    }
    
    // MARK: - Toolbar Views
    
    private var federatedSettingsButton: some View {
        Button(action: { showingConfiguration = true }) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Helper Methods
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Training"
        case 1: return "Privacy"
        case 2: return "Performance"
        case 3: return "Statistics"
        default: return ""
        }
    }
    
    private func startMonitoring() {
        // Start refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // Trigger UI updates
        }
    }
    
    private func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func toggleParticipation() {
        if isParticipating {
            // Stop participating
            isParticipating = false
        } else {
            // Start participating
            isParticipating = true
            startFederatedTraining()
        }
    }
    
    private func startFederatedTraining() {
        Task {
            do {
                let result = try await federatedLearningManager.startTraining()
                print("Federated training completed: \(result)")
            } catch {
                print("Federated training failed: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct FederatedStatusIndicator: View {
    let status: TrainingStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            Text(status.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FederatedMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct TrainingProgressCard: View {
    let progress: Double
    let status: TrainingStatus
    let currentRound: Int
    let totalRounds: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training Progress")
                    .font(.headline)
                Spacer()
                Text("\(currentRound)/\(totalRounds)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: status.color))
            
            HStack {
                Text(status.rawValue)
                    .font(.caption)
                    .foregroundColor(status.color)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TrainingStatusCard: View {
    let status: TrainingStatus
    let canParticipate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training Status")
                    .font(.headline)
                Spacer()
                FederatedStatusIndicator(status: status)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: canParticipate ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(canParticipate ? "Eligible to participate" : "Not eligible to participate")
                        .font(.subheadline)
                        .foregroundColor(canParticipate ? .green : .red)
                }
                
                Text(status.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ParticipationEligibilityCard: View {
    let canParticipate: Bool
    let stats: FederatedStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participation Eligibility")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                EligibilityRow(
                    title: "Data Size",
                    value: "\(stats.localDataSize) samples",
                    isMet: stats.localDataSize >= 100,
                    required: "≥ 100 samples"
                )
                
                EligibilityRow(
                    title: "Privacy Consent",
                    value: "Granted",
                    isMet: true,
                    required: "User consent"
                )
                
                EligibilityRow(
                    title: "Device Compatibility",
                    value: "Compatible",
                    isMet: true,
                    required: "ML capabilities"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct EligibilityRow: View {
    let title: String
    let value: String
    let isMet: Bool
    let required: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Required: \(required)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(isMet ? .green : .red)
                
                Image(systemName: isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isMet ? .green : .red)
                    .font(.caption)
            }
        }
    }
}

struct TrainingConfigurationCard: View {
    let config: FederatedConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Configuration")
                .font(.headline)
            
            VStack(spacing: 8) {
                ConfigRow(title: "Minimum Data Size", value: "\(config.minimumDataSize) samples")
                ConfigRow(title: "Privacy Epsilon", value: String(format: "%.2f", config.privacyEpsilon))
                ConfigRow(title: "Privacy Delta", value: String(format: "%.2e", config.privacyDelta))
                ConfigRow(title: "Max Rounds", value: "\(config.maxRounds)")
                ConfigRow(title: "Local Epochs", value: "\(config.localEpochs)")
                ConfigRow(title: "Learning Rate", value: String(format: "%.3f", config.learningRate))
                ConfigRow(title: "Batch Size", value: "\(config.batchSize)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ConfigRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

struct RecentTrainingRoundsCard: View {
    let rounds: ArraySlice<TrainingRound>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Training Rounds")
                .font(.headline)
            
            if rounds.isEmpty {
                Text("No training rounds completed yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(rounds.enumerated()), id: \.offset) { index, round in
                    HStack {
                        Text("Round \(round.roundNumber)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f%%", round.performance.accuracy * 100))
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            Text(round.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if index < rounds.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrivacyBudgetCard: View {
    let budgetStatus: PrivacyBudgetStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Privacy Budget")
                    .font(.headline)
                Spacer()
                Text(budgetStatus.isExhausted ? "Exhausted" : "Available")
                    .font(.subheadline)
                    .foregroundColor(budgetStatus.isExhausted ? .red : .green)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Remaining")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.3f", budgetStatus.remainingBudget))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(budgetStatus.remainingBudget > 0.5 ? .green : .red)
                }
                
                HStack {
                    Text("Used")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.3f", budgetStatus.usedBudget))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                ProgressView(value: budgetStatus.usedBudget, total: budgetStatus.totalBudget)
                    .progressViewStyle(LinearProgressViewStyle(tint: budgetStatus.isExhausted ? .red : .blue))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrivacySettingsCard: View {
    let config: FederatedConfig
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Settings")
                .font(.headline)
            
            VStack(spacing: 8) {
                PrivacySettingRow(
                    title: "Differential Privacy",
                    value: "Enabled",
                    description: "Epsilon: \(String(format: "%.2f", config.privacyEpsilon))"
                )
                
                PrivacySettingRow(
                    title: "Data Augmentation",
                    value: "Enabled",
                    description: "Noise: \(String(format: "%.3f", config.dataAugmentationNoise))"
                )
                
                PrivacySettingRow(
                    title: "Secure Aggregation",
                    value: "Enabled",
                    description: "Encrypted model updates"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrivacySettingRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PrivacyControlsCard: View {
    let onResetBudget: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Controls")
                .font(.headline)
            
            Button("Reset Privacy Budget") {
                onResetBudget()
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrivacyStatisticsCard: View {
    let stats: FederatedStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Statistics")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatRow(title: "Total Privacy Budget Used", value: String(format: "%.3f", stats.totalPrivacyBudgetUsed))
                StatRow(title: "Average per Round", value: String(format: "%.3f", stats.roundsParticipated > 0 ? stats.totalPrivacyBudgetUsed / Double(stats.roundsParticipated) : 0))
                StatRow(title: "Current Budget", value: String(format: "%.3f", stats.currentPrivacyBudget))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Placeholder Views for Performance Tab

struct ModelPerformanceCard: View {
    let accuracy: Double
    let trainingHistory: [TrainingRound]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Performance")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Accuracy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", accuracy * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(accuracy > 0.8 ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Training Rounds")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(trainingHistory.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ModelComparisonCard: View {
    let localModel: FederatedStats
    let globalModel: FederatedStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Comparison")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Local Model")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Accuracy: \(String(format: "%.1f%%", localModel.averageAccuracy * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Global Model")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Accuracy: \(String(format: "%.1f%%", globalModel.averageAccuracy * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PerformanceTrendsCard: View {
    let roundStats: [RoundStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Trends")
                .font(.headline)
            
            if roundStats.isEmpty {
                Text("No performance data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Simple chart representation
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(roundStats.suffix(10).enumerated()), id: \.offset) { index, stat in
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 20, height: max(10, CGFloat(stat.accuracy * 100)))
                    }
                }
                .frame(height: 60)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ModelManagementCard: View {
    let onExport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Management")
                .font(.headline)
            
            Button("Export Model") {
                onExport()
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Placeholder Views for Statistics Tab

struct OverallStatsCard: View {
    let stats: FederatedStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Statistics")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatRow(title: "Rounds Participated", value: "\(stats.roundsParticipated)")
                StatRow(title: "Total Data Processed", value: "\(stats.totalDataProcessed) samples")
                StatRow(title: "Average Accuracy", value: String(format: "%.1f%%", stats.averageAccuracy * 100))
                StatRow(title: "Local Data Size", value: "\(stats.localDataSize) samples")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct RoundStatsCard: View {
    let roundStats: [RoundStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round Statistics")
                .font(.headline)
            
            Text("\(roundStats.count) rounds completed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DataProcessingCard: View {
    let stats: FederatedStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Processing")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatRow(title: "Total Data Processed", value: "\(stats.totalDataProcessed) samples")
                StatRow(title: "Average per Round", value: "\(stats.roundsParticipated > 0 ? stats.totalDataProcessed / stats.roundsParticipated : 0) samples")
                StatRow(title: "Local Data Available", value: "\(stats.localDataSize) samples")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrivacyBudgetUsageCard: View {
    let stats: FederatedStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Budget Usage")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatRow(title: "Total Budget Used", value: String(format: "%.3f", stats.totalPrivacyBudgetUsed))
                StatRow(title: "Average per Round", value: String(format: "%.3f", stats.roundsParticipated > 0 ? stats.totalPrivacyBudgetUsed / Double(stats.roundsParticipated) : 0))
                StatRow(title: "Remaining Budget", value: String(format: "%.3f", stats.currentPrivacyBudget))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Placeholder Views for Sheets

struct FederatedConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Federated Learning Configuration")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Configuration settings will be implemented here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Privacy Settings")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Privacy settings will be configured here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TrainingDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Training Details")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Detailed training information will be displayed here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Training Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension TrainingStatus {
    var color: Color {
        switch self {
        case .idle: return .gray
        case .initializing: return .blue
        case .participating: return .green
        case .training: return .orange
        case .aggregating: return .purple
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var description: String {
        switch self {
        case .idle: return "Ready to start federated learning"
        case .initializing: return "Initializing federated learning system"
        case .participating: return "Participating in federated learning round"
        case .training: return "Training local model on health data"
        case .aggregating: return "Aggregating model updates from server"
        case .completed: return "Federated learning round completed"
        case .failed: return "Federated learning failed"
        }
    }
} 