import SwiftUI

@available(iOS 14.0, *)
struct HealthDataExportView: View {
    @StateObject private var viewModel = HealthDataExportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Current Export Progress (if active)
                    if viewModel.isExporting {
                        exportProgressSection
                    }
                    
                    // Export Configuration
                    exportConfigurationSection
                    
                    // Quick Export Actions
                    quickExportSection
                    
                    // Export History
                    exportHistorySection
                }
                .padding()
            }
            .navigationTitle("Export Health Data")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("History") {
                        viewModel.showExportHistory()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingExportSheet) {
            ExportConfigurationView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingHistorySheet) {
            ExportHistoryView(viewModel: viewModel)
        }
        .alert("Export Error", isPresented: $viewModel.showingErrorAlert) {
            Button("OK") {
                viewModel.dismissError()
            }
            if viewModel.canRetryAfterError {
                Button("Retry") {
                    Task {
                        await viewModel.startExport()
                    }
                }
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .confirmationDialog("Delete Export", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.performDeleteExport()
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeleteExport()
            }
        } message: {
            Text("Are you sure you want to delete this export? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.and.arrow.up.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Export Your Health Data")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Create comprehensive reports of your health data in multiple formats for analysis, backup, or sharing with healthcare providers.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Export Progress Section
    
    private var exportProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: viewModel.currentStatusIcon)
                    .foregroundColor(Color(viewModel.currentStatusColor))
                
                Text("Export in Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    viewModel.cancelExport()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text(viewModel.progressDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !viewModel.timeRemainingDescription.isEmpty {
                    Text(viewModel.timeRemainingDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Export Configuration Section
    
    private var exportConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Format Selection
            formatSelectionCard
            
            // Data Types Summary
            dataTypesSummaryCard
            
            // Date Range Summary
            dateRangeSummaryCard
            
            // Export Estimate
            if let estimate = viewModel.estimatedExport {
                exportEstimateCard(estimate)
            }
            
            // Main Export Button
            mainExportButton
        }
    }
    
    private var formatSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("Export Format")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        FormatSelectionCard(
                            format: format,
                            isSelected: viewModel.isFormatSelected(format)
                        ) {
                            viewModel.selectedFormat = format
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var dataTypesSummaryCard: some View {
        Button(action: { viewModel.showExportOptions() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Data Types")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(viewModel.selectedDataTypesDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dateRangeSummaryCard: some View {
        Button(action: { viewModel.showExportOptions() }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                        Text("Date Range")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text(viewModel.dateRangeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func exportEstimateCard(_ estimate: ExportEstimate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("Export Estimate")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(estimate.recordCount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("File Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.estimatedFileSizeFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.estimatedDurationFormatted)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var mainExportButton: some View {
        Button(action: {
            Task {
                await viewModel.startExport()
            }
        }) {
            HStack {
                if viewModel.isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "tray.and.arrow.up.fill")
                }
                
                Text(viewModel.isExporting ? "Exporting..." : "Start Export")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canStartExport ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canStartExport)
        
        if let validationMessage = viewModel.exportValidationMessage {
            Text(validationMessage)
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top, 4)
        }
    }
    
    // MARK: - Quick Export Section
    
    private var quickExportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Export")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickExportCard(
                    title: "JSON Report",
                    subtitle: "Last 30 days",
                    icon: "doc.text.fill",
                    color: .blue
                ) {
                    Task {
                        await viewModel.quickExportJSON()
                    }
                }
                
                QuickExportCard(
                    title: "CSV Data",
                    subtitle: "Last 30 days",
                    icon: "tablecells.fill",
                    color: .green
                ) {
                    Task {
                        await viewModel.quickExportCSV()
                    }
                }
                
                QuickExportCard(
                    title: "PDF Report",
                    subtitle: "Last 30 days",
                    icon: "doc.richtext.fill",
                    color: .red
                ) {
                    Task {
                        await viewModel.quickExportPDF()
                    }
                }
                
                QuickExportCard(
                    title: "Last Week",
                    subtitle: "All formats",
                    icon: "calendar.badge.clock",
                    color: .orange
                ) {
                    Task {
                        await viewModel.quickExportLastWeek()
                    }
                }
            }
        }
    }
    
    // MARK: - Export History Section
    
    private var exportHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Exports")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    viewModel.showExportHistory()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if viewModel.exportHistory.isEmpty {
                EmptyExportHistoryView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.exportHistory.prefix(3)), id: \.id) { exportResult in
                        ExportHistoryRowView(
                            exportResult: exportResult,
                            onDelete: { viewModel.confirmDeleteExport(exportResult) },
                            onRetry: { 
                                Task {
                                    await viewModel.retryExport(exportResult)
                                }
                            },
                            onShare: { viewModel.shareExport(exportResult) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

@available(iOS 14.0, *)
struct FormatSelectionCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(format.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(format.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 120, height: 100)
            .padding(12)
            .background(isSelected ? color : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch format {
        case .json: return "doc.text.fill"
        case .csv: return "tablecells.fill"
        case .pdf: return "doc.richtext.fill"
        case .appleHealth: return "heart.fill"
        }
    }
    
    private var color: Color {
        switch format {
        case .json: return .blue
        case .csv: return .green
        case .pdf: return .red
        case .appleHealth: return .pink
        }
    }
}

@available(iOS 14.0, *)
struct QuickExportCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 14.0, *)
struct ExportHistoryRowView: View {
    let exportResult: ExportResult
    let onDelete: () -> Void
    let onRetry: () -> Void
    let onShare: ([URL]) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: exportResult.status.icon)
                .foregroundColor(Color(exportResult.status.color))
                .frame(width: 24)
            
            // Export info
            VStack(alignment: .leading, spacing: 2) {
                Text(exportResult.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(exportResult.status.rawValue)
                        .font(.caption)
                        .foregroundColor(Color(exportResult.status.color))
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(exportResult.durationFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if exportResult.isSuccessful {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(exportResult.fileSizeFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if exportResult.status == .failed {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if exportResult.isSuccessful {
                    Button(action: { onShare(exportResult.filePath.map { [$0] } ?? []) }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Menu {
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

@available(iOS 14.0, *)
struct EmptyExportHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Export History")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Your export history will appear here after you create your first export.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct HealthDataExportView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDataExportView()
    }
}