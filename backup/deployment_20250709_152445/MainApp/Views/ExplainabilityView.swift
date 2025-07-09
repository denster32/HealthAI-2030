import SwiftUI

struct ExplainabilityView: View {
    let recommendation: String
    @State private var explanation: String = ""
    @State private var isLoading: Bool = false
    @State private var error: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendation:").font(.headline)
            Text(recommendation)
            Divider()
            Text("Explanation:").font(.headline)
            if isLoading {
                ProgressView("Generating explanation...")
            } else if let error = error {
                Text("Error: \(error)").foregroundColor(.red)
            } else {
                Text(explanation)
                    .font(.system(.body, design: .monospaced))
            }
            Spacer()
            Button("Regenerate Explanation") {
                generateExplanation()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            generateExplanation()
        }
        .navigationTitle("Explainability")
    }
    private func generateExplanation() {
        isLoading = true
        error = nil
        DispatchQueue.global().async {
            // Simulate async explainability (replace with real async call if available)
            sleep(1)
            let result = ExplainableAI().explanation(for: recommendation)
            DispatchQueue.main.async {
                self.explanation = result
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ExplainabilityView(recommendation: "Go to bed earlier tonight.")
}
