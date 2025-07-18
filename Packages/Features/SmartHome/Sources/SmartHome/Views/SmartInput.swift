import SwiftUI
import HealthAI2030UI

struct SmartInput: View {
    @State private var text: String = ""
    let suggestions = ["Headache", "Ibuprofen", "Running", "Salad", "Happy", "Restless"]
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Start typing...", text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Smart Input Field")
                .accessibilityHint("Start typing to see suggestions")
            if !text.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(suggestions.filter { $0.lowercased().contains(text.lowercased()) }, id: \.self) { suggestion in
                            Button(action: { text = suggestion }) {
                                Text(suggestion)
                                    .padding(8)
                                    .background(HealthAIDesignSystem.Color.surface)
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel("Suggestion: \(suggestion)")
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Smart Input")
        .accessibilityElement(children: .contain)
    }
}
