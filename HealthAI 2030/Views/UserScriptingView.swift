import SwiftUI

struct UserScriptingView: View {
    @State private var script: String = ""
    @State private var output: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Enter your script below:")
                .font(.headline)

            TextEditor(text: $script)
                .border(Color.gray, width: 1)
                .padding()
                .frame(height: 150)
                .overlay(
                    Text(script.isEmpty ? "e.g., WHEN my_sleep_score < 70 DO set_home_lights(to: 'calm', at: '9:00 PM')" : "")
                        .foregroundColor(.gray)
                        .padding(8), alignment: .topLeading
                )

            Button("Run Script") {
                output = UserScriptingEngine().run(script: script)
            }
            .buttonStyle(.borderedProminent)

            Text("Output:")
                .font(.headline)

            ScrollView {
                Text(output)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(height: 200)

            Spacer()
        }
        .padding()
        .navigationTitle("User Scripting")
    }
}

#Preview {
    UserScriptingView()
}
