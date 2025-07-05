import Foundation
import SwiftData

/// Skill that analyzes causal relationships between health metrics and provides explanations
public class CausalExplanationSkill: BaseCopilotSkill {
    
    public init() {
        super.init(
            skillID: "causal_explanation",
            skillName: "Causal Explanation",
            skillDescription: "Analyzes relationships between health metrics and explains patterns",
            handledIntents: [
                "explain_sleep_quality",
                "explain_heart_rate",
                "explain_stress_level",
                "explain_activity_pattern",
                "analyze_correlation",
                "why_health_change"
            ],
            priority: 3,
            requiresAuthentication: false
        )
    }
    
    public override func execute(intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        switch intent {
        case "explain_sleep_quality":
            return await explainSleepQuality(context: context)
        case "explain_heart_rate":
            return await explainHeartRate(context: context)
        case "explain_stress_level":
            return await explainStressLevel(context: context)
        case "explain_activity_pattern":
            return await explainActivityPattern(context: context)
        case "analyze_correlation":
            return await analyzeCorrelation(parameters: parameters, context: context)
        case "why_health_change":
            return await explainHealthChange(parameters: parameters, context: context)
        default:
            return .error("Unknown intent: \(intent)")
        }
    }
    
    private func explainSleepQuality(context: CopilotContext) async -> CopilotSkillResult {
        let recentSleepSessions = context.sleepSessions.suffix(7) // Last 7 sessions
        let recentHealthData = filterHealthDataByTimeRange(context.healthData, hours: 168) // Last 7 days
        
        guard !recentSleepSessions.isEmpty else {
            return .text("I don't have enough sleep data to provide an analysis. Try tracking your sleep for a few nights first.")
        }
        
        let averageSleepScore = recentSleepSessions.compactMap { $0.sleepScore }.reduce(0, +) / Double(recentSleepSessions.count)
        let averageSleepDuration = recentSleepSessions.map { $0.duration }.reduce(0, +) / Double(recentSleepSessions.count) / 3600
        
        var explanations: [String] = []
        var correlations: [String: Double] = [:]
        
        // Analyze correlations with other health metrics
        if !recentHealthData.isEmpty {
            let stressLevels = recentHealthData.compactMap { $0.stressLevel }
            let activityLevels = recentHealthData.compactMap { $0.activityLevel }
            let heartRates = recentHealthData.compactMap { $0.heartRate }
            
            if !stressLevels.isEmpty {
                let stressCorrelation = calculateCorrelation(
                    recentSleepSessions.map { $0.sleepScore ?? 0 },
                    stressLevels
                )
                correlations["stress"] = stressCorrelation
                
                if stressCorrelation < -0.3 {
                    explanations.append("Higher stress levels are strongly correlated with lower sleep quality.")
                }
            }
            
            if !activityLevels.isEmpty {
                let activityCorrelation = calculateCorrelation(
                    recentSleepSessions.map { $0.sleepScore ?? 0 },
                    activityLevels
                )
                correlations["activity"] = activityCorrelation
                
                if activityCorrelation > 0.3 {
                    explanations.append("Higher activity levels are associated with better sleep quality.")
                }
            }
        }
        
        // Generate insights based on sleep patterns
        if averageSleepScore < 70 {
            explanations.append("Your sleep quality has been below optimal levels. Consider improving your sleep hygiene.")
        }
        
        if averageSleepDuration < 7 {
            explanations.append("You're getting less than the recommended 7-9 hours of sleep per night.")
        }
        
        let result: [String: Any] = [
            "type": "sleep_analysis",
            "average_score": averageSleepScore,
            "average_duration": averageSleepDuration,
            "explanations": explanations,
            "correlations": correlations,
            "recommendations": generateSleepRecommendations(averageSleepScore: averageSleepScore, averageDuration: averageSleepDuration)
        ]
        
        return .composite([
            .text(generateSleepExplanationText(averageSleepScore: averageSleepScore, averageDuration: averageSleepDuration, explanations: explanations)),
            .json(result)
        ])
    }
    
    private func explainHeartRate(context: CopilotContext) async -> CopilotSkillResult {
        let recentHealthData = filterHealthDataByTimeRange(context.healthData, hours: 24)
        
        guard !recentHealthData.isEmpty else {
            return .text("I don't have enough heart rate data to provide an analysis.")
        }
        
        let heartRates = recentHealthData.compactMap { $0.heartRate }
        let hrvValues = recentHealthData.compactMap { $0.hrv }
        let stressLevels = recentHealthData.compactMap { $0.stressLevel }
        let activityLevels = recentHealthData.compactMap { $0.activityLevel }
        
        let averageHeartRate = heartRates.reduce(0, +) / Double(heartRates.count)
        let averageHRV = hrvValues.isEmpty ? 0 : hrvValues.reduce(0, +) / Double(hrvValues.count)
        
        var explanations: [String] = []
        var insights: [String: Any] = [:]
        
        // Analyze heart rate patterns
        if averageHeartRate > 100 {
            explanations.append("Your average heart rate is elevated, which could indicate stress, dehydration, or recent physical activity.")
        } else if averageHeartRate < 60 {
            explanations.append("Your heart rate is on the lower side, which is often a sign of good cardiovascular fitness.")
        }
        
        // Analyze HRV
        if averageHRV > 50 {
            explanations.append("Your heart rate variability is excellent, indicating good autonomic nervous system balance.")
        } else if averageHRV < 30 {
            explanations.append("Your heart rate variability is low, which may indicate stress or poor recovery.")
        }
        
        // Correlate with other metrics
        if !stressLevels.isEmpty {
            let stressCorrelation = calculateCorrelation(heartRates, stressLevels)
            if stressCorrelation > 0.5 {
                explanations.append("Your heart rate shows a strong positive correlation with stress levels.")
            }
        }
        
        if !activityLevels.isEmpty {
            let activityCorrelation = calculateCorrelation(heartRates, activityLevels)
            if activityCorrelation > 0.4 {
                explanations.append("Your heart rate increases with activity levels, which is normal and healthy.")
            }
        }
        
        insights = [
            "average_heart_rate": averageHeartRate,
            "average_hrv": averageHRV,
            "heart_rate_range": heartRates.isEmpty ? [:] : ["min": heartRates.min()!, "max": heartRates.max()!],
            "explanations": explanations
        ]
        
        return .composite([
            .text(generateHeartRateExplanationText(averageHeartRate: averageHeartRate, averageHRV: averageHRV, explanations: explanations)),
            .json(insights)
        ])
    }
    
    private func explainStressLevel(context: CopilotContext) async -> CopilotSkillResult {
        let recentHealthData = filterHealthDataByTimeRange(context.healthData, hours: 48)
        
        guard !recentHealthData.isEmpty else {
            return .text("I don't have enough stress data to provide an analysis.")
        }
        
        let stressLevels = recentHealthData.compactMap { $0.stressLevel }
        let sleepScores = context.sleepSessions.suffix(3).compactMap { $0.sleepScore }
        let activityLevels = recentHealthData.compactMap { $0.activityLevel }
        let heartRates = recentHealthData.compactMap { $0.heartRate }
        
        let averageStress = stressLevels.reduce(0, +) / Double(stressLevels.count)
        
        var explanations: [String] = []
        var factors: [String: Double] = [:]
        
        // Analyze stress patterns
        if averageStress > 0.7 {
            explanations.append("Your stress levels are elevated. Consider stress management techniques.")
        } else if averageStress < 0.3 {
            explanations.append("Your stress levels are well-managed. Keep up the good work!")
        }
        
        // Correlate with sleep
        if !sleepScores.isEmpty {
            let sleepCorrelation = calculateCorrelation(stressLevels, sleepScores)
            factors["sleep_impact"] = sleepCorrelation
            if sleepCorrelation < -0.4 {
                explanations.append("Poor sleep quality is strongly associated with higher stress levels.")
            }
        }
        
        // Correlate with activity
        if !activityLevels.isEmpty {
            let activityCorrelation = calculateCorrelation(stressLevels, activityLevels)
            factors["activity_impact"] = activityCorrelation
            if activityCorrelation < -0.3 {
                explanations.append("Higher activity levels are associated with lower stress.")
            }
        }
        
        // Correlate with heart rate
        if !heartRates.isEmpty {
            let heartRateCorrelation = calculateCorrelation(stressLevels, heartRates)
            factors["heart_rate_impact"] = heartRateCorrelation
            if heartRateCorrelation > 0.4 {
                explanations.append("Stress levels are positively correlated with heart rate.")
            }
        }
        
        let result: [String: Any] = [
            "average_stress": averageStress,
            "stress_trend": calculateTrend(stressLevels),
            "contributing_factors": factors,
            "explanations": explanations,
            "recommendations": generateStressRecommendations(averageStress: averageStress)
        ]
        
        return .composite([
            .text(generateStressExplanationText(averageStress: averageStress, explanations: explanations)),
            .json(result)
        ])
    }
    
    private func explainActivityPattern(context: CopilotContext) async -> CopilotSkillResult {
        let recentWorkouts = context.workoutRecords.suffix(10)
        let recentHealthData = filterHealthDataByTimeRange(context.healthData, hours: 168) // Last week
        
        guard !recentWorkouts.isEmpty else {
            return .text("I don't have enough activity data to provide an analysis. Try logging some workouts first.")
        }
        
        let totalWorkouts = recentWorkouts.count
        let totalDuration = recentWorkouts.map { $0.duration }.reduce(0, +) / 3600 // Hours
        let averageDuration = totalDuration / Double(totalWorkouts)
        let totalCalories = recentWorkouts.compactMap { $0.caloriesBurned }.reduce(0, +)
        
        var explanations: [String] = []
        var patterns: [String: Any] = [:]
        
        // Analyze workout patterns
        if totalWorkouts >= 5 {
            explanations.append("You're maintaining a consistent workout routine with \(totalWorkouts) sessions this week.")
        } else if totalWorkouts < 3 {
            explanations.append("Your workout frequency is below recommended levels. Aim for 3-5 sessions per week.")
        }
        
        if averageDuration > 1.0 {
            explanations.append("Your workouts are substantial in duration, which is great for cardiovascular health.")
        }
        
        // Analyze workout timing patterns
        let workoutTimes = recentWorkouts.map { Calendar.current.component(.hour, from: $0.startTime) }
        let morningWorkouts = workoutTimes.filter { $0 >= 6 && $0 <= 10 }.count
        let eveningWorkouts = workoutTimes.filter { $0 >= 17 && $0 <= 21 }.count
        
        if morningWorkouts > eveningWorkouts {
            explanations.append("You prefer morning workouts, which can boost metabolism and energy throughout the day.")
        } else if eveningWorkouts > morningWorkouts {
            explanations.append("You prefer evening workouts, which can help with stress relief and sleep preparation.")
        }
        
        patterns = [
            "total_workouts": totalWorkouts,
            "total_duration": totalDuration,
            "average_duration": averageDuration,
            "total_calories": totalCalories,
            "morning_workouts": morningWorkouts,
            "evening_workouts": eveningWorkouts
        ]
        
        let result: [String: Any] = [
            "activity_summary": patterns,
            "explanations": explanations,
            "recommendations": generateActivityRecommendations(totalWorkouts: totalWorkouts, averageDuration: averageDuration)
        ]
        
        return .composite([
            .text(generateActivityExplanationText(totalWorkouts: totalWorkouts, totalDuration: totalDuration, explanations: explanations)),
            .json(result)
        ])
    }
    
    private func analyzeCorrelation(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let metric1 = parameters["metric1"] as? String,
              let metric2 = parameters["metric2"] as? String else {
            return .error("Missing required parameters: metric1 and metric2")
        }
        
        let recentData = filterHealthDataByTimeRange(context.healthData, hours: 168) // Last week
        
        guard !recentData.isEmpty else {
            return .text("Insufficient data for correlation analysis.")
        }
        
        let values1 = getMetricValues(recentData, metric: metric1)
        let values2 = getMetricValues(recentData, metric: metric2)
        
        guard values1.count == values2.count && values1.count > 1 else {
            return .text("Insufficient data points for correlation analysis.")
        }
        
        let correlation = calculateCorrelation(values1, values2)
        let strength = getCorrelationStrength(correlation)
        
        let explanation = "The correlation between \(metric1) and \(metric2) is \(String(format: "%.3f", correlation)) (\(strength))."
        
        let result: [String: Any] = [
            "metric1": metric1,
            "metric2": metric2,
            "correlation": correlation,
            "strength": strength,
            "data_points": values1.count,
            "explanation": explanation
        ]
        
        return .composite([
            .text(explanation),
            .json(result)
        ])
    }
    
    private func explainHealthChange(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let metric = parameters["metric"] as? String else {
            return .error("Missing required parameter: metric")
        }
        
        let recentData = filterHealthDataByTimeRange(context.healthData, hours: 168) // Last week
        let olderData = filterHealthDataByTimeRange(context.healthData, hours: 336) // Week before last
        
        guard !recentData.isEmpty && !olderData.isEmpty else {
            return .text("Insufficient historical data to analyze changes.")
        }
        
        let recentValues = getMetricValues(recentData, metric: metric)
        let olderValues = getMetricValues(olderData, metric: metric)
        
        guard !recentValues.isEmpty && !olderValues.isEmpty else {
            return .text("No data available for the specified metric.")
        }
        
        let recentAverage = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAverage = olderValues.reduce(0, +) / Double(olderValues.count)
        let change = recentAverage - olderAverage
        let percentChange = (change / olderAverage) * 100
        
        var explanations: [String] = []
        
        if abs(percentChange) > 10 {
            if percentChange > 0 {
                explanations.append("Your \(metric) has increased by \(String(format: "%.1f", percentChange))% compared to the previous week.")
            } else {
                explanations.append("Your \(metric) has decreased by \(String(format: "%.1f", abs(percentChange)))% compared to the previous week.")
            }
        } else {
            explanations.append("Your \(metric) has remained relatively stable over the past two weeks.")
        }
        
        // Add contextual explanations based on the metric
        explanations.append(contentsOf: getContextualExplanations(metric: metric, change: change, context: context))
        
        let result: [String: Any] = [
            "metric": metric,
            "recent_average": recentAverage,
            "older_average": olderAverage,
            "change": change,
            "percent_change": percentChange,
            "explanations": explanations
        ]
        
        return .composite([
            .text(generateChangeExplanationText(metric: metric, percentChange: percentChange, explanations: explanations)),
            .json(result)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator == 0 ? 0 : numerator / denominator
    }
    
    private func getCorrelationStrength(_ correlation: Double) -> String {
        let absCorr = abs(correlation)
        switch absCorr {
        case 0.8...1.0: return "very strong"
        case 0.6..<0.8: return "strong"
        case 0.4..<0.6: return "moderate"
        case 0.2..<0.4: return "weak"
        default: return "very weak"
        }
    }
    
    private func calculateTrend(_ values: [Double]) -> String {
        guard values.count >= 3 else { return "insufficient data" }
        
        let recent = Array(values.suffix(3))
        let older = Array(values.prefix(3))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        let change = recentAvg - olderAvg
        if change > 0.1 { return "increasing" }
        else if change < -0.1 { return "decreasing" }
        else { return "stable" }
    }
    
    private func getMetricValues(_ data: [HealthData], metric: String) -> [Double] {
        switch metric.lowercased() {
        case "heart_rate":
            return data.compactMap { $0.heartRate }
        case "stress_level":
            return data.compactMap { $0.stressLevel }
        case "activity_level":
            return data.compactMap { $0.activityLevel }
        case "hrv":
            return data.compactMap { $0.hrv }
        case "oxygen_saturation":
            return data.compactMap { $0.oxygenSaturation }
        default:
            return []
        }
    }
    
    private func getContextualExplanations(metric: String, change: Double, context: CopilotContext) -> [String] {
        var explanations: [String] = []
        
        switch metric.lowercased() {
        case "heart_rate":
            if change > 5 {
                explanations.append("This could be due to increased stress, physical activity, or changes in medication.")
            } else if change < -5 {
                explanations.append("This improvement might be due to better fitness, reduced stress, or improved sleep.")
            }
        case "stress_level":
            if change > 0.2 {
                explanations.append("Consider stress management techniques like meditation, exercise, or talking to a professional.")
            } else if change < -0.2 {
                explanations.append("Great job managing stress! Keep up the positive habits.")
            }
        case "activity_level":
            if change > 0.2 {
                explanations.append("Increased activity is excellent for overall health and mood.")
            } else if change < -0.2 {
                explanations.append("Try to gradually increase your activity levels for better health outcomes.")
            }
        default:
            break
        }
        
        return explanations
    }
    
    // MARK: - Text Generation Methods
    
    private func generateSleepExplanationText(averageSleepScore: Double, averageDuration: Double, explanations: [String]) -> String {
        var text = "Your sleep analysis shows an average score of \(String(format: "%.1f", averageSleepScore)) and \(String(format: "%.1f", averageDuration)) hours of sleep per night. "
        
        if !explanations.isEmpty {
            text += explanations.joined(separator: " ")
        }
        
        return text
    }
    
    private func generateHeartRateExplanationText(averageHeartRate: Double, averageHRV: Double, explanations: [String]) -> String {
        var text = "Your heart rate analysis shows an average of \(String(format: "%.0f", averageHeartRate)) BPM with an HRV of \(String(format: "%.1f", averageHRV))ms. "
        
        if !explanations.isEmpty {
            text += explanations.joined(separator: " ")
        }
        
        return text
    }
    
    private func generateStressExplanationText(averageStress: Double, explanations: [String]) -> String {
        var text = "Your stress analysis shows an average stress level of \(String(format: "%.2f", averageStress)). "
        
        if !explanations.isEmpty {
            text += explanations.joined(separator: " ")
        }
        
        return text
    }
    
    private func generateActivityExplanationText(totalWorkouts: Int, totalDuration: Double, explanations: [String]) -> String {
        var text = "Your activity analysis shows \(totalWorkouts) workouts totaling \(String(format: "%.1f", totalDuration)) hours this week. "
        
        if !explanations.isEmpty {
            text += explanations.joined(separator: " ")
        }
        
        return text
    }
    
    private func generateChangeExplanationText(metric: String, percentChange: Double, explanations: [String]) -> String {
        var text = "Your \(metric) has changed by \(String(format: "%.1f", percentChange))% over the past two weeks. "
        
        if !explanations.isEmpty {
            text += explanations.joined(separator: " ")
        }
        
        return text
    }
    
    // MARK: - Recommendation Generation
    
    private func generateSleepRecommendations(averageSleepScore: Double, averageDuration: Double) -> [String] {
        var recommendations: [String] = []
        
        if averageSleepScore < 70 {
            recommendations.append("Establish a consistent bedtime routine")
            recommendations.append("Avoid screens 1 hour before bed")
            recommendations.append("Keep your bedroom cool and dark")
        }
        
        if averageDuration < 7 {
            recommendations.append("Aim for 7-9 hours of sleep per night")
            recommendations.append("Go to bed 30 minutes earlier")
        }
        
        return recommendations
    }
    
    private func generateStressRecommendations(averageStress: Double) -> [String] {
        var recommendations: [String] = []
        
        if averageStress > 0.7 {
            recommendations.append("Practice daily meditation or deep breathing")
            recommendations.append("Increase physical activity")
            recommendations.append("Consider talking to a mental health professional")
        }
        
        return recommendations
    }
    
    private func generateActivityRecommendations(totalWorkouts: Int, averageDuration: Double) -> [String] {
        var recommendations: [String] = []
        
        if totalWorkouts < 3 {
            recommendations.append("Aim for 3-5 workouts per week")
            recommendations.append("Start with shorter, more frequent sessions")
        }
        
        if averageDuration < 0.5 {
            recommendations.append("Gradually increase workout duration")
            recommendations.append("Mix cardio and strength training")
        }
        
        return recommendations
    }
    
    public override func getSuggestedActions(context: CopilotContext) -> [CopilotAction] {
        return [
            CopilotAction(
                id: "start_meditation",
                title: "Start Meditation",
                description: "Begin a stress-reducing meditation session",
                icon: "brain.head.profile",
                actionType: .startMeditation
            ),
            CopilotAction(
                id: "log_mood",
                title: "Log Mood",
                description: "Record your current emotional state",
                icon: "face.smiling",
                actionType: .logMood
            ),
            CopilotAction(
                id: "view_sleep_details",
                title: "View Sleep Details",
                description: "See detailed sleep analysis",
                icon: "bed.double.fill",
                actionType: .viewDetails,
                parameters: ["section": "sleep"]
            )
        ]
    }
} 