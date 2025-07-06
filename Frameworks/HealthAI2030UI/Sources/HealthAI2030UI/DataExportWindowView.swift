import SwiftUI
import AppKit

struct DataExportWindowView: View {
    @EnvironmentObject var dataExportManager: DataExportManager
    @State private var dateRange: ClosedRange<Date> = {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        return start...now
    }()
    @State private var selectedMetrics: Set<String> = ["sleepStage"]
    @State private var selectedFormat: DataExportManager.ExportFormat = .csv
    @State private var showShareSheet = false
    @State private var showSaveLocation = false
    @State private var finalExportURL: URL?

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start", selection: Binding(
                        get: { dateRange.lowerBound },
                        set: { dateRange = $0...dateRange.upperBound }
                    ), displayedComponents: .date)
                    DatePicker("End", selection: Binding(
                        get: { dateRange.upperBound },
                        set: { dateRange = dateRange.lowerBound...$0 }
                    ), displayedComponents: .date)
                }
                Section(header: Text("Metrics to Export")) {
                    Toggle("Sleep Stage", isOn: Binding(
                        get: { selectedMetrics.contains("sleepStage") },
                        set: { if $0 { selectedMetrics.insert("sleepStage") } else { selectedMetrics.remove("sleepStage") } }
                    ))
                    // Add toggles for other metrics as needed
                }
                Section(header: Text("Format")) {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(DataExportManager.ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            HStack {
                Button(action: {
                    dataExportManager.exportData(dateRange: dateRange, metrics: Array(selectedMetrics), format: selectedFormat)
                }) {
                    if dataExportManager.isExporting {
                        ProgressView()
                    } else {
                        Text("Export")
                    }
                }
                .disabled(dataExportManager.isExporting)
                Spacer()
                if let url = dataExportManager.lastExportURL {
                    Button("Share") {
                        showShareSheet = true
                    }
                    .sheet(isPresented: $showShareSheet) {
                        ShareLink(item: url)
                    }
                }
            }
            .padding()
            if let error = dataExportManager.exportError {
                Text("Error exporting data: \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding([.leading, .trailing, .bottom])
            }
        }
        .padding()
        // After temp export, prompt save panel
        .onChange(of: dataExportManager.lastExportURL) { url in
            if url != nil {
                showSaveLocation = true
            }
        }
        .onChange(of: showSaveLocation) { show in
            guard show, let tempURL = dataExportManager.lastExportURL else { return }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [selectedFormat == .csv ? UTType.commaSeparatedText : UTType.json]
            panel.nameFieldStringValue = tempURL.lastPathComponent
            if panel.runModal() == .OK, let destURL = panel.url {
                do {
                    try FileManager.default.copyItem(at: tempURL, to: destURL)
                    finalExportURL = destURL
                } catch {
                    dataExportManager.exportError = error
                }
            }
            showSaveLocation = false
        }
    }
}

struct DataExportWindowView_Previews: PreviewProvider {
    static var previews: some View {
        DataExportWindowView()
            .environmentObject(DataExportManager.shared)
    }
}
