import SwiftUI
import UniformTypeIdentifiers

struct AdvancedDataExportView: View {
    @StateObject private var exportManager = AdvancedDataExportManager()
    @State private var selectedExportFormat: ExportFormat = .json
    @State private var includeHealthData = true
    @State private var includeAppData = true
    @State private var showingExportSheet = false
    @State private var showingBackupSheet = false
    @State private var showingRecoverySheet = false
    @State private var showingMigrationSheet = false
    @State private var selectedBackup: BackupRecord?
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Export Section
                    exportSection
                    
                    // Backup Section
                    backupSection
                    
                    // Recovery Section
                    recoverySection
                    
                    // Migration Section
                    migrationSection
                    
                    // History Section
                    historySection
                }
                .padding()
            }
            .navigationTitle("Data Export & Backup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // Settings action
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportOptionsView(
                exportManager: exportManager,
                selectedFormat: $selectedExportFormat,
                includeHealthData: $includeHealthData,
                includeAppData: $includeAppData
            )
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupOptionsView(exportManager: exportManager)
        }
        .sheet(isPresented: $showingRecoverySheet) {
            RecoveryOptionsView(exportManager: exportManager)
        }
        .sheet(isPresented: $showingMigrationSheet) {
            MigrationOptionsView(exportManager: exportManager)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Export")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Format Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Format")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Format", selection: $selectedExportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Data Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data to Include")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Toggle("Health Data", isOn: $includeHealthData)
                    Toggle("App Data", isOn: $includeAppData)
                }
                
                // Export Button
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(exportManager.isExporting)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Backup Section
    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backup Management")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Backup Status
                HStack {
                    VStack(alignment: .leading) {
                        Text("Last Backup")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let lastBackup = exportManager.lastBackupDate {
                            Text(lastBackup, style: .relative)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text("Never")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(backupStatusColor)
                        .frame(width: 12, height: 12)
                }
                
                // Backup Actions
                HStack(spacing: 12) {
                    Button(action: {
                        showingBackupSheet = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Backup Now")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(exportManager.isBackingUp)
                    
                    Button(action: {
                        Task {
                            try? await exportManager.startBackup()
                        }
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                            Text("Cloud Backup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(exportManager.isBackingUp)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Recovery Section
    private var recoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Recovery")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Recovery Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recovery Options")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        showingRecoverySheet = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Restore from Backup")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Import from File")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                
                // Recovery Warning
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Recovery will overwrite current data. Make sure to backup first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Migration Section
    private var migrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Migration")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Migration Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Migration Tools")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Button(action: {
                        showingMigrationSheet = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Version Migration")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        // Import from third-party app
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import from Other Apps")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                
                // Migration Info
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("Migration tools help transfer data between different versions or apps.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Backup History
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Backups")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if exportManager.backupHistory.isEmpty {
                        Text("No backups yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(exportManager.backupHistory.prefix(3)) { backup in
                            BackupHistoryRow(backup: backup) {
                                selectedBackup = backup
                            }
                        }
                    }
                }
                
                // Export History
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Exports")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if exportManager.exportHistory.isEmpty {
                        Text("No exports yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(exportManager.exportHistory.prefix(3)) { export in
                            ExportHistoryRow(export: export)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Computed Properties
    private var backupStatusColor: Color {
        switch exportManager.backupStatus {
        case .idle:
            return .gray
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        case .restoring:
            return .blue
        }
    }
    
    // MARK: - Helper Methods
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFileURL = url
                // Handle file import
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct ExportOptionsView: View {
    @ObservedObject var exportManager: AdvancedDataExportManager
    @Binding var selectedFormat: ExportFormat
    @Binding var includeHealthData: Bool
    @Binding var includeAppData: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress indicator
                if isExporting {
                    VStack(spacing: 12) {
                        ProgressView(value: exportManager.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Exporting data... \(Int(exportManager.exportProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Export options
                if !isExporting {
                    VStack(alignment: .leading, spacing: 16) {
                        // Format selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export Format")
                                .font(.headline)
                            
                            Picker("Format", selection: $selectedFormat) {
                                ForEach(ExportFormat.allCases, id: \.self) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Data options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data to Include")
                                .font(.headline)
                            
                            Toggle("Health Data", isOn: $includeHealthData)
                            Toggle("App Data", isOn: $includeAppData)
                        }
                        
                        // Format information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Format Information")
                                .font(.headline)
                            
                            formatInformation
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Action buttons
                if !isExporting {
                    Button(action: startExport) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Start Export")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!includeHealthData && !includeAppData)
                } else {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Export")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(exportURL == nil)
                }
            }
            .padding()
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private var formatInformation: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch selectedFormat {
            case .json:
                Text("• Human-readable format")
                Text("• Easy to process programmatically")
                Text("• Includes all data types")
            case .csv:
                Text("• Spreadsheet-compatible")
                Text("• Good for data analysis")
                Text("• Limited to tabular data")
            case .pdf:
                Text("• Professional report format")
                Text("• Includes charts and summaries")
                Text("• Read-only format")
            case .xml:
                Text("• Structured data format")
                Text("• Good for data exchange")
                Text("• Verbose but readable")
            case .fhir:
                Text("• Healthcare standard format")
                Text("• Compatible with medical systems")
                Text("• Industry standard")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    private func startExport() {
        isExporting = true
        
        Task {
            do {
                let url = try await exportManager.exportData(
                    to: selectedFormat,
                    includeHealthData: includeHealthData,
                    includeAppData: includeAppData
                )
                
                await MainActor.run {
                    exportURL = url
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    // Show error alert
                }
            }
        }
    }
}

struct BackupOptionsView: View {
    @ObservedObject var exportManager: AdvancedDataExportManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isBackingUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Backup status
                VStack(spacing: 12) {
                    if isBackingUp {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Creating backup...")
                            .font(.headline)
                    } else {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Backup Options")
                            .font(.headline)
                    }
                }
                
                // Backup information
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "clock", title: "Last Backup", value: exportManager.lastBackupDate?.formatted() ?? "Never")
                    InfoRow(icon: "number", title: "Total Backups", value: "\(exportManager.backupHistory.count)")
                    InfoRow(icon: "checkmark.shield", title: "Encryption", value: "Enabled")
                    InfoRow(icon: "arrow.clockwise", title: "Auto Backup", value: "Daily")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Action buttons
                if !isBackingUp {
                    Button(action: startBackup) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Start Backup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Backup Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func startBackup() {
        isBackingUp = true
        
        Task {
            do {
                try await exportManager.startBackup()
                await MainActor.run {
                    isBackingUp = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isBackingUp = false
                    // Show error alert
                }
            }
        }
    }
}

struct RecoveryOptionsView: View {
    @ObservedObject var exportManager: AdvancedDataExportManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isRestoring = false
    @State private var selectedBackup: BackupRecord?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Recovery status
                VStack(spacing: 12) {
                    if isRestoring {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Restoring data...")
                            .font(.headline)
                    } else {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Recovery Options")
                            .font(.headline)
                    }
                }
                
                // Available backups
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Backups")
                        .font(.headline)
                    
                    if exportManager.backupHistory.isEmpty {
                        Text("No backups available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(exportManager.backupHistory) { backup in
                            BackupSelectionRow(
                                backup: backup,
                                isSelected: selectedBackup?.id == backup.id
                            ) {
                                selectedBackup = backup
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Action buttons
                if !isRestoring {
                    Button(action: startRecovery) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Restore Selected Backup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(selectedBackup == nil)
                }
            }
            .padding()
            .navigationTitle("Recovery Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func startRecovery() {
        guard let backup = selectedBackup else { return }
        
        isRestoring = true
        
        Task {
            do {
                try await exportManager.restoreFromBackup(backup.fileURL)
                await MainActor.run {
                    isRestoring = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    // Show error alert
                }
            }
        }
    }
}

struct MigrationOptionsView: View {
    @ObservedObject var exportManager: AdvancedDataExportManager
    @Environment(\.presentationMode) var presentationMode
    @State private var fromVersion = "1.0"
    @State private var toVersion = "1.1"
    @State private var isMigrating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Migration status
                VStack(spacing: 12) {
                    if isMigrating {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Migrating data...")
                            .font(.headline)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Migration Options")
                            .font(.headline)
                    }
                }
                
                // Version selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Version Migration")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("From Version")
                                .font(.subheadline)
                            Picker("From", selection: $fromVersion) {
                                Text("1.0").tag("1.0")
                                Text("1.1").tag("1.1")
                                Text("1.2").tag("1.2")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("To Version")
                                .font(.subheadline)
                            Picker("To", selection: $toVersion) {
                                Text("1.1").tag("1.1")
                                Text("1.2").tag("1.2")
                                Text("2.0").tag("2.0")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Action buttons
                if !isMigrating {
                    Button(action: startMigration) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Start Migration")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(fromVersion == toVersion)
                }
            }
            .padding()
            .navigationTitle("Migration Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func startMigration() {
        isMigrating = true
        
        Task {
            do {
                try await exportManager.migrateFromVersion(fromVersion, toVersion: toVersion)
                await MainActor.run {
                    isMigrating = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isMigrating = false
                    // Show error alert
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct BackupHistoryRow: View {
    let backup: BackupRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.timestamp, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(backup.fileSize / 1024 / 1024) MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(backup.type == .full ? "Full" : "Incremental")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(backup.type == .full ? Color.blue : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(backup.status == .success ? "Success" : "Failed")
                        .font(.caption)
                        .foregroundColor(backup.status == .success ? .green : .red)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExportHistoryRow: View {
    let export: ExportRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(export.timestamp, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(export.format.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(export.fileSize / 1024 / 1024) MB")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(export.includeHealthData ? "Health + App" : "App Only")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BackupSelectionRow: View {
    let backup: BackupRecord
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.timestamp, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(backup.fileSize / 1024 / 1024) MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    AdvancedDataExportView()
} 