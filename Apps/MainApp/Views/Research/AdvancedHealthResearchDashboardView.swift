import SwiftUI
import Charts

@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthResearchDashboardView: View {
    @StateObject private var researchEngine = AdvancedHealthResearchEngine(
        healthDataManager: HealthDataManager(),
        analyticsEngine: AnalyticsEngine()
    )
    
    @State private var selectedTab = 0
    @State private var showingStudyDetails = false
    @State private var showingTrialDetails = false
    @State private var showingSessionDetails = false
    @State private var showingCollaborationDetails = false
    @State private var selectedStudy: ResearchStudy?
    @State private var selectedTrial: ClinicalTrial?
    @State private var selectedSession: TelemedicineSession?
    @State private var selectedCollaboration: ProviderCollaboration?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    studiesTab
                        .tag(1)
                    
                    trialsTab
                        .tag(2)
                    
                    telemedicineTab
                        .tag(3)
                    
                    collaborationsTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .sheet(item: $selectedStudy) { study in
            StudyDetailView(study: study)
        }
        .sheet(item: $selectedTrial) { trial in
            TrialDetailView(trial: trial)
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .sheet(item: $selectedCollaboration) { collaboration in
            CollaborationDetailView(collaboration: collaboration)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Research")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Clinical Integration & Research Platform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        if researchEngine.isResearchActive {
                            await researchEngine.stopResearch()
                        } else {
                            try? await researchEngine.startResearch()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: researchEngine.isResearchActive ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        
                        Text(researchEngine.isResearchActive ? "Stop" : "Start")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(researchEngine.isResearchActive ? .red : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            
            // Progress Bar
            if researchEngine.isResearchActive {
                ProgressView(value: researchEngine.researchProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: item.icon)
                                .font(.title2)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                            
                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                        }
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Research Insights Card
                if let insights = researchEngine.researchInsights {
                    ResearchInsightsCard(insights: insights)
                }
                
                // Quick Stats
                QuickStatsView(researchEngine: researchEngine)
                
                // Research Progress
                ResearchProgressView(researchEngine: researchEngine)
                
                // Recent Activity
                RecentActivityView(researchEngine: researchEngine)
            }
            .padding()
        }
    }
    
    // MARK: - Studies Tab
    private var studiesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(researchEngine.researchStudies) { study in
                    StudyCardView(study: study) {
                        selectedStudy = study
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Trials Tab
    private var trialsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(researchEngine.clinicalTrials) { trial in
                    TrialCardView(trial: trial) {
                        selectedTrial = trial
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Telemedicine Tab
    private var telemedicineTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(researchEngine.telemedicineSessions) { session in
                    SessionCardView(session: session) {
                        selectedSession = session
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Collaborations Tab
    private var collaborationsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(researchEngine.providerCollaborations) { collaboration in
                    CollaborationCardView(collaboration: collaboration) {
                        selectedCollaboration = collaboration
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Tab Items
    private var tabItems: [(title: String, icon: String)] {
        [
            ("Overview", "chart.bar.fill"),
            ("Studies", "doc.text.fill"),
            ("Trials", "cross.fill"),
            ("Telemedicine", "video.fill"),
            ("Collaborations", "person.2.fill")
        ]
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct ResearchInsightsCard: View {
    let insights: ResearchInsights
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Research Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(insights.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                InsightMetricView(
                    title: "Study Participation",
                    value: "\(insights.studyParticipation.activeStudies)",
                    subtitle: "Active Studies",
                    color: .blue
                )
                
                InsightMetricView(
                    title: "Trial Eligibility",
                    value: "\(insights.trialEligibility.eligibleTrials)",
                    subtitle: "Eligible Trials",
                    color: .green
                )
                
                InsightMetricView(
                    title: "Telemedicine",
                    value: "\(insights.telemedicineUsage.completedSessions)",
                    subtitle: "Sessions",
                    color: .purple
                )
                
                InsightMetricView(
                    title: "Collaborations",
                    value: "\(insights.collaborationMetrics.activeCollaborations)",
                    subtitle: "Active",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct InsightMetricView: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QuickStatsView: View {
    @ObservedObject var researchEngine: AdvancedHealthResearchEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCardView(
                    title: "Total Studies",
                    value: "\(researchEngine.researchStudies.count)",
                    icon: "doc.text.fill",
                    color: .blue
                )
                
                StatCardView(
                    title: "Active Trials",
                    value: "\(researchEngine.clinicalTrials.filter { $0.status == .active }.count)",
                    icon: "cross.fill",
                    color: .green
                )
                
                StatCardView(
                    title: "Sessions",
                    value: "\(researchEngine.telemedicineSessions.count)",
                    icon: "video.fill",
                    color: .purple
                )
                
                StatCardView(
                    title: "Collaborations",
                    value: "\(researchEngine.providerCollaborations.count)",
                    icon: "person.2.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ResearchProgressView: View {
    @ObservedObject var researchEngine: AdvancedHealthResearchEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Research Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                ProgressRowView(
                    title: "Study Participation",
                    progress: researchEngine.researchInsights?.studyParticipation.participationRate ?? 0.0,
                    color: .blue
                )
                
                ProgressRowView(
                    title: "Trial Enrollment",
                    progress: researchEngine.researchInsights?.trialEligibility.enrollmentRate ?? 0.0,
                    color: .green
                )
                
                ProgressRowView(
                    title: "Telemedicine Usage",
                    progress: researchEngine.researchInsights?.telemedicineUsage.satisfactionScore ?? 0.0,
                    color: .purple
                )
                
                ProgressRowView(
                    title: "Collaboration Effectiveness",
                    progress: researchEngine.researchInsights?.collaborationMetrics.collaborationEffectiveness ?? 0.0,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ProgressRowView: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct RecentActivityView: View {
    @ObservedObject var researchEngine: AdvancedHealthResearchEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(researchEngine.researchHistory.prefix(5), id: \.timestamp) { activity in
                    ActivityRowView(activity: activity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ActivityRowView: View {
    let activity: ResearchActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Research Activity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(activity.studies.count) studies, \(activity.trials.count) trials")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Card Views

@available(iOS 18.0, macOS 15.0, *)
struct StudyCardView: View {
    let study: ResearchStudy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(study.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(study.institution)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadgeView(status: study.status)
                }
                
                Text(study.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(study.category.rawValue.capitalized)", systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    ProgressView(value: study.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 60)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct TrialCardView: View {
    let trial: ClinicalTrial
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trial.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(trial.institution)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadgeView(status: trial.status)
                }
                
                Text(trial.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("Phase \(trial.phase.rawValue)", systemImage: "cross.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    ProgressView(value: trial.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 60)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SessionCardView: View {
    let session: TelemedicineSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.provider)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(session.specialty)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadgeView(status: session.status)
                }
                
                Text(session.reason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(session.scheduledDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Label("\(Int(session.duration))min", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CollaborationCardView: View {
    let collaboration: ProviderCollaboration
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(collaboration.provider)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(collaboration.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadgeView(status: collaboration.status)
                }
                
                Text(collaboration.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(collaboration.topic, systemImage: "message.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Label("\(Int(collaboration.effectiveness * 100))%", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct StatusBadgeView: View {
    let status: String
    
    private var statusColor: Color {
        switch status {
        case "active": return .green
        case "completed": return .blue
        case "scheduled": return .orange
        case "paused": return .yellow
        case "cancelled": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Detail Views

@available(iOS 18.0, macOS 15.0, *)
struct StudyDetailView: View {
    let study: ResearchStudy
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(study.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(study.institution)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        StatusBadgeView(status: study.status.rawValue)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(study.description)
                            .font(.body)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRowView(title: "Category", value: study.category.rawValue.capitalized)
                        DetailRowView(title: "Duration", value: study.duration)
                        DetailRowView(title: "Principal Investigator", value: study.principalInvestigator)
                        DetailRowView(title: "Start Date", value: study.startDate, style: .date)
                        if let endDate = study.endDate {
                            DetailRowView(title: "End Date", value: endDate, style: .date)
                        }
                        if let compensation = study.compensation {
                            DetailRowView(title: "Compensation", value: compensation)
                        }
                    }
                    
                    // Progress
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                        
                        ProgressView(value: study.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        
                        Text("\(Int(study.progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Requirements
                    if !study.requirements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Requirements")
                                .font(.headline)
                            
                            ForEach(study.requirements, id: \.self) { requirement in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(requirement)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Study Details")
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

@available(iOS 18.0, macOS 15.0, *)
struct TrialDetailView: View {
    let trial: ClinicalTrial
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trial.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(trial.institution)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            StatusBadgeView(status: trial.status.rawValue)
                            Text("Phase \(trial.phase.rawValue)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(trial.description)
                            .font(.body)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRowView(title: "Condition", value: trial.condition)
                        DetailRowView(title: "Intervention", value: trial.intervention)
                        DetailRowView(title: "Principal Investigator", value: trial.principalInvestigator)
                        DetailRowView(title: "Start Date", value: trial.startDate, style: .date)
                        if let endDate = trial.endDate {
                            DetailRowView(title: "End Date", value: endDate, style: .date)
                        }
                        if let compensation = trial.compensation {
                            DetailRowView(title: "Compensation", value: compensation)
                        }
                    }
                    
                    // Progress
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                        
                        ProgressView(value: trial.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        
                        Text("\(Int(trial.progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Trial Details")
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

@available(iOS 18.0, macOS 15.0, *)
struct SessionDetailView: View {
    let session: TelemedicineSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.provider)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(session.specialty)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        StatusBadgeView(status: session.status.rawValue)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRowView(title: "Scheduled Date", value: session.scheduledDate, style: .date)
                        DetailRowView(title: "Duration", value: "\(Int(session.duration)) minutes")
                        DetailRowView(title: "Reason", value: session.reason)
                        if let notes = session.notes {
                            DetailRowView(title: "Notes", value: notes)
                        }
                    }
                    
                    // Quality
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Quality")
                            .font(.headline)
                        
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(session.quality * 5) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(session.quality * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Session Details")
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

@available(iOS 18.0, macOS 15.0, *)
struct CollaborationDetailView: View {
    let collaboration: ProviderCollaboration
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(collaboration.provider)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(collaboration.type.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        StatusBadgeView(status: collaboration.status.rawValue)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(collaboration.description)
                            .font(.body)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRowView(title: "Topic", value: collaboration.topic)
                        DetailRowView(title: "Start Date", value: collaboration.startDate, style: .date)
                        if let endDate = collaboration.endDate {
                            DetailRowView(title: "End Date", value: endDate, style: .date)
                        }
                    }
                    
                    // Effectiveness
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effectiveness")
                            .font(.headline)
                        
                        ProgressView(value: collaboration.effectiveness)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        
                        Text("\(Int(collaboration.effectiveness * 100))% Effective")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Collaboration Details")
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

@available(iOS 18.0, macOS 15.0, *)
struct DetailRowView: View {
    let title: String
    let value: String
    var style: DateFormatter.Style = .none
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            if style != .none {
                Text(value, style: style)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Extensions

extension ResearchStudy: Identifiable {}
extension ClinicalTrial: Identifiable {}
extension TelemedicineSession: Identifiable {}
extension ProviderCollaboration: Identifiable {} 