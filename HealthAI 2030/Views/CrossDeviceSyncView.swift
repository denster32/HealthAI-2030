import SwiftUI
import CloudKit

@available(iOS 18.0, *)
struct CrossDeviceSyncView: View {
    @StateObject private var syncManager = UnifiedCloudKitSyncManager.shared
    @State private var showingExportOptions = false
    @State private var selectedExportType: ExportType = .csv
    @State private var selectedDateRange = DateInterval(start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), end: Date())
    
    var body: some View {
        NavigationView {
            List {
                // Sync Status Section
                Section("Sync Status") {
                    SyncStatusCard()
                }
                
                // Device Insights Section
                Section("Device Insights") {
                    DeviceInsightsCard()
                }
                
                // Data Export Section
                Section("Data Export") {
                    DataExportCard(
                        showingExportOptions: $showingExportOptions,
                        selectedExportType: $selectedExportType,
                        selectedDateRange: $selectedDateRange
                    )
                }
                
                // Recent Analytics Section
                Section("Recent Analytics") {
                    RecentAnalyticsCard()
                }
            }
            .navigationTitle("Device Sync")
            .refreshable {
                await syncManager.startSync()
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(
                exportType: $selectedExportType,
                dateRange: $selectedDateRange,
                isPresented: $showingExportOptions
            )
        }
    }
}

struct SyncStatusCard: View {
    @StateObject private var syncManager = UnifiedCloudKitSyncManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: syncStatusIcon)
                    .foregroundColor(syncStatusColor)
                Text("Sync Status")
                    .font(.headline)
                Spacer()
                if syncManager.syncStatus == .syncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    Text(syncManager.syncStatus.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(syncStatusColor)
                }
                
                if let lastSync = syncManager.lastSyncDate {
                    HStack {
                        Text("Last Sync:")
                            .foregroundColor(.secondary)
                        Text(lastSync, style: .relative)
                            .fontWeight(.medium)
                    }
                }
                
                if syncManager.pendingSyncCount > 0 {
                    HStack {
                        Text("Pending:")
                            .foregroundColor(.secondary)
                        Text("\(syncManager.pendingSyncCount) items")
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                if !syncManager.isNetworkAvailable {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                        Text("Network Unavailable")
                            .foregroundColor(.red)
                    }
                }
            }
            
            if let errorMessage = syncManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            Button("Sync Now") {
                Task {
                    await syncManager.startSync()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(syncManager.syncStatus == .syncing || !syncManager.isNetworkAvailable)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var syncStatusIcon: String {
        switch syncManager.syncStatus {
        case .idle:
            return "checkmark.circle"
        case .syncing:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var syncStatusColor: Color {
        switch syncManager.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

import Analytics

import Analytics

struct DeviceInsightsCard: View {
    @State private var insights: [AnalyticsInsight] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI Insights")
                    .font(.headline)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading insights...")
                        .foregroundColor(.secondary)
                }
            } else if insights.isEmpty {
                Text("No recent insights available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(insights.prefix(3), id: \.id) { insight in
                    InsightRow(insight: insight)
                }
                
                if insights.count > 3 {
                    NavigationLink("View All Insights") {
                        AllInsightsView()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            loadInsights()
        }
    }
    
    private func loadInsights() {
        Task {
            // Load recent insights from SwiftData
            await MainActor.run {
                // Placeholder implementation
                insights = []
                isLoading = false
            }
        }
    }
}

struct InsightRow: View {
    import Analytics
    
    let insight: AnalyticsInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.actionable ? "lightbulb.fill" : "info.circle.fill")
                .foregroundColor(insight.actionable ? .yellow : .blue)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(insight.source)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(insight.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if insight.priority > 1 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(insight.priority > 2 ? .red : .orange)
                    .font(.system(size: 12))
            }
        }
    }
}

struct DataExportCard: View {
    @Binding var showingExportOptions: Bool
    @Binding var selectedExportType: ExportType
    @Binding var selectedDateRange: DateInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.green)
                Text("Data Export")
                    .font(.headline)
                Spacer()
                Button("Export") {
                    showingExportOptions = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Text("Export your health data for research, backup, or sharing with healthcare providers.")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Available Formats")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct RecentAnalyticsCard: View {
    @State private var recentAnalytics: [CompletedAnalysis] = []
    @State private var isLoading = true
    @State private var showingAnalyticsOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Mac Analytics")
                    .font(.headline)
                Spacer()
                
                Button("Analyze") {
                    showingAnalyticsOptions = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            
            if recentAnalytics.isEmpty && !isLoading {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mac Companion Ready")
                        .fontWeight(.medium)
                    Text("Trigger advanced analytics processing on your Mac for deeper insights and predictions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            } else {
                ForEach(recentAnalytics.prefix(2), id: \.id) { analysis in
                    AnalyticsRow(analysis: analysis)
                }
                
                #if os(macOS)
                NavigationLink("View Mac Dashboard") {
                    MacAnalyticsDashboardView()
                }
                .font(.caption)
                .foregroundColor(.blue)
                #endif
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            loadRecentAnalytics()
        }
        .sheet(isPresented: $showingAnalyticsOptions) {
            MacAnalyticsOptionsSheet(isPresented: $showingAnalyticsOptions)
        }
    }
    
    private func loadRecentAnalytics() {
        Task {
            // Load recent analytics from Mac
            await MainActor.run {
                // Placeholder implementation
                recentAnalytics = []
                isLoading = false
            }
        }
    }
}

struct AnalyticsRow: View {
    let analysis: CompletedAnalysis
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Confidence: \(Int(analysis.result.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(analysis.endTime, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.1f", analysis.duration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !analysis.result.recommendations.isEmpty {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                }
            }
        }
    }
}

// MARK: - Export Options Sheet

struct ExportOptionsSheet: View {
    @Binding var exportType: ExportType
    @Binding var dateRange: DateInterval
    @Binding var isPresented: Bool
    
    @State private var isExporting = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                
                Section("Date Range") {
                    DatePicker("Start Date", selection: Binding(
                        get: { dateRange.start },
                        set: { dateRange = DateInterval(start: $0, end: dateRange.end) }
                    ), displayedComponents: .date)
                    
                    DatePicker("End Date", selection: Binding(
                        get: { dateRange.end },
                        set: { dateRange = DateInterval(start: dateRange.start, end: $0) }
                    ), displayedComponents: .date)
                }
                
                Section("Export Options") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Include Raw Data")
                                .fontWeight(.medium)
                            Text("Heart rate, sleep, activity data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Include Analytics")
                                .fontWeight(.medium)
                            Text("Trends, patterns, insights")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Include AI Insights")
                                .fontWeight(.medium)
                            Text("Personalized recommendations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                }
                
                if let error = exportError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("Request Export") {
                        requestExport()
                    }
                    .disabled(isExporting)
                    
                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Requesting export...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func requestExport() {
        isExporting = true
        exportError = nil
        
        Task {
            do {
                let deviceSource = UIDevice.current.name
                try await UnifiedCloudKitSyncManager.shared.requestExport(
                    type: exportType,
                    dateRange: dateRange,
                    deviceSource: deviceSource,
                    modelContext: ModelContainer.shared.mainContext
                )
                
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    exportError = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

import Analytics

struct AllInsightsView: View {
    @State private var insights: [AnalyticsInsight] = []
    
    var body: some View {
        List(insights, id: \.id) { insight in
            InsightDetailRow(insight: insight)
        }
        .navigationTitle("All Insights")
        .onAppear {
            loadAllInsights()
        }
    }
    
    private func loadAllInsights() {
        // Load all insights from SwiftData
    }
}

struct InsightDetailRow: View {
    import Analytics
    
    let insight: AnalyticsInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.headline)
                Spacer()
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Text(insight.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                Text(insight.source)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                
                Spacer()
                
                Text(insight.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if os(macOS)
struct MacAnalyticsDashboardView: View {
    var body: some View {
        VStack {
            Text("Mac Analytics Dashboard")
                .font(.largeTitle)
            Text("View detailed analytics from your Mac")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Mac Analytics")
    }
}
#endif

// MARK: - Extensions

extension ExportType {
    var description: String {
        switch self {
        case .csv:
            return "Spreadsheet format"
        case .fhir:
            return "Healthcare standard"
        case .hl7:
            return "Medical exchange"
        case .pdf:
            return "Report format"
        }
    }
}

// MARK: - Mac Analytics Options Sheet

struct MacAnalyticsOptionsSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedAnalysisTypes: Set<AnalyticsType> = []
    @State private var isTriggering = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Available Analysis Types") {
                    ForEach(AnalyticsType.allCases, id: \.self) { analysisType in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(analysisType.displayName)
                                    .fontWeight(.medium)
                                Text(analysisType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedAnalysisTypes.contains(analysisType) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedAnalysisTypes.contains(analysisType) {
                                selectedAnalysisTypes.remove(analysisType)
                            } else {
                                selectedAnalysisTypes.insert(analysisType)
                            }
                        }
                    }
                }
                
                Section("Analysis Options") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Mac will process the selected analysis types using:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "cpu")
                            Text("Apple Silicon Neural Engine")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "server.rack")
                            Text("Metal GPU Acceleration")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "cloud.fill")
                            Text("Automatic result sync to all devices")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("Trigger Analysis") {
                        triggerAnalysis()
                    }
                    .disabled(selectedAnalysisTypes.isEmpty || isTriggering)
                    
                    if isTriggering {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Triggering analysis on Mac...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Mac Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            // Pre-select recommended analysis types
            selectedAnalysisTypes = [.comprehensiveHealthAnalysis, .anomalyDetection]
        }
    }
    
    private func triggerAnalysis() {
        isTriggering = true
        errorMessage = nil
        
        Task {
            do {
                // Create analytics insight to trigger Mac processing
                let deviceSource = UIDevice.current.name
                import Analytics
                
                let insight = AnalyticsInsight(
                                    title: "Mac Analytics Request",
                    description: "Requesting \(selectedAnalysisTypes.map(\.displayName).joined(separator: ", ")) analysis",
                    category: "Request",
                    confidence: 1.0,
                    source: deviceSource,
                    actionable: true,
                    priority: 2
                )
                
                guard let modelContext = try? ModelContext(ModelContainer.shared) else {
                    throw SyncError.dataContextUnavailable
                }
                
                modelContext.insert(insight)
                try modelContext.save()
                
                // Sync the request
                try await UnifiedCloudKitSyncManager.shared.syncRecord(insight, modelContext: modelContext)
                
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isTriggering = false
                }
            }
        }
    }
}

extension AnalyticsType {
    var description: String {
        switch self {
        case .comprehensiveHealthAnalysis:
            return "Complete health data correlation and pattern analysis"
        case .longTermTrendAnalysis:
            return "Historical trends and long-term health trajectory analysis"
        case .predictiveModeling:
            return "Future health predictions using machine learning"
        case .anomalyDetection:
            return "Identify unusual patterns that may indicate health concerns"
        case .sleepArchitectureAnalysis:
            return "Deep sleep stage analysis and optimization recommendations"
        case .modelRetraining:
            return "Update and improve AI models with your latest data"
        }
    }
}

#Preview {
    CrossDeviceSyncView()
}