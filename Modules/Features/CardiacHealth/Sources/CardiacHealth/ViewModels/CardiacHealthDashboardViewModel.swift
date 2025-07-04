import Foundation
import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
public class CardiacHealthDashboardViewModel: ObservableObject {
    private let healthKitManager: HealthKitManager
    private let ecgInsightManager: ECGInsightManager
    
    @Published public var summary: CardiacSummary?
    @Published public var trendData: [HeartRateMeasurement] = []
    @Published public var riskAssessment: String?
    @Published public var recommendations: [String] = []
    @Published public var riskLevel: RiskLevel = .low
    @Published public var error: CardiacHealthError?
    
    public init(healthKitManager: HealthKitManager, ecgInsightManager: ECGInsightManager) {
        self.healthKitManager = healthKitManager
        self.ecgInsightManager = ecgInsightManager
    }
    
    @MainActor
    public func fetchAllData() async {
        do {
            summary = try await healthKitManager.fetchCardiacSummary()
            trendData = try await healthKitManager.fetchHeartRateTrend(days: 7)
            await updateRiskAssessment()
        } catch {
            self.error = error as? CardiacHealthError ?? .dataFetchFailed
        }
    }
    
    @MainActor
    public func updateRiskAssessment() async {
        // Calculate risk based on ECG insights
        let criticalCount = ecgInsightManager.insights.filter { $0.severity == .critical }.count
        let warningCount = ecgInsightManager.insights.filter { $0.severity == .warning }.count
        
        riskLevel = if criticalCount > 0 {
            .critical
        } else if warningCount > 1 {
            .high
        } else if warningCount == 1 {
            .moderate
        } else {
            .low
        }
        
        riskAssessment = "Risk Level: \(riskLevel.rawValue)"
        updateRecommendations()
    }
    
    private func updateRecommendations() {
        recommendations = []
        
        switch riskLevel {
        case .critical:
            recommendations.append("Seek immediate medical attention")
            recommendations.append("Contact your healthcare provider")
        case .high:
            recommendations.append("Schedule a check-up with your doctor")
            recommendations.append("Monitor symptoms closely")
        case .moderate:
            recommendations.append("Continue monitoring your heart health")
            recommendations.append("Consider lifestyle adjustments")
        case .low:
            recommendations.append("Maintain current healthy habits")
            recommendations.append("Regular check-ups recommended")
        }
    }
}
