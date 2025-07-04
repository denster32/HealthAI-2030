import SwiftUI

struct DigitalTwinView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var simulationResult: SimulationResult?
    private let simulationEngine = CoreSimulationEngine()
    
    var body: some View {
        NavigationView {
            VStack {
                if let twin = dataManager.digitalTwin {
                    List {
                        Section {
                            Button("View Fusion Explanation") {
                                if let explanation = dataManager.generateFusionExplanation() {
                                    fusionExplanation = explanation
                                    showExplanation = true
                                }
                            }
                        }
                        
                        Section(header: Text("Digital Twin Status")) {
                            Text("Last Updated: \(twin.lastUpdated, formatter: itemFormatter)")
                        }
                        
                        Section(header: Text("Biometric Profile")) {
                            Text("Avg. Heart Rate: \(twin.biometricData.restingHeartRate.reduce(0, +) / Double(twin.biometricData.restingHeartRate.count), specifier: "%.1f") bpm")
                            Text("Avg. HRV: \(twin.biometricData.heartRateVariability.reduce(0, +) / Double(twin.biometricData.heartRateVariability.count), specifier: "%.1f") ms")
                            Text("Avg. SpO2: \(twin.biometricData.bloodOxygenSaturation.reduce(0, +) / Double(twin.biometricData.bloodOxygenSaturation.count), specifier: "%.1f")%")
                        }
                        
                        Section(header: Text("Lifestyle Profile")) {
                            Text("Avg. Sleep: \(twin.lifestyleData.averageSleepDuration / 3600, specifier: "%.1f") hours")
                        }
                        
                        Section(header: Text("Simulations")) {
                            Button("Run Sleep Improvement Simulation") {
                                Task {
                                    self.simulationResult = simulationEngine.simulateScenario(
                                        for: twin,
                                        interventions: [.improveSleep(hoursPerNight: 1.0), .reduceStress],
                                        duration: 30 * 24 * 3600 // 30 days
                                    )
                                }
                            }
                            
                            if let result = simulationResult {
                                Text("Projected Health Score: \(result.projectedHealthScore * 100, specifier: "%.1f")%")
                                Text("Projected Avg. HR: \(result.projectedBiometricData.restingHeartRate.reduce(0, +) / Double(result.projectedBiometricData.restingHeartRate.count), specifier: "%.1f") bpm")
                                Text("Projected Avg. Sleep: \(result.projectedLifestyleData.averageSleepDuration / 3600, specifier: "%.1f") hours")
                            }
                        }
                        
                        if let predictions = dataManager.digitalTwin?.healthPredictions, !predictions.isEmpty {
                            Section(header: Text("Health Predictions")) {
                                ForEach(predictions, id: \.type) { prediction in
                                    VStack(alignment: .leading) {
                                        Text(prediction.type.rawValue).font(.headline)
                                        Text(prediction.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Confidence: \(Int(prediction.confidence * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("Predicted Onset: \(prediction.predictedOnset, formatter: dateFormatter)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                } else {
                    Text("Digital Twin not yet created.")
                        .font(.headline)
                        .padding()
                }
                
                Button(action: {
                    Task {
                        await dataManager.createOrUpdateDigitalTwin()
                    }
                }) {
                    Text(dataManager.digitalTwin == nil ? "Create Digital Twin" : "Update Digital Twin")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Digital Twin")
            .sheet(isPresented: $showExplanation) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Fusion Explanation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    ScrollView {
                        Text(fusionExplanation)
                            .font(.body)
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
                            .padding()
                    }
                    
                    Button("Close") {
                        showExplanation = false
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .medium
    return formatter
}()

struct DigitalTwinView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalTwinView()
            .environmentObject(DataManager.shared)
    }
}