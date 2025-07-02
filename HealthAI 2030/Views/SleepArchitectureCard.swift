import SwiftUI

struct SleepArchitectureCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                Text("Sleep Architecture")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Current Stage: \(sleepOptimizationManager.currentSleepStage.rawValue.capitalized)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Visual breakdown of sleep stages (simplified for M1 Alpha)
                SleepStageBreakdownView(sleepMetrics: sleepOptimizationManager.sleepMetrics)

                HStack {
                    Text("Sleep Quality:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(sleepOptimizationManager.sleepQuality * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(sleepQualityColor(sleepOptimizationManager.sleepQuality))
                }

                Text("Deep Sleep: \(Int(sleepOptimizationManager.deepSleepPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Total Sleep Time: \(formatTimeInterval(sleepOptimizationManager.sleepMetrics.totalSleepTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("REM Sleep: \(Int(sleepOptimizationManager.sleepMetrics.remSleepPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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

struct SleepStageBreakdownView: View {
    var sleepMetrics: SleepMetrics
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                // Awake
                Rectangle()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.awakePercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.awakePercentage > 0.05 {
                            Text("Awake")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                        }
                    }
                
                // Light Sleep
                Rectangle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.lightSleepPercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.lightSleepPercentage > 0.05 {
                            Text("Light")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                        }
                    }
                
                // Deep Sleep
                Rectangle()
                    .fill(Color.purple.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.deepSleepPercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.deepSleepPercentage > 0.05 {
                            Text("Deep")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                        }
                    }
                
                // REM Sleep
                Rectangle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: geometry.size.width * CGFloat(sleepMetrics.remSleepPercentage))
                    .overlay(alignment: .bottom) {
                        if sleepMetrics.remSleepPercentage > 0.05 {
                            Text("REM")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                        }
                    }
            }
            .frame(height: 20)
            .cornerRadius(5)
        }
        .frame(height: 20)
    }
}

#Preview {
    SleepArchitectureCard()
        .environmentObject(SleepOptimizationManager.shared)
}