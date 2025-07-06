import SwiftUI

struct RecoveryRatingCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.walk.diamond.fill")
                    .foregroundColor(.green)
                Text("Recovery Rating")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Recovery:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text(recoveryRatingText(sleepOptimizationManager.sleepQuality))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(sleepQualityColor(sleepOptimizationManager.sleepQuality))
                    Spacer()
                    ProgressView(value: sleepOptimizationManager.sleepQuality)
                        .progressViewStyle(CircularProgressViewStyle(tint: sleepQualityColor(sleepOptimizationManager.sleepQuality)))
                        .frame(width: 50, height: 50)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func recoveryRatingText(_ quality: Double) -> String {
        if quality >= 0.9 {
            return "Excellent"
        } else if quality >= 0.7 {
            return "Good"
        } else if quality >= 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
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
}

#Preview {
    RecoveryRatingCard()
        .environmentObject(SleepOptimizationManager.shared)
}