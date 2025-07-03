import SwiftUI

struct UserScriptingView: View {
    @State private var script: String = ""
    @State private var output: String = ""
    var body: some View {
        VStack(alignment: .leading) {
            Text("User Script").font(.headline)
            TextEditor(text: $script)
                .border(Color.gray)
                .frame(height: 120)
            Button("Run Script") {
                output = UserScriptingEngine().run(script: script)
            }
            .padding(.top)
            Text("Output:")
            Text(output).font(.system(.body, design: .monospaced))
            Spacer()
        }
        .padding()
        .navigationTitle("User Scripting")
    }
}

#Preview {
    UserScriptingView()
}
