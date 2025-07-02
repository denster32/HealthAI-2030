import Foundation

class ActionSuggester {
    static let shared = ActionSuggester()
    
    struct SuggestedAction {
        let title: String
        let description: String
        let actionType: ActionType
        let deepLink: String?
    }
    
    enum ActionType {
        case callEMS
        case consultDoctor
        case scheduleAppointment
        case reviewData
        case adjustEnvironment
        case openSettings
        case dismiss
    }
    
    // MARK: - Suggestion Logic
    func suggestActions(for alert: AlertPrioritizer.PrioritizedAlert) -> [SuggestedAction] {
        let rule = alert.alert.rule
        let triage = alert.triageRank
        var actions: [SuggestedAction] = []
        
        switch rule.metricKey {
        case "ecg_ischemia_risk":
            if triage == .critical {
                actions.append(SuggestedAction(
                    title: "Call Emergency Services",
                    description: "Immediate action is required. Call EMS now.",
                    actionType: .callEMS,
                    deepLink: "tel://911"
                ))
            }
            actions.append(SuggestedAction(
                title: "Review ECG Data",
                description: "View detailed ECG and ST segment analysis.",
                actionType: .reviewData,
                deepLink: "app://ecg/insight"
            ))
        case "af_overall_risk":
            if triage == .high || triage == .veryHigh {
                actions.append(SuggestedAction(
                    title: "Consult a Cardiologist",
                    description: "Schedule a consultation with a heart specialist.",
                    actionType: .consultDoctor,
                    deepLink: "app://appointments/cardiology"
                ))
            }
            actions.append(SuggestedAction(
                title: "Review AF Risk Factors",
                description: "See contributing factors and lifestyle tips.",
                actionType: .reviewData,
                deepLink: "app://af/insight"
            ))
        case "qt_dynamic_risk":
            actions.append(SuggestedAction(
                title: "Review QT Dynamics",
                description: "View QT-RR slope and medication guidance.",
                actionType: .reviewData,
                deepLink: "app://qt/insight"
            ))
        case "sleep_quality":
            actions.append(SuggestedAction(
                title: "Adjust Sleep Environment",
                description: "Optimize bedroom environment for better sleep.",
                actionType: .adjustEnvironment,
                deepLink: "app://environment/sleep"
            ))
            actions.append(SuggestedAction(
                title: "Review Sleep Data",
                description: "See detailed sleep metrics and trends.",
                actionType: .reviewData,
                deepLink: "app://sleep/insight"
            ))
        default:
            actions.append(SuggestedAction(
                title: "Dismiss",
                description: "No immediate action required.",
                actionType: .dismiss,
                deepLink: nil
            ))
        }
        return actions
    }
}