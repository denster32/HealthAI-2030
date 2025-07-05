import SwiftUI
import Combine

/// Aggregates and visualizes system health for clinical trial and optimizer subsystems
struct SystemDiagnosticsDashboard: View {
    @ObservedObject var metalOptimizer = AdvancedMetalOptimizer.shared
    @ObservedObject var networkOptimizer = AdvancedNetworkOptimizer.shared
    @ObservedObject var trialManager: ClinicalTrialManager
    
    @State private var timer: Timer? = nil
    @State private var lastUpdate: Date = Date()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Metal Optimizer")) {
                    HStack { Text("GPU Efficiency"); Spacer(); Text("\(metalOptimizer.gpuEfficiency, specifier: "%.2f")") }
                    HStack { Text("Metal Acceleration"); Spacer(); Text(metalOptimizer.metalAccelerationEnabled ? "Enabled" : "Disabled") }
                    HStack { Text("Current Operation"); Spacer(); Text(metalOptimizer.currentOperation) }
                    HStack { Text("Optimization Progress"); Spacer(); ProgressView(value: metalOptimizer.optimizationProgress) }
                }
                Section(header: Text("Network Optimizer")) {
                    HStack { Text("Network Efficiency"); Spacer(); Text("\(networkOptimizer.networkEfficiency, specifier: "%.2f")") }
                    HStack { Text("Connection Quality"); Spacer(); Text("\(networkOptimizer.connectionQuality.description)") }
                    HStack { Text("Active Connections"); Spacer(); Text("\(networkOptimizer.activeConnections)") }
                    HStack { Text("Current Operation"); Spacer(); Text(networkOptimizer.currentOperation) }
                    HStack { Text("Optimization Progress"); Spacer(); ProgressView(value: networkOptimizer.optimizationProgress) }
                }
                Section(header: Text("Clinical Trials")) {
                    HStack { Text("Active Trials"); Spacer(); Text("\(trialManager.activeClinicalTrials.count)") }
                    HStack { Text("Adverse Events"); Spacer(); Text("\(trialManager.adverseEvents.count)") }
                    HStack { Text("Safety Alerts"); Spacer(); Text("\(trialManager.safetyAlerts.count)") }
                    HStack { Text("Protocol Compliance"); Spacer(); Text("\(trialManager.protocolCompliance.count)") }
                }
                Section(header: Text("System")) {
                    HStack { Text("Last Update"); Spacer(); Text("\(lastUpdate, formatter: dateFormatter)") }
                }
            }
            .navigationTitle("System Diagnostics")
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            lastUpdate = Date()
        }
    }
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .medium
        return df
    }
}

#if DEBUG
struct SystemDiagnosticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        SystemDiagnosticsDashboard(trialManager: ClinicalTrialManager())
    }
}
#endif
