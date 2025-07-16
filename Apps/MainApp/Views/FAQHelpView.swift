import SwiftUI

/// FAQ and Help view for user support
struct FAQHelpView: View {
    var body: some View {
        List {
            Section(header: Text("faq_general_header")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)) {
                Text("faq_q1")
                Text("faq_q2")
            }
            Section(header: Text("faq_privacy_header")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)) {
                Text("faq_q3")
                Text("faq_q4")
            }
            Section(header: Text("faq_features_header")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)) {
                Text("faq_q5")
                Text("faq_q6")
            }
        }
        .navigationTitle(Text("faq_title"))
    }
}

struct FAQHelpView_Previews: PreviewProvider {
    static var previews: some View {
        FAQHelpView()
    }
}
