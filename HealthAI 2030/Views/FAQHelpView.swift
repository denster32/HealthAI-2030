import SwiftUI

/// FAQ and Help view for user support
struct FAQHelpView: View {
    var body: some View {
        List {
            Section(header: Text("General")) {
                Text("How do I connect my Apple Watch?")
                Text("How do I export my health data?")
            }
            Section(header: Text("Privacy & Security")) {
                Text("How is my data protected?")
                Text("How do I delete my account?")
            }
            Section(header: Text("Features")) {
                Text("How do I use the scripting feature?")
                Text("How do I join a family group?")
            }
        }
        .navigationTitle("FAQ & Help")
    }
}

struct FAQHelpView_Previews: PreviewProvider {
    static var previews: some View {
        FAQHelpView()
    }
}
