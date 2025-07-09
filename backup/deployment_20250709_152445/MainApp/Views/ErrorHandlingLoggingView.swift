import SwiftUI
import Charts
import Combine

/// Comprehensive SwiftUI view for Error Handling & Logging Management
/// Provides interface for monitoring errors, viewing logs, and analyzing performance
public struct ErrorHandlingLoggingView: View {
    @StateObject private var errorManager = ErrorHandlingLoggingManager.shared
    @State private var selectedTab = 0
    @State private var showingErrorDetails = false
    @State private var showingLogDetails = false
    @State private var showingConfiguration = false
    @State private var searchText = ""
    @State private var selectedLogLevel: ErrorHandlingLoggingManager.LogLevel = .info
    @State private var selectedErrorSeverity: ErrorHandlingLoggingManager.ErrorSeverity = .medium
    @State private var selectedLogEntry: ErrorHandlingLoggingManager.LogEntry?
    @State private var selectedErrorEntry: ErrorHandlingLoggingManager.ErrorEntry?
    @State private var refreshTimer: Timer?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with error summary
                headerView
                
                // Tab selection
                tabSelectionView
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTabView
                        .tag(0)
                    
                    errorsTabView
                        .tag(1)
                    
                    logsTabView
                        .tag(2)
                    
                    performanceTabView
                        .tag(3)
                    
                    configurationTabView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Error Handling & Logging")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Configuration") {
                            showingConfiguration = true
                        }
                        
                        Button("Export Logs") {
                            exportLogs()
                        }
                        
                        Button("Clear Buffers") {
                            errorManager.clearBuffers()
                        }
                        
                        Button("Flush Buffers") {
                            errorManager.flushBuffers()
                        }
                        
                        Button("Refresh") {
                            // Trigger refresh
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingErrorDetails) {
            if let errorEntry = selectedErrorEntry {
                ErrorDetailsView(errorEntry: errorEntry)
            }
        }
        .sheet(isPresented: $showingLogDetails) {
            if let logEntry = selectedLogEntry {
                LogDetailsView(logEntry: logEntry)
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            ErrorHandlingConfigurationView()
        }
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error Summary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        
                        Text("\(errorManager.errorCount) Errors")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(errorManager.isMonitoringEnabled ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(errorManager.isMonitoringEnabled ? "Active" : "Inactive")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Error level indicators
            HStack(spacing: 16) {
                ErrorLevelIndicator(
                    title: "Errors",
                    count: errorManager.errorCount,
                    color: .red
                )
                
                ErrorLevelIndicator(
                    title: "Warnings",
                    count: errorManager.warningCount,
                    color: .orange
                )
                
                ErrorLevelIndicator(
                    title: "Info",
                    count: errorManager.infoCount,
                    color: .blue
                )
                
                ErrorLevelIndicator(
                    title: "Crashes",
                    count: errorManager.crashCount,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(["Overview", "Errors", "Logs", "Performance", "Config"], id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = ["Overview", "Errors", "Logs", "Performance", "Config"].firstIndex(of: tab) ?? 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == ["Overview", "Errors", "Logs", "Performance", "Config"].firstIndex(of: tab) ? .semibold : .regular)
                                .foregroundColor(selectedTab == ["Overview", "Errors", "Logs", "Performance", "Config"].firstIndex(of: tab) ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == ["Overview", "Errors", "Logs", "Performance", "Config"].firstIndex(of: tab) ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(width: 80)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Error summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    let errorSummary = errorManager.getErrorSummary()
                    
                    SummaryCardView(
                        title: "Total Errors",
                        value: "\(errorSummary.totalErrors)",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                    
                    SummaryCardView(
                        title: "Handled",
                        value: "\(errorSummary.handledErrors)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    SummaryCardView(
                        title: "Unhandled",
                        value: "\(errorSummary.unhandledErrors)",
                        icon: "xmark.circle",
                        color: .orange
                    )
                    
                    SummaryCardView(
                        title: "Crashes",
                        value: "\(errorManager.crashCount)",
                        icon: "bolt.circle",
                        color: .purple
                    )
                }
                
                // Error trends chart
                ErrorTrendsChartView()
                
                // Recent activity
                RecentActivityView()
            }
            .padding()
        }
    }
    
    // MARK: - Errors Tab
    
    private var errorsTabView: some View {
        VStack(spacing: 16) {
            // Filter controls
            HStack {
                Picker("Severity", selection: $selectedErrorSeverity) {
                    ForEach(ErrorHandlingLoggingManager.ErrorSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(severity)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Button("Clear Errors") {
                    // Clear error buffer
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            // Errors list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredErrors, id: \.id) { errorEntry in
                        ErrorCardView(errorEntry: errorEntry) {
                            selectedErrorEntry = errorEntry
                            showingErrorDetails = true
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredErrors: [ErrorHandlingLoggingManager.ErrorEntry] {
        // This would filter actual errors, for now return empty array
        return []
    }
    
    // MARK: - Logs Tab
    
    private var logsTabView: some View {
        VStack(spacing: 16) {
            // Search and filter controls
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Level", selection: $selectedLogLevel) {
                    ForEach(ErrorHandlingLoggingManager.LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            // Logs list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredLogs, id: \.id) { logEntry in
                        LogCardView(logEntry: logEntry) {
                            selectedLogEntry = logEntry
                            showingLogDetails = true
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredLogs: [ErrorHandlingLoggingManager.LogEntry] {
        // This would filter actual logs, for now return empty array
        return []
    }
    
    // MARK: - Performance Tab
    
    private var performanceTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance metrics
                PerformanceMetricsView()
                
                // Performance charts
                PerformanceChartsView()
                
                // System health
                SystemHealthView()
            }
            .padding()
        }
    }
    
    // MARK: - Configuration Tab
    
    private var configurationTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current configuration
                CurrentConfigurationView()
                
                // Logging settings
                LoggingSettingsView()
                
                // Error handling settings
                ErrorHandlingSettingsView()
                
                // Performance settings
                PerformanceSettingsView()
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // Trigger UI refresh
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func exportLogs() {
        if let exportData = errorManager.exportLogs() {
            // Save to file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let exportURL = documentsPath.appendingPathComponent("logs_export.json")
            try? exportData.write(to: exportURL)
            
            print("Logs exported to: \(exportURL)")
        }
    }
}

// MARK: - Supporting Views

struct ErrorLevelIndicator: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ErrorTrendsChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Error Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart {
                ForEach(0..<10, id: \.self) { index in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Errors", Int.random(in: 0...10))
                    )
                    .foregroundStyle(.red)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentActivityView: View {
    @StateObject private var errorManager = ErrorHandlingLoggingManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(errorManager.recentErrors.prefix(5)) { logEntry in
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color(logEntry.level.color))
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(logEntry.message)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("\(logEntry.category) - \(logEntry.level.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(logEntry.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ErrorCardView: View {
    let errorEntry: ErrorHandlingLoggingManager.ErrorEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(errorEntry.error.errorDescription ?? "Unknown Error")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(errorEntry.context.module)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(errorEntry.severity.rawValue)
                            .font(.headline)
                            .foregroundColor(severityColor)
                        
                        Text("Severity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Module")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(errorEntry.context.module)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Function")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(errorEntry.context.function)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Handled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(errorEntry.isHandled ? "Yes" : "No")
                            .font(.caption)
                            .foregroundColor(errorEntry.isHandled ? .green : .red)
                    }
                    
                    HStack {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(errorEntry.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch errorEntry.severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        case .fatal:
            return .black
        }
    }
}

struct LogCardView: View {
    let logEntry: ErrorHandlingLoggingManager.LogEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(logEntry.message)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text("\(logEntry.category) - \(logEntry.level.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(logEntry.level.icon)
                            .font(.title3)
                        
                        Text(logEntry.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PerformanceMetricsView: View {
    @StateObject private var errorManager = ErrorHandlingLoggingManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            let performanceSummary = errorManager.getPerformanceSummary()
            
            VStack(spacing: 12) {
                MetricRowView(
                    title: "Total Logs",
                    value: "\(performanceSummary.totalLogs)",
                    color: .blue
                )
                
                MetricRowView(
                    title: "Avg Log Size",
                    value: "\(performanceSummary.averageLogSize) chars",
                    color: .green
                )
                
                MetricRowView(
                    title: "Processing Time",
                    value: "\(String(format: "%.3f", performanceSummary.logProcessingTime))s",
                    color: .orange
                )
                
                MetricRowView(
                    title: "Buffer Flushes",
                    value: "\(performanceSummary.bufferFlushCount)",
                    color: .purple
                )
                
                MetricRowView(
                    title: "Remote Success",
                    value: "\(performanceSummary.remoteLoggingSuccess)",
                    color: .green
                )
                
                MetricRowView(
                    title: "Remote Failures",
                    value: "\(performanceSummary.remoteLoggingFailures)",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricRowView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct PerformanceChartsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Charts")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Log processing time chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Log Processing Time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(0..<10, id: \.self) { index in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Processing Time", Double.random(in: 0.001...0.1))
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 150)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
    }
}

struct SystemHealthView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Health")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HealthIndicatorView(
                    title: "Memory Usage",
                    value: "75%",
                    status: .warning
                )
                
                HealthIndicatorView(
                    title: "CPU Usage",
                    value: "45%",
                    status: .good
                )
                
                HealthIndicatorView(
                    title: "Network Status",
                    value: "Connected",
                    status: .good
                )
                
                HealthIndicatorView(
                    title: "Storage",
                    value: "60%",
                    status: .good
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct HealthIndicatorView: View {
    let title: String
    let value: String
    let status: HealthStatus
    
    enum HealthStatus {
        case good, warning, critical
        
        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct CurrentConfigurationView: View {
    @StateObject private var errorManager = ErrorHandlingLoggingManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Configuration")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ConfigRowView(
                    title: "Log Level",
                    value: errorManager.logLevel.rawValue
                )
                
                ConfigRowView(
                    title: "Monitoring",
                    value: errorManager.isMonitoringEnabled ? "Enabled" : "Disabled"
                )
                
                ConfigRowView(
                    title: "Crash Reporting",
                    value: errorManager.configuration.enableCrashReporting ? "Enabled" : "Disabled"
                )
                
                ConfigRowView(
                    title: "Performance Monitoring",
                    value: errorManager.configuration.enablePerformanceMonitoring ? "Enabled" : "Disabled"
                )
                
                ConfigRowView(
                    title: "Remote Logging",
                    value: errorManager.configuration.enableRemoteLogging ? "Enabled" : "Disabled"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ConfigRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct LoggingSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Logging Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Logging configuration options will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ErrorHandlingSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Error Handling Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Error handling configuration options will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PerformanceSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Performance monitoring configuration options will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Supporting Views (Placeholders)

struct ErrorDetailsView: View {
    let errorEntry: ErrorHandlingLoggingManager.ErrorEntry
    
    var body: some View {
        Text("Error Details for \(errorEntry.id)")
            .padding()
    }
}

struct LogDetailsView: View {
    let logEntry: ErrorHandlingLoggingManager.LogEntry
    
    var body: some View {
        Text("Log Details for \(logEntry.id)")
            .padding()
    }
}

struct ErrorHandlingConfigurationView: View {
    var body: some View {
        Text("Error Handling Configuration")
            .padding()
    }
}

#Preview {
    ErrorHandlingLoggingView()
} 