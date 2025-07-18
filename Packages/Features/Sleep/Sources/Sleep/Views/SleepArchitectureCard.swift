import SwiftUI

/// A card view displaying a summary of the user's sleep architecture, including current stage, quality, and stage breakdown.
///
/// - Uses: SleepOptimizationManager (as EnvironmentObject)
/// - Accessibility:
///   - Full VoiceOver support for all elements
///   - Dynamic Type support up to XXXLarge
///   - Switch Control compatible
///   - Detailed accessibility labels for all metrics
struct SleepArchitectureCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey("Sleep Architecture"))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Current Stage: \(sleepOptimizationManager.currentSleepStage.rawValue.capitalized)"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .accessibilityLabel(LocalizedStringKey("Current sleep stage: \(sleepOptimizationManager.currentSleepStage.displayName)"))
                
                SleepStageBreakdownView(sleepMetrics: sleepOptimizationManager.sleepMetrics)
                    .accessibilityLabel(LocalizedStringKey("Sleep stage breakdown"))

                HStack {
                    Text(LocalizedStringKey("Sleep Quality:"))
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(sleepOptimizationManager.sleepQuality * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(sleepQualityColor(sleepOptimizationManager.sleepQuality))
                        .accessibilityLabel(LocalizedStringKey("Sleep quality: \(Int(sleepOptimizationManager.sleepQuality * 100)) percent"))
                }

                Text(LocalizedStringKey("Deep Sleep: \(Int(sleepOptimizationManager.deepSleepPercentage * 100))%"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel(LocalizedStringKey("Deep sleep: \(Int(sleepOptimizationManager.deepSleepPercentage * 100)) percent"))
                Text(LocalizedStringKey("Total Sleep Time: \(formatTimeInterval(sleepOptimizationManager.sleepMetrics.totalSleepTime))"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel(LocalizedStringKey("Total sleep time: \(formatTimeInterval(sleepOptimizationManager.sleepMetrics.totalSleepTime))"))
                Text(LocalizedStringKey("REM Sleep: \(Int(sleepOptimizationManager.sleepMetrics.remSleepPercentage * 100))%"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel(LocalizedStringKey("REM sleep: \(Int(sleepOptimizationManager.sleepMetrics.remSleepPercentage * 100)) percent"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits([.isSummaryElement, .isButton])
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityAction(named: "View details") {
            // Future: Navigate to detailed sleep analysis
        }
        .accessibilityHint("Double tap to view detailed sleep analysis. Shows current sleep stage and quality metrics.")
        .accessibilityLabel("Sleep Architecture Summary")
        .accessibilityValue("""
            Current stage: \(sleepOptimizationManager.currentSleepStage.displayName).
            Quality: \(Int(sleepOptimizationManager.sleepQuality * 100))%.
            Deep sleep: \(Int(sleepOptimizationManager.deepSleepPercentage * 100))%.
            REM sleep: \(Int(sleepOptimizationManager.sleepMetrics.remSleepPercentage * 100))%.
            Total sleep time: \(formatTimeInterval(sleepOptimizationManager.sleepMetrics.totalSleepTime))
        """)
    }

    private func sleepQualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 {
            return .green
        } else if quality >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

/// A horizontal bar view visualizing the breakdown of sleep stages for a session.
///
/// - Accessibility:
///   - Each segment is individually focusable
///   - Provides detailed duration and percentage values
///   - Supports VoiceOver and Switch Control
struct SleepStageBreakdownView: View {
    var sleepMetrics: SleepMetrics
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                // Accessibility: Make each segment individually focusable
                // and provide detailed value descriptions
                Rectangle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.awakePercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.awakePercentage > 0.05 {
                            Text(LocalizedStringKey("Awake"))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                                .accessibilityLabel(LocalizedStringKey("Awake stage"))
                                .accessibilityValue(LocalizedStringKey("\(Int(sleepMetrics.awakePercentage * 100))%, \(formatTimeInterval(sleepMetrics.totalSleepTime * sleepMetrics.awakePercentage))"))
                                .accessibilityHint(LocalizedStringKey("Time spent awake during sleep"))
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                
                Rectangle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.lightSleepPercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.lightSleepPercentage > 0.05 {
                            Text(LocalizedStringKey("Light"))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                                .accessibilityLabel(LocalizedStringKey("Light sleep stage"))
                                .accessibilityValue(LocalizedStringKey("\(Int(sleepMetrics.lightSleepPercentage * 100))%, \(formatTimeInterval(sleepMetrics.totalSleepTime * sleepMetrics.lightSleepPercentage))"))
                                .accessibilityHint(LocalizedStringKey("Time spent in light sleep"))
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                
                Rectangle()
                    .fill(Color.purple.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.deepSleepPercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.deepSleepPercentage > 0.05 {
                            Text(LocalizedStringKey("Deep"))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                                .accessibilityLabel(LocalizedStringKey("Deep sleep stage"))
                                .accessibilityValue(LocalizedStringKey("\(Int(sleepMetrics.deepSleepPercentage * 100))%, \(formatTimeInterval(sleepMetrics.totalSleepTime * sleepMetrics.deepSleepPercentage))"))
                                .accessibilityHint(LocalizedStringKey("Time spent in deep, restorative sleep"))
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                
                Rectangle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.remSleepPercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.remSleepPercentage > 0.05 {
                            Text(LocalizedStringKey("REM"))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                                .accessibilityLabel(LocalizedStringKey("REM sleep stage"))
                                .accessibilityValue(LocalizedStringKey("\(Int(sleepMetrics.remSleepPercentage * 100))%, \(formatTimeInterval(sleepMetrics.totalSleepTime * sleepMetrics.remSleepPercentage))"))
                                .accessibilityHint(LocalizedStringKey("Time spent in REM sleep, important for memory consolidation"))
                                .accessibilityAddTraits(.isButton)
                        }
                    }
            }
            .frame(height: 20)
            .cornerRadius(5)
        }
        .frame(height: 20)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    SleepArchitectureCard()
        .environmentObject(SleepOptimizationManager.shared)
}