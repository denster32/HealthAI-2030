import SwiftUI

struct SleepStagePredictionView: View {
    @ObservedObject var healthDataManager: HealthDataManager
    @State private var predictedStage: SleepStage? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    private let classifier = SleepStageClassifier()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Live Sleep Stage Prediction")
                .font(.title2)
                .fontWeight(.bold)
            if isLoading {
                ProgressView("Predicting...")
            } else if let stage = predictedStage {
                VStack(spacing: 8) {
                    Image(systemName: stage.iconName)
                        .font(.system(size: 48))
                        .foregroundColor(stage.color)
                    Text(stage.displayName)
                        .font(.largeTitle)
                        .foregroundColor(stage.color)
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                Text("No prediction yet.")
                    .foregroundColor(.secondary)
            }
            Button("Predict Now") {
                Task { await predict() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { Task { await predict() } }
    }
    
    private func predict() async {
        isLoading = true
        errorMessage = nil
        do {
            let features = SleepFeatures(
                heartRateAverage: healthDataManager.currentHeartRate,
                hrv: healthDataManager.currentHRV,
                activityCount: healthDataManager.currentActivityCount,
                wristTemperatureAverage: healthDataManager.currentWristTemperature,
                oxygenSaturation: healthDataManager.currentOxygenSaturation,
                timestamp: Date(),
                sleepWakeDetection: healthDataManager.currentSleepWakeDetection
            )
            let result = await classifier.classifySleepStage(features: features)
            predictedStage = SleepStage(rawValue: result.stage.rawValue)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 