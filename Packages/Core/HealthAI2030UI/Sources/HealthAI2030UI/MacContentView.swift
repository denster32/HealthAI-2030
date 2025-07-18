import SwiftUI

struct MacContentView: View {
    @ObservedObject var analyzer = HealthDataAnalyzer.shared
    var body: some View {
        VStack {
            Text("HealthAI 2030 for Mac")
                .font(.largeTitle).bold()
                .padding(.top, 32)
            Text("All your Apple Health data is being analyzed on your Mac for maximum speed and privacy.")
                .font(.title3)
                .padding(.bottom, 16)
            if analyzer.analysisResults.isEmpty {
                ProgressView("Analyzing health data...")
            } else {
                List(analyzer.analysisResults.sorted(by: { $0.key < $1.key }), id: \ .key) { key, value in
                    HStack {
                        Text(key.capitalized)
                        Spacer()
                        Text("\(value)")
                    }
                }
            }
            Spacer()
            Text("Premium Mac Experience: Full analytics, AR, and export features.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
