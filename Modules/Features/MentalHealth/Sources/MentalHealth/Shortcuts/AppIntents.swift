import AppIntents
import HealthKit
import SwiftUI

/// An App Intent to get mental health insights.
@available(iOS 18.0, *)
public struct GetMentalHealthInsightsAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Mental Health Insights"
    public static var description = IntentDescription("Gets the user's latest mental health insights.")
    
    @Dependency private var mentalHealthManager: MentalHealthManager
    
    public init() {}
    
    public func perform() async throws -> some IntentResult & ProvidesStringResult {
        let insights = await mentalHealthManager.getLatestInsights()
        let result = insights.isEmpty ? "No mental health insights available." : insights.joined(separator: "\n")
        return .result(value: result)
    }
}