import SwiftUI

struct AccessibilityResourcesView: View {
    var body: some View {
        List {
            Section("Voiceover Script") {
                Text("Voiceover script available in-app and as a downloadable file.")
            }
            Section("Haptic Guide") {
                Text("Haptic feedback guide for accessible navigation.")
            }
            Section("Large Print Guide") {
                Text("Large print user guide for low-vision users.")
            }
        }
        .navigationTitle("Accessibility Resources")
    }
}
