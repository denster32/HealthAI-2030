import SwiftUI

struct ExportProgressView: View {
    @ObservedObject var exportManager = HealthDataExportManager.shared
    @State private var showCancelButton: Bool = true

    var body: some View {
        VStack {
            if let export = exportManager.currentExport {
                Text("Exporting \(export.request.format.rawValue) data...")
                ProgressView(value: export.progress) {
                    Text("\(Int(export.progress * 100))%")
                }
                if let estimatedTimeRemaining = export.estimatedTimeRemaining {
                    Text("Estimated time remaining: \(estimatedTimeRemaining.formatted(.time(pattern: .minuteSecond)))")
                }

                if showCancelButton {
                    Button("Cancel Export") {
                        exportManager.cancelExport()
                        showCancelButton = false // Disable after cancelling
                    }
                    .padding()
                }
            } else {
                Text("No export in progress.")
            }
        }
        .padding()
    }
}

#Preview {
    ExportProgressView()
}