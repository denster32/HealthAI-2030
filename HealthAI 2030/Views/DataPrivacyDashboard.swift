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
                Section(header: Text("Detailed Controls")) {
                    NavigationLink(destination: HealthDataSharingView()) {
                        Text("Manage Health Data Sharing")
                    }
                    NavigationLink(destination: UsageDataSharingView()) {
                        Text("Manage Usage Data Sharing")
                    }
                }
            }
            .navigationTitle("Data Privacy Dashboard")
        }
        .onChange(of: settings) { newValue in
            newValue.save()
        }
    }
}

struct HealthDataSharingView: View {
    @State private var shareHeartRate = true
    @State private var shareSleepData = false
    @State private var shareActivityData = true

    var body: some View {
        Form {
            Toggle("Share Heart Rate Data", isOn: $shareHeartRate)
            Toggle("Share Sleep Data", isOn: $shareSleepData)
            Toggle("Share Activity Data", isOn: $shareActivityData)
        }
        .navigationTitle("Health Data Sharing")
    }
}

struct UsageDataSharingView: View {
    @State private var shareAppUsage = true
    @State private var shareCrashReports = false

    var body: some View {
        Form {
            Toggle("Share App Usage Data", isOn: $shareAppUsage)
            Toggle("Share Crash Reports", isOn: $shareCrashReports)
        }
        .navigationTitle("Usage Data Sharing")
    }
}

#Preview {
    DataPrivacyDashboard()
}
