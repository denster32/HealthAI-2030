import SwiftUI
import Foundation

struct PrivacySettings {
    var shareHealthData: Bool
    var shareUsageData: Bool
    
    init(shareHealthData: Bool = true, shareUsageData: Bool = false) {
        self.shareHealthData = shareHealthData
        self.shareUsageData = shareUsageData
    }
}

extension PrivacySettings {
    static func load() -> PrivacySettings {
        // Load settings from persistent storage
        // For now, return default settings
        return PrivacySettings()
    }
    
    func save() {
        // Save settings to persistent storage
    }
}

struct DataPrivacyDashboard: View {
    @State private var settings = PrivacySettings.load()
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Your Data")) {
                    Text("Health Data: \(settings.shareHealthData ? "Collected" : "Not Collected")")
                    Text("Usage Data: \(settings.shareUsageData ? "Collected" : "Not Collected")")
                }
                Section(header: Text("Controls")) {
                    Toggle("Share Health Data", isOn: $settings.shareHealthData)
                    Toggle("Share Usage Data", isOn: $settings.shareUsageData)
                }
            }
            .navigationTitle("Data Privacy Dashboard")
        }
        .onChange(of: settings) { newValue in
            newValue.save()
        }
    }
}

#Preview {
    DataPrivacyDashboard()
}
