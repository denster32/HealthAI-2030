import SwiftUI

/// Data Privacy Dashboard for user transparency and control
struct DataPrivacyDashboardView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Your Data")) {
                    Text("Download your health data")
                    Text("Delete your account and data")
                }
                Section(header: Text("Permissions")) {
                    Text("Manage app permissions")
                }
                Section(header: Text("Privacy Settings")) {
                    Toggle("Share anonymized analytics", isOn: .constant(true))
                    Toggle("Enable personalized recommendations", isOn: .constant(true))
                }
            }
            .navigationTitle("Data Privacy Dashboard")
        }
    }
}

struct DataPrivacyDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DataPrivacyDashboardView()
    }
}
