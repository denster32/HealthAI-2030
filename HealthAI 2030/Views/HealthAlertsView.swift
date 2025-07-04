import SwiftUI
import Analytics

struct HealthAlertsView: View {
    @ObservedObject var analyticsManager = PredictiveAnalyticsManager.shared
    @State private var selectedFilter: PriorityAlert.TriageRank? = nil

    var filteredAlerts: [PredictiveAnalyticsManager.PrioritizedAlertWithExplanation] {
        if let filter = selectedFilter {
            return analyticsManager.activeAlerts.filter { $0.prioritizedAlert.triageRank == filter }
        } else {
            return analyticsManager.activeAlerts
        }
    }

    var body: some View {
        NavigationStack {
            if filteredAlerts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text("No Active Alerts")
                        .font(.headline)
                        .accessibilityLabel("No active health alerts")
                    Text("Your health dashboard is all clear.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityHint("There are currently no health alerts.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredAlerts) { alert in
                        EnhancedAlertCard(alert: alert, onDismiss: {
                            analyticsManager.dismissAlert(id: alert.id)
                        })
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if alert.prioritizedAlert.triageRank != .critical {
                                Button(role: .destructive) {
                                    analyticsManager.dismissAlert(id: alert.id)
                                } label: {
                                    Label("Dismiss", systemImage: "xmark.bin")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Health Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All", action: { selectedFilter = nil })
                        Divider()
                        ForEach(PriorityAlert.TriageRank.allCases, id: \ .self) { rank in
                            Button(rank.rawValue.capitalized, action: { selectedFilter = rank })
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

struct EnhancedAlertCard: View {
    let alert: PredictiveAnalyticsManager.PrioritizedAlertWithExplanation
    var onDismiss: (() -> Void)? = nil
    @State private var showDetails = false
    @EnvironmentObject var analyticsManager: PredictiveAnalyticsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForSeverity(alert.prioritizedAlert.triageRank))
                    .foregroundColor(colorForSeverity(alert.prioritizedAlert.triageRank))
                    .accessibilityLabel("Severity icon")
                Text(alert.explanation.title)
                    .font(.headline)
                    .accessibilityLabel(alert.explanation.title)
                Spacer()
                SeverityBadge(rank: alert.prioritizedAlert.triageRank)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    showDetails.toggle()
                }
                if alert.prioritizedAlert.triageRank == .critical {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Tap to view details")

            Text(alert.explanation.summary)
                .font(.subheadline)
                .accessibilityLabel(alert.explanation.summary)

            if showDetails {
                AlertDetailView(alert: alert)
                    .transition(.asymmetric(insertion: .scale(scale: 0.9, anchor: .top).combined(with: .opacity), removal: .opacity))
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private func iconForSeverity(_ rank: PriorityAlert.TriageRank) -> String {
        switch rank {
        case .critical: return "exclamationmark.octagon.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        case .advisory: return "exclamationmark.shield.fill"
        case .informational: return "info.circle.fill"
        }
    }

    private func colorForSeverity(_ rank: PriorityAlert.TriageRank) -> Color {
        switch rank {
        case .critical: return .red
        case .urgent: return .orange
        case .advisory: return .yellow
        case .informational: return .gray
        }
    }
}

struct SeverityBadge: View {
    let rank: PriorityAlert.TriageRank
    var body: some View {
        Text(rank.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(colorForRank(rank).opacity(0.2))
            .foregroundColor(colorForRank(rank))
            .cornerRadius(4)
    }
    private func colorForRank(_ rank: PriorityAlert.TriageRank) -> Color {
        switch rank {
        case .critical: return .red
        case .urgent: return .orange
        case .advisory: return .yellow
        case .informational: return .gray
        }
    }
}

struct AlertDetailView: View {
    let alert: PredictiveAnalyticsManager.PrioritizedAlertWithExplanation
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(alert.explanation.title)
                .font(.title2)
                .bold()
            Text(alert.explanation.summary)
                .font(.body)
            if !alert.explanation.contributingFactors.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Contributing Factors:")
                        .font(.caption)
                        .bold()
                    ForEach(alert.explanation.contributingFactors, id: \.self) { factor in
                        Text("• \(factor)").font(.caption)
                    }
                }
            }
            if let confidence = alert.explanation.modelConfidence {
                Text("Model Confidence: \(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            if let reference = alert.explanation.reference {
                Text("Reference: \(reference)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}

struct HealthAlertsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthAlertsView()
            .environmentObject(PredictiveAnalyticsManager.shared)
    }
}