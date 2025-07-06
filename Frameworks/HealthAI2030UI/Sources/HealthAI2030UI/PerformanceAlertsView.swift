import SwiftUI

/// Performance alerts and recommendations view
struct PerformanceAlertsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var neuralEngineOptimizer = NeuralEngineOptimizer.shared
    
    var body: some View {
        NavigationStack {
            List {
                if neuralEngineOptimizer.performanceAlerts.isEmpty {
                    ContentUnavailableView(
                        "No Performance Alerts",
                        systemImage: "checkmark.circle",
                        description: Text("Your system is performing optimally")
                    )
                } else {
                    ForEach(neuralEngineOptimizer.performanceAlerts) { alert in
                        PerformanceAlertRow(alert: alert)
                    }
                }
            }
            .navigationTitle("Performance Alerts")
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

struct PerformanceAlertRow: View {
    let alert: PerformanceAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: alert.severity.iconName)
                    .foregroundColor(alert.severity.color)
                
                Text(alert.title)
                    .font(.headline)
                
                Spacer()
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !alert.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    ForEach(alert.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if alert.severity == .critical {
                Button("Take Action") {
                    handleCriticalAlert(alert)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func handleCriticalAlert(_ alert: PerformanceAlert) {
        // Handle critical performance alert
        print("Handling critical alert: \(alert.title)")
    }
}

// MARK: - Supporting Types
struct PerformanceAlert: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let severity: AlertSeverity
    let timestamp: Date
    let recommendations: [String]
    let component: PerformanceComponent
}

enum AlertSeverity {
    case low
    case medium
    case high
    case critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
}

enum PerformanceComponent {
    case neuralEngine
    case graphics
    case memory
    case battery
    case temperature
    case overall
}

// MARK: - Preview
struct PerformanceAlertsView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceAlertsView()
    }
} 