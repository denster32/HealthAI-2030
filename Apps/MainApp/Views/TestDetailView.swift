import SwiftUI

struct TestDetailView: View {
    let testResult: ComprehensiveTestingManager.TestResult
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Test Overview
                    testOverviewSection
                    
                    // Test Details
                    testDetailsSection
                    
                    // Error Information (if failed)
                    if testResult.status == .failed || testResult.status == .error {
                        errorInformationSection
                    }
                    
                    // Metadata
                    if !testResult.metadata.isEmpty {
                        metadataSection
                    }
                    
                    // Performance Metrics
                    performanceMetricsSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Test Details", comment: "Test details navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "Done button")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // MARK: - Test Overview Section
    private var testOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Test Overview", comment: "Test overview section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: NSLocalizedString("Test Name", comment: "Test name label"),
                    value: testResult.testName
                )
                
                DetailRow(
                    title: NSLocalizedString("Test Suite", comment: "Test suite label"),
                    value: testResult.testSuite
                )
                
                DetailRow(
                    title: NSLocalizedString("Status", comment: "Status label"),
                    value: testResult.status.rawValue.capitalized,
                    valueColor: statusColor
                )
                
                DetailRow(
                    title: NSLocalizedString("Duration", comment: "Duration label"),
                    value: String(format: "%.3f seconds", testResult.duration)
                )
                
                DetailRow(
                    title: NSLocalizedString("Timestamp", comment: "Timestamp label"),
                    value: testResult.timestamp.formatted(date: .complete, time: .complete)
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Test Details Section
    private var testDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Test Details", comment: "Test details section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let category = testResult.metadata["category"] {
                    DetailRow(
                        title: NSLocalizedString("Category", comment: "Category label"),
                        value: category.capitalized
                    )
                }
                
                if let priority = testResult.metadata["priority"] {
                    DetailRow(
                        title: NSLocalizedString("Priority", comment: "Priority label"),
                        value: priority.capitalized
                    )
                }
                
                DetailRow(
                    title: NSLocalizedString("Execution Time", comment: "Execution time label"),
                    value: formatDuration(testResult.duration)
                )
                
                DetailRow(
                    title: NSLocalizedString("Memory Usage", comment: "Memory usage label"),
                    value: "~2.5 MB" // Simulated value
                )
                
                DetailRow(
                    title: NSLocalizedString("CPU Usage", comment: "CPU usage label"),
                    value: "~15%" // Simulated value
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Error Information Section
    private var errorInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Error Information", comment: "Error information section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                if let errorMessage = testResult.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Error Message", comment: "Error message label"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                if let stackTrace = testResult.stackTrace {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("Stack Trace", comment: "Stack trace label"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView {
                            Text(stackTrace)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // Error Analysis
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Error Analysis", comment: "Error analysis label"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("This appears to be a \(errorType) error. Consider checking the test setup and dependencies.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Additional Information", comment: "Additional information section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(Array(testResult.metadata.keys.sorted()), id: \.self) { key in
                    DetailRow(
                        title: key.capitalized,
                        value: testResult.metadata[key] ?? ""
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Performance Metrics Section
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Performance Metrics", comment: "Performance metrics section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                PerformanceMetricCard(
                    title: NSLocalizedString("Execution Time", comment: "Execution time metric"),
                    value: String(format: "%.3fs", testResult.duration),
                    icon: "clock.fill",
                    color: testResult.duration < 1.0 ? .green : .orange
                )
                
                PerformanceMetricCard(
                    title: NSLocalizedString("Memory Usage", comment: "Memory usage metric"),
                    value: "2.5 MB",
                    icon: "memorychip",
                    color: .blue
                )
                
                PerformanceMetricCard(
                    title: NSLocalizedString("CPU Usage", comment: "CPU usage metric"),
                    value: "15%",
                    icon: "cpu",
                    color: .purple
                )
                
                PerformanceMetricCard(
                    title: NSLocalizedString("Network Calls", comment: "Network calls metric"),
                    value: "3",
                    icon: "network",
                    color: .cyan
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var statusColor: Color {
        switch testResult.status {
        case .passed: return .green
        case .failed: return .red
        case .skipped: return .yellow
        case .error: return .orange
        }
    }
    
    private var errorType: String {
        if let errorMessage = testResult.errorMessage {
            if errorMessage.contains("timeout") {
                return "timeout"
            } else if errorMessage.contains("assertion") {
                return "assertion failure"
            } else if errorMessage.contains("network") {
                return "network"
            } else {
                return "runtime"
            }
        }
        return "unknown"
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1.0 {
            return String(format: "%.0f ms", duration * 1000)
        } else if duration < 60.0 {
            return String(format: "%.3f seconds", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = duration.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%02.0f", minutes, seconds)
        }
    }
}

// MARK: - Supporting Views
struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct PerformanceMetricCard: View {
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
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    TestDetailView(testResult: ComprehensiveTestingManager.TestResult(
        testName: "TestHealthDataProcessing",
        testSuite: "HealthDataTests",
        status: .passed,
        duration: 1.234,
        timestamp: Date(),
        errorMessage: nil,
        stackTrace: nil,
        metadata: ["category": "unit", "priority": "high"]
    ))
} 