import SwiftUI

struct HealthAlertsView: View {
    @ObservedObject var analyticsManager = PredictiveAnalyticsManager.shared

    var body: some View {
        NavigationStack {
            List(analyticsManager.activeAlerts) { alert in
                EnhancedAlertCard(alert: alert)
                    .padding(.vertical, 4)
            }
            .navigationTitle("Health Alerts")
        }
    }
}

struct EnhancedAlertCard: View {
    let alert: PredictiveAnalyticsManager.PrioritizedAlertWithExplanation
    @State private var showDetails = false
    @EnvironmentObject var analyticsManager: PredictiveAnalyticsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForSeverity(alert.prioritizedAlert.triageRank))
                    .foregroundColor(colorForSeverity(alert.prioritizedAlert.triageRank))
                Text(alert.explanation.title)
                    .font(.headline)
                Spacer()
                SeverityBadge(rank: alert.prioritizedAlert.triageRank)
            }
            .onTapGesture {
                showDetails.toggle()
                if alert.prioritizedAlert.triageRank == .critical {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }

            Text(alert.explanation.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)

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

            let actions = ActionSuggester.shared.suggestActions(for: alert.prioritizedAlert)
            if !actions.isEmpty {
                HStack {
                    ForEach(actions, id: \.title) { action in
                        Button {
                            if let link = action.deepLink {
                                DeepLinkManager.shared.handle(deepLink: link)
                            }
                        } label: {
                            Label(action.title, systemImage: iconForActionType(action.actionType))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(colorForActionType(action.actionType))
                        .accessibilityLabel(action.title)
                        .accessibilityHint(action.description)
                    }
                }
            }

            // Dismiss button for non-critical alerts
            if alert.prioritizedAlert.triageRank != .critical {
                Button(role: .destructive) {
                    // Remove alert from activeAlerts (requires binding or environment)
                    if let idx = analyticsManager.activeAlerts.firstIndex(where: { $0.id == alert.id }) {
                        analyticsManager.activeAlerts.remove(at: idx)
                    }
                } label: {
                    Label("Dismiss", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: colorForSeverity(alert.prioritizedAlert.triageRank).opacity(0.2), radius: 4)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .sheet(isPresented: $showDetails) {
            AlertDetailView(alert: alert)
        }
    }

    func iconForSeverity(_ rank: AlertPrioritizer.TriageRank) -> String {
        switch rank {
        case .critical: return "exclamationmark.triangle.fill"
        case .urgent: return "exclamationmark.circle.fill"
        case .advisory: return "info.circle.fill"
        case .informational: return "bell.fill"
        }
    }

    func colorForSeverity(_ rank: AlertPrioritizer.TriageRank) -> Color {
        switch rank {
        case .critical: return .red
        case .urgent: return .orange
        case .advisory: return .yellow
        case .informational: return .gray
        }
    }

    func iconForActionType(_ type: ActionSuggester.ActionType) -> String {
        switch type {
        case .callEMS: return "phone.fill"
        case .consultDoctor: return "stethoscope"
        case .scheduleAppointment: return "calendar"
        case .reviewData: return "doc.text.magnifyingglass"
        case .adjustEnvironment: return "bed.double.fill"
        case .openSettings: return "gearshape"
        case .dismiss: return "xmark.circle"
        }
    }

    func colorForActionType(_ type: ActionSuggester.ActionType) -> Color {
        switch type {
        case .callEMS: return .red
        case .consultDoctor: return .orange
        case .scheduleAppointment: return .yellow
        case .reviewData: return .blue
        case .adjustEnvironment: return .green
        case .openSettings: return .gray
        case .dismiss: return .secondary
        }
    }
}

struct SeverityBadge: View {
    let rank: AlertPrioritizer.TriageRank

    var body: some View {
        Text(rank.rawValue.capitalized)
            .font(.caption2)
            .padding(6)
            .background(badgeColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }

    var badgeColor: Color {
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