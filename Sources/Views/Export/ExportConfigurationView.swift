import SwiftUI
import HealthKit

struct ExportConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var exportManager = HealthDataExportManager.shared
    @State private var selectedFormat: ExportFormat = .json
    @State private var selectedDataTypes: [HealthDataType] = []
    @State private var startDate: Date = Date().addingTimeInterval(-86400 * 7) // Default to last 7 days
    @State private var endDate: Date = Date()
    @State private var isEncrypting: Bool = false
    @State private var encryptionPassword: String = ""
    @State private var showExportEstimate: Bool = false
    @State private var exportEstimate: ExportEstimate?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Format")) {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }

                Section(header: Text("Data Types")) {
                    ForEach(HealthDataType.allCases, id: \.self) { dataType in
                        Button(action: {
                            if selectedDataTypes.contains(dataType) {
                                selectedDataTypes.removeAll(where: { $0 == dataType })
                            } else {
                                selectedDataTypes.append(dataType)
                            }
                        }) {
                            HStack {
                                Text(dataType.rawValue)
                                Spacer()
                                Image(systemName: selectedDataTypes.contains(dataType) ? "checkmark.circle.fill" : "circle")
                            }
                        }
                    }
                }

                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                Section(header: Text("Encryption")) {
                    Toggle("Encrypt File", isOn: $isEncrypting)
                    if isEncrypting {
                        SecureField("Password", text: $encryptionPassword)
                    }
                }

                Button(action: {
                    showExportEstimate = true
                }) {
                    Text("Estimate Export")
                }

                if let exportEstimate = exportEstimate {
                    Text("Estimated Size: \(exportEstimate.estimatedFileSize.formatted(.byteCount(style: .file)))")
                    Text("Estimated Duration: \(exportEstimate.estimatedDuration.formatted(.time(pattern: .minuteSecond)))")
                }

                Button(action: {
                    startExport()
                }) {
                    Text("Start Export")
                }
                .disabled(exportManager.isExporting)
            }
            .navigationTitle("Export Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExportEstimate) {
                ExportEstimateView(
                    request: ExportRequest(
                        format: selectedFormat,
                        dataTypes: selectedDataTypes,
                        dateRange: DateRange(startDate: startDate, endDate: endDate),
                        privacySettings: PrivacySettings(anonymizeData: false, excludeSensitiveData: false),
                        encryptionSettings: EncryptionSettings(encryptFile: isEncrypting, password: encryptionPassword)
                    )
                )
            }
        }
    }

    private func startExport() {
        let request = ExportRequest(
            format: selectedFormat,
            dataTypes: selectedDataTypes,
            dateRange: DateRange(startDate: startDate, endDate: endDate),
            privacySettings: PrivacySettings(anonymizeData: false, excludeSensitiveData: false),
            encryptionSettings: EncryptionSettings(encryptFile: isEncrypting, password: encryptionPassword)
        )

        Task {
            do {
                let exportId = try await exportManager.startExport(request)
                // Handle export ID if needed
                dismiss()
            } catch {
                // Handle export error
                print("Export failed: \(error)")
            }
        }
    }
}

struct ExportEstimateView: View {
    @Environment(\.dismiss) var dismiss
    let request: ExportRequest
    @State private var estimate: ExportEstimate?

    var body: some View {
        NavigationView {
            VStack {
                if let estimate = estimate {
                    Text("Estimated Size: \(estimate.estimatedFileSize.formatted(.byteCount(style: .file)))")
                    Text("Estimated Duration: \(estimate.estimatedDuration.formatted(.time(pattern: .minuteSecond)))")
                    Text("Estimated Records: \(estimate.recordCount)")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Export Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                estimate = await HealthDataExportManager.shared.estimateExport(request)
            }
        }
    }
}

#Preview {
    ExportConfigurationView()
}