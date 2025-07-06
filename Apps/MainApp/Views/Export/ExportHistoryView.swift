import SwiftUI
import UniformTypeIdentifiers

@available(iOS 14.0, *)
struct ExportHistoryView: View {
    @ObservedObject var viewModel: HealthDataExportViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilterStatus: ExportStatus?
    @State private var selectedFilterFormat: ExportFormat?
    @State private var showingFilters = false
    @State private var selectedExports: Set<String> = []
    @State private var isSelectMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Export List
                exportList
            }
            .navigationTitle("Export History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectMode {
                        Button("Cancel") {
                            exitSelectMode()
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !filteredExports.isEmpty {
                            Button(isSelectMode ? "Done" : "Select") {
                                toggleSelectMode()
                            }
                        }
                        
                        Menu {
                            filterMenuItems
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ExportFilterView(
                    selectedStatus: $selectedFilterStatus,
                    selectedFormat: $selectedFilterFormat
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search exports...")
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            if isSelectMode && !selectedExports.isEmpty {
                selectedActionsBar
            }
            
            if hasActiveFilters {
                activeFiltersBar
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var selectedActionsBar: some View {
        HStack {
            Text("\(selectedExports.count) selected")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button("Share") {
                shareSelectedExports()
            }
            .disabled(selectedExports.isEmpty || !selectedExports.allSatisfy { id in
                viewModel.exportHistory.first(where: { $0.id == id })?.isSuccessful == true
            })
            
            Button("Delete") {
                deleteSelectedExports()
            }
            .foregroundColor(.red)
            .disabled(selectedExports.isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let status = selectedFilterStatus {
                    FilterChip(
                        title: status.rawValue,
                        color: Color(status.color)
                    ) {
                        selectedFilterStatus = nil
                    }
                }
                
                if let format = selectedFilterFormat {
                    FilterChip(
                        title: format.displayName,
                        color: .blue
                    ) {
                        selectedFilterFormat = nil
                    }
                }
                
                Button("Clear All") {
                    clearAllFilters()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Export List
    
    private var exportList: some View {
        Group {
            if filteredExports.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(groupedExports.keys.sorted(by: >), id: \.self) { date in
                        Section(header: sectionHeader(for: date)) {
                            ForEach(groupedExports[date] ?? [], id: \.id) { exportResult in
                                ExportHistoryCell(
                                    exportResult: exportResult,
                                    isSelected: selectedExports.contains(exportResult.id),
                                    isSelectMode: isSelectMode,
                                    onToggleSelection: {
                                        toggleSelection(exportResult.id)
                                    },
                                    onShare: {
                                        shareExport(exportResult)
                                    },
                                    onDelete: {
                                        viewModel.confirmDeleteExport(exportResult)
                                    },
                                    onRetry: {
                                        Task {
                                            await viewModel.retryExport(exportResult)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: hasActiveFilters ? "doc.text.magnifyingglass" : "tray")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(hasActiveFilters ? "No exports found" : "No export history")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(hasActiveFilters ? 
                 "Try adjusting your filters to see more results." :
                 "Your export history will appear here after you create your first export.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearAllFilters()
                }
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var filteredExports: [ExportResult] {
        var exports = viewModel.exportHistory
        
        // Apply search filter
        if !searchText.isEmpty {
            exports = exports.filter { export in
                export.displayName.localizedCaseInsensitiveContains(searchText) ||
                export.request.format.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        if let status = selectedFilterStatus {
            exports = exports.filter { $0.status == status }
        }
        
        // Apply format filter
        if let format = selectedFilterFormat {
            exports = exports.filter { $0.request.format == format }
        }
        
        return exports
    }
    
    private var groupedExports: [Date: [ExportResult]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExports) { export in
            calendar.startOfDay(for: export.startTime)
        }
        return grouped
    }
    
    private var hasActiveFilters: Bool {
        return selectedFilterStatus != nil || selectedFilterFormat != nil
    }
    
    private var filterMenuItems: some View {
        Group {
            Menu("Status") {
                Button("All Statuses") {
                    selectedFilterStatus = nil
                }
                
                ForEach(ExportStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) {
                        selectedFilterStatus = status
                    }
                }
            }
            
            Menu("Format") {
                Button("All Formats") {
                    selectedFilterFormat = nil
                }
                
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button(format.displayName) {
                        selectedFilterFormat = format
                    }
                }
            }
            
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearAllFilters()
                }
            }
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(formatSectionDate(date))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            let dayExports = groupedExports[date] ?? []
            Text("\(dayExports.count) export\(dayExports.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func toggleSelectMode() {
        isSelectMode.toggle()
        if !isSelectMode {
            selectedExports.removeAll()
        }
    }
    
    private func exitSelectMode() {
        isSelectMode = false
        selectedExports.removeAll()
    }
    
    private func toggleSelection(_ exportId: String) {
        if selectedExports.contains(exportId) {
            selectedExports.remove(exportId)
        } else {
            selectedExports.insert(exportId)
        }
    }
    
    private func clearAllFilters() {
        selectedFilterStatus = nil
        selectedFilterFormat = nil
    }
    
    private func shareExport(_ exportResult: ExportResult) {
        let files = viewModel.shareExport(exportResult)
        // Handle sharing logic here
    }
    
    private func shareSelectedExports() {
        let selectedResults = viewModel.exportHistory.filter { selectedExports.contains($0.id) }
        // Handle bulk sharing logic here
    }
    
    private func deleteSelectedExports() {
        for exportId in selectedExports {
            if let exportResult = viewModel.exportHistory.first(where: { $0.id == exportId }) {
                Task {
                    await viewModel.deleteExport(exportResult)
                }
            }
        }
        selectedExports.removeAll()
    }
}

// MARK: - Export History Cell

@available(iOS 14.0, *)
struct ExportHistoryCell: View {
    let exportResult: ExportResult
    let isSelected: Bool
    let isSelectMode: Bool
    let onToggleSelection: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if isSelectMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Status icon
            Image(systemName: exportResult.status.icon)
                .foregroundColor(Color(exportResult.status.color))
                .font(.title3)
                .frame(width: 24)
            
            // Export details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exportResult.request.format.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formatTime(exportResult.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(exportResult.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 16) {
                    StatusBadge(status: exportResult.status)
                    
                    if exportResult.isSuccessful {
                        Label(exportResult.fileSizeFormatted, systemImage: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(exportResult.durationFormatted, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Action menu
            if !isSelectMode {
                Menu {
                    if exportResult.isSuccessful {
                        Button(action: onShare) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    if exportResult.status == .failed {
                        Button(action: onRetry) {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectMode {
                onToggleSelection()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

@available(iOS 14.0, *)
struct StatusBadge: View {
    let status: ExportStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

@available(iOS 14.0, *)
struct FilterChip: View {
    let title: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

@available(iOS 14.0, *)
struct ExportFilterView: View {
    @Binding var selectedStatus: ExportStatus?
    @Binding var selectedFormat: ExportFormat?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Status") {
                    ForEach(ExportStatus.allCases, id: \.self) { status in
                        HStack {
                            Text(status.rawValue)
                            Spacer()
                            if selectedStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedStatus = selectedStatus == status ? nil : status
                        }
                    }
                }
                
                Section("Format") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Text(format.displayName)
                            Spacer()
                            if selectedFormat == format {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFormat = selectedFormat == format ? nil : format
                        }
                    }
                }
            }
            .navigationTitle("Filter Exports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct ExportHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ExportHistoryView(viewModel: HealthDataExportViewModel())
    }
}